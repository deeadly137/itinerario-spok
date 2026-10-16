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


func _overlay_base(title: String) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.name = "TaskRoot"
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101b2e")
	sb.border_color = Color("3b5a7a")
	sb.set_border_width_all(3)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var h := Label.new()
	h.text = title
	h.add_theme_font_size_override("font_size", 30)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(h)
	var close := Button.new()
	close.text = "FECHAR"
	close.pressed.connect(func() -> void: _close_task())
	head.add_child(close)
	return vb


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
	var ver := lbl("v2.1  -  mapa e salas corrigidos", 22)
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
	var jb = hud_layer.get_node_or_null("JoyBase")
	if jb:
		jb.visible = joy_stick_on


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
	lobby.reveal(role, animal)
	await get_tree().create_timer(2.5).timeout
	lobby.queue_free()
	# vantagem dos animais: entram 10 s antes dos cientistas
	if role == "scientist":
		toast("Os animais infiltraram-se... você entra em 10 s!", 6.0)
		await get_tree().create_timer(10.0).timeout
	_start_game()


func _start_game() -> void:
	boot_layer.visible = false
	hud_layer.visible = true
	world.visible = true
	player.visible = true
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
	joy_base = Control.new()
	joy_base.name = "JoyBase"
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.custom_minimum_size = Vector2(260, 260)
	joy_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joy_base.position = Vector2(20, -300)
	joy_base.visible = joy_stick_on
	hud_layer.add_child(joy_base)
	var ring := ColorRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.color = Color(1, 1, 1, 0.18)
	ring.size = Vector2(220, 220)
	ring.position = Vector2(20, 20)
	joy_base.add_child(ring)
	joy_knob = ColorRect.new()
	(joy_knob as ColorRect).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(joy_knob as ColorRect).color = Color(1, 1, 1, 0.55)
	(joy_knob as ColorRect).size = Vector2(96, 96)
	(joy_knob as ColorRect).position = Vector2(82, 82)
	joy_base.add_child(joy_knob)


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
	if not hud_layer.visible or current_task:
		return
	if event is InputEventScreenTouch and event.pressed:
		if _touch_on_station(event.position):
			return
		var vp := get_viewport().get_visible_rect().size
		var p: Vector2 = event.position
		if p.x < vp.x * 0.35 and p.y > vp.y * 0.55 and joy_touch == -1:
			joy_touch = event.index
			joy_center = p
			player.path.clear()
		elif tap_move:
			player.go_to(_screen_to_world(p))
	elif event is InputEventScreenTouch and not event.pressed and event.index == joy_touch:
		joy_touch = -1
		player.joy_dir = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == joy_touch:
		_drag_joy(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_on_station(event.position):
			return
		var vp2 := get_viewport().get_visible_rect().size
		if event.position.x < vp2.x * 0.35 and event.position.y > vp2.y * 0.55:
			joy_touch = -2
			joy_center = event.position
		elif tap_move:
			player.go_to(_screen_to_world(event.position))
	elif event is InputEventMouseButton and not event.pressed and joy_touch == -2:
		joy_touch = -1
		player.joy_dir = Vector2.ZERO
	elif event is InputEventMouseMotion and joy_touch == -2:
		_drag_joy(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E, KEY_SPACE:
				_on_use_pressed()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if current_task and current_task.get_meta("task_id", "") != "probe":
					_close_task()


func _drag_joy(screen_p: Vector2) -> void:
	var d := screen_p - joy_center
	if d.length() > 90.0:
		joy_center = screen_p - d.normalized() * 90.0
		d = screen_p - joy_center
	player.joy_dir = d / 90.0
	(joy_knob as ColorRect).position = Vector2(82, 82) + d * 0.9


func _screen_to_world(p: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * p


## Toque caiu sobre alguma estação? (evita andar + abrir tarefa juntos)
func _touch_on_station(screen_p: Vector2) -> bool:
	var w := _screen_to_world(screen_p)
	for id in world.stations:
		var st: Station = world.stations[id]
		if w.distance_to(st.position) <= 90.0:
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
	var found := ""
	for id in _stations():
		var st_pos: Vector2 = _stations()[id]["pos"]
		var radius: float = _stations()[id]["radius"]
		if player.global_position.distance_to(st_pos) <= radius:
			found = id
			break
	if found != near_station:
		near_station = found
		if found == "":
			use_btn.visible = false
		else:
			var nm: String = _stations()[found]["name"]
			use_btn.text = "USAR\n" + nm
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
	if current_task:
		var tid: String = current_task.get_meta("task_id", "")
		if tid == "probe" and current_task.get("timer_running"):
			toast("ALARME ATIVO: escolha um protocolo antes de sair!")
			return
		current_task.queue_free()
		current_task = null
	player.moving_allowed = true
	_update_proximity()


func _on_task_done(task_id: String) -> void:
	var l: Label = task_items[task_id]
	if not l.text.begins_with("OK"):
		l.text = "OK " + l.text.substr(2)
	l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.45))
	var st: Station = world.stations.get(task_id)
	if st:
		st.mark_done()
	AudioSys.key()
	_close_task()
	toast("Tarefa concluída! (%d/3)" % GameState.tasks_done(), 4.0)


