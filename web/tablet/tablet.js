/* ==========================================================================
   LOS SANTOS MEDICAL CENTER - CLINICAL EHR ENTERPRISE JAVASCRIPT
   Engine for vp_tablet native iframe embed
   ========================================================================== */

// Clinical State
const state = {
  activeTab: 'chart',
  patient: {
    name: 'Vinicius Albuquerque',
    cid: 'CIT-7532',
    age: 32,
    gender: 'Masculino',
    bloodType: 'O-',
    allergies: ['Penicilina', 'Morfina', 'Asma'],
    hr: 78,
    bp: '120/80',
    spo2: 98,
    temp: 36.6
  },
  rxList: [
    { label: 'Paracetamol 750mg', item: 'paracetamol', dosage: '1 comp de 8 em 8h após refeição', amount: 2, cost: 30 }
  ],
  pacs: {
    study: 'chest',
    filter: 'standard',
    zoom: 1
  }
};

// 1. Tab Navigation
function switchTab(tabId) {
  state.activeTab = tabId;
  document.querySelectorAll('.nav-tab').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === tabId);
  });
  document.querySelectorAll('.tab-pane').forEach(pane => {
    pane.classList.toggle('active', pane.id === `tab-${tabId}`);
  });
}

document.querySelectorAll('.nav-tab').forEach(btn => {
  btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

// 2. Real-time Clock
function updateClock() {
  const clockEl = document.getElementById('ehr-live-clock');
  if (!clockEl) return;
  const now = new Date();
  const d = String(now.getDate()).padStart(2, '0');
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const y = now.getFullYear();
  const h = String(now.getHours()).padStart(2, '0');
  const min = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  clockEl.textContent = `${d}/${m}/${y} - ${h}:${min}:${s}`;
}
setInterval(updateClock, 1000);
updateClock();

// 3. Mini ECG Wave Canvas Simulation (Smooth 60fps telemetry stream)
(function initEcgCanvas() {
  const canvas = document.getElementById('ehr-ecg-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  
  let width = canvas.width = canvas.offsetWidth || 560;
  let height = canvas.height = 85;
  let x = 0;
  let points = [];
  const maxPoints = Math.floor(width);
  const midY = height / 2;
  let phase = 0;

  function getEcgY(p) {
    // Standard P-Q-R-S-T wave pattern
    const mod = p % 80;
    if (mod < 10) return midY; // baseline
    if (mod >= 10 && mod < 20) return midY - Math.sin((mod - 10) / 10 * Math.PI) * 5; // P wave
    if (mod >= 20 && mod < 25) return midY; // PR segment
    if (mod >= 25 && mod < 28) return midY + 4; // Q wave
    if (mod >= 28 && mod < 34) return midY - 32; // R wave spike
    if (mod >= 34 && mod < 37) return midY + 12; // S wave
    if (mod >= 37 && mod < 45) return midY; // ST segment
    if (mod >= 45 && mod < 60) return midY - Math.sin((mod - 45) / 15 * Math.PI) * 9; // T wave
    return midY; // baseline
  }

  function renderEcg() {
    ctx.fillStyle = 'rgba(2, 6, 23, 0.2)';
    ctx.fillRect(0, 0, width, height);

    ctx.strokeStyle = '#10B981';
    ctx.lineWidth = 1.8;
    ctx.shadowColor = '#10B981';
    ctx.shadowBlur = 6;
    ctx.beginPath();

    for (let i = 0; i < points.length; i++) {
      if (i === 0) ctx.moveTo(i, points[i]);
      else ctx.lineTo(i, points[i]);
    }
    ctx.stroke();

    // Erase sweep line
    ctx.fillStyle = '#020617';
    ctx.fillRect(x + 2, 0, 15, height);

    // Push new point
    points[x] = getEcgY(phase);
    x = (x + 1) % width;
    phase += 1;

    requestAnimationFrame(renderEcg);
  }

  requestAnimationFrame(renderEcg);
})();

// 4. PACS Radiology Viewer Controls
const pacsWrapper = document.getElementById('pacs-wrapper');
const pacsImg = document.getElementById('pacs-image');
const pacsFilterVal = document.getElementById('pacs-filter-val');
const pacsZoomVal = document.getElementById('pacs-zoom-val');

document.getElementById('pacs-btn-normal')?.addEventListener('click', () => {
  pacsWrapper.className = 'pacs-canvas-wrapper';
  pacsFilterVal.textContent = 'STANDARD';
  pacsZoomVal.textContent = '100%';
  setActivePacsTool('pacs-btn-normal');
});

document.getElementById('pacs-btn-invert')?.addEventListener('click', () => {
  pacsWrapper.classList.toggle('inverted');
  pacsFilterVal.textContent = pacsWrapper.classList.contains('inverted') ? 'INVERT (NEG)' : 'STANDARD';
  setActivePacsTool('pacs-btn-invert');
});

document.getElementById('pacs-btn-contrast')?.addEventListener('click', () => {
  pacsWrapper.classList.toggle('high-contrast');
  pacsFilterVal.textContent = pacsWrapper.classList.contains('high-contrast') ? 'HI-CONTRAST' : 'STANDARD';
  setActivePacsTool('pacs-btn-contrast');
});

document.getElementById('pacs-btn-zoom')?.addEventListener('click', () => {
  pacsWrapper.classList.toggle('zoomed');
  pacsZoomVal.textContent = pacsWrapper.classList.contains('zoomed') ? '140%' : '100%';
  setActivePacsTool('pacs-btn-zoom');
});

function setActivePacsTool(activeId) {
  document.querySelectorAll('.pacs-tools .btn-tool').forEach(b => {
    b.classList.toggle('active', b.id === activeId);
  });
}

document.getElementById('pacs-study-select')?.addEventListener('change', (e) => {
  const val = e.target.value;
  if (val === 'chest') pacsImg.src = '../build/img/bullet.png';
  else if (val === 'arm') pacsImg.src = '../build/img/arm.png';
  else pacsImg.src = '../build/img/cotton.png';
});

// 5. Digital Prescription Management
function renderRxTable() {
  const tbody = document.getElementById('rx-items-body');
  if (!tbody) return;
  tbody.innerHTML = '';

  state.rxList.forEach((med, idx) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>${med.label}</strong></td>
      <td>${med.dosage}</td>
      <td>${med.amount} un</td>
      <td>$${med.cost}</td>
      <td><button class="btn-icon red" onclick="removeRxRowByIndex(${idx})"><i class="fa-solid fa-trash"></i></button></td>
    `;
    tbody.appendChild(tr);
  });
}

window.removeRxRowByIndex = function(idx) {
  state.rxList.splice(idx, 1);
  renderRxTable();
};

document.getElementById('btn-add-rx-item')?.addEventListener('click', () => {
  const select = document.getElementById('rx-med-select');
  const opt = select.options[select.selectedIndex];
  const item = select.value;
  const label = opt.text.split(' ($')[0];
  const costUnit = parseInt(opt.getAttribute('data-cost') || '15', 10);
  const amount = parseInt(document.getElementById('rx-med-amount').value || '1', 10);
  const dosage = document.getElementById('rx-med-dosage').value || '1 comp de 8/8h';

  if (state.rxList.length >= 5) {
    alert('Limite máximo de 5 medicamentos por receita atingido.');
    return;
  }

  state.rxList.push({
    item,
    label,
    dosage,
    amount,
    cost: costUnit * amount
  });

  renderRxTable();
});

window.resetRxForm = function() {
  state.rxList = [];
  renderRxTable();
};

// 6. Transmit Digital Prescription to Pharmacy Dispatch Queue
document.getElementById('btn-submit-digital-rx')?.addEventListener('click', () => {
  if (state.rxList.length === 0) {
    alert('Insira ao menos um medicamento na receita digital.');
    return;
  }

  const patient = document.getElementById('rx-input-patient').value;
  const cid = document.getElementById('rx-input-cid').value;
  const cid10 = document.getElementById('rx-input-cid10').value;
  const leaveDays = document.getElementById('rx-leave-days').value;
  const notes = document.getElementById('rx-clinical-notes').value;

  const payload = {
    patient,
    cid,
    cid10,
    leaveDays,
    notes,
    medications: state.rxList
  };

  // NUI Callback fetch to FiveM backend
  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/tabletSubmitPrescription`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload)
    }).then(res => res.json()).then(data => {
      alert(`Receita digital transmitida com sucesso!\nToken Gerado: ${data.token || 'RX-' + Math.floor(1000 + Math.random()*9000)}`);
      switchTab('pharmacy');
    }).catch(() => {
      // Offline / standalone fallback
      simulatePharmacyQueueAdd(payload);
    });
  } else {
    simulatePharmacyQueueAdd(payload);
  }
});

