extends RefCounted

const LEGACY_SITES := [
	{"id":"east_graves","pos":Vector2(178,-70),"kind":"grave","name":"The Unnamed Graves"},
	{"id":"dry_spring","pos":Vector2(-196,-80),"kind":"spring","name":"The Silent Spring"},
	{"id":"thorn_votive","pos":Vector2(215,-170),"kind":"tree","name":"The Thorn Votive"},
	{"id":"west_graves","pos":Vector2(-208,-315),"kind":"grave","name":"The Moss Burial"},
	{"id":"high_votive","pos":Vector2(224,-380),"kind":"tree","name":"The Last Ribbon"},
	{"id":"bridge_spring","pos":Vector2(210,-485),"kind":"spring","name":"The Dry Pilgrim Spring"},
	{"id":"west_votive","pos":Vector2(-208,-445),"kind":"tree","name":"The Forgotten Votive"},
	{"id":"east_spring","pos":Vector2(225,-685),"kind":"spring","name":"The Bitter Hollow"},
	{"id":"east_grave_march","pos":Vector2(215,-880),"kind":"grave","name":"The Unmarked Procession"},
	{"id":"west_grave_march","pos":Vector2(-212,-985),"kind":"grave","name":"The Last Burial"},
	{"id":"far_spring","pos":Vector2(222,-980),"kind":"spring","name":"The Spring Without Water"}
]
static var SITES: Array = relocated_sites()

static func relocated_sites() -> Array:
	var C = preload("res://scripts/content.gd")
	var result := []
	for original in LEGACY_SITES:
		var nearest: Vector2 = original.pos
		var distance := INF
		for road in C.ROADS:
			for index in range(road.size()-1):
				var point := Geometry2D.get_closest_point_to_segment(original.pos,road[index],road[index+1])
				if point.distance_to(original.pos)<distance:
					distance = point.distance_to(original.pos)
					nearest = point
		var moved: Dictionary = original.duplicate()
		moved.legacy_pos = original.pos
		moved.pos = original.pos.lerp(nearest,.5)
		result.append(moved)
	return result
const DEFAULTS := {"pitchbound_seen":false,"boughstalker_seen":false,"introduced":false,"intro_site":"","selected":[],"offerings":{}}

static func get_site(id: String) -> Dictionary:
	for site in SITES:
		if site.id==id: return site
	return {}

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["pitchbound_seen","boughstalker_seen","introduced"]:
		if not data.get(key) is bool: return false
	if not data.get("intro_site") is String or not data.get("selected") is Array or not data.get("offerings") is Dictionary: return false
	if data.selected.size()>SITES.size(): return false
	if data.introduced and not (data.pitchbound_seen and data.boughstalker_seen): return false
	if not data.introduced and (not data.selected.is_empty() or data.intro_site!="" or not data.offerings.is_empty()): return false
	if data.introduced and (get_site(data.intro_site).is_empty() or not data.selected.has(data.intro_site)): return false
	for id in data.selected:
		if not id is String or get_site(id).is_empty() or data.selected.count(id)!=1: return false
	for id in data.offerings:
		if not data.selected.has(id) or data.offerings[id]!=true: return false
	return true

static func reserved(p: Vector2) -> bool:
	# A clearing plus a broad entry/escape lane. Called after tree RNG draws so
	# trees elsewhere retain their authored positions across save upgrades.
	for site in SITES:
		if p.distance_to(site.pos)<14: return true
		if p.distance_to(site.legacy_pos)<14: return true
		var old_offset: Vector2 = p-site.legacy_pos
		if absf(old_offset.x)<4.5 and old_offset.y>0 and old_offset.y<32: return true
		var offset: Vector2 = p-site.pos
		if absf(offset.x)<4.5 and offset.y>0 and offset.y<32: return true
	return false

static func guard_clearing(p: Vector2) -> bool:
	return SITES.any(func(site): return p.distance_to(site.pos)<43)

static func recurrence_quota(entries: Array) -> int:
	var counts := {"pitchbound":0,"boughstalker":0}
	var C = preload("res://scripts/content.gd")
	for entry in entries:
		if counts.has(entry[1]) and C.distance_to_road(entry[2])>=65:
			counts[entry[1]] += 1
	return floori(mini(counts.pitchbound,counts.boughstalker)/5.0)

static func build_site(world: Node, site: Dictionary) -> Node3D:
	var C = preload("res://scripts/content.gd")
	var root := Node3D.new()
	root.name = "WeeperSite_"+site.id
	world.add_child(root)
	root.position = C.ground(site.pos)
	var stone: Material = world.paint("stone")
	var wood: Material = world.paint("wood")
	if site.kind=="grave":
		world.block(Vector3(0,.2,0),Vector3(2.6,.4,3.7),stone,true,root)
		var head: Node3D = world.block(Vector3(0,1.0,-1.6),Vector3(1.5,2,.55),stone,true,root)
		head.rotation.z = -.12
	elif site.kind=="spring":
		for i in range(8):
			world.block(Vector3(cos(i*TAU/8)*1.5,.35,sin(i*TAU/8)*1.5),Vector3(.9,.7,.65),stone,true,root)
	else:
		# Only a weathered, half-buried cross remains of the ancient votive.
		world.block(Vector3(0,.45,-1.8),Vector3(.32,1.6,.28),wood,true,root)
		world.block(Vector3(0,.9,-1.8),Vector3(1.35,.22,.28),wood,false,root)
	# Two substantial stones permit lateral cover; the southern lane stays open.
	for side in [-1.0,1.0]:
		var p: Vector2 = site.pos+Vector2(side*7,9)
		world.block(C.ground(p,1.45)-root.position,Vector3(2.8,2.9,2.3),stone,true,root)
	var offering: Node3D = world.block(Vector3(2,.65,0),Vector3(.65,.22,.65),wood,false,root)
	offering.name = "Offering"
	for i in range(5): world.cylinder(Vector3(1.8+i*.1,.85,0),.06,.12,stone,root)
	root.set_meta("site_id",site.id)
	return root

