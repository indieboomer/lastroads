extends SceneTree

func _initialize() -> void:
	var source := Image.load_from_file("res://assets/ambient/painted-grass.png")
	var atlas := Image.create(1024,256,false,Image.FORMAT_RGBA8)
	var library = preload("res://scripts/sprite_library.gd").new()
	for index in range(4):
		var cell := source.get_region(Rect2i(index*source.get_width()/4,0,source.get_width()/4,source.get_height()))
		cell = cell.get_region(library.visible_bounds(cell))
		cell.resize(256,256,Image.INTERPOLATE_LANCZOS)
		atlas.blit_rect(cell,Rect2i(0,0,256,256),Vector2i(index*256,0))
	atlas.save_png("res://assets/ambient/painted-grass-atlas.png")
	quit()
