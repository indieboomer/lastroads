extends SceneTree

var g: Node
var frame := -1
var shot := -1
var caption: Label
var subtitle: Label
var veil: ColorRect
var shots := [
	[0.0,Vector2(0,-325),Vector2(0,-330),Vector3(0,2.5,-337),19.0,"THE DARK DOES NOT WAIT.",""],
	[2.0,Vector2(130,-371),Vector2(130,-376),Vector3(130,1.7,-390),20.0,"", ""],
	[3.3,Vector2(2,-327),Vector2(-2,-330),Vector3(0,2.4,-337),19.0,"NEITHER SHOULD YOU.",""],
	[5.0,Vector2(0,48),Vector2(-3,40),Vector3(-9,3,24),14.0,"", "BELLS OF THE HOLLOW"],
	[8.5,Vector2(-105,-140),Vector2(-112,-147),Vector3(-130,3,-166),15.0,"FOLLOW THE FORGOTTEN ROADS", ""],
	[12.0,Vector2(122,-177),Vector2(128,-185),Vector3(132,4,-211),16.5,"", ""],
	[15.0,Vector2(-106,-225),Vector2(-110,-232),Vector3(-124,2,-249),18.5,"SOME THINGS SHOULD STAY BURIED", ""],
	[18.0,Vector2(130,-373),Vector2(130,-380),Vector3(130,1.8,-400),20.0,"", ""],
	[20.5,Vector2(0,-54),Vector2(1,-58),Vector3(0,1.4,-65),16.0,"STEEL.", ""],
	[23.0,Vector2(63,-158),Vector2(63,-163),Vector3(63,1.5,-173),17.5,"SORCERY.", ""],
	[25.5,Vector2(120,-204),Vector2(122,-208),Vector3(125,1.6,-220),19.0,"SURVIVAL.", ""],
	[28.0,Vector2(-105,-225),Vector2(-108,-229),Vector3(-121,1.7,-241),20.0,"", ""],
	[30.0,Vector2(0,-325),Vector2(2,-329),Vector3(0,2.5,-337),19.5,"STAND AGAINST THE NIGHT", ""],
	[32.5,Vector2(130,-375),Vector2(130,-379),Vector3(130,1.7,-391),20.0,"", ""],
	[34.0,Vector2(1,-326),Vector2(-1,-330),Vector3(0,2.5,-337),19.0,"", ""],
	[36.0,Vector2(6,-311),Vector2(3,-316),Vector3(0,7,-341),7.0,"BRING BACK THE LIGHT", ""],
	[39.5,Vector2(0,47),Vector2(0,43),Vector3(-8,3,25),17.0,"THE LAST ROADS", "BELLS OF THE HOLLOW"],
]

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	current_scene = g
	g.test_mode = true
	g.start_new(preload("res://scripts/profession_checks.gd").new().profile("mage"))
	g.set_physics_process(false)
	g.set_process(false)
	g.set_process_input(false)
	g.audio.set_muted(true)
	for e in g.enemies: e.set_physics_process(false)
	g.visuals.values.enabled = true
	g.visuals.values.preset = 1
	g.visuals.values.detail = 2
	g.visuals.values.dither = 0.50
	g.visuals.values.grain = 0.30
	g.ui.apply_visuals()
	for child in g.ui.get_children():
		if child is CanvasItem and child != g.ui.hud_root: child.hide()
	for child in g.ui.hud_root.get_children():
		if child is CanvasItem: child.hide()
	g.ui.hud_root.show()
	g.ui.retro_copy.show()
	g.ui.retro_effect.show()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	for y in [0,656]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0,y)
		bar.size = Vector2(1280,64)
		layer.add_child(bar)
	caption = make_label(layer,Vector2(60,510),Vector2(1160,90),36)
	subtitle = make_label(layer,Vector2(60,601),Vector2(1160,44),18)
	veil = ColorRect.new()
	veil.size = Vector2(1280,720)
	veil.color = Color(0,0,0,0)
	layer.add_child(veil)
	frame = 1080 if "--trailer-ending" in OS.get_cmdline_user_args() else 0

func make_label(parent: Node, pos: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font",load("res://assets/fonts/Cinzel.ttf"))
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("f1dfb6"))
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_y",3)
	parent.add_child(label)
	return label

func _process(_delta: float) -> bool:
	if frame < 0: return false
	var t := frame/30.0
	if t >= 45.0:
		print("TRAILER COMPLETE: 1350 frames; audited release PCK; fictional NPC art only")
		quit()
		return false
	var next := 0
	for i in shots.size():
		if t >= shots[i][0]: next = i
	if shot != next:
		shot = next
		g.combat.reset()
		g.state.day_clock = shots[shot][4]
		caption.text = shots[shot][5]
		subtitle.text = shots[shot][6]
		if shot == 0: g.spawn_enemy("trailer_warden","guardian",Vector2(0,-337))
		if shot == 9: g.spawn_enemy("trailer_bandit","bandit",Vector2(63,-173))
		if shot == 10: g.spawn_enemy("trailer_wraith","wraith",Vector2(125,-220))
		if shot == 15:
			g.state.flags.won = true
			g.state.flags.beacon_lit = true
			for e in g.enemies:
				e.dead = true
				e.hide()
				e.collision_layer = 0
			g.world.apply_state()
		if shot == 16:
			caption.position.y = 265
			caption.add_theme_font_size_override("font_size",66)
			subtitle.position.y = 365
			subtitle.add_theme_font_size_override("font_size",24)
	var end: float = shots[shot+1][0] if shot+1 < shots.size() else 45.0
	var local: float = t-shots[shot][0]
	var fraction: float = local/(end-shots[shot][0])
	var at: Vector2 = shots[shot][1].lerp(shots[shot][2],fraction)
	g.teleport(at)
	g.camera.position.y = g.eye_height + sin(local*2)*0.025
	g.camera.look_at(shots[shot][3])
	g.camera.fov = lerpf(79,71,fraction)
	g.state.elapsed = t
	g.world.tick(1.0/30)
	g.combat.tick(1.0/30)
	g.state.health = g.state.max_health
	if shot in [0,2,8,9,10,11,12,13,14]:
		for e in g.enemies:
			if not e.dead and e.position.distance_to(g.player.position)<28:
				e.tick(1.0/30)
	if shot in [0,2,8,9,10,11,12,13,14] and frame%24 == 5:
		var kind: String = ["ember","rime","dart"][int(frame/24)%3]
		g.combat.launch(kind)
		g.combat.animate(kind)
	if shot in [0,2,12,14]:
		for e in g.enemies:
			if e.kind == "guardian":
				e.position.y = g.C.height_at(e.position.x,e.position.z)+0.25+sin(t*4)*0.07
	caption.modulate.a = minf(1.0,local*5.0) * (1.0 if shot == 16 else minf(1.0,(end-t)*5.0))
	veil.color.a = clampf((t-43.5)/1.5,0,1)
	frame += 1
	return false
