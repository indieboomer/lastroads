extends Control

const Pack = preload("res://scripts/backpack.gd")
const CELL := 62
const ORIGIN := Vector2(36,111)
var icon_layer: Node2D
var text_layer: Node2D
var game: Node
var font: Font
var icons: Dictionary = {}
var held := ""
var selected := ""
var rotated := false
var grab := Vector2i.ZERO
var notice := ""
var dragged_slot := -1

func _ready() -> void:
	icon_layer = preload("res://scripts/retro_icons.gd").new()
	icon_layer.game = game
	add_child(icon_layer)
	text_layer = Node2D.new()
	add_child(text_layer)
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	for key in Pack.ITEMS:
		icons[key] = game.world.library.cell("res://assets/revision/inventory-icons.png",Pack.ITEMS[key].icon,4,3)
	icons.pistol_cartridge = load("res://assets/ranger/paper-cartridge.png")
	icons.musket_cartridge = icons.pistol_cartridge
	for key in ["burial_cloth","ancient_beads","resin_tear","graveward_resin"]:
		icons[key] = load("res://assets/wilderness/weeper/"+key+".svg")
	set_process(true)

func _process(_dt: float) -> void:
	if visible:
		queue_redraw()

func text(value: String, at: Vector2, size := 17, colour := Color("e9ddbf")) -> void:
	font.draw_string(text_layer.get_canvas_item(),at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,colour)

func icon(key: String, rect: Rect2, alpha := 1.0) -> void:
	var texture: Texture2D = icons[key]
	var size := Vector2(texture.get_width(),texture.get_height())
	var scaled := size*minf((rect.size.x-12)/size.x,(rect.size.y-16)/size.y)
	icon_layer.draw_icon(texture,Rect2(rect.get_center()-scaled*0.5,scaled),Color(1,1,1,alpha))

