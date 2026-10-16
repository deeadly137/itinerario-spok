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
var toast_label: Label
var toast_timer := 0.0
var use_btn: Button
var joy_base: Control
var joy_knob: Control
var joy_touch := -1
var joy_center := Vector2.ZERO
var sabotage: SabotageSys
var dark_layer: ColorRect
var blackout_on := false
var _flick_t := 0.0
const DARK_BASE := 0.72
# HUD (muda conforme o papel): barras no topo-centro + icone de mapa.
var top_hud: HBoxContainer
var bars_col: VBoxContainer
var hp_bar: Control
var tasks_bar: Control
var sabotage_btn: Button
var sabotage_fill: ColorRect
var map_btn: Button
var map_overlay: Control = null
var map_img_rect := Rect2()
var map_player_dot: Control = null
var my_role := "animal"
var sabotage_cd := 0.0
const SABOTAGE_CD := 25.0
var world_w := 2688.0
var world_h := 3600.0
var tap_move := true
var joy_stick_on := true
var in_match := false
var remotes := {}          # pid -> RemoteCrew (mapa)
var remotes_root: Node2D = null
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
	GameState.task_done.connect(_on_task_done)
	# Rede: posicoes dos outros e lista de jogadores (o lobby cuida do lobby).
	NetHub.peer_moved.connect(_on_peer_moved)
	NetHub.roster_changed.connect(_on_roster_changed)
	NetHub.peer_left.connect(_on_peer_left)
	NetHub.host_left.connect(func() -> void: toast("O host saiu da partida.", 5.0))
	NetHub.map_changed.connect(func(m: String) -> void: apply_map_mode(m))
	NetHub.sabotage_requested.connect(_on_sabotage_requested)


func _on_blackout(active: bool) -> void:
	blackout_on = active
	if active:
		if dark_layer == null:
			dark_layer = ColorRect.new()
			dark_layer.color = Color(0, 0, 0, DARK_BASE)
			dark_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
			dark_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud_layer.add_child(dark_layer)
		dark_layer.visible = true
		_flick_t = 0.0
	elif dark_layer:
		dark_layer.visible = false


## Luz falhando: quase sempre escuro, com claroes curtos e irregulares.
func _next_dark_alpha() -> float:
	var roll := randf()
	if roll < 0.14:
		return 0.05      # a lampada reacende por um instante
	if roll < 0.38:
		return 0.40
	return DARK_BASE

func _build_world() -> void:
	world = GameWorld.new()
	add_child(world)
	world.build(false, map_mode)
	world.station_pressed.connect(_on_station_pressed)
	player = Player.new()
	add_child(player)
	player.build_visual()
	player.stepped.connect(func() -> void: AudioSys.step())
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	_apply_world_geometry()
	world.visible = false
	player.visible = false


## Posicao de nascimento, tamanho do mundo, zoom e limites da camera conforme
## o mapa escolhido. Separado para poder reaplicar quando o host troca o mapa.
func _apply_world_geometry() -> void:
	var sp := MapData.SPAWN
	var ww := MapData.WORLD_W
	var wh := MapData.WORLD_H
	var z := 1.0
	var wp := true
	match map_mode:
		"new":
			sp = MapNew.px_to_world(MapNew.SPAWN_PX)
			ww = MapNew.WORLD_W
			wh = MapNew.WORLD_H
			z = 2.0
			wp = false
		"atlantis":
			sp = MapAtlantis.px_to_world(MapAtlantis.SPAWN_PX)
			ww = MapAtlantis.WORLD_W
			wh = MapAtlantis.WORLD_H
			wp = false
		"temp":
			sp = MapTemp.px_to_world(MapTemp.SPAWN_PX)
			ww = MapTemp.WORLD_W
			wh = MapTemp.WORLD_H
			wp = false
	player.position = sp
	player.world_w = ww
	player.world_h = wh
	player.use_waypoints = wp
	cam.zoom = Vector2(z, z)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ww)
	cam.limit_bottom = int(wh)
	world_w = ww
	world_h = wh


