class_name SabotageSys
extends Node
## Sabotagem simulada do "cientista" (sem rede): a cada 60 s sorteia um
## evento que atrapalha a locomoção. Estável por construção: efeitos com
## tempo fixo, sem tocar na geometria/colisão (só porta extra + slow).

signal blackout(active: bool)
signal door_blocked(name: String, active: bool)
signal sabotage_toast(text: String)

var active := false
var timer := 0.0
const INTERVAL := 60.0
var blackout_left := 0.0
var door_left := 0.0
const DURATION := 12.0


func start() -> void:
	active = true
	timer = INTERVAL


func stop() -> void:
	active = false
	if blackout_left > 0.0:
		blackout_left = 0.0
		blackout.emit(false)
	if door_left > 0.0:
		door_left = 0.0
		door_blocked.emit("porta", false)


func _process(delta: float) -> void:
	if not active:
		return
	if blackout_left > 0.0:
		blackout_left -= delta
		if blackout_left <= 0.0:
			blackout.emit(false)
	if door_left > 0.0:
		door_left -= delta
		if door_left <= 0.0:
			door_blocked.emit("porta", false)
	timer -= delta
	if timer <= 0.0:
		timer = INTERVAL
		_trigger()


func _trigger() -> void:
	var roll := randi() % 2
	if roll == 0:
		blackout_left = DURATION
		blackout.emit(true)
		sabotage_toast.emit("SABOTAGEM: os cientistas apagaram as luzes por 12 s! Decorem o caminho!")
	else:
		door_left = DURATION
		door_blocked.emit("porta", true)
		sabotage_toast.emit("SABOTAGEM: porta do HALL bloqueada por 12 s! Contornem pelo outro lado!")
