extends RefCounted

func mouse(ui: Control, point: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT, shift := false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = pressed
	event.shift_pressed = shift
	ui._gui_input(event)

func run(g: Node) -> void:
	var profile: Dictionary = preload("res://scripts/character_data.gd").defaults()
	profile.profession_id = "mage"
	g.start_new(profile)
	g.set_physics_process(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	var ui: Control = g.ui.backpack
	var pack = g.state.pack
	for key in pack.ITEMS: g.state.inventory[key] = 3
	assert(pack.arrange(g.state.inventory))
	var stock: Dictionary = g.state.inventory.duplicate(true)
	var layout: Dictionary = pack.layout.duplicate(true)
	for key in pack.ITEMS:
		for i in range(8): assert(pack.bind_slot(i,key),"Every supply must fit every shortcut")
	assert(g.state.inventory==stock and pack.layout==layout)
	assert(not pack.bind_slot(0,"unknown_item"))
	assert(not pack.bind_slot(8,"bread"))
	g.teleport(Vector2(12.715352,-174.671616),-3.0139775)
	g.camera.rotation.x = -.18300423
	g.set_modal("inventory")
	for key in ["lantern","torch","rest"]:
		for child in ui.get_children():
			if child is Button and child.text.begins_with(key.capitalize()):
				child.pressed.emit()
				assert(ui.selected==key,"Each carried-gear button selects its own action")
	ui.select_action("lantern")
	var initial_light: bool = g.lantern.visible
	for child in ui.get_children():
		if child is Button and child.text=="Use / activate selected":
			child.pressed.emit()
			assert(g.lantern.visible!=initial_light)
			child.pressed.emit()
			assert(g.lantern.visible==initial_light)
	for child in ui.get_children():
		if child is Button and child.text in ["Auto-arrange","Close [I]"]: assert(child.position.y==24)
	var scrap: Dictionary = pack.layout.scrap
	var pick: Vector2 = ui.ORIGIN+Vector2(scrap.x,scrap.y)*ui.CELL+Vector2(12,12)
	mouse(ui,pick,true)
	assert(ui.held=="scrap")
	mouse(ui,Vector2(36+7*100+30,595),false)
	assert(pack.slots[7]=="scrap" and ui.held.is_empty())
	assert(g.state.inventory==stock and pack.layout==layout,"Dragging creates only a shortcut")
	ui.selected = "moonwort"
	ui.handle_key(KEY_8)
	assert(pack.slots[7]=="moonwort")
	mouse(ui,Vector2(766,595),true,MOUSE_BUTTON_RIGHT)
	assert(pack.slots[7].is_empty())
	pack.bind_slot(0,"fur")
	pack.bind_slot(1,"essence")
	mouse(ui,Vector2(65,595),true,MOUSE_BUTTON_LEFT,true)
	mouse(ui,Vector2(165,595),false)
	assert(pack.slots[0]=="essence" and pack.slots[1]=="fur")
	assert(g.state.inventory==stock and pack.layout==layout)
	# Materials and poisonous plants inspect; neither is consumed or grants health.
	g.set_modal("")
	pack.bind_slot(0,"toadstools")
	var health: float = g.state.health
	g.use_quick_slot(0)
	assert(g.modal=="inventory" and ui.selected=="toadstools" and g.state.inventory==stock and g.state.health==health)
	g.use_item("toadstools")
	assert(g.state.inventory==stock and g.state.health==health)
	# Reusable equipment is visible in the pack and can replace any slot.
	ui.select_action("lantern")
	ui.handle_key(KEY_1)
	ui.select_action("torch")
	ui.handle_key(KEY_2)
	assert(pack.slots[0]=="lantern" and pack.slots[1]=="torch")
	g.set_modal("")
	var lit: bool = g.lantern.visible
	g.press_key(KEY_1)
	assert(g.lantern.visible!=lit)
	g.press_key(KEY_L)
	assert(g.lantern.visible==lit)
	g.press_key(KEY_2)
	assert(g.torch_equipped)
	g.press_key(KEY_T)
	assert(not g.torch_equipped and g.state.inventory==stock)
	# Empty stacks retain bindings, and replenishing them revives the shortcut.
	pack.bind_slot(2,"berries")
	g.state.health = 10
	g.state.inventory.berries = 1
	g.use_quick_slot(2)
	assert(g.state.inventory.berries==0 and pack.slots[2]=="berries")
	g.state.inventory.berries = 2
	g.use_quick_slot(2)
	assert(g.state.inventory.berries==1 and g.state.health==30)
	pack.bind_slot(7,"scrap")
	assert(g.save_game() and g.load_game())
	assert(g.state.pack.slots[7]=="scrap" and g.state.pack.slots[0]=="lantern")
	# Recorded saves remain valid and retain their exact shortcut assignments.
	for id in ["2026-11-09T17-36-54-246821871","2026-11-09T17-37-52-304536329","2026-11-09T17-42-12-564803604"]:
		var path: String = g.data_root().path_join("debug-logs/"+id+"/report.json")
		if not FileAccess.file_exists(path): continue
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert(g.validate_save(report))
		var restored = g.State.new()
		assert(restored.read_dict(report.state,5) and restored.pack.slots==report.state.backpack.slots)
	g.set_modal("inventory")
	ui.selected = "scrap"
	ui.notice = "Every slot accepts any supply. Bindings never move items out of the pack."
	for retro in [false,true]:
		g.visuals.values.enabled = retro
		g.visuals.values.preset = 1
		g.ui.apply_visuals()
		await g.capture("25-inventory-"+("copper" if retro else "original"))
	ui.select_action("lantern")
	await g.capture("25-carried-lights")
	# The older floor report is the inn's roofed porch, beyond its main walls.
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	assert(not g.world.outside_buildings(Vector2(-10.291915,40.820953),.5))
	for node in g.get_tree().get_nodes_in_group("fruit_bush_sprites"):
		if not node.visible: continue
		assert(g.world.outside_buildings(Vector2(node.position.x,node.position.z),1.0),"Bush must clear floors, including the inn porch")
	g.player.position = Vector3(-10.291915,1.212834,40.820953)
	g.player.rotation.y = -.4752056
	g.camera.rotation.x = -.4679003
	g.state.day_clock = 12
	g.world.tick(0)
	await g.capture("25-inn-porch-clear")
	print("INVENTORY PASS: all supplies/all slots, drag and replace without moving stock, clear/swap, materials inspect, reusable carried lights, depleted/replenished stacks, save compatibility, raised buttons and porch vegetation exclusion")
	g.get_tree().quit()
