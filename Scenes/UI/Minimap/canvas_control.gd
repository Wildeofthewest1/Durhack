extends CanvasLayer

var minimap_scene: PackedScene = preload("res://Scenes/UI/Minimap/minimap.tscn")
var minimap: Node = null

func _ready() -> void:
	minimap = minimap_scene.instantiate() as Node
	self.add_child(minimap)

	var player_path: NodePath = NodePath("../SubViewportContainer/SubViewport/Game/PlayerContainer/Player")
	var player: Node = get_node(player_path) as Node

	minimap.set("follow_node", player)
