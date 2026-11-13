extends RefCounted

const D = preload("res://scripts/woods_content.gd")
var nodes: Dictionary = {}

func label(w: Node3D, text: String, at: Vector2, height := 1.6, size := 24) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = .008
	node.modulate = Color("e0d0a5")
	node.outline_size = 3
	node.position = w.C.ground(at,height)
	w.add_child(node)
	return node

func post(w: Node3D, at: Vector2, text: String) -> void:
	w.signpost(at,text)

func build(w: Node3D) -> void:
	# New pads and roads are authored before vegetation, so approaches stay clear.
	post(w,Vector2(-6,-985),"ALDERWAKE / NORTH\nHESTER SEEKS WITNESSES")
	post(w,Vector2(6,-1034),"THE ROWAN MARCH\nALDERWAKE / NORTH")
	w.cottage(Vector2(-22,-1100),14,14,4.6,"ward")
	w.cottage(Vector2(23,-1110),12,13,4.4,"office")
	w.cottage(Vector2(-27,-1127),10,10,3.9)
	w.cottage(Vector2(22,-1080),10,10,3.9,"pantry")
	w.base_fires.append(Vector2(-7,-1081))
	post(w,Vector2(7,-1069),"ALDERWAKE\nCORONER / RELIEF / REST")
	post(w,Vector2(5,-1130),"BLACKWATER / EAST\nROWAN SANCTUARY / WEST")
	# A public case table with three visibly independent columns.
	w.block(w.C.ground(Vector2(-13,-1098),.68),Vector3(4,.18,1.6),w.paint("wood"),false)
	for x in [-14.5,-11.5]:
		w.block(w.C.ground(Vector2(x,-1098),.3),Vector3(.16,.6,.7),w.paint("wood"),false)
	for i in range(3):
		var paper: MeshInstance3D = w.block(w.C.ground(Vector2(-14+i,-1098),.80),Vector3(.7,.025,1.0),w.flat(Color("d7c7a1")),false)
		nodes["board_"+["cause","access","motive"][i]] = paper
	label(w,"CAUSE / ACCESS / MOTIVE",Vector2(-13,-1098),1.55,18)
	# Hester's safe yard and basin for Nell's ordinary toy, outside the ward doorway.
	w.cylinder(w.C.ground(Vector2(-25,-1081),.65),.55,.26,w.paint("wood"),w,false)
	nodes.boat = w.block(w.C.ground(Vector2(-25,-1081),.83),Vector3(.35,.12,.65),w.paint("wood"),false)
	nodes.boat.visible = false
	# Blackwater: a mill, shallow working channel and a covered, non-graphic body.
	w.cottage(Vector2(140,-1217),14,15,5.3,"workshop")
	w.base_fires.append(Vector2(127,-1204))
	w.water_pond(Vector2(169,-1238),10)
	for z in range(-1257,-1214,3):
		w.block(w.C.ground(Vector2(153,z),.2),Vector3(.45,.4,2.8),w.paint("stone"),false)
	for x in [145.0,152.0]:
		w.block(w.C.ground(Vector2(x,-1229),1),Vector3(.22,2,.22),w.paint("wood"),false)
	w.beam(w.C.ground(Vector2(145,-1229),1.7),w.C.ground(Vector2(152,-1229),1.7),.18)
	var wheel: MeshInstance3D = w.cylinder(w.C.ground(Vector2(148,-1216),2.5),2.2,.55,w.paint("wood"),w,false)
	wheel.rotation.z = PI/2
	for i in range(8):
		var angle := float(i)*TAU/8
		w.beam(w.C.ground(Vector2(148,-1216),2.5),w.C.ground(Vector2(148,-1216+cos(angle)*2.1),2.5+sin(angle)*2.1),.16)
	w.block(w.C.ground(Vector2(130,-1230),.23),Vector3(.8,.46,2.1),w.flat(Color("a6a49a")),false)
	w.block(w.C.ground(Vector2(130,-1230.75),.3),Vector3(.58,.5,.5),w.flat(Color("a6a49a")),false)
	post(w,Vector2(123,-1195),"BLACKWATER SLUICE\nDRAINED CHANNEL / SOUTH")
	post(w,Vector2(144,-1265),"WHITE KILN / NORTH\nALDERWAKE / SOUTHWEST")
	# Sanctuary: a living grove with a house, refusal records, and ordinary work.
	w.cottage(Vector2(-164,-1322),11,12,4.0,"home")
	w.base_fires.append(Vector2(-143,-1316))
	for i in range(7):
		var angle := float(i)*TAU/7
		var p := Vector2(-150,-1340)+Vector2(cos(angle),sin(angle))*10
		w.cylinder(w.C.ground(p,2.5),.25,5,w.paint("wood"),w,false,.12)
		w.beam(w.C.ground(p,3.3),w.C.ground(p+Vector2(1.3,1.2),4.7),.14)
		w.sprite("props",3,4,2,w.C.ground(p,5),2.2)
	w.cylinder(w.C.ground(Vector2(-160,-1325),.55),.5,.25,w.paint("stone"))
	label(w,"AN OFFERING MAY BE REFUSED",Vector2(-150,-1335),2.3,22)
	post(w,Vector2(-138,-1306),"ROWAN SANCTUARY\nALL MAY DRINK / NONE MUST PLEDGE")
	post(w,Vector2(-151,-1363),"OLD ASSIZE / NORTH\nWHITE KILN / EAST")
	# Kiln: open evidence benches, a masonry furnace, and a service shelter.
	w.cottage(Vector2(176,-1390),10,10,4.0,"workshop")
	w.base_fires.append(Vector2(152,-1382))
	w.cylinder(w.C.ground(Vector2(165,-1412),2.0),3.5,4,w.paint("stone"),w,true,2.7)
	w.cylinder(w.C.ground(Vector2(165,-1412),4.2),1.1,1.1,w.paint("stone"),w,true,.8)
	for p in [Vector2(173,-1410),Vector2(156,-1393)]:
		w.block(w.C.ground(p,.55),Vector3(2,.15,1.2),w.paint("wood"),false)
	post(w,Vector2(153,-1368),"THE WHITE KILN\nWATCH CONTRACTS / BOLT MOULDS")
	post(w,Vector2(148,-1435),"ROOT CELLARS / NORTH\nROOT COURT / BEYOND")
	# Ruined assize still has a proper doorway and a staffed copy desk.
	w.cottage(Vector2(-150,-1535),16,18,5.0,"office")
	w.cottage(Vector2(-181,-1576),10,10,3.8,"pantry")
	w.base_fires.append(Vector2(-139,-1514))
	for p in [Vector2(-163,-1528),Vector2(-137,-1538)]:
		w.block(w.C.ground(p,1.4),Vector3(.65,2.8,5),w.paint("stone"))
	post(w,Vector2(-141,-1497),"THE BURNED ASSIZE\nEDRIC KEEPS THE ORIGINALS")
	# The cellar is above grade: no loading screen, ladder or inaccessible basement.
	w.cottage(Vector2(143,-1570),20,18,4.3,"pantry")
	w.base_fires.append(Vector2(128,-1540))
	for x in [137.0,143.0,149.0]:
		var shutter: MeshInstance3D = w.block(w.C.ground(Vector2(x,-1561),1.15),Vector3(4,2.3,.15),w.paint("wood"),false)
		nodes["shutter_"+str(int(x))] = shutter
	for p in [Vector2(137,-1551),Vector2(143,-1560)]:
		var handle: MeshInstance3D = w.cylinder(w.C.ground(p,1),.38,.12,w.paint("wood"),w,false)
		handle.rotation.x = PI/2
	nodes.release_label = label(w,"SILAS / JORY / TEREN",Vector2(143,-1558),2.0,22)
	post(w,Vector2(132,-1528),"THE ROOT CELLARS\nVENT FIRST / THEN RELEASE")
	# Root court sits at the meeting of the two roads, separate from the sanctuary.
	w.cottage(Vector2(44,-1642),9,10,4.1,"home")
	w.base_fires.append(Vector2(17,-1630))
	for i in range(9):
		var angle := float(i)*TAU/9
		var p := Vector2(30,-1650)+Vector2(cos(angle),sin(angle))*12
		w.cylinder(w.C.ground(p,1.3),.7,2.6,w.paint("stone"),w,false,.4)
		w.beam(w.C.ground(p,.2),w.C.ground(Vector2(30,-1650),.3),.14)
	post(w,Vector2(21,-1618),"THE ROOT COURT\nTHE LISTENING OAK / NORTHWEST")
	# A large, readable oak silhouette with accessible knots around its clearing.
	w.cylinder(w.C.ground(Vector2(-95,-1775),4.5),1.6,9,w.paint("wood"),w,true,1.1)
	for i in range(7):
		var angle := float(i)*TAU/7
		var p := Vector2(-95,-1775)+Vector2(cos(angle),sin(angle))*8
		w.beam(w.C.ground(Vector2(-95,-1775),6.5),w.C.ground(p,9+float(i%3)),.55)
		w.sprite("trees",i%4,4,1,w.C.ground(p,4),8.0)
		w.beam(w.C.ground(Vector2(-95,-1775),.1),w.C.ground(p*0.6+Vector2(-95,-1775)*0.4,.15),.23)
	for key in ["ward_west","ward_east","ward_north"]:
		var p: Vector2 = D.OBJECTS["nw_"+key].pos
		var knot: MeshInstance3D = w.cylinder(w.C.ground(p,.8),.45,1.6,w.paint("wood"),w,false,.25)
		nodes[key] = knot
		label(w,key.trim_prefix("ward_").to_upper()+" BINDING",p,1.85,18)
	nodes.heart_glow = w.glow(w.C.ground(Vector2(-95,-1775),2.4),3,Color(.45,.7,.48,.5))
	post(w,Vector2(-91,-1735),"THE LISTENING OAK\nNO PERSON BELONGS TO THE ROOTS")
	# Relief travellers bring rescued adults here; this never creates child victims.
	for index in range(3):
		var p := Vector2(-31+index*5,-1116)
		var survivor: Sprite3D = w.sprite("npcs-cut",[1,4,6][index],4,2,w.C.ground(p),1.85,false)
		nodes["survivor_"+str(index)] = survivor
		nodes["survivor_name_"+str(index)] = label(w,["SILAS / 38","JORY / 46","TEREN / 25"][index],p,2.05,18)
	for p in [Vector2(7,-1015),Vector2(-13,-1098),Vector2(130,-1230),Vector2(137,-1551),Vector2(143,-1560),Vector2(-95,-1775),Vector2(-108,-1765),Vector2(-82,-1765),Vector2(-95,-1786),Vector2(-160,-1325)]:
		w.lush_grass.add_circle(p,2.5)

