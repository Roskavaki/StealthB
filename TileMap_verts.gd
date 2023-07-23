extends TileMap
class_name TileMap_Verts

#This script is a test to see if we can implement
#an algorithm which converts the tilemap directly
#to a series of vertices.

#The vertices could be used to auto-generate a proper baked
#nav region, and/or for the line of sight algorithm and/or a more efficient
#collision mesh(es) for the tilemap

#I would also like to store along with each vertex, some normal information
#ie. SW, NW, SE, NE, as this would allow us to generate nav regions with an offset
#from the walls, which could help since the AI could then have a collider
#It might also let us eliminate a few raycast calls for line of sight
#by checking if we are > 180 degrees away from the normal direction

#We also need to store info about the separate polygons the verts form
#if we are to use this for the navmesh.
#So while removing duplicates, mark the first 2 verts as part of polygon 0
#  every duplicate vert is part of the same polygon
#  every vert connected by an edge (remember the verts will come in pairs), is part of the same
#   polygon.
# when we are forced to start anew, increment the polygon # that is associated with the vertices

#Godot works by have an outermost "outline"/polygon, then subsequent ones will alternate
#as exclude/include as you get deeper.

# Called when the node enters the scene tree for the first time.


	#Tiles To Polygons Algorithm
	#1. Get Used Tiles
	#2. Sort them by row, within each row, by column (or vice versa)
	#3. For each Tile
		#. if I don't have a North neighbour
			#. if I have a west neighbour with a north edge
				#. Extend the west neighour's north edge by 1
				#. Set it as my north edge too (hold a ref to the edge)
			#  else: create a new edge for my north (mark as N edge)
		# South..
			#West neighbour with south edge
				#.. south
			#else make new south edge (Mark as S)
		#West..
			#. If I have a North neighbour with a west edge
				#extend it, set it as my edge
			#. Else: create new edge..
		#East
			# North neighbour w/ east edge
				# extend
			#else create new edge..

	#4. Convert edges to vertices
	#For each edge
		#add vertex to list (position of tile + 0.5*width of tile in dir marked to edge)
		#add second vertex pos to list
		#vertices should also hold normal info (N,S,E,W,NW,NE,SE,SW)
	#5. Remove duplicates (create new list, holding only unique coords)
		#where duplicates hold different normals (ex. N and W), they should be combined (ex. NW)
		#See note near top about also storing polygon information

#the diags represent cases where there are 4 overlapping verts because of diagonally adj tiles
#TODO: these should probly be handled by separating out new verts when creating the
#navmesh
enum Normal {N, S, E, W, NW, NE, SW, SE, DIAG_UNK, DIAG_SWNE, DIAG_NWSE, UNSET=-1}
class Edge:
	var start:Vector2 = Vector2(-1,-1) #tile position, convert to left edge of tile aligned vert
	var end: Vector2 = Vector2(-1,-1) # "", right edge of tile aligned vert
	var normal:Normal = Normal.UNSET
	func _init(s:Vector2, e:Vector2, norm:Normal):
		start = s
		end = e
		normal = norm
	
class Vert:
	var pos: Vector2 = Vector2(-1.0,-1.0)
	var normal: Normal = Normal.UNSET
	var polygon: int = 0
	func _init(posIn:Vector2,n:Normal,poly:int):
		pos = posIn
		normal = n
		polygon = poly

func vert_eq(a:Vert,b:Vert):
	return a.pos == b.pos

class Cell:
	var pos: Vector2i = Vector2i(-1,-1)
	var edgeN: Edge = null
	var edgeS: Edge = null
	var edgeE: Edge = null
	var edgeW: Edge = null
	func _init(p:Vector2i,N:Edge=null,S:Edge=null,E:Edge=null,W:Edge=null):
		pos = p
		edgeN = N
		edgeS = S
		edgeE = E
		edgeW = W
		
#func cell_equals(a:Cell,b:Cell):
#	return a.pos == b.pos
	
