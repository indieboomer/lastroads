extends RefCounted

const D = preload("res://scripts/woods_content.gd")
const N = preload("res://scripts/narrative.gd")
const DEFAULTS := {
	"started":false,"focus":false,"briefed":false,"body":false,"bolt":false,"watch":false,"letter":false,
	"mould":false,"ledger":false,"rites":false,"review":false,"prison":false,"knife":false,
	"cache_memory":false,"cache_raid":false,"boat":false,"winter":false,
	"hester_met":false,"bran_met":false,"maelin_met":false,"sella_met":false,"vey_met":false,
	"edric_met":false,"ada_met":false,"nell_met":false,"mill_account":false,"scribe_account":false,
	"cause":false,"access":false,"motive":false,"confession":false,"prison_key":false,
	"vented":false,"rescue_started":false,"rescued":false,"rescue_reward":false,
	"boat_returned":false,"vigil":false,"sella_consent":false,"ada_consent":false,
	"ward_west":false,"ward_east":false,"ward_north":false,"heart_called":false,
	"heart_done":false,"completed":false,"track":0,"justice":"","pact":""
}
var game: Node
var origin := ""

static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in DEFAULTS:
		if not value.has(key): return false
		if DEFAULTS[key] is bool and not value[key] is bool: return false
		if DEFAULTS[key] is String and not value[key] is String: return false
	var track: Variant = value.track
	if not (track is int or track is float) or not is_finite(float(track)) or track!=floor(float(track)) or track<0 or track>=D.TRACKS.size(): return false
	if value.justice not in ["","hearing","exile","conceal"] or value.pact not in ["","accord","sever","inherit"]: return false
	if value.confession and not (value.cause and value.access and value.motive): return false
	if not value.justice.is_empty() and not value.confession: return false
	if value.heart_done and (value.pact.is_empty() or value.justice.is_empty() or not value.rescued): return false
	if value.completed and not value.heart_done: return false
	return true

func s() -> Dictionary: return game.state.woods
func c(text: String, action: String) -> Dictionary: return N.choice(text,"woods:"+action)
func near(id: String, distance := 12.0) -> bool:
	var p: Vector2 = D.NPCS[id].pos if D.NPCS.has(id) else D.OBJECTS[id].pos
	return Vector2(game.player.position.x,game.player.position.z).distance_to(p)<distance

func page(id: String, body: String, choices: Array) -> void:
	game.dialogue_id = id
	game.ui.show_dialog(id,N.page(body,choices))

func note(title: String, body: String, choices: Array = []) -> void:
	if choices.is_empty(): choices = [c("Keep the account; return to the road.","leave")]
	page("hester",body,choices)
	game.ui.dialog_name.text = title
	game.ui.dialog_role.text = "THE ROWAN MARCH / FIELD NOTES"

func reward(key: String, title: String, xp: int, coins := 0) -> void:
	if s()[key]: return
	s()[key] = true
	game.state.inventory.gold += coins
	game.quest_reward(title,xp)
	game.world.apply_state()

func start() -> bool:
	if s().started: return true
	if not game.state.story.bell_done:
		note("A northern road","Alderwake's appeal has reached the hospice, but the roadkeepers cannot carry relief north while its bell is bound. Finish the hospice bell in The Names We Carry first. You may scout the road and return; no evidence disappears.")
		return false
	s().focus = true
	s().started = true
	s().track = 0
	game.state.log_event("chapter:the_shape_of_a_murder")
	game.message("Chapter III / The Shape of a Murder. Hester waits in Alderwake, north of the hospice.",9)
	return true

func talk(id: String) -> void:
	origin = id
	if not start(): return
	s()[id+"_met"] = true
	match id:
		"hester": hester()
		"bran": bran()
		"maelin": maelin()
		"sella": sella()
		"vey": vey()
		"edric": edric()
		"ada": ada()
		"nell": nell()

func hester() -> void:
	if s().completed:
		page("hester",ending(),[c("Read the complete case record.","case_record"),c("Rest and resupply.","care"),c("There are still people to visit.","leave")]); return
	if not s().briefed:
		s().briefed = true
		page("hester","Hester washes a dark stain from her hands before offering you the other chair.\n\n'Reeve Oren was found at Blackwater Sluice. Somebody cut an antler sign into him. By noon that had become proof against everyone who keeps the old rites. By evening Bran wanted a list of their houses.'\n\n'I need an examination, a weapon, a timeline and a reason. Start at the sluice east of here, or speak to the people whose names are being used. A symbol is evidence of a symbol. It isn't a confession.'\n\n[color=#dec48e]Chapter III / The Shape of a Murder. The mill and sanctuary leads can be investigated in either order. Use the journal's six case tracks; the investigation board links the evidence.[/color]",[c("Show me how to assemble the case.","board"),c("What can you tell me about Oren?","victim"),c("I'll follow the evidence.","leave")]); return
	if s().heart_done:
		page("hester","The witnesses have returned. Hester leaves the last line of the record blank.\n\n'We know who killed him. Now tell me what we're going to live beside.'\n\nYou can close the account without closing the road. Your decisions about justice and the woods will both be remembered.",[c("Give the final account to Alderwake.","complete"),c("Read the evidence once more.","case_record"),c("Let me see the others first.","leave")]); return
	if s().confession and s().justice.is_empty():
		page("hester","Bran's statement sits beside the bolt mould, the watch book, Oren's letter and the prisoner roll. Hester refuses to file it under 'religious unrest'.\n\n'Bran murdered Oren. Vey accepted people who never consented. Maelin's congregation is not either man. Oren's own clearances also belong in the record.'\n\nPublic hearing keeps Bran alive for testimony and names every institution involved. Exile with restitution keeps the written evidence but denies the families a hearing. Concealment buys the watch's cooperation at the cost of a deliberate lie. None changes what happened.",[c("Hear the three possible settlements.","justice"),c("The prisoners must come home too.","track_2"),c("I need time.","leave")]); return
	page("hester","The board has space for three links: how Oren died, who could reach him, and what he threatened to expose.\n\n'You don't need every rumour,' Hester says. 'You do need independent evidence for each claim. Sella knows the mill's time; Edric knows why the inquiry never reached the assize.'\n\n"+("Your completed links are strong enough to confront Bran." if deductions_done() else "Inspect the body and channel, read the watch book and Oren's letter, then follow the kiln and prisoner records."),[c("Work at the investigation board.","board"),c("Help with supplies or rest.","care"),c("I'll keep looking.","leave")])

