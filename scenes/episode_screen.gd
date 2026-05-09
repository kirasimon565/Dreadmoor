extends Control

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)

    var ep1_btn = $VBoxContainer/ScrollContainer/VBoxContainer/Ep1Btn
    ep1_btn.pressed.connect(_on_ep1_selected)

    _update_progress()

func _update_progress():
    # As per memory: Database integer percentage values are converted to 0.0-1.0 doubles
    # using (ep.progress / 100).clamp(0.0, 1.0)
    var progress_int = 0
    if GlobalState and GlobalState.has_method("GetVariable"):
        progress_int = GlobalState.GetVariable("Ep01Progress", "0").to_int()

    var progress_float = clamp(float(progress_int) / 100.0, 0.0, 1.0)

    var ep1_btn = $VBoxContainer/ScrollContainer/VBoxContainer/Ep1Btn
    ep1_btn.text = "EPISODE 1: The Disappearance\nProgress: " + str(int(progress_float * 100)) + "%"

func _on_ep1_selected():
    if GlobalState:
        GlobalState.ActiveEpisodeId = "ep01"
    if SceneManager:
        SceneManager.change_scene("res://scenes/recap_screen.tscn")

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")
