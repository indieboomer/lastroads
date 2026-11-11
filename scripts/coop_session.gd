extends Node

signal changed
const Data = preload("res://scripts/character_data.gd")
const Transport = preload("res://scripts/coop_transport.gd")
const Avatar = preload("res://scripts/coop_avatar.gd")
const COLORS := ["#b74239","#337ad1","#d6a934","#419d68","#a66bc7","#de833c","#49bac1","#d983ae"]
const MAX_PLAYERS := 4
const WORLD_FLAGS := ["accepted","supplies","scout","bargain","oil","relic","herbalist","herbs_done","courier","courier_done","prepared","beacon_lit","won","grave","letter","keeper","root","flame","bell"]
var game: Node
var transport: Node
var active := false
var is_host := false
var session_ready := false
var roster: Dictionary = {}
var avatars: Dictionary = {}
var poses: Dictionary = {}
var last_seen: Dictionary = {}
var hit_times: Dictionary = {}
var local_color := "#b74239"
var status := "Choose your character and recognition color."
var pending_mode := ""
var pending_address := "127.0.0.1"
var pending_port := 27841
var pending_lobby := 0
var timer := 0.0
var world_timer := 0.0
var hello_timer := 0.0
var sequence := 0
var last_sequence := -1
var target_peer := 0
var applying := false
var hello_profile: Dictionary
var last_world: Dictionary = {}
var initial_world := false
var joined_at := 0.0
var test_notes: Array = []
var damage_source_peer := 0
var pending_hits: Array = []
var sanctuary_visuals: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	transport = Transport.new()
	transport.name = "Transport"
	add_child(transport)
	transport.packet_received.connect(_packet)
	transport.departed.connect(_departed)
	transport.status_changed.connect(func(text): status = text; changed.emit())
	transport.invite_received.connect(func(id):
		pending_lobby = id
		status = "Steam invitation received. Choose your character and color to join."
		if game.ui: game.ui.coop_menu.open("join_steam")
	)

func prepare(mode: String, profile: Dictionary, color: String, address := "127.0.0.1", port := 27841) -> Error:
	if not Data.valid(profile) or color not in COLORS or port<1024 or port>65535: return ERR_INVALID_PARAMETER
	if active: return ERR_ALREADY_IN_USE
	hello_profile = profile.duplicate(true)
	local_color = color
	pending_mode = mode
	pending_address = address
	pending_port = port
	var result: Error = OK
	match mode:
		"host_steam": result = transport.host_steam()
		"join_steam": result = transport.join_steam(pending_lobby)
		"host_lan": result = transport.host_lan(port)
		"join_lan": result = transport.join_lan(address,port)
		_: return ERR_INVALID_PARAMETER
	if result!=OK:
		status = transport.last_error if mode.ends_with("steam") else "Could not open that connection. Check address and port."
		changed.emit()
		return result
	is_host = mode.begins_with("host")
	active = true
	session_ready = is_host
	initial_world = false
	last_sequence = -1
	joined_at = Time.get_ticks_msec()/1000.0
	game.start_new(profile)
	# Co-op files have their own paths; solo saves are never replaced.
	if is_host and FileAccess.file_exists(game.save_path()): game.load_game()
	hello_profile = game.state.profile.duplicate(true)
	if is_host:
		_register_local()
		status = "Hosting / 1 of 4 players."
	else:
		status = "Connecting to host..."
		game.set_modal("coop_connect")
	game.get_tree().paused = false
	changed.emit()
	return OK

func _register_local() -> void:
	var nickname: String = transport.nickname(transport.local_id)
	if nickname.is_empty(): nickname = game.state.profile.name
	roster[transport.local_id] = {"profile":game.state.profile.duplicate(true),"nickname":nickname,"color":local_color}
	poses[transport.local_id] = local_pose()
	last_seen[transport.local_id] = Time.get_ticks_msec()/1000.0

