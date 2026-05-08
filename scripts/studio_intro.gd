extends Control

@onready var anim_player = $AnimationPlayer

func _ready():
    # Hide Navigation Bar & Status Bar during intro
    var nav_bar = get_node_or_null("/root/NavigationBar")
    if nav_bar:
        nav_bar.hide()

    var status_bar = get_node_or_null("/root/StatusBar")
    if status_bar:
        status_bar.hide()

    anim_player.animation_finished.connect(_on_animation_finished)
    anim_player.play("sequence")

func _on_animation_finished(anim_name: String):
    if anim_name == "sequence":
        SceneManager.goto_scene("res://scenes/welcome_screen.tscn")
