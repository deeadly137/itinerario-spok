/* ============================================================
   PROJETO ABISMO — Registro 8.1 · EDIÇÃO "TRIPULANTE"
   Estilo Among Us: mover, chegar perto, USAR tarefa.
   ============================================================ */

"use strict";

/* ------------------------- ÁUDIO ------------------------- */

const AudioSys = (() => {
  let ctx = null;
  let master = null;
  let ambientStarted = false;
  let alarmOsc = null;
  let muted = false;

  function ensure() {
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.5;
      master.connect(ctx.destination);
    }
    if (ctx.state === "suspended") ctx.resume();
  }

  function setMuted(v) {
    muted = v;
    if (master) master.gain.value = v ? 0 : 0.5;
  }

  function click() {
    ensure();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = "square";
    o.frequency.value = 880;
    g.gain.setValueAtTime(0.12, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08);
    o.connect(g); g.connect(master);
    o.start(); o.stop(ctx.currentTime + 0.09);
  }

  function error() {
    ensure();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = "sawtooth";
    o.frequency.setValueAtTime(320, ctx.currentTime);
    o.frequency.exponentialRampToValueAtTime(70, ctx.currentTime + 0.45);
    g.gain.setValueAtTime(0.18, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
    o.connect(g); g.connect(master);
    o.start(); o.stop(ctx.currentTime + 0.52);
  }

  function success() {
    ensure();
    [523.25, 659.25, 783.99, 1046.5].forEach((f, i) => {
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.type = "triangle";
      o.frequency.value = f;
      const t = ctx.currentTime + i * 0.12;
      g.gain.setValueAtTime(0.001, t);
      g.gain.exponentialRampToValueAtTime(0.2, t + 0.02);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.35);
      o.connect(g); g.connect(master);
      o.start(t); o.stop(t + 0.4);
    });
  }

  function key() {
    ensure();
    [1318.5, 1760, 2093].forEach((f, i) => {
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.type = "sine";
      o.frequency.value = f;
      const t = ctx.currentTime + i * 0.07;
      g.gain.setValueAtTime(0.001, t);
      g.gain.exponentialRampToValueAtTime(0.22, t + 0.02);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.5);
      o.connect(g); g.connect(master);
      o.start(t); o.stop(t + 0.55);
    });
  }

  function step() {
    ensure();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = "triangle";
    o.frequency.value = 110 + Math.random() * 40;
    g.gain.setValueAtTime(0.05, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.09);
    o.connect(g); g.connect(master);
    o.start(); o.stop(ctx.currentTime + 0.1);
  }

  function doorOpen() {
    ensure();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = "sine";
    o.frequency.setValueAtTime(220, ctx.currentTime);
    o.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.4);
    g.gain.setValueAtTime(0.18, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
    o.connect(g); g.connect(master);
    o.start(); o.stop(ctx.currentTime + 0.55);
  }

  function startAlarm() {
    ensure();
    if (alarmOsc) return;
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = "square";
    o.frequency.value = 660;
    g.gain.value = 0.08;
    o.connect(g); g.connect(master);
    o.start();
    const lfo = ctx.createOscillator();
    const lfoGain = ctx.createGain();
    lfo.frequency.value = 4;
    lfoGain.gain.value = 160;
    lfo.connect(lfoGain); lfoGain.connect(o.frequency);
    lfo.start();
    alarmOsc = { o, g, lfo };
  }

  function stopAlarm() {
    if (alarmOsc) {
      try { alarmOsc.o.stop(); alarmOsc.lfo.stop(); } catch (e) { /* já parado */ }
      alarmOsc = null;
    }
  }

  function startAmbient() {
    ensure();
    if (ambientStarted) return;
    ambientStarted = true;
    const drone = ctx.createOscillator();
    const droneGain = ctx.createGain();
    const filter = ctx.createBiquadFilter();
    drone.type = "sawtooth";
    drone.frequency.value = 55;
    filter.type = "lowpass";
    filter.frequency.value = 180;
    droneGain.gain.value = 0.05;
    drone.connect(filter); filter.connect(droneGain); droneGain.connect(master);
    drone.start();
    setInterval(() => {
      if (muted || document.hidden) return;
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.type = "sine";
      const t = ctx.currentTime;
      o.frequency.setValueAtTime(300 + Math.random() * 300, t);
      o.frequency.exponentialRampToValueAtTime(900 + Math.random() * 400, t + 0.12);
      g.gain.setValueAtTime(0.03, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.15);
      o.connect(g); g.connect(master);
      o.start(t); o.stop(t + 0.16);
    }, 2600);
  }

  return { click, error, success, key, step, doorOpen, startAlarm, stopAlarm, startAmbient, setMuted,
           get muted() { return muted; } };
})();
/* ------------------------- ESTADO / HELPERS ------------------------- */

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => Array.from(document.querySelectorAll(sel));

