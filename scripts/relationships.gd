extends RefCounted

# Authored adult preference, never a generated roll or an ancestry check.
const MARA := {"age":45,"gender":"woman","interested_in":["man","woman","nonbinary"],"location":"Wayfarer's Rest / the quiet back room"}
const N = preload("res://scripts/narrative.gd")
const Options = preload("res://scripts/romance_options.gd")
const GENERIC := ["osric","rook","ysabet","nera","courier","ilya","merchant"]
var game: Node
var phase := ""
var clock := 0.0
var committed := false
var relaxed := false
var active_id := "mara"

const QUESTIONS := {
	"mara":"Do you ever get an evening away from the accounts?",
	"osric":"What do you make when nobody is paying you?",
	"rook":"Who are you when the captain's coat comes off?",
	"lucan":"What keeps you company after the last crossing?",
	"ysabet":"What would you like to grow here next spring?",
	"nera":"Who looks after you when the work is over?",
	"courier":"Where would you go if you had no letters to carry?",
	"ilya":"Do you ever walk somewhere without a map?",
	"merchant":"What do you bring home that isn't for sale?"
}

func dialogue_choices(id: String, d: Dictionary) -> Dictionary:
	if not QUESTIONS.has(id) and id!="nera": return d
	for option in d.choices:
		if option.action.begins_with("personal:") or option.action.begins_with("journey:"): return d
		if option.action in ["march:lucan_personal","march:nera_personal"]: return d
	# Preserve every quest choice. A personal question takes the ordinary exit
	# slot; Esc still ends a conversation, including pages with three choices.
	var choices: Array = d.choices.duplicate(true)
	var question: String = QUESTIONS.get(id,"Who looks after you when the work is over?")
	var entry := N.choice(question,"personal:entry:"+id)
	if choices.size()<3:
		choices.insert(maxi(0,choices.size()-1),entry)
		return N.page(d.body,choices)
	for index in range(choices.size()):
		if choices[index].action in ["leave","march:leave"]:
			choices[index] = entry
			return N.page(d.body,choices)
	return d

func enter(id: String) -> void:
	if game.dialogue_id!=id: return
	if id=="nera": game.march.choose("march:nera_personal")
	elif id=="mara": open()
	elif id=="lucan": open_lucan()
	elif id in GENERIC: open_new(id)

func appearance_active(id: String) -> bool:
	return game.visuals.values.intimacy and id==active_id and relaxed and game.modal in ["dialog","intimacy","keepsake"] and safe()

func update_appearance() -> void:
	if game.world and game.world.npcs.has(active_id): game.world.apply_npc_appearance(active_id)

func portrait_path() -> String:
	return art_path(active_id)

func art_path(id: String) -> String:
	return Options.PEOPLE.get(id,{}).get("art","res://assets/intimacy/"+id+"-private.png")

func companion(id: String) -> bool:
	return Options.PEOPLE.get(id,{}).get("kind","")=="companionship"

func portrait_texture(id := "") -> Texture2D:
	if id.is_empty(): id = active_id
	if game.visuals.values.intimacy and Options.PEOPLE.has(id):
		return game.world.library.cell(art_path(id),0)
	return game.world.npc_portrait(id)

func compatible(id: String) -> bool:
	if not Options.PEOPLE.has(id): return false
	var person: Dictionary = Options.PEOPLE[id]
	return game.state.profile.age>=18 and game.state.profile.gender in person.interested_in and invitations_for(person.gender)

func invitations_for(gender: String) -> bool:
	return game.visuals.values.intimacy and game.state.profile.romance_interest in (["adults","men"] if gender=="man" else ["adults","women"])

