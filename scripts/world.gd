extends Node3D

const C = preload("res://scripts/content.gd")
var woods_world = preload("res://scripts/woods_world.gd").new()
var march_world = preload("res://scripts/march_world.gd").new()
var game: Node
var ambient: Node3D
var environment: Environment
var sun: DirectionalLight3D
var objects: Dictionary = {}
var npcs: Dictionary = {}
var fire_nodes: Array = []
var beacon_light: OmniLight3D
var beacon_glow: MeshInstance3D
var mill_wheel: Node3D
var caravan: Node3D
var mats: Dictionary = {}
var atlases: Dictionary = {}
var texture_cache: Dictionary = {}
var library = preload("res://scripts/sprite_library.gd").new()
var wilderness_art = preload("res://scripts/wilderness_sprites.gd").new()
var cottages: Array[Node3D] = []
var architecture = preload("res://scripts/architecture.gd").new()
var foraging: Dictionary = {}
var npc_anchors: Dictionary = {}
var tree_locations: Array[Vector2] = []
var road_footprints: Array[PackedVector2Array] = []
var forest = preload("res://scripts/forest_renderer.gd").new()
var stains: Array[Node3D] = []
var rocks: Array = []
var glow_nodes: Array = []
var glow_clock := 0.0
var grass_count := 0
var lush_grass = preload("res://scripts/lush_grass.gd").new()
var water_bounds: Array[Rect2] = []
var base_fires: Array = [Vector2(-3,22),Vector2(15,-109),Vector2(-106,-165),Vector2(122,-184),Vector2(-110,-245),Vector2(0,-331)]

func tex(path: String) -> Texture2D:
	if not texture_cache.has(path):
		texture_cache[path] = load("res://assets/"+path+".png")
	return texture_cache[path]

func atlas(path: String, cell: int, cols: int, rows: int) -> Texture2D:
	if path=="trees":
		return library.cell("res://assets/revision/tree-%d.png" % cell,0)
	if path=="props":
		return library.cell("res://assets/props.png",cell,cols,rows)
	var id := "%s_%d" % [path,cell]
	if atlases.has(id):
		return atlases[id]
	var t := tex(path)
	var a := AtlasTexture.new()
	a.atlas = t
	var size := Vector2(t.get_width()/cols,t.get_height()/rows)
	a.region = Rect2(Vector2(cell%cols,cell/cols)*size,size)
	if path=="npcs-cut":
		# The generated sheet is packed slightly above its nominal half-row line.
		var regions := [Rect2(63,8,298,482),Rect2(367,0,330,496),Rect2(763,0,337,496),Rect2(1148,0,340,497),Rect2(41,499,341,525),Rect2(400,503,322,521),Rect2(773,506,330,518),Rect2(1140,508,350,516)]
		a.region = regions[cell]
	if path=="combat":
		var starts := [0.0,0.257,0.480,0.735]
		var heights := [0.250,0.220,0.251,0.265]
		var row := cell/4
		a.region = Rect2(Vector2(cell%4*t.get_width()/4.0,starts[row]*t.get_height()),Vector2(t.get_width()/4.0,heights[row]*t.get_height()))
	if path=="combat" or path=="enemies":
		var cleaned := library.isolated_region("res://assets/"+path+".png",Rect2i(a.region))
		atlases[id] = cleaned
		return cleaned
	atlases[id] = a
	return a

func flat(color: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	if emission>0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func paint(kind: String) -> ShaderMaterial:
	if mats.has(kind):
		return mats[kind]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/painted.gdshader")
	m.set_shader_parameter("atlas",tex("ground" if kind=="ground" else "material"))
	m.set_shader_parameter("atlas_mode",kind!="ground")
	var tiles := {"stone":Vector2(0,0),"plaster":Vector2(1,0),"wood":Vector2(0,1),"roof":Vector2(1,1),"road":Vector2(0,0)}
	m.set_shader_parameter("tile",tiles.get(kind,Vector2.ZERO))
	if kind=="roof":
		m.set_shader_parameter("back_tile",Vector2.ZERO)
		m.set_shader_parameter("back_atlas",tex("revision/interior-materials"))
		m.set_shader_parameter("use_back_atlas",true)
	m.set_shader_parameter("scale",0.18 if kind=="ground" else 0.5)
	if kind=="road":
		m.set_shader_parameter("tint",Color("c6b596"))
		m.set_shader_parameter("scale",0.45)
	if kind=="wood":
		m.set_shader_parameter("tint",Color("b6a68d"))
	if kind=="plaster":
		m.set_shader_parameter("tint",Color("b9b29a"))
	mats[kind] = m
	return m

func block(pos: Vector3, size: Vector3, mat: Material, solid := true, parent: Node = self) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = mat
	parent.add_child(m)
	m.position = pos
	if solid:
		var b := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		c.shape = s
		b.add_child(c)
		m.add_child(b)
	return m

func cylinder(pos: Vector3, radius: float, height: float, mat: Material, parent: Node = self, solid := false, top := -1.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top<0 else top
	shape.height = height
	shape.radial_segments = 16
	m.mesh = shape
	m.material_override = mat
	parent.add_child(m)
	m.position = pos
	if solid:
		m.create_trimesh_collision()
	return m

func sprite(path: String, cell: int, cols: int, rows: int, at: Vector3, height: float, shaded := true, parent: Node = self) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = atlas(path,cell,cols,rows)
	s.pixel_size = height/s.texture.get_height()
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = shaded
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.alpha_scissor_threshold = 0.25
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(s)
	s.position = at+Vector3(0,height*0.5,0)
	if path=="props":
		if cell==0: s.add_to_group("grass_sprites")
		if cell==3: s.add_to_group("fruit_bush_sprites")
		s.position.y -= 0.035
		if shaded and parent==self and cell in [1,2]:
			rocks.append({"node":s,"extras":[],"mesh":null,"at":at,"height":height})
		if parent==self and cell in [1,2,6,7]:
			shadow(at,height*0.28)
	return s

func glow(at: Vector3, size: float, color: Color, parent: Node = self) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE*size
	n.mesh = q
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/glow.gdshader")
	m.set_shader_parameter("color",color)
	n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n)
	n.position = at
	glow_nodes.append(n)
	return n

func lamp(at: Vector3, energy := 1.4, radius := 9.0, parent: Node = self) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = Color("ffc174")
	l.light_energy = energy
	l.omni_range = radius
	l.distance_fade_enabled = true
	l.distance_fade_begin = 55
	l.distance_fade_length = 15
	parent.add_child(l)
	l.position = at
	glow(at,1.1,Color(1,0.55,0.16,0.8),parent)
	return l

func signpost(at: Vector2, text: String) -> void:
	var p := C.ground(at)
	block(p+Vector3(0,1.25,0),Vector3(0.15,2.5,0.15),paint("wood"))
	block(p+Vector3(0,2.2,0),Vector3(3.3,0.8,0.18),paint("wood"),false)
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/Cinzel.ttf")
	l.font_size = 40
	l.pixel_size = 0.005
	l.outline_size = 3
	l.modulate = Color("e3c38b")
	add_child(l)
	l.position = p+Vector3(0,2.2,0.12)

func build() -> void:
	seed(C.SEED)
	setup_sky()
	build_ground()
	for road in C.ROADS:
		build_road(road,5.0 if road==C.ROADS[0] else 3.6)
	build_inn()
	build_gate()
	build_mill()
	build_chapel()
	build_crypt()
	build_tower()
	build_caravan()
	build_marsh()
	build_grove()
	march_world.build(self)
	woods_world.build(self)
	settle_foundations()
	add_child(forest)
	preload("res://scripts/forest_caches.gd").register(self)
	preload("res://scripts/road_discoveries.gd").register(self)
	plant_forest()
	build_foraging()
	for id in C.OBJECTS:
		var d: Dictionary = C.OBJECTS[id]
		if id in ["nw_notice","nw_caseboard","nw_body","nw_vent","nw_gate","nw_heart","nw_ward_west","nw_ward_east","nw_ward_north","nw_vigil","ash_winch","ash_raisa","ash_pavel","ash_memorial","ash_bell","ash_names_mateo","ash_names_elias","ash_names_alina","ash_candle_bridge","ash_candle_orchard","ash_coach"]:
			# These are authored meshes, beds and votives, not extra standing stones.
			var marker := Sprite3D.new()
			add_child(marker)
			marker.position = C.ground(d.pos)
			objects[id] = marker
			continue
		var height := 1.4 if d.cell==6 else 2.0 if d.cell==7 else 0.8
		var node := sprite("props",d.cell,4,2,C.ground(d.pos),height,false)
		objects[id] = node
		if d.kind in ["quest","herb","moonwort","beacon"]:
			glow(Vector3(0,height*0.1,0),1.2,Color(0.65,0.7,0.3,0.25),node)
	for id in C.NPCS:
		var d: Dictionary = C.NPCS[id]
		var node := sprite("npcs-cut",d.cell,4,2,C.ground(d.pos),C.NPC_HEIGHTS[id],false)
		node.texture = library.npc(id)
		node.pixel_size = C.NPC_HEIGHTS[id]/node.texture.get_height()
		node.material_override = actor_material(node.texture)
		node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		npcs[id] = node
		shadow(C.ground(d.pos),0.7)
	for p in base_fires:
		add_fire(C.ground(p),true)
	signpost(Vector2(4,1),"NORTHWATCH\nâ†‘ OLD PINE ROAD")
	signpost(Vector2(-5,-117),"MILL â†   â†’ CHAPEL\nNORTHWATCH â†‘")
	signpost(Vector2(8,-277),"NORTHWATCH â†‘\nâ† LANTERN FEN")
	signpost(Vector2(94,-282),"KING'S CAIRN â†’\nâ† NORTHWATCH")
	apply_state()
	build_more_grass()
	ambient = preload("res://scripts/ambient_life.gd").new()
	ambient.game = game
	add_child(ambient)
	ambient.build()

func setup_sky() -> void:
	var we := WorldEnvironment.new()
	environment = Environment.new()
	var sky := Sky.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = tex("sky")
	sky.sky_material = panorama
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bdd0ba")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("899d8a")
	environment.fog_density = 0.0035
	environment.fog_sky_affect = 0.15
	we.environment = environment
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-33,-45,0)
	sun.light_color = Color("ffe0aa")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)