func _ready():
	TilesToVerts()
	for v in tilemap_verts:
		print("vert ",v.pos," normal:",v.normal)
	print(tilemap_verts.size())
	print(tilemap_edges.size())
	queue_redraw()
	
var draw_size:float = 1
func _draw():
	for vert in tilemap_verts:
		draw_circle(vert.pos * draw_size,5,Color.RED)
	for edge in tilemap_edges:
		var offset:Vector2 = Vector2(0,0)#-80,-80)#displace(edge.normal)
		draw_line(edge.start as Vector2 * draw_size,(edge.end as Vector2 + offset)*draw_size ,Color.BLUE,3)

	
func sort_Y_X(a,b) -> bool:
	if a[1] < b[1]: #choose the earlier row
		return true
	elif b[1] < a[1]:
		return false
	return a[0] < b[0] #if the same row, choose the earlier column
	
enum {EAST, SOUTH, WEST, NORTH}

func _cell_occupied(cell: Vector2i) -> bool:
	return get_cell_tile_data(0,cell) != null

func _find_Cell(cells:Array[Cell],loc:Vector2i):
	for cell in cells:
		if cell.pos==loc:
			return cell
	return null

func combine_verts(v:Vert,new_v:Vert) -> void:
	if v.normal == Normal.N:
		if new_v.normal == Normal.W:
			v.normal = Normal.NW
		elif new_v.normal == Normal.E:
			v.normal = Normal.NE
		elif new_v.normal == Normal.S:
			v.normal = Normal.DIAG_UNK
		elif new_v.normal == Normal.N:
			pass
	elif v.normal == Normal.E:
		if new_v.normal == Normal.W:
			v.normal = Normal.DIAG_UNK
		elif new_v.normal == Normal.E:
			pass
		elif new_v.normal == Normal.S:
			v.normal = Normal.SE
		elif new_v.normal == Normal.N:
			v.normal = Normal.NE
	elif v.normal == Normal.S:
		if new_v.normal == Normal.W:
			v.normal = Normal.SW
		elif new_v.normal == Normal.E:
			v.normal = Normal.SE
		elif new_v.normal == Normal.S:
			pass
		elif new_v.normal == Normal.N:
			v.normal = Normal.DIAG_UNK
	elif v.normal == Normal.W:
		if new_v.normal == Normal.W:
			pass
		elif new_v.normal == Normal.E:
			v.normal = Normal.DIAG_UNK
		elif new_v.normal == Normal.S:
			v.normal = Normal.SW
		elif new_v.normal == Normal.N:
			v.normal = Normal.NW
	else:
		pass
	#TODO: Figure out combining all the diagonals, in particular what if we get N+S or E+W
	#for now these are marked as "diag UNK

var tilemap_verts: Array[Vert] = []
var tilemap_edges: Array[Edge] = []

func displace(norm:Normal) -> Vector2:
	var offset:Vector2 = Vector2(0,0)
	#we shouldnt get NEWS, only NW,NE, etc
	if norm == Normal.N:
		offset = Vector2(0,0)
	elif norm == Normal.E:
		offset = Vector2(0,0)
	elif norm == Normal.W:
		offset = Vector2(0,0)
	elif norm == Normal.S:
		offset = Vector2(0,0)
		
	elif norm == Normal.NW:
		offset = Vector2(0,0)
	elif norm == Normal.NE:
		offset = Vector2(1,0)
	elif norm == Normal.SW:
		offset = Vector2(0,1)
	elif norm == Normal.SE:
		offset = Vector2(1,1)
	return offset

