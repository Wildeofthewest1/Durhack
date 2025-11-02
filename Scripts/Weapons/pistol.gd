extends WeaponBase
class_name WeaponPistol

@export var bullet_scene: PackedScene
@export var muzzle_velocity: float = 800.0
@export var damage: float = 10.0

@onready var muzzle: Node2D = $Muzzle

var _aim_dir: Vector2 = Vector2.RIGHT  # cached direction toward mouse

func _process(delta: float) -> void:
	# let WeaponBase tick cooldown
	super._process(delta)

	# update aim every frame
	_update_aim()

func _update_aim() -> void:
	# 1. mouse in world space
	var mouse_world: Vector2 = get_global_mouse_position()

	# 2. direction from gun to mouse
	var to_mouse: Vector2 = mouse_world - global_position
	var dist: float = to_mouse.length()
	if dist > 0.0:
		_aim_dir = to_mouse / dist  # normalized

	# 3. rotate the weapon to face that direction
	# IMPORTANT:
	# If your pistol sprite points right in its default orientation, use this:
	rotation = _aim_dir.angle()

	# If your pistol art points up instead of right, use:
	# rotation = _aim_dir.angle() + PI / 2.0

func request_fire() -> void:
	# This is what WeaponManager will call.
	# We reuse WeaponBase.try_fire(), passing the current aim direction.
	try_fire(_aim_dir)

func _fire_projectile(dir: Vector2) -> void:
	# called by WeaponBase.try_fire() after cooldown check

	if bullet_scene == null:
		push_error("[WeaponPistol] bullet_scene is not set")
		return

	if muzzle == null:
		push_error("[WeaponPistol] muzzle is missing")
		return

	# 1. Instance bullet
	var proj: Node2D = bullet_scene.instantiate() as Node2D

	# 2. Add to world
	var world_root: Node = get_parent().get_parent().get_parent()
	world_root.add_child(proj)

	# 3. Place and orient
	proj.global_position = muzzle.global_position
	proj.global_rotation = dir.angle()

	# 4. Build inherited velocity from owner if possible
	var shooter_vel: Vector2 = Vector2.ZERO
	var owner_body: CharacterBody2D = owner as CharacterBody2D
	if owner_body != null:
		shooter_vel = owner_body.velocity

	# 5. Initialize projectile
	if proj.has_method("initialize_projectile"):
		# If your projectile takes 4 args (dir, speed, dmg, inherited_vel):
		proj.call("initialize_projectile", dir, muzzle_velocity, damage, shooter_vel)

		# If your projectile currently only accepts 3 args:
		# proj.call("initialize_projectile", dir, muzzle_velocity, damage)
