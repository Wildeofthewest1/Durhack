extends Control
class_name TalkUI

signal option_selected(option_index: int)

@export var typing_speed: float = 0.05  # Time between characters
@export var show_speaker_sprite: bool = true

@onready var speaker_sprite: TextureRect = $MarginContainer/MainContainer/SpriteContainer/SpeakerSprite
@onready var speaker_name_label: Label = $MarginContainer/MainContainer/DialogueContainer/SpeakerName
@onready var dialogue_label: RichTextLabel = $MarginContainer/MainContainer/DialogueContainer/DialogueText
@onready var options_container: VBoxContainer = $MarginContainer/MainContainer/DialogueContainer/OptionsContainer

var dialogue_system: DialogueSystem
var is_typing: bool = false
var current_text: String = ""
var visible_characters: int = 0
var typing_timer: float = 0.0

func _ready() -> void:
	if not dialogue_system:
		dialogue_system = DialogueSystem.new()
		add_child(dialogue_system)
	
	dialogue_system.dialogue_started.connect(_on_dialogue_started)
	dialogue_system.dialogue_ended.connect(_on_dialogue_ended)
	dialogue_system.node_changed.connect(_on_node_changed)
	
	visible = false

func _process(delta: float) -> void:
	if is_typing:
		_process_typing(delta)

func _process_typing(delta: float) -> void:
	typing_timer += delta
	
	if typing_timer >= typing_speed:
		typing_timer = 0.0
		visible_characters += 1
		
		if dialogue_label:
			dialogue_label.visible_characters = visible_characters
		
		if visible_characters >= current_text.length():
			is_typing = false

func start_dialogue(dialogue_data: Dictionary, start_node: String = "start", speaker_texture: Texture2D = null) -> void:
	dialogue_system.load_dialogue(dialogue_data)
	dialogue_system.start_dialogue(start_node)
	
	if speaker_sprite and speaker_texture:
		speaker_sprite.texture = speaker_texture
		speaker_sprite.visible = true
	elif speaker_sprite:
		speaker_sprite.visible = false
	
	visible = true

func end_dialogue() -> void:
	dialogue_system.end_dialogue()
	visible = false

func skip_typing() -> void:
	if is_typing and dialogue_label:
		is_typing = false
		dialogue_label.visible_characters = -1

func _display_current_node() -> void:
	var speaker: String = dialogue_system.get_current_speaker()
	var text: String = dialogue_system.get_current_text()
	var options: Array = dialogue_system.get_current_options()
	
	# Update speaker name
	if speaker_name_label:
		speaker_name_label.text = speaker
		speaker_name_label.visible = not speaker.is_empty()
	
	# Start typing effect
	current_text = text
	visible_characters = 0
	is_typing = true
	typing_timer = 0.0
	
	if dialogue_label:
		dialogue_label.text = text
		dialogue_label.visible_characters = 0
	
	# Clear and create option buttons
	_clear_options()
	_create_option_buttons(options)

func _clear_options() -> void:
	if not options_container:
		return
	
	for child: Node in options_container.get_children():
		child.queue_free()

func _create_option_buttons(options: Array) -> void:
	if not options_container:
		return
	
	for i: int in range(options.size()):
		var option: Dictionary = options[i]
		var button: Button = Button.new()
		button.text = option.get("text", "Option " + str(i + 1))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(button)

func _on_option_pressed(option_index: int) -> void:
	skip_typing()  # Finish any typing animation
	option_selected.emit(option_index)
	dialogue_system.select_option(option_index)

func _on_dialogue_started() -> void:
	_display_current_node()

func _on_dialogue_ended() -> void:
	visible = false

func _on_node_changed(node_id: String) -> void:
	_display_current_node()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed:
			# Space or Enter to skip typing
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
				if is_typing:
					skip_typing()
			# Number keys for quick option selection
			elif key_event.keycode >= KEY_1 and key_event.keycode <= KEY_9:
				var option_num: int = key_event.keycode - KEY_1
				var options: Array = dialogue_system.get_current_options()
				if option_num < options.size():
					_on_option_pressed(option_num)

# Public API
func load_dialogue(data: Dictionary) -> void:
	dialogue_system.load_dialogue(data)

func get_dialogue_system() -> DialogueSystem:
	return dialogue_system

func is_dialogue_active() -> bool:
	return dialogue_system.is_dialogue_active() if dialogue_system else false

func set_speaker_sprite(texture: Texture2D) -> void:
	if speaker_sprite:
		speaker_sprite.texture = texture
		speaker_sprite.visible = texture != null
