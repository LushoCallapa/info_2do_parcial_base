extends TextureRect

@onready var score_label = $level_label

func initText(level):
	score_label.text = "NIVEL" + str(level)

func endGame():
	score_label.text = "YOU WIN"
	
func gameOver():
	score_label.text = "GAME OVER"
