class_name MapNew
extends RefCounted
## Mapa novo (MapNEW.jpeg, 896x1200) - ATLANTIS SUB-BASE.
## Escala 3x -> mundo 2688x3600.
##
## GEOMETRIA (fonte unica): NAO tracei parede por parede em cima da arte,
## porque o tracado a mao errava de 15 a 65 px (ex.: a parede do topo do
## domo ficava 65 px acima do domo real). Em vez disso:
##   ROOMS_PX = areas CAMINHAVEIS (salas + corredores) em px da imagem;
##   WALLS_PX = complemento de ROOMS_PX, gerado por grade de 4 px e
##              mesclado em 37 retangulos.
## Resultado: as salas ficam FECHADAS (o jogador nao sai para o oceano),
## todos os corredores conectam, e as 4 estacoes sao alcancaveis.
## Para regerar: veja /tmp/gen_geom.py (grade + flood-fill de validacao).
##
## Salas: LAB_NW (monitores), BIOREATORES, AIRLOCK, PLATAFORMA, DOMO
##   (observatorio), ENERGIA, LAB_W (analises), TANQUES, ANEXO, PLANTAS
##   (estufa), TANQUES BIOMEDICOS, CENTRIFUGAS.

const SCALE := 3.0
const IMG_W := 896.0
const IMG_H := 1200.0
const WORLD_W := 2688.0
const WORLD_H := 3600.0

## Areas caminhaveis (px da imagem): [x, y, w, h]. Referencia/validacao.
const ROOMS_PX := [
	[38.0, 62.0, 245.0, 233.0], [275.0, 130.0, 80.0, 62.0], [348.0, 48.0, 205.0, 246.0],
	[540.0, 252.0, 86.0, 98.0], [425.0, 280.0, 152.0, 110.0], [296.0, 372.0, 316.0, 322.0],
	[656.0, 206.0, 180.0, 256.0], [600.0, 432.0, 70.0, 36.0], [230.0, 286.0, 60.0, 56.0],
	[40.0, 334.0, 241.0, 360.0], [270.0, 476.0, 40.0, 72.0], [48.0, 712.0, 232.0, 188.0],
	[110.0, 886.0, 290.0, 74.0], [376.0, 748.0, 242.0, 236.0], [455.0, 688.0, 150.0, 68.0],
	[600.0, 826.0, 66.0, 60.0], [650.0, 506.0, 206.0, 494.0], [458.0, 984.0, 240.0, 154.0],
	[690.0, 1032.0, 62.0, 60.0], [748.0, 986.0, 112.0, 110.0],
]

## Colisao = complemento das ROOMS_PX (px da imagem).
const WALLS_PX := [
	[0.0, 0.0, 896.0, 48.0], [0.0, 48.0, 348.0, 12.0], [552.0, 48.0, 344.0, 156.0],
	[0.0, 60.0, 36.0, 1140.0], [284.0, 60.0, 64.0, 68.0], [284.0, 192.0, 64.0, 92.0],
	[552.0, 204.0, 104.0, 48.0], [836.0, 204.0, 60.0, 300.0], [624.0, 252.0, 32.0, 180.0],
	[288.0, 284.0, 60.0, 88.0], [348.0, 292.0, 76.0, 80.0], [36.0, 296.0, 192.0, 36.0],
	[36.0, 332.0, 4.0, 868.0], [280.0, 340.0, 8.0, 136.0], [576.0, 348.0, 48.0, 24.0],
	[288.0, 372.0, 8.0, 104.0], [612.0, 372.0, 12.0, 60.0], [668.0, 460.0, 168.0, 44.0],
	[612.0, 468.0, 56.0, 36.0], [612.0, 504.0, 36.0, 244.0], [856.0, 504.0, 40.0, 480.0],
	[280.0, 548.0, 16.0, 336.0], [40.0, 692.0, 240.0, 20.0], [296.0, 692.0, 160.0, 56.0],
	[604.0, 692.0, 8.0, 56.0], [40.0, 712.0, 8.0, 488.0], [296.0, 748.0, 80.0, 136.0],
	[616.0, 748.0, 32.0, 76.0], [616.0, 884.0, 32.0, 100.0], [48.0, 900.0, 60.0, 300.0],
	[108.0, 960.0, 268.0, 240.0], [376.0, 984.0, 80.0, 216.0], [860.0, 984.0, 36.0, 216.0],
	[696.0, 1000.0, 52.0, 32.0], [696.0, 1092.0, 52.0, 108.0], [748.0, 1096.0, 112.0, 104.0],
	[456.0, 1136.0, 240.0, 64.0],
]

## Spawn: "meio / area azul" = dentro do DOMO (observatorio), longe da sonda.
const SPAWN_PX := Vector2(380.0, 440.0)

const STATIONS_PX := {
	"micro": {"px": Vector2(160.0, 510.0), "name": "ANALISES - MICROSCOPIO", "radius": 50.0},
	"atmo": {"px": Vector2(160.0, 175.0), "name": "NIVEIS DE CARBONO", "radius": 50.0},
	"tank": {"px": Vector2(578.0, 1065.0), "name": "TANQUES BIOMEDICOS", "radius": 50.0},
	"probe": {"px": Vector2(480.0, 560.0), "name": "OBSERVATORIO - SONDA", "radius": 55.0},
}

static func px_to_world(p):
	return p * SCALE

static func rect_px_to_world(r):
	return [r[0] * SCALE, r[1] * SCALE, r[2] * SCALE, r[3] * SCALE]
