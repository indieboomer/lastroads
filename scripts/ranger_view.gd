extends Control

const PISTOL_MUZZLE := Vector2(.265,.085)
const PISTOL_PAN := Vector2(.50,.325)
const PISTOL_HEIGHT := 660.0
const PISTOL_READY_MUZZLE := Vector2(680,455)
const MUSKET_MUZZLE := Vector2(.57,.505)
const MUSKET_PAN := Vector2(.81,.675)

var game: Node
var gun: TextureRect
var left_hand: TextureRect
var reload_label: Label
var reload_bar: ProgressBar
var textures: Dictionary = {}
var previous_smoke := 0.0
var smoke_muzzle := Vector2.ZERO
var smoke_pan := Vector2.ZERO
var smoke_view: ColorRect
var smoke_lifetime := 2.0
var smoke_strength := .5
var last_shot_serial := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280,720)
	for id in ["pistol","musket","dagger"]: textures[id] = load("res://assets/ranger/"+id+"-hand.png")
	textures.pistol = load("res://assets/ranger/pistol-hand-v2.png")
	textures.musket = load("res://assets/ranger/musket-hand-v2.png")
	left_hand = TextureRect.new()
	left_hand.texture = load("res://assets/ranger/reload-hand.png")
	left_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_hand.size = Vector2(550,367)
	add_child(left_hand)
	gun = TextureRect.new()
	gun.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gun)
	gun.pivot_offset = Vector2(480,350)
	move_child(left_hand,get_child_count()-1)
	reload_label = Label.new()
	reload_label.position = Vector2(440,520)
	reload_label.size = Vector2(400,30)
	reload_label.add_theme_font_size_override("font_size",20)
	reload_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	reload_label.z_index = 2
	add_child(reload_label)
	reload_bar = ProgressBar.new()
	reload_bar.position = Vector2(440,553)
	reload_bar.size = Vector2(400,10)
	reload_bar.show_percentage = false
	reload_bar.z_index = 2
	add_child(reload_bar)
	smoke_view = ColorRect.new()
	smoke_view.size = size
	smoke_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	smoke_view.z_index = 1
	smoke_view.material = ShaderMaterial.new()
	smoke_view.material.shader = load("res://shaders/blackpowder_smoke.gdshader")
	add_child(smoke_view)
	set_process(true)

