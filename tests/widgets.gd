extends SceneTree

var failures = 0
class FakeNative extends RefCounted:
	var calls: Array = []
	var succeed = true
	func is_available() -> bool:
		return true
	func publish_snapshot(json: String, leaving: bool) -> bool:
		calls.append({"snapshot": JSON.parse_string(json), "leaving": leaving})
		return succeed

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func run() -> void:
	var game = root.get_node("Game")
	var widgets = root.get_node("Widgets")
	game.set_process(false)
	game.storage_path = "user://widget_test.json"
	game.breed = "Puppy"
	game.points = 0
	game.active_seconds = 0
	game.resting = false
	game.paused_at = 0
	game.life = IslandLife.fresh()
	game.items = {}
	for kind in Goods.ITEMS:
		game.items[kind] = 0
	game.needs = {"Hunger": 40.0, "Happiness": 50.0, "Energy": 60.0, "Cleanliness": 70.0}
	game.cooldowns = {}
	var fake = FakeNative.new()
	widgets.native = fake
	check(game.save_game(), "Widget publishes after a successful save")
	var state: Dictionary = fake.calls.back().snapshot
	check(state.needs == [40.0,50.0,60.0,70.0], "Widget care order matches its four icons")
	check(not state.has("name") and not state.has("puppy_name"), "Widget does not export dog names or unrelated save details")
	check(not state.has("coins") and not state.has("health"), "Shared widget data is limited to its display")
	check(state.breed == "Puppy" and state.stage == "Tiny puppy", "Widget shares the current growth stage")
	var image = Image.new()
	check(image.load_png_from_buffer(Marshalls.base64_to_raw(state.artwork)) == OK, "Shared dog art is a usable transparent PNG")
	check(image.get_size() == Vector2i(384,384), "Widget art has a bounded memory footprint")
	var bounds = image.get_used_rect()
	check(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 384 and bounds.end.y < 384, "The whole dog fits safely inside its artwork canvas")
	var normal = state.artwork
	game.action("Feed")
	check(fake.calls.back().snapshot.needs[0] > 40, "Feeding refreshes widget care immediately after saving")
	check(fake.calls.back().snapshot.artwork == normal, "Unchanged artwork is cached during care actions")
	game.puppy_name = "むぎ"
	game.save_game()
	check(not JSON.stringify(fake.calls.back().snapshot).contains("むぎ"), "A dog rename does not introduce widget text")
	game.items.CoralBandana = 1
	game.life.accessory = "CoralBandana"
	game.save_game()
	check(fake.calls.back().snapshot.artwork != normal, "Widget wears the player's equipped bandana")
	game.items.CoralBandana = 0
	game.save_game()
	check(fake.calls.back().snapshot.artwork == normal, "Unowned accessories cannot leak into the widget")
	for breed in ["Shiba Inu", "Golden Retriever"]:
		game.breed = breed
		game.save_game()
		state = fake.calls.back().snapshot
		check(state.breed == breed and state.stage == "Adult" and state.growth == 1.0, "Widget uses the actual evolved dog: " + breed)
		check(state.artwork != normal, "Adult breeds never reuse a generic puppy portrait")
		image.load_png_from_buffer(Marshalls.base64_to_raw(state.artwork))
		bounds = image.get_used_rect()
		check(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 384 and bounds.end.y < 384, "Adult paws and ears stay within the canvas: " + breed)
	var before = fake.calls.size()
	game.coins = -1
	check(not game.save_game() and fake.calls.size() == before, "Rejected saves never replace good widget state")
	game.coins = 50
	fake.succeed = false
	check(game.save_game() and not widgets.last_error.is_empty(), "Widget storage failure cannot prevent the game save")
	fake.succeed = true
	game.breed = "Puppy"
	game.resting = true
	game.items.CloudBed = 1
	game.paused_at = Time.get_unix_time_from_system()
	game.save_game()
	check(fake.calls.back().leaving, "Leaving requests the latest widget timeline")
	check(is_equal_approx(fake.calls.back().snapshot.restRate,0.85), "Owned comfortable beds improve shared rest recovery")
	game.paused_at = 0
	game.resting = false
	game.needs = {"Hunger":80.0,"Happiness":80.0,"Energy":90.0,"Cleanliness":85.0}
	game.save_game()
	state = fake.calls.back().snapshot
	var at = float(state.updatedAt) + 7200.0
	game.advance(7200,false)
	var expected: Array = []
	for key in game.NEEDS:
		expected.append(game.needs[key])
	DirAccess.make_dir_recursive_absolute("res://build/widget-assets")
	var fixture = FileAccess.open("res://build/widget-assets/snapshot-fixture.json", FileAccess.WRITE)
	fixture.store_string(JSON.stringify({"snapshot": state, "at":at, "expected":expected}))
	fixture.close()
	widgets.native = null
	before = fake.calls.size()
	check(game.save_game() and fake.calls.size() == before, "Desktop and unsupported platforms keep working without widgets")
	# Opening the app for a widget must not replace a damaged save automatically.
	game.storage_path = "user://widget_unreadable_test.json"
	for suffix in ["", ".bak"]:
		var damaged = FileAccess.open(game.storage_path + suffix, FileAccess.WRITE)
		damaged.store_string("unreadable progress")
		damaged.close()
	game.load_game()
	widgets.native = fake
	before = fake.calls.size()
	widgets._ready()
	check(FileAccess.get_file_as_string(game.storage_path) == "unreadable progress", "Widget startup preserves unreadable saves for recovery")
	check(fake.calls.size() == before, "Unreadable progress is not published as a fresh widget save")
	check(game.save_game() and fake.calls.size() == before + 1, "An intentional successful save resumes widget updates")
	widgets.native = null
	print("Widget tests ", "passed" if failures == 0 else "FAILED: " + str(failures))
	quit(0 if failures == 0 else 1)
