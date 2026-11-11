extends CanvasLayer

var creator: Control
var coop_menu: Control
var powder_button: Button
var road_services_button: Button
var private_panel: Control
var private_fade: ColorRect
var private_caption: Label
var private_portrait: TextureRect
var private_title: Label
var keepsake_mara_button: Button
var keepsake_lucan_button: Button
var extra_keepsake_buttons: Dictionary = {}
var keepsake_panel: Panel
var keepsake_portrait: TextureRect
var keepsake_text: RichTextLabel
var settings_intimacy: CheckButton
var settings_dense_grass: CheckButton
var backpack: Control
var quickbar: Control
var weather_label: Label
var exposure_label: Label
var profession_label: Label
var game: Node
var font: Font
var hud_root: Control
var chapter: Label
var location: Label
var compass: Label
var tracker: Label
var resources: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var health_text: Label
var prompt: Label
var toast: Label
var discovery: Label
var discovery_sub: Label
var enemy_name: Label
var enemy_bar: ProgressBar
var tell: Label
var preparation_panel: Panel
var preparation_confirm: Button
var preparation_slots: Array[OptionButton] = []
var equipment_profession := ""
var casting_glyph: Control
var weapon: TextureRect
var shield: TextureRect
var torch_view: TextureRect
var lantern_view: TextureRect
var ranger_view: Control
var effect: ColorRect
var title: Control
var modal: Panel
var modal_type := ""
var dialog_portrait: TextureRect
var dialog_name: Label
var dialog_role: Label
var footer_controls_label: Label
var dialog_controls_label: Label
var dialog_body: RichTextLabel
var choices: Array[Button] = []
var current_choices: Array = []
var map_panel: Panel
var map_view: Control
var journal: RichTextLabel
var quest_track: OptionButton
var report_panel: Panel
var report_entry: TextEdit
var report_error: Label
var pause_panel: Panel
var toast_timer := 0.0
var discovery_timer := 0.0
var damage_flash := 0.0
var title_continue: Button
var dialog_feedback: Label
var retro_effect: ColorRect
var retro_copy: BackBufferCopy
var retro_material: ShaderMaterial
var portrait_material: ShaderMaterial
var settings_panel: Panel
var settings_preview: TextureRect
var settings_toggle: CheckButton
var settings_style: OptionButton
var settings_detail: OptionButton
var settings_trees: OptionButton
var settings_tree_hint: Label
var forest_preview := false
var settings_dither: HSlider
var settings_grain: HSlider
var settings_dither_label: Label
var settings_grain_label: Label
var settings_description: Label
var settings_status: Label
var settings_tag: Label
var settings_return := ""
var settings_syncing := false
var settings_art: Control
var settings_sounds: Control
var settings_music_volume: HSlider
var settings_sound_volume: HSlider
var settings_music_label: Label
var settings_sound_label: Label
var settings_reset_sound: Button
var settings_reset_look: Button
var settings_sound_tab: Button
var settings_tabs: Array[Button] = []
var settings_controls: Control
var settings_world: Control
var settings_wind: OptionButton
var settings_blood: OptionButton
var settings_lightning: CheckButton

func make_settings() -> void:
	settings_panel = panel(Vector2(50,42),Vector2(1180,636),self)
	label("SETTINGS",Vector2(28,20),27,settings_panel,true)
	settings_art = Control.new()
	settings_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.add_child(settings_art)
	for index in range(4):
		var tab := button(["Presentation","World & effects","Sounds","Keybindings"][index],Vector2(30+index*215,63),Vector2(205,32),settings_panel,func(): select_settings_tab(index))
		tab.toggle_mode = true
		settings_tabs.append(tab)
	settings_sound_tab = settings_tabs[2]
	settings_toggle = CheckButton.new()
	settings_toggle.text = "Retro look"
	settings_toggle.position = Vector2(25,106)
	settings_toggle.size = Vector2(420,45)
	settings_toggle.add_theme_font_size_override("font_size",23)
	settings_art.add_child(settings_toggle)
	settings_toggle.toggled.connect(func(on): change_setting("enabled",on))
	label("Visual style",Vector2(30,155),17,settings_art)
	settings_style = OptionButton.new()
	settings_style.position = Vector2(30,181)
	settings_style.size = Vector2(400,40)
	settings_style.add_theme_font_size_override("font_size",19)
	for preset in game.visuals.PRESETS:
		settings_style.add_item(preset.name)
	settings_art.add_child(settings_style)
	settings_style.item_selected.connect(func(index): change_setting("preset",index))
	label("Pixel detail",Vector2(30,236),17,settings_art)
	settings_detail = OptionButton.new()
	settings_detail.position = Vector2(30,260)
	settings_detail.size = Vector2(400,36)
	settings_detail.add_theme_font_size_override("font_size",17)
	for text in ["Coarse · big pixels","Classic · recommended","Fine · more detail"]:
		settings_detail.add_item(text)
	settings_art.add_child(settings_detail)
	settings_detail.item_selected.connect(func(index): change_setting("detail",index))
	settings_dither_label = label("Ordered dithering",Vector2(30,306),17,settings_art)
	settings_dither = settings_slider(Vector2(30,334),"dither")
	settings_grain_label = label("Paper grain",Vector2(30,368),17,settings_art)
	settings_grain = settings_slider(Vector2(30,396),"grain")
	label("Trees",Vector2(30,430),17,settings_art)
	settings_trees = OptionButton.new()
	settings_trees.position = Vector2(30,456)
	settings_trees.size = Vector2(400,40)
	settings_trees.add_theme_font_size_override("font_size",18)
	for mode in game.visuals.TREES:
		settings_trees.add_item(mode.name)
	settings_art.add_child(settings_trees)
	settings_trees.item_selected.connect(func(index): change_setting("trees",index))
	settings_tree_hint = label("Trees stay independent of Retro look.",Vector2(30,505),13,settings_art)
	settings_preview = TextureRect.new()
	settings_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_preview.texture = load("res://assets/settings-preview.png")
	settings_preview.position = Vector2(471,106)
	settings_preview.stretch_mode = TextureRect.STRETCH_SCALE
	settings_preview.size = Vector2(680,382.5)
	settings_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/retro_texture.gdshader")
	settings_preview.material = material
	settings_panel.add_child(settings_preview)
	settings_preview.set_deferred("size",Vector2(680,382.5))
	settings_tag = label("",Vector2(473,505),17,settings_panel,true)
	settings_tag.modulate = Color("d8b778")
	settings_description = label("",Vector2(473,536),17,settings_panel)
	settings_description.size = Vector2(660,72)
	settings_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Back",Vector2(30,552),Vector2(155,48),settings_panel,leave_settings)
	settings_reset_look = button("Reset look",Vector2(200,552),Vector2(230,48),settings_panel,func():
		game.visuals.values = game.visuals.DEFAULTS.duplicate()
		apply_visuals()
		sync_settings()
		save_visuals()
	)
	settings_status = label("Changes save automatically · Esc goes back",Vector2(30,608),13,settings_panel)
	make_world_settings()
	make_sound_settings()
	select_settings_tab(0)
	settings_panel.hide()

