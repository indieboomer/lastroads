extends RefCounted

func key(code: int, down: bool, ctrl := false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code; ev.physical_keycode = code; ev.pressed = down; ev.ctrl_pressed = ctrl
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func pad(code: int, down: bool) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = 0; ev.button_index = code; ev.pressed = down
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func tap_pad(g: Node, code: int) -> void:
	pad(code,true)
	pad(code,false)
	await g.get_tree().process_frame

func find_button(root: Node, text: String) -> Button:
	for child in root.get_children():
		if child is Button and child.text==text: return child
		var found := find_button(child,text)
		if found: return found
	return null

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	await g.get_tree().process_frame
	var c = g.controls
	var original: Dictionary = c.defaults()
	assert(c.movement()==Vector2.ZERO)
	key(KEY_W,true)
	assert(c.held("forward") and c.movement().y< -0.9)
	key(KEY_W,false)
	assert(c.movement()==Vector2.ZERO)
	assert(c.stick(Vector2(0.1,0.1))==Vector2.ZERO)
	assert(c.stick(Vector2(0.6,0)).x>0 and c.stick(Vector2(0.6,0)).x<1)
	assert(is_equal_approx(c.stick(Vector2.ONE).length(),1))
	var axis := InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_TRIGGER_RIGHT; axis.axis_value = 0.8
	assert(c.pressed("attack",axis))
	assert(not c.pressed("attack",axis),"Trigger noise cannot repeatedly fire")
	axis.axis_value = 0
	assert(not c.pressed("attack",axis))
	axis.axis_value = 0.8
	assert(c.pressed("attack",axis),"A released trigger can fire again")
	c.apply()
	# Controller gameplay actions use the same live game paths.
	var was_lit: bool = g.lantern.visible
	await tap_pad(g,JOY_BUTTON_DPAD_DOWN)
	assert(g.lantern.visible!=was_lit)
	await tap_pad(g,JOY_BUTTON_DPAD_DOWN)
	assert(g.lantern.visible==was_lit)
	var motion := InputEventJoypadMotion.new()
	motion.device = 0; motion.axis = JOY_AXIS_RIGHT_X; motion.axis_value = 0.7
	Input.parse_input_event(motion.duplicate()); Input.flush_buffered_events()
	var yaw: float = g.player.rotation.y
	c.look(0.1)
	assert(g.player.rotation.y<yaw,"Right stick changes the actual camera heading")
	motion.axis_value = 0
	Input.parse_input_event(motion.duplicate()); Input.flush_buffered_events()
	motion.axis = JOY_AXIS_LEFT_Y; motion.axis_value = -0.6
	Input.parse_input_event(motion.duplicate()); Input.flush_buffered_events()
	assert(c.movement().y<0 and c.movement().length()<0.9,"Analog movement preserves partial tilt")
	motion.axis_value = 0
	Input.parse_input_event(motion.duplicate()); Input.flush_buffered_events()
	await tap_pad(g,JOY_BUTTON_START)
	assert(g.modal=="pause")
	await tap_pad(g,JOY_BUTTON_B)
	assert(g.modal=="")
	await tap_pad(g,JOY_BUTTON_DPAD_UP)
	assert(g.modal=="actions" and g.controls_view.actions.visible)
	await tap_pad(g,JOY_BUTTON_B)
	# Live binding capture, conflict swap and persistence.
	g.ui.open_settings("pause")
	g.ui.select_settings_tab(3)
	c.using_pad = true
	c.menu_tick(0)
	c.capture("interact","key")
	key(KEY_W,true); key(KEY_W,false)
	assert(c.bindings.interact.key[0].code==KEY_W and c.bindings.forward.key[0].code==KEY_E)
	c.capture("interact","key")
	key(KEY_ESCAPE,true); key(KEY_ESCAPE,false)
	assert(c.capture_action.is_empty() and g.modal=="settings")
	c.capture("interact","key")
	key(KEY_CTRL,true,true)
	assert(not c.capture_action.is_empty(),"Modifier press waits for its chord")
	key(KEY_K,true,true); key(KEY_K,false,true); key(KEY_CTRL,false)
	assert(c.bindings.interact.key[0].ctrl and c.bindings.interact.key[0].code==KEY_K)
	c.capture("interact","pad")
	await tap_pad(g,JOY_BUTTON_Y)
	assert(c.bindings.interact.pad[0].code==JOY_BUTTON_Y and c.bindings.reload.pad[0].code==JOY_BUTTON_X)
	var copy = preload("res://scripts/input_controls.gd").new()
	assert(copy.read(c.path))
	assert(copy.bindings==c.bindings)
	assert(c.bind("save","pad",{"type":"button","code":JOY_BUTTON_A}).begins_with("!"))
	assert(c.bindings.jump.pad[0].code==JOY_BUTTON_A,"A new binding must not silently remove jump")
	var bad := ConfigFile.new()
	bad.set_value("controls","bindings",{"jump":{"key":[{"type":"key","code":-1}],"pad":[]}})
	bad.save(g.data_root().path_join("reports/controls-invalid.cfg"))
	assert(not copy.read(g.data_root().path_join("reports/controls-invalid.cfg")))
	c.bindings = original.duplicate(true); c.apply(); c.write()
	g.controls_view.refresh_bindings()
	await g.capture("34-keybindings")
	# Native controller focus opens the keybindings tab.
	g.ui.select_settings_tab(0)
	c.using_pad = true; c.menu_tick(0)
	g.ui.settings_tabs[3].grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(g.ui.settings_controls.visible)
	g.controls_view.binding_buttons.forward.key.grab_focus()
	for i in range(10): await tap_pad(g,JOY_BUTTON_DPAD_DOWN)
	for child in g.controls_view.settings.get_children():
		if child is ScrollContainer: assert(child.scroll_vertical>0,"Controller focus scrolls through all binding rows")
	g.ui.show_map()
	c.cursor = Vector2(1000,350)
	var scroll_before: float = g.ui.journal.get_v_scroll_bar().value
	for i in range(4): await tap_pad(g,JOY_BUTTON_RIGHT_SHOULDER)
	assert(g.ui.journal.get_v_scroll_bar().value>scroll_before,"Controller shoulders scroll actual journal text")
	g.set_modal("")
	g.talk("mara")
	await g.get_tree().process_frame
	await tap_pad(g,JOY_BUTTON_A)
	assert(g.state.flags.accepted,"Controller confirms normal quest dialogue choices")
	g.set_modal("")
	# The pointer drives the real inventory GUI, including dragging to a slot.
	g.set_modal("inventory")
	c.menu_tick(0)
	g.state.pack.sync(g.state.inventory)
	var item: Dictionary = g.state.pack.layout.wood
	c.cursor = g.ui.backpack.position+g.ui.backpack.ORIGIN+Vector2(item.x,item.y)*g.ui.backpack.CELL+Vector2(12,12)
	c.pointer_mode = true
	pad(JOY_BUTTON_A,true)
	assert(g.ui.backpack.held=="wood","Pad pointer must pick up a real inventory item")
	c.cursor = g.ui.backpack.position+Vector2(766,595)
	pad(JOY_BUTTON_A,false)
	assert(g.state.pack.slots[7]=="wood" and g.ui.backpack.held.is_empty(),"Pad drag creates a shortcut")
	await tap_pad(g,JOY_BUTTON_X)
	assert(g.state.pack.slots[7].is_empty(),"Pad right click clears a quick slot")
	# Pointer coordinates must remain correct when the window is scaled.
	DisplayServer.window_set_size(Vector2i(1600,900))
	await g.get_tree().process_frame
	await g.get_tree().process_frame
	c.cursor = g.ui.backpack.position+g.ui.backpack.ORIGIN+Vector2(item.x,item.y)*g.ui.backpack.CELL+Vector2(12,12)
	c.pointer_mode = true
	pad(JOY_BUTTON_A,true)
	assert(g.ui.backpack.held=="wood","Scaled pad pointer must select the same item")
	c.cursor = g.ui.backpack.position+Vector2(766,595)
	pad(JOY_BUTTON_A,false)
	assert(g.state.pack.slots[7]=="wood")
	await tap_pad(g,JOY_BUTTON_B)
	assert(g.modal=="")
	# Controller-only text entry, including a real form submission.
	g.open_report()
	c.using_pad = true; c.menu_tick(0)
	g.ui.report_entry.grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(g.controls_view.keyboard.visible)
	var letter := find_button(g.controls_view.keyboard,"A")
	letter.grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(g.controls_view.entry.text=="A")
	g.controls_view.entry.text = "AUTOMATED controller field-note test"
	find_button(g.controls_view.keyboard,"Done").grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(not g.controls_view.keyboard.visible and g.ui.report_entry.text.begins_with("AUTOMATED"))
	c.menu_tick(0)
	find_button(g.ui.report_panel,"Save note").grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(not g.reporting)
	g.ui.open_creator()
	c.using_pad = true; c.menu_tick(0)
	g.ui.creator.origin.grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(g.ui.creator.origin.get_popup().visible,"Controller opens creator dropdowns")
	await tap_pad(g,JOY_BUTTON_B)
	assert(g.modal=="creator" and not g.ui.creator.origin.get_popup().visible,"Back closes a dropdown before the creator")
	g.controls_view.open_keyboard(g.ui.creator.age.get_line_edit())
	g.controls_view.entry.text = "42"
	find_button(g.controls_view.keyboard,"Done").grab_focus()
	await tap_pad(g,JOY_BUTTON_A)
	assert(g.ui.creator.age.value==42,"Controller text entry commits numeric fields")
	g.set_modal("")
	# Disconnecting during play stops movement and opens pause safely.
	c.pad_id = 42
	c.connection_changed(42,false)
	assert(c.pad_id==-1 and g.modal=="pause")
	g.set_modal("")
	g.controls_view.open_actions()
	await g.capture("34-controller-actions")
	g.controls_view.open_keyboard(g.ui.creator.name_entry)
	await g.capture("34-controller-keyboard")
	g.controls_view.close_keyboard()
	c.bindings = original; c.apply(); c.write()
	print("CONTROLS PASS: live key/pad actions, circular sticks, trigger edges, remap/swap/chords/cancel, config round trip/rejection, native menu focus, inventory pointer drag/clear, on-screen text/form submission, disconnect pause; physical pads: ",Input.get_connected_joypads().size())
	g.get_tree().quit()
