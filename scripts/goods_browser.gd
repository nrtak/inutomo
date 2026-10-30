extends MarginContainer
var host: Control
var featured_day = ""
var shopping = false
var vet_supplies = false
var location = "Bag"
var category = "All"
var wallet: Label
var feedback: CommandHint
var needs_summary: Label
var detail_overlay: Control
var detail_kind = ""
var detail_count: Label
var detail_action: Button
var detail_notice: CommandHint
var list: GridContainer
var rows: Dictionary = {}
var category_buttons: Dictionary = {}
const CATEGORY_COLORS = {"Featured": Color("fff0bd"), "All": Color("f9d8e2"), "Food": Color("ffdfb5"), "Toys": Color("c8eddd"), "Care": Color("c2ecf4"), "Comfort": Color("e1d9f6"), "Accessories": Color("f9d8e2")}

func _ready() -> void:
 location = "Vet Clinic" if vet_supplies else ("Shop" if shopping else "Bag")
 add_theme_constant_override("margin_left", 0)
 var panel = UI.card()
 panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_child(panel)
 var content = UI.column(10)
 panel.add_child(content)
 var header = HBoxContainer.new()
 header.add_theme_constant_override("separation", 12)
 content.add_child(header)
 wallet = UI.label("", 26, UI.TEAL)
 wallet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(wallet)
 var purse = HBoxContainer.new()
 header.add_child(purse)
 var coin = TextureRect.new()
 coin.texture = preload("res://assets/ui/coin.svg")
 coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 coin.custom_minimum_size = Vector2(34, 34)
 purse.add_child(coin)
 var balance = UI.label("", 25)
 balance.autowrap_mode = TextServer.AUTOWRAP_OFF
 purse.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 balance.name = "CoinBalance"
 balance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 purse.add_child(balance)
 wallet.set_meta("balance", balance)
 var visit = UI.icon_button("Ask Leah" if vet_supplies else ("Talk to June" if shopping else "Visit Shop"), UI.resident_icon(Art.LEAH if vet_supplies else Art.JUNE) if shopping else UI.place_icon("Shop"), talk_to_leah if vet_supplies else (talk_to_june if shopping else host.show_page.bind("Shop")), Color("ffdfb5"))
 visit.size_flags_horizontal = Control.SIZE_SHRINK_END
 visit.custom_minimum_size = Vector2(180, 84)
 header.add_child(visit)
 var tabs = HBoxContainer.new()
 tabs.add_theme_constant_override("separation", 8)
 content.add_child(tabs)
 var categories = ["Care"] if vet_supplies else (["Featured"] + Goods.CATEGORIES if shopping else ["All"] + Goods.CATEGORIES)
 category = "Care" if vet_supplies else ("Food" if shopping else "All")
 for title in categories:
  var tab = UI.icon_button(title, Goods.icon({"Featured": "CelebrationTreat", "All": "Treat", "Food": "Treat", "Toys": "Toy", "Care": "Brush", "Comfort": "Bed", "Accessories": "CoralBandana"}[title]), select_category.bind(title), CATEGORY_COLORS[title])
  tab.custom_minimum_size.y = 84
  tab.add_theme_font_size_override("font_size", 23)
  tab.expand_icon = true
  tab.add_theme_constant_override("icon_max_width", 36)
  tabs.add_child(tab)
  category_buttons[title] = tab
 feedback = UI.hint_label("", 21)
 feedback.visible = false
 content.add_child(feedback)
 if not shopping:
  needs_summary = UI.label("", 21, UI.TEAL)
  content.add_child(needs_summary)
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 content.add_child(scroll)
 list = GridContainer.new()
 list.columns = 2
 list.add_theme_constant_override("h_separation", 16)
 list.add_theme_constant_override("v_separation", 18)
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 Game.changed.connect(refresh)
 rebuild()

func _process(_delta: float) -> void:
 if shopping and not vet_supplies and featured_day != IslandLife.today():
  featured_day = IslandLife.today()
  if category == "Featured":
   rebuild()

func select_category(value: String) -> void:
 category = value
 feedback.visible = false
 feedback.text = ""
 rebuild()

