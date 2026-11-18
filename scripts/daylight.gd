extends Node

# Local device time is intentionally independent of save progress and UTC.
const PERIODS = [
	{"start": 0, "name": "Late night", "tone": Color("849acb"), "light": 0.34, "cool": 0.65},
	{"start": 300, "name": "Early morning", "tone": Color("ffcfb7"), "light": 0.65, "cool": 0.18},
	{"start": 420, "name": "Morning", "tone": Color("fff1d8"), "light": 0.96, "cool": 0.0},
	{"start": 660, "name": "Noon", "tone": Color.WHITE, "light": 1.0, "cool": 0.0},
	{"start": 840, "name": "Afternoon", "tone": Color("fff0dc"), "light": 0.98, "cool": 0.0},
	{"start": 960, "name": "Late afternoon", "tone": Color("ffc393"), "light": 0.88, "cool": 0.08},
	{"start": 1080, "name": "Evening", "tone": Color("e9c3d5"), "light": 0.63, "cool": 0.28},
	{"start": 1200, "name": "Night", "tone": Color("93a9d5"), "light": 0.40, "cool": 0.55}
]
var material: ShaderMaterial
var current_period = ""
var clock = 0.0
var transition: Tween
var location_materials: Dictionary = {}
var current_weather = ""
var weather_clock = 0.0
var weather_transition: Tween
const SKY_HEIGHTS = {"Island":0.16,"Home":0.30,"Moment:Home":0.30,"Shop":0.29,"Vet Clinic":0.26,"Lighthouse Room":0.28,"Park":0.38,"Puppy Club":0.36,"Beach":0.37,"Beach Arrival":0.40,"Harbor":0.36,"Keeper’s Cottage":0.34,"Lighthouse":0.40,"Moment:Recall":0.35,"Moment:Beach":0.40,"Moment:Cottage":0.36,"Moment:Lighthouse":0.44}
const MOTION = {
 "Moment:Home":[Vector4(0.06,0.37,0.90,0.19)],
 "Moment:Recall":[Vector4(0.36,0.34,0.48,0.13),Vector4.ZERO,Vector4.ZERO,Vector4(0.855,0.36,0.06,0.13)],
 "Moment:Beach":[Vector4(0,0.35,1,0.34)],
 "Moment:Cottage":[Vector4(0.45,0.40,0.53,0.14)],
 "Moment:Lighthouse":[Vector4(0.19,0.43,0.69,0.20)],
 "Lighthouse Room":[Vector4(0.29,0.39,0.53,0.15)],
 "Island":[Vector4(0,0.16,1,0.84),Vector4(0,0.02,0.4,0.96),Vector4(0.56,0.02,0.44,0.96),Vector4(0.335,0.61,0.03,0.14),Vector4(0.145,0.57,0.04,0.20),Vector4(0.075,0.34,0.04,0.16),Vector4(0.485,0.375,0.055,0.10)],
 "Home":[Vector4(0.06,0.37,0.90,0.19),Vector4(0.02,0.08,0.32,0.7),Vector4(0.83,0,0.17,0.45)],
 "Park":[Vector4(0.3,0.24,0.5,0.3),Vector4(0,0,0.25,0.95),Vector4(0.73,0,0.27,0.96)],
 "Beach":[Vector4(0.32,0.25,0.68,0.5),Vector4(0,0,0.32,0.95),Vector4(0.75,0,0.25,1)],
 "Beach Arrival":[Vector4(0,0.35,1,0.36),Vector4(0,0,0.30,0.94),Vector4(0.85,0,0.15,1)],
 "Shop":[Vector4(0.45,0.22,0.52,0.43),Vector4(0,0,0.2,0.9),Vector4(0.84,0,0.16,0.9)],
 "Vet Clinic":[Vector4(0.32,0.2,0.36,0.38),Vector4(0,0,0.27,0.8),Vector4(0.78,0,0.22,0.9)],
 "Puppy Club":[Vector4(0.3,0.23,0.5,0.3),Vector4(0,0,0.3,0.94),Vector4(0.7,0,0.3,1)],
 "Harbor":[Vector4(0.25,0.25,0.75,0.45),Vector4(0,0,0.24,0.96),Vector4(0.83,0,0.17,1)],
 "Keeper’s Cottage":[Vector4(0.43,0.25,0.57,0.5),Vector4(0,0,0.30,0.96),Vector4(0.8,0,0.2,1)],
 "Lighthouse":[Vector4(0.1,0.35,0.88,0.24),Vector4(0,0,0.3,1),Vector4(0.8,0.12,0.2,0.88)]
}
# Treetop-only masks: no flowers, ground cover, bushes, or indoor plants.
const TREE_TOPS = {
 "Moment:Home":[Vector4.ZERO,Vector4(0.78,0.0,0.22,0.16)],
 "Moment:Recall":[Vector4(0.24,0,0.17,0.18),Vector4(0.86,0,0.14,0.17)],
 "Moment:Beach":[Vector4(0,0,0.28,0.20),Vector4(0.84,0,0.16,0.18)],
 "Moment:Cottage":[Vector4(0,0,0.14,0.16),Vector4(0.9,0,0.1,0.16)],
 "Moment:Lighthouse":[Vector4(0,0,0.15,0.16),Vector4(0.91,0,0.09,0.22)],
 "Island":[Vector4(0.065,0.075,0.13,0.19),Vector4(0.26,0.13,0.075,0.15)],
 "Home":[Vector4.ZERO,Vector4(0.78,0.0,0.22,0.16)],
 "Park":[Vector4(0.0,0.0,0.23,0.24),Vector4(0.82,0.0,0.18,0.20)],
 "Beach":[Vector4(0.0,0.0,0.30,0.22),Vector4(0.82,0.0,0.18,0.20)],
 "Beach Arrival":[Vector4(0.0,0.0,0.28,0.20),Vector4(0.83,0.0,0.17,0.20)],
 "Shop":[Vector4.ZERO,Vector4(0.90,0.0,0.10,0.15)],
 "Vet Clinic":[Vector4.ZERO,Vector4.ZERO],
 "Puppy Club":[Vector4(0.0,0.0,0.25,0.22),Vector4(0.82,0.0,0.18,0.22)],
 "Harbor":[Vector4(0.0,0.0,0.18,0.23),Vector4(0.88,0.0,0.12,0.20)],
 "Keeper’s Cottage":[Vector4(0.0,0.0,0.24,0.23),Vector4(0.87,0.0,0.13,0.20)],
 "Lighthouse":[Vector4(0.0,0.0,0.30,0.25),Vector4(0.92,0.12,0.08,0.15)]
}
const LIGHTS = {
	"Moment:Home": [Vector4(0.82, 0.50, 0.10, 0.18), Vector4(0.84, 0.77, 0.25, 0.22), Vector4(0.12, 0.42, 0.22, 0.38), Vector4.ZERO],
	"Moment:Beach": [Vector4(0.10,0.28,0.05,0.12),Vector4(0.30,0.76,0.55,0.45),Vector4.ZERO,Vector4.ZERO],
	"Moment:Lighthouse": [Vector4(0.63,0.16,0.045,0.10),Vector4(0.12,0.64,0.14,0.27),Vector4(0.92,0.64,0.14,0.27),Vector4(0.50,0.83,0.43,0.30)],
	"Lighthouse Room": [Vector4(0.18,0.34,0.12,0.18),Vector4(0.90,0.17,0.06,0.10),Vector4(0.50,0.82,0.60,0.40),Vector4.ZERO],
	"Beach Arrival": [Vector4(0.10,0.28,0.05,0.12),Vector4(0.30,0.76,0.55,0.45),Vector4.ZERO,Vector4.ZERO],
	"Beach": [Vector4(0.10,0.55,0.06,0.12),Vector4(0.45,0.85,0.6,0.4),Vector4.ZERO,Vector4.ZERO],
	"Harbor": [Vector4(0.08, 0.44, 0.035, 0.07), Vector4(0.235, 0.43, 0.035, 0.07), Vector4.ZERO, Vector4.ZERO],
	"Keeper’s Cottage": [Vector4(0.235, 0.37, 0.035, 0.07), Vector4(0.50, 0.15, 0.025, 0.04), Vector4.ZERO, Vector4.ZERO],
	"Home": [Vector4(0.82, 0.50, 0.10, 0.18), Vector4(0.84, 0.77, 0.25, 0.22), Vector4(0.12, 0.42, 0.22, 0.38), Vector4.ZERO],
	"Puppy Club": [Vector4(0.055, 0.26, 0.055, 0.10), Vector4(0.262, 0.30, 0.055, 0.10), Vector4(0.18, 0.40, 0.095, 0.18), Vector4(0.20, 0.55, 0.16, 0.15)],
	"Shop": [Vector4(0.20, 0.24, 0.22, 0.33), Vector4(0.27, 0.57, 0.23, 0.25), Vector4(0.90, 0.61, 0.16, 0.27), Vector4(0.50, 0.84, 0.33, 0.16)],
	"Vet Clinic": [Vector4(0.875, 0.095, 0.12, 0.13), Vector4(0.57, 0.02, 0.10, 0.10), Vector4(0.76, 0.02, 0.10, 0.10), Vector4(0.72, 0.76, 0.24, 0.30)],
	"Island": [Vector4(0.23, 0.20, 0.055, 0.075), Vector4(0.54, 0.20, 0.06, 0.08), Vector4(0.28, 0.50, 0.05, 0.07), Vector4(0.80, 0.49, 0.05, 0.07)],
	"Lighthouse": [Vector4(0.884, 0.13, 0.035, 0.045), Vector4(0.90, 0.27, 0.07, 0.05), Vector4.ZERO, Vector4.ZERO]
}

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://scripts/daylight.gdshader")
	for location in MOTION:
		material_for(location)
	refresh(true)
	set_reduced_motion(bool(get_node("/root/Game").reduce_motion))

