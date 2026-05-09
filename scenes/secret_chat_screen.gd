extends Control

func _ready():
    $ExitBtn.pressed.connect(_on_exit)

func _on_exit():
    SceneManager.change_scene("res://scenes/messenger_list.tscn")
