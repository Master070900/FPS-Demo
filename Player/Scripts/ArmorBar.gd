extends TextureProgress

const BAR_SPEED:int = 5

var player = null


func _ready(): player = Globals.player


func _process(delta):
	if player == null: player = Globals.player
	else:
		max_value = player.max_armor
		value = lerp(value, player.armor, BAR_SPEED * delta)
