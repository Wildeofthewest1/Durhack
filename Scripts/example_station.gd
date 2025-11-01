extends Interactable

func _ready() -> void:
	super._ready()
	
	# Configure this station
	interaction_name = "Deep Space Station Alpha"
	interactable_type = "Station"
	has_dialogue = true
	dialogue_start_node = "start"
	
	# Set up example dialogue
	var dialogue_data: Dictionary = {
		"start": {
			"text": "Welcome to Deep Space Station Alpha. The alien invasion is coming in 400 years. We must prepare!",
			"speaker": "Station Commander",
			"options": [
				{"text": "What can I do to help?", "next": "help", "id": "ask_help"},
				{"text": "Tell me about the station.", "next": "station_info", "id": "ask_info"},
				{"text": "I need supplies.", "next": "supplies", "id": "ask_supplies"},
				{"text": "Goodbye.", "next": "end", "id": "goodbye"}
			]
		},
		"help": {
			"text": "We need resources to build defensive structures. Mining operations in the asteroid belt would be invaluable.",
			"speaker": "Station Commander",
			"options": [
				{"text": "I'll start mining operations.", "next": "mining", "id": "accept_mining"},
				{"text": "What else can I do?", "next": "other_tasks", "id": "ask_more"},
				{"text": "Let me think about it.", "next": "end", "id": "maybe"}
			]
		},
		"station_info": {
			"text": "This station serves as a forward outpost. We conduct research and coordinate defense preparations across the system.",
			"speaker": "Station Commander",
			"options": [
				{"text": "Impressive. How can I help?", "next": "help", "id": "offer_help"},
				{"text": "Goodbye.", "next": "end", "id": "goodbye"}
			]
		},
		"supplies": {
			"text": "Our trading bay is on deck 3. You'll find fuel, ammunition, and ship parts there.",
			"speaker": "Station Commander",
			"options": [
				{"text": "Thanks. Anything else?", "next": "start", "id": "back"},
				{"text": "That's all I needed.", "next": "end", "id": "goodbye"}
			]
		},
		"mining": {
			"text": "Excellent! Head to the asteroid belt coordinates I'm uploading to your ship. Every ton of ore helps.",
			"speaker": "Station Commander",
			"options": [
				{"text": "I'm on it!", "next": "end", "id": "accept"},
				{"text": "Actually, let me reconsider.", "next": "help", "id": "back"}
			]
		},
		"other_tasks": {
			"text": "We also need scouts to survey distant sectors and engineers to maintain our defense grid.",
			"speaker": "Station Commander",
			"options": [
				{"text": "I can scout.", "next": "scout", "id": "accept_scout"},
				{"text": "I'll help with engineering.", "next": "engineer", "id": "accept_engineer"},
				{"text": "Let me think.", "next": "end", "id": "maybe"}
			]
		},
		"scout": {
			"text": "Perfect. Check sectors 7-12 for any anomalies. Report back with your findings.",
			"speaker": "Station Commander",
			"options": [
				{"text": "Understood.", "next": "end", "id": "accept"}
			]
		},
		"engineer": {
			"text": "We need someone to calibrate the defense satellites. It's delicate work but crucial.",
			"speaker": "Station Commander",
			"options": [
				{"text": "I'll get started.", "next": "end", "id": "accept"},
				{"text": "Maybe another time.", "next": "end", "id": "decline"}
			]
		}
	}
	
	set_dialogue_data(dialogue_data)
	
	# Add custom data
	custom_data["population"] = 1247
	custom_data["defense_level"] = "Medium"
	custom_data["services"] = ["Trading Bay", "Repair Dock", "Fuel Station"]
