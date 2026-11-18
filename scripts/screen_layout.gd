extends Node

var pending = false

func _ready() -> void:
	get_tree().node_added.connect(func(node: Node):
		if node is Control: schedule()
	)
	get_tree().root.size_changed.connect(schedule)

func schedule() -> void:
	if pending: return
	pending = true
	call_deferred("arrange")

func arrange() -> void:
	pending = false
	for scene in get_tree().get_nodes_in_group("responsive_scenes"):
		if scene is Control:
			if scene.has_method("arrange_screen"): scene.arrange_screen()
			fit_content(scene,scene.size.x-UI.safe_insets().left-UI.safe_insets().right)

func fit_content(node: Node, available: float) -> void:
	if node.has_meta("screen_layout_manual"): return
	if node is Control:
		var narrow = node.get_viewport_rect().size.x < 1000
		if not node.has_meta("wide_minimum"):
			node.set_meta("wide_minimum",node.custom_minimum_size)
		var original: Vector2 = node.get_meta("wide_minimum")
		if narrow:
			node.custom_minimum_size.x = minf(original.x,maxf(80,available))
		elif node.has_meta("layout_adjusted"):
			node.custom_minimum_size.x = original.x
		if narrow: node.set_meta("layout_adjusted",true)
		var inset = 0.0
		if node is PanelContainer:
			var box = node.get_theme_stylebox("panel")
			inset = box.get_content_margin(SIDE_LEFT)+box.get_content_margin(SIDE_RIGHT)
		elif node is MarginContainer:
			inset = node.get_theme_constant("margin_left")+node.get_theme_constant("margin_right")
		available = maxf(80,available-inset)
		if node is GridContainer:
			if not node.has_meta("wide_columns"): node.set_meta("wide_columns",node.columns)
			node.columns = node.get_meta("wide_columns")
			if narrow:
				node.columns=mini(node.columns,int(node.get_meta("portrait_columns",node.columns)))
				while node.columns>1 and node.get_combined_minimum_size().x>available: node.columns-=1
		if node.get_class()=="BoxContainer" and not node.has_meta("screen_layout_horizontal"):
			if not node.has_meta("wide_vertical"): node.set_meta("wide_vertical",node.vertical)
			node.vertical = node.get_meta("wide_vertical")
			if narrow and not node.vertical and node.get_combined_minimum_size().x>available:
				node.vertical = true
	for child in node.get_children(): fit_content(child,available)