## Troca o mapa em tempo real (escolha do host no lobby). No mapa "new" a
## camera fica mais aproximada; nos outros, zoom 1.0.
func apply_map_mode(mode: String) -> void:
	map_mode = mode
	world.build(false, map_mode)
	_apply_world_geometry()


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
	# A partir daqui eu publico a minha posicao e passo a ver os outros.
	in_match = true
	NetHub.clear_my_pos()
	if NetHub.online:
		player.global_position = _spawn_at(NetHub.my_index)
	await get_tree().create_timer(2.5).timeout
	# Assume o controle da tela ANTES de liberar o lobby (senao a camera
	# fica sem dono e a espera dos cientistas virava tela preta).
	cam.make_current()
	world.visible = true
	player.visible = true
	hud_layer.visible = true
	boot_layer.visible = false
	_spawn_remotes()
	lobby.queue_free()
	# HUD de acordo com o papel (animais: HP; cientistas: botao de sabotagem).
	_configure_hud(role)
	# O jogador so anda depois do fade de abertura (que revela a classe).
	player.moving_allowed = false
	sabotage.start()
	await _reveal_intro(role, animal)
	# vantagem dos animais: entram ~10 s antes dos cientistas
	if role == "scientist":
		await get_tree().create_timer(8.0).timeout
	player.moving_allowed = true


## Fade para uma tela preta que revela a classe do jogador (e o animal, se
## for animal) e depois volta para o jogo.
func _reveal_intro(role: String, animal: String) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 40
	add_child(cl)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(black)
	var txt := "VOCÊ É ANIMAL"
	var col := Color("9fe8ff")
	if role == "scientist":
		txt = "VOCÊ É CIENTISTA"
		col = Color("e8e8e8")
	else:
		txt = "VOCÊ É ANIMAL\n" + animal.to_upper()
		col = Color(NetHub.role_color("animal", animal))
	var lab := lbl(txt, 60)
	lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_color_override("font_color", col)
	lab.modulate.a = 0.0
	cl.add_child(lab)
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, 0.7)
	tw.parallel().tween_property(lab, "modulate:a", 1.0, 0.7)
	tw.tween_interval(2.4)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(black, "color:a", 0.0, 0.7)
	tw2.parallel().tween_property(lab, "modulate:a", 0.0, 0.7)
	await tw2.finished
	cl.queue_free()


func _on_sabotage_requested(kind: String) -> void:
	if kind == "blackout":
		sabotage.force_blackout()


func _on_sabotage_pressed() -> void:
	if sabotage_cd > 0.0 or current_task:
		return
	sabotage_cd = SABOTAGE_CD
	AudioSys.click()
	if NetHub.online:
		NetHub.request_sabotage("blackout")
	else:
		sabotage.force_blackout()


# ------------------------- REDE (jogadores remotos) -------------------------

## Ponto de nascimento de cada jogador: todos no mesmo lugar do mapa, mas
## espalhados num anel curto para nao nascerem um dentro do outro.
func _spawn_at(i: int) -> Vector2:
	var base: Vector2 = player.global_position
	if map_mode == "new":
		base = MapNew.px_to_world(MapNew.SPAWN_PX)
	var a := TAU * float(i % 9) / 9.0
	return base + Vector2(cos(a), sin(a)) * 46.0


## Cria/atualiza os personagens dos outros jogadores. Idempotente: pode ser
## chamado de novo quando alguem entra ou sai no meio da partida.
func _spawn_remotes() -> void:
	if remotes_root == null:
		remotes_root = Node2D.new()
		remotes_root.name = "Remotes"
		# filho por ULTIMO = desenhado por cima do mapa
		add_child(remotes_root)
	var me: int = NetHub.local_id()
	for pid in remotes.keys():
		if not NetHub.players.has(pid):
			var velho = remotes[pid]
			if is_instance_valid(velho):
				velho.queue_free()
			remotes.erase(pid)
	var i := 0
	for pid in NetHub.players.keys():
		if pid == me:
			continue
		var e: Dictionary = NetHub.players[pid]
		var role := str(e.get("role", ""))
		var animal := str(e.get("animal", ""))
		var nm := str(e.get("name", "P%d" % pid))
		if remotes.has(pid):
			(remotes[pid] as RemoteCrew).apply_role(role, animal, nm)
		else:
			var rc := RemoteCrew.new()
			rc.name = "R%d" % pid
			remotes_root.add_child(rc)
			rc.setup(int(pid), role, animal, nm, _spawn_at(int(e.get("index", i))))
			remotes[pid] = rc
		i += 1
	remotes_root.visible = world.visible and NetHub.online


