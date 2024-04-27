extends Node3D
class_name TrackSegment

# Preload track segment and obstacles
const BOX_OBSTACLE: PackedScene = preload("res://Objects/box_obstacle.tscn")
const COLLECTIBLE: PackedScene = preload("res://Objects/collectible.tscn")

# Center position of the obstacles (x coordinate)
const LANES: Array[float] = [-3.3, 0, 3.3]

func clear_children_of(node: Node3D) -> void:
	# Free up all the children - we do this when we reuse the track
	var children: Array[Node] = node.get_children()
	for child in children:
		child.queue_free()  # Safely mark the child for deletion

func random_pos(z: float) -> Vector3:
	# Randomly select a lane
	var lane_index: int = randi() % LANES.size()  
	# Randomly select high or low position
	var height_index: int = randi() % 2 

	return Vector3(LANES[lane_index], 0.5 + height_index * 1.5, z)

func create_obstacle_at(pos: Vector3) -> void:
	# New obstacle
	var obstacle: Node = BOX_OBSTACLE.instantiate()
	# Add inside the Obstacles node - we clean this up later
	$Obstacles.add_child(obstacle)
	# Position relative to this track segment
	obstacle.transform.origin = pos

func create_collectible_at(pos: Vector3) -> void:
	# New COLLECTIBLE
	var collectible: Node = COLLECTIBLE.instantiate()
	# Add inside the Obstacles node - we clean this up later
	$Collectibles.add_child(collectible)
	# Position relative to this track segment
	collectible.transform.origin = pos

	# Connect our collision signal
	collectible.connect("body_entered", on_collected.bind(collectible))

func create_objects(first_track: bool) -> void:
	# Clear each time
	clear_children_of($Obstacles)
	clear_children_of($Collectibles)

	# Break down our 100m into 40 subpositions (every 2.5 m)
	# For the first track we leave the first 15m empty (6 x 2.5)
	for i in range(6 if first_track else 0, 40):
		var z: float = 50 - i * 2.5
		var obstacle_pos: Vector3
		# Every 4th time (10m) we do an obstacle
		if i % 4 == 0:
			obstacle_pos = random_pos(z)
			create_obstacle_at(obstacle_pos)
		var collectible_pos: Vector3 = random_pos(z)
		# Avoid overlap
		while collectible_pos == obstacle_pos:
			collectible_pos = random_pos(z)
		create_collectible_at(collectible_pos)

func on_collected(_player: Node3D, collectible: Area3D) -> void:
	# Destroy the collected object
	collectible.queue_free()
