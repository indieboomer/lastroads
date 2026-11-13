extends RefCounted

const ACTIONS := [
	["forward","Move forward",KEY_W],["back","Move backward",KEY_S],
	["left","Move left",KEY_A],["right","Move right",KEY_D],
	["jump","Jump",KEY_SPACE],["sprint","Sprint / travel stride",KEY_SHIFT],
	["attack","Basic attack",0],["defend","Block / aim / offhand",0],
	["heavy","Heavy attack / dagger",KEY_Q],["primary","Primary ability / pistol",KEY_C],
	["secondary","Secondary ability / musket",KEY_V],["interact","Talk / interact",KEY_E],
	["reload","Reload / pack rotation",KEY_R],["inventory","Inventory",KEY_I],
	["map","Journal / map",KEY_M],["tools","Quick slots & actions",KEY_Z],
	["lantern","Lantern",KEY_L],["torch","Torch",KEY_T],
	["camp","Build campfire",KEY_F],["rest","Rest",KEY_G],
	["pause","Pause / back",KEY_ESCAPE],["save","Quick save",KEY_F5],
	["load","Quick load",KEY_F9],["report","Field note",KEY_QUOTELEFT],
	["coop","Co-op menu",KEY_F6],["fullscreen","Fullscreen",KEY_F11],["mute","Mute",KEY_F10],
	["slot1","Quick slot 1",KEY_1],["slot2","Quick slot 2",KEY_2],
	["slot3","Quick slot 3",KEY_3],["slot4","Quick slot 4",KEY_4],
	["slot5","Quick slot 5",KEY_5],["slot6","Quick slot 6",KEY_6],
	["slot7","Quick slot 7",KEY_7],["slot8","Quick slot 8",KEY_8]
]
const TUNING := {"mouse_sensitivity":1.0,"look_sensitivity":2.4,"deadzone":0.2,"invert_y":false,"cursor_speed":650.0}
var game: Node
var view: CanvasLayer
var bindings: Dictionary = {}
var tuning: Dictionary = TUNING.duplicate()
var path := ""
var pad_id := -1
var using_pad := false
var pointer_mode := false
var cursor := Vector2(640,360)
var trigger_edges: Dictionary = {}
var simulated_mouse := false
var dispatching_mouse := false
var capture_action := ""
var capture_kind := "key"
var menu_stamp := ""
var save_error := OK

func name_of(id: String) -> StringName: return StringName("roads_"+id)

func defaults() -> Dictionary:
	var result := {}
	for row in ACTIONS:
		result[row[0]] = {"key":[{"type":"key","code":row[2]}] if row[2]!=0 else [],"pad":[]}
	result.attack.key = [{"type":"mouse","code":MOUSE_BUTTON_LEFT}]
	result.defend.key = [{"type":"mouse","code":MOUSE_BUTTON_RIGHT}]
	result.map.key.append_array([{"type":"key","code":KEY_J},{"type":"key","code":KEY_TAB}])
	var axes: Dictionary = {"left":[0,-1],"right":[0,1],"forward":[1,-1],"back":[1,1],"defend":[4,1],"attack":[5,1]}
	for id in axes:
		result[id].pad = [{"type":"axis","code":axes[id][0],"sign":axes[id][1]}]
	var buttons := {"jump":JOY_BUTTON_A,"interact":JOY_BUTTON_X,"heavy":JOY_BUTTON_B,"reload":JOY_BUTTON_Y,
		"sprint":JOY_BUTTON_LEFT_STICK,"torch":JOY_BUTTON_RIGHT_STICK,"primary":JOY_BUTTON_RIGHT_SHOULDER,
		"secondary":JOY_BUTTON_LEFT_SHOULDER,"pause":JOY_BUTTON_START,"tools":JOY_BUTTON_DPAD_UP,
		"inventory":JOY_BUTTON_DPAD_LEFT,"map":JOY_BUTTON_DPAD_RIGHT,"lantern":JOY_BUTTON_DPAD_DOWN}
	for id in buttons: result[id].pad = [{"type":"button","code":buttons[id]}]
	result.tools.pad.append({"type":"button","code":JOY_BUTTON_BACK})
	return result

