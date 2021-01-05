extends Enemy

const MOVE_SPEED:float = 1.0
const ACCEL_SPEED:float = 5.0
const GRAVITY:int = 12

var snap = Vector3.ZERO
var gravity_vec:Vector3 = Vector3.ZERO
var h_vel:Vector3 = Vector3.ZERO
var motion:Vector3 = Vector3.ZERO

var player = null


func _ready():
	override_ready() # This sets our group to "Enemy" so we don't have to
	player = get_player()
	# Order: Health, Max Health, Armor, Armor Protection (View Enemy.gd for more details)
	set_stats(100, 100, INF, 0.75)


func _physics_process(delta):
	if player == null: get_player()
	if player != null:
		var player_position = player.transform.origin
		
		player_position.y = translation.y
		
		look_at(player_position, Vector3.UP)
		
		var move_direction = player_position - transform.origin
		
		move_direction = (move_direction.normalized()) * MOVE_SPEED
		
		# Gravity/Jumping
		if not is_on_floor():
			gravity_vec += Vector3.DOWN * GRAVITY * delta
		else:
			gravity_vec = -get_floor_normal()
			snap = -get_floor_normal()
		
		h_vel = h_vel.linear_interpolate(move_direction * max(1, MOVE_SPEED), ACCEL_SPEED * delta)
		motion = h_vel + gravity_vec
		
		# Move player
		motion = move_and_slide_with_snap(motion, snap, Vector3.UP, true, 4, deg2rad(46), false)
	
	check_health()