func local_pose() -> Dictionary:
	var motion := "idle"
	var speed := Vector2(game.player.velocity.x,game.player.velocity.z).length()
	if speed>.2: motion = "run" if speed>4.0 else "walk"
	if game.attack_clock>.1:
		var casting_shot: bool = game.state.profile.profession_id in ["mage","cleric"] and game.combat.gesture_clock>0 and game.combat.gesture in ["dart","ember","rime","judgement"]
		motion = "shoot" if game.ranger.flash>0 or casting_shot else "fight"
	if game.state.ranger.reload_left>0: motion = "action"
	if game.modal!="" or game.reporting: motion = "idle"
	return {"p":[game.player.position.x,game.player.position.y,game.player.position.z],"yaw":game.player.rotation.y,"pitch":game.camera.rotation.x,"motion":motion,"health":game.state.health,"enchanted":game.state.weapon_resin_seconds>0,"light":game.torch_equipped or game.lantern.visible,"blocking":game.blocking,"block_age":game.block_age,"busy":game.modal!="" or game.reporting,"sanctuary":game.combat.record().sanctuary}

static func valid_pose(value: Variant) -> bool:
	if not value is Dictionary or not value.get("p") is Array or value.p.size()!=3: return false
	for number in value.p:
		if not (number is float or number is int) or not is_finite(float(number)) or absf(number)>2000: return false
	for key in ["yaw","pitch","health","block_age"]:
		if not (value.get(key) is float or value.get(key) is int) or not is_finite(float(value[key])): return false
	if absf(value.pitch)>PI/2+.1 or value.health<0 or value.health>150 or value.block_age<0: return false
	for key in ["light","blocking","busy"]:
		if not value.get(key) is bool: return false
	if value.has("enchanted") and not value.enchanted is bool: return false
	if value.has("sanctuary"):
		if not value.sanctuary is Dictionary: return false
		if not value.sanctuary.is_empty():
			if not valid_point(value.sanctuary.get("position")) or not value.sanctuary.get("left") is float or not is_finite(value.sanctuary.left) or value.sanctuary.left<=0 or value.sanctuary.left>8: return false
	return value.get("motion") in Avatar.STATES and absf(value.p[0])<=240 and value.p[2]>=-1020 and value.p[2]<=90

func send(id: int, kind: String, data: Dictionary = {}, reliable := true) -> void:
	transport.send_to(id,{"protocol":Transport.PROTOCOL,"kind":kind,"data":data},reliable)

func broadcast(kind: String, data: Dictionary, reliable := true) -> void:
	for id in roster:
		if id!=transport.local_id: send(id,kind,data,reliable)

func _process(dt: float) -> void:
	if not active: return
	game.get_tree().paused = false
	var now := Time.get_ticks_msec()/1000.0
	if not is_host and not session_ready:
		hello_timer -= dt
		if hello_timer<=0 and transport.connected():
			hello_timer = 1.0
			send(transport.host_id,"hello",{"profile":hello_profile,"color":local_color,"build":game.C.BUILD,"layout":game.C.LAYOUT})
		if now-joined_at>20: disconnect_session("Could not join. The host may be unavailable or the party is full.")
		return
	if not session_ready: return
	if game.modal!="" or game.reporting: game.combat.tick(dt)
	if ally_protected_at(game.player.position) and not game.combat.own_protected_at(game.player.position):
		game.state.health = minf(game.state.max_health,game.state.health+dt*2.0)
	update_sanctuary_visuals()
	for hit in pending_hits:
		if is_instance_valid(hit.enemy):
			var foe: Node = hit.enemy
			send(transport.host_id,"hit",{"id":foe.id,"amount":hit.amount,"heavy":hit.heavy,"physical":hit.physical,"burning":foe.burning,"rimed":foe.rimed,"brittle":foe.brittle,"stun":foe.stun,"pose":local_pose()})
	pending_hits.clear()
	timer += dt
	world_timer += dt
	if timer>=.05:
		timer = 0
		poses[transport.local_id] = local_pose()
		if is_host:
			sequence += 1
			broadcast("frame",{"sequence":sequence,"poses":poses,"clock":game.state.day_clock},false)
			var chunk := {}
			for id in enemy_frame():
				var enemy: Dictionary = enemy_frame_cache[id]
				chunk[id] = enemy
				if chunk.size()>=6:
					broadcast("enemies",{"sequence":sequence,"records":chunk},false)
					chunk = {}
			if not chunk.is_empty(): broadcast("enemies",{"sequence":sequence,"records":chunk},false)
		else: send(transport.host_id,"pose",local_pose(),false)
	if is_host and world_timer>=.5:
		world_timer = 0
		broadcast("world",world_record(false))
	for id in roster.keys():
		if id==transport.local_id: continue
		if last_seen.has(id) and now-last_seen[id]>15: _departed(id)

