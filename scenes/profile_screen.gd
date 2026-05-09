extends Control

func _ready():
    var navbar = $NavigationBar
    navbar.back_pressed.connect(_on_back)

    _load_profile_data()

func _load_profile_data():
    if not GlobalState: return

    var thread_id = GlobalState.GetVariable("ActiveThread", "rebecca").to_lower()

    var tex = load("res://assets/characters/" + thread_id.split(" ")[0] + ".png")
    if not tex: tex = load("res://assets/characters/unknown.png")
    if tex: %Avatar.texture = tex

    if thread_id.contains("rebecca"):
        %NameLabel.text = "Rebecca Stone"
        var status = "Offline"
        if GlobalState.GetFlag("RebeccaOnline", false): status = "Online"

        %NotesLabel.text = "[color=#aaaaaa]Status:[/color] " + status + "\n[color=#aaaaaa]Notes:[/color] Last seen in the woods. Hasn't answered calls since yesterday."
    else:
        %NameLabel.text = GlobalState.GetVariable("ActiveThread", "Unknown")
        %NotesLabel.text = "[color=#aaaaaa]Status:[/color] Offline\n[color=#aaaaaa]Notes:[/color] No data available."

func _on_back():
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")
