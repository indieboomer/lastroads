extends RefCounted

# Heritage and species are independent from profession and personal choices.
const ORIGINS := [
	{"id":"valdren","name":"Valdren human","species":"human","heritage":"valdren","names":"Alven, Isera, Marel","description":"Western and northern roads. Wool, linen, doublets and travelling cloaks; varied European-inspired appearances."},
	{"id":"shenari","name":"Shenari human","species":"human","heritage":"shenari","names":"Shuren, Meilin, Renai","description":"Eastern river kingdoms. Layered collars, sashes and practical local coats; varied East Asian-inspired appearances."},
	{"id":"nambari","name":"Nambari human","species":"human","heritage":"nambari","names":"Ndera, Amari, Kalemi","description":"Southern lakes and plateaus. Patterned panels, brass and road-worn layers; varied Black and sub-Saharan-inspired appearances."},
	{"id":"dwarf","name":"Dwarf","species":"dwarf","heritage":"","names":"Beren, Ossa, Kel","description":"Short, broad and individual. A dwarf may be a scholar, soldier, priest or wanderer; craftsmanship is no obligation."},
	{"id":"elf","name":"Elf","species":"elf","heritage":"","names":"Aren, Selis, Venn","description":"Slender, pointed-eared and varied in complexion. Neither magic nor allegiance to the Old Faith is inherited."},
	{"id":"ogre","name":"Ogre","species":"ogre","heritage":"","names":"Oran, Mel, Tava","description":"Large, heavy and expressive. Ogres are found among scholars, clergy and soldiers as readily as any other people."}
]
const PROFESSIONS := [
	{"id":"warrior","name":"Warrior","health":110.0,"damage":32.0,"mana":0.0,"description":"A practised guard. 110 vitality; stronger blade. C: Second wind restores 35 stamina (20s). V: Driving strike staggers a nearby foe (25 stamina)."},
	{"id":"mage","name":"Mage","health":90.0,"damage":26.0,"mana":80.0,"description":"A mobile, learned caster. LMB: free aimed Arcane Dart. RMB/Q: Repulsion (12 mana, 8s). C: Ember (16 mana). V: Rime (12 mana), then Dart shatters Brittle. 80 mana, +0.8/sec. Prepare two spells at safe rest."},
	{"id":"cleric","name":"Cleric","health":100.0,"damage":28.0,"mana":70.0,"description":"A Christian road cleric. LMB: free consecrated staff strike. RMB/Q: Rebuke (10 mana, 5s). C: Judgement (14 mana). V: Sanctuary (24 mana): fixed protection and slow healing for 8s. 70 mana, +0.8/sec. Prepare at safe rest."},
	{"id":"ranger","name":"Ranger","health":100.0,"damage":16.0,"mana":0.0,"description":"A powder-and-road scout. C: pistol (80 damage). V: musket (130). Q: weak dagger (16). LMB attacks; RMB steadies aim with free hands. R: manual two-handed reload, 4s pistol / 6s musket. G: safe rest. No magic; shots require actual aim."}
]
const GENDERS := ["man","woman"]
const STATURE := {"human":{"eye":1.62,"body":1.95},"dwarf":{"eye":1.12,"body":1.42},"elf":{"eye":1.76,"body":2.05},"ogre":{"eye":2.15,"body":2.45}}
const INTERESTS := ["adults","men","women","none"]

static func defaults() -> Dictionary:
	return {"name":"Traveller","age":30,"origin_id":"valdren","species_id":"human","heritage_id":"valdren","profession_id":"warrior","gender":"man","presentation":0,"romance_interest":"adults"}

static func origin(id: String) -> Dictionary:
	for entry in ORIGINS:
		if entry.id==id: return entry
	return ORIGINS[0]

static func profession(id: String) -> Dictionary:
	for entry in PROFESSIONS:
		if entry.id==id: return entry
	return PROFESSIONS[0]

static func stature(species: String) -> Dictionary:
	return STATURE.get(species,STATURE.human)

static func body_id(profile: Dictionary) -> String:
	return ("female/" if profile.gender=="woman" else "")+profile.origin_id+"-"+profile.profession_id

static func body_path(profile: Dictionary) -> String:
	return "res://assets/coop/ready/"+body_id(profile)+".png"

static func migrate_profile(value: Variant) -> Variant:
	if not value is Dictionary: return value
	var profile: Dictionary = value.duplicate(true)
	var portrait: Variant = profile.get("presentation")
	if (portrait is int or portrait is float) and (portrait==0 or portrait==1):
		# Older saves allowed an independent portrait and a third gender option.
		if profile.get("gender")=="nonbinary": profile.gender = GENDERS[int(portrait)]
		if profile.get("gender") in GENDERS: profile.presentation = GENDERS.find(profile.gender)
	return profile

static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["name","origin_id","species_id","heritage_id","profession_id","gender","romance_interest"]:
		if not value.get(key) is String: return false
	if value.name.strip_edges().is_empty() or value.name.length()>32: return false
	for key in ["age","presentation"]:
		if not (value.get(key) is float or value.get(key) is int) or not is_finite(float(value[key])) or float(value[key])!=floor(float(value[key])): return false
	if value.age<18 or value.age>80 or value.gender not in GENDERS or value.presentation!=GENDERS.find(value.gender): return false
	var o := origin(value.origin_id)
	return o.id==value.origin_id and o.species==value.species_id and o.heritage==value.heritage_id and profession(value.profession_id).id==value.profession_id and value.gender in GENDERS and value.romance_interest in INTERESTS
