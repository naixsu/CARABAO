extends TileMap


var gridSize = 5
var tileDict = {}

var rows = 11
var cols = 20

var tile : Vector2

func _ready():
	# Init
	# Godot does cols first
	init()
	
	
func _process(_delta):
	tile = local_to_map(get_global_mouse_position())

	erase_tiles()
	hover_tile()



func erase_tiles():
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
		if not tileObj.hasSeed or not tileObj.tilled:
			set_cell(1, tile, 1, Vector2i(0, 0), 0)


func init_set_tile(pos: Vector2):
	tileDict[str(pos)] = {
		"type": "grass",
		"hasSeed": false,
		"fullGrown": false,
		"tilled": false
	}
	set_cell(0, pos, 0, Vector2i(0, 0), 0)


func init():
	for col in cols:
		for row in rows:
			if col == 0 or col == cols - 1\
			or row == 0 or row == rows - 1 or row == rows - 2:
				continue
			
			var pos = Vector2(col, row)
			
			init_set_tile(pos)
