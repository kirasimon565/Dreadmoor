extends Control

func _ready():
    %SkipBtn.pressed.connect(_on_skip)

    # Auto progress after X seconds
    var timer = get_tree().create_timer(4.0)
    timer.timeout.connect(_on_skip)

func _on_skip():
    SceneManager.change_scene("res://scenes/player_setup.tscn")
