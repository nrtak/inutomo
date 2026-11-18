class_name LocationHub
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
var unavailable: Label
var choices: GridContainer
var beach_scroll: ScrollContainer
var beach_content: VBoxContainer
var talk_button: Button
var plans_mode = false
var secondary_store: VBoxContainer

static func plans_title(place: String) -> String:
 return {"Vet Clinic":"Care & health records","Shop":"Care & shop plans","Park":"Park plans","Beach":"Walks & beach plans","Harbor":"Harbor stories","Keeper’s Cottage":"Cottage plans","Lighthouse":"Lighthouse plans","Lighthouse Room":"Lookout plans","Puppy Club":"Club events & stories"}.get(place,place+" plans")

func _ready() -> void:
 set_meta("screen_layout_manual",true)
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
 beach_scroll = scroll
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.custom_minimum_size.x = 400
 if plans_mode:
  spacer.visible=false
  var panel=UI.card()
  panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  row.add_child(panel)
  panel.add_child(scroll)
 else: row.add_child(scroll)
 var content = UI.column(10)
 beach_content = content
 content.custom_minimum_size.x = 380
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 if plans_mode:
  scroll.custom_minimum_size.x=0
  content.custom_minimum_size.x=0
  content.add_child(UI.label(plans_title(location),28,UI.TEAL))
 elif location == "Beach":
  beach_scroll = scroll
  beach_content = content
  var air = Control.new()
  air.name = "BeachBreathingRoom"
  air.custom_minimum_size.y = 80
  air.mouse_filter = Control.MOUSE_FILTER_IGNORE
  content.add_child(air)
  host.resized.connect(arrange_beach)
 else:
  var air = Control.new()
  air.name="BeachBreathingRoom"
  air.custom_minimum_size.y = 32
  air.mouse_filter = Control.MOUSE_FILTER_IGNORE
  content.add_child(air)
 wallet = UI.label("", 23)
 wallet.visible = false
 content.add_child(wallet)
 description = UI.hint_label("", 23)
 description.visible = false
 content.add_child(description)
 feedback = UI.hint_label("", 21)
 feedback.minimum_size_changed.connect(func(): arrange_beach.call_deferred())
 beach_scroll.resized.connect(func(): arrange_beach.call_deferred())
 feedback.visible = false
 if location == "Lighthouse":
  var note = UI.style(Color("fff6e4"))
  note.content_margin_left = 12
  note.content_margin_right = 12
  note.content_margin_top = 8
  note.content_margin_bottom = 8
  feedback.add_theme_stylebox_override("normal", note)
 content.add_child(feedback)
 primary_actions = UI.column(10)
 content.add_child(primary_actions)
 choices = GridContainer.new()
 choices.columns = 1
 choices.add_theme_constant_override("v_separation", 10)
 content.add_child(choices)
 unavailable = UI.label("", 21, UI.TEAL)
 content.add_child(unavailable)
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
    add_primary("Collect lantern kit", preload("res://assets/manga/ui/menu_bag.svg"), story_action.bind("kit"))
   elif story.get("lantern", false) and not story.get("repair_supplies", false):
    add_primary("Collect repair crate", preload("res://assets/manga/ui/menu_bag.svg"), story_action.bind("repair_supplies"))
   else:
    add_primary("Visit Cottage", UI.place_icon("Keeper’s Cottage"), host.request_page.bind("Keeper’s Cottage"))
   if story.get("welcome", false):
    pass
   else:
    add_choice("Visit Cottage", UI.place_icon("Keeper’s Cottage"), host.request_page.bind("Keeper’s Cottage"))
   add_choice("Story Journal", preload("res://assets/manga/ui/menu_journal.svg"), host.request_page.bind("Journal"))
   add_choice("Parcels", preload("res://assets/manga/ui/menu_bag.svg"), host.show_page.bind("Life:Deliveries"), Color("c8eddd"))
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
    add_primary("Deliver lantern kit", preload("res://assets/manga/ui/menu_bag.svg"), story_action.bind("deliver"))
   elif not story.get("lantern", false):
    add_primary("Prepare lantern", preload("res://assets/manga/ui/sunset.svg"), story_action.bind("lantern"))
   elif not story.get("beacon_checked", false):
    var step = IslandStory.restoration_step(Game)
    if step.place != location:
     add_primary(step.button, UI.place_icon(step.place), host.request_page.bind(step.place))
    else:
     add_primary(step.button, preload("res://assets/manga/ui/sunset.svg"), story_action.bind(step.action))
   else:
    add_primary("Visit lighthouse", UI.place_icon("Lighthouse"), host.enter_lighthouse)
   if story.get("met_keeper", false) and not story.get("lantern", false):
    pass
   else:
    add_choice("Visit Harbor", UI.place_icon("Harbor"), host.request_page.bind("Harbor"))
   add_choice("Story Journal", preload("res://assets/manga/ui/menu_journal.svg"), host.request_page.bind("Journal"))
   feedback.text = IslandStory.next_step(Game).text
  "Park":
   description.text = "An open plaza for little paws and bouncy balls."
   var text = "Resume Fetch" if Game.has_outing("Fetch") else "Play Fetch"
   add_primary(text, preload("res://assets/manga/ui/play.svg"), host.start_activity.bind("Fetch"), Color("c8eddd"))
   add_choice("Scent trail", preload("res://assets/manga/ui/leaf.svg"), host.start_scent_trail, Color("fff0bd"))
   add_choice("Training", preload("res://assets/manga/ui/training_treat.svg"), host.request_page.bind("Moment:Recall"), Color("f9d8e2"))
   feedback.text = "Three throws. Earn island coins."
  "Beach":
   add_primary("Find shells", beach_picture(0), host.request_page.bind("Moment:Beach"), Color("f9d8e2"))
   add_primary("Beach cleanup", beach_picture(1), host.open_beach_activity.bind("Cleanup"), Color("c8eddd"))
   add_primary("Sand fetch", beach_picture(2), host.open_beach_activity.bind("Sand Fetch"), Color("c2ecf4"))
   add_choice("Resume Walk" if Game.has_outing("Walk") else "Go for a walk", preload("res://assets/manga/ui/beach_leaf.svg"), host.start_activity.bind("Walk"),BeachStyle.PAPER)
  "Puppy Club":
   description.text = "Meet Nora and your island friends."
   wallet.visible = false
   add_primary(("Cozy playdate" if IslandWeather.current()=="Light rain" else "Puppy playdate"), preload("res://assets/manga/ui/heart.svg"), host.show_page.bind("Life:Playdate"))
   add_primary("Meet the dogs", preload("res://assets/manga/ui/club.svg"), host.show_page.bind("Life:Dog Friends"), Color("c2ecf4"))
   add_primary("Club events & stories", preload("res://assets/manga/ui/sunset.svg"), host.show_page.bind("Life:Club Plans"), Color("fff0bd"))
  "Shop":
   add_primary("Food & treats", Goods.picture("Treat"), host.browse_shop.bind("Food"), Color("ffdfb5"))
   add_primary("Toys & play", Goods.picture("Toy"), host.browse_shop.bind("Toys"), Color("c8eddd"))
   add_primary("Style & comfort", Goods.picture("CoralBandana"), host.browse_shop.bind("Accessories"), Color("f9d8e2"))
   add_choice("Care goods", Goods.picture("Brush"), host.browse_shop.bind("Care"))
  "Vet Clinic":
   description.text = "Checkups, treatment and supplies."
   health_button = add_primary("Free checkup", UI.resident_icon(Art.LEAH), clinic_main_action, Color("c2ecf4"))
   groom_button = add_choice("Grooming", preload("res://assets/manga/ui/care.svg"), groom, Color("c8eddd"))
   add_choice("Supplies", preload("res://assets/manga/ui/medicine.svg"), host.request_page.bind("Vet Supplies"), Color("f9d8e2"))
   add_choice("Rest at Home", preload("res://assets/manga/ui/rest.svg"), rest_at_home, Color("e1d9f6"))
   add_choice("Health history", UI.resident_icon(Art.LEAH), host.show_page.bind("Life:Health Record"), Color("ffdfb5"))
  "Lighthouse":
   if IslandAdventure.tower_open(Game):
    add_primary("Visit observation room", UI.place_icon("Lighthouse"), host.enter_lighthouse)
   else:
    feedback.text = "Help Ren finish the cottage restoration to open the lighthouse."
    add_primary("Visit Ren", UI.place_icon("Keeper’s Cottage"),host.request_page.bind("Keeper’s Cottage"))
   add_choice("Island map", preload("res://assets/manga/ui/island.svg"), host.show_page.bind("Island"))
  "Lighthouse Room":
   add_primary("The lighthouse story", UI.resident_icon(Art.REN), func(): host.show_resident(Art.REN,"Ren","Lighthouse keeper","Welcome to the observation room! The lens is safely behind its rail. That light has welcomed island families home for years. Enjoy the view with your little friend."))
   add_choice("Take a keepsake photo", preload("res://assets/manga/ui/beach_camera.svg"),host.open_photo_mode, Color("f9d8e2"))
   add_choice("Back to the lookout",UI.place_icon("Lighthouse"),host.request_page.bind("Lighthouse"))
 if Game.life.welcome_day.started and not Game.life.welcome_day.celebrated:
  if location == "Shop" and not Game.life.welcome_day.treats:
   add_choice("Pack picnic treats", Goods.picture("Treat"), prepare_picnic, Color("fff0bd"))
  elif location in ["Park", "Beach"]:
   add_choice("Welcome Day plans", preload("res://assets/manga/ui/heart.svg"), host.request_page.bind("Life:Welcome Day"), Color("fff0bd"))
 Game.changed.connect(refresh)
 if location == "Keeper’s Cottage" and (not Game.life.story.get("path_repaired",false) or "Sea glass" in Game.life.keepsakes):
  add_choice("Explore with Ren", preload("res://assets/manga/ui/sea_glass.svg"), host.request_page.bind("Moment:Cottage"), Color("c8eddd"))
 if location == "Lighthouse":
  add_choice("Gather with friends", preload("res://assets/manga/ui/heart.svg"), host.request_page.bind("Moment:Lighthouse"), Color("f9d8e2"))
 if location!="Puppy Club" and Game.life.delivery.recipient != "" and IslandLife.delivery_info(Game).place == location:
  add_choice("Deliver parcel", preload("res://assets/manga/ui/menu_bag.svg"), deliver_parcel, Color("fff0bd"))
 if location!="Puppy Club" and Game.life.connections.mystery<5 and IslandConnections.mystery_step(Game).place==location:
  var mystery = IslandConnections.mystery_step(Game)
  var button = add_choice(mystery.button,load("res://assets/manga/ui/"+mystery.icon+".svg"),mystery_action,Color("fff0bd"))
  button.set_meta("mystery",true)
 if IslandSurprises.ready_at(Game,location):
  var request=IslandSurprises.REQUESTS[Game.life.surprises.kind]
  add_choice("Return "+request.object,load("res://assets/manga/ui/"+request.icon+".svg"),complete_neighbor_request,Color("c8eddd"))
 organize_actions()
 feedback.visible = location == "Lighthouse" and not feedback.text.is_empty()
 refresh()
 if plans_mode:
  host.resized.connect(arrange_beach)
  arrange_beach.call_deferred()
  return
 show_greeting()
 host.habitat.present_location_dog()
 if not Game.resting:
  host.habitat.puppy.napping=false
  host.habitat.puppy.notice_point(host.habitat.puppy.position-Vector2(100,0))
 if location != "Beach": host.resized.connect(arrange_beach)
 arrange_beach.call_deferred()

