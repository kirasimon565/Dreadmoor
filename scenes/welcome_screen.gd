extends Control

func _ready():
    var logo_tex = load("res://assets/branding/dreadmoor_logo.png")
    if logo_tex:
        %LogoTexture.texture = logo_tex

    var stream = load("res://assets/backgrounds/welcome_fog_loop.mp4")
    if stream:
        %BackgroundVideo.stream = stream
        %BackgroundVideo.autoplay = true
        %BackgroundVideo.loop = true

    %ContinueBtn.pressed.connect(_on_continue)

func _on_continue():
    if %BackgroundVideo.is_playing():
        %BackgroundVideo.stop()
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")
