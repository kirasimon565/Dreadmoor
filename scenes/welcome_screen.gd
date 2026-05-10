extends Control

var has_active_game: bool = false
var music_ready: bool = false

func _ready():
    _check_active_game()
    _init_music()
    _setup_ui()

func _check_active_game():
    # Check if the player has started a game and saved it
    has_active_game = GlobalState.GetFlag("intro_cinematic_seen", false)
    if has_active_game:
        %ActionBtnLabel.text = "CONTINUE"
    else:
        %ActionBtnLabel.text = "START GAME"

func _init_music():
    if AudioManager:
        AudioManager.play_bgm("res://assets/music/welcome_theme.mp3", 2.0)
        music_ready = true
        %MusicIndicatorGroup.visible = true
        %AnimationPlayer.play("music_bars")
    else:
        %MusicIndicatorGroup.visible = false

func _setup_ui():
    %AnimationPlayer.play("breathing_logo")

    %ActionBtn.button_down.connect(_on_action_down)
    %ActionBtn.button_up.connect(_on_action_up)
    %ActionBtn.pressed.connect(_on_action_pressed)
    %ActionBtn.mouse_entered.connect(_on_action_enter)
    %ActionBtn.mouse_exited.connect(_on_action_exit)

func _on_action_down():
    var tween = create_tween()
    tween.tween_property(%ActionBtnGroup, "scale", Vector2(0.97, 0.97), 0.1)
    %ActionBtnBg.color = Color(0.24, 0.85, 0.95, 0.12)
    %ActionBtnBorder.border_color = Color(0.24, 0.85, 0.95, 0.8)

func _on_action_up():
    var tween = create_tween()
    tween.tween_property(%ActionBtnGroup, "scale", Vector2(1.0, 1.0), 0.1)
    %ActionBtnBg.color = Color(0.1, 0.1, 0.12, 0.25)
    %ActionBtnBorder.border_color = Color(0.24, 0.85, 0.95, 0.4)

func _on_action_enter():
    %ActionBtnBg.color = Color(0.1, 0.1, 0.12, 0.35)

func _on_action_exit():
    _on_action_up()

func _on_action_pressed():
    if AudioManager:
        AudioManager.stop_bgm(1.5)

    if has_active_game:
        # Continue Game -> go straight to messenger
        if GlobalScheduler and GlobalState.CurrentNodeId != "":
            GlobalScheduler.processNode(GlobalState.CurrentNodeId)
        SceneManager.change_scene("res://scenes/messenger_list.tscn", false)
    else:
        # First Launch -> Intro Trailer
        GlobalState.SetFlag("intro_cinematic_seen", true)
        GlobalState.Save()
        SceneManager.change_scene("res://scenes/intro_trailer_screen.tscn", false)
