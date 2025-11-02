extends Node2D
class_name WeaponBase

signal request_ammo_ui_update
signal reload_started(duration: float)
signal reload_progress(fraction: float)
signal reload_finished

# runtime weapon config
var data: WeaponData
var auto_reload_on_empty: bool = true

# state
var magazine: int = 0
var reserve: int = 0
var _cooldown_left: float = 0.0
var _reloading: bool = false
var _reload_left: float = 0.0
var _reload_total: float = 0.0

# Called by WeaponManager right after instancing
func setup_from_data(d: WeaponData) -> void:
	data = d
	magazine = data.max_magazine
	reserve = data.max_reserve
	_cooldown_left = 0.0
	_reloading = false
	_reload_left = 0.0
	_reload_total = 0.0

func _ready() -> void:
	# Do not touch data here anymore.
	# The WeaponManager will call setup_from_data() after creating us.
	pass

func _process(delta: float) -> void:
	# cooldown tick
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)

	# reload tick for UI
	if _reloading and _reload_total > 0.0:
		_reload_left = maxf(0.0, _reload_left - delta)
		var frac: float = 1.0 - (_reload_left / _reload_total)
		emit_signal("reload_progress", frac)

	emit_signal("request_ammo_ui_update")

# -------------------------
# Helpers
# -------------------------

func can_fire() -> bool:
	if _reloading:
		return false
	if _cooldown_left > 0.0:
		return false
	if magazine <= 0:
		return false
	return true

func can_reload() -> bool:
	if _reloading:
		return false
	if magazine >= data.max_magazine:
		return false
	if reserve <= 0:
		return false
	return true

# Main fire entry (call this every frame while holding fire)
func fire() -> void:
	# already reloading or on cooldown etc.
	if _reloading:
		return
	if _cooldown_left > 0.0:
		return

	if magazine > 0:
		# consume ammo
		magazine = magazine - 1
		_cooldown_left = data.fire_cooldown
		_emit_ui()
		_on_fire_effects()
		return

	# magazine is empty
	if auto_reload_on_empty and reserve > 0:
		reload()
	else:
		_on_dry_fire()

# Manual reload (call when reload key pressed)
func reload() -> void:
	if not can_reload():
		return

	_reloading = true
	_reload_total = maxf(0.001, data.reload_time)
	_reload_left = _reload_total

	emit_signal("reload_started", _reload_total)

	# wait actual reload duration
	await get_tree().create_timer(_reload_total).timeout

	# move ammo from reserve to mag
	var need: int = data.max_magazine - magazine
	var take: int = reserve
	if take > need:
		take = need

	magazine = magazine + take
	reserve = reserve - take

	# finish
	_reloading = false
	_reload_left = 0.0
	_reload_total = 0.0
	emit_signal("reload_progress", 1.0)
	emit_signal("reload_finished")
	_emit_ui()

# These two can be overridden in subclasses
func _on_fire_effects() -> void:
	pass

func _on_dry_fire() -> void:
	pass

# UI helpers
func get_ammo_text() -> String:
	return str(magazine) + " / " + str(reserve)

func get_cooldown_fraction() -> float:
	if data.fire_cooldown <= 0.0:
		return 0.0
	return clampf(_cooldown_left / data.fire_cooldown, 0.0, 1.0)

func get_reload_fraction() -> float:
	if not _reloading:
		return 0.0
	if _reload_total <= 0.0:
		return 0.0
	return clampf(1.0 - (_reload_left / _reload_total), 0.0, 1.0)

func _emit_ui() -> void:
	emit_signal("request_ammo_ui_update")

# Expose info for UI and WeaponManager
func get_mag() -> int:
	return magazine

func get_mag_max() -> int:
	return data.max_magazine

func get_reserve() -> int:
	return reserve

func get_display_name() -> String:
	return data.display_name
