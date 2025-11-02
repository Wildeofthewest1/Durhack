extends Node

@export var G: float = 100.0  # Gravitational constant

func _physics_process(delta: float) -> void:
	var planets := get_tree().get_nodes_in_group("Planets")
	var n := planets.size()

	for i in range(n):
		var a: CharacterBody2D = planets[i]
		for j in range(i + 1, n):
			var b: CharacterBody2D = planets[j]
			_apply_gravity(a, b, delta)


func _apply_gravity(a: CharacterBody2D, b: CharacterBody2D, delta: float) -> void:
	var dir := b.global_position - a.global_position
	var dist_sq := max(dir.length_squared(), 1.0)
	var force_mag := G * (a.mass * b.mass) / dist_sq
	var force_dir := dir.normalized()

	# Acceleration = F / m
	var accel_a := (force_dir * force_mag) / a.mass
	var accel_b := -(force_dir * force_mag) / b.mass

	a.velocity += accel_a * delta
	b.velocity += accel_b * delta
