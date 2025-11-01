extends Node2D
class_name WeaponManager

signal slot_changed(index: int)
signal inventory_changed()
signal weapon_equipped(node: Node)
signal weapon_unequipped()

@export var slot_count: int = 6
@export var socket_path: NodePath = NodePath("WeaponSocket")

# array of WeaponData for each slot
var slots: Array[WeaponData] = []

# currently equipped weapon index in slots
var _equipped_index: int = -1

# actual instantiated weapon node (WeaponBase or subclass)
var _equipped_instance: WeaponBase = null

# cached socket node (where to place weapon)
var _socket: Node2D = null

func _ready() -> void:
	print("[WeaponManager] ready")
	# prepare slots
	slots.resize(slot_count)

	# cache socket
	if has_node(socket_path):
		_socket = get_node(socket_path) as Node2D
	else:
		_socket = null
		push_warning("[WeaponManager] socket_path is not valid. Weapon will just sit at WeaponManager origin.")

	# (Optional) auto-equip first valid slot on ready
	var i: int = 0
	while i < slot_count:
		if slots[i] != null:
			_equip_slot(i)
			break
		i += 1

func _process(delta: float) -> void:
	# Make sure weapon stays snapped to socket and aims at cursor
	if _equipped_instance != null:
		if _socket != null:
			_equipped_instance.global_position = _socket.global_position
		else:
			_equipped_instance.global_position = global_position

		# let each weapon rotate to mouse, or do it here:
		_equipped_instance.look_at(get_global_mouse_position())

	# tick weapon-specific logic if it needs delta
	# (WeaponBase probably already has its own _process(delta),
	#  so you normally do not need to call anything here.)

	_handle_input(delta)

# ---------------------------------
# INPUT HANDLING (no longer in Player)
# ---------------------------------

func _handle_input(delta: float) -> void:
	if _equipped_instance == null:
		return
	
	# Primary fire (hold)
	if Input.is_action_pressed("weapon_fire"):
		# Replace 'try_fire' with your real method on WeaponBase
		if _equipped_instance.has_method("try_fire"):
			_equipped_instance.try_fire()

	# Release trigger (useful for semi-auto, burst cutoffs, etc.)
	if Input.is_action_just_released("weapon_fire"):
		if _equipped_instance.has_method("release_trigger"):
			_equipped_instance.release_trigger()

	# Manual reload
	if Input.is_action_just_pressed("weapon_reload"):
		if _equipped_instance.has_method("start_reload"):
			_equipped_instance.start_reload()

	# Switch weapon up / down
	if Input.is_action_just_pressed("weapon_next"):
		_cycle_slot(1)
	if Input.is_action_just_pressed("weapon_prev"):
		_cycle_slot(-1)

# ---------------------------------
# PUBLIC API: INVENTORY / EQUIP
# ---------------------------------

# call this to assign a WeaponData into a slot, e.g. picking up a gun
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

func _cycle_slot(add: int) -> void:
	if slot_count <= 0:
		return
	if _equipped_index < 0:
		# no weapon yet, just equip first non-empty
		var i: int = 0
		while i < slot_count:
			if slots[i] != null:
				_equip_slot(i)
				return
			i += 1
		return

	var target_index: int = _equipped_index + add

	# wrap forward / backward WITHOUT using the % operator
	if target_index < 0:
		target_index = slot_count - 1
	if target_index >= slot_count:
		target_index = 0

	_equip_slot(target_index)

func _equip_slot(index: int) -> void:
	# safety
	if index < 0:
		return
	if index >= slot_count:
		return
	var data: WeaponData = slots[index]
	if data == null:
		print("[WeaponManager] slot ", index, " is empty")
		return

	# remove old
	_unequip_internal()

	# instance new weapon
	if not data.scene:
		push_warning("[WeaponManager] WeaponData has no scene at slot ", index)
		return

	var inst: Node = data.scene.instantiate()
	if inst == null:
		push_warning("[WeaponManager] failed to instance scene in slot ", index)
		return

	# attach under WeaponManager (NOT Player directly)
	add_child(inst)

	# make sure it's a WeaponBase
	if inst is WeaponBase:
		_equipped_instance = inst as WeaponBase
		_equipped_index = index

		# position it right away at the socket
		if _socket != null:
			_equipped_instance.global_position = _socket.global_position
		else:
			_equipped_instance.global_position = global_position

		print("[WeaponManager] equipped -> ", data.display_name)
		emit_signal("weapon_equipped", _equipped_instance)

		emit_signal("slot_changed", index)
	else:
		push_warning("[WeaponManager] Equipped scene does not extend WeaponBase: ", data.display_name)

func _unequip_internal() -> void:
	if _equipped_instance != null:
		print("[WeaponManager] unequip ", _equipped_instance.name)
		_equipped_instance.queue_free()
		_equipped_instance = null
		emit_signal("weapon_unequipped")
	_equipped_index = -1
