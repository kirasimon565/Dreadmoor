extends Control

func _ready():
    %ConfirmBtn.pressed.connect(_on_confirm)

func _on_confirm():
    if %NameEdit.text.strip_edges() != "":
        if GlobalState:
            GlobalState.SetVariable("PlayerName", %NameEdit.text)

        SceneManager.change_scene("res://scenes/welcome_screen.tscn")
