extends Node2D

var game: Node
var slots: Array[Node2D] = []
var cursor := 0

func begin_frame() -> void:
	cursor = 0
	for slot in slots: RenderingServer.canvas_item_clear(slot.get_canvas_item())

func draw_icon(texture: Texture2D, rect: Rect2, tint := Color.WHITE) -> void:
	if cursor>=slots.size():
		var slot := Node2D.new()
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/retro_texture.gdshader")
		slot.material = material
		add_child(slot)
		slots.append(slot)
	var slot := slots[cursor]
	cursor += 1
	var material := slot.material as ShaderMaterial
	game.visuals.uniforms(material)
	material.set_shader_parameter("image_aspect",float(texture.get_width())/texture.get_height())
	material.set_shader_parameter("virtual_height",maxf(8,game.visuals.summary().virtual_height*rect.size.y/720.0))
	material.set_shader_parameter("item_tint",tint)
	RenderingServer.canvas_item_add_texture_rect(slot.get_canvas_item(),rect,texture.get_rid())