func build_ground() -> void:
	var data = preload("res://scripts/terrain.gd")
	for chunk_z in range(0,data.DEPTH-1,40):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for x in range(data.WIDTH-1):
			for z in range(chunk_z,mini(chunk_z+40,data.DEPTH-1)):
				var p := Vector2(data.MIN_X+x*data.STEP,data.MIN_Z+z*data.STEP)
				for offset in [Vector2.ZERO,Vector2(data.STEP,0),Vector2(0,data.STEP),Vector2(data.STEP,0),Vector2(data.STEP,data.STEP),Vector2(0,data.STEP)]:
					st.set_uv((p+offset)/5)
					st.add_vertex(C.ground(p+offset))
		st.generate_normals()
		var ground := MeshInstance3D.new()
		ground.mesh = st.commit()
		ground.material_override = paint("ground")
		add_child(ground)
		ground.create_trimesh_collision()

func build_road(points: Array, width: float) -> void:
	var data = preload("res://scripts/terrain.gd")
	var line := PackedVector2Array(points)
	var outlines := Geometry2D.offset_polyline(line,width*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)
	# Explicit small-radius discs close the flat/bevel cuts left by the offset
	# outline at endpoints and bends, including three-way road junctions.
	for point: Vector2 in points:
		var cap := PackedVector2Array()
		for i in range(24):
			var angle := i*TAU/24.0
			cap.append(point+Vector2(cos(angle),sin(angle))*width*.5)
		outlines.append(cap)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	for outline in outlines:
		road_footprints.append(outline)
		var bounds := Rect2(outline[0],Vector2.ZERO)
		for point in outline: bounds = bounds.expand(point)
		var begin_x := floori((bounds.position.x-data.MIN_X)/data.STEP)
		var end_x := ceili((bounds.end.x-data.MIN_X)/data.STEP)
		var begin_z := floori((bounds.position.y-data.MIN_Z)/data.STEP)
		var end_z := ceili((bounds.end.y-data.MIN_Z)/data.STEP)
		for x in range(maxi(0,begin_x),mini(data.WIDTH-1,end_x)):
			for z in range(maxi(0,begin_z),mini(data.DEPTH-1,end_z)):
				var p := Vector2(data.MIN_X+x*data.STEP,data.MIN_Z+z*data.STEP)
				for triangle in [PackedVector2Array([p,p+Vector2(data.STEP,0),p+Vector2(0,data.STEP)]),PackedVector2Array([p+Vector2(data.STEP,0),p+Vector2(data.STEP,data.STEP),p+Vector2(0,data.STEP)])]:
					for polygon in Geometry2D.intersect_polygons(triangle,outline):
						var indices := Geometry2D.triangulate_polygon(polygon)
						for index in indices:
							st.set_uv(polygon[index]/3)
							st.add_vertex(C.ground(polygon[index],.075))
							count += 1
	if count==0: return
	st.generate_normals()
	var road := MeshInstance3D.new()
	road.mesh = st.commit()
	road.material_override = paint("road")
	road.set_meta("terrain_conforming",true)
	road.add_to_group("road_surfaces")
	add_child(road)

func shadow(at: Vector3, radius: float) -> void:
	var m := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = 0.008
	disk.radial_segments = 24
	m.mesh = disk
	var mat := flat(Color(0.025,0.035,0.025,0.22))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visibility_range_end = 55
	add_child(m)
	m.position = at+Vector3(0,0.06,0)

