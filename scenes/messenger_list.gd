extends Control

func _ready():
    _populate_threads()

func _populate_threads():
    var threads = []

    if GlobalState:
        var r_last = GlobalState.GetVariable("RebeccaLastMsg", "Are you there?")
        threads.append({"id": "rebecca", "name": "Rebecca Stone", "last_msg": r_last, "unread": GlobalState.GetFlag("RebeccaUnread", true)})

        if GlobalState.GetFlag("UnknownContactUnlocked", false):
            var u_last = GlobalState.GetVariable("UnknownLastMsg", "I see you.")
            threads.append({"id": "unknown", "name": "Unknown Number", "last_msg": u_last, "unread": GlobalState.GetFlag("UnknownUnread", true)})
    else:
        threads.append({"id": "rebecca", "name": "Rebecca Stone", "last_msg": "Are you there?", "unread": true})

    for child in %ThreadList.get_children():
        child.queue_free()

    for t in threads:
        var hbox = HBoxContainer.new()
        hbox.custom_minimum_size = Vector2(0, 160)

        var avatar_rect = TextureRect.new()
        avatar_rect.custom_minimum_size = Vector2(120, 120)
        avatar_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var avatar_path = "res://assets/characters/" + t["id"].to_lower() + ".png"
        var tex = load(avatar_path)
        if not tex: tex = load("res://assets/characters/unknown.png")
        if tex: avatar_rect.texture = tex
        hbox.add_child(avatar_rect)

        var btn = Button.new()
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.theme_override_font_sizes.font_size = 36
        var text = t["name"] + "\n" + t["last_msg"]
        if t["unread"]:
            btn.modulate = Color(1, 1, 1, 1)
        else:
            btn.modulate = Color(0.6, 0.6, 0.6, 1)
        btn.text = text
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn.flat = true

        btn.pressed.connect(func(): _open_chat(t["id"], t["name"]))
        hbox.add_child(btn)

        %ThreadList.add_child(hbox)

func _open_chat(thread_id: String, thread_name: String):
    if GlobalState:
        GlobalState.SetVariable("ActiveThread", thread_name)
        GlobalState.SetVariable("ActiveThreadId", thread_id)
        GlobalState.SetFlag(thread_name.split(" ")[0] + "Unread", false)

    if SceneManager:
        SceneManager.change_scene("res://scenes/chat_screen.tscn")