func apply(w: Node3D) -> void:
	if nodes.is_empty(): return
	var q: Dictionary = w.game.state.woods
	for key in ["cause","access","motive"]:
		nodes["board_"+key].material_override.albedo_color = Color("9ecca6") if q[key] else Color("d7c7a1")
	nodes.boat.visible = q.boat_returned
	for key in ["ward_west","ward_east","ward_north"]:
		nodes[key].rotation.z = .8 if q[key] else 0.0
		nodes[key].material_override = w.flat(Color("71816a")) if q[key] else w.paint("wood")
	for key in ["shutter_137","shutter_143","shutter_149"]: nodes[key].visible = not q.rescued
	nodes.release_label.text = "THREE NAMES RETURNED HOME" if q.rescued else "SILAS / JORY / TEREN"
	for index in range(3):
		nodes["survivor_"+str(index)].visible = q.rescued
		nodes["survivor_name_"+str(index)].visible = q.rescued
	nodes.heart_glow.visible = not q.heart_done or q.pact!="sever"
	if w.npcs.has("bran"):
		w.npcs.bran.modulate = Color("a4a7a0") if not q.justice.is_empty() else Color.WHITE
		w.npcs.bran.visible = q.justice!="exile"
	if w.npcs.has("vey"): w.npcs.vey.visible = q.justice!="hearing" or not q.rescued
