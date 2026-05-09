extends Control

func _ready():
    %MessengerBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/messenger_list.tscn"))
    %DiaryBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/diary_screen.tscn"))
    %ProfileBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/player_profile_screen.tscn"))
    %BrowserBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/browser_home_screen.tscn"))
    %PhoneBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/phone_app_screen.tscn"))
    %SettingsBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/settings_screen.tscn"))
    %SystemBtn.pressed.connect(func(): SceneManager.change_scene("res://scenes/save_load_screen.tscn"))
