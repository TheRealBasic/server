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
const buildTab = document.getElementById('buildTab');
const trollTab = document.getElementById('trollTab');
const chaosPanel = document.getElementById('chaosPanel');
const buildPanel = document.getElementById('buildPanel');
const trollPanel = document.getElementById('trollPanel');
const trollActionSelect = document.getElementById('trollActionSelect');
const trollActionInfo = document.getElementById('trollActionInfo');
const triggerTrollBtn = document.getElementById('triggerTrollBtn');
const hudTimer = document.getElementById('hudTimer');
const hudCurrentEvent = document.getElementById('hudCurrentEvent');
const hudHistory = document.getElementById('hudHistory');
const buildCategorySelect = document.getElementById('buildCategorySelect');
const buildSearchInput = document.getElementById('buildSearchInput');
const buildCatalogList = document.getElementById('buildCatalogList');
const catalogGridBtn = document.getElementById('catalogGridBtn');
const catalogListBtn = document.getElementById('catalogListBtn');
const buildPlaceBtn = document.getElementById('buildPlaceBtn');
const buildCancelBtn = document.getElementById('buildCancelBtn');
const buildSnapToggle = document.getElementById('buildSnapToggle');
const buildRotateStep = document.getElementById('buildRotateStep');
const buildAttachToggle = document.getElementById('buildAttachToggle');

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
  buildCatalog: [],
  selectedProp: null,
  buildMode: {
    category: 'all',
    query: '',
    view: 'list',
    snap: true,
    rotateStep: 15,
    attach: false,
    enabled: false
  },
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

function getFilteredBuildCatalog() {
  const selectedCategory = state.buildMode.category;
  const query = state.buildMode.query.trim().toLowerCase();

  return state.buildCatalog.filter((entry) => {
    const categoryMatches = selectedCategory === 'all' || entry.categoryId === selectedCategory;
    if (!categoryMatches) {
      return false;
    }

    if (!query) {
      return true;
    }

    const haystack = `${entry.label || ''} ${entry.description || ''} ${entry.id || ''}`.toLowerCase();
    return haystack.includes(query);
  });
}

function renderBuildCatalog() {
  if (!buildCatalogList) {
    return;
  }

  buildCatalogList.innerHTML = '';
  const filtered = getFilteredBuildCatalog();

  if (!filtered.length) {
    const empty = document.createElement('div');
    empty.className = 'build-empty';
    empty.textContent = 'No build props found.';
    buildCatalogList.appendChild(empty);
    return;
  }

  filtered.forEach((entry) => {
    const item = document.createElement('button');
    item.type = 'button';
    item.className = 'build-item';
    if (state.selectedProp === entry.id) {
      item.classList.add('active');
    }

    const title = document.createElement('strong');
    title.textContent = entry.label || entry.id;
    item.appendChild(title);

    const category = document.createElement('span');
    category.className = 'build-item-category';
    category.textContent = entry.categoryLabel || entry.categoryId || 'Misc';
    item.appendChild(category);

    if (entry.description) {
      const description = document.createElement('span');
      description.className = 'build-item-description';
      description.textContent = entry.description;
      item.appendChild(description);
    }

    item.addEventListener('click', () => {
      state.selectedProp = entry.id;
      renderBuildCatalog();
      postNui('setBuildSelection', { propId: entry.id });
    });

    buildCatalogList.appendChild(item);
  });
}

