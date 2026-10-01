extends Node
## Player preferences, saved separately from game progress (user://settings.cfg).

signal changed

const PATH := "user://settings.cfg"

var fullscreen := false
var screen_shake := true
var damage_numbers := true
var path := PATH


func _ready() -> void:
	load_settings()


func set_value(key: String, value) -> void:
	set(key, value)
	if key == "fullscreen":
		apply_fullscreen()
	save_settings()
	changed.emit()


func apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in ["fullscreen", "screen_shake", "damage_numbers"]:
		cfg.set_value("prefs", k, get(k))
	cfg.save(path)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for k in ["fullscreen", "screen_shake", "damage_numbers"]:
		set(k, cfg.get_value("prefs", k, get(k)))
	# Browsers only allow fullscreen from a click, so don't force it at startup there.
	if not OS.has_feature("web"):
		apply_fullscreen()
