extends RefCounted

# Reward-budget targets for an exploratory run: level 2 at 10-15 minutes,
# level 3 near 30 minutes, level 4 near 60 minutes. No XP is awarded for idling.
const THRESHOLDS := [0,250,1000,2400,4000]
const LEGACY_THRESHOLDS := [0,60,160,320,550]
const VERSION := 2
const TRACKS := {
 "ranger":["Road scout: pistol, musket and weak dagger", "Well-packed shot: +10% firearm damage", "Practised hands: reloads are 20% faster", "Knife craft: dagger gains 4 damage", "Patient shot: +15% damage after aiming for one second"],
 "warrior":["Road guard: Second Wind and Driving Strike", "Tempered edge: +10% blade damage", "Rally: Second Wind also heals 12 vitality", "Hooking blow: Driving Strike cleaves nearby foes", "Veteran guard: blocked damage reduced by half"],
 "mage":["Apprentice: Dart, Ember, Rime and Repulsion", "Kindling: Ember burns for 2 extra seconds", "Learn Cinder Ring: close fire burst, prepare at safe rest", "Deep frost: Rime holds for 2 extra seconds", "Shattercraft: Brittle Dart gains 12 damage"],
 "cleric":["Road cleric: Staff, Judgement, Sanctuary and Rebuke", "Consecrated oak: staff gains 4 damage", "Learn Litany: heal and interrupt nearby foes, prepare at safe rest", "Long vigil: Sanctuary heals twice as quickly", "Steadfast: Rebuke costs 6 mana and recovers in 3 seconds"]
}
static func legacy_rank(xp: int) -> int:
 var result := 1
 for i in range(LEGACY_THRESHOLDS.size()):
  if xp>=LEGACY_THRESHOLDS[i]: result = i+1
 return result

static func rank(xp: int, earned_floor := 1) -> int:
 var result := 0
 for threshold in THRESHOLDS:
  if xp>=threshold: result += 1
 return maxi(earned_floor,result)
static func next_threshold(xp: int, earned_floor := 1) -> int:
 var level := rank(xp,earned_floor)
 return THRESHOLDS[level] if level<THRESHOLDS.size() else -1

static func spells(job: String, xp: int, earned_floor := 1) -> Array:
 var list: Array = {"mage":["ember","rime"],"cleric":["judgement","sanctuary"]}.get(job,[]).duplicate()
 if rank(xp,earned_floor)>=3 and job in ["mage","cleric"]: list.append("cinder_ring" if job=="mage" else "litany")
 return list
static func journal(job: String, xp: int, earned_floor := 1) -> String:
 var text := "\n[ color=#e2c38a]PROFESSION PROGRESSION[/color]\n".replace("[ color","[color")
 text += "Level %d/5 / %d XP (quests, exploration and defeated foes)\n" % [rank(xp,earned_floor),xp]
 for i in range(5): text += ("Learned: " if rank(xp,earned_floor)>i else "%d XP: " % THRESHOLDS[i])+TRACKS[job][i]+"\n"
 return text
