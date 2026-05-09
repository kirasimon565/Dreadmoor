extends Control

var _dialed_number = ""

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)
    %CallBtn.pressed.connect(_on_call)

    # Header label for dialed number
    var dial_display = Label.new()
    dial_display.name = "DialDisplay"
    dial_display.theme_override_font_sizes.font_size = 64
    dial_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    dial_display.custom_minimum_size = Vector2(0, 100)
    $VBoxContainer.add_child(dial_display)
    $VBoxContainer.move_child(dial_display, 1) # Put below header

    # Populate dialpad
    for i in range(1, 10):
        _create_dial_btn(str(i))

    _create_dial_btn("*")
    _create_dial_btn("0")
    _create_dial_btn("#")

func _create_dial_btn(txt: String):
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(160, 160)
    btn.text = txt
    btn.theme_override_font_sizes.font_size = 64
    btn.pressed.connect(func(): _on_digit_pressed(txt))
    $VBoxContainer/Dialpad.add_child(btn)

func _on_digit_pressed(digit: String):
    _dialed_number += digit
    $VBoxContainer/DialDisplay.text = _dialed_number

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")

func _on_call():
    if _dialed_number == "": return

    # Play dial sound
    if AudioManager:
        AudioManager.play_sfx("res://assets/music/call_connect.ogg")

    if GlobalState:
        GlobalState.SetVariable("IncomingCallerName", _dialed_number)

    # Transition to active call (outgoing)
    SceneManager.change_scene("res://scenes/active_call_screen.tscn", false)
