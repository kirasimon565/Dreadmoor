extends Control

func _ready():
    # Attempt to connect to GameClock using C# interoperability
    var game_clock = get_node_or_null("/root/GameClock")
    if game_clock:
        # Initial setting
        if game_clock.has_method("GetFormattedTime"):
            %TimeLabel.text = game_clock.GetFormattedTime()

        # Connect to signal if we can
        if game_clock.has_signal("GameTimeAdvanced"):
            game_clock.connect("GameTimeAdvanced", _on_time_advanced)

func _on_time_advanced(new_time_unix: int):
    var game_clock = get_node_or_null("/root/GameClock")
    if game_clock and game_clock.has_method("GetFormattedTime"):
        %TimeLabel.text = game_clock.GetFormattedTime()
