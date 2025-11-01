extends Control
class_name PlayerUI

signal upgrade_selected(upgrade_id: String)
signal fleet_ship_selected(ship_index: int)
signal item_used(slot_index: int)

# Player stats
var player_name: String = "Commander"
var player_level: int = 1
var player_credits: int = 1000

# Upgrades data structure:
# {
#   "id": "upgrade_name",
#   "name": "Display Name",
#   "description": "What it does",
#   "level": 0,
#   "max_level": 5,
#   "cost": 100,
#   "icon": Texture2D
# }
var upgrades: Array[Dictionary] = []

# Fleet data structure:
# {
#   "name": "Ship Name",
#   "type": "Fighter/Cruiser/etc",
#   "icon": Texture2D,
#   "stats": {"health": 100, "damage": 25, "speed": 300}
# }
var fleet: Array[Dictionary] = []

# Inventory (same as before)
var inventory_data: Array[Dictionary] = []
var hotbar_data: Array[Dictionary] = []
@export var hotbar_slots: int = 10

# UI Nodes
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var main_vbox: VBoxContainer = $ScrollContainer/MainVBox

# Section containers (created dynamically)
var stats_section: VBoxContainer
var upgrades_section: VBoxContainer
var fleet_section: VBoxContainer
var inventory_section: VBoxContainer

func _ready() -> void:
	_build_ui()
	_populate_example_data()
	_refresh_all()

func _build_ui() -> void:
	if not main_vbox:
		return
	
	# Clear existing children
	for child: Node in main_vbox.get_children():
		child.queue_free()
	
	# Build Player Stats Section
	stats_section = _create_section("PLAYER STATUS")
	main_vbox.add_child(stats_section)
	
	# Build Upgrades Section
	upgrades_section = _create_section("UPGRADES")
	main_vbox.add_child(upgrades_section)
	
	# Build Fleet Section
	fleet_section = _create_section("FLEET")
	main_vbox.add_child(fleet_section)
	
	# Build Inventory Section
	inventory_section = _create_section("INVENTORY")
	main_vbox.add_child(inventory_section)

func _create_section(title: String) -> VBoxContainer:
	var section: VBoxContainer = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Title
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	section.add_child(title_label)
	
	# Separator
	var separator: HSeparator = HSeparator.new()
	section.add_child(separator)
	
	# Content container
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(content)
	
	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = 10
	section.add_child(spacer)
	
	return section

func _populate_example_data() -> void:
	# Example upgrades
	upgrades = [
		{
			"id": "engine",
			"name": "Engine Upgrade",
			"description": "Increases ship speed",
			"level": 2,
			"max_level": 5,
			"cost": 250,
			"icon": null
		},
		{
			"id": "shields",
			"name": "Shield Generator",
			"description": "Increases shield capacity",
			"level": 1,
			"max_level": 5,
			"cost": 300,
			"icon": null
		},
		{
			"id": "weapons",
			"name": "Weapon System",
			"description": "Increases weapon damage",
			"level": 3,
			"max_level": 5,
			"cost": 400,
			"icon": null
		}
	]
	
	# Example fleet
	fleet = [
		{
			"name": "Vanguard",
			"type": "Fighter",
			"icon": null,
			"stats": {"health": 100, "damage": 25, "speed": 350}
		},
		{
			"name": "Sentinel",
			"type": "Cruiser",
			"icon": null,
			"stats": {"health": 250, "damage": 50, "speed": 200}
		}
	]
	
	# Initialize hotbar
	hotbar_data.resize(hotbar_slots)

func _refresh_all() -> void:
	_refresh_stats()
	_refresh_upgrades()
	_refresh_fleet()
	_refresh_inventory()

# === STATS SECTION ===

func _refresh_stats() -> void:
	if not stats_section:
		return
	
	var content: VBoxContainer = stats_section.get_node("Content") as VBoxContainer
	if not content:
		return
	
	# Clear existing
	for child: Node in content.get_children():
		child.queue_free()
	
	# Player name
	var name_label: Label = Label.new()
	name_label.text = "Name: " + player_name
	content.add_child(name_label)
	
	# Level
	var level_label: Label = Label.new()
	level_label.text = "Level: " + str(player_level)
	content.add_child(level_label)
	
	# Credits
	var credits_label: Label = Label.new()
	credits_label.text = "Credits: " + str(player_credits)
	content.add_child(credits_label)

func set_player_stats(name: String, level: int, credits: int) -> void:
	player_name = name
	player_level = level
	player_credits = credits
	_refresh_stats()

# === UPGRADES SECTION ===

func _refresh_upgrades() -> void:
	if not upgrades_section:
		return
	
	var content: VBoxContainer = upgrades_section.get_node("Content") as VBoxContainer
	if not content:
		return
	
	# Clear existing
	for child: Node in content.get_children():
		child.queue_free()
	
	# Create upgrade entries
	for upgrade: Dictionary in upgrades:
		var upgrade_panel: PanelContainer = _create_upgrade_panel(upgrade)
		content.add_child(upgrade_panel)

