extends SceneTree

# Compile the generator's pale, partially transparent canvas into connected
# background alpha. Interior linen/metal highlights remain untouched.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/coop/ready")
	var report := []
	for origin in preload("res://scripts/character_data.gd").ORIGINS:
		for profession in preload("res://scripts/character_data.gd").PROFESSIONS:
			var id: String = origin.id+"-"+profession.id
			var image := Image.load_from_file("res://assets/coop/"+id+".png")
			assert(image!=null and image.get_width()%4==0 and image.get_height()%6==0,id)
			image.convert(Image.FORMAT_RGBA8)
			var width := image.get_width()
			var height := image.get_height()
			var bytes := image.get_data()
			var visited := PackedByteArray()
			visited.resize(width*height)
			var queue := PackedInt32Array()
			for x in range(width):
				flood_seed(x,bytes,visited,queue)
				flood_seed((height-1)*width+x,bytes,visited,queue)
			for y in range(height):
				flood_seed(y*width,bytes,visited,queue)
				flood_seed(y*width+width-1,bytes,visited,queue)
			var head := 0
			while head<queue.size():
				var pixel: int = queue[head]
				head += 1
				if pixel%width>0: flood_seed(pixel-1,bytes,visited,queue)
				if pixel%width<width-1: flood_seed(pixel+1,bytes,visited,queue)
				if pixel>=width: flood_seed(pixel-width,bytes,visited,queue)
				if pixel<width*(height-1): flood_seed(pixel+width,bytes,visited,queue)
			for pixel in range(width*height): bytes[pixel*4+3] = 0 if visited[pixel]==1 else 255
			var ready := Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,bytes)
			var occupancies := []
			for row in range(6):
				for col in range(4):
					var cell := ready.get_region(Rect2i(col*width/4,row*height/6,width/4,height/6))
					assert(not cell.is_invisible(),id+" empty animation cell")
					occupancies.append(cell.get_used_rect().size.x*cell.get_used_rect().size.y)
			assert(ready.get_pixel(0,0).a==0,id+" background alpha")
			assert(ready.save_png("res://assets/coop/ready/"+id+".png")==OK)
			report.append({"id":id,"width":width,"height":height,"frames":24,"background_pixels":queue.size(),"occupancies":occupancies})
			print("COOP ART ",id," / 24 frames / ",queue.size()," background pixels")
	var file := FileAccess.open("res://reports/coop/art-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("COOP ART PASS: 24 character sheets, 576 cells, connected background alpha, original generator output retained")
	quit()

func flood_seed(pixel: int, bytes: PackedByteArray, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	if visited[pixel]!=0: return
	var i := pixel*4
	var pale: bool = bytes[i]>210 and bytes[i+1]>210 and bytes[i+2]>205 and maxi(bytes[i],maxi(bytes[i+1],bytes[i+2]))-mini(bytes[i],mini(bytes[i+1],bytes[i+2]))<34
	if bytes[i+3]<32 or pale:
		visited[pixel] = 1
		queue.append(pixel)
