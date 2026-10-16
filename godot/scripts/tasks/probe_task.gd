class_name ProbeTask
extends BaseTask
## Minigame final — SONDA EXTERNA.
##
## Fase 1: coletar as 3 CHAVES (segurar o dedo no painel ate a barra
##         encher; soltar esvazia). Fase 2: alarme + escolha do protocolo
##         no tempo. Fase 3: resultado.
## Sem botao gigante de OK e sem lista rolavel.

const PROTOCOLS := [
	{"t": "A) JOGAR FERRO NO OCEANO", "ok": false,
		"msg": "O ferro estimula algas, mas o bloom consome o oxigenio, mata peixe e a decomposicao devolve CO2. O pH nao volta a 8.2."},
	{"t": "B) CORTAR EMISSOES E PROTEGER O RECIFE", "ok": true,
		"msg": "Ataca a CAUSA: menos CO2 no ar = menos CO2 dissolvido = menos acido carbonico. Recife e manguezal saudaveis ainda capturam carbono azul."},
	{"t": "C) BOMBEAR OXIGENIO NA AGUA", "ok": false,
		"msg": "Oxigenio nao neutraliza acido carbonico: a acidez continua corroendo a concha do pteropode e o esqueleto do coral."},
]

var phase := "keys"
var fill := [0.0, 0.0, 0.0]
var got := [false, false, false]
var held := -1
var bars: Array = []
var time_left := 30.0
var timer_running := false
var timer_label: Label


func build_task(g) -> void:
	super.build_task(g)
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.gui_input.connect(_on_stage)
	_build_keys()


func _build_keys() -> void:
	head("SONDA EXTERNA - COLETA DAS 3 CHAVES")
	hint("SEGURE o dedo em cada painel ate a barra encher. A chave fica TRAVADA ao encher - colete as 3.")
	for i in 3:
		var b := Control.new()
		b.position = Vector2(90.0 + i * 260.0, 8.0)
		b.size = Vector2(240.0, STAGE_H - 16.0)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.draw.connect(_draw_key.bind(i))
		stage.add_child(b)
		bars.append(b)


func can_close() -> bool:
	return not timer_running


func _on_stage(event: InputEvent) -> void:
	if phase != "keys" or done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		held = _bar_at(event.position) if event.pressed else -1
	elif event is InputEventScreenTouch:
		held = _bar_at(event.position) if event.pressed else -1


func _bar_at(p: Vector2) -> int:
	for i in 3:
		var b: Control = bars[i]
		if b and Rect2(b.position, b.size).has_point(p):
			return i
	return -1


func _process(delta: float) -> void:
	if done:
		return
	if phase == "keys":
		for i in 3:
			if got[i]:
				continue
			if held == i:
				fill[i] = minf(1.0, fill[i] + delta * 0.55)
			else:
				fill[i] = maxf(0.0, fill[i] - delta * 0.30)
			if fill[i] >= 1.0:
				# chave coletada: TRAVA cheia (antes todas precisavam ficar
				# cheias ao mesmo tempo, o que era impossivel com 1 dedo)
				fill[i] = 1.0
				got[i] = true
				AudioSys.click()
			(bars[i] as Control).queue_redraw()
		if got[0] and got[1] and got[2]:
			_start_alarm()
	elif phase == "alarm" and timer_running:
		time_left -= delta
		timer_label.text = "TEMPO: %d s" % int(ceil(maxf(time_left, 0.0)))
		if time_left <= 0.0:
			_show_outcome(false, "A sonda perdeu a janela de manobra: o recife colapsou enquanto voces discutiam. Voce pode tentar de novo.")


