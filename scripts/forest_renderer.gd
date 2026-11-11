extends Node3D

# Four presentations of the same fixed roots. No mode changes collision or RNG.
const C = preload("res://scripts/content.gd")
var records: Array = []
var geometry: Node3D
var mode := -1
var root_centres: Dictionary = {}

func register_tree(card: Sprite3D, shadow: MeshInstance3D, p: Vector2, height: float, family: int, serial: int) -> void:
	if not root_centres.has(family):
		var image := card.texture.get_image()
		if image.is_compressed():
			image.decompress()
		var total := 0.0
		var weight := 0.0
		for y in range(int(image.get_height()*0.92),image.get_height()):
			for x in range(image.get_width()):
				var alpha := image.get_pixel(x,y).a
				if alpha>0.3:
					total += float(x)*alpha
					weight += alpha
		root_centres[family] = total/maxf(weight,1.0)
	var root: float = root_centres[family]
	if card.flip_h:
		root = card.texture.get_width()-1-root
	card.offset.x = card.texture.get_width()*0.5-root
	var closest := Vector2.ZERO
	var distance := INF
	for road in C.ROADS:
		for i in range(road.size()-1):
			var point := Geometry2D.get_closest_point_to_segment(p,road[i],road[i+1])
			if p.distance_squared_to(point)<distance:
				distance = p.distance_squared_to(point)
				closest = point
	var facing := closest-p
	var yaw := atan2(facing.x,facing.y)
	var base := C.height_at(p.x,p.y)
	var root_radius := minf(4.0,card.texture.get_width()*card.pixel_size*0.30)
	for ring in range(1,4):
		for direction in range(16):
			var angle := float(direction)*TAU/16.0
			var radius := root_radius*float(ring)/3.0
			base = minf(base,C.height_at(p.x+cos(angle)*radius,p.y+sin(angle)*radius))
	card.position.y = base+height*0.5-0.25
	shadow.position.y = card.position.y
	# Anchor the shadow at the same root rather than the asymmetric image centre.
	shadow.rotation.y = yaw
	shadow.position += Basis(Vector3.UP,yaw)*Vector3(card.offset.x*card.pixel_size,0,0)
	records.append({"card":card,"shadow":shadow,"p":p,"height":height,"family":family,"serial":serial,"yaw":yaw,"extra":[]})

func apply_mode(value: int) -> void:
	if value==mode:
		return
	mode = value
	if mode==0 and not geometry:
		build_geometry()
	if geometry:
		geometry.visible = mode==0
	for record in records:
		var card: Sprite3D = record.card
		card.visible = mode!=0
		record.shadow.visible = mode!=0
		card.rotation.y = record.yaw
		card.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if mode==3 else BaseMaterial3D.BILLBOARD_DISABLED
		(card.material_override as ShaderMaterial).set_shader_parameter("face_camera",mode==3)
		if mode==1 and record.extra.is_empty():
			for angle in [PI/3.0,2.0*PI/3.0]:
				var extra := card.duplicate() as Sprite3D
				extra.material_override = card.material_override.duplicate()
				get_parent().add_child(extra)
				extra.rotation.y = record.yaw+angle
				record.extra.append(extra)
		for extra in record.extra:
			extra.visible = mode==1

func build_geometry() -> void:
	geometry = Node3D.new()
	geometry.name = "RootedGrove"
	add_child(geometry)
	for family in range(4):
		var rng := RandomNumberGenerator.new()
		rng.seed = 18731+family*913
		var bark := SurfaceTool.new()
		var leaves := SurfaceTool.new()
		bark.begin(Mesh.PRIMITIVE_TRIANGLES)
		leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
		make_tree(family,bark,leaves,rng)
		bark.generate_normals()
		leaves.generate_normals()
		var bark_mesh := bark.commit()
		var leaf_mesh := leaves.commit()
		var bark_material := ShaderMaterial.new()
		bark_material.shader = load("res://shaders/arboreal.gdshader")
		bark_material.set_shader_parameter("leafy",false)
		var leaf_material := ShaderMaterial.new()
		leaf_material.shader = load("res://shaders/arboreal.gdshader")
		leaf_material.set_shader_parameter("leafy",true)
		bark_mesh.surface_set_material(0,bark_material)
		leaf_mesh.surface_set_material(0,leaf_material)
		var matching: Array = records.filter(func(record): return record.family==family)
		for mesh in [bark_mesh,leaf_mesh]:
			var batch := MultiMeshInstance3D.new()
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.use_colors = true
			instances.mesh = mesh
			instances.instance_count = matching.size()
			for i in range(matching.size()):
				var record: Dictionary = matching[i]
				var height: float = record.height
				var basis := Basis(Vector3.UP,float(record.serial)*2.39996).scaled(Vector3(height,height,height))
				instances.set_instance_transform(i,Transform3D(basis,Vector3(record.p.x,record.card.position.y-record.height*0.5,record.p.y)))
				var shade := 0.88+float(record.serial%9)*0.025
				instances.set_instance_color(i,Color(shade,shade,shade))
			batch.multimesh = instances
			geometry.add_child(batch)