func _on_roster_changed() -> void:
	if in_match:
		_spawn_remotes()


func _on_peer_moved(pid, pos: Vector2) -> void:
	if remotes.has(pid):
		(remotes[pid] as RemoteCrew).set_target(pos)


func _on_peer_left(pid) -> void:
	if remotes.has(pid):
		var rc = remotes[pid]
		if is_instance_valid(rc):
			rc.queue_free()
		remotes.erase(pid)


# ------------------------- HUD -------------------------

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	hud_layer.visible = false
	add_child(hud_layer)
	# ---- topo-centro: barras do papel + icone de mapa ----
	top_hud = HBoxContainer.new()
	top_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_hud.offset_top = 12
	top_hud.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hud.add_theme_constant_override("separation", 18)
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(top_hud)
	bars_col = VBoxContainer.new()
	bars_col.add_theme_constant_override("separation", 8)
	bars_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hud.add_child(bars_col)
	hp_bar = _make_bar(600, 46, Color("b8342b"))
	tasks_bar = _make_bar(600, 46, Color("2e86c1"))
	# Botao de sabotagem (cientista) com barra de recarga por cima.
	sabotage_btn = Button.new()
	sabotage_btn.custom_minimum_size = Vector2(600, 54)
	sabotage_btn.add_theme_font_size_override("font_size", 26)
	sabotage_btn.text = "SABOTAGEM"
	sabotage_btn.pressed.connect(_on_sabotage_pressed)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("5a1a1a")
	sb.border_color = Color("d64545")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sabotage_btn.add_theme_stylebox_override("normal", sb)
	sabotage_btn.add_theme_stylebox_override("disabled", sb)
	var sb_layer := Control.new()
	sb_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sb_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sabotage_btn.add_child(sb_layer)
	sabotage_fill = ColorRect.new()
	sabotage_fill.color = Color(0.85, 0.2, 0.2, 0.45)
	sabotage_fill.position = Vector2.ZERO
	sabotage_fill.size = Vector2.ZERO
	sabotage_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_layer.add_child(sabotage_fill)
	# Icone de mapa (a direita das barras).
	map_btn = Button.new()
	map_btn.text = "MAPA"
	map_btn.custom_minimum_size = Vector2(104, 104)
	map_btn.add_theme_font_size_override("font_size", 24)
	map_btn.pressed.connect(_toggle_map)
	top_hud.add_child(map_btn)
	# ---- avisos (toast) ----
	toast_label = lbl("", 24)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.position = Vector2(-480, -190)
	toast_label.custom_minimum_size = Vector2(960, 0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.visible = false
	hud_layer.add_child(toast_label)
	# ---- botao USAR ----
	use_btn = Button.new()
	use_btn.text = "USAR"
	use_btn.custom_minimum_size = Vector2(220, 220)
	use_btn.add_theme_font_size_override("font_size", 40)
	use_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	use_btn.position = Vector2(-252, -400)
	use_btn.visible = false
	use_btn.pressed.connect(_on_use_pressed)
	var us := StyleBoxFlat.new()
	us.bg_color = Color("166534")
	us.border_color = Color.WHITE
	us.set_border_width_all(4)
	use_btn.add_theme_stylebox_override("normal", us)
	hud_layer.add_child(use_btn)
	# ---- joystick REDONDO e flutuante (nasce onde o dedo encosta) ----
	joy_base = Control.new()
	joy_base.name = "JoyBase"
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.size = Vector2(JOY_RING * 2.0, JOY_RING * 2.0)
	joy_base.visible = false
	joy_base.draw.connect(_draw_joy_base)
	hud_layer.add_child(joy_base)
	joy_knob = Control.new()
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_knob.size = Vector2(JOY_KNOB, JOY_KNOB)
	joy_knob.draw.connect(_draw_joy_knob)
	_place_knob(Vector2.ZERO)
	joy_base.add_child(joy_knob)


## Barra (fundo + preenchimento + texto). Guarda fill/label/largura nas meta.
func _make_bar(w: float, h: float, color: Color) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(w, h)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.size = Vector2(w, h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = Vector2(3, 3)
	fill.size = Vector2(w - 6.0, h - 6.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fill)
	var lab := Label.new()
	lab.size = Vector2(w, h)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", int(h * 0.5))
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lab)
	root.set_meta("fill", fill)
	root.set_meta("label", lab)
	root.set_meta("w", w)
	return root


func _set_bar(bar: Control, frac: float, text: String) -> void:
	if bar == null:
		return
	var w: float = float(bar.get_meta("w"))
	var fill: ColorRect = bar.get_meta("fill")
	fill.size = Vector2(maxf(0.0, (w - 6.0) * clampf(frac, 0.0, 1.0)), fill.size.y)
	(bar.get_meta("label") as Label).text = text


func _update_task_bar() -> void:
	var total: int = maxi(1, GameState.tasks.size())
	var done := GameState.tasks_done()
	_set_bar(tasks_bar, float(done) / float(total), "TAREFAS %d/%d" % [done, total])


func _update_hp_bar() -> void:
	_set_bar(hp_bar, 1.0, "HP 100/100")


## Monta o topo conforme o papel: animais = HP + tarefas; cientistas =
## tarefas + botao de sabotagem.
func _configure_hud(role: String) -> void:
	my_role = role
	for c in bars_col.get_children():
		bars_col.remove_child(c)
	if role == "scientist":
		bars_col.add_child(tasks_bar)
		bars_col.add_child(sabotage_btn)
	else:
		bars_col.add_child(hp_bar)
		bars_col.add_child(tasks_bar)
	_update_task_bar()
	_update_hp_bar()


# ------------------------- MAPA (overlay) -------------------------

func _map_bg_path() -> String:
	match map_mode:
		"new":
			return "res://assets/img/map_new.jpg"
		"atlantis":
			return "res://assets/img/map_main.jpg"
		"temp":
			return "res://assets/img/map_temp.png"
	return ""


func _toggle_map() -> void:
	if map_overlay == null:
		_open_map()
	else:
		_close_map()


func _close_map() -> void:
	if map_overlay and is_instance_valid(map_overlay):
		map_overlay.queue_free()
	map_overlay = null
	map_player_dot = null


func _open_map() -> void:
	if map_overlay:
		return
	AudioSys.click()
	var vp := get_viewport().get_visible_rect().size
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_layer.add_child(ov)
	map_overlay = ov
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_map())
	ov.add_child(bg)
	# area do mapa, mantendo a proporcao do mundo
	var avail := Vector2(vp.x * 0.92, vp.y * 0.86)
	var aspect := world_w / maxf(1.0, world_h)
	var sz := Vector2(avail.x, avail.x / aspect)
	if sz.y > avail.y:
		sz.y = avail.y
		sz.x = avail.y * aspect
	map_img_rect = Rect2((vp - sz) * 0.5, sz)
	var frame := Control.new()
	frame.position = map_img_rect.position
	frame.size = map_img_rect.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(frame)
	var path := _map_bg_path()
	if path != "" and ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_SCALE
		tex.size = map_img_rect.size
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tex)
	else:
		var ph := ColorRect.new()
		ph.color = Color("16283a")
		ph.size = map_img_rect.size
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(ph)
	# pontos de interesse (tarefas) + posicao do jogador
	for id in world.stations:
		var st: Station = world.stations[id]
		var col := Color("38bdf8")
		if st.done:
			col = Color("22c55e")
		var dot := _dot(col, 12.0)
		dot.position = _world_to_map(st.position) - Vector2(12, 12)
		frame.add_child(dot)
	map_player_dot = _dot(Color("ffd23f"), 15.0)
	frame.add_child(map_player_dot)
	_update_map_player_dot()
	var xb := Button.new()
	xb.text = "X"
	xb.custom_minimum_size = Vector2(84, 84)
	xb.add_theme_font_size_override("font_size", 34)
	xb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 18)
	xb.pressed.connect(_close_map)
	ov.add_child(xb)