const state = {
  keys: { A: false, B: false, C: false },
  tasks: { micro: false, tank: false, atmo: false },
  timerId: null,
  timeLeft: 30,
  overlayOpen: null,
  probeUnlocked: false,
  running: false,
};

function setFeedback(el, kind, html) {
  el.className = "feedback show " + kind;
  el.innerHTML = html;
}

let toastTimeout = null;
function toast(text, ms = 3500, good = false) {
  const box = $("#toast");
  box.textContent = text;
  box.classList.toggle("good", good);
  box.classList.add("show");
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => box.classList.remove("show"), ms);
}

/* ------------------------- MAPA / PAREDES ------------------------- */

// mundo: 2200 x 1300. paredes: [x, y, w, h]
const WALLS = [
  // bordas externas
  [0, 0, 2200, 30], [0, 1270, 2200, 30], [0, 0, 30, 1300], [2170, 0, 30, 1300],
  // cômodo superior esquerdo (MICRO) — parede direita com porta em y 260-360
  [1010, 30, 30, 230], [1010, 360, 30, 200],
  // parede inferior do MICRO/ATMO com portas em x 480-620
  [30, 590, 450, 30], [620, 590, 420, 30],
  [30, 710, 450, 30], [620, 710, 420, 30],
  // cômodo superior direito (TANQUE) — parede esquerda com porta em y 260-360
  [1160, 30, 30, 230], [1160, 360, 30, 200],
  // parede inferior do TANQUE/SONDA com portas em x 1560-1700
  [1190, 590, 370, 30], [1700, 590, 470, 30],
  [1190, 710, 370, 30], [1700, 710, 470, 30],
  // parede esquerda do ATMO (inferior esquerdo) com porta em y 1010-1120
  [1010, 740, 30, 270], [1010, 1120, 30, 150],
  // parede esquerda da SONDA (inferior direito) — SEM porta (só acessível pela fechadura de cima)
  [1160, 740, 30, 530],
];
// fechadura da sonda: vão entre as paredes superiores em x 1640-1740, y 590-620
const DOOR_WALL = [1640, 590, 100, 30];

// posições (centro) e nome das estações
const STATIONS = {
  micro: { x: 505, y: 320, name: "MICROSCÓPIO", radius: 150 },
  tank:  { x: 1685, y: 320, name: "TANQUES", radius: 150 },
  atmo:  { x: 505, y: 975, name: "PAINEL DA ATMOSFERA", radius: 150 },
  probe: { x: 1685, y: 975, name: "SONDA EXTERNA", radius: 160 },
};

const WORLD_W = 2200;
const WORLD_H = 1300;
const PLAYER_R = 22;
const PLAYER_SPEED = 260; // px/s

const player = { x: 1100, y: 655, dir: 1, moving: false };

const keysDown = new Set();
let clickTarget = null; // {x, y} no mundo
/* ------------------------- CONSTRUÇÃO DO MUNDO ------------------------- */

function buildWalls() {
  const holder = $("#walls");
  holder.innerHTML = "";
  const all = state.probeUnlocked ? WALLS : [...WALLS, DOOR_WALL];
  all.forEach(([x, y, w, h]) => {
    const div = document.createElement("div");
    div.className = "wall";
    div.style.left = x + "px";
    div.style.top = y + "px";
    div.style.width = w + "px";
    div.style.height = h + "px";
    holder.appendChild(div);
  });
}

