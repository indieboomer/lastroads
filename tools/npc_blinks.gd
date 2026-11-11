extends SceneTree

const FACES := {"sister":Rect2i(302,94,112,112),"mara":Rect2i(270,196,120,120),"osric":Rect2i(257,62,119,119),"rook":Rect2i(291,185,135,135)}
const EYES := {"sister":[Vector2(343,137),Vector2(378,136)],"mara":[Vector2(310,240),Vector2(351,231)],"osric":[Vector2(294,107),Vector2(338,99)],"rook":[Vector2(321,235),Vector2(351,226)]}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/blink-work"))
	if "--review" in OS.get_cmdline_user_args():
		for id in FACES:
			var original := Image.load_from_file("res://assets/revision/npc-"+id+".png")
			original.get_region(Rect2i(0,0,original.get_width()/2,original.get_height())).save_png("res://reports/blink-work/"+id+"-before.png")
			var closed := Image.load_from_file("res://assets/old-masters/npc-"+id+"-blink.png").get_region(FACES[id])
			closed.resize(896,896,Image.INTERPOLATE_LANCZOS)
			closed.save_png("res://reports/blink-work/"+id+"-game-blink-face.png")
		quit()
		return
	if "--prepare" in OS.get_cmdline_user_args():
		for id in FACES:
			var image := Image.load_from_file("res://assets/old-masters/npc-"+id+".png")
			var face := image.get_region(FACES[id])
			face.resize(896,896,Image.INTERPOLATE_LANCZOS)
			face.save_png("res://reports/blink-work/"+id+"-open-face.png")
		print("BLINK INPUTS PREPARED / four face crops, no body regeneration")
		quit()
		return
	var audit: Array = []
	for id in FACES:
		var edited_path: String = "res://assets/old-masters/"+id+"-closed-face.png"
		if not FileAccess.file_exists(edited_path): continue
		var master := Image.load_from_file("res://assets/old-masters/npc-"+id+".png")
		master.convert(Image.FORMAT_RGBA8)
		var face := Image.load_from_file(edited_path)
		face.convert(Image.FORMAT_RGBA8)
		face.resize(FACES[id].size.x,FACES[id].size.y,Image.INTERPOLATE_LANCZOS)
		var closed := master.duplicate() as Image
		var changed := 0
		for center in EYES[id]:
			for y in range(int(center.y)-7,int(center.y)+8):
				for x in range(int(center.x)-13,int(center.x)+14):
					var ellipse := Vector2((x-center.x)/12.0,(y-center.y)/6.0).length()
					var opacity := 1.0-smoothstep(0.70,1.0,ellipse)
					if opacity<=0: continue
					var old := master.get_pixel(x,y)
					var colour := old.lerp(face.get_pixel(x-FACES[id].position.x,y-FACES[id].position.y),opacity)
					colour.a = old.a
					closed.set_pixel(x,y,colour)
					changed += 1
		# Only the tightly bounded eyelid masks differ; alpha and every other pixel stay exact.
		var outside_differences := 0
		var alpha_differences := 0
		for y in range(master.get_height()):
			for x in range(master.get_width()):
				var old := master.get_pixel(x,y)
				var updated := closed.get_pixel(x,y)
				if old.a!=updated.a: alpha_differences += 1
				if old!=updated:
					var within := false
					for center in EYES[id]:
						if Vector2((x-center.x)/12.0,(y-center.y)/6.0).length()<1.0: within = true
					if not within: outside_differences += 1
		assert(outside_differences==0 and alpha_differences==0)
		closed.save_png("res://assets/old-masters/npc-"+id+"-blink.png")
		var sheet := Image.create(master.get_width()*2,master.get_height(),false,Image.FORMAT_RGBA8)
		sheet.blit_rect(master,Rect2i(Vector2i.ZERO,master.get_size()),Vector2i.ZERO)
		sheet.blit_rect(closed,Rect2i(Vector2i.ZERO,closed.get_size()),Vector2i(master.get_width(),0))
		sheet.save_png("res://assets/old-masters/npc-"+id+"-poses.png")
		audit.append({"id":id,"face_crop":str(FACES[id]),"eyelid_centres":str(EYES[id]),"mask_radii":[12,6],"edited_pixels":changed,"outside_mask_differences":outside_differences,"alpha_differences":alpha_differences,"layout":"open then closed; original frame canvas, two columns","sheet_size":[sheet.get_width(),sheet.get_height()]})
	var file := FileAccess.open("res://assets/old-masters/blink-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(audit,"\t"))
	print("BLINK ASSEMBLY PASS: ",audit.size()," two-frame sheets; no non-eyelid or alpha changes")
	quit()