func bran() -> void:
	if s().confession:
		page("bran","'I remember the first winter,' Bran says. 'They slept because I kept the roots awake. I began to think their sleep made anything I did necessary.'\n\n'Vey never moved my hand. Oren was going to expose the people I gave him. I killed Oren, then borrowed the antler sign so fear would do the rest. Write that I chose it. Do not write that the woods made me.'\n\n"+("Bran is held for the hearing; his own watch has taken his keys." if s().justice=="hearing" else "Bran knows the agreement you made. The testimony has not changed."),[c("Hester will keep the statement.","leave"),c("Where are the prisoners?","bran_cells")]); return
	page("bran","Bran turns his badge so the light catches it.\n\n'The Old Faith marked him. Maelin has an antler knife. You can spend a week playing scholar, or ask her where she was.'\n\nHe says he patrolled the west road at the ninth bell. He admits holding the sluice key earlier that evening. He says someone must have borrowed it. When you ask who, he begins discussing the village's safety.",[c("Test the watch account against the evidence.","confront"),c("What did your protection cost?","bran_pact"),c("I'll check your account.","leave")])

func sella() -> void:
	if not s().mill_account:
		s().mill_account = true
		page("sella","Sella lays a broken gear on the bench.\n\n'The mill clock stopped at eight. That is not when he died. At the ninth bell I was lifting the watergate, and I saw Bran's watch cart by the sluice. I know his grey horse and the brass lamp bracket. I didn't see what happened behind it.'\n\n'Someone has been asking whether I saw Maelin. I saw no woman. Put down what I actually said.'\n\n[color=#dec48e]Adult witness account recorded: the mill's stopped clock is misleading. Bran's cart was present at the ninth bell.[/color]",[c("Will you make that statement publicly?","sella_statement"),c("What keeps this mill running?","sella_life"),c("I'll examine the channel.","leave")]); return
	page("sella","The stopped clock remains on the bench. Sella will not let you turn her limited sighting into a witnessed murder.\n\n'Maelin's people kept the upstream springs clear when Oren's men cut too high. I owe them that. I don't owe anyone a prisoner's life.'",[c("Would you support an agreement with the sanctuary?","consent_sella"),c("Tell me about the mill and the night again.","sella_life"),c("Thank you for the precise account.","leave")])

func maelin() -> void:
	page("maelin","Maelin is binding a splint with a strip of clean bark. Her antler knife lies in plain sight.\n\n'Vey used to sit beside me. We gave what belonged to us: grain, work, a memory. Then he said one person's refusal could condemn a village. That is how he made generosity into a debt owed by strangers.'\n\n'I knew Bran brought him people. I argued and stayed here, tending those the forest spared. You may ask whether staying clean was another way of leaving them there.'\n\nThe sanctuary's cords record consent and refusal. The knife was stolen and returned; Maelin will let you examine it. Her welcome is not proof of innocence, any more than her faith is proof of guilt.",[c("Explain a willing offering, including its cost.","faith"),c("Will you help end the forced offerings?","maelin_help"),c("I'll read the cords and examine the knife.","leave")])

func vey() -> void:
	var text := "'Bran wanted a boundary,' Vey says. 'I gave him one. The roots held raiders while the magistrate counted what the rescue would cost.'\n\n'I began with my memories. My sister died, and I could no longer remember her voice. I decided the next winter should cost someone who had given us nothing.'\n\nHe calls the prisoners willing because they stopped resisting. When you challenge this, he does not misunderstand you. He simply believes safety permits the lie."
	if s().rescued: text += "\n\nThe cellars are open. Vey has lost the people he intended to pledge. He has no claim on them."
	page("vey",text,[c("Release the prisoners. I have your transfer roll.","vey_key"),c("What is the bargain with the listening oak?","vey_heart"),c("I will decide what to do with your account.","leave")])

func edric() -> void:
	if not s().scribe_account: s().scribe_account = true
	page("edric","'I wrote a man's innocence once,' Edric says. 'Then I let an official copy make it disappear.'\n\nHe watched Bran follow Oren from the village carrying the watch crossbow. He did not see them reach the sluice. Afterward Bran ordered him to replace Oren's inquiry with a notice blaming the Old Faith. Edric hid the originals in the old assize.\n\n'Oren took people's homes. Then he tried to stop a worse thing. If I make him a saint because he was murdered, I will be falsifying another record.'\n\n[color=#dec48e]Edric's account corroborates the cover-up. The old transcript and winter depot are nearby.[/color]",[c("Will you preserve every part of the record?","edric_record"),c("What did the old hearing establish?","edric_hearing"),c("I'll search the surviving records.","leave")])

func ada() -> void:
	if s().rescued:
		page("ada","Silas is sleeping at the infirmary. Ada has stopped standing every time someone approaches.\n\n'He says the roots kept him warm. He says they would not let go when he asked. Both things happened. Don't let someone use the first to excuse the second.'\n\nShe is willing to hear Maelin's proposal. She will not speak for Silas, the other prisoners, or anyone who wants no part of it.",[c("Would you support a voluntary sanctuary agreement?","consent_ada"),c("What would winter need without the pact?","winter_help"),c("Let him rest. I'll return.","leave")]); return
	page("ada","'My brother's name is Silas. He's thirty-eight. He cannot write.'\n\nAda has a copy of a consent signed in her brother's name. She does not ask you to decide whether every story about the woods is true.\n\n'He was arrested for taking bread from Oren's stores. Bran said he'd be released. Then someone told me to be proud he was sheltering us.'\n\nThe root cellars lie on the eastern road beyond the white kiln. Find the transfer roll and a way to open the chambers. Vey at the Root Court may surrender the key; force is also possible.",[c("I'll look for Silas and the others.","track_2"),c("What can you tell me about his arrest?","ada_arrest"),c("Keep a place ready for him.","leave")])

