extends Node2D

# state machine
enum {WAIT, MOVE}
var state
var level = 1

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]

# current pieces in scene
var time_timer
var all_pieces = []
var moves
var time
var score = 0
var is_move = false
var match_count = 0
# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false
var matched_four = []
var matched_five= []
var score_goal = 2000
# scoring variables and signals

# counter variables and signals

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	moves = 20
	get_parent().get_node("top_ui").initCurrentCount(moves)
	get_parent().get_node("top_ui").initGoal(score_goal)
	get_parent().get_node("bottom_ui").initText(level)
	all_pieces = make_2d_array()
	spawn_pieces()
	
func start_new_level():
	if level == 2:
		
		clear_previous_pieces()
		score = 0
		time = 60
		get_parent().get_node("top_ui").initCurrentCount(time)
		get_parent().get_node("top_ui").initCurrentScore(score)
		get_parent().get_node("bottom_ui").initText(level)
		all_pieces = make_2d_array()
		spawn_pieces()
		state = WAIT
		get_parent().get_node("next_level").start()

		score_goal = 300
		

		print("Level 2 started")
	else:
		get_parent().get_node("bottom_ui").endGame()
		print("No hay mas niveles")

func clear_previous_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null 

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	is_move = true
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
		
	
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()
	

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	is_move = false
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		if is_move and match_count>0:
			if level == 1:
				get_parent().get_node("top_ui").decrease_count()
				moves-=1
				
				if(moves <= 0 and score < score_goal):
					game_over()
				if(score >= score_goal):
					level+= 1
					start_new_level()
				is_move = false
			else:
				get_parent().get_node("top_ui").increment_counter(10*match_count)
				score+=10*match_count
				if(moves <= 0 and score < score_goal):
					game_over()
				if(score >= score_goal):
					get_parent().get_node("second_timer").stop() 
					level+= 1
					state = WAIT
					start_new_level()
				is_move = false
		match_count = 0
		touch_input()

func eraseColumn(i,j):
	for k in height:
		all_pieces[i][k].matched = true
		all_pieces[i][k].dim()
		if(all_pieces[i][k].type == "Row"):
			eraseRow(i,k)
		if(all_pieces[i][k].type == "Adjacent"):
			eraseColor(all_pieces[k][j].color)
		
func eraseRow(i,j):
	for k in width:
		all_pieces[k][j].matched = true
		all_pieces[k][j].dim()
		if(all_pieces[k][j].type == "Column"):
			eraseColumn(k,j)
		if(all_pieces[k][j].type == "Adjacent"):
			eraseColor(all_pieces[k][j].color)
		
func eraseColor(color):
	for i in width:
		for j in height:
			if all_pieces[i][j].color == color:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()
				if(all_pieces[i][j].type == "Column"):
					eraseColumn(i,j)
				if(all_pieces[i][j].type == "Row"):
					eraseRow(i,j)
