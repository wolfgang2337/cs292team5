extends Node2D

@onready var tile_map : TileMap = $TileMap

var ground_layor = 0
#var top_layor = 1

var temp_count = 0

var global_lockout = false

 #returns tile category int (0 = no data, 1 = ground, 2 = riverbed, 3 = river, 4 = pump)
var tile_category_custom_data = "tile_category"



enum MODES {DIG, UNDIG, PUMP}
var mode_state = MODES.DIG # by default, player can dig ground

#array of coordinates of neighbors (curr, right, rightdown down, downleft, left, leftup, up, upright) if curr = (0,0)
const NEIGHBOR_DIF = [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1),
Vector2i(-1,1),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1)]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	for i in range(13):
		
		var pos = Vector2i(8, i) #coordinate (8,i), which is all tiles in col 8 
		var source_id = 0
		var atlas_coord = Vector2i(1,0) #riverbed tile
		tile_map.set_cell(ground_layor, pos, source_id, atlas_coord) #place riverbed at the middle tiles
		
	
	var pos = Vector2i(8, 0) #coordinate (8,i), which is all tiles in col 8 
	var source_id = 0
	var atlas_coord = Vector2i(3, 0) #riverbed tile
	tile_map.set_cell(ground_layor, pos, source_id, atlas_coord) #place water at the top of middle column


# Called every frame. 'delta' is the elapsed time since the previous frame.
# Go to Project Setting -> Physics -> Common to see number of cycles per second
func _process(delta):	
	
	pass #no function needed here at the moment, add code to _on_timer_timeout for pulse related events		
	
func _input(event): 
	
	#if toggle_dig (J) is pressed, mode change to dig mode
	if Input.is_action_just_pressed("toggle_dig"):
		mode_state = MODES.DIG
		
	#if toggle_undig (K) is pressed, mode change to undig mode
	elif Input.is_action_just_pressed("toggle_undig"):
		mode_state = MODES.UNDIG
	
	elif Input.is_action_just_pressed("toggle_pump"):
		mode_state = MODES.PUMP
	
	#can add action by Project -> Project Settings -> Input Map -> Add new Action
	elif Input.is_action_just_pressed("click") and global_lockout == false: #if left mouse button is clicked
		
		#add constraint to each kind of tile by TileSet (on the right) 
		#-> Custom Data Layers (and add variable) -> paint (bottom)->paint properties
		#->painting on 
		
		
		var mouse_pos : Vector2i = get_global_mouse_position() #global position in float
		var tile_mouse_pos : Vector2i = tile_map.local_to_map(mouse_pos) #local position in int
		
		
		var sur_tiles = get_category_sur_tiles(tile_mouse_pos)
		
		var source_id = 0
		
		if mode_state == MODES.DIG:
			var atlas_coord = Vector2i(1, 0) #riverbed tile
			
			#boolean variables for the following if statement
			
			var curr_tile_is_ground = sur_tiles[0] == 1 
			
			#if surrounding tiles contain no_data (outside border), false
			var surr_tiles_are_not_outside = sur_tiles.all(func(c): return c!=0)
			
			#if square of riverbed or river is made, false
			var will_not_make_riverbed_square = sur_tiles.slice(1,4).any(func(c): return c!=2 and c!=3) and \
				sur_tiles.slice(3,6).any(func(c): return c!=2 and c!=3) and  sur_tiles.slice(5,8).any(func(c): return c!=2 and c!=3) and \
				  ((sur_tiles[1] != 2 and sur_tiles[1] != 3) or sur_tiles.slice(7).any(func(c): return c!=2 and c!=3)) 
			
			#print(sur_tiles, sur_tiles.slice(1,4).any(func(c): return c!=2),sur_tiles.slice(3,6).any(func(c): return c!=2),sur_tiles.slice(5,8).any(func(c): return c!=2),(sur_tiles[1] != 2 or sur_tiles.slice(7).any(func(c): return c!=2)) )
			
			#if following conditions are met, set cell to riverbed
			if curr_tile_is_ground and surr_tiles_are_not_outside and will_not_make_riverbed_square:
				tile_map.set_cell(ground_layor, tile_mouse_pos, source_id, atlas_coord) #set cell to riverbed 
				
			else:
				print("cannot dig here")
				
				
		elif mode_state == MODES.UNDIG:
			var atlas_coord = Vector2i(0,0) #ground tile
			
			var curr_tile_is_riverbed = sur_tiles[0] == 2
			
			#if surrounding tiles contain no_data (outside border), false
			var surr_tiles_are_not_outside = sur_tiles.all(func(c): return c!=0)
			
			if curr_tile_is_riverbed and surr_tiles_are_not_outside and checkRiverConnection(tile_mouse_pos):
				tile_map.set_cell(ground_layor, tile_mouse_pos, source_id, atlas_coord)
			else:
				print("cannot undig here")
		
		elif mode_state == MODES.PUMP:
			var atlas_coord = Vector2i(0,1) #pump tile
			
			var curr_tile_is_ground = sur_tiles[0] == 1
			
			#if surrounding tiles contain no_data (outside border), false
			var surr_tiles_are_not_outside = sur_tiles.all(func(c): return c!=0)
			
			if curr_tile_is_ground and surr_tiles_are_not_outside:
				tile_map.set_cell(ground_layor, tile_mouse_pos, source_id, atlas_coord)
				
				remove_surrounding_river(tile_mouse_pos, source_id)
					
			else:
				print("cannot set pump here")
			
			
			
			
		else:
			print("error!!!")
			
	