func nell() -> void:
	if s().boat and not s().boat_returned:
		page("nell","Nell, twelve, recognizes the little boat in your pack. Hester stays within earshot.\n\n'That's the one. I wasn't down at the sluice. I was in Sella's kitchen and saw a cart go past. I didn't see a face. I only remembered the squeaky wheel.'\n\nHer recollection may suggest a question to ask an adult. It cannot identify a killer.",[c("Return the boat. You don't need to investigate anything.","boat_return"),c("I'll bring it back in a moment.","leave")]); return
	page("nell","Nell, twelve, sits in Alderwake's safe yard, carving a mast for a boat that is missing.\n\n'People keep asking which monster I saw. I didn't see one. I heard a cart. Grown-ups don't seem to like that answer.'\n\nHester has told her she can stop answering questions. Nell asks only whether you might bring back the toy boat caught in the reeds below Sella's mill. She will stay here.",[c("You can keep the details to yourself. I'll look for the boat.","track_boat"),c("Stay here with Hester.","leave")])

func deductions_done() -> bool: return s().cause and s().access and s().motive
func wards_open() -> bool: return s().ward_west and s().ward_east and s().ward_north

func board() -> void:
	if not near("nw_caseboard",20):
		game.message("Use Hester's board in Alderwake to compare the physical records."); return
	page("hester","Three claims must stand independently. A correct link is kept in the casebook; a mistaken link can be reconsidered without losing evidence.\n\nCause: "+("established" if s().cause else "unresolved")+"\nAccess: "+("established" if s().access else "unresolved")+"\nMotive: "+("established" if s().motive else "unresolved"),[c("How was Oren killed?","deduce_cause"),c("Who had the means and opportunity?","deduce_access"),c("What was the murder meant to prevent?","deduce_motive")])

func deduce(link: String) -> void:
	var body := ""
	var choices: Array = []
	match link:
		"cause":
			body = "The covered body has two kinds of injury. The channel contains an iron bolt. What do they establish?\n\nNeeded: the field examination and the recovered bolt."
			choices = [c("A fatal bolt wound preceded the staged antler cuts.","link_cause"),c("An antler sign proves a ritual killed him.","wrong_symbol"),c("Water killed him; the wounds were incidental.","wrong_water")]
		"access":
			body = "The watch book, Sella's precise account, and the chipped bolt mould can be compared. A stopped clock is not a time of death.\n\nNeeded: watch book, Sella's adult testimony, kiln bolt mould."
			choices = [c("Sella owns the mill; ownership proves access and guilt.","wrong_owner"),c("Bran's key, cart and missing personal bolt corroborate access.","link_access"),c("Maelin knows the woods, so she could be anywhere.","wrong_faith")]
		"motive":
			body = "Oren's inquiry, the protection ledger, and the prisoner transfer roll describe the same missing adults. What was being silenced?\n\nNeeded: Oren's letter, protection ledger, prisoner roll."
			choices = [c("The old religion required this particular murder.","wrong_faith"),c("Oren was disliked; anyone had equal reason.","wrong_dislike"),c("Bran and Vey's coerced offerings were about to be exposed.","link_motive")]
	page("hester",body,choices)

func justice() -> void:
	page("hester","Choose the disposition of Bran's confession. You will confirm the choice before the record is sealed. The woodland pact will be decided separately.\n\nPublic hearing: Bran remains in custody, Vey is named alongside him, and the land clearances also enter the record.\nExile and restitution: Bran leaves, his stores go to survivors, and Edric keeps an intact deposition.\nConcealment: the watch keeps its leader and relief stores move quickly. The killing is officially attributed to an unknown attacker; you knowingly protect a murderer.",[c("Prepare a public hearing.","confirm_hearing"),c("Prepare exile with restitution.","confirm_exile"),c("Conceal Bran's guilt.","confirm_conceal")])

func prison_gate() -> void:
	if s().rescued:
		note("The opened cellars","Silas, Jory and Teren have left for Alderwake. Their names remain on the release register. The chambers are empty."); return
	var cleared: bool = s().prison_key or s().rescue_started and ["nw_cell_guard_1","nw_cell_guard_2"].all(func(id): return game.state.defeated.has(id))
	if not cleared:
		note("Three people under the roots","The barred chamber holds three adults. A pressure wheel feeds the binding roots. A side vent must be opened before the release is turned. The wards are watched by Vey's debt collectors.\n\nVey may surrender his key when confronted with the transfer roll. Or you can fight the two collectors; they are not Maelin's congregation.",[c("Call the collectors and force a way through.","rescue_force"),c("Seek Vey's key at the Root Court.","track_2"),c("Leave the release alone for now.","leave")]); return
	if not s().vented:
		note("Pressure in the roots","The release wheel strains against a pressurized root. Forcing it now would crush the chamber shutters. Open the side vent beside the eastern entrance first. The prisoners ask you to take your time."); return
	if game.threats_near(game.C.ground(D.OBJECTS.nw_gate.pos),18): game.message("The collectors are too close. Clear a safe path for the prisoners first."); return
	s().rescued = true
	reward("rescue_reward","Those Who Did Not Consent",110,15)
	game.state.inventory.tonic += 2
	note("Three names returned","You open the shutters after the pressure falls. Silas, Jory and Teren are alive and able to walk. Silas confirms that Bran delivered them and Vey refused their requests to leave. Hester's relief runner leads them to Alderwake while you hold the exit.\n\nAda's account and the original roll are now supported by the survivors themselves. Two tonics remain in the release chest.\n\n[color=#dec48e]The prisoners are safe. Return to Ada if you want her view of the sanctuary's future.[/color]")

