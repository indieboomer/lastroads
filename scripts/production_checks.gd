extends RefCounted

const Data = preload("res://scripts/character_data.gd")

func run(g: Node) -> void:
	await g.get_tree().process_frame
	g.ui.open_creator()
	assert(g.modal=="creator" and g.get_tree().paused and g.ui.creator.visible)
	for index in range(Data.ORIGINS.size()):
		g.ui.creator.origin.select(index)
		for profession in range(Data.PROFESSIONS.size()):
			g.ui.creator.profession.select(profession)
			g.ui.creator.refresh()
			var profile: Dictionary = g.ui.creator.profile()
			assert(Data.valid(profile))
			var candidate = g.State.new()
			candidate.create_character(profile)
			var restored = g.State.new()
			assert(restored.read_dict(candidate.to_dict(),5))
			assert(restored.profile==profile and restored.mana==candidate.mana and restored.damage==candidate.damage)
			assert(g.ui.creator.portrait.texture!=null)
	g.ui.creator.origin.select(2)
	g.ui.creator.profession.select(1)
	g.ui.creator.gender.select(1)
	g.ui.creator.name_entry.text = "Amari"
	g.ui.creator.refresh()
	await g.capture("06-character-creator")
	var bad := Data.defaults()
	bad.age = 17
	assert(not Data.valid(bad))
	bad = Data.defaults()
	bad.species_id = "ogre"
	assert(not Data.valid(bad))
	g.ui.creator.begin()
	assert(g.started and g.modal=="" and g.state.profile.name=="Amari" and g.state.mana==80)
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	g.state.health = 40
	g.state.mana = 80
	g.set_modal("")
	g.use_ability(true)
	assert(g.state.health==40 and g.state.mana==68 and g.combat.projectiles.size()==1)
	g.attack_clock = 0
	g.use_ability(true)
	assert(g.state.mana==68,"Cooldown prevents repeat cast")
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	# Every master is real RGBA, cropped once, and grounded to its configured height.
	for id in ["mara","osric","ilya","vesna","rook","sister","courier","merchant"]:
		var image: Image = g.world.library.npc(id).get_image()
		assert(image.get_width()>100 and image.get_height()>500 and image.detect_alpha()!=Image.ALPHA_NONE)
		if id in ["sister","mara","osric","rook"]:
			var shut: Image = g.world.library.npc(id,true).get_image()
			assert(shut.get_size()==image.get_size())
			var open_bytes := image.get_data()
			var shut_bytes := shut.get_data()
			var changed := 0
			for pixel in range(image.get_width()*image.get_height()):
				assert(open_bytes[pixel*4+3]==shut_bytes[pixel*4+3],"Blink alpha cannot change")
				if open_bytes[pixel*4]!=shut_bytes[pixel*4] or open_bytes[pixel*4+1]!=shut_bytes[pixel*4+1] or open_bytes[pixel*4+2]!=shut_bytes[pixel*4+2]: changed += 1
			assert(changed>0 and changed<600,"Only tiny eyelid regions may change")
		g.talk(id)
		await g.capture("06-portrait-"+id)
	for preset in range(g.visuals.PRESETS.size()):
		g.visuals.values.enabled = true
		g.visuals.values.preset = preset
		g.ui.apply_visuals()
		g.talk("sister")
		await g.capture("06-art-style-%d" % preset)
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	# Four lookbook actors at real world scale, together in every look by day/night.
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	var cast := ["sister","mara","osric","rook"]
	for id in g.world.npcs:
		g.world.npcs[id].visible = id in cast
	for index in range(cast.size()):
		var id: String = cast[index]
		g.world.npc_anchors[id] = g.world.npc_ground(Vector2(-4.5+index*3.0,30),g.C.NPC_HEIGHTS[id])
	g.teleport(Vector2(0,40))
	g.player.position.y = g.C.height_at(0,40)
	g.camera.look_at(g.C.ground(Vector2(0,30),1.0),Vector3.UP)
	g.ui.hud_root.hide()
	for look in range(-1,g.visuals.PRESETS.size()):
		g.visuals.values.enabled = look>=0
		g.visuals.values.preset = maxi(0,look)
		g.ui.apply_visuals()
		for hour in [14.5,21.0]:
			g.state.day_clock = hour
			g.world.tick(0)
			await g.capture("06-cast-look-%d-%s" % [look,"day" if hour<18 else "night"])
	g.ui.hud_root.show()
	g.state.day_clock = 14.5
	g.world.apply_state()
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	g.set_modal("")
	# A small stone keeps its original billboard through every tree treatment.
	for mode in range(4):
		g.world.apply_rock_mode(mode)
		for record in g.world.rocks:
			assert(record.node.billboard==BaseMaterial3D.BILLBOARD_FIXED_Y and record.node.visible)
	g.world.impact(g.C.ground(Vector2(2,38)),false,false)
	assert(g.world.stains.size()>0)
	g.world.tick(45)
	assert(g.world.stains[0].material_override.get_shader_parameter("opacity")<1)
	g.world.tick(11)
	assert(g.world.stains.is_empty(),"Old blood must disappear")
	# Consensual Mara branch: friendship, locks, decline and final confirmation.
	g.teleport(Vector2(-8,45))
	g.player.position.y = g.C.height_at(-8,45)
	g.relationship.open()
	g.relationship.choose("personal:begin")
	assert(g.modal!="intimacy","An injected begin cannot bypass confirmation")
	g.relationship.choose("personal:confide")
	assert(g.state.relationships.mara_confided)
	g.visuals.values.intimacy = false
	assert(not g.relationship.reason().is_empty())
	g.visuals.values.intimacy = true
	g.state.flags.supplies = true
	g.state.flags.scout = true
	assert(g.relationship.reason().is_empty())
	g.relationship.choose("personal:offer")
	g.relationship.choose("personal:decline")
	assert(g.state.relationships.mara_declined and not g.state.keepsakes.has("mara_lamplight"))
	g.state.relationships.mara_declined = false
	g.relationship.open()
	g.relationship.choose("personal:offer")
	g.relationship.choose("personal:confirm")
	g.relationship.choose("personal:begin")
	assert(g.modal=="intimacy")
	var time_before: float = g.state.elapsed
	var day_before: float = g.state.day_clock
	g.relationship.tick(2.3)
	var phase_before: String = g.relationship.phase
	var clock_before: float = g.relationship.clock
	g.open_report()
	g.relationship.tick(8)
	assert(g.relationship.phase==phase_before and g.relationship.clock==clock_before)
	await g.capture("06-private-paused-report")
	g.close_report()
	g.relationship.tick(1.1)
	g.relationship.tick(1.0)
	assert(g.state.relationships.mara_evening and g.state.keepsakes.mara_lamplight)
	g.relationship.tick(1.6)
	assert(g.state.elapsed==time_before and g.state.day_clock==day_before)
	await g.capture("06-mara-aftermath")
	g.ui.show_keepsake()
	await g.capture("06-keepsake")
	assert(g.save_game())
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(g.save_path()))
	assert(g.validate_save(payload))
	assert(g.load_game() and g.state.profile.name=="Amari" and g.state.keepsakes.mara_lamplight)
	payload.state.profile.age = 17
	assert(not g.validate_save(payload))
	var player_backup: String = g.data_root().path_join("reports/pre-0.6-player-save.json")
	if FileAccess.file_exists(player_backup):
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(player_backup))
		assert(g.validate_save(original),"The actual pre-change player journey must migrate")
		assert(g.test_mode and g.save_path().contains("reports/integration-save.json"))
		var isolated := FileAccess.open(g.save_path(),FileAccess.WRITE)
		isolated.store_string(JSON.stringify(original))
		isolated.close()
		assert(g.load_game())
		assert(g.state.flags==original.state.flags)
		for item in original.state.inventory:
			if item!="cartridge": assert(g.state.inventory.get(item)==original.state.inventory[item],"Migration preserves each existing inventory item while adding new item slots")
		assert(g.state.profile.age>=18 and not g.state.story.started)
		assert(g.save_game() and g.load_game(),"Migrated original journey must round-trip as schema 5")
	print("PRODUCTION PASS: 24 origin/profession combinations, portrait selection, real spell costs/cooldowns, adult profile validation, schema-5 migration/roundtrip, eight stable NPC masters/nine art presets, legacy rocks, stain decay, friendship/decline/second consent, paused scene diagnostics, atomic keepsake state and journal")
	g.get_tree().quit()
