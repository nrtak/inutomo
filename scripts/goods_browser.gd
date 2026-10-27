extends MarginContainer
var host: Control
var shopping = false
var location = "Bag"
var category = "All"
var wallet: Label
var feedback: Label
var needs_summary: Label
var detail_overlay: Control
var detail_kind = ""
var detail_count: Label
var detail_action: Button
var detail_notice: Label
var list: GridContainer
var rows: Dictionary = {}
var category_buttons: Dictionary = {}

func _ready() -> void:
 location = "Shop" if shopping else "Bag"
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
 var visit = UI.button("Talk to June" if shopping else "Visit Shop", talk_to_june if shopping else host.show_page.bind("Shop"), Color("ffe0b0"))
 visit.custom_minimum_size.x = 220
 header.add_child(visit)
 var tabs = HBoxContainer.new()
 tabs.add_theme_constant_override("separation", 8)
 content.add_child(tabs)
 var categories = Goods.CATEGORIES if shopping else ["All"] + Goods.CATEGORIES
 category = "Food" if shopping else "All"
 for title in categories:
  var tab = UI.button(title, select_category.bind(title), Color("b7def4"))
  tab.add_theme_font_size_override("font_size", 23)
  tab.icon = Goods.icon({"All": "Treat", "Food": "Treat", "Toys": "Toy", "Care": "Brush", "Comfort": "Bed"}[title])
  tab.expand_icon = true
  tab.add_theme_constant_override("icon_max_width", 36)
  tabs.add_child(tab)
  category_buttons[title] = tab
 feedback = UI.label("", 21)
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

func select_category(value: String) -> void:
 category = value
 feedback.visible = false
 feedback.text = ""
 rebuild()

func rebuild() -> void:
 for title in category_buttons:
  category_buttons[title].add_theme_stylebox_override("normal", UI.style(Color("ffe0a0") if title == category else Color("b7def4"), 20))
 rows.clear()
 for child in list.get_children():
  list.remove_child(child)
  child.queue_free()
 for kind in Goods.ITEMS:
  var item: Dictionary = Goods.ITEMS[kind]
  if category != "All" and item.category != category:
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
  actions.add_child(owned)
  var action = UI.button("", perform.bind(kind), Color("bdeab0"))
  action.custom_minimum_size = Vector2(190, 84)
  action.add_theme_font_size_override("font_size", 23)
  if shopping:
   action.icon = preload("res://assets/ui/coin.svg")
   action.expand_icon = true
   action.add_theme_constant_override("icon_max_width", 28)
  actions.add_child(action)
  rows[kind] = {"count": owned, "button": action}
 if rows.is_empty():
  list.add_child(UI.label("Nothing here yet. June's Shop has treats, toys, care goods and a cozy bed.", 25))
 refresh()

func refresh() -> void:
 wallet.text = ("June's Shop" if shopping else Game.puppy_name + "'s Bag") + " / %d coins" % Game.coins
 if is_instance_valid(needs_summary):
  needs_summary.text = "Hunger %d / Happiness %d / Cleanliness %d" % [Game.needs.Hunger, Game.needs.Happiness, Game.needs.Cleanliness]
 for kind in rows:
  update_item_controls(kind, rows[kind].button, rows[kind].count)
 if is_instance_valid(detail_overlay):
  update_item_controls(detail_kind, detail_action, detail_count)

func update_item_controls(kind: String, button: Button, count_label: Label) -> void:
 var item: Dictionary = Goods.ITEMS[kind]
 var count = int(Game.items.get(kind, 0))
 count_label.text = "%d / %d in Bag" % [count, item.limit] if item.limit > 1 else "Reusable"
 if shopping:
  button.text = ("Full" if item.limit > 1 else "Owned") if count >= item.limit else "Buy %d" % item.price
  button.disabled = count >= item.limit or Game.coins < item.price
  if Game.coins < item.price and count < item.limit:
   count_label.text = "Need %d coins" % (item.price - Game.coins)
 else:
  button.text = "Equipped" if item.limit == 1 else "Use"
  button.disabled = item.limit == 1 or count == 0 or Game.cooldowns.get("Goods", 0) > 0

func perform(kind: String) -> void:
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

func talk_to_june() -> void:
 host.show_resident(Art.JUNE, "June", "Shopkeeper", "Welcome! Pick a category to browse. Treats and shampoo are used up; the ball, brush and bed stay with you.\n\nYour Bag shows what you own and what each good does. Ordinary care at Home is always free.")

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
 picture.texture = Goods.picture(kind)
 picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.custom_minimum_size = Vector2(260, 220)
 row.add_child(picture)
 var description = UI.column(16)
 description.custom_minimum_size.x = 450
 row.add_child(description)
 description.add_child(UI.label(Goods.ITEMS[kind].description, 25))
 detail_count = UI.label("", 24)
 description.add_child(detail_count)
 detail_notice = UI.label("", 21, UI.TEAL)
 detail_notice.visible = false
 description.add_child(detail_notice)
 var actions = HBoxContainer.new()
 actions.add_theme_constant_override("separation", 16)
 content.add_child(actions)
 detail_action = UI.button("", perform.bind(kind), Color("bdeab0"))
 actions.add_child(detail_action)
 actions.add_child(UI.button("Close", close_details, Color("fff0cf")))
 refresh()

func close_details() -> void:
 if is_instance_valid(detail_overlay):
  detail_overlay.queue_free()
 detail_overlay = null

func _exit_tree() -> void:
 close_details()
