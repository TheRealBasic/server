local sandboxHud = {
    visible = false,
    lines = {}
}

RegisterNetEvent('sandbox:updateHUD', function(profile)
    sandboxHud.lines = {
        ('Cash: $%d | Bank: $%d'):format(profile.cash or 0, profile.bank or 0),
        ('Home T%s | Biz T%s | Garage Slots %s'):format(
            profile.housing and profile.housing.tier or 0,
            profile.business and profile.business.tier or 0,
            profile.garage and profile.garage.slots or 0
        ),
        ('Faction: %s | Loans: $%d'):format(profile.faction or 'none', profile.loans or 0)
    }
    sandboxHud.visible = true
end)

CreateThread(function()
    Wait(1200)
    TriggerServerEvent('sandbox:clientReady')
end)

RegisterCommand('sandboxhud', function()
    sandboxHud.visible = not sandboxHud.visible
    local msg = sandboxHud.visible and 'Sandbox HUD enabled' or 'Sandbox HUD hidden'
    TriggerEvent('chat:addMessage', { args = { '^2Sandbox', msg } })
end, false)

CreateThread(function()
    while true do
        Wait(0)
        if sandboxHud.visible then
            local x = 0.015
            local y = 0.72
            for i, line in ipairs(sandboxHud.lines) do
                SetTextFont(4)
                SetTextScale(0.30, 0.30)
                SetTextColour(120, 255, 180, 190)
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(line)
                DrawText(x, y + (i - 1) * 0.022)
            end
        else
            Wait(200)
        end
    end
end)
