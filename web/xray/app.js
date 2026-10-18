// ============================================================
//  loki_prescriptions | web/xray/app.js
//  Módulo de Raio-X & Monitor Multiparamétrico de Sinais Vitais
// ============================================================

'use strict';

const IS_DUI     = window.location.search.includes('dui=true');
const IS_MONITOR = window.location.search.includes('monitor=true');

const app          = document.getElementById('app');
const vitalsApp    = document.getElementById('vitals-app');
const xrayImage    = document.getElementById('xray-image');
const scanningBar  = document.getElementById('scanning-bar');
const medOverlay   = document.getElementById('medical-overlay');
const boneResults  = document.getElementById('bone-results');
const noDataMsg    = document.getElementById('no-data-msg');
const patientName  = document.getElementById('patient-name');
const patientId    = document.getElementById('patient-id');
const cursor       = document.getElementById('cursor');
const printBtn     = document.getElementById('print-btn');
const closeBtn     = document.getElementById('btn-close-window');

// Mapeamento das imagens radiológicas por região anatômica
const XRAY_IMAGES = {
    head:      { healthy: 'assets/head-healthy.png',       broken: 'assets/head-broken.png' },
    chest:     { healthy: 'assets/chest-healthy.png',      broken: 'assets/chest-broken.png' },
    left_arm:  { healthy: 'assets/left-hand-healthy.png',  broken: 'assets/left-hand-broken.png' },
    right_arm: { healthy: 'assets/right-hand-healthy.png', broken: 'assets/right-hand-broken.png' },
    left_leg:  { healthy: 'assets/left-leg-healthy.png',   broken: 'assets/left-leg-broken.png' },
    right_leg: { healthy: 'assets/right-leg-healthy.png',  broken: 'assets/right-leg-broken.png' },
};

let currentBone = 'head';
let lastResults  = null;
let currentPatientData = null;

// Relógio do Sistema
function updateClock() {
    const now     = new Date();
    const timeStr = now.toLocaleTimeString('pt-BR');
    const dateStr = now.toLocaleDateString('pt-BR');

    const elTime = document.getElementById('overlay-time');
    const elDate = document.getElementById('overlay-date');
    if (elTime) elTime.textContent = timeStr;
    if (elDate) elDate.textContent = dateStr;

    const elClock       = document.getElementById('vitals-clock');
    const elFooterClock = document.getElementById('vitals-footer-clock');
    if (elClock)       elClock.textContent       = timeStr;
    if (elFooterClock) elFooterClock.textContent = timeStr;
}

setInterval(updateClock, 1000);
updateClock();

// Seleção de região anatômica
document.querySelectorAll('.bone-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.bone-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentBone = btn.dataset.bone;
        if (lastResults) updateXrayView(currentBone);
    });
});

// Botão Iniciar Varredura (Scan)
document.getElementById('scan-btn').addEventListener('click', () => {
    if (!patientName || patientName.textContent === 'NÃO IDENTIFICADO') {
        boneResults.innerHTML = '<p style="color:#e74c3c; font-weight:bold;">ERRO: Nenhum paciente detectado no leito radiológico.</p>';
        return;
    }
    triggerScan();
});

// Botão Imprimir Laudo
if (printBtn) {
    printBtn.addEventListener('click', () => {
        if (!lastResults || !currentPatientData) return;
        fetch('https://loki_prescriptions/printXrayReport', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                patient: currentPatientData,
                results: lastResults
            })
        });
    });
}

// Fechamento de janela
function closeWindow() {
    fetch('https://loki_prescriptions/closeUI', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({}),
    });
}

if (closeBtn) {
    closeBtn.addEventListener('click', closeWindow);
}

window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        closeWindow();
    }
});

function triggerScan() {
    startScanning();
    fetch('https://loki_prescriptions/syncInteraction', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ type: 'startScan' }),
    });
}

function startScanning() {
    lastResults = null;
    clearDisplay();
    scanningBar.style.display = 'block';
    noDataMsg.textContent = 'VARREDURA RADIOLÓGICA EM ANDAMENTO...';
    boneResults.innerHTML = '<p class="status-text">Iniciando feixe de raios-X digital...<br>Calibrando densidade óssea...<br>Examinando microfraturas e trauma...</p>';
    if (printBtn) printBtn.style.display = 'none';
}

function clearDisplay() {
    xrayImage.style.display   = 'none';
    scanningBar.style.display = 'none';
    medOverlay.style.display  = 'none';
    noDataMsg.style.display   = 'block';
    noDataMsg.textContent     = 'SEM SINAL DE ENTRADA';
}