func _packet(sender: int, packet: Dictionary) -> void:
	if not active or not packet.get("kind") is String or not packet.get("data") is Dictionary: return
	var data: Dictionary = packet.data
	if is_host:
		if packet.kind=="hello": _hello(sender,data); return
		if not roster.has(sender): return
		last_seen[sender] = Time.get_ticks_msec()/1000.0
		match packet.kind:
			"pose": _pose(sender,data)
			"hit": _hit(sender,data)
			"weeper_offering":
				if data.get("site") is String: game.weeper_director.collect(data.site,sender)
			"weeper_interrupt": _weeper_interrupt(sender,data)
			"world_change": _world_change(sender,data)
			"bye": _departed(sender)
	else:
		if sender!=transport.host_id: return
		last_seen[sender] = Time.get_ticks_msec()/1000.0
		match packet.kind:
			"welcome": _welcome(data)
			"roster": _set_roster(data)
			"frame": _frame(data)
			"enemies":
				if data.get("sequence") is int and data.sequence>=last_sequence and data.get("records") is Dictionary: _apply_enemies(data.records)
			"world": _world(data)
			"damage":
				if data.get("amount") is float and data.amount>=0 and data.amount<=80 and valid_point(data.get("from")):
					applying = true
					game.receive_hit(data.amount,Vector3(data.from[0],data.from[1],data.from[2]),str(data.get("family","wolf")))
					applying = false
			"weeper_loot":
				game.state.inventory.ancient_beads += 1
				game.message("OFFERING STOLEN / The weeping stops. Ancient beads +1.",4)
			"weeper_feedback":
				if data.get("text") is String: game.message(data.text.left(240),3)
			"reject": disconnect_session(str(data.get("reason","Host rejected the connection.")))
			"end": disconnect_session("The host has left. Your co-op character was saved.")

func _hello(sender: int, data: Dictionary) -> void:
	if roster.has(sender): send(sender,"welcome",{"roster":roster,"world":world_record(),"spawn":local_pose().p}); return
	if roster.size()>=MAX_PLAYERS:
		send(sender,"reject",{"reason":"This party already has four players."}); return
	if data.get("build")!=game.C.BUILD or data.get("layout")!=game.C.LAYOUT or not Data.valid(data.get("profile")):
		send(sender,"reject",{"reason":"Both players need the same game build and a valid character."}); return
	if data.get("color") not in COLORS:
		send(sender,"reject",{"reason":"Choose a recognition color before joining."}); return
	for record in roster.values():
		if record.color==data.color:
			send(sender,"reject",{"reason":"That color is already taken. Please choose another color."}); return
	var nickname: String = transport.nickname(sender)
	if nickname.is_empty(): nickname = data.profile.name
	roster[sender] = {"profile":data.profile.duplicate(true),"nickname":nickname,"color":data.color}
	last_seen[sender] = Time.get_ticks_msec()/1000.0
	poses[sender] = local_pose().duplicate(true)
	poses[sender].p = join_position(data.profile)
	poses[sender].health = Data.profession(data.profile.profession_id).health
	poses[sender].busy = false
	_make_avatar(sender)
	send(sender,"welcome",{"roster":roster,"world":world_record(),"spawn":poses[sender].p})
	broadcast("roster",roster)
	status = "Hosting / %d of 4 players." % roster.size()
	changed.emit()

static func valid_point(value: Variant) -> bool:
	if not value is Array or value.size()!=3: return false
	for v in value:
		if not (v is float or v is int) or not is_finite(float(v)) or absf(v)>2000: return false
	return true

func _pose(sender: int, data: Dictionary) -> void:
	if not valid_pose(data): return
	if not data.get("sanctuary",{}).is_empty() and roster[sender].profile.profession_id!="cleric": return
	if poses.has(sender):
		var old: Array = poses[sender].p
		# Portals/respawn are allowed only at the authored destinations.
		var gap := Vector3(data.p[0]-old[0],data.p[1]-old[1],data.p[2]-old[2]).length()
		if gap>12 and not near_portal(data.p): return
	poses[sender] = data.duplicate(true)
	if avatars.has(sender): avatars[sender].accept_pose(data)

