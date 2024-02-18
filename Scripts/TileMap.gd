extends TileMap

@onready var hoeButton = $"../HoeButton"
@onready var carabaoButton = $"../CarabaoButton"
@onready var randomButton = $"../RandomButton"
@onready var plantButton = $"../PlantButton"
@onready var seedTiles = $"../SeedTiles"
@onready var tilledCountLabel = $"../TilledCount"
@onready var grownCountLabel = $"../GrownCount"
@onready var harvestCountLabel = $"../HarvestCount"



@export var CarabaoScene : PackedScene
@export var SeedNode : PackedScene


var gridSize = 5
var tileDict = {}
var newTileDict = {}
var overlayTiles = []
var newOverlayTiles = []
var radius = 0
var tilledCount = 0
var grownCount = 0
var harvestCount = 0
@export var lookTime = .5
@export var seedTimer = 3

var rows = 11
var cols = 20

var tile : Vector2
var carabaoSpawned : bool = false

var mainCarabao : Node2D

var randomTilledChance : float = 0.20
var patrolChance : float = 0.20


enum State {
	SETUP, # 0
	TILLING, # 1
	CARABAO, # 2
	PLANTING, # 3
	HARVESTING, # 4
	RANDOM, # 5
	LOOKING, # 6
	MOVING, # 7
	PATROLLING, # 8
	GAMEOVER # 9
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
	"overlay": 4,
}

var plantTiles = {
	1: Vector2i(1, 0), # phase = 1
	2: Vector2i(2, 0), # phase = 2
	3: Vector2i(3, 0), # phase = 3
	4: Vector2i(4, 0), # phase = 4
}

var isPatrolling : bool = false

func _ready():
	# Init
	# Godot does cols first
	init()
	
	
func _process(_delta):
	tile = local_to_map(get_global_mouse_position())

	erase_layer_tiles(tilemapLayers["hover"])
	hover_tile()
	
	tilledCountLabel.text = str(tilledCount)
	grownCountLabel.text = str(grownCount)
	harvestCountLabel.text = str(harvestCount)
	
	#if currentState == State.PATROLLING:
		#await get_tree().create_timer(2).timeout
		#if not isPatrolling:
			#if randf() < patrolChance:
				#patrol()
				#isPatrolling = true
	
	#if carabaoSpawned:
		#print(local_to_map(mainCarabao.position))


func _input(event):
	# Click to till
	if not tileDict.has(str(tile)):
		return
		
	if event.is_action_pressed("Click"):
		if currentState == State.TILLING:
			set_tile(tile, "tilled", true, 0)
			AudioManager.play_sound("tillSound")
			print("Tilled tile at: ", str(tile))
		elif currentState == State.CARABAO:
			set_tile(tile, "carabao", true, 0)
			
	if event.is_action_pressed("RClick"):
		set_tile(tile, "grass", true, 0)
		AudioManager.play_sound("tillSound")


func set_tile(pos: Vector2, type: String, click: bool, phase: int):
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
	
	elif type == "plant":
		newTileDict[str(pos)].seedPhase = phase
		set_cell(
			tilemapLayers["plant"],
			pos,
			tilemapTiles["plantTiles"],
			plantTiles[phase],
			0
		)
	
	#print("set tile: ", tileObj)




func plant_tiles():
	# set newDict tiles
	for tileData in tileDict.values():
		if not tileData.isOuter:
			newTileDict[str(tileData.pos)] = tileData
	
	#for t in newTileDict.values():
		#print(t)
	
	#print(mainCarabao.pos)
	#print("tilledCount: ", tilledCount)
	look_for_tiles()


func calculate_travel_time(start: Vector2, end: Vector2, speed: float) -> float:
	var distance = start.distance_to(end)
	var time = distance / speed
	return time + 1


func end_phase(seedNode: Node2D):
	#print("Ending phase of: ", seedNode)
	var phase = newTileDict[str(seedNode.name)].seedPhase
	phase += 1
	
	if phase == 4:
		#print("LAST PHASE OF: ", str(seedNode.name))
		set_tile(newTileDict[str(seedNode.name)].pos, "plant", false, phase)
		newTileDict[str(seedNode.name)].isGrown = true
		grownCount += 1
		seedNode.queue_free()
		look_for_tiles()
		return
		
	set_tile(newTileDict[str(seedNode.name)].pos, "plant", false, phase)
	seedNode.start_timer()


