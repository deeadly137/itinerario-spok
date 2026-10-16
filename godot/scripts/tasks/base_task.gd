class_name BaseTask
extends Control
## Base das telas de tarefa: painel rolável + feedback.

var game = null
var vb: VBoxContainer
var feedback: Label


func build_task(g) -> void:
	game = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 600)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101b2e")
	sb.border_color = Color("3b5a7a")
	sb.set_border_width_all(3)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(892, 568)
	panel.add_child(scroll)
	vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)


func head(title: String) -> void:
	var h := HBoxContainer.new()
	vb.add_child(h)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(t)
	var close := Button.new()
	close.text = "FECHAR"
	close.pressed.connect(func() -> void: game._close_task())
	h.add_child(close)


func body(text: String, size := 22) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(l)
	return l


func mk_feedback() -> void:
	feedback = Label.new()
	feedback.add_theme_font_size_override("font_size", 22)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(feedback)


func say(kind: String, text: String) -> void:
	feedback.text = text
	match kind:
		"ok":
			feedback.add_theme_color_override("font_color", Color(0.4, 1, 0.5))
		"err":
			feedback.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
		_:
			feedback.add_theme_color_override("font_color", Color(1, 0.9, 0.5))


func photo(path: String, height := 300) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.custom_minimum_size = Vector2(0, height)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vb.add_child(tr)
	return tr
