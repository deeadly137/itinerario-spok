# Como criar um mapa (e o "bounding box" dele)

Este documento explica como adicionar um mapa novo ao jogo e como definir a
área caminhável (o *bounding box*).

## 1. Como o mapa funciona hoje

Um "mapa" é **só uma imagem** + alguns números. Não existe tilemap nem editor:
o fundo é um `TextureRect` esticado para um tamanho de **mundo** e todo o
resto é posicionado em cima dele.

Cada mapa tem um script em `godot/scripts/` (ex.: `map_new.gd`,
`map_atlantis.gd`) com estas constantes:

| Constante | Significa |
|---|---|
| `IMG_W`, `IMG_H` | tamanho da imagem em **pixels** |
| `SCALE` | quantos pixels de mundo valem 1 pixel da imagem |
| `WORLD_W`, `WORLD_H` | `IMG_W * SCALE`, `IMG_H * SCALE` (unidades de **mundo**) |
| `SPAWN_PX` | onde o jogador nasce, em pixels da imagem |
| `STATIONS_PX` | tarefas: `{"id": {"px": Vector2, "name": String, "radius": float}}` |
| `WALLS_PX` | retângulos de parede, em pixels da imagem (opcional) |

Regra de ouro: **tudo que você mede na imagem é em pixels; multiplica por
`SCALE` (`px_to_world`) e vira unidade de mundo.** O jogador, a câmera e as
tarefas vivem em unidades de mundo.

## 2. Passo a passo: mapa novo

1. **Coloque a imagem** em `godot/assets/img/` (ex.: `map_factory.jpg`).
2. **Crie o script** `godot/scripts/map_factory.gd`:

   ```gdscript
   class_name MapFactory
   extends RefCounted

   const SCALE := 3.0
   const IMG_W := 896.0
   const IMG_H := 1200.0
   const WORLD_W := IMG_W * SCALE
   const WORLD_H := IMG_H * SCALE
   const USE_WALLS := false          # ver seção 3

   const SPAWN_PX := Vector2(380.0, 440.0)

   const STATIONS_PX := {
       "micro": {"px": Vector2(160.0, 510.0), "name": "ANALISES", "radius": 50.0},
   }

   const WALLS_PX := []              # ver seção 3

   static func px_to_world(p): return p * SCALE
   static func rect_px_to_world(r):
       return [r[0] * SCALE, r[1] * SCALE, r[2] * SCALE, r[3] * SCALE]
   ```

3. **Desenhe o fundo** em `game_world.gd`, numa função `_build_factory()`:

   ```gdscript
   func _build_factory(probe_open: bool) -> void:
       var bg := TextureRect.new()
       bg.texture = load("res://assets/img/map_factory.jpg")
       bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
       bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
       bg.size = Vector2(MapFactory.WORLD_W, MapFactory.WORLD_H)
       bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
       add_child(bg)
       # estações...
   ```

   e chame no `build()`:

   ```gdscript
   if mode == "factory":
       _build_factory(probe_open)
       return
   ```

4. **Registre no `main.gd`** (3 lugares):
   - `_apply_world_geometry()` → o `match map_mode` (SPAWN, WORLD_W/H, zoom);
   - `_stations()` → a lista de tarefas com o raio;
   - `_map_bg_path()` → o caminho da imagem para o mapa do ícone MAPA.
5. **Registre no lobby** (`lobby_map.gd`, constante `MAPS`) para aparecer no
   botão `MAPA:` de quem cria a sala.

## 3. O "bounding box" (a área caminhável)

Existem **duas** noções de bounding box — escolha o que você quer:

### a) Não sair da imagem (já vem de graça)

O `Player` é um `CharacterBody2D` e, no fim do `_physics_process`, ele é
**preso ao mundo**:

```gdscript
global_position.x = clampf(global_position.x, RADIUS, world_w - RADIUS)
global_position.y = clampf(global_position.y, RADIUS, world_h - RADIUS)
```

Ou seja: basta o `WORLD_W`/`WORLD_H` estarem certos (iguais ao tamanho da
imagem × `SCALE`) e o jogador **nunca sai da imagem**. É o modo atual do
mapa `new` (andar livre, sem colisão nenhuma).

### b) Paredes de verdade (corredores/salas sólidos)

Para bloquear passagens, preencha `WALLS_PX` com retângulos em **pixels da
imagem** e ligue `USE_WALLS = true`. O `GameWorld` já traz um helper pronto:

```gdscript
func add_walls(rects_world: Array, draw := true, tint := WALL_C) -> void
```

Ele cria um `StaticBody2D` chamado `Walls` com **uma caixa de colisão por
retângulo**. Como o jogador é `CharacterBody2D`, ele colide de verdade e
**desliza** na parede (`move_and_slide`).

Exemplo (é o que o `_build_new` faz quando `MapNew.USE_WALLS` é `true`):

```gdscript
var walls := []
for r in MapFactory.WALLS_PX:
    walls.append(MapFactory.rect_px_to_world(r))   # px -> mundo
add_walls(walls)          # draw=true pinta as paredes (útil para conferir)
```

Dicas:
- Passe `add_walls(walls, true)` durante o desenvolvimento para **ver** as
  paredes pintadas de `WALL_C` e ajustar os retângulos; depois deixe `false`.
- Retângulos com menos de 8 px são inflados para 8 (evita parede "vazando"
  por causa do raio do jogador).
- Como o jogador é um círculo de raio 20, deixe os corredores com pelo menos
  ~60 px de mundo de largura.

## 4. Como achar as coordenadas

Não há editor visual. O jeito rápido:

1. Abra a imagem num editor (GIMP, Paint, Figma) e ligue a régua/grade em
   pixels.
2. Meça os cantos de cada sala/corredor → `[x, y, largura, altura]`.
3. **Confira no jogo**: ligue `USE_WALLS` e `draw=true` e veja se as paredes
   batem com os desenhos da imagem.
4. Para as tarefas, a `STATIONS_PX` usa o **centro** em `px` e um `radius`
   (também em pixels, multiplicado por `SCALE` e pelo `Station.REACH` de
   1.35 — ver `station.gd`). O alcance do botão USAR e a hitbox do toque usam
   esse mesmo número, então eles ficam sempre coerentes.
