extends TileMap

@onready var hoeButton = $"../HoeButton"
@onready var carabaoButton = $"../CarabaoButton"
@onready var randomButton = $"../RandomButton"
@onready var plantButton = $"../PlantButton"


@export var CarabaoScene : PackedScene


var gridSize = 5
var tileDict = {}
var newTileDict = {}
var overlayTiles = []
var newOverlayTiles = []
var radius = 0
var tilledCount = 0
var lookTime = .2

var rows = 11
var cols = 20

var tile : Vector2
var carabaoSpawned : bool = false

var mainCarabao : Node2D

var randomTilledChance : float = 0.40


enum State {
	SETUP, # 0
	TILLING, # 1
	CARABAO, # 2
	PLANTING, # 3
	HARVESTING, # 4
	RANDOM, # 5
	LOOKING, # 6
	MOVING, # 7
	GAMEOVER # 8
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
	"plantTiles": 5,
	"overlay": 6
}

var tilemapLayers = {
	"grass": 0,
	"hover": 1,
	"tilled": 2,
	"plant": 3,
	"overlay": 4
}

func _ready():
	# Init
	# Godot does cols first
	init()
	
	
func _process(_delta):
	tile = local_to_map(get_global_mouse_position())

	erase_layer_tiles(tilemapLayers["hover"])
	hover_tile()
	
	#if carabaoSpawned:
		#print(local_to_map(mainCarabao.position))


func _input(event):
	# Click to till
	if event.is_action_pressed("Click"):
		if currentState == State.TILLING:
			set_tile(tile, "tilled", true)
		elif currentState == State.CARABAO:
			set_tile(tile, "carabao", true)
	if event.is_action_pressed("RClick"):
		set_tile(tile, "grass", true)


func plant_tiles():
	# set newDict tiles
	for tileData in tileDict.values():
		if not tileData.isOuter:
			newTileDict[str(tileData.pos)] = tileData
	
	#for t in newTileDict.values():
		#print(t)
	
	print(mainCarabao.pos)
	print("tilledCount: ", tilledCount)
	look_for_tiles()


func calculate_travel_time(start: Vector2, end: Vector2, speed: float) -> float:
	var distance = start.distance_to(end)
	var time = distance / speed
	return time + 1


func stop_moving():
	var t = local_to_map(mainCarabao.position)
	print("Stop moving: ", t)
	var tileObj = newTileDict[str(t)]
	if newTileDict[str(t)].isTilled:
		print("Tilling tile: ", t)
		newTileDict[str(t)].isSeed = true
		mainCarabao.pos = t
		move_carabao(t)
		tilledCount -= 1
	
	if tilledCount > 0:
		look_for_tiles()


func move_to(t: Vector2i):
	set_state(State.MOVING)
	# move carabao from mainCarabao.pos to t
	var targetPosition = map_to_local(t)
	print(targetPosition)

	#var tween = create_tween()
	##tween.tween_property(mainCarabao, "position", Vector2(mainCarabao.pos.x, mainCarabao.pos.y), 1)
	#var time = calculate_travel_time(mainCarabao.pos, t, mainCarabao.speed)
	#print("TIME: ", time)
	#tween.tween_property(mainCarabao, "position", Vector2(target_position.x, target_position.y), time)
	#mainCarabao.play_run()
	mainCarabao.go_towards_target_point(mainCarabao.position, targetPosition)
	
	
	

func check_for_tilled():
	print("Checking for tilled tiles among overlays")
	for t in overlayTiles:
		if newTileDict[str(t)].isTilled and not newTileDict[str(t)].isSeed:
			radius = 0
			overlayTiles = []
			newOverlayTiles = []
			move_to(t)

	
	
func look_for_tiles():
	await get_tree().create_timer(lookTime).timeout
	set_state(State.LOOKING)
	radius += 1
	print("Looking for tiles with radius: ", radius)
	erase_layer_tiles(tilemapLayers["overlay"])
	
	set_tile(mainCarabao.pos, "overlay", false)
	
	if radius == 1:
		overlayTiles.append(mainCarabao.pos)
		check_for_tilled()
		if currentState == State.LOOKING:
			look_for_tiles()
		return
		
	newOverlayTiles = []
	
	for tilePos in overlayTiles:
		#print(tilePos)
		# Add the current tile to the list
		newOverlayTiles.append(tilePos)
		
		# Get the neighbors (up, down, left, right) of the current tile
		var neighbors = [
			tilePos + Vector2i(0, -1),  # Up
			tilePos + Vector2i(0, 1),   # Down
			tilePos + Vector2i(-1, 0),  # Left
			tilePos + Vector2i(1, 0)    # Right
		]
		
		# Add the neighbors to the list
		for neighbor in neighbors:
			if neighbor.y > 7 or neighbor.y < 2 or\
				neighbor.x > 17 or neighbor.x < 2:
					#print("Out of bounds: ", neighbor)
					continue
			if neighbor not in newOverlayTiles:
				newOverlayTiles.append(neighbor)
				set_tile(neighbor, "overlay", false)
	
	#print(newOverlayTiles)
	overlayTiles = newOverlayTiles
	check_for_tilled()
	
	if currentState == State.LOOKING:
		look_for_tiles()