function simulatePharmacyQueueAdd(payload) {
  const token = 'RX-' + Math.floor(1000 + Math.random() * 9000);
  const queueCards = document.getElementById('pharmacy-queue-cards');
  if (queueCards) {
    const card = document.createElement('div');
    card.className = 'pharmacy-card';
    card.innerHTML = `
      <div class="pharm-card-header">
        <span class="token-badge">TOKEN #${token}</span>
        <span class="status-pill status-prep">RECÉM-TRANSMITIDO</span>
      </div>
      <div class="pharm-card-body">
        <h4>${payload.patient}</h4>
        <div class="pharm-meta"><strong>Prescrito por:</strong> Dr. Ricardo Novaes</div>
        <div class="pharm-meta"><strong>CID-10:</strong> ${payload.cid10}</div>
        <div class="pharm-meds-list">
          ${payload.medications.map(m => `<div class="pharm-med-item"><i class="fa-solid fa-pills"></i> ${m.label} (x${m.amount})</div>`).join('')}
        </div>
      </div>
      <div class="pharm-card-footer">
        <span class="pharm-cost">Total: $${payload.medications.reduce((acc, cur) => acc + cur.cost, 0)}</span>
        <button class="btn btn-sm btn-primary" onclick="dispenseMedication('${token}')">
          <i class="fa-solid fa-hand-holding-medical"></i> Dispensar Medicamentos
        </button>
      </div>
    `;
    queueCards.prepend(card);
  }
  alert(`Receita digital transmitida com sucesso para a Farmácia Central!\nToken de Retirada: #${token}`);
  switchTab('pharmacy');
}