func near_portal(p: Array) -> bool:
	var at := Vector2(p[0],p[2])
	for destination in [Vector2(0,42),Vector2(-65,-514),Vector2(130,-368),Vector2(132,-216)]:
		if at.distance_to(destination)<8: return true
	if game.state.story.ferry_fixed:
		for destination in [Vector2(-61,-518),Vector2(135,-594),Vector2(7,-334)]:
			if at.distance_to(destination)<8: return true
	return false

func join_position(profile: Dictionary) -> Array:
	var size := Data.stature(profile.species_id)
	var capsule := CapsuleShape3D.new()
	capsule.radius = .34; capsule.height = size.body
	for offset in [Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,2),Vector3(0,0,-2),Vector3(3,0,3)]:
		var at: Vector3 = game.player.position+offset
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,at+Vector3.UP*(size.body*.5+.08))
		query.collision_mask = 1
		if game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return [at.x,at.y,at.z]
	return local_pose().p

func _welcome(data: Dictionary) -> void:
	if session_ready: return
	if not data.get("roster") is Dictionary or not valid_point(data.get("spawn")) or not data.get("world") is Dictionary: return
	_set_roster(data.roster)
	if not roster.has(transport.local_id): return
	# Load only this visitor's private character record, then apply the host world.
	if FileAccess.file_exists(game.save_path()): game.load_game()
	game.player.position = Vector3(data.spawn[0],data.spawn[1],data.spawn[2])
	_world(data.world)
	session_ready = true
	game.set_modal("")
	status = "Connected / %d of 4 players." % roster.size()
	changed.emit()

func _set_roster(value: Dictionary) -> void:
	if value.size()>MAX_PLAYERS: return
	for id in value:
		var record: Variant = value[id]
		if not id is int or not record is Dictionary or not Data.valid(record.get("profile")) or record.get("color") not in COLORS or not record.get("nickname") is String: return
	for id in avatars.keys():
		if not value.has(id): avatars[id].queue_free(); avatars.erase(id); poses.erase(id)
	roster = value.duplicate(true)
	for id in roster:
		if id!=transport.local_id: _make_avatar(id)
	changed.emit()

func _make_avatar(id: int) -> void:
	if avatars.has(id): return
	var avatar := Avatar.new()
	game.add_child(avatar)
	avatar.setup(roster[id])
	avatars[id] = avatar
	if poses.has(id): avatar.accept_pose(poses[id],true)

func _departed(id: int) -> void:
	if not active: return
	if not is_host and id==transport.host_id: disconnect_session("The host disconnected. Your co-op character was saved."); return
	if not roster.has(id): return
	roster.erase(id); poses.erase(id); last_seen.erase(id)
	if avatars.has(id): avatars[id].queue_free(); avatars.erase(id)
	if sanctuary_visuals.has(id): sanctuary_visuals[id].queue_free(); sanctuary_visuals.erase(id)
	if is_host: broadcast("roster",roster)
	status = "%d of 4 players connected." % roster.size()
	changed.emit()

func disconnect_session(reason := "Left co-op.") -> void:
	if active:
		if session_ready: game.save_game()
		if is_host: broadcast("end",{})
		else: send(transport.host_id,"bye",{})
	transport.leave()
	active = false; session_ready = false
	for avatar in avatars.values(): avatar.queue_free()
	avatars.clear(); roster.clear(); poses.clear(); last_seen.clear(); hit_times.clear()
	for zone in sanctuary_visuals.values(): zone.queue_free()
	sanctuary_visuals.clear()
	target_peer = 0
	status = reason
	game.to_title()
	if game.ui and game.ui.coop_menu: game.ui.coop_menu.open()
	changed.emit()

func world_record(include_enemies := true) -> Dictionary:
	var flags := {}
	for key in WORLD_FLAGS: flags[key] = game.state.flags[key]
	var story: Dictionary = game.state.story.duplicate(true)
	story.erase("track")
	var record := {"flags":flags,"story":story,"taken":game.state.taken.duplicate(),"defeated":game.state.defeated.duplicate(),"fires":game.state.fires.duplicate(true),"clock":game.state.day_clock,"weather":game.state.weather.duplicate()}
	record.weeper_world = game.state.weeper_world.duplicate(true)
	if include_enemies: record.enemies = enemy_frame()
	return record

