extends RefCounted

const D = preload("res://scripts/march_content.gd")
const N = preload("res://scripts/narrative.gd")
const DEFAULTS := {"started":false,"briefed":false,"orders":false,"ledger":false,"roll":false,"witness":false,"medicine_accepted":false,"bandages":false,"salve":false,"alcohol":false,"medicine_done":false,"patient":"","ashes_accepted":false,"locket":false,"ashes_done":false,"ashes_truth":false,"letters_accepted":false,"letter":false,"letters_done":false,"letters_truth":false,"ferry_accepted":false,"rope":false,"ferry_fixed":false,"soldier_accepted":false,"soldier_done":false,"witness_choice":"","faith_accepted":false,"candle_bridge":false,"candle_orchard":false,"faith_done":false,"faith_rite":"","verdict":"","defense_started":false,"defense_done":false,"name_mateo":false,"name_elias":false,"name_alina":false,"bell_method":"","bell_done":false,"epilogue":false,"track":0}
const COMPLETION := ["epilogue","medicine_done","ashes_done","letters_done","ferry_fixed","soldier_done","faith_done"]
var game: Node
var defense_clock := 0.0
var document_id := ""
var pending_verdict := ""

static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in DEFAULTS:
		if not value.has(key): return false
		var sample: Variant = DEFAULTS[key]
		if sample is bool and not value[key] is bool: return false
		if sample is String and not value[key] is String: return false
	if not (value.track is float or value.track is int) or not is_finite(float(value.track)) or value.track!=floor(value.track) or value.track<0 or value.track>=D.TRACKS.size(): return false
	return value.patient in ["","raisa","pavel"] and value.verdict in ["","trial","resign","burn"] and value.witness_choice in ["","testify","exile"] and value.faith_rite in ["","prayer","silence","ribbon"] and value.bell_method in ["","memory","force"]

func s() -> Dictionary: return game.state.story
func c(text: String, action: String) -> Dictionary: return N.choice(text,"march:"+action)
func page(id: String, body: String, choices: Array) -> void:
	game.dialogue_id = id
	game.ui.show_dialog(id,N.page(body,choices))

func finish(key: String, title: String, xp := 65, coins := 12) -> void:
	if s()[key]: return
	s()[key] = true
	game.state.inventory.gold += coins
	game.quest_reward(title,xp)
	game.world.apply_state()

func talk(id: String) -> void:
	var q := s()
	if not game.state.flags.won:
		page(id,"The north road is still dark. These people have troubles enough, but no safe way to bring help.\n\n[color=#dec48e]Restore the beacon at Northwatch first. Your journal still follows Mara's expedition.[/color]",[c("I'll bring a light back.","leave")])
		return
	if id!="merchant" and not q.started:
		page(id,"A caravan has reached Northwatch. Adela carries news of the refugees and the broken bridge.\n\nSpeak to her beside the beacon, then return. There is work here that a sword alone will not finish.",[c("I'll ask Adela.","leave")])
		return
	match id:
		"merchant":
			if not q.started:
				page(id,"The beacon reaches farther than you think. Refugees saw it from Saint Mere. They have a physician, two sickbeds, and a steward who insists the bridge disaster was an act of God.\n\nI carried that steward's stores. I don't believe him.\n\n[color=#dec48e]A second chapter / The Names We Carry. Follow the road north around Northwatch to Saint Avel's Bridge, then find Nera at Saint Mere.[/color]",[c("I'll take the road to Saint Mere.","start"),c("Let me trade first.","trade"),c("I need time in the Hollow.","leave")])
			else:
				page(id,"Saint Mere is north of the bridge. Nera keeps its refuge. Lucan can restore the ferry; once it runs, our carts can carry you between the landing, refuge and Northwatch.\n\n'If you learn why the gate closed,' Adela says, 'don't mistake the first answer for the whole answer.'",[c("Follow the March investigation.","track_0"),c("Let me trade.","trade"),c("I'll be on my way.","leave")])
		"nera": nera()
		"ysabet": ysabet()
		"lucan": lucan()
		"garran": garran()
		"corvin": corvin()
		"anselm": anselm()

func nera() -> void:
	var q := s()
	if not q.briefed:
		page("nera","'Wash your hands before you touch anything.'\n\nNera draws the curtain between two beds. Raisa, fifty-four, ran grain barges before the quarantine. Pavel, twenty-seven, laid the bridge's stones. Both have the fever.\n\n'The steward held our medicines behind a sealed gate. Captain Garran signed the order. Father Anselm buried the people outside it. I want the records before another official tells me what happened.'\n\n[color=#dec48e]Find the charred orders at the bridge, Garran at Gallows Cut, the private ledger at Veyr, and the burial roll at Saint Mary's Hospice.[/color]",[c("I'll find the records and the people behind them.","brief"),c("Tell me about the sickbeds.","medicine"),c("I'll return.","leave")])
	elif q.bell_done:
		var ending := "Corvin will answer in public. His former guards have withdrawn; the refuge must learn to defend itself." if q.verdict=="trial" else "Corvin has resigned. His stores keep the refuge fed, while Anselm keeps the complete record for a future hearing." if q.verdict=="resign" else "Corvin's wagons are already unloading. The official story remains a lie, though you know whose names it covers."
		var patient := "The two sickbeds are still waiting for your decision." if not q.medicine_done else "Raisa is sitting up. Pavel's bed is empty beneath a folded blanket." if q.patient=="raisa" else "Pavel is sleeping without fever. Raisa's barge keys lie beside an empty bed."
		page("nera","The hospice bell reaches Saint Mere without making anyone flinch.\n\n"+ending+"\n\n"+patient+"\n\n'You didn't mend the past,' Nera says. 'You gave us a day we can use. Let that be enough for tonight.'",[c("Tell me what the road remembers.","epilogue"),c("What about your patients?","medicine"),c("I still have people to see.","leave")])
	else:
		var outcome := "Raisa asks after her barges. Pavel's blanket has been folded for the next traveller." if q.patient=="raisa" else "Pavel asks whether anyone has sent for his wife. Raisa's keys are kept safe for her sister." if q.patient=="pavel" else "Both patients still wait. There is enough active medicine for one proper treatment."
		page("nera","Nera has a list of names beside her medicines. None has been crossed out carelessly.\n\n"+outcome+"\n\n'Tell me what you learned when you've spoken to them yourself. People aren't entries in my ledger.'",[c("The Last Dose / the patients.","medicine"),c("How are you carrying all this?","nera_personal"),c("Supplies and a road back.","refuge_services")])

