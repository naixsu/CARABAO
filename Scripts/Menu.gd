extends Control

@onready var cb1 = $CB1
@onready var cb2 = $CB2


# Called when the node enters the scene tree for the first time.
func _ready():
	cb1.play("default")
	cb2.play("default")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func play_game():
	var scene = load("res://Scenes/Main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_play_button_pressed():
	play_game()


func _on_fact_button_pressed():
	pass # Replace with function body.


func _on_qui_button_pressed():
	get_tree().quit()
