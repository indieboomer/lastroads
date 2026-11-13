extends RefCounted

const Data = preload("res://scripts/character_data.gd")

func clean(g: Node) -> void:
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()

func run(g: Node) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	g.ui.open_creator()
	var index: int = Data.PROFESSIONS.find(Data.profession("ranger"))
	g.ui.creator.profession.select(index)
	for origin in range(Data.ORIGINS.size()):
		g.ui.creator.origin.select(origin)
		for gender in range(2):
			g.ui.creator.gender.select(gender)
			verify(Data.valid(g.ui.creator.profile()) and g.ui.creator.profile().profession_id=="ranger")
	g.ui.creator.origin.select(0)
	g.ui.creator.gender.select(0)
	g.ui.creator.refresh()
	await g.capture("26-ranger-creator")
	g.ui.creator.begin()
	verify(g.state.profile.profession_id=="ranger" and g.state.prepared.is_empty())
	verify(g.state.inventory.pistol_cartridge==10 and g.state.inventory.musket_cartridge==5,"New Ranger starts with 10 pistol and 5 musket cartridges")
	g.set_physics_process(false)
	clean(g)
	g.teleport(Vector2(0,-55),0)
	var target: Node = g.spawn_enemy("ranger_target","bandit",Vector2(0,-65))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.camera.look_at(target.position+Vector3.UP,Vector3.UP)
	g.attack_clock = 0
	g.attack()
	verify(is_equal_approx(target.health,5.0) and not g.state.ranger.pistol_loaded)
	verify(g.state.inventory.pistol_cartridge==9,"One cartridge is removed on the shot")
	verify(g.audio.recent_events.any(func(e): return e.source=="res://sounds/pistol_shot.mp3"))
	g.attack_clock = 0
	g.attack()
	verify(target.health==5 and g.state.inventory.pistol_cartridge==9,"A spent pistol cannot fire or consume another cartridge")
	g.press_key(KEY_R)
	verify(g.state.ranger.reload_left==4 and not g.offhand_busy())
	verify(g.state.inventory.pistol_cartridge==9,"Reload does not consume ammunition")
	g.ranger.tick(1)
	var saved: Dictionary = g.snapshot()
	verify(g.validate_save(saved))
	var restored = g.State.new()
	verify(restored.read_dict(saved.state,5) and restored.ranger.reload_left==3 and not restored.ranger.pistol_loaded)
	var broken: Dictionary = saved.duplicate(true)
	broken.state.ranger.reload_left = 99
	verify(not g.validate_save(broken))
	g.set_modal("pause")
	g.ranger.tick(9)
	verify(g.state.ranger.reload_left==3,"Paused time must not complete reloads")
	g.set_modal("")
	g.ranger.tick(3)
	verify(g.state.ranger.pistol_loaded and g.state.ranger.reload_left==0)
	g.camera.rotation.y += .5
	g.attack_clock = 0
	g.attack()
	verify(target.health==5 and not g.state.ranger.pistol_loaded,"Firearms require real aim")
	verify(g.state.inventory.pistol_cartridge==8,"A missed shot also consumes exactly one cartridge")
	target.queue_free()
	g.enemies.erase(target)
	g.press_key(KEY_V)
	verify(g.state.ranger.weapon=="musket")
	var boss: Node = g.spawn_enemy("ranger_damage","mournkeeper",Vector2(0,-69))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.camera.look_at(boss.position+Vector3.UP,Vector3.UP)
	g.attack_clock = 0
	g.attack()
	verify(boss.health==190 and not g.state.ranger.musket_loaded,"Musket deals 130, more than pistol's 80")
	g.press_key(KEY_R)
	verify(g.state.ranger.reload_total==6)
	g.press_key(KEY_Q)
	verify(g.state.ranger.weapon=="dagger" and g.state.ranger.reload_left==0 and not g.state.ranger.musket_loaded,"Switching cancels without loading the firearm")
	var close: Node = g.spawn_enemy("ranger_knife","bandit",Vector2(0,-57))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.camera.look_at(close.position+Vector3.UP,Vector3.UP)
	g.attack_clock = 0
	g.attack()
	verify(close.health==69,"Dagger is deliberately weak")
	clean(g)
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.ranger.select("musket")
	g.state.ranger.musket_loaded = true
	var blocked: Node = g.spawn_enemy("ranger_wall","bandit",Vector2(0,-65))
	var wall: Node = g.world.block(g.C.ground(Vector2(0,-60),1.5),Vector3(4,3,.3),g.world.paint("stone"))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.camera.look_at(blocked.position+Vector3.UP,Vector3.UP)
	g.attack_clock = 0
	g.attack()
	verify(blocked.health==85,"Bullets cannot hit through a real wall")
	wall.queue_free()
	clean(g)
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	# Tall painted enemies must take real raycast shots above the old 1.7-unit capsule.
	g.ranger.select("pistol")
	for hour in [12.0,22.0]:
		g.state.day_clock = hour
		for family in ["boughstalker","pitchbound"]:
			var painted: Node = g.spawn_enemy("ranger_painted_%s_%d" % [family,int(hour)],family,Vector2(0,-65))
			await g.get_tree().physics_frame
			await g.get_tree().physics_frame
			g.camera.look_at(painted.position+Vector3(0,2.1 if family=="boughstalker" else 1.9,0),Vector3.UP)
			g.state.ranger.pistol_loaded = true
			g.attack_clock = 0
			g.attack()
			verify(is_equal_approx(painted.health,painted.spec.hp-80),"Upper-body pistol hits damage painted forest enemies by day and night")
			verify(painted.engaged,"A pistol hit starts persistent pursuit")
			clean(g)
			await g.get_tree().physics_frame
			await g.get_tree().physics_frame
	# Light/torch reports: no mana or hidden defence while the left hand is occupied.
	var p: Dictionary = Data.defaults()
	p.profession_id = "mage"
	g.start_new(p)
	g.set_physics_process(false)
	clean(g)
	g.teleport(Vector2(0,-55),0)
	g.toggle_lantern()
	var mana: float = g.state.mana
	g.use_ability(false)
	g.combat.defend()
	verify(g.state.mana==mana and g.combat.projectiles.is_empty())
	g.ui.tick(0)
	verify(g.ui.lantern_view.visible and not g.ui.shield.visible)
	await g.capture("26-held-lantern")
	g.toggle_torch()
	verify(not g.lantern.visible and g.torch_equipped)
	var living: Node = g.spawn_enemy("torch_living","bandit",Vector2(0,-57))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.camera.look_at(living.position+Vector3.UP,Vector3.UP)
	g.attack_clock = 0
	g.torch_attack()
	var living_damage: float = 85-living.health
	verify(living_damage>0 and living_damage<32)
	living.dead = true
	var spirit: Node = g.spawn_enemy("torch_spirit","wraith",Vector2(0,-57))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.attack_clock = 0
	g.torch_attack()
	verify(80-spirit.health>32 and 80-spirit.health>living_damage)
	g.ui.tick(0)
	verify(g.ui.torch_view.visible and not g.ui.shield.visible)
	var torch_position: Vector2 = g.ui.torch_view.position
	g.ui.tick(0)
	verify(g.ui.torch_view.position==torch_position,"A held torch swing must not drift across repeated render ticks")
	await g.capture("26-torch-strike")
	g.toggle_torch()
	g.attack_clock = 0
	g.use_ability(false)
	verify(g.state.mana<mana,"Stowing the light restores casting")
	# Inventory-click followed by every numbered key, retaining existing mouse mechanics.
	g.state.inventory.scrap = 3
	g.set_modal("inventory")
	g.state.pack.sync(g.state.inventory)
	var before: Dictionary = g.state.pack.layout.duplicate(true)
	var item: Dictionary = before.scrap
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = g.ui.backpack.ORIGIN+Vector2(item.x,item.y)*g.ui.backpack.CELL+Vector2(12,12)
	g.ui.backpack._gui_input(click)
	for key in range(KEY_1,KEY_8+1):
		g.press_key(key)
		verify(g.state.pack.slots[key-KEY_1]=="scrap")
	verify(g.state.inventory.scrap==3 and g.state.pack.layout==before)
	# Production captures of ready, discharged and all three two-handed reload stages.
	p.profession_id = "ranger"
	g.start_new(p)
	g.set_physics_process(false)
	clean(g)
	g.teleport(Vector2(-3,43),.6)
	for gun in ["pistol","musket"]:
		g.ranger.select(gun)
		g.attack_clock = 0
		for retro in [false,true]:
			g.visuals.values.enabled = retro
			g.ui.apply_visuals()
			g.ui.ranger_view._process(0)
			await g.capture("26-%s-ready-%s" % [gun,"copper" if retro else "original"])
		await g.get_tree().process_frame
		await g.capture("26-"+gun+"-ready")
		g.attack()
		g.ranger.tick(.04)
		await g.capture("26-"+gun+"-fire")
		g.ranger.tick(.5)
		await g.capture("26-"+gun+"-smoke")
		g.ranger.flash = 0
		g.ranger.smoke = 0
		g.ranger.reload()
		for stage in range(3):
			g.state.ranger.reload_left = g.state.ranger.reload_total*(.85-stage*.33)
			await g.get_tree().process_frame
			g.ui.ranger_view._process(0)
			g.ui.tick(0)
			verify(g.ui.ranger_view.left_hand.visible and not g.ui.lantern_view.visible and not g.ui.torch_view.visible)
			await g.capture("26-%s-reload-%d" % [gun,stage])
		g.ranger.tick(9)
	g.state.ranger.musket_loaded = false
	g.ranger.reload()
	g.ranger.tick(1)
	verify(g.save_game() and g.load_game())
	verify(g.state.ranger.reload_left==5 and not g.state.ranger.musket_loaded)
	g.ranger.tick(5)
	verify(g.state.ranger.musket_loaded)
	g.ranger.select("dagger")
	await g.capture("26-ranger-dagger")
	g.state.inventory.pistol_cartridge = 0
	g.ranger.select("pistol")
	g.state.ranger.pistol_loaded = false
	g.ranger.reload()
	verify(g.state.ranger.reload_left==0,"An empty pouch cannot reload")
	g.talk("mara")
	verify(g.ui.powder_button.visible)
	g.ui.powder_button.pressed.emit()
	var coins: int = g.state.inventory.gold
	g.choose_dialog("buy_powder")
	verify(g.state.inventory.pistol_cartridge==12 and g.state.inventory.gold==coins-6)
	await g.capture("26-powder-supplies")
	g.set_modal("")
	g.ranger.reload()
	verify(g.state.inventory.pistol_cartridge==12,"Reloading does not consume cartridges")
	g.state.inventory.pistol_cartridge = 111
	verify(not g.affordability("buy_powder").allowed,"Cartridge capacity is enforced during reload too")
	g.state.inventory.pistol_cartridge = 12
	g.ranger.select("dagger")
	verify(g.state.inventory.pistol_cartridge==12,"Interrupted reload leaves cartridge count unchanged")
	g.state.inventory.gold = 12
	g.state.inventory.musket_cartridge = 0
	g.talk("mara")
	g.choose_dialog("buy_musket_powder")
	verify(g.state.inventory.musket_cartridge==6 and g.state.inventory.pistol_cartridge==12 and g.state.inventory.gold==6,"Shop sells the selected ammunition type")
	g.set_modal("")
	g.state.xp = g.state.Progression.THRESHOLDS[2]
	g.ranger.select("pistol")
	g.ranger.reload()
	verify(is_equal_approx(g.state.ranger.reload_total,3.2),"Rank three improves handling")
	g.ranger.select("dagger")
	g.state.xp = g.state.Progression.THRESHOLDS[4]
	g.ranger.select("pistol")
	g.state.ranger.pistol_loaded = true
	g.ranger.steady = 1.1
	var elite: Node = g.spawn_enemy("ranger_rank_bonus","mournkeeper",Vector2(-3,31))
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	g.camera.look_at(elite.position+Vector3.UP,Vector3.UP)
	g.attack_clock = 0
	g.attack()
	verify(is_equal_approx(320-elite.health,101.2),"Rank two damage and rank five patient shot combine")
	g.state.flags.sword_upgrade = true
	elite.health = 320
	g.state.ranger.pistol_loaded = true
	g.attack_clock = 0
	g.attack()
	verify(is_equal_approx(320-elite.health,106.26),"Osric's lock tuning applies to firearm damage")
	clean(g)
	# New warning posts are cosmetic territory clues, not unexplained stone columns.
	g.ranger.flash = 0
	g.ranger.smoke = 0
	var signs: Array = g.get_tree().get_nodes_in_group("wilderness_warnings")
	verify(not signs.is_empty())
	var sign: Node3D = signs[0]
	g.teleport(Vector2(sign.position.x,sign.position.z+3),0)
	g.camera.look_at(sign.position+Vector3.UP*1.4,Vector3.UP)
	g.tutorial_timer = 0
	verify(g.interaction_prompt().contains("territory"))
	await g.capture("26-wilderness-warning")
	await pistol_pose_review(g)
	await latest_equipment_review(g)
	await cartridge_smoke_review(g)
	await ammunition_vendor_checks(g)
	print("RANGER PASS: all origins/genders and creator, pistol/musket damage/hit/miss/wall, empty-fire prevention, manual timed reload/cancel/pause/save-load, weak dagger, held-light blocking, torch living/spirit damage, select-item numbered shortcuts, painted equipment/reload/FX and warning clues")
	g.get_tree().quit()

