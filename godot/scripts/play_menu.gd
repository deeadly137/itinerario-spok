class_name PlayMenu
extends Control
## Submenu Jogar: "Encontrar partida local" (lista) ou "Por código".

signal found_match(ip, code)
signal host_match(code)
signal back

var game = null
var srv_list: VBoxContainer
var status: Label
var code_input: LineEdit
var _rows := {}

func build(g) -> void:
	game = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
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
	t.text = "JOGAR - PARTIDA LOCAL"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var b1 := Button.new()
	b1.text = "Encontrar partida local"
	b1.custom_minimum_size = Vector2(0, 80)
	b1.add_theme_font_size_override("font_size", 28)
	b1.pressed.connect(_on_find)
	vb.add_child(b1)
	srv_list = VBoxContainer.new()
	srv_list.add_theme_constant_override("separation", 8)
	vb.add_child(srv_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	code_input = LineEdit.new()
	code_input.placeholder_text = "Código numérico (3 dígitos)"
	code_input.custom_minimum_size = Vector2(0, 72)
	code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(code_input)
	var b2 := Button.new()
	b2.text = "Entrar por código"
	b2.custom_minimum_size = Vector2(0, 72)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.pressed.connect(_on_code)
	row.add_child(b2)
	var mk := Button.new()
	mk.text = "Criar partida (gera código)"
	mk.custom_minimum_size = Vector2(0, 72)
	mk.pressed.connect(_on_create)
	vb.add_child(mk)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(status)
	var backbtn := Button.new()
	backbtn.text = "VOLTAR"
	backbtn.custom_minimum_size = Vector2(0, 64)
	backbtn.pressed.connect(func(): back.emit(); queue_free())
	vb.add_child(backbtn)

func _on_find() -> void:
	NetHub.server_found.connect(_on_found)
	NetHub.start_discovery()
	status.text = "Procurando partidas na rede Wi-Fi..."

func _on_found(code, ip) -> void:
	if _rows.has(code):
		return
	var b := Button.new()
	b.text = "PARTIDA " + code
	b.custom_minimum_size = Vector2(0, 72)
	b.add_theme_font_size_override("font_size", 28)
	var c: String = code
	var a: String = ip
	b.pressed.connect(func(): _enter(a, c))
	srv_list.add_child(b)
	_rows[code] = b

func _on_code() -> void:
	var code = code_input.text.strip_edges()
	if code.length() != 3 or not code.is_valid_int():
		status.text = "Digite um código de 3 dígitos."
		return
	NetHub.start_discovery()
	status.text = "Procurando partida " + code + "... (se não aparecer, confirme o IP com o host)"
	# tenta descoberta primeiro; fallback: host na mesma rede costuma ser .1xx — pede IP
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self) and NetHub.found_servers.has(code):
		_enter(NetHub.found_servers[code], code)
	elif is_instance_valid(self):
		status.text = "Não achei sozinho. Peça o IP ao host e use CRIAR/ENTRAR manual."

func _enter(ip, code) -> void:
	var err: String = NetHub.join_game(ip, code)
	if err != "":
		status.text = err
		return
	NetHub.stop_discovery()
	found_match.emit(ip, code)
	queue_free()

func _on_create() -> void:
	var code = NetHub.make_code()
	var err: String = NetHub.host_game(code)
	if err != "":
		status.text = err
		return
	NetHub.stop_discovery()
	host_match.emit(code)
	queue_free()

func _exit_tree() -> void:
	if NetHub.server_found.is_connected(_on_found):
		NetHub.server_found.disconnect(_on_found)
