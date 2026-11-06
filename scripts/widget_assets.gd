extends SceneTree

func _initialize() -> void:
	call_deferred("export_assets")

func export_assets() -> void:
	var target = "res://build/widget-assets"
	DirAccess.make_dir_recursive_absolute(target)
	var files = {"CareFood": "feed", "CareHappy": "happy", "CareEnergy": "rest", "CareClean": "care"}
	var failure = false
	for name in files:
		var picture = Image.new()
		# Rasterize the vectors at 3x instead of upscaling their imported 1x bitmap.
		var error = picture.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/" + files[name] + ".svg"), 3.0)
		if error != OK:
			failure = true
			continue
		failure = picture.save_png(target.path_join(name + ".png")) != OK or failure
	var game = root.get_node("Game")
	game.set_process(false)
	game.breed = "Puppy"
	game.life.accessory = ""
	failure = WidgetState.artwork_image(game).save_png(target.path_join("PreviewDog.png")) != OK or failure
	print("Widget artwork export ", "FAILED" if failure else "passed")
	quit(1 if failure else 0)