func pistol_pose_review(g: Node) -> void:
	var profile: Dictionary = Data.defaults()
	profile.profession_id = "ranger"
	g.start_new(profile)
	g.set_physics_process(false)
	clean(g)
	var cameras := [
		["2026-11-09T19-42-25-49372132",Vector3(-2.759236,1.212837,41.716484),.05499997,-.3713998],
		["2026-11-09T19-43-19-104067851",Vector3(1.574014,1.212826,28.142788),.03850003,-.2624998],
		["2026-11-09T19-44-01-146269719",Vector3(8.075949,1.212837,24.994364),.2618001,-.1876999],
		["2026-11-09T20-11-26-188841740",Vector3(-44.720871,-2.298769,-133.892563),1.0736003,-.2900004]
	]
	var view: Control = g.ui.ranger_view
	for i in range(cameras.size()):
		var spec: Array = cameras[i]
		var path: String = g.data_root().path_join("debug-logs/"+spec[0]+"/report.json")
		if FileAccess.file_exists(path):
			var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			verify(g.validate_save(report),"Each reported journey must remain valid")
			var restored = g.State.new()
			verify(restored.read_dict(report.state,5))
			g.state = restored
			g.apply_player_stature()
		g.player.position = spec[1]
		g.player.velocity = Vector3.ZERO
		g.player.rotation.y = spec[2]
		g.camera.rotation = Vector3(spec[3],0,0)
		g.state.ranger.weapon = "pistol"
		g.state.ranger.pistol_loaded = true
		g.state.ranger.reload_left = 0.0
		g.state.ranger.reload_total = 0.0
		g.state.ranger.reload_weapon = ""
		g.ranger.reset()
		g.world.apply_state()
		for retro in [false,true]:
			g.visuals.values.enabled = retro
			g.visuals.values.preset = 1
			g.visuals.values.dither = .55
			g.visuals.values.grain = .4
			g.ui.apply_visuals()
			view._process(0)
			g.ui.tick(0)
			verify(view.gun.texture.resource_path.ends_with("pistol-hand-v2.png"))
			verify(is_equal_approx(view.gun.size.x/view.gun.size.y,float(view.gun.texture.get_width())/view.gun.texture.get_height()),"Portrait pistol must not stretch")
			verify(view.muzzle_position().distance_to(Vector2(680,455))<.1,"Pistol rests below and right of the central aiming dot")
			verify(view.gun.position.y>395,"Entire pistol image stays below the central sight corridor")
			verify(view.pan_position().x>view.muzzle_position().x and view.pan_position().y>view.muzzle_position().y)
			await g.capture("27-pistol-report-%d-%s" % [i,"copper" if retro else "original"])
		if i==1:
			g.state.ranger.pistol_loaded = false
			g.ranger.reload()
			for stage in range(3):
				g.state.ranger.reload_left = g.state.ranger.reload_total*(.85-stage*.33)
				view._process(0)
				verify(not view.show_reload_rod(),"Pistol reload must not draw the stick")
				verify(view.left_hand.visible and view.left_hand.z_index<view.gun.z_index,"Working left hand stays behind the pistol")
				await g.capture("27-pistol-reload-%d" % stage)
			g.ranger.tick(9)
		if i==2:
			g.attack_clock = 0
			g.attack()
			g.ranger.tick(.04)
			view._process(0)
			await g.capture("27-pistol-fire-aligned")
			var emission: Vector2 = view.smoke_muzzle
			g.ranger.tick(.5)
			view._process(0)
			verify(view.smoke_muzzle==emission,"Smoke remains at its emission point while recoil settles")
			await g.capture("27-pistol-smoke-aligned")
	if OS.has_feature("editor"):
		var presets := ConfigFile.new()
		verify(presets.load("res://export_presets.cfg")==OK)
		for section in presets.get_sections():
			if section.begins_with("preset.") and not section.ends_with(".options"):
				verify("IMG_1108.jpg" in str(presets.get_value(section,"exclude_filter","")))
	else:
		verify(not ResourceLoader.exists("res://IMG_1108.jpg"))
	print("PISTOL POSE PASS: photo-referenced forward/upward-lock art, all reported cameras in Original/Copper, correct aspect/muzzle anchors, no pistol stick, hand behind weapon, stable smoke and reference-photo export exclusion")

