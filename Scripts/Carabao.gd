extends CharacterBody2D

signal stop_moving

@onready var anim = $AnimatedSprite2D
var pos : Vector2i
var speed = 100
var targetPos : Vector2
var moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	play_idle()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Round each component of the position vector based on decimal value
	if not moving:
		return
		
	var x = "%.2f" % position.x
	var y = "%.2f" % position.y
	var splitX = x.split(".")
	var splitY = y.split(".")
	if int(splitX[1]) > 90:
		x = ceil(float(x))
	elif int(splitX[1]) < 10:
		x = floor(float(x))
	
	if int(splitY[1]) > 90:
		y = ceil(float(y))
	elif int(splitY[1]) < 10:
		y = floor(float(y))
	
	var reformed = Vector2(int(x), int(y))
	
	#print(reformed, " : ", targetPos)

	
	if reformed == targetPos or\
		reformed.x - 1 == targetPos.x or reformed.x + 1 == targetPos.x or\
		reformed.y - 1 == targetPos.y or reformed.y + 1 == targetPos.y:
			velocity = Vector2.ZERO
			stop_moving.emit()
			play_idle()
			moving = false
		
	move_and_slide()


func go_towards_target_point(currentAgentPosition, nextPathPosition):
	moving = true
	var newVelocity: Vector2 = nextPathPosition - currentAgentPosition
	targetPos = nextPathPosition
	newVelocity = newVelocity.normalized()
	newVelocity = newVelocity * speed
	velocity = newVelocity
	play_run()
	

func play_run():
	anim.play("run")

func play_idle():
	anim.play("idle")
	

	
