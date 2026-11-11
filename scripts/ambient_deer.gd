extends RefCounted

const C = preload("res://scripts/content.gd")
const REGIONS := [Rect2i(70,0,600,500),Rect2i(690,0,846,500),Rect2i(50,505,630,519),Rect2i(730,500,806,524)]
var game: Node
var view: Sprite3D
var frames: Array[Texture2D] = []
var rng := RandomNumberGenerator.new()
var active := false
var until_next := 8.0
var age := 0.0
var duration := 10.0
var start := Vector2.ZERO
var direction := Vector2.RIGHT
var speed := 6.5
var sightings := 0
var path_length := 0.0

func build(owner_game: Node, parent: Node3D) -> void:
	game = owner_game
	rng.seed = 177609
	var source: Image = game.world.library.image_for("res://assets/ambient/deer-gallop.png")
	for region in REGIONS:
		var image := source.get_region(region)
		image = image.get_region(game.world.library.visible_bounds(image))
		image.fix_alpha_edges()
		image.generate_mipmaps()
		frames.append(ImageTexture.create_from_image(image))
	view = Sprite3D.new()
	view.name = "AmbientDeer"
	view.texture = frames[0]
	view.pixel_size = 1.35/frames[0].get_height()
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.material_override = game.world.actor_material(view.texture)
	view.material_override.shader = load("res://shaders/ambient_deer.gdshader")
	parent.add_child(view)
	view.hide()

func reset() -> void:
	active = false
	until_next = 8
	age = 0
	sightings = 0
	path_length = 0
	if view: view.hide()

func clear_patch(p: Vector2) -> bool:
	if absf(p.x)>222 or p.y< -990 or p.y>65: return false
	if not game.world.outside_buildings(p,5): return false
	if C.distance_to_road(p)<5: return false
	if game.world.water_bounds.any(func(bounds): return bounds.grow(4).has_point(p)): return false
	return true

func clear_run(p: Vector2, heading: Vector2, length: float) -> bool:
	var previous := C.ground(p,.8)
	for index in range(int(ceil(length/3))+1):
		var at := p+heading*minf(float(index)*3,length)
		if not clear_patch(at): return false
		var next := C.ground(at,.8)
		if absf(next.y-previous.y)>2: return false
		if previous.distance_squared_to(next)>.01:
			var query := PhysicsRayQueryParameters3D.create(previous,next,1)
			if not game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
		previous = next
	return true

func spawn() -> bool:
	if active or game.in_crypt(): return false
	var forward := Vector2(-sin(game.player.rotation.y),-cos(game.player.rotation.y))
	var right := Vector2(-forward.y,forward.x)
	var player := Vector2(game.player.position.x,game.player.position.z)
	for attempt in range(32):
		var p := player+forward.rotated(rng.randf_range(-.55,.55))*rng.randf_range(35,62)
		if C.SITES.values().any(func(site): return p.distance_to(site.pos)<32): continue
		if not game.world.tree_locations.any(func(tree): return p.distance_to(tree)<18): continue
		var heading := (right*(-1.0 if rng.randf()<.5 else 1.0)+forward*.35).normalized()
		var pace := rng.randf_range(6,7.5)
		if not clear_run(p,heading,pace*10): continue
		var visible_run := true
		for seconds in [0.0,1.5,3.0]:
			var point := C.ground(p+heading*pace*seconds,1)
			if not game.camera.is_position_in_frustum(point) or not game.line_clear(game.camera.global_position,point): visible_run = false
		if not visible_run: continue
		begin_run(p,heading,pace)
		return true
	return false

func begin_run(p: Vector2, heading: Vector2, pace: float) -> void:
	start = p
	direction = heading.normalized()
	speed = pace
	age = 0
	duration = 10
	active = true
	sightings += 1
	view.show()
	update_view()

func update_view() -> void:
	var p := start+direction*speed*age
	var frame := int(age*10)%4
	view.texture = frames[frame]
	view.material_override.set_shader_parameter("image",view.texture)
	view.material_override.set_shader_parameter("fade",minf(smoothstep(0,.45,age),1.0-smoothstep(duration-1.5,duration,age)))
	var camera_right := Vector2(game.camera.global_basis.x.x,game.camera.global_basis.x.z)
	view.flip_h = direction.dot(camera_right)<0
	var lift := sin(fmod(age*2.5,1.0)*PI)*.12
	view.position = C.ground(p,view.texture.get_height()*view.pixel_size/2+lift)

func tick(dt: float) -> void:
	if dt<=0 or not game.started or game.reporting or game.modal!="": return
	if not active:
		until_next -= dt
		if until_next<=0:
			var seen := spawn()
			until_next = rng.randf_range(28,55) if seen else 5
		return
	age += dt
	var p := start+direction*speed*age
	# End beyond the player and trees, rather than teleporting within reach.
	if age>=duration or p.distance_to(Vector2(game.player.position.x,game.player.position.z))<22:
		active = false
		view.hide()
		return
	path_length += speed*dt
	update_view()

func summary() -> Dictionary:
	return {"active":active,"sightings":sightings,"age":age,"metres_run":path_length,"interactive":false,"huntable":false}