func stop_moving():
	var t = local_to_map(mainCarabao.position)
	print("Stop moving: ", t)
	
	#if currentState == State.PATROLLING:
		#isPatrolling = false
		##move_carabao(t)
		##patrol()
		##return
	
	#if currentState == State.HARVESTING:
		#grownCount -= 1
		#harvestCount += 1
		#print("HARVESTED AT: ", str(t))
		#radius = 0
		#overlayTiles = []
		#newOverlayTiles = []
		#mainCarabao.pos = t
		#move_carabao(t)
		#newTileDict[str(t)].isHarvested = true
		#newTileDict[str(t)].isSeed = false
		#erase_tile(tilemapLayers["plant"], t)
		#look_for_tiles()
		
	
	# This is where seed is planted
	if newTileDict[str(t)].isTilled and not newTileDict[str(t)].isSeed and not\
	newTileDict[str(t)].isHarvested and not newTileDict[str(t)].isGrown:
		print("Planting tile: ", t)
		set_tile(t, "plant", false, 1)
		AudioManager.play_sound("plantSound")
		newTileDict[str(t)].isSeed = true
		# instantiate a seednode 
		var seedNode = SeedNode.instantiate()
		seedNode.name = str(t)
		seedNode.seedTimer = seedTimer
		seedNode.connect("end_phase", end_phase)
		seedTiles.add_child(seedNode)
		seedNode.start_timer()
		mainCarabao.pos = t
		move_carabao(t)
		tilledCount -= 1
		radius = 0
		overlayTiles = []
		newOverlayTiles = []
		if tilledCount > 0:
			set_state(State.LOOKING)
			look_for_tiles()
		elif tilledCount == 0:
			set_state(State.HARVESTING)
			look_for_tiles()

	# Harvest
	elif newTileDict[str(t)].isGrown and not newTileDict[str(t)].isHarvested and tilledCount == 0:
		set_state(State.HARVESTING)
		print("Harvest tile: ", t)
		AudioManager.play_sound("harvestSound")
		mainCarabao.pos = t
		move_carabao(t)
		erase_tile(tilemapLayers["plant"], t)
		newTileDict[str(t)].isHarvested = true
		newTileDict[str(t)].isGrown = false
		newTileDict[str(t)].isSeed = false
		harvestCount += 1
		grownCount -= 1
		radius = 0
		overlayTiles = []
		newOverlayTiles = []
		
		if tilledCount == 0 and grownCount > 0:
			set_state(State.LOOKING)
			look_for_tiles()
			
		elif tilledCount == 0 and grownCount == 0:
			set_state(State.GAMEOVER)
			end_game()


func end_game():
	print("End Game")
	radius = 0
	overlayTiles = []
	newOverlayTiles = []
	erase_layer_tiles(tilemapLayers["overlay"])


func move_to(t: Vector2i):
	#print("moving to, ", str(t))
	#radius = 0
	#overlayTiles = []
	#newOverlayTiles = []
	#if currentState != State.HARVESTING:
	set_state(State.MOVING)
	# move carabao from mainCarabao.pos to t
	var targetPosition = map_to_local(t)
	#print(targetPosition)

	#var tween = create_tween()
	##tween.tween_property(mainCarabao, "position", Vector2(mainCarabao.pos.x, mainCarabao.pos.y), 1)
	#var time = calculate_travel_time(mainCarabao.pos, t, mainCarabao.speed)
	#print("TIME: ", time)
	#tween.tween_property(mainCarabao, "position", Vector2(target_position.x, target_position.y), time)
	#mainCarabao.play_run()
	mainCarabao.moving = true
	mainCarabao.go_towards_target_point(mainCarabao.position, targetPosition)
	

func check_for_tilled():
	#print("Checking for tilled tiles among overlays")
	for t in overlayTiles:
		if currentState == State.LOOKING:
			if newTileDict[str(t)].isTilled and not newTileDict[str(t)].isSeed and not\
			newTileDict[str(t)].isHarvested and not newTileDict[str(t)].isGrown:
				#radius = 0
				#overlayTiles = []
				#newOverlayTiles = []
				move_to(t)
				
			elif newTileDict[str(t)].isGrown and tilledCount == 0:
				move_to(t)
			
			#elif newTileDict[str(t)].isTilled and newTileDict[str(t)].isGrown and not\
			#newTileDict[str(t)].isHarvested:
				#print("SEED FOUND AT: ", str(t))
				#set_state(State.HARVESTING)
				#radius = 0
				#overlayTiles = []
				#newOverlayTiles = []
				#move_to(t)
				
	
