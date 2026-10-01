extends Node
## Top-level flow: Camp (3D scene that is also the menu) <-> Run.

var menu: CampMenu
var camp: CampScene
var run: RunController
var _menu_layer: CanvasLayer


func _ready() -> void:
	get_tree().root.theme = UiKit.theme()
	_menu_layer = CanvasLayer.new()
	add_child(_menu_layer)
	menu = CampMenu.new()
	menu.start_run.connect(start_run)
	_menu_layer.add_child(menu)
	_show_camp()


func _show_camp() -> void:
	camp = CampScene.new()
	add_child(camp)
	move_child(camp, 0)
	menu.camp = camp
	_menu_layer.visible = true
	menu.refresh()


func start_run(seed_value: int = -1) -> RunController:
	_menu_layer.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if camp:
		camp.queue_free()
		camp = null
	run = RunController.new()
	run.run_finished.connect(_on_run_finished)
	add_child(run)
	run.start(seed_value)
	return run


func _on_run_finished() -> void:
	run.queue_free()
	run = null
	_show_camp()
	menu.fade_in()
