@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("DebugGrid2D", "Node2D", preload("debug_grid_2d.gd"), preload("debug_grid_2d.svg"))

func _exit_tree():
	remove_custom_type("DebugGrid2D")
