extends Node

@onready var clickSound = $ClickSound
@onready var tillSound = $TillSounds


func play_sound(sound: String):
	var stream = null
	
	if sound == "clickSound":
		stream = clickSound
	
	elif sound == "tillSound":
		var sounds = tillSound.get_children()
		var rand = randi() % sounds.size()
		stream = sounds[rand]

	stream.play()

