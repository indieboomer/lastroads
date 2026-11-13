extends Control

const C = preload("res://scripts/content.gd")
var game: Node
var font: Font
var region := 0

func _ready() -> void:
	font = load("res://assets/fonts/Cinzel.ttf")

func sheet(p: Vector2) -> int:
	return 2 if p.y< -1005 else 1 if p.y< -425 else 0

func project(p: Vector2) -> Vector2:
	if region==2:
		return Vector2(330+p.x*1.05,48+(p.y+1830)*.66)
	if region==1:
		return Vector2(330+p.x*1.05,55+(p.y+995)*0.92)
	return Vector2(330+p.x*1.16,62+(p.y+370)*1.16)

func _draw() -> void:
	if game.in_crypt():
		draw_crypt()
		return
	draw_rect(Rect2(0,0,660,600),Color("142b2c"))
	# A quiet cartographer's border; the decorative zigzag was removed after playtest.
	draw_rect(Rect2(10,10,640,580),Color("627064"),false,1)
	for road in C.ROADS:
		var points := PackedVector2Array()
		for p in road:
			if sheet(p)!=region: continue
			points.append(project(p))
		if points.size()<2: continue
		draw_polyline(points,Color("4f6355"),7,true)
		draw_polyline(points,Color("a18b5f"),2,true)
	var target: Dictionary = game.target()
	if region==0 and game.state.flags.scout and not game.state.flags.prepared:
		for id in ["oil","relic"]:
			if game.state.flags[id]: continue
			var marker := project(C.OBJECTS[id].pos if id=="oil" else C.NPCS.sister.pos)
			draw_arc(marker,11,0,TAU,24,Color("b2ceae"),2,true)
	for id in C.SITES:
		var s: Dictionary = C.SITES[id]
		if sheet(s.pos)!=region: continue
		var p := project(s.pos)
		var known: bool = game.state.discovered.has(id)
		draw_circle(p,6,Color("dfbf7e") if known else Color("6b8072"))
		draw_arc(p,9,0,TAU,24,Color("7f906e"),1,true)
		var text: String = s.name
		var offset := Vector2(12,-7)
		if s.pos.x>70:
			offset.x = -font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x-12
		draw_string(font,p+offset,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("deceab") if known else Color("8fa293"))
	for marker in game.side_quests.markers():
		if sheet(marker.pos)!=region: continue
		var clue := project(marker.pos)
		draw_arc(clue,5,0,TAU,16,Color("a6d3aa") if marker.found else Color("ddc17d"),1.5,true)
		if marker.found: draw_circle(clue,2.5,Color("a6d3aa"))
	if target.has("pos") and sheet(target.pos)==region:
		var p := project(target.pos)
		draw_arc(p,15,0,TAU,32,Color("ffe0a0"),2,true)
		draw_string(font,p+Vector2(-4,-20),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ffe0a0"))
	var player_at := Vector2(game.player.position.x,game.player.position.z)
	var pp := project(player_at)
	var angle: float = game.player.rotation.y
	var forward := Vector2(-sin(angle),-cos(angle))
	if sheet(player_at)==region:
		draw_circle(pp,6,Color("edf4d8"))
		draw_line(pp,pp+forward*17,Color("edf4d8"),3,true)
	draw_string(font,Vector2(35,560),["THE HOLLOW VALLEY","THE ASHEN MARCH","THE ROWAN MARCH"][region],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("ccb57d"))
	draw_string(font,Vector2(548,548),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ccb57d"))
	draw_line(Vector2(556,565),Vector2(556,580),Color("ccb57d"),1,true)

func crypt_project(p: Vector2) -> Vector2:
	return Vector2(330+(p.x-130)*9,60+(p.y+421)*8)

func draw_crypt() -> void:
	draw_rect(Rect2(0,0,660,600),Color("142b2c"))
	draw_rect(Rect2(10,10,640,580),Color("627064"),false,1)
	var stone := Color("465d53")
	var ink := Color("b7ac7b")
	for room in [Rect2(267,60,126,480),Rect2(123,196,144,160),Rect2(393,196,144,160)]:
		draw_rect(room,stone)
		draw_rect(room,ink,false,2)
	for id in ["rune_root","rune_flame","rune_bell","relic","crypt_exit"]:
		var d: Dictionary = C.OBJECTS[id]
		var p := crypt_project(d.pos)
		draw_circle(p,7,Color("ddc17d"))
		draw_string(font,p+Vector2(14,-8),d.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e0d2aa"))
	var player_pos := crypt_project(Vector2(game.player.position.x,game.player.position.z))
	draw_circle(player_pos,6,Color("f3f5de"))
	var yaw: float = game.player.rotation.y
	draw_line(player_pos,player_pos+Vector2(-sin(yaw),-cos(yaw))*17,Color("f3f5de"),3,true)
	draw_string(font,Vector2(35,570),"THE UNDERCHAPEL",HORIZONTAL_ALIGNMENT_LEFT,-1,20,ink)

func _process(_dt: float) -> void:
	if visible:
		queue_redraw()
