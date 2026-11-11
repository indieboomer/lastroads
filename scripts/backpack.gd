extends RefCounted

const WIDTH := 8
const HEIGHT := 6
const ITEMS := {
	"graveward_resin":{"name":"Graveward resin","size":Vector2i(1,1),"icon":6,"use":"Coats your weapon with Old Faith alchemy for 120 seconds. Effective against the Hollow Weeper.","usable":true},
	"burial_cloth":{"name":"Burial cloth","size":Vector2i(1,2),"icon":10,"use":"Moss-stained Old Faith burial linen. Crafting material.","usable":false},
	"ancient_beads":{"name":"Ancient beads","size":Vector2i(1,1),"icon":11,"use":"Worn votive beads. Old Faith offering; a valuable curio.","usable":false},
	"resin_tear":{"name":"Resin tear","size":Vector2i(1,1),"icon":6,"use":"At a safe fire: combine one tear with two essence to brew Graveward resin. Use from the pack.","usable":true},
	"musket_cartridge":{"name":"Musket cartridges","size":Vector2i(1,2),"icon":0,"use":"Heavy powder + lead ball / musket only. 1 per shot.","usable":false},
	"pistol_cartridge":{"name":"Pistol cartridges","size":Vector2i(1,2),"icon":0,"use":"Small paper charge / pistol only. 1 per shot.","usable":false},
	"tonic":{"name":"Healing tonic","size":Vector2i(1,2),"icon":0,"use":"Restores 55 vitality.","usable":true},
	"bread":{"name":"Trail bread","size":Vector2i(2,1),"icon":1,"use":"Restores 28 vitality and stamina.","usable":true},
	"wood":{"name":"Dry firewood","size":Vector2i(1,3),"icon":2,"use":"Build a warming campfire outdoors.","usable":true},
	"scrap":{"name":"Iron scrap","size":Vector2i(2,2),"icon":4,"use":"Smithing material.","usable":false},
	"yarrow":{"name":"Golden yarrow","size":Vector2i(1,2),"icon":5,"use":"Bring three to Mother Vesna.","usable":false},
	"moonwort":{"name":"Moonwort","size":Vector2i(1,2),"icon":6,"use":"Bring three to Tomas.","usable":false},
	"berries":{"name":"Wild berries","size":Vector2i(2,1),"icon":7,"use":"Restores 10 vitality.","usable":true},
	"mushrooms":{"name":"Coppercaps","size":Vector2i(2,2),"icon":8,"use":"Edible. Restores 18 vitality.","usable":true},
	"toadstools":{"name":"Widow's bonnets","size":Vector2i(1,1),"icon":9,"use":"Poisonous. Trade only; never eaten.","usable":false},
	"fur":{"name":"Hound pelts","size":Vector2i(2,2),"icon":10,"use":"Trade with Adela.","usable":false},
	"essence":{"name":"Pale essence","size":Vector2i(1,2),"icon":11,"use":"A valuable spectral curio.","usable":false}
}
const DEFAULT_SLOTS := ["tonic","bread","berries","mushrooms","wood","lantern","rest","torch"]
const ACTIONS := {
	"lantern":{"name":"Hooded lantern","use":"Held left / L stows / blocks offhand actions."},
	"torch":{"name":"Hand torch","use":"Held left / T stows / RMB strikes with flame."},
	"rest":{"name":"Rest by a fire","use":"Rest safely by a fire until morning. G."}
}

static func valid_shortcut(key: String) -> bool:
	return key.is_empty() or ITEMS.has(key) or ACTIONS.has(key)

static func details(key: String) -> Dictionary:
	return ITEMS.get(key,ACTIONS.get(key,{"name":"Empty","use":"Choose a supply or carried gear."}))
var layout: Dictionary = {}
var slots: Array = DEFAULT_SLOTS.duplicate()
var unpacked: Array[String] = []

func footprint(key: String, rotated := false) -> Vector2i:
	var size: Vector2i = ITEMS[key].size
	return Vector2i(size.y,size.x) if rotated else size

func fits(key: String, cell: Vector2i, rotated := false, positions: Variant = null) -> bool:
	if positions==null:
		positions = layout
	var size := footprint(key,rotated)
	var candidate := Rect2i(cell,size)
	if cell.x<0 or cell.y<0 or cell.x+size.x>WIDTH or cell.y+size.y>HEIGHT:
		return false
	for other in positions:
		if other==key:
			continue
		var record: Dictionary = positions[other]
		if candidate.intersects(Rect2i(Vector2i(record.x,record.y),footprint(other,record.rotated))):
			return false
	return true

func move(key: String, cell: Vector2i, rotated: bool) -> bool:
	if not ITEMS.has(key) or not fits(key,cell,rotated):
		return false
	layout[key] = {"x":cell.x,"y":cell.y,"rotated":rotated}
	unpacked.erase(key)
	return true

func sync(counts: Dictionary) -> void:
	for key in layout.keys():
		if counts.get(key,0)<=0:
			layout.erase(key)
	unpacked.clear()
	for key in ITEMS:
		if counts.get(key,0)>0 and not layout.has(key):
			if not first_fit(key):
				unpacked.append(key)

func first_fit(key: String) -> bool:
	for rotated in [false,true]:
		for y in range(HEIGHT):
			for x in range(WIDTH):
				if move(key,Vector2i(x,y),rotated):
					return true
	return false

func arrange(counts: Dictionary) -> bool:
	var keys: Array = ITEMS.keys().filter(func(key): return counts.get(key,0)>0)
	keys.sort_custom(func(a,b): return footprint(a).x*footprint(a).y>footprint(b).x*footprint(b).y)
	var old := layout.duplicate(true)
	layout.clear()
	for key in keys:
		if not first_fit(key):
			layout = old
			return false
	unpacked.clear()
	return true

func bind_slot(index: int, key: String) -> bool:
	if index<0 or index>7 or not valid_shortcut(key):
		return false
	slots[index] = key
	return true

func record() -> Dictionary:
	return {"layout":layout.duplicate(true),"slots":slots.duplicate()}

func restore(data: Variant, counts: Dictionary) -> bool:
	if not data is Dictionary or not data.get("layout") is Dictionary or not data.get("slots") is Array or data.slots.size()!=8:
		return false
	var candidate: Dictionary = {}
	for key in data.layout:
		var item: Variant = data.layout[key]
		if not ITEMS.has(key) or not item is Dictionary or not (item.get("x") is int or item.get("x") is float) or not (item.get("y") is int or item.get("y") is float) or not item.get("rotated") is bool:
			return false
		if not is_finite(float(item.x)) or not is_finite(float(item.y)) or item.x!=floor(item.x) or item.y!=floor(item.y):
			return false
		if not fits(key,Vector2i(item.x,item.y),item.rotated,candidate):
			return false
		candidate[key] = {"x":int(item.x),"y":int(item.y),"rotated":item.rotated}
	for key in data.slots:
		if not key is String or not valid_shortcut(key):
			return false
	layout = candidate
	slots = data.slots.duplicate()
	sync(counts)
	return true
