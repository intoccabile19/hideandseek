# tests/test_example.gd
extends BaseTest

func test_example_math() -> void:
	assert_eq(2 + 2, 4, "Addition should work")
	assert_true(true, "True is true")
