class_name Station
extends Area2D
## Ponto interativo do mapa (microscópio, tanques, atmosfera, sonda).

signal pressed(station_id: String)

var station_id := ""
var display_name := ""
var done := false
var locked := false
var base: ColorRect
var tag: Label
var alert: Label


func setup(id: String, pos: Vector2, _label_text: String, short: String, tint: Color) -> void:
	station_id = id
	display_name = short
	position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 60.0
	shape.shape = circle
	add_child(shape)
	base = ColorRect.new()
	base.color = tint
	base.size = Vector2(120, 90)
	base.position = Vector2(-60, -90)
	add_child(base)
	tag = Label.new()
	tag.text = short
	tag.add_theme_font_size_override("font_size", 44)
	tag.position = Vector2(-30, -88)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)
	alert = Label.new()
	alert.text = "!"
	alert.add_theme_font_size_override("font_size", 34)
	alert.add_theme_color_override("font_color", Color(1, 0.75, 0.2))
	alert.position = Vector2(52, -130)
	alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(alert)
	input_event.connect(_on_input)


func _on_input(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(station_id)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(station_id)
		get_viewport().set_input_as_handled()


func mark_done() -> void:
	done = true
	alert.text = "OK"
	alert.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))


func set_locked(v: bool) -> void:
	locked = v
	alert.visible = not v