/* colisão: círculo do jogador vs retângulos [x,y,w,h] */
function collidesWall(px, py) {
  const all = state.probeUnlocked ? WALLS : [...WALLS, DOOR_WALL];
  for (const [x, y, w, h] of all) {
    const cx = Math.max(x, Math.min(px, x + w));
    const cy = Math.max(y, Math.min(py, y + h));
    const dx = px - cx;
    const dy = py - cy;
    if (dx * dx + dy * dy < PLAYER_R * PLAYER_R) return true;
  }
  return false;
}

/* ------------------------- CÂMERA ------------------------- */

const cam = { scale: 1, ox: 0, oy: 0 };

function updateCamera() {
  const vp = $("#viewport");
  const vw = vp.clientWidth;
  const vh = vp.clientHeight;
  // zoom para caber o mundo inteiro (com folga mínima)
  cam.scale = Math.min(vw / WORLD_W, vh / WORLD_H);
  cam.scale = Math.min(cam.scale, 1);
  const sw = WORLD_W * cam.scale;
  const sh = WORLD_H * cam.scale;
  cam.ox = (vw - sw) / 2;
  cam.oy = (vh - sh) / 2;
  const world = $("#world");
  world.style.transform = `translate(${cam.ox}px, ${cam.oy}px) scale(${cam.scale})`;
}

function screenToWorld(clientX, clientY) {
  const vp = $("#viewport");
  const rect = vp.getBoundingClientRect();
  const x = (clientX - rect.left - cam.ox) / cam.scale;
  const y = (clientY - rect.top - cam.oy) / cam.scale;
  return { x, y };
}

/* ------------------------- MOVIMENTO ------------------------- */

let lastStepAt = 0;

function tryMove(dx, dy) {
  // eixo X
  const nx = player.x + dx;
  if (!collidesWall(nx, player.y)) player.x = nx;
  // eixo Y
  const ny = player.y + dy;
  if (!collidesWall(player.x, ny)) player.y = ny;
  // limites do mundo
  player.x = Math.max(PLAYER_R, Math.min(WORLD_W - PLAYER_R, player.x));
  player.y = Math.max(PLAYER_R, Math.min(WORLD_H - PLAYER_R, player.y));
}

function gameLoop(ts) {
  if (!state.running) return;
  const dt = Math.min(0.05, (ts - (gameLoop.last || ts)) / 1000);
  gameLoop.last = ts;

  // pausa enquanto overlay aberto
  if (state.overlayOpen) {
    player.moving = false;
    $("#player").classList.remove("walking");
    requestAnimationFrame(gameLoop);
    return;
  }

  let vx = 0, vy = 0;
  if (keysDown.has("w") || keysDown.has("arrowup")) vy -= 1;
  if (keysDown.has("s") || keysDown.has("arrowdown")) vy += 1;
  if (keysDown.has("a") || keysDown.has("arrowleft")) vx -= 1;
  if (keysDown.has("d") || keysDown.has("arrowright")) vx += 1;

  const viaTeclado = vx !== 0 || vy !== 0;
  if (viaTeclado) clickTarget = null;

  if (!viaTeclado && clickTarget) {
    const tdx = clickTarget.x - player.x;
    const tdy = clickTarget.y - player.y;
    const dist = Math.hypot(tdx, tdy);
    if (dist < 8) {
      clickTarget = null;
    } else {
      vx = tdx / dist;
      vy = tdy / dist;
    }
  }

  const len = Math.hypot(vx, vy);
  player.moving = len > 0;
  const el = $("#player");
  if (player.moving) {
    if (vx !== 0) player.dir = vx > 0 ? 1 : -1;
    tryMove(vx / len * PLAYER_SPEED * dt, vy / len * PLAYER_SPEED * dt);
    el.classList.add("walking");
    // flip do sprite
    const flipped = player.dir < 0;
    const cm = el.querySelector(".crewmate");
    const img = el.querySelector(".player-img");
    if (cm) cm.classList.toggle("flip", flipped);
    if (img) img.classList.toggle("flip", flipped);
    // pisadas sonoras discretas
    if (ts - lastStepAt > 260) { AudioSys.step(); lastStepAt = ts; }
  } else {
    el.classList.remove("walking");
  }

  el.style.transform = `translate(${player.x}px, ${player.y}px)`;

  updateProximity();
  requestAnimationFrame(gameLoop);
}
/* ------------------------- PROXIMIDADE / USAR ------------------------- */

