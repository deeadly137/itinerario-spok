class_name ProbeTask
extends BaseTask
## Clímax — Sonda Externa: 30 s para escolher 1 dos 3 protocolos.
## B vence; A, C e timeout mostram derrota com retry.

var timer_running := false
var time_left := 30.0
var timer_label: Label
var alarm_box: VBoxContainer
var outcome_box: VBoxContainer
var outcome_title: Label
var outcome_img: TextureRect
var outcome_text: Label


func build_task(g) -> void:
	super.build_task(g)
	head("SONDA EXTERNA - CAMERA AO VIVO")
	alarm_box = VBoxContainer.new()
	alarm_box.add_theme_constant_override("separation", 10)
	vb.add_child(alarm_box)
	var feed := TextureRect.new()
	if ResourceLoader.exists("res://assets/img/probe-reef.jpeg"):
		feed.texture = load("res://assets/img/probe-reef.jpeg")
	feed.custom_minimum_size = Vector2(0, 260)
	feed.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feed.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	alarm_box.add_child(feed)
	var alarm := Label.new()
	alarm.text = "ALERTA DE COLAPSO ACIDIFICANTE - pH EM 7.7"
	alarm.add_theme_font_size_override("font_size", 26)
	alarm.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
	alarm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alarm_box.add_child(alarm)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 30)
	alarm_box.add_child(timer_label)
	var intro := Label.new()
	intro.text = "Escolha UM protocolo de emergencia antes do cronometro zerar:"
	intro.add_theme_font_size_override("font_size", 22)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alarm_box.add_child(intro)
	_add_proto("A", "PROTOCOLO A - SOLUCAO QUIMICA", "Jogar toneladas de alcalinizantes para neutralizar a acidez.")
	_add_proto("B", "PROTOCOLO B - PROTECAO SISTEMICA", "Areas de Protecao Marinha com manguezais/algas + reducao global de emissoes.")
	_add_proto("C", "PROTOCOLO C - ENGENHARIA GENETICA", "Modificar os corais geneticamente para ignorar o acido.")
	outcome_box = VBoxContainer.new()
	outcome_box.add_theme_constant_override("separation", 10)
	outcome_box.visible = false
	vb.add_child(outcome_box)
	outcome_img = TextureRect.new()
	outcome_img.custom_minimum_size = Vector2(0, 260)
	outcome_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	outcome_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	outcome_box.add_child(outcome_img)
	outcome_title = Label.new()
	outcome_title.add_theme_font_size_override("font_size", 30)
	outcome_box.add_child(outcome_title)
	outcome_text = Label.new()
	outcome_text.add_theme_font_size_override("font_size", 22)
	outcome_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_box.add_child(outcome_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	outcome_box.add_child(row)
	var retry := Button.new()
	retry.text = "TENTAR OUTRO PROTOCOLO"
	retry.custom_minimum_size = Vector2(0, 72)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(_restart)
	row.add_child(retry)
	var hub := Button.new()
	hub.text = "VOLTAR AO MAPA"
	hub.custom_minimum_size = Vector2(0, 72)
	hub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub.pressed.connect(func() -> void: game._close_task())
	row.add_child(hub)
	mk_feedback()
	if GameState.probe_done:
		_show_outcome("B")
	else:
		_start_timer()


func _add_proto(id: String, name: String, desc: String) -> void:
	var b := Button.new()
	b.text = name + "\n" + desc
	b.custom_minimum_size = Vector2(0, 96)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func() -> void: _choose(id))
	alarm_box.add_child(b)


func _start_timer() -> void:
	time_left = 30.0
	timer_running = true
	alarm_box.visible = true
	outcome_box.visible = false
	AudioSys.start_alarm()


func _process(delta: float) -> void:
	if not timer_running:
		return
	time_left -= delta
	var s := maxi(0, int(ceil(time_left)))
	timer_label.text = "TEMPO ATE O COLAPSO: 00:%02d" % s
	if s <= 10:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.25))
	if time_left <= 0.0:
		_show_outcome("TIMEOUT")


func _choose(id: String) -> void:
	if not timer_running:
		return
	AudioSys.click()
	_show_outcome(id)


func _restart() -> void:
	AudioSys.click()
	_start_timer()


func _show_outcome(which: String) -> void:
	timer_running = false
	AudioSys.stop_alarm()
	alarm_box.visible = false
	outcome_box.visible = true
	match which:
		"B":
			outcome_title.text = "VITORIA - RECIFE SALVO!"
			outcome_title.add_theme_color_override("font_color", Color(0.4, 1, 0.5))
			if ResourceLoader.exists("res://assets/img/outcome-vitoria.jpeg"):
				outcome_img.texture = load("res://assets/img/outcome-vitoria.jpeg")
			outcome_text.text = "As Areas de Protecao Marinha permitiram que manguezais e algas absorvessem o CO2 excessivo, elevando o pH local, enquanto a reducao global de emissoes atacou a causa raiz. Os corais recalcificaram e o recife voltou a se colorir.\n\nLembrete da reportagem: desde a era pre-industrial o pH ja caiu 0.1 (acidez +30%). Sem cortes, a projecao para 2100 e queda de 0.3 (~170% mais acido)."
			AudioSys.success()
			GameState.probe_done = true
			GameState.probe_finished.emit(true)
		"A":
			outcome_title.text = "PROTOCOLO A - FALHOU"
			outcome_title.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
			if ResourceLoader.exists("res://assets/img/outcome-protocolo-a.jpeg"):
				outcome_img.texture = load("res://assets/img/outcome-protocolo-a.jpeg")
			outcome_text.text = "Os alcalinizantes neutralizaram a acidez TEMPORARIAMENTE, mas alteraram salinidade e temperatura, causando choque termico. O pH recai em semanas porque o CO2 continua entrando no mar. Tratar o sintoma nao cura a doenca."
			AudioSys.error()
		"C":
			outcome_title.text = "PROTOCOLO C - FALHOU"
			outcome_title.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
			if ResourceLoader.exists("res://assets/img/outcome-protocolo-c.jpeg"):
				outcome_img.texture = load("res://assets/img/outcome-protocolo-c.jpeg")
			outcome_text.text = "Os corais modificados resistiram, mas plancton, peixes e crustaceos nao modificados colapsaram. O recife virou um deserto genetico. Engenharia genetica ignora a causa e arruina a biodiversidade."
			AudioSys.error()
		_:
			outcome_title.text = "TEMPO ESGOTADO - COLAPSO"
			outcome_title.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
			if ResourceLoader.exists("res://assets/img/probe-reef.jpeg"):
				outcome_img.texture = load("res://assets/img/probe-reef.jpeg")
			outcome_text.text = "O cronometro zerou. O pH continuou caindo, o carbonato sumiu e os corais se dissolveram. Missao falhou - mas voces podem tentar novamente."
			AudioSys.error()