func ysabet() -> void:
	var q := s()
	if q.ashes_done:
		var text := "'He wasn't waiting for me somewhere. I know that now.' Ysabet rests her hand on the named stone. 'Thank you for not making me live inside another story.'" if q.ashes_truth else "'He died helping people,' Ysabet repeats. It is the part you chose to tell her. The rest of the burial roll is still in your journal."
		page("ysabet",text+"\n\nThe orchard is quiet. There will be work here next spring, whether or not the truth has finished its work.",[c("I can stay a moment.","ysabet_vigil"),c("I'll leave you in peace.","leave")])
	elif q.locket:
		page("ysabet","Ysabet recognizes the little brass locket before you speak.\n\n'Elias. Twenty-three and already tired of being called my boy. He said he'd bring everyone through the gate. Tell me you found more than this.'\n\n"+("The burial roll says Elias died outside a gate closed early by his own employers. He had helped strangers to the hospice, then was refused medicine." if q.roll else "You have his name and a scorched locket. The hospice burial roll may explain his last hours. You can wait for the full account."),[c("I'll look for the full burial account.","track_2"),c("Tell her the whole truth. [Requires burial roll]","ashes_truth"),c("Tell her only that he helped others before he died.","ashes_comfort")])
	else:
		page("ysabet","'Don't call it abandoned. I'm still here.'\n\nYsabet has swept a doorstep whose house is ash. Her adult son Elias went to the bridge with the last refugees. The steward says nobody survived, but he won't give her a list.\n\n'At the old press, south-west of here. If there's anything left with a name on it, bring it to me. Not a story about him. Something that was his.'",[c("I'll search the burned press. [A Name for the Ashes]","ashes_accept"),c("What will you do with the orchard?","ysabet_orchard"),c("I'll be careful among the ashes.","leave")])

func lucan() -> void:
	var q := s()
	if q.letters_done:
		var truth := "'He took their money. Then he went back for the people he left.' Lucan says both sentences without letting either erase the other. 'I loved him. I can hate what he did.'" if q.letters_truth else "Lucan carries the short letter you chose to give him. He knows Mateo meant to return. You have kept the uglier page."
		page("lucan",truth+"\n\nThe ferry rope knocks softly against the post.",[c("A quiet word, away from the crossing.","lucan_personal"),c("What does the ferry need?","ferry"),c("Safe crossings, Lucan.","leave")])
	elif q.letter:
		page("lucan","'Mateo wrote all that?'\n\nThe first page is a love letter to Lucan, another adult man: an ordinary promise of a life across the water. The second admits Mateo sold places on the last boat, then returned to rescue those he had excluded.\n\nLucan asks for the truth. You can give him both pages, or keep the confession and offer only the farewell.",[c("Give him the complete letter.","letters_truth"),c("Give only the loving farewell.","letters_mercy"),c("Let me think before I hand this over.","leave")])
	else:
		page("lucan","Lucan has kept two cups on the ferry hut's shelf for eleven months.\n\n'Mateo was a bridge guard. He came here after the gate shut. Someone saw him at the wreck south of the landing. I know what an empty boat means. I'd still like to know what happened to the man in it.'\n\nHe looks at the water, then back to you. 'The wreck's about fifty paces south. There are deserters stripping it.'",[c("I'll look for his letter. [Letters Below the Water]","letters_accept"),c("Can this ferry run again?","ferry"),c("I'll return when I can.","leave")])

func garran() -> void:
	var q := s()
	if q.soldier_done:
		var line := "'I'll stand beside the record. Not in front of it. Not behind someone else's orders.'" if q.witness_choice=="testify" else "'I'll go north when the road opens. Don't tell yourself exile is forgiveness. I won't.'"
		page("garran",line+"\n\nGarran has folded his captain's coat into a small square. The shirt beneath has no insignia.",[c("The record will carry your name.","leave"),c("Tell me about Alina once more.","garran_alina")])
	elif q.orders and q.ledger:
		page("garran","Garran reads his own signature under Corvin's figures.\n\n'Alina was my wife. She stayed outside to bring children and the old through. I could have opened the gate before the fever took the bridge. I waited for another order.'\n\n'Corvin changed the hour. I obeyed the first one. Put both in your book.'\n\nHe will testify if you ask. Or you can give him the northern pass and let him leave before the hearing.",[c("Testify. Your remorse needs a public account.","witness_testify"),c("Give the written statement, then leave in exile.","witness_exile"),c("I need to consider what justice asks.","leave")])
	else:
		page("garran","'Captain is a word I haven't earned the right to hear.'\n\nThe deserter at Gallows Cut is Garran Rusk. His men took the medicine chest, but he would not follow them south.\n\n'Clear the robbers from the quarry. Read the bridge orders, then Corvin's ledger. I'll give you an account you can test against the paper. Don't take a confession on trust just because the man looks sorry.'",[c("I'll bring the orders and ledger. [A Soldier's Account]","soldier_accept"),c("Who was Alina?","garran_alina"),c("I'll be back.","leave")])

