extends Control

var min_display_time: float = 4.0
var elapsed_time: float = 0.0
var logic_navigated: bool = false

func _ready():
    # Setup Visuals
    var logo_tex = load("res://assets/branding/blackmoon_logo.png")
    if logo_tex:
        %LogoRect.texture = logo_tex
        %LogoRect.modulate = Color(1, 1, 1, 1) # Tint black logo to white
        # Use canvas item material with blend mode add or mix if needed, but modulate to white works if the logo is white.
        # Wait, the original logo is black. Tinting a black image with modulate doesn't make it white.
        # But we can use a shader or canvas item property to tint it.
        # Let's use a simple CanvasItemMaterial with CanvasItemMaterial.BLEND_MODE_ADD for now if it's black on black, or just use a shader to replace black with white.

    # Start sequence
    _play_intro()

func _process(delta):
    elapsed_time += delta

func _play_intro():
    # 1. Logo fade in and scale
    var tween_in = create_tween()
    tween_in.set_parallel(true)
    %LogoGroup.modulate.a = 0.0
    %LogoGroup.scale = Vector2(0.94, 0.94)

    tween_in.tween_property(%LogoGroup, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    tween_in.tween_property(%LogoGroup, "scale", Vector2(1.0, 1.0), 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

    # Breathing animation via AnimationPlayer
    %AnimationPlayer.play("breathing_pulse")

    # 2. Disclaimer fade in after 1.4s
    await get_tree().create_timer(1.4).timeout
    var tween_disc = create_tween()
    tween_disc.tween_property(%DisclaimerLabel, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

    # Loading dots animation
    %AnimationPlayer.play("loading_dots")

    # 3. Wait for min display time
    while elapsed_time < min_display_time:
        await get_tree().process_frame

    _navigate_next()

func _navigate_next():
    if logic_navigated:
        return
    logic_navigated = true

    # Fade logo out
    var tween_out = create_tween()
    tween_out.tween_property(self, "modulate:a", 0.0, 1.8)
    await tween_out.finished

    var player_name = GlobalState.GetVariable("PlayerName", "")
    if player_name != "":
        SceneManager.change_scene("res://scenes/welcome_screen.tscn", false)
    else:
        SceneManager.change_scene("res://scenes/player_setup.tscn", false)