function showResults(injuries) {
    lastResults = injuries || [];
    scanningBar.style.display = 'none';
    noDataMsg.style.display   = 'none';
    medOverlay.style.display  = 'block';
    if (printBtn) printBtn.style.display = 'block';

    updateXrayView(currentBone);

    const parts = [
        { key: 'head',      label: 'Crânio / Mandíbula' },
        { key: 'chest',     label: 'Tórax / Arcos Costais' },
        { key: 'left_arm',  label: 'Membro Sup. Esquerdo' },
        { key: 'right_arm', label: 'Membro Sup. Direito' },
        { key: 'left_leg',  label: 'Membro Inf. Esquerdo' },
        { key: 'right_leg', label: 'Membro Inf. Direito' },
    ];

    let html = '<div style="margin-top:4px;">';
    parts.forEach(part => {
        const injury = lastResults.find(i => i.part === part.key);
        let statusCls = injury ? 'broken' : 'ok';
        let text = 'ESTRUTURA ÍNTEGRA';
        if (injury) {
            if (injury.type === 'fracture') { text = 'FRATURA IDENTIFICADA'; }
            else if (injury.type === 'bullet') { text = 'CORPO ESTRANHO (PROJÉTIL)'; }
        }
        html += `<div class="injury-row">
            <span class="injury-label">${part.label}</span>
            <span class="injury-status ${statusCls}">${text}</span>
        </div>`;
    });
    html += '</div>';
    boneResults.innerHTML = html;
}

function updateXrayView(bone) {
    const imgs = XRAY_IMAGES[bone];
    if (!imgs) return;
    const isBroken = lastResults && lastResults.some(i => i.part === bone && i.type === 'fracture');
    xrayImage.src           = isBroken ? imgs.broken : imgs.healthy;
    xrayImage.style.display = 'block';
}

// Mensagens recebidas do client Lua
window.addEventListener('message', e => {
    const data = e.data;
    if (!data || !data.type) return;

    switch (data.type) {
        case 'show':
            if (IS_MONITOR) {
                vitalsApp.style.display = data.state ? 'flex' : 'none';
            } else {
                app.style.display = data.state ? 'flex' : 'none';
            }
            break;

        case 'setPatient':
            currentPatientData = data.patient;
            if (IS_MONITOR) {
                setMonitorPatient(data.patient);
            } else {
                setXrayPatient(data.patient);
            }
            break;

        case 'scanResults':
            showResults(data.injuries);
            break;

        case 'dui_cursor':
            if (data.show) {
                cursor.style.display = 'block';
                cursor.style.left    = (data.u * 100) + '%';
                cursor.style.top     = (data.v * 100) + '%';
            } else {
                cursor.style.display = 'none';
            }
            break;

        case 'updateVitals':
            if (IS_MONITOR) updateMonitorVitals(data);
            break;
    }
});

function setXrayPatient(patient) {
    if (patient) {
        patientName.textContent = String(patient.name || 'Paciente').toUpperCase();
        patientId.textContent   = 'ID: ' + String(patient.id || 'N/A');
        clearDisplay();
        boneResults.innerHTML = '<p class="status-text">Paciente posicionado no leito. Selecione a região anatômica e inicie a varredura.</p>';
    } else {
        patientName.textContent = 'NÃO IDENTIFICADO';
        patientId.textContent   = 'N/A';
        clearDisplay();
        boneResults.innerHTML = '<p class="status-text">Aguardando posicionamento de um paciente no leito radiológico...</p>';
    }
}

// Helpers do Monitor Multiparamétrico
let ecgActive    = false;
let monitorPulse = 0;
let monitorSpo2  = 0;

function setMonitorPatient(patient) {
    const elName = document.getElementById('vitals-name');
    const elSid  = document.getElementById('vitals-sid');
    if (patient) {
        if (elName) elName.textContent = String(patient.name || 'Paciente').toUpperCase();
        if (elSid)  elSid.textContent  = 'LEITO SID: ' + String(patient.id || 'N/A');
        setMonitorStatus('status-watch', 'PACIENTE MONITORADO');
    } else {
        if (elName) elName.textContent = 'NENHUM PACIENTE CONECTADO';
        if (elSid)  elSid.textContent  = 'LEITO SID: N/A';
        resetMonitorVitals();
        setMonitorStatus('status-watch', 'AGUARDANDO ELETRODOS...');
    }
}