func latest_equipment_review(g: Node) -> void:
	clean(g)
	await g.get_tree().physics_frame
	var report_path: String = g.data_root().path_join("debug-logs/2026-11-09T20-46-11-429609184/report.json")
	if FileAccess.file_exists(report_path):
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report_path))
		var restored = g.State.new()
		verify(restored.read_dict(report.state,5))
		g.state = restored
		g.apply_player_stature()
	g.player.position = Vector3(136.256882,.15093526,-387.847137)
	g.player.rotation.y = -.47080189
	g.camera.rotation = Vector3(-.07039945,0,0)
	g.player.velocity = Vector3.ZERO
	var ghost: Node = g.spawn_enemy("reported_wraith_hit","wraith",Vector2(138.995178,-393.040436))
	ghost.position = Vector3(138.995178,.15083361,-393.040436)
	ghost.set_physics_process(false)
	g.ranger.select("pistol")
	g.state.ranger.pistol_loaded = true
	g.attack_clock = 0
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	await g.capture("28-reported-wraith-before")
	g.attack()
	verify(ghost.dead,"The saved report aim must hit the visible upper body of the Unremembered")
	await g.capture("28-reported-wraith-hit")
	clean(g)
	g.teleport(Vector2(0,-55),0)
	g.camera.rotation = Vector3.ZERO
	g.ranger.reset()
	g.ranger.select("dagger")
	var view: Control = g.ui.ranger_view
	for phase in [0.0,.25,.5,.75,1.0]:
		g.ranger.dagger_clock = .4*(1.0-phase)
		view._process(0)
		verify(view.gun.position.x+view.gun.size.x>1280 and view.gun.position.y+view.gun.size.y>720,"Dagger sleeve must overscan viewport at every thrust phase")
		await g.capture("28-dagger-thrust-%d" % int(phase*100))
	g.ranger.select("musket")
	g.state.ranger.musket_loaded = true
	for retro in [false,true]:
		g.visuals.values.enabled = retro
		g.ui.apply_visuals()
		view._process(0)
		verify(view.gun.texture.resource_path.ends_with("musket-hand-v2.png"))
		verify(is_equal_approx(view.gun.size.x/view.gun.size.y,float(view.gun.texture.get_width())/view.gun.texture.get_height()))
		verify(view.pan_position().x>view.muzzle_position().x,"Lock effects follow the right side of the breech")
		verify(view.gun.position.x+view.gun.size.x>1280 and view.gun.position.y+view.gun.size.y>720,"Repositioned musket sleeves extend through screen edges")
		var barrel_direction: Vector2 = (view.muzzle_position()-view.weapon_point(Vector2(.75,.65))).normalized()
		verify(barrel_direction.dot((Vector2(640,360)-view.muzzle_position()).normalized())>.999,"Barrel points in a straight line to the aiming dot")
		await g.capture("28-musket-"+("copper" if retro else "original"))
	g.state.ranger.musket_loaded = false
	g.ranger.reload()
	for stage in range(3):
		g.state.ranger.reload_left = g.state.ranger.reload_total*(.85-stage*.33)
		view._process(0)
		verify(view.show_reload_rod()==(stage==1))
		await g.capture("28-musket-reload-%d" % stage)
	g.ranger.tick(9)
	g.attack_clock = 0
	g.attack()
	view._process(0)
	await g.capture("28-musket-right-lock-fire")
	print("EQUIPMENT REVIEW PASS: exact reported upper-body wraith shot, dagger sleeve overscan through full thrust, reference musket pose/aspect/right lock, reload and effects")

