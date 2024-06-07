extends Node2D


export (String) var color;
var move_tween
var matched = false

# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = $Move_Tween
	
func move(target):
	move_tween.interpolate_property(self, "position", position, target, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	move_tween.start()
	
func dim ():
	var sprite = $Sprite
	sprite.modulate = Color(1,1,1,0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
