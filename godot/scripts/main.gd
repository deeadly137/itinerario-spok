extends Node2D
## Main (parte 1) — mundo, boot, HUD mobile, input touch + joystick.

const MicroTask := preload("res://scripts/tasks/micro_task.gd")
const TankTask := preload("res://scripts/tasks/tank_task.gd")
const AtmoTask := preload("res://scripts/tasks/atmo_task.gd")
const ProbeTask := preload("res://scripts/tasks/probe_task.gd")
const LobbyUI := preload("res://scripts/lobby_ui.gd")
const ServerMenu := preload("res://scripts/server_menu.gd")
const LobbyMap := preload("res://scripts/lobby_map.gd")
const PlayMenu := preload("res://scripts/play_menu.gd")
const OptionsMenu := preload("res://scripts/options_menu.gd")

# "new" = MapNEW.jpeg (mapa refeito); "classic" = 2200x1300 (estável);
# "atlantis"/"temp" = legados
var map_mode := "new"

var world: GameWorld
var player: Player
var cam: Camera2D
var current_task: Control = null
var near_station := ""

var boot_layer: CanvasLayer
var hud_layer: CanvasLayer
var task_items := {}
var toast_label: Label
var toast_timer := 0.0
var use_btn: Button
var joy_base: Control
var joy_knob: Control
var joy_touch := -1
var joy_center := Vector2.ZERO
var sabotage: SabotageSys
var dark_layer: ColorRect
var hud_top: HBoxContainer
var hud_tasks: VBoxContainer
var tap_move := true
var joy_stick_on := true
const JOY_RING := 130.0    # raio visual do anel do joystick
const JOY_KNOB := 62.0     # tamanho do pino
const JOY_MAX := 110.0     # deslocamento maximo do pino (curso util)


func _ready() -> void:
	_build_world()
	_build_boot()
	_build_hud()
	sabotage = SabotageSys.new()
	add_child(sabotage)
	sabotage.blackout.connect(_on_blackout)
	sabotage.door_blocked.connect(_on_door_blocked)
	sabotage.sabotage_toast.connect(func(t: String) -> void: toast(t, 6.0))
	GameState.task_done.connect(_on_task_done)


func _on_blackout(active: bool) -> void:
	if active:
		if dark_layer == null:
			dark_layer = ColorRect.new()
			dark_layer.color = Color(0, 0, 0, 0.55)
			dark_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
			dark_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud_layer.add_child(dark_layer)
		dark_layer.visible = true
	elif dark_layer:
		dark_layer.visible = false


func _on_door_blocked(_name: String, active: bool) -> void:
	world.set_sabotage_block(active)
	if active:
		toast("Porta OESTE bloqueada! Use a porta LESTE.", 5.0)



func _build_world() -> void:
	world = GameWorld.new()
	add_child(world)
	world.build(false, map_mode)
	world.station_pressed.connect(_on_station_pressed)
	player = Player.new()
	if map_mode == "new":
		player.position = MapNew.px_to_world(MapNew.SPAWN_PX)
		player.world_w = MapNew.WORLD_W
		player.world_h = MapNew.WORLD_H
		player.use_waypoints = false
	elif map_mode == "atlantis":
		player.position = MapAtlantis.px_to_world(MapAtlantis.SPAWN_PX)
		player.world_w = MapAtlantis.WORLD_W
		player.world_h = MapAtlantis.WORLD_H
		player.use_waypoints = false
	elif map_mode == "temp":
		player.position = MapTemp.px_to_world(MapTemp.SPAWN_PX)
		player.world_w = MapTemp.WORLD_W
		player.world_h = MapTemp.WORLD_H
		player.use_waypoints = false
	else:
		player.position = MapData.SPAWN
	add_child(player)
	player.build_visual()
	player.stepped.connect(func() -> void: AudioSys.step())
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	# zoom: mostra ~640x360 unidades de mundo (cabe corredor + salas
	# próximas sem espremer; caixa de 40px fica legível no celular)
	var z := 1.0
	if map_mode == "new":
		z = 2.0
	cam.zoom = Vector2(z, z)
	var ww := MapData.WORLD_W
	var wh := MapData.WORLD_H
	if map_mode == "new":
		ww = MapNew.WORLD_W
		wh = MapNew.WORLD_H
	elif map_mode == "atlantis":
		ww = MapAtlantis.WORLD_W
		wh = MapAtlantis.WORLD_H
	elif map_mode == "temp":
		ww = MapTemp.WORLD_W
		wh = MapTemp.WORLD_H
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ww)
	cam.limit_bottom = int(wh)
	world.visible = false
	player.visible = false


