extends Spatial

export(int, 0, 3) var gun_index = 0 # Index of gun to spawn
export(float) var mid_height = 1 # How high the middle is
export(float) var extend = 0.25 # How far from mid to tween gun
export(float) var speed = 1 # How fast animation should play

var height = 0 # Height gun should be at

onready var gun_hold = $GunHold
onready var offset = $GunHold/Offset

onready var GUNS = { # Preloads the guns to instance one later
	AR = preload("res://Guns/Assault Rifle/AR.tscn"),
	PISTOL = preload("res://Guns/Pistol/Pistol.tscn"),
	LMG = preload("res://Guns/LMG/LMG.tscn"),
	KNIFE = preload("res://Guns/Knife/Knife.tscn")
}


func _ready():
	for child in offset.get_children(): # Resets default guns in offset node
		child.queue_free()
	
	match gun_index: # Instances gun based on gun_index
		0:
			var gun = GUNS.AR.instance()
			gun.transform.origin = offset.transform.origin
			offset.add_child(gun)
		1:
			var gun = GUNS.PISTOL.instance()
			gun.transform.origin = offset.transform.origin
			offset.add_child(gun)
		2:
			var gun = GUNS.LMG.instance()
			gun.transform.origin = offset.transform.origin
			offset.add_child(gun)
		3:
			var gun = GUNS.KNIFE.instance()
			gun.transform.origin = offset.transform.origin
			offset.add_child(gun)


func _process(delta):
	# Make height tween between -extend and extend, then add mid_height
	height += speed * delta
	
	var set_height = (sin(height * PI)) * extend
	
	set_height += mid_height
	
	# Set height and rotation of gun
	gun_hold.translation.y = set_height
	gun_hold.rotation.y = height

func _on_Area_body_entered(body): # Make player pick up gun based on gun_index
	queue_free()
	if body.is_in_group("Player"):
		match gun_index:
			0: body.gun = body.GUNS.AR
			1: body.gun = body.GUNS.PISTOL
			2: body.gun = body.GUNS.LMG
			3: body.gun = body.GUNS.KNIFE
