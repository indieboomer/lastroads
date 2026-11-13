extends Node3D

# Cosmetic, bounded and deliberately separate from combat, loot and world RNG.
const C = preload("res://scripts/content.gd")
const BIRD_LIMIT := 40
const LEAF_LIMIT := 40
const CLOUD_LIMIT := 3
const INSECTS_PER_CLOUD := 28
var game: Node
var rng := RandomNumberGenerator.new()
var birds: Array = []
var leaves: Array = []
var clouds: Array = []
var bird_view: MultiMeshInstance3D
var leaf_view: MultiMeshInstance3D
var insect_view: MultiMeshInstance3D
var bird_material: ShaderMaterial
var clock := 0.0
var flock_in := 2.0
var ground_in := 0.5
var leaves_in := 1.0
var next_group := 0
var flushes := 0
var initialized := false
var deer = preload("res://scripts/ambient_deer.gd").new()

func build() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rng.seed = 177608
	bird_material = ShaderMaterial.new()
	bird_material.shader = load("res://shaders/ambient_bird.gdshader")
	bird_view = pool(bird_mesh(),BIRD_LIMIT,bird_material)
	var leaf := SurfaceTool.new()
	leaf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in [[Vector3(0,0,-0.12),Vector3(-0.07,0,0),Vector3(0,0.025,0.10)],[Vector3(0,0,-0.12),Vector3(0,0.025,0.10),Vector3(0.07,0,0)]]:
		for p in triangle: leaf.add_vertex(p)
	leaf.generate_normals()
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("b88339")
	leaf_mat.vertex_color_use_as_albedo = true
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_view = pool(leaf.commit(),LEAF_LIMIT,leaf_mat)
	var speck := SphereMesh.new()
	speck.radius = 0.012
	speck.height = 0.024
	speck.radial_segments = 4
	speck.rings = 1
	var insect_mat := StandardMaterial3D.new()
	insect_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	insect_mat.albedo_color = Color("a5a577")
	insect_mat.vertex_color_use_as_albedo = true
	insect_view = pool(speck,CLOUD_LIMIT*INSECTS_PER_CLOUD,insect_mat)
	deer.build(game,self)
	reset()

func pool(mesh: Mesh, count: int, material: Material) -> MultiMeshInstance3D:
	var view := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.use_custom_data = true
	multi.mesh = mesh
	multi.instance_count = count
	view.multimesh = multi
	view.material_override = material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.custom_aabb = AABB(Vector3(-300,-15,-1050),Vector3(600,100,1200))
	add_child(view)
	for index in range(count):
		multi.set_instance_transform(index,Transform3D(Basis().scaled(Vector3.ZERO),Vector3.ZERO))
	return view

func bird_mesh() -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Faceted body, pointed beak, tail and two independently folding wings.
	for triangle in [[Vector3(0,.09,-.22),Vector3(-.085,0,0),Vector3(.085,0,0)],[Vector3(-.085,0,0),Vector3(0,.09,-.22),Vector3(0,.05,.24)],[Vector3(0,.09,-.22),Vector3(.085,0,0),Vector3(0,.05,.24)],[Vector3(-.05,.04,.15),Vector3(0,.05,.36),Vector3(.05,.04,.15)]]:
		for p in triangle:
			mesh.set_color(Color("33342d"))
			mesh.set_uv(Vector2.ZERO)
			mesh.add_vertex(p)
	for side in [-1.0,1.0]:
		for p in [Vector3(side*.03,.05,-.07),Vector3(side*.57,.05,.08),Vector3(side*.10,.05,.16)]:
			mesh.set_color(Color("424139"))
			mesh.set_uv(Vector2(side,absf(p.x)/.57))
			mesh.add_vertex(p)
	for p in [Vector3(-.035,.085,-.20),Vector3(0,.075,-.32),Vector3(.035,.085,-.20)]:
		mesh.set_color(Color("9b8557"))
		mesh.set_uv(Vector2.ZERO)
		mesh.add_vertex(p)
	mesh.generate_normals()
	return mesh.commit()

func reset() -> void:
	if not bird_view: return
	clock = 0
	flock_in = 2
	ground_in = .5
	leaves_in = 1
	flushes = 0
	next_group = 0
	initialized = false
	deer.reset()
	birds.clear()
	leaves.clear()
	clouds.clear()
	for index in range(BIRD_LIMIT): birds.append({"mode":"off","p":Vector3.ZERO,"v":Vector3.ZERO,"age":0.0,"ttl":0.0,"phase":rng.randf(),"group":0,"scale":rng.randf_range(.65,1.0)})
	for index in range(LEAF_LIMIT): leaves.append({"active":false,"p":Vector3.ZERO,"v":Vector3.ZERO,"age":0.0,"phase":rng.randf()*TAU})
	for index in range(CLOUD_LIMIT): clouds.append({"active":false,"p":Vector3.ZERO,"age":0.0,"ttl":0.0})
	for view in [bird_view,leaf_view,insect_view]:
		for index in range(view.multimesh.instance_count): hide_instance(view,index)

