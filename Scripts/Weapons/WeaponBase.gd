# res://weapons/WeaponBase.gd
extends Node2D
class_name WeaponBase

# --- UI signals (unchanged) ---
signal request_ammo_ui_update
signal reload_started(duration: float)
signal reload_progress(fraction: float)   # 0..1
signal reload_finished

@export var data: WeaponData

# QoL: click fire on empty magazine will start reload if possible
@export var auto_reload_on_empty: bool = true

# Optional: play a "dry fire" effect when empty (override in subclass)
func _on_dry_fire() -> void: pass

var magazine: int
var reserve: int
var _cooldown_left := 0.0
var _reloading := false
var _reload_left := 0.0
var _reload_total := 0.0

func _ready() -> void:
	assert(data, "WeaponBase requires WeaponData")
	magazine = data.max_magazine
	reserve  = data.max_reserve

func _process(delta: float) -> void:
	# cooldown tick
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)

	# reload tick for UI
	if _reloading and _reload_total > 0.0:
		_reload_left = maxf(0.0, _reload_left - delta)
		var frac := 1.0 - (_reload_left / _reload_total)
		emit_signal("reload_progress", frac)

	emit_signal("request_ammo_ui_update")

# Convenience helpers
func can_fire() -> bool:
	return not _reloading and _cooldown_left == 0.0 and magazine > 0

func can_reload() -> bool:
	return not _reloading and magazine < data.max_magazine and reserve > 0

# Call this on input press/hold. It will fire if possible; otherwise start reload.
func fire() -> void:
	if _reloading:
		# already reloading; ignore trigger
		return

	if _cooldown_left > 0.0:
		# on cooldown; ignore
		return

	if magazine > 0:
		# normal shot
		magazine -= 1
		_cooldown_left = data.fire_cooldown
		_emit_ui()
		_on_fire_effects()
		return

	# magazine == 0 here
	if auto_reload_on_empty and reserve > 0:
		# start reload because user clicked while empty
		reload()
	else:
		# no reserve or auto-reload disabled
		_on_dry_fire()

func reload() -> void:
	if not can_reload():
		return

	_reloading = true
	_reload_total = maxf(0.001, data.reload_time)
	_reload_left  = _reload_total
	emit_signal("reload_started", _reload_total)

	# wait actual reload time
	await get_tree().create_timer(_reload_total).timeout

	# transfer ammo
	var need := data.max_magazine - magazine
	var take := mini(need, reserve)
	magazine += take
	reserve  -= take

	# finish
	_reloading = false
	_reload_left = 0.0
	_reload_total = 0.0
	emit_signal("reload_progress", 1.0)
	emit_signal("reload_finished")
	_emit_ui()

func get_ammo_text() -> String:
	return "%d / %d" % [magazine, reserve]

func get_cooldown_fraction() -> float:
	if data.fire_cooldown <= 0.0: return 0.0
	return clampf(_cooldown_left / data.fire_cooldown, 0.0, 1.0)

func get_reload_fraction() -> float:
	if not _reloading or _reload_total <= 0.0: return 0.0
	return clampf(1.0 - (_reload_left / _reload_total), 0.0, 1.0)

func _emit_ui(): emit_signal("request_ammo_ui_update")

# Override in concrete weapons to spawn bullets / effects
func _on_fire_effects() -> void: pass

func get_mag() -> int: return magazine
func get_mag_max() -> int: return data.max_magazine
func get_reserve() -> int: return reserve
func get_display_name() -> String: return data.display_name
