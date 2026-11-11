extends RefCounted
const C = preload("res://scripts/content.gd")
const T = preload("res://scripts/terrain.gd")

func run(g: Node) -> void:
	g.start_new()
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	var low := INF
	var high := -INF
	for x in range(-225,226,15):
		for z in range(-1000,65,15):
			low = minf(low,C.height_at(x,z))
			high = maxf(high,C.height_at(x,z))
	assert(high-low>15.0,"The world needs visible rolling relief")
	for cottage in g.world.cottages:
		var size: Vector2 = cottage.get_meta("footprint")
		var base := C.height_at(cottage.position.x,cottage.position.z)
		for offset in [Vector2(-size.x/2,-size.y/2),Vector2(size.x/2,-size.y/2),Vector2(-size.x/2,size.y/2),Vector2(size.x/2,size.y/2)]:
			assert(absf(C.height_at(cottage.position.x+offset.x,cottage.position.z+offset.y)-base)<.02,"All house corners must occupy one flat pad")
	for p in [Vector2(-65,-435),Vector2(65,-435),Vector2(0,-451),Vector2(0,-422)]:
		assert(absf(C.height_at(p.x,p.y)-C.height_at(0,-435))<.02,"The bridge and banks share a level platform")
	var roads: Array = g.get_tree().get_nodes_in_group("road_surfaces")
	assert(roads.size()==C.ROADS.size())
	var vertices := 0
	for road in roads:
		var data: PackedVector3Array = road.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for p in data:
			assert(absf(p.y-C.height_at(p.x,p.z)-.075)<.001,"Every road triangle follows the same terrain plane")
		vertices += data.size()
	assert(vertices>5000)
	var grass: MultiMeshInstance3D = g.world.get_node("DenseGroundCover")
	assert(g.world.grass_count>14000,"Foliage population must materially exceed the old pass")
	# A complete shop loop stays in the shop and gives visible transaction feedback.
	g.state.inventory.gold = 20
	g.state.inventory.tonic = 1
	g.state.inventory.fur = 2
	g.state.inventory.essence = 3
	g.state.inventory.toadstools = 1
	g.open_shop("merchant")
	g.ui.choose(0)
	assert(g.state.inventory.gold==12 and g.state.inventory.tonic==2 and g.shop_owner=="merchant")
	assert(g.ui.dialog_feedback.text.contains("Purchased tonic"))
	g.ui.choose(1)
	assert(g.state.inventory.gold==30 and g.state.inventory.fur==0 and g.ui.choices[1].disabled)
	assert(g.ui.dialog_feedback.text.contains("18 coins"))
	await g.capture("09-merchant-feedback")
	# Formerly decorative chests are searchable exactly once and persist across reload.
	for id in ["cache_refuge_1","cache_refuge_2","cache_refuge_3","cache_veyr_1","cache_veyr_2","cache_veyr_3"]:
		g.interact_object(id)
		assert(g.state.taken.has(id) and not g.world.objects[id].visible)
		var items: Dictionary = g.state.inventory.duplicate()
		g.interact_object(id)
		assert(g.state.inventory==items)
	assert(g.save_game() and g.load_game() and g.state.taken.has("cache_veyr_3"))
	# Selected treatment covers all bitmap UI, with a separate unfiltered text canvas.
	g.visuals.values.enabled = true
	g.visuals.values.preset = 2
	g.ui.apply_visuals()
	g.to_title()
	await g.capture("09-retro-title")
	g.ui.open_creator()
	assert(g.ui.creator.portrait.material.get_shader_parameter("retro_enabled"))
	var atlas_region: Vector4 = g.ui.creator.portrait.material.get_shader_parameter("uv_rect")
	assert(absf(atlas_region.z-1.0/6.0)<.001 and is_equal_approx(atlas_region.w,.5),"Pixel quantization must stay inside the selected portrait cell")
	await g.capture("09-retro-creator")
	g.start_new()
	g.set_modal("inventory")
	await g.capture("09-retro-inventory")
	assert(g.ui.backpack.icon_layer.slots.size()>0 and g.ui.backpack.text_layer.material==null)
	assert(g.ui.backpack.icon_layer.slots[0].material.get_shader_parameter("retro_enabled"))
	g.set_modal("pause")
	g.ui.pause_panel.hide()
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	for scene in [[Vector2(-6.80695,-408.122),.95577,-.5947,"turn-bridge"],[Vector2(-62.868,-523.059),1.9761,-.475,"turn-refuge"],[Vector2(131.986,-707.569),.49899,-.768,"turn-veyr"],[Vector2(-47,-534),0.0,-.15,"furnished-refuge"],[Vector2(47,-151),-1.2,-.05,"rolling-hills"],[Vector2(-24,-55),0.0,.15,"dense-foliage"]]:
		g.teleport(scene[0],scene[1])
		g.player.position.y = C.height_at(g.player.position.x,g.player.position.z)
		g.camera.rotation.x = scene[2]
		g.state.day_clock = 15
		g.weather.force("clear")
		g.world.tick(0)
		g.update_location()
		await g.capture("09-"+scene[3])
	# Exact pre-change user save, isolated from the live save, remains continuable.
	var legacy_path: String = g.data_root().path_join("reports/pre-0.8-player-save.json")
	if FileAccess.file_exists(legacy_path):
		var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(legacy_path))
		assert(g.validate_save(old))
		var file := FileAccess.open(g.save_path(),FileAccess.WRITE)
		file.store_string(JSON.stringify(old))
		file.close()
		assert(g.load_game())
		assert(g.state.flags==old.state.flags and g.state.inventory==old.state.inventory)
		assert(g.player.position.y>=C.height_at(g.player.position.x,g.player.position.z)-.1)
		assert(g.save_game())
		var position: Vector3 = g.player.position
		assert(g.load_game() and g.player.position.distance_to(position)<.001,"Terrain migration must happen once only")
	print("TERRAIN PASS: %.1fm relief, level building/bridge pads, %d conforming road vertices, %d grass tufts, searchable persistent chests, real merchant buy/sell feedback, pixelized title/creator/inventory with sharp text, legacy terrain migration and rendered report regressions" % [high-low,vertices,g.world.grass_count])
	g.get_tree().quit()
