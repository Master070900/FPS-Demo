extends KinematicBody

const SPEEDS = {
	MOVE = {
		WALK = 10,
		RUN = 20
	},
	GROUND_ACCEL = {
		WALK = 20,
		RUN = 40
	},
	AIR_ACCEL = {
		WALK = 2,
		RUN = 2
	}
}

var mouse_sens:float = 0.3
var speed:float = SPEEDS.MOVE.WALK
var accel:float = SPEEDS.AIR_ACCEL.WALK
var gravity:float = 9.8
var jump:float = 5

var direction = Vector3.ZERO
var h_vel:Vector3 = Vector3.ZERO
var gravity_vec:Vector3 = Vector3.ZERO
var snap:Vector3 = Vector3.DOWN
var motion:Vector3 = Vector3.ZERO

onready var head = $Head


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))


func _physics_process(delta):
	direction = Vector3.ZERO
	direction += transform.basis.z * -(Input.get_action_strength("forwards") - Input.get_action_strength("backwards"))
	direction += transform.basis.x * (Input.get_action_strength("right") - Input.get_action_strength("left"))
	direction = direction.normalized()
	
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
	elif Input.is_action_just_pressed("jump"):
		gravity_vec = Vector3.UP * jump
		snap = Vector3.ZERO
	else:
		gravity_vec = -get_floor_normal()
		snap = -get_floor_normal()
	
	h_vel = motion
	h_vel.y = 0
	h_vel = h_vel.linear_interpolate(direction * speed, accel * delta)
	motion = h_vel + gravity_vec
	motion.y = gravity_vec.y
	
	motion = move_and_slide_with_snap(motion, snap, Vector3.UP, true, 4, deg2rad(46), false)
