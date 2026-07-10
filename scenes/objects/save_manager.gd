class_name SaveManager
extends Node

const SAVE_PATH = "user://savegame.json"

## Saves the scene path to user://savegame.json
static func save_level(scene_path: String) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {"current_level": scene_path}
		file.store_string(JSON.stringify(data))
		file.close()
		print("[SaveManager] Game saved. Current level: ", scene_path)

## Loads the scene path from user://savegame.json
static func load_level() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		file.close()
		var json := JSON.new()
		if json.parse(text) == OK:
			var data: Dictionary = json.get_data()
			return data.get("current_level", "")
	return ""

## Returns true if a save game file exists
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
