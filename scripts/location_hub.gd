extends VBoxContainer

var host: Control
var location = "Puppy Club"
var wallet: Label
var description: CommandHint
var feedback: CommandHint
var buy_buttons: Dictionary = {}
var groom_button: Button
var health_button: Button
var primary_actions: VBoxContainer
var choices: GridContainer

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation", 8)
 var spacer = Control.new()
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var row = HBoxContainer.new()
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(row)
 row.add_child(spacer)
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.custom_minimum_size.x = 400
 row.add_child(scroll)
 var content = UI.column(10)
 content.custom_minimum_size.x = 380
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 wallet = UI.label("", 23)
 wallet.visible = false
 content.add_child(wallet)
 description = UI.hint_label("", 23)
 description.visible = false
 content.add_child(description)
 feedback = UI.hint_label("", 21)
 feedback.visible = false
 content.add_child(feedback)
 primary_actions = UI.column(10)
 content.add_child(primary_actions)
 choices = GridContainer.new()
 choices.columns = 1
 choices.add_theme_constant_override("v_separation", 10)
 content.add_child(choices)
 if location == "Harbor" and not Game.life.story.get("welcome", false):
  IslandStory.advance(Game, "welcome")
 if location == "Keeper’s Cottage" and not Game.life.story.get("met_keeper", false):
  IslandStory.advance(Game, "meet")
 match location:
  "Harbor":
   description.text = "The ferry brings supplies and new island stories."
   wallet.visible = false
   var story: Dictionary = Game.life.story
   if not story.get("welcome", false):
    add_primary("Meet Owen", UI.resident_icon(Art.OWEN), harbor_welcome)
   elif not story.get("kit", false):
    add_primary("Collect lantern kit", preload("res://assets/ui/menu_bag.svg"), story_action.bind("kit"))
   elif story.get("lantern", false) and not story.get("repair_supplies", false):
    add_primary("Collect repair crate", preload("res://assets/ui/menu_bag.svg"), story_action.bind("repair_supplies"))
   else:
    add_primary("Visit Cottage", UI.place_icon("Keeper’s Cottage"), host.request_page.bind("Keeper’s Cottage"))
   if story.get("welcome", false):
    pass
   else:
    add_choice("Visit Cottage", UI.place_icon("Keeper’s Cottage"), host.request_page.bind("Keeper’s Cottage"))
   add_choice("Story Journal", preload("res://assets/ui/menu_journal.svg"), host.request_page.bind("Journal"))
   add_choice("Parcels", preload("res://assets/ui/menu_bag.svg"), host.show_page.bind("Life:Deliveries"), Color("c8eddd"))
   feedback.text = IslandStory.next_step(Game).text
  "Keeper’s Cottage":
   description.text = "Ren keeps a welcoming light beside the coastal path."
   wallet.visible = false
   var story: Dictionary = Game.life.story
   if not story.get("met_keeper", false):
    add_primary("Meet Ren", UI.resident_icon(Art.REN), meet_ren)
   elif not story.get("kit", false):
    add_primary("Visit Harbor", UI.place_icon("Harbor"), host.request_page.bind("Harbor"))
   elif not story.get("delivered", false):
    add_primary("Deliver lantern kit", preload("res://assets/ui/menu_bag.svg"), story_action.bind("deliver"))
   elif not story.get("lantern", false):
    add_primary("Prepare lantern", preload("res://assets/ui/sunset.svg"), story_action.bind("lantern"))
   elif not story.get("beacon_checked", false):
    var step = IslandStory.restoration_step(Game)
    if step.place != location:
     add_primary(step.button, UI.place_icon(step.place), host.request_page.bind(step.place))
    else:
     add_primary(step.button, preload("res://assets/ui/sunset.svg"), story_action.bind(step.action))
   else:
    add_primary("Island stories", preload("res://assets/ui/menu_journal.svg"), host.request_page.bind("Journal"))
   if story.get("met_keeper", false) and not story.get("lantern", false):
    pass
   else:
    add_choice("Visit Harbor", UI.place_icon("Harbor"), host.request_page.bind("Harbor"))
   add_choice("Story Journal", preload("res://assets/ui/menu_journal.svg"), host.request_page.bind("Journal"))
   feedback.text = IslandStory.next_step(Game).text
  "Park":
   description.text = "An open plaza for little paws and bouncy balls."
   var text = "Resume Fetch" if Game.has_outing("Fetch") else "Play Fetch"
   add_primary(text, preload("res://assets/ui/play.svg"), host.start_activity.bind("Fetch"), Color("c8eddd"))
   add_choice("Training", preload("res://assets/ui/training_treat.svg"), host.show_page.bind("Life:Training"), Color("f9d8e2"))
   feedback.text = "Three throws. Earn island coins."
  "Beach":
   add_primary("Find shells", beach_picture(0), host.open_beach_activity.bind("Shells"), Color("f9d8e2"))
   add_primary("Beach cleanup", beach_picture(1), host.open_beach_activity.bind("Cleanup"), Color("c8eddd"))
   add_primary("Sand fetch", beach_picture(2), host.open_beach_activity.bind("Sand Fetch"), Color("c2ecf4"))
   add_choice("Resume Walk" if Game.has_outing("Walk") else "Go for a walk", preload("res://assets/ui/leaf.svg"), host.start_activity.bind("Walk"))
  "Puppy Club":
   description.text = "Meet Nora and your island friends."
   wallet.visible = false
   add_choice("Puppy playdate", preload("res://assets/ui/heart.svg"), host.show_page.bind("Life:Playdate"))
   add_primary("Today's event", preload("res://assets/ui/heart.svg"), host.show_page.bind("Life:Events"), Color("f9d8e2"))
   add_choice("Friends", preload("res://assets/ui/club.svg"), host.show_page.bind("Life:Friends"), Color("e1d9f6"))
  "Shop":
   add_primary("Food & treats", Goods.picture("Treat"), host.browse_shop.bind("Food"), Color("ffdfb5"))
   add_primary("Toys & play", Goods.picture("Toy"), host.browse_shop.bind("Toys"), Color("c8eddd"))
   add_primary("Style & comfort", Goods.picture("CoralBandana"), host.browse_shop.bind("Accessories"), Color("f9d8e2"))
   add_choice("Care goods", Goods.picture("Brush"), host.browse_shop.bind("Care"))
  "Vet Clinic":
   description.text = "Checkups, treatment and supplies."
   health_button = add_primary("Free checkup", UI.resident_icon(Art.LEAH), clinic_main_action, Color("c2ecf4"))
   groom_button = add_choice("Grooming", preload("res://assets/ui/care.svg"), groom, Color("c8eddd"))
   add_choice("Supplies", preload("res://assets/ui/medicine.svg"), host.request_page.bind("Vet Supplies"), Color("f9d8e2"))
   add_choice("Rest at Home", preload("res://assets/ui/rest.svg"), rest_at_home, Color("e1d9f6"))
   add_choice("Health history", UI.resident_icon(Art.LEAH), host.show_page.bind("Life:Health Record"), Color("ffdfb5"))
  "Lighthouse":
   description.text = "A quiet lookout for a later chapter."
   feedback.text = "Preview only. The Lighthouse is still closed."
   add_choice("Island map", preload("res://assets/ui/island.svg"), host.show_page.bind("Island"))
 Game.changed.connect(refresh)
 if Game.life.delivery.recipient != "" and IslandLife.delivery_info(Game).place == location:
  add_choice("Deliver parcel", preload("res://assets/ui/menu_bag.svg"), deliver_parcel, Color("fff0bd"))
 feedback.visible = location == "Lighthouse" and not feedback.text.is_empty()
 refresh()
 show_greeting()
 host.habitat.present_location_dog()

