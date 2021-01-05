extends Node

var player = null # This is how we get reference to player node


func _process(delta):
	if Input.is_action_just_pressed("alt fire"): player.translate(Vector3(0, 30, 0))