func heart() -> void:
	if s().heart_done:
		note("The listening oak",pact_summary()+"\n\nHester needs the final account in Alderwake."); return
	if not s().confession or s().justice.is_empty() or not s().rescued:
		note("A creditor beneath the bark","The oak speaks in remembered voices, not a language you can call innocent or wicked. It has sheltered homes and held people who begged to leave.\n\nBefore deciding its future, establish the murder, settle Bran's confession with Hester, and free the prisoners. A bargain made over people still in chains would be another forced offering."); return
	if s().heart_called:
		note("The Borrowed Heart","The old contract has taken a body. Open the three binding knots around the oak, then defeat the Borrowed Heart. The western, eastern and northern knots can be opened in any order. Its broad attack has a long warning; evade sideways and answer during its recovery."); return
	page("maelin","At the listening oak, Maelin will witness a new agreement but will not speak for the prisoners. Vey's old contract is carved beneath the bark.\n\nA voluntary accord requires the sanctuary's recorded refusal rights and explicit support from Sella and Ada after the rescue. Severing the pact calls out the thing enforcing it; winter will require ordinary labour and stores. Inheriting Bran's authority preserves protection but leaves the forest's debt collectible from people who never agreed.\n\nNone of these choices will change who killed Oren.",[c("A public accord: only adult, personal, revocable offerings.","pact_accord"),c("Sever the contract and face its collector.","pact_sever"),c("Take Bran's place as guarantor of the old debt.","pact_inherit")])

func pact_summary() -> String:
	match s().pact:
		"accord": return "Maelin's sanctuary and Alderwake keep a public accord. Only adults may pledge what belongs to them, children are excluded from every offering, and refusal or withdrawal creates no debt. The roots shelter fewer houses. Some families choose ordinary wells and accept the work. The saved protection is smaller because nobody is being quietly spent to enlarge it."
		"sever": return "The Borrowed Heart is gone and no root can collect the old debt. Maelin's people may still pray and tend the springs; you broke a coercive contract, not their right to believe. "+("Ada opens the recovered winter stores. The village can face the cold without another hidden offering." if s().winter else "Without the emergency depot, Alderwake faces a lean winter. Hester asks the roadkeepers for grain; freedom has not supplied it by itself.")
		"inherit": return "The roots hold Alderwake's boundary. Your name has replaced Bran's beneath the old promise. You have demanded no immediate victim, but you preserved the clause allowing the guarantor to pledge another adult's future. Ada will not call it consent. Maelin keeps her independent sanctuary; Vey calls your hesitation the first stage of wisdom. The next collection has merely been deferred."
	return "The woodland agreement is unresolved."

func ending() -> String:
	var text := "[b]THE SHAPE OF A MURDER / THE RECORD THAT REMAINS[/b]\n\nOren was killed by Bran with the watch's missing bolt. The antler wounds were staged after death. The murder concealed forced offerings to Vey's Root Court. Oren's land clearances remain part of the record; they do not excuse his killing.\n\n"
	match s().justice:
		"hearing": text += "Bran and Vey are named for a public hearing. Bran remains alive in custody, and Edric copies the testimony so it cannot depend on one person's courage. The sanctuary's faith is distinguished from the acts of the two accused."
		"exile": text += "Bran leaves under a signed restitution order. His stores go to the survivors, and Vey's part remains in Edric's intact deposition. Some families prefer the immediate relief. Others say you sent their chance to question him down the road."
		"conceal": text += "Relief wagons arrive under Bran's seal. The public account names an unknown killer; the evidence remains hidden in your casebook. You protected Bran from the consequences of a murder you proved. Hester keeps a copy where a future investigator might find it."
	text += "\n\n"+pact_summary()+"\n\nSilas, Jory and Teren came home. Nell "+("has her boat and was never asked to accuse anyone." if s().boat_returned else "remains safe in Alderwake; her toy boat is still an unfinished small kindness.")
	text += "\n\nMaelin "+("heard a remembrance of her sister without asking the woods to return a stolen memory." if s().vigil else "still has a memory she cannot recover. Her vigil remains open to you.")
	text += "\n\nThe northern road stays open. Return to old friends, complete the smaller stories, or sit beside a fire. F5 keeps this account with your existing journey."
	return text

