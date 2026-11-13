extends RefCounted

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()
	await g.get_tree().physics_frame
	var sq = g.side_quests
	for object_id in g.C.OBJECTS:
		if not object_id.begins_with("side_"): continue
		var reachable := false
		for angle in range(8):
			var offset := Vector2(0,2.5).rotated(angle*PI/4.0)
			g.teleport(g.C.OBJECTS[object_id].pos+offset)
			g.camera.look_at(g.object_interaction_point(object_id),Vector3.UP)
			await g.get_tree().physics_frame
			if g.nearest_interaction().get("id","")==object_id:
				reachable = true
				g.interact()
				assert(g.modal!="dialog")
				g.set_modal("")
				break
		assert(reachable,"Clue must be reachable through ordinary focus interaction: "+object_id)
	g.state.taken.clear()
	assert(sq.QUESTS.size()==9)
	assert(g.world.npcs.has("pip") and g.C.NPCS.pip.minor)
	assert(not g.relationship.adult("pip") and not g.relationship.compatible("pip"))
	var child_reachable := false
	for angle in range(8):
		g.teleport(g.C.NPCS.pip.pos+Vector2(0,2).rotated(angle*PI/4.0))
		g.camera.look_at(g.world.npcs.pip.global_position,Vector3.UP)
		await g.get_tree().physics_frame
		if g.nearest_interaction().get("id","")=="pip":
			g.interact()
			child_reachable = true
			break
	assert(child_reachable,"Pip must be reachable through normal interaction")
	for choice in g.ui.current_choices:
		assert(not choice.action.begins_with("personal:"))
	for action in ["personal:entry:pip","personal:closer:pip","personal:offer","personal:yes","personal:new_offer","personal:lucan_offer"]:
		g.relationship.choose(action)
		assert(g.dialogue_id=="pip" and g.modal=="dialog")
		assert(not g.relationship.appearance_active("pip"))
	g.relationship.open_new("pip")
	assert(g.dialogue_id=="pip")
	g.relationship.active_id = "pip"
	assert(not g.relationship.safe())
	g.relationship.page("Must not open",[])
	assert(g.ui.dialog_name.text=="Pip")
	g.relationship.active_id = "mara"
	# Every story is reachable through the visible conversation options.
	for id in sq.QUESTS:
		var npc: String = sq.QUESTS[id].npc
		g.talk(npc)
		for index in range(g.ui.current_choices.size()-1):
			assert(g.ui.choices[index].get_rect().end.y<=g.ui.choices[index+1].position.y,"Conversation choices must not overlap")
		if not g.ui.current_choices.any(func(c): return c.action=="side:open:"+id):
			assert(g.ui.current_choices.any(func(c): return c.action=="side:menu"))
			g.choose_dialog("side:menu")
		assert(g.ui.current_choices.any(func(c): return c.action=="side:open:"+id))
		g.choose_dialog("side:open:"+id)
		assert(g.dialogue_id==npc)
		g.choose_dialog("return")
		assert(sq.active_id.is_empty())
	assert(g.world.npc_portrait("pip").get_height()>500,"Pip uses the painted asset")
	for branch in ["a","b"]:
		for id in sq.QUESTS:
			var q: Dictionary = sq.QUESTS[id]
			g.state.taken.clear()
			g.dialogue_id = q.npc
			var before: int = g.state.xp
			sq.choose("side:resolve:"+id+":"+branch)
			assert(g.state.xp==before,"Cannot finish without evidence")
			var order := [0,1] if branch=="a" else [1,0]
			for i in order:
				var object_id: String = "side_"+id+"_"+str(i)
				assert(g.world.objects.has(object_id))
				assert(g.world.outside_buildings(g.C.OBJECTS[object_id].pos),"Clue must be outdoors: "+object_id)
				g.set_modal("")
				var speaker: String = g.dialogue_id
				sq.interact(object_id)
				assert(g.modal=="" and g.dialogue_id==speaker,"Clues must not open remote NPC dialogue")
				assert(sq.marked(id+":known"))
				var queued: int = g.ui.pending_quest_updates.size()
				assert(queued>0 and g.ui.pending_quest_updates.back().detail.contains(q.clues[i]))
				var loot_before: int = g.state.inventory[q.loot]
				sq.interact(object_id)
				assert(g.state.inventory[q.loot]==loot_before and g.ui.pending_quest_updates.size()==queued,"Read evidence has no duplicate loot or stage announcement")
				var restored = preload("res://scripts/state.gd").new()
				assert(restored.read_dict(g.state.to_dict(),5),"Evidence must survive save validation")
				assert(restored.taken.get("side:"+id+":"+str(i),false))
			g.teleport(Vector2(g.world.npcs[q.npc].position.x,g.world.npcs[q.npc].position.z)+Vector2(0,2))
			sq.choose("side:resolve:"+id+":"+branch)
			assert(g.state.xp==before+q.xp and sq.marked(id+":done"))
			assert(sq.marked(id+":choice_b")== (branch=="b"))
			var completed_save = preload("res://scripts/state.gd").new()
			assert(completed_save.read_dict(g.state.to_dict(),5))
			assert(completed_save.taken.get("side:"+id+":done",false))
			assert(completed_save.taken.get("side:"+id+":choice_b",false)==(branch=="b"))
			sq.choose("side:resolve:"+id+":"+branch)
			assert(g.state.xp==before+q.xp,"No duplicate reward")
	# Mara can discuss Pip's account without switching the speaker to Pip.
	g.state.taken.clear()
	sq.mark("ribbon:0")
	sq.mark("ribbon:1")
	g.teleport(g.C.NPCS.mara.pos+Vector2(0,2))
	g.talk("mara")
	g.choose_dialog("side:menu")
	g.choose_dialog("side:open:ribbon")
	assert(g.dialogue_id=="mara")
	g.choose_dialog("side:resolve:ribbon:b")
	assert(sq.marked("ribbon:done") and g.dialogue_id=="mara")
	# Stage banners defer during menus, show the clue and preserve level banners.
	g.state.taken.clear()
	g.ui.reset_progression()
	g.set_modal("pause")
	sq.interact("side_boots_1")
	g.ui.tick_progression(0)
	assert(not g.ui.level_banner.visible and g.ui.pending_quest_updates.size()==1)
	g.set_modal("")
	g.ui.tick_progression(0)
	assert(g.ui.level_banner.visible and g.ui.level_title.text=="QUEST STAGE COMPLETE / 1/2")
	assert(g.ui.level_detail.text.contains(sq.QUESTS.boots.clues[1]))
	g.ui.tick_progression(10)
	sq.interact("side_boots_0")
	g.ui.tick_progression(0)
	assert(g.ui.level_title.text=="QUEST STAGE COMPLETE / 2/2")
	assert(g.ui.level_detail.text.contains("Return to Osric"))
	var old: Dictionary = g.state.to_dict()
	for key in ["amber","salt","wire"]: old.inventory.erase(key)
	var migrated = preload("res://scripts/state.gd").new()
	assert(migrated.read_dict(old,5),"Existing saves load without new loot keys")
	assert(migrated.inventory.amber==0)
	g.state.inventory.amber = 2
	g.state.inventory.salt = 1
	g.state.inventory.wire = 1
	g.state.inventory.fur = 0
	g.state.inventory.essence = 0
	g.state.inventory.toadstools = 0
	g.open_shop("merchant")
	var gold: int = g.state.inventory.gold
	g._local_choose_dialog("sell_curios")
	assert(g.state.inventory.gold==gold+48 and g.state.inventory.amber==0)
	print("SIDE QUEST PASS: 9 stories, both clue orders and all 18 endings, outdoor clues, save migration, no duplicate rewards, curio trade, child intimacy rejection")
	g.get_tree().quit()

