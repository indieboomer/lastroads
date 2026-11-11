extends RefCounted

const Data = preload("res://scripts/character_data.gd")

func profile(profession: String) -> Dictionary:
	var result := Data.defaults()
	result.profession_id = profession
	return result

func clear_enemies(g: Node) -> void:
	for enemy in g.enemies: enemy.queue_free()
	g.enemies.clear()

func aim(g: Node, enemy: Node) -> void:
	g.camera.look_at(enemy.global_position+Vector3.UP*1.1,Vector3.UP)

func run(g: Node) -> void:
	g.start_new(profile("mage"))
	g.set_physics_process(false)
	clear_enemies(g)
	g.teleport(Vector2(0,45),PI)
	var enemy: Node = g.spawn_enemy("profession_living","bandit",Vector2(0,52))
	await g.get_tree().physics_frame
	g.get_tree().paused = true
	aim(g,enemy)
	var mana: float = g.state.mana
	g.attack()
	assert(g.state.mana==mana and g.combat.projectiles.size()==1)
	# A miss stays a miss even when an enemy is in the old auto-target cone.
	var health: float = enemy.health
	for i in range(20): g.combat.tick(0.02)
	assert(enemy.health==health-12.0 and enemy.phase=="chase","A ranged hit must provoke pursuit")
	g.camera.rotation.y += 0.3
	g.attack_clock = 0
	g.attack()
	for i in range(25): g.combat.tick(0.02)
	assert(enemy.health==health-12.0,"Dart must require actual aim")
	aim(g,enemy)
	g.attack_clock = 0
	g.use_ability(true)
	for i in range(20): g.combat.tick(0.02)
	assert(enemy.brittle>0 and enemy.rimed>0 and g.state.mana==mana-12)
	health = enemy.health
	g.attack_clock = 0
	g.attack()
	for i in range(20): g.combat.tick(0.02)
	assert(enemy.health==health-30 and enemy.brittle==0)
	g.combat.impact("rime",enemy,enemy.position+Vector3.UP)
	var record: Dictionary = enemy.record()
	assert(record.rimed==4 and record.brittle==6)
	g.state.enemies[enemy.id] = record
	var save: Dictionary = g.snapshot()
	var restored = g.State.new()
	assert(restored.read_dict(save.state,5))
	g.combat.launch("dart")
	var flying: Dictionary = g.combat.record()
	g.combat.restore(flying)
	assert(g.combat.projectiles.size()==flying.projectiles.size() and g.combat.valid_record(flying))
	assert(restored.prepared==["ember","rime"] and restored.ability_cooldowns.has("defensive"))
	var legacy: Dictionary = save.state.duplicate(true)
	legacy.erase("prepared")
	legacy.ability_cooldowns.erase("defensive")
	assert(g.State.new().read_dict(legacy,5),"Older caster saves gain starting slots and defence")
	var bad: Dictionary = save.state.duplicate(true)
	bad.prepared = ["rime","rime"]
	assert(not g.State.new().read_dict(bad,5))
	# The ray must collide with walls rather than damaging through them.
	var wall: Node = g.world.block(g.player.position+Vector3(0,1.2,3),Vector3(3,3,0.3),g.world.paint("stone"))
	await g.get_tree().physics_frame
	aim(g,enemy)
	health = enemy.health
	g.combat.launch("dart")
	for i in range(20): g.combat.tick(0.02)
	assert(enemy.health==health)
	wall.queue_free()
	g.combat.reset()
	g.start_new(profile("cleric"))
	clear_enemies(g)
	g.teleport(Vector2(0,45),PI)
	enemy = g.spawn_enemy("cleric_living","bandit",Vector2(0,47.6))
	await g.get_tree().physics_frame
	g.get_tree().paused = true
	aim(g,enemy)
	mana = g.state.mana
	health = enemy.health
	g.attack()
	assert(enemy.health==health-24 and enemy.stun>=0.65 and g.state.mana==mana)
	g.attack_clock = 0
	g.use_ability(false)
	assert(enemy.health==health-58 and g.state.mana==mana-14)
	g.combat.defend()
	assert(enemy.push.length()>0 and g.state.ability_cooldowns.defensive==5)
	mana = g.state.mana
	g.combat.defend()
	assert(g.state.mana==mana,"Defence cooldown cannot be bypassed")
	g.attack_clock = 0
	g.use_ability(true)
	assert(g.combat.protected_at(g.player.position))
	var active_record: Dictionary = g.combat.record()
	assert(g.combat.valid_record(active_record))
	assert(g.validate_save(g.snapshot()))
	var broken: Dictionary = g.snapshot()
	broken.combat_runtime.sanctuary.left = -1
	assert(not g.validate_save(broken))
	g.combat.reset()
	g.combat.restore(active_record)
	assert(g.combat.sanctuary.left==8 and g.combat.protected_at(g.player.position))
	var at: Vector3 = g.player.position
	g.state.health = 50
	g.combat.tick(1)
	assert(g.state.health==52)
	g.set_modal("")
	g.receive_hit(20,enemy.position,"test")
	assert(is_equal_approx(g.state.health,39.0),"Sanctuary reduces damage by 35 percent")
	g.player.position.x += 4
	assert(not g.combat.protected_at(g.player.position),"Sanctuary stays where cast")
	g.player.position = at
	g.set_physics_process(true)
	g.open_report()
	assert(g.report_snapshot.combat_runtime.sanctuary.left>0)
	var left: float = g.combat.sanctuary.left
	await g.get_tree().create_timer(0.12).timeout
	assert(g.combat.sanctuary.left==left)
	g.close_report()
	g.set_physics_process(false)
	g.combat.tick(8)
	assert(g.combat.sanctuary.is_empty())
	var boss: Node = g.spawn_enemy("resistance","guardian",Vector2(0,50))
	boss.phase = "windup"
	boss.clock = 0
	boss.force_reaction(Vector3.FORWARD,10,2,1)
	assert(boss.push==Vector3.ZERO and boss.stun==0)
	boss.force_reaction(Vector3.FORWARD,10,2,1)
	assert(boss.stun>0,"Boss resists displacement but can be staggered in early windup")
	g.combat.impact("rime",boss,boss.position+Vector3.UP)
	health = boss.health
	g.combat.impact("dart",boss,boss.position+Vector3.UP)
	assert(boss.health==health-30 and boss.brittle==0)
	clear_enemies(g)
	g.set_modal("")
	g.state.ability_cooldowns.secondary = 0
	g.state.mana = 70
	g.teleport(Vector2(-3,43),0.6)
	g.attack_clock = 0
	g.combat.cast(true)
	assert(not g.combat.sanctuary.is_empty())
	g.swing = g.swing_duration*0.55
	g.ui.tick(0)
	await g.capture("10-cleric-sanctuary")
	g.state.ability_cooldowns.defensive = 0
	g.combat.defend()
	g.swing = g.swing_duration*0.55
	g.combat.gesture_clock = 0.2
	await g.capture("10-cleric-rebuke")
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	await g.capture("10-cleric-original")
	g.get_tree().paused = true
	g.teleport(Vector2(-3,22))
	g.rest()
	assert(g.modal=="preparation" and g.state.day_clock==7 and g.state.mana==70)
	g.ui.preparation_slots[0].select(1)
	g.ui.preparation_slots[0].item_selected.emit(1)
	assert(g.ui.preparation_slots[1].selected==0)
	await g.capture("10-safe-rest-preparation")
	g.ui.preparation_confirm.pressed.emit()
	assert(g.state.prepared==["sanctuary","judgement"] and g.modal=="")
	var prepared_save = g.State.new()
	assert(prepared_save.read_dict(g.state.to_dict(),5) and prepared_save.prepared==g.state.prepared)
	g.set_modal("")
	g.start_new(profile("mage"))
	clear_enemies(g)
	g.teleport(Vector2(-3,43),0.6)
	g.toggle_torch()
	var before_torch_mana: float = g.state.mana
	g.combat.cast(true)
	g.ui.tick(0)
	assert(g.state.mana==before_torch_mana and g.ui.torch_view.visible and not g.ui.shield.visible,"A held torch blocks offhand spellcasting")
	g.combat.tick(0.5)
	g.swing = 0
	g.ui.tick(0)
	assert(g.ui.torch_view.visible and not g.ui.shield.visible)
	g.toggle_torch()
	g.state.ability_cooldowns.secondary = 0
	g.attack_clock = 0
	g.combat.cast(true)
	g.swing = g.swing_duration*0.55
	g.combat.gesture_clock = 0.2
	await g.capture("10-mage-rime")
	g.visuals.values.enabled = true
	g.visuals.values.preset = 6
	g.ui.apply_visuals()
	await g.capture("10-mage-macintosh")
	await visual_review(g)
	await progression_review(g)
	print("PROFESSION PASS: aimed free basics/hit/miss/wall collision, living-target sacred damage/stagger, Rime-Dart consume/Brittle bonus, status/save migration and validation, defensive cooldown, fixed Sanctuary/healing/35% mitigation/expiry/report freeze, boss displacement resistance/early interrupt/combo, caster equipment and safe-rest preparation captures")
	g.get_tree().quit()