func beam(a: Vector3, b: Vector3, width: float, parent: Node = self) -> void:
	var m := block((a+b)/2,Vector3(width,a.distance_to(b),width),paint("wood"),false,parent)
	m.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func roof(at: Vector3, width: float, depth: float, rise: float, parent: Node) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := width*0.5
	var d := depth*0.5
	var v := [Vector3(-w,0,-d),Vector3(0,rise,-d),Vector3(-w,0,d),Vector3(0,rise,-d),Vector3(0,rise,d),Vector3(-w,0,d),Vector3(0,rise,-d),Vector3(w,0,-d),Vector3(0,rise,d),Vector3(w,0,-d),Vector3(w,0,d),Vector3(0,rise,d),Vector3(-w,0,d),Vector3(0,rise,d),Vector3(w,0,d),Vector3(w,0,-d),Vector3(0,rise,-d),Vector3(-w,0,-d)]
	for i in range(0,12,3):
		st.add_vertex(v[i])
		st.add_vertex(v[i+1])
		st.add_vertex(v[i+2])
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = paint("roof")
	parent.add_child(m)
	m.position = at
	var gable := SurfaceTool.new()
	gable.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12,v.size()):
		gable.add_vertex(v[i])
	gable.generate_normals()
	var face := MeshInstance3D.new()
	face.mesh = gable.commit()
	face.material_override = parent.get_meta("wall_material",paint("plaster"))
	parent.add_child(face)
	face.position = at
	for z in [-d-0.04,d+0.04]:
		beam(at+Vector3(-w,0,z),at+Vector3(0,rise,z),0.2,parent)
		beam(at+Vector3(0,rise,z),at+Vector3(w,0,z),0.2,parent)
		beam(at+Vector3(-w,0,z),at+Vector3(w,0,z),0.2,parent)
		beam(at+Vector3(0,0,z),at+Vector3(0,rise,z),0.18,parent)
	beam(at+Vector3(0,rise,-d),at+Vector3(0,rise,d),0.18,parent)

func cottage(at: Vector2, width: float, depth: float, tall := 4.2, purpose := "home") -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.position = C.ground(at)
	n.set_meta("footprint",Vector2(width,depth))
	cottages.append(n)
	block(Vector3(0,0.15,0),Vector3(width+0.5,0.3,depth+0.5),paint("stone"),true,n)
	architecture.shell(self,n,width,depth,tall,purpose)
	roof(Vector3(0,tall,0),width+1.5,depth+1.6,2.8,n)
	architecture.hearth(self,n,width,depth,tall)
	architecture.lighting(self,n,depth,tall)
	cottage_ramp(n,width,depth)
	furnish_cottage(n,width,depth)
	return n

func room_clear(house: Node3D, local: Vector3) -> bool:
	var at := Vector2(house.position.x+local.x,house.position.z+local.z)
	for record in C.OBJECTS.values():
		if at.distance_to(record.pos)<2.7: return false
	return true

func furnish_cottage(house: Node3D, width: float, depth: float) -> void:
	architecture.furnish(self,house,width,depth)

func cottage_ramp(house: Node3D, width: float, depth: float) -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := minf(width*0.14,2.25)
	# Meet the plank floor at its edge; overlapping coplanar faces flicker here.
	for section in [Vector2(-0.175,0.35),Vector2(0.35,3.0)]:
		var front: float = depth/2+section.x
		var back: float = depth/2+section.y
		for p in [Vector2(-half,front),Vector2(half,front),Vector2(-half,back),Vector2(half,front),Vector2(half,back),Vector2(-half,back)]:
			var y := 0.31 if p.y<=depth/2+0.351 else C.height_at(house.position.x+p.x,house.position.z+p.y)-house.position.y+0.015
			mesh.set_uv(p/2)
			mesh.add_vertex(Vector3(p.x,y,p.y))
	mesh.generate_normals()
	var ramp := MeshInstance3D.new()
	ramp.mesh = mesh.commit()
	ramp.material_override = paint("stone")
	house.add_child(ramp)
	ramp.create_trimesh_collision()

func build_inn() -> void:
	var inn := cottage(Vector2(-14,30),13,12,5.0,"inn")
	# The roofed porch extends beyond the cottage's wall footprint.
	inn.set_meta("vegetation_annexes",[Rect2(-7.7,5.5,15.4,5.2)])
	# Porch and inn furniture.
	block(Vector3(0,0.25,8),Vector3(15,0.5,5),paint("wood"),true,inn)
	for x in [-6.0,6.0]:
		block(Vector3(x,2.0,9.8),Vector3(0.3,4,0.3),paint("wood"),true,inn)
	roof(Vector3(0,3.8,8),15.4,5,0.6,inn)
	for z in [-2.0,2.5]:
		block(Vector3(-3,1,z),Vector3(3,0.2,1.2),paint("wood"),true,inn)
		for x in [-4.0,-2.0]:
			block(Vector3(x,0.5,z),Vector3(0.15,1,0.8),paint("wood"),true,inn)
	block(Vector3(3,1,-3),Vector3(0.8,2,4),paint("wood"),true,inn)
	signpost(Vector2(-6,38),"THE WAYFARER'S\nREST")
	var smith := cottage(Vector2(16,20),7,8,3.5,"workshop")
	block(Vector3(-1,1,6),Vector3(1.6,0.4,0.8),flat(Color("505c5c")),true,smith)
	block(Vector3(-1,0.45,6),Vector3(0.5,0.9,0.5),paint("wood"),true,smith)
	lamp(C.ground(Vector2(14,25),2.2),1.4,10)
	# Low fences frame the safe yard without trapping the player.
	for x in range(-34,35,4):
		if abs(x)<5:
			continue
		var p := C.ground(Vector2(x,48))
		block(p+Vector3(0,0.8,0),Vector3(0.15,1.6,0.15),paint("wood"))
		block(p+Vector3(1.8,1,0),Vector3(3.7,0.12,0.12),paint("wood"))

func build_gate() -> void:
	for x in [-1.0,17.0]:
		var p := C.ground(Vector2(x,-94))
		cylinder(p+Vector3(0,3.2,0),2.5,6.4,paint("stone"),self,true)
		cylinder(p+Vector3(0,6.8,0),2.9,1.0,paint("stone"),self,false)
		for a in range(8):
			var angle := a*TAU/8
			block(p+Vector3(cos(angle)*2.5,7.6,sin(angle)*2.5),Vector3(0.8,1,0.8),paint("stone"),false)
	block(C.ground(Vector2(8,-94),6.7),Vector3(15,1.1,2.5),paint("stone"),false)
	# Wrecked cart, wheels and a cloth canopy.
	var cart := Node3D.new()
	add_child(cart)
	cart.position = C.ground(Vector2(0,-102))
	cart.rotation.y = -0.3
	block(Vector3(0,0.8,0),Vector3(2,0.25,3.2),paint("wood"),true,cart)
	for x in [-1.2,1.2]:
		for z in [-1.0,1.0]:
			var wheel := cylinder(Vector3(x,0.6,z),0.6,0.15,paint("wood"),cart)
			wheel.rotation.z = PI/2
	for i in range(10):
		var p := C.ground(Vector2(randf_range(-7,23),randf_range(-110,-85)))
		sprite("props",2,4,2,p,randf_range(0.7,1.6))

func build_mill() -> void:
	var mill := cottage(Vector2(-123,-166),11,12,5.5,"mill")
	mill_wheel = Node3D.new()
	mill.add_child(mill_wheel)
	mill_wheel.position = Vector3(-7.1,3,0)
	for i in range(12):
		var spoke := block(Vector3.ZERO,Vector3(0.25,6.2,0.3),paint("wood"),false,mill_wheel)
		spoke.rotation.x = i*PI/12
	for i in range(20):
		var a := i*TAU/20
		var paddle := block(Vector3(0,cos(a)*3,sin(a)*3),Vector3(1.6,0.6,0.2),paint("wood"),false,mill_wheel)
		paddle.rotation.x = -a
	water_ribbon()
	signpost(Vector2(-106,-149),"THE WIDOW'S MILL")