func _draw_key(i: int) -> void:
	# As barras sao liberadas (queue_free) ao virar a fase, mas o desenho
	# ainda pode disparar no mesmo frame: sem esta guarda, `bars[i]` estoura.
	if i >= bars.size() or not is_instance_valid(bars[i]):
		return
	var b: Control = bars[i]
	var w: float = b.size.x
	var h: float = b.size.y
	b.draw_rect(Rect2(0, 0, w, h), Color("0a1a26"))
	b.draw_rect(Rect2(0, 0, w, h), Color(0.35, 1.0, 0.55) if got[i] else Color("2f6b8f"), false, 4.0)
	var tx := 24.0
	var ty := 24.0
	var tw := w - 48.0
	var th := h - 92.0
	var fh: float = th * float(fill[i])
	b.draw_rect(Rect2(tx, ty, tw, th), Color("08131c"))
	var fcol := Color(0.35, 1.0, 0.55, 0.9) if got[i] else Color(0.35, 0.85, 1.0, 0.9)
	b.draw_rect(Rect2(tx, ty + (th - fh), tw, fh), fcol)
	var txt := ("CHAVE %d - OK" % (i + 1)) if got[i] else ("SEGURE - CHAVE %d" % (i + 1))
	var tcol := Color(0.45, 1.0, 0.6) if got[i] else Color(0.75, 0.9, 1.0)
	b.draw_string(ThemeDB.fallback_font, Vector2(0, h - 10.0), txt,
		HORIZONTAL_ALIGNMENT_CENTER, w, 22, tcol)


func _start_alarm() -> void:
	phase = "alarm"
	held = -1
	for c in stage.get_children():
		c.queue_free()
	bars.clear()
	head("SONDA EXTERNA - CAMERA AO VIVO")
	AudioSys.start_alarm()
	stage_image("res://assets/img/probe-reef.jpeg", Rect2(16, 44, 356, 300))
	var alarm := label("ALERTA DE COLAPSO ACIDIFICANTE\npH EM 7.7", 25, Color(1, 0.55, 0.4))
	alarm.position = Vector2(396, 2)
	alarm.size = Vector2(540, 56)
	stage.add_child(alarm)
	var q := label("Escolha o protocolo para estabilizar o recife:", 19)
	q.position = Vector2(396, 62)
	q.size = Vector2(540, 26)
	stage.add_child(q)
	for i in PROTOCOLS.size():
		var b := key_button(str(PROTOCOLS[i]["t"]), 540, 76)
		b.add_theme_font_size_override("font_size", 21)
		b.position = Vector2(396, 94 + i * 84)
		b.pressed.connect(_choose.bind(i))
		stage.add_child(b)
	timer_label = label("TEMPO: 30 s", 23, Color("ffd75e"))
	timer_label.position = Vector2(396, 344)
	timer_label.size = Vector2(540, 30)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(timer_label)
	timer_running = true
	time_left = 30.0


func _choose(i: int) -> void:
	if not timer_running:
		return
	timer_running = false
	AudioSys.stop_alarm()
	AudioSys.click()
	var p: Dictionary = PROTOCOLS[i]
	_show_outcome(bool(p["ok"]), str(p["msg"]))


func _show_outcome(win: bool, text: String) -> void:
	phase = "outcome"
	timer_running = false
	for c in stage.get_children():
		c.queue_free()
	head("RESULTADO DA SONDA")
	var t := label("VITORIA: O RECIFE RESPIRA" if win else "DERROTA: O RECIFE COLAPSOU",
		28, Color(0.45, 1.0, 0.55) if win else Color(1, 0.5, 0.45))
	t.position = Vector2(24, 12)
	t.size = Vector2(STAGE_W - 48.0, 40)
	stage.add_child(t)
	var b := label(text, 21)
	b.position = Vector2(24, 62)
	b.size = Vector2(STAGE_W - 48.0, 220)
	stage.add_child(b)
	if win:
		GameState.probe_done = true
		GameState.probe_finished.emit(true)
		var ok := key_button("CONCLUIR MISSAO", 340, 72)
		ok.position = Vector2((STAGE_W - 340.0) * 0.5, 296)
		ok.pressed.connect(func() -> void: finish("MISSAO CUMPRIDA: pH de volta a 8.2 e o recife calcifica de novo.", "probe"))
		stage.add_child(ok)
	else:
		var again := key_button("TENTAR DE NOVO", 340, 72)
		again.position = Vector2((STAGE_W - 340.0) * 0.5, 296)
		again.pressed.connect(_retry)
		stage.add_child(again)


func _retry() -> void:
	phase = "keys"
	fill = [0.0, 0.0, 0.0]
	got = [false, false, false]
	held = -1
	done = false
	for c in stage.get_children():
		c.queue_free()
	bars.clear()
	_build_keys()
