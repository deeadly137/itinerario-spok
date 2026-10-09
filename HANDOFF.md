# HANDOFF — PROJETO ABISMO · Registro 8.1

> Documento de contexto completo para outro agente de IA administrar/evoluir este projeto.
> Última atualização: state atual validado com 43/43 testes E2E + auditoria de estilo.

---

## 1. O QUE É ESTE PROJETO

Jogo educativo web (**point-and-click estilo Among Us**) sobre **acidificação dos oceanos**,
para apresentação escolar (turma de 16–18 anos) vinculada a uma reportagem/noticiário
("estilo William Bonner / Cidade Alerta"). O apresentador comanda o tripulante no
projetor enquanto a turma decide as escolhas em voz alta. Duração alvo: ~10 min.

- **Idioma de toda a UI/textos:** pt-BR (não traduzir).
- **Público:** sala de aula, projetor/notebook, offline (funciona via `file://`).
- **Data de apresentação no cronograma original:** 09/10 (jogo feito entre 03–07/10).

### Conteúdo científico obrigatório (fonte: reportagem dos alunos)
- Oceano absorve ~30% do CO₂ emitido → CO₂ + H₂O → H₂CO₃ (ácido carbônico) → H⁺ sobe.
- H⁺ sequestra CO₃²⁻ → organismos perdem matéria-prima para CaCO₃ (conchas/corais).
- pH pré-industrial ≈ 8.2; queda de 0,1 unidade desde a era pré-industrial = +30% na acidez;
  projeção 2100: queda de 0,3 (~170% mais ácido). pH 7.8 = projeção para 2100.
- Fotossíntese de algas/ervas marinhas remove o CO₂ dissolvido da água e eleva o pH local.
- Protocolo B (proteção sistêmica: manguezais + redução de emissões) = VITÓRIA.
  A (alcalinizantes) e C (engenharia genética) = derrota com explicação científica.

---

## 2. COMO RODAR E VALIDAR

```bash
# rodar (offline, sem servidor)
xdg-open /home/deadly/Projects/Codium/mygf/index.html   # ou duplo clique

# validações sempre usadas neste projeto
node --check /home/deadly/Projects/Codium/mygf/game.js          # sintaxe JS
# HTML balanceado: script python com html.parser (ver seção 8)
# IDs do JS presentes no HTML: regex /\$\("#id"\)/ vs id="..." no HTML
```

### Teste E2E (Playwright) — recriável em ~1 min
O pacote foi instalado em **/tmp/pwtest** (pode ser apagado pelo sistema):
```bash
mkdir -p /tmp/pwtest && cd /tmp/pwtest && npm init -y && npm i playwright-core
# binário do Chromium já existe no host:
#   /home/deadly/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome
```
O `test.js` (43 asserções) percorre: boot → movimento → microscópio (erros deliberados
no pH 7.3 e acerto no 8.2) → tanque → sonda BLOQUEADA → atmosfera (3 pares de engrenagens)
→ porta destravada → clímax → Protocolo B (vitória) → reinício completo → zero erros de
console. **Se recriar o teste, copie a lógica descrita aqui: ele usa `walkTo()` com
alinhamento por eixo (portas em x=530 e x=1670, corredor em y=665) e quebra ao detectar
posição estática por 4 iterações.**

Padrão do listener de console: ignorar `favicon` e `ERR_FILE_NOT_FOUND` (5 PNGs opcionais
ainda inexistentes — ver seção 7).

---

## 3. ESTRUTURA DE ARQUIVOS

```
/home/deadly/Projects/Codium/mygf/
├── index.html      (~300 linhas)  — telas, HUD, overlays das tarefas
├── styles.css      (~1120 linhas) — visual flat industrial (ver seção 6)
├── game.js         (~1130 linhas) — todo o motor (ver seção 5)
├── HANDOFF.md      — este documento
└── img/            — 11 JPGs gerados (Gemini/Nano Banana) + 5 PNGs opcionais ausentes
```

**Sem build, sem dependências, sem framework.** HTML+CSS+JS puros clássicos
(`<script src="game.js">` no fim do body — nada de modules/import).

---

## 4. HISTÓRICO DE EVOLUÇÃO (não retroceder)