func _draw() -> void:
	if not icon_layer: return
	icon_layer.begin_frame()
	RenderingServer.canvas_item_clear(text_layer.get_canvas_item())
	var pack = game.state.pack
	pack.sync(game.state.inventory)
	draw_style_box(game.ui.panel_style(Color("102527")),Rect2(Vector2.ZERO,size))
	text("THE TRAVELLER'S PACK",Vector2(34,43),29)
	text("8 x 6 cells  /  no weight limit  /  supplies stack by type",Vector2(36,77),15,Color("c2b28c"))
	for y in range(Pack.HEIGHT):
		for x in range(Pack.WIDTH):
			draw_rect(Rect2(ORIGIN+Vector2(x,y)*CELL,Vector2.ONE*(CELL-2)),Color("1c3432"))
	for key in pack.layout:
		var record: Dictionary = pack.layout[key]
		var rect := Rect2(ORIGIN+Vector2(record.x,record.y)*CELL,Vector2(pack.footprint(key,record.rotated))*CELL-Vector2(2,2))
		draw_rect(rect,Color("3b4e42") if selected==key else Color("263d36"))
		draw_rect(rect,Color("d6b677") if selected==key else Color("786e4d"),false,1)
		icon(key,rect,0.3 if held==key else 1.0)
		if key.ends_with("_cartridge"): text("P" if key=="pistol_cartridge" else "M",rect.position+Vector2(5,19),17,Color("f0cc7a"))
		text(str(int(game.state.inventory[key])),rect.end-Vector2(25,10),18)
	if not held.is_empty():
		var cell := hovered_cell()
		var rect := Rect2(ORIGIN+Vector2(cell)*CELL,Vector2(pack.footprint(held,rotated))*CELL)
		draw_rect(rect,Color(0.3,0.7,0.4,0.3) if pack.fits(held,cell,rotated) else Color(0.9,0.15,0.15,0.4))
		icon(held,rect,0.8)
	text("EQUIPPED",Vector2(574,120),17,Color("d8bc7d"))
	var profession: String = game.state.profile.profession_id
	text("Steel sword"+(" / reforged" if game.state.flags.sword_upgrade else "") if profession=="warrior" else "Grimoire / free Dart" if profession=="mage" else "Pistol / musket / dagger" if profession=="ranger" else "Road staff / cross",Vector2(574,151))
	text("Torch raised" if game.torch_equipped else "Buckler / traveller's coat" if profession=="warrior" else "Traveller's coat / casting hand free",Vector2(574,179))
	text("Ash lining: rain & cold protection" if game.state.flags.coat_upgrade else "Ask Osric about an ash-lined coat.",Vector2(574,209),15)
	text("Coins: %d / Pistol %d / Musket %d" % [game.state.inventory.gold,game.state.inventory.pistol_cartridge,game.state.inventory.musket_cartridge] if profession=="ranger" else "Coins: %d / Carried lights below" % game.state.inventory.gold,Vector2(574,226),17,Color("e3bd6e"))
	if not selected.is_empty():
		text(Pack.details(selected).name,Vector2(574,305),23)
		text(Pack.details(selected).use,Vector2(574,338),15)
		if Pack.ITEMS.has(selected):
			text("%d x %d cells / stack %d" % [pack.footprint(selected,pack.layout.get(selected,{}).get("rotated",false)).x,pack.footprint(selected,pack.layout.get(selected,{}).get("rotated",false)).y,game.state.inventory.get(selected,0)],Vector2(574,370),15)
		else:
			text("Already carried / no purchase required",Vector2(574,370),15)
		text("Select a quick slot below to bind this item.",Vector2(574,405),15)
	else:
		text("Reusable lantern and torch are already yours.",Vector2(574,305),15)
		text("Select one above, then press 1-8 to bind it.",Vector2(574,338),15)
		text("Lantern: %s / Torch: %s" % ["ON" if game.lantern.visible else "OFF","raised" if game.torch_equipped else "stowed"],Vector2(574,370),15)
	if not pack.unpacked.is_empty():
		text("UNPACKED: click to fit, or auto-arrange",Vector2(574,505),16,Color("f0b676"))
		for i in range(mini(1,pack.unpacked.size())):
			text(Pack.ITEMS[pack.unpacked[i]].name,Vector2(574,528+i*23),15)
		if pack.unpacked.size()>1:
			text("+ %d more; Auto-arrange fits them all." % (pack.unpacked.size()-1),Vector2(574,549),13)
	text(notice,Vector2(36,512),16,Color("e8c180"))
	text("QUICK SLOTS / click one to bind selected item",Vector2(36,550),16)
	for i in range(8):
		var rect := Rect2(Vector2(36+i*100,565),Vector2(92,66))
		draw_rect(rect,Color("263b34"))
		draw_rect(rect,Color("87734c"),false)
		var key: String = pack.slots[i]
		if icons.has(key):
			icon(key,rect)
		else:
			text(key.capitalize() if not key.is_empty() else "Empty",rect.position+Vector2(7,37),13)
		text(str(i+1) if game.controls.using_pad else game.controls.hint("slot"+str(i+1)),rect.position+Vector2(5,17),14)
		if dragged_slot==i: draw_rect(rect,Color("f0cc7a"),false,2)
	text("Sticks: pointer / Hold A: drag / X: use or clear / Y: rotate / B: cancel" if game.controls.using_pad else "Drag item to slot / Right-click clears / Shift-drag swaps / "+game.controls.hint("reload")+" rotates / Esc cancels",Vector2(36,665),14)

func hovered_cell() -> Vector2i:
	return Vector2i(((get_local_mouse_position()-ORIGIN)/CELL).floor())-grab

func cancel_drag() -> bool:
	if dragged_slot>=0:
		dragged_slot = -1
		return true
	if held.is_empty():
		return false
	held = ""
	notice = "Move cancelled; the item remains in its original cells."
	return true

