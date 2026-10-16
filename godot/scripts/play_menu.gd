class_name PlayMenu
extends Control
## Pagina "Jogar": encontrar partida local, entrar por codigo ou criar.
## Layout ancorado (PRESET_FULL_RECT + offsets) para nada escapar da tela.

signal found_match(ip, code)
signal host_match(code)
signal back

const PAGE_W := 900.0
const CONTENT_H := 500.0

var game = null
var srv_list: VBoxContainer
var status: Label
var code_input: LineEdit
var ip_input: LineEdit
var _rows := {}


func build(g) -> void:
	game = g
	# Pagina inteira: ancora E offsets (sem isso o Control fica 0x0 no canto).
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_page_bg(self)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := _panel(PAGE_W)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)
	var t := Label.new()
	t.text = "JOGAR  -  PARTIDA LOCAL"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	# Area rolavel: se a lista de partidas crescer, nada sai da tela.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PAGE_W - 56.0, CONTENT_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	var b1 := _btn("Encontrar partida local", 76)
	b1.pressed.connect(_on_find)
	col.add_child(b1)
	srv_list = VBoxContainer.new()
	srv_list.add_theme_constant_override("separation", 8)
	col.add_child(srv_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	code_input = LineEdit.new()
	code_input.placeholder_text = "Código (3 dígitos)"
	code_input.custom_minimum_size = Vector2(0, 72)
	code_input.add_theme_font_size_override("font_size", 26)
	code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(code_input)
	var b2 := _btn("Entrar por código", 72)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.pressed.connect(_on_code)
	row.add_child(b2)
	var hint := Label.new()
	hint.text = "Se não achar sozinho, digite o IP do host aqui:"
	hint.add_theme_font_size_override("font_size", 18)
	vb.add_child(hint)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP do host (ex.: 192.168.0.10)"
	ip_input.custom_minimum_size = Vector2(0, 64)
	ip_input.add_theme_font_size_override("font_size", 22)
	vb.add_child(ip_input)
	var mk := _btn("CRIAR PARTIDA (gera código)", 76)
	mk.pressed.connect(_on_create)
	col.add_child(mk)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(0, 60)
	col.add_child(status)
	var backbtn := _btn("VOLTAR", 64)
	backbtn.pressed.connect(func(): back.emit(); queue_free())
	col.add_child(backbtn)


# ---- estilo comum das paginas do menu -----------------------------------
static func _page_bg(root: Control) -> void:
	if ResourceLoader.exists("res://assets/img/menu_bg.jpg"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/img/menu_bg.jpg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.03, 0.06, 0.82)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)


static func _panel(width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("0d1b2e")
	sb.border_color = Color("2f6b8f")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	return panel


static func _btn(text: String, h := 72.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("17324d")
	sb.border_color = Color("4d9dc4")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var sh := sb.duplicate() as StyleBoxFlat
	sh.bg_color = Color("1f4a6d")
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	return b


func _on_find() -> void:
	NetHub.server_found.connect(_on_found)
	NetHub.start_discovery()
	status.text = "Procurando partidas na rede Wi-Fi..."


func _on_found(code, ip) -> void:
	if _rows.has(code):
		return
	var b := _btn("PARTIDA " + str(code), 76)
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
	# Com o IP na mao, entra direto (sem depender de broadcast na rede).
	var ip := ip_input.text.strip_edges()
	if ip != "":
		_enter(ip, code)
		return
	NetHub.start_discovery()
	status.text = "Procurando partida " + code + "..."
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
