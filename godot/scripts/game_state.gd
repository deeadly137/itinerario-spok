extends Node
## GameState — estado global (projeto longo, SEM chaves).
## Tarefas marcam progresso; sonda sempre acessível.

signal task_done(task_id: String)
signal probe_finished(win: bool)

var tasks := {"micro": false, "tank": false, "atmo": false}
var probe_done := false


func reset() -> void:
	tasks = {"micro": false, "tank": false, "atmo": false}
	probe_done = false


func complete_task(task_id: String) -> bool:
	if tasks.get(task_id, true):
		return false
	tasks[task_id] = true
	task_done.emit(task_id)
	return true


func tasks_done() -> int:
	var n := 0
	for v in tasks.values():
		if v:
			n += 1
	return n
