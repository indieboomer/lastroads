extends RefCounted

const C = preload("res://scripts/content.gd")
const N = preload("res://scripts/narrative.gd")
const STOPS := {
	"inn":Vector2(0,42), "grove":Vector2(-77,-58),
	"gate":Vector2(13,-102), "mill":Vector2(-111,-158),
	"chapel":Vector2(122,-190), "tower":Vector2(7,-334),
	"ash_refuge":Vector2(-61,-518), "ash_ferry":Vector2(135,-594),
	"nw_village":Vector2(-7,-1081), "nw_sanctuary":Vector2(-143,-1316), "nw_court":Vector2(17,-1630)
}
const CONTACTS := ["mara","ilya","rook","sister","vesna","merchant","nera","lucan","hester","maelin","vey"]
var game: Node
var menu_page := 0
var stride_clock := 0.0
var scan_clock := 0.0
var last_position := Vector3.ZERO

func reset() -> void:
	stride_clock = 0
	scan_clock = 0
	last_position = game.player.position

func nearest_stop() -> String:
	if game.in_crypt(): return ""
	var at := Vector2(game.player.position.x,game.player.position.z)
	for id in STOPS:
		if at.distance_to(STOPS[id])<20: return id
	return ""

func resolved(id: String) -> bool:
	var f: Dictionary = game.state.flags
	match id:
		"inn": return true
		"grove": return f.herbs_done
		"gate": return f.supplies and f.scout
		"mill": return f.bargain or game.state.defeated.has("mill_enforcer_1") and game.state.defeated.has("mill_enforcer_2")
		"chapel": return f.relic
		"tower": return f.prepared and (not f.beacon_lit or f.won)
		"nw_village", "nw_sanctuary", "nw_court": return game.state.woods.started
		"ash_refuge", "ash_ferry": return f.won and game.state.story.ferry_fixed
	return false

func available(id: String) -> bool:
	if not STOPS.has(id) or not resolved(id): return false
	# First arrival must be on foot. Existing discovered saves count as visits.
	if not game.state.discovered.get(id,false): return false
	return not game.threats_near(C.ground(STOPS[id]),22)

func travel_reason(id: String) -> String:
	var from := nearest_stop()
	if from.is_empty(): return "Depart from a settlement travel stop."
	if game.threats_near(game.player.position,22): return "Danger is too close to depart."
	if not available(from): return "Resolve this stop's trouble and clear nearby danger first."
	if not STOPS.has(id): return "Unknown travel stop."
	if not game.state.discovered.get(id,false): return "Visit on foot first."
	if not resolved(id):
		match id:
			"grove": return "Help Vesna first."
			"gate": return "Recover the stores and hear Ilya's report."
			"mill": return "Resolve Rook's bargain or guards."
			"chapel": return "Recover the clapper first."
			"tower": return "Prepare for Northwatch; finish any defence."
			"ash_refuge", "ash_ferry": return "Restore Reedwater's ferry first."
	if not available(id): return "Danger near the destination."
	if from==id: return "You are already here."
	if (from.begins_with("ash_") or id.begins_with("ash_")) and not game.state.story.ferry_fixed:
		return "Restore Reedwater's ferry first."
	return ""

func speaker() -> String:
	if game.dialogue_id in CONTACTS and game.world.npcs.has(game.dialogue_id) and game.world.npcs[game.dialogue_id].position.distance_to(game.player.position)<10:
		return game.dialogue_id
	match nearest_stop():
		"gate": return "ilya"
		"mill": return "rook"
		"chapel": return "sister"
		"grove": return "vesna"
		"nw_village": return "hester"
		"nw_sanctuary": return "maelin"
		"nw_court": return "vey"
		"ash_refuge": return "nera"
		"ash_ferry": return "lucan"
		"tower": return "merchant" if game.state.flags.won else "ilya"
	return "mara"

func page(body: String, choices: Array) -> void:
	var id := speaker()
	game.dialogue_id = id
	game.ui.show_dialog(id,N.page(body,choices))
	game.ui.dialog_body.text = body
	game.ui.powder_button.hide()

func services() -> void:
	page("Roadkeepers pass medicine and messages between the remaining hearths. You can continue your journey while they carry the supplies.\n\nVisited, secured stops offer free passage. The ferry still connects the Hollow to the March.",[
		N.choice("Arrange onward travel.","journey:menu:0"),
		N.choice("Send medicine / settle errands.","journey:errands"),
		N.choice("Back to our conversation.","return")])