var enemy_frame_cache: Dictionary = {}
func enemy_frame() -> Dictionary:
	var result := {}
	for enemy in game.enemies:
		var record: Dictionary = {"kind":enemy.kind,"position":[enemy.position.x,enemy.position.y,enemy.position.z],"health":float(enemy.health),"phase":enemy.phase,"clock":enemy.clock,"dead":enemy.dead,"shielded":enemy.shielded}
		if enemy.kind=="hollow_weeper":
			record.weeper_aim = [enemy.scream_direction.x,0.0,enemy.scream_direction.z]
			record.engaged = enemy.engaged
			record.weeper_scream_serial = enemy.scream_serial
		result[enemy.id] = record
		record.visible = enemy.visible
	enemy_frame_cache = result
	return result

func _frame(data: Dictionary) -> void:
	if not session_ready or not data.get("sequence") is int or data.sequence<=last_sequence or not data.get("poses") is Dictionary: return
	last_sequence = data.sequence
	for id in data.poses:
		if not roster.has(id) or not valid_pose(data.poses[id]): continue
		if id!=transport.local_id:
			poses[id] = data.poses[id].duplicate(true)
			if avatars.has(id): avatars[id].accept_pose(poses[id])
	if data.get("clock") is float and is_finite(data.clock): game.state.day_clock = fposmod(data.clock,24)

func _apply_enemies(records: Dictionary) -> void:
	for id in records:
		var record: Variant = records[id]
		if not record is Dictionary or record.get("kind") not in game.C.ENEMY_TYPES or not valid_point(record.get("position")): continue
		if not record.get("health") is float or not is_finite(record.health): continue
		var enemy: Node
		for candidate in game.enemies:
			if candidate.id==id: enemy = candidate; break
		if enemy==null:
			if not id is String or id.length()>96 or game.enemies.size()>=512: continue
			enemy = game.spawn_enemy(id,record.kind,Vector2(record.position[0],record.position[2]))
		enemy.position = Vector3(record.position[0],record.position[1],record.position[2])
		enemy.health = clampf(record.health,0,enemy.spec.hp)
		enemy.phase = str(record.get("phase","idle"))
		enemy.clock = float(record.get("clock",0))
		enemy.shielded = bool(record.get("shielded",false))
		var was_dead: bool = enemy.dead
		enemy.dead = enemy.health<=0
		if enemy.dead:
			if not was_dead and initial_world: game.state.xp += int(enemy.spec.xp)
			game.state.defeated[id] = true
			enemy.collision_layer = 0
			if not game.state.looted.has(id): enemy.show_corpse()
			else: enemy.hide()
		else:
			enemy.visible = bool(record.get("visible",true))
			enemy.collision_layer = 2 if enemy.visible else 0
			var frame := 3 if enemy.phase=="stunned" else 1 if enemy.phase=="windup" else 2 if enemy.phase=="recover" and enemy.clock<.3 else 0
			if enemy.kind=="hollow_weeper":
				if valid_point(record.get("weeper_aim")): enemy.scream_direction = Vector3(record.weeper_aim[0],0,record.weeper_aim[2]).normalized()
				enemy.engaged = bool(record.get("engaged",false))
				var serial: Variant = record.get("weeper_scream_serial",0)
				if serial is int and serial>=0 and serial<=1000000: enemy.scream_serial = maxi(enemy.scream_serial,serial)
				enemy.render_pose()
			elif enemy.illustrated_wilderness: enemy.set_art_pose(frame)
			else:
				enemy.visual.texture = game.world.atlas("combat",enemy.spec.cell*4+frame,4,4)
				(enemy.visual.material_override as ShaderMaterial).set_shader_parameter("image",enemy.visual.texture)
				enemy.visual.pixel_size = enemy.spec.height/enemy.visual.texture.get_height()
				enemy.visual.position.y = enemy.spec.height*.5