func corvin() -> void:
	var q := s()
	if not q.verdict.is_empty():
		var line := "'Then let the court hear every name, including mine.' Corvin places his seal on the table. His guards are packing their colours. They will not protect Saint Mere after this." if q.verdict=="trial" else "'I resign, the stores go to Nera, and the full record stays with Anselm. I understand that a private agreement can still become a public question.'" if q.verdict=="resign" else "'The wagons leave today.' Corvin does not thank you for the ashes in the grate. He does not need to."
		page("corvin",line+"\n\nThe agreement is already entered. It will not become another agreement if you ask twice.",[c("I understand the cost.","leave")])
	elif q.orders and q.ledger and q.roll and q.witness:
		page("corvin","Corvin sets four documents beside one another. His large hands are very still.\n\n'Three hundred people behind the gate. Fever outside it. I closed it early and kept the medicine here. I told myself I was choosing the greater number. Then I altered the ledger so nobody could judge the choice.'\n\nHe offers a public hearing; or resignation with all stores surrendered and an intact record held privately; or wagons and fifty coins if the incriminating pages burn.\n\n[color=#dec48e]Public trial: the garrison withdraws; defend the refuge. Private resignation: immediate supplies, testimony preserved without a public reckoning. Burn the record: Corvin stays in power; the official lie survives.[/color]",[c("The whole record goes to a public hearing.","verdict_trial"),c("Resign. Give Nera the stores; Anselm keeps every page.","verdict_resign"),c("Burn the incriminating pages for wagons and coin.","verdict_burn")])
	else:
		page("corvin","'I will discuss accusations when you bring evidence.'\n\nThe magistrate is an ogre in a scholar's coat, articulate and tired, with no guard between his desk and the road. The men at the storehouse are another matter.\n\n'The bridge orders, my ledger, the hospice roll and Garran's account. Bring all four. A few charred lines won't tell you how many people were waiting on either side.'",[c("I'll bring the complete record.","track_0"),c("Why did you leave the refugees outside?","corvin_reason"),c("This conversation is not over.","leave")])

func anselm() -> void:
	var q := s()
	if q.bell_done:
		page("anselm","The little dwarf priest has stopped listening for footsteps in the empty ward.\n\n'Lord Jesus Christ, remember them. Elias Vale. Mateo Venn. Alina Rusk. And those we have not learned to name.'\n\nHe turns to you. 'Nera should hear that the bell is quiet. The living have waited quite long enough.'",[c("I'll return to Nera.","track_0"),c("What remains of faith?","faith"),c("Keep their names safe.","leave")])
	else:
		page("anselm","'I buried them under numbers. The orders said names would invite unrest.'\n\nFather Anselm wears a small wooden cross over a dwarf's plain road coat. 'God forgive me, I obeyed. The thing beneath our bell has been answering those numbers ever since. It isn't the grove's Old Faith. It isn't God. Something from the Abyss is feeding on what we refuse to remember.'\n\n[color=#dec48e]The burial roll is behind the altar. Resolve the record with Corvin. Then name the three tablets beside the bell, or break the keeper that binds it.[/color]",[c("Tell me how to free the bell.","bell_help"),c("Can we do something for the little shrines?","faith"),c("I'll read the roll first.","leave")])

