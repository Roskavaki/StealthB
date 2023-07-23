extends Node2D

var move_dir:bool = false
@export var speed:float = 0.5
# Called when the node enters the scene tree for the first time.
func _ready():
	#add myself as an agent to the navmesh
	#"real" agents will be told to avoid me by moving away a certain radius
	var new_agent_rid: RID = NavigationServer2D.agent_create()
	var default_map_rid: RID = get_world_2d().navigation_map

	NavigationServer2D.agent_set_map(new_agent_rid, default_map_rid)


# Move the "door"
func _process(delta):
	if $Timer.is_stopped():
		$Timer.start()
	elif move_dir:
		translate(Vector2(speed,0.0))
	else:
		translate(Vector2(-speed,0.0))


func _on_timer_timeout():
	move_dir = !move_dir
