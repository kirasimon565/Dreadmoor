extends Control

func _ready():
    %AnswerBtn.pressed.connect(_on_answer)
    %DeclineBtn.pressed.connect(_on_decline)

    # Pulse animation for answer button
    var tween = create_tween().set_loops()
    tween.tween_property(%AnswerBtn, "modulate:a", 0.5, 0.5)
    tween.tween_property(%AnswerBtn, "modulate:a", 1.0, 0.5)

    if GlobalState:
        var caller = GlobalState.GetVariable("IncomingCallerName", "Unknown Number")
        %CallerName.text = caller

    if AudioManager:
        AudioManager.play_bgm("res://assets/media/sfx/phone_ringtone_glitch.mp3", 0.0)

    # Auto-decline after timeout
    await get_tree().create_timer(15.0).timeout
    if is_inside_tree() and visible:
        _on_decline()

func _on_answer():
    if AudioManager:
        AudioManager.stop_bgm(0.0)

    if GlobalState:
        GlobalState.SetFlag("CallAnswered", true)

    if SceneManager:
        SceneManager.change_scene("res://scenes/active_call_screen.tscn", false)

func _on_decline():
    if AudioManager:
        AudioManager.stop_bgm(0.0)

    if GlobalState:
        GlobalState.SetFlag("CallAnswered", false)

    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler and GlobalState:
        var next_node = GlobalState.GetVariable("CallDeclineNodeId", "")
        if not next_node.is_empty():
            scheduler.StartPlayback(next_node)

    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
