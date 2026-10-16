class_name SabotageSys
extends Node
## Sabotagem simulada dos "cientistas" (sem rede): a cada 60 s as luzes
## caem por 12 s. Sem texto na tela — o efeito (a luz falhando) fala por si
## e o aviso automatico incomodava durante a partida.

signal blackout(active: bool)

var active := false
var timer := 0.0
const INTERVAL := 60.0
var blackout_left := 0.0
const DURATION := 12.0


func start() -> void:
	active = true
	timer = INTERVAL


func stop() -> void:
	active = false
	if blackout_left > 0.0:
		blackout_left = 0.0
		blackout.emit(false)


func _process(delta: float) -> void:
	if not active:
		return
	if blackout_left > 0.0:
		blackout_left -= delta
		if blackout_left <= 0.0:
			blackout.emit(false)
	timer -= delta
	if timer <= 0.0:
		timer = INTERVAL
		blackout_left = DURATION
		blackout.emit(true)
