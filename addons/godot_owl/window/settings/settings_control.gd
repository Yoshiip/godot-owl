@tool
extends Control


var main_node : MenuButton

var properties := {
	"general": {
	}
}

@onready var BooleanProperty := preload("res://addons/godot_owl/window/settings/properties/boolean_property.tscn")

func _on_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	for child in $content/container.get_children():
		child.visible = false
	var _category_name : String = $list.get_item_text(index).to_lower()
	var _tab := $content/container.get_node(_category_name)
	_tab.visible = true
	if _tab.name == "about":
		return
	for child in _tab.get_children():
		child.queue_free() 
	
	var _settings : OwlSettings = main_node.settings
	
	var _label := Label.new()
	_label.text = _category_name.capitalize()
	_label.set("theme_override_font_sizes/font_size", 32)
	_tab.add_child(_label)
	
	for property in properties[_category_name].keys():
		var _type := typeof(_settings.get(property))
		match _type:
			TYPE_BOOL:
				var _propertyNode := BooleanProperty.instantiate()
				_propertyNode.name = property
				_propertyNode.text = properties[_category_name][property].get("label")
				_propertyNode.button_pressed = _settings.get(property)
				_propertyNode.pressed.connect(_property_pressed.bind(_propertyNode))
				_tab.add_child(_propertyNode)

func _property_pressed(node : Control) -> void:
	main_node.settings.set(node.name, node.button_pressed)
	main_node.settings_updated()