func choose(action: String) -> void:
	if game.reporting: return
	var a := action.trim_prefix("woods:")
	if a=="leave": game.set_modal(""); return
	if not start(): return
	if a=="lead":
		game.state.tracked_side = ""
		s().focus = true
		note("A third northern road","Hester, the coroner of Alderwake, asks for independent witnesses after a murder at Blackwater Sluice. Follow the road north from Saint Mary's Hospice. The journal now follows her appeal.",[c("Follow the case.","track_0"),c("Keep my place here.","leave")]); return
	if a.begins_with("track_"):
		game.state.tracked_side = ""
		s().focus = true
		if a=="track_boat": s().track = 1
		else: s().track = clampi(int(a.trim_prefix("track_")),0,D.TRACKS.size()-1)
		game.set_modal("")
		game.message("Tracking / "+D.TRACKS[s().track],4); return
	if a.begins_with("deduce_"):
		if near("nw_caseboard",20): deduce(a.trim_prefix("deduce_"))
		return
	if a.begins_with("wrong_"):
		if not near("nw_caseboard",20): return
		page("hester","Hester leaves that line out.\n\n'A confession of belief cannot substitute for evidence of an act. Ownership of a place isn't proof of a murder. Neither is a stopped clock. Compare independent records; you can revise the link without losing anything.'",[c("Return to the three links.","board"),c("I'll look for more evidence.","leave")]); return
	if a.begins_with("link_"):
		if not near("nw_caseboard",20): return
		var link := a.trim_prefix("link_")
		var needed: Array = {"cause":["body","bolt"],"access":["watch","mill_account","mould"],"motive":["letter","ledger","prison"]}.get(link,[])
		if needed.is_empty(): return
		if not needed.all(func(key): return s()[key]):
			page("hester","The link is plausible, but an independent part is still missing.\n\nRequired evidence: "+", ".join(needed.map(func(key): return "Sella's account" if key=="mill_account" else D.EVIDENCE[key].title))+". Your journal keeps the accounts you have already found.",[c("Review the board.","board"),c("Find the missing account.","leave")]); return
		if not s()[link]:
			s()[link] = true
			game.quest_reward("A tested link / "+link,35)
		page("hester","Hester copies the link beneath the records supporting it.\n\n"+("All three claims now stand together. Confront Bran in Alderwake; he must answer the physical evidence, the timeline and the motive." if deductions_done() else "This establishes one part of the case. The other links must stand on their own evidence."),[c("Review the board.","board"),c("Return to the investigation.","leave")]); return
	if a.begins_with("confirm_"):
		if not near("hester") or not s().confession or not s().justice.is_empty(): return
		var decision := a.trim_prefix("confirm_")
		if decision not in ["hearing","exile","conceal"]: return
		page("hester","Seal this disposition: "+decision+"?\n\nBran's future and the public record will follow this decision. The separate choice about the woodland pact is still ahead. This record cannot be changed by asking twice.",[c("Seal the decision.","seal_"+decision),c("Reconsider the alternatives.","justice"),c("Leave it undecided.","leave")]); return
	if a.begins_with("seal_"):
		if not near("hester") or not s().confession or not s().justice.is_empty(): return
		var decision := a.trim_prefix("seal_")
		if decision not in ["hearing","exile","conceal"]: return
		s().justice = decision
		game.quest_reward("Judgement at Alderwake",100)
		game.state.inventory.gold += 20
		s().track = 2 if not s().rescued else 5
		game.world.apply_state()
		page("hester","Hester seals the disposition and makes two copies.\n\n"+("Free the people still held at the root cellars before deciding the forest's future." if not s().rescued else "The prisoners are safe. At the listening oak beyond the Root Court, decide what becomes of the old contract."),[c("Follow the remaining work.","track_"+str(s().track)),c("Let me read the case again.","case_record"),c("I'll be back.","leave")]); return
	if a.begins_with("pact_"):
		if not near("nw_heart") or not s().confession or s().justice.is_empty() or not s().rescued or s().heart_done or s().heart_called: return
		var decision := a.trim_prefix("pact_")
		if decision not in ["accord","sever","inherit"]: return
		if decision=="accord" and not (s().rites and s().maelin_met and s().sella_consent and s().ada_consent):
			note("An agreement needs people","A new accord needs more than your signature. Read the sanctuary consent cords, hear Maelin, and ask Sella and Ada explicitly whether they support the proposal. Ada can answer only after the prisoners are safe. They offer support for themselves; nobody grants consent for another adult.\n\nYou can leave and return without losing any progress.",[c("Follow the willing witnesses.","track_3"),c("Leave the contract undecided.","leave")]); return
		page("maelin","Confirm the oak's future: "+decision+".\n\n"+({"accord":"The binding will accept only personal adult offerings and respect refusal. This limits the protection it can demand payment for.","sever":"You will call the collector into the open. Break its three knots, then defeat it. The sanctuary may keep its faith; the coercive debt ends.","inherit":"Your authority replaces Bran's. The protection remains, along with a clause permitting future forced offerings. Ada and Maelin will name that cost plainly."}[decision]),[c("Commit to this choice.","commit_"+decision),c("Reconsider at the oak.","heart"),c("Leave it for now.","leave")]); return
	if a.begins_with("commit_"):
		var decision := a.trim_prefix("commit_")
		if not near("nw_heart") or not s().confession or s().justice.is_empty() or not s().rescued or not s().pact.is_empty(): return
		if decision not in ["accord","sever","inherit"]: return
		if decision=="accord" and not (s().rites and s().maelin_met and s().sella_consent and s().ada_consent): return
		s().pact = decision
		if decision=="sever":
			s().heart_called = true
			game.set_modal("")
			ensure_encounters()
			game.message("THE BORROWED HEART / Open the three binding knots around the oak before your attacks can harm it.",10)
		else:
			reward("heart_done","What May Be Asked of the Living",180,25)
			note("A contract rewritten",pact_summary()+"\n\nReturn to Hester in Alderwake with the final account.")
		return
	match a:
		"board": board()
		"heart": heart()
		"justice":
			if near("hester") and s().confession and s().justice.is_empty(): justice()
		"confront":
			if not near("bran"): return
			if not deductions_done():
				page("bran","Bran asks which part of your case establishes the murder rather than a general suspicion. You are not ready to answer all three claims yet.\n\n[color=#dec48e]Complete cause, access and motive at Hester's investigation board. Accusations can be revised; missing evidence remains available.[/color]",[c("I'll complete the case.","track_0"),c("We will speak again.","leave")]); return
			if not s().confession:
				s().confession = true
				game.quest_reward("The Shape of a Murder / the confession",120)
				s().track = 4
			bran()
		"bran_pact": page("bran","'The first winter cost me the sound of my mother's voice. I paid it myself. The next, Vey asked what the thieves in my cells had ever given the village.'\n\nBran does not finish the argument. The kiln ledger may finish it for him.",[c("I'll find the written account.","track_1"),c("Enough for now.","leave")])
		"bran_cells": page("bran","'East of the Root Court. Silas, Jory, Teren. All adults. I signed their transfers.'\n\nBran writes the names without calling them offerings. The writing will not release them. Vey has the key; the cellar has a pressure vent beside its release.",[c("They will come home.","track_2"),c("Keep your statement ready.","leave")])
		"victim": page("hester","'Oren sold the right to cut above the springs, evicted people who could not pay, and called it rebuilding. Then he found out what the prisoners were being used for and tried to stop it.'\n\n'We owe him the same care we would owe someone we admired. Otherwise the next investigator will be asked whether the victim was worth the trouble.'",[c("I'll read his inquiry.","track_0"),c("Thank you.","leave")])
		"care":
			if not near("hester"): return
			if game.threats_near(game.player.position,22): game.message("Wait until the yard is safe before resting."); return
			game.state.health = game.state.max_health
			game.state.stamina = 100
			game.state.mana = game.state.max_mana
			game.state.cold = 0
			game.state.wetness = 0
			page("hester","Hester gives you clean water and a place beside the relief stove. Vitality, stamina and focus recover; your clothes dry.\n\nSupplies are in the marked northern road chests. The village and sanctuary are travel stops after you first reach them on foot.",[N.choice("Buy a tonic. [8 coins]","buy_tonic"),c("Read the case record.","case_record"),c("Back to the road.","leave")])
		"sella_statement": page("sella","'Yes. Write exactly what I saw, not what would be useful. Bran's cart. The ninth bell. No face at the sluice.'\n\nHer name goes beneath those sentences alone.",[c("That is the account I'll use.","leave")])
		"sella_life": page("sella","'I keep the clock because my wife made it. It stops every other week. People hear that and decide it's a sign. Mostly it needs a new pin.'\n\nShe turns the gear over. 'At nine I was outside at the gate. I heard the bell from Alderwake and saw the watch cart. That part doesn't need a clock.'",[c("A useful distinction. Thank you.","leave")])
		"faith": page("maelin","'I gave the memory of my sister teaching me to swim. I know she did it. I cannot remember her laughing in the water. A spring ran clear for a winter.'\n\n'Mine to give does not mean harmless to give. We write the cost, wait a night, ask again, and permit refusal. No child may make an offering. No adult may offer another person's memory, body or future.'\n\nVey removed every one of those limits, while keeping the name of the faith.",[c("Could we remember her without another bargain?","vigil_offer"),c("How could a new accord protect refusal?","maelin_help"),c("I'll read the consent cords.","leave")])
		"maelin_help": page("maelin","'I will speak against Vey, and I will open my records. That is late. It is still something I can do.'\n\nFor a new agreement, read the consent cords and ask Sella and Ada for their own support. Bring the prisoners home first. Maelin refuses to take their consent from anyone else's mouth.",[c("I'll ask the people who must live with it.","track_3"),c("I'll remember that limit.","leave")])
		"vigil_offer": page("maelin","'Her name was Enna. I remember the name. I thought I had to buy back the rest.'\n\nThere is a remembrance bowl beside the sanctuary. You may write the ordinary facts Maelin still knows and sit with her. No resource or supernatural offering is required.",[c("I'll use the remembrance bowl.","track_3"),c("Later, when you wish.","leave")])
		"vey_key":
			if not near("vey"): return
			if not (s().prison and s().ledger):
				page("vey","'You are repeating an accusation,' Vey says. 'Bring the transfer roll and the protection ledger. Then tell me whose promises those are.'\n\nHe is buying time. The physical records can be recovered in either order.",[c("I'll bring both originals.","track_2"),c("We are not finished.","leave")]); return
			s().prison_key = true
			page("vey","You read the three names, Bran's receipts, and the forged consent. You offer to publish the copies at every road stop. Vey knows a private bargain cannot survive public witnesses.\n\nHe gives you the release key. This is capitulation, not repentance. The side vent must be opened before the release wheel.",[c("I'll bring them out.","track_2"),c("You will answer for them too.","leave")])
		"vey_heart": page("vey","'A boundary requires a guarantor. Bran pledged what he could command. The oak does not ask whether a prisoner's sentence was fair.'\n\nYou can ask whether that makes the oak evil or makes a terrible contract useful to people who want one. Vey shrugs. He is not interested in the distinction unless it protects his authority.\n\nThe listening oak lies northwest beyond the Root Court. The new accord, if you seek one, needs real adult support from the village.",[c("I will decide after the prisoners are free.","track_5"),c("Enough.","leave")])
		"edric_record": page("edric","Edric makes a clean copy and keeps the stained original.\n\n'The next witness should not have to discover which official story is convenient before telling the truth.'\n\nHe will preserve Oren's abuses, Bran's killing, Vey's coerced pledges, and the sanctuary's refusal rules together.",[c("Keep separate copies.","leave")])
		"edric_hearing": page("edric","'A missing man came home. That should have ended the charge against Maelin. It did, in the room. Outside, people remembered only that she had been charged.'\n\nHe points to the original transcript in the old assize. An accusation can outlive its correction unless someone keeps saying both.",[c("I'll preserve the correction too.","leave")])
		"ada_arrest": page("ada","'Silas took bread. He didn't ask me to say he hadn't. Oren's stores were full; ours weren't. A fair sentence could still be argued about. Nobody sentenced him to belong to a tree.'\n\nAda has kept the watch's release promise. Its date matches the transfer roll's forged consent.",[c("I'll compare the records.","leave")])
		"consent_sella":
			if not near("sella"): return
			if not s().rites:
				page("sella","'Bring me the actual refusal rules. I won't sign a promise that only sounds kind when someone explains it.'",[c("I'll read the sanctuary cords.","track_3"),c("Fair enough.","leave")]); return
			s().sella_consent = true
			page("sella","'I support an accord where no one owes anything for refusing, and only an adult can offer something of their own. I might offer maintenance work upstream. I will not offer my wife's memory for her.'\n\nSella signs support for that rule, not consent to any future offering.",[c("Those are the terms I'll carry.","leave")])
		"consent_ada":
			if not near("ada"): return
			if not s().rescued or not s().rites:
				page("ada","'Bring my brother home and bring the written refusal rules. I will not negotiate while people are held beneath the roots.'",[c("I'll do both.","track_2"),c("I understand.","leave")]); return
			s().ada_consent = true
			page("ada","'I support the right to refuse. That includes refusing the whole faith. If Maelin will say that in public, I can live beside her sanctuary. I speak for myself. Silas will answer when he's ready.'\n\nAda signs that condition. She grants nobody authority to pledge a prisoner or a child.",[c("That is the agreement I'll ask for.","leave")])
		"winter_help": page("ada","'Ordinary work. Grain counted honestly. Roofs repaired before snow. The old assize had emergency stores; Oren said they were gone. Edric may know where the depot was.'\n\nThe depot is southwest of the Burned Assize. Recovering it changes the cost of severing the pact; it is not required to choose freedom.",[c("I'll check the depot.","track_1"),c("Thank you.","leave")])
		"boat_return":
			if not near("nell") or not s().boat or s().boat_returned: return
			reward("boat_returned","A Boat, Not a Burden",35,0)
			page("nell","Nell sets the boat in a basin and watches it turn. Hester asks whether she wants to talk about anything else.\n\nNell asks whether boats need names. For a while that is the only question anybody expects her to answer.",[c("Give the boat a good voyage.","leave")])
		"rescue_force":
			if not near("nw_gate") or s().rescued or s().prison_key: return
			s().rescue_started = true
			game.set_modal("")
			ensure_encounters()
			game.message("Two debt collectors defend the cellars. Keep their attacks away from the chamber; evade the long reach, then counter.",8)
		"case_record": note("The casebook",journal())
		"complete":
			if not near("hester") or not s().heart_done: return
			reward("completed","The Shape of a Murder / the living account",200,30)
			hester()

