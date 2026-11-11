extends CanvasLayer

var game: Node
var controls: RefCounted
var settings: Control
var status: Label
var binding_buttons: Dictionary = {}
var actions: Panel
var keyboard: Panel
var target: Control
var entry: LineEdit
var pointer: Label
var help: Label
var device_status: Label
var sliders: Dictionary = {}

func build() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	controls = game.controls
	build_settings()
	build_actions()
	build_keyboard()
	pointer = game.ui.label("+",Vector2.ZERO,25,self)
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer.hide()
	help = game.ui.label("",Vector2(270,694),13,self)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help.hide()

func _process(_dt: float) -> void:
	if device_status:
		var devices := Input.get_connected_joypads()
		device_status.text = "Controller: "+Input.get_joy_name(controls.pad_id) if controls.pad_id in devices else "Controller: not connected"
	help.visible = controls.using_pad and (game.modal!="" or not game.started or game.reporting)
	help.text = "Sticks: pointer | D-pad: focus | A/Cross: choose / text | B/Circle: back | LB/RB: scroll"
	if game.modal=="inventory": help.text = "Sticks: pointer | A/Cross: hold & drag | X/Square: use / clear slot | Y/Triangle: rotate | B/Circle: cancel / close"
	if keyboard.visible:
		var focus: Control = game.get_viewport().gui_get_focus_owner()
		if focus==null or not keyboard.is_ancestor_of(focus): controls.focus_first(keyboard)

func build_settings() -> void:
	settings = Control.new()
	settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui.settings_panel.add_child(settings)
	game.ui.settings_controls = settings
	var title: Label = game.ui.label("KEYBINDINGS & CONTROLLER",Vector2(30,116),22,settings,true)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui.label("Select a binding, then press its replacement. Conflicts swap when possible. Esc / Back cancels capture.",Vector2(30,151),15,settings)
	game.ui.label("Action",Vector2(42,183),15,settings)
	game.ui.label("Keyboard / mouse",Vector2(357,183),15,settings)
	game.ui.label("Controller",Vector2(597,183),15,settings)
	device_status = game.ui.label("",Vector2(858,126),13,settings)
	device_status.size = Vector2(285,50)
	device_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30,210)
	scroll.size = Vector2(800,325)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	settings.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",5)
	scroll.add_child(rows)
	for action in controls.ACTIONS:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var caption := Label.new()
		caption.text = action[1]
		caption.custom_minimum_size = Vector2(310,48)
		row.add_child(caption)
		binding_buttons[action[0]] = {}
		for kind in ["key","pad"]:
			var id: String = action[0]
			var bind_kind: String = kind
			var b: Button = game.ui.button("",Vector2.ZERO,Vector2(230,48),row,func(): controls.capture(id,bind_kind))
			b.custom_minimum_size = Vector2(230,48)
			binding_buttons[id][kind] = b
	game.ui.label("Mouse look",Vector2(858,190),16,settings)
	add_slider("mouse_sensitivity",Vector2(858,217),0.2,3,0.1)
	game.ui.label("Controller look",Vector2(858,255),16,settings)
	add_slider("look_sensitivity",Vector2(858,282),0.5,6,0.1)
	game.ui.label("Stick deadzone",Vector2(858,320),16,settings)
	add_slider("deadzone",Vector2(858,347),0.05,0.5,0.01)
	game.ui.label("Menu pointer speed",Vector2(858,385),16,settings)
	add_slider("cursor_speed",Vector2(858,412),200,1200,50)
	var invert := CheckButton.new()
	invert.text = "Invert controller Y"
	invert.position = Vector2(853,452)
	settings.add_child(invert)
	invert.set_pressed_no_signal(controls.tuning.invert_y)
	invert.toggled.connect(func(on): controls.tuning.invert_y = on; controls.write())
	game.ui.label("Menu A/B stay fixed.\nSticks move the menu pointer.\nTriggers can be rebound.\nUnbound pad actions: Actions menu.",Vector2(858,497),13,settings)
	game.ui.button("Reset bindings",Vector2(200,552),Vector2(230,48),settings,func():
		controls.capture_action = ""
		controls.bindings = controls.defaults()
		controls.tuning = controls.TUNING.duplicate()
		controls.apply()
		controls.write()
		invert.set_pressed_no_signal(false)
		for key in sliders: sliders[key].set_value_no_signal(controls.tuning[key])
		refresh_bindings()
		status.text = "Default controls restored."
	)
	status = game.ui.label("Changes save automatically to controls.cfg. Esc always remains available to go back.",Vector2(445,568),13,settings)
	status.size = Vector2(690,45)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refresh_bindings()
	settings.hide()

