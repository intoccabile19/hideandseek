class_name TerminalInteractable
extends Interactable

@export var target_bridge: NodePath
@export var target_obstacle_1: NodePath
@export var target_obstacle_2: NodePath
@export var target_plate: NodePath

func _ready() -> void:
	super._ready()

func execute_interaction(actor: Node3D) -> void:
	print("[Terminal] Terminal activated by actor: %s" % actor.name)
	SoundManager.play_interact(global_position)
	
	if target_plate:
		var plate := get_node_or_null(target_plate)
		if plate and plate.has_method("disable_plate"):
			plate.call("disable_plate")
			
	if target_bridge:
		var bridge = get_node_or_null(target_bridge)
		if bridge and bridge.has_method("activate"):
			bridge.call("activate")
			
	for path in [target_obstacle_1, target_obstacle_2]:
		if path:
			var obstacle = get_node_or_null(path)
			if obstacle:
				if obstacle.has_method("retract"):
					obstacle.call("retract")
				else:
					# Fallback to direct translation
					obstacle.global_position.y = -5.0
					var col = obstacle.get_node_or_null("CollisionShape3D")
					if col:
						col.disabled = true
					print("[Terminal] Obstacle %s retracted directly!" % obstacle.name)