func make_tree(family: int, bark: SurfaceTool, leaves: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var trunk_color := Color("665440") if family!=1 else Color("b6b8a0")
	var radius: float = [0.046,0.030,0.035,0.057][family]
	var bends := [Vector3.ZERO,Vector3(-0.014,0.22,0.01),Vector3(0.018,0.45,-0.015),Vector3(-0.005,0.70,0.01),Vector3(0,0.96,0)]
	for i in range(bends.size()-1):
		branch(bark,bends[i],bends[i+1],radius*(1.0-float(i)*0.22),radius*(0.78-float(i)*0.22),trunk_color)
	for i in range(6):
		var angle := float(i)*TAU/6.0
		var direction := Vector3(cos(angle),0,sin(angle))
		branch(bark,direction*0.105+Vector3(0,0.005,0),Vector3(0,0.13,0),radius*0.28,radius*0.8,trunk_color.darkened(0.12))
	var base: Color = [Color("6d8052"),Color("b49a42"),Color("476a58"),Color("7e8c58")][family]
	if family==2:
		# An irregular layered spruce silhouette, rather than a stack of cones.
		for tier in range(6):
			var y := 0.32+float(tier)*0.11
			var spread := 0.25-float(tier)*0.035
			for side in range(3):
				var angle := float(side)*TAU/3.0+float(tier)*1.8
				var centre := Vector3(cos(angle)*spread*0.4,y,sin(angle)*spread*0.4)
				blob(leaves,centre,Vector3(spread,0.105,spread),base,rng)
	else:
		var count := 15 if family!=1 else 12
		for i in range(count):
			var angle := float(i)*2.39996
			var spread := rng.randf_range(0.06,0.23) if family!=1 else rng.randf_range(0.04,0.13)
			var y := rng.randf_range(0.55,0.84) if family!=1 else rng.randf_range(0.48,0.89)
			var centre := Vector3(cos(angle)*spread,y,sin(angle)*spread)
			branch(bark,Vector3(0,y*0.65,0),centre,0.017,0.005,trunk_color)
			var size := rng.randf_range(0.12,0.18)
			blob(leaves,centre,Vector3(size,0.11 if family!=1 else 0.15,size),base,rng)

func branch(surface: SurfaceTool, start: Vector3, end: Vector3, r0: float, r1: float, colour: Color) -> void:
	var along := (end-start).normalized()
	var right := along.cross(Vector3.FORWARD).normalized()
	if right.length()<0.01:
		right = along.cross(Vector3.RIGHT).normalized()
	var forward := along.cross(right).normalized()
	for i in range(7):
		var a := float(i)*TAU/7.0
		var b := float(i+1)*TAU/7.0
		var v0 := right*cos(a)+forward*sin(a)
		var v1 := right*cos(b)+forward*sin(b)
		surface.set_color(colour)
		for point in [start+v0*r0,start+v1*r0,end+v0*maxf(r1,0.001),start+v1*r0,end+v1*maxf(r1,0.001),end+v0*maxf(r1,0.001)]:
			surface.add_vertex(point)

func blob(surface: SurfaceTool, centre: Vector3, size: Vector3, colour: Color, rng: RandomNumberGenerator) -> void:
	var shade := rng.randf_range(0.84,1.12)
	var phase := rng.randf()*TAU
	for ring in range(4):
		for side in range(8):
			var points: Array[Vector3] = []
			for corner in [Vector2(side,ring),Vector2(side+1,ring),Vector2(side,ring+1),Vector2(side+1,ring+1)]:
				var a: float = corner.x*TAU/8.0
				var b: float = corner.y*PI/4.0
				var irregular := 1.0+sin(a*3.0+b*2.0+phase)*0.12
				points.append(centre+Vector3(cos(a)*sin(b),cos(b),sin(a)*sin(b))*size*irregular)
			surface.set_color(Color(colour.r*shade,colour.g*shade,colour.b*shade))
			for index in [0,1,2,1,3,2]:
				surface.add_vertex(points[index])
