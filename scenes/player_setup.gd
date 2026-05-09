extends Control

func _ready():
    %ConfirmBtn.pressed.connect(_on_confirm)

func _on_confirm():
    if %NameEdit.text.strip_edges() != "":
        if GlobalState and GlobalState.has_method("SetVariable"):
            GlobalState.SetVariable("PlayerName", %NameEdit.text)

        SceneManager.change_scene("res://scenes/messenger_list.tscn")
