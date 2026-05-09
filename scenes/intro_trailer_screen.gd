extends Control

func _ready():
    %SkipBtn.pressed.connect(_on_skip)

    var stream = load("res://assets/media/videos/intro_teaser.mp4")
    if stream:
        %VideoPlayer.stream = stream
        %VideoPlayer.play()
        %VideoPlayer.finished.connect(_on_skip)
    else:
        var timer = get_tree().create_timer(4.0)
        timer.timeout.connect(_on_skip)

func _on_skip():
    if %VideoPlayer.is_playing():
        %VideoPlayer.stop()
    SceneManager.change_scene("res://scenes/player_setup.tscn")