func lbl(text: String, size := 22) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# ------------------------- BOOT / MENU PRINCIPAL -------------------------

func _menu_vbox() -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	vb.custom_minimum_size = Vector2(760, 0)
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	return vb


func _build_boot() -> void:
	boot_layer = CanvasLayer.new()
	boot_layer.layer = 10
	add_child(boot_layer)
	if ResourceLoader.exists("res://assets/img/menu_bg.jpg"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/img/menu_bg.jpg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		boot_layer.add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = Color("06121f")
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		boot_layer.add_child(bg)
	# véu escuro transparente sobre a imagem
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.55)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boot_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boot_layer.add_child(center)
	var vb := _menu_vbox()
	center.add_child(vb)
	var t := lbl("PROJETO ABISMO", 72)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(t)
	var sub := lbl("REGISTRO 8.1", 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sub)
	# Versao visivel: serve para conferir no celular se a instalacao pegou.
	var ver := lbl("v2.2  -  menus, lobby, joystick e minigames novos", 22)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_color_override("font_color", Color(0.55, 0.72, 0.85))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ver)
	var play := Button.new()
	play.text = "Jogar"
	play.custom_minimum_size = Vector2(420, 100)
	play.add_theme_font_size_override("font_size", 40)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_on_play_pressed)
	vb.add_child(play)
	var opts := Button.new()
	opts.text = "Opções"
	opts.custom_minimum_size = Vector2(420, 72)
	opts.add_theme_font_size_override("font_size", 30)
	opts.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	opts.pressed.connect(_on_options_pressed)
	vb.add_child(opts)


func _apply_joy() -> void:
	if joy_base:
		joy_base.visible = false
	joy_touch = -1
	if player:
		player.joy_dir = Vector2.ZERO


func _on_options_pressed() -> void:
	var o := OptionsMenu.new()
	boot_layer.add_child(o)
	o.build(self)


func _on_play_pressed() -> void:
	var pm := PlayMenu.new()
	boot_layer.add_child(pm)
	pm.build(self)
	pm.back.connect(func() -> void: pm.queue_free())
	pm.found_match.connect(func(ip, code) -> void: pm.queue_free(); _open_lobby_map())
	pm.host_match.connect(func(code) -> void: pm.queue_free(); _open_lobby_map())


func _open_lobby_map() -> void:
	boot_layer.visible = false
	var lobby := LobbyMap.new()
	add_child(lobby)
	lobby.build(self)
	move_child(lobby, 0)
	NetHub.game_started.connect(func() -> void: _on_match_start(lobby))
	lobby.started.connect(func() -> void: _on_match_start(lobby))


func _on_match_start(lobby: LobbyMap) -> void:
	var role := NetHub.my_role
	var animal := NetHub.my_animal
	if role == "":
		role = "animal"
		animal = "pteropode"
	# Modo solo nao passa pelo start_match: grava o papel para que o sprite
	# e a cor do personagem saiam certos.
	if NetHub.my_role == "":
		NetHub.my_role = role
		NetHub.my_animal = animal
	player.apply_role_skin()
	lobby.reveal(role, animal)
	await get_tree().create_timer(2.5).timeout
	# Assume o controle da tela ANTES de liberar o lobby (senao a camera
	# fica sem dono e a espera dos cientistas virava tela preta).
	cam.make_current()
	world.visible = true
	player.visible = true
	hud_layer.visible = true
	lobby.queue_free()
	var role_txt := "VOCE E ANIMAL: " + animal.to_upper() + "\nEntrou 10 s antes dos cientistas!"
	if role == "scientist":
		role_txt = "VOCE E CIENTISTA\nOs animais ja entraram. Voce entra em 10 s!"
		player.moving_allowed = false
	toast(role_txt, 8.0)
	# vantagem dos animais: entram 10 s antes dos cientistas
	if role == "scientist":
		await get_tree().create_timer(10.0).timeout
	_start_game()


func _start_game() -> void:
	boot_layer.visible = false
	hud_layer.visible = true
	world.visible = true
	player.visible = true
	player.moving_allowed = true
	cam.make_current()
	sabotage.start()
	toast("Chegue perto de um objeto e toque USAR! Cuidado com sabotagens...")


