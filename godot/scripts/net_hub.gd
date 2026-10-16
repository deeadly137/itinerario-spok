# MULTIPLAYER (LAN, ENet) - fase 2.
# Fluxo: menu servidores (codigo 3 digitos) -> lobby (MapLobby.jpeg)
#   -> host aperta START -> sorteio de classes -> jogo (MapNEW.jpeg).

extends Node

signal players_changed
signal role_assigned(role, animal)
signal sabotage_event(kind, active)
signal game_started
signal server_found(code, ip)

const PORT_BASE := 7777
const DISCOVER_PORT := 7776
const MAX_PLAYERS := 9

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
var my_role := ""
var my_animal := ""
var my_index := 0
var players := {}
var found_servers := {}
var _discover = null
var _broadcast_time := 0.0

func port_for(code):
	return PORT_BASE + int(code)

func make_code():
	return "%03d" % randi_range(0, 999)

func animal_sprite(id):
	return "res://assets/img/animals/" + id + ".png"

func scientist_sprite(id):
	return "res://assets/img/scientists/" + id + ".png"

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(pid):
	if is_host:
		players[pid] = {"role": "", "animal": "", "index": 0, "name": "P%d" % pid}
		players_changed.emit()

func _on_peer_disconnected(pid):
	players.erase(pid)
	players_changed.emit()

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
	if _discover == null:
		return
	if is_host and online:
		_broadcast_time += _delta
		if _broadcast_time >= 1.0:
			_broadcast_time = 0.0
			_discover.set_dest_address("255.255.255.255", DISCOVER_PORT)
			_discover.put_packet(("ABISMO:" + server_code).to_utf8_buffer())
	elif not is_host:
		while _discover.get_available_packet_count() > 0:
			var pkt = _discover.get_packet().get_string_from_utf8()
			var ip = _discover.get_packet_ip()
			if pkt.begins_with("ABISMO:"):
				var code = pkt.trim_prefix("ABISMO:")
				if not found_servers.has(code):
					found_servers[code] = ip
					server_found.emit(code, ip)

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
	players[1] = {"role": "", "animal": "", "index": 0, "name": "Host"}
	start_discovery()
	players_changed.emit()
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
	players.clear()
	my_role = ""
	my_animal = ""
	my_index = 0

func local_id():
	return multiplayer.get_unique_id()

func start_match():
	if not is_host:
		return
	var ids = players.keys()
	ids.shuffle()
	for i in ids.size():
		var pid = ids[i]
		var role = "animal"
		var animal = ANIMALS[i % ANIMALS.size()]["id"]
		var idx = i % ANIMALS.size()
		if ids.size() >= 4 and i < 3:
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
