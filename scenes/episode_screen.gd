extends Control

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")
