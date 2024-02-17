extends TileMap

@onready var hoeButton = $"../HoeButton"
@onready var carabaoButton = $"../CarabaoButton"
@onready var randomButton = $"../RandomButton"
@onready var plantButton = $"../PlantButton"


@export var CarabaoScene : PackedScene


var gridSize = 5
var tileDict = {}

var rows = 11
var cols = 20

var tile : Vector2
var carabaoSpawned : bool = false

var mainCarabao : Node2D


enum State {
	SETUP, # 0
	TILLING, # 1
	CARABAO, # 2
	PLANTING, # 3
	HARVESTING, # 4
	GAMEOVER # 5
}

var currentState = State.SETUP : set = set_state

# This var is dependent on the tile IDs in TileMap
# DO NOT CHANGE
var tilemapTiles = {
	"grass": 0,
	"hover": 1,
	"tilled": 2,
	"grassTiles": 3,
	"tilledTiles": 4,
	"plantTiles": 5
}

var tilemapLayers = {
	"grass": 0,
	"hover": 1,
	"tilled": 2,
	"plant": 3,
}

func _ready():
	# Init
	# Godot does cols first
	init()
	
	
func _process(_delta):
	tile = local_to_map(get_global_mouse_position())

	erase_hover_tiles()
	hover_tile()


func _input(event):
	# Click to till
	if event.is_action_pressed("Click"):
		if currentState == State.TILLING:
			set_tile(tile, "tilled")
		elif currentState == State.CARABAO:
			set_tile(tile, "carabao")
	if event.is_action_pressed("RClick"):
		set_tile(tile, "grass")

func set_tile(pos: Vector2, type: String):
	if not tileDict.has(str(tile)):
		return
		
	var tileObj = tileDict[str(pos)]
	
	if type == "tilled" and currentState == State.TILLING: # till tile
		if tileObj.isOuter:
			return
			
		tileObj.isTilled = true
		set_cell(tilemapLayers["tilled"], pos, tilemapTiles["tilledTiles"], Vector2i(1, 1), 0)
		check_tilled_dict()
	
	elif type == "carabao" and currentState == State.CARABAO: # put carabao
		if not carabaoSpawned:
			var carabao = CarabaoScene.instantiate()
			mainCarabao = carabao
			mainCarabao.position = map_to_local(tile)
			
			var root = get_tree().get_root()
			var main = root.get_node("Main")
			main.add_child(mainCarabao)
			carabaoSpawned = true
		else:
			mainCarabao.position = map_to_local(tile)
		
		plantButton.disabled = false
		
		
	elif type == "seed":
		tileObj.isSeed = true
		
	elif type == "grow":
		tileObj.isGrown = true
		
	elif type == "grass" and currentState == State.TILLING: # untill tile
		if tileObj.isTilled and not tileObj.isSeed:
			erase_cell(tilemapLayers["tilled"], tile)
			tileObj.isTilled = false
			check_tilled_dict()
	
	print(tileObj)


func check_tilled_dict():
	var count = 0

	for tileData in tileDict.values():
		if tileData["isTilled"]:
			count += 1

	if count > 0:
		carabaoButton.disabled = false
	else:
		carabaoButton.disabled = true


func set_state(newState):
	if newState == currentState:
		return
	
	currentState = newState
	print("state changed: ", currentState)
	
	disable_button_on_state()
	

func disable_button_on_state():
	match currentState:
		State.SETUP:
			#hoeButton.disabled = true
			plantButton.disabled = true
			carabaoButton.disabled = true
			#randomButton.disabled = true
			
		State.TILLING:
			if not carabaoSpawned:
				carabaoButton.disabled = true
			plantButton.disabled = true
		
		State.PLANTING:
			hoeButton.disabled = true
			plantButton.disabled = true
			carabaoButton.disabled = true
			randomButton.disabled = true
			
		State.CARABAO:
			plantButton.disabled = true
		

func erase_hover_tiles():
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			
			erase_tile(1, pos)


func erase_tile(layer: int, pos: Vector2):
	erase_cell(layer, pos)


func hover_tile():
	if currentState == State.SETUP or currentState == State.PLANTING:
		return
		
	if tileDict.has(str(tile)):
		var tileObj = tileDict[str(tile)]
		if not tileObj.isSeed and not tileObj.isOuter:
			set_cell(1, tile, tilemapTiles["hover"], Vector2i(0, 0), 0)


func init_set_tile(pos: Vector2, atlas: Vector2i, isOuter: bool):
	tileDict[str(pos)] = {
		"pos": pos,
		"isOuter": isOuter,
		"isSeed": false,
		"isGrown": false,
		"isTilled": false
	}
	set_cell(0, pos, tilemapTiles["grassTiles"], atlas, 0)


func init():
	disable_button_on_state()
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			var atlas = Vector2i(1, 1)
			var isOuter = false
			
			if row == 1:
				if col == 1:
					atlas = Vector2i(0, 0)
					isOuter = true
				elif col == 18:
					atlas = Vector2i(2, 0)
					isOuter = true
				else:
					atlas = Vector2i(1, 0)
					isOuter = true
			
			elif row == 8:
				if col == 1:
					atlas = Vector2i(0, 2)
					isOuter = true
				elif col == 18:
					atlas = Vector2i(2, 2)
					isOuter = true
				else:
					atlas = Vector2i(1, 2)
					isOuter = true
			
			if col == 1:
				if row >= 2 and row <= 7:
					atlas = Vector2i(0, 1)
					isOuter = true
					
			elif col == 18:
				if row >= 2 and row <= 7:
					atlas = Vector2i(2, 1)
					isOuter = true
				
			if not isOuter:
				if randf() < 0.25:
					#  chance of generating random coordinates 
					# in the ranges (0, 5) to (5, 5) or (0, 6) to (5, 6)"
					var ranX = randi() % 6
					var ranY = randi() % 2 + 5
					atlas = Vector2i(ranX, ranY)

			init_set_tile(pos, atlas, isOuter)

	#set_state(State.TILLING)


func _on_plant_button_pressed():
	set_state(State.PLANTING)


func _on_hoe_button_pressed():
	set_state(State.TILLING)


func _on_carabao_button_pressed():
	set_state(State.CARABAO)


func _on_random_button_pressed():
	pass