func look_for_tiles():
	#overlayTiles = []
	#newOverlayTiles = []
	#if currentState == State.MOVING:
		#print("MOVING")
		#radius = 0
		#overlayTiles = []
		#newOverlayTiles = []
		#erase_layer_tiles(tilemapLayers["overlay"])
		#return
		
	#if tilledCount == 0:
		#radius = 0
		#overlayTiles = []
		#newOverlayTiles = []
		#erase_layer_tiles(tilemapLayers["overlay"])
		#return
	
			
	#if grownCount > 0 and currentState != State.HARVESTING:
		##print("Harvesting")
		#set_state(State.HARVESTING)
	#else:
		#print("Patrolling")
		#set_state(State.PATROLLING)
		
	await get_tree().create_timer(lookTime).timeout
	set_state(State.LOOKING)
	radius += 1
	#print("Looking for tiles with radius: ", radius)
	erase_layer_tiles(tilemapLayers["overlay"])
	
	
	#set_tile(mainCarabao.pos, "overlay", false, 0)
	
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
				#set_tile(neighbor, "overlay", false, 0)
	
	#print(newOverlayTiles)
	newOverlayTiles = array_unique(newOverlayTiles)
	
	for neighbor in newOverlayTiles:
		set_tile(neighbor, "overlay", false, 0)
		
	overlayTiles = newOverlayTiles
	check_for_tilled()
	
	if currentState == State.LOOKING:
		print("Looking")
		look_for_tiles()


func array_unique(array: Array) -> Array:
	var unique: Array = []

	for item in array:
		if not unique.has(item):
			unique.append(item)

	return unique

func move_carabao(pos: Vector2i):
	if not carabaoSpawned:
		#print("Carabao not spawned")
		return
		
	mainCarabao.position = map_to_local(pos)
	mainCarabao.pos = pos
	
	print("Carabao moved to: ", mainCarabao.position, " : ", mainCarabao.pos)


func spawn_carabao(pos: Vector2i):
	var carabao = CarabaoScene.instantiate()
	mainCarabao = carabao
	carabaoSpawned = true
	move_carabao(pos)
	
	var root = get_tree().get_root()
	var main = root.get_node("Main")
	main.add_child(mainCarabao)
	mainCarabao.connect("stop_moving", stop_moving)
	


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
	
	#if currentState == State.PATROLLING:
		#patrol()
	
	disable_button_on_state()


func patrol():
	var randomTile = newTileDict.keys()[randi() % newTileDict.size()]
	randomTile = newTileDict[str(randomTile)].pos
	print("Patrolling to: ", str(randomTile))
	move_to(randomTile)
	


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
			else:
				plantButton.disabled = false
		
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
	erase_layer_tiles(tilemapLayers["plant"])
	

	for child in seedTiles.get_children():
		child.queue_free()
	
	# Set isTilled on all tiles to false
	for tileData in tileDict.values():
		tileData.isTilled = false
		tileData.isSeed = false
		tileData.isGrown = false
		tileData.isHarvested = false
		tileData.seedPhase = 0
		tileData.seedTimer = seedTimer
	
	if carabaoSpawned:
		mainCarabao.queue_free()
	carabaoSpawned = false


func random_place():
	# Random till
	set_state(State.TILLING)
	AudioManager.play_sound("plantSound")
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			
			if randf() < randomTilledChance:
				set_tile(pos, "tilled", false, 0)
	

	
	# Carabao process
	carabaoSpawned = false
	
	while not carabaoSpawned:
		var randomTile = tileDict.keys()[randi() % tileDict.size()]
		
		if not tileDict[str(randomTile)].isOuter:
			#mainCarabao.position = map_to_local(Vector2())
			randomTile = tileDict[str(randomTile)].pos
			var coords = Vector2i(randomTile)
			
			if not carabaoSpawned:
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
		"isTilled": false,
		"isHarvested": false,
		"seedPhase": 0,
		"seedTimer": seedTimer,
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
	AudioManager.play_sound("clickSound")
	set_state(State.PLANTING)
	plant_tiles()


func _on_hoe_button_pressed():
	AudioManager.play_sound("clickSound")
	set_state(State.TILLING)


func _on_carabao_button_pressed():
	AudioManager.play_sound("clickSound")
	set_state(State.CARABAO)


func _on_random_button_pressed():
	AudioManager.play_sound("clickSound")
	set_state(State.RANDOM)
	randomize_tiles()


func _on_cancel_button_pressed():
	AudioManager.play_sound("clickSound")
	AudioManager.play_sound("clearSound")
	set_state(State.TILLING)
	clear_tiles()


func _on_back_button_pressed():
	AudioManager.play_sound("clickSound")
	var root = get_tree().get_root()
	var menu = root.get_node("Menu")
	var main = root.get_node("Main")
	menu.show()
	main.queue_free()
