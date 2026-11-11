extends Node3D

const TYPES := {
	"clear":{"name":"Clear sky","rain":0.0,"wind":0.18,"clouds":0.05},
	"clouds":{"name":"Passing clouds","rain":0.0,"wind":0.35,"clouds":0.48},
	"rain":{"name":"Rain","rain":0.48,"wind":0.50,"clouds":0.82},
	"heavy":{"name":"Heavy rain","rain":0.95,"wind":0.85,"clouds":0.96},
	"wind":{"name":"Strong wind","rain":0.10,"wind":1.35,"clouds":0.75},
	"storm":{"name":"Thunderstorm","rain":1.0,"wind":1.65,"clouds":1.0}
}
const SCHEDULE := ["clear","clouds","rain","heavy","wind","storm","clouds","clear"]
const DURATIONS := [85.0,80.0,100.0,80.0,70.0,90.0,80.0,100.0]
var game: Node
var rain: GPUParticles3D
var rain_material: ParticleProcessMaterial
var wind_stream: AudioStreamPlayer
var rain_heavy_stream: AudioStreamPlayer
var rain_stream: AudioStreamPlayer
var bolt: MeshInstance3D
var sheltered := false
var warmth := false
var shelter_clock := 0.0
var godrays: MeshInstance3D

func build() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rain = GPUParticles3D.new()
	rain.amount = 2000
	rain.lifetime = 1.4
	rain.preprocess = 1.4
	rain.visibility_aabb = AABB(Vector3(-22,-16,-22),Vector3(44,38,44))
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rain_material = ParticleProcessMaterial.new()
	rain_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_material.emission_box_extents = Vector3(17,0.2,17)
	rain_material.direction = Vector3(0,-1,0)
	rain_material.spread = 3
	rain_material.initial_velocity_min = 18
	rain_material.initial_velocity_max = 24
	rain_material.gravity = Vector3(0,-6,0)
	rain_material.particle_flag_align_y = true
	rain.process_material = rain_material
	var streak := QuadMesh.new()
	streak.size = Vector2(0.022,0.65)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/rain.gdshader")
	streak.material = material
	rain.draw_pass_1 = streak
	add_child(rain)
	rain.emitting = false
	rain_stream = AudioStreamPlayer.new()
	rain_stream.bus = game.audio.SOUND_BUS
	rain_stream.stream = game.audio.library.loop_stream("rain",0)
	if not rain_stream.stream: rain_stream.stream = noise_loop(811,0.18)
	rain_stream.volume_db = -80
	add_child(rain_stream)
	rain_stream.play()
	rain_heavy_stream = AudioStreamPlayer.new()
	rain_heavy_stream.bus = game.audio.SOUND_BUS
	rain_heavy_stream.stream = game.audio.library.loop_stream("rain",1)
	if not rain_heavy_stream.stream: rain_heavy_stream.stream = rain_stream.stream.duplicate()
	rain_heavy_stream.volume_db = -80
	add_child(rain_heavy_stream)
	rain_heavy_stream.play()
	wind_stream = AudioStreamPlayer.new()
	wind_stream.bus = game.audio.SOUND_BUS
	wind_stream.stream = noise_loop(413,0.014)
	wind_stream.volume_db = -80
	add_child(wind_stream)
	wind_stream.play()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://shaders/weather_sky.gdshader")
	sky_material.set_shader_parameter("panorama",game.world.tex("sky"))
	game.world.environment.sky.sky_material = sky_material
	godrays = preload("res://scripts/godrays.gd").new()
	game.camera.add_child(godrays)
	godrays.setup(game)
	apply_visuals()

func noise_loop(seed_value: int, smoothing: float) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples := 22050*4
	var bytes := PackedByteArray()
	bytes.resize(samples*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var value := 0.0
	for i in range(samples):
		value = lerpf(value,rng.randf_range(-1,1),smoothing)
		var envelope := minf(1.0,minf(float(i)/800.0,float(samples-i)/800.0))
		bytes.encode_s16(i*2,int(value*23000*envelope))
	wave.data = bytes
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_end = samples
	return wave

func kind() -> String:
	return SCHEDULE[int(game.state.weather.phase)]

func force(id: String) -> void:
	game.state.weather.phase = SCHEDULE.find(id)
	game.state.weather.age = 0.0
	for key in ["rain","wind","clouds"]:
		game.state.weather[key] = TYPES[id][key]
	apply_visuals()

func tick(dt: float) -> void:
	var w: Dictionary = game.state.weather
	w.clock += dt
	w.age += dt
	if w.age>=DURATIONS[int(w.phase)]:
		w.age -= DURATIONS[int(w.phase)]
		w.phase = (int(w.phase)+1)%SCHEDULE.size()
		game.state.log_event("weather:"+kind())
		game.message(TYPES[kind()].name+" moves over the Hollow.",5)
	var target: Dictionary = TYPES[kind()]
	for key in ["rain","wind","clouds"]:
		w[key] = move_toward(w[key],target[key],dt*0.07)
	shelter_clock -= dt
	if shelter_clock<=0:
		shelter_clock = 0.35
		sheltered = under_roof()
		warmth = game.fire_distance(game.player.position)<6.0
	update_exposure(dt,sheltered,warmth)
	w.flash = maxf(0,w.flash-dt*3.0)
	if kind()=="storm" and not game.in_crypt():
		w.strike_in -= dt
		if w.strike_in<=0:
			strike()
			w.strike_in = 11.0+fposmod(w.clock*1.731,8.0)
	if w.thunder>=0:
		w.thunder -= dt
		if w.thunder<0:
			game.audio.play_effect("thunder")
	if bolt:
		bolt.visible = w.flash>0.03 and not game.in_crypt() and game.visuals.values.lightning
	apply_visuals()

func under_roof() -> bool:
	if game.in_crypt():
		return true
	var eye: Vector3 = game.camera.global_position
	# Include awnings/roof geometry that deliberately has no movement collider.
	for cottage in game.world.cottages:
		var local: Vector3 = cottage.to_local(eye)
		var footprint: Vector2 = cottage.get_meta("footprint")
		if absf(local.x)<footprint.x*0.5+0.45 and absf(local.z)<footprint.y*0.5+0.45 and local.y<8:
			return true
	if eye.x>122 and eye.x<140 and eye.z< -198 and eye.z> -224 and eye.y<12:
		return true
	var result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,eye+Vector3.UP*16,1))
	return not result.is_empty()