func _process(delta: float) -> void:
	clock += delta
	weather_clock += delta
	if weather_clock>=1.0:
		weather_clock=0
		refresh_weather()
	if clock >= 30:
		clock = 0
		refresh()

func period_at(minute: int) -> Dictionary:
	var local_minute = posmod(minute, 1440)
	var period: Dictionary = PERIODS[0]
	for candidate in PERIODS:
		if local_minute >= candidate.start:
			period = candidate
	return period

func refresh(immediate: bool = false) -> void:
	var local = Time.get_datetime_dict_from_system(false)
	apply_minute(int(local.hour) * 60 + int(local.minute), immediate)
	refresh_weather(immediate)

func refresh_weather(immediate: bool = false) -> void:
	var weather=IslandWeather.current()
	if weather==current_weather and not immediate: return
	current_weather=weather
	if weather_transition!=null and weather_transition.is_valid(): weather_transition.kill()
	var cover={"Sunny":0.0,"Passing clouds":0.48,"Light rain":1.0}[weather]
	var wet=1.0 if weather=="Light rain" else 0.0
	if not immediate: weather_transition=create_tween().set_parallel(true)
	for target in [material]+location_materials.values():
		if immediate:
			target.set_shader_parameter("cloud_cover",cover)
			target.set_shader_parameter("wetness",wet)
		else:
			weather_transition.tween_property(target,"shader_parameter/cloud_cover",cover,6.0)
			weather_transition.tween_property(target,"shader_parameter/wetness",wet,6.0)

