extends RefCounted

func find_track(g: Node, id: String) -> int:
	for i in range(14,g.ui.quest_track.item_count):
		if g.ui.quest_track.get_item_metadata(i)==id: return i
	return -1

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	g.ui.show_map()
	assert(g.ui.quest_track.visible and g.ui.quest_track.selected==13)
	assert(find_track(g,"ribbon")==-1,"Unknown stories must not be exposed")
	g.teleport(Vector2(0,42))
	g.talk("pip")
	g.side_quests.open_quest("ribbon")
	assert(g.ui.current_choices.any(func(c): return c.action=="side:track:ribbon"))
	g.side_quests.choose("side:track:ribbon")
	assert(g.state.tracked_side=="ribbon" and g.modal=="")
	var first: Dictionary = g.target()
	assert(first.pos in [g.C.OBJECTS.side_ribbon_0.pos,g.C.OBJECTS.side_ribbon_1.pos])
	g.ui.show_map()
	var selected: int = find_track(g,"ribbon")
	assert(selected>=14 and g.ui.quest_track.selected==selected)
	assert(g.ui.journal.text.begins_with("[color=#e2c38a]TRACKED / Where the Ribbon Went"))
	assert(g.side_quests.markers().size()==2)
	var payload: Dictionary = g.state.to_dict()
	var copy = g.State.new()
	assert(copy.read_dict(payload,5) and copy.tracked_side=="ribbon")
	payload.erase("tracked_side")
	assert(copy.read_dict(payload,5) and copy.tracked_side.is_empty())
	payload.tracked_side = "not a quest"
	assert(not g.State.new().read_dict(payload,5))
	g.side_quests.interact("side_ribbon_1")
	assert(g.target().pos==g.C.OBJECTS.side_ribbon_0.pos)
	assert(g.side_quests.markers()[1].found)
	g.side_quests.interact("side_ribbon_0")
	var at: Vector3 = g.world.npcs.pip.position
	assert(g.target().pos==Vector2(at.x,at.z))
	g.teleport(Vector2(at.x,at.z)+Vector2(0,2))
	g.side_quests.choose("side:resolve:ribbon:a")
	assert(g.state.tracked_side.is_empty())
	g.ui.show_map()
	assert(find_track(g,"ribbon")==-1)
	# An early trader story must not point at Adela before she arrives.
	g.state.taken.clear()
	g.side_quests.open_quest("dowry")
	g.side_quests.choose("side:track:dowry")
	g.side_quests.interact("side_dowry_0")
	g.side_quests.interact("side_dowry_1")
	assert(g.target().text.contains("Northwatch restored first"))
	assert(g.target().pos==g.main_target().pos)
	# Both clue orders and all contacts, including moved end-of-chapter NPCs.
	g.state.flags.won = true
	g.world.apply_state()
	for id in g.side_quests.QUESTS:
		g.state.taken.clear()
		g.side_quests.open_quest(id)
		g.side_quests.choose("side:track:"+id)
		assert(g.state.tracked_side==id)
		for i in [0,1]: g.side_quests.interact("side_"+id+"_"+str(i))
		var npc: String = g.side_quests.QUESTS[id].npc
		var npc_at: Vector3 = g.world.npcs[npc].position
		assert(g.target().pos==Vector2(npc_at.x,npc_at.z),"Return markers follow relocated NPCs")
		g.ui.show_map()
		assert(find_track(g,id)>=14)
	# Selecting a chapter restores that chapter's tracker without deleting side progress.
	g.ui.select_quest_track(1)
	assert(g.state.tracked_side.is_empty() and g.state.story.track==1 and not g.state.woods.focus)
	g.ui.select_quest_track(9)
	assert(g.state.woods.focus and g.state.woods.track==2)
	# A tracked outside quest directs the player to the crypt exit first.
	g.state.taken.clear()
	g.side_quests.open_quest("boots")
	g.side_quests.choose("side:track:boots")
	g.teleport(Vector2(130,-390))
	assert(g.in_crypt() and g.target().pos==g.C.OBJECTS.crypt_exit.pos)
	g.teleport(Vector2(0,42))
	g.ui.show_map()
	g.ui.map_view.region = 0
	g.ui.tick(0)
	assert(g.ui.tracker.text.begins_with("THE CAPTAIN OF BOTH BOOTS"))
	assert(g.ui.level_banner.position.y>350,"Level banner must leave the aiming reticle clear")
	if DisplayServer.get_name()!="headless": await g.capture("35-track-side-story")
	print("JOURNAL PASS: discovered-only selectable side stories, map/compass objectives, either clue order, relocated contacts, chapter switching, completion cleanup, crypt exit and persistence")
	g.get_tree().quit()
