extends Control

func _ready():
    var navbar = $NavigationBar
    navbar.back_pressed.connect(_on_back)
    %SaveBtn.pressed.connect(_on_save)

    # Load from GlobalState if possible
    if GlobalState and GlobalState.has_method("GetVariable"):
        %NameEdit.text = GlobalState.GetVariable("PlayerName", "Player")

func _on_save():
    if GlobalState and GlobalState.has_method("SetVariable"):
        GlobalState.SetVariable("PlayerName", %NameEdit.text)
        if NotificationManager:
            NotificationManager.show_notification("System", "Profile updated.")

func _on_back():
    if SceneManager:
        SceneManager.change_scene("res://scenes/apps_screen.tscn")
