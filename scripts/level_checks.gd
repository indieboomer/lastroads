extends RefCounted
const P = preload("res://scripts/progression.gd")

func run(g: Node) -> void:
	g.start_new()
	g.set_physics_process(false)
	g.ui.reset_progression()
	for i in range(P.THRESHOLDS.size()):
		assert(P.rank(P.THRESHOLDS[i])==i+1)
		if i>0: assert(P.rank(P.THRESHOLDS[i]-1)==i)
	assert(P.THRESHOLDS==[0,250,1000,2400,4000])
	# All reward sources use the same observed XP state, including raw exploration,
	# evidence and replicated enemy XP; ordinary toasts cannot erase the banner.
	g.state.xp = 249
	g.ui.tick_progression(0)
	assert(not g.ui.level_banner.visible and g.ui.pending_levels.is_empty())
	g.quest_reward("Level test",1)
	g.set_modal("")
	g.ui.tick_progression(0)
	assert(g.ui.level_title.text=="LEVEL UP / LEVEL 2" and g.ui.level_banner.visible)
	assert(g.ui.level_detail.text.contains("+10%"))
	g.message("Another quest notification")
	g.ui.discover("Another place","Exploration notification")
	assert(g.ui.level_title.text=="LEVEL UP / LEVEL 2")
	g.ui.tick_progression(4)
	assert(g.ui.level_timer==4)
	g.set_modal("pause")
	g.ui.tick_progression(30)
	assert(g.ui.level_timer==4 and not g.ui.level_banner.visible)
	g.set_modal("")
	g.ui.tick_progression(4)
	g.ui.tick_progression(0)
	assert(not g.ui.level_banner.visible and g.ui.pending_levels.is_empty())
	g.state.xp = P.THRESHOLDS[3]
	g.set_modal("dialog")
	g.ui.tick_progression(0)
	assert(g.ui.pending_levels==[3,4] and not g.ui.level_banner.visible)
	g.set_modal("")
	g.ui.tick_progression(0)
	assert(g.ui.level_title.text=="LEVEL UP / LEVEL 3")
	g.ui.tick_progression(8)
	g.ui.tick_progression(0)
	assert(g.ui.level_title.text=="LEVEL UP / LEVEL 4")
	var count: int = g.state.events.filter(func(event): return event.event.begins_with("level_up:")).size()
	g.ui.tick_progression(8)
	g.ui.tick_progression(0)
	assert(g.state.events.filter(func(event): return event.event.begins_with("level_up:")).size()==count)
	# Rebalancing preserves old levels, XP, equipped unlocked spells and the
	# remainder of the traveller; re-saving never migrates twice.
	for job in ["warrior","ranger","mage","cleric"]:
		var profile: Dictionary = preload("res://scripts/character_data.gd").defaults()
		profile.profession_id = job
		g.start_new(profile)
		g.set_physics_process(false)
		for i in range(P.LEGACY_THRESHOLDS.size()):
			g.state.xp = P.LEGACY_THRESHOLDS[i]
			var old: Dictionary = g.state.to_dict()
			old.erase("progression_version")
			old.erase("level_floor")
			if i>=2 and job in ["mage","cleric"]: old.prepared[0] = "cinder_ring" if job=="mage" else "litany"
			var restored = g.State.new()
			assert(restored.read_dict(old,5))
			assert(restored.xp==old.xp and restored.rank()==i+1)
			assert(restored.prepared==old.prepared)
			var again = g.State.new()
			assert(again.read_dict(restored.to_dict(),5) and again.rank()==restored.rank() and again.xp==restored.xp)
			g.state = again
			g.ui.tick_progression(0)
			assert(not g.ui.level_banner.visible and g.ui.pending_levels.is_empty(),"Loading never replays old level messages")
			g.state.level_floor = 1
	# A real save/load, not only a dictionary roundtrip, resets notification state.
	g.state.xp = P.THRESHOLDS[2]
	g.ui.reset_progression()
	assert(g.save_game() and g.load_game())
	g.ui.tick_progression(0)
	assert(not g.ui.level_banner.visible)
	g.state.xp = P.THRESHOLDS[3]
	g.ui.tick_progression(0)
	assert(g.ui.level_title.text=="LEVEL UP / LEVEL 4")
	g.ui.tick(0)
	assert(g.ui.profession_label.text.contains("Level 4") and g.ui.profession_label.text.contains("to next level"))
	if DisplayServer.get_name()!="headless":
		g.set_modal("")
		g.teleport(Vector2(0,43))
		await g.capture("34-level-up")
	print("LEVEL PASS: thresholds, prominent non-overwritten banner, all XP sources, queued multi-level gains, pause/dialog deferral, HUD, legacy levels/spells preserved, no replay after save/load")
	g.get_tree().quit()
