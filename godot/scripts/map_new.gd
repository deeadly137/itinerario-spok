class_name MapNew
extends RefCounted
## Mapa novo (MapNEW.jpeg, 896x1200) - ATLANTIS SUB-BASE refeito.
## Escala 2x -> mundo 1792x2400. Trazado sobre grade 64px + perfis.
## Salas: SINAIS, NIVEIS DE CARBONO, BIORREATORES, HALL/OBSERVATORIO,
##   ENERGIA, ANALISES (lab oeste), TANQUES, ANEXO (sala clara sul),
##   PLANTAS (estufa leste), TANQUES BIOMEDICOS, CENTRIFUGAS.
## Tasks: micro->ANALISES, tank->TANQUES BIOMEDICOS, atmo->NIVEIS DE
##   CARBONO, probe->HALL/OBSERVATORIO.

const SCALE := 3.0
const IMG_W := 896.0
const IMG_H := 1200.0
const WORLD_W := 2688.0
const WORLD_H := 3600.0

const WALLS_PX := [
	# SINAIS (30,60 -> 285,300)
	[30.0, 60.0, 255.0, 10.0], [30.0, 60.0, 10.0, 240.0],
	[275.0, 60.0, 10.0, 240.0], [30.0, 294.0, 110.0, 10.0],
	[210.0, 294.0, 75.0, 10.0],
	# corredor SINAIS->BIORREATORES
	[285.0, 140.0, 55.0, 8.0], [285.0, 188.0, 55.0, 8.0],
	# NIVEIS DE CARBONO (30,330 -> 285,690)
	[30.0, 330.0, 255.0, 10.0], [30.0, 330.0, 10.0, 360.0],
	[275.0, 330.0, 10.0, 360.0], [30.0, 684.0, 95.0, 10.0],
	[190.0, 684.0, 95.0, 10.0],
	# corredor CARBONO->sul (escada)
	[125.0, 694.0, 65.0, 8.0], [125.0, 744.0, 65.0, 8.0],
	# BIORREATORES (345,55 -> 560,300)
	[345.0, 55.0, 215.0, 10.0], [345.0, 55.0, 10.0, 245.0],
	[550.0, 55.0, 10.0, 245.0], [345.0, 294.0, 150.0, 10.0],
	# spawn (nicho, aberto - sem paredes próprias)
	# HALL/OBSERVATORIO (345,310 -> 620,690)
	[345.0, 310.0, 10.0, 200.0], [345.0, 560.0, 10.0, 130.0],
	[610.0, 310.0, 10.0, 380.0], [345.0, 684.0, 275.0, 10.0],
	[345.0, 310.0, 100.0, 10.0], [500.0, 310.0, 120.0, 10.0],
	# corredor HALL->ENERGIA
	[620.0, 380.0, 50.0, 8.0], [620.0, 430.0, 50.0, 8.0],
	# ENERGIA (670,225 -> 835,470)
	[670.0, 225.0, 165.0, 10.0], [670.0, 225.0, 10.0, 245.0],
	[825.0, 225.0, 10.0, 245.0], [670.0, 464.0, 165.0, 10.0],
	# lab oeste ANALISES (30,335 -> 285,690): paredes internas = moveis
	# corredor lab->HALL
	[285.0, 495.0, 60.0, 8.0], [285.0, 545.0, 60.0, 8.0],
	# TANQUES norte do lab (30,715 -> 285,900)
	[30.0, 715.0, 255.0, 10.0], [30.0, 715.0, 10.0, 185.0],
	[275.0, 715.0, 10.0, 185.0], [30.0, 894.0, 255.0, 10.0],
	# corredor TANQUES->ANEXO (passarela)
	[125.0, 904.0, 250.0, 8.0], [125.0, 954.0, 250.0, 8.0],
	# ANEXO sala clara sul (375,750 -> 620,985)
	[375.0, 750.0, 10.0, 235.0], [610.0, 750.0, 10.0, 235.0],
	[375.0, 750.0, 130.0, 10.0], [560.0, 750.0, 60.0, 10.0],
	[375.0, 979.0, 245.0, 10.0],
	# corredor ANEXO->PLANTAS
	[620.0, 830.0, 55.0, 8.0], [620.0, 880.0, 55.0, 8.0],
	# PLANTAS estufa leste (675,505 -> 865,985)
	[675.0, 505.0, 190.0, 10.0], [675.0, 505.0, 10.0, 480.0],
	[855.0, 505.0, 10.0, 480.0], [675.0, 979.0, 190.0, 10.0],
	# TANQUES BIOMEDICOS (455,990 -> 700,1140)
	[455.0, 990.0, 245.0, 10.0], [455.0, 990.0, 10.0, 150.0],
	[690.0, 990.0, 10.0, 150.0], [455.0, 1134.0, 245.0, 10.0],
	# corredor TANQUES->CENTRIFUGAS
	[700.0, 1040.0, 45.0, 8.0], [700.0, 1090.0, 45.0, 8.0],
	# CENTRIFUGAS (745,985 -> 865,1100)
	[745.0, 985.0, 120.0, 10.0], [745.0, 985.0, 10.0, 115.0],
	[855.0, 985.0, 10.0, 115.0], [745.0, 1094.0, 120.0, 10.0],
]

const SPAWN_PX := Vector2(482.0, 500.0)

const STATIONS_PX := {
	"micro": {"px": Vector2(160.0, 510.0), "name": "ANALISES - MICROSCOPIO", "radius": 45.0},
	"tank": {"px": Vector2(578.0, 1065.0), "name": "TANQUES BIOMEDICOS", "radius": 45.0},
	"atmo": {"px": Vector2(160.0, 510.0), "name": "NIVEIS DE CARBONO", "radius": 45.0},
	"probe": {"px": Vector2(482.0, 500.0), "name": "OBSERVATORIO - SONDA", "radius": 48.0},
}

static func px_to_world(p):
	return p * SCALE

static func rect_px_to_world(r):
	return [r[0] * SCALE, r[1] * SCALE, r[2] * SCALE, r[3] * SCALE]
