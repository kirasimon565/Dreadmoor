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
        AudioManager.play_bgm("res://assets/music/ringtone.ogg", 0.0)

    # Auto-decline after timeout
    await get_tree().create_timer(15.0).timeout
    if is_inside_tree() and visible:
        _on_decline()

func _on_answer():
    if AudioManager:
        AudioManager.stop_bgm(0.0)
        AudioManager.play_sfx("res://assets/music/call_connect.ogg")

    # Inform scheduler that call was answered
    if GlobalState:
        GlobalState.SetFlag("CallAnswered", true)

    if SceneManager:
        SceneManager.change_scene("res://scenes/active_call_screen.tscn", false)

func _on_decline():
    if AudioManager:
        AudioManager.stop_bgm(0.0)

    # Inform scheduler that call was declined
    if GlobalState:
        GlobalState.SetFlag("CallAnswered", false)

    # Trigger scheduler branch for decline
    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler and GlobalState:
        var next_node = GlobalState.GetVariable("CallDeclineNodeId", "")
        if not next_node.is_empty():
            scheduler.StartPlayback(next_node)

    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