func rebuild() -> void:
 for title in category_buttons:
  var box = UI.style(CATEGORY_COLORS[title], 20)
  box.set_border_width_all(4 if title == category else 2)
  box.border_color = UI.TEAL if title == category else Color("b88b59")
  category_buttons[title].add_theme_stylebox_override("normal", box)
 rows.clear()
 for child in list.get_children():
  list.remove_child(child)
  child.queue_free()
 var display_order: Array = Goods.ITEMS.keys()
 if category == "Featured":
  display_order = Goods.featured()
 elif category == "Food":
  display_order = ["PuppyMeal", "AdultMeal", "PicnicPack", "Treat", "TrainingTreat", "CelebrationTreat"]
 for kind in display_order:
  var item: Dictionary = Goods.ITEMS[kind]
  if shopping and item.get("vet_only", false) != vet_supplies:
   continue
  if category not in ["All", "Featured"] and item.category != category:
   continue
  if not shopping and Game.items.get(kind, 0) == 0:
   continue
  var card = UI.column(8)
  card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  list.add_child(card)
  var picture = UI.picture_button(item.name, Goods.picture(kind), show_details.bind(kind))
  picture.custom_minimum_size = Vector2(280, 200)
  card.add_child(picture)
  var actions = HBoxContainer.new()
  actions.add_theme_constant_override("separation", 12)
  card.add_child(actions)
  var owned = UI.label("", 23)
  owned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  owned.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  var information = UI.column(4)
  information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  actions.add_child(information)
  information.add_child(owned)
  if shopping:
   information.add_child(UI.label("%d coins" % item.price, 24, UI.TEAL))
  var action = UI.icon_button("", UI.place_icon("Shop") if shopping else Goods.icon(kind), perform.bind(kind), Color("c8eddd"))
  action.custom_minimum_size = Vector2(190, 84)
  action.add_theme_font_size_override("font_size", 23)
  actions.add_child(action)
  rows[kind] = {"count": owned, "button": action}
 if rows.is_empty():
  list.add_child(UI.label("Nothing here yet. June's Shop has treats, toys, care goods and a cozy bed.", 25))
 refresh()

func refresh() -> void:
 wallet.text = "Leah’s Supplies" if vet_supplies else ("June's Shop" if shopping else Game.puppy_name + "'s Bag")
 if category == "Featured":
  wallet.text = "June’s daily picks"
 wallet.get_meta("balance").text = "%d coins" % Game.coins
 if is_instance_valid(needs_summary):
  needs_summary.text = "Hunger: %d    Happiness: %d    Energy: %d    Cleanliness: %d" % [Game.needs.Hunger, Game.needs.Happiness, Game.needs.Energy, Game.needs.Cleanliness]
 for kind in rows:
  update_item_controls(kind, rows[kind].button, rows[kind].count)
 if is_instance_valid(detail_overlay):
  update_item_controls(detail_kind, detail_action, detail_count)

func update_item_controls(kind: String, button: Button, count_label: Label) -> void:
 var item: Dictionary = Goods.ITEMS[kind]
 var count = int(Game.items.get(kind, 0))
 count_label.text = "%d of %d in Bag" % [count, item.limit] if item.limit > 1 else ("Owned" if count > 0 else "Reusable")
 if shopping:
  UI.button_caption(button, ("Bag full" if item.limit > 1 else "Owned") if count >= item.limit else "Buy")
  button.disabled = count >= item.limit or Game.coins < item.price
  if Game.coins < item.price and count < item.limit:
   count_label.text = "Need %d coins" % (item.price - Game.coins)
 else:
  var placeable = item.category in ["Toys", "Comfort", "Accessories"]
  UI.button_caption(button, ("Wear" if item.category == "Accessories" else "Place") if placeable else ("Equipped" if item.limit == 1 else "Use"))
  button.disabled = count == 0 or (not placeable and (item.limit == 1 or Game.cooldowns.get("Goods", 0) > 0))
 UI.button_caption(button, button.text)

func perform(kind: String) -> void:
 if not shopping and Goods.ITEMS[kind].category in ["Toys", "Comfort", "Accessories"]:
  host.call_deferred("show_page", "Life:Wardrobe" if Goods.ITEMS[kind].category == "Accessories" else "Life:Home")
  return
 var before = int(Game.items.get(kind, 0))
 feedback.visible = true
 feedback.text = Game.buy_item(kind) if shopping else Game.use_item(kind)
 if not Game.save_error.is_empty():
  feedback.text = Game.save_error
 if is_instance_valid(detail_overlay):
  detail_notice.text = feedback.text
  detail_notice.visible = true
 if not shopping and Game.items.get(kind, 0) == 0:
  rebuild()
 refresh()
 if shopping and Game.items.get(kind, 0) > before:
  purchase_feedback(kind)
 elif not shopping and (kind in ["Treat", "TrainingTreat", "Medicine", "Bandage"] or Goods.ITEMS[kind].has("need")) and Game.items.get(kind, 0) < before:
  host.call_deferred("show_page", "Home")

