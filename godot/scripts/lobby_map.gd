class_name LobbyMap
extends Node2D
## Sala de espera: fundo MapLobby.jpeg, cada um anda com SUA caixa
## (cor aleatoria, sem cargo). READY -> START -> revelacao do cargo.
##
## Correcoes: a camera do lobby agora VIRA A ATUAL (antes a do player do
## mapa continuava ativa, entao o personagem ficava fora do enquadramento
## e parecia que "nao dava para andar") e o joystick tambem e dinamico.

signal started

const SPEED := 300.0

var game = null
var players := {}
var code_labels := {}
var ready_labels := {}
var ready_state := {}
var start_btn: Button = null
var my_code := ""
var my_id = "local"
var revealed := false
var cam: Camera2D = null
var my_box: CharacterBody2D = null
var my_vel := Vector2.ZERO
var remote_targets := {}
var lobby_joy := -1
var lobby_center := Vector2.ZERO

const JOY_RING := 130.0
const JOY_KNOB := 62.0
const JOY_MAX := 110.0
var joy_base: Control
var joy_knob: Control

const IMG_W := 896.0
const IMG_H := 1200.0
const SCALE := 1.5
const WORLD_W := 1344.0
const WORLD_H := 1800.0
const CENTER_PX := Vector2(448, 560)
const RING_R_PX := 165.0
const FAKE_COLORS := ["5bc8e8", "ff7b9c", "7be495", "d9c8ff", "ffe066", "ff9a5c", "e8e8e8", "9ad0ff", "ffc9c9"]
## Mapas que o host pode escolher ao criar a sala.
const MAPS := [["new", "MAPNEW"], ["classic", "CLÁSSICO"],
	["atlantis", "ATLANTIS"], ["temp", "ESQUEMA"]]

