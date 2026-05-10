extends Control

var transitioning: bool = false

func _ready():
    # Load and play title intro video
    var stream = load("res://assets/media/videos/title_intro.mp4")
    if stream:
        %VideoPlayer.stream = stream
        %VideoPlayer.autoplay = true
        %VideoPlayer.play()
    else:
        push_error("Missing title intro video")
        call_deferred("_navigate_next")
        return

    %VideoPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
    _navigate_next()

func _navigate_next():
    if transitioning:
        return
    transitioning = true

    # After title cinematic, game actually begins
    if GlobalScheduler:
        # Load from node or use a default
        var start_node = GlobalState.GetVariable("start_node_id", "SCENE_1_NEWS_ARTICLE")
        GlobalState.CurrentNodeId = start_node
        GlobalState.Save()

        GlobalScheduler.processNode(start_node)

    SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
