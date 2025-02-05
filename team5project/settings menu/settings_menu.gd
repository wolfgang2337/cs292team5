class_name SettingsMenu
extends Control

@onready var exit_button = $MarginContainer/VBoxContainer/Exit_Button as Button
# Called when the node enters the scene tree for the first time.
signal exit_settings_menu

func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_exit_pressed() -> void:
	exit_settings_menu.emit()
	set_process(false)