func setup(g: Node) -> void:
	game = g
	path = g.data_root().path_join("reports/integration-controls.cfg" if g.test_mode else "controls.cfg")
	bindings = defaults()
	if not g.test_mode: read(path)
	apply()
	# This project has no editor InputMap section; UI defaults contain keys only.
	var codes := {"ui_accept":JOY_BUTTON_A,"ui_cancel":JOY_BUTTON_B,"ui_left":JOY_BUTTON_DPAD_LEFT,"ui_right":JOY_BUTTON_DPAD_RIGHT,"ui_up":JOY_BUTTON_DPAD_UP,"ui_down":JOY_BUTTON_DPAD_DOWN}
	for action in codes:
		var event := InputEventJoypadButton.new()
		event.button_index = codes[action]; event.device = -1
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
	var devices := Input.get_connected_joypads()
	if not devices.is_empty(): pad_id = devices[0]
	Input.joy_connection_changed.connect(connection_changed)

func event_from(record: Dictionary) -> InputEvent:
	var ev: InputEvent
	match record.type:
		"key":
			ev = InputEventKey.new()
			ev.physical_keycode = int(record.code)
			ev.shift_pressed = record.get("shift",false)
			ev.ctrl_pressed = record.get("ctrl",false)
			ev.alt_pressed = record.get("alt",false)
		"mouse": ev = InputEventMouseButton.new(); ev.button_index = int(record.code)
		"button": ev = InputEventJoypadButton.new(); ev.button_index = int(record.code)
		"axis": ev = InputEventJoypadMotion.new(); ev.axis = int(record.code); ev.axis_value = float(record.sign)
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion: ev.device = -1
	return ev

func apply() -> void:
	for row in ACTIONS:
		var action := name_of(row[0])
		if not InputMap.has_action(action): InputMap.add_action(action)
		Input.action_release(action)
		InputMap.action_erase_events(action)
		InputMap.action_set_deadzone(action,float(tuning.deadzone))
		for kind in ["key","pad"]:
			for record in bindings[row[0]][kind]: InputMap.action_add_event(action,event_from(record))
	trigger_edges.clear()

func valid_record(r: Variant, kind: String) -> bool:
	if not r is Dictionary or not r.get("type") is String: return false
	var code: Variant = r.get("code")
	if not (code is int or code is float) or not is_finite(float(code)) or code!=floor(code): return false
	if kind=="key":
		if r.type=="mouse": return code>=1 and code<=9
		if r.type!="key" or code<=0 or code>0x7fffff: return false
		for modifier in ["shift","ctrl","alt"]:
			if r.has(modifier) and not r[modifier] is bool: return false
		return true
	if r.type=="button": return code>=0 and code<JOY_BUTTON_MAX
	return r.type=="axis" and code>=0 and code<JOY_AXIS_MAX and r.get("sign") in [-1,1]

func read(file: String) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(file)!=OK: return false
	var saved: Variant = cfg.get_value("controls","bindings",{})
	var settings: Variant = cfg.get_value("controls","tuning",{})
	if not saved is Dictionary or not settings is Dictionary: return false
	var next := defaults()
	for id in saved:
		if not next.has(id) or not saved[id] is Dictionary: return false
		for kind in ["key","pad"]:
			var records: Variant = saved[id].get(kind)
			if not records is Array or records.size()>3: return false
			for record in records:
				if not valid_record(record,kind): return false
			next[id][kind] = records.duplicate(true)
	var next_tuning := TUNING.duplicate()
	for key in settings:
		if not next_tuning.has(key): return false
		if key=="invert_y":
			if not settings[key] is bool: return false
		else:
			var value: Variant = settings[key]
			if not (value is float or value is int) or not is_finite(float(value)): return false
			if key=="deadzone" and (value<0.05 or value>0.5): return false
			if key=="mouse_sensitivity" and (value<0.2 or value>3): return false
			if key=="look_sensitivity" and (value<0.5 or value>6): return false
			if key=="cursor_speed" and (value<200 or value>1200): return false
		next_tuning[key] = settings[key]
	bindings = next
	tuning = next_tuning
	return true

func write() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("controls","bindings",bindings)
	cfg.set_value("controls","tuning",tuning)
	save_error = cfg.save(path)
	return save_error

