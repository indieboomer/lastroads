extends RefCounted

func run(g: Node) -> void:
	g.start_new(preload("res://scripts/character_data.gd").defaults())
	g.set_physics_process(false)
	g.set_modal("pause")
	var session = g.coop
	assert(not session.active and session.MAX_PLAYERS==4)
	assert(session.prepare("host_lan",g.state.profile,"#ffffff")==ERR_INVALID_PARAMETER)
	assert(not session.active)
	var pose: Dictionary = session.local_pose()
	assert(session.valid_pose(pose))
	assert(pose.motion=="idle","Opening a menu must not send a kneeling action pose")
	for bad in [NAN,INF,-INF]:
		var broken: Dictionary = pose.duplicate(true)
		broken.p[0] = bad
		assert(not session.valid_pose(broken))
	var broken: Dictionary = pose.duplicate(true)
	broken.p = [0,0]
	assert(not session.valid_pose(broken))
	broken = pose.duplicate(true)
	broken.motion = "arbitrary_action"
	assert(not session.valid_pose(broken))
	var count := 0
	for origin in g.coop.Data.ORIGINS:
		for profession in g.coop.Data.PROFESSIONS:
			var path: String = "res://assets/coop/ready/"+origin.id+"-"+profession.id+".png"
			assert(ResourceLoader.exists(path),path)
			var texture: Texture2D = load(path)
			var image: Image = texture.get_image()
			assert(image.get_width()%4==0 and image.get_height()%6==0 and image.get_pixel(0,0).a==0)
			for row in range(6):
				for column in range(4):
					var cell := image.get_region(Rect2i(column*image.get_width()/4,row*image.get_height()/6,image.get_width()/4,image.get_height()/6))
					assert(not cell.is_invisible(),"All six animation states contain four frames")
			count += 1
	assert(count==24)
	for origin in session.Data.ORIGINS:
		for profession in session.Data.PROFESSIONS:
			var female: Dictionary = session.Data.defaults()
			female.origin_id = origin.id; female.profession_id = profession.id; female.gender = "woman"
			var path: String = session.Data.body_path(female)
			assert(path.contains("/female/") and ResourceLoader.exists(path))
			var sheet: Texture2D = load(path)
			var image: Image = sheet.get_image()
			assert(image.get_width()%4==0 and image.get_height()%6==0 and image.get_pixel(0,0).a==0)
			for row in range(6):
				for column in range(4):
					var cell := image.get_region(Rect2i(column*image.get_width()/4,row*image.get_height()/6,image.get_width()/4,image.get_height()/6))
					assert(not cell.is_invisible(),path+" empty female animation")
			count += 1
	assert(count==48)
	# Four visible class/race combinations and recognition colors.
	var actors: Array = []
	for index in range(4):
		var profile: Dictionary = session.Data.defaults()
		var origin: Dictionary = session.Data.ORIGINS[[0,1,3,5][index]]
		profile.origin_id = origin.id; profile.species_id = origin.species; profile.heritage_id = origin.heritage
		profile.profession_id = session.Data.PROFESSIONS[index].id
		if index%2==1: profile.gender = "woman"; profile.presentation = 1
		var actor = session.Avatar.new()
		g.add_child(actor)
		actor.setup({"profile":profile,"nickname":["Host / sword","Friend / magic","Friend / faith","Steam nickname / powder"][index],"color":session.COLORS[index]})
		actor.accept_pose({"p":[-5.0+index*2.6,g.C.height_at(-5.0+index*2.6,34.0),34.0],"yaw":0.0,"pitch":0.0,"motion":"idle"},true)
		assert(actor.sprite.texture!=null and actor.nameplate.text.length()>0)
		actors.append(actor)
	g.teleport(Vector2(0,43),0)
	g.camera.look_at(g.C.ground(Vector2(0,34),1.4),Vector3.UP)
	g.set_modal("")
	g.set_physics_process(false)
	await g.capture("28-coop-party")
	for row in range(6):
		for actor in actors: actor.motion = session.Avatar.STATES[row]
		await g.get_tree().process_frame
		await g.capture("28-coop-"+session.Avatar.STATES[row])
	for actor in actors: actor.queue_free()
	assert(g.save_path()==g.data_root().path_join("reports/integration-save.json"),"Solo save destination remains unchanged")
	assert(session.prepare("host_lan",session.Data.defaults(),session.COLORS[0],"127.0.0.1",31441)==OK)
	g.set_physics_process(false)
	var guest: Dictionary = session.Data.defaults()
	guest.name = "Protocol guest"
	var hello := {"profile":guest,"color":session.COLORS[1],"build":g.C.BUILD,"layout":g.C.LAYOUT}
	session._hello(2002,hello)
	assert(session.roster.size()==2)
	session._hello(2003,hello)
	assert(session.roster.size()==2,"Duplicate recognition colors are rejected")
	hello.color = session.COLORS[2]
	hello.build = "incompatible"
	session._hello(2004,hello)
	assert(session.roster.size()==2,"Build mismatch is rejected")
	hello.build = g.C.BUILD
	hello.profile = guest.duplicate(true)
	hello.profile.profession_id = "cleric"
	session._hello(2005,hello)
	assert(session.roster.size()==3)
	session.poses[2005].sanctuary = {"position":[g.player.position.x,g.player.position.y,g.player.position.z],"left":8.0}
	assert(session.ally_protected_at(g.player.position) and g.combat.protected_at(g.player.position),"Cleric sanctuary protects teammates")
	g.state.health = 40
	session._process(.25)
	assert(g.state.health>40,"Ally sanctuary heals without stacking")
	hello.color = session.COLORS[3]
	session._hello(2006,hello)
	assert(session.roster.size()==4)
	hello.color = session.COLORS[4]
	session._hello(2007,hello)
	assert(session.roster.size()==4,"Fifth player is refused by the session protocol too")
	assert(g.save_path().contains("reports/coop/") and not g.save_path().ends_with("hollow-valley.json"))
	session.disconnect_session("Protocol and sanctuary checks complete.")
	g.ui.coop_menu.open()
	await g.capture("28-coop-menu")
	g.ui.coop_menu.choose_character("host_lan")
	assert(g.ui.creator.recognition_color.visible)
	await g.capture("28-coop-character-color")
	g.ui.creator.gender.selected = 1
	g.ui.creator.refresh()
	assert((g.ui.creator.portrait.texture as AtlasTexture).atlas.resource_path.contains("/female/"))
	await g.capture("31-coop-female-character")
	await female_gallery(g)
	g.ui.open_creator()
	assert(g.ui.creator.coop_mode=="" and not g.ui.creator.recognition_color.visible)
	assert(not g.ui.creator.portrait.texture is AtlasTexture or not (g.ui.creator.portrait.texture as AtlasTexture).atlas.resource_path.contains("/coop/"),"Solo creator must refresh its portrait after leaving co-op")
	print("COOP PASS: four-player cap, duplicate color/build rejection, 48 sheets / 1152 frames / six states / alpha, gender-specific bodies and creator preview, overhead names/color shader, malformed poses rejected, ally sanctuary healing/protection, co-op entry/creator UI, solo save isolation")
	g.get_tree().quit()