func progression_review(g: Node) -> void:
	var progression = preload("res://scripts/progression.gd")
	for i in range(progression.THRESHOLDS.size()):
		var threshold: int = progression.THRESHOLDS[i]
		assert(progression.rank(threshold)==i+1)
		if i>0: assert(progression.rank(threshold-1)==i)
	for job in ["mage","cleric"]:
		g.start_new(profile(job))
		g.set_physics_process(false)
		clear_enemies(g)
		g.teleport(Vector2(-3,43),0.6)
		g.get_tree().paused = true
		var learned: String = "cinder_ring" if job=="mage" else "litany"
		var saved: Dictionary = g.state.to_dict()
		saved.prepared[0] = learned
		assert(not g.State.new().read_dict(saved,5),"Locked spells cannot be loaded")
		g.state.xp = 160
		g.ui.show_preparation()
		assert(g.ui.preparation_slots[0].item_count==3)
		g.ui.preparation_slots[0].select(2)
		g.ui.preparation_slots[0].item_selected.emit(2)
		g.ui.preparation_slots[1].select(2)
		g.ui.preparation_slots[1].item_selected.emit(2)
		assert(g.ui.preparation_slots[0].selected!=g.ui.preparation_slots[1].selected)
		g.ui.preparation_confirm.pressed.emit()
		assert(learned in g.state.prepared)
		var restored = g.State.new()
		assert(restored.read_dict(g.state.to_dict(),5) and restored.prepared==g.state.prepared)
		g.state.health = 40
		var mana_before: float = g.state.mana
		g.combat.cast(g.state.prepared[1]==learned)
		assert(g.state.mana==mana_before-g.combat.COSTS[learned])
		assert(g.combat.gesture==learned and not g.combat.fx.is_empty())
		if job=="cleric": assert(g.state.health==62)
		assert(g.validate_save(g.snapshot()),"Unlocked spell runtime must survive validation")
		g.ui.tick(0)
		await g.capture("20-progression-"+job)
	print("PROGRESSION PASS: rank boundaries, locked spell rejection, three-spell preparation, distinct slots, unlocked spell saves, mana and casts")

