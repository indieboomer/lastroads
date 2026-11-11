extends RefCounted

func run(g: Node) -> void:
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	g.set_physics_process(false)
	g.get_tree().paused = true
	await preload("res://scripts/travel_checks.gd").new().run(g)
	var wild = g.Wilderness
	assert(wild.tier(Vector2(-37,0),12)==0)
	assert(wild.tier(Vector2(50,30),12)>0)
	assert(wild.tier(Vector2(10,0),22)==0)
	assert(wild.tier(Vector2(0,0),22)==0)
	for road in g.C.ROADS:
		for p in road: assert(wild.tier(p)==0,"Roads retain their authored danger")
	for site in g.C.SITES.values(): assert(wild.tier(site.pos)==0)
	var entries: Array = wild.encounters(g.world)
	assert(entries==g.wilderness_encounters,"Encounters must be deterministic")
	assert(entries.any(func(e): return e[0].begins_with("wild_edge_") and g.C.distance_to_road(e[2])>=16 and g.C.distance_to_road(e[2])<32),"Night encounters live near road edges")
	assert(entries.any(func(e): return e[0].begins_with("wild_edge_") and wild.tier(e[2],12,g.world)>0 and g.C.distance_to_road(e[2])<50),"Day encounters live about ten seconds off road")
	assert(entries.any(func(e): return e[1]=="pitchbound"))
	assert(entries.any(func(e): return e[1]=="boughstalker"))
	assert(entries.any(func(e): return e[0].ends_with("_hunter")),"Deepest wilds contain pairs")
	for foe in g.enemies:
		if foe.kind in ["pitchbound","boughstalker"] and foe.id.begins_with("wild_"):
			assert(not foe.visible or g.C.distance_to_road(Vector2(foe.position.x,foe.position.z))>=38,"Passive forest enemies cannot appear at daytime road edges")
	g.torch_equipped = true
	g.teleport(Vector2(0,-55),0)
	g.state.day_clock = 12
	assert(not g.forest_light_protection(),"Daytime torch does not repel the corporeal hunters")
	g.state.day_clock = 22
	assert(g.forest_light_protection())
	g.teleport(Vector2(-200,0),0)
	assert(not g.forest_light_protection(),"Nighttime torch is not protection in woods")
	g.stow_lights()
	var counts := [0,0,0,0]
	for entry in entries:
		var p: Vector2 = entry[2]
		var danger: int = wild.tier(p,22,g.world)
		assert(danger>0 and g.C.distance_to_road(p)>=16)
		assert(not g.world.water_bounds.any(func(bounds): return bounds.has_point(p)))
		counts[danger] += 1
	for foe in g.enemies: foe.queue_free()
	g.enemies.clear()
	await pursuit_checks(g)
	g.teleport(Vector2(0,45),0)
	g.set_modal("")
	var pitch: Node = g.spawn_enemy("wild_test_pitch","pitchbound",Vector2(0,41))
	await g.get_tree().physics_frame
	assert(pitch.illustrated_wilderness and pitch.visual.visible)
	g.blocking = true
	g.block_age = 1
	g.state.health = 90
	g.receive_hit(26,g.player.position-Vector3(0,0,2),"pitchbound")
	assert(g.state.health==83,"Poker chips through a held guard")
	g.block_age = .1
	g.receive_hit(26,g.player.position-Vector3(0,0,2),"pitchbound")
	assert(g.state.health==83,"Timed parry stops poker damage")
	g.blocking = false
	g.teleport(Vector2(-200,-55),0)
	pitch.position = g.player.position+Vector3(0,0,-2)
	pitch.home = pitch.position
	pitch.phase = "windup"
	pitch.clock = 0
	await g.get_tree().physics_frame
	g.state.health = 90
	pitch.tick(1)
	assert(g.state.health==90,"Poker must show its full warning before striking")
	pitch.tick(.5)
	assert(g.state.health<90 and pitch.phase=="recover")
	var hunter: Node = g.spawn_enemy("wild_test_hunter","boughstalker",Vector2(-197,-58))
	await g.get_tree().physics_frame
	hunter.phase = "windup"
	g.teleport(Vector2(0,0),0)
	g.state.day_clock = 22
	hunter.position = g.player.position+Vector3(4,0,0)
	hunter.home = hunter.position
	g.state.health = 90
	g.torch_equipped = true
	hunter.tick(2)
	g.torch_equipped = false
	assert(hunter.phase=="idle" and g.state.health==90,"Held light cancels forest attacks on roads at night")
	g.teleport(Vector2(-200,-55),0)
	hunter.position = g.player.position+Vector3(3,0,-3)
	hunter.home = hunter.position
	hunter.phase = "chase"
	hunter.tick(.016)
	assert(Vector2(hunter.velocity.x,hunter.velocity.z).length()>hunter.spec.speed,"Hunter rushes on approach")
	hunter.phase = "windup"
	hunter.clock = .1
	hunter.hit(1)
	assert(hunter.stun>=.9,"Light attacks interrupt the hunter's warning")
	var gold: int = g.state.inventory.gold
	pitch.hit(999)
	pitch.search_body()
	pitch.search_body()
	assert(g.state.inventory.gold==gold+5,"Loot is awarded once")
	pitch.tick(.2)
	assert(pitch.visual.texture==g.world.wilderness_art.frame(g.world.library,"pitchbound",4),"Cleanup retains the painted corpse")
	var save: Dictionary = g.snapshot()
	assert(g.validate_save(save))
	var restored = g.State.new()
	assert(restored.read_dict(save.state,5))
	assert(restored.defeated.has(pitch.id) and restored.looted.has(pitch.id))
	assert(restored.enemies[hunter.id].kind=="boughstalker")
	var original_state = g.state
	g.state = restored
	var copy: Node = g.Enemy.new()
	g.add_child(copy)
	copy.setup(g,hunter.id,"boughstalker",hunter.home)
	assert(copy.health==hunter.health and copy.phase==hunter.phase and copy.illustrated_wilderness)
	copy.queue_free()
	g.state = original_state
	g.teleport(Vector2(-3,43),0)
	pitch.queue_free()
	g.enemies.erase(pitch)
	hunter.position = g.player.position+Vector3(1,0,-6)
	hunter.stun = 0
	hunter.phase = "windup"
	hunter.clock = .25
	hunter.hit_flash = 0
	hunter.set_art_pose(1)
	g.visuals.values.enabled = true
	g.visuals.values.preset = 1
	g.ui.apply_visuals()
	g.ui.tick(0)
	await g.capture("21-boughstalker")
	hunter.hide()
	g.enemies.erase(hunter)
	var model: Node = g.spawn_enemy("wild_capture_pitch","pitchbound",Vector2(0,36))
	model.phase = "windup"
	model.tick(0)
	g.ui.tick(0)
	await g.capture("21-pitchbound")
	model.hide()
	g.enemies.erase(model)
	await art_review(g)
	var report := {"encounters":entries.size(),"tiers":counts,"entries":[]}
	for entry in entries: report.entries.append({"id":entry[0],"kind":entry[1],"x":entry[2].x,"z":entry[2].y,"danger":wild.tier(entry[2])})
	var file := FileAccess.open(g.data_root().path_join("reports/wilderness-validation.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("WILDERNESS PASS: deterministic encounters ",entries.size()," / tiers ",counts,"; road/site protection, dry land, both enemies, poker warning/block/parry, hunter interrupt, one-time loot and save validation")
	g.get_tree().quit()

func pursuit_checks(g: Node) -> void:
	g.state.day_clock = 22
	g.stow_lights()
	for family in ["pitchbound","boughstalker","wraith"]:
		g.teleport(Vector2(0,-55),0)
		var foe: Node = g.spawn_enemy("wild_pursuit_"+family,family,Vector2(0,-57))
		await g.get_tree().physics_frame
		foe.hit(1)
		foe.stun = 0
		# Beyond the old home leash, an engaged enemy still attacks on the road.
		foe.home = foe.position+Vector3(70,0,0)
		g.state.health = 90
		foe.phase = "windup"
		foe.clock = 0
		foe.tick(foe.spec.windup+.01)
		assert(g.state.health<90 and foe.engaged,"Engaged enemies attack on roads without light")
		for light in ["torch","lantern"]:
			g.torch_equipped = light=="torch"
			g.lantern.visible = light=="lantern"
			g.state.health = 90
			foe.phase = "windup"
			foe.clock = 0
			foe.tick(foe.spec.windup+.01)
			assert(g.state.health==90 and foe.phase=="idle" and foe.engaged,"Both held lights interrupt attacks without forgetting pursuit")
		g.stow_lights()
		foe.position = g.player.position+Vector3(0,0,-2)
		foe.tick(.01)
		assert(foe.phase!="idle","Stowing light resumes pursuit")
		foe.queue_free()
		g.enemies.erase(foe)
	g.torch_equipped = true
	g.teleport(Vector2(0,30),0)
	assert(g.forest_light_protection(),"Settlement light protection")
	g.teleport(Vector2(-200,0),0)
	assert(not g.forest_light_protection(),"A held light alone does not protect deep woods")
	var fire := Node3D.new()
	g.world.add_child(fire)
	fire.global_position = g.player.global_position+Vector3(2,0,0)
	var record := {"node":fire,"permanent":false}
	g.world.fire_nodes.append(record)
	assert(g.forest_light_protection(),"Held light protects near fire")
	g.stow_lights()
	assert(not g.forest_light_protection(),"Fire protection requires a held light")
	g.world.fire_nodes.erase(record)
	fire.queue_free()

func art_review(g: Node) -> void:
	for job in ["pitchbound","boughstalker"]:
		var foe: Node = g.spawn_enemy("art_review_"+job,job,Vector2(0,36))
		var pixel_scale: float = foe.visual.pixel_size
		for retro in [false,true]:
			g.visuals.values.enabled = retro
			g.visuals.values.preset = 1
			g.ui.apply_visuals()
			for frame in range(6):
				foe.set_art_pose(frame)
				assert(is_equal_approx(foe.visual.pixel_size,pixel_scale))
				var texture: Texture2D = foe.visual.texture
				assert(texture.get_width()>50 and texture.get_height()>50)
				var image: Image = texture.get_image()
				assert(image.detect_alpha()!=Image.ALPHA_NONE)
				assert(is_equal_approx(foe.visual.position.y-texture.get_height()*pixel_scale/2,0.0),"Every pose stays grounded")
				await g.capture("22-%s-%s-%d" % [job,"copper" if retro else "original",frame])
		foe.hide()
		g.enemies.erase(foe)
	print("WILDERNESS ART PASS: both painted enemies, all six poses, alpha, stable scale and grounding in Original and Copper")