func organize_actions() -> void:
 var all=primary_actions.get_children()+choices.get_children()
 var main: Array[Button]=[]
 var extra: Array[Button]=[]
 var compact: Array[Button]=[]
 var first=primary_actions.get_child(0) if primary_actions.get_child_count()>0 else null
 for button in all:
  var core=false
  match location:
   "Puppy Club": core=button.get_parent()==primary_actions
   "Beach":
    core=button.get_parent()==primary_actions
    if button.text in ["Go for a walk","Resume Walk"]: compact.append(button); continue
   "Park": core=button==first or button.text in ["Training","Scent trail"]
   "Shop": core=button.get_parent()==primary_actions
   "Vet Clinic": core=button==health_button or button==groom_button or button.text=="Supplies"
   "Harbor": core=button==first or button.text=="Parcels"
   "Keeper’s Cottage": core=button==first or button.text=="Explore with Ren"
   "Lighthouse":
    if button.text=="Island map": button.queue_free(); continue
    core=true
   "Lighthouse Room":
    if button.text in ["The lighthouse story","Back to the lookout"]: button.queue_free(); continue
    core=true
  if core: main.append(button)
  else: extra.append(button)
 if location=="Beach" and not extra.is_empty():
  extra=compact+extra
  compact.clear()
 secondary_store=UI.column()
 secondary_store.visible=false
 add_child(secondary_store)
 for button in all:
  if not button.is_queued_for_deletion(): button.reparent(secondary_store)
 if plans_mode:
  for button in extra: button.reparent(primary_actions)
  if extra.is_empty():
   description.text="The main activities are on the arrival screen."
   description.visible=true
 else:
  for button in main: button.reparent(primary_actions)
  for button in compact: button.reparent(choices)
  if not extra.is_empty():
   var action=host.request_page.bind("Plans:"+location)
   if main.size()<3: add_primary(plans_title(location),preload("res://assets/manga/ui/menu_journal.svg"),action,Color("fff0bd"))
   else: add_choice(plans_title(location),preload("res://assets/manga/ui/menu_journal.svg"),action,Color("fff0bd"))