func build(g) -> void:
	game = g
	if ResourceLoader.exists("res://assets/img/map_lobby.jpg"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/img/map_lobby.jpg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		bg.position = Vector2.ZERO
		bg.size = Vector2(WORLD_W, WORLD_H)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	var cx = CENTER_PX.x * SCALE
	var cy = CENTER_PX.y * SCALE
	var rr = (RING_R_PX + 60.0) * SCALE
	var body := StaticBody2D.new()
	body.name = "LobbyWalls"
	add_child(body)
	for i in 24:
		var a = TAU * i / 24.0
		var p = Vector2(cx + cos(a) * rr, cy + sin(a) * rr)
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(120, 120)
		col.shape = rs
		col.rotation = a
		col.position = p
		body.add_child(col)
	cam = Camera2D.new()
	cam.position = Vector2(cx, cy)
	# Zoom FORTE: no mapa o zoom e 2.0 e o mundo do lobby tem metade do
	# tamanho, entao 1.35 deixa os bonecos com o mesmo peso visual e o anel
	# inteiro cabe na tela (o lobby antes ficava com o zoom 0.55, minusculo).
	cam.zoom = Vector2(1.35, 1.35)
	cam.enabled = true
	add_child(cam)
	cam.make_current()          # <-- sem isto a camera do mapa continuava ativa
	_build_joy()
	my_code = "%03d" % randi_range(0, 999)
	_show_ready()
	# Rede: a lista de quem esta na sala vem do host (codigo e cor iguais em
	# todo mundo) e a posicao dos outros chega pelo NetHub. A caixa LOCAL
	# nasce no _sync_boxes: cliente so sabe o proprio id depois de conectar.
	NetHub.roster_changed.connect(_sync_boxes)
	NetHub.peer_moved.connect(_on_peer_moved)
	NetHub.peer_left.connect(_on_peer_left)
	_sync_boxes()


func _my_key():
	if not NetHub.online:
		return "local"
	return NetHub.local_id()


## Cria/remove caixas para ficar igual a lista de jogadores do host.
func _sync_boxes() -> void:
	if revealed:
		return
	var mine = _my_key()
	var roster: Dictionary = NetHub.players
	if my_box == null:
		# cliente: espera conectar (senao a gente se confundiria com o host)
		if NetHub.online and int(mine) <= 0:
			return
		my_id = mine
		var me: Dictionary = {}
		if roster.has(mine):
			me = roster[mine]
		var col := str(me.get("color", FAKE_COLORS[randi() % FAKE_COLORS.size()]))
		my_code = str(me.get("code", my_code))
		my_box = _add_box(my_id, my_code, col, int(me.get("index", 0)))
	for pid in players.keys():
		if pid == my_id:
			continue
		if not roster.has(pid):
			var b = players[pid]["node"]
			if is_instance_valid(b):
				b.queue_free()
			players.erase(pid)
			code_labels.erase(pid)
			ready_labels.erase(pid)
			ready_state.erase(pid)
			remote_targets.erase(pid)
	for pid in roster.keys():
		if pid == my_id or players.has(pid):
			continue
		var ev: Dictionary = roster[pid]
		_add_box(pid, str(ev.get("code", "000")), str(ev.get("color", "e8e8e8")),
			int(ev.get("index", 0)))
	_sync_ready()


func _on_peer_moved(pid, pos: Vector2) -> void:
	if revealed or pid == my_id:
		return
	if players.has(pid):
		remote_targets[pid] = pos


func _on_peer_left(pid) -> void:
	if pid == my_id or not players.has(pid):
		return
	var b = players[pid]["node"]
	if is_instance_valid(b):
		b.queue_free()
	players.erase(pid)
	code_labels.erase(pid)
	ready_labels.erase(pid)
	ready_state.erase(pid)
	remote_targets.erase(pid)


func _build_joy() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	joy_base = Control.new()
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.size = Vector2(JOY_RING * 2.0, JOY_RING * 2.0)
	joy_base.visible = false
	layer.add_child(joy_base)
	var ring := ColorRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.color = Color(1, 1, 1, 0.15)
	ring.size = Vector2(JOY_RING * 2.0, JOY_RING * 2.0)
	joy_base.add_child(ring)
	joy_knob = ColorRect.new()
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_knob.color = Color(0.55, 0.85, 1.0, 0.7)
	joy_knob.size = Vector2(JOY_KNOB, JOY_KNOB)
	_place_joy_knob(Vector2.ZERO)
	joy_base.add_child(joy_knob)


func _place_joy_knob(d: Vector2) -> void:
	joy_knob.position = Vector2(JOY_RING, JOY_RING) + d - Vector2(JOY_KNOB * 0.5, JOY_KNOB * 0.5)


func _joy_start(idx: int, p: Vector2) -> void:
	lobby_joy = idx
	lobby_center = p
	joy_base.position = p - Vector2(JOY_RING, JOY_RING)
	joy_base.visible = true
	_place_joy_knob(Vector2.ZERO)


func _joy_drag(p: Vector2) -> void:
	var d = p - lobby_center
	if d.length() > JOY_MAX:
		lobby_center = p - d.normalized() * JOY_MAX
		d = p - lobby_center
	var m: float = d.length() / JOY_MAX
	if m < 0.18:
		my_vel = Vector2.ZERO
	else:
		my_vel = d.normalized() * SPEED * clampf(m, 0.5, 1.0)
	_place_joy_knob(d)


func _joy_end() -> void:
	lobby_joy = -1
	my_vel = Vector2.ZERO
	if joy_base:
		joy_base.visible = false


func ring_pos(i, total):
	var cx = CENTER_PX.x * SCALE
	var cy = CENTER_PX.y * SCALE
	var rr = RING_R_PX * SCALE
	var a = TAU * i / max(1, total) - PI / 2.0
	return Vector2(cx + cos(a) * rr, cy + sin(a) * rr)

func _add_box(pid, code, color_hex, slot := -1):
	var box := CharacterBody2D.new()
	var n: int = slot if slot >= 0 else players.size()
	# halo na cor do jogador + sprite/bicho do slot (o MESMO em todo mundo,
	# porque o slot vem da lista do host).
	NetHub.decorate_crew(box, "", "", str(color_hex), 50.0, "",
		NetHub.lobby_sprite(n))
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(44, 44)
	col.shape = rs
	box.add_child(col)
	var lab := Label.new()
	lab.text = str(code)
	lab.position = Vector2(-30, -56)
	lab.add_theme_font_size_override("font_size", 24)
	box.add_child(lab)
	var rl := Label.new()
	rl.text = ""
	rl.position = Vector2(-30, 26)
	rl.add_theme_font_size_override("font_size", 20)
	rl.add_theme_color_override("font_color", Color(0.4, 1, 0.5))
	box.add_child(rl)
	box.position = ring_pos(n, 9)
	add_child(box)
	players[pid] = {"node": box, "code": str(code)}
	code_labels[pid] = lab
	ready_labels[pid] = rl
	ready_state[pid] = false
	return box

func _joy_zone(p: Vector2) -> bool:
	var vp = get_viewport().get_visible_rect().size
	return p.y > vp.y * 0.42 and p.x < vp.x * 0.75


func _unhandled_input(event) -> void:
	if revealed:
		return
	if event is InputEventScreenTouch and event.pressed:
		if _joy_zone(event.position) and lobby_joy == -1:
			_joy_start(event.index, event.position)
	elif event is InputEventScreenTouch and not event.pressed and event.index == lobby_joy:
		_joy_end()
	elif event is InputEventScreenDrag and event.index == lobby_joy:
		_joy_drag(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _joy_zone(event.position) and lobby_joy == -1:
			_joy_start(-2, event.position)
	elif event is InputEventMouseButton and not event.pressed and lobby_joy == -2:
		_joy_end()
	elif event is InputEventMouseMotion and lobby_joy == -2:
		_joy_drag(event.position)

func _physics_process(delta) -> void:
	if revealed:
		return
	if my_box:
		my_box.velocity = my_vel
		my_box.move_and_slide()
		# publica a minha posicao (o NetHub limita a 15 Hz)
		NetHub.set_my_pos(my_box.position)
	# caixas dos outros: deslizam ate a ultima posicao recebida
	for pid in remote_targets.keys():
		if not players.has(pid):
			continue
		var b = players[pid]["node"]
		if is_instance_valid(b):
			b.position = b.position.lerp(remote_targets[pid],
				clampf(delta * 12.0, 0.0, 1.0))

func _show_ready():
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.name = "LobbyUI"
	add_child(layer)
	# Quadro de entrada: o host mostra codigo + IP para o outro digitar
	# (garantia quando a descoberta automatica nao funciona na rede).
	if NetHub.online:
		var info := Label.new()
		if NetHub.is_host:
			info.text = "SALA %s   -   seu IP: %s" % [NetHub.server_code, NetHub.local_ip()]
		else:
			info.text = "SALA %s   -   conectado ao host" % NetHub.server_code
		info.add_theme_font_size_override("font_size", 26)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		info.position = Vector2(0, 22)
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(info)
	var rb := Button.new()
	rb.text = "READY"
	rb.custom_minimum_size = Vector2(320, 110)
	rb.add_theme_font_size_override("font_size", 44)
	rb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	rb.position = Vector2(-160, -160)
	rb.pressed.connect(_mark_ready)
	layer.add_child(rb)
	# START: aparece para o host E tambem no modo solo (sem rede), que
	# antes ficava sem nenhum botao para comecar.
	if not NetHub.online or NetHub.is_host:
		# Escolha do mapa: quem cria a sala decide (e vale para todos na LAN).
		var mb := Button.new()
		mb.text = "MAPA: " + _map_label(game.map_mode)
		mb.custom_minimum_size = Vector2(340, 74)
		mb.add_theme_font_size_override("font_size", 26)
		mb.anchor_left = 0.0
		mb.anchor_top = 0.0
		mb.anchor_right = 0.0
		mb.anchor_bottom = 0.0
		mb.offset_left = 22.0
		mb.offset_top = 22.0
		mb.offset_right = 362.0
		mb.offset_bottom = 96.0
		mb.pressed.connect(func() -> void:
			var next := _next_map(game.map_mode)
			mb.text = "MAPA: " + _map_label(next)
			if NetHub.online:
				NetHub.set_server_map(next)
			else:
				game.apply_map_mode(next))
		layer.add_child(mb)
		start_btn = Button.new()
		start_btn.text = "COMEÇAR" if not NetHub.online else "START"
		start_btn.custom_minimum_size = Vector2(320, 90)
		start_btn.add_theme_font_size_override("font_size", 40)
		start_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		start_btn.position = Vector2(-160, -280)
		start_btn.pressed.connect(_on_start)
		layer.add_child(start_btn)

func _mark_ready() -> void:
	set_ready(my_id, true)
	NetHub.set_ready(true)

func set_ready(pid, v):
	ready_state[pid] = v
	var rl: Label = ready_labels.get(pid)
	if rl:
		rl.text = "READY!" if v else ""

## Espelha o READY que o host conhece (o meu e o dos outros).
func _sync_ready() -> void:
	for pid in players.keys():
		var d = NetHub.players.get(pid, {})
		if d is Dictionary:
			set_ready(pid, bool(d.get("ready", false)))

func all_ready():
	if NetHub.online:
		return NetHub.all_ready()
	if ready_state.is_empty():
		return false
	for k in ready_state:
		if not ready_state[k]:
			return false
	return true

func _on_start():
	if NetHub.online and not NetHub.is_host:
		return
	if NetHub.online and not all_ready():
		return
	if NetHub.online and NetHub.is_host:
		NetHub.start_match()
	else:
		reveal("animal", "pteropode")
		started.emit()

func reveal(role, animal):
	revealed = true
	my_vel = Vector2.ZERO
	if joy_base:
		joy_base.visible = false
	var txt = "CIENTISTA" if role == "scientist" else "ANIMAL: " + animal.to_upper()
	for pid in players:
		var lab: Label = code_labels.get(pid)
		if lab == null:
			continue
		if pid == my_id:
			lab.text = players[pid]["code"] + "\n" + txt
	var ui = get_node_or_null("LobbyUI")
	if ui:
		ui.queue_free()

func local_box():
	return my_box


func _map_label(m: String) -> String:
	for e in MAPS:
		if e[0] == m:
			return str(e[1])
	return m.to_upper()


func _next_map(m: String) -> String:
	for i in MAPS.size():
		if MAPS[i][0] == m:
			return str(MAPS[(i + 1) % MAPS.size()][0])
	return "new"
