extends RefCounted

# Shared architectural vocabulary, with contents selected by the building's use.
# No global RNG: decoration must not change encounters or procedural vegetation.
func material(w: Node3D, kind: String, color: Color) -> ShaderMaterial:
	var key := "architecture:"+kind+color.to_html()
	if not w.mats.has(key):
		var m: ShaderMaterial = w.paint(kind).duplicate()
		m.set_shader_parameter("tint",color)
		if kind=="wood":
			m.set_shader_parameter("atlas",w.tex("revision/interior-materials"))
			m.set_shader_parameter("tile",Vector2.ZERO)
		w.mats[key] = m
	return w.mats[key]

func textile(w: Node3D, quadrant: int, color := Color.WHITE) -> ShaderMaterial:
	var key := "textile:%d:" % quadrant+color.to_html()
	if not w.mats.has(key):
		var m := material(w,"wood",color).duplicate()
		m.set_shader_parameter("tile",Vector2(quadrant%2,quadrant/2))
		m.set_shader_parameter("scale",.85 if quadrant==2 else 1.4)
		w.mats[key] = m
	return w.mats[key]

func shell(w: Node3D, h: Node3D, width: float, depth: float, tall: float, purpose: String) -> void:
	var wash := Color("c3c1ad")
	if purpose in ["inn","ferry"]: wash = Color("8daba0")
	elif purpose in ["mill","workshop"]: wash = Color("b5a18b")
	elif purpose in ["office","pantry"]: wash = Color("b78c76")
	var plaster: ShaderMaterial = w.paint("plaster").duplicate()
	plaster.set_shader_parameter("limewash",true)
	plaster.set_shader_parameter("tint",wash)
	plaster.set_shader_parameter("foundation_y",h.position.y)
	plaster.set_shader_parameter("scale",0.32)
	plaster.set_shader_parameter("back_atlas",w.tex("revision/interior-materials"))
	h.set_meta("wall_material",plaster)
	h.set_meta("purpose",purpose)
	var wood := material(w,"wood",Color("756e60"))
	# Stone plinth and timber rails break up the wall at human scale.
	w.block(Vector3(0,.3025,0),Vector3(width-.35,.015,depth-.35),material(w,"wood",Color("aaa18b")),false,h)
	wall(w,h,Vector3(0,0,-depth/2),0,width,tall,[],plaster,wood)
	for side in [-1.0,1.0]:
		wall(w,h,Vector3(side*width/2,0,0),PI/2,depth,tall,[-depth*.25,depth*.25],plaster,wood)
	# A human-scale arched portal replaces the shed-like full-height opening.
	var door := clampf(width*.20,2.2,3.2)
	var wing := (width-door)*.5
	for side in [-1.0,1.0]:
		wall(w,h,Vector3(side*(door+wing)*.5,0,depth/2),0,wing,tall,[0.0],plaster,wood)
	doorway(w,h,door,tall,depth,plaster)
	ornament(w,h,width,depth,tall,purpose)
	# Visible rafters and trusses give the roof interior depth without a low ceiling.
	for z in [-depth*.35,0.0,depth*.35]:
		w.beam(Vector3(-width/2,tall-.12,z),Vector3(width/2,tall-.12,z),.22,h)
		w.beam(Vector3(-width/2,tall,z),Vector3(0,tall+2.4,z),.14,h)
		w.beam(Vector3(width/2,tall,z),Vector3(0,tall+2.4,z),.14,h)
	for x in [-width*.28,width*.28]:
		w.beam(Vector3(x,tall+.6,-depth/2),Vector3(x,tall+.6,depth/2),.15,h)