func choose(action: String) -> void:
	if game.reporting: return
	var a := action.trim_prefix("march:")
	var q := s()
	if a=="leave": game.set_modal(""); return
	if a.begins_with("track_"):
		q.track = clampi(int(a.trim_prefix("track_")),0,D.TRACKS.size()-1)
		game.set_modal("")
		game.message("Tracking / "+D.TRACKS[q.track],4)
		return
	match a:
		"trade": game.open_shop("merchant")
		"start":
			if q.started: return
			q.started = true
			q.track = 0
			game.state.inventory.tonic += 3
			game.state.inventory.bread += 2
			game.state.inventory.wood += 3
			game.state.log_event("chapter:the_names_we_carry")
			game.set_modal("")
			game.message("The Ashen March / Nera waits beyond Saint Avel's Bridge. Adela packs 3 tonics, 2 bread and 3 wood.",8)
		"brief": q.briefed = true; q.track = 0; game.set_modal("")
		"medicine": medicine()
		"medicine_accept": q.medicine_accepted = true; q.track = 1; game.set_modal("")
		"dose_raisa", "dose_pavel":
			if q.medicine_done or not (q.bandages and q.salve and q.alcohol): return
			q.patient = "raisa" if a=="dose_raisa" else "pavel"
			finish("medicine_done","The Last Dose",90,15)
			medicine()
		"nera_personal":
			page("nera","'My husband died before this fever had a name. I spent a week bargaining with God and another bargaining with my own notes. I had medicines other people needed. I kept them for him.'\n\nNera folds a bandage along its old crease. 'He died anyway. That's why I ask for help with these beds. I don't trust love to make every decision for me.'",[c("You don't have to make this one alone.","medicine"),c("I'll carry the records too.","track_0"),N.choice("What would you choose for yourself, away from the ward?","personal:closer:nera")])
		"refuge_services":
			page("nera","There is clean water by the door, and a warm fire in the yard. Rest costs nothing.\n\nNera sells a tonic for eight coins; the proceeds buy linen. Restored ferry passage connects Saint Mere, Reedwater and Northwatch.",[N.choice("Buy a tonic. [8 coins]","buy_tonic"),c("Take the restored trade route.","travel_menu"),c("I'll be on my way.","leave")])
		"ashes_accept": q.ashes_accepted = true; q.track = 2; game.set_modal("")
		"ashes_truth", "ashes_comfort":
			if q.ashes_done or not q.locket: return
			if a=="ashes_truth" and not q.roll:
				page("ysabet","You cannot give her an account you haven't found. The burial roll is at Saint Mary's Hospice, north of the central road.\n\nYsabet takes your hand. 'Come back when you know.'",[c("I'll find the roll.","track_2"),c("I'll leave you in peace.","leave")]); return
			q.ashes_truth = a=="ashes_truth"
			finish("ashes_done","A Name for the Ashes",75,10)
			ysabet()
		"ysabet_orchard":
			page("ysabet","'The trees that lived will fruit. I'll graft new branches onto the ones with sound roots. That's what an orchard is. Keeping what can live, and admitting what can't.'\n\nShe is not asking you to rebuild it in an afternoon.",[c("I'll search for Elias.","ashes_accept"),c("I hope I see it in spring.","leave")])
		"ysabet_vigil": page("ysabet","You sit with Ysabet without offering a lesson. After a while she tells you Elias hated the sound of ripe pears falling on the roof. She laughs once, unexpectedly.\n\nThe memorial keeps his name; you keep that small, ordinary detail.",[c("Thank you for telling me.","leave")])
		"letters_accept": q.letters_accepted = true; q.track = 3; game.set_modal("")
		"letters_truth", "letters_mercy":
			if q.letters_done or not q.letter: return
			q.letters_truth = a=="letters_truth"
			finish("letters_done","Letters Below the Water",75,10)
			lucan()
		"lucan_personal": game.relationship.open_lucan()
		"ferry": ferry()
		"ferry_accept": q.ferry_accepted = true; q.track = 4; game.set_modal("")
		"repair":
			if q.ferry_fixed: ferry(); return
			if not q.rope or game.state.inventory.wood<3 or game.state.inventory.scrap<2:
				game.message("The winch needs sound rope, 3 dry wood and 2 scrap.",5); return
			if game.threats_near(game.C.ground(D.OBJECTS.ash_winch.pos),15): game.message("Clear the landing before working on the winch."); return
			game.state.inventory.wood -= 3
			game.state.inventory.scrap -= 2
			finish("ferry_fixed","Two Shores",65,8)
			ferry()
		"travel_menu": travel_menu()
		"travel_refuge", "travel_ferry", "travel_tower":
			if not q.ferry_fixed: game.message("Restore the ferry before taking the trade route."); return
			var stop := "ash_refuge" if a=="travel_refuge" else "ash_ferry" if a=="travel_ferry" else "tower"
			game.journey.choose("journey:go:"+stop)
		"soldier_accept": q.soldier_accepted = true; q.track = 5; game.set_modal("")
		"witness_testify", "witness_exile":
			if q.soldier_done or not q.orders or not q.ledger: return
			if game.threats_near(game.C.ground(D.NPCS.garran.pos),25): game.message("The quarry robbers must be driven off before Garran can give his account."); return
			q.witness_choice = "testify" if a=="witness_testify" else "exile"
			q.witness = true
			finish("soldier_done","A Soldier's Account",85,12)
			garran()
		"garran_alina": page("garran","'Alina Rusk. Road guard. My wife. She knew the names of every family at the gate. I knew their numbers.'\n\nHe rubs the place where his wedding ring used to sit. 'She called me by my name when she asked me to open it. Not by my rank. I heard her. That's the part I can't put on Corvin.'",[c("Her name belongs in the record.","soldier_accept"),c("I'll remember it.","leave")])
		"corvin_reason": page("corvin","'Because I was afraid. Not of fever alone. Of being the man who let it in.'\n\nCorvin looks toward the refuge. 'I counted the people behind me. Then I made the people in front of me into a number I could bear. That was easier than admitting I didn't know what would happen.'",[c("I'll bring the records.","track_0"),c("Fear doesn't settle the question.","leave")])
		"verdict_trial", "verdict_resign", "verdict_burn":
			if not q.verdict.is_empty() or not (q.orders and q.ledger and q.roll and q.witness): return
			var option := a.trim_prefix("verdict_")
			pending_verdict = option
			page("corvin","[b]Enter this agreement?[/b]\n\n"+("Every page goes to a public hearing. Corvin is detained; the garrison withdraws. You will defend Saint Mere before returning to the hospice." if option=="trial" else "Corvin resigns and surrenders the stores. Anselm preserves the entire account privately. The community has food, but no public hearing today." if option=="resign" else "Corvin keeps his office and sends supplies. You receive fifty coins. The incriminating pages burn, and the official lie survives. Personal memories remain yours.")+"\n\nThis choice is final for this journey.",[c("Enter the agreement.","commit_"+option),c("I need more time.","leave")])
		"commit_trial", "commit_resign", "commit_burn":
			if pending_verdict!=a.trim_prefix("commit_"): return
			if not q.verdict.is_empty() or not (q.orders and q.ledger and q.roll and q.witness): return
			q.verdict = a.trim_prefix("commit_")
			pending_verdict = ""
			game.state.inventory.gold += 50 if q.verdict=="burn" else 15
			game.state.inventory.tonic += 2
			game.quest_reward("The Price of Silence",100)
			game.state.log_event("march_verdict:"+q.verdict)
			corvin()
		"faith": faith()
		"faith_accept": q.faith_accepted = true; q.track = 6; game.set_modal("")
		"faith_prayer", "faith_silence", "faith_ribbon":
			if q.faith_done or not (q.candle_bridge and q.candle_orchard): return
			q.faith_rite = a.trim_prefix("faith_")
			finish("faith_done","What Remains of Faith",55,0)
			faith()
		"bell_help":
			page("anselm","'Read the burial roll. Bring the complete record to Corvin and decide what to do with it. If you choose a hearing, protect Saint Mere when its garrison goes.'\n\n'Then the tablets: Mateo Venn at the ferry stone, Elias Vale at the orchard stone, Alina Rusk at the guard stone. Speak their names and ring the bell. The keeper loses its hold.'\n\n'You can also force it into the open and fight. It will not tell you anything the dead haven't already said.'",[c("I'll follow the names. [Track main chapter]","track_0"),c("I understand.","leave")])
		"bell_memory", "bell_force": begin_bell(a=="bell_force")
		"epilogue": epilogue()