func reason() -> String:
	var s = game.state
	if not game.visuals.values.intimacy: return "Private invitations are switched off."
	if s.profile.age<18: return "Only adult travellers can enter this story."
	if active_id in GENERIC:
		if not compatible(active_id): return "You both value this as a friendship."
		if s.relationships[active_id+"_declined"]: return "You have chosen to keep this a friendship."
		if active_id=="osric" and not s.flags.scout: return "Carry Ilya's report before arranging a quiet evening at the forge."
		if active_id=="rook" and not s.flags.bargain: return "Make peace over the mill's oil first. A personal invitation is separate from the bargain."
		if active_id=="ysabet" and not s.story.ashes_done: return "Finish bringing Ysabet the account of Elias, then let her speak about her own future."
		if active_id=="nera" and not s.story.medicine_done: return "Nera cannot leave the sickbeds until the patients' treatment has been settled."
		if active_id=="courier" and (not s.flags.courier_done or not s.flags.won): return "Tomas needs to recover, and reach the safety of Northwatch first."
		if active_id in ["ilya","merchant"] and not s.flags.won: return "The beacon still needs you. There will be time for an evening together once the road is safe."
		if not s.relationships[active_id+"_confided"]: return "Ask about life beyond the day's work first."
		if not safe(): return "Return to "+game.C.NPCS[active_id].name+" with no danger nearby."
		return ""
	if active_id=="lucan":
		if s.profile.gender!="man" or not invitations_for("man"): return "Lucan is interested in adult men. Your friendship is welcome as it is."
		if s.relationships.lucan_declined: return "You have chosen to keep this a friendship."
		if not s.story.letters_done or not s.story.letters_truth: return "There is an unfinished truth in Mateo's letter."
		if not s.relationships.lucan_confided: return "Let Lucan speak for himself before making an invitation."
		if not safe(): return "Find Lucan at the landing, with no danger nearby."
		return ""
	if s.profile.gender not in MARA.interested_in or s.profile.romance_interest not in ["adults","women"]: return "An easy friendship is what you both want."
	if s.relationships.mara_declined: return "You have chosen to keep this a friendship."
	if not s.flags.supplies or not s.flags.scout: return "There is still urgent news to carry between the fallen toll and the inn."
	if not s.relationships.mara_confided: return "Take time to know Mara as a person first."
	if not safe(): return "Find Mara at the inn, with no danger nearby."
	return ""

func safe() -> bool:
	if game.state.health<=0 or game.in_crypt(): return false
	if not game.world.npcs.has(active_id): return false
	var anchor: Vector3 = game.world.npcs[active_id].position
	var p := Vector2(anchor.x,anchor.z)
	if Vector2(game.player.position.x,game.player.position.z).distance_to(p)>8.0: return false
	for enemy in game.enemies:
		if not enemy.dead and enemy.position.distance_to(game.player.position)<18.0: return false
	return true

func page(text: String, choices: Array) -> void:
	if game.coop.active:
		text = text.replace("does not advance the world clock","does not pause the party's world")
	if active_id=="mara" and not invitations_for("woman"):
		for index in range(choices.size()):
			if choices[index].action=="personal:offer":
				choices[index] = N.choice("Share a cup as friends.","personal:tea")
	game.dialogue_id = active_id
	game.ui.show_dialog(active_id,N.page(text,choices))
	if relaxed:
		game.ui.dialog_portrait.texture = portrait_texture()
	update_appearance()

func open() -> void:
	if game.reporting: return
	cancel()
	active_id = "mara"
	phase = "conversation"
	relaxed = false
	if game.state.relationships.mara_evening:
		page("Mara sets a second cup beside hers without asking.\n\n'No need to make a ceremony of it,' she says. 'But I'm glad you came back.'\n\nYour shared memory belongs to this traveller's journal.",[N.choice("Sit with her over tea.","personal:tea"),N.choice("Look at the keepsake.","personal:card"),N.choice("Until later, Mara.","personal:leave")])
	else:
		page("For once, Mara lets the inn's accounts lie closed.\n\n'I used to think a full house meant I could stop being afraid. Turns out you can worry about twenty strangers as easily as one.'\n\nShe makes room at the table, with no bargain attached.",[N.choice("Tell me about your life before the inn.","personal:confide"),N.choice("I'd like to stay a little longer, with you.","personal:offer"),N.choice("A quiet moment is enough. Thank you.","personal:leave")])

