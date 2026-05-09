extends Control

func _ready():
    var logo_tex = load("res://assets/branding/dreadmoor_logo.png")
    if logo_tex:
        %LogoTexture.texture = logo_tex

    %ContinueBtn.pressed.connect(_on_continue)

func _on_continue():
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")
