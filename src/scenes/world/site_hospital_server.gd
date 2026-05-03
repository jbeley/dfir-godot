extends "res://src/scenes/components/world_scene.gd"

## St. Catherine's — IT room. Two hidden secrets celebrating healthcare-IT
## archeology: a vintage TRS-80 still running ER triage, and a misfiled paper
## chart from 1995 that should have been shredded a decade ago.


func _ready() -> void:
	location_id = &"site_hospital_server"
	super._ready()
