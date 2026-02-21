const app = document.getElementById('app');
const eventSelect = document.getElementById('eventSelect');
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
const triggerTrollBtn = document.getElementById('triggerTrollBtn');

const resourceName = typeof GetParentResourceName === 'function'
  ? GetParentResourceName()
  : 'chaos_mode';

const state = {
  events: [],
  players: [],
  trollActions: [],
  mode: 'chaos'
};

function postNui(name, data = {}) {
  return fetch(`https://${resourceName}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function renderEvents() {
  eventSelect.innerHTML = '';
  state.events.forEach((eventName) => {
    const option = document.createElement('option');
    option.value = eventName;
    option.textContent = eventName;
    eventSelect.appendChild(option);
  });
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
    const option = document.createElement('option');
    option.value = actionName;
    option.textContent = actionName;
    trollActionSelect.appendChild(option);
  });
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

  if (data.action === 'setData') {
    state.events = Array.isArray(data.events) ? data.events : [];
    state.players = Array.isArray(data.players) ? data.players : [];
    state.trollActions = Array.isArray(data.trollActions) ? data.trollActions : [];
    renderEvents();
    renderPlayers();
    renderTrollActions();
    updatePlayerListState();
  }
});

allPlayersRadio.addEventListener('change', updatePlayerListState);
specificPlayersRadio.addEventListener('change', updatePlayerListState);

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