func doorway(w: Node3D, h: Node3D, width: float, tall: float, depth: float, plaster: Material) -> void:
	var r := width*.5
	var spring := maxf(1.85,3.10-r)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var x0 := -r+width*i/16.0
		var x1 := -r+width*(i+1)/16.0
		var y0 := spring+sqrt(maxf(0,r*r-x0*x0))
		var y1 := spring+sqrt(maxf(0,r*r-x1*x1))
		for sign_value in [-1.0,1.0]:
			var z: float = depth*.5+sign_value*.2
			for v in [Vector3(x0,y0,z),Vector3(x1,y1,z),Vector3(x0,tall,z),Vector3(x1,y1,z),Vector3(x1,tall,z),Vector3(x0,tall,z)]: surface.add_vertex(v)
		for v in [Vector3(x0,y0,depth*.5-.2),Vector3(x1,y1,depth*.5-.2),Vector3(x0,y0,depth*.5+.2),Vector3(x1,y1,depth*.5-.2),Vector3(x1,y1,depth*.5+.2),Vector3(x0,y0,depth*.5+.2)]: surface.add_vertex(v)
	surface.generate_normals()
	var face := MeshInstance3D.new()
	face.mesh = surface.commit()
	face.material_override = plaster
	h.add_child(face)
	face.create_trimesh_collision()
	var stone := material(w,"stone",Color("c2b89e"))
	for i in range(13):
		var a := (i+.5)*PI/13.0
		var voussoir: MeshInstance3D = w.block(Vector3(cos(a)*(r+.12),spring+sin(a)*(r+.12),depth*.5+.09),Vector3(.27,(r+.12)*PI/13*.94,.62),stone,false,h)
		voussoir.rotation.z = a
	for side in [-1.0,1.0]:
		w.block(Vector3(side*(r+.12),spring*.5,depth*.5+.09),Vector3(.27,spring,.62),stone,false,h)
		for y in [.40,spring-.06]: w.block(Vector3(side*(r+.12),y,depth*.5+.1),Vector3(.43,.16,.73),stone,false,h)
	w.block(Vector3(0,spring+r+.05,depth*.5+.13),Vector3(.28,.42,.75),stone,false,h)

func ornament(w: Node3D, h: Node3D, width: float, depth: float, tall: float, purpose: String) -> void:
	var wood := material(w,"wood",Color("8c7d65"))
	var stone := material(w,"stone",Color("c1b9a3"))
	# Carved brackets beneath the eaves, moulded lintels and small gable oculi.
	for x in [-width*.5,width*.5]:
		for z in [-depth*.5,depth*.5]:
			w.block(Vector3(x,tall-.13,z),Vector3(.46,.25,.46),wood,false,h)
			w.beam(Vector3(x,tall-.85,z),Vector3(x,tall-.05,z+signf(z)*.55),.20,h)
	for z in [-depth*.5-.18,depth*.5+.18]:
		w.block(Vector3(0,tall+.08,z),Vector3(width+.4,.17,.2),wood,false,h)
		var disk: MeshInstance3D = w.cylinder(Vector3(0,tall+1.12,z),.40,.12,stone,h)
		disk.rotation.x = PI/2
		var centre: MeshInstance3D = w.cylinder(Vector3(0,tall+1.12,z),.27,.24,w.flat(Color("414a43")),h)
		centre.rotation.x = PI/2
		w.block(Vector3(0,tall+1.12,z),Vector3(.055,.55,.32),wood,false,h)
		w.block(Vector3(0,tall+1.12,z),Vector3(.55,.055,.32),wood,false,h)
	if purpose in ["office","chapel","inn"]:
		for side in [-1.0,1.0]:
			var at := Vector3(side*width*.35,tall-.7,depth*.5+.25)
			var plaque: MeshInstance3D = w.block(at,Vector3(.32,.32,.09),stone,false,h)
			plaque.rotation.z = PI/4

