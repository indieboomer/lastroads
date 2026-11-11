extends RefCounted

func choose(g: Node, action: String) -> void:
	var index: int = g.ui.current_choices.find_custom(func(c): return c.action==action)
	assert(index>=0 and index<3,"The personal path must use a visible normal dialogue choice: "+action)
	g.ui.choose(index)

func assert_art(g: Node, id: String) -> void:
	var texture: Texture2D = g.relationship.portrait_texture(id)
	assert(texture!=g.world.library.npc(id))
	assert(g.world.npcs[id].texture==texture,"World and portrait must use the same private artwork")
	assert(g.ui.private_portrait.texture==texture)
	assert(is_equal_approx(g.world.npcs[id].pixel_size*texture.get_height(),g.C.NPC_HEIGHTS[id]),"Wardrobe changes preserve physical height")
	var image: Image = load("res://assets/intimacy/"+id+"-private.png").get_image()
	if image.is_compressed(): image.decompress()
	assert(image.get_width()>=700 and image.get_height()>=1000 and image.detect_alpha()!=Image.ALPHA_NONE)
	assert(image.get_pixel(0,0).a<0.01 and image.get_pixel(image.get_width()-1,image.get_height()-1).a<0.01)
	assert(not g.relationship.appearance_active("ilya") and not g.relationship.appearance_active("merchant"))
	g.visuals.values.intimacy = false
	g.world.apply_npc_appearance(id)
	assert(g.world.npcs[id].texture!=texture and g.relationship.portrait_texture(id)!=texture)
	g.visuals.values.intimacy = true
	g.world.apply_npc_appearance(id)
	assert(g.world.npcs[id].texture==texture)

func lucan(g: Node) -> void:
	g.set_modal("")
	g.state.flags.won = true
	g.state.story.started = true
	g.state.story.letters_done = true
	g.state.story.letters_truth = true
	g.state.profile.gender = "man"
	g.state.profile.romance_interest = "adults"
	g.teleport(g.C.NPCS.lucan.pos+Vector2(0,2))
	g.talk("lucan")
	choose(g,"march:lucan_personal")
	choose(g,"personal:lucan_confide")
	choose(g,"personal:lucan_offer")
	choose(g,"personal:lucan_confirm")
	choose(g,"personal:begin")
	assert_art(g,"lucan")
	g.relationship.tick(2.3)
	g.relationship.tick(1.1)
	g.relationship.tick(1.0)
	g.relationship.tick(1.6)
	assert(g.state.relationships.lucan_evening and g.ui.dialog_portrait.texture==g.relationship.portrait_texture("lucan"))
	await g.capture("32-private-dialog-lucan")
	g.ui.modal.hide()
	g.camera.look_at(g.world.npcs.lucan.global_position)
	await g.capture("32-private-world-lucan")
	g.set_modal("")
	assert(g.world.npcs.lucan.texture!=g.relationship.portrait_texture("lucan"))