func find_matches():
	matched_four = []
	matched_five = []
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i < width - 2 and j < height - 1 and j>0:
					if all_pieces[i][j + 1] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i][j-1] != null:
						if all_pieces[i][j + 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i][j-1].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and (not all_pieces[i+2][j].matched) and (not all_pieces[i+1][j+1].matched) and (not all_pieces[i][j+1].matched):
							
							all_pieces[i][j+ 1].matched = true
							all_pieces[i][j+ 1].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i + 2][j].matched = true
							all_pieces[i + 2][j].dim()
							all_pieces[i ][j - 1].matched = true
							all_pieces[i ][j - 1].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							if(all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i][j-1].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent"):
								eraseColor(all_pieces[i][j].color)
														
							if last_place.x == i and last_place.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x == i+1 and last_place.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x == i+2 and last_place.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j-1:
								matched_five.append([i, j-1 , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+1:
								matched_five.append([i, j+1 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j-1:
								matched_five.append([i, j-1 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+1:
								matched_five.append([i, j+1 , all_pieces[i][j],true])
							else:
								matched_five.append([i, j , all_pieces[i][j],true])
							if(all_pieces[i][j].type == "Column"):
								eraseColumn(i,j)
							if(all_pieces[i+1][j].type == "Column"):
								eraseColumn(i+1,j)
							if(all_pieces[i+2][j].type == "Column"):
								eraseColumn(i+2,j)
							if(all_pieces[i][j-1].type == "Column"):
								eraseColumn(i,j-1)
							if(all_pieces[i][j+1].type == "Column"):
								eraseColumn(i,j+1)
								
							if(all_pieces[i][j].type == "Row"):
								eraseRow(i,j)
							if(all_pieces[i+1][j].type == "Row"):
								eraseRow(i+1,j)
							if(all_pieces[i+2][j].type == "Row"):
								eraseRow(i+2,j)
							if(all_pieces[i][j-1].type == "Row"):
								eraseRow(i,j-1)
							if(all_pieces[i][j+1].type == "Row"):
								eraseRow(i,j+1)
								
				if i < width - 2 and j > 1:
					if all_pieces[i][j - 1] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i ][j - 2] != null:
						if all_pieces[i][j - 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i ][j - 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i+2][j].matched and not all_pieces[i][j-2].matched and not all_pieces[i][j-1].matched:
							all_pieces[i][j-1].matched = true
							all_pieces[i][j-1].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i + 2][j].matched = true
							all_pieces[i + 2][j].dim()
							all_pieces[i][j - 2].matched = true
							all_pieces[i][j - 2].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							
							if last_place.x == i and last_place.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x == i+1 and last_place.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x == i+2 and last_place.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j-2:
								matched_five.append([i, j-2 , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j-1:
								matched_five.append([i, j-1 , all_pieces[i][j],true])
								
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j-2:
								matched_five.append([i, j-2 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j-1:
								matched_five.append([i, j-1 , all_pieces[i][j],true])
							else:
								matched_five.append([i, j , all_pieces[i][j],true])
							
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i][j-2].type == "Adjacent" or all_pieces[i][j-1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i+1][j].type == "Column":
								eraseColumn(i+1, j)
							if all_pieces[i+2][j].type == "Column":
								eraseColumn(i+2, j)
							if all_pieces[i][j-2].type == "Column":
								eraseColumn(i, j-2)
							if all_pieces[i][j-1].type == "Column":
								eraseColumn(i, j-1)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i+1][j].type == "Row":
								eraseRow(i+1, j)
							if all_pieces[i+2][j].type == "Row":
								eraseRow(i+2, j)
							if all_pieces[i][j-2].type == "Row":
								eraseRow(i, j-2)
							if all_pieces[i][j-1].type == "Row":
								eraseRow(i, j-1)

				if i < width - 2 and j < height - 2:
					if all_pieces[i][j + 1] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i][j + 2] != null:
						if all_pieces[i][j + 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i][j + 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i+2][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched:
							all_pieces[i][j+1].matched = true
							all_pieces[i][j+1].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i + 2][j].matched = true
							all_pieces[i + 2][j].dim()
							all_pieces[i][j +2].matched = true
							all_pieces[i][j +2].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							
							if last_place.x == i and last_place.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x == i+1 and last_place.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x == i+2 and last_place.y==j:
								matched_five.append([i+2, j, all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+2:
								matched_five.append([i, j+2 , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+1:
								matched_five.append([i, j+1 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+2:
								matched_five.append([i, j+2 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+1:
								matched_five.append([i, j+1 , all_pieces[i][j],true])
							else:
								matched_five.append([i, j , all_pieces[i][j],true])
							
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i][j+2].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i+1][j].type == "Column":
								eraseColumn(i+1, j)
							if all_pieces[i+2][j].type == "Column":
								eraseColumn(i+2, j)
							if all_pieces[i][j+2].type == "Column":
								eraseColumn(i, j+2)
							if all_pieces[i][j+1].type == "Column":
								eraseColumn(i, j+1)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i+1][j].type == "Row":
								eraseRow(i+1, j)
							if all_pieces[i+2][j].type == "Row":
								eraseRow(i+2, j)
							if all_pieces[i][j+2].type == "Row":
								eraseRow(i, j+2)
							if all_pieces[i][j+1].type == "Row":
								eraseRow(i, j+1)
								
				if i>0 and i < width - 1 and j > 1:
					
					if all_pieces[i][j - 1] != null and all_pieces[i + 1][j] != null and all_pieces[i-1][j] != null and all_pieces[i][j - 2] != null:
						if all_pieces[i][j - 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i - 1][j].color == current_color and all_pieces[i][j - 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i+1][j-1].matched and not all_pieces[i+1][j-2].matched and not all_pieces[i][j-1].matched:
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i][j - 1].matched = true
							all_pieces[i][j - 1].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i -1][j].matched = true
							all_pieces[i -1][j].dim()
							all_pieces[i ][j - 2].matched = true
							all_pieces[i ][j - 2].dim()
							
							if last_place.x == i and last_place.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x == i + 1 and last_place.y == j:
								matched_five.append([i + 1, j, all_pieces[i][j], true])
							elif last_place.x == i  and last_place.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j - 2:
								matched_five.append([i, j - 2, all_pieces[i][j], true])
							elif last_place.x == i-1  and last_place.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
								
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i + 1 and last_place.y + last_direction.y == j:
								matched_five.append([i + 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i  and last_place.y + last_direction.y == j - 1:
								matched_five.append([i , j - 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i  and last_place.y + last_direction.y == j - 2:
								matched_five.append([i , j - 2, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i-1 and last_place.y + last_direction.y == j :
								matched_five.append([i-1, j , all_pieces[i][j], true])
							else:
								matched_five.append([i, j, all_pieces[i][j], true])
							
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i + 1][j].type == "Adjacent" or all_pieces[i ][j - 1].type == "Adjacent" or all_pieces[i][j - 2].type == "Adjacent" or all_pieces[i- 1][j ].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i + 1][j].type == "Column":
								eraseColumn(i + 1, j)
							if all_pieces[i ][j - 1].type == "Column":
								eraseColumn(i , j - 1)
							if all_pieces[i ][j - 2].type == "Column":
								eraseColumn(i , j - 2)
							if all_pieces[i - 1][j].type == "Column":
								eraseColumn(i - 1, j)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i + 1][j].type == "Row":
								eraseRow(i + 1, j)
							if all_pieces[i ][j - 1].type == "Row":
								eraseRow(i , j - 1)
							if all_pieces[i ][j - 2].type == "Row":
								eraseRow(i , j - 2)
							if all_pieces[i - 1][j].type == "Row":
								eraseRow(i - 1, j)
				
				if i > 0 and i < width - 1 and j < height - 1 and j > 0:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null and all_pieces[i][j + 1] != null and all_pieces[i][j - 1] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i][j + 1].color == current_color and all_pieces[i][j - 1].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j-1].matched:
							all_pieces[i - 1][j].matched = true
							all_pieces[i - 1][j].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i][j + 1].matched = true
							all_pieces[i][j + 1].dim()
							all_pieces[i][j - 1].matched = true
							all_pieces[i][j - 1].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							
							if last_place.x == i and last_place.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x == i - 1 and last_place.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x == i + 1 and last_place.y == j:
								matched_five.append([i + 1, j, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i + 1 and last_place.y + last_direction.y == j:
								matched_five.append([i + 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							else:
								matched_five.append([i, j, all_pieces[i][j], true])

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i + 1][j].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent" or all_pieces[i][j - 1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i - 1][j].type == "Column":
								eraseColumn(i - 1, j)
							if all_pieces[i + 1][j].type == "Column":
								eraseColumn(i + 1, j)
							if all_pieces[i][j + 1].type == "Column":
								eraseColumn(i, j + 1)
							if all_pieces[i][j - 1].type == "Column":
								eraseColumn(i, j - 1)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i - 1][j].type == "Row":
								eraseRow(i - 1, j)
							if all_pieces[i + 1][j].type == "Row":
								eraseRow(i + 1, j)
							if all_pieces[i][j + 1].type == "Row":
								eraseRow(i, j + 1)
							if all_pieces[i][j - 1].type == "Row":
								eraseRow(i, j - 1)
				
				if i > 1 and j > 1:
					if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null and all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i - 2][j].color == current_color and all_pieces[i][j - 1].color == current_color and all_pieces[i][j - 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i-2][j].matched and not all_pieces[i][j-1].matched and not all_pieces[i][j-2].matched:
							all_pieces[i - 1][j].matched = true
							all_pieces[i - 1][j].dim()
							all_pieces[i - 2][j].matched = true
							all_pieces[i - 2][j].dim()
							all_pieces[i][j - 1].matched = true
							all_pieces[i][j - 1].dim()
							all_pieces[i][j - 2].matched = true
							all_pieces[i][j - 2].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							if last_place.x == i and last_place.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x == i - 1 and last_place.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x == i - 2 and last_place.y == j:
								matched_five.append([i - 2, j, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j - 2:
								matched_five.append([i, j - 2, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 2 and last_place.y + last_direction.y == j:
								matched_five.append([i - 2, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 2:
								matched_five.append([i, j - 2, all_pieces[i][j], true])
							else:
								matched_five.append([i, j, all_pieces[i][j], true])
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i - 2][j].type == "Adjacent" or all_pieces[i][j - 1].type == "Adjacent" or all_pieces[i][j - 2].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i - 1][j].type == "Column":
								eraseColumn(i - 1, j)
							if all_pieces[i - 2][j].type == "Column":
								eraseColumn(i - 2, j)
							if all_pieces[i][j - 1].type == "Column":
								eraseColumn(i, j - 1)
							if all_pieces[i][j - 2].type == "Column":
								eraseColumn(i, j - 2)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i - 1][j].type == "Row":
								eraseRow(i - 1, j)
							if all_pieces[i - 2][j].type == "Row":
								eraseRow(i - 2, j)
							if all_pieces[i][j - 1].type == "Row":
								eraseRow(i, j - 1)
							if all_pieces[i][j - 2].type == "Row":
								eraseRow(i, j - 2)
				
				if i > 1 and j<height - 2:
					if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null and all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i - 2][j].color == current_color and all_pieces[i][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i-2][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched:
							all_pieces[i - 1][j].matched = true
							all_pieces[i - 1][j].dim()
							all_pieces[i - 2][j].matched = true
							all_pieces[i - 2][j].dim()
							all_pieces[i][j + 1].matched = true
							all_pieces[i][j + 1].dim()
							all_pieces[i][j + 2].matched = true
							all_pieces[i][j + 2].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							if last_place.x == i and last_place.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x == i - 1 and last_place.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x == i - 2 and last_place.y == j:
								matched_five.append([i - 2, j, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j + 2:
								matched_five.append([i, j + 2, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 2 and last_place.y + last_direction.y == j:
								matched_five.append([i - 2, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 2:
								matched_five.append([i, j + 2, all_pieces[i][j], true])
							else:
								matched_five.append([i, j, all_pieces[i][j], true])

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i - 2][j].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent" or all_pieces[i][j + 2].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i - 1][j].type == "Column":
								eraseColumn(i - 1, j)
							if all_pieces[i - 2][j].type == "Column":
								eraseColumn(i - 2, j)
							if all_pieces[i][j + 1].type == "Column":
								eraseColumn(i, j + 1)
							if all_pieces[i][j + 2].type == "Column":
								eraseColumn(i, j + 2)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i - 1][j].type == "Row":
								eraseRow(i - 1, j)
							if all_pieces[i - 2][j].type == "Row":
								eraseRow(i - 2, j)
							if all_pieces[i][j + 1].type == "Row":
								eraseRow(i, j + 1)
							if all_pieces[i][j + 2].type == "Row":
								eraseRow(i, j + 2)
				
				if i > 1 and j > 0 and j<height - 1:
					if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null and all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i - 2][j].color == current_color and all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i-2][j].matched and not all_pieces[i][j-1].matched and not all_pieces[i][j+1].matched:
							all_pieces[i - 1][j].matched = true
							all_pieces[i - 1][j].dim()
							all_pieces[i - 2][j].matched = true
							all_pieces[i - 2][j].dim()
							all_pieces[i][j - 1].matched = true
							all_pieces[i][j - 1].dim()
							all_pieces[i][j + 1].matched = true
							all_pieces[i][j + 1].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()

							if last_place.x == i and last_place.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x == i - 1 and last_place.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x == i - 2 and last_place.y == j:
								matched_five.append([i - 2, j, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 2 and last_place.y + last_direction.y == j:
								matched_five.append([i - 2, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 1:
								matched_five.append([i, j - 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							else:
								matched_five.append([i, j, all_pieces[i][j], true])

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i - 2][j].type == "Adjacent" or all_pieces[i][j - 1].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i - 1][j].type == "Column":
								eraseColumn(i - 1, j)
							if all_pieces[i - 2][j].type == "Column":
								eraseColumn(i - 2, j)
							if all_pieces[i][j - 1].type == "Column":
								eraseColumn(i, j - 1)
							if all_pieces[i][j + 1].type == "Column":
								eraseColumn(i, j + 1)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i - 1][j].type == "Row":
								eraseRow(i - 1, j)
							if all_pieces[i - 2][j].type == "Row":
								eraseRow(i - 2, j)
							if all_pieces[i][j - 1].type == "Row":
								eraseRow(i, j - 1)
							if all_pieces[i][j + 1].type == "Row":
								eraseRow(i, j + 1)
				
				if i > 0 and i < width -1 and j<height - 2:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null and all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched:
							all_pieces[i - 1][j].matched = true
							all_pieces[i - 1][j].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i][j + 1].matched = true
							all_pieces[i][j + 1].dim()
							all_pieces[i][j + 2].matched = true
							all_pieces[i][j + 2].dim()
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()

							if last_place.x == i and last_place.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x == i - 1 and last_place.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x == i + 1 and last_place.y == j:
								matched_five.append([i + 1, j, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x == i and last_place.y == j + 2:
								matched_five.append([i, j + 2, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
								matched_five.append([i, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
								matched_five.append([i - 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i + 1 and last_place.y + last_direction.y == j:
								matched_five.append([i + 1, j, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
								matched_five.append([i, j + 1, all_pieces[i][j], true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 2:
								matched_five.append([i, j + 2, all_pieces[i][j], true])
							else:
								matched_five.append([i, j, all_pieces[i][j], true])

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i + 1][j].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent" or all_pieces[i][j + 2].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							if all_pieces[i][j].type == "Column":
								eraseColumn(i, j)
							if all_pieces[i - 1][j].type == "Column":
								eraseColumn(i - 1, j)
							if all_pieces[i + 1][j].type == "Column":
								eraseColumn(i + 1, j)
							if all_pieces[i][j + 1].type == "Column":
								eraseColumn(i, j + 1)
							if all_pieces[i][j + 2].type == "Column":
								eraseColumn(i, j + 2)
							if all_pieces[i][j].type == "Row":
								eraseRow(i, j)
							if all_pieces[i - 1][j].type == "Row":
								eraseRow(i - 1, j)
							if all_pieces[i + 1][j].type == "Row":
								eraseRow(i + 1, j)
							if all_pieces[i][j + 1].type == "Row":
								eraseRow(i, j + 1)
							if all_pieces[i][j + 2].type == "Row":
								eraseRow(i, j + 2)
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# detect horizontal matches
				if i < width - 4:
					#print("I: ",i)
					if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i + 3][j] != null and all_pieces[i + 4][j] != null:
						#print("I1: ",i)
						if all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i + 3][j].color == current_color and all_pieces[i + 4][j].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and (not all_pieces[i+2][j].matched) and (not all_pieces[i+3][j].matched) and (not all_pieces[i+4][j].matched):
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i + 2][j].matched = true
							all_pieces[i + 2][j].dim()
							all_pieces[i + 3][j].matched = true
							all_pieces[i + 3][j].dim()
							all_pieces[i + 4][j].matched = true
							all_pieces[i + 4][j].dim()
							
							if(all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i+3][j].type == "Adjacent" or all_pieces[i+4][j].type == "Adjacent"):
								eraseColor(all_pieces[i][j].color)
														
							if last_place.x == i and last_place.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x == i+1 and last_place.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x == i+2 and last_place.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x == i+3 and last_place.y==j:
								matched_five.append([i+3, j , all_pieces[i][j],true])
							elif last_place.x == i+4 and last_place.y==j:
								matched_five.append([i+4, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
								matched_five.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
								matched_five.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+3 and last_place.y+ last_direction.y==j:
								matched_five.append([i+3, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+4 and last_place.y+ last_direction.y==j:
								matched_five.append([i+4, j , all_pieces[i][j],true])
							else:
								matched_five.append([i, j , all_pieces[i][j],true])
							if(all_pieces[i][j].type == "Column"):
								eraseColumn(i,j)
							if(all_pieces[i+1][j].type == "Column"):
								eraseColumn(i+1,j)
							if(all_pieces[i+2][j].type == "Column"):
								eraseColumn(i+2,j)
							if(all_pieces[i+3][j].type == "Column"):
								eraseColumn(i+3,j)
							if(all_pieces[i+4][j].type == "Column"):
								eraseColumn(i+4,j)
								
							if(all_pieces[i][j].type == "Row"):
								eraseRow(i,j)
							if(all_pieces[i+1][j].type == "Row"):
								eraseRow(i+1,j)
							if(all_pieces[i+2][j].type == "Row"):
								eraseRow(i+2,j)
							if(all_pieces[i+3][j].type == "Row"):
								eraseRow(i+3,j)
							if(all_pieces[i+4][j].type == "Row"):
								eraseRow(i+4,j)
								
				if i < width - 3:
					if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i + 3][j] != null:
						if all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i + 3][j].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and (not all_pieces[i+2][j].matched) and (not all_pieces[i+3][j].matched):
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i + 1][j].matched = true
							all_pieces[i + 1][j].dim()
							all_pieces[i + 2][j].matched = true
							all_pieces[i + 2][j].dim()
							all_pieces[i + 3][j].matched = true
							all_pieces[i + 3][j].dim()
							
							if(all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent"):
								eraseColor(all_pieces[i][j].color)
														
							if last_place.x == i and last_place.y==j:
								matched_four.append([i, j , all_pieces[i][j],true])
							elif last_place.x == i+1 and last_place.y==j:
								matched_four.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x == i+2 and last_place.y==j:
								matched_four.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x == i+3 and last_place.y==j:
								matched_four.append([i+3, j , all_pieces[i][j],true])
							
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
								matched_four.append([i, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
								matched_four.append([i+1, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
								matched_four.append([i+2, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i+3 and last_place.y+ last_direction.y==j:
								matched_four.append([i+3, j , all_pieces[i][j],true])
							else:
								matched_four.append([i, j , all_pieces[i][j],true])
							if(all_pieces[i][j].type == "Column"):
								eraseColumn(i,j)
							if(all_pieces[i+1][j].type == "Column"):
								eraseColumn(i+1,j)
							if(all_pieces[i+2][j].type == "Column"):
								eraseColumn(i+2,j)
							if(all_pieces[i+3][j].type == "Column"):
								eraseColumn(i+3,j)
								
							if(all_pieces[i][j].type == "Row"):
								eraseRow(i,j)
							if(all_pieces[i+1][j].type == "Row"):
								eraseRow(i+1,j)
							if(all_pieces[i+2][j].type == "Row"):
								eraseRow(i+2,j)
							if(all_pieces[i+3][j].type == "Row"):
								eraseRow(i+3,j)
							
				if (
					i < width - 2 
					and 
					all_pieces[i + 2][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i + 2][j].color == current_color and all_pieces[i + 1][j].color == current_color
					and
					not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and (not all_pieces[i+2][j].matched)
				):
					all_pieces[i + 2][j].matched = true
					all_pieces[i + 2][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
					
					if(all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent"):
						eraseColor(all_pieces[i][j].color)
					
					if(all_pieces[i][j].type == "Column"):
						eraseColumn(i,j)
					if(all_pieces[i+1][j].type == "Column"):
						eraseColumn(i+1,j)
					if(all_pieces[i+2][j].type == "Column"):
						eraseColumn(i+2,j)
						
					if(all_pieces[i][j].type == "Row"):
						eraseRow(i,j)
					if(all_pieces[i+1][j].type == "Row"):
						eraseRow(i+1,j)
					if(all_pieces[i+2][j].type == "Row"):
						eraseRow(i+2,j)
					
				if j <= height - 5:
					#print("I: ",i)
					if all_pieces[i][j+1] != null and all_pieces[i ][j+ 2] != null and all_pieces[i ][j+ 3] != null and all_pieces[i][j + 4] != null:
						#print("I1: ",i)
						if all_pieces[i ][j+ 1].color == current_color and all_pieces[i][j + 2].color == current_color and all_pieces[i][j + 3].color == current_color and all_pieces[i][j + 4].color == current_color and not all_pieces[i][j].matched and not all_pieces[i][j+1].matched and (not all_pieces[i][j+2].matched) and (not all_pieces[i][j+3].matched) and (not all_pieces[i][j+4].matched):
							
							if(all_pieces[i][j].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent" or all_pieces[i][j+2].type == "Adjacent" or all_pieces[i][j+3].type == "Adjacent" or all_pieces[i][j+4].type == "Adjacent"):
								eraseColor(all_pieces[i][j].color)
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i ][j+ 1].matched = true
							all_pieces[i ][j+ 1].dim()
							all_pieces[i ][j+ 2].matched = true
							all_pieces[i ][j+ 2].dim()
							all_pieces[i][j + 3].matched = true
							all_pieces[i][j + 3].dim()
							all_pieces[i][j + 4].matched = true
							all_pieces[i][j + 4].dim()
														
							if last_place.x == i and last_place.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+1:
								matched_five.append([i, j+1 , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+2:
								matched_five.append([i, j+2 , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+3 :
								matched_five.append([i, j+3 , all_pieces[i][j],true])
							elif last_place.x == i and last_place.y==j+4:
								matched_five.append([i, j+4 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
								matched_five.append([i, j , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+1:
								matched_five.append([i, j+1 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+2:
								matched_five.append([i, j +2, all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+3:
								matched_five.append([i, j+3 , all_pieces[i][j],true])
							elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+4:
								matched_five.append([i, j+4 , all_pieces[i][j],true])
							else:
								matched_five.append([i, j , all_pieces[i][j],true])
							if(all_pieces[i][j].type == "Column"):
								eraseColumn(i,j)
							if(all_pieces[i][j+1].type == "Column"):
								eraseColumn(i,j+1)
							if(all_pieces[i][j+2].type == "Column"):
								eraseColumn(i,j+2)
							if(all_pieces[i][j+3].type == "Column"):
								eraseColumn(i,j+3)
							if(all_pieces[i][j+4].type == "Column"):
								eraseColumn(i,j+4)
								
							if(all_pieces[i][j].type == "Row"):
								eraseRow(i,j)
							if(all_pieces[i][j+1].type == "Row"):
								eraseRow(i,j+1)
							if(all_pieces[i][j+2].type == "Row"):
								eraseRow(i,j+2)
							if(all_pieces[i][j+3].type == "Row"):
								eraseRow(i,j+3)
							if(all_pieces[i][j+4].type == "Row"):
								eraseRow(i,j+4)
								
				if j <= height - 4:
					#print("J: ",j)
					if all_pieces[i][j+1] != null and all_pieces[i][j+2] != null and all_pieces[i][j+3] != null:
						#print("J1: ",j)
						if all_pieces[i ][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color and all_pieces[i][j + 3].color == current_color and not all_pieces[i][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched and not all_pieces[i][j+3].matched:
							all_pieces[i][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i ][j + 1].matched = true
							all_pieces[i ][j + 1].dim()
							all_pieces[i][j + 2].matched = true
							all_pieces[i][j + 2].dim()
							all_pieces[i][j + 3].matched = true
							all_pieces[i][j + 3].dim()
							
							if(all_pieces[i][j].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent" or all_pieces[i][j+2].type == "Adjacent" or all_pieces[i][j+3].type == "Adjacent"):
								eraseColor(all_pieces[i][j].color)
							if last_place.x == i and last_place.y==j:
								matched_four.append([i, j , all_pieces[i][j],false])
							if last_place.x == i and last_place.y==j+1:
								matched_four.append([i, j+1 , all_pieces[i][j],false])
							if last_place.x == i and last_place.y==j+2:
								matched_four.append([i, j +2, all_pieces[i][j],false])
							if last_place.x == i and last_place.y==j+3:
								matched_four.append([i, j+3 , all_pieces[i][j],false])
							
							if last_place.x + last_direction.x == i and last_place.y + last_direction.y ==j:
								matched_four.append([i, j , all_pieces[i][j],false])
							if last_place.x + last_direction.x == i and last_place.y + last_direction.y==j+1:
								matched_four.append([i, j+1 , all_pieces[i][j],false])
							if last_place.x + last_direction.x == i and last_place.y + last_direction.y==j+2:
								matched_four.append([i, j +2, all_pieces[i][j],false])
							if last_place.x + last_direction.x == i and last_place.y + last_direction.y==j+3:
								matched_four.append([i, j+3 , all_pieces[i][j],false])
							
							
							if(all_pieces[i][j].type == "Column"):
								eraseColumn(i,j)
							if(all_pieces[i][j+1].type == "Column"):
								eraseColumn(i,j+1)
							if(all_pieces[i][j+2].type == "Column"):
								eraseColumn(i,j+2)
							if(all_pieces[i][j+3].type == "Column"):
								eraseColumn(i,j+3)
								
							if(all_pieces[i][j].type == "Row"):
								eraseRow(i,j)
							if(all_pieces[i][j+1].type == "Row"):
								eraseRow(i,j+1)
							if(all_pieces[i][j+2].type == "Row"):
								eraseRow(i,j+2)
							if(all_pieces[i][j+3].type == "Row"):
								eraseRow(i,j+3)
				if (
					j < height - 2 
					and 
					all_pieces[i][j + 2] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j + 2].color == current_color and all_pieces[i][j + 1].color == current_color
					and
					not all_pieces[i][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched
				):
					
					if(all_pieces[i][j].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent" or all_pieces[i][j+2].type == "Adjacent"):
						eraseColor(all_pieces[i][j].color)
					all_pieces[i][j + 2].matched = true
					all_pieces[i][j + 2].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					if(all_pieces[i][j].type == "Column"):
						eraseColumn(i,j)
					if(all_pieces[i][j+1].type == "Column"):
						eraseColumn(i,j+1)
					if(all_pieces[i][j+2].type == "Column"):
						eraseColumn(i,j+2)
						
					if(all_pieces[i][j].type == "Row"):
						eraseRow(i,j)
					if(all_pieces[i][j+1].type == "Row"):
						eraseRow(i,j+1)
					if(all_pieces[i][j+2].type == "Row"):
						eraseRow(i,j+2)
					
				
	get_parent().get_node("destroy_timer").start()

func destroy_matched():
	var was_matched = false
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				match_count += 1
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	
	for bloque in matched_four:
		var piece = bloque[2].duplicate()
		add_child(piece)
		piece.position = grid_to_pixel(bloque[0], bloque[1])
		all_pieces[bloque[0]][bloque[1]] = piece
		all_pieces[bloque[0]][bloque[1]].normal()
		all_pieces[bloque[0]][bloque[1]].newSprite(bloque[3])
		
	for bloque in matched_five:
		var piece = bloque[2].duplicate()
		add_child(piece)
		piece.position = grid_to_pixel(bloque[0], bloque[1])
		all_pieces[bloque[0]][bloque[1]] = piece
		all_pieces[bloque[0]][bloque[1]].normal()
		all_pieces[bloque[0]][bloque[1]].newSpriteFive()
		
		
	move_checked = true
	get_parent().get_node("top_ui").increment_counter(10 * match_count)
	score+=10*match_count
	
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				#print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	#print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	#print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func game_over():
	state = WAIT
	get_parent().get_node("bottom_ui").gameOver()
	print("game over")


func _on_timer_timeout() -> void:
	get_parent().get_node("top_ui").decrease_count()
	
	if(time<=0):
		state = WAIT
		if score < score_goal:
			game_over()
		get_parent().get_node("second_timer").stop() 
	else:
		time -=1
		time = max(0,time)
		get_parent().get_node("second_timer").start()	

func _on_next_level_timeout() -> void:
	get_parent().get_node("second_timer").start()
	state = MOVE
	print("Next Level")
	get_parent().get_node("next_level").stop()
