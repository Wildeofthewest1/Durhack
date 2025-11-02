extends Node2D
class_name WeaponManager

signal slot_changed(index: int)
signal inventory_changed()
signal weapon_equipped(node: Node)
signal weapon_unequipped()

@export var slot_count: int = 6
@export var socket_path: NodePath = NodePath("WeaponSocket")

var slots: Array[WeaponData] = []
var _equipped_index: int = -1
var _equipped_instance: WeaponBase = null
var _socket: Node2D = null

func _ready() -> void:
	print("[WeaponManager] ready")

	# pre-size slots
	slots.resize(slot_count)

	# cache socket
	if has_node(socket_path):
		_socket = get_node(socket_path) as Node2D
	else:
		_socket = null
		push_warning("[WeaponManager] socket_path invalid. Weapon will sit at WeaponManager origin.")

	# optional: auto-equip first non-empty slot
	var i: int = 0
	while i < slot_count:
		if slots[i] != null:
			_equip_slot(i)
			break
		i = i + 1

func _process(delta: float) -> void:
	# keep equipped weapon positioned at socket
	if _equipped_instance != null:
		if _socket != null:
			_equipped_instance.global_position = _socket.global_position
		else:
			_equipped_instance.global_position = global_position

	# let weapon scripts aim themselves (pistol.gd etc.), so we do NOT forcibly rotate here

	_handle_input(delta)

# -------------------------------------------------
# INPUT HANDLING (WeaponManager now owns shooting)
# -------------------------------------------------

func _handle_input(delta: float) -> void:
	if _equipped_instance == null:
		return

	# fire while held
	if Input.is_action_pressed("weapon_fire"):
		_equipped_instance.fire()

	# manual reload
	if Input.is_action_just_pressed("weapon_reload"):
		_equipped_instance.reload()

	# switch weapons
	if Input.is_action_just_pressed("weapon_next"):
		_cycle_slot(1)
	if Input.is_action_just_pressed("weapon_prev"):
		_cycle_slot(-1)

# -------------------------------------------------
# PUBLIC API
# -------------------------------------------------

func set_slot(index: int, data: WeaponData) -> void:
	if index < 0:
		return
	if index >= slot_count:
		return
	slots[index] = data
	emit_signal("inventory_changed")

func get_equipped_instance() -> WeaponBase:
	return _equipped_instance

func get_equipped_index() -> int:
	return _equipped_index

# Switch to another slot by offset (+1 next, -1 prev)
func _cycle_slot(add: int) -> void:
	if slot_count <= 0:
		return

	if _equipped_index < 0:
		# nothing equipped yet: pick first non-empty
		var j: int = 0
		while j < slot_count:
			if slots[j] != null:
				_equip_slot(j)
				return
			j = j + 1
		return

	var target_index: int = _equipped_index + add

	# wrap manually (no modulo)
	if target_index < 0:
		target_index = slot_count - 1
	if target_index >= slot_count:
		target_index = 0

	_equip_slot(target_index)

# Equip a specific slot index
func _equip_slot(index: int) -> void:
	if index < 0:
		return
	if index >= slot_count:
		return

	var data: WeaponData = slots[index]
	if data == null:
		print("[WeaponManager] slot ", index, " is empty")
		return

	# remove old weapon
	_unequip_internal()

	# check data.weapon_scene is valid
	if data.weapon_scene == null:
		push_warning("[WeaponManager] WeaponData at slot ", index, " has no weapon_scene")
		return

	var inst_node: Node = data.weapon_scene.instantiate()
	if inst_node == null:
		push_warning("[WeaponManager] failed to instance weapon_scene at slot ", index)
		return

	# attach under WeaponManager (NOT Player directly)
	add_child(inst_node)

	# verify it's a WeaponBase
	if inst_node is WeaponBase:
		var weapon: WeaponBase = inst_node as WeaponBase

		# inject the WeaponData BEFORE we start using it
		weapon.setup_from_data(data)

		_equipped_instance = weapon
		_equipped_index = index

		# snap position immediately
		if _socket != null:
			_equipped_instance.global_position = _socket.global_position
		else:
			_equipped_instance.global_position = global_position

		print("[WeaponManager] equipped -> " + data.display_name)
		emit_signal("weapon_equipped", _equipped_instance)
		emit_signal("slot_changed", index)
	else:
		push_warning("[WeaponManager] Equipped scene does not extend WeaponBase: " + data.display_name)

func _unequip_internal() -> void:
	if _equipped_instance != null:
		print("[WeaponManager] unequip ", _equipped_instance.name)
		_equipped_instance.queue_free()
		_equipped_instance = null
		emit_signal("weapon_unequipped")
	_equipped_index = -1
