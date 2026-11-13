extends Node3D

const C = preload("res://scripts/content.gd")
const BIN := 8.0
const TILE := 32.0
const SPACING := .8
# Include the full leaning/swaying tuft footprint, not just its root point.
const FOOTPRINT := 1.2
var circles: Dictionary = {}
var rectangles: Dictionary = {}
var collectible_clearings: Array[Vector3] = []
var instance_count := 0
var built := false
var build_ms := 0

func prepare(w: Node3D) -> void:
	name = "LushGrass"
	for record in w.foraging.values():
		add_circle(record.pos,2.3 if record.kind=="berries" else 1.3,true)
	for bush in get_tree().get_nodes_in_group("fruit_bush_sprites"):
		add_circle(Vector2(bush.position.x,bush.position.z),2.3)
	for record in C.OBJECTS.values():
		add_circle(record.pos,1.9 if record.kind=="wood" else 1.5,record.kind=="wood")
	for record in C.NPCS.values(): add_circle(record.pos,1.6)
	for fire in w.base_fires: add_circle(fire,1.7)
	for cottage in w.cottages:
		var size: Vector2 = cottage.get_meta("footprint")
		var bounds := Rect2(Vector2(cottage.position.x,cottage.position.z),Vector2.ZERO)
		for x in [-size.x/2,size.x/2]:
			for z in [-size.y/2,size.y/2]:
				var corner: Vector3 = cottage.to_global(Vector3(x,0,z))
				bounds = bounds.expand(Vector2(corner.x,corner.z))
		add_rectangle(bounds.grow(2))
	add_rectangle(Rect2(120,-226,22,30)) # Ruined chapel.
	add_rectangle(Rect2(99,-431,67,77)) # Separate underchapel area.
	add_rectangle(Rect2(-22,34,16,8)) # Inn porch.
	for bounds in w.water_bounds: add_rectangle(bounds.grow(1))
	# Existing decorative grass must respect the same clearings as the new field.
	for grass in get_tree().get_nodes_in_group("grass_sprites"):
		if not clear_of_items(Vector2(grass.position.x,grass.position.z)): grass.hide()

func bin_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x/BIN),floori(p.y/BIN))

func add_circle(p: Vector2, radius: float, collectible := false) -> void:
	if collectible: collectible_clearings.append(Vector3(p.x,p.y,radius))
	var reach := radius+FOOTPRINT
	var low := bin_at(p-Vector2.ONE*reach)
	var high := bin_at(p+Vector2.ONE*reach)
	for x in range(low.x,high.x+1):
		for z in range(low.y,high.y+1):
			var key := Vector2i(x,z)
			if not circles.has(key): circles[key] = []
			circles[key].append(Vector3(p.x,p.y,reach))

func add_rectangle(bounds: Rect2) -> void:
	var low := bin_at(bounds.position)
	var high := bin_at(bounds.end)
	for x in range(low.x,high.x+1):
		for z in range(low.y,high.y+1):
			var key := Vector2i(x,z)
			if not rectangles.has(key): rectangles[key] = []
			rectangles[key].append(bounds)

func clear_of_items(p: Vector2) -> bool:
	if preload("res://scripts/weeper_sites.gd").reserved(p): return false
	for record: Vector3 in circles.get(bin_at(p),[]):
		if p.distance_squared_to(Vector2(record.x,record.y))<record.z*record.z: return false
	return true

func allowed(p: Vector2) -> bool:
	if not clear_of_items(p): return false
	for bounds: Rect2 in rectangles.get(bin_at(p),[]):
		if bounds.has_point(p): return false
	# Reuse the terrain's road segment index instead of scanning every road.
	var key := Vector2i(floori(p.x/32),floori(p.y/32))
	for id in C.terrain.bins.get(key,[]):
		var segment: Array = C.terrain.segments[id]
		if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))<10.24: return false
	return true

func set_enabled(on: bool) -> void:
	if on and not built: build_field()
	visible = on

func tuft_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three crossed painted cards retain volume without pointed green geometry.
	for blade in range(3):
		var angle := blade*PI/3
		var side := Vector3(cos(angle),0,sin(angle))*.4
		var points := [-side,side,Vector3.UP*.8-side,side,Vector3.UP*.8+side,Vector3.UP*.8-side]
		var uvs := [Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0)]
		for index in range(6):
			surface.set_color(Color.WHITE)
			surface.set_uv(uvs[index])
			surface.add_vertex(points[index])
	surface.generate_normals()
	var mesh := surface.commit()
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/grass.gdshader")
	material.set_shader_parameter("image",load("res://assets/ambient/painted-grass-atlas.png"))
	mesh.surface_set_material(0,material)
	return mesh

func build_field() -> void:
	var start := Time.get_ticks_msec()
	var mesh := tuft_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 491827
	for tx in range(-8,8):
		for tz in range(-58,3):
			var origin := Vector3((tx+.5)*TILE,0,(tz+.5)*TILE)
			var transforms: Array[Transform3D] = []
			for ix in range(40):
				for iz in range(40):
					var p := Vector2(tx*TILE+(ix+.5)*SPACING,tz*TILE+(iz+.5)*SPACING)+Vector2(rng.randf_range(-.22,.22),rng.randf_range(-.22,.22))
					if p.x< -235 or p.x>235 or p.y< -1840 or p.y>65 or not allowed(p): continue
					var height := rng.randf_range(.55,.95)
					var width := rng.randf_range(1.05,1.45)
					var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(width,height,width))
					transforms.append(Transform3D(basis,C.ground(p,-.018)-origin))
			if transforms.is_empty(): continue
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = mesh
			multi.instance_count = transforms.size()
			for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
			var patch := MultiMeshInstance3D.new()
			patch.multimesh = multi
			patch.position = origin
			patch.visibility_range_end = 95
			patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(patch)
			instance_count += transforms.size()
	built = true
	build_ms = Time.get_ticks_msec()-start
