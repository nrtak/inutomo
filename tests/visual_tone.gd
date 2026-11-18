extends SceneTree

var failures = 0
func _initialize(): call_deferred("run")
func check(condition: bool, message: String):
	if not condition:
		push_error(message)
		failures += 1

func run():
	var game = root.get_node("Game")
	game.set_process(false)
	game.storage_path = "user://visual_tone_test.json"
	game.intro_seen = true
	game.name_chosen = true
	game.pending_stage = ""
	game.home_greeted = true
	var tone = root.get_node("VisualTone")
	check(tone.finish.mouse_filter==Control.MOUSE_FILTER_IGNORE and tone.finish.focus_mode==Control.FOCUS_NONE,"The color finish cannot intercept touch or keyboard navigation")
	var photo = TextureRect.new()
	tone.prepare_photo(photo,"puppy_photo_legacy.png")
	check(photo.material==null,"Older photos receive the normal screen finish")
	tone.prepare_photo(photo,"puppy_photo_soft1_test.png")
	check(photo.material!=null,"New photos avoid being color-adjusted twice in the album")
	photo.free()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for place in ["Home","Island","Beach","Shop"]:
		main.show_page(place)
		await process_frame
		await process_frame
		check(tone.finish.get_global_rect()==root.get_visible_rect(),"The color finish covers the whole screen: "+place)
		main.menu_button.pressed.emit()
		check(is_instance_valid(main.navigation_overlay),"Menu remains available beneath the color finish: "+place)
		main.close_navigation()
	main.queue_free()
	await process_frame
	var title = load("res://scenes/start_menu.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check(is_instance_valid(tone.finish) and tone.finish.is_visible_in_tree(),"The same color finish stays active on the title screen")
	title.queue_free()
	await process_frame
	print("Visual tone checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