func _world(data: Dictionary) -> void:
	if not preload("res://scripts/weeper_sites.gd").valid(data.get("weeper_world",preload("res://scripts/weeper_sites.gd").DEFAULTS)): return
	if not data.get("flags") is Dictionary or not data.get("story") is Dictionary or not data.get("taken") is Dictionary: return
	for key in WORLD_FLAGS:
		if not data.flags.get(key) is bool: return
	for key in data.story:
		if not game.state.story.has(key) or typeof(data.story[key])!=typeof(game.state.story[key]): return
	if not data.get("fires") is Array or data.fires.size()>128: return
	for fire in data.fires:
		if not fire is Dictionary or not valid_point(fire.get("position")) or not fire.get("fuel") is float or not is_finite(fire.fuel) or fire.fuel<0 or fire.fuel>240: return
	var scenery_changed: bool = game.state.taken!=data.taken or game.state.fires.size()!=data.fires.size()
	for key in WORLD_FLAGS:
		if game.state.flags[key]!=data.flags[key]: scenery_changed = true
	for key in data.story:
		if game.state.story[key]!=data.story[key]: scenery_changed = true
	for key in WORLD_FLAGS: game.state.flags[key] = data.flags[key]
	for key in data.story: game.state.story[key] = data.story[key]
	game.state.weeper_world = data.get("weeper_world",preload("res://scripts/weeper_sites.gd").DEFAULTS).duplicate(true)
	game.state.taken = data.taken.duplicate()
	game.state.fires = data.fires.duplicate(true)
	if data.get("weather") is Dictionary:
		var valid_weather := true
		for key in game.state.weather:
			if not (data.weather.get(key) is float or data.weather.get(key) is int) or not is_finite(float(data.weather[key])): valid_weather = false
		if valid_weather: game.state.weather = data.weather.duplicate()
	if data.get("enemies") is Dictionary: _apply_enemies(data.enemies)
	if data.get("clock") is float and is_finite(data.clock): game.state.day_clock = fposmod(data.clock,24)
	if scenery_changed: game.world.apply_state()
	initial_world = true
	last_world = data.duplicate(true)

func transact(kind: String, id: String, method: String, args: Array) -> void:
	var before: Dictionary = world_record() if active and not is_host and session_ready else {}
	game.callv(method,args)
	if before.is_empty(): return
	var after := world_record()
	var changes := {"flags":{},"story":{},"taken":{}}
	for section in changes:
		for key in after[section]:
			if before[section].get(key)!=after[section][key]: changes[section][key] = after[section][key]
	if before.fires.size()!=after.fires.size(): changes.fires = after.fires
	if before.clock!=after.clock: changes.clock = after.clock
	var spawns := []
	for enemy_id in after.enemies:
		if not before.enemies.has(enemy_id): spawns.append({"id":enemy_id,"kind":after.enemies[enemy_id].kind,"position":after.enemies[enemy_id].position})
	send(transport.host_id,"world_change",{"kind":kind,"id":id,"changes":changes,"spawns":spawns})

