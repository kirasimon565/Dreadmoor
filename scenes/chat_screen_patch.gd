extends "res://scenes/chat_screen.gd"

# Patching to hook media click logic
func _add_media_bubble(path: String, is_video: bool, is_player: bool):
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(300, 300)

    # Check if image and show thumbnail
    if not is_video:
        var tex = load(path)
        if tex:
            btn.icon = tex
            btn.expand_icon = true
            btn.clip_text = true
    else:
        btn.text = "[ VIDEO ]\nTap to play"
        btn.theme_override_font_sizes.font_size = 32

    btn.pressed.connect(func(): _open_media_viewer(path, is_video))
    %MessageList.add_child(btn)
    _scroll_to_bottom()
