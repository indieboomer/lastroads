extends MeshInstance3D

var game: Node
var material: ShaderMaterial
var intensity := 0.0

static func solar_direction(hour: float) -> Vector3:
	var angle := (hour-6.0)*PI/12.0
	return Vector3(cos(angle),sin(angle)*.85,.35).normalized()

static func golden_hour(hour: float) -> float:
	return clampf(exp(-pow((hour-6.7)/1.25,2))+exp(-pow((hour-17.3)/1.25,2)),0,1)

static func clear_strength(hour: float, clouds: float, rain: float) -> float:
	var daylight := smoothstep(-.035,.055,solar_direction(hour).y)
	var clarity := 1.0-smoothstep(.10,.44,clouds)
	var dry := 1.0-smoothstep(.02,.16,rain)
	return daylight*clarity*dry*(.16+.72*golden_hour(hour))

func setup(owner_game: Node) -> void:
	game = owner_game
	name = "ClearWeatherGodrays"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var quad := QuadMesh.new()
	quad.size = Vector2(2,2)
	mesh = quad
	position.z = -1
	extra_cull_margin = 16384
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/godrays.gdshader")
	material.render_priority = -100
	material_override = material
	update_effect()

func _process(_dt: float) -> void:
	update_effect()

func update_effect() -> void:
	if game==null or material==null: return
	var hour: float = game.state.day_clock
	var sun := solar_direction(hour)
	var golden := golden_hour(hour)
	var sky: ShaderMaterial = game.world.environment.sky.sky_material as ShaderMaterial
	if sky:
		sky.set_shader_parameter("sun_direction",sun)
		sky.set_shader_parameter("sun_tint",Color("ffbb73").lerp(Color("fff1ce"),1.0-golden))
		sky.set_shader_parameter("sun_strength",clear_strength(hour,game.state.weather.clouds,game.state.weather.rain)*1.6)
	intensity = 0.0
	visible = false
	if not game.started or game.in_crypt() or game.weather==null or game.weather.sheltered: return
	var base := clear_strength(hour,game.state.weather.clouds,game.state.weather.rain)
	if base<.001: return
	var point: Vector3 = game.camera.global_position+sun*150.0
	if game.camera.is_position_behind(point): return
	var viewport: Vector2 = game.get_viewport().get_visible_rect().size
	var screen: Vector2 = game.camera.unproject_position(point)/viewport
	var margin: float = maxf(maxf(-screen.x,screen.x-1),maxf(-screen.y,screen.y-1))
	var edge_fade := 1.0-smoothstep(.05,.7,margin)
	intensity = base*edge_fade
	if intensity<.001: return
	material.set_shader_parameter("sun_screen",screen)
	material.set_shader_parameter("strength",intensity)
	material.set_shader_parameter("sun_tint",Color("ffc27e").lerp(Color("fff1d1"),1.0-golden))
	material.set_shader_parameter("sky_distance",game.camera.far)
	material.set_shader_parameter("aspect_ratio",viewport.x/maxf(viewport.y,1))
	visible = true
