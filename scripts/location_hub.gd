extends VBoxContainer

var host: Control
var location = "Puppy Club"
var wallet: Label
var description: Label
var feedback: Label
var buy_buttons: Dictionary = {}
var groom_button: Button
var choices: GridContainer

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation", 8)
 var spacer = Control.new()
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(spacer)
 var panel = UI.card()
 panel.custom_minimum_size.x = 460
 panel.size_flags_horizontal = Control.SIZE_SHRINK_END
 add_child(panel)
 var content = UI.column(8)
 content.custom_minimum_size.x = 420
 panel.add_child(content)
 var heading = HBoxContainer.new()
 content.add_child(heading)
 var emblem = TextureRect.new()
 emblem.texture = UI.place_icon(location)
 emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 emblem.custom_minimum_size = Vector2(52, 52)
 heading.add_child(emblem)
 var place_name = UI.label(location, 30, UI.TEAL)
 place_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 place_name.autowrap_mode = TextServer.AUTOWRAP_OFF
 heading.add_child(place_name)
 wallet = UI.label("", 23)
 content.add_child(wallet)
 description = UI.label("", 23)
 content.add_child(description)
 feedback = UI.label("", 21)
 content.add_child(feedback)
 choices = GridContainer.new()
 choices.columns = 2
 choices.add_theme_constant_override("h_separation", 10)
 choices.add_theme_constant_override("v_separation", 10)
 content.add_child(choices)
 match location:
  "Park":
   description.text = "An open plaza for little paws and bouncy balls."
   var text = "Resume Fetch" if Game.active_outing.get("kind", "") == "Fetch" else "Play Fetch"
   add_choice(text, preload("res://assets/ui/play.svg"), host.start_activity.bind("Fetch"), Color("c8eddd"))
   add_choice("Talk to Ben", UI.resident_icon(Art.BEN), talk_to_ben, Color("ffdfb5"))
   add_choice("Practice sit", preload("res://assets/ui/training_treat.svg"), little_activity)
   feedback.text = "Three throws. Earn island coins."
  "Beach":
   description.text = "A gentle coastal path with three discoveries."
   var text = "Resume Walk" if Game.active_outing.get("kind", "") == "Walk" else "Go for a Walk"
   add_choice(text, preload("res://assets/ui/leaf.svg"), host.start_activity.bind("Walk"), Color("c8eddd"))
   add_choice("Talk to Owen", UI.resident_icon(Art.OWEN), talk_to_owen, Color("ffdfb5"))
   add_choice("Sniff the breeze", UI.place_icon("Beach"), little_activity)
   feedback.text = "Three discoveries, then head home."
  "Puppy Club":
   description.text = "Nora's gathering place for island friends."
   add_choice("Talk to Nora", UI.resident_icon(Art.NORA), talk_to_nora, Color("ffdfb5"))
   add_choice("Say hello", preload("res://assets/ui/heart.svg"), little_activity)
   add_choice("Play Fetch", preload("res://assets/ui/play.svg"), host.start_activity.bind("Fetch"), Color("c8eddd"))
   add_choice("Go for a Walk", preload("res://assets/ui/leaf.svg"), host.start_activity.bind("Walk"), Color("c2ecf4"))
  "Shop":
   description.text = "June's little comforts for your puppy."
   add_choice("Talk to June", UI.resident_icon(Art.JUNE), talk_to_june)
   for kind in ["Treat", "Toy", "Brush"]:
    var button = add_choice("", Goods.picture(kind), purchase.bind(kind), Color("ffdfb5"))
    buy_buttons[kind] = button
   feedback.text = "Treats boost the next Feed; toys and brushes improve Play and Care."
  "Vet Clinic":
   description.text = "Leah is here for gentle checkups and coat care."
   add_choice("Free checkup", UI.resident_icon(Art.LEAH), checkup, Color("c2ecf4"))
   groom_button = add_choice("Grooming", preload("res://assets/ui/care.svg"), groom, Color("c8eddd"))
   feedback.text = "Grooming costs 12 coins. Home care is free."
  "Lighthouse":
   description.text = "A quiet lookout for a later chapter."
   feedback.text = "Preview only. The Lighthouse is still closed."
   add_choice("Island map", preload("res://assets/ui/island.svg"), host.show_page.bind("Island"))
 Game.changed.connect(refresh)
 refresh()

func add_choice(text: String, picture: Texture2D, action: Callable, color: Color = Color("f9d8e2")) -> Button:
 var button = UI.icon_button(text, picture, action, color)
 button.custom_minimum_size = Vector2(205, 110)
 button.add_theme_font_size_override("font_size", 22)
 choices.add_child(button)
 return button

func refresh() -> void:
 if location == "Puppy Club":
  wallet.text = "Walks: %d    Fetch games: %d" % [Game.walks, Game.fetches]
 elif location == "Lighthouse":
  wallet.text = "Opens later"
 else:
  wallet.text = "Island coins: %d" % Game.coins
 for kind in buy_buttons:
  var owned = Game.items[kind]
  var full = owned >= (5 if kind == "Treat" else 1)
  UI.button_caption(buy_buttons[kind], "Owned" if full else "Buy " + kind)
  buy_buttons[kind].tooltip_text = "%d coins" % Game.PRICES[kind]
  buy_buttons[kind].disabled = full or Game.coins < Game.PRICES[kind]
 if is_instance_valid(groom_button):
  groom_button.disabled = Game.coins < 12 or Game.needs.Cleanliness >= 99

func purchase(kind: String) -> void:
 feedback.text = Game.buy_item(kind)
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error
 refresh()

func talk_to_nora() -> void:
 Game.meet_nora()
 host.show_resident(Art.NORA, "Nora", "Puppy Club organizer", Game.personalize("Lovely to see you and Mochi!\n\nTry Fetch at the Park or a Walk at the Beach. Your Journal follows every little chapter."))

func little_activity() -> void:
 feedback.text = Game.island_moment(location)
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error

func checkup() -> void:
 host.show_resident(Art.LEAH, "Leah", "Veterinarian", Game.clinic_checkup())

func groom() -> void:
 feedback.text = Game.clinic_groom()
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error
 refresh()

func talk_to_june() -> void:
 host.show_resident(Art.JUNE, "June", "Shopkeeper", "Welcome! Treats, toys and little comforts await.\n\nTap a picture to learn more. Earn coins through Walks and Fetch.")

func talk_to_ben() -> void:
 host.show_resident(Art.BEN, "Ben", "Trainer", Game.personalize("I'm Ben! Ready for Fetch?\n\nTap Throw in the green zone. Let Mochi bring the ball back. Three throws make a game!"))

func talk_to_owen() -> void:
 host.show_resident(Art.OWEN, "Owen", "Neighbor", Game.personalize("Hi, I'm Owen! Lovely to meet you and Mochi.\n\nFind three treasures along the coast, then walk home. Your Journal keeps the memories."))
