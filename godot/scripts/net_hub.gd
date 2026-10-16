# MULTIPLAYER (LAN, ENet) - fase 2.
# Fluxo: menu servidores (codigo 3 digitos) -> lobby (MapLobby.jpeg)
#   -> host aperta START -> sorteio de classes -> jogo (MapNEW.jpeg).

extends Node

signal players_changed
signal role_assigned(role, animal)
signal sabotage_event(kind, active)
signal game_started
signal server_found(code, ip)
signal roster_changed          # a lista de jogadores (com papeis/cores) mudou
signal peer_moved(pid, pos)    # posicao de OUTRO jogador (lobby ou mapa)
signal peer_left(pid)          # alguem saiu
signal host_left               # o host caiu (eu era cliente)
signal map_changed(m)          # o host trocou o mapa (vale para todos)
signal sabotage_requested(kind) # sabotagem pedida e validada pelo host

const PORT_BASE := 7777
const DISCOVER_PORT := 7776
const MAX_PLAYERS := 9
## 15 pacotes por segundo e o suficiente: o outro lado interpola.
const NET_TICK := 1.0 / 15.0
## Cores do lobby (antes de sair o sorteio de cargo).
const FAKE_COLORS := ["5bc8e8", "ff7b9c", "7be495", "d9c8ff", "ffe066",
	"ff9a5c", "e8e8e8", "9ad0ff", "ffc9c9"]

const ANIMALS := [
	{"id": "pteropode", "name": "Pteropode", "color": "5bc8e8"},
	{"id": "polipo", "name": "Polipo de coral", "color": "ff7b9c"},
	{"id": "alga", "name": "Alga", "color": "7be495"},
	{"id": "ostra", "name": "Ostra", "color": "d9c8ff"},
	{"id": "plancton", "name": "Plancton", "color": "ffe066"},
	{"id": "caranguejo", "name": "Caranguejo", "color": "ff9a5c"},
]
const SCIENTISTS := [
	{"id": "cientista1", "name": "Cientista I", "color": "e8e8e8"},
	{"id": "cientista2", "name": "Cientista II", "color": "c9c9c9"},
	{"id": "cientista3", "name": "Cientista III", "color": "a8a8a8"},
]

var peer = null
var is_host := false
var online := false
var server_code := ""
var server_map := "new"        # mapa escolhido pelo host (sincronizado)
var my_role := ""
var my_animal := ""
var my_index := 0
var players := {}
var found_servers := {}
var _discover = null
var _broadcast_time := 0.0
var _ask_time := 0.0
# canal de posicao (lobby e mapa usam o mesmo)
var _pos := Vector2.ZERO
var _pos_on := false
var _pos_acc := 0.0
var _slot_next := 1
var my_net_id := 0

func port_for(code):
	return PORT_BASE + int(code)

func make_code():
	return "%03d" % randi_range(0, 999)

func animal_sprite(id):
	return "res://assets/img/animals/" + id + ".png"

func scientist_sprite(id):
	return "res://assets/img/scientists/" + id + ".png"


## Sprite do personagem para um papel, com cadeia de fallback:
## sprite do papel -> player.png -> "" (aí o jogo usa a caixa colorida).
func crew_sprite(role: String, id: String) -> String:
	var p := ""
	if role == "animal":
		p = animal_sprite(id)
	elif role == "scientist":
		p = scientist_sprite(id)
	if p != "" and ResourceLoader.exists(p):
		return p
	if ResourceLoader.exists("res://assets/img/player.png"):
		return "res://assets/img/player.png"
	return ""


## Sprite do lobby (ainda sem sorteio): qualquer animal/cientista, escolhido
## de forma estavel pelo indice do jogador.
func lobby_sprite(i: int) -> String:
	var all: Array = []
	for a in ANIMALS:
		all.append(animal_sprite(a["id"]))
	for s in SCIENTISTS:
		all.append(scientist_sprite(s["id"]))
	if all.is_empty():
		return ""
	var p: String = str(all[abs(i) % all.size()])
	if ResourceLoader.exists(p):
		return p
	return ""


