extends RefCounted

const Story = preload("res://scripts/woods.gd")
const C = preload("res://scripts/woods_content.gd")

func move_to(g: Node, id: String) -> void:
	var p: Vector2 = C.NPCS[id].pos if C.NPCS.has(id) else C.OBJECTS[id].pos
	g.teleport(p+Vector2(0,2.4))

func choose(g: Node, action: String) -> void:
	g._local_choose_dialog("woods:"+action)

func checkpoint(g: Node) -> void:
	assert(Story.valid(g.state.woods))
	var copy = g.State.new()
	assert(copy.read_dict(g.state.to_dict(),5),"Every stage must survive save validation")
	assert(copy.woods==g.state.woods)

func focus(g: Node, id: String, npc := false) -> bool:
	var p: Vector2 = C.NPCS[id].pos if npc else C.OBJECTS[id].pos
	for angle in range(12):
		g.set_modal("")
		g.teleport(p+Vector2(0,2.8).rotated(angle*TAU/12))
		g.camera.look_at(g.world.npcs[id].global_position if npc else g.object_interaction_point(id),Vector3.UP)
		await g.get_tree().physics_frame
		if g.nearest_interaction().get("id","")==id:
			g.interact()
			return true
	return false

func preview(g: Node) -> void:
	g.start_new()
	g.state.flags.won = true
	g.state.flags.accepted = true
	g.state.flags.sword_upgrade = true
	g.state.flags.coat_upgrade = true
	g.state.damage = 43
	g.state.max_health = 125
	g.state.health = 125
	g.state.xp = g.state.Progression.THRESHOLDS[4]
	g.state.inventory.gold = 60
	g.state.inventory.tonic = 6
	g.state.inventory.bread = 6
	g.state.inventory.wood = 6
	g.state.story.bell_done = true
	g.state.story.epilogue = true
	g.teleport(Vector2(0,-1064))
	g.camera.rotation.x = -.05
	g.woods.start()
	g.set_modal("")

