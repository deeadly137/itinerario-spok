class_name MicroTask
extends BaseTask
## Minigame 1 — FOCO DO MICROSCOPIO.
##
## Nada de quiz: o jogador ARRASTA um cursor de foco e tem que SEGURAR
## dentro da faixa nitida (a imagem desfoca de verdade conforme o erro).
## 3 amostras. O aprendizado (pH 8.2 / carbonato) entra no fim.

const TARGETS := [0.20, 0.50, 0.80]
const TOL := 0.07          # meia-largura da faixa alvo
const HOLD := 0.85         # tempo segurando no foco para travar a amostra

var focus := 0.30
var target := TARGETS[0]
var round := 0
var hold := 0.0
var dragging := false
var view: Control
var slider: Control
var info: Label


func build_task(g) -> void:
	super.build_task(g)
	head("ANALISES - FOCO DO MICROSCOPIO")
	info = label("AMOSTRA 1/3", 23, Color("bfeeff"))
	info.position = Vector2(0, 4)
	info.size = Vector2(STAGE_W, 30)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(info)
	view = Control.new()
	view.position = Vector2(250, 40)
	view.size = Vector2(440, 216)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_view)
	stage.add_child(view)
	slider = Control.new()
	slider.position = Vector2(120, 272)
	slider.size = Vector2(700, 92)
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	slider.gui_input.connect(_on_slider)
	slider.draw.connect(_draw_slider)
	stage.add_child(slider)
	_next_round()


func _next_round() -> void:
	hold = 0.0
	info.text = "AMOSTRA %d/3 - segure o foco na faixa verde" % (round + 1)
	hint("Arraste na barra ate o detalhe aparecer nitido e MANTENHA.")
	view.queue_redraw()
	slider.queue_redraw()


func _process(delta: float) -> void:
	if done:
		return
	if absf(focus - target) <= TOL:
		hold += delta
		if hold >= HOLD:
			_lock_round()
	else:
		hold = maxf(0.0, hold - delta * 2.5)
	view.queue_redraw()
	slider.queue_redraw()


func _on_slider(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var pressed: bool = event.pressed
		if pressed:
			dragging = true
			_set_from(event.position.x)
		else:
			dragging = false
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		_set_from(event.position.x)


func _set_from(x: float) -> void:
	focus = clampf(x / slider.size.x, 0.0, 1.0)


func _lock_round() -> void:
	AudioSys.key()
	round += 1
	if round >= TARGETS.size():
		finish("AMOSTRA NITIDA! A concha do pteropode precisa de pH 8.2: abaixo disso falta carbonato (CO3--) e a calcificacao para.", "micro")
	else:
		good("Foco travado! Proxima amostra...")
		target = TARGETS[round]
		_next_round()


# ------------------------------ desenho ---------------------------------

func _draw_view() -> void:
	var err := clampf(absf(focus - target) / 0.42, 0.0, 1.0)
	view.draw_rect(Rect2(Vector2.ZERO, view.size), Color("050d16"))
	var c := view.size * 0.5
	view.draw_circle(c, 102.0, Color("0b2233"))
	var col := Color("a8ecff")
	var w := 3.0 + err * 15.0
	var a := 0.9 - err * 0.5
	for i in 4:
		var r := 18.0 + i * 22.0
		if err > 0.05:
			for k in 8:
				var off := Vector2(cos(TAU * k / 8.0), sin(TAU * k / 8.0)) * (err * 17.0)
				view.draw_arc(c + off, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, a / 9.0), w)
		else:
			view.draw_arc(c, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, a), w)
	# detalhe (a corrosao) so aparece quando esta nitido
	if err < 0.25:
		var da := (0.25 - err) / 0.25
		for k in 12:
			var ang := TAU * k / 12.0
			var p := c + Vector2(cos(ang), sin(ang)) * 62.0
			view.draw_circle(p, 3.2, Color(1.0, 0.55, 0.45, da))
	view.draw_arc(c, 106.0, 0.0, TAU, 64, Color("2f6b8f"), 3.0)


func _draw_slider() -> void:
	var w: float = slider.size.x
	var y := 42.0
	var h := 26.0
	slider.draw_rect(Rect2(0, y, w, h), Color("0d2233"))
	var tx := (target - TOL) * w
	var tw := TOL * 2.0 * w
	slider.draw_rect(Rect2(tx, y - 7, tw, h + 14), Color(0.3, 1.0, 0.5, 0.30))
	slider.draw_rect(Rect2(tx, y - 7, 2, h + 14), Color(0.4, 1.0, 0.6))
	slider.draw_rect(Rect2(tx + tw - 2, y - 7, 2, h + 14), Color(0.4, 1.0, 0.6))
	if absf(focus - target) <= TOL:
		slider.draw_rect(Rect2(0, y - 16, w, 8), Color(0.2, 0.6, 0.9, 0.45))
		slider.draw_rect(Rect2(0, y - 16, w * clampf(hold / HOLD, 0.0, 1.0), 8), Color(0.4, 1.0, 0.6))
	var cx := focus * w
	slider.draw_rect(Rect2(cx - 4, y - 24, 8, h + 48), Color("7fd4f0"))
	slider.draw_circle(Vector2(cx, y + h * 0.5), 15.0, Color("bfeeff"))
