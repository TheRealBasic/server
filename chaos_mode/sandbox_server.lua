local RESOURCE = GetCurrentResourceName()

Config = Config or {}
Config.Sandbox = Config.Sandbox or {
    StartingCash = 5000,
    StartingBank = 2500,
    TickIncomeMinutes = 10,
    DeliveryBasePayout = 550,
    TerritoryCaptureSeconds = 45,
    CommunityProjectGoal = 50000,
    SeasonName = 'Founders Season',
    SeasonReward = 3000,
    Skills = {
        driving = { max = 5, cost = 900 },
        mechanic = { max = 5, cost = 900 },
        harvesting = { max = 5, cost = 700 },
        crafting = { max = 5, cost = 700 },
        trading = { max = 5, cost = 800 }
    }
}

local stateFile = 'sandbox_state.json'
local state = {
    players = {},
    market = {},
    groups = {},
    territories = {
        city = { owner = nil, bonus = 'Delivery +20%' },
        desert = { owner = nil, bonus = 'Gather +20%' },
        coast = { owner = nil, bonus = 'Fishing +20%' }
    },
    communityProject = {
        name = 'Restore Sandy Airstrip Services',
        progress = 0,
        goal = Config.Sandbox.CommunityProjectGoal,
        completed = false
    },
    season = {
        name = Config.Sandbox.SeasonName,
        participants = {},
        rewardClaimed = {}
    }
}

local contracts = {}
local capturers = {}

local function send(source, msg)
    TriggerClientEvent('chat:addMessage', source, {
        args = { '^2Sandbox', msg }
    })
end

local function broadcast(msg)
    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^2Sandbox', msg }
    })
end

