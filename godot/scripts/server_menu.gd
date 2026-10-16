class_name ServerMenu
extends Control
## Menu de servidores LAN: mostra código de 3 dígitos como "nome".
## Descoberta via broadcast UDP; fallback: digitar IP + código.

signal joined
signal back

var game = null
var srv_list: VBoxContainer
var status: Label
var ip_input: LineEdit
var code_input: LineEdit
var _rows := {}

func build(g) -> void:
	game = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101b2e")
	sb.border_color = Color("3b5a7a")
	sb.set_border_width_all(3)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)
	var t := Label.new()
	t.text = "SERVIDORES NA REDE"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	srv_list = VBoxContainer.new()
	srv_list.add_theme_constant_override("separation", 8)
	vb.add_child(srv_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	var mk := Button.new()
	mk.text = "CRIAR SERVIDOR"
	mk.custom_minimum_size = Vector2(0, 72)
	mk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mk.pressed.connect(_on_create)
	row.add_child(mk)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP (se nao achar sozinho)"
	ip_input.custom_minimum_size = Vector2(0, 72)
	ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ip_input)
	code_input = LineEdit.new()
	code_input.placeholder_text = "COD (3 digitos)"
	code_input.custom_minimum_size = Vector2(200, 72)
	row.add_child(code_input)
	var join := Button.new()
	join.text = "ENTRAR"
	join.custom_minimum_size = Vector2(0, 72)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.pressed.connect(_on_manual_join)
	row.add_child(join)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(status)
	var backbtn := Button.new()
	backbtn.text = "VOLTAR"
	backbtn.custom_minimum_size = Vector2(0, 64)
	backbtn.pressed.connect(func(): back.emit())
	vb.add_child(backbtn)
	NetHub.server_found.connect(_on_found)
	NetHub.start_discovery()
	status.text = "Procurando servidores na rede..."

func _on_found(code, ip) -> void:
	if _rows.has(code):
		return
	var b := Button.new()
	b.text = "SERVIDOR " + code + "  (" + ip + ")"
	b.custom_minimum_size = Vector2(0, 72)
	b.add_theme_font_size_override("font_size", 26)
	var c: String = code
	var a: String = ip
	b.pressed.connect(func(): _join(a, c))
	srv_list.add_child(b)
	_rows[code] = b
	status.text = "Servidores encontrados: %d" % _rows.size()

func _join(ip, code) -> void:
	var err = NetHub.join_game(ip, code)
	if err != "":
		status.text = err
		return
	NetHub.stop_discovery()
	joined.emit()

func _on_manual_join() -> void:
	var ip = ip_input.text.strip_edges()
	var code = code_input.text.strip_edges()
	if ip == "" or code == "":
		status.text = "Digite IP e COD de 3 digitos."
		return
	_join(ip, code)

func _on_create() -> void:
	var code = NetHub.make_code()
	var err = NetHub.host_game(code)
	if err != "":
		status.text = err
		return
	NetHub.stop_discovery()
	joined.emit()

func _exit_tree() -> void:
	if NetHub.server_found.is_connected(_on_found):
		NetHub.server_found.disconnect(_on_found)
