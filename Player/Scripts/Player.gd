extends KinematicBody

enum STATES { # States player can be in
	GROUNDED,
	MIDAIR,
	TOUCHDOWN
}

onready var GUNS = { # Holds references to all the guns
	AR = $LeanPosition/Head/Hand/AR,
	PISTOL = $LeanPosition/Head/Hand/Pistol,
	LMG = $LeanPosition/Head/Hand/LMG,
	KNIFE = $LeanPosition/Head/Hand/Knife
}

const SPEEDS = { # Stores the speeds of the player
	MOVE = {
		CROUCH = 1,
		WALK = 6,
		RUN = 10
	},
	GROUND_ACCEL = {
		CROUCH = 9,
		WALK = 18,
		RUN = 32
	},
	AIR_ACCEL = {
		CROUCH = 1,
		WALK = 1,
		RUN = 1
	}
}

const LEAN_AMOUNT:int = 30 # How much in deg to lean left or right
const CROUCH_SPEED:int = 10 # How fast you crouch
const FALL_DAMAGE_START:int = 17 # How far you have to fall before you start taking fall damage

var HSWAY:float = 0 # Horizontal sway of gun
var VSWAY:float = 0 # Vertical sway of gun

var state = null # State of Player
onready var gun = GUNS.KNIFE # What gun you have
var gun_setup # This variable is just so we know what gun to store ammo too when we switch guns and to play gun setup

var max_health:float = 100 # Max health of player
var health:float = max_health # Current health of player
var max_armor:float = 50 # Max armor of player (Mainly just so we have a max value on armor bar)
var armor:float = max_armor # Current armor of player
var armor_protection:float = 0.25 # 0.25 # How much damage the armor will take instead of player

var mouse_sens:float = 0.3 # Sensitivity of mouse 
var speed:float = SPEEDS.MOVE.WALK # Variable to change speed depending on buttons being pressed
var accel:float = SPEEDS.AIR_ACCEL.WALK # Variable to change acceleration depending on buttons being pressed
var gravity:float = 12 # Variable of how strong gravity is
var jump:float = 5 # How strong your jump is
var max_height:float = 1.4 # Max height of player (deafult height)
var min_height:float = 0.0 # Min height of player (crouch height)
var height:float = max_height # Current height of player
var visual_height:float = 1 # How much the collision and mesh have to move up to be aligned

var _ammo:int = 0 # Ammo of current gun
var _max_ammo:int = 0 # Max ammo of current gun
var _gun_cooldown:float = 0 # Cooldown left between shots
var _max_gun_cooldown:float = 0 # What to set "_gun_cooldown" after every shot
var _damage:float = 0 # Damage of current gun
var _weight:float = 0 # How much to slow down player depending on what gun you have
var _gun_offset:float = 0 # Angle of raycast when not ads
var _gun_hip:Vector3 = Vector3(0.3, -0.35, 0) # Vector of where gun sets when gun is at hip
var _gun_ads:Vector3 = Vector3(0, -0.35, 0) # Vector of where gun sets when ads
var _inf_ammo:bool = false # Boolean of weather current gun has inf ammo
var _can_aim:bool = true # Boolean of weather current gun can aim
var _piercing:bool = false # Boolean of weather current gun can pierce through armor
var _reloading:bool = false # Boolean of weather current gun is reloading

var direction = Vector3.ZERO # direction that you are trying to move
var h_vel:Vector3 = Vector3.ZERO # direction * speed
var gravity_vec:Vector3 = Vector3.ZERO # Vector that applies jumping and gravity
var snap:Vector3 = Vector3.DOWN # Where the player collisions snaps to ground
var motion:Vector3 = Vector3.ZERO # Final input to move player

onready var collision_shape = $CollisionShape
onready var mesh = $MeshInstance

onready var lean_pivot = $LeanPosition
onready var head = $LeanPosition/Head
onready var camera = $LeanPosition/Head/Camera
onready var hand = $LeanPosition/Head/Hand
onready var hand_position = $LeanPosition/Head/HandPosition


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Make cursor invisible and stay in center of screen
	hand.set_as_toplevel(true) # Allows for hand to wiggle
	Globals.player = self # Allows for other nodes to know we are the player


