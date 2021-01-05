extends KinematicBody
class_name Enemy

var max_health:float = 1
var health:float = max_health
var armor:float = 0
var armor_protection:float = 0


func override_ready() -> void: # We call this function if we override the ready function (We do)
	self.add_to_group("Shootable")
	self.add_to_group("Enemy")


func get_player(): # Gets the player for us
	return Globals.player


func set_stats(health:float, max_health:float, armor:float, armor_protection:float) -> void:
	self.health = health
	self.max_health = max_health
	self.armor = armor
	self.armor_protection = armor_protection


func deal_damage(damage:float, piercing:bool = false) -> void:
	if piercing:
		health -= damage
		return
	
	var protected_amount = armor_protection * damage
	var unprotected_amount = (1-armor_protection) * damage
	
	armor -= protected_amount
	if armor < 0:
		unprotected_amount += -armor
		armor = 0
	
	health -= unprotected_amount
	


func check_health() -> void:
	if health <= 0:
		queue_free()
