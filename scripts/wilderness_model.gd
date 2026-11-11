extends RefCounted

# Original, code-authored silhouettes; no photographic or likeness assets.
static func part(parent: Node3D, at: Vector3, size: Vector3, colour: Color, round_shape := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var shape: PrimitiveMesh = SphereMesh.new() if round_shape else BoxMesh.new()
	if round_shape:
		shape.radius = .5
		shape.height = 1
	else: shape.size = Vector3.ONE
	node.mesh = shape
	node.visibility_range_end = 80
	node.visibility_range_end_margin = 10
	node.position = at
	node.scale = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1
	node.material_override = material
	parent.add_child(node)
	return node

static func warning(world: Node3D, p: Vector2, pale: bool) -> void:
	var root := Node3D.new()
	root.name = "HighClawMarks" if pale else "PitchWarning"
	world.add_child(root)
	root.position = world.C.ground(p+Vector2(-5,4))
	root.add_to_group("wilderness_warnings")
	root.set_meta("warning","High claw marks / Boughstalker territory. Interrupt its attack warning." if pale else "Pitch smeared on bark / Pitchbound territory. Evade the long poker, then strike.")
	# A narrow, bark-textured broken timber, rather than a smooth square column.
	var trunk: MeshInstance3D = world.cylinder(Vector3(0,1.05,0),.14,2.1,world.paint("wood"),root,false,.10)
	trunk.rotation.z = -.035
	world.beam(Vector3(-.08,1.8,0),Vector3(-.32,2.16,.05),.07,root)
	for i in range(3):
		var mark := part(root,Vector3((i-1)*.055,1.75 if pale else 1.1,-.14),Vector3(.035,.35,.025),Color("ded2ac") if pale else Color("101610"))
		mark.rotation.z = -.35