1. **v1 — Quiz point-and-click:** Hub com 4 hotspots + telas de tarefa separadas.
2. **v2 — Imagens integradas:** 11 JPGs do Gemini renomeados para slugs sem espaços
   (`micro-erro.jpeg`, `tank-ok.jpeg`, etc.); crossfades erro→sucesso por classes.
3. **v3 — Among Us:** mundo top-down 2200×1300, WASD/clique, colisão, USAR por proximidade,
   overlays de tarefa, crewmate em CSS com fallback `onerror="this.remove()"`.
4. **v4 (ATUAL) — Redesign flat + mapa proper:** removidos gradientes/neon/arredondamentos/
   scanlines; mapa reconstruído a partir de dados únicos (fonte única de geometria);
   minimapa, câmera que segue o jogador, rota por waypoints, obstáculos com colisão,
   bug da fechadura corrigido, botão "NOVA MISSÃO", detecção de travamento.

**Motivo da v4 (pedido explícito do usuário):** "Remove AI generated aspects from the game
itself (you can let the images stay), like gradients and too much rounding with neon colors.
Improve the game by making a proper map."
---

## 5. ARQUITETURA TÉCNICA (game.js, ~1130 linhas)

Ordem de seções no arquivo:

| Seção | Conteúdo |
|---|---|
| `AudioSys` (IIFE) | Áudio 100% sintetizado (Web Audio API), sem arquivos: `click, error, success, key, step, doorOpen, startAlarm, stopAlarm, startAmbient, setMuted`. Contexto criado no 1º gesto do usuário (botão INICIAR). Alarme = square 660Hz + LFO. Ambiente = drone 55Hz + bolhas a cada 2,6s. |
| Estado/Helpers | `state {keys A/B/C, tasks micro/tank/atmo, timerId, timeLeft:30, overlayOpen, probeUnlocked, probeDone, running}`; `$`/`$$`; `setFeedback(el,kind,html)`; `toast(text,ms,good)`. |
| **MAPA (fonte única)** | `WORLD_W/H=2200/1300`, `ROOMS`, `WALLS`, `DOOR_WALL`, `PROPS`, `THRESHOLDS`, `SPAWN`, `SPAWN_PAD`, `STATIONS`, `PLAYER_R=22`, `PLAYER_SPEED=260`, `player`, `keysDown`, `clickPath`. **Toda geometria (visual + colisão + minimapa) deriva daqui.** |
| Construção | `activeWalls()` = WALLS + DOOR_WALL (se travada) + PROPS; `buildMap()` (gera `#map-layer`: pisos→rótulos→spawn→limiares→props→paredes→porta; posiciona estações; chama `buildMinimap()`); `collidesWall(px,py)` círculo-vs-retângulos. |
| Câmera | `measureViewport()`, `computeCamTarget()` (zoom = `min(1, max(vw/1600, vh/850))`, segue jogador com clamp nos limites), `updateCamera(snap)` (lerp 0.12), `screenToWorld()`. |
| Movimento | `tryMove` por eixo (desliza em paredes); `gameLoop(ts)` com dt clamp 0.05; input WASD/setas cancela rota; rota por waypoints `clickPath` com `pathTo(target)`/`doorCx(x)`/`regionOf(x,y)` — atravessa portas (centros x=530 e x=1670, corredor y=665); detecção de travamento cancela rota com toast após 1,1s. |
| Proximidade/USAR | `updateProximity()` raio 150/160 → mostra `#use-btn`; `tryUse()` (bloqueia sonda com toast se sem chaves). |
| Overlays | `openTask(id)` / `closeTask(id)`; clímax não pode fechar com timer ativo (ESC/FECHAR bloqueados com aviso); reabrir sonda com `probeDone` mostra desfecho sem alarme. |
| Input | keydown/keyup (`e` ou espaço = USAR, ESC = fechar), clique em estação (perto→USAR, longe→`pathTo`), clique no chão→`pathTo` + marcador, `blur` limpa teclas. |
| Chaves/Porta | `collectKey(letter, taskId)` (slot + lista + marcador + minimapa); `unlockProbe()` (porta→open, rótulo verde, alerta, som, toast, `buildMap()`). |
| Tarefas | Micro (flasks `data-ph`: **8.2=certo**, 7.8=erro 2100, 7.3=erro grave+shake); Tanque (CO₂=erro ácido, O₂=parcial, fotossíntese=certo com crossfade 0,9s); Atmosfera (3 pares `GEARS` embaralhados via `sort(random-0.5)`). |
| Clímax | `OUTCOMES {A,B,C,TIMEOUT}` com textos científicos; `OUTCOME_IMGS`; `startProbe/stopProbe/updateTimerDisplay` (30s, perigo ≤10s); `showOutcome(which)` (B marca `probeDone` + tarefa concluída). |
| Reinício | `resetGame()` — zera chaves/tarefas/porta/fotos/feedbacks/gears (`buildGears()`), overlays, jogador→spawn, câmera snap. Vinculado a `#outcome-restart`. |
| Init | `#start-btn`: ambient → esconde boot → `buildMap()` → `measureViewport()` → `updateCamera(true)` → gameLoop. |