func hide_instance(view: MultiMeshInstance3D, index: int) -> void:
	view.multimesh.set_instance_transform(index,Transform3D(Basis().scaled(Vector3.ZERO),Vector3.ZERO))

func patch(p: Vector2) -> bool:
	if absf(p.x)>225 or p.y< -1830 or p.y>75: return false
	if p.x>98 and p.x<166 and p.y< -354 and p.y> -435: return false
	if not game.world.outside_buildings(p,3.0): return false
	for npc in game.world.npcs.values():
		if npc.visible and Vector2(npc.position.x,npc.position.z).distance_to(p)<4: return false
	return true

func spawn_flock() -> void:
	var angle := rng.randf()*TAU
	var direction := Vector3(sin(angle),0,cos(angle))
	var center: Vector3 = game.player.position-direction*32+Vector3(0,13+rng.randf()*7,0)
	next_group += 1
	var added := 0
	for bird in birds:
		if bird.mode!="off": continue
		var side := -1.0 if added%2==0 else 1.0
		var rank := float(added/2)
		bird.p = center+direction*rank*1.7+Vector3(direction.z,0,-direction.x)*side*rank*1.5
		bird.p.y += rng.randf_range(-.7,.7)
		bird.v = direction*rng.randf_range(6.0,7.5)
		bird.mode = "flight"
		bird.group = next_group
		bird.age = 0.0
		bird.ttl = rng.randf_range(17,23)
		added += 1
		if added>=10: break

func spawn_ground() -> void:
	var angle: float = game.player.rotation.y+rng.randf_range(-1.0,1.0)
	var base: Vector3 = game.player.position+Vector3(-sin(angle),0,-cos(angle))*rng.randf_range(12,24)
	next_group += 1
	var added := 0
	for bird in birds:
		if bird.mode!="off": continue
		var p := Vector2(base.x,base.z)+Vector2(rng.randf_range(-2.5,2.5),rng.randf_range(-2,2))
		if not patch(p): continue
		bird.p = C.ground(p,.06)
		if not game.line_clear(game.camera.global_position,bird.p+Vector3.UP*.15): continue
		bird.mode = "rest"
		bird.group = next_group
		bird.v = Vector3(sin(angle),0,cos(angle))
		bird.age = 0.0
		bird.ttl = rng.randf_range(28,50)
		added += 1
		if added>=4: break

func threat_at(p: Vector3) -> Vector3:
	if p.distance_to(game.player.position)<6.0: return game.player.position
	for creature in game.enemies:
		if not creature.dead and creature.position.distance_to(p)<4.5: return creature.position
	for npc in game.world.npcs.values():
		if npc.visible and npc.position.distance_to(p)<3.0: return npc.position
	return Vector3.INF

func scatter(group: int, from: Vector3) -> void:
	flushes += 1
	for bird in birds:
		if bird.mode!="rest" or bird.group!=group: continue
		var away: Vector3 = bird.p-from
		away.y = 0
		if away.length_squared()<.01: away = Vector3.RIGHT
		bird.v = away.normalized().rotated(Vector3.UP,rng.randf_range(-.4,.4))*rng.randf_range(5.5,8)
		bird.mode = "escape"
		bird.age = 0.0
		bird.ttl = 13.0

func tick(dt: float) -> void:
	if dt<=0 or not game.started or game.reporting or game.modal!="": return
	clock += dt
	var p := Vector2(game.player.position.x,game.player.position.z)
	visible = not game.in_crypt() and game.world.outside_buildings(p,.2)
	if not visible: return
	deer.tick(dt)
	if not initialized:
		initialized = true
		spawn_ground()
	flock_in -= dt
	ground_in -= dt
	if flock_in<=0:
		spawn_flock()
		flock_in = rng.randf_range(22,42)
	if ground_in<=0:
		spawn_ground()
		ground_in = rng.randf_range(12,20)
	bird_material.set_shader_parameter("life_time",clock)
	for index in range(birds.size()):
		var bird: Dictionary = birds[index]
		if bird.mode=="off": hide_instance(bird_view,index); continue
		bird.age += dt
		if bird.age>bird.ttl or bird.p.distance_to(game.player.position)>145:
			bird.mode = "off"
			hide_instance(bird_view,index)
			continue
		if bird.mode=="rest":
			var threat := threat_at(bird.p)
			if threat!=Vector3.INF: scatter(bird.group,threat)
		if bird.mode!="rest":
			bird.p += bird.v*dt
			bird.p.y += (minf(4.5,bird.age*3.0)*dt if bird.mode=="escape" else sin(clock*1.7+bird.phase*TAU)*dt*.16)
		var yaw := atan2(-bird.v.x,-bird.v.z)
		var basis := Basis(Vector3.UP,yaw).scaled(Vector3.ONE*bird.scale)
		bird_view.multimesh.set_instance_transform(index,Transform3D(basis,bird.p))
		bird_view.multimesh.set_instance_custom_data(index,Color(bird.phase,0.0 if bird.mode=="rest" else 1.0,.75+bird.phase*.4,1))
		bird_view.multimesh.set_instance_color(index,Color.WHITE)
	tick_insects(dt)
	tick_leaves(dt)

