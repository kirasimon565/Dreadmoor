extends Control

func _ready():
    %AnswerBtn.pressed.connect(_on_answer)
    %DeclineBtn.pressed.connect(_on_decline)

    if AudioManager:
        AudioManager.play_bgm("res://assets/music/ringtone.ogg", 0.0)

func _on_answer():
    if AudioManager:
        AudioManager.stop_bgm(0.0)
    if SceneManager:
        SceneManager.change_scene("res://scenes/active_call_screen.tscn", false)

func _on_decline():
    if AudioManager:
        AudioManager.stop_bgm(0.0)
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