func remove_surrounding_river(curr_pos, source_id):
	var sur_tiles = get_category_sur_tiles(curr_pos)
	
	#surtiles except for index 0 (current tile)
	for i in range(1,9):

		#if there is river tile in the neighbor, change it to riverbed
		if sur_tiles[i] == 3:
		
			var neighbor_pos = curr_pos + NEIGHBOR_DIF[i]
			
			var atlas_coord = Vector2i(1,0) #riverbed tile
			
			tile_map.set_cell(ground_layor, neighbor_pos, source_id, atlas_coord)
		
			
			
			
#get category of surrounding tiles (0=nodata, 1=ground, 2=riverbed, 3=river, 4=pump)
func get_category_sur_tiles(curr_pos):
	var neighbor_tiles = [0,0,0,0,0,0,0,0,0]
	
	#for each neighboring tiles (curr, right, rightdown, down, downleft, left, leftup, up, upright)
	for i in range(9):
		var tile_data : TileData = tile_map.get_cell_tile_data(ground_layor, curr_pos + NEIGHBOR_DIF[i])
		if tile_data:
			neighbor_tiles[i] = tile_data.get_custom_data(tile_category_custom_data)
			
	return neighbor_tiles
			
	

# 2 second pulse, check water flow. order is down, left, then right. no support for water flowing up
func _on_timer_timeout():
	
	var lockout = false
	var leftlock = false
	
	if tile_map.get_cell_atlas_coords(ground_layor, Vector2i(8, 0)) == Vector2i(1, 0):
		tile_map.set_cell(ground_layor, Vector2i(8,0), 0, Vector2i(3,0))
	elif tile_map.get_cell_atlas_coords(ground_layor, Vector2i(8, 0)) == Vector2i(3, 0) and tile_map.get_cell_atlas_coords(ground_layor, Vector2i(8, 1)) != Vector2i(3, 0):
		tile_map.set_cell(ground_layor, Vector2i(8,1), 0, Vector2i(3,0))
		lockout = true
	
	if tile_map.get_cell_atlas_coords(ground_layor, Vector2i(8, 12)) == Vector2i(3, 0):
		global_lockout = true
		print("game over!")
	
	for y in range(12, 0, -1):
		for x in range(16, 0 , -1):
			var temp_vec = Vector2i(x, y)
			if tile_map.get_cell_atlas_coords(ground_layor, temp_vec) == Vector2i(3, 0) and lockout == false:
				if tile_map.get_cell_atlas_coords(ground_layor, tile_map.get_neighbor_cell(temp_vec, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)) == Vector2i(1,0) and leftlock == false: 
					tile_map.set_cell(ground_layor, tile_map.get_neighbor_cell(temp_vec, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE), 0, Vector2i(3,0))
				elif tile_map.get_cell_atlas_coords(ground_layor, tile_map.get_neighbor_cell(temp_vec, TileSet.CELL_NEIGHBOR_LEFT_SIDE)) == Vector2i(1,0) and leftlock == false: 
					tile_map.set_cell(ground_layor, tile_map.get_neighbor_cell(temp_vec, TileSet.CELL_NEIGHBOR_LEFT_SIDE), 0, Vector2i(3,0))
					leftlock = true
				elif tile_map.get_cell_atlas_coords(ground_layor, tile_map.get_neighbor_cell(temp_vec, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)) == Vector2i(1,0): 
					tile_map.set_cell(ground_layor, tile_map.get_neighbor_cell(temp_vec, TileSet.CELL_NEIGHBOR_RIGHT_SIDE), 0, Vector2i(3,0))
			else:
				leftlock = false
	
	lockout = false
	
func checkRiverConnection(tile_pos):
	var tiles_to_visit = {Vector2i(8,0): 1}
	var tiles_checked = {}
	
	while tiles_to_visit.is_empty() == false:
		
		var tile = tiles_to_visit.keys()[0]
		print(tile)
		if tiles_checked.get(tile) or tile == tile_pos:
			tiles_to_visit.erase(tile)
			continue
		tiles_checked[tile] = 1
		
		if checkIfNeighborIsRiver(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE):
			tiles_to_visit[tile_map.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)] = 1
		if checkIfNeighborIsRiver(tile, TileSet.CELL_NEIGHBOR_LEFT_SIDE):
			tiles_to_visit[tile_map.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_LEFT_SIDE)] = 1
		if checkIfNeighborIsRiver(tile, TileSet.CELL_NEIGHBOR_RIGHT_SIDE):
			tiles_to_visit[tile_map.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)] = 1
	
	if(tiles_checked.get(Vector2i(8, 12))):
		return true
	else: 
		return false

func checkIfNeighborIsRiver(tile, direction):
	var neighbor = tile_map.get_neighbor_cell(tile, direction)
	if tile_map.get_cell_atlas_coords(ground_layor, neighbor) == Vector2i(1,0) or \
	tile_map.get_cell_atlas_coords(ground_layor, neighbor) == Vector2i(3,0):
		return true
	else:
		return false
