extends Control

func _ready() -> void:
	Game.set_process(false)
	call_deferred("open_saved_game")

func open_saved_game() -> void:
	# An unfinished welcome resumes with Nora after the puppy has been named.
	var returning = Game.name_chosen or Game.intro_seen
	var destination = "res://scenes/main.tscn" if returning else "res://scenes/start_menu.tscn"
	Game.set_process(returning)
	if get_tree().change_scene_to_file(destination) != OK:
		Game.set_process(false)
		push_error("Could not open the game screen.")
