extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var goal_score_label = $MarginContainer/HBoxContainer/goal_score_label

var current_score = 0
var current_count = 0

func initGoal(goal_score):
	goal_score_label.text =  "mision" + "\n" +str(goal_score)

func increment_counter(increment):
	current_score += increment
	score_label.text = str(current_score)

func decrease_count():
	current_count -=1
	current_count = max(0,current_count)
	counter_label.text = str(current_count)

func initCurrentCount(init):
	current_count =init
	counter_label.text = str(current_count)

func initCurrentScore(init):
	current_score =init
	score_label.text = str(current_score)
