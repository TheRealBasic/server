const app = document.getElementById('app');
const eventSelect = document.getElementById('eventSelect');
const eventInfo = document.getElementById('eventInfo');
const eventToggle = document.getElementById('eventToggle');
const allPlayersRadio = document.getElementById('allPlayers');
const specificPlayersRadio = document.getElementById('specificPlayers');
const playerList = document.getElementById('playerList');
const triggerBtn = document.getElementById('triggerBtn');
const closeBtn = document.getElementById('closeBtn');
const chaosTab = document.getElementById('chaosTab');
const trollTab = document.getElementById('trollTab');
const chaosPanel = document.getElementById('chaosPanel');
const trollPanel = document.getElementById('trollPanel');
const trollActionSelect = document.getElementById('trollActionSelect');
const trollActionInfo = document.getElementById('trollActionInfo');
const triggerTrollBtn = document.getElementById('triggerTrollBtn');
const hudTimer = document.getElementById('hudTimer');
const hudCurrentEvent = document.getElementById('hudCurrentEvent');
const hudHistory = document.getElementById('hudHistory');

const resourceName = typeof GetParentResourceName === 'function'
  ? GetParentResourceName()
  : 'chaos_mode';

const state = {
  events: [],
  players: [],
  trollActions: [],
  trollActionMeta: {},
  eventMeta: {},
  eventToggles: {},
  mode: 'chaos',
  hud: {
    secondsRemaining: 30,
    currentEvent: 'Waiting for next event',
    history: []
  }
};