func _world_change(sender: int, data: Dictionary) -> void:
	if not data.get("changes") is Dictionary or not data.get("id") is String or not poses.has(sender): return
	var p: Array = poses[sender].p
	var at := Vector2(p[0],p[2])
	var kind: String = str(data.get("kind",""))
	if kind=="npc":
		if not game.world.npcs.has(data.id): return
		var npc_at: Vector3 = game.world.npcs[data.id].position
		if at.distance_to(Vector2(npc_at.x,npc_at.z))>10: return
	elif kind=="object":
		if not game.C.OBJECTS.has(data.id) or at.distance_to(game.C.OBJECTS[data.id].pos)>8: return
	elif kind=="forage":
		# Forage is personal and never changes the shared quest world.
		return
	elif kind!="camp": return
	var changes: Dictionary = data.changes
	if not changes.get("flags") is Dictionary or not changes.get("story") is Dictionary or not changes.get("taken") is Dictionary: return
	if kind=="camp" and (not changes.flags.is_empty() or not changes.story.is_empty() or not changes.taken.is_empty()): return
	for key in changes.flags:
		if key not in WORLD_FLAGS or not changes.flags[key] is bool: return
	for key in changes.story:
		if not game.state.story.has(key) or key=="track" or typeof(changes.story[key])!=typeof(game.state.story[key]): return
	for key in changes.taken:
		if not key is String or changes.taken[key]!=true: return
	for key in changes.flags:
		if changes.flags[key]: game.state.flags[key] = true
	for key in changes.story:
		var current: Variant = game.state.story[key]
		if current is bool: game.state.story[key] = current or changes.story[key]
		elif current is String and current.is_empty(): game.state.story[key] = changes.story[key]
	game.state.taken.merge(changes.taken)
	if data.get("spawns") is Array:
		for spawn in data.spawns:
			if not spawn is Dictionary: continue
			if data.id=="rook" and spawn.get("id") in ["mill_enforcer_1","mill_enforcer_2"]:
				game.spawn_enemy("mill_enforcer_1","bandit",Vector2(-106,-166))
				game.spawn_enemy("mill_enforcer_2","bandit",Vector2(-113,-174))
			if data.id in ["anselm","ash_bell"] and spawn.get("id")=="ash_mournkeeper" and game.state.story.bell_method=="force":
				game.spawn_enemy("ash_mournkeeper","mournkeeper",Vector2(0,-929))
	if kind=="camp" and changes.get("fires") is Array and changes.fires.size()==game.state.fires.size()+1 and changes.fires.size()<=128:
		var fire: Variant = changes.fires.back()
		if fire is Dictionary and valid_point(fire.get("position")) and Vector2(fire.position[0],fire.position[2]).distance_to(at)<4:
			game.state.fires.append({"position":fire.position,"fuel":240.0})
	if kind=="camp" and changes.has("clock") and game.fire_distance(Vector3(p[0],p[1],p[2]))<4.5 and not game.threats_near(Vector3(p[0],p[1],p[2]),16): game.state.day_clock = 7.0
	game.world.apply_state()
	broadcast("world",world_record())

func request_hit(enemy: Node, amount: float, heavy: bool, physical: bool) -> void:
	if pending_hits.size()<16: pending_hits.append({"enemy":enemy,"amount":amount,"heavy":heavy,"physical":physical})

func _hit(sender: int, data: Dictionary) -> void:
	if not data.get("id") is String or not data.get("amount") is float or not is_finite(data.amount) or data.amount<=0: return
	if not data.get("heavy") is bool or not data.get("physical") is bool or not valid_pose(data.get("pose")): return
	_pose(sender,data.pose)
	if not poses.has(sender): return
	var profession: String = roster[sender].profile.profession_id
	var cap := 180.0 if profession=="ranger" else 105.0 if profession=="warrior" else 65.0
	if data.amount>cap: return
	var now := Time.get_ticks_msec()/1000.0
	var key: String = str(sender)+":"+str(data.id)
	if now-float(hit_times.get(key,-100))<.12: return
	var p: Array = poses[sender].p
	var at := Vector3(p[0],p[1],p[2])
	var eye: Vector3 = at+Vector3.UP*Data.stature(roster[sender].profile.species_id).eye
	var reach := 101.0 if profession=="ranger" and data.amount>30 else 55.0 if profession=="mage" else 36.0 if profession=="cleric" else 4.5
	for enemy in game.enemies:
		if enemy.id!=data.id or enemy.dead: continue
		var aim: Vector3 = enemy.position+Vector3.UP*minf(1.5,enemy.spec.height*.5)
		if enemy.position.distance_to(at)>reach or not game.line_clear(eye,aim): return
		hit_times[key] = now
		damage_source_peer = sender
		enemy.hit(data.amount,data.heavy,data.physical)
		damage_source_peer = 0
		for effect in ["burning","rimed","brittle","stun"]:
			if enemy.kind=="hollow_weeper" and effect=="stun": continue
			if data.get(effect) is float and is_finite(data[effect]): enemy.set(effect,clampf(data[effect],0,6))
		break

func tick_enemy(enemy: Node, dt: float) -> void:
	if not active: enemy.tick(dt); return
	if not is_host: return
	if enemy.kind=="hollow_weeper": enemy.tick(dt); return
	var nearest: int = transport.local_id
	var best: float = enemy.position.distance_squared_to(game.player.position)
	for id in poses:
		if id==transport.local_id or not avatars.has(id) or poses[id].health<=0: continue
		var distance: float = enemy.position.distance_squared_to(avatars[id].body.position)
		if distance<best: best = distance; nearest = id
	if nearest==transport.local_id: enemy.tick(dt); return
	var saved_player: Node = game.player
	var saved_camera: Node = game.camera
	var saved_torch: bool = game.torch_equipped
	target_peer = nearest
	game.player = avatars[nearest].body
	game.camera = avatars[nearest].viewpoint
	game.torch_equipped = poses[nearest].light
	enemy.tick(dt)
	game.player = saved_player
	game.camera = saved_camera
	game.torch_equipped = saved_torch
	target_peer = 0

