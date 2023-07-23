extends Node2D

@export var tilemap_verts:TileMap_Verts
@export var draw_polys:bool = false
#This script is to hold the experimental

#@export var verts: Array[Vector2i] = [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,0)]
var verts:Array[TileMap_Verts.Vert] = []
# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

#from stackoverflow
#returns -1 if no collision else the dist to the intersection, if so we also set vec2 out to be the intersection point
func lineIntersection(l1s:Vector2,l1e:Vector2,l2s:Vector2,l2e:Vector2) -> Intersect:
	var s1:Vector2 = l1e - l1s
	var s2:Vector2 = l2e - l2s
	
	var colinear_test = s2 - s1
	if abs(colinear_test.x) > 0.0 and abs(colinear_test.y) > 0.0:
		#(-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y);
		var s:float = (-s1.y * (l1s.x-l2s.x) + s1.x*(l1s.y-l2s.y)) / (-s2.x*s1.y + s1.x*s2.y)
		#( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y)
		var t:float = (s2.x*(l1s.y-l2s.y) - s2.y*(l1s.x-l2s.x))/(-s2.x*s1.y + s1.x*s2.y)
		
		if(s <=1 and s >=0 and t <= 1 and t>=0):
			var angle = atan2(s1.y,s1.x)
			return Intersect.new(true,l1s + (t * s1),angle,t)
	return Intersect.new(false)

var rays:Array[Intersect] = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	calcLineOfSight()
	#if draw_polys:
	#	queue_redraw()
	
func _draw():
	var tri_pts:PackedVector2Array = PackedVector2Array()
	for i in rays.size():
		tri_pts[0] = rays[i].intersection
		tri_pts[1] = rays[i+1].intersection
		tri_pts[2] = position
		draw_colored_polygon(tri_pts,Color.WHITE)
	

class Intersect:
	var dist:float = 0
	var angle:float = 0
	var intersection:Vector2 = Vector2(0,0)
	var valid:bool = false
	func _init(validIn:bool,intersectIn:Vector2=intersection,angleIn:float=angle, distIn:float = 0):
		angle = angleIn
		intersection = intersectIn
		dist = distIn
		valid = validIn
		
func sort_intersect_angle(a:Intersect,b:Intersect):
	return a.angle < b.angle

#find the closest intersection with a line
func edge_raycast(edges:Array[TileMap_Verts.Edge],ray_s:Vector2,ray_e:Vector2) -> Intersect:
	var collide:bool = false
	var min_dist:float = INF
	var i_out:Intersect = Intersect.new(false)
	var angle:float = 0.0
	for edge in edges:
		var intersection:Intersect = lineIntersection(ray_s,ray_e,edge.start,edge.end)
		if intersection.dist >= 0 and intersection.dist < min_dist: #we got an intersection, and its less than before
			min_dist = intersection.dist
			i_out = intersection
			collide = true
	#var atanvec = pos_intersection - ray_s 
	#angle = atan2(atanvec.y,atanvec.x)
	#out = Intersect.new(pos_intersection,angle)
	return i_out

func calcLineOfSight():
	verts = tilemap_verts.tilemap_verts
	rays.clear()
	
	for vert in verts:
		#raycast from here to the vert
		#store the intersection location and the angle from UP (verts could be in any order,
		#so we use the angle to sort them)
		var dir = vert.pos-position
		var angle = atan2(dir.y,dir.x)
		var angle_2 = angle + 0.0001
		var angle_3 = angle - 0.0001
		
		var ray1 = edge_raycast(tilemap_verts.tilemap_edges,position,dir*10000)
		#var ray2 = edge_raycast(tilemap_verts.tilemap_edges,position,dir*10000,out2)
		#var ray3 = edge_raycast(tilemap_verts.tilemap_edges,position,dir*10000,out3)
		if ray1.valid:
			rays.append(ray1)
			if ray1.angle == 0 and ray1.intersection == Vector2(0,0):
				print("SAME")
		#if ray2:
		#	rays.append(out2)
		#if ray3:
		#	rays.append(out3)
	rays.sort_custom(sort_intersect_angle)
	
		#actual algorithm:
		#he calcs the distance to the vert, then uses its atan2 y/x for an angle
		
		#then he creates 2 more rays at theta + and -= (so the sort angle does more here)
		#ray dx = max_radius*cos(theta), ray dy = max_rad*sin(theta)
		
		#store closest edge intersection info
		#check for a line segment intersection with every edge in the scene (dist, pos, angle)
		#for each edge
			#calc dir vector
			#skip if the vector is co-linear w/ the ray
			#if this is the closest edge the ray intersected, keep (we only want the closest intersected edge)
			#
		
	