func _dot(color: Color, r: float) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(r * 2.0, r * 2.0)
	p.size = Vector2(r * 2.0, r * 2.0)
	var st := StyleBoxFlat.new()
	st.bg_color = color
	st.set_corner_radius_all(int(r) + 1)
	st.border_color = Color(0, 0, 0, 0.85)
	st.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _world_to_map(wpos: Vector2) -> Vector2:
	var n := Vector2(wpos.x / maxf(1.0, world_w), wpos.y / maxf(1.0, world_h))
	return map_img_rect.position + n * map_img_rect.size


func _update_map_player_dot() -> void:
	if map_player_dot and is_instance_valid(map_player_dot):
		map_player_dot.position = _world_to_map(player.global_position) - Vector2(15, 15)


# ------------------------- JOYSTICK (desenho redondo) -------------------------

func _draw_joy_base() -> void:
	var c := Vector2(JOY_RING, JOY_RING)
	joy_base.draw_circle(c, JOY_RING, Color(1, 1, 1, 0.10))
	joy_base.draw_circle(c, JOY_RING * 0.52, Color(1, 1, 1, 0.08))
	joy_base.draw_arc(c, JOY_RING, 0.0, TAU, 64, Color(1, 1, 1, 0.35), 4.0)


func _draw_joy_knob() -> void:
	joy_knob.draw_circle(Vector2(JOY_KNOB, JOY_KNOB) * 0.5, JOY_KNOB * 0.5,
		Color(0.55, 0.85, 1.0, 0.85))


