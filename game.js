/* ============================================================
   PROJETO ABISMO — Registro 8.1 — lógica do jogo
   Áudio 100% sintetizado via Web Audio API (sem arquivos externos).
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

  // "bip" de clique
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

  // som de erro (descida áspera)
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

  // arpejo de sucesso
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

  // "coletar chave": brilho agudo
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

  // sonar (ping ao voltar ao hub)
  function sonar() {
    ensure();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = "sine";
    o.frequency.setValueAtTime(1200, ctx.currentTime);
    g.gain.setValueAtTime(0.15, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.9);
    o.connect(g); g.connect(master);
    o.start(); o.stop(ctx.currentTime + 0.95);
  }

  // alarme contínuo da sonda (dois tons alternados)
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
    lfo.frequency.value = 4; // 4 alternâncias por segundo
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

  // drone ambiente + bolhas aleatórias
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

    // bolhas periódicas
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

  return { click, error, success, key, sonar, startAlarm, stopAlarm, startAmbient, setMuted,
           get muted() { return muted; } };
})();
/* ------------------------- ESTADO ------------------------- */

const state = {
  keys: { A: false, B: false, C: false },
  current: "boot",
  probeStarted: false,
  timerId: null,
  timeLeft: 30,
};

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => Array.from(document.querySelectorAll(sel));

/* ------------------------- NAVEGAÇÃO ------------------------- */

function showScreen(id) {
  $$(".screen").forEach((s) => s.classList.remove("active"));
  const el = document.getElementById(id);
  if (el) el.classList.add("active");
  state.current = id;

  // efeitos de entrada
  if (id === "hub") {
    AudioSys.sonar();
    refreshHub();
  }
  // (re)inicia o clímax apenas se o desfecho ainda não foi mostrado
  if (id === "st-probe" && allKeys() &&
      $("#probe-outcome").classList.contains("hidden")) {
    startProbe();
  }
  if (id !== "st-probe") {
    stopProbeTimer();
  }
}

function allKeys() {
  return state.keys.A && state.keys.B && state.keys.C;
}

function collectKey(letter) {
  if (state.keys[letter]) return; // já coletada
  state.keys[letter] = true;
  const slot = document.getElementById("slot" + letter);
  slot.classList.add("collected");
  slot.textContent = "CHAVE " + letter + " ✓";
  AudioSys.key();
  refreshHub();
}

function refreshHub() {
  const hsMicro = $(".hs-micro");
  const hsTank = $(".hs-tank");
  const hsAtmo = $(".hs-atmo");
  const hsProbe = $("#hotspot-probe");

  hsMicro.classList.toggle("solved", state.keys.A);
  hsTank.classList.toggle("solved", state.keys.B);
  hsAtmo.classList.toggle("solved", state.keys.C);
  hsProbe.classList.toggle("locked", !allKeys());

  if (allKeys()) {
    hubMsg("TODAS AS CHAVES COLETADAS! A Sonda Externa foi destravada. Bom sorte, agente.", 6000);
  }
}

let hubMsgTimeout = null;
function hubMsg(text, ms = 4000) {
  const box = $("#hub-msg");
  box.textContent = text;
  box.classList.add("show");
  clearTimeout(hubMsgTimeout);
  hubMsgTimeout = setTimeout(() => box.classList.remove("show"), ms);
}

/* botões de voltar + hotspots */
$$(".btn-back").forEach((b) => b.addEventListener("click", () => {
  AudioSys.click();
  showScreen("hub");
}));

$$(".hotspot").forEach((h) => h.addEventListener("click", () => {
  const target = h.dataset.target;
  if (target === "st-probe" && !allKeys()) {
    AudioSys.error();
    hubMsg("SONDA BLOQUEADA: reúna as Chaves A, B e C primeiro.");
    return;
  }
  AudioSys.click();
  showScreen(target);
}));

/* botão de som */
$("#mute-btn").addEventListener("click", () => {
  AudioSys.setMuted(!AudioSys.muted);
  const btn = $("#mute-btn");
  btn.textContent = AudioSys.muted ? "🔇 MUDO" : "🔊 SOM";
  btn.classList.toggle("muted", AudioSys.muted);
});

/* helpers de feedback */
function setFeedback(el, kind, html) {
  el.className = "feedback show " + kind;
  el.innerHTML = html;
}

/* ==================== ENIGMA 1: MICROSCÓPIO ==================== */