func encounters(g: Node) -> void:
	# Same bounded physics arena and enemy roster for both professions.
	# This is an input-driving bot, not a replacement damage simulation.
	var centre := Vector2(205,50)
	var floor_y: float = g.C.height_at(centre.x,centre.y)+20
	g.world.block(Vector3(centre.x,floor_y-0.25,centre.y),Vector3(45,0.5,45),g.world.paint("stone"))
	var outcomes: Array = []
	Engine.time_scale = 4
	for profession in ["cleric","mage"]:
		for encounter in ["living","abyss","boss","empty-mana"]:
			g.start_new(profile(profession))
			clear_enemies(g)
			await g.get_tree().physics_frame
			g.player.position = Vector3(centre.x,floor_y+0.1,centre.y)
			g.player.velocity = Vector3.ZERO
			g.state.day_clock = 22 if encounter=="abyss" else 12
			g.state.inventory.tonic = 0
			g.state.inventory.bread = 0
			if encounter=="empty-mana": g.state.mana = 0
			var kinds: Array = ["mournkeeper"] if encounter=="boss" else ["wraith","wraith","wraith"] if encounter=="abyss" else ["bandit","bandit","bandit"] if encounter=="living" else ["bandit"]
			for i in range(kinds.size()):
				var enemy: Node = g.spawn_enemy("defence_profession_"+str(i),kinds[i],centre+Vector2(-3+i*3,-9-i))
				enemy.position.y = floor_y+0.1
				enemy.home = enemy.position
			await g.get_tree().physics_frame
			var start: float = g.state.elapsed
			var casts := 0
			var retreat_steps := 0
			while g.enemies.any(func(e): return not e.dead) and g.state.deaths==0 and g.state.elapsed-start<150:
				var target: Node = null
				var distance := 999.0
				for enemy in g.enemies:
					if not enemy.dead and g.player.position.distance_to(enemy.position)<distance:
						target = enemy
						distance = g.player.position.distance_to(enemy.position)
				if target==null: break
				# Both aim at actual collider space; caster attacks still use physics.
				aim(g,target)
				if encounter=="empty-mana": g.state.mana = 0
				if profession=="mage":
					if distance<5 and g.state.ability_cooldowns.defensive<=0: g.combat.defend()
					if encounter!="empty-mana" and target.brittle<=0 and g.state.ability_cooldowns.secondary<=0 and g.state.mana>=12 and g.attack_clock<=0:
						g.use_ability(true); casts += 1
					elif encounter!="empty-mana" and target.brittle<=0 and g.state.ability_cooldowns.primary<=0 and g.state.mana>=16 and g.attack_clock<=0:
						g.use_ability(false); casts += 1
					else: g.attack()
					# Physical kiting with collision, bounded inside the common arena.
					if distance<9:
						var escape: Vector3 = (g.player.position-target.position).normalized()
						escape.y = 0
						var candidate: Vector3 = g.player.position+escape*3.8/60.0
						if Vector2(candidate.x-centre.x,candidate.z-centre.y).length()<16:
							g.player.move_and_collide(escape*3.8/60.0)
							retreat_steps += 1
				else:
					if encounter!="empty-mana" and g.state.health<85 and g.state.ability_cooldowns.secondary<=0 and g.state.mana>=24 and g.attack_clock<=0:
						g.use_ability(true); casts += 1
					if distance<4.5 and g.state.ability_cooldowns.defensive<=0 and g.state.mana>=10: g.combat.defend()
					if encounter!="empty-mana" and distance<9 and g.state.ability_cooldowns.primary<=0 and g.state.mana>=14 and g.attack_clock<=0:
						g.use_ability(false); casts += 1
					elif distance<3.5: g.attack()
					if distance>2.7:
						var approach: Vector3 = (target.position-g.player.position).normalized()
						approach.y = 0
						g.player.move_and_collide(approach*3.2/60.0)
				await g.get_tree().physics_frame
			var won: bool = g.enemies.all(func(e): return e.dead) and g.state.deaths==0
			outcomes.append({"profession":profession,"encounter":encounter,"won":won,"health":g.state.health,"seconds":g.state.elapsed-start,"casts":casts,"retreat_steps":retreat_steps})
			print("ENCOUNTER ",outcomes.back())
			var file := FileAccess.open(g.data_root().path_join("reports/profession-encounters.json"),FileAccess.WRITE)
			file.store_string(JSON.stringify(outcomes,"\t")); file.close()
			assert(won,"Solo acceptance encounter failed: "+profession+" / "+encounter)
	print("PROFESSION ENCOUNTERS PASS: both casters solo against three living enemies, three night Abyss creatures, displacement-resistant boss and zero-mana fallback, without tonic rescue; real enemy AI and projectile physics")
	g.get_tree().quit()

