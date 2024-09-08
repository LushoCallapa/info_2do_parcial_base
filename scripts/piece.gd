extends Node2D

@export var color: String
var type = "normal"
var matched = false

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
	
func normal():
	$Sprite2D.modulate = Color(1, 1, 1, 1)

func newSprite(isVertical):
	var aux :String = color
	aux[0]=aux[0].to_upper()
	if color == "light_green":
		aux = "Light Green"
	if(isVertical):
		type = "Column"
	else:
		type = "Row"
	var image = "res://assets/pieces/"+aux+ " "+ type+".png"
	
	$Sprite2D.texture = load(image)
	
func newSpriteFive():
	var aux :String = color
	aux[0]=aux[0].to_upper()
	if color == "light_green":
		aux = "Light Green"
	type = "Adjacent"
	var image = "res://assets/pieces/"+aux+ " "+ type+".png"

	$Sprite2D.texture = load(image)
