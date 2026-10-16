class_name LobbyUI
extends Control
## Lobby LAN: hospedar ou entrar com IP + escolha de sprite (plugável).
## Em single-player (offline) o jogo continua igual — o lobby só aparece
## se o jogador tocar em "MULTIPLAYER" no boot.

signal play_offline
signal play_online

var game = null
var ip_input: LineEdit
var status: Label
var plist: Label
var sprite_row: HBoxContainer
var chosen := 0  # índice do animal escolhido (0-5)


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
	t.text = "LOBBY — PROJETO ABISMO"
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var info := Label.new()
	info.text = "6 animais infiltrados x 3 cientistas sabotadores (LAN, ate 9 aparelhos). Sem rede? Jogue offline."
	info.add_theme_font_size_override("font_size", 20)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(info)
	# escolha do animal (sprites plugáveis)
	var st := Label.new()
	st.text = "ESCOLHA SEU ANIMAL:"
	st.add_theme_font_size_override("font_size", 22)
	vb.add_child(st)
	sprite_row = HBoxContainer.new()
	sprite_row.add_theme_constant_override("separation", 8)
	vb.add_child(sprite_row)
	_refresh_sprites()
	# host / join
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	var host := Button.new()
	host.text = "HOSPEDAR SALA"
	host.custom_minimum_size = Vector2(0, 72)
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.pressed.connect(_on_host)
	row.add_child(host)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP do host (ex: 192.168.0.10)"
	ip_input.custom_minimum_size = Vector2(0, 72)
	ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ip_input)
	var join := Button.new()
	join.text = "ENTRAR"
	join.custom_minimum_size = Vector2(0, 72)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.pressed.connect(_on_join)
	row.add_child(join)
	plist = Label.new()
	plist.add_theme_font_size_override("font_size", 20)
	plist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(plist)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(status)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	vb.add_child(row2)
	var mapbtn := Button.new()
	mapbtn.text = "MAPA: ATLANTIS (novo)"
	mapbtn.custom_minimum_size = Vector2(0, 72)
	mapbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mapbtn.pressed.connect(func() -> void:
		if game.map_mode == "atlantis":
			game.map_mode = "classic"
			mapbtn.text = "MAPA: CLASSICO (estavel)"
		else:
			game.map_mode = "atlantis"
			mapbtn.text = "MAPA: ATLANTIS (novo)")
	row2.add_child(mapbtn)
	var off := Button.new()
	off.text = "JOGAR OFFLINE (1 jogador)"
	off.custom_minimum_size = Vector2(0, 72)
	off.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	off.pressed.connect(func() -> void: play_offline.emit())
	row2.add_child(off)
	var back := Button.new()
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(0, 72)
	back.pressed.connect(func() -> void: queue_free())
	row2.add_child(back)
	NetHub.players_changed.connect(_refresh_list)


func _refresh_sprites() -> void:
	for c in sprite_row.get_children():
		c.queue_free()
	for i in NetHub.ANIMALS.size():
		var a: Dictionary = NetHub.ANIMALS[i]
		var b := Button.new()
		var path: String = NetHub.animal_sprite(a["id"])
		if ResourceLoader.exists(path):
			b.text = ""
			b.icon = load(path)
			b.expand_icon = true
		else:
			b.text = a["name"]
		b.custom_minimum_size = Vector2(120, 90)
		b.toggle_mode = true
		b.button_pressed = (i == chosen)
		var idx := i
		b.pressed.connect(func() -> void: _pick(idx))
		sprite_row.add_child(b)


func _pick(i: int) -> void:
	chosen = i
	_refresh_sprites()


func _on_host() -> void:
	var err: String = NetHub.host_game(NetHub.make_code())
	if err != "":
		status.text = err
	else:
		status.text = "Sala aberta! Passe seu IP para a turma entrar."
		_refresh_list()
		play_online.emit()


func _on_join() -> void:
	var ip := ip_input.text.strip_edges()
	if ip == "":
		status.text = "Digite o IP do aparelho host."
		return
	var err: String = NetHub.join_game(ip, NetHub.server_code if NetHub.server_code != "" else "000")
	status.text = "Conectando..." if err == "" else err
	if err == "":
		_refresh_list()
		play_online.emit()


func _refresh_list() -> void:
	var lines: Array = []
	for pid in NetHub.players:
		var p: Dictionary = NetHub.players[pid]
		lines.append("peer %d: %s %s" % [pid, p.get("role", "?"), p.get("animal", "")])
	plist.text = "Jogadores (%d):\n%s" % [lines.size(), "\n".join(lines)]