## Cria um Sprite2D JA RECORTADO da margem transparente e escalado para
## caber em `box` px no maior lado. Assim qualquer PNG serve, com ou sem
## espaco em branco em volta.
func make_crew_sprite(path: String, box: float) -> Sprite2D:
	var tex: Texture2D = load(path)
	var region := Rect2(Vector2.ZERO, tex.get_size())
	var img := tex.get_image()
	if img != null:
		var ur := img.get_used_rect()
		if ur.size.x > 0.0 and ur.size.y > 0.0:
			region = Rect2(ur)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = region
	var spr := Sprite2D.new()
	spr.texture = at
	var s := box / maxf(region.size.x, region.size.y)
	spr.scale = Vector2(s, s)
	return spr

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


## Id deste cliente so e valido DEPOIS de conectar (antes disso o Godot
## devolve 1, que e o id do host - e a gente se confundiria com ele).
func _on_connected_to_server() -> void:
	my_net_id = multiplayer.get_unique_id()
	players_changed.emit()
	roster_changed.emit()


## Cor do papel (usada no halo do personagem). "" -> cor neutra.
func role_color(role: String, id: String) -> String:
	if role == "animal":
		for a in ANIMALS:
			if a["id"] == id:
				return str(a["color"])
	elif role == "scientist":
		for s in SCIENTISTS:
			if s["id"] == id:
				return str(s["color"])
	return "2b6cb0"


## Poe o visual de um tripulante (halo + sprite/caixa + apelido opcional)
## dentro de qualquer Node2D. Usado pelo lobby e pelos jogadores remotos.
func decorate_crew(node: Node2D, role: String, animal: String, fallback_hex: String,
		box := 50.0, tag := "", sprite_path := "") -> void:
	var hex := fallback_hex
	if role != "":
		hex = role_color(role, animal)
	var halo := ColorRect.new()
	var hc := Color(hex)
	hc.a = 0.5
	halo.color = hc
	halo.size = Vector2(box + 8.0, box + 8.0)
	halo.position = -halo.size * 0.5
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(halo)
	var sp := sprite_path
	if sp == "":
		sp = crew_sprite(role, animal)
	if sp != "":
		node.add_child(make_crew_sprite(sp, box))
	else:
		var rect := ColorRect.new()
		rect.color = Color(hex)
		rect.size = Vector2(box - 6.0, box - 6.0)
		rect.position = -rect.size * 0.5
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(rect)
	if tag != "":
		var lab := Label.new()
		lab.text = tag
		lab.add_theme_font_size_override("font_size", 20)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.custom_minimum_size = Vector2(170, 0)
		lab.position = Vector2(-85, -box * 0.5 - 30.0)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(lab)


func _on_peer_connected(pid):
	if not is_host:
		return
	var slot := _slot_next
	_slot_next = (_slot_next + 1) % MAX_PLAYERS
	players[pid] = {"role": "", "animal": "", "index": slot,
		"name": "P%d" % pid, "color": FAKE_COLORS[slot % FAKE_COLORS.size()],
		"code": "%03d" % randi_range(0, 999), "ready": false}
	players_changed.emit()
	roster_changed.emit()
	push_roster()
	# manda o mapa atual para quem acabou de entrar
	rpc_map.rpc_id(pid, server_map)


func _on_peer_disconnected(pid):
	peer_left.emit(pid)
	if not is_host:
		return
	players.erase(pid)
	players_changed.emit()
	roster_changed.emit()
	push_roster()


func _on_server_disconnected():
	online = false
	_pos_on = false
	# o "peer 1" era o host: some com o boneco dele tambem
	peer_left.emit(1)
	host_left.emit()


## Host -> todos: quem esta na sala (id, papel, cor, codigo do lobby).
func push_roster() -> void:
	if not (is_host and online):
		return
	rpc_roster.rpc(players.duplicate(true))


@rpc("authority", "call_local", "reliable")
func rpc_roster(d):
	players = d
	var me = players.get(local_id(), {})
	if me is Dictionary and me.size() > 0:
		my_role = str(me.get("role", my_role))
		my_animal = str(me.get("animal", my_animal))
		my_index = int(me.get("index", my_index))
	players_changed.emit()
	roster_changed.emit()


