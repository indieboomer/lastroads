extends RefCounted

func choose(g: Node, action: String) -> void:
	var index: int = g.ui.current_choices.find_custom(func(c): return c.action==action)
	assert(index>=0 and index<3,"Relationship route must be visible: "+action)
	g.ui.choose(index)

func move_to(g: Node, id: String) -> void:
	var at: Vector3 = g.world.npcs[id].position
	g.teleport(Vector2(at.x,at.z)+Vector2(0,2))

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()
	g.state.profile.romance_interest = "adults"
	g.state.profile.gender = "man"
	g.state.flags.supplies = true
	g.state.flags.scout = true
	g.state.flags.oil = true
	g.state.flags.relic = true
	g.state.flags.prepared = true
	g.state.story.started = true
	g.state.story.briefed = true
	for id in ["nera","courier","ilya","merchant"]:
		g.set_modal("")
		g.state.flags.won = true
		g.world.apply_state()
		move_to(g,id)
		g.talk(id)
		if id=="nera":
			choose(g,"march:nera_personal")
			assert(g.ui.dialog_body.text.contains("My husband died"),"Original Nera friendship is preserved")
			choose(g,"personal:closer:nera")
		else: choose(g,"personal:entry:"+id)
		choose(g,"personal:new_confide")
		if id=="nera": g.state.story.medicine_done = false
		elif id=="courier": g.state.flags.courier_done = false
		else: g.state.flags.won = false
		assert(not g.relationship.reason().is_empty(),"Local quest/recovery gates matter")
		g.state.flags.won = true
		g.state.flags.courier_done = true
		g.state.story.medicine_done = true
		g.state.story.patient = "raisa"
		g.world.apply_state()
		move_to(g,id)
		assert(g.relationship.reason().is_empty(),"Safety must follow relocated Ilya and Tomas")
		if id=="courier":
			assert(g.world.npcs.courier.texture==g.world.npc_portrait("courier"))
			assert(g.world.npcs.courier.texture!=g.world.library.npc("courier"),"Recovered Tomas sheds bloody bandages")
		choose(g,"personal:new_offer")
		choose(g,"personal:new_confirm")
		if g.relationship.companion(id):
			g.relationship.choose("personal:begin")
			assert(g.modal!="intimacy" and not g.state.relationships[id+"_evening"],"Companionship cannot enter a private-room scene")
			choose(g,"personal:companion_begin")
			assert(g.modal=="dialog" and g.relationship.phase=="aftermath")
			assert(g.ui.dialog_body.text.contains("hand in hand") if id=="ilya" else g.ui.dialog_body.text.contains("dance"))
		else:
			choose(g,"personal:begin")
			assert(g.modal=="intimacy")
			g.relationship.tick(2.3)
			g.relationship.tick(1.1)
			g.relationship.tick(1.0)
			g.relationship.tick(1.6)
		var art: Texture2D = g.relationship.portrait_texture(id)
		assert(g.ui.dialog_portrait.texture==art and g.world.npcs[id].texture==art)
		assert(is_equal_approx(g.world.npcs[id].pixel_size*art.get_height(),g.C.NPC_HEIGHTS[id]))
		var image: Image = load(g.relationship.art_path(id)).get_image()
		if image.is_compressed(): image.decompress()
		assert(image.detect_alpha()!=Image.ALPHA_NONE and image.get_pixel(0,0).a<0.01)
		assert(g.state.keepsakes[id+"_lamplight"] and g.state.relationships[id+"_evening"])
		await g.capture("33-relationship-dialog-"+id)
		g.ui.modal.hide()
		g.camera.look_at(g.world.npcs[id].global_position)
		await g.capture("33-relationship-world-"+id)
		g.ui.modal.show()
		g.ui.show_keepsake(id)
		assert(g.ui.keepsake_portrait.texture==art and g.ui.extra_keepsake_buttons[id].visible)
		assert(g.ui.keepsake_text.text.contains(g.C.NPCS[id].name))
		g.set_modal("")
		assert(g.world.npcs[id].texture!=art,"Normal wardrobe returns when the scene ends")
	# New fields are optional in older saves and reset on reused state readers.
	var save: Dictionary = g.snapshot()
	assert(g.validate_save(save))
	var restored = g.State.new()
	assert(restored.read_dict(JSON.parse_string(JSON.stringify(save.state)),5))
	for id in ["nera","courier","ilya","merchant"]:
		for suffix in ["confided","declined","evening"]: save.state.relationships.erase(id+"_"+suffix)
		save.state.keepsakes.erase(id+"_lamplight")
	assert(restored.read_dict(save.state,5))
	assert(not restored.relationships.nera_evening and not restored.relationships.merchant_evening)
	save.state.relationships.nera_evening = true
	assert(not g.validate_save(save),"New memories remain atomic with their keepsakes")
	# Render every selector together; all nine fit inside the existing panel.
	for id in g.relationship.Options.PEOPLE:
		g.state.relationships[id+"_evening"] = true
		g.state.keepsakes[id+"_lamplight"] = true
	g.ui.show_keepsake("merchant")
	for selector in g.ui.extra_keepsake_buttons.values():
		assert(selector.position.x+selector.size.x<=g.ui.keepsake_panel.size.x)
		assert(selector.position.y+selector.size.y<=544)
	await g.capture("33-nine-keepsakes")
	print("RELATIONSHIP EXPANSION PASS: Nera/Tomas private paths, Ilya/Adela clothed companionship, dynamic NPC safety, healed daytime Tomas, four asset pairs, nine keepsakes, JSON/legacy/atomic saves")