func _place_knob(offset: Vector2) -> void:
	joy_knob.position = Vector2(JOY_RING, JOY_RING) + offset \
		- Vector2(JOY_KNOB * 0.5, JOY_KNOB * 0.5)


func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.visible = false
	# Blecaute: a luz pisca (claroes curtos) enquanto as luzes estao fora.
	if blackout_on and dark_layer:
		_flick_t -= delta
		if _flick_t <= 0.0:
			dark_layer.color = Color(0, 0, 0, _next_dark_alpha())
			_flick_t = randf_range(0.04, 0.26)
	# Joystick: some suavemente quando ninguem esta tocando.
	if joy_touch == -1 and joy_base and joy_base.visible:
		joy_base.modulate.a = maxf(0.0, joy_base.modulate.a - delta * 5.0)
		if joy_base.modulate.a <= 0.02:
			joy_base.visible = false
	# Botao de sabotagem: recarga e barra.
	if my_role == "scientist" and sabotage_btn and sabotage_btn.is_inside_tree():
		if sabotage_cd > 0.0:
			sabotage_cd = maxf(0.0, sabotage_cd - delta)
		sabotage_btn.disabled = sabotage_cd > 0.0
		sabotage_btn.text = "SABOTAGEM" if sabotage_cd <= 0.0 \
			else "SABOTAGEM %ds" % int(ceil(sabotage_cd))
		if sabotage_fill:
			var frac := clampf(1.0 - sabotage_cd / SABOTAGE_CD, 0.0, 1.0)
			sabotage_fill.size = Vector2(sabotage_btn.size.x * frac, sabotage_btn.size.y)
	# Mapa aberto: acompanha a posicao do jogador.
	if map_overlay:
		_update_map_player_dot()
	_update_proximity()
	# Publica a minha posicao para os outros jogadores (15 Hz, dentro do NetHub).
	if in_match and world.visible and player.visible:
		NetHub.set_my_pos(player.global_position)


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
	# Mapa aberto: ESC fecha e nenhum toque mexe o jogador (o overlay trata).
	if map_overlay:
		if event is InputEventKey and event.pressed and not event.echo \
				and event.keycode == KEY_ESCAPE:
			_close_map()
			get_viewport().set_input_as_handled()
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
	joy_base.modulate.a = 1.0
	joy_base.visible = true
	_place_knob(Vector2.ZERO)


func _joy_end() -> void:
	joy_touch = -1
	player.joy_dir = Vector2.ZERO
	# Nao esconde na hora: o _process apaga suavemente ("transparente
	# quando nao usado").


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
	var st: Station = world.stations.get(task_id)
	if st:
		st.mark_done()
	_update_task_bar()
	toast("Tarefa concluída! (%d/%d)" % [GameState.tasks_done(), GameState.tasks.size()], 4.0)


