extends Node2D

signal end_phase(seedNode)

@onready var timer = $Timer

var seedTimer : int

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = seedTimer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func start_timer():
	#print("Starting timer")
	timer.start()


func _on_timer_timeout():
	end_phase.emit(self)