window.dispenseMedication = function(token) {
  if (confirm(`Confirmar dispensação e baixa dos medicamentos para o Token #${token}?`)) {
    if (window.GetParentResourceName) {
      fetch(`https://${GetParentResourceName()}/tabletDispensePrescription`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ token })
      });
    }
    alert(`Medicamentos dispensados e entregues com sucesso! Token #${token} baixado.`);
    document.querySelectorAll('.pharmacy-card').forEach(card => {
      if (card.textContent.includes(token)) {
        card.classList.add('dispensed');
        const status = card.querySelector('.status-pill');
        if (status) {
          status.className = 'status-pill status-done';
          status.textContent = 'DISPENSADO';
        }
        const btn = card.querySelector('button');
        if (btn) btn.outerHTML = '<span class="text-muted"><i class="fa-solid fa-check"></i> Entregue ao Paciente</span>';
      }
    });
  }
};

// Initial Render
renderRxTable();

/* ==========================================================================
   5TH MODULE: PHYSICAL REHABILITATION & PHYSIOTHERAPY CONTROLLER
   ========================================================================== */

const rehabState = {
  selectedPatient: null,
  selectedEquip: 'wheelchair',
  selectedDuration: 600,
  progressive: true,
  nearbyPatients: [],
  activePatients: []
};

// Equip selector
window.selectRehabEquip = function(equip) {
  rehabState.selectedEquip = equip;
  document.querySelectorAll('.equip-card').forEach(card => {
    card.classList.toggle('active', card.dataset.equip === equip);
  });
};

// Duration selector
window.selectRehabDuration = function(seconds) {
  rehabState.selectedDuration = Number(seconds);
  document.querySelectorAll('.duration-pill').forEach(pill => {
    pill.classList.toggle('active', Number(pill.dataset.seconds) === Number(seconds));
  });
};

// Patient selector
window.selectRehabPatient = function(id, name) {
  rehabState.selectedPatient = { id, name };
  document.querySelectorAll('.patient-pick-card').forEach(card => {
    card.classList.toggle('active', Number(card.dataset.id) === Number(id));
  });
};