let nearStation = null;

function updateProximity() {
  let found = null;
  for (const [id, st] of Object.entries(STATIONS)) {
    const d = Math.hypot(player.x - st.x, player.y - st.y);
    if (d <= st.radius) { found = id; break; }
  }
  if (found !== nearStation) {
    nearStation = found;
    $$(".station-obj").forEach((s) => s.classList.toggle("near", s.dataset.station === found));
    const btn = $("#use-btn");
    if (found) {
      btn.classList.remove("hidden");
      $("#use-name").textContent = STATIONS[found].name;
    } else {
      btn.classList.add("hidden");
    }
  }
}

function tryUse() {
  if (!nearStation || state.overlayOpen) return;
  const id = nearStation;

  if (id === "probe" && !state.probeUnlocked) {
    AudioSys.error();
    toast("SONDA BLOQUEADA: reúna as Chaves A, B e C primeiro.");
    return;
  }
  AudioSys.click();
  openTask(id);
}

/* ------------------------- OVERLAYS / TAREFAS ------------------------- */

function openTask(id) {
  state.overlayOpen = id;
  $("#task-" + id).classList.add("open");
  $("#use-btn").classList.add("hidden");
  if (id === "probe") startProbe();
}

function closeTask(id) {
  $("#task-" + id).classList.remove("open");
  state.overlayOpen = null;
  // sonda: abortar com o alarme tocando não é permitido via ESC; só pelo botão,
  // que também para o timer se o desfecho já apareceu
  if (id === "probe" && !$("#probe-outcome").classList.contains("hidden")) {
    stopProbeTimer();
  }
}

$$(".btn-close").forEach((b) => {
  b.addEventListener("click", () => {
    AudioSys.click();
    const overlay = b.closest(".task-overlay");
    const id = overlay.id.replace("task-", "");
    // não deixa fechar o clímax antes do desfecho (timer rodando)
    if (id === "probe" && state.timerId) {
      toast("ALARME ATIVO: escolha um protocolo antes de sair!");
      return;
    }
    closeTask(id);
  });
});

/* ------------------------- INPUT ------------------------- */

document.addEventListener("keydown", (e) => {
  const k = e.key.toLowerCase();
  if (["arrowup", "arrowdown", "arrowleft", "arrowright", " "].includes(k)) e.preventDefault();
  if (!state.running) return;
  keysDown.add(k);
  if (k === "e" || k === " ") {
    if (state.overlayOpen) return;
    tryUse();
  }
  if (k === "escape" && state.overlayOpen) {
    const id = state.overlayOpen;
    if (id === "probe" && state.timerId) return; // clímax exige escolha
    closeTask(id);
  }
});

document.addEventListener("keyup", (e) => keysDown.delete(e.key.toLowerCase()));

$("#viewport").addEventListener("click", (e) => {
  if (!state.running || state.overlayOpen) return;
  // clique em estação: se estiver perto, USAR; senão, andar até lá
  const stationBtn = e.target.closest(".station-obj");
  if (stationBtn) {
    const id = stationBtn.dataset.station;
    const st = STATIONS[id];
    if (Math.hypot(player.x - st.x, player.y - st.y) <= st.radius) {
      tryUse();
    } else {
      clickTarget = { x: st.x, y: st.y + st.radius * 0.65 };
      toast("Indo para " + st.name + "… chegue perto e clique USAR.");
    }
    return;
  }
  // clique no chão: andar até o ponto
  const p = screenToWorld(e.clientX, e.clientY);
  if (p.x < 0 || p.y < 0 || p.x > WORLD_W || p.y > WORLD_H) return;
  clickTarget = { x: p.x, y: p.y };
  const marker = document.createElement("div");
  marker.className = "click-marker";
  marker.style.left = p.x + "px";
  marker.style.top = p.y + "px";
  $("#world").appendChild(marker);
  setTimeout(() => marker.remove(), 650);
});

