@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("FlashAnimation","Node2d",preload("res://addons/flash_animation/FlashAnimation.gd"),preload("res://addons/flash_animation/flash-file-format-svg.svg"))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type("FlashAnimation")