## Chamar TODO FRAME com a minha posicao (lobby ou mapa). O envio e
## limitado a 15 Hz aqui dentro, e o host repassa para os outros.
func set_my_pos(p: Vector2) -> void:
	if not online:
		return
	_pos = p
	_pos_on = true


func clear_my_pos() -> void:
	_pos_on = false


func _send_pos() -> void:
	if is_host:
		rpc_pos.rpc(1, _pos)
	else:
		# rpc_id(id, ...) leva os ARGUMENTOS depois do id, entao o pid vai
		# junto (o host troca pelo remetente real ao receber).
		rpc_pos.rpc_id(1, my_net_id, _pos)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func rpc_pos(pid, pos):
	var sender := multiplayer.get_remote_sender_id()
	if not is_host:
		# veio do host (repasse): so aplica
		peer_moved.emit(int(pid), pos)
		return
	# chegou no host: assume o remetente real e repassa aos demais clientes
	pid = sender
	peer_moved.emit(int(pid), pos)
	for id in players:
		if id != pid and id != 1:
			rpc_pos.rpc_id(id, pid, pos)


## READY do lobby: vai no proprio elenco (players[pid]["ready"]), entao o
## host consegue saber quem levantou a mao e liberar o START.
func set_ready(v: bool) -> void:
	if not online:
		return
	if is_host:
		if players.has(1):
			players[1]["ready"] = v
		players_changed.emit()
		roster_changed.emit()
		push_roster()
	else:
		rpc_ready.rpc_id(1, v)


@rpc("any_peer", "call_remote", "reliable")
func rpc_ready(v):
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	if players.has(sender):
		players[sender]["ready"] = bool(v)
	players_changed.emit()
	roster_changed.emit()
	push_roster()


func all_ready() -> bool:
	for pid in players:
		if not bool((players[pid] as Dictionary).get("ready", false)):
			return false
	return true

func start_discovery():
	stop_discovery()
	_discover = PacketPeerUDP.new()
	_discover.bind(DISCOVER_PORT)
	_discover.set_broadcast_enabled(true)

func stop_discovery():
	if _discover:
		_discover.close()
		_discover = null
	found_servers.clear()

func _process(_delta):
	if _discover:
		if is_host and online:
			_broadcast_time += _delta
			# Responde a quem perguntou ("ABISMO?") por UNICAST: muitos
			# roteadores e Androids filtram broadcast, mas unicast passa.
			while _discover.get_available_packet_count() > 0:
				var ask: String = _discover.get_packet().get_string_from_utf8()
				var from_ip: String = _discover.get_packet_ip()
				if ask.begins_with("ABISMO?") and from_ip != "":
					_discover.set_dest_address(from_ip, DISCOVER_PORT)
					_discover.put_packet(("ABISMO:" + server_code).to_utf8_buffer())
			if _broadcast_time >= 1.0:
				_broadcast_time = 0.0
				_discover.set_dest_address("255.255.255.255", DISCOVER_PORT)
				_discover.put_packet(("ABISMO:" + server_code).to_utf8_buffer())
		elif not is_host:
			# pergunta ativamente (nao so escuta o broadcast do host)
			_ask_time += _delta
			if _ask_time >= 1.0:
				_ask_time = 0.0
				_discover.set_dest_address("255.255.255.255", DISCOVER_PORT)
				_discover.put_packet("ABISMO?".to_utf8_buffer())
			while _discover.get_available_packet_count() > 0:
				var pkt = _discover.get_packet().get_string_from_utf8()
				var ip = _discover.get_packet_ip()
				if pkt.begins_with("ABISMO:"):
					var code = pkt.trim_prefix("ABISMO:")
					if not found_servers.has(code):
						found_servers[code] = ip
						server_found.emit(code, ip)
	# posicao: manda 15x por segundo enquanto alguem estiver publicando
	if online and _pos_on:
		_pos_acc += _delta
		if _pos_acc >= NET_TICK:
			_pos_acc = 0.0
			_send_pos()

func host_game(code):
	_leave()
	server_code = code
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port_for(code), MAX_PLAYERS)
	if err != OK:
		peer = null
		return "Falha ao hospedar (porta ocupada?)"
	multiplayer.multiplayer_peer = peer
	is_host = true
	online = true
	my_net_id = 1
	_slot_next = 1
	players[1] = {"role": "", "animal": "", "index": 0, "name": "Host",
		"color": FAKE_COLORS[0], "code": "%03d" % randi_range(0, 999), "ready": false}
	start_discovery()
	players_changed.emit()
	roster_changed.emit()
	return ""

