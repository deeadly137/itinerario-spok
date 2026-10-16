class_name MicroTask
extends BaseTask
## Tarefa 1 — Microscópio: escolher o frasco de pH correto (8.2).

var shell: TextureRect
var status: Label


func build_task(g) -> void:
	super.build_task(g)
	head("MICROSCOPIO - CONCHA DO PTEROPODE")
	body("A concha esta corroída e cheia de furos. Escolha o frasco com o pH que restaura a calcificacao:")
	shell = photo("res://assets/img/micro-erro.jpeg")
	status = body("STATUS: CONCHA CORROIDA", 20)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	for ph in ["8.2", "7.8", "7.3"]:
		var b := Button.new()
		b.text = "pH " + ph
		b.custom_minimum_size = Vector2(0, 90)
		b.add_theme_font_size_override("font_size", 32)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value: String = ph
		b.pressed.connect(func() -> void: _choose(value))
		row.add_child(b)
	mk_feedback()


func _choose(ph: String) -> void:
	if GameState.tasks["micro"]:
		return
	if ph == "8.2":
		if ResourceLoader.exists("res://assets/img/micro-ok.jpeg"):
			shell.texture = load("res://assets/img/micro-ok.jpeg")
		status.text = "STATUS: CONCHA RESTAURADA - CALCIFICACAO RETOMADA"
		say("ok", "TAREFA CONCLUÍDA! Em pH 8.2 (valor natural pre-industrial) ha carbonato disponivel. O Pteropode reconstruiu sua concha!")
		AudioSys.success()
		GameState.complete_task("micro")
	elif ph == "7.8":
		say("err", "Ainda acido demais. pH 7.8 e a projecao da ciencia para 2100: acidificacao ~170% maior que o pre-industrial. Tente outro frasco!")
		AudioSys.error()
	else:
		say("err", "ERRO CRITICO! Nesse pH, os ions H+ sequestram o carbonato (CO3--) para formar bicarbonato. Sem carbonato livre, a concha se dissolve ainda mais rapido. Aumente o pH!")
		AudioSys.error()