func wall(w: Node3D, h: Node3D, at: Vector3, yaw: float, span: float, tall: float, windows: Array, plaster: Material, wood: Material) -> void:
	var panel := Node3D.new()
	h.add_child(panel)
	panel.position = at
	panel.rotation.y = yaw
	var sill := 1.4
	var lintel := minf(2.95,tall-.35)
	var half := minf(.66,span*.26)
	var cursor := -span/2
	for x: float in windows:
		var start := x-half
		if start>cursor: w.block(Vector3((start+cursor)/2,tall/2,0),Vector3(start-cursor,tall,.4),plaster,true,panel)
		w.block(Vector3(x,sill/2,0),Vector3(half*2,sill,.4),plaster,true,panel)
		w.block(Vector3(x,(tall+lintel)/2,0),Vector3(half*2,tall-lintel,.4),plaster,true,panel)
		window(w,panel,Vector3(x,(sill+lintel)/2,0),half*2,lintel-sill,wood)
		cursor = x+half
	if cursor<span/2: w.block(Vector3((cursor+span/2)/2,tall/2,0),Vector3(span/2-cursor,tall,.4),plaster,true,panel)
	w.block(Vector3(0,.58,0),Vector3(span+.015,.5,.47),w.paint("stone"),false,panel)
	for y in [.87,tall-.08]: w.block(Vector3(0,y,0),Vector3(span+.12,.16,.53),wood,false,panel)
	if h.get_meta("purpose") in ["inn","office","home","chapel"]:
		var panels := maxi(1,int(span/1.4))
		var step := (span-.3)/panels
		var inset := material(w,"wood",Color("9d9988"))
		for face in [-1.0,1.0]:
			w.block(Vector3(0,1.28,face*.235),Vector3(span,.075,.07),wood,false,panel)
			for i in range(panels):
				var x := -span/2+.15+step*(i+.5)
				w.block(Vector3(x,1.07,face*.22),Vector3(step-.10,.34,.055),inset,false,panel)
				for side in [-1.0,1.0]: w.block(Vector3(x+side*(step-.08)*.5,1.07,face*.25),Vector3(.045,.4,.065),wood,false,panel)
	for x in [-span/2,span/2]: w.block(Vector3(x,tall/2,0),Vector3(.22,tall+.1,.54),wood,false,panel)
	if span>5:
		w.block(Vector3(0,tall/2,0),Vector3(.18,tall,.52),wood,false,panel)
		for side in [-1.0,1.0]:
			w.beam(Vector3(side*(span/2-.15),.95,.23),Vector3(side*span*.29,tall-.15,.23),.12,panel)

func window(w: Node3D, p: Node3D, at: Vector3, width: float, height: float, wood: Material) -> void:
	# Glass sits within the actual opening. Deep reveals and a sill read from inside too.
	var glass: Material = w.flat(Color("667a72"),.12)
	w.block(at,Vector3(width,height,.035),glass,false,p)
	for x in [-width/2,width/2]: w.block(at+Vector3(x,0,0),Vector3(.10,height+.2,.5),wood,false,p)
	for y in [-height/2,height/2]: w.block(at+Vector3(0,y,0),Vector3(width+.22,.11,.56),wood,false,p)
	w.block(at+Vector3(0,-height/2-.04,0),Vector3(width+.32,.10,.78),w.paint("stone"),false,p)
	w.block(at,Vector3(.055,height,.12),wood,false,p)
	w.block(at+Vector3(0,.12,0),Vector3(width,.055,.12),wood,false,p)
	# Thin diamond leading, clipped by construction to the glass bounds.
	for sign_value in [-1.0,1.0]:
		for offset in [-.48,0.0,.48]:
			var low := maxf(-height/2,(-width/2-offset)*sign_value)
			var high := minf(height/2,(width/2-offset)*sign_value)
			if sign_value<0:
				low = maxf(-height/2,(offset-width/2))
				high = minf(height/2,(offset+width/2))
			if high>low:
				w.beam(at+Vector3(offset+sign_value*low,low,.035),at+Vector3(offset+sign_value*high,high,.035),.022,p)
	for side in [-1.0,1.0]:
		var shutter: MeshInstance3D = w.block(at+Vector3(side*(width*.5+.27),0,.27),Vector3(.40,height+.12,.09),wood,false,p)
		shutter.rotation.y = side*.25
		for y in [-height*.32,height*.32]: w.block(at+Vector3(side*(width*.5+.27),y,.34),Vector3(.42,.065,.05),w.flat(Color("45433b")),false,p)

func table(w: Node3D, p: Node3D, at: Vector3, size: Vector2) -> void:
	var wood := material(w,"wood",Color("8b7e68"))
	w.block(at+Vector3(0,.92,0),Vector3(size.x,.14,size.y),wood,true,p)
	w.block(at+Vector3(0,.81,0),Vector3(size.x*.91,.09,size.y*.86),wood,false,p)
	for x in [-size.x*.38,size.x*.38]:
		for z in [-size.y*.34,size.y*.34]:
			lathe(w,p,at+Vector3(x,0,z),[Vector2(.10,.32),Vector2(.10,.39),Vector2(.06,.48),Vector2(.09,.59),Vector2(.065,.72),Vector2(.11,.86)],wood)
	w.block(at+Vector3(0,.52,0),Vector3(size.x*.85,.1,.12),wood,false,p)

