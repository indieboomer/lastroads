extends CanvasLayer

var surface: Control
var status: Label
var phases: Array = []
var scene: PackedScene
const ART := preload("res://assets/ui/loading-splash-copper-pine.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	surface = Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(surface)
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = ART
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	surface.add_child(image)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0,0,0,.16)
	surface.add_child(shade)
	add_text("THE LAST ROADS",.11,54,Color("e6d4af"))
	add_text("BELLS OF THE HOLLOW",.215,22,Color("c4b696"))
	status = add_text("Loading the road ahead…",.87,19,Color("ded3bd"))
	call_deferred("begin")

func add_text(text: String, top: float, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.anchor_left = .05; label.anchor_right = .95
	label.anchor_top = top; label.anchor_bottom = top+.08
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font",preload("res://assets/fonts/Cinzel.ttf"))
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",colour)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,.9))
	label.add_theme_constant_override("shadow_offset_y",2)
	surface.add_child(label)
	return label

func present(text: String) -> void:
	status.text = text
	phases.append(text)
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw

func begin() -> void:
	await present("Loading the road ahead…")
	if "--splash-check" in OS.get_cmdline_user_args():
		var folder: String = ProjectSettings.globalize_path("res://reports/splash")
		if FileAccess.file_exists(OS.get_executable_path().get_base_dir().get_base_dir().path_join("TheLastRoads.pck")):
			folder = OS.get_executable_path().get_base_dir().get_base_dir().path_join("reports/splash")
		DirAccess.make_dir_recursive_absolute(folder)
		get_viewport().get_texture().get_image().save_png(folder.path_join("loading.png"))
	var error := ResourceLoader.load_threaded_request("res://main.tscn")
	if error!=OK: status.text = "Unable to load the road. Please restart the game."; push_error(error_string(error)); return
	while true:
		var state := ResourceLoader.load_threaded_get_status("res://main.tscn")
		if state==ResourceLoader.THREAD_LOAD_LOADED: break
		if state==ResourceLoader.THREAD_LOAD_FAILED or state==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			status.text = "Unable to load the road. Please restart the game."
			push_error("Main scene load failed")
			return
		await get_tree().process_frame
	scene = ResourceLoader.load_threaded_get("res://main.tscn")
	await present("Preparing the countryside…")
	var game: Node = scene.instantiate()
	get_tree().root.add_child(game)
	await game.loading_complete
	get_tree().current_scene = game
	if "--splash-check" in OS.get_cmdline_user_args():
		assert(phases.size()>=5 and game.ui.title.visible and not game.started)
		print("SPLASH PASS: artwork rendered before scene loading; real world/UI/enemy stages; title handoff")
		get_tree().quit()
		return
	if not game.test_mode:
		var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade.tween_property(surface,"modulate:a",0.0,.3)
		await fade.finished
	queue_free()
