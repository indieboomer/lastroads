extends Node

const Sites = preload("res://scripts/weeper_sites.gd")
var game: Node
var site_nodes: Dictionary = {}
var timer := 0.0
var announced := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for site in Sites.SITES:
		if eligible(site): site_nodes[site.id] = Sites.build_site(game.world,site)

func eligible(site: Dictionary) -> bool:
	if game.C.distance_to_road(site.pos)<18 or not game.world.outside_buildings(site.pos,20): return false
	for npc in game.C.NPCS.values():
		if site.pos.distance_to(npc.pos)<32.5: return false
	return not game.world.water_bounds.any(func(bounds): return bounds.grow(12).has_point(site.pos))

func participants() -> Array:
	var result := []
	if game.modal=="" and not game.reporting:
		result.append({"id":game.coop.transport.local_id,"p":game.player.position,"eye":game.camera.global_position,"forward":-game.camera.global_basis.z})
	if game.coop.active:
		for id in game.coop.poses:
			if id==game.coop.transport.local_id or game.coop.poses[id].busy or not game.coop.avatars.has(id): continue
			var avatar: Node = game.coop.avatars[id]
			result.append({"id":id,"p":avatar.body.position,"eye":avatar.viewpoint.global_position,"forward":-avatar.body.basis.z})
	return result

func observe_kind(kind: String) -> void:
	if kind=="pitchbound": game.state.weeper_world.pitchbound_seen = true
	elif kind=="boughstalker": game.state.weeper_world.boughstalker_seen = true

func occupied_positions() -> Array:
	# Menu users still occupy the world: never introduce a guardian on them.
	var positions := [game.player.position]
	if game.coop.active:
		for avatar in game.coop.avatars.values(): positions.append(avatar.body.position)
	return positions

func _physics_process(dt: float) -> void:
	if not game.started or game.test_mode: return
	timer -= dt
	if timer<=0:
		timer = .35
		tick()

func tick() -> void:
	if game.coop.active and not game.coop.is_host: return
	var players := participants()
	var occupied := occupied_positions()
	for foe in game.enemies:
		if foe.kind not in ["pitchbound","boughstalker"] or foe.dead: continue
		for player in players:
			var offset: Vector3 = foe.position+Vector3.UP-player.eye
			if offset.length()<27 and player.forward.dot(offset.normalized())>-.1 and game.line_clear(player.eye,foe.position+Vector3.UP): observe_kind(foe.kind)
	var progress: Dictionary = game.state.weeper_world
	if not (progress.pitchbound_seen and progress.boughstalker_seen): return
	if not progress.introduced:
		for site in Sites.SITES:
			if not site_nodes.has(site.id) or not solitary(site): continue
			var at: Vector3 = game.C.ground(site.pos+Vector2(0,3.5),1.4)
			if occupied.any(func(point): return point.distance_to(at)<30): continue
			for player in players:
				var offset: Vector3 = at-player.eye
				var p := Vector2(player.p.x,player.p.z)
				if game.C.distance_to_road(p)<25 or offset.length()>68 or player.forward.dot(offset.normalized())<.45: continue
				if not game.line_clear(player.eye,at): continue
				progress.introduced = true
				progress.intro_site = site.id
				progress.selected.append(site.id)
				game.spawn_enemy("weeper_intro_"+site.id,"hollow_weeper",site.pos+Vector2(0,3.5))
				# The script encounter is separate from the 1:5 recurring population.
				var quota := Sites.recurrence_quota(game.wilderness_encounters)
				for next in Sites.SITES:
					if progress.selected.size()>=quota+1: break
					if next.id!=site.id and site_nodes.has(next.id) and solitary(next): progress.selected.append(next.id)
				game.state.log_event("hollow_weeper_introduced:"+site.id)
				if game.coop.active: game.coop.broadcast("world",game.coop.world_record())
				return
	else:
		for id in progress.selected:
			if id==progress.intro_site: continue
			var site: Dictionary = Sites.get_site(id)
			# No teleporting reinforcements: later guardians only materialize while
			# everyone is well outside the site; existing/saved guardians persist.
			if occupied.any(func(point): return point.distance_to(game.C.ground(site.pos))<70): continue
			var uid: String = "weeper_site_"+id
			if not game.state.defeated.has(uid) and not game.enemies.any(func(foe): return foe.id==uid):
				game.spawn_enemy(uid,"hollow_weeper",site.pos+Vector2(0,3.5))

