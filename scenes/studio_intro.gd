extends Control

func _ready():
    var logo_tex = load("res://assets/branding/blackmoon_logo.png")
    if logo_tex:
        %LogoRect.texture = logo_tex

    _play_intro()

func _play_intro():
    var tween = create_tween()
    tween.tween_property(%LogoRect, "modulate:a", 1.0, 1.5)
    tween.tween_interval(1.5)
    tween.tween_property(%LogoRect, "modulate:a", 0.0, 1.5)

    await tween.finished

    if SceneManager:
        SceneManager.change_scene("res://scenes/title_cinematic_screen.tscn", false)
