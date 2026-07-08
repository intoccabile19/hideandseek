# test_runner.gd
extends SceneTree

const TESTS_DIR = "res://tests/"

func _init() -> void:
	print("=========================================")
	print("Starting Godot Headless Test Runner...")
	print("=========================================")
	
	var test_files: Array[String] = []
	
	# Check if tests directory exists
	if not DirAccess.dir_exists_absolute(TESTS_DIR):
		print("No tests directory found at %s. Exiting." % TESTS_DIR)
		quit(0)
		return
		
	var dir = DirAccess.open(TESTS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".gd") and file_name.begins_with("test_") and file_name != "test_runner.gd":
				test_files.append(TESTS_DIR + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if test_files.is_empty():
		print("No test files found in %s matching 'test_*.gd'." % TESTS_DIR)
		quit(0)
		return
		
	var total_passed = 0
	var total_failed = 0
	var failed_tests: Array[String] = []
	
	for file_path in test_files:
		print("\nRunning suite: %s" % file_path.get_file())
		var script = load(file_path)
		if not script:
			print("  [ERROR] Failed to load test script: %s" % file_path)
			total_failed += 1
			failed_tests.append(file_path + " (Load Error)")
			continue
			
		var instance = script.new()
		if not instance:
			print("  [ERROR] Failed to instantiate test script: %s" % file_path)
			total_failed += 1
			failed_tests.append(file_path + " (Instantiation Error)")
			continue
			
		# Get all methods
		var methods = instance.get_method_list()
		for method in methods:
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				# Reset instance state for this test if inheriting from BaseTest
				if instance.has_method("assert_eq"):
					instance.failed = false
					instance.failure_message = ""
					instance.current_test_name = method_name
				
				# Run before_each if defined
				if instance.has_method("before_each"):
					instance.call("before_each")
				
				# Execute test method
				instance.call(method_name)
				
				# Run after_each if defined
				if instance.has_method("after_each"):
					instance.call("after_each")
				
				# Check results
				var test_failed = false
				var err_msg = ""
				if instance.has_method("assert_eq"):
					test_failed = instance.failed
					err_msg = instance.failure_message
				
				if test_failed:
					print("  [FAIL] %s: %s" % [method_name, err_msg])
					total_failed += 1
					failed_tests.append("%s -> %s: %s" % [file_path.get_file(), method_name, err_msg])
				else:
					print("  [PASS] %s" % method_name)
					total_passed += 1
		
		# Free instance if it's a Node or Object
		if instance is RefCounted:
			pass # Auto-freed
		elif instance is Object:
			instance.free()
			
	print("\n=========================================")
	print("Test Summary:")
	print("Passed: %d" % total_passed)
	print("Failed: %d" % total_failed)
	print("=========================================")
	
	if total_failed > 0:
		print("\nFailed Tests Details:")
		for fail in failed_tests:
			print("  - %s" % fail)
		quit(1)
	else:
		print("All tests completed successfully!")
		quit(0)
