extends Control

var transitioning: bool = false

func _ready():
    # Load and play intro video
    var stream = load("res://assets/media/videos/intro_teaser.mp4")
    if stream:
        %VideoPlayer.stream = stream
        %VideoPlayer.autoplay = true
        %VideoPlayer.play()
    else:
        push_error("Missing intro teaser video")
        call_deferred("_navigate_next")
        return

    %VideoPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
    _navigate_next()

func _navigate_next():
    if transitioning:
        return
    transitioning = true
    SceneManager.change_scene("res://scenes/title_cinematic_screen.tscn", false)