func medicine() -> void:
	var q := s()
	if q.medicine_done:
		page("nera",("Raisa lives. She has asked her sister to run the grain barges until she is strong enough. Pavel died before dawn; Nera sent his last words to his wife." if q.patient=="raisa" else "Pavel lives. A letter has gone to his wife. Raisa died before dawn; her sister has the barge keys.")+"\n\nNera offers no arithmetic that makes the empty bed acceptable. She sits beside it with you.\n\n'We chose with what we had. We still owe the other one a name.'",[c("Then keep both names.","leave"),c("Tell me about your own loss.","nera_personal"),c("I should continue the investigation.","track_0")])
	elif q.bandages and q.salve and q.alcohol:
		page("nera","The supplies are ready. Nera can make one proper treatment. Splitting it would comfort both patients but cure neither; she will give them pain relief regardless.\n\nRaisa is fifty-four. Her grain barges feed three villages; her sister could inherit them. Pavel is twenty-seven, with a wife expecting their first child; he helped build the gate that kept the others out. Neither is a verdict.\n\n[color=#dec48e]Choose who receives the treatment. The other patient will die. No choice awards a better relationship or greater reward.[/color]",[c("Treat Raisa.","dose_raisa"),c("Treat Pavel.","dose_pavel"),c("I need a moment before deciding.","leave")])
	else:
		page("nera","'There's sound linen in the quarry chest, salve in the ferry surgeon's case, and alcohol reserved at Veyr. The disease isn't a punishment. It doesn't care whether anyone deserves another day.'\n\n[color=#dec48e]Gallows Cut: bandages "+("found" if q.bandages else "missing")+"\nReedwater wreck: salve "+("found" if q.salve else "missing")+"\nVeyr storehouse: alcohol "+("found" if q.alcohol else "missing")+"[/color]\n\nRecover all three, then return. Nera will explain the final choice before you make it.",[c("I'll gather the treatment supplies. [The Last Dose]","medicine_accept"),c("How are you carrying this?","nera_personal"),c("I'll return.","leave")])

func ferry() -> void:
	var q := s()
	if q.ferry_fixed:
		page("lucan","The winch turns cleanly. Grain barges can reach the refuge; Adela's cart completes the landward stretch to Northwatch.\n\nYou can use the restored trade route for free. Letters and people cross with the cargo now.",[c("Arrange passage.","travel_menu"),c("A quiet word.","lucan_personal"),c("Safe crossings.","leave")])
	else:
		page("lucan","'Three sound timbers, two bits of iron, and a rope that hasn't spent the winter underwater. I'll do the fitting.'\n\nA salvage chest lies west along the refuge road, around forty-five paces east of its central fork. The winch is on the landing beside Lucan.\n\n[color=#dec48e]Sound rope: "+("found" if q.rope else "missing")+" / wood %d/3 / scrap %d/2[/color]\n\nOnce repaired, free passage connects the landing, refuge and Northwatch." % [game.state.inventory.wood,game.state.inventory.scrap],[c("I'll restore the crossing. [Two Shores]","ferry_accept"),c("Let's work on the winch. [Rope + 3 wood + 2 scrap]","repair"),c("I'll return with the materials.","leave")])

func faith() -> void:
	var q := s()
	if q.faith_done:
		var words := "You and Anselm prayed to Jesus Christ by name. He keeps a candle for people whose faith was different from his." if q.faith_rite=="prayer" else "You kept silence together. Anselm did not fill it with an answer you had not asked for." if q.faith_rite=="silence" else "You tied a local remembrance ribbon to the living tree. Anselm blessed the dead in his own words and left your gesture intact."
		page("anselm",words+"\n\n'The older customs aren't the thing under this bell,' he says. 'Neither are questions. God can bear those.'",[c("Keep the candles lit.","leave"),c("Tell me about the bell.","bell_help")])
	elif q.candle_bridge and q.candle_orchard:
		page("anselm","You have tended the votives at the bridge and the orchard. Anselm opens the little hospice chapel.\n\n'We can pray. We can sit in silence. Or you may tie one of their remembrance ribbons to the tree outside. I won't pretend every grief asks the same thing.'",[c("Pray: Lord Jesus Christ, remember them.","faith_prayer"),c("Keep a silent vigil.","faith_silence"),c("Tie a local remembrance ribbon.","faith_ribbon")])
	else:
		page("anselm","'A little votive stands on the bridge, another in the burned orchard. Clean the ash from them. Someone needs to see that the dead haven't been abandoned.'\n\n[color=#dec48e]Bridge votive: "+("tended" if q.candle_bridge else "waiting")+"\nOrchard shrine: "+("tended" if q.candle_orchard else "waiting")+"[/color]\n\nReturn here when both are tended; choose a prayer, a silent vigil or a local remembrance ribbon.",[c("I'll tend both places. [What Remains of Faith]","faith_accept"),c("I'll think about it.","leave")])