func cartridge_smoke_review(g: Node) -> void:
	clean(g)
	g.ranger.reset()
	g.state.inventory.pistol_cartridge = 32
	g.state.inventory.musket_cartridge = 32
	g.state.pack.sync(g.state.inventory)
	verify(g.state.pack.layout.has("pistol_cartridge"))
	g.set_modal("inventory")
	g.ui.backpack.selected = "pistol_cartridge"
	verify(g.ui.backpack.icons.pistol_cartridge.resource_path.ends_with("paper-cartridge.png"))
	await g.capture("29-cartridges-inventory")
	g.set_modal("")
	var modern: Dictionary = g.state.to_dict()
	var legacy: Dictionary = modern.duplicate(true)
	legacy.ranger.erase("ammo_version")
	legacy.ranger.reserve = 17
	legacy.ranger.pistol_loaded = true
	legacy.ranger.musket_loaded = false
	legacy.ranger.weapon = "musket"
	legacy.ranger.reload_weapon = "musket"
	legacy.ranger.reload_total = 6.0
	legacy.ranger.reload_left = 2.0
	legacy.inventory.erase("pistol_cartridge")
	var old_state = g.State.new()
	verify(old_state.read_dict(legacy,5) and old_state.inventory.pistol_cartridge==13 and old_state.inventory.musket_cartridge==6,"Migrate spare + loaded + in-progress ammunition without loss")
	var roundtrip = g.State.new()
	verify(roundtrip.read_dict(JSON.parse_string(JSON.stringify(old_state.to_dict())),5) and roundtrip.inventory.pistol_cartridge==13 and roundtrip.inventory.musket_cartridge==6,"Migration must happen only once")
	var shared: Dictionary = legacy.duplicate(true)
	shared.ranger.ammo_version = 2
	shared.inventory.cartridge = 19
	shared.backpack.slots[0] = "cartridge"
	verify(roundtrip.read_dict(shared,5) and roundtrip.inventory.pistol_cartridge+roundtrip.inventory.musket_cartridge==19)
	verify(roundtrip.pack.slots[0]=="pistol_cartridge" and shared.backpack.slots[0]=="cartridge","Migrate old bindings without mutating the input save")
	for invalid in [-1,1.5,123]:
		var bad: Dictionary = modern.duplicate(true)
		bad.inventory.pistol_cartridge = invalid
		verify(not roundtrip.read_dict(bad,5))
	g.ranger.select("musket")
	g.state.ranger.musket_loaded = true
	g.attack_clock = 0
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	g.attack()
	verify(g.state.inventory.musket_cartridge==31 and g.state.inventory.pistol_cartridge==32 and g.ranger.smoke==4)
	var view: Control = g.ui.ranger_view
	view._process(0)
	await g.capture("29-musket-flash")
	for age in [.15,.5,1.2,2.5,3.8]:
		g.ranger.smoke = 4.0-age
		g.ranger.flash = 0
		view._process(0)
		verify(is_equal_approx(float(view.smoke_view.material.get_shader_parameter("age")),age))
		await g.capture("29-musket-smoke-%03d" % int(age*100))
	g.ranger.select("pistol")
	g.state.ranger.pistol_loaded = true
	g.attack_clock = 0
	g.attack()
	view._process(0)
	verify(view.smoke_lifetime==2 and is_equal_approx(view.smoke_strength,.5),"Switching firearms assigns the new shot its own emission profile")
	verify(g.state.inventory.pistol_cartridge==31 and g.state.inventory.musket_cartridge==31)
	g.ranger.tick(5)
	view._process(0)
	verify(not view.smoke_view.visible)
	g.state.inventory.musket_cartridge = 0
	g.ranger.select("musket")
	g.state.ranger.musket_loaded = true
	g.attack_clock = 0
	g.attack()
	verify(g.state.inventory.musket_cartridge==0 and g.state.inventory.pistol_cartridge==31 and g.state.ranger.musket_loaded and g.ranger.smoke==0,"Zero cartridges cannot fire or create effects")
	print("CARTRIDGE / SMOKE PASS: visible painted stack, one per shot including misses, reload/cancel unchanged, legacy loaded/reloading migration once, invalid counts, zero-ammo block, four-second turbulent smoke stages")

