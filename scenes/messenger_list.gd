extends Control

func _ready():
    _populate_dummy_threads()

func _populate_dummy_threads():
    var threads = [
        {"name": "Rebecca Stone", "last_msg": "Are you there?", "unread": true},
        {"name": "Unknown Number", "last_msg": "I see you.", "unread": true},
        {"name": "Mom", "last_msg": "Call me back.", "unread": false}
    ]

    for t in threads:
        var btn = Button.new()
        btn.custom_minimum_size = Vector2(0, 140)
        btn.theme_override_font_sizes.font_size = 36
        var text = t["name"] + "\n" + t["last_msg"]
        if t["unread"]:
            btn.modulate = Color(1, 1, 1, 1)
        else:
            btn.modulate = Color(0.6, 0.6, 0.6, 1)
        btn.text = text
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

        btn.pressed.connect(func(): _open_chat(t["name"]))
        %ThreadList.add_child(btn)

func _open_chat(thread_name: String):
    # Pass thread context via GlobalState or instantiate directly
    if GlobalState:
        GlobalState.SetVariable("ActiveThread", thread_name)
    if true:
        SceneManager.change_scene("res://scenes/chat_screen.tscn")
