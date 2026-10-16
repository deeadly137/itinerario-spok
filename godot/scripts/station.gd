class_name Station
extends Area2D
## Ponto interativo do mapa (microscopio, tanques, atmosfera, sonda).
##
## Sem "!" e sem "OK" gigante: o piso circular mostra ONDE ficar para usar
## e ele acende quando o jogador chega perto. Ao concluir, o equipamento
## muda de cor. A area de toque tambem e a area de interacao (bem maior
## que antes, que era o que deixava a "hitbox" pequena demais no celular).

signal pressed(station_id: String)

var station_id := ""
var display_name := ""
var done := false
var locked := false
var base: ColorRect
var tag: Label
var pad: Control
var pad_radius := 100.0
var tint_color := Color("2b6cb0")
var _near := false


func setup(id: String, pos: Vector2, _label_text: String, short: String, tint: Color, radius_world := 100.0) -> void:
	station_id = id
	display_name = short
	tint_color = tint
	pad_radius = radius_world
	position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius_world
	shape.shape = circle
	add_child(shape)
	# piso circular (area de interacao) - desenhado no chao
	pad = Control.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size = Vector2(pad_radius * 2.0, pad_radius * 2.0)
	pad.position = Vector2(-pad_radius, -pad_radius)
	pad.draw.connect(_draw_pad)
	add_child(pad)
	# equipamento
	base = ColorRect.new()
	base.color = tint
	base.size = Vector2(120, 90)
	base.position = Vector2(-60, -90)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	tag = Label.new()
	tag.text = short
	tag.add_theme_font_size_override("font_size", 44)
	tag.position = Vector2(-30, -88)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)
	pad.queue_redraw()
	input_event.connect(_on_input)


func _draw_pad() -> void:
	var c := Vector2(pad_radius, pad_radius)
	var fill_a := 0.30 if _near else 0.14
	var edge_a := 0.75 if _near else 0.28
	var col := Color(tint_color.r, tint_color.g, tint_color.b, fill_a)
	pad.draw_circle(c, pad_radius, col)
	pad.draw_arc(c, pad_radius, 0.0, TAU, 64, Color(1, 1, 1, edge_a), 4.0)


func _on_input(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(station_id)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(station_id)
		get_viewport().set_input_as_handled()


## Realce quando o jogador esta dentro da area.
func set_near(v: bool) -> void:
	if _near == v:
		return
	_near = v
	if pad:
		pad.queue_redraw()


func mark_done() -> void:
	done = true
	base.color = Color("1f7a4d")
	tag.add_theme_color_override("font_color", Color(0.55, 1, 0.65))


func set_locked(v: bool) -> void:
	locked = v
	base.modulate.a = 0.35 if v else 1.0
	tag.modulate.a = 0.35 if v else 1.0
