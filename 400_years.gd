extends Label

signal invasion_started_signal  # emitted when countdown ends

var timevalue = 400
@export var timescale = 0.2
var invasion_started := false
var pulse_speed := 3.0
var pulse_strength := 0.2

func _ready() -> void:
	$Timer.wait_time = timescale
	text = str(snapped(timevalue, 0.1)) + " Years Until the Invasion"


func _process(delta: float) -> void:
	if not invasion_started:
		text = str(snapped(timevalue, 0.1)) + " Years Until the Invasion"
	else:
		text = "The Invasion Has Begun!"
		var scale_factor = 1.0 + sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) * pulse_strength
		scale = Vector2(scale_factor, scale_factor)


func _on_timer_timeout() -> void:
	if timevalue > 0:
		timevalue -= 0.1
	else:
		if not invasion_started:
			invasion_started = true
			$Timer.stop()
			emit_signal("invasion_started_signal")  # 🔔 tell other nodes to start spawning
