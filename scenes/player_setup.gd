extends Control

var selected_gender: String = "female"
var is_saving: bool = false

func _ready():
    %ConfirmBtn.pressed.connect(_on_confirm)
    %MaleBtn.pressed.connect(_on_male_selected)
    %FemaleBtn.pressed.connect(_on_female_selected)

    _update_gender_ui()

    # Hide any warning label by default
    %WarningLabel.modulate.a = 0.0

func _on_male_selected():
    selected_gender = "male"
    _update_gender_ui()

func _on_female_selected():
    selected_gender = "female"
    _update_gender_ui()

func _update_gender_ui():
    var cyan_color = Color(0.24, 0.85, 0.95, 1.0)
    var cyan_bg = Color(0.24, 0.85, 0.95, 0.1)
    var normal_border = Color(1, 1, 1, 0.08)
    var normal_text = Color(1, 1, 1, 0.7)
    var trans_bg = Color(0, 0, 0, 0)

    if selected_gender == "male":
        # Manually construct StyleBoxFlat because modifying shared stylebox modifies both
        var male_sb = StyleBoxFlat.new()
        male_sb.bg_color = cyan_bg
        male_sb.border_color = cyan_color
        male_sb.set_border_width_all(1)
        male_sb.set_corner_radius_all(20)
        %MaleBtnRect.add_theme_stylebox_override("panel", male_sb)
        %MaleBtnLabel.add_theme_color_override("font_color", cyan_color)

        var female_sb = StyleBoxFlat.new()
        female_sb.bg_color = trans_bg
        female_sb.border_color = normal_border
        female_sb.set_border_width_all(1)
        female_sb.set_corner_radius_all(20)
        %FemaleBtnRect.add_theme_stylebox_override("panel", female_sb)
        %FemaleBtnLabel.add_theme_color_override("font_color", normal_text)
    else:
        var female_sb = StyleBoxFlat.new()
        female_sb.bg_color = cyan_bg
        female_sb.border_color = cyan_color
        female_sb.set_border_width_all(1)
        female_sb.set_corner_radius_all(20)
        %FemaleBtnRect.add_theme_stylebox_override("panel", female_sb)
        %FemaleBtnLabel.add_theme_color_override("font_color", cyan_color)

        var male_sb = StyleBoxFlat.new()
        male_sb.bg_color = trans_bg
        male_sb.border_color = normal_border
        male_sb.set_border_width_all(1)
        male_sb.set_corner_radius_all(20)
        %MaleBtnRect.add_theme_stylebox_override("panel", male_sb)
        %MaleBtnLabel.add_theme_color_override("font_color", normal_text)

func _show_warning(msg: String):
    %WarningLabel.text = msg
    var tween = create_tween()
    tween.tween_property(%WarningLabel, "modulate:a", 1.0, 0.2)
    tween.tween_interval(2.0)
    tween.tween_property(%WarningLabel, "modulate:a", 0.0, 0.5)

func _on_confirm():
    if is_saving: return

    var player_name = %NameEdit.text.strip_edges()
    var player_phone = %PhoneEdit.text.strip_edges()

    if player_name == "":
        _show_warning("Please enter your name.")
        return
    if player_phone == "":
        _show_warning("Please enter your phone number.")
        return

    is_saving = true
    %ConfirmLabel.text = "SAVING..."

    # Fake saving delay
    await get_tree().create_timer(0.3).timeout

    GlobalState.SetVariable("PlayerName", player_name)
    GlobalState.SetVariable("PlayerPhone", player_phone)
    GlobalState.SetVariable("PlayerGender", selected_gender)
    GlobalState.Save()

    SceneManager.change_scene("res://scenes/welcome_screen.tscn", false)
