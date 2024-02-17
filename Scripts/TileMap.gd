extends TileMap


var gridSize = 5
var tileDict = {}

var rows = 11
var cols = 20

var tile : Vector2

# This var is dependent on the tile IDs in TileMap
# DO NOT CHANGE
var tilemapTiles = {
	"grass": 0,
	"hover": 1,
	"tilled": 2
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
		set_tile(tile, "tilled")
	if event.is_action_pressed("RClick"):
		set_tile(tile, "grass")

func set_tile(pos: Vector2, type: String):
	if not tileDict.has(str(tile)):
		return
		
	var tileObj = tileDict[str(pos)]
	
	if type == "tilled":
		tileObj.isTilled = true
		set_cell(0, pos, tilemapTiles["tilled"], Vector2i(0, 0), 0)
	elif type == "seed":
		tileObj.isSeed = true
	elif type == "grow":
		tileObj.isGrown = true
	elif type == "grass":
		if tileObj.isTilled and not tileObj.isSeed:
			set_cell(0, pos, tilemapTiles["grass"], Vector2i(0, 0), 0)
	
	print(tileObj)

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
	if tileDict.has(str(tile)):
		var tileObj = tileDict[str(tile)]
		if not tileObj.isSeed:
			set_cell(1, tile, tilemapTiles["hover"], Vector2i(0, 0), 0)


func init_set_tile(pos: Vector2):
	tileDict[str(pos)] = {
		"pos": pos,
		"isSeed": false,
		"isGrown": false,
		"isTilled": false
	}
	set_cell(0, pos, tilemapTiles["grass"], Vector2i(0, 0), 0)


func init():
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			
			init_set_tile(pos)
