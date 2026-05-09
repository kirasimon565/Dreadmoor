extends Control

func _ready():
    # Attempt to load actual logo if exists, else fallback to text
    var logo_tex = load("res://assets/branding/blackmoon_logo.png")
    if logo_tex:
        %LogoRect.texture = logo_tex
    else:
        var label = Label.new()
        label.text = "BLACKMOON"
        label.add_theme_font_size_override("font_size", 64)
        $CenterContainer.add_child(label)
        label.modulate = Color(1, 1, 1, 0)
        %LogoRect = label # reassign for tweening

    _play_intro()

func _play_intro():
    # Simple fade in, wait, fade out, transition to title
    var tween = create_tween()
    tween.tween_property(%LogoRect, "modulate:a", 1.0, 1.5)
    tween.tween_interval(1.5)
    tween.tween_property(%LogoRect, "modulate:a", 0.0, 1.5)

    await tween.finished

    if SceneManager:
        SceneManager.change_scene("res://scenes/title_cinematic_screen.tscn", false)