func label_record(r: Dictionary) -> String:
	if r.type=="button":
		return {0:"A / Cross",1:"B / Circle",2:"X / Square",3:"Y / Triangle",4:"Back",6:"Start / Options",7:"L3",8:"R3",9:"LB / L1",10:"RB / R1",11:"D-pad Up",12:"D-pad Down",13:"D-pad Left",14:"D-pad Right"}.get(int(r.code),"Pad "+str(r.code))
	if r.type=="axis":
		if r.code==4: return "LT / L2"
		if r.code==5: return "RT / R2"
		if r.code==0: return "Left stick "+("right" if r.sign>0 else "left")
		if r.code==1: return "Left stick "+("down" if r.sign>0 else "up")
		return "Axis %d %s" % [r.code,"+" if r.sign>0 else "-"]
	return event_from(r).as_text()

func hint(id: String, pad := using_pad) -> String:
	var events: Array = bindings[id]["pad" if pad else "key"]
	if events.is_empty(): return "Actions" if pad else "Unbound"
	return label_record(events[0]).replace(" (Physical)","").replace(" (physical)","")

func help_text() -> String:
	var text := "Move with the left stick; look with the right stick.\n" if using_pad else "Move: %s / %s / %s / %s. Look with the mouse.\n" % [hint("forward"),hint("left"),hint("back"),hint("right")]
	text += "%s interact / %s attack / %s defence or aim / %s heavy or dagger.\n" % [hint("interact"),hint("attack"),hint("defend"),hint("heavy")]
	text += "%s / %s profession abilities. %s jump. %s sprint.\n" % [hint("primary"),hint("secondary"),hint("jump"),hint("sprint")]
	text += "%s inventory / %s journal / %s quick slots and road actions.\n" % [hint("inventory"),hint("map"),hint("tools")]
	text += "%s lantern / %s torch. Stow a held light to free your offhand.\n" % [hint("lantern"),hint("torch")]
	text += "Rangers must reload each shot. Warriors time defence just before impact to parry. Casters regain mana; safe rest prepares spells.\n\nYou can change controls in Settings / Keybindings. The Actions menu includes campfire, rest, reload, quick slots, save/load and field notes."
	return text

func pressed(id: String, ev: InputEvent) -> bool:
	if ev is InputEventJoypadMotion:
		var matched := false
		var down := false
		for record in bindings[id].pad:
			if record.type=="axis" and record.code==ev.axis:
				matched = true
				down = ev.axis_value*float(record.sign)>0.55
		if not matched: return false
		var prior: bool = trigger_edges.get(id,false)
		trigger_edges[id] = down
		return down and not prior
	if not ev.is_action(name_of(id)): return false
	return ev.is_pressed() and not ev.is_echo()

func held(id: String) -> bool: return Input.is_action_pressed(name_of(id))

func movement() -> Vector2:
	return Input.get_vector(name_of("left"),name_of("right"),name_of("forward"),name_of("back"),float(tuning.deadzone))

func stick(raw: Vector2) -> Vector2:
	var strength := raw.length()
	if strength<=float(tuning.deadzone): return Vector2.ZERO
	return raw.normalized()*clampf((strength-float(tuning.deadzone))/(1.0-float(tuning.deadzone)),0,1)

func look(dt: float) -> void:
	if pad_id<0: return
	var aim := stick(Vector2(Input.get_joy_axis(pad_id,JOY_AXIS_RIGHT_X),Input.get_joy_axis(pad_id,JOY_AXIS_RIGHT_Y)))
	game.player.rotate_y(-aim.x*float(tuning.look_sensitivity)*dt)
	game.camera.rotation.x = clampf(game.camera.rotation.x-aim.y*float(tuning.look_sensitivity)*dt*(-1 if tuning.invert_y else 1),-1.25,1.25)

func capture(id: String, kind: String) -> void:
	capture_action = id; capture_kind = kind
	view.status.text = "Press a key/mouse button or controller button/trigger. Esc / Back cancels."

