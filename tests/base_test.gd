# tests/base_test.gd
extends RefCounted
class_name BaseTest

var current_test_name: String = ""
var failed: bool = false
var failure_message: String = ""

# Asserts that two values are equal
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_fail("Expected %s, but got %s. %s" % [str(expected), str(actual), message])

# Asserts that a value is true
func assert_true(actual: bool, message: String = "") -> void:
	if not actual:
		_fail("Expected true, but got false. %s" % [message])

# Asserts that a value is false
func assert_false(actual: bool, message: String = "") -> void:
	if actual:
		_fail("Expected false, but got true. %s" % [message])

# Asserts that two float values are approximately equal
func assert_approx_eq(actual: float, expected: float, margin: float = 0.0001, message: String = "") -> void:
	if abs(actual - expected) > margin:
		_fail("Expected %f (approx %f), but got %f. %s" % [expected, expected, actual, message])

func _fail(message: String) -> void:
	failed = true
	failure_message = message
