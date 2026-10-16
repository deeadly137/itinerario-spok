class_name LobbyMap
extends Node2D
## Sala de espera: fundo MapLobby.jpeg, cada um anda com SUA caixa
## (cor aleatoria, sem cargo). Todos READY -> host START -> revelacao
## do cargo real -> partida.

signal started

const SPEED := 260.0

var game = null
var players := {}
var code_labels := {}
var ready_labels := {}
var ready_state := {}
var start_btn: Button = null
var my_code := ""
var revealed := false
var cam: Camera2D = null
var my_box: CharacterBody2D = null
var my_vel := Vector2.ZERO
var lobby_joy := -1
var lobby_center := Vector2.ZERO

const IMG_W := 896.0
const IMG_H := 1200.0
const SCALE := 1.5
const WORLD_W := 1344.0
const WORLD_H := 1800.0
const CENTER_PX := Vector2(448, 560)
const RING_R_PX := 250.0
const FAKE_COLORS := ["5bc8e8", "ff7b9c", "7be495", "d9c8ff", "ffe066", "ff9a5c", "e8e8e8", "9ad0ff", "ffc9c9"]

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
	cam.zoom = Vector2(0.55, 0.55)
	cam.enabled = true
	add_child(cam)
	my_code = "%03d" % randi_range(0, 999)
	var fake = FAKE_COLORS[randi() % FAKE_COLORS.size()]
	my_box = _add_box("local", my_code, fake)
	_show_ready()

func ring_pos(i, total):
	var cx = CENTER_PX.x * SCALE
	var cy = CENTER_PX.y * SCALE
	var rr = RING_R_PX * SCALE
	var a = TAU * i / max(1, total) - PI / 2.0
	return Vector2(cx + cos(a) * rr, cy + sin(a) * rr)
func _add_box(pid, code, color_hex):
	var box := CharacterBody2D.new()
	var rect := ColorRect.new()
	rect.color = Color(color_hex)
	rect.size = Vector2(40, 40)
	rect.position = Vector2(-20, -20)
	box.add_child(rect)
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(40, 40)
	col.shape = rs
	box.add_child(col)
	var lab := Label.new()
	lab.text = code
	lab.position = Vector2(-30, -52)
	lab.add_theme_font_size_override("font_size", 24)
	box.add_child(lab)
	var rl := Label.new()
	rl.text = ""
	rl.position = Vector2(-30, 24)
	rl.add_theme_font_size_override("font_size", 20)
	rl.add_theme_color_override("font_color", Color(0.4, 1, 0.5))
	box.add_child(rl)
	var n = players.size()
	box.position = ring_pos(n, 9)
	add_child(box)
	players[pid] = {"node": box, "code": code}
	code_labels[pid] = lab
	ready_labels[pid] = rl
	ready_state[pid] = false
	return box

func _unhandled_input(event) -> void:
	if revealed:
		return
	if event is InputEventScreenTouch and event.pressed:
		var vp = get_viewport().get_visible_rect().size
		if event.position.x < vp.x * 0.35 and event.position.y > vp.y * 0.55:
			lobby_joy = event.index
			lobby_center = event.position
	elif event is InputEventScreenTouch and not event.pressed and event.index == lobby_joy:
		lobby_joy = -1
		my_vel = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == lobby_joy:
		var d = event.position - lobby_center
		my_vel = d.normalized() * SPEED if d.length() > 12.0 else Vector2.ZERO
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var vp2 = get_viewport().get_visible_rect().size
		if event.position.x < vp2.x * 0.35 and event.position.y > vp2.y * 0.55:
			lobby_joy = -2
			lobby_center = event.position
	elif event is InputEventMouseButton and not event.pressed and lobby_joy == -2:
		lobby_joy = -1
		my_vel = Vector2.ZERO
	elif event is InputEventMouseMotion and lobby_joy == -2:
		var d2 = event.position - lobby_center
		my_vel = d2.normalized() * SPEED if d2.length() > 12.0 else Vector2.ZERO

func _physics_process(_delta) -> void:
	if my_box and my_vel.length() > 0.0 and not revealed:
		my_box.velocity = my_vel
		my_box.move_and_slide()

func _show_ready():
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.name = "LobbyUI"
	add_child(layer)
	var rb := Button.new()
	rb.text = "READY"
	rb.custom_minimum_size = Vector2(320, 110)
	rb.add_theme_font_size_override("font_size", 44)
	rb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rb.position = Vector2(-160, -150)
	rb.pressed.connect(func(): set_ready("local", true))
	layer.add_child(rb)
	if NetHub.online and NetHub.is_host:
		start_btn = Button.new()
		start_btn.text = "START"
		start_btn.custom_minimum_size = Vector2(320, 90)
		start_btn.add_theme_font_size_override("font_size", 40)
		start_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		start_btn.position = Vector2(-160, -260)
		start_btn.pressed.connect(_on_start)
		layer.add_child(start_btn)

func set_ready(pid, v):
	ready_state[pid] = v
	var rl: Label = ready_labels.get(pid)
	if rl:
		rl.text = "READY!" if v else ""

func all_ready():
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
	var txt = "CIENTISTA" if role == "scientist" else "ANIMAL: " + animal.to_upper()
	for pid in players:
		var lab: Label = code_labels[pid]
		if pid == "local" or pid == NetHub.local_id():
			lab.text = players[pid]["code"] + "\n" + txt
	var ui = get_node_or_null("LobbyUI")
	if ui:
		ui.queue_free()

func local_box():
	return my_box