func bind(id: String, kind: String, record: Dictionary) -> String:
	var old: Array = bindings[id][kind].duplicate(true)
	var swapped := ""
	# An action without a previous binding has nothing to swap back. Do not
	# silently remove another action's only controller input in that case.
	if old.is_empty():
		for other in bindings:
			if other==id or bindings[other][kind].size()!=1: continue
			if event_from(bindings[other][kind][0]).is_match(event_from(record)):
				return "!Already used by "+other+". Rebind that action first, or use the Actions menu."
	for other in bindings:
		if other==id: continue
		for previous in bindings[other][kind]:
			if event_from(previous).is_match(event_from(record)):
				if old.is_empty(): bindings[other][kind].erase(previous)
				else: bindings[other][kind] = old.slice(0,1)
				swapped = other
				break
	bindings[id][kind] = [record]
	apply()
	write()
	return swapped

func capture_event(ev: InputEvent) -> bool:
	if capture_action.is_empty(): return false
	if ev is InputEventKey and ev.pressed and ev.keycode==KEY_ESCAPE or ev is InputEventJoypadButton and ev.pressed and ev.button_index==JOY_BUTTON_BACK:
		capture_action = ""; view.status.text = "Binding cancelled."; return true
	var record := {}
	if capture_kind=="key":
		if ev is InputEventKey and not ev.echo and ((ev.pressed and ev.keycode not in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META]) or (not ev.pressed and ev.keycode in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META])):
			record = {"type":"key","code":ev.physical_keycode if ev.physical_keycode!=0 else ev.keycode,"shift":ev.shift_pressed and ev.keycode!=KEY_SHIFT,"ctrl":ev.ctrl_pressed and ev.keycode!=KEY_CTRL,"alt":ev.alt_pressed and ev.keycode!=KEY_ALT}
		elif ev is InputEventMouseButton and ev.pressed: record = {"type":"mouse","code":ev.button_index}
	else:
		if ev is InputEventJoypadButton and ev.pressed: record = {"type":"button","code":ev.button_index}
		elif ev is InputEventJoypadMotion and ev.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and ev.axis_value>0.65: record = {"type":"axis","code":ev.axis,"sign":1}
	if not record.is_empty():
		var swapped := bind(capture_action,capture_kind,record)
		capture_action = ""
		view.refresh_bindings()
		if swapped.begins_with("!"): view.status.text = swapped.trim_prefix("!")
		else: view.status.text = "Binding saved."+(" Swapped with "+swapped+"." if not swapped.is_empty() else "") if save_error==OK else "Could not save controls: "+error_string(save_error)
	return true

