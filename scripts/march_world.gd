extends RefCounted

const C = preload("res://scripts/content.gd")
var nodes: Dictionary = {}

func build(w: Node3D) -> void:
	# Saint Avel's low timber crossing keeps the walkable grade close to terrain.
	var bridge := C.ground(Vector2(0,-435))
	var deck_surface := SurfaceTool.new()
	deck_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-451,-419,2):
		for p in [Vector2(-3.7,z),Vector2(3.7,z),Vector2(-3.7,z+2),Vector2(3.7,z),Vector2(3.7,z+2),Vector2(-3.7,z+2)]:
			var rise := smoothstep(0.0,5.0,minf(p.y+451.0,-419.0-p.y))*0.26
			deck_surface.set_uv(p/2.0)
			deck_surface.add_vertex(C.ground(p,rise+0.005))
	deck_surface.generate_normals()
	var deck := MeshInstance3D.new()
	deck.mesh = deck_surface.commit()
	deck.material_override = w.paint("wood")
	deck.set_meta("footstep_family","footstep_wood")
	w.add_child(deck)
	deck.create_trimesh_collision()
	for z in range(-448,-421,2):
		for x in [-3.8,3.8]:
			w.block(C.ground(Vector2(x,z),1.0),Vector3(0.23,1.9,0.23),w.paint("wood"),false)
			w.block(C.ground(Vector2(x,z),1.65),Vector3(0.16,0.18,2.1),w.paint("wood"),false)
	var water: Array[Vector3] = []
	for x in range(-65,65,2):
		for p in [Vector2(x,-441),Vector2(x+2,-441),Vector2(x,-430),Vector2(x+2,-441),Vector2(x+2,-430),Vector2(x,-430)]:
			water.append(C.ground(p,0.07))
	w.water_surface(water)
	for x in [-7.0,7.0]:
		w.block(C.ground(Vector2(x,-435),2.5),Vector3(2.0,5.0,2.0),w.paint("stone"))
		cross(w,C.ground(Vector2(x,-435),6.0),0.65)
	w.signpost(Vector2(21,-355),"SAINT MERE / NORTH\nTHE ASHEN MARCH")
	w.signpost(Vector2(6,-460),"SAINT MERE / NORTH\nNORTHWATCH / SOUTH")
	# A lived-in refuge: shelter, hearth, sickbeds, storage and a dry public table.
	w.cottage(Vector2(-77,-539),16,16,4.6,"ward")
	w.cottage(Vector2(-47,-541),10,11,4.0,"pantry")
	w.cottage(Vector2(-90,-513),9,9,3.8)
	w.base_fires.append(Vector2(-65,-514))
	w.signpost(Vector2(-55,-510),"SAINT MERE REFUGE\nCLEAN WATER / REST")
	w.signpost(Vector2(-58,-555),"ORCHARD / WEST\nFERRY / EAST\nHOSPICE / NORTH")
	for x in [-80.0,-73.0]:
		var at := C.ground(Vector2(x,-540),0.55)
		w.block(at,Vector3(2.2,0.65,3.5),w.paint("wood"))
		w.block(at+Vector3(0,.37,0),Vector3(2.1,.14,3.3),w.flat(Color("d4cdb9")),false)
		var blanket: MeshInstance3D = quilt(w,at,Color("a5b7ac") if x< -76 else Color("b3a9c4"))
		nodes["raisa" if x< -76 else "pavel"] = blanket
		var id := "raisa" if x< -76 else "pavel"
		nodes["pillow_"+id] = w.block(at+Vector3(0,.49,-1.1),Vector3(1.3,.16,.7),w.flat(Color("d4c8a8")),false)
		# Upright, propped figures: never a card rotated flat onto the mattress.
		var person := Sprite3D.new()
		person.name = "Seated"+id.capitalize()
		person.texture = w.library.cell("res://assets/old-masters/refuge-patients-seated.png",0 if id=="raisa" else 1,2,1)
		person.pixel_size = 1.12/person.texture.get_height()
		person.material_override = w.actor_material(person.texture)
		person.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(person)
		person.position = at+Vector3(0,.53+1.12/2,-.75)
		nodes["patient_"+id] = person
		var folded: MeshInstance3D = w.block(at+Vector3(0,.48,.6),Vector3(1.7,.14,.8),w.architecture.textile(w,2,Color("d3cbb7")),false)
		folded.visible = false
		nodes["folded_"+id] = folded
	label3(w,"RAISA / 54",C.ground(Vector2(-80,-538.1),1.1),18)
	label3(w,"PAVEL / 27",C.ground(Vector2(-73,-538.1),1.1),18)
	# Burned orchard: charred frame, roofless press and an intimate memorial corner.
	var charred: Material = w.paint("wood").duplicate()
	charred.set_shader_parameter("tint",Color("45423c"))
	for x in [-220.0,-210.0]:
		for z in [-657.0,-645.0]:
			w.block(C.ground(Vector2(x,z),2.4),Vector3(0.4,4.8,0.4),charred)
		w.beam(C.ground(Vector2(x,-657),4.5),C.ground(Vector2(x,-645),4.5),0.25)
	w.block(C.ground(Vector2(-215,-657),0.8),Vector3(11,1.6,0.7),w.paint("stone"))
	w.cottage(Vector2(-184,-608),9,9,3.8)
	w.base_fires.append(Vector2(-181,-622))
	for index in range(25):
		var p := Vector2(-225+(index%5)*12,-603-(index/5)*10)
		if p.distance_to(Vector2(-196,-620))<8: continue
		w.cylinder(C.ground(p,1.8),0.17,3.6,charred,w,true)
		w.beam(C.ground(p,2.8),C.ground(p+Vector2(1.8,-1.4),4.1),0.14)
		w.beam(C.ground(p,3.1),C.ground(p+Vector2(-1.6,0.8),4.3),0.11)
	cross(w,C.ground(Vector2(-196,-620),1.3),1.0)
	nodes.memorial = label3(w,"ELIAS VALE",C.ground(Vector2(-196,-619.8),2.2),32)
	w.signpost(Vector2(-178,-597),"BELLWETHER ORCHARD\nTHE OLD PRESS / SOUTHWEST")
	# Ferry hut and jetty, moored boat, broken winch and a sloping wreck.
	w.cottage(Vector2(124,-594),10,9,3.8,"ferry")
	w.base_fires.append(Vector2(132,-587))
	w.water_pond(Vector2(168,-615),29)
	var jetty_surface := SurfaceTool.new()
	jetty_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-628,-586,2):
		for p in [Vector2(138,z),Vector2(144,z),Vector2(138,z+2),Vector2(144,z),Vector2(144,z+2),Vector2(138,z+2)]:
			var rise := smoothstep(0.0,4.0,minf(p.y+628.0,-586.0-p.y))*0.22
			jetty_surface.set_uv(p/2)
			jetty_surface.add_vertex(C.ground(p,rise+0.005))
	jetty_surface.generate_normals()
	var jetty := MeshInstance3D.new()
	jetty.mesh = jetty_surface.commit()
	jetty.material_override = w.paint("wood")
	jetty.set_meta("footstep_family","footstep_wood")
	w.add_child(jetty)
	jetty.create_trimesh_collision()
	for z in range(-624,-589,3):
		for x in [137.7,144.3]:
			w.cylinder(C.ground(Vector2(x,z),0.7),0.17,1.8,w.paint("wood"))
	var boat := Node3D.new()
	w.add_child(boat)
	boat.position = C.ground(Vector2(150,-617),0.3)
	w.block(Vector3(0,0,0),Vector3(5,0.25,10),w.paint("wood"),false,boat)
	for x in [-2.4,2.4]: w.block(Vector3(x,0.7,0),Vector3(0.25,1.4,10),w.paint("wood"),false,boat)
	for z in [-4.8,4.8]: w.block(Vector3(0,0.7,z),Vector3(5,1.4,0.25),w.paint("wood"),false,boat)
	nodes.boat = boat
	var wreck := boat.duplicate() as Node3D
	w.add_child(wreck)
	wreck.position = C.ground(Vector2(150,-649),0.1)
	wreck.rotation = Vector3(0.12,-0.3,0.30)
	var winch: MeshInstance3D = w.cylinder(C.ground(Vector2(140,-593),1),0.6,1.8,w.paint("wood"))
	winch.rotation.z = PI/2
	nodes.winch = winch
	w.signpost(Vector2(130,-583),"REEDWATER LANDING\nTHE WRECK / SOUTH")
	# Veyr's stores: a courtyard, public desk, storehouse and guarded wine annex.
	w.cottage(Vector2(177,-760),17,16,5.5,"office")
	w.cottage(Vector2(197,-782),10,10,4.2,"pantry")
	w.base_fires.append(Vector2(164,-743))
	for x in [162.0,191.0]:
		w.block(C.ground(Vector2(x,-750),1.1),Vector3(0.5,2.2,16),w.paint("stone"))
		w.block(C.ground(Vector2(x,-742),1.8),Vector3(1.1,3.6,1.1),w.paint("stone"))
	w.signpost(Vector2(176,-733),"VEYR COUNTING HOUSE\nSTORES / RECORDS")
	# Quarry camp: no solid decorative clutter in the road or around the witness.
	w.cottage(Vector2(-148,-786),10,10,3.6,"workshop")
	w.base_fires.append(Vector2(-147,-802))
	for i in range(14):
		var p := Vector2(-200+(i%4)*5,-817-(i/4)*5)
		w.block(C.ground(p,0.65),Vector3(3.5,1.3,2.6),w.paint("stone"))
	w.signpost(Vector2(-143,-777),"GALLOWS CUT\nTHE QUARRY CAMP")
	# Hospice chapel and wards: familiar architecture, a Catholic altar and named stones.
	w.cottage(Vector2(0,-951),26,32,6.5,"chapel")
	for x in [-10.0,10.0]:
		for z in [-960.0,-948.0]:
			w.block(C.ground(Vector2(x,z),0.7),Vector3(2.0,0.7,5.0),w.paint("wood"))
	w.block(C.ground(Vector2(0,-955),0.8),Vector3(5.5,1.6,1.8),w.paint("stone"))
	cross(w,C.ground(Vector2(0,-962),4.7),2.1)
	label3(w,"LORD JESUS CHRIST / REMEMBER THEM",C.ground(Vector2(0,-961.8),2.7),32)
	w.base_fires.append(Vector2(-12,-918))
	w.signpost(Vector2(14,-921),"SAINT MARY'S HOSPICE\nTHE NAMES ARE KEPT HERE")
	for p in [Vector2(-6,-937),Vector2(6,-937),Vector2(-10,-931)]:
		w.block(C.ground(p,0.50),Vector3(1.6,1.0,0.45),w.paint("stone"))
	var bell: MeshInstance3D = w.cylinder(C.ground(Vector2(0,-942),4.0),0.8,1.1,w.flat(Color("a58147")),w,false,0.42)
	nodes.bell = bell
	for x in [-1.5,1.5]: w.block(C.ground(Vector2(x,-942),2.7),Vector3(0.22,5.4,0.22),w.paint("wood"))
	w.block(C.ground(Vector2(0,-942),5.4),Vector3(3.2,0.3,0.3),w.paint("wood"))
	for index in range(12):
		var p := Vector2(20+(index%3)*4,-938-(index/3)*5)
		cross(w,C.ground(p,1.0),0.65)
	w.signpost(Vector2(5,-990),"ALDERWAKE / NORTH\nHESTER SEEKS WITNESSES")
	for p in [Vector2(8,-439),Vector2(-200,-632)]:
		var at := C.ground(p)
		w.block(at+Vector3(0,0.4,0),Vector3(1.0,0.8,0.8),w.paint("stone"))
		w.cylinder(at+Vector3(0,0.95,0),0.10,0.3,w.flat(Color("d9cfab")))
		w.glow(at+Vector3(0,1.17,0),0.3,Color("ffc47c"))
		cross(w,at+Vector3(0,1.7,-0.3),0.55)