func settings_slider(at: Vector2, key: String) -> HSlider:
	var slider := HSlider.new()
	slider.position = at
	slider.size = Vector2(400,25)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.tooltip_text = "A stable pattern, without animated flicker."
	settings_art.add_child(slider)
	slider.value_changed.connect(func(value): change_setting(key,value))
	return slider

func open_settings(from: String) -> void:
	settings_return = from
	game.set_modal("settings")
	settings_panel.show()
	select_settings_tab(0)
	sync_settings()
	settings_toggle.grab_focus()

func leave_settings() -> void:
	game.controls.capture_action = ""
	save_visuals()
	game.set_modal("pause" if settings_return=="pause" else "")

func change_setting(key: String, value: Variant) -> void:
	if settings_syncing:
		return
	game.visuals.values[key] = value
	if key=="trees":
		forest_preview = true
	apply_visuals()
	sync_settings()
	save_visuals()

func save_visuals() -> void:
	var error: Error = game.visuals.write(game.settings_path())
	settings_status.text = "Saved automatically · Esc goes back" if error==OK else "Could not save settings: "+error_string(error)

func sync_settings() -> void:
	settings_syncing = true
	var values: Dictionary = game.visuals.values
	settings_toggle.set_pressed_no_signal(values.enabled)
	settings_style.select(values.preset)
	settings_detail.select(values.detail)
	settings_trees.select(values.trees)
	settings_wind.select(values.wind_strength)
	settings_blood.select(values.blood_size)
	settings_lightning.set_pressed_no_signal(values.lightning)
	settings_intimacy.set_pressed_no_signal(values.intimacy)
	settings_dense_grass.set_pressed_no_signal(values.dense_grass)
	settings_dither.set_value_no_signal(values.dither)
	settings_grain.set_value_no_signal(values.grain)
	settings_dither_label.text = "Ordered dithering  %d%%" % roundi(values.dither*100)
	settings_grain_label.text = "Paper grain  %d%%" % roundi(values.grain*100)
	settings_style.disabled = not values.enabled
	settings_detail.disabled = not values.enabled
	settings_dither.editable = values.enabled
	settings_grain.editable = values.enabled
	var preset: Dictionary = game.visuals.PRESETS[values.preset]
	settings_tag.text = preset.tag if values.enabled else "ORIGINAL ILLUSTRATION"
	settings_description.text = preset.description if values.enabled else "The original painted presentation. Switch Retro look on to try nine treatments. Game text stays crisp in every style."
	if forest_preview:
		var mode: Dictionary = game.visuals.TREES[values.trees]
		settings_tag.text = mode.name.to_upper()
		settings_description.text = mode.description
		var preview := "res://assets/forest-preview-%d.png" % values.trees
		if ResourceLoader.exists(preview):
			settings_preview.texture = load(preview)
	sync_sound_settings()
	settings_syncing = false

func apply_visuals() -> void:
	game.visuals.uniforms(retro_material)
	game.visuals.uniforms(portrait_material)
	portrait_material.set_shader_parameter("virtual_height",game.visuals.summary().virtual_height*0.77)
	game.visuals.uniforms(settings_preview.material)
	retro_effect.visible = game.visuals.values.enabled
	retro_copy.visible = game.visuals.values.enabled
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if game.visuals.values.enabled else Viewport.MSAA_4X
	game.world.forest.apply_mode(game.visuals.values.trees)
	game.world.apply_rock_mode(game.visuals.values.trees)
	game.world.lush_grass.set_enabled(game.visuals.values.dense_grass)
	if game.weather:
		game.weather.apply_visuals()
	style_menu_graphics(self)
	if backpack: backpack.queue_redraw()
	if quickbar: quickbar.queue_redraw()

func style_graphic(node: TextureRect) -> void:
	if not node.texture: return
	if not node.material:
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/retro_texture.gdshader")
		node.material = material
	var material := node.material as ShaderMaterial
	if not material: return
	game.visuals.uniforms(material)
	var aspect := float(node.texture.get_width())/node.texture.get_height()
	var height := minf(node.size.y,node.size.x/aspect) if node.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED else node.size.y
	material.set_shader_parameter("image_aspect",aspect)
	var region := Vector4(0,0,1,1)
	if node.texture is AtlasTexture:
		var atlas := node.texture as AtlasTexture
		var texture_size := atlas.atlas.get_size()
		region = Vector4(atlas.region.position.x/texture_size.x,atlas.region.position.y/texture_size.y,atlas.region.size.x/texture_size.x,atlas.region.size.y/texture_size.y)
	material.set_shader_parameter("uv_rect",region)
	material.set_shader_parameter("virtual_height",maxf(8,game.visuals.summary().virtual_height*height/720.0))

func style_menu_graphics(parent: Node) -> void:
	for child in parent.get_children():
		if child==hud_root: continue
		if child is TextureRect: style_graphic(child)
		style_menu_graphics(child)

