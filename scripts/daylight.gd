extends Node

# Local device time is intentionally independent of save progress and UTC.
const PERIODS = [
	{"start": 0, "name": "Late night", "tone": Color("b8c9ed"), "light": 0.78, "cool": 0.24},
	{"start": 300, "name": "Early morning", "tone": Color("ffcfb7"), "light": 0.78, "cool": 0.12},
	{"start": 420, "name": "Morning", "tone": Color("fff1d8"), "light": 0.96, "cool": 0.0},
	{"start": 660, "name": "Noon", "tone": Color.WHITE, "light": 1.0, "cool": 0.0},
	{"start": 840, "name": "Afternoon", "tone": Color("fff0dc"), "light": 0.98, "cool": 0.0},
	{"start": 960, "name": "Late afternoon", "tone": Color("ffc393"), "light": 0.88, "cool": 0.08},
	{"start": 1080, "name": "Evening", "tone": Color("e9d3ed"), "light": 0.88, "cool": 0.16},
	{"start": 1200, "name": "Night", "tone": Color("c0cff0"), "light": 0.82, "cool": 0.20}
]
var material: ShaderMaterial
var current_period = ""
var clock = 0.0
var transition: Tween
var location_materials: Dictionary = {}
const LIGHTS = {
	"Beach Arrival": [Vector4(0.10,0.28,0.05,0.12),Vector4(0.30,0.76,0.55,0.45),Vector4.ZERO,Vector4.ZERO],
	"Beach": [Vector4(0.10,0.55,0.06,0.12),Vector4(0.45,0.85,0.6,0.4),Vector4.ZERO,Vector4.ZERO],
	"Harbor": [Vector4(0.08, 0.44, 0.035, 0.07), Vector4(0.235, 0.43, 0.035, 0.07), Vector4.ZERO, Vector4.ZERO],
	"Keeper’s Cottage": [Vector4(0.235, 0.37, 0.035, 0.07), Vector4(0.50, 0.15, 0.025, 0.04), Vector4.ZERO, Vector4.ZERO],
	"Home": [Vector4(0.82, 0.52, 0.13, 0.20), Vector4(0.84, 0.77, 0.25, 0.22), Vector4(0.12, 0.42, 0.22, 0.38), Vector4.ZERO],
	"Puppy Club": [Vector4(0.055, 0.26, 0.055, 0.10), Vector4(0.262, 0.30, 0.055, 0.10), Vector4(0.18, 0.40, 0.095, 0.18), Vector4(0.20, 0.55, 0.16, 0.15)],
	"Shop": [Vector4(0.20, 0.24, 0.22, 0.33), Vector4(0.27, 0.57, 0.23, 0.25), Vector4(0.90, 0.61, 0.16, 0.27), Vector4(0.50, 0.84, 0.33, 0.16)],
	"Vet Clinic": [Vector4(0.875, 0.095, 0.12, 0.13), Vector4(0.57, 0.02, 0.10, 0.10), Vector4(0.76, 0.02, 0.10, 0.10), Vector4(0.72, 0.76, 0.24, 0.30)],
	"Island": [Vector4(0.23, 0.20, 0.055, 0.075), Vector4(0.54, 0.20, 0.06, 0.08), Vector4(0.28, 0.50, 0.05, 0.07), Vector4(0.80, 0.49, 0.05, 0.07)],
	"Lighthouse": [Vector4(0.884, 0.13, 0.035, 0.045), Vector4(0.90, 0.27, 0.07, 0.05), Vector4.ZERO, Vector4.ZERO]
}

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://scripts/daylight.gdshader")
	for location in LIGHTS:
		material_for(location)
	refresh(true)

func _process(delta: float) -> void:
	clock += delta
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

func apply_minute(minute: int, immediate: bool = false) -> void:
	var period = period_at(minute)
	if period.name == current_period and not immediate:
		return
	current_period = period.name
	if transition != null and transition.is_valid():
		transition.kill()
	if immediate:
		for target in [material] + location_materials.values():
			target.set_shader_parameter("tone", period.tone)
			target.set_shader_parameter("exposure", period.light)
			target.set_shader_parameter("coolness", period.cool)
	else:
		transition = create_tween().set_parallel(true)
		for target in [material] + location_materials.values():
			transition.tween_property(target, "shader_parameter/tone", period.tone, 12.0)
			transition.tween_property(target, "shader_parameter/exposure", period.light, 12.0)
			transition.tween_property(target, "shader_parameter/coolness", period.cool, 12.0)

func material_for(location: String) -> ShaderMaterial:
	if not LIGHTS.has(location):
		return material
	if not location_materials.has(location):
		var local: ShaderMaterial = material.duplicate()
		for index in 4:
			local.set_shader_parameter("lamp_" + str(index), LIGHTS[location][index])
		location_materials[location] = local
	return location_materials[location]

func apply_to(background: CanvasItem, location: String = "Home") -> void:
	background.material = material_for(location)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and material != null:
		refresh(true)
