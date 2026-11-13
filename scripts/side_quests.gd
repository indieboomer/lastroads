extends RefCounted

const N = preload("res://scripts/narrative.gd")
var game: Node
var active_id := ""
const DIRECTIONS := {
	"names":"Search the charcoal clearings far west of the Fallen Toll and the mill road.",
	"debt":"Search west of the Widow's Mill, then the western edge of Lantern Fen.",
	"mercy":"Search the old trapping ground west of Foxglove Grove.",
	"boots":"Search the woods east of the inn, north of the chapel turning.",
	"bell":"Search east of the Fallen Toll, north of the chapel road.",
	"ribbon":"Search southwest of the Fallen Toll, then west toward the mill turning.",
	"oath":"Search south of the chapel road, between the chapel and Northwatch's eastern approach.",
	"spoons":"Search the woods west of the northbound road beyond Lantern Fen.",
	"dowry":"Search beyond the King's Cairn, in the far eastern woods. This is a long, dangerous detour."
}
const QUESTS := {
	"names":{"title": "Names Under the Charcoal", "npc": "sister", "intro": "The charcoal burners were buried as thieves. Elian suspects their employer withheld wages, then paid soldiers to silence them.", "a": "Publish their names and wage claims.", "b": "Bury the record with the dead.", "clues": ["A wage book lists deductions for tools the workers never received.", "A burial tally calls the same workers armed thieves. One hand has corrected the names."], "endings": ["Elian reads every name aloud. The chapel becomes a place to bring wage claims.", "Elian seals the book beneath a marker. The families can mourn privately, but the employer keeps his reputation."], "loot": "amber", "xp": 55},
	"debt":{"title": "The Price of Winter", "npc": "rook", "intro": "Rook took grain from a widow to feed deserters. Her sealed pantry account may show whether hunger excused what he did.", "a": "Return the grain money to the widow.", "b": "Fund a shared winter pantry.", "clues": ["An empty grain chest holds a receipt signed under threat.", "A soldier's ration list includes children and wounded enemies."], "endings": ["Rook sends restitution and admits the theft without calling it a requisition.", "Rook opens a pantry with no uniforms at the door. The widow receives the first share, but no apology erases the threat."], "loot": "salt", "xp": 60},
	"mercy":{"title": "A Measured Mercy", "npc": "vesna", "intro": "A dying trapper asked Vesna for pain relief. His family accused her of poisoning him. His notes remain beyond the grove.", "a": "Give the family the full account.", "b": "Keep his last words private.", "clues": ["The trapper records his own doses and begs to remain awake for one last dawn.", "An unused vial rests beside a final note: the fever took him before the next dose."], "endings": ["Vesna lets the family read the notes. Their grief finds no easy culprit.", "Vesna keeps his words in confidence. She accepts that some neighbours will never forgive what they do not understand."], "loot": "salt", "xp": 45},
	"boots":{"title": "The Captain of Both Boots", "npc": "osric", "intro": "A drunken militia quartermaster promoted his left boot for bravery and dismissed the right for desertion. Osric wants the pair back before the man orders a court martial.", "a": "Return both boots with the true report.", "b": "Invent an honourable reconciliation.", "clues": ["The left boot stands on a stump with a medal made from a spoon.", "The right boot is in a badger hole. A notice offers it safe conduct."], "endings": ["Osric laughs until he has to sit down. The captain blames the spoon.", "Osric writes that both boots served with distinction. Their owner demands back pay for each."], "loot": "amber", "xp": 35},
	"bell":{"title": "A Bell for the Living", "npc": "mara", "intro": "A warning bell was sold as scrap while fever spread. Mara wants to know whether the watch was bribed or simply abandoned.", "a": "Expose the watch ledger.", "b": "Use the evidence to demand a new alarm.", "clues": ["A watch ledger shows wages unpaid for eleven weeks.", "A scrap receipt paid for medicine, not drink. The bell still bears a watchman's name."], "endings": ["Mara posts both records together. Neglect and desperation appear in the same ink.", "Mara wins a promise of a new alarm and paid watches. The old bell's silence remains on nobody's official record."], "loot": "wire", "xp": 50},
	"ribbon":{"title": "Where the Ribbon Went", "npc": "pip", "intro": "Pip, eleven, lent a ribbon to a parent who never returned from the logging camp. Pip asks you to look, but will stay safely at the inn with Mara.", "a": "Tell Pip the truth gently, with Mara present.", "b": "Give Mara the account to explain in her own time.", "clues": ["A blue ribbon marks an evacuation route away from the collapsed camp.", "A rescuer's note says Pip's parent died guiding others out. A carved wooden bird was saved for Pip."], "endings": ["Mara sits beside Pip as you explain. Pip keeps the bird and asks that the rescued people remember the name.", "Mara takes the note and bird. She promises to answer honestly when Pip asks, and makes room by the hearth."], "loot": "wire", "xp": 40},
	"oath":{"title": "An Oath in the Moss", "npc": "ilya", "intro": "An army medic hid wounded deserters in the woods. Ilya wants their route found before bounty hunters do.", "a": "Erase the trail and protect the survivors.", "b": "Copy the testimony for a public hearing.", "clues": ["A medical roll lists enemy and friendly casualties together, all treated alike.", "A hidden shelter contains a departure note. The survivors left voluntarily; no prisoners were held."], "endings": ["Ilya removes the route markings. The survivors lose their chance to testify safely, but gain time to disappear.", "Ilya copies the testimony without the shelter coordinates. Naming the officers may still put the medic at risk."], "loot": "salt", "xp": 65},
	"spoons":{"title": "The Saint of Stolen Spoons", "npc": "courier", "intro": "Tomas has been accused of stealing every spoon on his route. His chief suspect is a saint, because nobody will arrest one.", "a": "Return the spoons and clear Tomas.", "b": "Leave a spoon shrine and tell the joke.", "clues": ["A magpie nest glitters with spoons. One bears the chapel's inventory number.", "A pilgrim's diary thanks a bird for a silver miracle, then complains that the saint took his cutlery."], "endings": ["Tomas ties the spoons to his bag. For once people are pleased to hear him coming.", "Tomas calls it the Shrine of Our Lady of Minor Inconvenience. Pilgrims bring wooden spoons from then on."], "loot": "amber", "xp": 45},
	"dowry":{"title": "What Was Never Yours", "npc": "merchant", "intro": "Adela once carried a marriage payment for a woman who fled before the wedding. The family now wants the money and her whereabouts.", "a": "Return the property to the woman through Adela.", "b": "Place it in a refuge fund at her request.", "clues": ["A locked travel case holds a marriage contract signed only by the two fathers.", "A letter authorizes Adela to return the woman's own savings or donate them to shelter other fugitives. It gives no address."], "endings": ["Adela arranges a private collection. She tells the family only that the contract bought them no claim to a person.", "Adela follows the letter's second instruction. The refuge buys locks that work from the inside."], "loot": "wire", "xp": 75},
}