# ------------------------- HUD -------------------------

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	hud_layer.visible = false
	add_child(hud_layer)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 12)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.visible = false
	hud_layer.add_child(top)
	var title := lbl("", 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(title)
	hud_top = top
	var tasks := VBoxContainer.new()
	tasks.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tasks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tasks.position = Vector2(12, 60)
	tasks.add_theme_constant_override("separation", 4)
	tasks.visible = false
	hud_layer.add_child(tasks)
	hud_tasks = tasks
	var defs := [["micro", "Microscopio"], ["tank", "Tanques"],
		["atmo", "Atmosfera"], ["probe", "Sonda (3 chaves)"]]
	for d in defs:
		var l := lbl("O " + d[1], 22)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tasks.add_child(l)
		task_items[d[0]] = l
	toast_label = lbl("", 24)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.position = Vector2(-480, -190)
	toast_label.custom_minimum_size = Vector2(960, 0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.visible = false
	hud_layer.add_child(toast_label)
	use_btn = Button.new()
	use_btn.text = "USAR"
	use_btn.custom_minimum_size = Vector2(220, 220)
	use_btn.add_theme_font_size_override("font_size", 40)
	use_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	use_btn.position = Vector2(-252, -400)
	use_btn.visible = false
	use_btn.pressed.connect(_on_use_pressed)
	var us := StyleBoxFlat.new()
	us.bg_color = Color("166534")
	us.border_color = Color.WHITE
	us.set_border_width_all(4)
	use_btn.add_theme_stylebox_override("normal", us)
	hud_layer.add_child(use_btn)
	# Joystick DINAMICO: o anel nasce onde o dedo encosta e o pino segue o
	# arrasto (nao fica preso no canto). joy_base e so um retangulo que a
	# gente move pela tela; fica escondido quando ninguem esta tocando.
	joy_base = Control.new()
	joy_base.name = "JoyBase"
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.size = Vector2(JOY_RING * 2.0, JOY_RING * 2.0)
	joy_base.visible = false
	hud_layer.add_child(joy_base)
	var ring := ColorRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.color = Color(1, 1, 1, 0.15)
	ring.size = Vector2(JOY_RING * 2.0, JOY_RING * 2.0)
	joy_base.add_child(ring)
	var ring_in := ColorRect.new()
	ring_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_in.color = Color(1, 1, 1, 0.10)
	ring_in.size = Vector2(JOY_RING, JOY_RING)
	ring_in.position = Vector2(JOY_RING * 0.5, JOY_RING * 0.5)
	joy_base.add_child(ring_in)
	joy_knob = ColorRect.new()
	(joy_knob as ColorRect).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(joy_knob as ColorRect).color = Color(0.55, 0.85, 1.0, 0.7)
	(joy_knob as ColorRect).size = Vector2(JOY_KNOB, JOY_KNOB)
	_place_knob(Vector2.ZERO)
	joy_base.add_child(joy_knob)


func _place_knob(offset: Vector2) -> void:
	(joy_knob as ColorRect).position = Vector2(JOY_RING, JOY_RING) + offset \
		- Vector2(JOY_KNOB * 0.5, JOY_KNOB * 0.5)


func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.visible = false
	_update_proximity()


func toast(text: String, secs := 4.0) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_timer = secs


# ------------------------- INPUT -------------------------

# _input (não _unhandled_input): as estações consomem o toque via
# Area2D.input_event, então _unhandled_input nunca receberia o tap-to-move.
func _input(event: InputEvent) -> void:
	if not hud_layer.visible:
		return
	# ESC fecha o minigame (a nao ser que ele esteja bloqueando a saida).
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and current_task:
			_close_task()
			get_viewport().set_input_as_handled()
			return
	if current_task:
		return
	if event is InputEventScreenTouch and event.pressed:
		var p: Vector2 = event.position
		if _touch_on_station(p) or _over_use_button(p):
			return
		if _joy_zone(p) and joy_touch == -1:
			_joy_start(event.index, p)
		elif tap_move:
			player.go_to(_screen_to_world(p))
	elif event is InputEventScreenTouch and not event.pressed and event.index == joy_touch:
		_joy_end()
	elif event is InputEventScreenDrag and event.index == joy_touch:
		_drag_joy(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_on_station(event.position) or _over_use_button(event.position):
			return
		if _joy_zone(event.position) and joy_touch == -1:
			_joy_start(-2, event.position)
		elif tap_move:
			player.go_to(_screen_to_world(event.position))
	elif event is InputEventMouseButton and not event.pressed and joy_touch == -2:
		_joy_end()
	elif event is InputEventMouseMotion and joy_touch == -2:
		_drag_joy(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_on_use_pressed()
			get_viewport().set_input_as_handled()


## Zona em que o joystick pode nascer: metade de baixo, fora do botao USAR.
func _joy_zone(p: Vector2) -> bool:
	if not joy_stick_on:
		return false
	var vp := get_viewport().get_visible_rect().size
	return p.y > vp.y * 0.45 and p.x < vp.x * 0.8


func _over_use_button(p: Vector2) -> bool:
	return use_btn != null and use_btn.visible and use_btn.get_global_rect().has_point(p)


func _joy_start(idx: int, p: Vector2) -> void:
	joy_touch = idx
	joy_center = p
	player.stop()
	joy_base.position = p - Vector2(JOY_RING, JOY_RING)
	joy_base.visible = true
	_place_knob(Vector2.ZERO)


func _joy_end() -> void:
	joy_touch = -1
	player.joy_dir = Vector2.ZERO
	if joy_base:
		joy_base.visible = false


func _drag_joy(screen_p: Vector2) -> void:
	var d := screen_p - joy_center
	if d.length() > JOY_MAX:
		joy_center = screen_p - d.normalized() * JOY_MAX
		d = screen_p - joy_center
	player.joy_dir = d / JOY_MAX
	_place_knob(d)


func _screen_to_world(p: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * p


## Toque caiu sobre alguma estação? Usa a MESMA area do piso (antes usava
## 90 px fixos, o que criava uma zona morta entre o piso visivel e o toque).
func _touch_on_station(screen_p: Vector2) -> bool:
	var w := _screen_to_world(screen_p)
	for id in world.stations:
		var st: Station = world.stations[id]
		if w.distance_to(st.position) <= st.pad_radius:
			return true
	return false


func _stations() -> Dictionary:
	if map_mode == "new":
		var d := {}
		for id in MapNew.STATIONS_PX:
			var e: Dictionary = MapNew.STATIONS_PX[id]
			d[id] = {"pos": MapNew.px_to_world(e["px"]), "name": e["name"], "radius": float(e["radius"])}
		return d
	if map_mode == "atlantis":
		var d := {}
		for id in MapAtlantis.STATIONS_PX:
			var e: Dictionary = MapAtlantis.STATIONS_PX[id]
			d[id] = {"pos": MapAtlantis.px_to_world(e["px"]), "name": e["name"], "radius": float(e["radius"])}
		return d
	if map_mode == "temp":
		var d := {}
		for id in MapTemp.STATIONS_PX:
			var e: Dictionary = MapTemp.STATIONS_PX[id]
			d[id] = {"pos": MapTemp.px_to_world(e["px"]), "name": e["name"], "radius": float(e["radius"])}
		return d
	return MapData.STATIONS


func _update_proximity() -> void:
	if not hud_layer.visible:
		return
	var sts := _stations()
	# marca a estacao mais proxima (destaca o "piso" dela no mapa)
	var best := ""
	var best_d := 1e9
	for id in sts:
		var d: float = player.global_position.distance_to(sts[id]["pos"])
		if d <= float(sts[id]["radius"]) and d < best_d:
			best = id
			best_d = d
	for id in world.stations:
		(world.stations[id] as Station).set_near(id == best)
	if best != near_station:
		near_station = best
		if best == "":
			use_btn.visible = false
		else:
			use_btn.text = "USAR\n" + String(sts[best]["name"])
			use_btn.visible = true


func _on_use_pressed() -> void:
	if near_station == "" or current_task:
		return
	_open_task(near_station)


func _on_station_pressed(id: String) -> void:
	AudioSys.click()
	var st_pos: Vector2 = _stations()[id]["pos"]
	if player.global_position.distance_to(st_pos) <= float(_stations()[id]["radius"]):
		_open_task(id)
		return
	player.go_to(st_pos)
	toast("Indo para " + String(_stations()[id]["name"]) + "...")


func _open_task(id: String) -> void:
	if current_task:
		return
	AudioSys.click()
	player.stop()
	player.moving_allowed = false
	use_btn.visible = false
	var t: Control
	match id:
		"micro":
			t = MicroTask.new()
		"tank":
			t = TankTask.new()
		"atmo":
			t = AtmoTask.new()
		_:
			t = ProbeTask.new()
	t.set_meta("task_id", id)
	current_task = t
	hud_layer.add_child(t)
	t.call("build_task", self)


func _close_task() -> void:
	if current_task == null:
		return
	if current_task.has_method("request_close"):
		current_task.request_close()
	else:
		force_close_task()


## Fechamento de fato (o minigame decide QUANDO pode fechar).
func force_close_task() -> void:
	if current_task:
		current_task.queue_free()
		current_task = null
	player.moving_allowed = true
	_update_proximity()


func _on_task_done(task_id: String) -> void:
	var l: Label = task_items.get(task_id)
	if l:
		if not l.text.begins_with("OK"):
			l.text = "OK   " + l.text
		l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.45))
	var st: Station = world.stations.get(task_id)
	if st:
		st.mark_done()
	toast("Tarefa concluída! (%d/3)" % GameState.tasks_done(), 4.0)