func quilt(w: Node3D, at: Vector3, colour: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(12):
		for column in range(8):
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var x: float = -1.05+(column+corner.x)*2.1/8
				var z: float = -1.55+(row+corner.y)*3.1/12
				var drape: float = exp(-pow(x/.6,2))*(.17+.10*sin((z+1.55)*PI/3.1))
				surface.set_uv(Vector2(x,z))
				surface.add_vertex(Vector3(x,.44+drape+.018*sin(z*15+x*4),z))
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.material_override = w.architecture.textile(w,1,colour).duplicate()
	w.add_child(node)
	node.position = at
	return node

func cross(w: Node3D, at: Vector3, scale: float) -> void:
	var bottom := C.height_at(at.x,at.z)-.03
	var top := at.y+.95*scale
	var stem: MeshInstance3D = w.block(Vector3(at.x,(bottom+top)*.5,at.z),Vector3(.16*scale,top-bottom,.16*scale),w.paint("wood"),false)
	stem.add_to_group("march_cross_stems")
	w.block(at+Vector3(0,0.45*scale,0),Vector3(1.0,0.16,0.16)*scale,w.paint("wood"),false)

func label3(w: Node3D, text: String, at: Vector3, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.008
	label.modulate = Color("ded0a7")
	label.outline_size = 3
	label.no_depth_test = false
	w.add_child(label)
	label.position = at
	return label

func apply(w: Node3D) -> void:
	if nodes.is_empty(): return
	var q: Dictionary = w.game.state.story
	nodes.memorial.visible = q.ashes_done
	for id in ["raisa","pavel"]:
		nodes[id].material_override.set_shader_parameter("tint",Color("c4bca5") if q.medicine_done and q.patient!=id else Color("a5b7ac") if id=="raisa" else Color("b3a9c4"))
		var occupied: bool = not q.medicine_done or q.patient==id
		nodes["patient_"+id].visible = occupied
		nodes["folded_"+id].visible = not occupied
		nodes["pillow_"+id].visible = not occupied
		nodes[id].visible = occupied
	nodes.winch.rotation.x = 0.3 if q.ferry_fixed else -0.2
	nodes.bell.material_override.albedo_color = Color("d4b572") if q.bell_done else Color("87704b")
	for id in ["ash_names_mateo","ash_names_elias","ash_names_alina","ash_candle_bridge","ash_candle_orchard"]:
		if w.objects.has(id):
			var key: String = id.trim_prefix("ash_names_")
			var lit: bool = q.get("name_"+key,false) if id.begins_with("ash_names_") else q.get("candle_bridge" if id=="ash_candle_bridge" else "candle_orchard",false)
			w.objects[id].modulate = Color("ffe0a0") if lit else Color.WHITE