// Render nearby patients list
function renderRehabPatients() {
  const container = document.getElementById('rehab-patient-list');
  const countEl = document.getElementById('rehab-nearby-count');
  if (!container) return;

  if (countEl) countEl.textContent = `${rehabState.nearbyPatients.length} encontrados`;

  if (rehabState.nearbyPatients.length === 0) {
    container.innerHTML = `
      <div class="rehab-empty-state">
        <i class="fa-solid fa-person-circle-question"></i>
        <span>Nenhum paciente detectado nas imediações (raio de 6m).</span>
      </div>
    `;
    return;
  }

  container.innerHTML = rehabState.nearbyPatients.map(p => {
    const isSelected = rehabState.selectedPatient && rehabState.selectedPatient.id === p.id;
    const statusBadge = p.inRecovery
      ? `<span class="badge badge-warning"><i class="fa-solid fa-bed-pulse"></i> Em Tratamento (${Math.floor(p.remaining / 60)}m)</span>`
      : `<span class="badge badge-success"><i class="fa-solid fa-check"></i> Apto para Prescrição</span>`;

    return `
      <div class="patient-pick-card ${isSelected ? 'active' : ''}" data-id="${p.id}" onclick="window.selectRehabPatient(${p.id}, '${p.name}')">
        <div>
          <div class="patient-pick-name">${p.name} <small class="text-muted">(ID ${p.id})</small></div>
          <div class="patient-pick-meta">Distância: ${p.distance}m</div>
        </div>
        <div>
          ${statusBadge}
        </div>
      </div>
    `;
  }).join('');
}

// Render active rehabilitation patients list
function renderActiveRehabList() {
  const container = document.getElementById('rehab-active-list');
  const countEl = document.getElementById('rehab-active-count');
  if (!container) return;

  const activeOnes = rehabState.nearbyPatients.filter(p => p.inRecovery);
  rehabState.activePatients = activeOnes;
  if (countEl) countEl.textContent = `${activeOnes.length} ativos`;

  if (activeOnes.length === 0) {
    container.innerHTML = `
      <div class="rehab-empty-state">
        <i class="fa-solid fa-heart-pulse"></i>
        <span>Nenhum paciente sob reabilitação física no momento.</span>
      </div>
    `;
    return;
  }

  container.innerHTML = activeOnes.map(p => {
    const equipIcon = p.mode === 'wheelchair' ? 'fa-wheelchair text-emerald' : 'fa-crutch text-cyan';
    const equipName = p.mode === 'wheelchair' ? 'Cadeira de Rodas' : 'Muletas Ortopédicas';
    const mins = Math.floor(p.remaining / 60);
    const secs = p.remaining % 60;
    const timeFormatted = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    const stageText = p.nextStage ? `Fase 1 (60%) &rarr; Próx: Muletas` : `Fase Única / Final`;

    return `
      <div class="active-rehab-card">
        <div class="active-card-head">
          <div class="active-card-name">
            <i class="fa-solid ${equipIcon}"></i> ${p.name} <small class="text-muted">(ID ${p.id})</small>
          </div>
          <span class="badge badge-emerald">${equipName}</span>
        </div>
        <div style="display: flex; justify-content: space-between; font-size: 10px; color: var(--text-muted); margin-top: 4px;">
          <span>${stageText}</span>
          <span>Tempo Restante: <strong style="color: #fff; font-family: var(--font-mono); font-variant-numeric: tabular-nums;">${timeFormatted}</strong></span>
        </div>
        <div class="rehab-progress-track">
          <div class="rehab-progress-fill" style="width: 65%;"></div>
        </div>
        <div class="active-card-actions">
          <button class="btn btn-xs btn-secondary" onclick="window.quickBandage(${p.id}, '${p.name}')" title="Acelerar cura em 60s">
            <i class="fa-solid fa-bandage text-emerald"></i> Curativo (-60s)
          </button>
          <button class="btn btn-xs btn-outline" onclick="window.quickDischarge(${p.id}, '${p.name}')" title="Conceder alta médica imediata" style="color: var(--rose-500); border-color: rgba(244, 63, 94, 0.4);">
            <i class="fa-solid fa-person-walking"></i> Alta
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// Fetch nearby patients from Lua backend
window.refreshRehabPatients = function() {
  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/tabletGetRehabPatients`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    }).then(res => res.json()).then(data => {
      if (Array.isArray(data)) {
        rehabState.nearbyPatients = data;
        renderRehabPatients();
        renderActiveRehabList();
      }
    }).catch(() => {
      simulateMockPatients();
    });
  } else {
    simulateMockPatients();
  }
};