func travel_menu(index := 0) -> void:
	var ids: Array = STOPS.keys()
	var pages := ceili(ids.size()/2.0)
	menu_page = posmod(index,pages)
	var choices: Array = []
	for i in range(menu_page*2,menu_page*2+2):
		if i>=ids.size(): break
		var id: String = ids[i]
		choices.append(N.choice(C.SITES[id].name,"journey:go:"+id))
	choices.append(N.choice("More stops (%d/%d). Esc closes." % [menu_page+1,pages],"journey:menu:"+str(menu_page+1)))
	page("Travel with the roadkeepers. Depart from a visited, secured stop. First visit each destination on foot and resolve its local trouble. No passage while danger waits at either end.\n\nThe inn, grove, toll, mill, chapel and Northwatch share the Hollow road. Repair the ferry to reach Saint Mere and Reedwater. The northern stops at Alderwake, Rowan Sanctuary and the Root Court join the road after a first visit on foot.",choices)

func errands() -> void:
	page("Leave three yarrow for Vesna, or send three moonwort to Tomas after you have met him in the fen. A runner carries the medicine; the same agreed reward is paid here.\n\nYou can still deliver either medicine in person.",[
		N.choice("Send Vesna's yarrow. [2 tonics, 20 coins, 40 XP]","journey:yarrow"),
		N.choice("Send Tomas's moonwort. [35 coins, 60 XP]","journey:moonwort"),
		N.choice("Back to road services.","journey:services")])

func requirement(action: String) -> Dictionary:
	var reason := ""
	if action.begins_with("journey:go:"):
		reason = travel_reason(action.trim_prefix("journey:go:"))
	elif action in ["journey:yarrow","journey:moonwort"]:
		var yarrow := action=="journey:yarrow"
		var f: Dictionary = game.state.flags
		if nearest_stop().is_empty() or game.threats_near(game.player.position,22): reason = "Find a safe settlement contact."
		elif (f.herbs_done if yarrow else f.courier_done): reason = "Already completed."
		elif not (f.herbalist if yarrow else game.state.discovered.get("met_courier",false)): reason = "Speak to Vesna first." if yarrow else "Meet Tomas in the fen first."
		elif game.state.inventory["yarrow" if yarrow else "moonwort"]<3: reason = "Need three yarrow." if yarrow else "Need three moonwort."
	return {"allowed":reason.is_empty(),"reason":reason}

func choose(action: String) -> void:
	var check := requirement(action)
	if not check.allowed: game.message(check.reason); return
	if action=="journey:services": services()
	elif action=="journey:errands": errands()
	elif action.begins_with("journey:menu:"): travel_menu(int(action.get_slice(":",2)))
	elif action.begins_with("journey:go:"):
		var id := action.trim_prefix("journey:go:")
		game.set_modal("")
		game.teleport(STOPS[id])
		game.update_location()
		game.state.log_event("road_passage:"+id)
		game.message("The roadkeepers bring you to "+C.SITES[id].name+".",6)
	elif action in ["journey:yarrow","journey:moonwort"]:
		game._local_choose_dialog("give_yarrow" if action=="journey:yarrow" else "save_courier")
		game.world.apply_state()
		game.message("A runner takes the medicine. Your agreed reward is paid here.",7)

func stride(dt: float, moving: bool) -> bool:
	var at := Vector2(game.player.position.x,game.player.position.z)
	if not moving or not nearest_stop().is_empty() or game.in_crypt() or C.distance_to_road(at)>4 or game.threats_near(game.player.position,25) or game.blocking or game.attack_clock>0 or game.player_stagger>0 or game.state.cold>65 or game.ranger.active() and game.state.ranger.reload_left>0:
		stride_clock = 0
		return false
	stride_clock += dt
	return stride_clock>=5

func tick(dt: float) -> void:
	var gap: float = game.player.position.distance_to(last_position)
	last_position = game.player.position
	if gap<0.01 or gap>3 or game.in_crypt(): return
	game.state.journey.interest = minf(30,game.state.journey.interest+dt)
	game.state.journey.story = minf(300,game.state.journey.story+dt)
	scan_clock += dt
	if scan_clock<1: return
	scan_clock = 0
	if game.threats_near(game.player.position,25): return
	if game.ui.toast_timer>0 or game.ui.discovery_timer>0: return
	if game.state.journey.story>=300:
		story_beat()
		game.state.journey.story = 0.0
	elif game.state.journey.interest>=30:
		interest_beat()
		game.state.journey.interest = 0.0

