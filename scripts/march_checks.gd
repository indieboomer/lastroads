extends RefCounted

const D = preload("res://scripts/march_content.gd")
const Story = preload("res://scripts/march.gd")

func run(g: Node) -> void:
	var profile := preload("res://scripts/character_data.gd").defaults()
	profile.name = "Marel"
	g.start_new(profile)
	g.state.flags.won = true
	g.world.apply_state()
	for e in g.enemies:
		e.dead = true
		g.state.defeated[e.id] = true
		e.collision_layer = 0
		e.hide()
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	g.talk("merchant")
	assert(g.ui.current_choices[0].action=="march:start")
	g.choose_dialog("march:start")
	var stock: int = g.state.inventory.tonic
	g.choose_dialog("march:start")
	assert(g.state.inventory.tonic==stock,"Chapter provisions happen once")
	g.choose_dialog("march:brief")
	assert(g.state.story.briefed)
	for id in D.NPCS:
		var image: Image = g.world.library.npc(id).get_image()
		assert(image.detect_alpha()!=Image.ALPHA_NONE and image.get_height()>500)
		g.talk(id)
		await g.capture("07-portrait-"+id)
	g.choose_dialog("march:medicine_accept")
	g.choose_dialog("march:ashes_accept")
	g.march.interact("ash_locket")
	g.choose_dialog("march:ashes_truth")
	assert(not g.state.story.ashes_done,"The full account requires evidence")
	for id in ["ash_orders","ash_ledger","ash_roll","ash_letter","ash_bandages","ash_salve","ash_alcohol","ash_rope"]:
		g.march.interact(id)
		assert(g.modal=="dialog")
		if id=="ash_roll": await g.capture("07-burial-roll")
	g.choose_dialog("march:ashes_truth")
	assert(g.state.story.ashes_done and g.state.story.ashes_truth)
	g.choose_dialog("march:dose_pavel")
	var xp_before: int = g.state.xp
	g.choose_dialog("march:dose_raisa")
	assert(g.state.story.patient=="pavel" and g.state.xp==xp_before)
	g.talk("nera")
	g.choose_dialog("march:medicine")
	await g.capture("07-last-dose-aftermath")
	g.choose_dialog("march:letters_truth")
	g.choose_dialog("march:witness_testify")
	assert(g.state.story.witness and g.state.story.soldier_done)
	g.choose_dialog("march:repair")
	assert(g.state.story.ferry_fixed)
	var wood_before: int = g.state.inventory.wood
	g.choose_dialog("march:repair")
	assert(g.state.inventory.wood==wood_before,"Repairs never charge twice")
	# Travel requires actual visits and departure from a secured stop.
	g.teleport(Vector2(135,-594))
	g.update_location()
	g.teleport(Vector2(-61,-518))
	g.update_location()
	g.choose_dialog("march:travel_ferry")
	assert(g.player.position.z< -590 and not g.in_crypt(),"The new eastern region is not the old crypt")
	g.march.interact("ash_candle_bridge")
	g.march.interact("ash_candle_orchard")
	var faith_seed: Dictionary = g.state.story.duplicate(true)
	for rite in ["prayer","silence","ribbon"]:
		g.state.story = faith_seed.duplicate(true)
		g.choose_dialog("march:faith_"+rite)
		assert(g.state.story.faith_done and g.state.story.faith_rite==rite)
	# Each political settlement is final and survives coordinated persistence.
	var seed: Dictionary = g.state.story.duplicate(true)
	for verdict in ["trial","resign","burn"]:
		g.state.story = seed.duplicate(true)
		g.choose_dialog("march:verdict_"+verdict)
		assert(g.state.story.verdict.is_empty(),"A second confirmation precedes the settlement")
		g.choose_dialog("march:commit_"+verdict)
		assert(g.state.story.verdict==verdict)
		xp_before = g.state.xp
		g.choose_dialog("march:commit_resign")
		assert(g.state.xp==xp_before and g.state.story.verdict==verdict)
		if verdict=="trial":
			g.teleport(D.SITES.ash_refuge.pos)
			g.march.tick(0)
			assert(g.state.story.defense_started and not g.state.story.defense_done)
			assert(g.save_game())
			assert(g.load_game())
			for enemy in g.enemies:
				if enemy.id.begins_with("ash_defense_"): enemy.hit(999)
			g.march.tick(0)
			assert(g.state.story.defense_done,"Refuge defense resumes after reload")
		for enemy in g.enemies:
			enemy.dead = true
			enemy.collision_layer = 0
			enemy.hide()
		g.teleport(Vector2(0,-935))
		g.choose_dialog("march:bell_memory")
		assert(not g.state.story.bell_done)
		for name_text in ["mateo","elias","alina"]: g.march.interact("ash_names_"+name_text)
		g.choose_dialog("march:bell_memory")
		assert(g.state.story.bell_done)
		g.choose_dialog("march:epilogue")
		assert(g.state.story.epilogue)
		await g.capture("07-epilogue-"+verdict)
		assert(g.save_game() and g.load_game() and g.state.story.verdict==verdict)
	# The force ending uses an independent boss, with no old-tower echo spawns.
	for e in g.enemies:
		e.dead = true
		g.state.defeated[e.id] = true
		e.collision_layer = 0
	g.state.story.bell_done = false
	g.state.story.bell_method = ""
	g.choose_dialog("march:bell_force")
	var keeper: Node = null
	for e in g.enemies:
		if e.id=="ash_mournkeeper": keeper = e
	assert(keeper!=null and keeper.kind=="mournkeeper")
	g.teleport(Vector2(0,-935))
	g.state.health = g.state.max_health
	g.state.damage = 43
	g.state.inventory.tonic = 6
	g.set_modal("")
	g.bot_active = true
	Engine.time_scale = 3.0
	var fight_start: float = g.state.elapsed
	while not keeper.dead and g.state.elapsed-fight_start<80:
		await g.get_tree().physics_frame
	g.bot_active = false
	Engine.time_scale = 1.0
	assert(keeper.dead and g.state.deaths==0,"The independent keeper must be reachable and beatable in live combat")
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	g.march.tick(0)
	assert(g.state.story.bell_done)
	# Authored male/male ending: adult identity, trust, separate confirmation, no time jump.
	for e in g.enemies:
		e.dead = true
		e.collision_layer = 0
	g.teleport(Vector2(136,-596))
	g.relationship.open_lucan()
	g.relationship.choose("personal:lucan_confide")
	assert(g.relationship.reason().is_empty())
	g.state.profile.gender = "woman"
	assert(not g.relationship.reason().is_empty(),"Lucan's authored preference is stable")
	g.state.profile.gender = "man"
	g.relationship.choose("personal:lucan_offer")
	g.relationship.choose("personal:lucan_confirm")
	g.relationship.choose("personal:begin")
	assert(g.modal=="intimacy")
	var clock_before: float = g.state.day_clock
	g.relationship.tick(2.3)
	g.open_report()
	var phase_before: String = g.relationship.phase
	g.relationship.tick(10)
	assert(g.relationship.phase==phase_before)
	assert(g.report_snapshot.area_id=="ashen_march" and g.report_snapshot.session.relationship.partner=="lucan")
	g.close_report()
	g.relationship.tick(1.1)
	g.relationship.tick(1.0)
	g.relationship.tick(1.6)
	assert(g.state.relationships.lucan_evening and g.state.keepsakes.lucan_lamplight and g.state.day_clock==clock_before)
	await g.capture("07-lucan-aftermath")
	g.ui.show_keepsake("lucan")
	await g.capture("07-lucan-keepsake")
	g.state.keepsakes.mara_lamplight = true
	g.state.relationships.mara_evening = true
	assert(g.save_game() and g.load_game() and g.state.keepsakes.size()==2)
	var bad: Dictionary = g.snapshot()
	bad.state.story.verdict = "nonsense"
	assert(not g.validate_save(bad))
	g.ui.show_map()
	g.ui.quest_track.select(3)
	g.ui.quest_track.item_selected.emit(3)
	assert(g.state.story.track==3 and g.ui.map_view.region==1)
	await g.capture("07-march-journal")
	g.ui.map_view.region = 0
	await g.capture("07-hollow-journal")
	# Render all seven new sites in day / dusk and one storm.
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	for id in D.SITES:
		g.set_modal("pause")
		g.ui.pause_panel.hide()
		var p: Vector2 = D.SITES[id].pos
		g.teleport(p+Vector2(0,20))
		g.player.position.y = g.C.height_at(g.player.position.x,g.player.position.z)
		g.camera.look_at(g.C.ground(p,2.2),Vector3.UP)
		g.state.day_clock = 15.0
		g.world.tick(0)
		g.update_location()
		await g.capture("07-site-"+id)
		if id in ["ash_refuge","ash_ferry","ash_hospice"]:
			g.state.day_clock = 19.0
			g.world.tick(0)
			await g.capture("07-dusk-"+id)
	print("MARCH PASS: six adult NPCs, seven places, evidence locks, scarce treatment/aftermath, named grief, complete letter, testimony, ferry repair/free passage, three faith endings, all three final political settlements, defense reload, peaceful/live-combat keeper endings, authored male/male consent/paused reports/keepsake, two-region journal and schema-5 persistence")
	g.get_tree().quit()

func route(g: Node) -> void:
	g.start_new()
	g.state.flags.won = true
	g.state.story.started = true
	g.state.story.briefed = true
	for enemy in g.enemies:
		enemy.dead = true
		enemy.collision_layer = 0
		enemy.hide()
	g.teleport(Vector2(8,-330))
	g.route_active = true
	Engine.time_scale = 6.0
	for road in D.ROADS:
		g.teleport(road[0])
		assert(await g.route_walk(road))
	# Walk through real doorways to the two sickbeds, the ledger and the burial roll.
	for path in [[Vector2(-77,-523),Vector2(-77,-531),Vector2(-77,-538),Vector2(-77,-531),Vector2(-77,-523)],[Vector2(177,-747),Vector2(177,-754),Vector2(170,-754),Vector2(170,-763)],[Vector2(0,-927),Vector2(0,-936),Vector2(0,-951)]]:
		g.teleport(path[0])
		assert(await g.route_walk(path))
	Engine.time_scale = 1.0
	g.route_active = false
	print("MARCH ROUTE PASS: all seven road routes, Saint Avel's bridge, every regional approach, refuge sickbeds, Veyr ledger and hospice interior reached by real character collision; ",roundi(g.route_distance),"m walked")
	g.get_tree().quit()