$("#use-btn").addEventListener("click", tryUse);

window.addEventListener("resize", () => { if (state.running) updateCamera(); });
/* ------------------------- CHAVES / TAREFAS ------------------------- */

function allKeys() {
  return state.keys.A && state.keys.B && state.keys.C;
}

function collectKey(letter, taskId) {
  if (state.keys[letter]) return;
  state.keys[letter] = true;
  const slot = $("#slot" + letter);
  slot.classList.add("collected");
  slot.textContent = "CHAVE " + letter + " ✓";
  AudioSys.key();

  // tarefa concluída no HUD e no mapa
  if (taskId) {
    state.tasks[taskId] = true;
    const item = $("#task-item-" + taskId);
    item.classList.add("done");
    item.querySelector(".tick").textContent = "✓";
    const obj = $(`.station-obj[data-station="${taskId}"]`);
    obj.classList.add("done");
    const alert = obj.querySelector(".station-alert");
    alert.classList.add("done");
    alert.textContent = "✓";
  }

  if (allKeys()) unlockProbe();
}

function unlockProbe() {
  state.probeUnlocked = true;
  // porta abre
  const door = $("#door-probe");
  door.classList.remove("locked");
  door.classList.add("open");
  $("#door-sign").textContent = "ABERTA ✓";
  $("#label-probe").classList.add("open");
  buildWalls(); // remove a parede da fechadura da colisão
  // sonda destravada no mapa
  const probeObj = $("#obj-probe");
  probeObj.classList.remove("locked");
  const alert = $("#alert-probe");
  alert.classList.remove("hidden");
  const item = $("#task-item-probe");
  item.classList.add("unlocked");
  item.querySelector(".tick").textContent = "!";
  AudioSys.doorOpen();
  toast("TODAS AS CHAVES COLETADAS! A Sonda foi destravada — entre pela porta verde!", 6000, true);
}

/* ==================== TAREFA 1: MICROSCÓPIO ==================== */

$$(".flask").forEach((flask) => {
  flask.addEventListener("click", () => {
    if (state.keys.A) return;
    const ph = flask.dataset.ph;
    const fb = $("#micro-feedback");
    const photo = $("#shell-photo");

    if (ph === "8.2") {
      photo.classList.add("fixed");
      $("#shell-status").textContent = "STATUS: CONCHA RESTAURADA — CALCIFICAÇÃO RETOMADA ✓";
      setFeedback(fb, "ok",
        "<b>✓ CHAVE DIGITAL A LIBERADA!</b><br>" +
        "Em pH 8.2 (o valor natural pré-industrial do oceano), há carbonato de cálcio (CO₃²⁻) " +
        "disponível em abundância. O Pterópode consegue retirar Ca²⁺ + CO₃²⁻ da água e " +
        "reconstruir sua concha. Espécime estabilizado!");
      AudioSys.success();
      collectKey("A", "micro");
    } else if (ph === "7.8") {
      setFeedback(fb, "err",
        "<b>✗ Ainda ácido demais.</b> pH 7.8 é a projeção da ciência para o ano de 2100 " +
        "se as emissões continuarem — uma acidificação ~170% maior que o pré-industrial. " +
        "A concha ainda se formaria deformada e frágil. Tente outro frasco!");
      AudioSys.error();
    } else {
      photo.classList.add("dissolving");
      setTimeout(() => photo.classList.remove("dissolving"), 1600);
      setFeedback(fb, "err",
        "<b>✗ ERRO CRÍTICO!</b> Nesse pH a alta concentração de íons H⁺ sequestra os íons " +
        "carbonato (CO₃²⁻) para formar bicarbonato. Sem CO₃²⁻ livre, a concha não só para de " +
        "crescer como <b>se dissolve ainda mais rápido</b>. Aumente o pH!");
      AudioSys.error();
    }
  });
});

/* ==================== TAREFA 2: TANQUE ==================== */