func run(g: Node) -> void:
	await preview(g)
	g.set_physics_process(false)
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()
	await g.get_tree().physics_frame
	var legacy: Dictionary = g.state.to_dict()
	legacy.erase("woods")
	var old = g.State.new()
	assert(old.read_dict(legacy,5) and not old.woods.started)
	assert(old.flags==g.state.flags and old.story==g.state.story)
	var malformed: Dictionary = g.state.to_dict()
	malformed.woods.track = 99
	assert(not old.read_dict(malformed,5))
	malformed = g.state.to_dict()
	malformed.woods.confession = true
	assert(not old.read_dict(malformed,5),"Confession needs corroborated links")
	g.state.woods = Story.DEFAULTS.duplicate(true)
	g.state.story.bell_done = false
	assert(not g.woods.start())
	g.state.story.bell_done = true
	assert(g.woods.start())
	for id in C.OBJECTS:
		if id.begins_with("nw_"): assert(await focus(g,id),"Unreachable chapter object: "+id)
	for id in C.NPCS:
		assert(await focus(g,id,true),"Unreachable chapter NPC: "+id)
		assert(g.ui.current_choices.size()<=3)
	g.visuals.values.intimacy = true
	for id in ["pip","nell"]:
		g.teleport(g.C.NPCS[id].pos+Vector2(0,2))
		g.talk(id)
		assert(not g.relationship.adult(id) and not g.relationship.compatible(id))
		assert(not g.relationship.appearance_active(id))
		assert(not g.ui.current_choices.any(func(option): return option.action.begins_with("personal:")))
		for action in ["personal:entry:"+id,"personal:closer:"+id,"personal:offer","personal:confirm","personal:begin","personal:new_offer","personal:new_confirm"]:
			g.relationship.choose(action)
			assert(g.dialogue_id==id and g.modal=="dialog")
		g.relationship.open_new(id)
		assert(g.dialogue_id==id)
		g.relationship.active_id = id
		g.relationship.relaxed = true
		g.set_modal("intimacy")
		assert(not g.relationship.safe() and not g.relationship.appearance_active(id))
		assert(g.relationship.portrait_texture(id)==g.world.npc_portrait(id))
		g.relationship.active_id = "mara"
		g.relationship.relaxed = false
		g.set_modal("dialog")
	g.state.woods = Story.DEFAULTS.duplicate(true)
	g.woods.start()
	move_to(g,"bran")
	g.talk("bran")
	choose(g,"confront")
	assert(not g.state.woods.confession)
	move_to(g,"nw_caseboard")
	choose(g,"wrong_symbol")
	choose(g,"link_cause")
	assert(not g.state.woods.cause)
	for justice in ["hearing","exile","conceal"]:
		for pact in ["accord","sever","inherit"]:
			g.state.woods = Story.DEFAULTS.duplicate(true)
			g.state.defeated.erase("nw_borrowed_heart")
			g.state.enemies.erase("nw_borrowed_heart")
			g.state.looted.erase("nw_borrowed_heart")
			for enemy in g.enemies:
				if enemy.id.begins_with("nw_"): enemy.queue_free()
			g.enemies = g.enemies.filter(func(enemy): return not enemy.id.begins_with("nw_"))
			g.woods.start()
			var keys: Array = ["body","bolt","watch","letter","mould","ledger","prison"]
			if pact!="accord": keys.reverse()
			for key in keys:
				g.woods.interact("nw_"+key)
				var xp: int = g.state.xp
				g.woods.interact("nw_"+key)
				assert(g.state.xp==xp,"No repeated evidence XP")
			move_to(g,"sella")
			g.talk("sella")
			move_to(g,"nw_caseboard")
			for link in ["cause","access","motive"]: choose(g,"link_"+link)
			assert(g.woods.deductions_done())
			checkpoint(g)
			move_to(g,"bran")
			g.talk("bran")
			choose(g,"confront")
			assert(g.state.woods.confession and not g.state.woods.nell_met)
			move_to(g,"hester")
			g.talk("hester")
			choose(g,"confirm_"+justice)
			assert(g.state.woods.justice.is_empty(),"Preview must not commit judgement")
			choose(g,"seal_"+justice)
			assert(g.state.woods.justice==justice)
			var sealed_xp: int = g.state.xp
			choose(g,"seal_"+justice)
			assert(g.state.xp==sealed_xp)
			move_to(g,"vey")
			g.talk("vey")
			choose(g,"vey_key")
			assert(g.state.woods.prison_key)
			move_to(g,"nw_gate")
			g.woods.interact("nw_gate")
			assert(not g.state.woods.rescued,"Release must wait for pressure vent")
			g.woods.interact("nw_vent")
			g.woods.interact("nw_gate")
			assert(g.state.woods.rescued)
			checkpoint(g)
			move_to(g,"nw_heart")
			choose(g,"commit_accord")
			assert(g.state.woods.pact.is_empty(),"Accord needs independent adult support")
			if pact=="accord":
				g.woods.interact("nw_rites")
				move_to(g,"maelin")
				g.talk("maelin")
				move_to(g,"sella")
				choose(g,"consent_sella")
				move_to(g,"ada")
				g.talk("ada")
				choose(g,"consent_ada")
				assert(g.state.woods.sella_consent and g.state.woods.ada_consent)
			move_to(g,"nw_heart")
			choose(g,"pact_"+pact)
			assert(g.state.woods.pact.is_empty(),"Preview must not commit pact")
			choose(g,"commit_"+pact)
			assert(g.state.woods.pact==pact)
			if pact=="sever":
				assert(not g.state.woods.heart_done)
				var boss: Node = g.enemies.filter(func(enemy): return enemy.id=="nw_borrowed_heart")[0]
				boss.tick(.01)
				assert(boss.shielded)
				var hp: float = boss.health
				boss.hit(100,true,false)
				assert(boss.health==hp)
				for key in ["ward_north","ward_east","ward_west"]: g.woods.interact("nw_"+key)
				boss.tick(.01)
				assert(not boss.shielded)
				boss.hit(1000,true,false)
				var tears: int = g.state.inventory.resin_tear
				boss.search_body()
				boss.search_body()
				assert(g.state.inventory.resin_tear==tears+1)
				g.woods.tick(.01)
			assert(g.state.woods.heart_done)
			checkpoint(g)
			move_to(g,"hester")
			choose(g,"complete")
			assert(g.state.woods.completed)
			var final_xp: int = g.state.xp
			choose(g,"complete")
			assert(g.state.xp==final_xp)
			assert(g.woods.ending().contains("Oren was killed by Bran"))
			checkpoint(g)
	g.state.woods = Story.DEFAULTS.duplicate(true)
	g.woods.start()
	move_to(g,"nw_gate")
	choose(g,"rescue_force")
	g.woods.ensure_encounters()
	assert(g.enemies.filter(func(enemy): return enemy.id.begins_with("nw_cell_guard_")).size()==2)
	checkpoint(g)
	for enemy in g.enemies:
		if enemy.id.begins_with("nw_cell_guard_"): enemy.hit(1000,true,false)
	g.woods.interact("nw_vent")
	g.woods.interact("nw_gate")
	assert(g.state.woods.rescued)
	g.ui.map_view.region = 2
	for site in C.SITES.values(): assert(Rect2(10,10,640,580).has_point(g.ui.map_view.project(site.pos)))
	g.ui.quest_track.item_selected.emit(9)
	assert(g.state.woods.focus and g.state.woods.track==2)
	g.ui.quest_track.item_selected.emit(1)
	assert(not g.state.woods.focus and g.state.story.track==1)
	assert(g.journey.STOPS.size()==11)
	for index in range(6):
		g.journey.travel_menu(index)
		assert(g.ui.current_choices.size()<=3)
	# Cartridge caches must never make a legal full pouch produce an invalid save.
	g.state.inventory.pistol_cartridge = 120
	g.state.inventory.musket_cartridge = 120
	g._local_interact_object("cache_nw_sluice")
	assert(g.state.inventory.pistol_cartridge==122 and g.state.inventory.musket_cartridge==122)
	checkpoint(g)
	# Shared progress excludes local tracking preferences, and object-origin choices
	# remain attached to the object even when a distant NPC narrates the page.
	var session: Node = g.coop
	var shared: Dictionary = session.world_record(false)
	assert(shared.has("woods") and not shared.woods.has("track") and not shared.woods.has("focus"))
	g.state.woods.track = 3
	g.state.woods.focus = true
	g.state.woods.boat = true
	shared.woods.boat = true
	session.session_ready = true
	session._world(shared)
	assert(g.state.woods.track==3 and g.state.woods.focus and g.state.woods.boat)
	session.session_ready = false
	g.state.woods = Story.DEFAULTS.duplicate(true)
	g.state.woods.started = true
	session.poses[77] = {"p":[143.0,0.0,-1560.0]}
	var changes := {"flags":{},"story":{},"taken":{},"woods":{"rescue_started":true}}
	session._world_change(77,{"kind":"object","id":"nw_gate","changes":changes})
	assert(g.state.woods.rescue_started,"Host accepts shared cellar progress at the cellar's actual position")
	assert(g.enemies.filter(func(enemy): return enemy.id.begins_with("nw_cell_guard_")).size()==2)
	session.poses.erase(77)
	print("WOODS PASS: world access, 9 endings, revisable deductions, child exclusion, both rescues, boss wards, persistence, maps and travel")
	g.get_tree().quit()


