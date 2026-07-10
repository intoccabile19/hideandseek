class_name EscapeZone
extends Area3D

var escaped_members: Array[Node3D] = []

@export_file("*.tscn") var next_level_path: String = ""

func _ready() -> void:
	add_to_group("escape_zones")
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 6 # Detect Player (Layer 2) & Family Members (Layer 3)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body is FamilyMember:
		if not escaped_members.has(body):
			escaped_members.append(body)
			print("[EscapeZone] %s entered escape zone. Total inside: %d" % [body.name, escaped_members.size()])
		
		# Check if victory criteria is met
		_check_victory_condition()

func _on_body_exited(body: Node3D) -> void:
	if escaped_members.has(body):
		escaped_members.erase(body)
		print("[EscapeZone] %s left escape zone. Total inside: %d" % [body.name, escaped_members.size()])

func _check_victory_condition() -> void:
	# Find player inside
	var player_escaped := false
	for m in escaped_members:
		if m is Player:
			player_escaped = true
			break
			
	if not player_escaped:
		print("[EscapeZone] Victory check: Player has not entered the escape zone yet.")
		return
		
	# Check if all active family members are inside
	for member in FamilyManager.active_members:
		if is_instance_valid(member) and member.is_inside_tree():
			if not escaped_members.has(member):
				print("[EscapeZone] Victory check: Waiting for %s to enter the escape zone." % member.name)
				return # Someone is still left behind!
				
	# If we got here, player and all active family members are safely inside!
	var saved_count: int = FamilyManager.active_members.size()
	if next_level_path != "":
		SaveManager.save_level(next_level_path)
		get_tree().change_scene_to_file(next_level_path)
		print("[EscapeZone] Level complete! Transitioning to: %s" % next_level_path)
	else:
		var menus := get_tree().get_nodes_in_group("game_state_menus")
		if not menus.is_empty():
			var menu = menus[0]
			if menu.has_method("show_victory"):
				menu.show_victory(saved_count)
				print("[EscapeZone] Escape complete! Victory triggered with %d survivors." % saved_count)
