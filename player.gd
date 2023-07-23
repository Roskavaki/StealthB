extends CharacterBody2D

@export var speed:float = 5 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_D):
		move_and_collide(speed*Vector2(1,0))
	elif Input.is_key_pressed(KEY_A):
		move_and_collide(speed*Vector2(-1,0))
	if Input.is_key_pressed(KEY_W):
		move_and_collide(speed*Vector2(0,-1))
	elif Input.is_key_pressed(KEY_S):
		move_and_collide(speed*Vector2(0,1))
