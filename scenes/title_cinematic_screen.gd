extends Control

func _ready():
    %StartButton.modulate.a = 0.0

    var logo_tex = load("res://assets/branding/dreadmoor_logo.png")
    if logo_tex:
        %LogoTexture.texture = logo_tex

    var tween = create_tween()
    tween.tween_property(%StartButton, "modulate:a", 1.0, 2.0).set_delay(1.0)

    %StartButton.pressed.connect(_on_start_pressed)

    # Play background title video
    var vp = VideoStreamPlayer.new()
    vp.name = "BackgroundVideo"
    vp.set_anchors_preset(Control.PRESET_FULL_RECT)
    vp.expand = true
    vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var stream = load("res://assets/media/videos/title_intro.mp4")
    if stream:
        vp.stream = stream
        vp.autoplay = true
        vp.loop = true

    add_child(vp)
    move_child(vp, 0) # Place behind everything else

    # Also play title background music
    if AudioManager:
        AudioManager.play_bgm("res://assets/music/welcome_theme.mp3", 2.0)

func _on_start_pressed():
    if AudioManager:
        AudioManager.stop_bgm(1.0)
    if true:
        SceneManager.change_scene("res://scenes/intro_trailer_screen.tscn")
