extends SceneTree
var failures = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1
func run() -> void:
	var original = "Tap Throw in the green zone. [color=red]Mochi[/color]"
	var hint = UI.hint_label(original, 25)
	root.add_child(hint)
	await process_frame
	check("[color=#176c91][b]Throw" in hint.text and "[color=#247a4d][b]green zone" in hint.text, "Actions and target cues receive distinct readable highlights")
	check(hint.get_parsed_text() == original, "Hint formatting preserves words and treats brackets as plain text")
	check(CommandHint.markup("Playful resting") == "Playful resting", "Command highlighting does not match inside unrelated words")
	hint.text = "Choose Rest at Home."
	await process_frame
	check("[b]Rest[/b]" in hint.text, "Changing hints refreshes their command highlights")
	hint.queue_free()
	var game = root.get_node("Game")
	var sound = root.get_node("Sound")
	game.set_process(false)
	game.storage_path = "user://player_features_test.json"
	game.choose_name("   ")
	check(game.puppy_name == "Mochi", "Blank name keeps the default")
	game.choose_name("  Sora  ")
	check(game.puppy_name == "Sora" and game.name_chosen, "Name is trimmed and remembered")
	game.choose_name("ABCDEFGHIJKLMNOPQRST")
	check(game.puppy_name.length() == 16, "Names fit the mobile UI")
	game.choose_name("Mochita")
	check(game.personalize("Meet Mochi!") == "Meet Mochita!", "Names can contain the default name")
	sound.set_enabled(false)
	sound.play_effect("feed")
	check(not sound.ambience.playing, "Mute stops the ambience")
	for voice in sound.voices:
		check(not voice.playing, "Muted effects stay silent")
	sound.set_enabled(true)
	sound.play_effect("feed")
	check(sound.ambience.playing, "Unmute resumes ambience")
	sound.set_enabled(false)
	game.save_game()
	game.puppy_name = "Mochi"
	game.sound_enabled = true
	game.load_game()
	check(game.puppy_name == "Mochita" and not game.sound_enabled, "Name and sound preference survive reload")
	game.active_outing = {}
	game.saved_outings = {}
	game.begin_outing("Walk")
	game.checkpoint_outing(2)
	game.begin_outing("Fetch")
	game.checkpoint_outing(1, 1)
	check(game.has_outing("Walk") and game.has_outing("Fetch"), "Switching activities preserves both outings")
	game.load_game()
	check(game.begin_outing("Walk").checkpoint == 2, "Walk checkpoint survives switching and reloading")
	game.checkpoint_outing(-1)
	check(game.active_outing.checkpoint == 2, "Invalid checkpoints cannot corrupt progress")
	game.checkpoint_outing(3)
	check(game.complete_outing("Walk") and not game.complete_outing("Walk"), "Walk rewards can only be claimed once")
	check(game.begin_outing("Fetch").score == 1, "Completing Walk preserves Fetch score")
	game.checkpoint_outing(3, 1)
	var before_coins = game.coins
	check(game.complete_outing("Fetch", 99), "Saved Fetch can finish after a Walk")
	check(game.coins == before_coins + 11, "Fetch rewards use the saved score rather than a caller-supplied value")
	check(not game.has_outing("Fetch") and not game.has_outing("Walk"), "Finished outings are removed")
	var good_save = FileAccess.get_file_as_string(game.storage_path)
	game.coins = -1
	check(not game.save_game(), "Invalid runtime state is refused before writing")
	check(FileAccess.get_file_as_string(game.storage_path) == good_save, "Failed validation preserves the last usable save")
	game.load_game()
	check(game.coins >= before_coins, "Valid progress remains loadable after a rejected save")
	game.intro_seen = true
	game.pending_stage = ""
	game.last_stage = "Tiny puppy"
	game.breed = "Puppy"
	game.points = 8
	game.active_seconds = 600
	game.collection = []
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	game.update_growth()
	await process_frame
	await process_frame
	check(is_instance_valid(main.stage_overlay), "New stages open a growth celebration")
	check(not game.is_processing(), "Growth moment pauses needs")
	main.close_growth_moment()
	check(game.pending_stage.is_empty(), "Acknowledged celebrations do not repeat")
	game.set_process(false)
	main.show_intro()
	main.advance_intro()
	check("Mochita" in main.intro_text.text and not "Mochitata" in main.intro_text.text, "Nora uses the chosen name once")
	main.queue_free()
	await process_frame
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(game.storage_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(game.storage_path + suffix))
	print("Player feature checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
