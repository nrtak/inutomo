class_name WalkArea
extends RefCounted

# Convex ground areas in the artwork's 1280 x 720 coordinate space.
# Straight routes between any two permitted foot positions stay on clear ground.
static var AREAS = {
	"Home": PackedVector2Array([Vector2(540, 495), Vector2(800, 495), Vector2(800, 510), Vector2(520, 510)]),
	"Puppy Club": PackedVector2Array([Vector2(510, 540), Vector2(820, 540), Vector2(820, 600), Vector2(510, 600)]),
	"Shop": PackedVector2Array([Vector2(510, 540), Vector2(800, 540), Vector2(800, 600), Vector2(510, 600)]),
	"Vet Clinic": PackedVector2Array([Vector2(510, 540), Vector2(800, 540), Vector2(800, 600), Vector2(510, 600)]),
	"Lighthouse": PackedVector2Array([Vector2(510, 540), Vector2(800, 540), Vector2(800, 600), Vector2(510, 600)]),
	"Park": PackedVector2Array([Vector2(350, 515), Vector2(900, 515), Vector2(900, 610), Vector2(350, 610)]),
	"Beach": PackedVector2Array([Vector2(350, 520), Vector2(425, 520), Vector2(760, 625), Vector2(520, 625), Vector2(350, 565)])
}
const SPAWNS = {"Puppy Club": Vector2(600, 560), "Shop": Vector2(600, 560), "Vet Clinic": Vector2(600, 560), "Lighthouse": Vector2(600, 560), "Home": Vector2(640, 505), "Park": Vector2(500, 560), "Beach": Vector2(500, 580)}
const WALK_STOPS = [Vector2(400, 550), Vector2(640, 615), Vector2(520, 615)]

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


