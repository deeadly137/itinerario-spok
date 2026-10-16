class_name TankTask
extends BaseTask
## Minigame 2 — CALIBRAR VALVULAS DO TANQUE.
##
## Tres valvulas com o marcador oscilando: toque quando ele estiver na
## faixa verde. Erra? A valvula acelera. (Nada de quiz.)
## Aprendizado: quem repoe o oxigenio e captura o CO2 sao as algas /
## ervas marinhas pela fotossintese.

const N := 3
const VALVE_W := 250.0
const TRACK_TOP := 34.0
const TRACK_H := 250.0

var pos := [0.5, 0.5, 0.5]
var zone := [0.30, 0.55, 0.40]
var half := [0.10, 0.09, 0.08]
var speed := [1.5, 1.9, 2.3]
var phase := [0.0, 1.9, 3.7]
var locked := [false, false, false]
var t := 0.0
var valves: Array = []
var hits := 0
var misses := 0


func build_task(g) -> void:
	super.build_task(g)
	head("TANQUE DE CALCIFICACAO - VALVULAS")
	hint("Toque na valvula quando o marcador estiver na FAIXA VERDE. Acerte as 3.")
	for i in N:
		var v := Control.new()
		v.position = Vector2(58.0 + i * (VALVE_W + 26.0), 6.0)
		v.size = Vector2(VALVE_W, STAGE_H - 12.0)
		v.mouse_filter = Control.MOUSE_FILTER_STOP
		v.gui_input.connect(_on_valve.bind(i))
		v.draw.connect(_draw_valve.bind(i))
		stage.add_child(v)
		valves.append(v)
	_update_hint()


func _update_hint() -> void:
	if locked[0] and locked[1] and locked[2]:
		return
	hint("Toque na valvula quando o marcador estiver na FAIXA VERDE.  (%d/3 acertos)" % hits)


func _process(delta: float) -> void:
	if done:
		return
	t += delta
	for i in N:
		if locked[i]:
			continue
		pos[i] = 0.5 + 0.5 * sin(t * speed[i] + phase[i])
		(valves[i] as Control).queue_redraw()


func _on_valve(event: InputEvent, i: int) -> void:
	if done or locked[i]:
		return
	var press := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		press = event.pressed
	elif event is InputEventScreenTouch:
		press = event.pressed
	if not press:
		return
	if absf(pos[i] - zone[i]) <= half[i]:
		locked[i] = true
		hits += 1
		AudioSys.click()
		_update_hint()
		(valves[i] as Control).queue_redraw()
		if hits >= N:
			finish("VALVULAS CALIBRADAS! As algas e ervas marinhas fazem fotossintese: capturam CO2 e devolvem O2 - sem elas o tanque acidifica.", "tank")
	else:
		misses += 1
		speed[i] *= 1.25
		bad("Fora da faixa! A valvula dispara mais rapido. (erros: %d)" % misses)


func _draw_valve(i: int) -> void:
	var v: Control = valves[i]
	var cx: float = v.size.x * 0.5
	var ok: bool = locked[i]
	# corpo da valvula
	v.draw_rect(Rect2(0, 0, v.size.x, v.size.y), Color("0a1a26"))
	v.draw_rect(Rect2(cx - 30.0, TRACK_TOP - 6.0, 60.0, TRACK_H + 12.0), Color("123044"), false, 2.0)
	# trilho
	v.draw_rect(Rect2(cx - 22.0, TRACK_TOP, 44.0, TRACK_H), Color("08131c"))
	if ok:
		v.draw_rect(Rect2(cx - 22.0, TRACK_TOP, 44.0, TRACK_H), Color(0.25, 0.85, 0.45, 0.45))
		v.draw_rect(Rect2(cx - 26.0, TRACK_TOP - 6.0, 52.0, TRACK_H + 12.0), Color(0.3, 1.0, 0.5, 0.9), false, 3.0)
	else:
		# faixa alvo (verde)
		var zt: float = TRACK_TOP + (1.0 - float(zone[i]) - float(half[i])) * TRACK_H
		var zh: float = float(half[i]) * 2.0 * TRACK_H
		v.draw_rect(Rect2(cx - 22.0, zt, 44.0, zh), Color(0.3, 1.0, 0.5, 0.35))
		v.draw_rect(Rect2(cx - 22.0, zt, 44.0, 2.0), Color(0.4, 1.0, 0.6))
		v.draw_rect(Rect2(cx - 22.0, zt + zh - 2.0, 44.0, 2.0), Color(0.4, 1.0, 0.6))
		# marcador oscilante
		var y: float = TRACK_TOP + (1.0 - float(pos[i])) * TRACK_H
		var near: bool = absf(float(pos[i]) - float(zone[i])) <= float(half[i])
		v.draw_rect(Rect2(cx - 34.0, y - 6.0, 68.0, 12.0), Color("ffd75e") if not near else Color("6bff8f"))
	# rotulo curto
	var font := ThemeDB.fallback_font
	var lbl := "TRAVADA" if ok else "VALVULA %d" % (i + 1)
	var col := Color(0.5, 1.0, 0.65) if ok else Color(0.7, 0.85, 1.0)
	v.draw_string(font, Vector2(cx - 60.0, v.size.y - 14.0), lbl, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 20, col)
