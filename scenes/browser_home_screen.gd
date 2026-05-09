extends Control

func _ready():
    $NavigationBar.back_pressed.connect(_on_back)
    %ArticleBtn.pressed.connect(_on_article)

func _on_back():
    SceneManager.change_scene("res://scenes/apps_screen.tscn")

func _on_article():
    SceneManager.change_scene("res://scenes/article_viewer_screen.tscn")