func _input(event):
	if event is InputEventMouseMotion:
		# Rotate player based on mouse motion
		rotate_y(deg2rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))


func _process(delta):
	if gun != null:
		# What to do while ads
		if Input.is_action_pressed("alt fire") and not _reloading and _can_aim:
			hand_position.transform.origin = hand_position.transform.origin.linear_interpolate(
				_gun_ads, (HSWAY/2) * delta)
			var gun_rot_diff = Vector3( # This is getting the difference in angle so shots are more realistic
				hand.rotation.x - head.rotation.x,
				hand.rotation.y - rotation.y,
				hand.rotation.z - head.rotation.z)
			camera.find_node("Cast").rotation = gun_rot_diff
		# What to do when not ads
		else:
			hand_position.transform.origin = hand_position.transform.origin.linear_interpolate(
				_gun_hip, (HSWAY/2) * delta)
			var y_offset = rand_range(-_gun_offset, _gun_offset)
			var x_offset = rand_range(-_gun_offset, _gun_offset)
			var vec_offset = Vector3(x_offset, y_offset, 0)
			vec_offset += Vector3( # This is getting the difference in angle so shots are more realistic
				hand.rotation.x - head.rotation.x,
				hand.rotation.y - rotation.y,
				hand.rotation.z - head.rotation.z)
			camera.find_node("Cast").rotation = vec_offset
	# Make hand approach the correct position of hand
	hand.global_transform.origin = hand_position.global_transform.origin
	hand.rotation.y = lerp_angle(hand.rotation.y, rotation.y, HSWAY * delta)
	hand.rotation.x = lerp_angle(hand.rotation.x, head.rotation.x, VSWAY * delta)
	hand.rotation.z = lerp_angle(hand.rotation.z, lean_pivot.rotation.z, (LEAN_AMOUNT/2) * delta)
	
	# Lean player if pressing lean buttons (Q and E)
	var lean_direction = Input.get_action_strength("lean right") - Input.get_action_strength("lean left")
	lean_direction = -sign(lean_direction)
	
	var lean_rot = lerp_angle(lean_pivot.rotation.z, deg2rad(lean_direction * LEAN_AMOUNT), (LEAN_AMOUNT/2) * delta)
	
	lean_pivot.rotation.z = lean_rot
	
	# Make player height crouched or un-crouched
	var crouch_direction = -1 * ((int(Input.is_action_pressed("crouch")) * 2) - 1) # Make it -1 or 1
	
	mesh.mesh.mid_height += crouch_direction * CROUCH_SPEED * delta
	mesh.mesh.mid_height = clamp(mesh.mesh.mid_height, min_height, max_height)
	collision_shape.shape.height = mesh.mesh.mid_height
	
	var height_diff = max_height - min_height
	var current_height_diff = max_height - mesh.mesh.mid_height
	var crouch_progress = current_height_diff/height_diff
	
	mesh.translation.y = visual_height-(current_height_diff/2)
	collision_shape.translation.y = mesh.translation.y
	
	lean_pivot.translation.y = visual_height - ((crouch_progress * height_diff)/2)
	head.translation.y = lean_pivot.translation.y


func _physics_process(delta):
	# Get player input and make it normalized
	direction = Vector3.ZERO
	direction += transform.basis.z * -(Input.get_action_strength("forwards") - Input.get_action_strength("backwards"))
	direction += transform.basis.x * (Input.get_action_strength("right") - Input.get_action_strength("left"))
	direction = direction.normalized()
	
	# Sets speed of player based on input
	if Input.is_action_pressed("crouch"): speed = SPEEDS.MOVE.CROUCH
	else: speed = SPEEDS.MOVE.RUN if Input.is_action_pressed("sprint") else SPEEDS.MOVE.WALK
	
	# Gravity/Jumping
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		if Input.is_action_pressed("crouch"): accel = SPEEDS.AIR_ACCEL.CROUCH
		else: accel = SPEEDS.AIR_ACCEL.RUN if Input.is_action_pressed("sprint") else SPEEDS.AIR_ACCEL.WALK
		state = STATES.MIDAIR
	elif Input.is_action_just_pressed("jump"):
		gravity_vec = Vector3.UP * jump
		snap = Vector3.ZERO
		state = STATES.MIDAIR
	else:
		if state == STATES.MIDAIR:
			if gravity_vec.y < -FALL_DAMAGE_START:
				# Piercing is true because we want to deal damage regardless of armor
				deal_damage((2 * ((-gravity_vec.y)-FALL_DAMAGE_START)), true)
		state = STATES.GROUNDED
		gravity_vec = -get_floor_normal()
		snap = -get_floor_normal()
		if Input.is_action_pressed("crouch"): accel = SPEEDS.GROUND_ACCEL.CROUCH
		else: accel = SPEEDS.GROUND_ACCEL.RUN if Input.is_action_pressed("sprint") else SPEEDS.GROUND_ACCEL.WALK
	
	# Interpolate h_vel to where player should move and make motion equal the sum of h_vel and gravity_vec
	h_vel = h_vel.linear_interpolate(direction * max(1, (speed - _weight)), accel * delta)
	motion = h_vel + gravity_vec
	
	# Move player
	motion = move_and_slide_with_snap(motion, snap, Vector3.UP, true, 4, deg2rad(46), false)
	
	# Do gun related things
	gun_physics(delta)


