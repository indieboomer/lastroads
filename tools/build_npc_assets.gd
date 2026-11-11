extends SceneTree

# Deterministic import preparation, never an independent generated eye/body frame.
# Run with Godot --headless --path . --script tools/build_npc_assets.gd
func _initialize() -> void:
	var contracts: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/old-masters/source-contracts.json"))
	var report: Array = []
	for contract in contracts:
		var path := "res://assets/old-masters/npc-"+str(contract.id)+"-source.png"
		if not FileAccess.file_exists(path): continue
		var image := Image.load_from_file(path)
		image.convert(Image.FORMAT_RGBA8)
		var bytes := image.get_data()
		var left := image.get_width()
		var top := image.get_height()
		var right := -1
		var bottom := -1
		var transparent := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var i := (y*image.get_width()+x)*4
				# Reject sub-scissor edge colours; the shipped actor shader uses .3.
				if bytes[i+3]<77:
					bytes[i+3] = 0
					transparent += 1
				else:
					left = mini(left,x)
					top = mini(top,y)
					right = maxi(right,x)
					bottom = maxi(bottom,y)
		assert(right>left and bottom>top and transparent>image.get_width()*image.get_height()/10,"Missing silhouette or alpha: "+path)
		image = Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes)
		var cropped := image.get_region(Rect2i(left,top,right-left+1,bottom-top+1))
		var target_width := int(contract.bounds[2])-int(contract.bounds[0])
		var target_height := int(contract.bounds[3])-int(contract.bounds[1])
		var factor := minf(float(target_width)/cropped.get_width(),float(target_height)/cropped.get_height())
		cropped.resize(maxi(1,roundi(cropped.get_width()*factor)),maxi(1,roundi(cropped.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(int(contract.active_frame[2]),int(contract.active_frame[3]),false,Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		var x := roundi((int(contract.bounds[0])+int(contract.bounds[2])-cropped.get_width())*0.5)
		var y := int(contract.baseline)+1-cropped.get_height()
		canvas.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),Vector2i(x,y))
		canvas.fix_alpha_edges()
		var destination := "res://assets/old-masters/npc-"+str(contract.id)+".png"
		assert(canvas.save_png(destination)==OK)
		report.append({"id":contract.id,"old":contract.source,"new":destination,"canvas":[canvas.get_width(),canvas.get_height()],"old_baseline":contract.baseline,"new_baseline":y+cropped.get_height()-1,"uniform_scale":factor,"placement":[x,y,cropped.get_width(),cropped.get_height()],"source_alpha_zero_or_subscissor":transparent,"state":"open eyes only","raw_source":path})
	var file := FileAccess.open("res://assets/old-masters/asset-map.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("NPC ASSET PREPARATION PASS: ",report.size()," stable masters; uniform fit, original frame canvas and baseline; real alpha")
	quit()