func apply_minute(minute: int, immediate: bool = false) -> void:
	var period = period_at(minute)
	if period.name == current_period and not immediate:
		return
	current_period = period.name
	var night={"Late night":1.0,"Night":0.95,"Evening":0.16,"Early morning":0.08}.get(period.name,0.0)
	var sunset={"Late afternoon":0.72,"Evening":1.0}.get(period.name,0.0)
	var dawn=0.8 if period.name=="Early morning" else 0.0
	if transition != null and transition.is_valid():
		transition.kill()
	if immediate:
		for target in [material] + location_materials.values():
			target.set_shader_parameter("tone", period.tone)
			target.set_shader_parameter("exposure", period.light)
			target.set_shader_parameter("coolness", period.cool)
			target.set_shader_parameter("night_amount",night)
			target.set_shader_parameter("sunset_amount",sunset)
			target.set_shader_parameter("dawn_amount",dawn)
	else:
		transition = create_tween().set_parallel(true)
		for target in [material] + location_materials.values():
			transition.tween_property(target, "shader_parameter/tone", period.tone, 12.0)
			transition.tween_property(target, "shader_parameter/exposure", period.light, 12.0)
			transition.tween_property(target, "shader_parameter/coolness", period.cool, 12.0)
			transition.tween_property(target,"shader_parameter/night_amount",night,12.0)
			transition.tween_property(target,"shader_parameter/sunset_amount",sunset,12.0)
			transition.tween_property(target,"shader_parameter/dawn_amount",dawn,12.0)

func material_for(location: String) -> ShaderMaterial:
	if not MOTION.has(location) and not LIGHTS.has(location):
		return material
	if not location_materials.has(location):
		var local: ShaderMaterial = material.duplicate()
		for index in 4:
			local.set_shader_parameter("lamp_" + str(index), LIGHTS.get(location,[Vector4.ZERO,Vector4.ZERO,Vector4.ZERO,Vector4.ZERO])[index])
		local.set_shader_parameter("island_land_mask",location == "Island")
		local.set_shader_parameter("water_shimmer",0.0)
		local.set_shader_parameter("indoor",location in WeatherLayer.INDOOR)
		var window: Rect2=WeatherLayer.WINDOWS.get(location,Rect2(0,0,1,1))
		local.set_shader_parameter("weather_window",Vector4(window.position.x,window.position.y,window.size.x,window.size.y))
		local.set_shader_parameter("sky_height",SKY_HEIGHTS.get(location,0.35))
		var regions: Array = MOTION.get(location,[])
		var names = ["water_area","foliage_a","foliage_b","falls_a","falls_b","falls_c","falls_d"]
		for index in names.size():
			local.set_shader_parameter(names[index],regions[index] if index < regions.size() else Vector4.ZERO)
		var treetops: Array = TREE_TOPS.get(location,[Vector4.ZERO,Vector4.ZERO])
		local.set_shader_parameter("foliage_a",treetops[0])
		local.set_shader_parameter("foliage_b",treetops[1])
		location_materials[location] = local
	return location_materials[location]

func apply_to(background: CanvasItem, location: String = "Home") -> void:
	if IslandWeather.current()!=current_weather: refresh_weather(true)
	background.material = material_for(location)
	var layer = load("res://scripts/weather_layer.gd").new()
	layer.location = location
	background.add_child(layer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and material != null:
		refresh(true)

func set_reduced_motion(enabled: bool) -> void:
	for target in [material]+location_materials.values():
		if is_instance_valid(target):
			target.set_shader_parameter("motion_enabled",not enabled)