func connection_changed(device: int, connected: bool) -> void:
	if connected and pad_id<0: pad_id = device
	elif not connected and device==pad_id:
		pad_id = -1
		using_pad = false
		pointer_mode = false
		for row in ACTIONS: Input.action_release(name_of(row[0]))
		trigger_edges.clear()
		mouse_click(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if game.started and game.modal=="": game.set_modal("pause"); game.message("Controller disconnected. Reconnect it or use keyboard and mouse.",8)

func mouse_click(down: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button; ev.pressed = down; ev.position = cursor; ev.global_position = cursor
	if button==MOUSE_BUTTON_LEFT: simulated_mouse = down
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if simulated_mouse else 0
	dispatching_mouse = true
	game.get_viewport().push_input(ev,true)
	dispatching_mouse = false

func focus_first(root: Node) -> void:
	for child in root.get_children():
		if child is Control and not child.is_visible_in_tree(): continue
		if child is Control and child.focus_mode!=Control.FOCUS_NONE and (child is BaseButton and not child.disabled or child is LineEdit or child is TextEdit):
			child.grab_focus(); return
		focus_first(child)
		if game.get_viewport().gui_get_focus_owner()!=null: return

func focus_root() -> Node:
	if view.keyboard.visible: return view.keyboard
	if game.reporting: return game.ui.report_panel
	if game.modal=="actions": return view.actions
	return game.ui

func focus_default() -> void:
	if game.modal=="dialog" and not game.reporting and not view.keyboard.visible:
		for option in game.ui.choices:
			if option.visible and not option.disabled:
				option.grab_focus()
				return
	focus_first(focus_root())

func menu_tick(dt: float) -> void:
	if not view: return
	view.actions.visible = game.modal=="actions"
	var menu: bool = game.modal!="" or not game.started or game.reporting
	if not menu:
		if simulated_mouse: mouse_click(false)
		view.pointer.hide()
		menu_stamp = ""
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if using_pad else Input.MOUSE_MODE_VISIBLE
	var stamp: String = game.modal+str(game.reporting)+str(view.keyboard.visible)
	if stamp!=menu_stamp:
		menu_stamp = stamp; pointer_mode = false
		if simulated_mouse: mouse_click(false)
		if using_pad:
			var old: Control = game.get_viewport().gui_get_focus_owner()
			if old: old.release_focus()
			focus_default()
	if using_pad and pad_id>=0:
		var motion := stick(Vector2(Input.get_joy_axis(pad_id,JOY_AXIS_LEFT_X),Input.get_joy_axis(pad_id,JOY_AXIS_LEFT_Y)))
		motion += stick(Vector2(Input.get_joy_axis(pad_id,JOY_AXIS_RIGHT_X),Input.get_joy_axis(pad_id,JOY_AXIS_RIGHT_Y)))
		if motion.length()>0.01:
			pointer_mode = true
			var prior := cursor
			cursor = (cursor+motion.limit_length()*float(tuning.cursor_speed)*dt).clamp(Vector2(3,3),Vector2(1277,717))
			Input.warp_mouse(cursor)
			var ev := InputEventMouseMotion.new()
			ev.position = cursor; ev.global_position = cursor; ev.relative = cursor-prior
			ev.button_mask = MOUSE_BUTTON_MASK_LEFT if simulated_mouse else 0
			game.get_viewport().push_input(ev,true)
	view.pointer.visible = using_pad and pointer_mode
	view.pointer.position = cursor-Vector2(8,8)

func menu_pad(ev: InputEventJoypadButton) -> bool:
	if not pointer_mode and game.get_viewport().gui_get_focus_owner()==null: focus_default()
	if ev.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
		pointer_mode = false
		if game.get_viewport().gui_get_focus_owner()==null: focus_default()
		return false
	if ev.button_index==JOY_BUTTON_B and ev.pressed:
		if view.keyboard.visible: view.close_keyboard()
		else: cancel_menu()
		return true
	if ev.button_index==JOY_BUTTON_START and ev.pressed: cancel_menu(); return true
	if game.modal=="inventory":
		if ev.button_index==JOY_BUTTON_Y and ev.pressed: game.ui.backpack.handle_key(KEY_R); return true
		if ev.button_index==JOY_BUTTON_X: mouse_click(ev.pressed,MOUSE_BUTTON_RIGHT); return true
		if ev.button_index==JOY_BUTTON_A and (pointer_mode or not game.get_viewport().gui_get_focus_owner() is BaseButton): mouse_click(ev.pressed); return true
	if ev.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER] and ev.pressed:
		mouse_click(true,MOUSE_BUTTON_WHEEL_UP if ev.button_index==JOY_BUTTON_LEFT_SHOULDER else MOUSE_BUTTON_WHEEL_DOWN)
		return true
	if ev.button_index==JOY_BUTTON_A:
		var focus: Control = game.get_viewport().gui_get_focus_owner()
		if not pointer_mode and ev.pressed and focus is SpinBox: view.open_keyboard(focus.get_line_edit()); return true
		if not pointer_mode and ev.pressed and (focus is LineEdit or focus is TextEdit): view.open_keyboard(focus); return true
		if pointer_mode:
			mouse_click(ev.pressed)
			if ev.pressed:
				focus = game.get_viewport().gui_get_focus_owner()
				if focus is LineEdit or focus is TextEdit: view.open_keyboard(focus)
			return true
	return false

func close_popup(root: Node) -> bool:
	for child in root.get_children(true):
		if child is PopupMenu and child.visible:
			child.hide()
			return true
		if close_popup(child): return true
	return false

func cancel_menu() -> void:
	if view.keyboard.visible: view.close_keyboard(); return
	if game.reporting: game.close_report(); return
	if close_popup(game.ui): return
	if game.modal=="settings":
		game.ui.leave_settings()
	elif game.modal=="inventory" and game.ui.backpack.cancel_drag(): return
	elif game.modal=="intimacy" and game.relationship.committed: game.relationship.aftermath()
	elif game.modal=="coop": game.ui.coop_menu.close()
	elif game.modal=="creator": game.set_modal(""); game.ui.title.show()
	elif game.modal!="": game.set_modal("")
	elif game.started: game.set_modal("pause")

func handle_input(ev: InputEvent) -> bool:
	if not view: return false
	if dispatching_mouse: return false
	if ev is InputEventJoypadButton and ev.pressed or ev is InputEventJoypadMotion and absf(ev.axis_value)>float(tuning.deadzone):
		using_pad = true; pad_id = ev.device
	elif ev is InputEventKey and ev.pressed or ev is InputEventMouseButton and ev.pressed:
		using_pad = false
	if capture_event(ev): return true
	var menu: bool = game.modal!="" or not game.started or game.reporting
	if menu and ev is InputEventJoypadButton: return menu_pad(ev)
	if menu and ev is InputEventJoypadMotion: return false
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode==KEY_ESCAPE: cancel_menu(); return true
	var focus: Control = game.get_viewport().gui_get_focus_owner()
	if menu and (focus is LineEdit or focus is TextEdit):
		if game.reporting and ev is InputEventKey and ev.pressed and ev.keycode in [KEY_ENTER,KEY_KP_ENTER]:
			if ev.shift_pressed: game.ui.report_entry.insert_text_at_caret("\n")
			else: game.submit_report()
			return true
		return false
	if menu and ev is InputEventMouseButton: return false
	# Remapping a game action to Enter, an arrow or the primary mouse button
	# must never take away the UI's own confirmation and navigation controls.
	if menu and ev is InputEventKey and ev.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: return false
	for id in ["pause","fullscreen","mute","coop","report"]:
		if pressed(id,ev):
			if id=="pause": cancel_menu()
			else: perform(id)
			return true
	if menu:
		if game.modal=="inventory":
			if pressed("inventory",ev): game.set_modal(""); return true
			if pressed("reload",ev): game.ui.backpack.handle_key(KEY_R); return true
			for i in range(8):
				if pressed("slot"+str(i+1),ev): game.ui.backpack.handle_key(KEY_1+i); return true
		elif game.modal=="map" and pressed("map",ev): game.set_modal(""); return true
		elif game.modal=="dialog":
			for i in range(game.ui.current_choices.size()):
				if pressed("slot"+str(i+1),ev): game.ui.choose(i); return true
		return false
	if ev is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		game.player.rotate_y(-ev.relative.x*0.0022*float(tuning.mouse_sensitivity))
		game.camera.rotation.x = clampf(game.camera.rotation.x-ev.relative.y*0.0022*float(tuning.mouse_sensitivity),-1.25,1.25)
	for row in ACTIONS:
		if row[0] in ["left","right","forward","back","sprint","pause","fullscreen","mute","coop","report"]: continue
		if pressed(row[0],ev): perform(row[0]); return true
	return false

func perform(id: String) -> void:
	match id:
		"fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		"mute": game.audio.set_muted(not game.audio.muted)
		"coop": game.ui.coop_menu.open()
		"report":
			if not game.reporting: game.open_report()
		"tools": view.open_actions()
		"inventory": game.set_modal("inventory")
		"map": game.ui.show_map()
		"interact": game.interact()
		"attack": game.attack()
		"defend":
			if game.torch_equipped: game.torch_attack()
			elif game.offhand_busy(): game.message("Stow the held light to free your offhand.",2)
			elif game.state.profile.profession_id not in ["warrior","ranger"]: game.combat.defend()
		"heavy":
			if game.ranger.active(): game.ranger.select("dagger")
			elif game.state.profile.profession_id=="warrior": game.attack(true)
			else: game.combat.defend()
		"primary": game.use_ability(false)
		"secondary": game.use_ability(true)
		"reload":
			if game.ranger.active(): game.ranger.reload()
			else: game.rest()
		"camp": game.place_fire()
		"rest": game.rest()
		"lantern": game.toggle_lantern()
		"torch": game.toggle_torch()
		"save": game.save_game()
		"load": game.load_game()
		"jump":
			if game.player.is_on_floor() and game.state.stamina>=12:
				game.player.velocity.y = 5.5; game.state.stamina -= 12
		_:
			if id.begins_with("slot"): game.use_quick_slot(int(id.trim_prefix("slot"))-1)
