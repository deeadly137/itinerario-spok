class_name AtmoTask
extends BaseTask
## Minigame 3 — LIGAR OS SENSORES DE CARBONO (minigame de FIOS).
##
## Arraste da fonte poluidora ate a solucao certa. Cada acerto explica
## POR QUE aquela troca reduz a acidificacao. (Nada de quiz de botoes.)

const PAIRS := [
	{"id": "energia", "a": "ENERGIA FOSSIL", "b": "ENERGIA EOLICA", "col": "ff8a5c",
		"why": "Queimar carvao/gas/petroleo lanca CO2, e ~30% disso o oceano absorve."},
	{"id": "desmat", "a": "DESMATAMENTO", "b": "REFLORESTAMENTO", "col": "8fd96b",
		"why": "Floresta queimada libera o carbono estocado e para de capturar CO2."},
	{"id": "industria", "a": "INDUSTRIA SUJA", "b": "MANGUEZAIS E ALGAS", "col": "5bc8e8",
		"why": "Manguezais e algas capturam 'carbono azul' e protegem a costa."},
	{"id": "transporte", "a": "TRANSPORTE A DIESEL", "b": "TRANSPORTE ELETRICO", "col": "d9c8ff",
		"why": "Menos combustivel fossil queimado = menos CO2 dissolvido no mar."},
]

const ROW_H := 58.0
const GAP := 32.0
const BOX_W := 320.0
const LEFT_X := 24.0
const RIGHT_X := 940.0 - 24.0 - BOX_W

var order := [0, 1, 2, 3]
var linked := {}
var drag_from := -1
var drag_pos := Vector2.ZERO
var layer: Control


func _row_y(i: int) -> float:
	return 14.0 + i * (ROW_H + GAP)


func build_task(g) -> void:
	super.build_task(g)
	head("PAINEL DA ATMOSFERA - SENSORES")
	order.shuffle()
	for p in PAIRS:
		linked[p["id"]] = false
	layer = Control.new()
	layer.position = Vector2.ZERO
	layer.size = Vector2(STAGE_W, STAGE_H)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.gui_input.connect(_on_layer)
	layer.draw.connect(_draw_layer)
	stage.add_child(layer)
	hint("Arraste da coluna POLUIDORA (esquerda) ate a SOLUCAO certa (direita).")


func _process(_delta: float) -> void:
	pass


func _on_layer(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			var i := _source_at(event.position)
			if i >= 0:
				drag_from = i
				drag_pos = event.position
				layer.queue_redraw()
		elif drag_from >= 0:
			_try_link(drag_from, _socket_at(event.position))
			drag_from = -1
			layer.queue_redraw()
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and drag_from >= 0:
		drag_pos = event.position
		layer.queue_redraw()


func _source_at(p: Vector2) -> int:
	for i in PAIRS.size():
		if linked[PAIRS[i]["id"]]:
			continue
		if Rect2(LEFT_X - 14.0, _row_y(i) - 10.0, BOX_W + 28.0, ROW_H + 20.0).has_point(p):
			return i
	return -1


func _socket_at(p: Vector2) -> int:
	for j in PAIRS.size():
		if Rect2(RIGHT_X - 14.0, _row_y(j) - 10.0, BOX_W + 28.0, ROW_H + 20.0).has_point(p):
			return j
	return -1


func _try_link(i: int, j: int) -> void:
	if j < 0:
		return
	var src: String = PAIRS[i]["id"]
	var dst: String = PAIRS[order[j]]["id"]
	if src == dst:
		linked[src] = true
		AudioSys.click()
		var done_n := 0
		for k in linked:
			if linked[k]:
				done_n += 1
		if done_n >= PAIRS.size():
			finish("SENSORES LIGADOS! Menos CO2 na atmosfera = menos CO2 dissolvido = menos acido carbonico no mar.", "atmo")
		else:
			good("LIGADO: " + str(PAIRS[i]["b"]) + " - " + str(PAIRS[i]["why"]))
	else:
		AudioSys.error()
		bad("Curto-circuito! '" + str(PAIRS[order[j]]["b"]) + "' nao resolve '" + str(PAIRS[i]["a"]) + "'.")


func _draw_layer() -> void:
	var font := ThemeDB.fallback_font
	for i in PAIRS.size():
		var y := _row_y(i)
		var id: String = PAIRS[i]["id"]
		var col := Color(str(PAIRS[i]["col"]))
		var is_linked: bool = linked[id]
		# terminal da esquerda
		layer.draw_rect(Rect2(LEFT_X, y, BOX_W, ROW_H), Color("0d2130") if not is_linked else Color("0d2b20"))
		layer.draw_rect(Rect2(LEFT_X, y, BOX_W, ROW_H), col, false, 3.0)
		layer.draw_rect(Rect2(LEFT_X + 10.0, y + ROW_H * 0.5 - 9.0, 18.0, 18.0), col)
		layer.draw_string(font, Vector2(LEFT_X + 40.0, y + ROW_H * 0.5 + 7.0), str(PAIRS[i]["a"]), HORIZONTAL_ALIGNMENT_LEFT, BOX_W - 50.0, 20, Color(0.88, 0.94, 1.0))
		# terminal da direita (embaralhado)
		var j := order.find(i)
		var sy := _row_y(j)
		var sc := Color(str(PAIRS[i]["col"]))
		layer.draw_rect(Rect2(RIGHT_X, sy, BOX_W, ROW_H), Color("0d2b20") if is_linked else Color("0d2130"))
		layer.draw_rect(Rect2(RIGHT_X, sy, BOX_W, ROW_H), sc, false, 3.0)
		layer.draw_rect(Rect2(RIGHT_X + BOX_W - 28.0, sy + ROW_H * 0.5 - 9.0, 18.0, 18.0), sc)
		layer.draw_string(font, Vector2(RIGHT_X + 12.0, sy + ROW_H * 0.5 + 7.0), str(PAIRS[i]["b"]), HORIZONTAL_ALIGNMENT_LEFT, BOX_W - 50.0, 20, Color(0.88, 0.94, 1.0))
		# fio ja ligado
		if is_linked:
			var p1 := Vector2(LEFT_X + BOX_W + 6.0, y + ROW_H * 0.5)
			var p2 := Vector2(RIGHT_X - 6.0, sy + ROW_H * 0.5)
			layer.draw_line(p1, p2, col, 6.0)
	# fio sendo arrastado
	if drag_from >= 0:
		var p1b := Vector2(LEFT_X + BOX_W + 6.0, _row_y(drag_from) + ROW_H * 0.5)
		layer.draw_line(p1b, drag_pos, Color(str(PAIRS[drag_from]["col"])), 6.0)
		layer.draw_circle(drag_pos, 9.0, Color(str(PAIRS[drag_from]["col"])))