func tick_insects(dt: float) -> void:
	insect_view.visible = game.state.weather.rain<.5 and game.state.weather.wind<1.1
	for index in range(clouds.size()):
		var cloud: Dictionary = clouds[index]
		cloud.age += dt
		if not cloud.active or cloud.age>cloud.ttl or cloud.p.distance_to(game.player.position)>35:
			var at: Vector3 = game.player.position+Vector3(rng.randf_range(-18,18),0,rng.randf_range(-18,18))
			cloud.active = patch(Vector2(at.x,at.z)) and at.distance_to(game.player.position)>6
			cloud.p = C.ground(Vector2(at.x,at.z),rng.randf_range(.7,1.8))
			cloud.age = 0.0
			cloud.ttl = rng.randf_range(22,40)
		for speck in range(INSECTS_PER_CLOUD):
			var slot := index*INSECTS_PER_CLOUD+speck
			if not cloud.active: hide_instance(insect_view,slot); continue
			var phase := float(speck)*2.39996
			var at: Vector3 = cloud.p+Vector3(sin(clock*1.8+phase)*.65,sin(clock*2.7+phase*1.3)*.35,cos(clock*1.9+phase)*.65)
			insect_view.multimesh.set_instance_transform(slot,Transform3D(Basis(),at))
			insect_view.multimesh.set_instance_color(slot,Color("c4bb78") if speck%3==0 else Color("7d8063"))

func tick_leaves(dt: float) -> void:
	var strength: float = [0.0,.5,1.0,1.8][game.visuals.values.wind_strength]
	leaf_view.visible = strength>0
	leaves_in -= dt
	if leaves_in<=0:
		leaves_in = rng.randf_range(5,12)/maxf(.7,game.state.weather.wind)
		var added := 0
		for leaf in leaves:
			if leaf.active: continue
			var at: Vector3 = game.player.position+Vector3(rng.randf_range(-12,4),0,rng.randf_range(-12,12))
			if not patch(Vector2(at.x,at.z)): continue
			leaf.p = C.ground(Vector2(at.x,at.z),rng.randf_range(3,6))
			leaf.v = Vector3(rng.randf_range(.7,1.7),-.35,rng.randf_range(-.4,.8))
			leaf.active = true
			leaf.age = 0.0
			added += 1
			if added>=8: break
	for index in range(leaves.size()):
		var leaf: Dictionary = leaves[index]
		if not leaf.active: hide_instance(leaf_view,index); continue
		leaf.age += dt
		leaf.p += (leaf.v*Vector3(strength*(.6+game.state.weather.wind),1,strength)+Vector3(sin(clock*2+leaf.phase)*.3,0,cos(clock*2+leaf.phase)*.3))*dt
		if leaf.age>14 or leaf.p.y<C.height_at(leaf.p.x,leaf.p.z)+.04 or leaf.p.distance_to(game.player.position)>45:
			leaf.active = false
			hide_instance(leaf_view,index)
			continue
		var basis := Basis.from_euler(Vector3(clock*2+leaf.phase,clock+leaf.phase,sin(clock+leaf.phase)*.8))
		leaf_view.multimesh.set_instance_transform(index,Transform3D(basis,leaf.p))
		leaf_view.multimesh.set_instance_color(index,Color("a76730") if index%2 else Color("cab061"))

func summary() -> Dictionary:
	return {"clock":clock,"birds":birds.filter(func(b): return b.mode!="off").size(),"ground_birds":birds.filter(func(b): return b.mode=="rest").size(),"leaves":leaves.filter(func(l): return l.active).size(),"insect_clouds":clouds.filter(func(c): return c.active).size(),"scatter_events":flushes,"deer":deer.summary(),"interactive":false}