func solitary(site: Dictionary) -> bool:
	return not game.enemies.any(func(foe): return not foe.dead and (Vector2(foe.home.x,foe.home.z).distance_to(site.pos)<42 or Vector2(foe.position.x,foe.position.z).distance_to(site.pos)<42))

func _process(_dt: float) -> void:
	if not game.started: return
	var progress: Dictionary = game.state.weeper_world
	for id in site_nodes:
		var offering: Node3D = site_nodes[id].get_node("Offering")
		offering.visible = not progress.offerings.has(id)
	if progress.introduced and not announced:
		var site: Dictionary = Sites.get_site(progress.intro_site)
		if game.player.position.distance_to(game.C.ground(site.pos))<95:
			announced = true
			game.message("A WOMAN WEEPS / An Old Faith site lies ahead. Keep your distance; you can still turn back.",8)
	update_leaves()

func update_leaves() -> void:
	var power := 0.0
	var at := Vector3.ZERO
	for foe in game.enemies:
		if foe.kind=="hollow_weeper" and not foe.dead and foe.phase=="windup" and foe.position.distance_to(game.player.position)<65:
			power = maxf(power,clampf(foe.clock/.9,.1,1.0))
			at = foe.position
	RenderingServer.global_shader_parameter_set("road_scream_position",at)
	RenderingServer.global_shader_parameter_set("road_scream_strength",power)

func nearest_offering() -> Dictionary:
	for id in game.state.weeper_world.selected:
		if game.state.weeper_world.offerings.has(id): continue
		var site: Dictionary = Sites.get_site(id)
		var at: Vector3 = game.C.ground(site.pos+Vector2(2,0),.8)
		var offset: Vector3 = at-game.camera.global_position
		if offset.length()<4.2 and (-game.camera.global_basis.z).dot(offset.normalized())>.3 and game.line_clear(game.camera.global_position,at):
			return {"type":"weeper_offering","id":id,"name":"Take ancient beads / disturb the offering"}
	return {}

func take_offering(id: String) -> void:
	if game.coop.active and not game.coop.is_host:
		game.coop.send(game.coop.transport.host_id,"weeper_offering",{"site":id})
	else: collect(id,game.coop.transport.local_id)

func collect(id: String, player_id: int) -> void:
	var progress: Dictionary = game.state.weeper_world
	if not progress.selected.has(id) or progress.offerings.has(id): return
	var site: Dictionary = Sites.get_site(id)
	var at: Vector3 = game.player.position
	if game.coop.active and player_id!=game.coop.transport.local_id:
		if not game.coop.poses.has(player_id): return
		var p: Array = game.coop.poses[player_id].p
		at = Vector3(p[0],p[1],p[2])
	if at.distance_to(game.C.ground(site.pos+Vector2(2,0)))>4.5: return
	progress.offerings[id] = true
	for foe in game.enemies:
		if foe.kind=="hollow_weeper" and foe.site_id==id and not foe.dead: foe.engaged = true
	if not game.coop.active or player_id==game.coop.transport.local_id:
		game.state.inventory.ancient_beads += 1
		game.message("OFFERING STOLEN / The weeping stops. Ancient beads +1.",4)
	else: game.coop.send(player_id,"weeper_loot",{})
	if game.coop.active: game.coop.broadcast("world",game.coop.world_record())
