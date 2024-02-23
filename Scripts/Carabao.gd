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
	#print(moving)
	if not moving:
		return
		
	# Round each component of the position vector based on decimal value
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
	
	#if reformed == targetPos or \
	#is_point_close_enough(position, targetPos, 0.2):
			
			velocity = Vector2.ZERO
			position = targetPos
			stop_moving.emit()
			play_idle()
			#print("here: ", velocity)
			#
			moving = false
		
	move_and_slide()

func is_point_close_enough(point: Vector2, target: Vector2, margin: float) -> bool:
	return abs(point.x - target.x) <= margin and abs(point.y - target.y) <= margin

func go_towards_target_point(currentAgentPosition, nextPathPosition):
	moving = true
	#print("moving ", moving, " ", currentAgentPosition, " ", nextPathPosition)
	var newVelocity: Vector2 = nextPathPosition - currentAgentPosition
	#print("newVelocity: ", newVelocity)
	targetPos = nextPathPosition
	#print("targetPos: ", targetPos)
	newVelocity = newVelocity.normalized()
	newVelocity = newVelocity * speed
	velocity = newVelocity
	play_run()
	

func play_run():
	anim.play("run")

func play_idle():
	anim.play("idle")
	

	