func ammunition_vendor_checks(g: Node) -> void:
	g.state.flags.won = true
	for id in g.C.AMMO_SELLERS:
		g.state.inventory.gold = 12
		g.state.inventory.pistol_cartridge = 0
		g.state.inventory.musket_cartridge = 0
		g.talk(id)
		verify(g.ui.powder_button.visible,"Missing ammunition entry for "+id)
		g.ui.powder_button.pressed.emit()
		verify(g.dialogue_id==id)
		g.choose_dialog("buy_powder")
		verify(g.state.inventory.pistol_cartridge==12 and g.state.inventory.gold==6)
		g.choose_dialog("buy_musket_powder")
		verify(g.state.inventory.musket_cartridge==6 and g.state.inventory.gold==0)
		g.choose_dialog("buy_powder")
		verify(g.state.inventory.pistol_cartridge==12 and g.state.inventory.gold==0)
		g.choose_dialog("powder_back")
		verify(g.dialogue_id==id)
		g.open_powder_shop(id)
		g.state.inventory.gold = 12
		g.state.inventory.pistol_cartridge = 122
		g.state.inventory.musket_cartridge = 122
		g.choose_dialog("buy_powder")
		g.choose_dialog("buy_musket_powder")
		verify(g.state.inventory.gold==12 and g.state.inventory.pistol_cartridge==122 and g.state.inventory.musket_cartridge==122)
		print("AMMUNITION VENDOR PASS: "+id)
	g.set_modal("")

# Release exports strip assert expressions entirely. Always execute validation,
# including playback/save actions, and report failures to the build runner.
func verify(condition: bool, detail := "") -> void:
	if not condition:
		push_error("VALIDATION FAILED: "+detail)