func add_slider(key: String, at: Vector2, low: float, high: float, step: float) -> void:
	var slider := HSlider.new()
	slider.position = at; slider.size = Vector2(285,25)
	slider.min_value = low; slider.max_value = high; slider.step = step
	slider.value = controls.tuning[key]
	slider.tooltip_text = str(slider.value)
	settings.add_child(slider)
	sliders[key] = slider
	slider.value_changed.connect(func(value):
		controls.tuning[key] = value
		slider.tooltip_text = str(value)
		controls.apply()
		controls.write()
	)

func refresh_bindings() -> void:
	for id in binding_buttons:
		binding_buttons[id].key.text = controls.hint(id,false)
		binding_buttons[id].pad.text = controls.hint(id,true)
		binding_buttons[id].pad.disabled = id in ["left","right","forward","back"]

func build_actions() -> void:
	actions = game.ui.panel(Vector2(110,40),Vector2(1060,640),self)
	game.ui.label("QUICK SLOTS & ROAD ACTIONS",Vector2(35,25),27,actions,true)
	var ids: Array[String] = []
	for i in range(8): ids.append("slot"+str(i+1))
	ids.append_array(["inventory","map","lantern","torch","camp","rest","reload","save","load","report","coop","mute","fullscreen"])
	for i in range(ids.size()):
		var id: String = ids[i]
		var text := id.capitalize()
		for row in controls.ACTIONS:
			if row[0]==id: text = row[1]
		var b: Button = game.ui.button(text,Vector2(35+(i%3)*330,90+int(i/3)*65),Vector2(315,55),actions,func():
			game.set_modal("")
			controls.perform(id)
		)
		b.set_meta("action",id)
	game.ui.button("Back",Vector2(35,560),Vector2(315,50),actions,func(): game.set_modal(""))
	actions.hide()

func open_actions() -> void:
	game.set_modal("actions")
	for b in actions.get_children():
		if b is Button and str(b.get_meta("action","")).begins_with("slot"):
			var slot := int(str(b.get_meta("action")).trim_prefix("slot"))-1
			b.text = "Slot %d: %s" % [slot+1,game.state.pack.slots[slot].capitalize()]
	actions.show()
	controls.menu_stamp = ""

func build_keyboard() -> void:
	keyboard = game.ui.panel(Vector2(170,70),Vector2(940,570),self)
	game.ui.label("CONTROLLER TEXT ENTRY",Vector2(30,20),25,keyboard,true)
	entry = LineEdit.new()
	entry.focus_mode = Control.FOCUS_NONE
	entry.position = Vector2(30,65); entry.size = Vector2(880,45)
	keyboard.add_child(entry)
	var chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?@_-()/"
	for i in range(chars.length()):
		var value := chars.substr(i,1)
		var b: Button = game.ui.button("Space" if value==" " else value,Vector2(30+(i%12)*73,130+int(i/12)*48),Vector2(68,44),keyboard,func(): entry.insert_text_at_caret(value))
		# Fit compact keys without the general menu's tall content margins.
		for state in ["normal","hover","pressed"]:
			var style: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
			style.content_margin_top = 4; style.content_margin_bottom = 4
			style.content_margin_left = 2; style.content_margin_right = 2
			b.add_theme_stylebox_override(state,style)
		b.size = Vector2(68,44)
	game.ui.button("Delete",Vector2(30,480),Vector2(200,50),keyboard,func():
		var at := entry.caret_column
		if at>0: entry.delete_text(at-1,at)
	)
	game.ui.button("Cancel",Vector2(250,480),Vector2(200,50),keyboard,close_keyboard)
	game.ui.button("Done",Vector2(470,480),Vector2(200,50),keyboard,func():
		if is_instance_valid(target):
			target.text = entry.text
			if target is LineEdit:
				target.text_changed.emit(target.text)
				target.text_submitted.emit(target.text)
		close_keyboard()
	)
	keyboard.hide()

func open_keyboard(field: Control) -> void:
	if field==entry: return
	target = field
	entry.text = field.text
	entry.caret_column = entry.text.length()
	keyboard.show()
	controls.pointer_mode = false
	controls.menu_stamp = ""
	controls.focus_first(keyboard)

func close_keyboard() -> void:
	keyboard.hide()
	if is_instance_valid(target): target.grab_focus()
	target = null
	controls.menu_stamp = ""
