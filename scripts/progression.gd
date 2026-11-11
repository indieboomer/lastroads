extends RefCounted

const THRESHOLDS := [0,60,160,320,550]
const TRACKS := {
 "ranger":["Road scout: pistol, musket and weak dagger", "Well-packed shot: +10% firearm damage", "Practised hands: reloads are 20% faster", "Knife craft: dagger gains 4 damage", "Patient shot: +15% damage after aiming for one second"],
 "warrior":["Road guard: Second Wind and Driving Strike", "Tempered edge: +10% blade damage", "Rally: Second Wind also heals 12 vitality", "Hooking blow: Driving Strike cleaves nearby foes", "Veteran guard: blocked damage reduced by half"],
 "mage":["Apprentice: Dart, Ember, Rime and Repulsion", "Kindling: Ember burns for 2 extra seconds", "Learn Cinder Ring: close fire burst, prepare at safe rest", "Deep frost: Rime holds for 2 extra seconds", "Shattercraft: Brittle Dart gains 12 damage"],
 "cleric":["Road cleric: Staff, Judgement, Sanctuary and Rebuke", "Consecrated oak: staff gains 4 damage", "Learn Litany: heal and interrupt nearby foes, prepare at safe rest", "Long vigil: Sanctuary heals twice as quickly", "Steadfast: Rebuke costs 6 mana and recovers in 3 seconds"]
}
static func rank(xp: int) -> int:
 var result := 0
 for threshold in THRESHOLDS:
  if xp>=threshold: result += 1
 return result
static func spells(job: String, xp: int) -> Array:
 var list: Array = {"mage":["ember","rime"],"cleric":["judgement","sanctuary"]}.get(job,[]).duplicate()
 if rank(xp)>=3 and job in ["mage","cleric"]: list.append("cinder_ring" if job=="mage" else "litany")
 return list
static func journal(job: String, xp: int) -> String:
 var text := "\n[ color=#e2c38a]PROFESSION PROGRESSION[/color]\n".replace("[ color","[color")
 text += "Rank %d/5 / %d XP (quests and defeated foes)\n" % [rank(xp),xp]
 for i in range(5): text += ("Learned: " if rank(xp)>i else "%d XP: " % THRESHOLDS[i])+TRACKS[job][i]+"\n"
 return text
