extends SceneTree
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1
func run() -> void:
	var lighting = root.get_node("Daylight")
	lighting.set_process(false)
	for index in lighting.PERIODS.size():
		var period: Dictionary = lighting.PERIODS[index]
		check(lighting.period_at(period.start).name == period.name, "Each lighting period starts at its local boundary")
		var previous: Dictionary = lighting.PERIODS[posmod(index - 1, lighting.PERIODS.size())]
		check(lighting.period_at(period.start - 1).name == previous.name, "The minute before a boundary keeps the previous period")
		lighting.apply_minute(period.start, true)
		check(is_equal_approx(lighting.material.get_shader_parameter("exposure"), period.light), "Immediate lighting applies the selected brightness")
	check(lighting.period_at(1440).name == "Late night", "Midnight wraps to a fresh local day")
	lighting.refresh(true)
	var local = Time.get_datetime_dict_from_system(false)
	check(lighting.current_period == lighting.period_at(local.hour * 60 + local.minute).name, "The device local clock chooses the period")
	lighting.apply_minute(720, true)
	var home_light = lighting.material_for("Home")
	var clinic_light = lighting.material_for("Vet Clinic")
	check(home_light.get_shader_parameter("lamp_0") != clinic_light.get_shader_parameter("lamp_0"), "Building lamps stay anchored to their own artwork")
	check(home_light.get_shader_parameter("exposure") == lighting.material.get_shader_parameter("exposure"), "Indoor lamps share the device clock brightness")
	lighting.apply_minute(1320)
	check(lighting.transition != null and lighting.transition.is_running(), "Live changes blend instead of snapping")
	lighting._notification(NOTIFICATION_APPLICATION_RESUMED)
	check(home_light.get_shader_parameter("tone") == lighting.material.get_shader_parameter("tone"), "Resume updates every building's lighting")
	check(lighting.current_period == lighting.period_at(local.hour * 60 + local.minute).name, "Resume catches up with the local clock")
	var game = root.get_node("Game")
	game.set_process(false)
	game.intro_seen = true
	game.pending_stage = ""
	game.storage_path = "user://daylight_test.json"
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	check(main.habitat.background.material == lighting.material_for("Home"), "Home uses the shared background lighting")
	main.show_page("Island")
	await process_frame
	var map = main.world_host.get_child(0)
	check(map.map_image.material == lighting.material_for("Island"), "Full-screen map uses its local lamps with clock lighting")
	main.queue_free()
	await process_frame
	print("Daylight checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