func run(g: Node) -> void:
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	g.set_physics_process(false)
	for foe in g.enemies: foe.queue_free()
	g.enemies.clear()
	var options = g.relationship.Options
	assert(options.PEOPLE.size()==9 and g.C.NPCS.size()==14,"Nine authored relationship paths")
	g.visuals.values.intimacy = true
	for id in options.PEOPLE:
		for gender in ["man","woman","nonbinary"]:
			for interest in ["adults","men","women","none"]:
				g.state.profile.gender = gender
				g.state.profile.romance_interest = interest
				var expected: bool = gender in options.PEOPLE[id].interested_in and interest in (["adults","men"] if options.PEOPLE[id].gender=="man" else ["adults","women"])
				assert(g.relationship.compatible(id)==expected)
				if id in ["osric","rook","ysabet"]:
					g.relationship.open_new(id)
					assert(g.ui.current_choices.any(func(c): return c.action=="personal:new_offer")==expected)
	for id in ["osric","rook","ysabet"]:
		g.state.profile.gender = "man" if id=="rook" else "woman"
		g.state.profile.romance_interest = "adults"
		g.teleport(g.C.NPCS[id].pos+Vector2(0,2),0)
		g.state.flags.scout = false
		g.state.flags.bargain = false
		g.state.story.ashes_done = false
		g.state.flags.won = true
		g.state.story.started = true
		g.dialogue_id = id
		if id=="rook": g.state.flags.bargain = true
		g.talk(id)
		assert(not g.ui.dialog_body.text.contains("seems interested"))
		choose(g,"personal:entry:"+id)
		g.state.flags.bargain = false
		assert(g.relationship.active_id==id)
		g.relationship.choose("personal:begin")
		assert(g.modal!="intimacy","Direct begin cannot bypass the invitation")
		g.relationship.choose("personal:new_confide")
		assert(not g.relationship.reason().is_empty(),"Quest hint remains until the relevant work is done")
		g.state.flags.scout = true
		g.state.flags.bargain = true
		g.state.story.ashes_done = true
		assert(g.relationship.reason().is_empty())
		g.visuals.values.intimacy = false
		assert(not g.relationship.reason().is_empty())
		g.visuals.values.intimacy = true
		g.relationship.choose("personal:new_offer")
		g.relationship.choose("personal:new_decline")
		assert(g.state.relationships[id+"_declined"])
		g.relationship.open_new(id)
		assert(not g.ui.current_choices.any(func(c): return c.action=="personal:new_offer"))
		g.state.relationships[id+"_declined"] = false
		g.relationship.open_new(id)
		g.relationship.choose("personal:new_offer")
		g.relationship.choose("personal:new_confirm")
		g.relationship.choose("personal:new_tea")
		g.relationship.choose("personal:begin")
		assert(g.modal!="intimacy" and not g.state.keepsakes.has(id+"_lamplight"),"Choosing friendship cancels consent")
		g.relationship.choose("personal:new_offer")
		g.relationship.choose("personal:new_confirm")
		g.relationship.choose("personal:begin")
		assert(g.modal=="intimacy" and g.ui.private_portrait.texture!=null)
		assert_art(g,id)
		await g.capture("27-romance-"+id+"-evening")
		var hour: float = g.state.day_clock
		g.relationship.tick(2.3)
		g.relationship.tick(1.1)
		g.relationship.tick(1.0)
		g.relationship.tick(1.6)
		assert(g.state.keepsakes[id+"_lamplight"] and g.state.relationships[id+"_evening"] and g.state.day_clock==hour)
		assert(g.ui.dialog_portrait.texture==g.relationship.portrait_texture(id))
		if id=="rook":
			g.journey.services()
			assert(g.ui.dialog_portrait.texture==g.world.npcs[id].texture,"Service submenus keep the current wardrobe consistent")
			g.relationship.aftermath()
		g.ui.modal.hide()
		g.camera.look_at(g.world.npcs[id].global_position)
		await g.capture("32-private-world-"+id)
		g.ui.modal.show()
		await g.capture("32-private-dialog-"+id)
		g.ui.show_keepsake(id)
		assert(g.ui.keepsake_text.text.contains(g.C.NPCS[id].name) and g.ui.extra_keepsake_buttons[id].visible)
		await g.capture("27-romance-"+id+"-keepsake")
		g.ui.extra_keepsake_buttons[id].pressed.emit()
		assert(g.ui.keepsake_text.text.contains(options.PEOPLE[id].title))
		g.set_modal("")
		assert(g.world.npcs[id].texture!=g.relationship.portrait_texture(id),"Closing the private conversation restores work clothes")
	var save: Dictionary = g.snapshot()
	assert(g.validate_save(save))
	var restored = g.State.new()
	assert(restored.read_dict(save.state,5) and restored.keepsakes==g.state.keepsakes and restored.relationships==g.state.relationships)
	var legacy: Dictionary = save.state.duplicate(true)
	for id in ["osric","rook","ysabet"]:
		for suffix in ["confided","evening","declined"]: legacy.relationships.erase(id+"_"+suffix)
		legacy.keepsakes.erase(id+"_lamplight")
	var old = g.State.new()
	assert(old.read_dict(legacy,5) and not old.relationships.ysabet_evening,"Old saves acquire optional romance defaults")
	save.state.keepsakes.erase("ysabet_lamplight")
	assert(not g.validate_save(save),"An evening and its keepsake must remain atomic")
	# Exercise Mara directly too; her older production suite also requires a
	# character-creator atlas that is absent from this workspace.
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	g.set_physics_process(false)
	for foe in g.enemies: foe.queue_free()
	g.enemies.clear()
	g.teleport(g.C.NPCS.mara.pos+Vector2(0,2),0)
	g.state.flags.supplies = true
	g.state.flags.scout = true
	g.talk("mara")
	choose(g,"personal:entry:mara")
	choose(g,"personal:confide")
	g.relationship.choose("personal:offer")
	g.relationship.choose("personal:confirm")
	g.relationship.choose("personal:begin")
	assert(g.modal=="intimacy")
	assert_art(g,"mara")
	g.relationship.tick(2.3)
	g.relationship.tick(1.1)
	g.relationship.tick(1.0)
	g.relationship.tick(1.6)
	await g.capture("32-private-dialog-mara")
	g.ui.modal.hide()
	g.camera.look_at(g.world.npcs.mara.global_position)
	await g.capture("32-private-world-mara")
	g.ui.modal.show()
	g.ui.show_keepsake("mara")
	assert(g.state.keepsakes.mara_lamplight and g.ui.keepsake_text.text.contains("Mara"))
	assert(g.validate_save(g.snapshot()))
	await lucan(g)
	await preload("res://scripts/relationship_expansion_checks.gd").new().run(g)
	print("ROMANCE PASS: nine of fourteen NPCs, full gender/interest matrix, natural dialogue routing, three authored paths, locks/opt-out/decline/confirmation/cancellation, nine matched world/dialog assets and recovered Tomas, world restoration, all journal selectors, atomic saves and old-save migration")
