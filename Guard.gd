extends CharacterBody2D

var movement_speed: float = 200.0
var movement_target_position: Vector2 = Vector2(60.0,200.0)

@export var target: Node2D


@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(movement_target_position)

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return

	navigation_agent.target_position = target.position
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	
	var move_dir = position.direction_to(next_path_position)
	var intended_vel = move_dir * movement_speed
	#tell the nav agent how we intend to move
	$NavigationAgent2D.set_velocity(intended_vel)

#The nav agent will tell us to stop if there is an obstacle with safe_velocity
func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

	
