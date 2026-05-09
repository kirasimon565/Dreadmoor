extends Control

func _ready():
    var navbar = $NavigationBar
    navbar.back_pressed.connect(_on_back)

func _on_back():
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")
