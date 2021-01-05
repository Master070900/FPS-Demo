extends Spatial

const UP_FORCE:int = 15


func _on_Area_body_entered(body) -> void:
	if body.is_in_group("Player"):
		var boost_vec:Vector3 = Vector3.UP * UP_FORCE
		boost_vec += (body.direction * 15)
		
		body.snap = Vector3.ZERO
		body.gravity_vec = boost_vec