func choose(action: String) -> void:
	if game.reporting: return
	if action.begins_with("personal:entry:"):
		enter(action.get_slice(":",2))
		return
	if action.begins_with("personal:closer:"):
		var id := action.get_slice(":",2)
		if game.dialogue_id==id: open_new(id)
		return
	if action.begins_with("personal:new_"):
		choose_new(action)
		return
	if action.begins_with("personal:lucan_"):
		choose_lucan(action)
		return
	match action:
		"personal:confide":
			game.state.relationships.mara_confided = true
			page("'I married young. Loved him, too. When he died I thought keeping the inn would mean living in a room full of his absence.'\n\nMara turns her cup in her hands. 'It didn't. People kept arriving. I found I still wanted things for myself. A laugh. A long walk. Someone who listens.'\n\n'What about you? Is there a life waiting beyond the next job?'",[N.choice("I hope so. I'd like you to be part of it.","personal:offer"),N.choice("For now, a friend's table is enough.","personal:tea"),N.choice("Thank you for telling me.","personal:leave")])
		"personal:offer":
			var unavailable := reason()
			if not unavailable.is_empty():
				page("Mara smiles, without awkwardness. 'Then let's keep each other company as friends.'\n\n[color=#dec48e]"+unavailable+"[/color]\n\nNothing is owed, and the road's work is unchanged.",[N.choice("Tea and a little company, then.","personal:tea"),N.choice("Tell me about yourself.","personal:confide"),N.choice("I'll see you again.","personal:leave")])
				return
			phase = "invitation"
			page("Mara holds your gaze a moment longer.\n\n'I would like that too. There's a quiet room behind the kitchen, if you'd like to be alone with me. You don't have to say yes. The tea is still yours either way.'\n\nThe invitation is personal; the returned stores paid for nothing here.",[N.choice("I'd like that. Shall we take a quiet moment?","personal:confirm"),N.choice("Tempting. Let's just share the tea tonight.","personal:tea"),N.choice("I'd rather stay friends.","personal:decline")])
		"personal:confirm":
			if phase!="invitation": return
			if not reason().is_empty(): open(); return
			phase = "confirmation"
			page("'One last question,' Mara says softly. 'Do you want to stay with me?'\n\nShe lays her hand beside yours, leaving the space between them for you to close. 'Only if you want to. We can always go back to the tea.'",[N.choice("Yes. I want to stay with you.","personal:begin"),N.choice("Let's keep this a friendly evening.","personal:tea"),N.choice("Not tonight. Thank you for asking.","personal:leave")])
		"personal:begin":
			# A stale button or direct action cannot bypass the second confirmation.
			if companion(active_id) or phase!="confirmation" or not reason().is_empty(): return
			committed = false
			relaxed = true
			phase = "prelude"
			clock = 0.0
			game.set_modal("intimacy")
			game.ui.show_private_scene()
			update_appearance()
		"personal:companion_begin":
			if not companion(active_id) or phase!="confirmation" or not reason().is_empty(): return
			# A fully clothed walk/dance is shown directly, without a private-room fade.
			game.state.relationships[active_id+"_evening"] = true
			game.state.keepsakes[active_id+"_lamplight"] = true
			game.state.log_event("shared_memory:"+active_id+"_lamplight")
			committed = true
			aftermath()
		"personal:decline":
			game.state.relationships.mara_declined = true
			page("'Friends, then.' Mara's smile stays warm. 'You'll always have a place at my table.'\n\nShe pours the tea. No promise is withdrawn; no debt is created.",[N.choice("I'm glad of that.","personal:leave")])
		"personal:tea":
			relaxed = false
			phase = "conversation"
			page("You share tea and stories about foolish travellers until Mara laughs into her cup. It is an ordinary, generous moment.\n\n'Come back when you can,' she says. 'I like your company.'\n\nNo time, resources or quest rewards are changed.",[N.choice("I'll come back.","personal:leave")])
		"personal:card": game.ui.show_keepsake(active_id)
		"personal:leave": game.set_modal("")

func tick(dt: float) -> void:
	if game.modal!="intimacy" or game.reporting: return
	clock += dt
	match phase:
		"prelude":
			if clock>=2.2: phase = "fade_out"; clock = 0.0
		"fade_out":
			game.ui.private_fade.color.a = clampf(clock/1.0,0,1)
			if clock>=1.0: phase = "black"; clock = 0.0
		"black":
			if clock>=0.9:
				if not reason().is_empty():
					game.set_modal("")
					game.message("You leave the invitation for another time.")
					return
				# Both fields belong to the same character/save payload; no partial award.
				game.state.relationships[active_id+"_evening"] = true
				game.state.keepsakes[active_id+"_lamplight"] = true
				game.state.log_event("shared_memory:"+active_id+"_lamplight")
				committed = true
				phase = "fade_in"
				clock = 0.0
				game.ui.private_caption.text = "Later, the kettle sings again.\nYou sit together in the lamplight." if active_id=="mara" else "Later, the tide turns beneath the landing.\nThere is another cup, and time to finish it."
				if active_id in GENERIC: game.ui.private_caption.text = Options.PEOPLE[active_id].after
		"fade_in":
			game.ui.private_fade.color.a = 1.0-clampf(clock/1.0,0,1)
			if clock>=1.5: aftermath()