# Extra scripting functions


func gun_physics(delta:float) -> void:
	# Make every gun invisible (We'll make the current gun visibile later)
	for child in hand.get_children():
		child.visible = false
	
	# Reloading of current gun
	if gun != null:
		if Input.is_action_just_pressed("reload") and not _inf_ammo and _ammo < _max_ammo:
			_reloading = true
			gun.reload()
			yield(get_tree().create_timer(gun.reload_time), "timeout")
			_ammo = _max_ammo
			_reloading = false
	
	# Find what gun player is holding and do physics of that gun
	match gun:
		GUNS.AR:
			# Make current gun visibile
			gun.visible = true
			
			# Check if the current gun just got picked up
			var new_info:Array
			if gun_setup != gun:
				if gun_setup != null: gun_setup.store([_ammo])
				gun_setup = gun
				new_info = gun.setup()
			
			# If current gun just got picked up, set local variables to that value
			if new_info:
				_ammo = new_info[0]
				_max_ammo = new_info[1]
				_gun_cooldown = new_info[2]
				_max_gun_cooldown = new_info[3]
				HSWAY = new_info[4]
				VSWAY = new_info[5]
				_damage = new_info[6]
				_weight = new_info[7]
				_inf_ammo = new_info[8]
				_gun_hip = new_info[9]
				_gun_ads = new_info[10]
				_gun_offset = deg2rad(new_info[11])
				_can_aim = new_info[12]
				_piercing = new_info[13]
			
			# Lower gun cooldown by the time from last frame and this frame
			_gun_cooldown -= delta
			
			# Do firing and collisions of bullet
			if Input.is_action_pressed("fire") and _gun_cooldown <= 0 and _ammo > 0 and not _reloading:
				_gun_cooldown = _max_gun_cooldown
				if not _inf_ammo: _ammo -= 1
				gun.fire()
				var cast = camera.get_child(0).find_node("ARcast")
				if cast.is_colliding():
					var collider = cast.get_collider()
					if collider.is_in_group("Shootable"):
						if collider.is_in_group("Enemy"):
							collider.deal_damage(_damage, _piercing)
			
		
		
		GUNS.PISTOL:
			# Make current gun visibile
			gun.visible = true
			
			# Check if the current gun just got picked up
			var new_info:Array
			if gun_setup != gun:
				if gun_setup != null: gun_setup.store([_ammo])
				gun_setup = gun
				new_info = gun.setup()
			
			# If current gun just got picked up, set local variables to that value
			if new_info:
				_ammo = new_info[0]
				_max_ammo = new_info[1]
				_gun_cooldown = new_info[2]
				_max_gun_cooldown = new_info[3]
				HSWAY = new_info[4]
				VSWAY = new_info[5]
				_damage = new_info[6]
				_weight = new_info[7]
				_inf_ammo = new_info[8]
				_gun_hip = new_info[9]
				_gun_ads = new_info[10]
				_gun_offset = deg2rad(new_info[11])
				_can_aim = new_info[12]
				_piercing = new_info[13]
			
			# Lower gun cooldown by the time from last frame and this frame
			_gun_cooldown -= delta
			
			# Do firing and collisions of bullet
			if Input.is_action_just_pressed("fire") and _gun_cooldown <= 0 and _ammo > 0 and not _reloading:
				_gun_cooldown = _max_gun_cooldown
				if not _inf_ammo:_ammo -= 1
				gun.fire()
				var cast = camera.get_child(0).find_node("PistolCast")
				if cast.is_colliding():
					var collider = cast.get_collider()
					if collider.is_in_group("Shootable"):
						if collider.is_in_group("Enemy"):
							collider.deal_damage(_damage, _piercing)
			
		
		
		GUNS.LMG:
			# Make current gun visibile
			gun.visible = true
			
			# Check if the current gun just got picked up
			var new_info:Array
			if gun_setup != gun:
				if gun_setup != null: gun_setup.store([_ammo])
				gun_setup = gun
				new_info = gun.setup()
			
			# If current gun just got picked up, set local variables to that value
			if new_info:
				_ammo = new_info[0]
				_max_ammo = new_info[1]
				_gun_cooldown = new_info[2]
				_max_gun_cooldown = new_info[3]
				HSWAY = new_info[4]
				VSWAY = new_info[5]
				_damage = new_info[6]
				_weight = new_info[7]
				_inf_ammo = new_info[8]
				_gun_hip = new_info[9]
				_gun_ads = new_info[10]
				_gun_offset = deg2rad(new_info[11])
				_can_aim = new_info[12]
				_piercing = new_info[13]
			
			# Lower gun cooldown by the time from last frame and this frame
			_gun_cooldown -= delta
			
			# Do firing and collisions of bullet
			if Input.is_action_pressed("fire") and _gun_cooldown <= 0 and _ammo > 0 and not _reloading:
				_gun_cooldown = _max_gun_cooldown
				if not _inf_ammo:_ammo -= 1
				gun.fire()
				var cast = camera.get_child(0).find_node("LMGcast")
				if cast.is_colliding():
					var collider = cast.get_collider()
					if collider.is_in_group("Shootable"):
						if collider.is_in_group("Enemy"):
							collider.deal_damage(_damage, _piercing)
			
		
		
		GUNS.KNIFE:
			# Make current gun visibile
			gun.visible = true
			
			# Check if the current gun just got picked up
			var new_info:Array
			if gun_setup != gun:
				if gun_setup != null: gun_setup.store([_ammo])
				gun_setup = gun
				new_info = gun.setup()
			
			# If current gun just got picked up, set local variables to that value
			if new_info:
				_ammo = new_info[0]
				_max_ammo = new_info[1]
				_gun_cooldown = new_info[2]
				_max_gun_cooldown = new_info[3]
				HSWAY = new_info[4]
				VSWAY = new_info[5]
				_damage = new_info[6]
				_weight = new_info[7]
				_inf_ammo = new_info[8]
				_gun_hip = new_info[9]
				_gun_ads = new_info[10]
				_gun_offset = deg2rad(new_info[11])
				_can_aim = new_info[12]
				_piercing = new_info[13]
			
			# Lower gun cooldown by the time from last frame and this frame
			_gun_cooldown -= delta
			
			# Do firing and collisions of bullet
			if Input.is_action_pressed("fire") and _gun_cooldown <= 0 and _ammo > 0 and not _reloading:
				_gun_cooldown = _max_gun_cooldown
				if not _inf_ammo:_ammo -= 1
				gun.fire()
				var cast = camera.get_child(0).find_node("KnifeCast")
				for body in cast.get_overlapping_bodies():
					if body.is_in_group("Shootable"):
						if body.is_in_group("Enemy"):
							body.deal_damage(_damage, _piercing)
			
		
		
		null: # This is if you have no gun, or just drop your gun
			if gun_setup != gun:
				if gun_setup != null: gun_setup.store([_ammo])
				gun_setup = gun
			


func deal_damage(damage:float, piercing:bool = false) -> void: # How we will deal damage to player
	if piercing: #                                                Same as Enemy damaging system
		health -= damage
		return
	
	var protected_amount = armor_protection * damage
	var unprotected_amount = (1-armor_protection) * damage
	
	armor -= protected_amount
	if armor < 0:
		unprotected_amount += -armor
		armor = 0
	
	health -= unprotected_amount
	

