extends Control

func _ready():
    %BackBtn.pressed.connect(_on_back_pressed)

    # Connect to GlobalScheduler
    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler:
        if scheduler.has_signal("NodeExecuted"):
            scheduler.connect("NodeExecuted", _on_node_executed)
        if scheduler.has_signal("TypingStatusChanged"):
            scheduler.connect("TypingStatusChanged", _on_typing_changed)

        # Try to load and play scene_01.json
        if scheduler.has_method("LoadSceneGraph"):
            scheduler.LoadSceneGraph("ep01", "scene_01.json")
            # We assume SCENE_1_START is a valid node ID in scene_01.json based on common Dreadmoor conventions
            scheduler.StartPlayback("SCENE_1_START")
        else:
            # Fallback mock playback if parsing fails
            var test_node = {"id": "msg1", "type": "Chat_Event", "sender": "rebecca", "content": "Hello? Is anyone there?", "typing_delay": 2.0}
            scheduler.EnqueueNode(test_node)

func _on_back_pressed():
    if SceneManager:
        SceneManager.change_scene("res://scenes/messenger_list.tscn")

func _on_node_executed(node_id: String, type: String, payload: Dictionary):
    if type == "Chat_Event" or type == "Message": # Handle potential JSON key differences
        var content = payload.get("content", "")
        var sender = payload.get("sender", "unknown")
        var is_player = sender == "player" or sender == "Player"
        _add_message_bubble(content, is_player)
    elif type == "Choice_Prompt":
        _show_choices(payload)

func _on_typing_changed(thread_id: String, character_id: String, is_typing: bool):
    %TypingIndicator.visible = is_typing
    if is_typing:
        %TypingIndicator.text = character_id.capitalize() + " is typing..."

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
            btn.pressed.connect(func(): _on_choice_selected(next_id))
            %ChoiceOverlay.add_child(btn)

func _on_choice_selected(next_id: String):
    %ChoiceOverlay.visible = false
    var scheduler = get_node_or_null("/root/GlobalScheduler")
    if scheduler and scheduler.has_method("StartPlayback") and not next_id.is_empty():
        scheduler.StartPlayback(next_id)

func _add_message_bubble(text: String, is_player: bool):
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 40 if is_player else 20)
    margin.add_theme_constant_override("margin_right", 20 if is_player else 40)

    var panel = PanelContainer.new()
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.2, 0.25, 1) if is_player else Color(0.15, 0.15, 0.2, 0.9)
    style.set_corner_radius_all(20)
    panel.add_theme_stylebox_override("panel", style)

    var label = Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.theme_override_font_sizes.font_size = 36

    var inner_margin = MarginContainer.new()
    inner_margin.add_theme_constant_override("margin_left", 20)
    inner_margin.add_theme_constant_override("margin_right", 20)
    inner_margin.add_theme_constant_override("margin_top", 20)
    inner_margin.add_theme_constant_override("margin_bottom", 20)

    inner_margin.add_child(label)
    panel.add_child(inner_margin)
    margin.add_child(panel)

    if is_player:
        margin.size_flags_horizontal = Control.SIZE_SHRINK_END
    else:
        margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

    %MessageList.add_child(margin)

    await get_tree().process_frame
    var scroll = %MessageList.get_parent()
    scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
