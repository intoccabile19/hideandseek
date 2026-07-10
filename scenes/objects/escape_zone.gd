class_name EscapeZone
extends Area3D

func _ready() -> void:
	# Enable monitoring to detect the player (Layer 2)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2 # Detect Player (Layer 2)
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		var saved_count: int = FamilyManager.active_members.size()
		var menus := get_tree().get_nodes_in_group("game_state_menus")
		if not menus.is_empty():
			var menu = menus[0]
			if menu.has_method("show_victory"):
				menu.show_victory(saved_count)
				print("[EscapeZone] Player escaped! Counted %d survivors." % saved_count)
