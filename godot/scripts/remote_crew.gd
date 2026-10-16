class_name RemoteCrew
extends Node2D
## Outro jogador, visto por mim, dentro do mapa (MapNEW).
##
## A posicao chega pela rede ~15x/s e e INTERPOLADA aqui: sem isso o boneco
## anda aos pulos. Se o salto for grande (entrou agora, ou a rede engasgou),
## a gente cola direto em vez de deslizar pela parede.

var pid := 0
var target := Vector2.ZERO
var has_target := false
var role := ""
var animal := ""
var _built := false


func setup(p_pid: int, p_role: String, p_animal: String, nm: String, pos: Vector2) -> void:
	pid = p_pid
	position = pos
	target = pos
	has_target = true
	apply_role(p_role, p_animal, nm)


## (Re)desenha o boneco quando o papel chega pela rede.
func apply_role(p_role: String, p_animal: String, nm: String) -> void:
	if _built and p_role == role and p_animal == animal:
		return
	role = p_role
	animal = p_animal
	for c in get_children():
		remove_child(c)
		c.queue_free()
	NetHub.decorate_crew(self, role, animal, "e8e8e8", 48.0, nm)
	_built = true


func set_target(p: Vector2) -> void:
	if not has_target or target.distance_to(p) > 320.0:
		position = p
	target = p
	has_target = true


func _process(delta: float) -> void:
	if has_target:
		position = position.lerp(target, clampf(delta * 12.0, 0.0, 1.0))