func interact(id: String) -> void:
	origin = id
	if not start(): return
	var key := id.trim_prefix("nw_")
	if D.EVIDENCE.has(key):
		if not s()[key]:
			s()[key] = true
			game.state.log_event("woods_evidence:"+key)
			game.state.xp += 12
			game.audio.play_effect("quest")
			if key=="winter": game.state.inventory.bread += 4; game.state.inventory.wood += 3
		var record: Dictionary = D.EVIDENCE[key]
		note(record.title,record.body+"\n\n[color=#dec48e]Copied into the casebook. Evidence can be discovered before its related conversation. J / M opens the journal.[/color]")
		return
	match key:
		"notice": note("Alderwake's appeal","Reeve Oren is dead. A charcoal antler has been drawn across the watch's notice blaming the Old Faith. A smaller sheet asks witnesses to speak to Hester, the coroner, before anyone begins a purge.\n\nAlderwake lies a short walk north of the hospice. The sluice is on its east road; the sanctuary is west.",[c("Follow the appeal to Hester.","track_0"),c("Keep walking.","leave")])
		"caseboard": board()
		"vent":
			if not s().prison_key and not s().rescue_started:
				note("A locked pressure vent","The release key opens this housing. Vey carries it. Or confront the collectors at the cellar gate and take the housing apart once they are defeated."); return
			if s().rescue_started and not s().prison_key and not ["nw_cell_guard_1","nw_cell_guard_2"].all(func(uid): return game.state.defeated.has(uid)):
				game.message("The collectors still control the vent housing."); return
			s().vented = true
			game.world.apply_state()
			note("The pressure falls","You open the side vent slowly. Air escapes from the binding roots and the chamber shutters stop straining. The main release can now open without harming the prisoners.")
		"gate": prison_gate()
		"heart": heart()
		"ward_west","ward_east","ward_north":
			if not s().heart_called:
				note("A knot in an old promise","A name has been bound into the oak's debt. It will open if the collector is called out during a decision to sever the contract. You can also seek a new voluntary accord instead of a fight."); return
			s()[key] = true
			game.world.apply_state()
			game.set_modal("")
			game.message("Binding opened. "+("All three are open: the Borrowed Heart can now be harmed." if wards_open() else "Open the remaining knots around the oak."),6)
		"vigil":
			if not s().maelin_met:
				note("A bowl for ordinary remembrance","A little card invites people to write what they still know of someone they miss. Speak to Maelin before adding anything in her name."); return
			reward("vigil","The Part We Still Remember",50)
			note("Enna, who taught her sister to swim","You write the name Enna and the facts Maelin still knows: she laughed at cold water, taught her younger sister to float, and always carried an extra towel.\n\nThe lost memory does not return. Maelin reads the card anyway. 'I can tell someone this much,' she says. No one asks the woods to take anything in exchange.")

