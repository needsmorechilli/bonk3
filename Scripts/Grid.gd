extends Node2D

enum {move, wait}
var state

# can be changed in inspector
export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;
export (int) var y_offset;

export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces

signal damage_ice
signal make_ice

var possible_pieces = [
	preload("res://Scenes//Blueberry_Piece.tscn"),
	preload("res://Scenes//Carrot_Piece.tscn"),
	preload("res://Scenes//IceCube_Piece.tscn"),
	preload("res://Scenes//Popsicle_Piece.tscn"),
	preload("res://Scenes//Watermelon_Piece.tscn"),
	preload("res://Scenes//Zucchini_Piece.tscn"),
	
]

var all_pieces = [];

var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_check = false

var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready():
	state = move
	randomize()
	all_pieces = make_2D_array()
	spawn_pieces()
	spawn_ice()
	
	
	
func restricted_fill(place):
	if is_in_array(empty_spaces, place):
		return true
	return false
	
func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false
			

func make_2D_array():
	var array = []
	for i in range(width): 
		array.append([])
		for j in range(height):
			array[i].append(null)
	return array
	
func spawn_pieces():
	for i in range(width):
		for j in range(height):
			if !restricted_fill(Vector2(i,j)):
				
				var rand = floor(rand_range(0, possible_pieces.size()))
				var piece = possible_pieces[rand].instance()
				var loops = 0
				while (match_at(i,j,piece.color) && loops<100):
					rand = floor(rand_range(0, possible_pieces.size()))
					loops +=1
					piece =possible_pieces[rand].instance()
				

				add_child(piece)
				piece.position = grid_to_pixel(i, j)
				all_pieces[i][j] = piece
				
func spawn_ice():
	for i in range(ice_spaces.size()):
		emit_signal("make_ice", ice_spaces[i])

			
func match_at(i, j, color):
	if i > 1:
		if all_pieces[i-1][j] != null && all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].color == color && all_pieces[i-2][j].color== color:
				return true
	if j>1:
		if all_pieces[i][j-1] != null && all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].color == color && all_pieces[i][j-2].color== color:
				return true
		
	
func grid_to_pixel(row, column):
	var new_x = x_start + row * offset
	var new_y = y_start + column * -offset
	return Vector2(new_x, new_y)
			
			
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func is_in_grid(grid_position):
	if grid_position.x >= 0 and grid_position.x < width:
		if grid_position.y >= 0 and grid_position.y < height:
			return true
	return false

	
func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) and controlling:
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			touch_difference(first_touch, final_touch)


			
func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece != null and other_piece != null:
		store_info(first_piece, other_piece, Vector2(column, row), direction)
		state = wait
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		first_piece.move(grid_to_pixel(column + direction.x , row + direction.y))
		other_piece.move(grid_to_pixel(column, row))
		if !move_check:
			find_matches()
		
func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction
	pass	
		
		
func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_check = false
	pass
	
func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1,0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1,0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,-1))
			
func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width - 1:
					if all_pieces[i-1][j] != null && all_pieces[i + 1][j] != null:
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							match_and_dim(all_pieces[i-1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i+1][j])
				if j > 0 && j < height - 1:
					if all_pieces[i][j-1] != null && all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							match_and_dim(all_pieces[i][j-1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j+1])
	get_parent().get_node("Destroy_Timer").start()
# Called every frame. 'delta' is the elapsed time since the previous frame.

func match_and_dim(item):
	item.matched = true
	item.dim()
	
func is_piece_null(column, row):
	if all_pieces[column][row] == null:
		return true
	return false

func _process(delta):
	if state == move:
		touch_input()
	
func destroy_matched():
	var is_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					emit_signal("damage_ice", Vector2(i,j))
					is_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	move_check = true
	if is_matched:
		get_parent().get_node("Collapse_Timer").start()
	else:
		swap_back()

func _on_Timer_timeout():
	destroy_matched()
	pass # Replace with function body.
	
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i,j)):
				for k in range(j+1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("Refill_Timer").start()
	
func refill_columns():
	for i in range(width):
		for j in range(height):
			if all_pieces[i][j] == null and !restricted_fill(Vector2(i,j)):
				var rand = floor(rand_range(0, possible_pieces.size()))
				var piece = possible_pieces[rand].instance()
				var loops = 0
				while (match_at(i,j,piece.color) && loops<100):
					rand = floor(rand_range(0, possible_pieces.size()))
					loops +=1
					piece =possible_pieces[rand].instance()
			

				add_child(piece)
				piece.position = grid_to_pixel(i, j-y_offset)
				piece.move(grid_to_pixel(i,j))
				all_pieces[i][j] = piece
	after_refill()
				
func after_refill():
	for i in range(width):
		for j in range(height):
			if all_pieces[i][j] != null:
				if match_at(i,j, all_pieces[i][j].color):
					find_matches()
					get_parent().get_node("Destroy_Timer").start()
					return
	state = move
	move_check = false
	


func _on_Collapse_Timer_timeout():
	collapse_columns()


func _on_Refill_Timer_timeout():
	refill_columns()
