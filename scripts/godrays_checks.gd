extends RefCounted

func run(g: Node) -> void:
	var Rays = preload("res://scripts/godrays.gd")
	assert(Rays.clear_strength(6.7,.05,0)>Rays.clear_strength(12,.05,0)*3)
	assert(Rays.clear_strength(17.3,.05,0)>Rays.clear_strength(12,.05,0)*3)
	for hour in [0.0,3.0,21.0,23.0]: assert(Rays.clear_strength(hour,.05,0)==0)
	assert(Rays.clear_strength(12,.48,0)==0 and Rays.clear_strength(12,.82,.48)==0)
	assert(Rays.solar_direction(6.7).x>0 and Rays.solar_direction(17.3).x<0)
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	g.set_physics_process(false)
	g.get_tree().paused = true
	g.ui.hud_root.hide()
	g.visuals.values.enabled = false
	g.ui.apply_visuals()
	g.teleport(Vector2(0,-35),0)
	g.stow_lights()
	g.weather.force("clear")
	g.weather.sheltered = false
	var rays: Node = g.weather.godrays
	for hour in [6.7,12.0,17.3]:
		g.state.day_clock = hour
		g.camera.look_at(g.camera.global_position+Rays.solar_direction(hour)*100,Vector3.UP)
		g.world.tick(0)
		g.weather.apply_visuals()
		rays.update_effect()
		assert(rays.visible and rays.intensity>0)
		await g.capture("29-godrays-"+str(hour))
		if hour==6.7:
			var lit: Image = g.get_viewport().get_texture().get_image()
			rays.set_process(false)
			rays.hide()
			await g.capture("29-godrays-dawn-off")
			var plain: Image = g.get_viewport().get_texture().get_image()
			var difference := 0.0
			for y in range(0,lit.get_height(),8):
				for x in range(0,lit.get_width(),8):
					var a := lit.get_pixel(x,y)
					var b := plain.get_pixel(x,y)
					difference += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
			assert(difference>1.0,"The compiled depth shader must visibly render shafts")
			rays.set_process(true)
			print("GODRAYS rendered dawn difference: ",difference)
	g.state.day_clock = 17.3
	g.camera.look_at(g.camera.global_position+Rays.solar_direction(17.3)*100,Vector3.UP)
	for kind in ["clouds","rain","storm"]:
		g.weather.force(kind)
		rays.update_effect()
		assert(not rays.visible)
	g.weather.force("clear")
	g.state.day_clock = 22
	rays.update_effect()
	assert(not rays.visible)
	g.state.day_clock = 6.7
	g.weather.sheltered = true
	rays.update_effect()
	assert(not rays.visible,"Roofs suppress light shafts")
	g.weather.sheltered = false
	g.teleport(Vector2(130,-390),0)
	rays.update_effect()
	assert(not rays.visible,"No outdoor shafts underground")
	g.teleport(Vector2(0,-35),0)
	g.state.day_clock = 17.3
	g.camera.look_at(g.camera.global_position+Rays.solar_direction(17.3)*100,Vector3.UP)
	g.visuals.values.enabled = true
	g.visuals.values.preset = 1
	g.ui.apply_visuals()
	g.world.tick(0)
	rays.update_effect()
	await g.capture("29-godrays-dusk-retro")
	g.camera.look_at(g.camera.global_position-Rays.solar_direction(17.3)*100,Vector3.UP)
	rays.update_effect()
	assert(not rays.visible,"Sun behind the camera costs no full-screen pass")
	print("GODRAYS PASS: visible depth-sampled shafts, sunrise/noon/sunset, stronger golden hours, cloudy/rain/storm/night/roof/crypt suppression, sun direction and rear-view culling, Original and Copper rendering")
	g.get_tree().quit()