func ensure_encounters() -> void:
	if game.coop.active and not game.coop.is_host: return
	var entries: Array = []
	if s().rescue_started and not s().rescued and not s().prison_key:
		entries.append_array([["nw_cell_guard_1","pitchbound",Vector2(129,-1567)],["nw_cell_guard_2","bandit",Vector2(155,-1574)]])
	if s().heart_called and not s().heart_done:
		entries.append(["nw_borrowed_heart","rootwarden",Vector2(-95,-1780)])
	for entry in entries:
		if game.state.defeated.has(entry[0]) or game.enemies.any(func(enemy): return enemy.id==entry[0]): continue
		game.spawn_enemy(entry[0],entry[1],entry[2])

func tick(_dt: float) -> void:
	if not s().started: return
	ensure_encounters()
	if s().heart_called and not s().heart_done and game.state.defeated.has("nw_borrowed_heart"):
		reward("heart_done","A Debt That Cannot Be Collected",180,25)
		game.message("The old contract breaks. The sanctuary remains a place of belief; the debt can no longer bind anyone. Return to Hester.",10)

func goal(text: String, id: String) -> Dictionary:
	return {"text":text,"pos":D.NPCS[id].pos if D.NPCS.has(id) else D.OBJECTS[id].pos}

func objective() -> Dictionary:
	var q := s()
	if not q.started or not q.briefed: return goal("Chapter III / Hear Hester's appeal in Alderwake, north of the hospice.","hester")
	if q.completed: return {"text":"The Rowan March account is complete. Optional kindnesses and earlier stories remain open.","complete":true}
	if q.heart_done: return goal("Return to Hester in Alderwake with the final account.","hester")
	var track := int(q.track)
	if track==1:
		if not q.sella_met: return goal("Hear Sella's precise account at Blackwater Sluice.","sella")
		if not q.edric_met: return goal("Hear Edric at the Burned Assize, west of the Root Court.","edric")
		if not q.boat: return goal("Optional / recover Nell's toy boat below the sluice.","nw_boat")
		if not q.boat_returned: return goal("Return the toy boat to Nell in Alderwake.","nell")
		if not q.winter: return goal("Recover emergency winter stores southwest of the old assize.","nw_winter")
		return goal("Witnesses heard. Review the case with Hester.","hester")
	if track==2 and not q.rescued:
		if not q.prison: return goal("Read the prisoner roll at the eastern root cellars.","nw_prison")
		if not q.ledger: return goal("Find the protection ledger at the White Kiln.","nw_ledger")
		if not q.prison_key and not q.rescue_started: return goal("Confront Vey with both records, or force the cellar gate.","vey")
		if q.rescue_started and not q.prison_key and not ["nw_cell_guard_1","nw_cell_guard_2"].all(func(id): return game.state.defeated.has(id)): return goal("Defeat the two debt collectors at the cellars.","nw_gate")
		if not q.vented: return goal("Open the side pressure vent before turning the cellar release.","nw_vent")
		return goal("Open the release and bring the three prisoners home.","nw_gate")
	if track==3:
		if not q.maelin_met: return goal("Hear Maelin at Rowan Sanctuary.","maelin")
		if not q.rites: return goal("Read the sanctuary's consent and refusal cords.","nw_rites")
		if not q.rescued: return goal("Free the prisoners before asking Ada about a voluntary accord.","nw_gate")
		if not q.sella_consent: return goal("Ask Sella for her own support of the refusal rules.","sella")
		if not q.ada_consent: return goal("Ask Ada for her own support after the rescue.","ada")
		if not q.vigil: return goal("Optional / remember Enna at the sanctuary bowl.","nw_vigil")
		return goal("The voluntary witnesses are ready. Decide at the listening oak.","nw_heart")
	if track==5 and not q.justice.is_empty() and q.rescued:
		if q.heart_called:
			for key in ["ward_west","ward_east","ward_north"]:
				if not q[key]: return goal("Open the three binding knots / "+key.replace("_"," "),"nw_"+key)
			return goal("Defeat the Borrowed Heart. Evade the long attack warning.","nw_heart")
		return goal("Decide the pact at the listening oak beyond the Root Court.","nw_heart")
	if q.confession:
		if q.justice.is_empty(): return goal("Bring Bran's confession to Hester; choose justice separately from faith.","hester")
		if not q.rescued: return goal("Bring the prisoners home from the eastern root cellars.","nw_gate")
		return goal("Decide the woodland pact at the listening oak.","nw_heart")
	for row in [["body","Inspect Oren's covered remains at the sluice.","nw_body"],["bolt","Search the drained channel for the missing bolt.","nw_bolt"],["watch","Read the unaltered watch book in Alderwake.","nw_watch"],["mill_account","Ask Sella about the stopped clock and ninth bell.","sella"],["mould","Compare the bolt mould at the White Kiln.","nw_mould"],["letter","Read Oren's undelivered inquiry in Alderwake.","nw_letter"],["ledger","Read the protection ledger at the kiln.","nw_ledger"],["prison","Read the prisoner transfer roll at the cellars.","nw_prison"]]:
		if not q[row[0]]: return goal(row[1],row[2])
	if not deductions_done(): return goal("Link cause, access and motive at Hester's board in Alderwake.","nw_caseboard")
	return goal("Confront Bran with the three corroborated links.","bran")

