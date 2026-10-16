class_name GameWorld
extends Node2D
## Mapa da estação desenhado por código a partir de MapData.
## Pisos, paredes, porta da sonda, obstáculos, spawn e estações.

signal station_pressed(station_id: String)

const TONES := {
	"a": Color("1b3a52"), "b": Color("1a4a44"), "c": Color("2a3140"),
	"d": Color("3a2f4a"), "e": Color("33301f"),
}
const WALL_C := Color("141c2a")
const DOOR_LOCKED := Color("7f1d1d")
const DOOR_OPEN := Color("166534")
const PROP_C := Color("31435c")

var stations: Dictionary = {}
var door_rect: ColorRect
var door_label: Label


func rect_at(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = pos
	r.size = size
	add_child(r)
	return r


func label_at(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func build(probe_open: bool, mode := "classic") -> void:
	for c in get_children():
		c.queue_free()
	stations.clear()
	if mode == "new":
		_build_new(probe_open)
		return
	if mode == "atlantis":
		_build_atlantis(probe_open)
		return
	if mode == "temp":
		_build_temp(probe_open)
		return
	_build_classic(probe_open)


## Mapa novo (MapNEW.jpeg): fundo + movimento LIVRE sobre a imagem.
## Sem colisao: as paredes eram um "bounding box" que so servia para nao
## sair da imagem (o proprio player ja fica preso aos limites do mundo).
## O mapa agora e um espaco aberto e o fundo e a unica referencia visual.
func _build_new(_probe_open: bool) -> void:
	if ResourceLoader.exists("res://assets/img/map_new.jpg"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/img/map_new.jpg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		bg.position = Vector2.ZERO
		bg.size = Vector2(MapNew.WORLD_W, MapNew.WORLD_H)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	var sp: Vector2 = MapNew.px_to_world(MapNew.SPAWN_PX)
	rect_at(self, sp - Vector2(30, 30), Vector2(60, 60), Color("1d4ed8"))
	var defs := [
		["micro", "ANALISES", "M", Color("1e6f8e")],
		["tank", "TANQUES", "B", Color("1f7a5c")],
		["atmo", "CARBONO", "C", Color("6b4fa1")],
		["probe", "SONDA", "S", Color("8e3b46")],
	]
	for dd in defs:
		var id: String = dd[0]
		var st := Station.new()
		add_child(st)
		st.setup(id, MapNew.px_to_world(MapNew.STATIONS_PX[id]["px"]), dd[1], dd[2], dd[3],
			float(MapNew.STATIONS_PX[id]["radius"]) * MapNew.SCALE)
		st.pressed.connect(func(sid: String) -> void: station_pressed.emit(sid))
		stations[id] = st
		if id == "probe":
			st.set_locked(false)


func _build_classic(_probe_open: bool) -> void:
	# pisos
	for r in MapData.ROOMS:
		rect_at(self, Vector2(r["x"], r["y"]), Vector2(r["w"], r["h"]),
			TONES.get(r["tone"], Color.DARK_SLATE_GRAY))
		label_at(r["label"], Vector2(r["lx"] - 220, r["ly"] - 14), 26, Color(0.7, 0.8, 0.9))
	# spawn
	var pad: Array = MapData.SPAWN_PAD
	rect_at(self, Vector2(pad[0], pad[1]), Vector2(pad[2], pad[3]), Color("1d4ed8"))
	label_at("INICIO", Vector2(pad[0] - 4, pad[1] + 18), 20, Color.WHITE)
	# limiares
	for t in MapData.THRESHOLDS:
		rect_at(self, Vector2(t[0], t[1]), Vector2(t[2], t[3]), Color("3b4a63"))
	# móveis
	for p in MapData.PROPS:
		rect_at(self, Vector2(p[0], p[1]), Vector2(p[2], p[3]), PROP_C)
		if String(p[5]) != "":
			label_at(String(p[5]), Vector2(p[0] + 8, p[1] + 14), 18, Color(0.75, 0.82, 0.92))
	# paredes (corpo estático para CharacterBody2D colidir)
	var static_body := StaticBody2D.new()
	static_body.name = "Walls"
	add_child(static_body)
	for w in MapData.WALLS:
		rect_at(self, Vector2(w[0], w[1]), Vector2(w[2], w[3]), WALL_C)
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(w[2], w[3])
		col.shape = rs
		col.position = Vector2(w[0] + w[2] / 2.0, w[1] + w[3] / 2.0)
		static_body.add_child(col)
	for p in MapData.PROPS:
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(p[2], p[3])
		col.shape = rs
		col.position = Vector2(p[0] + p[2] / 2.0, p[1] + p[3] / 2.0)
		static_body.add_child(col)
	# vão da sonda: sempre aberto (sem chaves no projeto longo)
	var d: Array = MapData.DOOR_WALL
	door_rect = rect_at(self, Vector2(d[0], d[1]), Vector2(d[2], d[3]), DOOR_OPEN)
	door_label = label_at("ABERTA",
		Vector2(d[0] + 8, d[1] - 30), 20, Color(0.4, 1, 0.5))
	# estações
	var defs := [
		["micro", "MICROSCOPIO", "M", Color("1e6f8e")],
		["tank", "BIORREATORES", "B", Color("1f7a5c")],
		["atmo", "NIVEIS DE CARBONO", "C", Color("6b4fa1")],
		["probe", "PISCINA LUNAR", "S", Color("8e3b46")],
	]
	for dd in defs:
		var id: String = dd[0]
		var st := Station.new()
		add_child(st)
		st.setup(id, MapData.STATIONS[id]["pos"], dd[1], dd[2], dd[3],
			float(MapData.STATIONS[id]["radius"]))
		st.pressed.connect(func(sid: String) -> void: station_pressed.emit(sid))
		stations[id] = st
		if id == "probe":
			st.set_locked(false)


## Mapa ATLANTIS SUB-BASE: fundo MAPtest.jpeg + colisão traçada.
func _build_atlantis(probe_open: bool) -> void:
	if ResourceLoader.exists("res://assets/img/map_main.jpg"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/img/map_main.jpg")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		bg.position = Vector2.ZERO
		bg.size = Vector2(MapAtlantis.WORLD_W, MapAtlantis.WORLD_H)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	var static_body := StaticBody2D.new()
	static_body.name = "Walls"
	add_child(static_body)
	for w in MapAtlantis.WALLS_PX:
		var wr := MapAtlantis.rect_px_to_world(w)
		rect_at(self, Vector2(wr[0], wr[1]), Vector2(wr[2], wr[3]), WALL_C)
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(maxf(wr[2], 8.0), maxf(wr[3], 8.0))
		col.shape = rs
		col.position = Vector2(wr[0] + wr[2] / 2.0, wr[1] + wr[3] / 2.0)
		static_body.add_child(col)
	var sp := MapAtlantis.px_to_world(MapAtlantis.SPAWN_PX)
	rect_at(self, sp - Vector2(30, 30), Vector2(60, 60), Color("1d4ed8"))
	var defs := [
		["micro", "ANALISES", "M", Color("1e6f8e")],
		["tank", "TANQUES", "B", Color("1f7a5c")],
		["atmo", "CARBONO", "C", Color("6b4fa1")],
		["probe", "SONDA", "S", Color("8e3b46")],
	]
	for dd in defs:
		var id: String = dd[0]
		var st := Station.new()
		add_child(st)
		st.setup(id, MapAtlantis.px_to_world(MapAtlantis.STATIONS_PX[id]["px"]), dd[1], dd[2], dd[3],
			float(MapAtlantis.STATIONS_PX[id]["radius"]) * MapAtlantis.SCALE)
		st.pressed.connect(func(sid: String) -> void: station_pressed.emit(sid))
		stations[id] = st
		if id == "probe":
			st.set_locked(false)


## Mapa temporário: fundo PNG (esquema) + pisos translúcidos, paredes
## traçadas de MapTemp.WALLS_PX e estações de MapTemp.STATIONS_PX.
func _build_temp(probe_open: bool) -> void:
	if ResourceLoader.exists("res://assets/img/map_temp.png"):
		var bg := TextureRect.new()
		bg.texture = load("res://assets/img/map_temp.png")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		bg.position = Vector2.ZERO
		bg.size = Vector2(MapTemp.WORLD_W, MapTemp.WORLD_H)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	# pisos translúcidos (só para leitura; o PNG é o visual)
	for r in MapTemp.ROOMS_PX:
		var wr := MapTemp.rect_px_to_world([r["x"], r["y"], r["w"], r["h"]])
		rect_at(self, Vector2(wr[0], wr[1]), Vector2(wr[2], wr[3]), Color(0.2, 0.5, 0.7, 0.18))
		if String(r["label"]) != "":
			label_at(String(r["label"]), Vector2(wr[0] + 8, wr[1] + 8), 22, Color(0.75, 0.86, 0.95))
	var static_body := StaticBody2D.new()
	static_body.name = "Walls"
	add_child(static_body)
	for w in MapTemp.WALLS_PX:
		var wr := MapTemp.rect_px_to_world(w)
		rect_at(self, Vector2(wr[0], wr[1]), Vector2(wr[2], wr[3]), WALL_C)
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(maxf(wr[2], 8.0), maxf(wr[3], 8.0))
		col.shape = rs
		col.position = Vector2(wr[0] + wr[2] / 2.0, wr[1] + wr[3] / 2.0)
		static_body.add_child(col)
	# spawn
	var sp := MapTemp.px_to_world(MapTemp.SPAWN_PX)
	rect_at(self, sp - Vector2(30, 30), Vector2(60, 60), Color("1d4ed8"))
	# estações do mapa novo
	var defs := [
		["micro", "ANALISES", "M", Color("1e6f8e")],
		["tank", "TANQUES", "B", Color("1f7a5c")],
		["atmo", "CARBONO", "C", Color("6b4fa1")],
		["probe", "SONDA", "S", Color("8e3b46")],
	]
	for dd in defs:
		var id: String = dd[0]
		var st := Station.new()
		add_child(st)
		st.setup(id, MapTemp.px_to_world(MapTemp.STATIONS_PX[id]["px"]), dd[1], dd[2], dd[3],
			float(MapTemp.STATIONS_PX[id]["radius"]) * MapTemp.SCALE)
		st.pressed.connect(func(sid: String) -> void: station_pressed.emit(sid))
		stations[id] = st
		if id == "probe":
			st.set_locked(false)