**IDs criados dinamicamente pelo `buildMap()`** (não estão no HTML — não "consertar"):
`#map-layer`, `#door-probe`, `#door-sign`, `#label-probe` (ganha `.open` quando
`state.probeUnlocked` — já tratado dentro do buildMap, não adicionar depois).
IDs do minimapa: `mini-micro/tank/atmo/probe` (classes `done`/`locked`).

**Fluxo completo:** boot → Hub(mapa) → [micro|tanque|atmo em qualquer ordem] →
3 chaves → `unlockProbe` → andar até sonda → overlay clímax (cronômetro) →
Protocolo B = vitória | A/C/timeout = derrota com retry → voltar ao mapa ou
"NOVA MISSÃO" (`resetGame`).

---

## 6. VISUAL — REGRAS DE ESTILO (auditado por script, não violar)

Pedido do usuário: **sem gradientes, sem brilhos neon (box-shadow colorido), sem
text-shadow, sem arredondamento na UI**. O screnshot/auditoria confirmam:
`AUDITORIA OK` checando estilos computados de 18 seletores-chave.

- Paleta (em `:root`): `--bg:#0d1117 --surface:#151b22 --surface2:#1b232d
  --line:#2b3542 --line2:#3d4a5a --text:#ccd5df --dim:#8b97a6
  --accent:#6aa5c7 (aço) --good:#58a06a --bad:#c15c5c --warn:#c9a253`.
- Fonte: mono (`Consolas/DejaVu Sans Mono/Courier New`). Cantos retos (`border-radius:0`)
  em TODA a UI. **Exceções permitidas** (é desenho de objeto, não UI): corpo do crewmate,
  visor/mochila/pernas, frascos (Erlenmeyer), marcador de clique e ponto do minimapa (círculos).
- `.btn-neon` é **nome legado** — o estilo já é flat; não renomear (aparece em 7 botões do HTML).
- Sons de estados: verde=ok/certo, vermelho=erro, âmbar=atenção/chave, aço=neutro.
- Emojis (🔬🧪🏭📡) são placeholders dos sprites PNG; manter o fallback `onerror="this.remove()"`.
- Fotos JPG ficam em containers `position:relative; aspect-ratio:16/9` com `<img>` absolutos
  e crossfade por opacidade (classes `.erro`/`.ok` + estado `.fixed|.saved|.solved`).
---

## 7. IMAGENS (img/)

### Presentes (11 JPGs gerados por Gemini 3.6 / Nano Banana — NÃO substituir o estilo)
| Arquivo | Uso |
|---|---|
| `micro-erro.jpeg` / `micro-ok.jpeg` | Concha corroída → restaurada (tarefa micro) |
| `tank-erro.jpeg` / `tank-ok.jpeg` | Tanques ácidos → salvos (tarefa tanque) |
| `graph-erro.jpeg` / `graph-ok.jpeg` | Gráfico CO₂×pH → linha verde estável (atmosfera) |
| `probe-reef.jpeg` | Câmera do recife em colapso (clímax) + desfecho TIMEOUT |
| `outcome-vitoria.jpeg` | Desfecho Protocolo B |
| `outcome-protocolo-a.jpeg` | Desfecho Protocolo A (também é o `src` inicial do `#outcome-img`) |
| `outcome-protocolo-c.jpeg` | Desfecho Protocolo C |
| `hub-lab.jpeg` | **ÓRFÃO** — usado na v1/v2, não referenciado no código atual (manter ou apagar) |

