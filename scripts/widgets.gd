extends Node

var native: Object
var cached_key = ""
var cached_artwork = ""
var last_error = ""

func _ready() -> void:
	if OS.get_name() == "iOS" and Engine.has_singleton("PuppyWidgets"):
		native = Engine.get_singleton("PuppyWidgets")
	# Publish only a successful save, never unpersisted or rejected game state.
	# Leave an unreadable save untouched until the player deliberately proceeds.
	if available() and Game.save_error.is_empty():
		Game.save_game()

func available() -> bool:
	return is_instance_valid(native) and native.is_available()

func sync_saved_game(saved_at: float) -> void:
	if not available():
		return
	var key = WidgetState.artwork_key(Game)
	if key != cached_key or cached_artwork.is_empty():
		cached_artwork = Marshalls.raw_to_base64(WidgetState.artwork_image(Game).save_png_to_buffer())
		cached_key = key
	var state = WidgetState.snapshot(Game, saved_at, cached_artwork)
	var ok: bool = native.publish_snapshot(JSON.stringify(state), Game.paused_at > 0.0)
	last_error = "" if ok else "Widget snapshot could not be shared."