func set_tile(pos: Vector2, type: String, click: bool):
	if click and not tileDict.has(str(tile)):
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
			spawn_carabao(tile)
		else:
			#mainCarabao.position = map_to_local(tile)
			move_carabao(tile)
		
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
	
	elif type == "overlay" and not tileDict[str(pos)].isOuter \
		and currentState == State.LOOKING: # planting
			set_cell(tilemapLayers["overlay"], pos, tilemapTiles["overlay"], Vector2i(0, 0), 0)
	
	#print("set tile: ", tileObj)


func distance_to_carabao(pos: Vector2i):
	return mainCarabao.pos.distance_squared_to(pos)


func move_carabao(pos: Vector2i):
	mainCarabao.position = map_to_local(pos)
	mainCarabao.pos = pos
	
	print("Carabao moved to: ", mainCarabao.position, " : ", mainCarabao.pos)


func spawn_carabao(pos: Vector2i):
	var carabao = CarabaoScene.instantiate()
	mainCarabao = carabao
	
	move_carabao(pos)
	
	var root = get_tree().get_root()
	var main = root.get_node("Main")
	main.add_child(mainCarabao)
	mainCarabao.connect("stop_moving", stop_moving)
	carabaoSpawned = true


func check_tilled_dict():
	var count = 0

	for tileData in tileDict.values():
		if tileData.isTilled:
			count += 1
			
	tilledCount = count
	
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
			if tilledCount > 0:
				plantButton.disabled = false
			else:
				plantButton.disabled = true

		State.RANDOM:
			hoeButton.disabled = false
			#plantButton.disabled = false
			carabaoButton.disabled = false
			randomButton.disabled = false


func clear_tiles():
	# Clear all tilled tiles
	erase_layer_tiles(tilemapLayers["tilled"])
	
	# Set isTilled on all tiles to false
	for tileData in tileDict.values():
		tileData.isTilled = false
		tileData.isSeed = false
		tileData.isGrown = false
	
	if carabaoSpawned:
		carabaoSpawned = false
		mainCarabao.queue_free()


func random_place():
	# Random till
	set_state(State.TILLING)
	
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			
			if randf() < randomTilledChance:
				set_tile(pos, "tilled", false)
	

	
	# Carabao process
	carabaoSpawned = false
	
	while not carabaoSpawned:
		var randomTile = tileDict.keys()[randi() % tileDict.size()]
		
		if not tileDict[str(randomTile)].isOuter:
			#mainCarabao.position = map_to_local(Vector2())
			randomTile = tileDict[str(randomTile)].pos
			var coords = Vector2i(randomTile)
			
			if mainCarabao == null:
				spawn_carabao(coords)
			else:
				move_carabao(coords)
				
			carabaoSpawned = true
			set_state(State.CARABAO)


func randomize_tiles():
	clear_tiles()
	random_place()


func erase_layer_tiles(layer: int):
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			
			erase_tile(layer, pos)


func erase_tile(layer: int, pos: Vector2):
	erase_cell(layer, pos)


func hover_tile():
	if currentState == State.SETUP or currentState == State.PLANTING:
		return
		
	if tileDict.has(str(tile)):
		var tileObj = tileDict[str(tile)]
		if not tileObj.isSeed and not tileObj.isOuter:
			set_cell(tilemapLayers["hover"], tile, tilemapTiles["hover"], Vector2i(0, 0), 0)


func init_set_tile(pos: Vector2, atlas: Vector2i, isOuter: bool):
	tileDict[str(pos)] = {
		"pos": pos,
		"isOuter": isOuter,
		"isSeed": false,
		"isGrown": false,
		"isTilled": false
	}
	set_cell(tilemapLayers["grass"], pos, tilemapTiles["grassTiles"], atlas, 0)


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
	plant_tiles()


func _on_hoe_button_pressed():
	set_state(State.TILLING)


func _on_carabao_button_pressed():
	set_state(State.CARABAO)


func _on_random_button_pressed():
	set_state(State.RANDOM)
	randomize_tiles()


func _on_cancel_button_pressed():
	clear_tiles()