func interact(id: String) -> void:
	document_id = id
	var q := s()
	if not game.state.flags.won or not q.started:
		game.message("Ask Adela about the northern road after restoring Northwatch.",5); return
	if id=="ash_winch": ferry(); return
	if id=="ash_coach": travel_menu(); return
	if id in ["ash_raisa","ash_pavel"]: medicine(); return
	if id=="ash_memorial":
		document("Bellwether memorial", "Elias Vale / twenty-three / loved by Ysabet and remembered by name." if q.ashes_done else "An empty stone, swept clean. Ysabet will not let an official number stand in place of her son's name."); return
	if id=="ash_bell": bell_menu(); return
	if id.begins_with("ash_names_"):
		if not q.roll: game.message("Read the burial roll behind the altar before naming these stones."); return
		var key := "name_"+id.trim_prefix("ash_names_")
		q[key] = true
		game.world.apply_state()
		game.audio.play_effect("bell")
		document("A name spoken aloud", "Mateo Venn. Ferryman's beloved. He sold places on a boat, then returned for the people he had left." if key=="name_mateo" else "Elias Vale. Orchard keeper's adult son. He helped strangers reach shelter and was refused the medicine they all needed." if key=="name_elias" else "Alina Rusk. Road guard. Garran's wife. She stayed outside the gate because people were still arriving."); return
	if id in ["ash_candle_bridge","ash_candle_orchard"]:
		q["candle_bridge" if id=="ash_candle_bridge" else "candle_orchard"] = true
		game.world.apply_state()
		var next_step := "Both votives are tended. Return to Father Anselm at Saint Mary's Hospice and ask about a vigil." if q.candle_bridge and q.candle_orchard else "Next: tend the orchard shrine at Bellwether." if q.candle_bridge else "Next: tend Saint Avel's bridge votive."
		if q.faith_done: next_step = "Your vigil is complete. Both lights are still tended."
		document("A little light", "You clear soot from the votive and shelter its small flame. No voice answers. A traveller passing tomorrow will see that someone cared.\n\n[color=#dec48e]"+next_step+"[/color]"); return
	if game.threats_near(game.C.ground(D.OBJECTS[id].pos),8):
		game.message("Find a moment clear of nearby enemies before searching here."); return
	var records := {
		"ash_orders":["orders","The order at Saint Avel","Close Saint Avel's gate at the sixth bell. Admit no further civilians. All medicines reserved for the inner district. / Captain Garran Rusk.\n\nA later hand changes SIXTH to FOURTH. The correction carries Magistrate Corvin's seal.\n\nThe gate was closed before its announced hour."],
		"ash_locket":["locket","A name among the ashes","The brass locket is blackened but whole. ELIAS VALE, in Ysabet's careful hand, is tucked behind a pressed pear blossom.\n\nThere is no body here. The hospice burial roll may say where he went.\n\nReturn this to Ysabet in the orchard."],
		"ash_letter":["letter","Two pages for Lucan","Lucan, I kept thinking we could begin when the roads were kind. There will always be another winter. If I get back, let us begin anyway.\n\nI took money for places on the boat. I told myself the others could walk to the gate. I knew it had closed. I went back. I don't know whether that makes a difference. It ought to matter that I went back; it ought not to make the first thing disappear.\n\nMateo.\n\nBoth pages are dry. Both belong to the same man."],
		"ash_bandages":["bandages","The quarry medicine chest","Sound sealed linen, spared by rain inside a stolen hospice chest. Nera can use it.\n\nThe deserters took more than coins when they abandoned their posts."],
		"ash_salve":["salve","The ferry surgeon's case","The surgeon's salve survived beneath the wreck's bench. Most of the bottles broke. Enough active treatment remains for one patient, if Nera has clean linen and alcohol."],
		"ash_alcohol":["alcohol","Reserved supplies","Medical spirits, entered as table wine. Corvin's steward moved the bottles into a private storeroom while the hospice requested disinfectant.\n\nBring these to Nera."],
		"ash_ledger":["ledger","The private account","Gate closure advanced by two bells. Twelve medicine cases diverted to Veyr. Twenty-seven outer-district deaths entered under 'transit losses'.\n\nCorvin's margin: The fever did not cross. I cannot know how many that saved. I know exactly how many I kept outside.\n\nGarran's signature appears on the original order; Corvin's on the altered hour. Neither cancels the other."],
		"ash_roll":["roll","The burial roll","27 / Elias Vale, twenty-three. Brought strangers to the hospice. Refused reserved treatment.\n28 / Mateo Venn, thirty-two. Returned from the ferry with three survivors. Died of cold and injury.\n29 / Alina Rusk, thirty-eight. Road guard. Refused to leave those outside.\n\nFather Anselm added the names beneath the official numbers. The keeper under the bell answers when the numbers are read."],
		"ash_rope":["rope","A sound ferry rope","Dry salvage rope under a waxed tarp. Enough for Lucan's winch. You also recover three timbers and two sound iron brackets.\n\n[Two Shores: +3 wood, +2 scrap, once only.]" ]
	}
	if not records.has(id): return
	var record: Array = records[id]
	if not q[record[0]]:
		q[record[0]] = true
		if id=="ash_rope": game.state.inventory.wood += 3; game.state.inventory.scrap += 2
		game.take(id)
		game.state.log_event("march_evidence:"+id)
	document(record[1],record[2])

func document(title: String, text: String) -> void:
	game.ui.show_dialog("anselm",N.page(text,[c("Close this account.","leave")]))
	game.dialogue_id = ""
	game.ui.dialog_portrait.hide()
	game.ui.dialog_name.text = title
	game.ui.dialog_role.text = "Recovered testimony / The Ashen March"

func travel_menu() -> void:
	if not s().ferry_fixed:
		page("lucan","The ferry winch needs sound rope, three timbers and two iron brackets. Passage resumes after Two Shores is complete.",[c("What needs doing?","ferry"),c("I'll walk for now.","leave")]); return
	game.journey.travel_menu(3)