func handle_key(code: int) -> void:
	if code==KEY_R and not held.is_empty():
		rotated = not rotated
		grab = Vector2i.ZERO
	elif code>=KEY_1 and code<=KEY_8 and not selected.is_empty():
		assign_slot(code-KEY_1,selected)

func select_action(key: String) -> void:
	held = ""
	selected = key
	notice = "%s selected. Press 1-8 or click a slot. Already carried." % Pack.details(key).name

func activate_selected() -> void:
	held = ""
	if selected=="lantern": game.toggle_lantern()
	elif selected=="torch": game.toggle_torch()
	elif selected in ["wood","rest"]:
		game.set_modal("")
		if selected=="wood": game.place_fire()
		else: game.rest()
	elif selected in ["tonic","bread","berries","mushrooms"]:
		game.use_item(selected)
		game.state.pack.sync(game.state.inventory)
	elif not selected.is_empty(): notice = Pack.details(selected).use
	else: notice = "Select a supply or carried gear first."

func assign_slot(index: int, key: String) -> void:
	if game.state.pack.bind_slot(index,key):
		held = ""
		dragged_slot = -1
		notice = "Slot %d cleared." % (index+1) if key.is_empty() else "%s assigned to slot %d; inventory unchanged." % [Pack.details(key).name,index+1]

func slot_at(point: Vector2) -> int:
	for i in range(8):
		if Rect2(Vector2(36+i*100,565),Vector2(92,66)).has_point(point): return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var point: Vector2 = event.position
	var slot := slot_at(point)
	if event.pressed and event.button_index==MOUSE_BUTTON_RIGHT and slot>=0:
		assign_slot(slot,"")
		accept_event()
		return
	if not event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if dragged_slot>=0:
			if slot>=0 and slot!=dragged_slot:
				var old: String = game.state.pack.slots[slot]
				game.state.pack.slots[slot] = game.state.pack.slots[dragged_slot]
				game.state.pack.slots[dragged_slot] = old
				notice = "Shortcuts swapped; inventory unchanged."
			dragged_slot = -1
			accept_event()
			return
		if slot>=0 and not held.is_empty():
			assign_slot(slot,held)
			accept_event()
			return
	if event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if slot>=0:
			if event.shift_pressed or selected.is_empty():
				dragged_slot = slot
			else: assign_slot(slot,selected)
			accept_event()
			return
		if not held.is_empty():
			try_place(point)
			return
		for key in game.state.pack.layout:
			var record: Dictionary = game.state.pack.layout[key]
			var rect := Rect2(ORIGIN+Vector2(record.x,record.y)*CELL,Vector2(game.state.pack.footprint(key,record.rotated))*CELL)
			if rect.has_point(point):
				selected = key
				rotated = record.rotated
				if event.shift_pressed:
					game.state.pack.first_fit(key)
				else:
					held = key
					grab = Vector2i(((point-rect.position)/CELL).floor())
				accept_event()
				return
		for i in range(mini(1,game.state.pack.unpacked.size())):
			if Rect2(574,508+i*23,340,23).has_point(point):
				held = game.state.pack.unpacked[i]
				selected = held
				rotated = false
				grab = Vector2i.ZERO
	elif not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not held.is_empty():
		try_place(point)
	elif event.pressed and event.button_index==MOUSE_BUTTON_RIGHT and not selected.is_empty():
		if selected in ["lantern","torch"]:
			if selected=="lantern": game.toggle_lantern()
			else: game.toggle_torch()
		elif selected in ["tonic","bread","berries","mushrooms"]:
			game.use_item(selected)
			game.state.pack.sync(game.state.inventory)
			held = ""
	accept_event()

func try_place(point := Vector2(INF,INF)) -> void:
	var cell := hovered_cell() if not is_finite(point.x) else Vector2i(((point-ORIGIN)/CELL).floor())-grab
	if game.state.pack.move(held,cell,rotated):
		held = ""
		notice = "Packed."
	else:
		notice = "Doesn't fit. R rotates; Esc returns the item."
