extends Control

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)
    %SaveBtn.pressed.connect(_on_save)
    %LoadBtn.pressed.connect(_on_load)

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")

func _on_save():
    if GlobalState and GlobalState.has_method("Save"):
        GlobalState.Save()
        if NotificationManager:
            NotificationManager.show_notification("System", "Data backup complete.")

func _on_load():
    if GlobalState and GlobalState.has_method("Load"):
        GlobalState.Load()
        if NotificationManager:
            NotificationManager.show_notification("System", "Data restored.")
