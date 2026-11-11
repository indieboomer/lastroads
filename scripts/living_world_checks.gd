extends RefCounted
const Data = preload("res://scripts/character_data.gd")

func run(g: Node) -> void:
	g.set_physics_process(false)
	g.ui.open_creator()
	assert(g.ui.creator.gender.item_count==2)
	for origin in range(Data.ORIGINS.size()):
		g.ui.creator.origin.select(origin)
		for gender in range(2):
			g.ui.creator.gender.select(gender)
			g.ui.creator.gender.item_selected.emit(gender)
			var profile: Dictionary = g.ui.creator.profile()
			assert(Data.valid(profile) and profile.presentation==gender)
			var image: AtlasTexture = g.ui.creator.portrait.texture
			assert(image.region.position.y==gender*image.region.size.y)
		var selected: Dictionary = g.ui.creator.profile()
		g.start_new(selected)
		var size: Dictionary = Data.stature(selected.species_id)
		assert(is_equal_approx(g.eye_height,size.eye) and is_equal_approx(g.camera.position.y,size.eye))
		assert(is_equal_approx(g.player_collision.shape.height,size.body) and size.eye<size.body)
		assert(g.save_game() and g.load_game())
		assert(is_equal_approx(g.eye_height,size.eye) and is_equal_approx(g.camera.position.y,size.eye))
		if selected.species_id in ["human","dwarf","ogre"]:
			g.teleport(Vector2(0,40))
			g.player.position.y = g.C.height_at(0,40)
			g.camera.rotation.x = 0
			await g.capture("08-camera-"+selected.species_id)
	var old := Data.defaults()
	old.gender = "nonbinary"
	old.presentation = 1
	assert(not Data.valid(old) and Data.migrate_profile(old).gender=="woman")
	old.gender = "man"
	assert(Data.migrate_profile(old).presentation==0)
	g.start_new()
	g.teleport(Vector2(0,-40))
	var life: Node3D = g.world.ambient
	life.reset()
	life.tick(.1)
	life.spawn_flock()
	life.tick(.1)
	assert(life.summary().birds>=10)
	# Controlled resting flock: approaching player flushes the entire group.
	for index in range(3):
		life.birds[index].mode = "rest"
		life.birds[index].group = 999
		life.birds[index].p = g.C.ground(Vector2(index*.3,-44),.06)
		life.birds[index].age = 0.0
		life.birds[index].ttl = 30.0
	life.tick(.1)
	for index in range(3): assert(life.birds[index].mode=="escape")
	assert(life.flushes>=1)
	# A living creature also scatters birds independently of player distance.
	g.teleport(Vector2(0,-20))
	var creature: Node = g.spawn_enemy("ambient-scatter-check","wolf",Vector2(3,-44))
	life.birds[0].mode = "rest"
	life.birds[0].group = 1000
	life.birds[0].p = g.C.ground(Vector2(0,-44),.06)
	life.birds[0].age = 0.0
	life.tick(.1)
	assert(life.birds[0].mode=="escape")
	creature.dead = true
	creature.collision_layer = 0
	g.teleport(Vector2(0,-40))
	g.state.weather.rain = 0
	g.state.weather.wind = .3
	for count in range(50): life.tick(.1)
	assert(life.summary().insect_clouds>0 and life.summary().leaves>0)
	assert(life.birds.size()==40 and life.leaves.size()==40 and life.clouds.size()==3)
	assert(life.get_children().all(func(node): return node is MultiMeshInstance3D or node==life.deer.view))
	g.state.weather.rain = 1
	life.tick(.1)
	assert(not life.insect_view.visible)
	g.visuals.values.wind_strength = 0
	life.tick(.1)
	assert(not life.leaf_view.visible)
	g.visuals.values.wind_strength = 2
	var before: Dictionary = life.summary()
	g.open_report()
	life.tick(30)
	assert(life.summary()==before and g.report_snapshot.ambient_life.interactive==false)
	g.close_report()
	g.set_modal("pause")
	life.tick(30)
	assert(life.summary()==before)
	g.set_modal("")
	g.teleport(Vector2(130,-390))
	life.tick(.1)
	assert(not life.visible)
	g.teleport(Vector2(-14,30))
	life.tick(.1)
	assert(not life.visible)
	# A close, outdoor review of the actual mesh/wing animation.
	g.teleport(Vector2(0,-40))
	g.camera.rotation.x = -.12
	g.state.weather.rain = 0
	for index in range(6):
		life.birds[index].mode = "flight"
		life.birds[index].p = g.C.ground(Vector2(-2+index*.8,-48-index*.6),3.5+index*.12)
		life.birds[index].v = Vector3(1,0,-.2)
		life.birds[index].age = 0.0
		life.birds[index].ttl = 30.0
	life.tick(.01)
	g.world.tick(0)
	await g.capture("08-living-world")
	await deer_review(g)
	assert(g.snapshot().player.eye_height==g.eye_height)
	# Race-sized bodies must still pass a small cottage and the crypt corridor.
	g.set_physics_process(true)
	for species in ["dwarf","ogre"]:
		var profile := Data.defaults()
		profile.origin_id = species
		profile.species_id = species
		profile.heritage_id = ""
		g.start_new(profile)
		for enemy in g.enemies:
			enemy.dead = true
			enemy.collision_layer = 0
		g.route_active = true
		Engine.time_scale = 6.0
		g.teleport(Vector2(16,29))
		g.route_goal = Vector2(16,29)
		assert(await g.route_walk([Vector2(16,28),Vector2(16,24),Vector2(16,21),Vector2(16,28)]))
		g.teleport(Vector2(130,-369))
		g.route_goal = Vector2(130,-369)
		assert(await g.route_walk([Vector2(130,-392),Vector2(116,-394),Vector2(130,-394)]))
		g.route_active = false
	Engine.time_scale = 1.0
	print("LIVING PASS: two gender options/automatic matching portraits, all six race heights and capsules/save-load, legacy profile migration, bounded ambient flocks/ground birds/insects/leaves, creature and player scatter, weather/wind filtering, indoor/crypt exclusion, paused field notes and camera/rendered captures")
	g.get_tree().quit()

