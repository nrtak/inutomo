class_name CommandHint
extends RichTextLabel

var rendered_text = ""
var source_text = ""
static var commands: RegEx

static func escaped(value: String) -> String:
	var result = ""
	for character in value:
		result += "[lb]" if character == "[" else ("[rb]" if character == "]" else character)
	return result

static func markup(value: String) -> String:
	if commands == null:
		commands = RegEx.new()
		commands.compile("\\b(?:Go for a Walk|Throw the ball|Island life|Title screen|green zone|Feed|Play|Care|Rest|Wake|Throw|Fetch|Walk|Explore|Capture|Photo|Wardrobe|Training|Sit|Stay|Come|Buy|Use|Wear|Preview|Go|Close|Home|Island|Bag|Shop|Journal|Menu)\\b")
	var result = ""
	var cursor = 0
	for match in commands.search_all(value):
		result += escaped(value.substr(cursor, match.get_start() - cursor))
		var color = "#247a4d" if match.get_string() == "green zone" else "#176c91"
		result += "[color=" + color + "][b]" + escaped(match.get_string()) + "[/b][/color]"
		cursor = match.get_end()
	return result + escaped(value.substr(cursor))

func set_hint(value: String) -> void:
	if value != source_text or rendered_text.is_empty():
		source_text = value
		rendered_text = markup(value)
	text = rendered_text

func _process(_delta: float) -> void:
	if text != rendered_text:
		set_hint(text)
