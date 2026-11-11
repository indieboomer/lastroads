extends RefCounted

# Pose rectangles exclude neighbours, especially the wider horizontal corpses.
# Source PNGs retain their generated alpha and are never modified by this loader.
const REGIONS := {
	"pitchbound":[Rect2i(50,8,425,504),Rect2i(550,0,430,512),Rect2i(1060,35,476,477),Rect2i(35,520,430,504),Rect2i(475,710,580,304),Rect2i(1080,520,450,504)],
	"boughstalker":[Rect2i(90,4,330,508),Rect2i(570,0,430,512),Rect2i(1070,4,466,508),Rect2i(90,516,375,508),Rect2i(470,790,590,234),Rect2i(1080,516,445,508)]
}
var frames: Dictionary = {}

func frame(library: RefCounted, kind: String, index: int) -> Texture2D:
	var key := kind+str(index)
	if not frames.has(key):
		var source: Image = library.image_for("res://assets/wilderness/"+kind+"-poses.png")
		var region: Rect2i = Rect2i(index%3*source.get_width()/3,index/3*source.get_height()/2,source.get_width()/3,source.get_height()/2) if kind=="hollow_weeper" else REGIONS[kind][index]
		if kind=="hollow_weeper" and index==4: region = Rect2i(450,785,620,239)
		var image := source.get_region(region)
		image = image.get_region(library.visible_bounds(image))
		image.fix_alpha_edges()
		image.generate_mipmaps()
		frames[key] = ImageTexture.create_from_image(image)
	return frames[key]