func deer_review(g: Node) -> void:
	var deer = g.world.ambient.deer
	deer.reset()
	g.set_modal("")
	g.get_tree().paused = true
	var found := false
	for p in [Vector2(-30,-35),Vector2(40,-110),Vector2(-120,-80),Vector2(70,-245),Vector2(-90,-720),Vector2(65,-820)]:
		g.teleport(p,0)
		g.camera.rotation.x = -.05
		if deer.spawn():
			found = true
			break
	assert(found,"Visible deer runs must be possible in authored forest clearings")
	assert(deer.view.get_child_count()==0 and deer.view is Sprite3D,"Wildlife has no body/hurtbox or interaction nodes")
	assert(not g.enemies.any(func(enemy): return enemy==deer.view))
	var before: Dictionary = g.state.inventory.duplicate(true)
	var xp: int = g.state.xp
	deer.tick(.7)
	var initial: Vector3 = deer.view.position
	var texture: Texture2D = deer.view.texture
	deer.tick(.15)
	assert(initial.distance_to(deer.view.position)>.8 and texture!=deer.view.texture,"Deer travels and cycles gallop poses")
	assert(g.camera.is_position_in_frustum(deer.view.global_position),"Wildlife must be visible in the current camera")
	var frozen: Dictionary = deer.summary()
	g.set_modal("pause")
	deer.tick(10)
	assert(deer.summary()==frozen)
	g.set_modal("")
	g.world.tick(0)
	g.camera.look_at(deer.view.global_position,Vector3.UP)
	for retro in [false,true]:
		g.visuals.values.enabled = retro
		g.visuals.values.preset = 1
		g.ui.apply_visuals()
		await g.capture("23-deer-"+("copper" if retro else "original"))
	for i in range(220): deer.tick(.05)
	assert(not deer.active and deer.path_length>50 and not deer.view.visible)
	assert(g.state.inventory==before and g.state.xp==xp,"Cosmetic deer cannot yield hunting rewards")
	assert(g.snapshot().ambient_life.deer.huntable==false)
	print("DEER PASS: visible forest run, gallop, 50m+ travel, no hunt/interaction/reward, pause, bounded lifetime and two rendered styles")
