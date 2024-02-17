extends Node2D

@onready var anim = $AnimatedSprite2D
var pos : Vector2i

# Called when the node enters the scene tree for the first time.
func _ready():
	anim.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
