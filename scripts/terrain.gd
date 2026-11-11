extends RefCounted

const STEP := 2.5
const MIN_X := -250.0
const MIN_Z := -1030.0
const WIDTH := 201
const DEPTH := 455
const BIN := 32.0
# Flat inner rectangles include porches, approaches, bridge banks and water.
const PADS := [
	[Vector2(0,30),Vector2(42,30)], [Vector2(8,-98),Vector2(23,22)],
	[Vector2(-80,-65),Vector2(18,18)], [Vector2(-123,-166),Vector2(28,25)],
	[Vector2(132,-207),Vector2(31,28)], [Vector2(-119,-243),Vector2(48,38)],
	[Vector2(0,-350),Vector2(24,27)], [Vector2(160,-311),Vector2(15,15)],
	[Vector2(0,-435),Vector2(72,23)], [Vector2(-68,-531),Vector2(40,32)],
	[Vector2(-200,-630),Vector2(35,39)], [Vector2(147,-619),Vector2(66,46)],
	[Vector2(180,-764),Vector2(35,37)], [Vector2(-166,-805),Vector2(40,32)],
	[Vector2(0,-950),Vector2(40,39)]
]
var noise := FastNoiseLite.new()
var heights := PackedFloat32Array()
var segments: Array = []
var bins: Dictionary = {}
var ready := false

func configure(roads: Array) -> void:
	noise.seed = 17760811
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = .009
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_gain = .48
	for road in roads:
		for index in range(road.size()-1):
			var a: Vector2 = road[index]
			var b: Vector2 = road[index+1]
			var id := segments.size()
			segments.append([a,b])
			for x in range(floori((minf(a.x,b.x)-19)/BIN),floori((maxf(a.x,b.x)+19)/BIN)+1):
				for z in range(floori((minf(a.y,b.y)-19)/BIN),floori((maxf(a.y,b.y)+19)/BIN)+1):
					var key := Vector2i(x,z)
					if not bins.has(key): bins[key] = []
					bins[key].append(id)

static func legacy(x: float, z: float) -> float:
	if x>100 and x<165 and z< -355 and z> -430: return 0.0
	var h := sin(x*.018)*1.5+sin(z*.024)*1.15+sin((x+z)*.011)*1.4
	var distance := Vector2(x,z).distance_to(Vector2(0,-350))
	if distance<25:
		var foundation := sin(-350*.024)*1.15+sin(-350*.011)*1.4
		h = lerpf(foundation,h,smoothstep(14,25,distance))
	return h

func raw_height(p: Vector2) -> float:
	if p.x>100 and p.x<165 and p.y< -355 and p.y> -430: return 0.0
	var h := legacy(p.x,p.y)+noise.get_noise_2d(p.x,p.y)*24.0+noise.get_noise_2d(p.x*.37+701,p.y*.37-213)*13.0
	var nearest := 19.0
	var road_point := p
	for id in bins.get(Vector2i(floori(p.x/BIN),floori(p.y/BIN)),[]):
		var segment: Array = segments[id]
		var point := Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1])
		var distance := p.distance_to(point)
		if distance<nearest:
			nearest = distance
			road_point = point
	h = lerpf(legacy(road_point.x,road_point.y),h,smoothstep(5.5,19.0,nearest))
	# Preserve a shallow, continuous bed for the existing mill stream.
	if p.y< -92 and p.y> -282:
		var river_distance := absf(p.x+135)
		h = lerpf(legacy(-135,p.y),h,smoothstep(5.0,14.0,river_distance))
	var best := 0.0
	var target := h
	for pad in PADS:
		var delta: Vector2 = (p-pad[0]).abs()-pad[1]
		var distance := Vector2(maxf(0,delta.x),maxf(0,delta.y)).length()
		var weight := 1.0-smoothstep(0.0,22.0,distance)
		if weight>best:
			best = weight
			target = legacy(pad[0].x,pad[0].y)
		if best>=1.0: break
	return lerpf(h,target,best)

func build() -> void:
	if ready: return
	heights.resize(WIDTH*DEPTH)
	for z in range(DEPTH):
		for x in range(WIDTH): heights[z*WIDTH+x] = raw_height(Vector2(MIN_X+x*STEP,MIN_Z+z*STEP))
	ready = true

func height_at(x: float, z: float) -> float:
	build()
	var gx := clampf((x-MIN_X)/STEP,0,WIDTH-1.00001)
	var gz := clampf((z-MIN_Z)/STEP,0,DEPTH-1.00001)
	var ix := floori(gx)
	var iz := floori(gz)
	var fx := gx-ix
	var fz := gz-iz
	var a := heights[iz*WIDTH+ix]
	var b := heights[iz*WIDTH+ix+1]
	var c := heights[(iz+1)*WIDTH+ix]
	var d := heights[(iz+1)*WIDTH+ix+1]
	# Same diagonal and barycentric interpolation as the physical ground mesh.
	return a+(b-a)*fx+(c-a)*fz if fx+fz<=1 else d+(c-d)*(1-fx)+(b-d)*(1-fz)
