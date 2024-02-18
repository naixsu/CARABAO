extends Node

@onready var clickSound = $ClickSound


func play_sound(sound: String):
	var stream = null
	
	if sound == "clickSound":
		stream = clickSound

	stream.play()

