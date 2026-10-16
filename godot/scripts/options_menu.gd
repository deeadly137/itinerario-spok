class_name OptionsMenu
extends Control
## Opções: mostra IP local + botões de mapa + voltar.

signal back

var game = null

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
	panel.custom_minimum_size = Vector2(760, 0)
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
	t.text = "OPÇÕES"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var ip := Label.new()
	ip.text = "Seu IP local: " + _local_ip()
	ip.add_theme_font_size_override("font_size", 22)
	ip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(ip)
	var ml := Label.new()
	ml.text = "Controles:"
	ml.add_theme_font_size_override("font_size", 22)
	vb.add_child(ml)
	var tapbtn := Button.new()
	tapbtn.text = ("[X] " if game.tap_move else "[ ] ") + "Andar tocando na tela"
	tapbtn.custom_minimum_size = Vector2(0, 64)
	tapbtn.pressed.connect(func(): game.tap_move = not game.tap_move; queue_free(); game._on_options_pressed())
	vb.add_child(tapbtn)
	var joybtn := Button.new()
	joybtn.text = ("[X] " if game.joy_stick_on else "[ ] ") + "Joystick virtual"
	joybtn.custom_minimum_size = Vector2(0, 64)
	joybtn.pressed.connect(func(): game.joy_stick_on = not game.joy_stick_on; game._apply_joy(); queue_free(); game._on_options_pressed())
	vb.add_child(joybtn)
	var maps := [["new", "MapNEW (atual)"], ["classic", "Clássico (estável)"],
		["atlantis", "Atlantis (legado)"], ["temp", "Esquema (legado)"]]
	for m in maps:
		var b := Button.new()
		b.text = ("[X] " if game.map_mode == m[0] else "[ ] ") + m[1]
		b.custom_minimum_size = Vector2(0, 64)
		var mid: String = m[0]
		b.pressed.connect(func(): _pick(mid))
		vb.add_child(b)
	var backbtn := Button.new()
	backbtn.text = "VOLTAR"
	backbtn.custom_minimum_size = Vector2(0, 64)
	backbtn.pressed.connect(func(): back.emit(); queue_free())
	vb.add_child(backbtn)

func _pick(mid) -> void:
	game.map_mode = mid
	queue_free()
	game._on_options_pressed()

func _local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	for addr in IP.get_local_addresses():
		if "." in addr and not addr.begins_with("127."):
			return addr
	return "desconhecido"
