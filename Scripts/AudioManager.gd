extends Node

@onready var clickSound = $ClickSound
@onready var tillSound = $TillSounds
@onready var plantSound = $PlantSounds
@onready var harvestSound = $HarvestSound
@onready var clearSound = $ClearSound
@onready var endSound = $EndSound
@onready var cowSound = $CowSounds
@onready var moveSound = $MoveSounds

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
	
	elif sound == "endSound":
		stream = endSound
	
	elif sound == "cowSound":
		var sounds = cowSound.get_children()
		var rand = randi() % sounds.size()
		stream = sounds[rand]
	
	elif sound == "moveSound":
		var sounds = moveSound.get_children()
		var rand = randi() % sounds.size()
		stream = sounds[rand]
		
	stream.play()