func add_primary(text: String, picture: Texture2D, action: Callable, color: Color = Color("c8eddd")) -> Button:
 var button = UI.location_button(text, picture, action, color)
 button.custom_minimum_size = Vector2(380, 112)
 primary_actions.add_child(button)
 return button

func add_choice(text: String, picture: Texture2D, action: Callable, color: Color = Color("f9d8e2")) -> Button:
 var button = UI.location_button(text, picture, action, color)
 button.custom_minimum_size = Vector2(380, 72)
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
 if is_instance_valid(health_button):
  UI.button_caption(health_button, "Free treatment" if PuppyHealth.unwell(Game) and Game.health.diagnosed and not Game.health.treated else "Free checkup")
  feedback.text = PuppyHealth.status(Game) + ". Treatment is free."
  feedback.visible = PuppyHealth.unwell(Game)
 if is_instance_valid(groom_button):
  groom_button.disabled = Game.coins < 12 or Game.needs.Cleanliness >= 99

func purchase(kind: String) -> void:
 feedback.text = Game.buy_item(kind)
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error
 refresh()

func talk_to_nora() -> void:
 Game.meet_nora()
 host.show_resident(Art.NORA, "Nora", "Puppy Club organizer", IslandActivities.greeting(Game, "Nora", Game.personalize("Lovely to see you and Mochi!\n\nTry Fetch at the Park or a Walk at the Beach. Your Journal follows every little chapter.")))

func little_activity() -> void:
 feedback.visible = true
 feedback.text = Game.island_moment(location)
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error

func checkup() -> void:
 host.show_resident(Art.LEAH, "Leah", "Veterinarian", Game.clinic_checkup())

func groom() -> void:
 var reply = Game.clinic_groom()
 refresh()
 if not Game.save_error.is_empty():
  reply = Game.save_error
 host.show_resident(Art.LEAH, "Leah", "Veterinarian", reply)

