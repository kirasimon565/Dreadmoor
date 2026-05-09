extends Node

signal FlagChanged(flagName: String, value: bool)

var ActiveEpisodeId: String = "ep01"
var CurrentNodeId: String = "SCENE_1_NEWS_ARTICLE"
var ActiveChoiceId: Variant = null # Can be String or null

var Flags: Dictionary = {}
var Variables: Dictionary = {}

func SetFlag(flagName: String, value: bool) -> void:
    Flags[flagName] = value
    emit_signal("FlagChanged", flagName, value)

func GetFlag(flagName: String, defaultValue: bool = false) -> bool:
    if Flags.has(flagName):
        return Flags[flagName]
    return defaultValue

func SetVariable(varName: String, value: String) -> void:
    Variables[varName] = value

func GetVariable(varName: String, defaultValue: String = "") -> String:
    if Variables.has(varName):
        return Variables[varName]
    return defaultValue

func Save() -> void:
    var save_dict = {
        "ActiveEpisodeId": ActiveEpisodeId,
        "CurrentNodeId": CurrentNodeId,
        "ActiveChoiceId": ActiveChoiceId,
        "Flags": Flags,
        "Variables": Variables
    }

    if GameClock:
        save_dict["CurrentGameTimeUnix"] = GameClock.CurrentGameTimeUnix

    var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_dict))
        print("GlobalState: Saved data to user://save_data.json")

func Load() -> void:
    if not FileAccess.file_exists("user://save_data.json"):
        print("GlobalState: No save data found.")
        return

    var file = FileAccess.open("user://save_data.json", FileAccess.READ)
    if file:
        var json_str = file.get_as_text()
        var json = JSON.new()
        var err = json.parse(json_str)
        if err == OK:
            var data = json.get_data()
            if typeof(data) == TYPE_DICTIONARY:
                ActiveEpisodeId = data.get("ActiveEpisodeId", "ep01")
                CurrentNodeId = data.get("CurrentNodeId", "SCENE_1_NEWS_ARTICLE")
                ActiveChoiceId = data.get("ActiveChoiceId", null)
                Flags = data.get("Flags", {})
                Variables = data.get("Variables", {})

                if GameClock and data.has("CurrentGameTimeUnix"):
                    GameClock.CurrentGameTimeUnix = data["CurrentGameTimeUnix"]

                print("GlobalState: Loaded data from user://save_data.json")