func build_chapel() -> void:
	var p := C.ground(Vector2(132,-211))
	block(p+Vector3(0,0.2,0),Vector3(16,0.4,26),paint("stone"))
	# A broad ramp joins the raised chapel floor to the road.
	var ramp := SurfaceTool.new()
	ramp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := C.ground(Vector2(129,-193),0.03)
	var b := C.ground(Vector2(135,-193),0.03)
	var c := Vector3(129,p.y+0.42,-198.5)
	var d := Vector3(135,p.y+0.42,-198.5)
	for point in [a,c,b,b,c,d]:
		ramp.add_vertex(point)
	ramp.generate_normals()
	var ramp_mesh := MeshInstance3D.new()
	ramp_mesh.mesh = ramp.commit()
	ramp_mesh.material_override = paint("stone")
	add_child(ramp_mesh)
	ramp_mesh.create_trimesh_collision()
	for x in [-7.0,7.0]:
		block(p+Vector3(x,2.5,-2),Vector3(0.7,5,20),paint("stone"))
		for z in [-10.0,-3.0,4.0]:
			cylinder(p+Vector3(x,3,z),0.6,6,paint("stone"),self,true)
	block(p+Vector3(0,3,-12),Vector3(15,6,0.8),paint("stone"))
	# Two wings leave a broad open front; only rear roof survives.
	for x in [-5.0,5.0]:
		block(p+Vector3(x,3,12),Vector3(4,6,0.7),paint("stone"))
	roof(p+Vector3(0,6,-7),15,10,4,self)
	for z in [-6.0,-1.0,4.0]:
		for x in [-3.8,3.8]:
			block(p+Vector3(x,0.65,z),Vector3(3.2,0.2,0.8),paint("wood"))
			block(p+Vector3(x,1.05,z-.32),Vector3(3.2,.85,.12),architecture.material(self,"wood",Color("968c76")),false)
			for dx in [-1.15,1.15]: block(p+Vector3(x+dx,.4,z),Vector3(.15,.5,.7),paint("wood"),false)
	block(p+Vector3(0,1,-9),Vector3(4,2,1.7),paint("stone"))
	block(p+Vector3(0,2.03,-8.85),Vector3(4.12,.04,1.8),architecture.textile(self,2,Color("c9bd9d")),false)
	for x in [-1.5,1.5]: architecture.candle(self,self,p+Vector3(x,2.07,-8.65))
	var window := cylinder(p+Vector3(0,4.5,-11.5),1.5,0.1,flat(Color("92b3c0"),0.8))
	window.rotation.x = PI/2
	block(p+Vector3(0,4.5,-11.35),Vector3(0.12,3.2,0.15),flat(Color("c8af72")),false)
	block(p+Vector3(0,4.5,-11.35),Vector3(3.2,0.12,0.15),flat(Color("c8af72")),false)
	for i in range(12):
		var pos := C.ground(Vector2(147+randf_range(0,12),-193-i*2.4))
		block(pos+Vector3(0,0.5,0),Vector3(0.7,1,0.25),paint("stone"))
	lamp(p+Vector3(0,2,-8),1.5,12)
	signpost(Vector2(120,-182),"CHAPEL OF\nTHE LAST BELL")

func build_tower() -> void:
	var p := C.ground(Vector2(0,-350))
	cylinder(p+Vector3(0,0.01,0),12,0.12,paint("stone"),self,true)
	# Rear watchtower; beacon courtyard remains accessible from the road.
	cylinder(p+Vector3(0,7,-9),4.5,14,paint("stone"),self,true)
	cylinder(p+Vector3(0,14.5,-9),5,1,paint("stone"))
	for i in range(12):
		var angle := i*TAU/12
		block(p+Vector3(cos(angle)*4.5,15.6,-9+sin(angle)*4.5),Vector3(1.2,1.5,1.2),paint("stone"))
	for x in [-12.0,12.0]:
		block(p+Vector3(x,1.5,4),Vector3(1,3,14),paint("stone"))
	beacon_light = lamp(C.ground(Vector2(0,-344),3),0,24)
	beacon_glow = glow(C.ground(Vector2(0,-344),2),6,Color(1,0.6,0.15,0))
	signpost(Vector2(8,-324),"NORTHWATCH\nTHE LAST ROAD")

func build_crypt() -> void:
	# A deliberately authored interior beyond the valley, reached by a stair transition.
	var center := Vector2(130,-391)
	block(C.ground(center,0.0),Vector3(14,0.3,60),paint("stone"))
	block(C.ground(center,5.1),Vector3(16,0.4,61),paint("stone"))
	for x in [123.0,137.0]:
		block(C.ground(Vector2(x,-372.5),2.5),Vector3(1,5,23),paint("stone"))
		block(C.ground(Vector2(x,-410.5),2.5),Vector3(1,5,21),paint("stone"))
	for z in [-361.0,-421.0]:
		block(C.ground(Vector2(130,z),2.5),Vector3(15,5,1),paint("stone"))
	for x in [116.0,144.0]:
		block(C.ground(Vector2(x,-394),0.0),Vector3(18,0.3,18),paint("stone"))
		block(C.ground(Vector2(x,-394),5.1),Vector3(18,0.4,22),paint("stone"))
		for z in [-384.0,-404.0]:
			block(C.ground(Vector2(x,z),2.5),Vector3(18,5,1),paint("stone"))
		block(C.ground(Vector2(107 if x<130 else 153,-394),2.5),Vector3(1,5,20),paint("stone"))
	for z in range(-414,-366,8):
		for x in [125.0,135.0]:
			cylinder(C.ground(Vector2(x,z),2.5),0.4,5,paint("stone"),self,true)
		lamp(C.ground(Vector2(130,z),3.8),1.0,9)
	for p in [Vector2(115,-391),Vector2(145,-395),Vector2(130,-417)]:
		lamp(C.ground(p,2),1.0,9)

func build_marsh() -> void:
	for i in range(22):
		var p := Vector2(randf_range(-151,-88),randf_range(-266,-220))
		if p.distance_to(Vector2(-117,-242))<5:
			continue
		water_pond(p,randf_range(2,5))
		for j in range(3):
			var at := p+Vector2(randf_range(-5,5),randf_range(-3,3))
			sprite("props",4,4,2,C.ground(at),randf_range(1.5,2.8))
	for i in range(8):
		glow(C.ground(Vector2(-140+i*5,-250+sin(i)*6),1),0.7,Color(0.4,0.9,0.7,0.7))
	block(C.ground(Vector2(-117,-241),0.1),Vector3(5,0.2,5),paint("wood"),false)

func build_caravan() -> void:
	caravan = Node3D.new()
	add_child(caravan)
	caravan.position = C.ground(Vector2(12,-326))
	caravan.rotation.y = -0.25
	block(Vector3(0,1.1,0),Vector3(2.8,0.3,5),paint("wood"),true,caravan)
	for x in [-1.6,1.6]:
		for z in [-1.6,1.6]:
			var wheel := cylinder(Vector3(x,0.8,z),0.8,0.2,paint("wood"),caravan)
			wheel.rotation.z = PI/2
			for i in range(4):
				var spoke := block(Vector3(x,0.8,z),Vector3(0.23,1.65,0.12),flat(Color("3f433c")),false,caravan)
				spoke.rotation.x = i*PI/4
	for x in [-1.3,1.3]:
		block(Vector3(x,1.7,0),Vector3(0.16,1.1,5),paint("wood"),true,caravan)
		for z in [-2.2,0.0,2.2]:
			beam(Vector3(x,1.3,z),Vector3(x,3.4,z),0.13,caravan)
	roof(Vector3(0,3.3,0),3.4,5.6,1,caravan)
	for x in [-0.8,0.6]:
		sprite("props",6,4,2,Vector3(x,1.2,0),1.2,false,caravan)
	lamp(Vector3(1.5,2.8,2.4),1.5,10,caravan)
	caravan.hide()

