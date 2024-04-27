extends Node3D

func _ready() -> void:
	# Create the objects that belong to each track
	$Tracks/TrackSegment1.create_objects(true)
	$Tracks/TrackSegment2.create_objects(false)

func _on_restart_timer_timeout() -> void:
	get_tree().reload_current_scene()
