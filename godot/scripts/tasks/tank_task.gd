class_name TankTask
extends BaseTask
## Tarefa 2 — Tanques: fotossíntese salva o coral (não CO2, não O2).

var tank: TextureRect
var coral_status: Label
var grass_status: Label


func build_task(g) -> void:
	super.build_task(g)
	head("TANQUE DE CALCIFICACAO")
	body("De um lado, um coral definhando. Do outro, ervas marinhas inativas. O que salva o ecossistema?")
	tank = photo("res://assets/img/tank-erro.jpeg")
	coral_status = body("CORAL: ESTRESSADO", 20)
	grass_status = body("ERVAS: INATIVAS", 20)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	var b1 := _btn(row, "INJETAR CO2")
	b1.pressed.connect(_do_co2)
	var b2 := _btn(row, "INJETAR OXIGENIO")
	b2.pressed.connect(_do_o2)
	var b3 := _btn(row, "ATIVAR FOTOSSINTESE")
	b3.pressed.connect(_do_photo)
	mk_feedback()


func _btn(row: HBoxContainer, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 80)
	b.add_theme_font_size_override("font_size", 22)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b)
	return b


func _do_co2() -> void:
	if GameState.tasks["tank"]:
		return
	coral_status.text = "CORAL: COLAPSO ACIDO"
	say("err", "Nao! CO2 + H2O vira acido carbonico (H2CO3), que libera H+. O pH despencou e a agua ficou toxica. Voce acelerou a acidificacao! Quem REMOVE CO2 da agua?")
	AudioSys.error()


func _do_o2() -> void:
	if GameState.tasks["tank"]:
		return
	say("err", "Parcial. O oxigenio nao remove o carbono nem devolve o pH. O coral continua estressado. Precisamos de algo que ABSORVA CO2...")
	AudioSys.error()


func _do_photo() -> void:
	if GameState.tasks["tank"]:
		return
	grass_status.text = "ERVAS: FOTOSSINTESE ATIVA"
	if ResourceLoader.exists("res://assets/img/tank-ok.jpeg"):
		tank.texture = load("res://assets/img/tank-ok.jpeg")
	coral_status.text = "CORAL: SALVO - pH LOCAL ESTABILIZADO"
	say("ok", "TAREFA CONCLUÍDA! As ervas fazem fotossintese: absorveram o CO2 dissolvido, reduziram o H+ e elevaram o pH local - salvando o coral vizinho!")
	AudioSys.success()
	GameState.complete_task("tank")
