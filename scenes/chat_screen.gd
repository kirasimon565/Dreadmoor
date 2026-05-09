extends Control

var _current_thread: String = "rebecca"
var _typing_audio_player: AudioStreamPlayer

func _ready():
    %BackBtn.pressed.connect(_on_back_pressed)

    _typing_audio_player = AudioStreamPlayer.new()
    _typing_audio_player.stream = load("res://assets/media/sfx/typing.mp3")
    _typing_audio_player.bus = "SFX"
    add_child(_typing_audio_player)

    if GlobalState and GlobalState.has_method("GetVariable"):
        _current_thread = GlobalState.GetVariable("ActiveThread", "Rebecca Stone")
        %ThreadName.text = _current_thread

    if _current_thread.to_lower() == "unknown" or _current_thread.to_lower() == "unknown number":
        var bg = load("res://assets/media/images/skull_noir_bg.png")
        if bg: %Background.texture = bg
    else:
        var bg = load("res://assets/media/images/default_chat_bg.png")
        if bg: %Background.texture = bg

        var avatar_path = "res://assets/characters/" + _current_thread.split(" ")[0].to_lower() + ".png"
        var tex = load(avatar_path)
        if not tex: tex = load("res://assets/characters/unknown.png")
        if tex: %AvatarRect.texture = tex

    _load_chat_history()

    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler:
        if scheduler.has_signal("NodeExecuted"):
            scheduler.connect("NodeExecuted", _on_node_executed)
        if scheduler.has_signal("TypingStatusChanged"):
            scheduler.connect("TypingStatusChanged", _on_typing_changed)

        if not scheduler.get("_isPlaying") and GlobalState.GetVariable("ActiveEpisodeId") == "ep01":
            var next_node = GlobalState.GetVariable("CurrentNodeId", "SCENE_1_START")
            if next_node:
                scheduler.StartPlayback(next_node)

func _load_chat_history():
    for child in %MessageList.get_children():
        child.queue_free()

func _on_back_pressed():
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")

func _on_node_executed(node_id: String, type: String, payload: Dictionary):
    if type == "Chat_Event" or type == "Message":
        var content = payload.get("content", "")
        var sender = payload.get("sender", "unknown")

        var is_player = sender.to_lower() == "player"
        var is_secret = _current_thread.to_lower().contains("unknown")

        if not is_player and AudioManager:
            AudioManager.play_sfx("res://assets/media/sfx/message_receive.mp3")

        _add_message_bubble(content, is_player, is_secret)

        if GlobalState:
            GlobalState.SetVariable("CurrentNodeId", node_id)

    elif type == "Choice_Prompt":
        _show_choices(payload)

    elif type == "Media_Message":
        var path = payload.get("media_path", "")
        var is_video = payload.get("is_video", false)
        _add_media_bubble(path, is_video, payload.get("sender", "unknown").to_lower() == "player")

func _on_typing_changed(thread_id: String, character_id: String, is_typing: bool):
    %TypingIndicator.visible = is_typing
    if is_typing:
        var char_name = character_id.capitalize()
        if char_name.to_lower() == "player": char_name = "You"
        %TypingIndicator.text = char_name + " is typing..."
        _scroll_to_bottom()

        if not _typing_audio_player.playing:
            _typing_audio_player.play()
    else:
        _typing_audio_player.stop()

func _show_choices(payload: Dictionary):
    var options = payload.get("options", [])
    if options.is_empty(): return

    %ChoiceOverlay.visible = true
    for child in %ChoiceOverlay.get_children():
        child.queue_free()

    for opt in options:
        if typeof(opt) == TYPE_DICTIONARY:
            var btn = Button.new()
            btn.text = opt.get("text", "...")
            btn.theme_override_font_sizes.font_size = 32
            btn.custom_minimum_size = Vector2(0, 80)

            var next_id = opt.get("next", "")
            btn.pressed.connect(func(): _on_choice_selected(next_id, btn.text))
            %ChoiceOverlay.add_child(btn)

    _scroll_to_bottom()

