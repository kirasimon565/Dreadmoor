extends Control

var _pages = []
var _current_page_idx = 0
var _is_typing = false
var _full_text = ""

func _ready():
    var navbar = $NavigationBar
    navbar.back_pressed.connect(_on_back)

    _load_diary_pages()
    _render_page(_current_page_idx)

func _load_diary_pages():
    _pages.clear()

    var episode = "ep01"
    if GlobalState and GlobalState.has_method("GetVariable"):
        episode = GlobalState.GetVariable("ActiveEpisodeId", "ep01")

    var page_idx = 1
    while true:
        # Use the correct path based on memory recording
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
                if GlobalState and GlobalState.has_method("GetFlag"):
                    if page_idx > 1:
                        is_unlocked = GlobalState.GetFlag(flag_name, false)

                _pages.append({
                    "unlocked": is_unlocked,
                    "content": data.get("content", [])
                })
        page_idx += 1

    # Fallback mock data
    if _pages.is_empty():
        _pages.append({
            "unlocked": true,
            "content": ["June 12th.", "The woods were quiet today.", "Too quiet.", "I found the marker they told me about, but the box was empty."]
        })

func _render_page(idx: int):
    if idx < 0 or idx >= _pages.size():
        return

    var page = _pages[idx]
    if not page["unlocked"]:
        %DiaryText.text = "[color=#555555][ ENCRYPTED DATA CORRUPTED ][/color]"
        return

    _full_text = ""
    for line in page["content"]:
        _full_text += line + "\n\n"

    %DiaryText.text = ""
    %DiaryText.visible_characters = 0
    %DiaryText.text = _full_text

    _is_typing = true
    var char_count = %DiaryText.get_total_character_count()
    var duration = char_count * 0.05

    var tween = create_tween()
    tween.tween_property(%DiaryText, "visible_ratio", 1.0, duration)
    tween.finished.connect(func(): _is_typing = false)

func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if _is_typing:
            %DiaryText.visible_ratio = 1.0
            _is_typing = false

func _on_back():
    if SceneManager:
        SceneManager.change_scene("res://scenes/apps_screen.tscn")