function syncBuildControls() {
  buildCategorySelect.value = state.buildMode.category || 'all';
  buildSearchInput.value = state.buildMode.query || '';
  buildSnapToggle.checked = state.buildMode.snap === true;
  buildAttachToggle.checked = state.buildMode.attach === true;
  buildRotateStep.value = String(state.buildMode.rotateStep || 15);

  buildCatalogList.classList.toggle('grid', state.buildMode.view === 'grid');
  buildCatalogList.classList.toggle('list', state.buildMode.view !== 'grid');
  catalogGridBtn.classList.toggle('active', state.buildMode.view === 'grid');
  catalogListBtn.classList.toggle('active', state.buildMode.view !== 'grid');
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
  const buildMode = mode === 'build';
  chaosTab.classList.toggle('active', mode === 'chaos');
  buildTab.classList.toggle('active', buildMode);
  trollTab.classList.toggle('active', trollMode);
  chaosPanel.classList.toggle('hidden', mode !== 'chaos');
  buildPanel.classList.toggle('hidden', !buildMode);
  trollPanel.classList.toggle('hidden', !trollMode);
  allPlayersRadio.disabled = trollMode || buildMode;
  if (trollMode || buildMode) {
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
    if (data.mode === 'troll') {
      setMode('troll');
    } else if (data.mode === 'build') {
      setMode('build');
    } else {
      setMode('chaos');
    }
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
    state.buildCatalog = Array.isArray(data.buildCatalog) ? data.buildCatalog : [];
    if (typeof data.selectedProp === 'string') {
      state.selectedProp = data.selectedProp;
    }
    if (data.buildMode && typeof data.buildMode === 'object') {
      state.buildMode = {
        ...state.buildMode,
        ...data.buildMode
      };
    }
    renderEvents();
    renderPlayers();
    renderTrollActions();
    syncBuildControls();
    renderBuildCatalog();
    updatePlayerListState();
  }

  if (data.action === 'setEventToggles') {
    state.eventToggles = data.eventToggles && typeof data.eventToggles === 'object' ? data.eventToggles : {};
    updateEventToggle();
  }

  if (data.action === 'setBuildSelection') {
    state.selectedProp = typeof data.propId === 'string' ? data.propId : null;
    renderBuildCatalog();
  }

  if (data.action === 'setBuildState') {
    if (data.buildMode && typeof data.buildMode === 'object') {
      state.buildMode = {
        ...state.buildMode,
        ...data.buildMode
      };
      syncBuildControls();
      renderBuildCatalog();
    }
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

buildCategorySelect.addEventListener('change', async () => {
  state.buildMode.category = buildCategorySelect.value;
  renderBuildCatalog();
  await postNui('setBuildCategory', { category: state.buildMode.category });
});

buildSearchInput.addEventListener('input', async () => {
  state.buildMode.query = buildSearchInput.value || '';
  renderBuildCatalog();
  await postNui('setBuildFilter', { query: state.buildMode.query });
});

catalogGridBtn.addEventListener('click', async () => {
  state.buildMode.view = 'grid';
  syncBuildControls();
  await postNui('setBuildView', { view: 'grid' });
});

catalogListBtn.addEventListener('click', async () => {
  state.buildMode.view = 'list';
  syncBuildControls();
  await postNui('setBuildView', { view: 'list' });
});

buildPlaceBtn.addEventListener('click', async () => {
  await postNui('buildPlace', {
    propId: state.selectedProp,
    snap: buildSnapToggle.checked,
    rotateStep: Number(buildRotateStep.value),
    attach: buildAttachToggle.checked
  });
});

buildCancelBtn.addEventListener('click', async () => {
  await postNui('buildCancel');
});

buildSnapToggle.addEventListener('change', async () => {
  state.buildMode.snap = buildSnapToggle.checked;
  await postNui('setBuildSnap', { enabled: state.buildMode.snap });
});

buildRotateStep.addEventListener('change', async () => {
  state.buildMode.rotateStep = Number(buildRotateStep.value);
  await postNui('setBuildRotateStep', { step: state.buildMode.rotateStep });
});

buildAttachToggle.addEventListener('change', async () => {
  state.buildMode.attach = buildAttachToggle.checked;
  await postNui('setBuildAttachMode', { enabled: state.buildMode.attach });
});

chaosTab.addEventListener('click', () => setMode('chaos'));
buildTab.addEventListener('click', () => setMode('build'));
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
syncBuildControls();
renderBuildCatalog();