func talk_to_june() -> void:
 host.show_resident(Art.JUNE, "June", "Shopkeeper", IslandActivities.greeting(Game, "June", "Welcome! Treats, toys and little comforts await.\n\nTap a picture to learn more. Earn coins through Walks and Fetch."))

func talk_to_ben() -> void:
 host.show_resident(Art.BEN, "Ben", "Trainer", IslandActivities.greeting(Game, "Ben", Game.personalize("I'm Ben! Ready for Fetch?\n\nTap Throw in the green zone. Let Mochi bring the ball back. Three throws make a game!")))

func talk_to_owen() -> void:
 host.show_resident(Art.OWEN, "Owen", "Neighbor", IslandActivities.greeting(Game, "Owen", Game.personalize("Hi, I'm Owen! Lovely to meet you and Mochi.\n\nFind three treasures along the coast, then walk home. Your Journal keeps the memories.")))

func harbor_welcome() -> void:
 var reply = IslandStory.advance(Game, "welcome")
 host.show_resident(Art.OWEN, "Owen", "Harbor neighbor", reply)
 rebuild_story_actions()

func meet_ren() -> void:
 var reply = IslandStory.advance(Game, "meet")
 host.show_resident(Art.REN, "Ren", "Lighthouse keeper", reply)
 rebuild_story_actions()

func story_action(action: String) -> void:
 var reply = IslandStory.advance(Game, action)
 if action in ["kit", "repair_supplies"]:
  host.show_resident(Art.OWEN, "Owen", "Harbor neighbor", reply)
 else:
  host.show_resident(Art.REN, "Ren", "Lighthouse keeper", reply)
 rebuild_story_actions()

func rebuild_story_actions() -> void:
 host.call_deferred("location_story_refresh", location)

func clinic_main_action() -> void:
 if PuppyHealth.unwell(Game) and Game.health.diagnosed and not Game.health.treated:
  host.show_resident(Art.LEAH,"Leah","Veterinarian",PuppyHealth.treat(Game))
 else:
  checkup()

func health_guide() -> void:
 host.show_resident(Art.LEAH,"Leah","Veterinarian","If your puppy feels unwell, get a Free checkup. I treat illnesses and sore paws for free. Medicine or bandages from Supplies can also help after diagnosis. Rest at Home helps recovery.")

func deliver_parcel() -> void:
 var person: String = Game.life.delivery.recipient
 var portrait: Texture2D = {"Nora":Art.NORA, "Ben":Art.BEN, "Leah":Art.LEAH, "Ren":Art.REN}.get(person, Art.OWEN)
 var reply = IslandLife.deliver_parcel(Game, location)
 host.show_resident(portrait, person, "Parcel recipient", reply if Game.save_error.is_empty() else Game.save_error)
 rebuild_story_actions()

func rest_at_home() -> void:
 host.request_page("Home")
 if not Game.resting:
  Game.action("Rest")

func talk_to_kai() -> void:
 host.show_resident(Art.KAI, "Kai", "Beach lifeguard", IslandActivities.greeting(Game, "Kai", Game.personalize("Hey, I'm Kai! Welcome to the beach.\n\nTry a Walk to find little shore treasures. Give Mochi a rest when those paws get tired. I'll keep an eye on the coast!")))

func show_greeting() -> void:
 for child in host.world_host.get_children():
  if child.name == "LocationGreeting":
   host.world_host.remove_child(child)
   child.queue_free()
 var people = {"Puppy Club":[Art.NORA,"Nora","Welcome! A playdate or an island event?"], "Park":[Art.BEN,"Ben","Ready to play? Try Fetch or practice a trick."], "Beach":[Art.KAI,"Kai","Welcome to the beach! What shall we try?"], "Shop":[Art.JUNE,"June","Welcome! Choose a shelf to browse."], "Vet Clinic":[Art.LEAH,"Leah","I'm here to help. Checkups and treatment are free."], "Harbor":[Art.OWEN,"Owen","Welcome aboard! Parcels and island supplies are here."], "Keeper’s Cottage":[Art.REN,"Ren","Welcome to my cottage. Let's tend the island light."]}
 if location not in people:
  return
 var person = people[location]
 var greeting = load("res://scripts/location_greeting.gd").new()
 greeting.texture = person[0]
 greeting.character_name = person[1]
 greeting.text = IslandStory.next_step(Game).text if location in ["Harbor", "Keeper’s Cottage"] else person[2]
 if location == "Puppy Club":
  Game.meet_nora()
 host.world_host.add_child(greeting)

func beach_picture(index: int) -> Texture2D:
 var sheet = preload("res://assets/ui/beach_activities.png")
 var atlas = AtlasTexture.new()
 atlas.atlas = sheet
 var cell = sheet.get_width() / 3.0
 atlas.region = Rect2(index * cell,0,cell,sheet.get_height())
 return atlas
