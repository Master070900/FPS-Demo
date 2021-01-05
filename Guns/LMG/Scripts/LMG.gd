extends Spatial

const h_weight:int = 10 # Stiffness of the gun while moving camera horizontally
const v_weight:int = 10 # Stiffness of the gun while moving camera vertically
const weight:int = 4 # How much the player slows down while holding this gun
const reload_time:float = 3.6 # How long it takes to reload (Independent of reload animation)
const hip_offset:int = 15 # The maximum angle the raycast can rotate when not ads
const inf_ammo:bool = false # Boolean of if the gun has inf ammo or not
const can_aim:bool = true # Boolean of if the gun can aim
const piercing:bool = false # Boolean of if the gun has armor piercing

const hip:Vector3 = Vector3(0.3, -0.35, 0) # Expected position of hand while gun is at hip
const ads:Vector3 = Vector3(0, -0.25, 0) # Expected position of hand while gun is ads

var max_ammo:int = 100 # Maximum ammo the gun has
var ammo:int = max_ammo # The ammo left in mag
var shoot_cooldown:float = .25 # How long in seconds it takes to shoot next bullet
var current_cooldown:float = shoot_cooldown * 5 # Main purpose of this is to give time for anim "ready gun" to play
var damage:float = 35 # How much damage each bullet does

onready var anim = $AnimationPlayer


func setup() -> Array: # This sends the stats of the gun to the player to hold the information locally
	anim.play("ready gun")
	return [ammo, max_ammo, current_cooldown, shoot_cooldown, h_weight, v_weight, damage,
		weight, inf_ammo, hip, ads, hip_offset, can_aim, piercing]


func store(values:Array) -> void: # Stores the values after gun is switched
	ammo = values[0]


func fire(): # Happens every time the gun shoots
	if $AudioStreamPlayer3D.playing: $AudioStreamPlayer3D.stop()
	$AudioStreamPlayer3D.play()
	anim.play("fire")


func reload(): # Just plays the gun reload animation
	anim.play("reload")