func build_grove() -> void:
	var hut := cottage(Vector2(-84,-69),7,7,3.2)
	hut.rotation.y = 0.3
	for i in range(14):
		var angle := i*TAU/14
		var p := Vector2(160+cos(angle)*5,-311+sin(angle)*5)
		sprite("props",7,4,2,C.ground(p),1.6)

func plant_forest() -> void:
	var march_rng := RandomNumberGenerator.new()
	march_rng.seed = 731940
	var woods_rng := RandomNumberGenerator.new()
	woods_rng.seed = 913074
	for i in range(4400):
		var p := Vector2(randf_range(-230,230),randf_range(-418,80)) if i<1250 else Vector2(march_rng.randf_range(-230,230),march_rng.randf_range(-1005,-435))
		if i>=2600: p = Vector2(woods_rng.randf_range(-230,230),woods_rng.randf_range(-1825,-1040))
		if p.x>98 and p.x<166 and p.y<-354 and p.y> -430:
			continue
		if C.distance_to_road(p)<7:
			continue
		if not outside_buildings(p,2.0):
			continue
		var near_site := false
		for object_data in C.OBJECTS.values():
			if p.distance_to(object_data.pos)<4.0: near_site = true
		for s in C.SITES.values():
			if p.distance_to(s.pos)<float(s.get("clearing",26 if s.name=="Wayfarer's Rest" else 20)):
				near_site = true
		if near_site:
			continue
		var h: float = randf_range(10,19) if i<1250 else march_rng.randf_range(10,19) if i<2600 else woods_rng.randf_range(12,23)
		if preload("res://scripts/weeper_sites.gd").reserved(p): continue
		var tree := sprite("trees",i%4,4,1,C.ground(p,-0.15),h)
		tree_locations.append(p)
		tree.flip_h = i%3==0
		tree.modulate = Color("c4c9a6") if i%4==1 else Color("b7c6bd")
		tree.visibility_range_end = 235
		wind(tree,0.13,0.48)
		var proxy := static_tree_shadow(tree)
		forest.register_tree(tree,proxy,p,h,i%4,i)
		if true:
			var b := StaticBody3D.new()
			var hit := CollisionShape3D.new()
			var shape := CylinderShape3D.new()
			shape.radius = [0.65,0.42,0.50,0.8][i%4]*h/14.0
			b.add_to_group("tree_trunks")
			shape.height = 3
			hit.shape = shape
			b.add_child(hit)
			add_child(b)
			b.position = C.ground(p,1.5)
	for i in range(680):
		var road: Array = C.ROADS[i%C.ROADS.size()]
		var j := randi_range(0,road.size()-2)
		var p: Vector2 = road[j].lerp(road[j+1],randf())+Vector2(randf_range(-12,12),randf_range(-8,8))
		if C.distance_to_road(p)<3.3:
			continue
		if not outside_buildings(p,1.5):
			continue
		var cell := i%5
		var node := sprite("props",cell,4,2,C.ground(p),randf_range(0.7,1.8))
		node.visibility_range_end = 85
		node.flip_h = i%2==0
		if cell==2:
			node.modulate = Color("b7c4b1")
		if cell in [0,3,4]:
			wind(node,0.035,0.18)
	# Small, unobtrusive ground cover never intersects an authored doorway or floor.
	for i in range(260):
		var road: Array = C.ROADS[i%C.ROADS.size()]
		var j := i%(road.size()-1)
		var p: Vector2 = road[j].lerp(road[j+1],randf())+Vector2(randf_range(-10,10),randf_range(-8,8))
		if C.distance_to_road(p)<2.8 or not outside_buildings(p,1.2):
			continue
		var plant := sprite("props",0 if i%2 else 3,4,2,C.ground(p,-0.02),randf_range(0.2,0.45))
		plant.visibility_range_end = 45
		wind(plant,0.02,0.05)

func add_fire(at: Vector3, permanent := false) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.position = at
	for i in range(8):
		var a := i*TAU/8
		var stone := cylinder(Vector3(cos(a)*0.65,0.1,sin(a)*0.65),0.2,0.2,paint("stone"),n)
		stone.scale.y = 0.7
	for i in range(3):
		var log := block(Vector3(0,0.15,0),Vector3(1.15,0.17,0.18),paint("wood"),false,n)
		log.rotation.y = i*PI/3
	var particles := GPUParticles3D.new()
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	particles.amount = 30
	particles.lifetime = 1.25
	particles.preprocess = 1.25
	particles.visibility_aabb = AABB(Vector3(-2,-1,-2),Vector3(4,5,4))
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	motion.emission_sphere_radius = 0.22
	motion.direction = Vector3.UP
	motion.spread = 14
	motion.initial_velocity_min = 0.5
	motion.initial_velocity_max = 1.3
	motion.gravity = Vector3(0,0.2,0)
	motion.scale_min = 0.3
	motion.scale_max = 0.7
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,0.9,0.4,0.9),Color(1,0.3,0.04,0.6),Color(0.6,0.07,0.01,0)])
	gradient.offsets = PackedFloat32Array([0,0.55,1])
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	motion.color_ramp = ramp
	particles.process_material = motion
	var flame := QuadMesh.new()
	flame.size = Vector2(0.9,1.3)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.vertex_color_use_as_albedo = true
	var radial := GradientTexture2D.new()
	var edge := Gradient.new()
	edge.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	radial.gradient = edge
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(0.5,0.5)
	radial.fill_to = Vector2(1,0.5)
	fm.albedo_texture = radial
	flame.material = fm
	particles.draw_pass_1 = flame
	n.add_child(particles)
	particles.position.y = 0.3
	glow(Vector3(0,0.6,0),2.8,Color(1,0.4,0.08,0.8),n)
	lamp(Vector3(0,1,0),2.3,12,n)
	fire_nodes.append({"node":n,"permanent":permanent})
	return n