function postNui(name, data = {}) {
  return fetch(`https://${resourceName}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function formatDuration(durationMs) {
  if (typeof durationMs !== 'number' || Number.isNaN(durationMs) || durationMs <= 0) {
    return null;
  }

  const seconds = durationMs / 1000;
  return Number.isInteger(seconds) ? `${seconds}s` : `${seconds.toFixed(1)}s`;
}

function describeMeta(id, meta) {
  const description = meta && typeof meta.description === 'string' && meta.description.trim()
    ? meta.description.trim()
    : `ID: ${id}`;
  const duration = formatDuration(meta && meta.durationMs);
  return duration ? `${description} (${duration})` : description;
}

function renderEvents() {
  eventSelect.innerHTML = '';
  state.events.forEach((eventName) => {
    const meta = state.eventMeta[eventName] || {};
    const option = document.createElement('option');
    option.value = eventName;
    option.textContent = meta.label || eventName;
    eventSelect.appendChild(option);
  });
  updateEventInfo();
  updateEventToggle();
}

function updateEventToggle() {
  const selectedId = eventSelect.value;
  if (!selectedId || !eventToggle) {
    return;
  }

  eventToggle.checked = state.eventToggles[selectedId] !== false;
}

function renderPlayers() {
  playerList.innerHTML = '';

  if (!state.players.length) {
    playerList.textContent = 'No players in lobby.';
    return;
  }

  state.players.forEach((player) => {
    const row = document.createElement('label');
    row.className = 'player-item';

    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.value = String(player.id);

    const text = document.createElement('span');
    text.textContent = `${player.name} (${player.id})`;

    row.appendChild(checkbox);
    row.appendChild(text);
    playerList.appendChild(row);
  });
}

function renderTrollActions() {
  trollActionSelect.innerHTML = '';
  state.trollActions.forEach((actionName) => {
    const meta = state.trollActionMeta[actionName] || {};
    const option = document.createElement('option');
    option.value = actionName;
    option.textContent = meta.label || actionName;
    trollActionSelect.appendChild(option);
  });
  updateTrollActionInfo();
}

function updateEventInfo() {
  if (!eventInfo) {
    return;
  }

  const selectedId = eventSelect.value;
  if (!selectedId) {
    eventInfo.textContent = 'No event selected.';
    return;
  }

  const meta = state.eventMeta[selectedId] || {};
  eventInfo.textContent = describeMeta(selectedId, meta);
  updateEventToggle();
}

function updateTrollActionInfo() {
  if (!trollActionInfo) {
    return;
  }

  const selectedId = trollActionSelect.value;
  if (!selectedId) {
    trollActionInfo.textContent = 'No trolling action selected.';
    return;
  }

  const meta = state.trollActionMeta[selectedId] || {};
  trollActionInfo.textContent = describeMeta(selectedId, meta);
}


function renderHud() {
  if (hudTimer) {
    const remaining = Number.isFinite(state.hud.secondsRemaining) ? Math.max(0, Math.floor(state.hud.secondsRemaining)) : 0;
    hudTimer.textContent = `Next event in: ${remaining}s`;
  }

  if (hudCurrentEvent) {
    hudCurrentEvent.textContent = state.hud.currentEvent || 'Waiting for next event';
  }

  if (hudHistory) {
    hudHistory.innerHTML = '';
    const entries = Array.isArray(state.hud.history) ? state.hud.history.slice(0, 4) : [];
    if (!entries.length) {
      const empty = document.createElement('li');
      empty.textContent = 'No previous events';
      hudHistory.appendChild(empty);
      return;
    }

    entries.forEach((entry) => {
      const item = document.createElement('li');
      item.textContent = entry;
      hudHistory.appendChild(item);
    });
  }
}

function setMode(mode) {
  state.mode = mode;
  const trollMode = mode === 'troll';
  chaosTab.classList.toggle('active', !trollMode);
  trollTab.classList.toggle('active', trollMode);
  chaosPanel.classList.toggle('hidden', trollMode);
  trollPanel.classList.toggle('hidden', !trollMode);
  allPlayersRadio.disabled = trollMode;
  if (trollMode) {
    specificPlayersRadio.checked = true;
  }
  updatePlayerListState();
}

function updatePlayerListState() {
  const useSpecific = specificPlayersRadio.checked;
  playerList.classList.toggle('disabled', !useSpecific);
}

function getSelectedPlayers() {
  return [...playerList.querySelectorAll('input[type="checkbox"]:checked')]
    .map((entry) => Number(entry.value));
}

window.addEventListener('message', (event) => {
  const data = event.data || {};

  if (data.action === 'setVisible') {
    app.classList.toggle('hidden', !data.visible);
    if (data.visible) {
      updatePlayerListState();
    }
  }

  if (data.action === 'setMode') {
    setMode(data.mode === 'troll' ? 'troll' : 'chaos');
  }

  if (data.action === 'setHudData') {
    state.hud.secondsRemaining = Number(data.secondsRemaining) || 0;
    state.hud.currentEvent = typeof data.currentEvent === 'string' ? data.currentEvent : 'Waiting for next event';
    state.hud.history = Array.isArray(data.history) ? data.history : [];
    renderHud();
  }

  if (data.action === 'setData') {
    state.events = Array.isArray(data.events) ? data.events : [];
    state.players = Array.isArray(data.players) ? data.players : [];
    state.trollActions = Array.isArray(data.trollActions) ? data.trollActions : [];
    state.trollActionMeta = data.trollActionMeta && typeof data.trollActionMeta === 'object' ? data.trollActionMeta : {};
    state.eventMeta = data.eventMeta && typeof data.eventMeta === 'object' ? data.eventMeta : {};
    state.eventToggles = data.eventToggles && typeof data.eventToggles === 'object' ? data.eventToggles : {};
    renderEvents();
    renderPlayers();
    renderTrollActions();
    updatePlayerListState();
  }

  if (data.action === 'setEventToggles') {
    state.eventToggles = data.eventToggles && typeof data.eventToggles === 'object' ? data.eventToggles : {};
    updateEventToggle();
  }
});

allPlayersRadio.addEventListener('change', updatePlayerListState);
specificPlayersRadio.addEventListener('change', updatePlayerListState);
eventSelect.addEventListener('change', updateEventInfo);
trollActionSelect.addEventListener('change', updateTrollActionInfo);
eventToggle.addEventListener('change', async () => {
  const eventName = eventSelect.value;
  if (!eventName) {
    return;
  }

  state.eventToggles[eventName] = eventToggle.checked;
  await postNui('setEventToggle', { eventName, enabled: eventToggle.checked });
});

triggerBtn.addEventListener('click', async () => {
  const eventName = eventSelect.value;
  const targetType = specificPlayersRadio.checked ? 'specific' : 'all';
  const players = targetType === 'specific' ? getSelectedPlayers() : [];

  if (!eventName) {
    return;
  }

  await postNui('triggerEvent', { eventName, targetType, players });
});

triggerTrollBtn.addEventListener('click', async () => {
  const actionName = trollActionSelect.value;
  const players = getSelectedPlayers();

  if (!actionName || !players.length) {
    return;
  }

  await postNui('triggerTrollAction', { actionName, players });
});

chaosTab.addEventListener('click', () => setMode('chaos'));
trollTab.addEventListener('click', () => setMode('troll'));

closeBtn.addEventListener('click', async () => {
  await postNui('close');
});

document.addEventListener('keydown', async (event) => {
  if (event.key === 'Escape') {
    await postNui('close');
  }
});

renderHud();