func visual_review(g: Node) -> void:
	assert(ProjectSettings.get_setting("application/boot_splash/show_image")==false)
	for mode in [-1,1,6]:
		g.visuals.values.enabled = mode>=0
		g.visuals.values.preset = maxi(mode,0)
		g.ui.apply_visuals()
		for kind in ["dart","ember","rime","rebuke"]:
			g.start_new(profile("cleric" if kind=="rebuke" else "mage"))
			clear_enemies(g)
			g.teleport(Vector2(-3,43),0.6)
			g.state.day_clock = 14.5
			if kind=="rebuke": g.combat.defend()
			else:
				g.combat.launch(kind)
				g.combat.animate(kind)
			g.combat.tick(.12 if kind=="rebuke" else .08)
			g.swing = g.swing_duration*.55
			g.ui.tick(0)
			assert(g.combat.visual_clock>0 and g.ui.casting_glyph.visible)
			if kind=="rebuke":
				assert(g.combat.fx.any(func(effect): return effect.get("mode","")=="wave"))
			else:
				assert(g.combat.projectiles.size()==1 and g.combat.projectiles[0].node.get_child_count()>5)
			await g.capture("11-vfx-%s-%d" % [kind,mode])
			if kind!="rebuke":
				g.combat.reset()
				g.combat.impact(kind,null,g.camera.global_position-g.camera.global_basis.z*4)
				g.combat.tick(.1)
				await g.capture("11-impact-%s-%d" % [kind,mode])
			var frozen: float = g.combat.visual_clock
			g.open_report()
			await g.get_tree().create_timer(.05).timeout
			assert(g.combat.visual_clock==frozen)
			g.close_report()
	g.combat.tick(2)
	assert(g.combat.fx.is_empty() and g.combat.projectiles.is_empty())
