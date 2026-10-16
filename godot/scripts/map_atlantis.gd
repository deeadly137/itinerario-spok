class_name MapAtlantis
extends RefCounted
## Mapa ATLANTIS SUB-BASE (MAPtest.jpeg, 1248x863) — fundo + colisão.
## Traçado manual sobre grade de 64px. Escala 2x -> mundo 2496x1726.
## Salas: SINAIS, NIVEIS DE CARBONO, BIORREATORES, spawn, HALL PRINCIPAL,
##   ENERGIA, ANALISES (corredor L), PLANTAS, TANQUES BIOMEDICOS, CENTRIFUGAS.
## Tasks (marcadores dourados do desenho):
##   micro->ANALISES(505,445)  tank->TANQUES(735,535)  atmo->CARBONO(460,335)
##   probe->HALL(675,275)  + extras: biorreatores(525,135), plantas(885,465)

const SCALE := 2.0
const IMG_W := 1248.0
const IMG_H := 863.0
const WORLD_W := 2496.0
const WORLD_H := 1726.0

# pisos (retângulos andáveis, coords do PNG)
const FLOORS_PX := [
	[128.0, 100.0, 270.0, 140.0],    # SINAIS
	[400.0, 130.0, 70.0, 60.0],      # corredor SINAIS->BIORREATORES
	[55.0, 255.0, 300.0, 165.0],     # NIVEIS DE CARBONO
	[470.0, 60.0, 250.0, 170.0],     # BIORREATORES
	[725.0, 160.0, 70.0, 90.0],      # spawn
	[470.0, 235.0, 250.0, 185.0],    # HALL PRINCIPAL
	[725.0, 265.0, 70.0, 60.0],      # corredor HALL->ENERGIA
	[880.0, 130.0, 190.0, 260.0],    # ENERGIA
	[55.0, 425.0, 130.0, 130.0],     # corredor L vertical
	[55.0, 480.0, 400.0, 75.0],      # ANALISES (corredor horizontal)
	[455.0, 425.0, 370.0, 165.0],    # sala gradeada central
	[830.0, 455.0, 40.0, 60.0],      # corredor -> PLANTAS
	[875.0, 395.0, 300.0, 160.0],    # PLANTAS
	[640.0, 590.0, 330.0, 230.0],    # TANQUES BIOMEDICOS
	[975.0, 590.0, 55.0, 40.0],      # corredor -> CENTRIFUGAS
	[1030.0, 505.0, 145.0, 250.0],   # CENTRIFUGAS
]

# paredes externas de cada bloco (coords do PNG, espessura ~10px)
const WALLS_PX := [
	# SINAIS
	[124.0, 96.0, 278.0, 10.0], [124.0, 96.0, 10.0, 148.0],
	[396.0, 96.0, 10.0, 148.0], [124.0, 238.0, 120.0, 10.0],
	[300.0, 238.0, 102.0, 10.0],
	# NIVEIS DE CARBONO
	[51.0, 251.0, 308.0, 10.0], [51.0, 251.0, 10.0, 173.0],
	[353.0, 251.0, 10.0, 173.0], [51.0, 418.0, 40.0, 10.0],
	[215.0, 418.0, 144.0, 10.0],
	# corredor SINAIS->BIORREATORES
	[400.0, 126.0, 70.0, 8.0], [400.0, 186.0, 70.0, 8.0],
	# BIORREATORES
	[466.0, 56.0, 258.0, 10.0], [466.0, 56.0, 10.0, 178.0],
	[718.0, 56.0, 10.0, 100.0], [718.0, 190.0, 10.0, 44.0],
	[466.0, 228.0, 130.0, 10.0], [640.0, 228.0, 84.0, 10.0],
	# spawn
	[721.0, 156.0, 78.0, 8.0], [721.0, 156.0, 8.0, 98.0],
	[793.0, 156.0, 8.0, 98.0], [721.0, 248.0, 78.0, 8.0],
	# HALL PRINCIPAL
	[466.0, 238.0, 10.0, 186.0], [718.0, 238.0, 10.0, 30.0],
	[718.0, 322.0, 10.0, 102.0], [466.0, 418.0, 262.0, 10.0],
	# corredor HALL->ENERGIA
	[725.0, 261.0, 70.0, 8.0], [725.0, 321.0, 70.0, 8.0],
	# ENERGIA
	[876.0, 126.0, 198.0, 10.0], [876.0, 126.0, 10.0, 268.0],
	[1068.0, 126.0, 10.0, 268.0], [876.0, 388.0, 198.0, 10.0],
	# corredor L vertical
	[51.0, 424.0, 10.0, 136.0], [121.0, 424.0, 10.0, 136.0],
	[51.0, 554.0, 80.0, 10.0],
	# ANALISES (corredor horizontal)
	[55.0, 476.0, 400.0, 8.0], [55.0, 551.0, 400.0, 8.0],
	# sala gradeada central
	[451.0, 421.0, 10.0, 173.0], [819.0, 421.0, 10.0, 173.0],
	[451.0, 588.0, 190.0, 10.0], [735.0, 588.0, 94.0, 10.0],
	# corredor -> PLANTAS
	[826.0, 451.0, 48.0, 8.0], [826.0, 511.0, 48.0, 8.0],
	# PLANTAS
	[871.0, 391.0, 308.0, 10.0], [871.0, 391.0, 10.0, 168.0],
	[1173.0, 391.0, 10.0, 168.0], [871.0, 553.0, 308.0, 10.0],
	# TANQUES BIOMEDICOS
	[636.0, 586.0, 10.0, 238.0], [968.0, 586.0, 10.0, 238.0],
	[636.0, 590.0, 100.0, 10.0], [790.0, 590.0, 178.0, 10.0],
	[636.0, 818.0, 338.0, 10.0],
	# corredor -> CENTRIFUGAS
	[975.0, 586.0, 55.0, 8.0], [975.0, 626.0, 55.0, 8.0],
	# CENTRIFUGAS (octógono aproximado por retângulo)
	[1026.0, 501.0, 153.0, 10.0], [1026.0, 501.0, 10.0, 258.0],
	[1173.0, 501.0, 10.0, 258.0], [1026.0, 753.0, 153.0, 10.0],
]

const SPAWN_PX := Vector2(760.0, 205.0)

# estações nos marcadores dourados do desenho (pos em PNG)
const STATIONS_PX := {
	"micro": {"px": Vector2(505.0, 445.0), "name": "ANALISES · MICROSCOPIO", "radius": 60.0},
	"tank": {"px": Vector2(735.0, 535.0), "name": "TANQUES BIOMEDICOS", "radius": 60.0},
	"atmo": {"px": Vector2(460.0, 335.0), "name": "NIVEIS DE CARBONO", "radius": 60.0},
	"probe": {"px": Vector2(675.0, 275.0), "name": "HALL · SONDA", "radius": 65.0},
}


static func px_to_world(p: Vector2) -> Vector2:
	return p * SCALE


static func rect_px_to_world(r: Array) -> Array:
	return [r[0] * SCALE, r[1] * SCALE, r[2] * SCALE, r[3] * SCALE]
