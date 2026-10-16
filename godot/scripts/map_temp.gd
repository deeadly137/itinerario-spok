class_name MapTemp
extends RefCounted
## Mapa temporário (projeto longo): fundo PNG (map_temp.png, 850x1100)
## + colisão traçada manualmente a partir do esquema.
## Escala 2x -> mundo 1700x2200 (corredores >=150px p/ dedo).
## Origem do esquema: conteúdo em x50-810 / y10-700 do PNG.
## Salas identificadas no esquema (nomes do desenho):
##   SINAIS, Biorreatores, spawn, HALL PRINCIPAL, energia, niveis de carbono,
##   PLANTAS, ANALISES, Tanques/aquarios, centrifugas.
## Mapeamento das tasks: micro->ANALISES, tank->Tanques, atmo->niveis de
## carbono, probe->Tanques (piscina lunar futura).

const SCALE := 2.0
const IMG_W := 850.0
const IMG_H := 1100.0
const WORLD_W := 1700.0
const WORLD_H := 2200.0

# salas (retângulos de piso) em coords do PNG -> convertidas em runtime
const ROOMS_PX := [
	{"id": "sinais", "x": 50.0, "y": 10.0, "w": 190.0, "h": 150.0, "label": "SINAIS"},
	{"id": "biorre", "x": 350.0, "y": 10.0, "w": 170.0, "h": 100.0, "label": "BIORREATORES"},
	{"id": "hall", "x": 350.0, "y": 150.0, "w": 190.0, "h": 140.0, "label": "HALL PRINCIPAL"},
	{"id": "spawn", "x": 545.0, "y": 140.0, "w": 60.0, "h": 55.0, "label": "SPAWN"},
	{"id": "energia", "x": 640.0, "y": 110.0, "w": 120.0, "h": 210.0, "label": "ENERGIA"},
	{"id": "carbono", "x": 75.0, "y": 220.0, "w": 130.0, "h": 150.0, "label": "NIVEIS DE CARBONO"},
	{"id": "meio", "x": 290.0, "y": 330.0, "w": 270.0, "h": 130.0, "label": ""},
	{"id": "plantas", "x": 590.0, "y": 350.0, "w": 190.0, "h": 110.0, "label": "PLANTAS"},
	{"id": "analises", "x": 440.0, "y": 490.0, "w": 90.0, "h": 45.0, "label": "ANALISES"},
	{"id": "tanques", "x": 435.0, "y": 535.0, "w": 150.0, "h": 110.0, "label": "TANQUES BIOMEDICOS"},
	{"id": "centrif", "x": 660.0, "y": 500.0, "w": 110.0, "h": 150.0, "label": "CENTRIFUGAS"},
]

# paredes em coords do PNG (segmentos grossos viram retângulos)
const WALLS_PX := [
	[50.0, 10.0, 190.0, 4.0], [50.0, 10.0, 4.0, 150.0],
	[236.0, 10.0, 4.0, 150.0], [50.0, 156.0, 190.0, 4.0],
	[350.0, 10.0, 170.0, 4.0], [350.0, 10.0, 4.0, 100.0],
	[516.0, 10.0, 4.0, 100.0], [350.0, 106.0, 170.0, 4.0],
	[350.0, 150.0, 190.0, 4.0], [350.0, 150.0, 4.0, 140.0],
	[536.0, 150.0, 4.0, 140.0], [350.0, 286.0, 190.0, 4.0],
	[640.0, 110.0, 120.0, 4.0], [640.0, 110.0, 4.0, 210.0],
	[756.0, 110.0, 4.0, 210.0], [640.0, 316.0, 120.0, 4.0],
	[75.0, 220.0, 130.0, 4.0], [75.0, 220.0, 4.0, 150.0],
	[201.0, 220.0, 4.0, 150.0], [75.0, 366.0, 130.0, 4.0],
	[290.0, 330.0, 270.0, 4.0], [290.0, 330.0, 4.0, 130.0],
	[556.0, 330.0, 4.0, 130.0], [290.0, 456.0, 270.0, 4.0],
	[590.0, 350.0, 190.0, 4.0], [590.0, 350.0, 4.0, 110.0],
	[776.0, 350.0, 4.0, 110.0], [590.0, 456.0, 190.0, 4.0],
	[435.0, 535.0, 150.0, 4.0], [435.0, 535.0, 4.0, 110.0],
	[581.0, 535.0, 4.0, 110.0], [435.0, 641.0, 150.0, 4.0],
	[660.0, 500.0, 110.0, 4.0], [660.0, 500.0, 4.0, 150.0],
	[766.0, 500.0, 4.0, 150.0], [660.0, 646.0, 110.0, 4.0],
]

const SPAWN_PX := Vector2(575.0, 167.0)

# estações neste mapa (pos em PNG)
const STATIONS_PX := {
	"micro": {"px": Vector2(485.0, 512.0), "name": "ANALISES · MICROSCOPIO", "radius": 75.0},
	"tank": {"px": Vector2(510.0, 590.0), "name": "TANQUES BIOMEDICOS", "radius": 75.0},
	"atmo": {"px": Vector2(140.0, 295.0), "name": "NIVEIS DE CARBONO", "radius": 75.0},
	"probe": {"px": Vector2(715.0, 575.0), "name": "CENTRIFUGAS · SONDA", "radius": 80.0},
}


static func px_to_world(p: Vector2) -> Vector2:
	return p * SCALE


static func rect_px_to_world(r: Array) -> Array:
	return [r[0] * SCALE, r[1] * SCALE, r[2] * SCALE, r[3] * SCALE]
