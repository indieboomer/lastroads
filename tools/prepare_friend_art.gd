extends SceneTree
func _initialize() -> void:
 for id in ["ilya-girl1","merchant-girl2"]:
  var image := Image.load_from_file("res://assets/friends/npc-"+id+".png")
  var w := image.get_width()
  var h := image.get_height()
  var region := Rect2i(int(w*.24),int(h*.025),int(w*.52),int(h*.49)) if id=="ilya-girl1" else Rect2i(int(w*.26),int(h*.025),int(w*.51),int(h*.43))
  var portrait := image.get_region(region)
  portrait.fix_alpha_edges()
  assert(portrait.save_png("res://assets/friends/npc-"+id+"-portrait.png")==OK)
 var icon := Image.new()
 assert(icon.load_svg_from_string(FileAccess.get_file_as_string("res://assets/game-icon.svg"))==OK)
 assert(icon.save_png("res://assets/game-icon.png")==OK)
 print("FRIEND ART PASS: matching dialogue crops and native game icon ready")
 quit()
