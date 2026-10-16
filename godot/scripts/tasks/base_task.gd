class_name BaseTask
extends Control
## Base das telas de MINIGAME.
##
## Layout: cabecalho fixo + PALCO de tamanho fixo + rodape de dica.
## Sem ScrollContainer: era ele que, com largura 0, fazia cada palavra virar
## uma linha e empurrava o botao de acao para 5000 px abaixo da tela.
##
## Subclasses colocam os widgets dentro de `stage` (coordenadas locais,
## 940x380) e chamam `finish()` quando ganham.

const STAGE_W := 940.0
const STAGE_H := 380.0
const PANEL_W := STAGE_W + 56.0

var game = null
var stage: Control
var title_label: Label
var hint_label: Label
var done := false


func build_task(g) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.06, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_W, 0.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("08131f")
	sb.border_color = Color("2f6b8f")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vb.add_child(head)
	title_label = Label.new()
	title_label.text = "MINIGAME"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("7fd4f0"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	head.add_child(title_label)
	var close := key_button("SAIR", 130.0, 62.0)
	close.pressed.connect(request_close)
	head.add_child(close)
	stage = Control.new()
	stage.custom_minimum_size = Vector2(STAGE_W, STAGE_H)
	stage.clip_contents = true
	vb.add_child(stage)
	hint_label = Label.new()
	hint_label.text = ""
	hint_label.add_theme_font_size_override("font_size", 21)
	hint_label.custom_minimum_size = Vector2(STAGE_W, 58.0)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vb.add_child(hint_label)


# ----------------------------- utilitarios -----------------------------

func head(text: String) -> void:
	title_label.text = text


func hint(text: String, color := Color(0.8, 0.88, 0.96)) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", color)


func good(text: String) -> void:
	hint(text, Color(0.45, 1, 0.55))


func bad(text: String) -> void:
	hint(text, Color(1, 0.5, 0.45))


## Botao estilo "tecla de console" (diferente dos botoes do menu inicial).
func key_button(text: String, w := 0.0, h := 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.add_theme_font_size_override("font_size", 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("0f2b3d")
	sb.border_color = Color("3ba9d4")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	var sh := sb.duplicate() as StyleBoxFlat
	sh.bg_color = Color("17475f")
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	var sd := sb.duplicate() as StyleBoxFlat
	sd.bg_color = Color("10212c")
	sd.border_color = Color("2b4a5a")
	b.add_theme_stylebox_override("disabled", sd)
	return b


func label(text: String, size := 22, color := Color(0.85, 0.92, 1.0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Imagem de fundo do palco (feed da sonda, foto do problema, etc).
func stage_image(path: String, rect: Rect2) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.position = rect.position
	tr.size = rect.size
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tr)
	return tr


# ----------------------------- fluxo -----------------------------------

## Sobrescreva para bloquear a saida (ex.: alarme da sonda ligado).
func can_close() -> bool:
	return true


func request_close() -> void:
	if not can_close():
		bad("ALARME ATIVO: resolva a emergência antes de sair!")
		AudioSys.error()
		return
	AudioSys.click()
	game.force_close_task()


## Conclusao: avisa, marca no GameState (se for uma tarefa contavel) e
## fecha sozinho depois de um instante.
func finish(message: String, task_id := "") -> void:
	if done:
		return
	done = true
	good(message)
	AudioSys.success()
	if task_id != "":
		GameState.complete_task(task_id)
	await get_tree().create_timer(1.8).timeout
	if is_instance_valid(self):
		game.force_close_task()