func apply_state() -> void:
	march_world.apply(self)
	apply_foraging()
	for id in objects:
		objects[id].visible = not game.state.taken.has(id)
		if id=="beacon":
			objects[id].visible = true
	for id in npcs:
		npcs[id].visible = id!="merchant" or game.state.flags.won
		npcs[id].position = npc_ground(C.NPCS[id].pos,C.NPC_HEIGHTS[id])
	if game.state.flags.won:
		npcs.ilya.position = npc_ground(Vector2(-7,-332),C.NPC_HEIGHTS.ilya)
		if game.state.flags.courier_done:
			npcs.courier.position = npc_ground(Vector2(6,-327),C.NPC_HEIGHTS.courier)
	elif game.state.flags.oil and game.state.flags.relic and game.state.flags.scout:
		npcs.ilya.position = npc_ground(Vector2(-7,-332),C.NPC_HEIGHTS.ilya)
	for id in npcs:
		npc_anchors[id] = npcs[id].position
		apply_npc_appearance(id)
	woods_world.apply(self)
	caravan.visible = game.state.flags.won
	for id in ["rune_root","rune_flame","rune_bell"]:
		objects[id].modulate = Color("a6e8df") if game.state.flags.get(id.trim_prefix("rune_"),false) else Color.WHITE
	beacon_light.light_energy = 5 if game.state.flags.beacon_lit else 0
	var m: ShaderMaterial = beacon_glow.material_override
	m.set_shader_parameter("color",Color(1,0.6,0.15,0.8 if game.state.flags.beacon_lit else 0))
	# Reconstruct portable fires from the coordinated save.
	for record in fire_nodes.duplicate():
		if not record.permanent:
			record.node.queue_free()
			fire_nodes.erase(record)
	for record in game.state.fires:
		if record.fuel>0:
			add_fire(Vector3(record.position[0],record.position[1],record.position[2]))

func tick(dt: float) -> void:
	if ambient: ambient.tick(dt)
	# Cosmetic decay follows simulation time, so menus and field notes freeze it.
	for index in range(stains.size()-1,-1,-1):
		var stain := stains[index]
		var age: float = stain.get_meta("age",0.0)+dt
		stain.set_meta("age",age)
		if age>=55.0:
			stains.remove_at(index)
			stain.queue_free()
		else:
			stain.material_override.set_shader_parameter("opacity",1.0-smoothstep(40.0,55.0,age))
	glow_clock -= dt
	if glow_clock<=0 and game.camera:
		glow_clock = 0.15
		glow_nodes = glow_nodes.filter(func(node): return is_instance_valid(node))
		for node in glow_nodes:
			var material: ShaderMaterial = node.material_override
			material.set_shader_parameter("occlusion",1.0 if game.line_clear(game.camera.global_position,node.global_position) else 0.0)
	for id in npcs:
		var npc: Sprite3D = npcs[id]
		var breath := sin(game.state.elapsed*1.9+float(id.hash()%100)*0.13)*0.006
		npc.scale = Vector3(1.0-breath*0.3,1.0+breath,1.0)
		npc.position = npc_anchors[id]+Vector3(0,breath*C.NPC_HEIGHTS[id]*0.5,0)
		apply_npc_appearance(id)
	if mill_wheel:
		mill_wheel.rotation.x += dt*0.24
	var hour: float = game.state.day_clock
	var solar := preload("res://scripts/godrays.gd").solar_direction(hour)
	if solar.y>0:
		sun.look_at(sun.global_position-solar,Vector3.UP)
	else:
		sun.rotation_degrees = Vector3(-33,-45,0)
	sun.light_color = Color("ffe0aa").lerp(Color("ffb36b"),preload("res://scripts/godrays.gd").golden_hour(hour))
	var darkness := smoothstep(17.0,20.5,hour) if hour>=12 else 1.0-smoothstep(4.5,7.0,hour)
	var storm: float = game.state.weather.clouds
	var flash: float = game.state.weather.flash if game.visuals.values.lightning else 0.0
	sun.light_energy = lerpf(0.85,0.10,darkness)*(1.0-storm*0.65)+flash*0.9
	environment.ambient_light_energy = lerpf(0.55,0.40,darkness)*(1.0-storm*0.25)+flash*0.30
	environment.ambient_light_color = Color("bdd0ba").lerp(Color("7e9fae"),darkness)
	environment.fog_light_color = Color("6d8f9b").lerp(Color("273f52"),darkness)
	environment.background_energy_multiplier = lerpf(0.85,0.19,darkness)
	environment.fog_density = lerpf(0.0035,0.005,darkness)+game.state.weather.rain*0.002
	if game.in_crypt():
		sun.light_energy = 0.03
		environment.ambient_light_energy = 0.22
		environment.fog_density = 0.007
		environment.fog_light_color = Color("253d3a")
	RenderingServer.global_shader_parameter_set("road_fog_colour",environment.fog_light_color)
	RenderingServer.global_shader_parameter_set("road_fog_density",environment.fog_density)
	RenderingServer.global_shader_parameter_set("road_daylight",0.15 if game.in_crypt() else (1.0-darkness)*(1.0-storm*0.30))

func is_blinking(id: String, time: float) -> bool:
	return fposmod(time+float(id.hash()%83)*0.17,4.0+float(id.hash()%13)*0.12)<0.14

func outside_buildings(p: Vector2, margin := 0.0) -> bool:
	for cottage_node in cottages:
		var local := cottage_node.to_local(C.ground(p))
		var size: Vector2 = cottage_node.get_meta("footprint")
		if absf(local.x)<size.x/2+margin and absf(local.z)<size.y/2+margin:
			return false
		for annex in cottage_node.get_meta("vegetation_annexes",[]):
			if annex.grow(margin).has_point(Vector2(local.x,local.z)): return false
	if p.x>121-margin and p.x<141+margin and p.y< -197+margin and p.y> -225-margin:
		return false
	if p.x>100 and p.x<165 and p.y< -355 and p.y> -430:
		return false
	return true

func settle_foundations() -> void:
	for cottage_node in cottages:
		var size: Vector2 = cottage_node.get_meta("footprint")
		var bottom := cottage_node.position.y-0.3
		for x in [-size.x/2,size.x/2]:
			for z in [-size.y/2,size.y/2]:
				var corner := cottage_node.to_global(Vector3(x,0,z))
				bottom = minf(bottom,C.height_at(corner.x,corner.z)-0.25)
		var depth := cottage_node.position.y-bottom
		block(Vector3(0,-depth/2+0.1,0),Vector3(size.x+0.48,depth+0.2,size.y+0.48),paint("stone"),false,cottage_node)

func wind(s: Sprite3D, amplitude: float, crown_start: float) -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/foliage.gdshader")
	m.set_shader_parameter("image",s.texture)
	m.set_shader_parameter("amplitude",amplitude)
	m.set_shader_parameter("phase",s.position.x*0.2+s.position.z*0.13)
	m.set_shader_parameter("crown_start",crown_start)
	s.material_override = m

func static_tree_shadow(s: Sprite3D) -> MeshInstance3D:
	var proxy := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(s.texture.get_width(),s.texture.get_height())*s.pixel_size
	proxy.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_texture = s.texture
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	proxy.material_override = m
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(proxy)
	proxy.position = s.position
	proxy.rotation.y = PI/4
	proxy.visibility_range_end = 85
	return proxy

