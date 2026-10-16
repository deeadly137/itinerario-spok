class_name AtmoTask
extends BaseTask
## Tarefa 3 — Atmosfera: casar cada engrenagem poluidora com a limpa.

const GEARS := [
	{"id": "energia", "dirty": "ENERGIA FOSSEIS", "clean": "ENERGIA EOLICA",
		"why": "Queimar carvao/gas/petroleo lanca CO2 que o oceano absorve (~30%). A eolica emite zero carbono."},
	{"id": "desmat", "dirty": "DESMATAMENTO", "clean": "REFLORESTAMENTO",
		"why": "Florestas queimadas liberam carbono estocado e perdem a capacidade de captar CO2."},
	{"id": "industria", "dirty": "INDUSTRIA SUJA", "clean": "MANGUEZAIS E ALGAS",
		"why": "Manguezais e algas capturam carbono ('carbono azul') e protegem a costa - bercarios de peixes e corais."},
]

var graph: TextureRect
var caption: Label
var selected := ""
var dirty_btns := {}
var clean_btns := {}


func build_task(g) -> void:
	super.build_task(g)
	head("PAINEL DA ATMOSFERA")
	body("ENIGMA: toque numa engrenagem POLUIDORA e depois na sua alternativa SUSTENTAVEL. Acerte as 3 e a linha vermelha para de subir.")
	graph = photo("res://assets/img/graph-erro.jpeg")
	caption = body("CO2 EMISSOES SOBEM - pH DO OCEANO CAI (1900 ... 2100)", 20)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	vb.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	for gg in GEARS:
		var b := Button.new()
		b.text = gg["dirty"]
		b.custom_minimum_size = Vector2(0, 76)
		b.add_theme_font_size_override("font_size", 20)
		var gid: String = gg["id"]
		b.pressed.connect(func() -> void: _select_dirty(gid))
		left.add_child(b)
		dirty_btns[gid] = b
	var order := [0, 1, 2]
	order.shuffle()
	for i in order:
		var gg: Dictionary = GEARS[i]
		var b := Button.new()
		b.text = gg["clean"]
		b.custom_minimum_size = Vector2(0, 76)
		b.add_theme_font_size_override("font_size", 20)
		var gid: String = gg["id"]
		b.pressed.connect(func() -> void: _try_clean(gid))
		right.add_child(b)
		clean_btns[gid] = b
	mk_feedback()


func _select_dirty(gid: String) -> void:
	if (dirty_btns[gid] as Button).disabled:
		return
	AudioSys.click()
	selected = gid
	for id in dirty_btns:
		(dirty_btns[id] as Button).text = (" > " if id == gid else "") + _dirty_label(id)
	say("info", "Selecionado. Agora toque na alternativa limpa correspondente.")


func _dirty_label(gid: String) -> String:
	for gg in GEARS:
		if gg["id"] == gid:
			return gg["dirty"]
	return gid


func _try_clean(gid: String) -> void:
	if (clean_btns[gid] as Button).disabled:
		return
	if selected == "":
		say("info", "Primeiro toque numa engrenagem POLUIDORA (coluna da esquerda).")
		AudioSys.error()
		return
	if selected == gid:
		(dirty_btns[gid] as Button).disabled = true
		(clean_btns[gid] as Button).disabled = true
		selected = ""
		var why := ""
		for gg in GEARS:
			if gg["id"] == gid:
				why = gg["why"]
		AudioSys.success()
		say("ok", "Substituicao realizada: " + why)
		_check_solved()
	else:
		say("err", "Essas pecas nao se encaixam. Pense em qual problema cada alternativa limpa resolve.")
		AudioSys.error()


func _check_solved() -> void:
	for id in clean_btns:
		if not (clean_btns[id] as Button).disabled:
			return
	if ResourceLoader.exists("res://assets/img/graph-ok.jpeg"):
		graph.texture = load("res://assets/img/graph-ok.jpeg")
	caption.text = "EMISSOES ESTABILIZADAS - pH DO OCEANO PAROU DE CAIR"
	say("ok", "TAREFA CONCLUÍDA! Com energia limpa, florestas e manguezais, as emissoes estabilizam e o pH para de cair. A linha vermelha foi contida!")
	GameState.complete_task("atmo")