func purchase_feedback(kind: String) -> void:
 var item = TextureRect.new()
 item.texture = Goods.picture(kind)
 item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 item.mouse_filter = Control.MOUSE_FILTER_IGNORE
 item.size = Vector2(110, 110)
 host.add_child(item)
 item.global_position = rows[kind].button.global_position - Vector2(0, 90)
 var bag = TextureRect.new()
 bag.texture = preload("res://assets/ui/menu_bag.svg")
 bag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bag.size = Vector2(70, 70)
 bag.position = Vector2(host.size.x - UI.safe_insets().right - 80, 145)
 host.add_child(bag)
 var animation = host.create_tween()
 animation.tween_property(item, "global_position", bag.global_position, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 animation.parallel().tween_property(item, "size", Vector2(45, 45), 0.55)
 animation.tween_property(item, "modulate:a", 0.0, 0.15)
 animation.parallel().tween_property(bag, "modulate:a", 0.0, 0.3)
 animation.tween_callback(item.queue_free)
 animation.tween_callback(bag.queue_free)

func talk_to_june() -> void:
 host.show_resident(Art.JUNE, "June", "Shopkeeper", IslandActivities.greeting(Game,"June","Welcome! Tap a picture to learn about an item.\n\nTreats and shampoo are used up. Toys, brushes and beds stay with you."))

func show_details(kind: String) -> void:
 if is_instance_valid(detail_overlay):
  return
 detail_kind = kind
 detail_overlay = Control.new()
 detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 host.add_child(detail_overlay)
 var shade = ColorRect.new()
 shade.color = Color(0.1, 0.18, 0.22, 0.5)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 detail_overlay.add_child(shade)
 var center = CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 detail_overlay.add_child(center)
 var panel = UI.card()
 panel.custom_minimum_size.x = 800
 center.add_child(panel)
 var content = UI.column(16)
 content.custom_minimum_size.x = 760
 panel.add_child(content)
 content.add_child(UI.label(Goods.ITEMS[kind].name, 32, UI.TEAL))
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 24)
 content.add_child(row)
 var picture = TextureRect.new()
 picture.texture = Art.PUPPIES[Game.breed] if Goods.ITEMS[kind].category == "Accessories" else Goods.picture(kind)
 if Goods.ITEMS[kind].category == "Accessories":
  var preview_material = ShaderMaterial.new()
  preview_material.shader = preload("res://scripts/dog_style.gdshader")
  preview_material.set_shader_parameter("bandana", Goods.ITEMS[kind].color)
  preview_material.set_shader_parameter("recolor", true)
  picture.material = preview_material
 picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.custom_minimum_size = Vector2(260, 220)
 row.add_child(picture)
 var description = UI.column(16)
 description.custom_minimum_size.x = 450
 row.add_child(description)
 if Goods.ITEMS[kind].category == "Accessories":
  description.add_child(UI.hint_label("Preview on " + Game.puppy_name + ". Your outfit stays unchanged until you choose Wear.", 23, UI.TEAL))
 description.add_child(UI.hint_label(Goods.ITEMS[kind].description, 25))
 if shopping:
  description.add_child(UI.label("Price: %d coins" % Goods.ITEMS[kind].price, 25, UI.TEAL))
 detail_count = UI.label("", 24)
 description.add_child(detail_count)
 detail_notice = UI.hint_label("", 21, UI.TEAL)
 detail_notice.visible = false
 description.add_child(detail_notice)
 var actions = HBoxContainer.new()
 actions.add_theme_constant_override("separation", 16)
 content.add_child(actions)
 detail_action = UI.icon_button("", UI.place_icon("Shop") if shopping else Goods.icon(kind), perform.bind(kind), Color("c8eddd"))
 actions.add_child(detail_action)
 if Goods.ITEMS[kind].category == "Accessories":
  var wear = UI.button("Wear", wear_preview.bind(kind), Color("f9d8e2"))
  wear.set_meta("wear_preview", true)
  actions.add_child(wear)
 actions.add_child(UI.button("Close", close_details, Color("fff0cf")))
 refresh()

func wear_preview(kind: String) -> void:
 if Game.items.get(kind, 0) == 0:
  detail_notice.text = "Buy this accessory first. Previewing is free."
  detail_notice.visible = true
  return
 Game.life.accessory = kind
 Game.save_game()
 detail_notice.text = "Now wearing " + Goods.ITEMS[kind].name.to_lower() + "." if Game.save_error.is_empty() else Game.save_error
 detail_notice.visible = true
 Game.changed.emit()

func close_details() -> void:
 if is_instance_valid(detail_overlay):
  detail_overlay.queue_free()
 detail_overlay = null

func _exit_tree() -> void:
 close_details()

func talk_to_leah() -> void:
 host.show_resident(Art.LEAH, "Leah", "Veterinarian", IslandActivities.greeting(Game,"Leah","Get a free checkup before using medicine or bandages. One treatment starts recovery; extra doses do not help. Treatment at my clinic is always free."))
