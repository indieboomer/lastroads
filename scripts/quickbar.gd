extends Control
const Pack = preload("res://scripts/backpack.gd")
var icon_layer: Node2D
var text_layer: Node2D
var game: Node
var icons: Dictionary = {}
var highlighted := -1
var highlight_time := 0.0

func _ready() -> void:
	icon_layer = preload("res://scripts/retro_icons.gd").new()
	icon_layer.game = game
	add_child(icon_layer)
	text_layer = Node2D.new()
	add_child(text_layer)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in Pack.ITEMS:
		icons[key] = game.world.library.cell("res://assets/revision/inventory-icons.png",Pack.ITEMS[key].icon,4,3)
	icons.pistol_cartridge = load("res://assets/ranger/paper-cartridge.png")
	icons.musket_cartridge = icons.pistol_cartridge
	for key in ["burial_cloth","ancient_beads","resin_tear","graveward_resin"]:
		icons[key] = load("res://assets/wilderness/weeper/"+key+".svg")

func _draw() -> void:
	if not icon_layer: return
	icon_layer.begin_frame()
	RenderingServer.canvas_item_clear(text_layer.get_canvas_item())
	var font := ThemeDB.fallback_font
	for i in range(8):
		var rect := Rect2(Vector2(i*66,0),Vector2(61,64))
		draw_rect(rect,Color(0.045,0.09,0.09,0.88))
		draw_rect(rect,Color("f0cc7a") if highlighted==i and game.state.elapsed<highlight_time else Color("8c7854"),false,1)
		var key: String = game.state.pack.slots[i]
		if icons.has(key):
			var texture: Texture2D = icons[key]
			var image_size := Vector2(texture.get_width(),texture.get_height())
			var scaled := image_size*minf(43/image_size.x,43/image_size.y)
			var tint := Color.WHITE if game.state.inventory.get(key,0)>0 else Color(0.5,0.5,0.5,0.45)
			icon_layer.draw_icon(texture,Rect2(rect.get_center()-scaled*0.5,scaled),tint)
			font.draw_string(text_layer.get_canvas_item(),rect.end-Vector2(21,6),str(int(game.state.inventory.get(key,0))),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ead7ac"))
			if key.ends_with("_cartridge"): font.draw_string(text_layer.get_canvas_item(),rect.position+Vector2(42,18),"P" if key=="pistol_cartridge" else "M",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f0cc7a"))
		else:
			font.draw_string(text_layer.get_canvas_item(),rect.position+Vector2(6,38),key.capitalize() if not key.is_empty() else "-",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e1c185"))
		var shortcut: String = str(i+1) if game.controls.using_pad else game.controls.hint("slot"+str(i+1))
		font.draw_string(text_layer.get_canvas_item(),rect.position+Vector2(5,15),shortcut.left(6),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d8c7a7"))
