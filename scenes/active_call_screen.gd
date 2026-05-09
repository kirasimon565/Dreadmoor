extends Control

var time_elapsed = 0

func _ready():
    %EndBtn.pressed.connect(_on_end)
    $CallTimer.timeout.connect(_on_tick)

    # In a real impl, start playing the voice over audio node here
    if AudioManager:
        AudioManager.play_sfx("res://assets/media/audio/threatening_call_01.mp3")

func _on_tick():
    time_elapsed += 1
    var m = time_elapsed / 60
    var s = time_elapsed % 60
    %TimerLabel.text = "%02d:%02d" % [m, s]

func _on_end():
    # End event playback if scheduler is managing a call script
    if GlobalScheduler:
        GlobalScheduler.StopPlayback()

    if true:
        SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