func _create_upgrade_panel(upgrade: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.y = 60
	
	var hbox: HBoxContainer = HBoxContainer.new()
	panel.add_child(hbox)
	
	# Icon (placeholder)
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.texture = upgrade.get("icon", null)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)
	
	# Info
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label: Label = Label.new()
	name_label.text = upgrade.get("name", "Unknown")
	info_vbox.add_child(name_label)
	
	var desc_label: Label = Label.new()
	desc_label.text = upgrade.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(desc_label)
	
	var level_label: Label = Label.new()
	var current_level: int = upgrade.get("level", 0)
	var max_level: int = upgrade.get("max_level", 5)
	level_label.text = "Level: %d/%d" % [current_level, max_level]
	info_vbox.add_child(level_label)
	
	# Upgrade button
	if current_level < max_level:
		var upgrade_button: Button = Button.new()
		upgrade_button.text = "Upgrade (%d)" % upgrade.get("cost", 0)
		upgrade_button.custom_minimum_size.x = 100
		upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade.get("id", "")))
		hbox.add_child(upgrade_button)
	else:
		var max_label: Label = Label.new()
		max_label.text = "MAX"
		max_label.custom_minimum_size.x = 100
		max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(max_label)
	
	return panel

func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	upgrade_selected.emit(upgrade_id)
	
	# Find and upgrade
	for upgrade: Dictionary in upgrades:
		if upgrade.get("id", "") == upgrade_id:
			var cost: int = upgrade.get("cost", 0)
			if player_credits >= cost:
				player_credits -= cost
				upgrade["level"] = upgrade.get("level", 0) + 1
				upgrade["cost"] = int(upgrade["cost"] * 1.5)  # Increase cost for next level
				_refresh_upgrades()
				_refresh_stats()
			break

func add_upgrade(upgrade: Dictionary) -> void:
	upgrades.append(upgrade)
	_refresh_upgrades()

# === FLEET SECTION ===

func _refresh_fleet() -> void:
	if not fleet_section:
		return
	
	var content: VBoxContainer = fleet_section.get_node("Content") as VBoxContainer
	if not content:
		return
	
	# Clear existing
	for child: Node in content.get_children():
		child.queue_free()
	
	if fleet.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No ships in fleet"
		content.add_child(empty_label)
		return
	
	# Create fleet entries
	for i: int in range(fleet.size()):
		var ship: Dictionary = fleet[i]
		var ship_panel: PanelContainer = _create_fleet_panel(ship, i)
		content.add_child(ship_panel)

func _create_fleet_panel(ship: Dictionary, index: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.y = 80
	
	var hbox: HBoxContainer = HBoxContainer.new()
	panel.add_child(hbox)
	
	# Icon
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.texture = ship.get("icon", null)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)
	
	# Info
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label: Label = Label.new()
	name_label.text = ship.get("name", "Unknown Ship")
	info_vbox.add_child(name_label)
	
	var type_label: Label = Label.new()
	type_label.text = ship.get("type", "Unknown Type")
	type_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(type_label)
	
	# Stats
	var stats: Dictionary = ship.get("stats", {})
	var stats_label: Label = Label.new()
	stats_label.text = "HP: %d | DMG: %d | SPD: %d" % [
		stats.get("health", 0),
		stats.get("damage", 0),
		stats.get("speed", 0)
	]
	stats_label.add_theme_font_size_override("font_size", 9)
	info_vbox.add_child(stats_label)
	
	# Select button
	var select_button: Button = Button.new()
	select_button.text = "Select"
	select_button.custom_minimum_size.x = 80
	select_button.pressed.connect(_on_fleet_ship_selected.bind(index))
	hbox.add_child(select_button)
	
	return panel

func _on_fleet_ship_selected(index: int) -> void:
	fleet_ship_selected.emit(index)

func add_fleet_ship(ship: Dictionary) -> void:
	fleet.append(ship)
	_refresh_fleet()

func remove_fleet_ship(index: int) -> void:
	if index >= 0 and index < fleet.size():
		fleet.remove_at(index)
		_refresh_fleet()

# === INVENTORY SECTION ===

func _refresh_inventory() -> void:
	if not inventory_section:
		return
	
	var content: VBoxContainer = inventory_section.get_node("Content") as VBoxContainer
	if not content:
		return
	
	# Clear existing
	for child: Node in content.get_children():
		child.queue_free()
	
	# Hotbar label
	var hotbar_label: Label = Label.new()
	hotbar_label.text = "HOTBAR (1-0 to use)"
	hotbar_label.add_theme_font_size_override("font_size", 12)
	content.add_child(hotbar_label)
	
	# Hotbar container
	var hotbar_container: HBoxContainer = HBoxContainer.new()
	hotbar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(hotbar_container)
	
	# Create hotbar slots
	for i: int in range(hotbar_slots):
		var slot_button: Button = Button.new()
		slot_button.custom_minimum_size = Vector2(40, 40)
		slot_button.name = "HotbarSlot" + str(i)
		
		# Icon
		var icon: TextureRect = TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.anchors_preset = Control.PRESET_FULL_RECT
		slot_button.add_child(icon)
		
		# Quantity
		var quantity: Label = Label.new()
		quantity.name = "Quantity"
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quantity.anchors_preset = Control.PRESET_FULL_RECT
		slot_button.add_child(quantity)
		
		slot_button.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		hotbar_container.add_child(slot_button)
	
	# Separator
	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)
	
	# Inventory label
	var inv_label: Label = Label.new()
	inv_label.text = "STORAGE"
	inv_label.add_theme_font_size_override("font_size", 12)
	content.add_child(inv_label)
	
	# Inventory grid
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	content.add_child(scroll)
	
	var grid: GridContainer = GridContainer.new()
	grid.name = "InventoryGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	
	_refresh_hotbar_display()
	_refresh_inventory_grid()