func aftermath() -> void:
	phase = "aftermath"
	relaxed = true
	if active_id in GENERIC:
		page(Options.PEOPLE[active_id].after+"\n\n[color=#dec48e]Your shared memory is in Personal keepsakes in the journal. F5 saves it with your journey.[/color]",[N.choice("Remember this evening.","personal:card"),N.choice("Until next time.","personal:leave")])
		return
	if active_id=="lucan":
		page("The tide turns beneath the landing. Lucan puts another cup beside yours.\n\n'There's room for what I lost and what I still want,' he says. 'I didn't know that until I said it aloud.'\n\nNeither of you asks the evening to erase Mateo. You finish the tea together before returning to the road.\n\n[color=#dec48e]A personal keepsake is in your journal. F5 saves the journey and this memory together.[/color]",[N.choice("I'd like to remember this.","personal:card"),N.choice("Stay over another cup.","personal:lucan_tea"),N.choice("Until the next crossing.","personal:leave")])
		return
	page("Later, Mara rests her hand beside yours on the table. The kettle sings again.\n\n'For a little while,' she says, 'neither of us had to be brave.'\n\nYou share another cup before the road calls. No performance, no bargain; just a little warmth you chose together.\n\n[color=#dec48e]A personal keepsake has been placed in your journal. F5 saves your journey and this memory together.[/color]",[N.choice("I'd like to remember this.","personal:card"),N.choice("Another cup, before I go.","personal:tea"),N.choice("Until I return.","personal:leave")])

func cancel() -> void:
	phase = ""
	clock = 0.0
	relaxed = false
	committed = false
	update_appearance()

func open_new(id: String) -> void:
	if game.reporting or id not in GENERIC: return
	cancel()
	active_id = id
	phase = "conversation"
	relaxed = false
	var person: Dictionary = Options.PEOPLE[id]
	var choices := [N.choice("Tell me about life beyond the day's work.","personal:new_confide"),N.choice("Stay a little, as friends.","personal:new_tea"),N.choice("Until next time.","personal:leave")]
	if compatible(id) and not game.state.relationships[id+"_declined"]:
		var offer := "I'd like some time alone with you."
		if id=="ilya": offer = "I'd like to take an evening walk with you."
		elif id=="merchant": offer = "I'd like to hear one of those tunes with you."
		choices[1] = N.choice(offer,"personal:new_offer")
	if game.state.relationships[id+"_evening"]:
		page(person.after,[N.choice("Share a quiet moment.","personal:new_tea"),N.choice("Look at our keepsake.","personal:card"),N.choice("Until next time.","personal:leave")])
	else:
		page(person.opening,choices)

func choose_new(action: String) -> void:
	if active_id not in GENERIC: return
	var person: Dictionary = Options.PEOPLE[active_id]
	match action:
		"personal:new_confide":
			game.state.relationships[active_id+"_confided"] = true
			var choices := [N.choice("Thank you for telling me.","personal:new_tea"),N.choice("Until next time.","personal:leave")]
			if compatible(active_id) and not game.state.relationships[active_id+"_declined"]:
				choices.push_front(N.choice("I'd like to spend an evening with you.","personal:new_offer"))
			page(person.confide,choices)
		"personal:new_offer":
			var unavailable := reason()
			if not unavailable.is_empty():
				page("There is time for friendship without a promise.\n\n[color=#dec48e]"+unavailable+"[/color]",[N.choice("Tell me about yourself.","personal:new_confide"),N.choice("Stay as friends.","personal:new_tea"),N.choice("Another time.","personal:leave")])
				return
			phase = "invitation"
			page(person.invite,[N.choice("I'd like that too.","personal:new_confirm"),N.choice("Let's keep tonight friendly.","personal:new_tea"),N.choice("I'd rather remain friends.","personal:new_decline")])
		"personal:new_confirm":
			if phase!="invitation" or not reason().is_empty(): return
			phase = "confirmation"
			var text: String = person.get("confirm","'Are you sure you'd like to stay?'\n\nA hand rests beside yours. There is time to answer, and room to change your mind. 'Only if this is what you want too.'")
			page(text,[N.choice("Yes. I'd like to spend the evening with you.","personal:companion_begin" if companion(active_id) else "personal:begin"),N.choice("Just a friendly evening.","personal:new_tea"),N.choice("Not tonight.","personal:leave")])
		"personal:new_decline":
			game.state.relationships[active_id+"_declined"] = true
			phase = "conversation"
			page("'Friends, then. I'm glad you told me.'\n\nThe welcome remains warm. Nothing else between you changes.",[N.choice("I'm glad too.","personal:leave")])
		"personal:new_tea":
			relaxed = false
			phase = "conversation"
			page("You share a little company with "+game.C.NPCS[active_id].name+". For a while, nobody asks anything of either of you.\n\n'Come back when you can. I like talking with you.'",[N.choice("I will.","personal:leave")])

