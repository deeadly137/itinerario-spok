class_name Player
extends CharacterBody2D
## Jogador = APENAS uma caixa 40x40 (projeto longo).
## PNG transparente futuro será aplicado DENTRO desta caixa pelo código
## de rede/skins — sem tripulante, sem pernas, sem visor, sem animação.

signal stepped

const BOX := 40.0
const RADIUS := 20.0
const SPEED := 260.0

var path: Array = []
var touch_target := Vector2.ZERO
var has_touch_target := false
var joy_dir := Vector2.ZERO
var moving_allowed := true
var world_w := 2200.0
var world_h := 1300.0
var use_waypoints := true
var _stuck_time := 0.0
var _last_pos := Vector2.ZERO
var speed_mul := 1.0
var body: ColorRect


func _ready() -> void:
	_last_pos = global_position


func build_visual() -> void:
	# APENAS a caixa. PNG futuro entra aqui dentro via add_skin().
	body = ColorRect.new()
	body.color = _tint_color()
	body.size = Vector2(BOX, BOX)
	body.position = Vector2(-BOX / 2.0, -BOX / 2.0)
	add_child(body)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	# Se existir a imagem do personagem, ela entra DENTRO da caixa: basta
	# soltar o PNG em res://assets/img/player.png (e/ou player_animal.png).
	for p in ["res://assets/img/player.png", "res://assets/img/crew.png"]:
		if ResourceLoader.exists(p):
			add_skin(load(p))
			break


## PNG transparente aplicado DENTRO da caixa (fundo: animals/scientists).
func add_skin(tex: Texture2D) -> void:
	for c in get_children():
		if c is Sprite2D:
			c.queue_free()
	var spr := Sprite2D.new()
	spr.texture = tex
	var ts: Vector2 = tex.get_size()
	if ts.x > 0.0:
		var s := BOX / maxf(ts.x, ts.y)
		spr.scale = Vector2(s, s)
	add_child(spr)


func _tint_color() -> Color:
	if NetHub.online:
		for a in NetHub.ANIMALS:
			if a["id"] == NetHub.my_animal:
				return Color(a["color"])
		for s in NetHub.SCIENTISTS:
			if s["id"] == NetHub.my_animal:
				return Color(s["color"])
	return Color("2b6cb0")


func _apply_tint(_spr: Sprite2D) -> void:
	pass


func stop() -> void:
	path.clear()
	has_touch_target = false
	joy_dir = Vector2.ZERO
	velocity = Vector2.ZERO


func go_to(world_point: Vector2) -> void:
	if use_waypoints:
		path = MapData.path_to(global_position, world_point)
	else:
		path = [world_point]
	has_touch_target = false


func _physics_process(delta: float) -> void:
	if not moving_allowed:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := Vector2.ZERO
	speed_mul = 1.0
	if joy_dir.length() > 0.15:
		dir = joy_dir.normalized()
		# joystick analogico: quanto mais longe do centro, mais rapido
		speed_mul = lerpf(0.55, 1.0, clampf(joy_dir.length(), 0.0, 1.0))
		path.clear()
		has_touch_target = false
	elif has_touch_target:
		var d := touch_target - global_position
		if d.length() < 10.0:
			has_touch_target = false
		else:
			dir = d.normalized()
	elif not path.is_empty():
		var wp: Vector2 = path[0]
		var d := wp - global_position
		if d.length() < 8.0:
			path.pop_front()
			_stuck_time = 0.0
		else:
			dir = d.normalized()
			var moved := global_position.distance_to(_last_pos)
			if moved < MapData.PLAYER_SPEED * delta * 0.2:
				_stuck_time += delta
				if _stuck_time > 1.1:
					path.clear()
					has_touch_target = false
					_stuck_time = 0.0
			else:
				_stuck_time = 0.0
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	velocity = dir * SPEED * speed_mul
	move_and_slide()
	# limites do mundo (por modo de mapa)
	global_position.x = clampf(global_position.x, RADIUS, world_w - RADIUS)
	global_position.y = clampf(global_position.y, RADIUS, world_h - RADIUS)