static func register(objects: Dictionary, npcs: Dictionary, heights: Dictionary) -> void:
	npcs.pip = {"name":"Pip","role":"Child, age 11 / Wayfarer's Rest","age":11,"minor":true,"cell":0,"pos":Vector2(-13,35)}
	heights.pip = 1.30

	objects["side_names_0"] = {"name":"Names Under the Charcoal / first trace","kind":"sidequest","pos":Vector2(-164, -110),"cell":6}
	objects["side_names_1"] = {"name":"Names Under the Charcoal / second trace","kind":"sidequest","pos":Vector2(-188, -154),"cell":6}
	objects["side_debt_0"] = {"name":"The Price of Winter / first trace","kind":"sidequest","pos":Vector2(-170, -205),"cell":6}
	objects["side_debt_1"] = {"name":"The Price of Winter / second trace","kind":"sidequest","pos":Vector2(-192, -238),"cell":6}
	objects["side_mercy_0"] = {"name":"A Measured Mercy / first trace","kind":"sidequest","pos":Vector2(-137, -54),"cell":6}
	objects["side_mercy_1"] = {"name":"A Measured Mercy / second trace","kind":"sidequest","pos":Vector2(-158, -82),"cell":6}
	objects["side_boots_0"] = {"name":"The Captain of Both Boots / first trace","kind":"sidequest","pos":Vector2(66, -58),"cell":6}
	objects["side_boots_1"] = {"name":"The Captain of Both Boots / second trace","kind":"sidequest","pos":Vector2(94, -87),"cell":6}
	objects["side_bell_0"] = {"name":"A Bell for the Living / first trace","kind":"sidequest","pos":Vector2(55, -126),"cell":6}
	objects["side_bell_1"] = {"name":"A Bell for the Living / second trace","kind":"sidequest","pos":Vector2(84, -112),"cell":6}
	objects["side_ribbon_0"] = {"name":"Where the Ribbon Went / first trace","kind":"sidequest","pos":Vector2(-54, -101),"cell":6}
	objects["side_ribbon_1"] = {"name":"Where the Ribbon Went / second trace","kind":"sidequest","pos":Vector2(-118, -113),"cell":6}
	objects["side_oath_0"] = {"name":"An Oath in the Moss / first trace","kind":"sidequest","pos":Vector2(66, -245),"cell":6}
	objects["side_oath_1"] = {"name":"An Oath in the Moss / second trace","kind":"sidequest","pos":Vector2(104, -260),"cell":6}
	objects["side_spoons_0"] = {"name":"The Saint of Stolen Spoons / first trace","kind":"sidequest","pos":Vector2(-164, -277),"cell":6}
	objects["side_spoons_1"] = {"name":"The Saint of Stolen Spoons / second trace","kind":"sidequest","pos":Vector2(-182, -300),"cell":6}
	objects["side_dowry_0"] = {"name":"What Was Never Yours / first trace","kind":"sidequest","pos":Vector2(198, -267),"cell":6}
	objects["side_dowry_1"] = {"name":"What Was Never Yours / second trace","kind":"sidequest","pos":Vector2(223, -292),"cell":6}

