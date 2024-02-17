extends TileMap


var gridSize = 5
var tileDict = {}

func _ready():
	for x in gridSize:
		for y in gridSize:
			var pos = Vector2(x, y)
			
			tileDict[str(pos)] = {
				"type": "grass"
			}
			
			set_cell(0, pos, 0, Vector2i(0, 0), 0)
	
func _process(_delta):
	var tile = local_to_map(get_global_mouse_position())

	#if tileDict.has(str(tile)):
		#set_cell(1, tile, 1, Vector2i(0, 0), 0)