func bench(w: Node3D, p: Node3D, at: Vector3, length: float) -> void:
	var wood := material(w,"wood",Color("897d6a"))
	w.block(at+Vector3(0,.66,0),Vector3(length,.13,.44),wood,true,p)
	for x in [-length*.37,length*.37]: w.block(at+Vector3(x,.48,0),Vector3(.16,.36,.4),wood,false,p)

func chair(w: Node3D, p: Node3D, at: Vector3) -> void:
	var wood := material(w,"wood",Color("a39981"))
	w.block(at+Vector3(0,.72,0),Vector3(.64,.12,.62),wood,false,p)
	w.block(at+Vector3(0,1.26,.25),Vector3(.54,.84,.09),wood,false,p)
	w.block(at+Vector3(0,1.27,.31),Vector3(.38,.54,.04),textile(w,2),false,p)
	for x in [-.26,.26]:
		for z in [-.24,.24]:
			lathe(w,p,at+Vector3(x,0,z),[Vector2(.06,.33),Vector2(.045,.50),Vector2(.065,.62),Vector2(.06,.72)],wood)
		lathe(w,p,at+Vector3(x,0,.25),[Vector2(.045,.75),Vector2(.045,1.65),Vector2(.075,1.7),Vector2(.03,1.8)],wood)

func vessel(w: Node3D, p: Node3D, at: Vector3, radius: float, color: Color) -> void:
	var clay := material(w,"plaster",color)
	var profile: Array[Vector2] = [Vector2(.55,0),Vector2(.75,.08),Vector2(.96,.35),Vector2(1,.8),Vector2(.85,1.25),Vector2(.48,1.5),Vector2(.45,1.75),Vector2(.58,1.82),Vector2(.58,1.93),Vector2(.37,1.93),Vector2(.35,1.75)]
	for i in range(profile.size()): profile[i] *= radius
	lathe(w,p,at,profile,clay)
	w.cylinder(at+Vector3(0,radius*1.75,0),radius*.35,.012,w.flat(color.darkened(.7)),p)