func build_foraging() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17761108
	var berries := [Vector2(-5,3),Vector2(-20,-29),Vector2(-66,-57),Vector2(-42,-132),Vector2(43,-163),Vector2(18,-255)]
	for i in range(berries.size()):
		var p: Vector2 = berries[i]
		var node := sprite("props",3,4,2,C.ground(p,-0.03),1.1)
		wind(node,0.035,0.2)
		foraging["berries_%02d" % i] = {"node":node,"pos":p,"kind":"berries","name":"Wild berries Â· pick fruit"}
	var count := 0
	for i in range(0,tree_locations.size(),4):
		var p := tree_locations[i]+Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))
		if C.distance_to_road(p)>35 or not outside_buildings(p,1.2):
			continue
		var edible := rng.randf()>0.28
		var direction := Vector2(sin(float(i)*2.39996),cos(float(i)*2.39996))
		for attempt in range(32):
			p = tree_locations[i]+direction*(4.5+float(attempt)*0.3)
			var clear := outside_buildings(p,1.0)
			for trunk in tree_locations:
				if p.distance_to(trunk)<3.8:
					clear = false
			if clear:
				break
			direction = direction.rotated(0.7)
		var node := Sprite3D.new()
		node.texture = library.cell("res://assets/revision/forage.png",0 if edible else 1,2,1)
		node.pixel_size = rng.randf_range(0.22,0.4)/node.texture.get_height()
		node.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		node.alpha_scissor_threshold = 0.3
		add_child(node)
		node.position = C.ground(p,node.pixel_size*node.texture.get_height()/2-0.02)
		node.visibility_range_end = 40
		foraging["mushroom_%03d" % count] = {"node":node,"pos":p,"kind":"mushrooms" if edible else "toadstools","name":"Coppercap Â· edible" if edible else "Widow's bonnet Â· INEDIBLE"}
		count += 1

func apply_foraging() -> void:
	for id in foraging:
		var record: Dictionary = foraging[id]
		var picked: bool = game.state.taken.has(id)
		record.node.visible = not picked

func surface_height(at: Vector3) -> float:
	var start := Vector3(at.x,maxf(at.y+2,C.height_at(at.x,at.z)+2),at.z)
	var end := Vector3(at.x,C.height_at(at.x,at.z)-5,at.z)
	var result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1))
	return result.position.y+0.02 if not result.is_empty() else C.height_at(at.x,at.z)

func contact_step_family(at: Vector3) -> String:
	var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*1.3,1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or absf(hit.position.y-at.y)>.4: return ""
	var node: Node = hit.collider
	while node and node!=self:
		if node.has_meta("footstep_family"): return node.get_meta("footstep_family")
		node = node.get_parent()
	return ""

func impact(at: Vector3, spectral: bool, heavy: bool) -> void:
	var color := Color("22c9ef") if spectral else Color("e50927")
	var large: bool = game.visuals.values.blood_size==1
	var particles := GPUParticles3D.new()
	particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = (100 if heavy else 70) if large else (36 if heavy else 24)
	particles.lifetime = 0.8
	var motion := ParticleProcessMaterial.new()
	motion.direction = Vector3.UP
	motion.spread = 90
	motion.initial_velocity_min = 1.5
	motion.initial_velocity_max = (7.5 if heavy else 5.5) if large else 3.2
	motion.gravity = Vector3(0,-9,0)
	motion.particle_flag_align_y = true
	motion.scale_min = 0.22
	motion.scale_max = 0.70
	particles.process_material = motion
	var drop := QuadMesh.new()
	drop.size = Vector2(0.34,0.85) if large else Vector2(0.12,0.28)
	var liquid := ShaderMaterial.new()
	liquid.shader = load("res://shaders/liquid.gdshader")
	liquid.set_shader_parameter("ink",color)
	drop.material = liquid
	particles.draw_pass_1 = drop
	add_child(particles)
	particles.add_to_group("combat_fx")
	particles.position = at
	particles.emitting = true
	get_tree().create_timer(1.6,false).timeout.connect(particles.queue_free)
	var stain := MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := (1.9 if heavy else 1.35) if large else 0.45
	var base_height := surface_height(at)
	var edge: Array[Vector3] = []
	for i in range(16):
		var angle := i*TAU/16
		edge.append(Vector3(cos(angle),0,sin(angle))*radius*1.2)
	for i in range(edge.size()):
		edge[i].y = surface_height(Vector3(at.x+edge[i].x,at.y,at.z+edge[i].z))-base_height+0.065
	for i in range(16):
		for point in [Vector3(0,0.065,0),edge[i],edge[(i+1)%16]]:
			surface.set_uv(Vector2(point.x,point.z)/(radius*2)+Vector2(0.5,0.5))
			surface.add_vertex(point)
	surface.generate_normals()
	stain.mesh = surface.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/splatter.gdshader")
	mat.set_shader_parameter("ink",Color("18bfdc") if spectral else Color("b60921"))
	mat.set_shader_parameter("variation",randf()*TAU)
	stain.material_override = mat
	stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stain.visibility_range_end = 60
	add_child(stain)
	stain.position = Vector3(at.x,base_height,at.z)
	stains.append(stain)
	if stains.size()>100:
		stains.pop_front().queue_free()

func clear_impacts() -> void:
	for stain in stains:
		if is_instance_valid(stain):
			stain.queue_free()
	stains.clear()
	for node in get_tree().get_nodes_in_group("combat_fx"):
		node.queue_free()

func npc_floor_height(p: Vector2) -> float:
	var height := C.height_at(p.x,p.y)
	# Roads have no separate collider, but their painted surface sits above terrain.
	for footprint in road_footprints:
		if Geometry2D.is_point_in_polygon(p,footprint): return height+.075
	return height

func apply_npc_appearance(id: String) -> void:
	var npc: Sprite3D = npcs[id]
	var private_pose: bool = game.relationship.appearance_active(id)
	npc.texture = game.relationship.portrait_texture(id) if private_pose else library.npc(id,is_blinking(id,game.state.elapsed))
	if not private_pose and id=="courier" and game.state.flags.courier_done:
		npc.texture = library.cell("res://assets/revision/npc-courier-recovered.png",0)
	npc.pixel_size = C.NPC_HEIGHTS[id]/npc.texture.get_height()
	(npc.material_override as ShaderMaterial).set_shader_parameter("image",npc.texture)

func npc_portrait(id: String, blink := false) -> Texture2D:
	if id=="courier" and game.state.flags.courier_done:
		return library.cell("res://assets/revision/npc-courier-recovered.png",0)
	return library.portrait(id,blink)

func npc_ground(p: Vector2, height := 1.90) -> Vector3:
	var floor_height := npc_floor_height(p)
	for offset in [Vector2(-0.42,0),Vector2(0.42,0),Vector2(0,-0.35),Vector2(0,0.35)]:
		floor_height = maxf(floor_height,npc_floor_height(p+offset))
	var at := Vector3(p.x,floor_height+height*0.5+0.015,p.y)
	if absf(p.x+117)<2.5 and absf(p.y+241)<2.5:
		at.y = maxf(at.y,C.height_at(-117,-241)+0.22+height*0.5)
	return at

func water_material() -> ShaderMaterial:
	if mats.has("water"):
		return mats.water
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
varying vec3 pos;
void vertex(){pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){float w=sin(pos.x*2.5+TIME)*cos(pos.z*1.7-TIME); NORMAL=normalize(NORMAL+vec3(w*0.12,0.0,cos(pos.z*3.0+TIME)*0.1)); float f=pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),3.0); ALBEDO=mix(vec3(0.09,0.22,0.22),vec3(0.48,0.64,0.65),f*0.75)+w*0.012; ROUGHNESS=0.16; SPECULAR=0.85;}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	mats.water = material
	return material

func water_surface(points: Array[Vector3]) -> void:
	var bounds := Rect2(Vector2(points[0].x,points[0].z),Vector2.ZERO)
	for point in points: bounds = bounds.expand(Vector2(point.x,point.z))
	water_bounds.append(bounds.grow(.6))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in points:
		surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = water_material()
	add_child(mesh)