func route(g: Node) -> void:
	await preview(g)
	g.set_modal("")
	for enemy in g.enemies:
		enemy.collision_layer = 0
	g.route_active = true
	Engine.time_scale = 8.0
	for road in C.ROADS:
		g.teleport(road[0])
		assert(await g.route_walk(road),"New northern road must be traversable: "+str(road))
	print("WOODS ROUTE PASS: all ten northern roads physically walked / %dm / %ds walking simulation" % [g.route_distance,g.state.elapsed])
	g.get_tree().quit()

func captures(g: Node) -> void:
	await preview(g)
	g.set_physics_process(false)
	g.state.day_clock = 13.0
	g.weather.force("clear")
	for scene in [
		[Vector2(0,-1068),Vector2(-11,-1093),"village"],
		[Vector2(125,-1195),Vector2(141,-1220),"sluice"],
		[Vector2(-135,-1305),Vector2(-155,-1335),"sanctuary"],
		[Vector2(150,-1373),Vector2(166,-1407),"kiln"],
		[Vector2(-135,-1494),Vector2(-153,-1524),"assize"],
		[Vector2(130,-1535),Vector2(143,-1560),"cellars"],
		[Vector2(17,-1615),Vector2(34,-1646),"court"],
		[Vector2(-82,-1745),Vector2(-95,-1774),"oak"]]:
		g.set_modal("")
		g.teleport(scene[0])
		g.camera.look_at(g.C.ground(scene[1],1.7),Vector3.UP)
		g.world.tick(0)
		g.update_location()
		await g.capture("33-rowan-"+scene[2])
	move_to(g,"nell")
	g.talk("nell")
	await g.capture("33-rowan-nell")
	move_to(g,"hester")
	g.talk("hester")
	await g.capture("33-rowan-hester")
	g.ui.show_map()
	g.ui.map_view.region = 2
	await g.capture("33-rowan-map")
	print("WOODS CAPTURE PASS: 8 landmarks, both new settlement portraits and third map sheet")
	g.get_tree().quit()