func join_game(ip, code):
	_leave()
	server_code = code
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip.strip_edges(), port_for(code))
	if err != OK:
		peer = null
		return "Falha ao conectar em %s" % ip
	multiplayer.multiplayer_peer = peer
	is_host = false
	online = true
	my_net_id = 0
	return ""

func _leave():
	stop_discovery()
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	online = false
	is_host = false
	server_code = ""
	server_map = "new"
	players.clear()
	my_role = ""
	my_animal = ""
	my_index = 0
	_pos_on = false
	_pos_acc = 0.0
	_slot_next = 1
	my_net_id = 0

func local_id() -> int:
	if not online:
		return 0
	return my_net_id


## IP deste aparelho no Wi-Fi. Serve para o outro jogador DIGITAR direto
## (alguns roteadores/Androids filtram o broadcast da descoberta).
func local_ip() -> String:
	var best := ""
	for a in IP.get_local_addresses():
		var s := str(a)
		if s.find(":") >= 0 or s.begins_with("127.") or s.begins_with("169.254."):
			continue
		if s.begins_with("192.168.") or s.begins_with("10."):
			return s
		if s.begins_with("172."):
			var p := s.split(".")
			var segundo := int(p[1]) if p.size() > 1 else 0
			if segundo >= 16 and segundo <= 31:
				return s
		if best == "":
			best = s
	return best

func start_match():
	if not is_host:
		return
	var ids = players.keys()
	ids.sort()
	var order = ids.duplicate()
	order.shuffle()
	for i in order.size():
		var pid = order[i]
		var role = "animal"
		var animal = ANIMALS[i % ANIMALS.size()]["id"]
		var idx = i % ANIMALS.size()
		if order.size() >= 4 and i < 3:
			role = "scientist"
			animal = SCIENTISTS[i % 3]["id"]
			idx = i % 3
		players[pid]["role"] = role
		players[pid]["animal"] = animal
		players[pid]["index"] = idx
		if pid == 1:
			my_role = role
			my_animal = animal
			my_index = idx
		else:
			rpc_assign.rpc_id(pid, role, animal, idx)
	role_assigned.emit(my_role, my_animal)
	# o elenco inteiro (com papeis) vai para todo mundo: e assim que cada um
	# sabe qual sprite desenhar para os outros.
	push_roster()
	rpc_start_game.rpc()
	players_changed.emit()

@rpc("authority", "call_remote", "reliable")
func rpc_assign(role, animal, index):
	my_role = role
	my_animal = animal
	my_index = index
	role_assigned.emit(role, animal)

@rpc("authority", "call_local", "reliable")
func rpc_start_game():
	game_started.emit()

@rpc("authority", "call_local", "reliable")
func rpc_sabotage(kind, active):
	sabotage_event.emit(kind, active)

func scientist_sabotage(kind, active):
	if not is_host:
		return
	rpc_sabotage.rpc(kind, active)


## Mapa: o host escolhe e todo mundo passa a usar o mesmo.
func set_server_map(m: String) -> void:
	if not is_host:
		return
	server_map = m
	rpc_map.rpc(m)


@rpc("authority", "call_local", "reliable")
func rpc_map(m):
	server_map = str(m)
	map_changed.emit(server_map)


## Sabotagem manual (botao do cientista): o cliente pede ao host, o host
## valida e repassa para todo mundo, para o blecaute valer em todos.
func request_sabotage(kind: String) -> void:
	if not online:
		sabotage_requested.emit(kind)
		return
	if is_host:
		rpc_do_sabotage.rpc(kind)
	else:
		rpc_request_sabotage.rpc_id(1, kind)


@rpc("any_peer", "call_remote", "reliable")
func rpc_request_sabotage(kind):
	if not is_host:
		return
	rpc_do_sabotage.rpc(str(kind))


@rpc("authority", "call_local", "reliable")
func rpc_do_sabotage(kind):
	sabotage_requested.emit(str(kind))
