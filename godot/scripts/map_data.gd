class_name MapData
extends RefCounted
## Geometria da estação — porte 1:1 do game.js (WORLD 2200x1300).
## Fonte única: pisos, paredes, porta, obstáculos, estações, rota.

const WORLD_W := 2200.0
const WORLD_H := 1300.0

const ROOMS := [
	{"id": "micro", "x": 30.0, "y": 30.0, "w": 970.0, "h": 530.0,
		"tone": "a", "label": "ANALISES · MICROSCOPIA", "lx": 515.0, "ly": 85.0},
	{"id": "tank", "x": 1030.0, "y": 30.0, "w": 1140.0, "h": 530.0,
		"tone": "b", "label": "BIORREATORES · TANQUES", "lx": 1600.0, "ly": 85.0},
	{"id": "spine", "x": 30.0, "y": 590.0, "w": 2140.0, "h": 150.0,
		"tone": "c", "label": "HALL PRINCIPAL", "lx": 700.0, "ly": 665.0, "hall": true},
	{"id": "atmo", "x": 30.0, "y": 770.0, "w": 970.0, "h": 500.0,
		"tone": "d", "label": "ENERGIA · NIVEIS DE CARBONO", "lx": 515.0, "ly": 830.0},
	{"id": "probe", "x": 1030.0, "y": 770.0, "w": 1140.0, "h": 500.0,
		"tone": "e", "label": "PISCINA LUNAR · SONDA EXTERNA", "lx": 1600.0, "ly": 830.0},
]

const WALLS := [
	[0.0, 0.0, 2200.0, 30.0], [0.0, 1270.0, 2200.0, 30.0],
	[0.0, 0.0, 30.0, 1300.0], [2170.0, 0.0, 30.0, 1300.0],
	[1000.0, 30.0, 30.0, 530.0], [1000.0, 740.0, 30.0, 530.0],
	[30.0, 560.0, 430.0, 30.0], [600.0, 560.0, 430.0, 30.0],
	[1030.0, 560.0, 570.0, 30.0], [1740.0, 560.0, 430.0, 30.0],
	[30.0, 740.0, 430.0, 30.0], [600.0, 740.0, 430.0, 30.0],
	[1030.0, 740.0, 570.0, 30.0], [1740.0, 740.0, 430.0, 30.0],
]

const DOOR_WALL := [1600.0, 740.0, 140.0, 30.0]

const PROPS := [
	[80.0, 60.0, 320.0, 56.0, "bench", "BANCADA 01"],
	[640.0, 60.0, 300.0, 56.0, "bench", "BANCADA 02"],
	[1100.0, 60.0, 260.0, 56.0, "rack", "FILEIRA A"],
	[1810.0, 60.0, 300.0, 56.0, "rack", "FILEIRA B"],
	[80.0, 1160.0, 240.0, 70.0, "server", "SERVIDOR"],
	[720.0, 1160.0, 220.0, 70.0, "server", "ESTACAO DE DADOS"],
	[1100.0, 1170.0, 200.0, 64.0, "crate", "EQUIPAMENTO"],
	[1900.0, 1170.0, 210.0, 64.0, "crate", "SUPRIMENTOS"],
	[240.0, 590.0, 70.0, 70.0, "crate", ""],
	[1960.0, 590.0, 70.0, 70.0, "crate", ""],
]

const THRESHOLDS := [
	[460.0, 560.0, 140.0, 30.0], [1600.0, 560.0, 140.0, 30.0],
	[460.0, 740.0, 140.0, 30.0], [1600.0, 740.0, 140.0, 30.0],
]

const SPAWN := Vector2(1100.0, 665.0)
const SPAWN_PAD := [1070.0, 635.0, 60.0, 60.0]

const STATIONS := {
	"micro": {"pos": Vector2(515.0, 300.0), "name": "MICROSCOPIO DE ANALISES", "radius": 150.0},
	"tank": {"pos": Vector2(1600.0, 300.0), "name": "BIORREATORES", "radius": 150.0},
	"atmo": {"pos": Vector2(515.0, 1020.0), "name": "NIVEIS DE CARBONO", "radius": 150.0},
	"probe": {"pos": Vector2(1600.0, 1020.0), "name": "PISCINA LUNAR · SONDA", "radius": 160.0},
}

const PLAYER_R := 22.0
const PLAYER_SPEED := 260.0


static func door_cx(x: float) -> float:
	return 530.0 if x < 1000.0 else 1670.0


static func region_of(p: Vector2) -> String:
	if p.y >= 590.0 and p.y <= 740.0:
		return "C"
	if p.y < 590.0:
		return "micro" if p.x < 1000.0 else "tank"
	return "atmo" if p.x < 1000.0 else "probe"


## Rota por waypoints atravessando as portas (porte do pathTo do JS).
static func path_to(from: Vector2, target: Vector2) -> Array:
	var rf := region_of(from)
	var rt := region_of(target)
	if rf == rt:
		return [target]
	var wps: Array = []
	if rf != "C":
		wps.append(Vector2(door_cx(from.x), from.y))
		wps.append(Vector2(door_cx(from.x), 665.0))
	if rt != "C":
		wps.append(Vector2(door_cx(target.x), 665.0))
		var exit_y := 545.0 if (rt == "micro" or rt == "tank") else 785.0
		wps.append(Vector2(door_cx(target.x), exit_y))
	wps.append(target)
	return wps