$("#btn-co2").addEventListener("click", () => {
  if (state.keys.B) return;
  $("#tank-photo").classList.add("acid", "shake");
  setTimeout(() => $("#tank-photo").classList.remove("shake"), 1600);
  $("#coral-status").textContent = "CONDICIONADO: COLAPSO ÁCIDO";
  $("#coral-status").className = "tank-status bad";
  setFeedback($("#tank-feedback"), "err",
    "<b>✗ Não!</b> O CO₂ dissolvido reage com a água: CO₂ + H₂O → H₂CO₃ (ácido carbônico), " +
    "que se dissocia liberando H⁺. O pH despencou e a água do tanque ficou tóxica para o coral. " +
    "Você acelerou a acidificação! Inverta a lógica: quem remove CO₂ da água?");
  AudioSys.error();
});

$("#btn-o2").addEventListener("click", () => {
  if (state.keys.B) return;
  setFeedback($("#tank-feedback"), "err",
    "<b>✗ Parcial.</b> O oxigênio não reage com o CO₂ dissolvido — ele apenas oxigena a água, " +
    "não remove o carbono nem devolve o pH. O coral continua estressado. Precisamos de algo que " +
    "<b>absorva CO₂</b> ativamente...");
  AudioSys.error();
});

$("#btn-photo").addEventListener("click", () => {
  if (state.keys.B) return;
  $("#grass-status").textContent = "CONDICIONADO: FOTOSSÍNTESE ATIVA ✓";
  $("#grass-status").className = "tank-status good";
  setTimeout(() => {
    $("#tank-photo").classList.remove("acid");
    $("#tank-photo").classList.add("saved");
    $("#coral-status").textContent = "CONDICIONADO: SALVO — pH LOCAL ESTABILIZADO";
    $("#coral-status").className = "tank-status good";
  }, 900);
  setFeedback($("#tank-feedback"), "ok",
    "<b>✓ CHAVE DIGITAL B LIBERADA!</b><br>" +
    "As ervas marinhas e algas realizam fotossíntese: 6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂. " +
    "Elas <b>absorveram o CO₂ dissolvido</b> da água, reduziram a concentração de H⁺ e " +
    "elevaram o pH local — resgatando o coral do tanque vizinho. Ecossistema restaurado!");
  AudioSys.success();
  collectKey("B", "tank");
});
/* ==================== TAREFA 3: ATMOSFERA ==================== */

const GEARS = [
  { id: "energia",   dirty: "⚡ ENERGIA FÓSSEIS", clean: "🌬 ENERGIA EÓLICA",
    why: "Queimar carvão/gás/petróleo lança CO₂ que o oceano absorve (~30% do que emitimos). A eólica emite zero carbono." },
  { id: "desmat",    dirty: "🪓 DESMATAMENTO",    clean: "🌳 REFLORESTAMENTO",
    why: "Florestas queimadas liberam carbono estocado e perdem a capacidade de captar CO₂. Reflorestar devolve o sumidouro natural." },
  { id: "industria", dirty: "🏭 INDÚSTRIA SUJA",  clean: "🌿 MANGUEZAIS & ALGAS",
    why: "Manguezais e algas capturam carbono ('carbono azul') e bufferizam a acidez da costa — berçários naturais de peixes e corais." },
];

let selectedDirty = null;

function buildGears() {
  const dirtyCol = $("#dirty-col");
  const cleanCol = $("#clean-col");
  dirtyCol.innerHTML = "";
  cleanCol.innerHTML = "";
  selectedDirty = null;

  GEARS.forEach((g) => {
    const b = document.createElement("button");
    b.className = "gear dirty";
    b.textContent = g.dirty;
    b.dataset.id = g.id;
    b.addEventListener("click", () => selectDirty(b, g));
    dirtyCol.appendChild(b);
  });

  const shuffled = [...GEARS].sort(() => Math.random() - 0.5);
  shuffled.forEach((g) => {
    const b = document.createElement("button");
    b.className = "gear clean";
    b.textContent = g.clean;
    b.dataset.id = g.id;
    b.addEventListener("click", () => tryClean(b, g));
    cleanCol.appendChild(b);
  });
}