func _process(_dt: float) -> void:
	visible = game.started and game.modal=="" and game.state.profile.profession_id=="ranger"
	if not visible: return
	var r: Dictionary = game.state.ranger
	gun.texture = textures[r.weapon]
	gun.size = Vector2(700,467) if r.weapon=="musket" else Vector2(650,433)
	gun.position = Vector2(630,295) if r.weapon=="musket" else Vector2(640,300)
	gun.pivot_offset = Vector2(480,350)
	if r.weapon=="musket":
		# Full-frame composition follows musket.png, with an unobstructed central sight.
		gun.size = Vector2(1400,1400.0*gun.texture.get_height()/gun.texture.get_width())
		gun.position = Vector2(690,385)-gun.size*MUSKET_MUZZLE
		gun.pivot_offset = gun.size*Vector2(.82,.80)
	elif r.weapon=="dagger":
		# Overscan both sleeve exits through the complete thrust, including its peak.
		gun.size = Vector2(980,980.0*gun.texture.get_height()/gun.texture.get_width())
		gun.position = Vector2(500,160)
	if r.weapon=="pistol":
		# Retain the photo's forward foreshortening and wrist roll, without stretching.
		gun.size = Vector2(PISTOL_HEIGHT*gun.texture.get_width()/gun.texture.get_height(),PISTOL_HEIGHT)
		# Keep the centre aiming dot and the target above the weapon unobstructed.
		gun.position = PISTOL_READY_MUZZLE-gun.size*PISTOL_MUZZLE
		gun.pivot_offset = gun.size*Vector2(.62,.62)
	game.ui.style_graphic(gun)
	gun.material.shader = load("res://shaders/ranger_equipment.gdshader")
	game.ui.style_graphic(left_hand)
	gun.rotation = 0
	var reload: bool = r.reload_left>0
	left_hand.visible = reload
	left_hand.size = Vector2(750,500) if r.weapon=="musket" else Vector2(550,367)
	left_hand.z_index = -1 if r.weapon=="pistol" else 1
	gun.material.set_shader_parameter("remove_left_support",reload and r.weapon=="musket")
	reload_label.visible = reload
	reload_bar.visible = reload
	if reload:
		var progress: float = 1.0-r.reload_left/r.reload_total
		var stage: int = game.ranger.stage()
		if r.weapon=="pistol":
			gun.position += Vector2(-35,55+sin(progress*PI)*12)
			gun.rotation = .08*sin(progress*PI)
			left_hand.position = [Vector2(210,450),Vector2(235,425+sin(progress*PI*6)*10),Vector2(260,455)][stage]
		else:
			gun.position += Vector2(-120,60+sin(progress*PI)*15)
			gun.rotation = .35*sin(progress*PI)
			left_hand.position = [Vector2(-30,300),Vector2(-30,240+sin(progress*PI*12)*18),Vector2(140,390)][stage]
		reload_label.text = "%s / %.1fs" % [["Loading charge","Ramming","Priming / cocking"][stage],r.reload_left]
		reload_bar.value = progress*100
	else:
		gun.position.y += sin(game.state.elapsed*6)*minf(game.player.velocity.length(),3)*1.4
		gun.position += Vector2(20,40)*maxf(0,game.ranger.flash/.16)
		if r.weapon=="dagger":
			var thrust := sin((1.0-game.ranger.dagger_clock/.4)*PI) if game.ranger.dagger_clock>0 else 0.0
			gun.position += Vector2(-140,-70)*thrust
	if game.ranger.smoke>0 and game.ranger.shot_serial!=last_shot_serial:
		last_shot_serial = game.ranger.shot_serial
		smoke_muzzle = muzzle_position()
		smoke_pan = pan_position()
		smoke_lifetime = 4.0 if r.weapon=="musket" else 2.0
		smoke_strength = 1.35 if r.weapon=="musket" else .5
	previous_smoke = game.ranger.smoke
	smoke_view.visible = game.ranger.smoke>0
	smoke_view.material.set_shader_parameter("muzzle",smoke_muzzle)
	smoke_view.material.set_shader_parameter("pan",smoke_pan)
	smoke_view.material.set_shader_parameter("lifetime",smoke_lifetime)
	smoke_view.material.set_shader_parameter("strength",smoke_strength)
	smoke_view.material.set_shader_parameter("age",smoke_lifetime-game.ranger.smoke)
	smoke_view.material.set_shader_parameter("ignition",game.ranger.flash/.16)
	smoke_view.material.set_shader_parameter("fire_muzzle",muzzle_position())
	smoke_view.material.set_shader_parameter("fire_pan",pan_position())
	queue_redraw()

func weapon_point(uv: Vector2) -> Vector2:
	return gun.get_transform()*(gun.size*uv)

func muzzle_position() -> Vector2:
	return weapon_point(PISTOL_MUZZLE if game.state.ranger.weapon=="pistol" else MUSKET_MUZZLE)

func pan_position() -> Vector2:
	return weapon_point(PISTOL_PAN if game.state.ranger.weapon=="pistol" else MUSKET_PAN)

func show_reload_rod() -> bool:
	return game.state.ranger.weapon=="musket" and game.state.ranger.reload_left>0 and game.ranger.stage()==1

func _draw() -> void:
	if not visible: return
	var r: Dictionary = game.state.ranger
	if show_reload_rod():
		var a := muzzle_position()
		var along := (pan_position()-a).normalized()
		draw_line(a-along*(70+sin(r.reload_left*15)*15),a+along*80,Color("876640"),4)