func interest_beat() -> void:
	var best := 100.0
	var hint := ""
	var hint_id := ""
	for id in C.OBJECTS:
		if not (id.begins_with("forest_cache_") or id.begins_with("road_find_")) or game.state.taken.has(id) or game.state.discovered.has("journey_hint_"+id): continue
		var delta: Vector2 = C.OBJECTS[id].pos-Vector2(game.player.position.x,game.player.position.z)
		if delta.length()>=best: continue
		best = delta.length()
		hint_id = id
		var compass := "east" if delta.x>0 else "west"
		if absf(delta.y)>absf(delta.x): compass = "south" if delta.y>0 else "north"
		hint = "Roadkeeper's trail: supplies to the %s, %s. Look for a low chest." % [compass,"among the trees" if id.begins_with("forest_cache_") else "on the road verge"]
	if not hint.is_empty():
		game.state.discovered["journey_hint_"+hint_id] = true
		game.message(hint,7)
	else:
		var lines := ["Old wheel ruts run beneath the needles. Someone still expected this road to open.","A strip of lamp-black cloth marks the next bend: the roadkeepers' sign for a safe way onward.","Beyond the branches, a crow answers another. The road is quiet enough to hear your own pack creak.","A bootprint holds rain beside the stones. The sole was patched with string, like the mill workers' shoes."]
		var index: int = int(game.state.journey.observations)%lines.size()
		game.message(lines[index],7)
		game.state.journey.observations += 1
	game.state.log_event("journey_interest")

func story_beats() -> Array:
	var f: Dictionary = game.state.flags
	return [
		["promise",not f.won,"A lamp at the other end","Mara's inn is a patch of warmth behind you. Every empty cart on this road was once expected home. Somewhere ahead, Northwatch still waits for its light."],
		["oil",f.oil,"The weight of ordinary things","The mill's last lamp oil was enough to give Northwatch a chance. The next wagon through should carry flour back to Rook's people. A light on a tower means little if the hearths below it stay cold."],
		["clapper",f.relic,"The bell's promise","Root remembers. Flame forgives. Bell calls home. The dead beneath the chapel asked for remembrance. The clapper you carried out of the dark was once a familiar sound at the end of an ordinary day."],
		["courier",f.courier_done,"News for the living","Tomas's letters are no longer sinking into the fen. A dozen people may learn that someone still remembers them. Keeping a road open means keeping those small promises moving."],
		["beacon",f.won,"The road answers","Northwatch's light catches between the trunks. The same stones now lead toward occupied hearths. There will be complaints about prices and weather again. An ordinary tomorrow has begun."],
		["march",game.state.story.started,"The names we carry","Beyond the restored road are people who were counted as losses before anyone asked their names. Nera's sickbeds are waiting. What you carry north now is more than lamp oil."],
		["ferry",game.state.story.ferry_fixed,"Two shores","A rope, a few timbers, iron brackets: enough to bring two shores together. Grain and letters can cross beside the living. Some repairs are small enough to hold in your hands."],
		["verdict",not game.state.story.verdict.is_empty(),"An answer on the road","Word of your judgement travels behind you. At the next hearth someone will repeat it, perhaps differently. The people at Saint Mere must live with what the road carries."],
		["bell",game.state.story.bell_done,"Let the living speak","The hospice bell no longer keeps its silence. Names have a way of outlasting the ledgers that tried to bury them. There are still people on this road who need to be heard."]]
func story_beat() -> void:
	var beats := story_beats()
	for i in range(beats.size()-1,-1,-1):
		var beat: Array = beats[i]
		var key: String = "journey_story_"+beat[0]
		if not beat[1] or game.state.discovered.has(key): continue
		game.state.discovered[key] = true
		game.ui.discover(beat[2],"A thought carried along the road")
		game.message(beat[3],16)
		game.state.log_event(key)
		return
	game.ui.discover("A little farther",game.target().text)
	game.message("Behind each shutter is someone waiting for the road to become ordinary again. You check your bearings and carry on.",10)
	game.state.log_event("journey_story_bearings")

func journal() -> String:
	var text := "\n[color=#e2c38a]THOUGHTS FROM THE ROAD[/color]\n"
	for beat in story_beats():
		if game.state.discovered.has("journey_story_"+beat[0]): text += beat[2]+"\n"+beat[3]+"\n\n"
	return text