func marked(key: String) -> bool:
	return game.state.taken.get("side:"+key,false)

func mark(key: String) -> void:
	game.state.taken["side:"+key] = true

func show_page(body: String, choices: Array) -> void:
	game.ui.show_dialog(game.dialogue_id,N.page(body,choices))

func dialogue_choices(id: String, page: Dictionary) -> Dictionary:
	if not active_id.is_empty(): return page
	if not QUESTS.values().any(func(q): return q.npc==id) and id!="mara": return page
	for option in page.choices:
		if option.action.begins_with("side:"): return page
	var options: Array = page.choices.duplicate(true)
	options.append(N.choice("What else is happening?","side:menu"))
	return N.page(page.body,options)

func menu() -> void:
	active_id = ""
	var choices: Array = []
	for id in QUESTS:
		if QUESTS[id].npc==game.dialogue_id or game.dialogue_id=="mara" and id=="ribbon":
			choices.append(N.choice(QUESTS[id].title,"side:open:"+id))
	choices.append(N.choice("Back to our conversation.","return"))
	show_page("There are a few things you could help with. What would you like to talk about?",choices)

func at_contact(id: String) -> bool:
	var contact: String = "mara" if id=="ribbon" and game.dialogue_id=="mara" else QUESTS[id].npc
	return game.player.position.distance_to(game.world.npcs[contact].position)<8.0

func open_quest(id: String) -> void:
	active_id = id
	var q: Dictionary = QUESTS[id]
	mark(id+":known")
	if marked(id+":done"):
		show_page(q.endings[1 if marked(id+":choice_b") else 0],[N.choice("Until later.","leave")])
		return
	var body: String = q.intro+"\n\n"+DIRECTIONS[id]
	var complete := true
	for i in range(2):
		var object_id := "side_"+id+"_"+str(i)
		var pos: Vector2 = game.C.OBJECTS[object_id].pos
		if marked(id+":"+str(i)): body += "\n\n"+q.clues[i]
		else:
			complete = false
			body += "\n\nSearch off the road near east %d / north %d. Watch for woodland predators; retreat and return if outmatched." % [int(pos.x),int(-pos.y)]
	var choices: Array = []
	if complete and at_contact(id):
		choices = [N.choice(q.a,"side:resolve:"+id+":a"),N.choice(q.b,"side:resolve:"+id+":b")]
	elif complete: body += "\n\nBring the account to "+game.C.NPCS[q.npc].name+" to decide what happens next."
	else: body += "\n\nBoth traces can be found in either order. Discuss them with "+game.C.NPCS[q.npc].name+"."
	choices.append(N.choice("Track this story in my journal.","side:track:"+id))
	choices.append(N.choice("Back to our conversation.","return"))
	show_page(body,choices)

func interact(object_id: String) -> void:
	var parts := object_id.split("_")
	var id: String = parts[1]
	var q: Dictionary = QUESTS[id]
	if marked(id+":"+parts[2]):
		game.message(q.clues[int(parts[2])]+" Already recorded in your journal.",8)
		return
	var loot: String = q.loot
	game.state.inventory[loot] = game.state.inventory.get(loot,0)+1
	game.state.pack.sync(game.state.inventory)
	mark(id+":"+parts[2])
	mark(id+":known")
	game.state.log_event("side_evidence:"+object_id)
	var count := int(marked(id+":0"))+int(marked(id+":1"))
	var next: String = "Find the remaining trace." if count<2 else "Return to "+game.C.NPCS[q.npc].name+" to discuss the evidence."
	game.ui.pending_quest_updates.append({"title":"QUEST STAGE COMPLETE / %d/2" % count,"detail":q.title+"\n"+q.clues[int(parts[2])]+"\n"+next})
	game.message("Recovered: "+game.state.pack.details(loot).name+". Journal updated.",6)

