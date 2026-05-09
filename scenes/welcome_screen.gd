extends Control

func _ready():
    %ContinueBtn.pressed.connect(_on_continue)

func _on_continue():
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")