func lathe(_w: Node3D, p: Node3D, at: Vector3, profile: Array[Vector2], mat: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(profile.size()-1):
		for segment in range(16):
			var a := segment*TAU/16.0
			var b := (segment+1)*TAU/16.0
			var low := profile[ring]
			var high := profile[ring+1]
			var v0 := Vector3(cos(a)*low.x,low.y,sin(a)*low.x)
			var v1 := Vector3(cos(b)*low.x,low.y,sin(b)*low.x)
			var v2 := Vector3(cos(a)*high.x,high.y,sin(a)*high.x)
			var v3 := Vector3(cos(b)*high.x,high.y,sin(b)*high.x)
			for point in [v0,v2,v1,v1,v2,v3]: surface.add_vertex(point)
	surface.index()
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = mat
	p.add_child(mesh)
	mesh.position = at
	mesh.visibility_range_end = 75
	mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	return mesh

func barrel(w: Node3D, p: Node3D, at: Vector3) -> void:
	var wood := material(w,"wood",Color("9c8b70"))
	lathe(w,p,at,[Vector2(.32,.32),Vector2(.38,.36),Vector2(.45,.58),Vector2(.47,.82),Vector2(.45,1.06),Vector2(.36,1.24)],wood)
	for y in [.41,.77,1.16]: w.cylinder(at+Vector3(0,y,0),.465 if y==.77 else .4,.055,w.flat(Color("454942")),p)
	w.cylinder(at+Vector3(0,1.25,0),.37,.035,wood,p)

func sack(w: Node3D, p: Node3D, at: Vector3, shade: Color) -> void:
	lathe(w,p,at,[Vector2(.22,.32),Vector2(.35,.4),Vector2(.39,.65),Vector2(.33,.96),Vector2(.14,1.08),Vector2(.21,1.19)],textile(w,1,shade.lightened(.25)))
	w.cylinder(at+Vector3(.02,1.08,0),.16,.045,w.flat(Color("5a4934")),p)

func shelf(w: Node3D, h: Node3D, at: Vector3, purpose: String) -> void:
	var wood := material(w,"wood",Color("85775e"))
	for x in [-.8,.8]: w.block(at+Vector3(x,1.45,0),Vector3(.12,2.25,.48),wood,false,h)
	w.block(at+Vector3(0,1.45,-.20),Vector3(1.7,2.25,.07),wood,false,h)
	for y in [.55,1.18,1.82,2.5]:
		w.block(at+Vector3(0,y,0),Vector3(1.85,.09,.55),wood,false,h)
		if y<2.5:
			for i in range(3):
				var pos := at+Vector3(-.55+i*.52,y+.05,0)
				if purpose=="office":
					for j in range(3): w.block(pos+Vector3(0,j*.07,0),Vector3(.33,.055,.29),w.flat(Color("7d5649") if i%2==0 else Color("777d69")),false,h)
				else: vessel(w,h,pos,.12+.035*(i%2),Color("799084") if i%2==0 else Color("b58e65"))

func candle(w: Node3D, h: Node3D, at: Vector3) -> void:
	var brass: Material = w.flat(Color("a18c58"))
	lathe(w,h,at,[Vector2(.13,0),Vector2(.13,.035),Vector2(.06,.07),Vector2(.035,.20),Vector2(.07,.25),Vector2(.10,.27)],brass)
	w.cylinder(at+Vector3(0,.36,0),.045,.19,textile(w,1,Color("eee0ad")),h)
	w.glow(at+Vector3(0,.49,0),.11,Color("ffd793"),h)

func credenza(w: Node3D, h: Node3D, at: Vector3) -> void:
	var wood := material(w,"wood",Color("aaa28b"))
	var inset := material(w,"wood",Color("7a7d6a"))
	w.block(at+Vector3(0,.83,0),Vector3(2.15,1.0,.65),inset,true,h)
	for y in [.38,1.34]: w.block(at+Vector3(0,y,0),Vector3(2.40,.13,.82),wood,false,h)
	for side in [-1.0,1.0]:
		var x: float = side*.54
		w.block(at+Vector3(x,.84,.35),Vector3(.95,.78,.08),wood,false,h)
		w.block(at+Vector3(x,.84,.40),Vector3(.70,.53,.06),inset,false,h)
		var diamond: MeshInstance3D = w.block(at+Vector3(x,.84,.45),Vector3(.21,.21,.04),wood,false,h)
		diamond.rotation.z = PI/4
		w.cylinder(at+Vector3(x-side*.26,.84,.50),.045,.06,w.flat(Color("ab905e")),h)
		lathe(w,h,at+Vector3(side*1.1,0,.34),[Vector2(.10,.32),Vector2(.10,.45),Vector2(.065,.6),Vector2(.065,1.14),Vector2(.12,1.22),Vector2(.12,1.31)],wood)
	candle(w,h,at+Vector3(-.8,1.41,0))
	vessel(w,h,at+Vector3(.7,1.41,0),.17,Color("829887"))

func lighting(w: Node3D, h: Node3D, depth: float, tall: float) -> void:
	var at := Vector3(0,maxf(3.1,tall-.85),depth*.15)
	var light := OmniLight3D.new()
	light.light_color = Color("ffd3a1")
	light.light_energy = 1.8
	light.omni_range = 12.0
	light.shadow_enabled = true
	light.distance_fade_enabled = true
	light.distance_fade_begin = 35
	light.distance_fade_length = 12
	h.add_child(light)
	light.position = at
	var iron: Material = w.flat(Color("3e443c"))
	var lantern := Node3D.new()
	h.add_child(lantern)
	lantern.position = at
	w.beam(Vector3(0,.26,0),Vector3(0,tall+2.7-at.y,0),.035,lantern)
	for y in [-.22,.22]: w.block(Vector3(0,y,0),Vector3(.4,.07,.4),iron,false,lantern)
	for x in [-.17,.17]:
		for z in [-.17,.17]: w.block(Vector3(x,0,z),Vector3(.035,.44,.035),iron,false,lantern)
	w.block(Vector3.ZERO,Vector3(.25,.32,.25),w.flat(Color("edbe77"),1.5),false,lantern)
	for child in lantern.get_children():
		if child is GeometryInstance3D: child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func hearth(w: Node3D, h: Node3D, width: float, depth: float, tall: float) -> void:
	var at := Vector3(width*.25,0,-depth*.2)
	var stone: Material = w.paint("stone")
	w.block(at+Vector3(0,.40,.5),Vector3(2.15,.2,1.8),stone,false,h)
	for x in [-.72,.72]: w.block(at+Vector3(x,1.04,.1),Vector3(.36,1.25,1.0),stone,true,h)
	w.block(at+Vector3(0,1.72,.1),Vector3(1.95,.34,1.16),stone,true,h)
	w.block(at+Vector3(0,(tall+5.4)/2,0),Vector3(1.15,tall+1.8,1.0),textile(w,3,Color("c8b9a5")),true,h)
	w.block(at+Vector3(0,tall+3.61,0),Vector3(.9,.035,.75),w.flat(Color("292b27")),false,h)
	for x in [-.64,.64]: w.block(at+Vector3(x,tall+3.65,0),Vector3(.22,.18,1.36),stone,false,h)
	for z in [-.57,.57]: w.block(at+Vector3(0,tall+3.65,z),Vector3(1.45,.18,.22),stone,false,h)
	w.block(at+Vector3(0,1.02,-.37),Vector3(1.12,1.15,.12),w.flat(Color("292b27")),false,h)
	for offset in [-.19,.19]:
		var log_mesh: MeshInstance3D = w.cylinder(at+Vector3(offset,.58,.2),.12,.85,material(w,"wood",Color("4f4336")),h)
		log_mesh.rotation.z = PI/2
		log_mesh.rotation.y = offset
	w.block(at+Vector3(0,.53,.24),Vector3(.65,.055,.48),w.flat(Color("c35c29"),.7),false,h)
	# Mantel shelf, crocks, and firewood beside the hearth.
	w.block(at+Vector3(0,1.96,.2),Vector3(2.2,.14,1.3),material(w,"wood",Color("675c4b")),false,h)
	for x in [-.68,.68]: vessel(w,h,at+Vector3(x,2.04,.48),.14,Color("9a8b65"))
	for i in range(4):
		var log_mesh: MeshInstance3D = w.cylinder(at+Vector3(1.3,.46+(i/2)*.2,(i%2)*.25),.12,.7,material(w,"wood",Color("8e7b5d")),h)
		log_mesh.rotation.x = PI/2

func furnish(w: Node3D, h: Node3D, width: float, depth: float) -> void:
	var first_detail := h.get_child_count()
	var purpose: String = h.get_meta("purpose","home")
	# Back-wall storage leaves the full middle and entry aisle free.
	var storage := Vector3(-width*.5+1.5,0,-depth*.5+.65)
	if w.room_clear(h,storage): shelf(w,h,storage,purpose)
	var corner := Vector3(width*.5-.85,0,-depth*.5+.85)
	if w.room_clear(h,corner):
		barrel(w,h,corner)
		if depth>9: barrel(w,h,corner+Vector3(0,0,1.0))
	# A faded woven runner with a simple border; geometry makes the weave readable.
	var rug: Material = textile(w,2,Color("a4a58b") if purpose!="office" else Color("c3a99a"))
	if purpose not in ["mill","workshop","pantry"]:
		w.block(Vector3(-width*.22,.325,0),Vector3(width*.29,.018,depth*.45),rug,false,h)
		for side in [-1.0,1.0]:
			w.block(Vector3(-width*.22+side*width*.13,.340,0),Vector3(.06,.012,depth*.43),w.flat(Color("b5a17a")),false,h)
	if purpose in ["mill","pantry","ferry"]:
		for i in range(5):
			var at := Vector3(-width/2+.75+(i%2)*.65,0,-depth*.26+(i/2)*.85)
			if w.room_clear(h,at): sack(w,h,at,Color("b7a480") if i%2==0 else Color("999b7c"))
	elif purpose not in ["ward","chapel","inn"]:
		var at := Vector3(-width*.30,0,0)
		if w.room_clear(h,at):
			table(w,h,at,Vector2(1.9,1.0))
			if purpose=="office": chair(w,h,at+Vector3(0,0,1))
			else: bench(w,h,at+Vector3(0,0,1),1.5)
			vessel(w,h,at+Vector3(.5,1.0,0),.16,Color("6e8d80"))
			if purpose=="office":
				w.block(at+Vector3(-.3,1.02,0),Vector3(.55,.035,.4),w.flat(Color("d3c5a0")),false,h)
			else: w.cylinder(at+Vector3(-.3,1.01,0),.22,.035,w.flat(Color("c0ae85")),h)
	# Wainscot, coat pegs, and hanging cloth break the blank rear wall.
	var back := -depth/2+.27
	var wood := material(w,"wood",Color("867862"))
	w.block(Vector3(0,.98,back),Vector3(width-.6,.12,.12),wood,false,h)
	for x in [-width*.30,0.0,width*.30]:
		w.block(Vector3(x,2.2,back+.06),Vector3(.065,.065,.27),wood,false,h)
	if purpose in ["inn","office","home"]:
		var at := Vector3(0,0,-depth*.5+.80)
		if w.room_clear(h,at): credenza(w,h,at)
	if purpose in ["inn","office","chapel"]:
		var at := Vector3(-width*.1,2.6,back+.08)
		w.block(at,Vector3(1.8,2.0,.04),textile(w,2,Color("b5ae98")),false,h)
		for y in [-1.03,1.03]: w.block(at+Vector3(0,y,0),Vector3(2.0,.09,.09),wood,false,h)
		for x in [-.94,.94]: w.block(at+Vector3(x,0,0),Vector3(.07,2.12,.08),wood,false,h)
	if purpose in ["home","ward","chapel"]:
		w.block(Vector3(-width*.23,2.0,back+.04),Vector3(1.2,1.5,.025),textile(w,2,Color("a6b39e")),false,h)
		w.block(Vector3(-width*.23,2.1,back+.07),Vector3(.07,.9,.04),wood,false,h)
		w.block(Vector3(-width*.23,2.3,back+.08),Vector3(.46,.07,.04),wood,false,h)
	# Site-specific equipment gives each room a clear purpose.
	if purpose=="mill":
		var at := Vector3(-width*.28,0,-depth*.22)
		w.cylinder(at+Vector3(0,.65,0),.95,.55,w.paint("stone"),h)
		w.cylinder(at+Vector3(0,.96,0),.87,.12,material(w,"stone",Color("b8b3a2")),h)
		w.cylinder(at+Vector3(0,1.04,0),.16,.12,w.flat(Color("49493f")),h)
		var hopper: MeshInstance3D = w.cylinder(at+Vector3(0,1.8,0),.2,.65,wood,h,false,.7)
		hopper.name = "GrainHopper"
		for side in [-1.0,1.0]: w.block(at+Vector3(side*.9,1.15,0),Vector3(.13,1.65,.13),wood,false,h)
	elif purpose=="workshop":
		var at := Vector3(-width*.28,0,-depth*.25)
		if w.room_clear(h,at):
			table(w,h,at,Vector2(2.2,.85))
			for i in range(3): w.block(at+Vector3(-.6+i*.5,1.05,0),Vector3(.32,.12,.17),w.flat(Color("5d635d")),false,h)
	elif purpose=="home":
		var at := Vector3(width*.5-1.05,0,depth*.12)
		if w.room_clear(h,at):
			w.block(at+Vector3(0,.55,0),Vector3(1.45,.45,2.7),wood,true,h)
			w.block(at+Vector3(0,.83,0),Vector3(1.4,.16,2.6),textile(w,2,Color("aab3a1")),false,h)
			w.block(at+Vector3(0,.98,-.85),Vector3(1,.14,.55),textile(w,1,Color("e1dac1")),false,h)
	elif purpose=="inn":
		for z in [-2.0,2.5]:
			for side in [-1.0,1.0]: bench(w,h,Vector3(-3,0,z+side*1.05),2.6)
			for x in [-3.8,-2.3]:
				vessel(w,h,Vector3(x,1.12,z),.12,Color("819482"))
				w.cylinder(Vector3(x+.3,1.12,z+.2),.22,.035,w.flat(Color("bcae88")),h)
		var counter := Vector3(3.0,0,-3.0)
		for z in [-4.2,-3.2,-2.2]: vessel(w,h,Vector3(counter.x,2.04,z),.14,Color("a18664"))
	for i in range(first_detail,h.get_child_count()): detail_range(h.get_child(i))

func detail_range(node: Node) -> void:
	if node is GeometryInstance3D:
		node.visibility_range_end = 75
	for child in node.get_children(): detail_range(child)
