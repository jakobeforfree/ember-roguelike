extends Node
## Top-level flow: Camp (Hub) <-> Run.

var hub: Hub
var run: RunController
var _hub_layer: CanvasLayer


func _ready() -> void:
	_hub_layer = CanvasLayer.new()
	add_child(_hub_layer)
	hub = Hub.new()
	hub.start_run.connect(start_run)
	_hub_layer.add_child(hub)


func start_run(seed_value: int = -1) -> RunController:
	_hub_layer.visible = false
	run = RunController.new()
	run.run_finished.connect(_on_run_finished)
	add_child(run)
	run.start(seed_value)
	return run


func _on_run_finished() -> void:
	run.queue_free()
	run = null
	_hub_layer.visible = true
	hub.refresh()
