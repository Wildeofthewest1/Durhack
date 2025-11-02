# res://weapons/WeaponPistol.gd
extends WeaponBase

@export var bullet_scene: PackedScene = preload("res://Scenes/weapons/pistol_bullet.tscn")
@onready var muzzle: Node2D = $Muzzle  # <-- drag the marker in the scene

func _process(delta: float) -> void:
	super._process(delta) # keeps cooldown UI ticking
	# Point the weapon toward the mouse in world space
	look_at(get_global_mouse_position())

func _on_fire_effects() -> void:
	if not bullet_scene:
		push_error("[Pistol] bullet_scene not set")
		return

	# Choose a transform source (Muzzle if present, otherwise the weapon node)
	var xform_src := muzzle if is_instance_valid(muzzle) else self
	var spawn_pos := muzzle.global_position
	var dir := Vector2.RIGHT.rotated(xform_src.global_rotation)

	# Instance bullet into the same world as the player/weapon
	var b := bullet_scene.instantiate()
	if(get_parent()):
		get_parent().get_parent().get_parent().add_child(b)  # world/root, not UI CanvasLayer
	b.global_position = spawn_pos
	b.global_rotation = muzzle.global_rotation

	# Inherit player's velocity if available
	var shooter_vel := Vector2.ZERO
	if owner and "velocity" in owner:
		shooter_vel = owner.velocity

	if b.has_method("setup"):
		b.setup(dir, shooter_vel)