func female_gallery(g: Node) -> void:
	var gallery := Control.new()
	g.ui.add_child(gallery)
	var background := ColorRect.new()
	background.size = Vector2(1280,720)
	background.color = Color("162224")
	gallery.add_child(background)
	g.ui.label("FEMALE TRAVELLERS / SIX ORIGINS, FOUR PROFESSIONS",Vector2(24,14),24,gallery,true)
	for column in range(6):
		var origin: Dictionary = g.coop.Data.ORIGINS[column]
		g.ui.label(origin.name,Vector2(24+column*208,52),16,gallery)
		for row in range(4):
			var profile: Dictionary = g.coop.Data.defaults()
			profile.gender = "woman"; profile.origin_id = origin.id
			profile.profession_id = g.coop.Data.PROFESSIONS[row].id
			var sheet: Texture2D = load(g.coop.Data.body_path(profile))
			var cell := AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(0,0,sheet.get_width()/4.,sheet.get_height()/6.)
			var portrait := TextureRect.new()
			portrait.texture = cell
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.position = Vector2(24+column*208,78+row*156)
			portrait.size = Vector2(180,130)
			gallery.add_child(portrait)
			g.ui.label(profile.profession_id.capitalize(),portrait.position+Vector2(28,130),15,gallery)
	await g.capture("31-coop-female-gallery")
	gallery.queue_free()