function updateMonitorVitals(data) {
    const pulse = Number(data.pulse || 0);
    const o2    = Number(data.o2    || 0);

    monitorPulse = pulse;
    monitorSpo2  = o2;

    const elPulse = document.getElementById('pulse-val');
    const elO2    = document.getElementById('o2-val');
    const elBp    = document.getElementById('bp-val');
    if (elPulse) elPulse.textContent = String(pulse);
    if (elO2)    elO2.textContent    = String(o2);
    if (elBp)    elBp.textContent    = data.bp || '120/80';

    if (pulse > 0) {
        ecgActive = true;
        vitalsApp.classList.add('vitals-active');
        if (pulse < 40 || pulse > 130 || o2 < 90) {
            setMonitorStatus('status-alert', 'ALARME CRÍTICO — REAVALIAR PACIENTE IMEDIATAMENTE');
        } else if (pulse < 55 || pulse > 110 || o2 < 94) {
            setMonitorStatus('status-watch', 'ATENÇÃO — PARÂMETROS HEMODINÂMICOS INSTÁVEIS');
        } else {
            setMonitorStatus('status-ok', 'ESTÁVEL — SINAIS VITAIS NORMAIS');
        }
    } else {
        resetMonitorVitals();
        setMonitorStatus('status-watch', 'PACIENTE SEM SINAL CARDÍACO DETECTADO');
    }
}

function resetMonitorVitals() {
    ecgActive    = false;
    monitorPulse = 0;
    monitorSpo2  = 0;
    vitalsApp.classList.remove('vitals-active');
    const elPulse = document.getElementById('pulse-val');
    const elO2    = document.getElementById('o2-val');
    const elBp    = document.getElementById('bp-val');
    if (elPulse) elPulse.textContent = '0';
    if (elO2)    elO2.textContent    = '0';
    if (elBp)    elBp.textContent    = '0/0';
}

function setMonitorStatus(level, text) {
    vitalsApp.classList.remove('status-ok', 'status-watch', 'status-alert');
    vitalsApp.classList.add(level);
    const el = document.getElementById('vitals-status');
    if (el) el.textContent = text;
}

// Traçado dinâmico em Canvas do ECG
let waveHrCanvas, waveHrCtx;
let waveSpo2Canvas, waveSpo2Ctx;
let waveBpCanvas, waveBpCtx;
let waveX = 0, lastX = 0;
let lastYHr = 0, lastYSpo2 = 0, lastYBp = 0;
let smoothHrY = 0, smoothSpo2Y = 0, smoothBpY = 0;
let hrPhase = 0, spo2Phase = 0, bpPhase = 0;
let lastFrameTs = 0;

function initECG() {
    waveHrCanvas   = document.getElementById('wave-hr');
    waveSpo2Canvas = document.getElementById('wave-spo2');
    waveBpCanvas   = document.getElementById('wave-bp');
    if (!waveHrCanvas || !waveSpo2Canvas || !waveBpCanvas) return;

    waveHrCtx   = waveHrCanvas.getContext('2d');
    waveSpo2Ctx = waveSpo2Canvas.getContext('2d');
    waveBpCtx   = waveBpCanvas.getContext('2d');

    const resize = () => {
        [waveHrCanvas, waveSpo2Canvas, waveBpCanvas].forEach(c => {
            c.width  = c.offsetWidth;
            c.height = c.offsetHeight;
        });
        lastYHr     = waveHrCanvas.height   / 2;
        lastYSpo2   = waveSpo2Canvas.height / 2;
        lastYBp     = waveBpCanvas.height   / 2;
        smoothHrY   = lastYHr;
        smoothSpo2Y = lastYSpo2;
        smoothBpY   = lastYBp;
    };

    window.addEventListener('resize', resize);
    resize();
    requestAnimationFrame(drawECG);
}