function selectDirty(btn, g) {
  if (btn.classList.contains("done")) return;
  AudioSys.click();
  $$(".gear.dirty").forEach((b) => b.classList.remove("selected"));
  btn.classList.add("selected");
  selectedDirty = g;
  setFeedback($("#atmo-feedback"), "info",
    "Selecionado: <b>" + g.dirty + "</b>. Agora clique na alternativa limpa correspondente →");
}

function tryClean(btn, g) {
  if (btn.classList.contains("done")) return;
  const fb = $("#atmo-feedback");

  if (!selectedDirty) {
    setFeedback(fb, "info", "Primeiro clique numa engrenagem <b>poluidora</b> (coluna vermelha).");
    AudioSys.error();
    return;
  }

  if (selectedDirty.id === g.id) {
    const dirtyBtn = $$(".gear.dirty").find((b) => b.dataset.id === g.id);
    dirtyBtn.classList.add("done");
    dirtyBtn.classList.remove("selected");
    btn.classList.add("done");
    selectedDirty = null;
    AudioSys.success();
    setFeedback(fb, "ok", "<b>✓ Substituição realizada:</b> " + g.why);
    checkAtmoSolved();
  } else {
    btn.classList.add("shake");
    setTimeout(() => btn.classList.remove("shake"), 450);
    setFeedback(fb, "err",
      "<b>✗ Essas peças não se encaixam.</b> Pense em qual problema de emissão cada " +
      "alternativa limpa resolve de verdade.");
    AudioSys.error();
  }
}

function checkAtmoSolved() {
  const done = $$(".gear.clean.done").length;
  if (done === GEARS.length) {
    $("#graph-photo").classList.add("solved");
    $("#graph-caption").textContent = "EMISSÕES ESTABILIZADAS ✓ — pH DO OCEANO PAROU DE CAIR";
    setFeedback($("#atmo-feedback"), "ok",
      "<b>✓ CHAVE DIGITAL C LIBERADA!</b><br>" +
      "Com energia limpa, florestas restauradas e manguezais protegidos, as emissões de CO₂ " +
      "estabilizam. Sem o excesso de CO₂ entrando no mar, a concentração de H⁺ para de subir " +
      "e o pH do oceano deixa de cair. A linha vermelha do gráfico foi contida!");
    AudioSys.success();
    collectKey("C", "atmo");
  }
}

buildGears();

/* ==================== CLÍMAX: SONDA EXTERNA ==================== */

const OUTCOMES = {
  A: {
    win: false,
    title: "PROTOCOLO A — FALHOU",
    text: "Os alcalinizantes neutralizaram a acidez <b>temporariamente</b>, mas a massiva " +
      "injeção química alterou a salinidade e a temperatura da água, causando <b>choque térmico " +
      "e destruição química</b> da fauna sensível. O pH recai em semanas porque a causa — o CO₂ — " +
      "continua entrando no mar. Tratar o sintoma não cura a doença.",
  },
  C: {
    win: false,
    title: "PROTOCOLO C — FALHOU",
    text: "Os corais modificados resistiram, mas as espécies <b>não modificadas da cadeia " +
      "alimentar</b> — plâncton, peixes, crustáceos — colapsaram sem conseguir se adaptar tão " +
      "rápido. O recife virou um deserto genético: poucos sobreviventes e nenhum ecossistema. " +
      "Engenharia genética ignora a causa e arruína a biodiversidade.",
  },
  TIMEOUT: {
    win: false,
    title: "TEMPO ESGOTADO — COLAPSO",
    text: "O cronômetro zerou. Sem intervenção, o pH continuou caindo, o carbonato de cálcio " +
      "desapareceu da água e os corais se dissolveram. O recife deixou de existir. Missão falhou " +
      "— mas vocês podem tentar novamente.",
  },
  B: {
    win: true,
    title: "VITÓRIA — RECIFE SALVO!",
    text: "As Áreas de Proteção Marinha permitiram que <b>manguezais e algas absorvessem o CO₂ " +
      "excessivo</b>, elevando o pH local, enquanto a <b>redução global de emissões</b> atacou a " +
      "causa raiz do problema. O carbonato de cálcio voltou a ficar disponível, os corais " +
      "recalcificaram e o recife voltou a se colorir.<br><br>" +
      "<b>Lembrete da reportagem:</b> desde a era pré-industrial o pH do mar já caiu 0.1 unidade — " +
      "um aumento de 30% na acidez. Sem corte de emissões e com descarte responsável de resíduos, " +
      "a projeção para 2100 é de queda de 0.3 unidades (~170% mais ácido). Tratar o lixo e reduzir " +
      "carbono não é opcional: é sobrevivência humana.",
  },
};

