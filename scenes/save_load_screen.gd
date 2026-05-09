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
        %SaveBtn.text = "SAVING..."
        await get_tree().create_timer(1.0).timeout
        %SaveBtn.text = "BACKUP DATA"
        if NotificationManager:
            NotificationManager.show_notification("System", "Memory core backup complete.")

func _on_load():
    if GlobalState and GlobalState.has_method("Load"):
        %LoadBtn.text = "RESTORING..."
        await get_tree().create_timer(1.5).timeout
        GlobalState.Load()
        %LoadBtn.text = "RESTORE DATA"
        if NotificationManager:
            NotificationManager.show_notification("System", "Memory core restored successfully.")

        # Reboot OS effect
        SceneManager.change_scene("res://scenes/welcome_screen.tscn")
