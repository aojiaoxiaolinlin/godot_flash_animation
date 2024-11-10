extends Node2D

@onready var swf = $SwfAnimation

func _ready() -> void:
	swf.set_animation("DEA")
	