### Pendentes (5 PNGs opcionais — jogo funciona sem eles)
`img/player.png`, `img/obj-microscope.png`, `img/obj-tanks.png`, `img/obj-panel.png`,
`img/obj-probe.png`. Referenciados no HTML com `onerror="this.remove()"` (emoji/CSS
crewmate fazem fallback). Ao adicionar os arquivos, **nenhum código precisa mudar**.
Prompts originais (inglês, fundo transparente, top-down) estão na conversa de criação:
player = astronauta ciano 3/4; objetos = consoles/estações sci-fi neon ciano.

---

## 8. SCRIPTS DE VALIDAÇÃO (reutilizar)

1. **Sintaxe:** `node --check game.js`
2. **HTML balanceado:** `HTMLParser` do python3 com lista de void tags
   (`meta,link,br,img,input,hr,circle,rect,line,path,ellipse,stop`).
3. **IDs cruzados:** regex `/\$\("#([a-zA-Z0-9_-]+)"\)/` no JS vs `id="..."` no HTML
   — esperado 4 falsos positivos criados dinamicamente (ver §5).
4. **Geometria do mapa:** extrair do JS o trecho de `const ROOMS` até `const player`,
   avaliar em node e asserir: vãos das linhas y=560 e y=740 exatamente
   `[[460,600],[1600,1740]]` (intervalos mesclados!), `DOOR_WALL=[1600,740,140,30]`,
   divisórias x=1000, props sem colidir paredes/estações/spawn entre si,
   spawn livre, estações dentro dos cômodos com raio USAR inteiro dentro da sala,
   vãos de 140px e corredor de 150px ≥ 2·PLAYER_R+margem.
5. **Auditoria de estilo (no navegador):** para 18 seletores-chave
   (`body,#topbar,#tasklist,#minimap,#use-btn,.task-panel,.task-head h2,.btn-close,
   .challenge-panel,.station-base,.station-name,.alarm-banner,.protocol,.feedback,
   .btn-neon,.gear,.door,.floor.tone-c`) asserir: `borderRadius==="0px"` (exceto floor),
   `backgroundImage` sem `gradient`, `textShadow` vazio, sem glow
   (`box-shadow` colorido com deslocamento 0 e blur ≥8).
6. **E2E (playwright-core):** ver §2 — 43 asserções, fluxo completo jogável.

---

## 9. PENDÊNCIAS, ARMADILHAS E NOTAS FINAIS

- **Testes/E2E ficam em `/tmp/pwtest`** (fora do repositório; pode sumir). O binário do
  Chromium é do Playwright e vive em `~/.cache/ms-playwright/`. Se recriar, `npm i playwright-core`.
- **Não há Git** neste diretório (workspace associado a `itinerario-spok.git`, mas o projeto
  não está versionado). Antes de mudanças grandes, considerar copiar os 3 arquivos.
- **Restrição da ferramenta de edição:** o editor de arquivos deste ambiente rejeita
  texto >6000 caracteres por chamada. Padrão usado: criar arquivo e ir anexando blocos
  substituindo o marcador `<!--APPEND-->` (ou chaves `{/*APPEND*/}` no JS). styles.css e
  game.js cresceram assim.
- **Armadilhas já resolvidas (não reintroduzir):**
  - Porta da sonda: colisão E visual devem usar o MESMO retângulo (hoje `DOOR_WALL`).
  - `buildMap()` recria rótulo/porta — estados como `.open` precisam ser reaplicados
    DENTRO do buildMap (já está assim).
  - Caixote no meio do corredor bloqueava a rota principal (removido; só 2 laterais em
    x=240 e x=1960, encostados na parede norte).
  - `alignX/alignY` de teste precisam quebrar com posição estática senão travam 13s.
  - Teclas presas: `window blur` limpa `keysDown`.
  - Sonda reaberta pós-vitória: checar `state.probeDone` antes de `startProbe()`.
- **Melhorias possíveis (não pedidas):** pathfinding A* (hoje waypoint+deslize);
  telas de pausa; legendas/português para PNGs; reduzir ~900KB/JPG se precisar de
  pen-drive mais leve (hoje ~9,4MB no total, aceitável offline).
- **Tom da comunicação com o usuário:** pt-BR, direto, com validação executada
  (sempre rodar os checks antes de afirmar que funciona).

// FIM DO HANDOFF — qualquer agente deve atualizar este arquivo ao concluir tarefas.


