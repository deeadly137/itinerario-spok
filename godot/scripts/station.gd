class_name Station
extends Area2D
## Ponto interativo do mapa (microscopio, tanques, atmosfera, sonda).
##
## Sem o circulo no chao (ele nao significava nada): o proprio equipamento
## acende quando o jogador chega perto e o botao USAR fica ativo. O alcance
## do toque e o MESMO do botao USAR, e generoso de proposito (celular).

signal pressed(station_id: String)

## Multiplicador do alcance de interacao (toque direto e botao USAR).
const REACH := 1.35

var station_id := ""
var display_name := ""
var done := false
var locked := false
var base: ColorRect
var tag: Label
var pad_radius := 135.0   ## alcance efetivo em unidades de mundo (com REACH)
var tint_color := Color("2b6cb0")
var _near := false


func setup(id: String, pos: Vector2, _label_text: String, short: String, tint: Color, radius_world := 100.0) -> void:
	station_id = id
	display_name = short
	tint_color = tint
	pad_radius = radius_world * REACH
	position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = pad_radius
	shape.shape = circle
	add_child(shape)
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
	input_event.connect(_on_input)


func _on_input(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(station_id)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(station_id)
		get_viewport().set_input_as_handled()


## Realce quando o jogador esta dentro da area: acende o proprio equipamento
## (substitui o antigo circulo do chao).
func set_near(v: bool) -> void:
	if _near == v:
		return
	_near = v
	var glow := Color(1.45, 1.45, 1.45) if v else Color.WHITE
	if base:
		base.self_modulate = glow
	if tag:
		tag.self_modulate = glow


func mark_done() -> void:
	done = true
	base.color = Color("1f7a4d")
	tag.add_theme_color_override("font_color", Color(0.55, 1, 0.65))


func set_locked(v: bool) -> void:
	locked = v
	base.modulate.a = 0.35 if v else 1.0
	tag.modulate.a = 0.35 if v else 1.0