local function getIdentifier(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:find('license:') then
            return id
        end
    end
    return ('player:%s'):format(source)
end

local function defaultPlayer(name)
    return {
        name = name,
        cash = Config.Sandbox.StartingCash,
        bank = Config.Sandbox.StartingBank,
        inventory = { wood = 0, ore = 0, fish = 0, meat = 0, parts = 0 },
        housing = { owned = false, tier = 0, spawn = 'default' },
        business = { owned = false, type = nil, tier = 0, stock = 0 },
        garage = { slots = 2, tier = 1 },
        rep = { trucker = 0, taxi = 0, tow = 0, medic = 0, mechanic = 0, fisher = 0 },
        property = { lots = 0, workshop = 0, warehouse = 0, farm = 0, dock = 0 },
        faction = nil,
        loans = 0,
        insurance = { vehicle = false, property = false },
        skills = { driving = 0, mechanic = 0, harvesting = 0, crafting = 0, trading = 0 }
    }
end

local function loadState()
    local raw = LoadResourceFile(RESOURCE, stateFile)
    if not raw or raw == '' then return end
    local decoded = json.decode(raw)
    if decoded then
        state = decoded
    end
end

local function saveState()
    SaveResourceFile(RESOURCE, stateFile, json.encode(state), -1)
end

local function getPlayerState(source)
    local id = getIdentifier(source)
    local entry = state.players[id]
    if not entry then
        entry = defaultPlayer(GetPlayerName(source) or ('Player %s'):format(source))
        state.players[id] = entry
    end
    entry.name = GetPlayerName(source) or entry.name
    return id, entry
end

local function adjustCash(player, amount)
    player.cash = math.floor((player.cash or 0) + amount)
end

local function transferToBank(player, amount)
    if player.cash < amount then return false end
    player.cash = player.cash - amount
    player.bank = player.bank + amount
    return true
end

local function takeFromBank(player, amount)
    if player.bank < amount then return false end
    player.bank = player.bank - amount
    player.cash = player.cash + amount
    return true
end

RegisterNetEvent('sandbox:clientReady', function()
    local src = source
    local _, player = getPlayerState(src)
    TriggerClientEvent('sandbox:updateHUD', src, player)
end)

AddEventHandler('playerDropped', function()
    saveState()
end)

CreateThread(function()
    loadState()
    while true do
        Wait((Config.Sandbox.TickIncomeMinutes or 10) * 60000)
        for _, player in pairs(state.players) do
            if player.business and player.business.owned then
                player.cash = player.cash + (250 * math.max(1, player.business.tier))
            end
        end
        saveState()
    end
end)

local function commandHelp(source)
    send(source, 'Use /sandboxhelp for all 15 systems and commands.')
end

RegisterCommand('sandboxhelp', function(source)
    if source == 0 then return end
    send(source, 'Housing:/house | Business:/business | Craft:/gather,/craft | Garage:/garage | Jobs:/jobrep,/deliver')
    send(source, 'Property:/property | Hunting/Fishing:/hunt,/fish | Market:/market | Factions:/faction | Territory:/territory')
    send(source, 'Banking:/bank | Skills:/skill | Projects:/project | Seasons:/season')
end)

RegisterCommand('house', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    if action == 'buy' then
        local cost = 6000 + (player.housing.tier * 2500)
        if player.cash < cost then return send(source, ('Need $%d cash to buy/upgrade housing.'):format(cost)) end
        player.cash = player.cash - cost
        player.housing.owned = true
        player.housing.tier = player.housing.tier + 1
        send(source, ('Housing upgraded to tier %d.'):format(player.housing.tier))
    elseif action == 'setspawn' then
        player.housing.spawn = 'home'
        send(source, 'Spawn point set to home interior.')
    else
        send(source, ('Home owned: %s | Tier: %d | Spawn: %s'):format(tostring(player.housing.owned), player.housing.tier, player.housing.spawn))
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('business', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    if action == 'buy' then
        local bizType = args[2] or 'shop'
        local cost = 8000 + (player.business.tier * 3000)
        if player.cash < cost then return send(source, ('Need $%d cash to buy/upgrade a business.'):format(cost)) end
        player.cash = player.cash - cost
        player.business.owned = true
        player.business.type = bizType
        player.business.tier = player.business.tier + 1
        send(source, ('Bought/upgraded %s business tier %d.'):format(bizType, player.business.tier))
    elseif action == 'stock' then
        local qty = math.max(1, tonumber(args[2]) or 1)
        local cost = qty * 100
        if player.cash < cost then return send(source, 'Not enough cash for stock purchase.') end
        player.cash = player.cash - cost
        player.business.stock = player.business.stock + qty
        send(source, ('Stocked +%d units.'):format(qty))
    else
        send(source, ('Business: %s Tier %d Stock %d'):format(player.business.type or 'none', player.business.tier or 0, player.business.stock or 0))
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('gather', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local node = args[1] or 'wood'
    local skillBonus = player.skills.harvesting * 0.1
    local amount = math.random(2, 4) + math.floor(skillBonus * 4)
    player.inventory[node] = (player.inventory[node] or 0) + amount
    send(source, ('Gathered %d %s.'):format(amount, node))
    saveState()
end)

RegisterCommand('craft', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local recipe = args[1] or 'repairkit'
    if recipe == 'repairkit' then
        if (player.inventory.ore or 0) < 2 or (player.inventory.wood or 0) < 1 then
            return send(source, 'Need 2 ore + 1 wood for repairkit.')
        end
        player.inventory.ore = player.inventory.ore - 2
        player.inventory.wood = player.inventory.wood - 1
        player.inventory.parts = (player.inventory.parts or 0) + 1
        send(source, 'Crafted 1 repair part.')
    end
    saveState()
end)

RegisterCommand('garage', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    if action == 'upgrade' then
        local cost = 3000 * player.garage.tier
        if player.cash < cost then return send(source, ('Need $%d for garage upgrade.'):format(cost)) end
        player.cash = player.cash - cost
        player.garage.tier = player.garage.tier + 1
        player.garage.slots = player.garage.slots + 2
        send(source, ('Garage upgraded: Tier %d, slots %d.'):format(player.garage.tier, player.garage.slots))
    else
        send(source, ('Garage Tier %d | Slots %d'):format(player.garage.tier, player.garage.slots))
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('jobrep', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local job = args[1]
    if job and player.rep[job] ~= nil then
        player.rep[job] = player.rep[job] + 1
        send(source, ('%s rep increased to %d.'):format(job, player.rep[job]))
        saveState()
        return
    end
    local msg = 'Rep '
    for k, v in pairs(player.rep) do
        msg = msg .. ('%s:%d '):format(k, v)
    end
    send(source, msg)
end)

RegisterCommand('deliver', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local risk = args[1] or 'normal'
    local mult = (risk == 'high' and 1.8) or (risk == 'low' and 0.8) or 1.0
    local territoryBonus = 1.0
    if state.territories.city.owner == player.faction and player.faction ~= nil then
        territoryBonus = 1.2
    end
    local payout = math.floor(Config.Sandbox.DeliveryBasePayout * mult * territoryBonus * (1 + player.skills.driving * 0.05))
    adjustCash(player, payout)
    player.rep.trucker = player.rep.trucker + 1
    send(source, ('Delivery complete (%s risk): +$%d'):format(risk, payout))
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('property', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local slot = args[1] or 'workshop'
    if player.property[slot] == nil then
        return send(source, 'Usage: /property workshop|warehouse|farm|dock')
    end
    local current = player.property[slot]
    local cost = 2500 + (current * 1800)
    if player.cash < cost then return send(source, ('Need $%d to upgrade %s.'):format(cost, slot)) end
    player.cash = player.cash - cost
    player.property[slot] = current + 1
    send(source, ('%s upgraded to level %d.'):format(slot, player.property[slot]))
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('fish', function(source)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local base = math.random(1, 3)
    if state.territories.coast.owner == player.faction and player.faction ~= nil then
        base = math.floor(base * 1.2)
    end
    player.inventory.fish = player.inventory.fish + base
    player.rep.fisher = player.rep.fisher + 1
    send(source, ('Caught %d fish.'):format(base))
    saveState()
end)

RegisterCommand('hunt', function(source)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local gain = math.random(1, 2) + math.floor(player.skills.harvesting * 0.2)
    player.inventory.meat = player.inventory.meat + gain
    send(source, ('Hunted %d meat.'):format(gain))
    saveState()
end)

RegisterCommand('market', function(source, args)
    if source == 0 then return end
    local id, player = getPlayerState(source)
    local action = args[1] or 'list'
    if action == 'sell' then
        local item = args[2] or 'fish'
        local qty = math.max(1, tonumber(args[3]) or 1)
        if (player.inventory[item] or 0) < qty then return send(source, 'Not enough inventory.') end
        player.inventory[item] = player.inventory[item] - qty
        table.insert(state.market, { seller = id, sellerName = player.name, item = item, qty = qty, price = 100 * qty })
        send(source, ('Listed %d %s on market.'):format(qty, item))
    elseif action == 'buy' then
        local index = tonumber(args[2])
        local listing = state.market[index]
        if not listing then return send(source, 'Listing not found.') end
        if player.cash < listing.price then return send(source, 'Not enough cash.') end
        player.cash = player.cash - listing.price
        player.inventory[listing.item] = (player.inventory[listing.item] or 0) + listing.qty
        local seller = state.players[listing.seller]
        if seller then seller.cash = seller.cash + listing.price end
        table.remove(state.market, index)
        send(source, 'Purchase complete.')
    else
        if #state.market == 0 then return send(source, 'No active listings.') end
        for i, listing in ipairs(state.market) do
            send(source, ('[%d] %s x%d for $%d by %s'):format(i, listing.item, listing.qty, listing.price, listing.sellerName))
        end
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('faction', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    if action == 'create' then
        local name = args[2]
        if not name then return send(source, 'Usage: /faction create <name>') end
        if state.groups[name] then return send(source, 'Faction already exists.') end
        state.groups[name] = { owner = getIdentifier(source), members = { [getIdentifier(source)] = true } }
        player.faction = name
        send(source, ('Faction %s created.'):format(name))
    elseif action == 'join' then
        local name = args[2]
        if not name or not state.groups[name] then return send(source, 'Faction not found.') end
        state.groups[name].members[getIdentifier(source)] = true
        player.faction = name
        send(source, ('Joined faction %s.'):format(name))
    else
        send(source, ('Faction: %s'):format(player.faction or 'none'))
    end
    saveState()
end)

RegisterCommand('territory', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    local zone = args[2] or 'city'
    if action == 'capture' then
        if not player.faction then return send(source, 'Join/create a faction first.') end
        if not state.territories[zone] then return send(source, 'Unknown territory.') end
        if capturers[zone] then return send(source, 'This territory is already being captured.') end
        capturers[zone] = source
        send(source, ('Capturing %s... stay active for %ds'):format(zone, Config.Sandbox.TerritoryCaptureSeconds))
        SetTimeout(Config.Sandbox.TerritoryCaptureSeconds * 1000, function()
            if capturers[zone] == source then
                state.territories[zone].owner = player.faction
                capturers[zone] = nil
                broadcast(('%s captured %s for faction %s.'):format(player.name, zone, player.faction))
                saveState()
            end
        end)
    else
        for key, value in pairs(state.territories) do
            send(source, ('%s owner: %s (%s)'):format(key, value.owner or 'none', value.bonus))
        end
    end
end)

RegisterCommand('bank', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    local amount = math.max(0, tonumber(args[2]) or 0)
    if action == 'deposit' then
        if not transferToBank(player, amount) then return send(source, 'Not enough cash to deposit.') end
        send(source, ('Deposited $%d.'):format(amount))
    elseif action == 'withdraw' then
        if not takeFromBank(player, amount) then return send(source, 'Not enough bank funds.') end
        send(source, ('Withdrew $%d.'):format(amount))
    elseif action == 'loan' then
        local loanAmount = math.max(1000, amount)
        player.loans = player.loans + loanAmount
        player.bank = player.bank + loanAmount
        send(source, ('Loan approved for $%d.'):format(loanAmount))
    elseif action == 'insurance' then
        player.insurance.vehicle = true
        player.insurance.property = true
        player.bank = math.max(0, player.bank - 750)
        send(source, 'Vehicle + property insurance activated.')
    else
        send(source, ('Cash:$%d Bank:$%d Loans:$%d'):format(player.cash, player.bank, player.loans))
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('skill', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local skill = args[1]
    if not skill or not Config.Sandbox.Skills[skill] then
        local available = {}
        for name in pairs(Config.Sandbox.Skills) do
            table.insert(available, name)
        end
        return send(source, 'Usage: /skill <' .. table.concat(available, '|') .. '>')
    end
    local meta = Config.Sandbox.Skills[skill]
    if player.skills[skill] >= meta.max then return send(source, 'Skill already maxed.') end
    local cost = meta.cost * (player.skills[skill] + 1)
    if player.cash < cost then return send(source, ('Need $%d to upgrade %s.'):format(cost, skill)) end
    player.cash = player.cash - cost
    player.skills[skill] = player.skills[skill] + 1
    send(source, ('%s upgraded to %d.'):format(skill, player.skills[skill]))
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('project', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'status'
    if action == 'contribute' then
        local amount = math.max(100, tonumber(args[2]) or 100)
        if player.cash < amount then return send(source, 'Not enough cash to contribute.') end
        player.cash = player.cash - amount
        state.communityProject.progress = state.communityProject.progress + amount
        if state.communityProject.progress >= state.communityProject.goal and not state.communityProject.completed then
            state.communityProject.completed = true
            broadcast(('Community project completed: %s'):format(state.communityProject.name))
        end
        send(source, ('Contributed $%d to project.'):format(amount))
    else
        send(source, ('Project %s: $%d / $%d'):format(state.communityProject.name, state.communityProject.progress, state.communityProject.goal))
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('season', function(source, args)
    if source == 0 then return end
    local id, player = getPlayerState(source)
    local action = args[1] or 'status'
    if action == 'join' then
        state.season.participants[id] = true
        send(source, ('Joined %s.'):format(state.season.name))
    elseif action == 'claim' then
        if state.season.participants[id] and not state.season.rewardClaimed[id] then
            player.bank = player.bank + Config.Sandbox.SeasonReward
            state.season.rewardClaimed[id] = true
            send(source, ('Claimed season reward: $%d'):format(Config.Sandbox.SeasonReward))
        else
            send(source, 'No reward available yet.')
        end
    else
        send(source, ('Season: %s | Joined: %s'):format(state.season.name, tostring(state.season.participants[id] == true)))
    end
    saveState()
    TriggerClientEvent('sandbox:updateHUD', source, player)
end)

RegisterCommand('contract', function(source, args)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    local action = args[1] or 'new'
    if action == 'new' then
        local opts = {
            { type = 'delivery', goal = math.random(1, 3), reward = 900 },
            { type = 'fishing', goal = math.random(2, 6), reward = 800 },
            { type = 'gather', goal = math.random(3, 8), reward = 750 }
        }
        local pick = opts[math.random(1, #opts)]
        contracts[source] = { type = pick.type, goal = pick.goal, progress = 0, reward = pick.reward }
        send(source, ('Contract: %s x%d reward $%d'):format(pick.type, pick.goal, pick.reward))
    elseif action == 'complete' then
        local c = contracts[source]
        if not c then return send(source, 'No active contract.') end
        c.progress = c.goal
        player.cash = player.cash + c.reward
        contracts[source] = nil
        send(source, ('Contract completed! +$%d'):format(c.reward))
        saveState()
        TriggerClientEvent('sandbox:updateHUD', source, player)
    else
        local c = contracts[source]
        if not c then return send(source, 'No active contract.') end
        send(source, ('Contract %s: %d/%d'):format(c.type, c.progress, c.goal))
    end
end)

RegisterCommand('sandboxstatus', function(source)
    if source == 0 then return end
    local _, player = getPlayerState(source)
    TriggerClientEvent('sandbox:updateHUD', source, player)
    commandHelp(source)
end)