func _on_choice_selected(next_id: String, choice_text: String):
    %ChoiceOverlay.visible = false
    _add_message_bubble(choice_text, true, _current_thread.to_lower().contains("unknown"))

    if AudioManager:
        AudioManager.play_sfx("res://assets/media/sfx/typing.mp3")

    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler and not next_id.is_empty():
        await get_tree().create_timer(0.5).timeout
        scheduler.StartPlayback(next_id)

func _add_message_bubble(text: String, is_player: bool, is_secret: bool = false):
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 80 if is_player else 20)
    margin.add_theme_constant_override("margin_right", 20 if is_player else 80)

    var panel = PanelContainer.new()
    var style = StyleBoxFlat.new()

    if is_secret:
        style.bg_color = Color(0.1, 0.1, 0.1, 1) # black charcoal
    else:
        style.bg_color = Color(0.18, 0.20, 0.25, 1) if is_player else Color(0.25, 0.25, 0.25, 0.9)
    style.set_corner_radius_all(24)
    panel.add_theme_stylebox_override("panel", style)

    var label = Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.theme_override_font_sizes.font_size = 32
    if is_secret:
        label.theme_override_colors.font_color = Color(0.8, 0.2, 0.2, 1) # red accents

    var inner_margin = MarginContainer.new()
    inner_margin.add_theme_constant_override("margin_left", 24)
    inner_margin.add_theme_constant_override("margin_right", 24)
    inner_margin.add_theme_constant_override("margin_top", 16)
    inner_margin.add_theme_constant_override("margin_bottom", 16)

    inner_margin.add_child(label)
    panel.add_child(inner_margin)

    var vbox = VBoxContainer.new()
    vbox.add_child(panel)

    var time_lbl = Label.new()
    var clock = get_node_or_null("/root/GameClock")
    time_lbl.text = clock.GetFormattedTime() if clock else "12:00"

    if is_secret:
        time_lbl.theme_override_colors.font_color = Color(0.48, 0.16, 0.16, 0.65) # dark red
    else:
        time_lbl.theme_override_colors.font_color = Color(1, 1, 1, 0.55) # white

    time_lbl.theme_override_font_sizes.font_size = 20
    time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_player else HORIZONTAL_ALIGNMENT_LEFT
    vbox.add_child(time_lbl)

    margin.add_child(vbox)

    if is_player:
        margin.size_flags_horizontal = Control.SIZE_SHRINK_END
    else:
        margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

    margin.modulate.a = 0.0
    margin.position.y = 20
    %MessageList.add_child(margin)

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(margin, "modulate:a", 1.0, 0.2)
    tween.tween_property(margin, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE)

    _scroll_to_bottom()

func _add_media_bubble(path: String, is_video: bool, is_player: bool):
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(300, 300)

    if not is_video:
        var tex = load("res://" + path.replace("assets/", "assets/"))
        if tex:
            var trect = TextureRect.new()
            trect.texture = tex
            trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
            trect.set_anchors_preset(Control.PRESET_FULL_RECT)
            trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
            btn.add_child(trect)
    else:
        btn.text = "[ VIDEO ]\nTap to play"
        btn.theme_override_font_sizes.font_size = 32

    btn.pressed.connect(func(): _open_media_viewer(path, is_video))
    %MessageList.add_child(btn)
    _scroll_to_bottom()

func _open_media_viewer(path: String, is_video: bool):
    var viewer_scene = load("res://scenes/media_viewer.tscn")
    if viewer_scene:
        var viewer = viewer_scene.instantiate()
        get_tree().root.get_node("Main/OverlayLayer").add_child(viewer)
        viewer.load_media(path, is_video)

func _scroll_to_bottom():
    await get_tree().process_frame
    var scroll = %MessageList.get_parent().get_parent()
    if scroll is ScrollContainer:
        var max_scroll = scroll.get_v_scroll_bar().max_value
        var tween = create_tween()
        tween.tween_property(scroll, "scroll_vertical", max_scroll, 0.1)