func add_primary(text: String, picture: Texture2D, action: Callable, color: Color = Color("c8eddd")) -> Button:
 var button = UI.location_button(text, picture, action, color)
 button.custom_minimum_size = Vector2(380, 112)
 primary_actions.add_child(button)
 BeachStyle.style_button(button,color)
 return button

func add_choice(text: String, picture: Texture2D, action: Callable, color: Color = Color("f9d8e2")) -> Button:
 var button = UI.location_button(text, picture, action, color)
 button.custom_minimum_size = Vector2(380, 72)
 button.add_theme_font_size_override("font_size", 22)
 choices.add_child(button)
 BeachStyle.style_button(button,color)
 return button

func arrange_beach() -> void:
 if not is_instance_valid(beach_scroll) or not is_instance_valid(primary_actions):
  return
 var width = BeachStyle.column_width(host.size,UI.safe_insets())
 if plans_mode:
  beach_scroll.custom_minimum_size.x=0
  beach_content.custom_minimum_size.x=0
  for button in primary_actions.get_children():
   button.custom_minimum_size=Vector2(0,100)
   button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  return
 beach_scroll.custom_minimum_size.x = width
 beach_content.custom_minimum_size.x = width
 var air=beach_content.get_node_or_null("BeachBreathingRoom")
 if air!=null:
  air.custom_minimum_size.y = 24 if host.size.y>host.size.x else (clampf(host.size.y-560,32,160) if location=="Lighthouse" else 32)
  if host.size.x>=host.size.y and location=="Vet Clinic" and feedback.visible: air.custom_minimum_size.y=8
 var primary_height=132.0 if host.size.y>host.size.x else (100.0 if host.size.y<690 else 112.0)
 if host.size.x>=host.size.y and beach_scroll.size.y>0 and primary_actions.get_child_count()>0:
  var fixed=0.0
  var visible_children=0
  for child in beach_content.get_children():
   if not child.visible: continue
   visible_children+=1
   if child in [primary_actions,choices]: continue
   fixed+=68.0 if child==talk_button else child.get_combined_minimum_size().y
  fixed+=maxi(0,visible_children-1)*10+maxi(0,primary_actions.get_child_count()-1)*10
  fixed+=choices.get_child_count()*72+maxi(0,choices.get_child_count()-1)*10
  primary_height=clampf((beach_scroll.size.y-fixed)/primary_actions.get_child_count(),72,primary_height)
 for button in primary_actions.get_children()+choices.get_children():
  button.custom_minimum_size.x = width
  var portrait=host.size.y>host.size.x
  button.custom_minimum_size.y = 132 if portrait else (primary_height if button.get_parent()==primary_actions else 72)
  var picture=button.get_meta("picture")
  var caption=button.get_meta("caption")
  picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT if portrait else Control.PRESET_LEFT_WIDE)
  picture.offset_left=14
  picture.offset_right=-14 if portrait else 100
  picture.offset_top=8 if portrait else 12
  picture.offset_bottom=-60 if portrait else -12
  caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if portrait else Control.PRESET_FULL_RECT)
  caption.offset_left=4 if portrait else 112
  caption.offset_right=-4 if portrait else -32
  caption.offset_top=-58 if portrait else 0
  caption.offset_bottom=-4 if portrait else 0
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
  caption.add_theme_font_size_override("font_size",20 if portrait else (23 if width<350 else 25))
  caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  button.get_child(2).visible=not portrait
 if is_instance_valid(talk_button):
  var portrait=host.size.y>host.size.x
  talk_button.custom_minimum_size=Vector2(width,118 if portrait else 68)
  var picture=talk_button.get_meta("picture")
  var caption=talk_button.get_meta("caption")
  picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT if portrait else Control.PRESET_LEFT_WIDE)
  picture.offset_left=14
  picture.offset_right=-14 if portrait else 76
  picture.offset_top=8
  picture.offset_bottom=-44 if portrait else -8
  caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if portrait else Control.PRESET_FULL_RECT)
  caption.offset_left=4 if portrait else 90
  caption.offset_right=-4 if portrait else -12
  caption.offset_top=-40 if portrait else 0
  caption.offset_bottom=-4 if portrait else 0
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
  caption.add_theme_font_size_override("font_size",20 if portrait else 23)

