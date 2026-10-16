class_name OptionsMenu
extends Control
## Pagina "Opcoes": IP local e controles (joystick / andar tocando).
## A escolha de mapa agora fica no lobby (quem cria a sala escolhe).
## Layout ancorado: nada sai da tela.

signal back

var game = null


func build(g) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	PlayMenu._page_bg(self)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PlayMenu._panel(820)
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(764, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vb)
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
	var joybtn := PlayMenu._btn(("  [X]  " if game.joy_stick_on else "  [ ]  ") + "Joystick virtual (arraste na tela)", 64)
	joybtn.pressed.connect(func(): game.joy_stick_on = not game.joy_stick_on; game._apply_joy(); queue_free(); game._on_options_pressed())
	vb.add_child(joybtn)
	var tapbtn := PlayMenu._btn(("  [X]  " if game.tap_move else "  [ ]  ") + "Andar tocando no chão", 64)
	tapbtn.pressed.connect(func(): game.tap_move = not game.tap_move; queue_free(); game._on_options_pressed())
	vb.add_child(tapbtn)
	var backbtn := PlayMenu._btn("VOLTAR", 64)
	backbtn.pressed.connect(func(): back.emit(); queue_free())
	vb.add_child(backbtn)


func _local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	for addr in IP.get_local_addresses():
		if "." in addr and not addr.begins_with("127."):
			return addr
	return "desconhecido"