$$(".flask").forEach((flask) => {
  flask.addEventListener("click", () => {
    if (state.keys.A) return; // já resolvido
    const ph = flask.dataset.ph;
    const fb = $("#micro-feedback");
    const photo = $("#shell-photo");

    if (ph === "8.2") {
      // CORRETO — pH oceânico pré-industrial
      photo.classList.add("fixed");
      $("#shell-status").textContent = "STATUS: CONCHA RESTAURADA — CALCIFICAÇÃO RETOMADA ✓";
      setFeedback(fb, "ok",
        "<b>✓ CHAVE DIGITAL A LIBERADA!</b><br>" +
        "Em pH 8.2 (o valor natural pré-industrial do oceano), há carbonato de cálcio (CO₃²⁻) " +
        "disponível em abundância. O Pterópode consegue retirar Ca²⁺ + CO₃²⁻ da água e " +
        "reconstruir sua concha. Espécime estabilizado!");
      AudioSys.success();
      collectKey("A");
    } else if (ph === "7.8") {
      // erro "quase"
      setFeedback(fb, "err",
        "<b>✗ Ainda ácido demais.</b> pH 7.8 é a projeção da ciência para o ano de 2100 " +
        "se as emissões continuarem — uma acidificação ~170% maior que o pré-industrial. " +
        "A concha ainda se formaria deformada e frágil. Tente outro frasco!");
      AudioSys.error();
    } else {
      // erro grave — concha se dissolve
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
/* ==================== ENIGMA 2: TANQUE ==================== */

$("#btn-co2").addEventListener("click", () => {
  if (state.keys.B) return;
  const fb = $("#tank-feedback");
  $("#tank-photo").classList.add("acid", "shake");
  setTimeout(() => $("#tank-photo").classList.remove("shake"), 1600);
  $("#coral-status").textContent = "CONDICIONADO: COLAPSO ÁCIDO";
  $("#coral-status").className = "tank-status bad";
  setFeedback(fb, "err",
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
  const fb = $("#tank-feedback");
  $("#grass-status").textContent = "CONDICIONADO: FOTOSSÍNTESE ATIVA ✓";
  $("#grass-status").className = "tank-status good";
  setTimeout(() => {
    $("#tank-photo").classList.remove("acid");
    $("#tank-photo").classList.add("saved");
    $("#coral-status").textContent = "CONDICIONADO: SALVO — pH LOCAL ESTABILIZADO";
    $("#coral-status").className = "tank-status good";
  }, 900);
  setFeedback(fb, "ok",
    "<b>✓ CHAVE DIGITAL B LIBERADA!</b><br>" +
    "As ervas marinhas e algas realizam fotossíntese: 6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂. " +
    "Elas <b>absorveram o CO₂ dissolvido</b> da água, reduziram a concentração de H⁺ e " +
    "elevaram o pH local — resgatando o coral do tanque vizinho. Ecossistema restaurado!");
  AudioSys.success();
  collectKey("B");
});
/* ==================== ENIGMA 3: ATMOSFERA ==================== */

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

  // embaralha as limpas para virar um verdadeiro puzzle de conexão
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
    collectKey("C");
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
      "desapareceu da água e os corais se dissolviram. O recife deixou de existir. Missão falhou " +
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

function startProbe() {
  state.probeStarted = true;
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

const OUTCOME_IMGS = {
  A: "img/outcome-protocolo-a.jpeg",
  B: "img/outcome-vitoria.jpeg",
  C: "img/outcome-protocolo-c.jpeg",
  TIMEOUT: "img/probe-reef.jpeg",
};

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

  // some com o ".hidden" herdado do display flex
  $("#probe-outcome").style.display = "flex";

  if (o.win) {
    AudioSys.success();
    setTimeout(() => AudioSys.key(), 500);
  } else {
    AudioSys.error();
  }
}

$$(".protocol").forEach((p) => {
  p.addEventListener("click", () => {
    const proto = p.dataset.protocol;
    AudioSys.click();
    showOutcome(proto);
  });
});

$("#outcome-retry").addEventListener("click", () => {
  AudioSys.click();
  startProbe(); // reinicia cronômetro + alarme
});

$("#outcome-hub").addEventListener("click", () => {
  AudioSys.click();
  showScreen("hub");
});

/* ==================== INICIALIZAÇÃO ==================== */

$("#start-btn").addEventListener("click", () => {
  AudioSys.startAmbient();
  AudioSys.click();
  showScreen("hub");
  hubMsg("Clique nos objetos do laboratório. A sala decide em voz alta!");
});

// estado inicial da sonda no hub
refreshHub();




