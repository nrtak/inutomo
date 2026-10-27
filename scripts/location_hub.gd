extends VBoxContainer

var host: Control
var location = "Puppy Club"
var wallet: Label
var description: Label
var feedback: Label
var buy_buttons: Dictionary = {}
var groom_button: Button

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation", 8)
 var spacer = Control.new()
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(spacer)
 var panel = UI.card()
 panel.custom_minimum_size.x = 500
 panel.size_flags_horizontal = Control.SIZE_SHRINK_END
 add_child(panel)
 var content = UI.column(8)
 content.custom_minimum_size.x = 460
 panel.add_child(content)
 content.add_child(UI.label(location, 30, UI.TEAL))
 wallet = UI.label("", 23)
 content.add_child(wallet)
 description = UI.label("", 23)
 content.add_child(description)
 feedback = UI.label("", 21)
 content.add_child(feedback)
 match location:
  "Park":
   description.text = "An open plaza for little paws and bouncy balls."
   var text = "Resume Fetch" if Game.active_outing.get("kind", "") == "Fetch" else "Play Fetch"
   content.add_child(UI.button(text, host.start_activity.bind("Fetch"), Color("bdeab0")))
   content.add_child(UI.button("Talk to Ben", talk_to_ben, Color("ffe0b0")))
   feedback.text = "Three throws. Finish together to earn island coins."
  "Beach":
   description.text = "A gentle coastal path with three discoveries."
   var text = "Resume Walk" if Game.active_outing.get("kind", "") == "Walk" else "Go for a Walk"
   content.add_child(UI.button(text, host.start_activity.bind("Walk"), Color("b7def4")))
   content.add_child(UI.button("Talk to Owen", talk_to_owen, Color("ffe0b0")))
   feedback.text = "The path goes down, across the foreground and back up."
  "Puppy Club":
   description.text = "Nora's gathering place for island friends."
   content.add_child(UI.button("Talk to Nora", talk_to_nora, Color("ffe0b0")))
   content.add_child(UI.button("Fetch at the Park", host.start_activity.bind("Fetch"), Color("bdeab0")))
   content.add_child(UI.button("Walk by the Beach", host.start_activity.bind("Walk"), Color("b7def4")))
  "Shop":
   description.text = "June's little comforts for your puppy."
   content.add_child(UI.button("Talk to June", talk_to_june, Color("b7def4")))
   for kind in ["Treat", "Toy", "Brush"]:
    var button = UI.button("", purchase.bind(kind), Color("ffe0b0"))
    content.add_child(button)
    buy_buttons[kind] = button
   feedback.text = "Treats boost the next Feed; toys and brushes improve Play and Care."
  "Vet Clinic":
   description.text = "Leah is here for gentle checkups and coat care."
   content.add_child(UI.button("Checkup / Free", checkup, Color("b7def4")))
   groom_button = UI.button("Gentle grooming / 12 coins", groom, Color("bdeab0"))
   content.add_child(groom_button)
   feedback.text = "Care at Home is always free."
  "Lighthouse":
   description.text = "A quiet lookout for a later chapter."
   feedback.text = "Preview only. The Lighthouse is still closed."
   content.add_child(UI.button("Back to Island", host.show_page.bind("Island"), Color("b7def4")))
 Game.changed.connect(refresh)
 refresh()

func refresh() -> void:
 if location == "Puppy Club":
  wallet.text = "Walks together: %d / Fetch games: %d" % [Game.walks, Game.fetches]
 elif location == "Lighthouse":
  wallet.text = "Locked / Opens later"
 else:
  wallet.text = "Island coins: %d" % Game.coins
 for kind in buy_buttons:
  var owned = Game.items[kind]
  var full = owned >= (5 if kind == "Treat" else 1)
  buy_buttons[kind].text = "%s / %d coins%s" % [kind, Game.PRICES[kind], " / Owned" if full and kind != "Treat" else (" / %d in jar" % owned if kind == "Treat" else "")]
  buy_buttons[kind].disabled = full or Game.coins < Game.PRICES[kind]
 if is_instance_valid(groom_button):
  groom_button.disabled = Game.coins < 12 or Game.needs.Cleanliness >= 99

func purchase(kind: String) -> void:
 feedback.text = Game.buy_item(kind)
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error
 refresh()

func talk_to_nora() -> void:
 host.show_resident(Art.NORA, "Nora", "Puppy Club organizer", Game.personalize("Lovely to see you and Mochi!\n\nStart with little moments at Home, or try Fetch at the Park and a Walk by the Beach. The Journal follows your puppy's growth.\n\nNo rush. Enjoy island life together!"))

func checkup() -> void:
 host.show_resident(Art.LEAH, "Leah", "Veterinarian", Game.clinic_checkup())

func groom() -> void:
 feedback.text = Game.clinic_groom()
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error
 refresh()

func talk_to_june() -> void:
 host.show_resident(Art.JUNE, "June", "Shopkeeper", "Welcome to my little shop!\n\nA treat adds a little extra to the next meal. The toy and brush stay with you and improve Play and Care.\n\nEarn island coins through Walks and Fetch. Everyday care at Home is always free.")

func talk_to_ben() -> void:
 host.show_resident(Art.BEN, "Ben", "Trainer", Game.personalize("Hey, you two! I'm Ben. Ready for a little Fetch practice?\n\nTap Throw when the power reaches the green zone near 70%. Let Mochi bring the ball back before the next throw.\n\nThree throws make a game. If those paws get tired, a cozy rest at Home helps."))

func talk_to_owen() -> void:
 host.show_resident(Art.OWEN, "Owen", "Neighbor", Game.personalize("Hi! I'm Owen. I live just up the path. It's lovely to meet you and Mochi!\n\nThe coastal walk has a leafy trail, a seashell cove and a sunset lookout. Take your time, then head back up the path.\n\nYour Journal keeps the little discoveries you find together."))
