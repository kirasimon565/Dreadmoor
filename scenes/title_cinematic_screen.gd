extends Control

func _ready():
    %StartButton.modulate.a = 0.0

    var tween = create_tween()
    tween.tween_property(%StartButton, "modulate:a", 1.0, 2.0).set_delay(1.0)

    %StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed():
    if SceneManager:
        # Route to intro trailer instead of direct welcome screen for cinematic flow
        SceneManager.change_scene("res://scenes/intro_trailer_screen.tscn")
