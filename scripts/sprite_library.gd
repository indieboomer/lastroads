extends RefCounted

func cache_folder() -> String:
	return "res://.godot/sprite-cache" if OS.has_feature("editor") else "user://sprite-cache"

func cache_tag() -> String:
	return preload("res://scripts/content.gd").BUILD

# Texture extraction is cached. Transparent padding is not part of an object's
# physical height, so the bottom visible pixel, rather than the atlas cell, is grounded.
var cache: Dictionary = {}
var sources: Dictionary = {}
var bounds: Dictionary = {}

func image_for(path: String) -> Image:
	if not sources.has(path):
		var image: Image = (load(path) as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		sources[path] = image
	return sources[path]

func visible_bounds(image: Image) -> Rect2i:
	if image.get_format()!=Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	var left := image.get_width()
	var right := -1
	var top := image.get_height()
	var bottom := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if pixels[(y*image.get_width()+x)*4+3]>=77:
				left = mini(left,x)
				right = maxi(right,x)
				top = mini(top,y)
				bottom = maxi(bottom,y)
	return Rect2i(left,top,right-left+1,bottom-top+1) if right>=left else Rect2i(0,0,image.get_width(),image.get_height())

func cell(path: String, index: int, cols := 1, rows := 1) -> Texture2D:
	var key := "%s:%d:%d:%d" % [path,index,cols,rows]
	if cache.has(key):
		return cache[key]
	var cache_folder := cache_folder()
	var disk_path := cache_folder.path_join((cache_tag()+":v3.3:"+key+":"+str(FileAccess.get_modified_time(path))).md5_text()+".res")
	if FileAccess.file_exists(disk_path):
		cache[key] = load(disk_path)
		return cache[key]
	var source := image_for(path)
	var w := source.get_width()/cols
	var h := source.get_height()/rows
	var image := source.get_region(Rect2i(index%cols*w,index/cols*h,w,h))
	var bound := visible_bounds(image)
	var cropped := image.get_region(bound)
	cropped.fix_alpha_edges()
	cropped.generate_mipmaps()
	var texture := ImageTexture.create_from_image(cropped)
	cache[key] = texture
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_folder))
	ResourceSaver.save(texture,disk_path,ResourceSaver.FLAG_COMPRESS)
	return texture

func npc(id: String, _blink := false) -> Texture2D:
	if id in preload("res://scripts/woods_content.gd").NPCS:
		return cell("res://assets/rowan/cast-atlas.png",preload("res://scripts/woods_content.gd").NPCS[id].cell,4,2)
	if id=="pip": return cell("res://assets/pip.png",0)
	if id in ["ilya","merchant"]:
		return cell("res://assets/friends/npc-"+("ilya-girl1" if id=="ilya" else "merchant-girl2")+".png",0)
	var poses := "res://assets/old-masters/npc-"+id+"-poses.png"
	if ResourceLoader.exists(poses):
		return cell(poses,1 if _blink else 0,2,1)
	var master := "res://assets/old-masters/npc-"+id+".png"
	if ResourceLoader.exists(master):
		return cell(master,0)
	if id=="courier":
		var key := "courier-clean"
		if not cache.has(key):
			var path := "res://assets/revision/npc-courier.png"
			var source := image_for(path)
			cache[key] = isolated_region(path,Rect2i(0,0,source.get_width()/2,source.get_height()),true)
		return cache[key]
	# Keep one stable painted pose; alternate generations cannot serve as eye frames.
	if id=="ilya":
		return cell("res://assets/revision/npc-ilya-v4.png",0)
	return cell("res://assets/revision/npc-"+id+".png",0,2,1)

# Keep the main connected silhouette; packed action sheets may spill a neighbour
# into the transparent margin. Cache the result on disk, just like normal cells.
func isolated_region(path: String, region: Rect2i, trim := false) -> Texture2D:
	var key := "isolated-v3:"+str(trim)+path+str(region)+str(FileAccess.get_modified_time(path))
	var disk := cache_folder().path_join((cache_tag()+key).md5_text()+".res")
	if FileAccess.file_exists(disk):
		return load(disk)
	var image := image_for(path).get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width*height)
	var largest := PackedInt32Array()
	for index in range(width*height):
		if seen[index] or data[index*4+3]<77:
			continue
		var component := PackedInt32Array([index])
		seen[index] = 1
		var cursor := 0
		while cursor<component.size():
			var current := component[cursor]
			cursor += 1
			var x := current%width
			var y := current/width
			for dy in range(-1,2):
				for dx in range(-1,2):
					var nx := x+dx
					var ny := y+dy
					if nx<0 or nx>=width or ny<0 or ny>=height:
						continue
					var neighbour := ny*width+nx
					if not seen[neighbour] and data[neighbour*4+3]>=77:
						seen[neighbour] = 1
						component.append(neighbour)
		if component.size()>largest.size():
			largest = component
	seen.fill(0)
	for index in largest:
		seen[index] = 1
	# One-pixel fringe keeps antialiasing at the retained outline.
	for index in range(width*height):
		if seen[index]:
			continue
		var keep := false
		for dy in range(-1,2):
			for dx in range(-1,2):
				var nx := index%width+dx
				var ny := index/width+dy
				if nx>=0 and nx<width and ny>=0 and ny<height and seen[ny*width+nx]:
					keep = true
		if not keep:
			data[index*4+3] = 0
	image = Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,data)
	if trim:
		image = image.get_region(visible_bounds(image))
	image.fix_alpha_edges()
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	ResourceSaver.save(texture,disk,ResourceSaver.FLAG_COMPRESS)
	return texture

func portrait(id: String, blink := false) -> Texture2D:
	if id in ["ilya","merchant"]:
		return cell("res://assets/friends/npc-"+("ilya-girl1" if id=="ilya" else "merchant-girl2")+"-portrait.png",0)
	return npc(id,blink)