function drawECG() {
    if (!waveHrCtx) return;

    const w   = waveHrCanvas.width;
    const now = performance.now();
    const dt  = lastFrameTs > 0 ? Math.min(50, now - lastFrameTs) : 16.67;
    lastFrameTs = now;

    if (w <= 0) { requestAnimationFrame(drawECG); return; }

    const trace = (ctx, canvas, color, curY, prevY) => {
        ctx.clearRect(waveX, 0, 20, canvas.height);
        ctx.strokeStyle = color;
        ctx.lineWidth   = 2.5;
        ctx.lineJoin    = 'round';
        ctx.lineCap     = 'round';
        ctx.shadowBlur  = 4;
        ctx.shadowColor = color;
        ctx.beginPath();
        ctx.moveTo(lastX, prevY);
        ctx.lineTo(waveX, curY);
        ctx.stroke();
    };

    lastX  = waveX;
    waveX += 2;

    if (waveX > w) {
        waveX = 0; lastX = 0;
        waveHrCtx.clearRect(0, 0, waveHrCanvas.width, waveHrCanvas.height);
        waveSpo2Ctx.clearRect(0, 0, waveSpo2Canvas.width, waveSpo2Canvas.height);
        waveBpCtx.clearRect(0, 0, waveBpCanvas.width, waveBpCanvas.height);
        lastYHr = waveHrCanvas.height / 2;
        lastYSpo2 = waveSpo2Canvas.height / 2;
        lastYBp = waveBpCanvas.height / 2;
        smoothHrY = lastYHr; smoothSpo2Y = lastYSpo2; smoothBpY = lastYBp;
    }

    // ECG (Verde)
    const hrMid = waveHrCanvas.height / 2;
    let tHr = hrMid;
    if (ecgActive && monitorPulse > 0) {
        const beatMs = Math.max(360, Math.floor(60000 / monitorPulse));
        hrPhase = (hrPhase + dt / beatMs) % 1;
        const g = (x, mu, s) => Math.exp(-0.5 * ((x - mu) / s) ** 2);
        const ecg = 0.015 * Math.sin(2 * Math.PI * hrPhase)
            + 0.12 * g(hrPhase, 0.18, 0.030)
            - 0.16 * g(hrPhase, 0.39, 0.012)
            + 1.05 * g(hrPhase, 0.42, 0.010)
            - 0.28 * g(hrPhase, 0.45, 0.013)
            + 0.30 * g(hrPhase, 0.70, 0.060);
        tHr = hrMid - ecg * 42 + (Math.random() * 0.6 - 0.3);
    } else {
        hrPhase = 0;
        tHr = hrMid + (Math.random() * 2 - 1);
    }
    smoothHrY = smoothHrY * 0.72 + tHr * 0.28;
    trace(waveHrCtx, waveHrCanvas, '#58e19f', smoothHrY, lastYHr);
    lastYHr = smoothHrY;

    // SpO2 (Azul)
    const spo2Mid = waveSpo2Canvas.height / 2;
    let tSpo2 = spo2Mid;
    if (ecgActive && monitorPulse > 0) {
        const beatMs = Math.max(380, Math.floor(60000 / Math.max(45, monitorPulse - 3)));
        spo2Phase = (spo2Phase + dt / beatMs) % 1;
        const amp   = monitorSpo2 > 0 ? Math.max(8, Math.min(18, monitorSpo2 - 82)) : 10;
        const rise  = Math.sin(Math.PI * Math.min(1, spo2Phase * 1.25));
        const notch = spo2Phase > 0.46 && spo2Phase < 0.56 ? 3 : 0;
        tSpo2 = spo2Mid + 5 - rise * amp + notch + (Math.random() * 0.5 - 0.25);
    } else {
        spo2Phase = 0;
        tSpo2 = spo2Mid + (Math.random() * 2 - 1);
    }
    smoothSpo2Y = smoothSpo2Y * 0.68 + tSpo2 * 0.32;
    trace(waveSpo2Ctx, waveSpo2Canvas, '#6ab7ff', smoothSpo2Y, lastYSpo2);
    lastYSpo2 = smoothSpo2Y;

    // Pressão Arterial (Amarelo)
    const bpMid = waveBpCanvas.height / 2;
    let tBp = bpMid;
    if (ecgActive && monitorPulse > 0) {
        const beatMs = Math.max(360, Math.floor(60000 / monitorPulse));
        bpPhase = (bpPhase + dt / beatMs) % 1;
        const rise = Math.sin(Math.PI * Math.min(1, bpPhase * 1.4));
        tBp = bpMid + 4 - rise * 14 + (Math.random() * 0.4 - 0.2);
    } else {
        bpPhase = 0;
        tBp = bpMid + (Math.random() * 2 - 1);
    }
    smoothBpY = smoothBpY * 0.70 + tBp * 0.30;
    trace(waveBpCtx, waveBpCanvas, '#ffe066', smoothBpY, lastYBp);
    lastYBp = smoothBpY;

    requestAnimationFrame(drawECG);
}

// Exibição inicial (DUI / Monitores)
if (IS_DUI) {
    if (IS_MONITOR) {
        vitalsApp.style.display = 'flex';
        initECG();
    } else {
        app.style.display = 'flex';
    }
}
