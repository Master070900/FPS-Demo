extends TextureProgress

const BAR_SPEED:int = 5

var player = null


func _ready(): player = Globals.player


func _process(delta):
	if player == null: player = Globals.player
	else:
		max_value = player.max_health
		value = lerp(value, player.health, BAR_SPEED * delta)
