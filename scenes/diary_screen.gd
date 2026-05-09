extends Control

var _pages = []
var _current_page_idx = 0
var _is_typing = false
var _full_text = ""
var _tween: Tween

func _ready():
    var navbar = $NavigationBar
    if navbar and navbar.has_signal("back_pressed"):
        navbar.back_pressed.connect(_on_back)

    # Adding page controls
    var next_btn = Button.new()
    next_btn.text = "Next >"
    next_btn.pressed.connect(_on_next)

    var prev_btn = Button.new()
    prev_btn.text = "< Prev"
    prev_btn.pressed.connect(_on_prev)

    var hbox = HBoxContainer.new()
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    hbox.add_child(prev_btn)
    hbox.add_child(next_btn)

    # We add this above navigation bar but inside the VBox
    var parent = %DiaryText.get_parent()
    parent.add_child(hbox)

    _load_diary_pages()
    _render_page(_current_page_idx)

func _load_diary_pages():
    _pages.clear()

    var episode = "ep01"
    if GlobalState:
        episode = GlobalState.GetVariable("ActiveEpisodeId", "ep01")

    var page_idx = 1
    while true:
        var path = "res://episodes/diary/page_%02d.json" % page_idx
        if not FileAccess.file_exists(path):
            break

        var file = FileAccess.open(path, FileAccess.READ)
        if file:
            var json_text = file.get_as_text()
            var json = JSON.new()
            var err = json.parse(json_text)
            if err == OK:
                var data = json.get_data()

                var is_unlocked = true
                var flag_name = "DiaryPage" + str(page_idx) + "Unlocked"
                if GlobalState:
                    if page_idx > 1:
                        is_unlocked = GlobalState.GetFlag(flag_name, false)

                _pages.append({
                    "unlocked": is_unlocked,
                    "content": data.get("content", [])
                })
        page_idx += 1

    if _pages.is_empty():
        _pages.append({
            "unlocked": true,
            "content": ["June 12th.", "The woods were quiet today.", "Too quiet.", "I found the marker they told me about, but the box was empty."]
        })

func _render_page(idx: int):
    if idx < 0 or idx >= _pages.size():
        return

    _current_page_idx = idx

    var page = _pages[idx]
    if not page["unlocked"]:
        %DiaryText.text = "[color=#555555][ ENCRYPTED DATA CORRUPTED ][/color]"
        _is_typing = false
        if _tween: _tween.kill()
        return

    _full_text = ""
    for line in page["content"]:
        _full_text += str(line) + "\n\n"

    %DiaryText.text = ""
    %DiaryText.visible_ratio = 0.0
    %DiaryText.text = _full_text

    _is_typing = true
    var char_count = %DiaryText.get_total_character_count()
    var duration = char_count * 0.05

    if _tween: _tween.kill()
    _tween = create_tween()
    _tween.tween_property(%DiaryText, "visible_ratio", 1.0, duration).set_ease(Tween.EASE_OUT)
    _tween.finished.connect(func(): _is_typing = false)

func _on_next():
    if _current_page_idx + 1 < _pages.size():
        _render_page(_current_page_idx + 1)
        if AudioManager:
            AudioManager.play_sfx("res://assets/media/sfx/typing.mp3")

func _on_prev():
    if _current_page_idx > 0:
        _render_page(_current_page_idx - 1)
        if AudioManager:
            AudioManager.play_sfx("res://assets/media/sfx/typing.mp3")

func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if _is_typing:
            if _tween: _tween.kill()
            %DiaryText.visible_ratio = 1.0
            _is_typing = false

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")