func refresh() -> void:
 var blocked = Game.activity_block_reason()
 unavailable.text = blocked + "." if not blocked.is_empty() else ""
 unavailable.visible = location in ["Park", "Beach", "Puppy Club"] and not blocked.is_empty()
 for button in primary_actions.get_children() + choices.get_children():
  if button.has_meta("mystery"):
   button.disabled = not IslandConnections.available(Game)
  if button.text in ["Play Fetch", "Resume Fetch", "Go for a walk", "Resume Walk", "Find shells", "Beach cleanup", "Sand fetch", "Puppy playdate", "Cozy playdate", "Scent trail", "Training"]:
   button.disabled = not blocked.is_empty()
   button.tooltip_text = blocked if not blocked.is_empty() else button.text
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

func complete_neighbor_request() -> void:
 if not IslandSurprises.ready_at(Game,location): return
 var person: String=IslandSurprises.REQUESTS[Game.life.surprises.kind].person
 var result=IslandSurprises.finish_request(Game,location)
 host.show_resident(IslandFestivals.PORTRAITS[person],person,"Island neighbor",result.text)
 rebuild_story_actions()

func talk_to_kai() -> void:
 host.show_resident(Art.KAI, "Kai", "Beach lifeguard", IslandActivities.greeting(Game, "Kai", Game.personalize("Hey, I'm Kai! Welcome to the beach.\n\nTry a Walk to find little shore treasures. Give Mochi a rest when those paws get tired. I'll keep an eye on the coast!")))