#convert the tiles to an array of "Vert"s (an intermediate format)
# a second function will convert to the wanted final format
func TilesToVerts() -> void:
	#Get and sort the used cells
	var block_width = tile_set.tile_size.x
	var used_cell_coords: Array[Vector2i] = get_used_cells(0)
	used_cell_coords.sort_custom(sort_Y_X)
	
	var edges:Array[Edge] = []
	var verts:Array[Vert] = []
	var cells:Array[Cell] = []
	
	for coordi in used_cell_coords:
		var coord:Vector2 = (coordi as Vector2)*block_width
		var neighbours = get_surrounding_cells(coordi)
		var cell = Cell.new(coordi)
		if !_cell_occupied(neighbours[NORTH]):
			#coord + Vector2i.LEFT is equivalent to neighbours[WEST] 
			var w_neighbour:Cell = _find_Cell(cells,neighbours[WEST])
			#if we have a W neighbour but not a NW neighbour essentially...
			if w_neighbour != null and w_neighbour.edgeN != null:
				w_neighbour.edgeN.end += Vector2(block_width,0)
				cell.edgeN = w_neighbour.edgeN
			else:
				var edge = Edge.new(coord,coord + Vector2(block_width,0),Normal.N)
				edges.append(edge)
				cell.edgeN = edge
			#print("Eastern neighbor",cell,neighbor_locations[EAST])
		if !_cell_occupied(neighbours[WEST]):
			var n_neighbour:Cell = _find_Cell(cells,neighbours[NORTH])
			#if we have a N neighbour but not a NW neighbour essentially...
			if n_neighbour != null and n_neighbour.edgeW != null:
				n_neighbour.edgeW.end += Vector2(0,block_width)
				cell.edgeW = n_neighbour.edgeW
			else:
				var edge = Edge.new(coord,coord + Vector2(0,block_width),Normal.W)
				edges.append(edge)
				cell.edgeW = edge
		if !_cell_occupied(neighbours[SOUTH]):
			var w_neighbour:Cell = _find_Cell(cells,neighbours[WEST])
			#if we have a W neighbour but not a SW neighbour essentially...
			if w_neighbour != null and w_neighbour.edgeS != null:
				w_neighbour.edgeS.end += Vector2(block_width,0)
				cell.edgeS = w_neighbour.edgeS
			else:
				var edge = Edge.new(coord+ Vector2(0,block_width),coord + Vector2(block_width,block_width),Normal.S)
				edges.append(edge)
				cell.edgeS = edge
		if !_cell_occupied(neighbours[EAST]):
			var n_neighbour:Cell = _find_Cell(cells,neighbours[NORTH])
			#if we have a N neighbour but not a NE neighbour essentially...
			if n_neighbour != null and n_neighbour.edgeE != null:
				n_neighbour.edgeE.end += Vector2(0,block_width)
				cell.edgeE = n_neighbour.edgeE
			else:
				var edge = Edge.new(coord + Vector2(block_width,0) ,coord + Vector2(block_width,block_width),Normal.E)
				edges.append(edge)
				cell.edgeE = edge
		cells.append(cell)	
	
	#TODO: Change the 0 to be the polygon #, polygon # might only need to be on the edge
	#rather than the vert, this is so we can iterate through the edges, polygon by polygon
	#To add the polygons to the nav mesh
	for edge in edges:
		var offset:Vector2 = displace(edge.normal)
		var start_v = Vert.new(edge.start as Vector2,edge.normal,0)
		var duplicate:bool = false
		for v in verts:
			if vert_eq(v,start_v):
				combine_verts(v,start_v)
				duplicate = true
				break
		if !duplicate:
			verts.append(start_v)
		verts.append(start_v)
			
		
			
		var end_v = Vert.new(edge.end as Vector2 + offset,edge.normal,0)
		duplicate = false
		for v in verts:
			if vert_eq(v,end_v):
				combine_verts(v,end_v)
				duplicate = true
				break
		if !duplicate:
			verts.append(end_v)
		verts.append(end_v)
	tilemap_verts = verts
	tilemap_edges = edges
	
		
	
#for navmesh, return a list of vec2 verts, with added offset along vert normals
# interface will need revision to account for multiple polygons... 
func getVertsWithOffset(offset:float):
	pass
	
