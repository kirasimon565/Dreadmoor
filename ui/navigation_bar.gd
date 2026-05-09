extends Control

signal back_pressed
signal home_pressed
signal recent_pressed

func _ready():
    $HBoxContainer/BackBtn.pressed.connect(_on_back_pressed)
    $HBoxContainer/HomeBtn.pressed.connect(_on_home_pressed)
    $HBoxContainer/RecentBtn.pressed.connect(_on_recent_pressed)

func _on_back_pressed():
    emit_signal("back_pressed")

func _on_home_pressed():
    emit_signal("home_pressed")
    # Usually routes to apps screen
    var sm = SceneManager
    if sm:
        sm.change_scene("res://scenes/apps_screen.tscn")

func _on_recent_pressed():
    emit_signal("recent_pressed")
