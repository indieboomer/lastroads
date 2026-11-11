extends RefCounted

# Thick world-space geometry stays readable in GL Compatibility and one-bit modes.
static func paint(colour: Color, alpha := 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(colour,alpha)
	if alpha<1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return mat

static func ball(parent: Node3D, radius: float, mat: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = at
	return node

static func beam(parent: Node3D, from: Vector3, to: Vector3, width: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := CylinderMesh.new()
	mesh.top_radius = width*0.35
	mesh.bottom_radius = width
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 6
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = (from+to)*0.5
	var direction := (to-from).normalized()
	var side := direction.cross(Vector3.FORWARD)
	if side.length_squared()<0.01: side = direction.cross(Vector3.UP)
	side = side.normalized()
	node.basis = Basis(side,direction,side.cross(direction).normalized())

static func band(parent: Node3D, radius: float, width: float, mat: Material, depth_offset := 0.0) -> void:
	var node := MeshInstance3D.new()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,mat)
	for i in range(48):
		var a := Vector3(cos(i*TAU/48.0),sin(i*TAU/48.0),0)
		var b := Vector3(cos((i+1)*TAU/48.0),sin((i+1)*TAU/48.0),0)
		for point in [a*(radius-width),a*radius,b*radius,a*(radius-width),b*radius,b*(radius-width)]:
			mesh.surface_add_vertex(point)
	mesh.surface_end()
	node.mesh = mesh
	parent.add_child(node)
	node.position.z = depth_offset
	node.material_override = mat

static func projectile(parent: Node3D, kind: String, colour: Color) -> void:
	var bright := paint(Color("fff5d4") if kind=="ember" else Color("e7fbff"))
	var coloured := paint(colour)
	var trail := paint(colour,.48)
	var radius := 0.10 if kind=="dart" else 0.20
	ball(parent,radius,bright).scale.z = 1.8
	var tail := 1.15 if kind=="dart" else 1.9
	beam(parent,Vector3(0,0,0.1),Vector3(0,0,tail),radius*0.65,trail)
	for i in range(4 if kind=="dart" else 7):
		var angle := i*TAU/(4.0 if kind=="dart" else 7.0)
		var offset := Vector3(cos(angle),sin(angle),0)*radius*1.5
		beam(parent,offset+Vector3(0,0,.15),offset*0.5+Vector3(0,0,tail*.75),.025 if kind=="dart" else .04,trail)
	if kind=="rime":
		band(parent,.33,.065,coloured)
		for i in range(4):
			var direction := Vector3(cos(i*PI/2),sin(i*PI/2),0)
			beam(parent,direction*.15,direction*.40,.055,bright)
	elif kind=="ember":
		ball(parent,.29,paint(colour,.30))

static func wave(parent: Node3D, mat: Material, sacred: bool) -> void:
	band(parent,1.025,.125,paint(Color("101b22"),.82))
	band(parent,1.0,.075,mat,.008)
	band(parent,.86,.022,mat)
	for i in range(4 if sacred else 3):
		var angle := i*TAU/(4.0 if sacred else 3.0)
		var at := Vector3(cos(angle),sin(angle),0)*.70
		if sacred:
			beam(parent,at-Vector3.UP*.14,at+Vector3.UP*.20,.025,mat)
			beam(parent,at+Vector3(-.10,.07,0),at+Vector3(.10,.07,0),.025,mat)
		else:
			beam(parent,at,Vector3(cos(angle+TAU/3),sin(angle+TAU/3),0)*.70,.035,mat)

static func impact(parent: Node3D, mat: Material, frost: bool) -> void:
	band(parent,.59,.15,paint(Color("101b22"),.82))
	band(parent,.55,.085,mat,.008)
	for i in range(10 if frost else 8):
		var angle := i*TAU/(10.0 if frost else 8.0)
		var direction := Vector3(cos(angle),sin(angle),sin(angle*3)*.2)
		beam(parent,direction*.30,direction*(.85 if frost else .72),.035,mat)

static func fading_materials(parent: Node3D) -> Array:
	var result: Array = []
	var seen: Array = []
	for child in parent.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			if mat not in seen:
				seen.append(mat)
				result.append({"material":mat,"alpha":mat.albedo_color.a})
	return result
