extends Control

func _ready():
    if GameClock:
        %TimeLabel.text = GameClock.GetFormattedTime()
        GameClock.connect("GameTimeAdvanced", _on_time_advanced)

func _on_time_advanced(new_time_unix: int):
    if GameClock:
        %TimeLabel.text = GameClock.GetFormattedTime()
