extends Control

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)
    %VolumeSlider.value_changed.connect(_on_volume)

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")

func _on_volume(value: float):
    # Map 0-1 to dB
    pass