function simulateMockPatients() {
  rehabState.nearbyPatients = [
    { id: 2, name: 'Lucas Brandão', distance: 2.1, inRecovery: false, mode: null, remaining: 0 },
    { id: 4, name: 'Gabriel Santana', distance: 3.8, inRecovery: true, mode: 'wheelchair', remaining: 420, nextStage: 'crutch' }
  ];
  renderRehabPatients();
  renderActiveRehabList();
}

// Submit prescription
window.submitRehabPrescription = function() {
  if (!rehabState.selectedPatient) {
    alert('Selecione um paciente próximo na lista antes de prescrever.');
    return;
  }

  const progToggle = document.getElementById('rehab-progressive-toggle');
  const progressive = progToggle ? progToggle.checked : true;

  const payload = {
    target: rehabState.selectedPatient.id,
    mode: rehabState.selectedEquip,
    duration: rehabState.selectedDuration,
    progressive: progressive
  };

  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/tabletApplyRehab`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload)
    }).then(res => res.json()).then(res => {
      alert(`Reabilitação prescrita com sucesso para ${rehabState.selectedPatient.name}!`);
      window.refreshRehabPatients();
    });
  } else {
    alert(`[Simulação] Reabilitação ativada para ${rehabState.selectedPatient.name} (${payload.mode}, ${payload.duration}s)!`);
    window.refreshRehabPatients();
  }
};

// Submit discharge / remove
window.submitRehabDischarge = function() {
  if (!rehabState.selectedPatient) {
    alert('Selecione um paciente na lista para remover o equipamento.');
    return;
  }

  if (confirm(`Confirmar alta médica e remoção do equipamento para ${rehabState.selectedPatient.name}?`)) {
    if (window.GetParentResourceName) {
      fetch(`https://${GetParentResourceName()}/tabletRemoveRehab`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ target: rehabState.selectedPatient.id })
      }).then(() => {
        alert(`Alta concedida para ${rehabState.selectedPatient.name}.`);
        window.refreshRehabPatients();
      });
    } else {
      alert(`[Simulação] Alta médica concedida.`);
      window.refreshRehabPatients();
    }
  }
};

// Submit bandage
window.submitRehabBandage = function() {
  if (!rehabState.selectedPatient) {
    alert('Selecione um paciente para aplicar o curativo acelerador.');
    return;
  }

  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/tabletBandageRehab`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ target: rehabState.selectedPatient.id })
    }).then(() => {
      alert(`Curativo aplicado em ${rehabState.selectedPatient.name} (-60s).`);
      window.refreshRehabPatients();
    });
  } else {
    alert(`[Simulação] Curativo aplicado (-60s).`);
  }
};

// Inline quick actions from active cards
window.quickBandage = function(targetId, targetName) {
  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/tabletBandageRehab`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ target: targetId })
    }).then(() => {
      window.refreshRehabPatients();
    });
  } else {
    alert(`[Simulação] Curativo aplicado em ${targetName} (-60s).`);
  }
};

window.quickDischarge = function(targetId, targetName) {
  if (confirm(`Confirmar alta médica imediata para ${targetName}?`)) {
    if (window.GetParentResourceName) {
      fetch(`https://${GetParentResourceName()}/tabletRemoveRehab`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ target: targetId })
      }).then(() => {
        window.refreshRehabPatients();
      });
    } else {
      alert(`[Simulação] Alta concedida para ${targetName}.`);
      window.refreshRehabPatients();
    }
  }
};

// Hook tab switch to auto-refresh rehab list
const originalSwitchTab = switchTab;
switchTab = function(tabId) {
  originalSwitchTab(tabId);
  if (tabId === 'rehab') {
    window.refreshRehabPatients();
  }
};


