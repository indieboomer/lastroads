extends Node3D

var age := 0.0
var material: StandardMaterial3D

func _ready() -> void:
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(.78,.83,.70,.34)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,material)
	for i in range(48):
		var a := i*TAU/48
		var b := (i+1)*TAU/48
		for point in [Vector3(cos(a),sin(a),0),Vector3(cos(b),sin(b),0),Vector3(cos(a),sin(a),0)*.88,Vector3(cos(b),sin(b),0),Vector3(cos(b),sin(b),0)*.88,Vector3(cos(a),sin(a),0)*.88]: mesh.surface_add_vertex(point)
	mesh.surface_end()
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)

func _process(dt: float) -> void:
	age += dt
	visible = age>=0
	if age<0: return
	position += -basis.z*dt*12
	scale = Vector3.ONE*(.35+age*2.4)
	material.albedo_color.a = maxf(0,.34*(1-age/.85))
	if age>=.85: queue_free()
