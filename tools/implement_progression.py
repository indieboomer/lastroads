from pathlib import Path
r=Path('.')
def edit(p,a,b):
 f=r/p;s=f.read_text(encoding='utf-8');assert a in s,(p,a[:60]);f.write_text(s.replace(a,b),encoding='utf-8')
Path('scripts/progression.gd').write_text('''extends RefCounted

const THRESHOLDS := [0,60,160,320,550]
const TRACKS := {
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
 if rank(xp)>=3 and job!="warrior": list.append("cinder_ring" if job=="mage" else "litany")
 return list
static func journal(job: String, xp: int) -> String:
 var text := "\\n[ color=#e2c38a]PROFESSION PROGRESSION[/color]\\n".replace("[ color","[color")
 text += "Rank %d/5 / %d XP (quests and defeated foes)\\n" % [rank(xp),xp]
 for i in range(5): text += ("Learned: " if rank(xp)>i else "%d XP: " % THRESHOLDS[i])+TRACKS[job][i]+"\\n"
 return text
''',encoding='utf-8')
edit('scripts/state.gd','var health :=','const Progression = preload("res://scripts/progression.gd")\n\nfunc rank() -> int:\n\treturn Progression.rank(xp)\n\nvar health :=')
edit('scripts/state.gd','if not loaded_slots is Array or loaded_slots.size()!=allowed.size(): return false\n\t\tfor spell in allowed:\n\t\t\tif loaded_slots.count(spell)!=1: return false','allowed = Progression.spells(loaded_profile.profession_id,int(d.xp))\n\t\tif not loaded_slots is Array or loaded_slots.size()!=(0 if loaded_profile.profession_id=="warrior" else 2): return false\n\t\tfor spell in loaded_slots:\n\t\t\tif spell not in allowed or loaded_slots.count(spell)!=1: return false')
edit('scripts/profession_combat.gd','"sanctuary":24.0}','"sanctuary":24.0,"cinder_ring":22.0,"litany":26.0}')
edit('scripts/profession_combat.gd','"sanctuary":14.0}','"sanctuary":14.0,"cinder_ring":9.0,"litany":16.0}')
edit('scripts/profession_combat.gd','24.0+(4.0 if','24.0+(4.0 if game.state.rank()>=2 else 0.0)+(4.0 if')
edit('scripts/profession_combat.gd','var cost := 10.0 if profession()=="cleric" else 12.0','var cost := (6.0 if game.state.rank()>=5 else 10.0) if profession()=="cleric" else 12.0')
edit('scripts/profession_combat.gd','5.0 if profession()=="cleric" else 8.0','(3.0 if game.state.rank()>=5 else 5.0) if profession()=="cleric" else 8.0')
edit('scripts/profession_combat.gd','elif spell=="judgement":','elif spell in ["cinder_ring","litany"]:\n\t\tif spell=="litany": game.state.health = minf(game.state.max_health,game.state.health+22.0)\n\t\tfor enemy in game.enemies:\n\t\t\tif enemy.dead or enemy.position.distance_to(game.player.position)>5.0 or not game.line_clear(game.camera.global_position,enemy.position+Vector3.UP): continue\n\t\t\tenemy.hit(28.0 if spell=="cinder_ring" else 8.0,false,false)\n\t\t\tif spell=="cinder_ring": enemy.burning = 3.0\n\t\t\telse: enemy.force_reaction((enemy.position-game.player.position).normalized(),2.0,1.0,1.0)\n\t\tring(game.player.position+Vector3.UP*.1,5.0,COLOURS.ember if spell=="cinder_ring" else COLOURS.judgement,.8)\n\telif spell=="judgement":')
edit('scripts/profession_combat.gd','game.audio.play_effect(spell)','game.audio.play_effect("ember" if spell=="cinder_ring" else "sanctuary" if spell=="litany" else spell)')
edit('scripts/profession_combat.gd','game.state.health+2.0*dt','game.state.health+(4.0 if game.state.rank()>=4 else 2.0)*dt')
edit('scripts/profession_combat.gd','damage += 18.0','damage += 30.0 if game.state.rank()>=5 else 18.0')
edit('scripts/profession_combat.gd','enemy.burning = 3.0\n\t\t\tif kind','enemy.burning = 5.0 if game.state.rank()>=2 else 3.0\n\t\t\tif kind')
edit('scripts/profession_combat.gd','enemy.rimed = 4.0','enemy.rimed = 6.0 if game.state.rank()>=4 else 4.0')
edit('scripts/interface.gd','select.item_selected.connect(func(value): preparation_slots[1-index].select(1-value))','select.item_selected.connect(func(value):\n\t\t\t\tif preparation_slots[1-index].selected==value:\n\t\t\t\t\tpreparation_slots[1-index].select((value+1)%select.item_count))')
edit('scripts/interface.gd','game.combat.SPELLS[game.state.profile.profession_id]','game.state.Progression.spells(game.state.profile.profession_id,game.state.xp)')
edit('scripts/interface.gd','Choose the order of your two memorised spells.','Choose two learned spells for C and V.')
edit('scripts/interface.gd','profession_label.text += "\\nC:','profession_label.text += " / Rank %d / %d XP" % [s.rank(),s.xp]\n\tprofession_label.text += "\\nC:')
edit('scripts/game.gd','\treturn lines\n','\tlines += state.Progression.journal(state.profile.profession_id,state.xp)\n\tlines += "\\nDEEP WOODS\\nRisk rises away from roads and settlements. Tar on bark warns of the Pitchbound; high scratches warn of the Boughstalker. Bait the poker and punish its recovery. Sidestep the pale hunter; strike during its warning to interrupt.\\n"\n\treturn lines\n')
edit('scripts/game.gd','foe.hit(state.damage*1.5,true)','foe.hit(state.damage*1.5*(1.1 if state.rank()>=2 else 1.0),true)\n\t\t\tif state.rank()>=4:\n\t\t\t\tfor other in enemies:\n\t\t\t\t\tif other!=foe and not other.dead and other.position.distance_to(foe.position)<2.5 and line_clear(camera.global_position,other.position+Vector3.UP): other.hit(state.damage*.65,true)')
edit('scripts/game.gd','state.stamina = minf(100,state.stamina+35)','state.stamina = minf(100,state.stamina+35)\n\t\t\tif state.rank()>=3: state.health = minf(state.max_health,state.health+12.0)')
edit('scripts/game.gd','state.damage*(1.8 if heavy else 1.0)','state.damage*(1.1 if state.rank()>=2 else 1.0)*(1.8 if heavy else 1.0)')
edit('scripts/game.gd','damage = 0 if parry else 2','damage = 0 if parry else (1 if state.rank()>=5 else 2)\n\t\tif family=="pitchbound" and not parry: damage += 5')