func open_lucan() -> void:
	cancel()
	if game.reporting: return
	active_id = "lucan"
	phase = "conversation"
	relaxed = false
	if game.state.relationships.lucan_evening:
		page("Lucan has put the second cup on the table for you this time. Mateo's little painted boat is still on the shelf.\n\n'I like that you don't ask me to put it away.'",[N.choice("Share a quiet cup.","personal:lucan_tea"),N.choice("Look at the keepsake.","personal:card"),N.choice("I'll see you after the crossing.","personal:leave")])
		return
	var invite: bool = invitations_for("man") and game.state.profile.gender=="man" and not game.state.relationships.lucan_declined
	page("Lucan closes the ferry hut's door against the wind, leaving it unlatched.\n\n'I used to think wanting anything after Mateo would mean I'd loved him badly. He never asked me to stop living. I managed to give myself that order.'\n\nHe is thirty-six, and learning how much life is still his to choose.",[N.choice("What would you choose for yourself now?","personal:lucan_confide"),N.choice("I'd like to stay with you a little longer." if invite else "Share a little company as friends.","personal:lucan_offer" if invite else "personal:lucan_tea"),N.choice("Thank you for trusting me.","personal:leave")])

func choose_lucan(action: String) -> void:
	if active_id!="lucan": return
	match action:
		"personal:lucan_confide":
			game.state.relationships.lucan_confided = true
			var invite: bool = invitations_for("man") and game.state.profile.gender=="man" and not game.state.relationships.lucan_declined
			page("'A working ferry. Someone who answers honestly when I ask a hard question. A morning I don't spend apologizing to a dead man for having slept well.'\n\nLucan smiles, a little surprised at himself. 'Tea first. I can promise tea without consulting my entire past.'",[N.choice("Tea, and perhaps a little more time together." if invite else "Tea and a friend's company.","personal:lucan_offer" if invite else "personal:lucan_tea"),N.choice("A friend's table is enough.","personal:lucan_tea"),N.choice("I'll come back.","personal:leave")])
		"personal:lucan_offer":
			var unavailable := reason()
			if not unavailable.is_empty():
				page("The quiet is welcome, without a promise attached.\n\n[color=#dec48e]"+unavailable+"[/color]\n\nLucan pours the tea. The ferry and his friendship remain available.",[N.choice("Stay as friends.","personal:lucan_tea"),N.choice("Let him speak for himself.","personal:lucan_confide"),N.choice("Until next time.","personal:leave")]); return
			phase = "invitation"
			page("'I'd like you to stay,' Lucan says. 'For myself. Not because of the letter, and not because you think I shouldn't be alone.'\n\n'Only if you want it too. We can just drink the tea.'",[N.choice("I want to stay with you.","personal:lucan_confirm"),N.choice("Let's make it a friendly evening.","personal:lucan_tea"),N.choice("I'd rather keep this a friendship.","personal:lucan_decline")])
		"personal:lucan_confirm":
			if phase!="invitation" or not reason().is_empty(): return
			phase = "confirmation"
			page("'Are you sure?' Lucan asks. 'We can leave this here, with no awkward debt between us.'\n\nHe waits for your answer. 'The tea will still be here if you would rather just talk.'",[N.choice("Yes. I want this quiet time with you.","personal:begin"),N.choice("Tea and friendship tonight.","personal:lucan_tea"),N.choice("Not tonight. Thank you for asking.","personal:leave")])
		"personal:lucan_decline":
			game.state.relationships.lucan_declined = true
			page("'Friends, then. I'm glad you said what you wanted.'\n\nThe second cup stays on the table. Safe passage and a warm welcome remain yours.",[N.choice("I'm glad too.","personal:leave")])
		"personal:lucan_tea":
			relaxed = false
			phase = "conversation"
			page("You sit with Lucan while the ferry rope taps against its post. He tells you about a time Mateo tried to teach a priest to row. The story is funnier when he gets to the priest's opinion of boats.\n\nFor a little while, remembering is easy.",[N.choice("I'm glad I stayed.","personal:leave")])