func choose(action: String) -> void:
	var parts := action.split(":")
	if parts.size()<2: return
	if parts[1]=="menu": menu()
	elif parts[1]=="track" and parts.size()==3 and QUESTS.has(parts[2]):
		var id: String = parts[2]
		if not marked(id+":known") or marked(id+":done"): return
		game.state.tracked_side = id
		game.set_modal("")
		game.message("Tracking / "+QUESTS[id].title+". Both traces are marked in the journal map.",7)
	elif parts[1]=="open" and QUESTS.has(parts[2]): open_quest(parts[2])
	elif parts[1]=="resolve" and parts.size()==4 and QUESTS.has(parts[2]):
		var id: String = parts[2]
		var q: Dictionary = QUESTS[id]
		if (game.dialogue_id!=q.npc and not (id=="ribbon" and game.dialogue_id=="mara")) or not at_contact(id) or marked(id+":done") or not marked(id+":0") or not marked(id+":1"): return
		mark(id+":done")
		if game.state.tracked_side==id: game.state.tracked_side = ""
		if parts[3]=="b": mark(id+":choice_b")
		game.state.inventory.gold += 8
		game.quest_reward(q.title,q.xp)
		game.state.pack.sync(game.state.inventory)
		show_page(q.endings[1 if parts[3]=="b" else 0]+"\n\nReward: %d experience and 8 coins. Keep or sell the curios you recovered." % q.xp,[N.choice("Back to the road.","leave")])

func objective(id: String) -> Dictionary:
	if not QUESTS.has(id) or not marked(id+":known") or marked(id+":done"): return {}
	if game.in_crypt():
		return {"text":"Return to daylight to continue "+QUESTS[id].title+".","pos":game.C.OBJECTS.crypt_exit.pos}
	var missing: Array[String] = []
	for i in range(2):
		if not marked(id+":"+str(i)): missing.append("side_"+id+"_"+str(i))
	if missing.is_empty():
		var npc: String = QUESTS[id].npc
		if npc=="merchant" and not game.state.flags.won:
			var main: Dictionary = game.main_target().duplicate()
			main.text = "Adela needs Northwatch restored first. "+main.text
			return main
		var at: Vector3 = game.world.npcs[npc].position
		return {"text":"Return to "+game.C.NPCS[npc].name+" with both traces.","pos":Vector2(at.x,at.z)}
	var player_at := Vector2(game.player.position.x,game.player.position.z)
	missing.sort_custom(func(a,b): return player_at.distance_squared_to(game.C.OBJECTS[a].pos)<player_at.distance_squared_to(game.C.OBJECTS[b].pos))
	var next: String = missing[0]
	return {"text":"Find the next woodland trace. "+str(2-missing.size())+"/2 found.","pos":game.C.OBJECTS[next].pos}

func markers() -> Array:
	var id: String = game.state.tracked_side
	if not QUESTS.has(id) or not marked(id+":known") or marked(id+":done"): return []
	var result: Array = []
	for i in range(2): result.append({"pos":game.C.OBJECTS["side_"+id+"_"+str(i)].pos,"found":marked(id+":"+str(i))})
	return result

func tracked_journal() -> String:
	var id: String = game.state.tracked_side
	if objective(id).is_empty(): return ""
	var q: Dictionary = QUESTS[id]
	var text: String = "[color=#e2c38a]TRACKED / "+q.title+"[/color]\n"+objective(id).text+"\n\n"+q.intro+"\n\n"+DIRECTIONS[id]+"\n"
	for i in range(2):
		text += "\n"+("[found] "+q.clues[i] if marked(id+":"+str(i)) else "[open] Trace %d / still to find" % (i+1))+"\n"
	text += "\nBoth traces may be found in either order. The nearer missing trace is tracked; filled green map markers are already read. Once both are found, the marker follows the contact's current location.\n"
	return text

func journal() -> String:
	var text := "\n[color=#e2c38a]OFF THE ROAD[/color]\nExplore freely: each story has two traces, found in either order. Coordinates use east / north from the inn.\n"
	for id in QUESTS:
		var q: Dictionary = QUESTS[id]
		if not marked(id+":known"): continue
		text += q.title+" / "+game.C.NPCS[q.npc].name+" / "+("Complete" if marked(id+":done") else "Investigating")+"\n"
		if not marked(id+":done"): text += DIRECTIONS[id]+"\n"
		for i in range(2):
			var pos: Vector2 = game.C.OBJECTS["side_"+id+"_"+str(i)].pos
			text += "  "+("Found" if marked(id+":"+str(i)) else "Search")+" / E %d, N %d\n" % [int(pos.x),int(-pos.y)]
	return text