func show_greeting() -> void:
 for child in host.world_host.get_children():
  if child.name == "LocationGreeting":
   host.world_host.remove_child(child)
   child.queue_free()
 var people = {"Puppy Club":[Art.NORA,"Nora","Welcome! A playdate or an island event?"], "Park":[Art.BEN,"Ben","Ready to play? Try Fetch or practice a trick."], "Beach":[Art.KAI,"Kai","Welcome to the beach! What shall we try?"], "Shop":[Art.JUNE,"June","Welcome! Choose a shelf to browse."], "Vet Clinic":[Art.LEAH,"Leah","Free checkups and gentle care."], "Harbor":[Art.OWEN,"Owen","Welcome! Let’s help the island."], "Keeper’s Cottage":[Art.REN,"Ren","Good to see you. The light needs us."], "Lighthouse":[Art.REN,"Ren","Welcome to the lookout! Enjoy the sea breeze."], "Lighthouse Room":[Art.REN,"Ren","Welcome inside! Enjoy the island view."]}
 if location not in people:
  return
 var person = people[location]
 var greeting = load("res://scripts/location_greeting.gd").new()
 greeting.texture = person[0]
 greeting.scene_style = "Beach" if location == "Beach" else "Anime"
 greeting.character_name = person[1]
 var visits = maxi(1 if Game.life.friends.has(person[1]) else 0,int(host.arrival_visits.get(location, 0)))
 greeting.duration = 6.0 if visits == 0 else 3.5
 var repeats = ["Lovely to see you both!", "Welcome back! What shall we try?", "Ready for another little adventure?"]
 greeting.text = IslandWeather.greeting(person[1],person[2] if visits == 0 else repeats[visits % repeats.size()])
 greeting.talk = func(): host.show_resident(person[0],person[1],"Island friend",IslandAdventure.chapter(Game,person[1]))
 if IslandSurprises.ready_at(Game,location): greeting.talk=complete_neighbor_request
 if location == "Beach" and visits == 0 and IslandWeather.current()=="Sunny":
  greeting.text = "A peaceful evening by the sea." if Daylight.current_period in ["Evening","Night","Late night"] else "A perfect day for the beach!"
 greeting.text = IslandConnections.greeting(Game,person[1],greeting.text)
 if Game.life.welcome_day.started and not Game.life.welcome_day.celebrated:
  greeting.text = WelcomeDay.greeting(Game,person[1],greeting.text)
 IslandConnections.arrive(Game,person[1])
 host.arrival_visits[location] = visits + 1
 if not Game.life.friends.has(person[1]):
  IslandLife.talk(Game,person[1])
 if location == "Puppy Club":
  Game.meet_nora()
 host.world_host.add_child(greeting)
 talk_button=UI.icon_button("Talk to "+person[1],UI.resident_icon(person[0]),greeting.talk,Color("e7dff2"))
 talk_button.name="ResidentConversation"
 talk_button.tooltip_text="Chat with "+person[1]+" about the island"
 beach_content.add_child(talk_button)

func beach_picture(index: int) -> Texture2D:
 return BeachStyle.activity_picture(index)

func prepare_picnic() -> void:
 var reply = WelcomeDay.pack_treats(Game)
 host.show_resident(Art.JUNE, "June", "Shopkeeper", reply if Game.save_error.is_empty() else Game.save_error)
 host.call_deferred("location_story_refresh", location)

func mystery_action() -> void:
 var step: int = Game.life.connections.mystery
 if step in [1,2,3]:
  host.request_page("Mystery")
  return
 var spec = IslandConnections.mystery_step(Game)
 var result = IslandConnections.advance_mystery(Game,step,location)
 host.show_resident(Art.NORA,"Nora","Puppy Club organizer",result.text if Game.save_error.is_empty() else Game.save_error)
 if result.ok: rebuild_story_actions()
