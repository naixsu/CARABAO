extends Node

@onready var clickSound = $ClickSound
@onready var tillSound = $TillSounds
@onready var plantSound = $PlantSounds
@onready var harvestSound = $HarvestSound
@onready var clearSound = $ClearSound


func play_sound(sound: String):
	var stream = null
	
	if sound == "clickSound":
		stream = clickSound
	
	elif sound == "tillSound":
		var sounds = tillSound.get_children()
		var rand = randi() % sounds.size()
		stream = sounds[rand]
	
	elif sound == "plantSound":
		var sounds = plantSound.get_children()
		var rand = randi() % sounds.size()
		stream = sounds[rand]
	
	elif sound == "harvestSound":
		stream = harvestSound
	
	elif sound == "clearSound":
		stream = clearSound
		
	stream.play()