const OUTCOME_IMGS = {
  A: "img/outcome-protocolo-a.jpeg",
  B: "img/outcome-vitoria.jpeg",
  C: "img/outcome-protocolo-c.jpeg",
  TIMEOUT: "img/probe-reef.jpeg",
};
function startProbe() {
  state.timeLeft = 30;
  $("#probe-alarm-mode").classList.remove("hidden");
  $("#probe-outcome").classList.add("hidden");
  updateTimerDisplay();
  AudioSys.startAlarm();

  clearInterval(state.timerId);
  state.timerId = setInterval(() => {
    state.timeLeft--;
    updateTimerDisplay();
    if (state.timeLeft <= 0) {
      stopProbeTimer();
      showOutcome("TIMEOUT");
    }
  }, 1000);
}

function stopProbeTimer() {
  clearInterval(state.timerId);
  state.timerId = null;
  AudioSys.stopAlarm();
}

function updateTimerDisplay() {
  const t = $("#timer");
  const s = String(state.timeLeft).padStart(2, "0");
  t.textContent = "00:" + s;
  t.classList.toggle("danger", state.timeLeft <= 10);
}

function showOutcome(which) {
  stopProbeTimer();
  const o = OUTCOMES[which];
  const card = $("#outcome-card");
  card.classList.toggle("win", o.win);
  card.classList.toggle("lose", !o.win);
  $("#outcome-title").textContent = o.title;
  $("#outcome-text").innerHTML = o.text;
  const img = $("#outcome-img");
  img.src = OUTCOME_IMGS[which] || OUTCOME_IMGS.TIMEOUT;
  img.alt = o.title;
  $("#probe-alarm-mode").classList.add("hidden");
  $("#probe-outcome").classList.remove("hidden");

  if (o.win) {
    AudioSys.success();
    setTimeout(() => AudioSys.key(), 500);
    // marca a tarefa da sonda como concluída
    const item = $("#task-item-probe");
    item.classList.remove("unlocked");
    item.classList.add("done");
    item.querySelector(".tick").textContent = "✓";
    const alert = $("#alert-probe");
    alert.classList.add("done");
    alert.textContent = "✓";
    $("#obj-probe").classList.add("done");
  } else {
    AudioSys.error();
  }
}

$$(".protocol").forEach((p) => {
  p.addEventListener("click", () => {
    AudioSys.click();
    showOutcome(p.dataset.protocol);
  });
});

$("#outcome-retry").addEventListener("click", () => {
  AudioSys.click();
  startProbe();
});

$("#outcome-hub").addEventListener("click", () => {
  AudioSys.click();
  stopProbeTimer();
  closeTask("probe");
  toast("De volta ao mapa. Reavalie a situação com a turma!");
});

/* ==================== INICIALIZAÇÃO ==================== */

$("#start-btn").addEventListener("click", () => {
  AudioSys.startAmbient();
  AudioSys.click();
  $("#boot").classList.remove("active");
  $("#game").classList.add("active");
  state.running = true;
  buildWalls();
  updateCamera();
  $("#player").style.transform = `translate(${player.x}px, ${player.y}px)`;
  requestAnimationFrame(gameLoop);
  toast("Chegue perto de um objeto brilhante e clique USAR (ou tecla E)!", 5000);
});

$("#mute-btn").addEventListener("click", () => {
  AudioSys.setMuted(!AudioSys.muted);
  const btn = $("#mute-btn");
  btn.textContent = AudioSys.muted ? "🔇 MUDO" : "🔊 SOM";
  btn.classList.toggle("muted", AudioSys.muted);
});