func water_ribbon() -> void:
	var points: Array[Vector3] = []
	for i in range(190):
		var z0 := -92.0-float(i)
		var x0 := -135.0+sin(float(i-51)*0.125)*2.0+sin(float(i-51)*0.025)*1.5
		var x1 := -135.0+sin(float(i-50)*0.125)*2.0+sin(float(i-50)*0.025)*1.5
		# The diverted millrace bends continuously underneath the wheel at x=-130.1.
		x0 = lerpf(x0,-130.3,exp(-pow((z0+166.0)/9.0,2.0)))
		x1 = lerpf(x1,-130.3,exp(-pow((z0+165.0)/9.0,2.0)))
		var a := C.ground(Vector2(x0-1.7,z0),0.1)
		var b := C.ground(Vector2(x0+1.7,z0),0.1)
		var c := C.ground(Vector2(x1-1.7,z0-1),0.1)
		var d := C.ground(Vector2(x1+1.7,z0-1),0.1)
		points.append_array([a,b,c,b,d,c])
	water_surface(points)

func water_pond(p: Vector2, radius: float) -> void:
	var points: Array[Vector3] = []
	for ring in range(4):
		for i in range(48):
			var corners: Array[Vector3] = []
			for corner in [Vector2(ring,i),Vector2(ring+1,i),Vector2(ring,i+1),Vector2(ring+1,i+1)]:
				var angle: float = corner.y*TAU/48.0
				corners.append(C.ground(p+Vector2(cos(angle),sin(angle)*0.6)*radius*(1.0+0.22*sin(angle*3.0+p.x)+0.13*cos(angle*5.0+p.y))*corner.x/4.0,0.065))
			for index in [0,2,1,1,2,3]:
				points.append(corners[index])
	water_surface(points)

func corpse_smoke(at: Vector3) -> void:
	var puff := GPUParticles3D.new()
	puff.process_mode = Node.PROCESS_MODE_PAUSABLE
	puff.one_shot = true
	puff.amount = 22
	puff.lifetime = 0.8
	puff.explosiveness = 1.0
	var motion := ParticleProcessMaterial.new()
	motion.direction = Vector3.UP
	motion.spread = 75
	motion.initial_velocity_min = 0.3
	motion.initial_velocity_max = 1.1
	motion.gravity = Vector3(0,0.3,0)
	motion.scale_min = 0.15
	motion.scale_max = 0.5
	var gradient := Gradient.new()
	gradient.set_color(0,Color(0.5,0.56,0.55,0.5))
	gradient.set_color(1,Color(0.5,0.56,0.55,0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	motion.color_ramp = ramp
	puff.process_material = motion
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	puff.draw_pass_1 = sphere
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(puff)
	puff.add_to_group("combat_fx")
	puff.position = at+Vector3(0,0.3,0)
	puff.emitting = true
	get_tree().create_timer(1.5,false).timeout.connect(puff.queue_free)

func actor_material(image: Texture2D) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/actor.gdshader")
	material.set_shader_parameter("image",image)
	return material

func apply_rock_mode(mode: int) -> void:
	# Rocks retain the original painted billboards independently of tree style.
	mode = 3
	for record in rocks:
		var node: Sprite3D = record.node
		var yaw: float = fposmod(node.position.x*0.73+node.position.z*0.17,TAU)
		node.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if mode==3 else BaseMaterial3D.BILLBOARD_DISABLED
		node.rotation.y = yaw
		if mode==0 and not record.mesh:
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var rng := RandomNumberGenerator.new()
			rng.seed = int(absf(node.position.x*711+node.position.z*91))
			forest.blob(surface,Vector3(0,0.38,0),Vector3(0.66,0.50,0.52),Color.WHITE,rng)
			surface.generate_normals()
			var rock := MeshInstance3D.new()
			rock.mesh = surface.commit()
			rock.material_override = paint("stone")
			add_child(rock)
			rock.position = record.at
			rock.scale = Vector3.ONE*record.height
			rock.rotation.y = yaw
			record.mesh = rock
		if mode==1 and record.extras.is_empty():
			for angle in [PI/3,2*PI/3]:
				var extra := node.duplicate() as Sprite3D
				add_child(extra)
				extra.rotation.y = yaw+angle
				record.extras.append(extra)
		node.visible = mode!=0
		if record.mesh:
			record.mesh.visible = mode==0
		for extra in record.extras:
			extra.visible = mode==1

func build_more_grass() -> void:
	add_child(lush_grass)
	lush_grass.prepare(self)
	var rng := RandomNumberGenerator.new()
	rng.seed = 193774
	var transforms: Array[Transform3D] = []
	var image := library.cell("res://assets/props.png",0,4,2)
	for i in range(10500):
		var road: Array = C.ROADS[i%C.ROADS.size()]
		var segment := rng.randi_range(0,road.size()-2)
		var p: Vector2 = road[segment].lerp(road[segment+1],rng.randf())+Vector2(rng.randf_range(-30,30),rng.randf_range(-24,24))
		if C.distance_to_road(p)<3.2 or not outside_buildings(p,2.0):
			continue
		var blocked := false
		for water in water_bounds:
			if water.has_point(p): blocked = true
		for record in C.OBJECTS.values():
			if p.distance_to(record.pos)<2.2: blocked = true
		if blocked or not lush_grass.clear_of_items(p): continue
		var height := rng.randf_range(0.28,0.80)
		var width := height*image.get_width()/image.get_height()
		transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(width,height,1)),C.ground(p,height*0.5-0.035)))
	var batch := MultiMeshInstance3D.new()
	batch.name = "DenseGroundCover"
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/foliage.gdshader")
	material.set_shader_parameter("image",image)
	material.set_shader_parameter("amplitude",0.10)
	material.set_shader_parameter("crown_start",0.05)
	material.set_shader_parameter("max_distance",100.0)
	mesh.material = material
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()/4
	for i in range(instances.instance_count):
		instances.set_instance_transform(i,transforms[i*4])
	batch.multimesh = instances
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	grass_count = instances.instance_count
	build_meadow_blades(transforms,rng)
	lush_grass.set_enabled(game.visuals.values.dense_grass)

func build_meadow_blades(transforms: Array[Transform3D], rng: RandomNumberGenerator) -> void:
	var mesh: ArrayMesh = lush_grass.tuft_mesh()
	var patches: Dictionary = {}
	for transform in transforms:
		for copy in range(2):
			var p := Vector2(transform.origin.x,transform.origin.z)+Vector2(rng.randf_range(-.45,.45),rng.randf_range(-.45,.45))
			if not lush_grass.clear_of_items(p): continue
			var key := Vector2i(floori(p.x/64),floori(p.y/64))
			if not patches.has(key): patches[key] = []
			var height := transform.basis.y.length()*rng.randf_range(.75,1.15)
			patches[key].append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*height),C.ground(p,-.015)))
	for key in patches:
		var view := MultiMeshInstance3D.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = patches[key].size()
		for index in range(multi.instance_count): multi.set_instance_transform(index,patches[key][index])
		view.multimesh = multi
		view.visibility_range_end = 80
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.add_to_group("meadow_grass")
		add_child(view)
		grass_count += multi.instance_count
