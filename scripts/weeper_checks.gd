extends RefCounted

func run(g: Node) -> void:
	DirAccess.make_dir_recursive_absolute(g.data_root().path_join("reports/weeper"))
	var Sites = preload("res://scripts/weeper_sites.gd")
	for candidate in Sites.SITES:
		assert(is_equal_approx(g.C.distance_to_road(candidate.pos),g.C.distance_to_road(candidate.legacy_pos)*.5))
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	g.set_physics_process(false)
	g.get_tree().paused = true
	var original_solitary := []
	for candidate in Sites.SITES:
		if g.weeper_director.site_nodes.has(candidate.id) and g.weeper_director.solitary(candidate): original_solitary.append(candidate.id)
	assert(original_solitary.size()>=3,"The first encounter and 1:5 recurring quota need unoccupied sites")
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()
	await g.get_tree().process_frame
	assert(not g.weeper_director.site_nodes.is_empty())
	var site: Dictionary = Sites.get_site(g.weeper_director.site_nodes.keys()[0])
	var foe: Node = g.spawn_enemy("weeper_intro_"+site.id,"hollow_weeper",site.pos+Vector2(0,3.5))
	assert(foe.health>=g.C.ENEMY_TYPES.wolf.hp*2.5 and foe.health<=g.C.ENEMY_TYPES.wolf.hp*3)
	foe.hit(40)
	assert(is_equal_approx(foe.health,140) and foe.stun==0)
	foe.hit(20,false,false)
	assert(is_equal_approx(foe.health,120))
	g.state.weapon_resin_seconds = 120
	foe.hit(20)
	assert(is_equal_approx(foe.health,102))
	foe.phase = "recover"
	foe.hit(20,false,false)
	assert(is_equal_approx(foe.health,77))
	foe.phase = "windup"; foe.clock = .4
	foe.force_reaction(Vector3.ZERO,1,.8,.5)
	assert(foe.phase=="windup" and foe.stun==0 and foe.clock==.4)
	assert(foe.try_interrupt(1) and foe.phase=="recover")
	foe.phase = "windup"; foe.clock = .2
	assert(not foe.try_interrupt(1))
	foe.scream_direction = Vector3.FORWARD
	assert(foe.in_scream(foe.position+Vector3(0,0,-8)))
	assert(not foe.in_scream(foe.position+Vector3(7,0,-7)))
	assert(not foe.in_scream(foe.position+Vector3(0,0,-12)))
	# Exercise the actual damage path, shield reduction, occlusion and aim lock.
	g.player.position = foe.position+Vector3(0,0,8)
	g.player.rotation.y = 0
	g.camera.rotation = Vector3.ZERO
	g.blocking = false
	g.state.health = 110
	foe.scream_direction = Vector3.BACK
	foe.release_scream()
	assert(is_equal_approx(g.state.health,52) and g.player_stagger==.32)
	g.state.health = 110
	g.blocking = true; g.block_age = .1
	foe.release_scream()
	assert(g.state.health<110 and g.state.health>85,"A timed shield reduces but never negates the scream")
	g.blocking = false; g.state.health = 110
	var cover: Node3D = g.world.block(foe.position+Vector3(0,1.5,4),Vector3(4,4,1),g.world.paint("stone"),true)
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	foe.release_scream()
	assert(g.state.health==110,"Substantial solid terrain blocks the cone")
	cover.queue_free()
	await g.get_tree().physics_frame
	foe.engaged = true; foe.phase = "windup"; foe.clock = .89
	foe.tick(.02)
	var locked: Vector3 = foe.scream_direction
	g.player.position = foe.position+Vector3(8,0,0)
	foe.tick(.15)
	assert(foe.scream_direction==locked,"Last quarter-second cannot track a sidestep")
	foe.tick(.12)
	assert(g.state.health==110 and foe.phase=="recover")
	foe.tick(1.8)
	assert(foe.phase=="recover")
	foe.tick(.4)
	assert(foe.phase=="chase")
	g.state.day_clock = 7.1
	foe.engaged = false
	assert(not foe.dead and foe.visible,"Corporeal guardians persist through dawn")
	for index in range(6):
		var frame: Texture2D = g.world.wilderness_art.frame(g.world.library,"hollow_weeper",index)
		assert(frame.get_height()>100 and frame.get_width()>100)
	assert(is_equal_approx(foe.spec.height,2.55*1.2))
	for event in ["lament","windup","scream","recover","sweep","death"]:
		var previous := ""
		for index in range(8):
			var cue: Dictionary = foe.cues.choose(event)
			assert(cue.path.begins_with("res://sounds/weeper/") and cue.stream.get_length()>0)
			assert(cue.length>0 and cue.length<=foe.cues.CAPS[event])
			if event!="sweep": assert(cue.path!=previous,"Supplied cue variants cannot repeat consecutively")
			previous = cue.path
	foe.last_phase = "windup"; foe.phase = "recover"
	foe.last_scream_serial = foe.scream_serial
	foe.voice.stop(); foe._process(.01)
	assert(not foe.voice.playing,"Interrupted wind-up must not play a scream")
	foe.release_scream(); foe._process(.01)
	assert(foe.voice.stream!=null and foe.last_scream_serial==foe.scream_serial)
	var saved: Dictionary = g.state.to_dict()
	saved.enemies[foe.id] = foe.record()
	var restored = g.State.new()
	assert(restored.read_dict(saved))
	assert(restored.read_dict(JSON.parse_string(JSON.stringify(saved))),"JSON numeric fields survive a real save round-trip")
	assert(is_equal_approx(restored.weapon_resin_seconds,saved.weapon_resin_seconds))
	saved.erase("weeper_world"); saved.erase("weapon_resin_seconds")
	for key in ["burial_cloth","ancient_beads","resin_tear","graveward_resin"]: saved.inventory.erase(key)
	assert(restored.read_dict(saved),"Legacy saves remain readable")
	assert(not Sites.valid({"introduced":true}))
	# One-time introduction: real sightline, prerequisites, distant placement.
	foe.queue_free(); g.enemies.clear()
	await g.get_tree().process_frame
	g.state.weeper_world = Sites.DEFAULTS.duplicate(true)
	var introduced := false
	for candidate in Sites.SITES:
		if not g.weeper_director.site_nodes.has(candidate.id): continue
		g.teleport(candidate.pos+Vector2(0,38),0)
		g.camera.look_at(g.C.ground(candidate.pos+Vector2(0,3.5),1.4))
		g.weeper_director.tick()
		assert(not g.state.weeper_world.introduced)
		g.state.weeper_world.pitchbound_seen = true
		g.weeper_director.tick()
		assert(not g.state.weeper_world.introduced)
		g.state.weeper_world.boughstalker_seen = true
		g.weeper_director.tick()
		if g.state.weeper_world.introduced:
			introduced = true
			break
		g.state.weeper_world = Sites.DEFAULTS.duplicate(true)
	assert(introduced,"Authored approaches must permit the introduction")
	assert(g.enemies.size()==1 and g.enemies[0].position.distance_to(g.player.position)>=30)
	foe = g.enemies[0]
	site = Sites.get_site(g.state.weeper_world.intro_site)
	var intro_uid: String = foe.id
	g.weeper_director.tick()
	assert(g.enemies.filter(func(enemy): return enemy.id.begins_with("weeper_intro_")).size()==1)
	assert(g.state.weeper_world.selected.size()==Sites.recurrence_quota(g.wilderness_encounters)+1)
	g.player.position = g.C.ground(site.pos+Vector2(2,0))
	var before_beads: int = g.state.inventory.ancient_beads
	g.weeper_director.collect(site.id,g.coop.transport.local_id)
	g.weeper_director.collect(site.id,g.coop.transport.local_id)
	assert(foe.engaged and g.state.inventory.ancient_beads==before_beads+1)
	foe.health = 1; foe.hit(20,false,false)
	foe.search_body(); foe.search_body()
	assert(g.state.inventory.resin_tear==1 and g.state.inventory.burial_cloth==1)
	g.state.inventory.essence = 2
	g.player.position = g.world.fire_nodes[0].node.global_position+Vector3(0,0,1)
	g.use_item("resin_tear")
	assert(g.state.inventory.resin_tear==0 and g.state.inventory.essence==0 and g.state.inventory.graveward_resin==1)
	g.use_item("graveward_resin")
	assert(g.state.inventory.graveward_resin==0 and g.state.weapon_resin_seconds==120)
	foe.dead = false; foe.collision_layer = 2; foe.health = 150
	# Capture full-size details alongside the ordinary gameplay view.
	g.state.weeper_world.pitchbound_seen = true
	g.state.weeper_world.boughstalker_seen = true
	g.state.weeper_world.introduced = true
	g.state.weeper_world.intro_site = site.id
	g.state.weeper_world.selected = [site.id]
	assert(Sites.valid(g.coop.world_record().weeper_world))
	foe.health = 150; foe.engaged = false; foe.phase = "idle"; foe.hit_flash = 0
	g.teleport(site.pos+Vector2(0,15),0)
	g.camera.look_at(foe.position+Vector3.UP*1.4)
	g.state.day_clock = 12
	g.weather.force("clear")
	g.world.tick(0)
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	g.ui.damage_flash = 0
	g.tutorial_timer = 0
	foe.render_pose()
	await g.capture("30-weeper-bowed")
	foe.phase = "windup"; foe.clock = .95; foe.render_pose()
	await g.capture("30-weeper-opening")
	foe.phase = "recover"; foe.render_pose()
	await g.capture("30-weeper-recovery")
	g.teleport(site.pos+Vector2(0,8),0)
	g.camera.look_at(foe.position+Vector3.UP*1.4)
	foe.phase = "windup"; foe.render_pose()
	await g.capture("30-weeper-close")
	var report := {"passed":true,"hp":150,"scream_damage":58,"mundane_resistance":.75,"sites":g.weeper_director.site_nodes.keys(),"original_solitary_sites":original_solitary,"recurring_quota":Sites.recurrence_quota(g.wilderness_encounters),"intro_uid":intro_uid,"cover_blocks":true,"shield_reduces":true,"aim_locks":true}
	FileAccess.open(g.data_root().path_join("reports/weeper/validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	# World-level co-op introduction can be triggered by a visitor exploring
	# while the host stays on the road with a menu open.
	var session: Node = g.coop
	assert(session.prepare("host_lan",session.Data.defaults(),session.COLORS[0],"127.0.0.1",31452)==OK)
	g.start_new(session.Data.defaults())
	g.set_physics_process(false)
	g.set_modal("pause")
	var guest: Dictionary = session.Data.defaults()
	guest.name = "Weeper visitor"
	guest.profession_id = "cleric"
	session._hello(2011,{"profile":guest,"color":session.COLORS[1],"build":g.C.BUILD,"layout":g.C.LAYOUT})
	var guest_pose: Dictionary = session.local_pose().duplicate(true)
	var approach: Vector3 = g.C.ground(site.pos+Vector2(0,38),.5)
	guest_pose.p = [approach.x,approach.y,approach.z]
	guest_pose.busy = false; guest_pose.yaw = 0.0; guest_pose.pitch = 0.0
	session.poses[2011] = guest_pose
	session.avatars[2011].body.position = approach
	session.avatars[2011].body.rotation.y = 0
	g.state.weeper_world.pitchbound_seen = true
	g.state.weeper_world.boughstalker_seen = true
	for candidate in Sites.SITES:
		if not g.weeper_director.site_nodes.has(candidate.id) or not g.weeper_director.solitary(candidate): continue
		approach = g.C.ground(candidate.pos+Vector2(0,38),.5)
		guest_pose.p = [approach.x,approach.y,approach.z]
		session.poses[2011] = guest_pose
		session.avatars[2011].body.position = approach
		g.weeper_director.tick()
		if g.state.weeper_world.introduced: break
	assert(g.state.weeper_world.introduced,"Visitor can introduce the guardian while host is away")
	var shared: Dictionary = session.world_record()
	assert(Sites.valid(shared.weeper_world))
	var guardian: Node
	for enemy in g.enemies:
		if enemy.kind=="hollow_weeper": guardian = enemy; break
	assert(guardian!=null and shared.enemies[guardian.id].has("weeper_aim"))
	# A remote sacred hit uses the visitor's class, not the hosting warrior's.
	var hit_at: Vector3 = guardian.position+Vector3(0,0,3)
	guest_pose.p = [hit_at.x,hit_at.y,hit_at.z]
	session.poses[2011] = guest_pose
	guardian.phase = "idle"
	session._hit(2011,{"id":guardian.id,"amount":20.0,"heavy":false,"physical":true,"pose":guest_pose,"stun":6.0})
	assert(is_equal_approx(guardian.health,127) and guardian.stun==0,"Remote sacred damage and no client stun-lock")
	guardian.phase = "windup"; guardian.clock = .2
	session._weeper_interrupt(2011,{"id":guardian.id,"pose":guest_pose})
	assert(guardian.phase=="recover")
	session.disconnect_session("Weeper co-op checks complete.")
	print("WEEPER PASS: resistance, enchantment, recovery, interrupts, cone, six poses, audio, legacy saves, world progression")
	g.get_tree().quit()