func bell_menu() -> void:
	var q := s()
	if q.bell_done: document("A bell for the living","The bell answers with its own small voice. The keeper has gone. Nera waits at Saint Mere; people with unfinished business remain along the road."); return
	if q.verdict.is_empty(): game.message("Resolve the complete record with Corvin before calling the keeper.",5); return
	if q.verdict=="trial" and not q.defense_done: game.message("The garrison has withdrawn. Defend Saint Mere before returning to the bell.",5); return
	page("anselm","The hospice bell has no master now. The keeper beneath it still holds the names.\n\nYou can speak all three names at the tablets, then ring for remembrance; or force the keeper into the open and defeat it.\n\n[color=#dec48e]Mateo: "+("named" if q.name_mateo else "waiting")+" / Elias: "+("named" if q.name_elias else "waiting")+" / Alina: "+("named" if q.name_alina else "waiting")+"[/color]",[c("Ring for the named dead. [All three tablets]","bell_memory"),c("Call out the keeper and fight.","bell_force"),c("Not yet.","leave")])

func begin_bell(force: bool) -> void:
	var q := s()
	if q.bell_done or q.verdict.is_empty() or q.verdict=="trial" and not q.defense_done: return
	if game.threats_near(game.C.ground(D.OBJECTS.ash_bell.pos),25): game.message("Clear the hospice grounds before sounding the bell."); return
	if not force and not (q.name_mateo and q.name_elias and q.name_alina): game.message("Speak all three names at the tablets before ringing for remembrance."); return
	game.set_modal("")
	q.bell_method = "force" if force else "memory"
	game.audio.play_effect("bell")
	if force:
		if not game.state.defeated.has("ash_mournkeeper") and not game.enemies.any(func(e): return e.id=="ash_mournkeeper"):
			game.spawn_enemy("ash_mournkeeper","mournkeeper",Vector2(0,-929))
		game.ui.discover("THE UNBURIED","The keeper of those reduced to numbers")
	else:
		finish("bell_done","A Bell Without a Master",140,15)
		game.ui.discover("THE NAMES REMAIN","The bell answers the living, and no one else")

func tick(dt: float) -> void:
	var q := s()
	if not q.started: return
	if q.verdict=="trial" and not q.defense_done:
		if not q.defense_started and game.coop.party_near(game.C.ground(D.SITES.ash_refuge.pos),28):
			q.defense_started = true
			for record in [["ash_defense_1","bandit",Vector2(-47,-500)],["ash_defense_2","wolf",Vector2(-86,-505)],["ash_defense_3","wraith",Vector2(-40,-540)],["ash_defense_4","wraith",Vector2(-94,-548)]]:
				if not game.state.defeated.has(record[0]): game.spawn_enemy(record[0],record[1],record[2])
			game.message("The garrison has gone. Hold Saint Mere against the shapes coming from the road.",8)
		if q.defense_started and ["ash_defense_1","ash_defense_2","ash_defense_3","ash_defense_4"].all(func(id): return game.state.defeated.has(id)):
			finish("defense_done","The Refuge Holds",100,20)
			game.state.inventory.tonic += 2
			game.message("Saint Mere holds. Nera tends the wounded. Return to the hospice bell.",7)
	if q.bell_method=="force" and not q.bell_done and game.state.defeated.has("ash_mournkeeper"):
		finish("bell_done","A Bell Without a Master",140,15)
		game.message("The keeper releases the bell. Bring the news to Nera at Saint Mere.",8)

func objective() -> Dictionary:
	var q := s()
	var track := int(q.track)
	if not q.started: return goal("Speak to Adela about the northern road.",game.C.NPCS.merchant.pos)
	var unfinished: Array[String] = []
	for i in range(1,COMPLETION.size()):
		if not q[COMPLETION[i]]: unfinished.append(D.TRACKS[i])
	if q.epilogue and unfinished.is_empty():
		return {"text":"All March quests complete. Return to the Hollow or keep exploring.","complete":true}
	if track>0 and q[COMPLETION[track]]:
		return {"text":D.TRACKS[track]+" complete. Choose another tracked quest in J / M.","complete":true}
	if track==1 and not q.medicine_done:
		if not q.bandages: return object_goal("Recover Nera's bandages at Gallows Cut.","ash_bandages")
		if not q.salve: return object_goal("Recover the surgeon's salve at the ferry wreck.","ash_salve")
		if not q.alcohol: return object_goal("Find the medicinal spirits at Veyr.","ash_alcohol")
		return npc_goal("Return to Nera / choose the treatment.","nera")
	if track==2 and not q.ashes_done:
		if not q.locket: return object_goal("Search the burned orchard press for Elias's name.","ash_locket")
		if not q.roll: return object_goal("Read the hospice burial roll for the full account.","ash_roll")
		return npc_goal("Bring Elias's name and account to Ysabet.","ysabet")
	if track==3 and not q.letters_done:
		return npc_goal("Bring both pages to Lucan.","lucan") if q.letter else object_goal("Find Mateo's letter at the ferry wreck.","ash_letter")
	if track==4 and not q.ferry_fixed:
		return object_goal("Repair the ferry winch / rope, 3 wood, 2 scrap.","ash_winch") if q.rope else object_goal("Recover sound ferry rope east of the refuge.","ash_rope")
	if track==5 and not q.soldier_done:
		if not q.orders: return object_goal("Find the original bridge orders.","ash_orders")
		if not q.ledger: return object_goal("Find Corvin's private ledger at Veyr.","ash_ledger")
		return npc_goal("Clear the quarry; hear Garran's account.","garran")
	if track==6 and not q.faith_done:
		if not q.candle_bridge: return object_goal("Tend Saint Avel's bridge votive.","ash_candle_bridge")
		if not q.candle_orchard: return object_goal("Tend the orchard shrine.","ash_candle_orchard")
		return npc_goal("Return to Anselm for a vigil.","anselm")
	if not q.briefed: return npc_goal("Meet Nera at Saint Mere Refuge.","nera")
	if not q.orders: return object_goal("Recover the charred bridge orders.","ash_orders")
	if not q.ledger: return object_goal("Recover the private ledger at Veyr.","ash_ledger")
	if not q.witness: return npc_goal("Clear Gallows Cut and obtain Garran's account.","garran")
	if not q.roll: return object_goal("Read the burial roll at Saint Mary's Hospice.","ash_roll")
	if q.verdict.is_empty(): return npc_goal("Bring the full record to Corvin. Choose its future.","corvin")
	if q.verdict=="trial" and not q.defense_done: return goal("Defend Saint Mere after the garrison withdraws.",D.SITES.ash_refuge.pos)
	if not q.bell_done:
		if q.bell_method=="force": return goal("Defeat the Unburied at the hospice.",Vector2(0,-929))
		if not q.name_mateo: return object_goal("Name Mateo's tablet / or call the keeper.","ash_names_mateo")
		if not q.name_elias: return object_goal("Name Elias's tablet.","ash_names_elias")
		if not q.name_alina: return object_goal("Name Alina's tablet.","ash_names_alina")
		return object_goal("Ring the bell for the named dead.","ash_bell")
	if not q.epilogue: return npc_goal("Return to Nera for the chapter's aftermath.","nera")
	return {"text":"Main chapter complete. Still open: "+", ".join(unfinished)+". Choose a quest in J / M.","complete":true}

