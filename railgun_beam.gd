extends Node2D
class_name RailgunBeam

# Lifetimes
@export var core_lifetime: float = 0.10          # core line + white streak
@export var lightning_lifetime: float = 0.08     # jittery lightning
@export var width: float = 4.0
@export var jitter_amplitude: float = 12.0
@export var beam_color: Color = Color(0.8, 1.0, 1.0, 1.0)

@export var extra_line_count: int = 2
@export var segment_density: float = 1.0 / 24.0
@export var min_segments: int = 4
@export var max_segments: int = 64
@export var jumble_fraction: float = 0.35

# How far past the lightning end the lines should extend (pixels)
@export var core_extra_length: float = 40.0
@export var streak_extra_length: float = 80.0

@export var explosion_scene: PackedScene

@onready var _core_line: Line2D = $Line2D     # straight colored core line
var _streak_line: Line2D                      # white overextended streak

var _core_time_left: float = 0.0
var _lightning_time_left: float = 0.0
var _lightning_lines: Array[Line2D] = []

var _start: Vector2 = Vector2.ZERO
var _end: Vector2 = Vector2.ZERO
var _length: float = 0.0


func _ready() -> void:
	_core_time_left = core_lifetime
	_lightning_time_left = lightning_lifetime

	_core_line.width = width
	_core_line.default_color = beam_color

	_lightning_lines.clear()

	# Create the white streak line
	_streak_line = Line2D.new()
	_streak_line.width = width * 1.2
	_streak_line.default_color = Color(1.0, 1.0, 1.0, 0.5)
	add_child(_streak_line)


func setup(start: Vector2, end: Vector2) -> void:
	global_position = Vector2.ZERO

	_start = start
	_end = end
	_length = (_end - _start).length()

	_build_core_line()
	_build_streak_line()
	_ensure_lightning_lines()
	_rebuild_lightning_lines()
	_spawn_explosion()


func _build_core_line() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(_start)

	var direction: Vector2 = _end - _start
	var length: float = direction.length()
	var core_end: Vector2 = _end

	if length > 0.0:
		var dir_norm: Vector2 = direction / length
		core_end = _end + dir_norm * core_extra_length

	points.append(core_end)
	_core_line.points = points


func _build_streak_line() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(_start)

	var direction: Vector2 = _end - _start
	var length: float = direction.length()
	var streak_end: Vector2 = _end

	if length > 0.0:
		var dir_norm: Vector2 = direction / length
		streak_end = _end + dir_norm * streak_extra_length

	points.append(streak_end)
	_streak_line.points = points


func _ensure_lightning_lines() -> void:
	var needed: int = extra_line_count - _lightning_lines.size()
	if needed > 0:
		for i in range(needed):
			var line: Line2D = Line2D.new()
			line.width = width * 0.7
			line.default_color = beam_color
			add_child(line)
			_lightning_lines.append(line)

	for idx in range(_lightning_lines.size()):
		var line_update: Line2D = _lightning_lines[idx]
		line_update.width = width * 0.7
		line_update.default_color = beam_color


func _rebuild_lightning_lines() -> void:
	var direction: Vector2 = _end - _start
	_length = direction.length()

	if _length <= 0.0:
		var simple_points: PackedVector2Array = PackedVector2Array()
		simple_points.append(_start)
		simple_points.append(_end)
		for idx in range(_lightning_lines.size()):
			_lightning_lines[idx].points = simple_points
		return

	var dir_norm: Vector2 = direction / _length
	var perp: Vector2 = Vector2(-dir_norm.y, dir_norm.x)

	var steps: int = int(_length * segment_density)
	if steps < min_segments:
		steps = min_segments
	if steps > max_segments:
		steps = max_segments

	for idx in range(_lightning_lines.size()):
		var line: Line2D = _lightning_lines[idx]
		var points: PackedVector2Array = PackedVector2Array()
		var jitter_scale: float = 1.0 + float(idx) * 0.4

		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			var base_point: Vector2 = _start.lerp(_end, t)

			var offset: float = 0.0
			if i != 0 and i != steps:
				offset = randf_range(-jitter_amplitude * jitter_scale, jitter_amplitude * jitter_scale)

			points.append(base_point + perp * offset)

		line.points = points


func _spawn_explosion() -> void:
	if explosion_scene == null:
		return

	var root: Node = get_parent()
	if root == null:
		root = get_parent()
	if root == null:
		return

	var e: Node2D = explosion_scene.instantiate() as Node2D
	root.add_child(e)
	# your explosion scene handles emitting/rotation itself
	e.emitting = true
	e.look_at(get_tree().get_first_node_in_group("player").global_position-_end)
	e.global_position = _end


func _process(delta: float) -> void:
	_core_time_left -= delta
	_lightning_time_left -= delta

	if _core_time_left <= 0.0 and _lightning_time_left <= 0.0:
		queue_free()
		return

	# Lightning jitters only while it's still "early" in its own lifetime
	var lightning_ratio: float = 0.0
	if lightning_lifetime > 0.0:
		lightning_ratio = _lightning_time_left / lightning_lifetime

	if lightning_ratio > (1.0 - jumble_fraction):
		_rebuild_lightning_lines()

	# Core fade (core line + streak)
	var core_ratio: float = 0.0
	if core_lifetime > 0.0:
		core_ratio = _core_time_left / core_lifetime
	if core_ratio < 0.0:
		core_ratio = 0.0
	if core_ratio > 1.0:
		core_ratio = 1.0

	var main_color: Color = beam_color
	main_color.a = beam_color.a * core_ratio
	_core_line.default_color = main_color

	var streak_color: Color = Color(1.0, 1.0, 1.0, core_ratio)
	_streak_line.default_color = streak_color

	# Lightning fade
	var lightning_alpha: float = lightning_ratio
	if lightning_alpha < 0.0:
		lightning_alpha = 0.0
	if lightning_alpha > 1.0:
		lightning_alpha = 1.0

	var lightning_color: Color = beam_color
	lightning_color.a = beam_color.a * lightning_alpha

	for idx in range(_lightning_lines.size()):
		_lightning_lines[idx].default_color = lightning_color
