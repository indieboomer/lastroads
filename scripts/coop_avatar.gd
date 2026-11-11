extends Node3D

const Data = preload("res://scripts/character_data.gd")
const STATES := ["idle","walk","run","fight","shoot","action"]
static var sheets: Dictionary = {}
var body: CharacterBody3D
var viewpoint: Camera3D
var sprite: Sprite3D
var nameplate: Label3D
var material: ShaderMaterial
var destination := Vector3.ZERO
var target_yaw := 0.0
var clock := 0.0
var motion := "idle"
var profile: Dictionary
var last_frame := -1

func setup(record: Dictionary) -> void:
	profile = record.profile.duplicate(true)
	var stature := Data.stature(profile.species_id)
	body = CharacterBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	add_child(body)
	viewpoint = Camera3D.new()
	viewpoint.current = false
	viewpoint.position.y = stature.eye
	body.add_child(viewpoint)
	sprite = Sprite3D.new()
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.no_depth_test = false
	body.add_child(sprite)
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/coop_actor.gdshader")
	material.set_shader_parameter("recognition_color",Color(record.color))
	sprite.material_override = material
	nameplate = Label3D.new()
	nameplate.text = record.nickname
	nameplate.font_size = 48
	nameplate.outline_size = 12
	nameplate.pixel_size = .006
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.no_depth_test = false
	nameplate.modulate = Color(record.color).lightened(.35)
	nameplate.position.y = stature.body+.4
	body.add_child(nameplate)
	set_frame(0)

func set_frame(frame: int) -> void:
	if last_frame==frame: return
	last_frame = frame
	var id: String = Data.body_id(profile)
	if not sheets.has(id):
		var path: String = Data.body_path(profile)
		if not ResourceLoader.exists(path): return
		sheets[id] = load(path)
	var sheet: Texture2D = sheets[id]
	var region := AtlasTexture.new()
	region.atlas = sheet
	var cell := Vector2(sheet.get_width()/4.0,sheet.get_height()/6.0)
	region.region = Rect2(Vector2(frame%4,frame/4)*cell,cell)
	sprite.texture = region
	# The whole cell keeps attacks and moving limbs at a stable scale.
	sprite.pixel_size = Data.stature(profile.species_id).body/(cell.y*.92)
	sprite.position.y = cell.y*sprite.pixel_size*.5
	material.set_shader_parameter("image",region)

func accept_pose(pose: Dictionary, snap := false) -> void:
	destination = Vector3(pose.p[0],pose.p[1],pose.p[2])
	target_yaw = pose.yaw
	motion = pose.motion
	viewpoint.rotation.x = pose.pitch
	if snap: body.position = destination

func _process(dt: float) -> void:
	if body==null: return
	body.position = body.position.lerp(destination,1.0-exp(-dt*16.0)) if body.position.distance_to(destination)<15 else destination
	body.rotation.y = lerp_angle(body.rotation.y,target_yaw,1.0-exp(-dt*16.0))
	clock += dt
	var row: int = maxi(0,STATES.find(motion))
	var frame: int = 0 if motion=="idle" else int(clock*(10 if motion=="run" else 7))%4
	set_frame(row*4+frame)
	var breath := 1.0+sin(clock*2.1)*.008 if motion=="idle" else 1.0
	sprite.scale = Vector3(1.0,breath,1.0)
	# The current art faces three-quarter forward. Mirror consistently with travel.
	sprite.flip_h = sin(target_yaw)>0
