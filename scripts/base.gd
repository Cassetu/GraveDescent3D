extends Node3D

func _ready() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.z_index = 100
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.modulate.a = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas := CanvasLayer.new()
	canvas.add_child(overlay)
	add_child(canvas)

	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(overlay, "modulate:a", 0.0, 1.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(overlay.queue_free)