func update_exposure(dt: float, protected: bool, fire: bool) -> void:
	var state = game.state
	var protection := 0.48 if state.flags.coat_upgrade else 1.0
	var rain_amount: float = state.weather.rain
	if not protected and rain_amount>0.15:
		state.wetness = minf(100,state.wetness+rain_amount*0.48*protection*dt)
	else:
		state.wetness = maxf(0,state.wetness-dt*(1.25 if fire else 0.20 if protected else 0.08))
	if fire:
		state.wetness = maxf(0,state.wetness-dt*1.1)
	var night: bool = state.day_clock>=18 or state.day_clock<7
	var pressure: float = (0.04+state.wetness*0.003+maxf(0,state.weather.wind-0.4)*0.10+(0.11 if night else 0.0))*protection
	if fire:
		state.cold = maxf(0,state.cold-dt*1.4)
	elif protected:
		state.cold = maxf(0,state.cold-dt*0.30)
	elif not night and state.wetness<15 and state.weather.wind<0.6:
		state.cold = maxf(0,state.cold-dt*0.10)
	else:
		state.cold = minf(100,state.cold+pressure*dt)

func stamina_factor() -> float:
	return 1.0-clampf((game.state.cold-35.0)/65.0,0,1)*0.42-clampf((game.state.wetness-65.0)/35.0,0,1)*0.08

func apply_visuals() -> void:
	var w: Dictionary = game.state.weather
	var visual_scale: float = [0.0,0.5,1.0,1.8][game.visuals.values.wind_strength]
	RenderingServer.global_shader_parameter_set("road_time",w.clock)
	RenderingServer.global_shader_parameter_set("road_wind",(0.55+w.wind*0.9)*visual_scale)
	RenderingServer.global_shader_parameter_set("road_clouds",w.clouds)
	RenderingServer.global_shader_parameter_set("road_flash",w.flash if game.visuals.values.lightning else 0.0)
	RenderingServer.global_shader_parameter_set("road_rain",w.rain)
	if not rain:
		return
	rain.global_position = game.player.global_position+Vector3(0,12,0)
	rain.amount_ratio = maxf(0.02,w.rain)
	rain.emitting = w.rain>0.1 and not sheltered and not game.in_crypt()
	rain.visible = not sheltered and not game.in_crypt()
	rain_material.direction = Vector3(w.wind*0.23,-1,0.1).normalized()
	var silence: bool = game.audio.muted or not game.started or game.in_crypt()
	var heavy_mix: float = clampf((w.rain-.45)/.45,0.0,1.0)
	rain_stream.volume_db = -80 if silence or w.rain<0.05 else linear_to_db(maxf(.0001,w.rain*.25*(1.0-heavy_mix)*(0.25 if sheltered else 1.0)))
	rain_heavy_stream.volume_db = -80 if silence or w.rain<0.05 else linear_to_db(maxf(.0001,w.rain*.30*heavy_mix*(0.25 if sheltered else 1.0)))
	wind_stream.volume_db = -80 if silence else linear_to_db(maxf(0.002,w.wind*0.30)*(0.35 if sheltered else 1.0))

func strike() -> void:
	game.state.weather.flash = 0.85
	game.state.weather.thunder = 1.1
	if bolt:
		bolt.queue_free()
	bolt = MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var origin: Vector3 = game.player.position-game.player.basis.z*70+Vector3(15,0,0)
	var points := [origin+Vector3(0,65,0),origin+Vector3(-3,48,1),origin+Vector3(2,46,0),origin+Vector3(-5,28,1),origin+Vector3(-1,29,0),origin+Vector3(-8,8,0)]
	var side: Vector3 = game.player.basis.x*0.35
	for i in range(points.size()-1):
		for point in [points[i]-side,points[i]+side,points[i+1]-side,points[i+1]-side,points[i]+side,points[i+1]+side]:
			surface.add_vertex(point)
	bolt.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.8,0.93,1.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bolt.material_override = material
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bolt)
