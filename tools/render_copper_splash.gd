extends SceneTree

func _initialize() -> void:
	call_deferred("render")

func render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var picture := TextureRect.new()
	picture.texture = load("res://assets/ui/loading-splash.png")
	picture.size = Vector2(1920,1080)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	var ink := ShaderMaterial.new()
	ink.shader = load("res://shaders/retro_texture.gdshader")
	ink.set_shader_parameter("retro_enabled",true)
	ink.set_shader_parameter("style",1)
	ink.set_shader_parameter("virtual_height",270.0)
	ink.set_shader_parameter("image_aspect",16.0/9.0)
	ink.set_shader_parameter("dither_amount",.5)
	ink.set_shader_parameter("grain_amount",.3)
	picture.material = ink
	viewport.add_child(picture)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	assert(not image.is_empty())
	assert(image.save_png("res://assets/ui/loading-splash-copper-pine.png")==OK)
	print("COPPER SPLASH PASS: original composition / actual Copper & Pine shader / 270p grid / 50% dithering / 30% grain")
	quit()
