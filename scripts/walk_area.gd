class_name WalkArea
extends RefCounted

# Convex ground areas in the artwork's 1280 x 720 coordinate space.
# Straight routes between any two permitted foot positions stay on clear ground.
static var AREAS = {
	"Lighthouse Room":PackedVector2Array([Vector2(500,540),Vector2(850,540),Vector2(850,620),Vector2(500,620)]),
	"Harbor": PackedVector2Array([Vector2(330, 495), Vector2(780, 495), Vector2(900, 610), Vector2(360, 640)]),
	"Keeper’s Cottage": PackedVector2Array([Vector2(370, 505), Vector2(770, 505), Vector2(870, 630), Vector2(350, 650)]),
	"Home": PackedVector2Array([Vector2(475, 490), Vector2(940, 490), Vector2(970, 650), Vector2(440, 650)]),
	"Puppy Club": PackedVector2Array([Vector2(510, 540), Vector2(820, 540), Vector2(820, 600), Vector2(510, 600)]),
	"Shop": PackedVector2Array([Vector2(510, 540), Vector2(800, 540), Vector2(800, 600), Vector2(510, 600)]),
	"Vet Clinic": PackedVector2Array([Vector2(510, 540), Vector2(800, 540), Vector2(800, 600), Vector2(510, 600)]),
	"Lighthouse": PackedVector2Array([Vector2(510, 540), Vector2(800, 540), Vector2(800, 600), Vector2(510, 600)]),
	"Park": PackedVector2Array([Vector2(335, 505), Vector2(900, 505), Vector2(935, 635), Vector2(320, 635)]),
	"Beach": PackedVector2Array([Vector2(355, 535), Vector2(430, 535), Vector2(755, 635), Vector2(520, 635), Vector2(355, 575)])
}
const SPAWNS = {"Lighthouse Room":Vector2(660,600),"Harbor": Vector2(500, 570), "Keeper’s Cottage": Vector2(500, 575),"Puppy Club": Vector2(600, 560), "Shop": Vector2(600, 560), "Vet Clinic": Vector2(600, 560), "Lighthouse": Vector2(600, 560), "Home": Vector2(640, 505), "Park": Vector2(500, 560), "Beach": Vector2(500, 580)}
const WALK_STOPS = [Vector2(400, 555), Vector2(640, 620), Vector2(520, 620)]

# These are paw-space barriers, already padded beyond the visible furniture.
static func barriers_for(location: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if location=="Home":
		result.assign([Rect2(0,430,370,280),Rect2(990,405,290,280),Rect2(360,340,120,142)])
	return result

static func walkable(polygon: PackedVector2Array, barriers: Array[Rect2], point: Vector2) -> bool:
	if not contains(polygon,point): return false
	for barrier in barriers:
		if barrier.grow(-0.1).has_point(point): return false
	return true

static func destination(polygon: PackedVector2Array, barriers: Array[Rect2], point: Vector2) -> Vector2:
	var result = nearest(polygon,point)
	for attempt in 8:
		var obstructed = false
		for barrier in barriers:
			if not barrier.grow(-0.1).has_point(result): continue
			obstructed = true
			var best = result
			var distance = INF
			for option in [Vector2(barrier.position.x-1,result.y),Vector2(barrier.end.x+1,result.y),Vector2(result.x,barrier.position.y-1),Vector2(result.x,barrier.end.y+1)]:
				var candidate = nearest(polygon,option)
				if not barrier.has_point(candidate) and candidate.distance_squared_to(point)<distance:
					best = candidate
					distance = candidate.distance_squared_to(point)
			result = best
		if not obstructed: break
	return result

static func crosses_barrier(start: Vector2, end: Vector2, barrier: Rect2) -> bool:
	var box = barrier.grow(-0.25)
	var direction = end-start
	var lower = 0.0
	var upper = 1.0
	for axis in 2:
		if absf(direction[axis])<0.00001:
			if start[axis]<=box.position[axis] or start[axis]>=box.end[axis]: return false
		else:
			var a = (box.position[axis]-start[axis])/direction[axis]
			var b = (box.end[axis]-start[axis])/direction[axis]
			lower = maxf(lower,minf(a,b))
			upper = minf(upper,maxf(a,b))
			if lower>=upper: return false
	return upper>0 and lower<1

static func clear_segment(start: Vector2, end: Vector2, barriers: Array[Rect2], escaping: bool = false) -> bool:
	for barrier in barriers:
		# A dog waking on a bed must be able to step off it over several frames.
		if escaping and barrier.has_point(start): continue
		if crosses_barrier(start,end,barrier): return false
	return true

static func route(polygon: PackedVector2Array, barriers: Array[Rect2], start: Vector2, goal: Vector2) -> Array[Vector2]:
	var finish = destination(polygon,barriers,goal)
	if clear_segment(start,finish,barriers,true): return [finish]
	var nodes: Array[Vector2] = [start,finish]
	for barrier in barriers:
		var box = barrier.grow(1)
		for point in [box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)]:
			if walkable(polygon,barriers,point): nodes.append(point)
	var distances: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	for node in nodes:
		distances.append(INF)
		previous.append(-1)
		visited.append(false)
	distances[0] = 0
	for iteration in nodes.size():
		var current = -1
		for i in nodes.size():
			if not visited[i] and (current<0 or distances[i]<distances[current]): current = i
		if current<0 or is_inf(distances[current]): break
		if current==1: break
		visited[current] = true
		for i in nodes.size():
			if visited[i] or not clear_segment(nodes[current],nodes[i],barriers,current==0): continue
			var distance = distances[current]+nodes[current].distance_to(nodes[i])
			if distance<distances[i]:
				distances[i] = distance
				previous[i] = current
	var result: Array[Vector2] = []
	var index = 1
	while previous[index]>=0:
		result.push_front(nodes[index])
		index = previous[index]
	return result

static func contains(polygon: PackedVector2Array, point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, polygon) or nearest(polygon, point).distance_to(point) < 0.01

static func nearest(polygon: PackedVector2Array, point: Vector2) -> Vector2:
	if polygon.is_empty() or Geometry2D.is_point_in_polygon(point, polygon):
		return point
	var result = polygon[0]
	var best_distance = INF
	for index in polygon.size():
		var candidate = Geometry2D.get_closest_point_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()])
		var distance = point.distance_squared_to(candidate)
		if distance < best_distance:
			result = candidate
			best_distance = distance
	return result


