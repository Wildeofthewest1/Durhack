extends WeaponBase
class_name WeaponRailgun

@export var muzzle_path: NodePath = NodePath("Muzzle")
@export var spawn_offset_px: float = 0.0
@export var max_range: float = 900.0

# Charging
@export var charge_time: float = 0.4
@export var charge_particles_path: NodePath = NodePath("ChargeParticles")

var _muzzle: Node2D
@onready var _audio: AudioStreamPlayer = $AudioStreamPlayer2D
var _charge_particles: GPUParticles2D = null

var _is_charging: bool = false
var _charge_timer: float = 0.0
var _wants_to_fire: bool = false   # true while fire button is held


func _ready() -> void:
	super._ready()
	_muzzle = get_node(muzzle_path) as Node2D
	if charge_particles_path != NodePath(""):
		_charge_particles = get_node(charge_particles_path) as GPUParticles2D
	_update_aim()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_aim()
	_update_charge(delta)


func _update_aim() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = mouse_world - global_position
	var dist: float = to_mouse.length()
	if dist > 0.0:
		_aim_dir = to_mouse / dist


# Called continuously while fire is held
func request_fire() -> void:
	_wants_to_fire = true

	# Already charging, nothing else to do
	if _is_charging:
		return

	# Mirror WeaponBase.try_fire checks, but don't actually fire yet
	if data == null:
		return
	if _is_reloading:
		return
	if _cooldown > 0.0:
		return
	if _current_mag <= 0:
		_start_reload()
		return

	_start_charge()


# You need WeaponManager to call this when fire button is released
func release_fire() -> void:
	_wants_to_fire = false

	if _is_charging:
		_is_charging = false
		_charge_timer = 0.0
		if _charge_particles != null:
			_charge_particles.emitting = false


func _start_charge() -> void:
	_is_charging = true
	_charge_timer = charge_time
	if _charge_particles != null:
		_charge_particles.emitting = true


func _update_charge(delta: float) -> void:
	if not _is_charging:
		return

	_charge_timer -= delta
	if _charge_timer <= 0.0:
		_is_charging = false
		if _charge_particles != null:
			_charge_particles.emitting = false

		# Only actually fire if the button is STILL held
		if _wants_to_fire:
			# This calls into WeaponBase, which finally calls _fire_projectile
			try_fire(_aim_dir)


func _fire_projectile(dir: Vector2) -> void:
	if data == null:
		return
	if _muzzle == null:
		push_error("WeaponRailgun: muzzle is missing")
		return

	# Softer knockback on player/mech
	var parent_node: Node = get_parent().get_parent().get_parent()
	if parent_node is Node2D:
		var parent_nd2: Node2D = parent_node as Node2D
		parent_nd2.global_position += -4.0 * dir.normalized()

	var fire_dir: Vector2 = dir
	if fire_dir.length() == 0.0:
		fire_dir = Vector2.RIGHT
	fire_dir = fire_dir.normalized()

	var origin: Vector2 = _muzzle.global_position + fire_dir * spawn_offset_px
	var target: Vector2 = origin + fire_dir * max_range

	# 1) Piercing hitscan: damage all enemies along the line, get last enemy hit pos
	var end_point: Vector2 = _piercing_hitscan(origin, target, fire_dir)

	# 2) Visual beam from muzzle to last hit enemy (or max range if none hit)
	_spawn_beam(origin, end_point)

	# 3) Audio / muzzle flash
	if _audio != null:
		_audio.play()

	if data.flash_scene != null:
		var flash_instance: Node2D = data.flash_scene.instantiate() as Node2D
		_muzzle.add_child(flash_instance)
		flash_instance.position = Vector2.ZERO
		flash_instance.rotation = 0.0
		flash_instance.scale = Vector2(1.0, 1.0)


func _piercing_hitscan(origin: Vector2, target: Vector2, fire_dir: Vector2) -> Vector2:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var exclude_rids: Array[RID] = []

	# Exclude the weapon parent body so we never hit ourselves
	var parent_node: Node = get_parent()
	if parent_node is CollisionObject2D:
		var parent_body: CollisionObject2D = parent_node as CollisionObject2D
		exclude_rids.append(parent_body.get_rid())

	var from_point: Vector2 = origin
	var last_hit_pos: Vector2 = target

	var max_iterations: int = 32
	for i in range(max_iterations):
		var query := PhysicsRayQueryParameters2D.create(from_point, target)
		query.collide_with_bodies = true
		query.collide_with_areas = true
		query.exclude = exclude_rids

		var result: Dictionary = space.intersect_ray(query)
		if result.is_empty():
			break

		var collider: Object = result["collider"]
		var hit_pos: Vector2 = result["position"]
		var rid: RID = result["rid"]
		exclude_rids.append(rid)

		# Only enemies take damage; anything else is just passed through
		if collider != null and _is_damageable(collider):
			_apply_hit_damage(collider)
			last_hit_pos = hit_pos

		from_point = hit_pos + fire_dir * 1.0

		var remaining: Vector2 = target - from_point
		if remaining.length() <= 0.5:
			break

	return last_hit_pos


func _is_damageable(collider: Object) -> bool:
	# STRICT: only nodes in the "Enemy" group are damageable
	if collider.is_in_group("Enemy"):
		return true
	return false


func _apply_hit_damage(collider: Object) -> void:
	var damage: float = data.damage

	if collider.has_method("take_damage"):
		collider.call("take_damage", damage)
	elif collider.has_method("apply_damage"):
		collider.call("apply_damage", damage)
	elif collider.has_method("damage"):
		collider.call("damage", damage)


func _spawn_beam(origin: Vector2, end_point: Vector2) -> void:
	if data.bullet_scene == null:
		return

	var beam: RailgunBeam = data.bullet_scene.instantiate() as RailgunBeam

	var parent_node: Node = get_parent().get_parent().get_parent().get_parent()
	if parent_node == null:
		parent_node = get_parent()
	if parent_node == null:
		return

	parent_node.add_child(beam)
	beam.setup(origin, end_point)
