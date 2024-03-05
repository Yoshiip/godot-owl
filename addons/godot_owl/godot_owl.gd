@tool
extends EditorPlugin


var button

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		button = preload("res://addons/godot_owl/module.tscn").instantiate()
		add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, button)
		button.free()