func _weeper_interrupt(sender: int, data: Dictionary) -> void:
	if roster[sender].profile.profession_id not in ["mage","cleric"] or not data.get("id") is String or not valid_pose(data.get("pose")): return
	_pose(sender,data.pose)
	var point: Array = poses[sender].p
	var at := Vector3(point[0],point[1],point[2])
	var key: String = str(sender)+":weeper_interrupt"
	var now := Time.get_ticks_msec()/1000.0
	if now-float(hit_times.get(key,-100))<1.5: return
	for foe in game.enemies:
		if foe.id==data.id and foe.kind=="hollow_weeper" and not foe.dead and foe.position.distance_to(at)<9.5 and game.line_clear(at+Vector3.UP*1.5,foe.position+Vector3.UP*1.5):
			hit_times[key] = now
			foe.try_interrupt(1.0)

func damage_remote(amount: float, from: Vector3, family: String) -> bool:
	if not active or not is_host or target_peer==0: return false
	send(target_peer,"damage",{"amount":amount,"from":[from.x,from.y,from.z],"family":family})
	return true

func host_while_busy(dt: float) -> void:
	if not active or not is_host or not session_ready: return
	game.state.elapsed += dt
	game.state.day_clock = fposmod(game.state.day_clock+dt/60.0,24)
	game.march.tick(dt)
	for enemy in game.enemies: tick_enemy(enemy,dt)
	game.world.tick(dt)
	game.weather.tick(dt)
	game.update_defence(dt)
	for fire in game.state.fires: fire.fuel = maxf(0,fire.fuel-dt)
	if game.state.fires.any(func(fire): return fire.fuel<=0):
		game.state.fires = game.state.fires.filter(func(fire): return fire.fuel>0)
		game.world.apply_state()

func party_near(at: Vector3, radius: float) -> bool:
	if game.player.position.distance_to(at)<radius: return true
	if not active: return false
	for pose in poses.values():
		if Vector3(pose.p[0],pose.p[1],pose.p[2]).distance_to(at)<radius: return true
	return false

func ally_protected_at(at: Vector3) -> bool:
	if not active: return false
	for id in poses:
		if id==transport.local_id or not roster.has(id) or roster[id].profile.profession_id!="cleric": continue
		var zone: Dictionary = poses[id].get("sanctuary",{})
		if zone.is_empty() or zone.left<=0: continue
		var position := Vector3(zone.position[0],zone.position[1],zone.position[2])
		if Vector2(position.x,position.z).distance_to(Vector2(at.x,at.z))<=3 and absf(position.y-at.y)<2 and game.line_clear(position+Vector3.UP,at+Vector3.UP): return true
	return false

func update_sanctuary_visuals() -> void:
	for id in poses:
		if id==transport.local_id: continue
		var zone: Dictionary = poses[id].get("sanctuary",{})
		if zone.is_empty() or zone.left<=0:
			if sanctuary_visuals.has(id): sanctuary_visuals[id].queue_free(); sanctuary_visuals.erase(id)
			continue
		var at := Vector3(zone.position[0],zone.position[1]+.06,zone.position[2])
		if not sanctuary_visuals.has(id): sanctuary_visuals[id] = game.combat.make_ring(at,3.0,game.combat.COLOURS.sanctuary)
		sanctuary_visuals[id].global_position = at

func save_name() -> String:
	var identity: String = str(transport.local_id) if transport.mode=="steam" else "lan"
	var character: String = hello_profile.get("name","Traveller")+"-"+hello_profile.get("origin_id","valdren")+"-"+hello_profile.get("profession_id","warrior")
	return "saves/coop/"+("host-" if is_host else "visitor-")+identity+"-"+character.sha256_text().substr(0,12)+".json"
