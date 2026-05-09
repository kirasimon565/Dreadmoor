extends Control

var time_elapsed = 0

func _ready():
    %EndBtn.pressed.connect(_on_end)
    $CallTimer.timeout.connect(_on_tick)

    if GlobalState:
        var caller = GlobalState.GetVariable("IncomingCallerName", "Unknown Number")
        %CallerName.text = caller

    # If scheduler has an active call script, execute it
    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler:
        var call_node = GlobalState.GetVariable("CallAcceptNodeId", "")
        if not call_node.is_empty() and not scheduler.get("_isPlaying"):
            scheduler.StartPlayback(call_node)

        # Listen for scheduler ending
        if scheduler.has_signal("PlaybackCompleted"):
            scheduler.connect("PlaybackCompleted", _on_playback_ended)

func _on_tick():
    time_elapsed += 1
    var m = time_elapsed / 60
    var s = time_elapsed % 60
    %TimerLabel.text = "%02d:%02d" % [m, s]

func _on_end():
    _cleanup_and_exit()

func _on_playback_ended():
    # Call ends when script ends
    _cleanup_and_exit()

func _cleanup_and_exit():
    if AudioManager:
        AudioManager.play_sfx("res://assets/music/call_disconnect.ogg")

    if GlobalScheduler and GlobalScheduler.has_method("StopPlayback"):
        GlobalScheduler.StopPlayback()

    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