func _refresh_hotbar_display() -> void:
	if not inventory_section:
		return
	
	var content: VBoxContainer = inventory_section.get_node("Content") as VBoxContainer
	if not content:
		return
	
	for i: int in range(hotbar_slots):
		var slot: Button = content.find_child("HotbarSlot" + str(i), true, false) as Button
		if not slot:
			continue
		
		var icon: TextureRect = slot.get_node_or_null("Icon") as TextureRect
		var quantity_label: Label = slot.get_node_or_null("Quantity") as Label
		
		if i >= hotbar_data.size() or hotbar_data[i].is_empty():
			if icon:
				icon.texture = null
			if quantity_label:
				quantity_label.text = ""
		else:
			var item: Dictionary = hotbar_data[i]
			if icon:
				icon.texture = item.get("icon", null)
			if quantity_label:
				var qty: int = item.get("quantity", 1)
				quantity_label.text = str(qty) if qty > 1 else ""

func _refresh_inventory_grid() -> void:
	if not inventory_section:
		return
	
	var grid: GridContainer = inventory_section.find_child("InventoryGrid", true, false) as GridContainer
	if not grid:
		return
	
	# Clear grid
	for child: Node in grid.get_children():
		child.queue_free()
	
	# Add items
	for i: int in range(inventory_data.size()):
		var item: Dictionary = inventory_data[i]
		var slot: Button = Button.new()
		slot.custom_minimum_size = Vector2(50, 50)
		
		var icon: TextureRect = TextureRect.new()
		icon.texture = item.get("icon", null)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.anchors_preset = Control.PRESET_FULL_RECT
		slot.add_child(icon)
		
		var quantity_label: Label = Label.new()
		quantity_label.text = str(item.get("quantity", 1))
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quantity_label.anchors_preset = Control.PRESET_FULL_RECT
		slot.add_child(quantity_label)
		
		slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		grid.add_child(slot)

func _on_hotbar_slot_pressed(slot_index: int) -> void:
	use_hotbar_item(slot_index)

func _on_inventory_slot_pressed(slot_index: int) -> void:
	# Could implement drag to hotbar here
	pass

func use_hotbar_item(hotbar_index: int) -> void:
	if hotbar_index < 0 or hotbar_index >= hotbar_slots:
		return
	
	var item: Dictionary = hotbar_data[hotbar_index]
	if item.is_empty():
		return
	
	item_used.emit(hotbar_index)
	
	# Decrease quantity
	var quantity: int = item.get("quantity", 1)
	if quantity > 1:
		item["quantity"] = quantity - 1
		_refresh_hotbar_display()
	else:
		remove_from_hotbar(hotbar_index)

func add_item(item: Dictionary) -> bool:
	# Try to stack
	for i: int in range(inventory_data.size()):
		if _can_stack(inventory_data[i], item):
			inventory_data[i]["quantity"] = inventory_data[i].get("quantity", 1) + item.get("quantity", 1)
			_refresh_inventory_grid()
			return true
	
	# Add new
	inventory_data.append(item.duplicate())
	_refresh_inventory_grid()
	return true

func remove_item(slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= inventory_data.size():
		return false
	
	var item: Dictionary = inventory_data[slot_index]
	var current_quantity: int = item.get("quantity", 1)
	
	if current_quantity <= quantity:
		inventory_data.remove_at(slot_index)
	else:
		item["quantity"] = current_quantity - quantity
	
	_refresh_inventory_grid()
	return true

func add_to_hotbar(item: Dictionary, hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= hotbar_slots:
		return false
	
	hotbar_data[hotbar_index] = item.duplicate()
	_refresh_hotbar_display()
	return true

func remove_from_hotbar(hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= hotbar_slots:
		return false
	
	hotbar_data[hotbar_index] = {}
	_refresh_hotbar_display()
	return true

func _can_stack(item1: Dictionary, item2: Dictionary) -> bool:
	if item1.is_empty() or item2.is_empty():
		return false
	return item1.get("name", "") == item2.get("name", "") and \
		   item1.get("type", "") == item2.get("type", "")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed:
			var key_code: int = key_event.keycode
			if key_code >= KEY_1 and key_code <= KEY_9:
				var slot: int = key_code - KEY_1
				if slot < hotbar_slots:
					use_hotbar_item(slot)
			elif key_code == KEY_0:
				if hotbar_slots > 9:
					use_hotbar_item(9)