func journal() -> String:
	var q := s()
	var text := "\n[color=#e2c38a]CHAPTER III / THE SHAPE OF A MURDER[/color]\n"
	if not q.started: return text+"Alderwake is north of the hospice. Finish the hospice bell, then follow its road to Hester's appeal.\n"
	text += "Tracked: "+D.TRACKS[int(q.track)]+"\n"+objective().text+"\n\n"
	text += "Reeve Oren was found with an antler sign. Establish an act, not a faith's guilt. The sluice and sanctuary can be investigated independently. No evidence expires. Wrong deductions can be revised.\n"
	for row in [[q.cause,"Cause / body and recovered bolt"],[q.access,"Access / watch book, Sella, bolt mould"],[q.motive,"Motive / inquiry, protection ledger, prisoner roll"],[q.confession,"Confront Bran with the three links"],[not q.justice.is_empty(),"Decide the public account with Hester"],[q.rescued,"Release Silas, Jory and Teren safely"],[q.heart_done,"Decide the listening oak's contract"],[q.completed,"Bring the final account to Hester"]]:
		text += ("[done] " if row[0] else "[open] ")+row[1]+"\n"
	text += "\n[color=#dec48e]INDEPENDENT ACCOUNTS[/color]\n"
	if q.mill_account: text += "Sella: mill clock stopped at eight; Bran's cart present at the ninth bell. She did not see the killing.\n"
	if q.scribe_account: text += "Edric: Bran followed Oren with the watch crossbow and later ordered a false public notice.\n"
	if q.nell_met: text += "Nell, twelve: heard a cart, saw no killer. Her recollection is optional and cannot support an accusation.\n"
	if q.rescued: text += "Silas, Jory, Teren: brought by Bran, held by Vey, refused release. All three returned alive.\n"
	for key in D.EVIDENCE:
		if q[key]: text += "\n[b]"+D.EVIDENCE[key].title+"[/b]\n"+D.EVIDENCE[key].body+"\n"
	text += "\n[color=#dec48e]THE SANCTUARY / OPTIONAL WORK[/color]\n"
	for row in [[q.maelin_met,"Hear Maelin's account"],[q.rites,"Read the refusal rules"],[q.sella_consent,"Sella supports a voluntary accord"],[q.ada_consent,"Ada supports refusal, after the rescue"],[q.vigil,"Remember Enna without another offering"],[q.boat_returned,"Return Nell's boat; keep the child safe"],[q.winter,"Recover winter stores for an independent village"]]:
		text += ("[done] " if row[0] else "[open] ")+row[1]+"\n"
	if not q.justice.is_empty(): text += "\nJustice: "+q.justice+". Sealed; the separate forest choice does not rewrite it.\n"
	if not q.pact.is_empty(): text += "\nWoodland pact: "+q.pact+".\n"+pact_summary()+"\n"
	text += "\nNAVIGATION / Alderwake is north of the hospice. East: sluice, kiln, cellars. West: sanctuary, assize. Both roads meet at the Root Court. Northwest beyond it: listening oak. Cycle the three map sheets with the map button. First reach each travel stop on foot.\n"
	return text
