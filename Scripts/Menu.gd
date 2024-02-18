extends Control

@onready var cb1 = $MenuNode/CB1
@onready var cb2 = $MenuNode/CB2

@onready var cb3 = $FactNode/CB3

@onready var menuNode = $MenuNode
@onready var factNode = $FactNode

@onready var pages = $FactNode/Page/Pages
var pageNumber = 0
var maxPageNumber = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	menuNode.show()
	factNode.hide()
	cb1.play("default")
	cb2.play("default")
	cb3.play("default")
	
	maxPageNumber = pages.get_children().size()
	open_page()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func open_page():
	for page in pages.get_children():
		page.hide()
	pages.get_children()[pageNumber].show()


func play_game():
	var scene = load("res://Scenes/Main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_play_button_pressed():
	AudioManager.play_sound("clickSound")
	play_game()


func _on_fact_button_pressed():
	AudioManager.play_sound("clickSound")
	menuNode.hide() 
	factNode.show()


func _on_qui_button_pressed():
	AudioManager.play_sound("clickSound")
	get_tree().quit()


func _on_back_button_pressed():
	AudioManager.play_sound("clickSound")
	pageNumber -= 1
	if pageNumber < 0:
		pageNumber = maxPageNumber - 1
	open_page()


func _on_next_button_pressed():
	AudioManager.play_sound("clickSound")
	pageNumber += 1
	if pageNumber > maxPageNumber - 1:
		pageNumber = 0
	open_page()


func _on_menu_button_pressed():
	AudioManager.play_sound("clickSound")
	factNode.hide()
	menuNode.show()
