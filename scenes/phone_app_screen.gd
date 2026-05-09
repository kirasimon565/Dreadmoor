extends Control

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)
    %CallBtn.pressed.connect(_on_call)

    # Populate dialpad
    for i in range(1, 10):
        var btn = Button.new()
        btn.custom_minimum_size = Vector2(160, 160)
        btn.text = str(i)
        btn.theme_override_font_sizes.font_size = 64
        $VBoxContainer/Dialpad.add_child(btn)

    var star = Button.new()
    star.custom_minimum_size = Vector2(160, 160)
    star.text = "*"
    star.theme_override_font_sizes.font_size = 64
    $VBoxContainer/Dialpad.add_child(star)

    var zero = Button.new()
    zero.custom_minimum_size = Vector2(160, 160)
    zero.text = "0"
    zero.theme_override_font_sizes.font_size = 64
    $VBoxContainer/Dialpad.add_child(zero)

    var hash = Button.new()
    hash.custom_minimum_size = Vector2(160, 160)
    hash.text = "#"
    hash.theme_override_font_sizes.font_size = 64
    $VBoxContainer/Dialpad.add_child(hash)

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")

func _on_call():
    # Calling logic...
    pass
