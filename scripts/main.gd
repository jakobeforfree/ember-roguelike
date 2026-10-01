extends Node
## Top-level flow: Camp (3D scene + Hub UI) <-> Run.

var hub: Hub
var camp: CampScene
var run: RunController
var _hub_layer: CanvasLayer


func _ready() -> void:
	get_tree().root.theme = UiKit.theme()
	_hub_layer = CanvasLayer.new()
	add_child(_hub_layer)
	hub = Hub.new()
	hub.start_run.connect(start_run)
	_hub_layer.add_child(hub)
	_show_camp()


func _show_camp() -> void:
	camp = CampScene.new()
	add_child(camp)
	move_child(camp, 0)
	_hub_layer.visible = true
	hub.refresh()


func start_run(seed_value: int = -1) -> RunController:
	_hub_layer.visible = false
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