func goal(text: String, p: Vector2) -> Dictionary: return {"text":text,"pos":p}
func npc_goal(text: String, id: String) -> Dictionary: return goal(text,D.NPCS[id].pos)
func object_goal(text: String, id: String) -> Dictionary: return goal(text,D.OBJECTS[id].pos)

func journal() -> String:
	var q := s()
	var text := "\n[color=#e2c38a]THE ASHEN MARCH / THE NAMES WE CARRY[/color]\n"
	text += "The gate closed early. Twenty-seven people became 'transit losses'. Find their names and decide what the living will do with the record.\n"
	text += "\n[color=#dec48e]TRACKED / "+D.TRACKS[int(q.track)]+"[/color]\n"+objective().text+"\n\n"
	for row in [[q.briefed,"Hear Nera at Saint Mere"],[q.orders,"Read the original gate orders"],[q.ledger,"Find Corvin's private ledger"],[q.witness,"Obtain Garran's signed account"],[q.roll,"Read the hospice burial roll"],[not q.verdict.is_empty(),"Decide what becomes of the record"],[q.bell_done,"Free the hospice bell"],[q.epilogue,"Return to Nera for the aftermath"]]:
		text += ("✓ " if row[0] else "○ ")+row[1]+"\n"
	text += "\n[color=#e2c38a]PEOPLE OF THE MARCH[/color]\n"
	for row in [[q.medicine_done,"The Last Dose / Nera's two sickbeds"],[q.ashes_done,"A Name for the Ashes / Ysabet and Elias"],[q.letters_done,"Letters Below the Water / Lucan and Mateo"],[q.ferry_fixed,"Two Shores / restore free trade-route passage"],[q.soldier_done,"A Soldier's Account / Garran's complicity"],[q.faith_done,"What Remains of Faith / Anselm's votives"]]:
		text += ("✓ " if row[0] else "○ ")+row[1]+"\n"
	if q.medicine_done: text += "\nTreatment given to "+q.patient.capitalize()+". The other bed is empty. Both names are kept.\n"
	if q.ashes_done: text += "Ysabet heard the whole burial account.\n" if q.ashes_truth else "Ysabet heard only the comforting part. The full account remains known to you.\n"
	if q.letters_done: text += "Lucan received both pages: guilt and courage.\n" if q.letters_truth else "Lucan received the farewell; Mateo's confession was withheld.\n"
	if not q.verdict.is_empty(): text += "The record: "+q.verdict+". This decision is final.\n"
	if q.roll: text += "\n[color=#e2c38a]THE THREE NAMES[/color]\nMateo Venn, thirty-two / Lucan's beloved.\nElias Vale, twenty-three / Ysabet's son.\nAlina Rusk, thirty-eight / Garran's wife and a road guard.\n"
	text += "\nChange the tracked quest above. The map has separate Hollow / March sheets. Repaired ferry passage reduces return travel. Personal scenes are optional, adult, private and fade to black.\n"
	return text

func epilogue() -> void:
	if not s().bell_done: return
	finish("epilogue","The Names We Carry",150,20)
	var q := s()
	var lines := "[b]The Ashen March / an ordinary tomorrow[/b]\n\n"
	lines += "Corvin will face a public hearing; the refuge holds without his garrison.\n" if q.verdict=="trial" else "Corvin has resigned; the record waits intact with Anselm.\n" if q.verdict=="resign" else "Corvin's wagons feed Saint Mere. His official lie survives.\n"
	lines += "Ysabet keeps Elias's name in her orchard.\n" if q.ashes_done else "Ysabet is still waiting beside an empty stone.\n"
	lines += "Lucan has both pages of Mateo's letter.\n" if q.letters_done and q.letters_truth else "Lucan has the part of Mateo you chose to preserve.\n" if q.letters_done else "Two cups still wait in Lucan's hut.\n"
	lines += "Raisa lives; Pavel is remembered.\n" if q.patient=="raisa" else "Pavel lives; Raisa is remembered.\n" if q.patient=="pavel" else "Nera's two beds still wait for your help.\n"
	lines += "The ferry carries grain and travellers again.\n" if q.ferry_fixed else "The ferry still needs a sound rope.\n"
	lines += "\nThe bell speaks for the living. There are no numbers beneath it now.\n\nYou can keep exploring, finish unfinished personal quests and return to friends in the Hollow. F5 saves this journey."
	page("nera",lines,[c("There are still people I want to see.","leave"),c("Follow the restored trade road.","travel_menu"),c("Stay for a little while.","nera_personal")])
