class_name EscapeZone
extends Area3D

var escaped_members: Array[Node3D] = []

func _ready() -> void:
	add_to_group("escape_zones")
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2 # Detect Player & Family Members (Layer 2)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body is FamilyMember:
		if not escaped_members.has(body):
			escaped_members.append(body)
			print("[EscapeZone] %s entered escape zone." % body.name)
		
		# Check if victory criteria is met
		_check_victory_condition()

func _on_body_exited(body: Node3D) -> void:
	if escaped_members.has(body):
		escaped_members.erase(body)
		print("[EscapeZone] %s left escape zone." % body.name)

func _check_victory_condition() -> void:
	# Find player inside
	var player_escaped := false
	for m in escaped_members:
		if m is Player:
			player_escaped = true
			break
			
	if not player_escaped:
		return
		
	# Check if all active family members are inside
	for member in FamilyManager.active_members:
		if is_instance_valid(member) and member.is_inside_tree():
			if not escaped_members.has(member):
				return # Someone is still left behind!
				
	# If we got here, player and all active family members are safely inside!
	var saved_count: int = FamilyManager.active_members.size()
	var menus := get_tree().get_nodes_in_group("game_state_menus")
	if not menus.is_empty():
		var menu = menus[0]
		if menu.has_method("show_victory"):
			menu.show_victory(saved_count)
			print("[EscapeZone] Escape complete! Victory triggered with %d survivors." % saved_count)