func panel_style(bg := Color("102527"),border := Color("756b49")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(0 if game.visuals.values.enabled else 3)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func label(text: String, at: Vector2, size: int, parent: Node, heading := false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color("e7dcc2"))
	l.add_theme_color_override("font_shadow_color",Color(0.02,0.04,0.04,0.9))
	l.add_theme_constant_override("shadow_offset_x",1)
	l.add_theme_constant_override("shadow_offset_y",2)
	if heading:
		l.add_theme_font_override("font",font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(text: String, at: Vector2, size: Vector2, parent: Node, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = size
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_stylebox_override("normal",panel_style(Color("1a3332")))
	b.add_theme_stylebox_override("hover",panel_style(Color("314c41"),Color("cfb374")))
	b.add_theme_stylebox_override("pressed",panel_style(Color("52634a")))
	parent.add_child(b)
	b.pressed.connect(func():
		game.audio.throttled("back_close" if text=="Back" else "confirm","back_close" if text=="Back" else "ui_confirm",.10,Vector3.INF,true))
	b.pressed.connect(action)
	return b

func panel(at: Vector2, size: Vector2, parent: Node) -> Panel:
	var p := Panel.new()
	p.position = at
	p.size = size
	p.add_theme_stylebox_override("panel",panel_style())
	parent.add_child(p)
	return p

func bar(at: Vector2, size: Vector2, color: Color, parent: Node) -> ProgressBar:
	var b := ProgressBar.new()
	b.position = at
	b.size = size
	b.show_percentage = false
	b.add_theme_font_size_override("font_size",1)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("112123")
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	b.add_theme_stylebox_override("background",background)
	b.add_theme_stylebox_override("fill",fill)
	parent.add_child(b)
	b.set_deferred("size",size)
	return b

func build() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = load("res://assets/fonts/Cinzel.ttf")
	hud_root = Control.new()
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)
	# Painted weapons use separate atlas halves so their motion is independent.
	for i in range(2):
		var t: Texture2D = load("res://assets/revision/shield-v2.png" if i==0 else "res://assets/revision/sword-v2.png")
		var r := TextureRect.new()
		r.texture = t
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var height := 800.0 if i==0 else 1000.0
		r.size = Vector2(t.get_width()*height/t.get_height(),height)
		r.position = Vector2(-80,330) if i==0 else Vector2(740,30)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud_root.add_child(r)
		if i==0:
			shield = r
			shield.flip_h = true
		else:
			weapon = r
	# Canvas order matters: the sword must pass in front of the shield.
	hud_root.move_child(shield,0)
	hud_root.move_child(weapon,1)
	torch_view = TextureRect.new()
	torch_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	torch_view.texture = load("res://assets/revision/torch-hand.png")
	torch_view.size = Vector2(torch_view.texture.get_width()*830.0/torch_view.texture.get_height(),830)
	torch_view.position = Vector2(5,145)
	torch_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(torch_view)
	hud_root.move_child(torch_view,1)
	torch_view.hide()
	lantern_view = TextureRect.new()
	lantern_view.texture = load("res://assets/ranger/lantern-hand.png")
	lantern_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lantern_view.size = Vector2(900,600)
	lantern_view.position = Vector2(-35,180)
	lantern_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(lantern_view)
	lantern_view.hide()
	ranger_view = preload("res://scripts/ranger_view.gd").new()
	ranger_view.game = game
	hud_root.add_child(ranger_view)
	casting_glyph = preload("res://scripts/casting_glyph.gd").new()
	casting_glyph.game = game
	hud_root.add_child(casting_glyph)
	weapon.pivot_offset = Vector2(weapon.size.x*0.46,580)
	shield.pivot_offset = Vector2(shield.size.x*0.85,900)
	effect = ColorRect.new()
	effect.size = Vector2(1280,720)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/atmosphere.gdshader")
	effect.material = mat
	hud_root.add_child(effect)
	retro_copy = BackBufferCopy.new()
	retro_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	hud_root.add_child(retro_copy)
	retro_effect = ColorRect.new()
	retro_effect.size = Vector2(1280,720)
	retro_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retro_material = ShaderMaterial.new()
	retro_material.shader = load("res://shaders/retro.gdshader")
	retro_effect.material = retro_material
	hud_root.add_child(retro_effect)
	chapter = label("THE LAST ROADS",Vector2(30,20),17,hud_root,true)
	location = label("Wayfarer's Rest",Vector2(30,45),23,hud_root,true)
	compass = label("",Vector2(480,22),19,hud_root,true)
	compass.size.x = 320
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tracker = label("",Vector2(914,30),17,hud_root)
	tracker.size = Vector2(336,95)
	tracker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var dot := label("·",Vector2(629,344),30,hud_root)
	dot.modulate = Color("fff0c7")
	health_bar = bar(Vector2(30,628),Vector2(225,11),Color("a76651"),hud_root)
	stamina_bar = bar(Vector2(30,648),Vector2(180,6),Color("b9ac77"),hud_root)
	health_text = label("",Vector2(30,599),17,hud_root)
	resources = label("",Vector2(30,668),16,hud_root)
	prompt = label("",Vector2(320,572),21,hud_root)
	prompt.size = Vector2(640,35)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = label("",Vector2(140,125),18,hud_root)
	toast.size = Vector2(1000,70)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color",Color("f0d494"))
	discovery = label("",Vector2(240,200),34,hud_root,true)
	discovery.size.x = 800
	discovery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	discovery_sub = label("",Vector2(240,248),17,hud_root)
	discovery_sub.size.x = 800
	discovery_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name = label("",Vector2(470,474),18,hud_root,true)
	enemy_name.size.x = 340
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_bar = bar(Vector2(510,505),Vector2(260,6),Color("9b765c"),hud_root)
	enemy_bar.hide()
	tell = label("",Vector2(350,530),19,hud_root)
	tell.size.x = 580
	tell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tell.add_theme_color_override("font_color",Color("ffc985"))
	footer_controls_label = label("",Vector2(30,701),12,hud_root)
	make_title()
	make_dialog()
	make_map()
	make_report()
	pause_panel = panel(Vector2(410,180),Vector2(460,350),self)
	label("A MOMENT'S REST",Vector2(45,30),25,pause_panel,true)
	button("Resume expedition",Vector2(35,95),Vector2(390,48),pause_panel,func(): game.set_modal(""))
	button("Save and return to title",Vector2(35,215),Vector2(390,48),pause_panel,func():
		if game.save_game():
			game.to_title()
	)
	label("Esc resumes · ` records a field note",Vector2(55,298),16,pause_panel)
	button("Settings",Vector2(35,155),Vector2(390,48),pause_panel,func(): open_settings("pause"))
	pause_panel.hide()
	backpack = preload("res://scripts/backpack_ui.gd").new()
	backpack.game = game
	backpack.position = Vector2(150,15)
	backpack.size = Vector2(980,690)
	add_child(backpack)
	button("Auto-arrange",Vector2(574,24),Vector2(180,36),backpack,func():
		game.state.pack.arrange(game.state.inventory)
		backpack.held = ""
		backpack.dragged_slot = -1
		backpack.notice = "Supplies arranged. No items lost."
	)
	button("Close",Vector2(780,24),Vector2(160,36),backpack,func(): game.set_modal(""))
	for key in ["lantern","torch","rest"]:
		var index: int = ["lantern","torch","rest"].find(key)
		button(key.capitalize(),Vector2(574+index*124,235),Vector2(118,36),backpack,func(): backpack.select_action(key))
	button("Use / activate selected",Vector2(574,410),Vector2(366,32),backpack,func(): backpack.activate_selected())
	button("Reset quick slots",Vector2(574,455),Vector2(300,32),backpack,func():
		game.state.pack.slots = game.state.pack.DEFAULT_SLOTS.duplicate()
		backpack.notice = "Default shortcuts restored. Any supply or carried gear can replace them."
	)
	backpack.hide()
	quickbar = preload("res://scripts/quickbar.gd").new()
	quickbar.game = game
	quickbar.position = Vector2(346,631)
	quickbar.size = Vector2(528,64)
	hud_root.add_child(quickbar)
	weather_label = label("",Vector2(30,84),15,hud_root)
	exposure_label = label("",Vector2(923,622),15,hud_root)
	profession_label = label("",Vector2(30,112),14,hud_root)
	make_settings()
	creator = preload("res://scripts/character_creator.gd").new()
	creator.game = game
	creator.ui = self
	add_child(creator)
	creator.build()
	make_relationship_panels()
	apply_visuals()

func make_title() -> void:
	title = Control.new()
	add_child(title)
	var art := TextureRect.new()
	art.texture = load("res://assets/last-roads.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size = Vector2(1280,720)
	title.add_child(art)
	var veil := ColorRect.new()
	veil.color = Color(0.015,0.035,0.04,0.64)
	veil.size = Vector2(1280,720)
	title.add_child(veil)
	label("T H E   L A S T   R O A D S",Vector2(75,125),39,title,true)
	label("BELLS OF THE HOLLOW / THE NAMES WE CARRY",Vector2(78,185),23,title,true)
	label("The last road north has gone dark.\nA stolen caravan. A silent chapel. A bell that rings for nobody.\n\nThere are still people worth finding out there.\nAnd one fire left to light.",Vector2(80,260),22,title)
	button("Begin a new journey",Vector2(80,453),Vector2(290,54),title,func(): open_creator())
	title_continue = button("Continue journey",Vector2(386,453),Vector2(260,54),title,func(): game.continue_game())
	button("Settings",Vector2(662,453),Vector2(180,54),title,func(): open_settings("title"))
	button("Exit game",Vector2(858,453),Vector2(180,54),title,func(): game.get_tree().quit())
	button("Co-op / Steam friends",Vector2(80,517),Vector2(350,40),title,func(): coop_menu.open())
	label("Keyboard / mouse or controller. Change controls in Settings / Keybindings.\nController: sticks move and look; D-pad Up opens quick slots and road actions.\nIn menus: D-pad focuses, sticks move the pointer, A confirms and B goes back.",Vector2(80,592),17,title)
	label("The Last Roads / "+game.C.BUILD+" | F10 sound | F11 fullscreen",Vector2(80,683),14,title)

func make_dialog() -> void:
	modal = panel(Vector2(60,60),Vector2(1160,600),self)
	dialog_portrait = TextureRect.new()
	dialog_portrait.position = Vector2(22,22)
	dialog_portrait.size = Vector2(270,554)
	portrait_material = ShaderMaterial.new()
	portrait_material.shader = load("res://shaders/retro_texture.gdshader")
	dialog_portrait.material = portrait_material
	dialog_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialog_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	modal.add_child(dialog_portrait)
	dialog_name = label("",Vector2(325,25),32,modal,true)
	dialog_role = label("",Vector2(327,72),17,modal)
	dialog_role.add_theme_color_override("font_color",Color("b9aa7c"))
	powder_button = button("Paper cartridges",Vector2(650,28),Vector2(230,42),modal,func(): game.open_powder_shop(game.dialogue_id))
	road_services_button = button("Road services",Vector2(900,77),Vector2(220,32),modal,func(): game.journey.services())
	dialog_body = RichTextLabel.new()
	dialog_body.position = Vector2(327,115)
	dialog_body.size = Vector2(790,250)
	dialog_body.add_theme_font_size_override("normal_font_size",19)
	dialog_body.add_theme_color_override("default_color",Color("dfddc9"))
	dialog_body.bbcode_enabled = true
	modal.add_child(dialog_body)
	dialog_feedback = label("",Vector2(327,370),15,modal)
	dialog_feedback.add_theme_color_override("font_color",Color("ec9b8b"))
	for i in range(3):
		var index := i
		var b := button("",Vector2(325,400+i*54),Vector2(795,46),modal,func(): choose(index))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choices.append(b)
	dialog_controls_label = label("",Vector2(325,575),14,modal)
	modal.hide()

func show_dialog(id: String, d: Dictionary) -> void:
	d = game.relationship.dialogue_choices(id,d)
	game.set_modal("dialog")
	var spec: Dictionary = game.C.NPCS[id]
	dialog_portrait.show()
	dialog_portrait.texture = game.relationship.portrait_texture(id) if game.relationship.appearance_active(id) else game.world.npc_portrait(id)
	dialog_name.text = spec.name
	dialog_role.text = spec.role
	powder_button.visible = game.state.profile.profession_id=="ranger" and id in game.C.AMMO_SELLERS
	road_services_button.visible = id in game.journey.CONTACTS
	dialog_body.text = d.body
	dialog_body.call_deferred("scroll_to_line",0)
	current_choices = d.choices
	update_control_hints()
	dialog_feedback.text = ""
	dialog_feedback.add_theme_color_override("font_color",Color("ec9b8b"))
	for i in range(3):
		choices[i].visible = i<current_choices.size()
		if i<current_choices.size():
			choices[i].text = "%d   %s" % [i+1,current_choices[i].text]
			var requirement: Dictionary = game.affordability(current_choices[i].action)
			choices[i].disabled = not requirement.allowed
			choices[i].add_theme_color_override("font_disabled_color",Color("d99888"))
			if not requirement.allowed:
				choices[i].text += " — "+requirement.reason
				if dialog_feedback.text.is_empty():
					dialog_feedback.text = requirement.reason
	modal.show()
	if game.controls.using_pad:
		for option in choices:
			if option.visible and not option.disabled:
				option.call_deferred("grab_focus")
				break

func choose(index: int) -> void:
	if game.reporting or modal_type!="dialog" or index>=current_choices.size():
		return
	if choices[index].disabled:
		dialog_feedback.text = game.affordability(current_choices[index].action).reason
		return
	game.choose_dialog(current_choices[index].action)

func make_map() -> void:
	map_panel = panel(Vector2(35,35),Vector2(1210,650),self)
	map_view = preload("res://scripts/map.gd").new()
	map_view.game = game
	map_view.position = Vector2(15,20)
	map_view.size = Vector2(660,600)
	map_view.clip_contents = true
	map_panel.add_child(map_view)
	button("Hollow / March map",Vector2(28,30),Vector2(220,32),map_panel,func(): map_view.region = 1-map_view.region; map_view.queue_redraw())
	label("THE ROADKEEPER'S JOURNAL",Vector2(707,24),22,map_panel,true)
	button("Personal keepsakes",Vector2(709,552),Vector2(300,36),map_panel,show_keepsake)
	button("Travel",Vector2(1020,552),Vector2(160,36),map_panel,func(): game.journey.travel_menu())
	journal = RichTextLabel.new()
	journal.bbcode_enabled = true
	quest_track = OptionButton.new()
	quest_track.position = Vector2(709,65)
	quest_track.size = Vector2(470,35)
	for name_text in preload("res://scripts/march_content.gd").TRACKS:
		quest_track.add_item(name_text)
	map_panel.add_child(quest_track)
	quest_track.item_selected.connect(func(index):
		game.state.story.track = index
		journal.text = game.journal_text()
	)
	journal.position = Vector2(709,113)
	journal.size = Vector2(470,425)
	journal.add_theme_font_size_override("normal_font_size",18)
	journal.add_theme_color_override("default_color",Color("d6d4b9"))
	map_panel.add_child(journal)
	label("M / J / Esc closes · Gold ring: next destination · White arrow: you",Vector2(710,604),13,map_panel)
	map_panel.hide()

func show_map() -> void:
	game.set_modal("map")
	map_view.region = 1 if game.player.position.z< -425 and not game.in_crypt() else 0
	quest_track.visible = game.state.flags.won
	quest_track.select(int(game.state.story.track))
	journal.text = game.journal_text()
	map_panel.show()

func make_report() -> void:
	report_panel = panel(Vector2(240,145),Vector2(800,430),self)
	label("FIELD NOTES / GAME PAUSED",Vector2(26,20),26,report_panel,true)
	label("Describe the problem. Enter saves · Shift+Enter adds a line · Esc cancels",Vector2(26,65),17,report_panel)
	report_entry = TextEdit.new()
	report_entry.position = Vector2(26,104)
	report_entry.size = Vector2(748,230)
	report_entry.add_theme_font_size_override("font_size",20)
	report_entry.placeholder_text = "What happened? What did you expect?"
	report_panel.add_child(report_entry)
	report_error = label("",Vector2(26,345),17,report_panel)
	report_error.size = Vector2(420,42)
	report_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Save note",Vector2(470,340),Vector2(145,44),report_panel,func(): game.submit_report())
	button("Cancel",Vector2(630,340),Vector2(145,44),report_panel,func(): game.close_report())
	report_error.add_theme_color_override("font_color",Color("f0bb88"))
	label("Screenshot · position · stats · quests · enemies · recent events → debug-logs",Vector2(26,390),16,report_panel)
	report_panel.hide()

func toast_message(text: String, duration := 4.0) -> void:
	toast.text = text
	# Long travel reflections sit below discovery titles, clear of the status HUD.
	toast.position = Vector2(140,285) if duration>10 else Vector2(320,155)
	toast.size = Vector2(1000,90) if duration>10 else Vector2(640,70)
	toast_timer = duration

func discover(name_text: String, sub: String) -> void:
	discovery.text = name_text
	discovery_sub.text = sub
	discovery_timer = 5.0

func update_control_hints() -> void:
	if footer_controls_label:
		footer_controls_label.visible = not game.controls.using_pad
		footer_controls_label.text = "%s Journal & map    %s Save    %s Load    %s Field note    %s Pause" % [game.controls.hint("map"),game.controls.hint("save"),game.controls.hint("load"),game.controls.hint("report"),game.controls.hint("pause")]
	if not dialog_controls_label: return
	dialog_controls_label.text = "D-pad: choose · A/Cross: confirm · B/Circle: leave" if game.controls.using_pad else "%s / %s / %s choose · Esc leave conversation" % [game.controls.hint("slot1"),game.controls.hint("slot2"),game.controls.hint("slot3")]

func tick(dt: float) -> void:
	update_control_hints()
	var s = game.state
	configure_equipment()
	var profession := preload("res://scripts/character_data.gd").profession(s.profile.profession_id)
	profession_label.text = "%s / %s\nC / V abilities%s" % [s.profile.name,profession.name," / Mana %d / %d" % [s.mana,s.max_mana] if s.max_mana>0 else ""]
	var names: Array = s.prepared if s.profile.profession_id in ["mage","cleric"] else ["pistol","musket"] if s.profile.profession_id=="ranger" else ["second wind","driving strike"]
	profession_label.text = "%s / %s%s" % [s.profile.name,profession.name," / Mana %d / %d" % [s.mana,s.max_mana] if s.max_mana>0 else ""]
	profession_label.text += " / Rank %d / %d XP" % [s.rank(),s.xp]
	if s.profile.profession_id=="ranger":
		profession_label.text += "\nC: pistol %s / V: musket %s" % ["loaded" if s.ranger.pistol_loaded else "empty","loaded" if s.ranger.musket_loaded else "empty"]
	else:
		profession_label.text += "\nC: %s %s / V: %s %s" % [str(names[0]).capitalize(),"ready" if s.ability_cooldowns.primary<=0 else "%ds" % ceili(s.ability_cooldowns.primary),str(names[1]).capitalize(),"ready" if s.ability_cooldowns.secondary<=0 else "%ds" % ceili(s.ability_cooldowns.secondary)]
	if s.profile.profession_id=="ranger":
		var r: Dictionary = s.ranger
		profession_label.text += "\n%s / %s / R reload / Q dagger / G rest\nCartridges: pistol %d / musket %d / RMB steady aim" % [r.weapon.capitalize(),"reloading %.1fs" % r.reload_left if r.reload_left>0 else "loaded" if r.weapon!="dagger" and r[r.weapon+"_loaded"] else "empty" if r.weapon!="dagger" else "ready",s.inventory.pistol_cartridge,s.inventory.musket_cartridge]
	elif s.profile.profession_id in ["mage","cleric"]:
		profession_label.text += "\nLMB: %s / RMB/Q: %s %s" % ["Staff" if s.profile.profession_id=="cleric" else "Dart","Rebuke" if s.profile.profession_id=="cleric" else "Repulsion","ready" if s.ability_cooldowns.defensive<=0 else "%ds" % ceili(s.ability_cooldowns.defensive)]
		if game.combat.protected_at(game.player.position): profession_label.text += " / SANCTUARY -35% damage"
	if game.offhand_busy(): profession_label.text += "\nLeft: torch / RMB strike / T stow" if game.torch_equipped else "\nLeft: lantern / L stow / offhand unavailable"
	for pair in [["C:","primary"],["V:","secondary"],["R reload","reload"],["Q dagger","heavy"],["G rest","rest"],["LMB","attack"],["RMB","defend"],["T stow","torch"],["L stow","lantern"]]:
		var suffix: String = ":" if pair[0].ends_with(":") else " "+pair[0].get_slice(" ",1) if pair[0].contains(" ") else ""
		profession_label.text = profession_label.text.replace(pair[0],game.controls.hint(pair[1])+suffix)
	profession_label.text = profession_label.text.replace("/Q:","/"+game.controls.hint("heavy")+":")
	if modal_type=="dialog" and not game.dialogue_id.is_empty() and not game.relationship.relaxed:
		dialog_portrait.texture = game.world.npc_portrait(game.dialogue_id,game.world.is_blinking(game.dialogue_id,Time.get_ticks_msec()/1000.0))
		portrait_material.set_shader_parameter("image_aspect",float(dialog_portrait.texture.get_width())/dialog_portrait.texture.get_height())
	toast_timer = maxf(0,toast_timer-dt)
	toast.modulate.a = minf(toast_timer,1)
	discovery_timer = maxf(0,discovery_timer-dt)
	discovery.modulate.a = minf(discovery_timer,1)
	discovery_sub.modulate.a = minf(discovery_timer,1)
	damage_flash = maxf(0,damage_flash-dt*2)
	(effect.material as ShaderMaterial).set_shader_parameter("hurt",damage_flash)
	(effect.material as ShaderMaterial).set_shader_parameter("night",0.5 if s.day_clock>18 else 0.0)
	health_bar.max_value = s.max_health
	health_bar.value = s.health
	stamina_bar.value = s.stamina
	health_text.text = "VITALITY  %d / %d" % [s.health,s.max_health]
	resources.add_theme_font_size_override("font_size",14)
	resources.text = "Wood %d / Coin %d / [%s] Backpack" % [s.inventory.wood,s.inventory.gold,game.controls.hint("inventory")]
	if game.controls.using_pad: resources.text += " / "+game.controls.hint("tools")+" Actions"
	quickbar.queue_redraw()
	s.pack.sync(s.inventory)
	if game.weather:
		var weather = game.weather
		weather_label.text = weather.TYPES[weather.kind()].name+(" / Sheltered" if weather.sheltered else " / By the fire" if weather.warmth else "")
		exposure_label.text = "WET %d%%   COLD %d%%\nStamina recovery %d%%" % [s.wetness,s.cold,roundi(weather.stamina_factor()*100)]
		exposure_label.modulate = Color("e2aa80") if s.cold>55 else Color("c5d1c4")

	var t: Dictionary = game.target()
	var dist := Vector2(game.player.position.x,game.player.position.z).distance_to(t.get("pos",Vector2.ZERO))
	var title: String = preload("res://scripts/march_content.gd").TRACKS[int(s.story.track)].to_upper() if s.flags.won else "THE ROAD NORTH"
	tracker.text = title+"\n"+t.get("text","") + ("  ·  %dm" % dist if t.has("pos") else "")
	var degrees := fposmod(rad_to_deg(-game.player.rotation.y),360)
	var directions := ["N","NE","E","SE","S","SW","W","NW"]
	compass.text = "‹   %s   ›     %02d:%02d" % [directions[int(round(degrees/45))%8],int(s.day_clock),int(fmod(s.day_clock,1)*60)]
	if t.has("pos"):
		var delta: Vector2 = t.pos-Vector2(game.player.position.x,game.player.position.z)
		var bearing := wrapf(atan2(-delta.x,-delta.y)-game.player.rotation.y,-PI,PI)
		compass.text += "\n%s  %dm" % ["←" if bearing>0.2 else "→" if bearing< -0.2 else "◇",dist]
	prompt.text = game.interaction_prompt()
	var nearest: Node = game.target_enemy()
	enemy_name.text = ""
	tell.text = ""
	enemy_bar.visible = nearest!=null
	if nearest:
		enemy_name.text = nearest.spec.name
		enemy_bar.max_value = nearest.spec.hp
		enemy_bar.value = nearest.health
		if nearest.phase=="windup":
			tell.text = "INCOMING / BLOCK OR PARRY" if s.profile.profession_id=="warrior" else "INCOMING / REBUKE OR MOVE" if s.profile.profession_id=="cleric" else "INCOMING / MOVE OR REPULSION"
			if nearest.kind=="pitchbound": tell.text = "LONG POKER / STEP BACK OR PARRY"
			elif nearest.kind=="boughstalker" and nearest.clock<nearest.spec.windup*.65: tell.text = "INTERRUPT / STRIKE DURING THE WARNING"
		elif nearest.stun>0.3:
			tell.text = "STAGGERED · STRIKE NOW"
		if nearest.kind=="hollow_weeper":
			if nearest.phase=="windup": tell.text = "CHEST RISING / SIDESTEP OR SOLID COVER" if nearest.clock<.9 else "SCREAM LOCKED / MOVE SIDEWAYS"
			elif nearest.phase=="sweep_windup": tell.text = "ARM SWEEP / STEP BACK"
			elif nearest.phase=="recover": tell.text = "EXHAUSTED / COUNTERATTACK"
			elif not nearest.engaged: tell.text = "OLD FAITH / PROTECTS THIS SITE"
		if nearest.poise>0 and nearest.kind in ["guardian","mournkeeper"]: tell.text += " / STAGGER %d/2" % ceili(nearest.poise)
		if nearest.brittle>0: tell.text += " / BRITTLE: LMB SHATTERS"
		if nearest.burning>0: tell.text += " / BURNING"
		if nearest.kind in ["guardian","mournkeeper"] and nearest.phase=="windup" and nearest.clock<nearest.spec.windup*0.65: tell.text += " / EARLY WINDUP: STAGGER WINDOW"
		if nearest.shielded:
			tell.text = "ECHO WARD · DEFEAT THE TWO SPIRITS"
	var bob: float = sin(s.elapsed*7)*minf(game.player.velocity.length()*0.8,3)
	var stroke := sin(clampf(1.0-game.swing/game.swing_duration,0,1)*PI) if game.swing>0 else 0.0
	weapon.position = Vector2(740,30+bob)
	weapon.rotation = 0
	weapon.scale = Vector2.ONE
	if game.swing_style==0:
		weapon.rotation = -0.85*stroke
		weapon.position += Vector2(-170,-70)*stroke
	else:
		var progress := clampf(1.0-game.swing/game.swing_duration,0,1) if game.swing>0 else 0.0
		var lift := sin(minf(progress/0.28,1.0)*PI/2.0)
		var chop := smoothstep(0.28,0.65,progress)
		var recover := smoothstep(0.70,1.0,progress)
		weapon.position += (Vector2(-200,-330)*lift+Vector2(15,520)*chop)*(1.0-recover)
		weapon.rotation = (-0.20*lift+0.32*chop)*(1.0-recover)
	shield.position = Vector2(-85,285) if game.blocking else Vector2(-230,400+bob)
	shield.rotation = -0.07 if game.blocking else 0
	if s.profile.profession_id=="cleric":
		weapon.position = Vector2(870,100+bob)
		weapon.rotation = 0
		shield.position = Vector2(0,420+bob)
		shield.rotation = 0
		if game.combat.gesture=="staff":
			weapon.position += Vector2(-130,-55)*stroke
			weapon.rotation = -0.30*stroke
		elif game.combat.gesture_clock>0:
			shield.position += Vector2(100,-140)*stroke
			weapon.position += Vector2(30,30)*stroke
	elif s.profile.profession_id=="mage":
		weapon.position = Vector2(900,350+bob)+Vector2(18,35)*stroke
		weapon.rotation = 0.08*stroke
		shield.position = Vector2(35,440+bob)+Vector2(60,-75)*stroke
		shield.rotation = -0.1*stroke
		shield.modulate = Color.WHITE
	casting_glyph.visible = game.modal=="" and game.started and s.profile.profession_id in ["mage","cleric"] and game.combat.visual_clock>0 and not game.offhand_busy()
	casting_glyph.queue_redraw()
	weapon.visible = game.modal=="" and game.started and s.profile.profession_id!="ranger"
	shield.visible = weapon.visible and not game.offhand_busy()
	torch_view.visible = game.modal=="" and game.started and game.torch_equipped
	lantern_view.visible = game.modal=="" and game.started and game.lantern.visible
	lantern_view.position.y = 180+bob*.5
	torch_view.position = Vector2(5,145+bob)
	if game.combat.gesture=="torch" and game.swing>0:
		torch_view.position += Vector2(150,-100)*stroke
	torch_view.modulate = Color.WHITE*(0.96+sin(s.elapsed*7)*0.04)

func close_modals() -> void:
	if preparation_panel: preparation_panel.hide()
	if private_panel: private_panel.hide()
	if keepsake_panel: keepsake_panel.hide()
	if creator: creator.hide()
	if coop_menu: coop_menu.hide()
	if backpack:
		backpack.hide()
		backpack.held = ""
		backpack.dragged_slot = -1
	if settings_panel:
		settings_panel.hide()
	modal.hide()
	map_panel.hide()
	pause_panel.hide()
	modal_type = ""

func make_world_settings() -> void:
	settings_world = Control.new()
	settings_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.add_child(settings_world)
	label("Visual wind strength",Vector2(30,127),18,settings_world)
	settings_wind = OptionButton.new()
	settings_wind.position = Vector2(30,161)
	settings_wind.size = Vector2(400,42)
	for value in ["Off","Gentle","Normal","Strong"]:
		settings_wind.add_item(value)
	settings_world.add_child(settings_wind)
	settings_wind.item_selected.connect(func(index): change_setting("wind_strength",index))
	label("Weather still affects exposure with wind visuals off.",Vector2(30,216),13,settings_world)
	label("Blood & spectral splashes",Vector2(30,268),18,settings_world)
	settings_blood = OptionButton.new()
	settings_blood.position = Vector2(30,303)
	settings_blood.size = Vector2(400,42)
	for value in ["Small splashes","Large / very bloody"]:
		settings_blood.add_item(value)
	settings_world.add_child(settings_blood)
	settings_blood.item_selected.connect(func(index): change_setting("blood_size",index))
	settings_lightning = CheckButton.new()
	settings_lightning.text = "Lightning flashes"
	settings_lightning.position = Vector2(25,374)
	settings_lightning.size = Vector2(405,45)
	settings_world.add_child(settings_lightning)
	settings_lightning.toggled.connect(func(on): change_setting("lightning",on))
	settings_intimacy = CheckButton.new()
	settings_intimacy.text = "Optional private invitations"
	settings_intimacy.position = Vector2(25,424)
	settings_intimacy.size = Vector2(405,42)
	settings_world.add_child(settings_intimacy)
	settings_intimacy.toggled.connect(func(on): change_setting("intimacy",on))
	settings_dense_grass = CheckButton.new()
	settings_dense_grass.text = "Dense grass coverage"
	settings_dense_grass.position = Vector2(25,472)
	settings_dense_grass.size = Vector2(405,42)
	settings_world.add_child(settings_dense_grass)
	settings_dense_grass.toggled.connect(func(on): change_setting("dense_grass",on))
	label("Keeps mushrooms, berries and firewood clear.\nSwitch off for lighter grass and better performance.",Vector2(30,518),12,settings_world)
	settings_world.hide()

func open_creator() -> void:
	creator.coop_mode = ""
	creator.recognition_color.hide()
	creator.color_label.hide()
	creator.refresh()
	game.set_modal("creator")
	title.hide()
	creator.show()
	creator.name_entry.grab_focus()

func make_relationship_panels() -> void:
	private_panel = Control.new()
	add_child(private_panel)
	private_panel.size = Vector2(1280,720)
	var backdrop := ColorRect.new()
	backdrop.color = Color("101c1d")
	backdrop.size = Vector2(1280,720)
	private_panel.add_child(backdrop)
	private_title = label("A LITTLE LAMPLIGHT",Vector2(330,40),29,private_panel,true)
	private_title.size.x = 620
	private_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait := TextureRect.new()
	portrait.position = Vector2(395,100)
	portrait.size = Vector2(490,455)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = load("res://assets/old-masters/mara-lamplight.png")
	private_portrait = portrait
	private_panel.add_child(portrait)
	private_caption = label("",Vector2(250,578),20,private_panel)
	private_caption.size.x = 780
	private_caption.size.y = 92
	private_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	private_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label("Esc leaves / ` records a paused field note",Vector2(450,677),14,private_panel)
	private_fade = ColorRect.new()
	private_fade.size = Vector2(1280,720)
	private_fade.color = Color(0,0,0,0)
	private_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	private_panel.add_child(private_fade)
	private_panel.hide()
	keepsake_panel = panel(Vector2(95,45),Vector2(1090,630),self)
	label("A PERSONAL KEEPSAKE",Vector2(475,35),27,keepsake_panel,true)
	keepsake_portrait = TextureRect.new()
	keepsake_portrait.position = Vector2(30,25)
	keepsake_portrait.size = Vector2(400,555)
	keepsake_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keepsake_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	keepsake_portrait.texture = load("res://assets/old-masters/mara-lamplight.png")
	keepsake_panel.add_child(keepsake_portrait)
	keepsake_text = RichTextLabel.new()
	keepsake_text.bbcode_enabled = true
	keepsake_text.position = Vector2(477,105)
	keepsake_text.size = Vector2(570,345)
	keepsake_text.add_theme_font_size_override("normal_font_size",23)
	keepsake_panel.add_child(keepsake_text)
	keepsake_mara_button = button("Mara",Vector2(477,460),Vector2(106,40),keepsake_panel,func(): show_keepsake("mara"))
	keepsake_lucan_button = button("Lucan",Vector2(587,460),Vector2(106,40),keepsake_panel,func(): show_keepsake("lucan"))
	for id in game.relationship.GENERIC:
		var index := extra_keepsake_buttons.size()+2
		var at := Vector2(477+(index%5)*110,460+int(index/5)*44)
		extra_keepsake_buttons[id] = button(game.C.NPCS[id].name.replace("Captain ",""),at,Vector2(106,40),keepsake_panel,func(): show_keepsake(id))
	# The general button padding enforces a height taller than this two-row grid.
	for selector in [keepsake_mara_button,keepsake_lucan_button]+extra_keepsake_buttons.values():
		for style_name in ["normal","hover","pressed"]:
			var style: StyleBoxFlat = selector.get_theme_stylebox(style_name).duplicate()
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			style.content_margin_left = 8
			style.content_margin_right = 8
			selector.add_theme_stylebox_override(style_name,style)
		selector.size = Vector2(106,40)
	button("Back to journal",Vector2(477,548),Vector2(300,46),keepsake_panel,show_map)
	keepsake_panel.hide()

func show_private_scene() -> void:
	private_fade.color.a = 0.0
	var mara: bool = game.relationship.active_id=="mara"
	private_portrait.texture = game.relationship.portrait_texture()
	style_graphic(private_portrait)
	private_title.text = "A LITTLE LAMPLIGHT" if mara else "AT THE TURNING TIDE"
	private_caption.text = "Behind the kitchen, Mara sets her cap aside.\n'We can leave the road at the door for a while.'" if mara else "Lucan sets the cups down and lets his hair loose.\n'For a little while, there's nowhere else I need to be.'"
	if game.relationship.active_id in game.relationship.GENERIC:
		private_title.text = game.relationship.Options.PEOPLE[game.relationship.active_id].title
		private_caption.text = game.relationship.Options.PEOPLE[game.relationship.active_id].invite
	private_panel.show()

func show_keepsake(id := "") -> void:
	game.set_modal("keepsake")
	if id.is_empty():
		id = "mara"
		for candidate in game.relationship.Options.PEOPLE:
			if game.state.keepsakes.has(candidate+"_lamplight"):
				id = candidate
				break
	var found: bool = game.state.keepsakes.get(id+"_lamplight",false)
	keepsake_portrait.visible = found
	keepsake_mara_button.visible = game.state.keepsakes.has("mara_lamplight")
	keepsake_lucan_button.visible = game.state.keepsakes.has("lucan_lamplight")
	for candidate in extra_keepsake_buttons:
		extra_keepsake_buttons[candidate].visible = game.state.keepsakes.has(candidate+"_lamplight")
	if found:
		keepsake_portrait.texture = game.relationship.portrait_texture(id)
		style_graphic(keepsake_portrait)
		keepsake_text.text = ("[b]Mara / A Little Lamplight[/b]\n\n'For a little while, neither of us had to be brave.'\n\nWayfarer's Rest" if id=="mara" else "[b]Lucan / The Turning Tide[/b]\n\n'There's room for what I lost and what I still want.'\n\nReedwater Landing")+"\n\nA quiet evening freely shared.\n\nThis keepsake belongs to "+game.state.profile.name+"."
	if found and id in game.relationship.GENERIC:
		var person: Dictionary = game.relationship.Options.PEOPLE[id]
		keepsake_text.text = "[b]"+game.C.NPCS[id].name+" / "+person.title+"[/b]\n\n"+person.after+"\n\n"+person.place+"\n\nThis keepsake belongs to "+game.state.profile.name+"."
	elif not found:
		keepsake_text.text = "There are no private keepsakes in this traveller's journal yet.\n\nFriendship and a completed journey need no memento to count."
	keepsake_panel.show()

func configure_equipment() -> void:
	var profession: String = game.state.profile.profession_id
	if equipment_profession==profession: return
	equipment_profession = profession
	if profession=="ranger": return
	if profession=="warrior":
		weapon.texture = load("res://assets/revision/sword-v2.png")
		shield.texture = load("res://assets/revision/shield-v2.png")
		weapon.size = Vector2(weapon.texture.get_width()*1000.0/weapon.texture.get_height(),1000)
		shield.size = Vector2(shield.texture.get_width()*800.0/shield.texture.get_height(),800)
		shield.flip_h = true
		weapon.pivot_offset = Vector2(weapon.size.x*0.46,580)
		shield.pivot_offset = Vector2(shield.size.x*0.85,900)
	else:
		var atlas: Texture2D = load("res://assets/professions/equipment-atlas.png")
		var cell := Vector2(atlas.get_size())/2.0
		for index in range(2):
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(Vector2(index,0 if profession=="cleric" else 1)*cell,cell)
			var target: TextureRect = weapon if index==0 else shield
			target.texture = texture
			target.size = Vector2(500,720) if profession=="cleric" and index==0 else Vector2(370,370) if index==1 else Vector2(420,420)
			target.pivot_offset = Vector2(target.size.x*0.7,target.size.y*0.85)
			target.flip_h = false
	weapon.scale = Vector2.ONE
	shield.modulate = Color.WHITE

func show_preparation() -> void:
	game.set_modal("preparation")
	if not preparation_panel:
		preparation_panel = Panel.new()
		preparation_panel.position = Vector2(320,170)
		preparation_panel.size = Vector2(640,370)
		add_child(preparation_panel)
		label("MORNING PREPARATION",Vector2(30,25),26,preparation_panel,true)
		label("Choose two learned spells for C and V.\nBasic attack and defence are always equipped.\nChange this selection only after safe rest.",Vector2(30,78),17,preparation_panel)
		for index in range(2):
			label("C slot" if index==0 else "V slot",Vector2(30,178+index*55),18,preparation_panel)
			var select := OptionButton.new()
			select.position = Vector2(135,170+index*55)
			select.size = Vector2(465,42)
			preparation_panel.add_child(select)
			preparation_slots.append(select)
			select.item_selected.connect(func(value):
				if preparation_slots[1-index].selected==value:
					preparation_slots[1-index].select((value+1)%select.item_count))
		preparation_confirm = button("Memorise and continue",Vector2(170,300),Vector2(300,45),preparation_panel,func():
			var list: Array = game.state.Progression.spells(game.state.profile.profession_id,game.state.xp)
			game.state.prepared = [list[preparation_slots[0].selected],list[preparation_slots[1].selected]]
			game.state.log_event("memorised:"+str(game.state.prepared))
			game.set_modal("")
			game.message("Prepared C: %s / V: %s" % [game.state.prepared[0].capitalize(),game.state.prepared[1].capitalize()],4))
	var spells: Array = game.state.Progression.spells(game.state.profile.profession_id,game.state.xp)
	for index in range(2):
		preparation_slots[index].clear()
		for spell in spells: preparation_slots[index].add_item("%s / %d mana" % [spell.capitalize(),game.combat.COSTS[spell]])
		preparation_slots[index].select(spells.find(game.state.prepared[index]))
	preparation_panel.show()

func select_settings_tab(index: int) -> void:
	settings_art.visible = index==0
	settings_world.visible = index==1
	settings_sounds.visible = index==2
	if settings_controls: settings_controls.visible = index==3
	settings_preview.visible = index<2
	settings_tag.visible = index<2
	settings_description.visible = index<2
	settings_reset_look.visible = index<2
	for i in range(settings_tabs.size()): settings_tabs[i].set_pressed_no_signal(i==index)

func make_sound_settings() -> void:
	settings_sounds = Control.new()
	settings_sounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.add_child(settings_sounds)
	label("THE SOUND OF THE ROADS",Vector2(30,128),24,settings_sounds,true)
	label("Changes apply immediately and are saved automatically.",Vector2(30,176),17,settings_sounds)
	settings_music_label = label("Music volume",Vector2(30,232),20,settings_sounds)
	settings_sound_label = label("Sound volume",Vector2(30,358),20,settings_sounds)
	for index in range(2):
		var slider := HSlider.new()
		slider.position = Vector2(30,274+index*126)
		slider.size = Vector2(720,32)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.tooltip_text = "0% is silent. Arrow keys adjust by 1%."
		settings_sounds.add_child(slider)
		var key: String = "music_volume" if index==0 else "sound_volume"
		slider.value_changed.connect(func(value):
			game.visuals.audio_values[key] = value/100.0
			game.audio.apply_volumes()
			sync_sound_settings()
			save_visuals())
		if index==0: settings_music_volume = slider
		else: settings_sound_volume = slider
	label("Title, day, night, forest, battle and private-scene music.",Vector2(30,318),16,settings_sounds)
	label("Combat, spells, NPC voices, footsteps, ambience and weather.",Vector2(30,444),16,settings_sounds)
	label("Mute can be rebound in Keybindings; your volume choices are kept.",Vector2(30,494),16,settings_sounds)
	settings_reset_sound = button("Reset sounds",Vector2(200,552),Vector2(230,48),settings_sounds,func():
		game.visuals.audio_values = game.visuals.AUDIO_DEFAULTS.duplicate()
		game.audio.apply_volumes()
		sync_sound_settings()
		save_visuals())

func sync_sound_settings() -> void:
	if not settings_music_volume: return
	var levels: Dictionary = game.visuals.audio_values
	settings_music_volume.set_value_no_signal(levels.music_volume*100)
	settings_sound_volume.set_value_no_signal(levels.sound_volume*100)
	settings_music_label.text = "Music volume  %d%%" % roundi(levels.music_volume*100)
	settings_sound_label.text = "Sound volume  %d%%" % roundi(levels.sound_volume*100)
