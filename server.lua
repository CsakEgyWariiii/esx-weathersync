ESX = exports["es_extended"]:getSharedObject()
local CurrentWeather = Config.StartWeather
local baseTime = Config.BaseTime
local timeOffset = Config.TimeOffset
local freezeTime = Config.FreezeTime
local blackout = Config.Blackout
local newWeatherTimer = Config.NewWeatherTimer

--- Is the source a client or the server
--- @param src string | number - source to check
--- @return int - source
local function getSource(src)
    if src == '' then
        return 0
    end
    return src
end

--- Does source have permissions to run admin commands
--- @param src number - Source to check
--- @return boolean - has permission

--- Sets time offset based on minutes provided
--- @param minute number - Minutes to offset by
local function shiftToMinute(minute)
    timeOffset = timeOffset - (((baseTime + timeOffset) % 60) - minute)
end

--- Sets time offset based on hour provided
--- @param hour number - Hour to offset by
local function shiftToHour(hour)
    timeOffset = timeOffset - ((((baseTime + timeOffset) / 60) % 24) - hour) * 60
end

--- Triggers event to switch weather to next stage
local function nextWeatherStage()
    if CurrentWeather == "CLEAR" or CurrentWeather == "CLOUDS" or CurrentWeather == "EXTRASUNNY" then
        CurrentWeather = (math.random(1, 5) > 2) and "CLEARING" or "OVERCAST" -- 60/40 chance
    elseif CurrentWeather == "CLEARING" or CurrentWeather == "OVERCAST" then
        local new = math.random(1, 6)
        if new == 1 then CurrentWeather = (CurrentWeather == "CLEARING") and "FOGGY" or "RAIN"
        elseif new == 2 then CurrentWeather = "CLOUDS"
        elseif new == 3 then CurrentWeather = "CLEAR"
        elseif new == 4 then CurrentWeather = "EXTRASUNNY"
        elseif new == 5 then CurrentWeather = "SMOG"
        else CurrentWeather = "FOGGY"
        end
    elseif CurrentWeather == "THUNDER" or CurrentWeather == "RAIN" then CurrentWeather = "CLEARING"
    elseif CurrentWeather == "SMOG" or CurrentWeather == "FOGGY" then CurrentWeather = "CLEAR"
    else CurrentWeather = "CLEAR"
    end
    TriggerEvent("qb-weathersync:server:RequestStateSync")
end

--- Switch to a specified weather type
--- @param weather string - Weather type from Config.AvailableWeatherTypes
--- @return boolean - success
local function setWeather(weather)
    local validWeatherType = false
    for _, weatherType in pairs(Config.AvailableWeatherTypes) do
        if weatherType == string.upper(weather) then
            validWeatherType = true
        end
    end
    if not validWeatherType then return false end
    CurrentWeather = string.upper(weather)
    newWeatherTimer = Config.NewWeatherTimer
    TriggerEvent('qb-weathersync:server:RequestStateSync')
    return true
end

--- Sets sun position based on time to specified
--- @param hour number|string - Hour to set (0-24)
--- @param minute number|string `optional` - Minute to set (0-60)
--- @return boolean - success
local function setTime(hour, minute)
    local argh = tonumber(hour)
    local argm = tonumber(minute) or 0
    if argh == nil or argh > 24 then
        print('Ismeretlen idő formátum')
        return false
    end
    shiftToHour((argh < 24) and argh or 0)
    shiftToMinute((argm < 60) and argm or 0)
    TriggerEvent('qb-weathersync:server:RequestStateSync')
    return true
end

--- Sets or toggles blackout state and returns the state
--- @param state boolean `optional` - enable blackout?
--- @return boolean - blackout state
local function setBlackout(state)
    if state == nil then state = not blackout end
    if state then blackout = true
    else blackout = false end
    TriggerEvent('qb-weathersync:server:RequestStateSync')
    return blackout
end

--- Sets or toggles time freeze state and returns the state
--- @param state boolean `optional` - Enable time freeze?
--- @return boolean - Time freeze state
local function setTimeFreeze(state)
    if state == nil then state = not freezeTime end
    if state then freezeTime = true
    else freezeTime = false end
    TriggerEvent('qb-weathersync:server:RequestStateSync')
    return freezeTime
end

--- Sets or toggles dynamic weather state and returns the state
--- @param state boolean `optional` - Enable dynamic weather?
--- @return boolean - Dynamic Weather state
local function setDynamicWeather(state)
    if state == nil then state = not Config.DynamicWeather end
    if state then Config.DynamicWeather = true
    else Config.DynamicWeather = false end
    TriggerEvent('qb-weathersync:server:RequestStateSync')
    return Config.DynamicWeather
end

-- EVENTS
RegisterNetEvent('qb-weathersync:server:RequestStateSync', function()
    TriggerClientEvent('qb-weathersync:client:SyncWeather', -1, CurrentWeather, blackout)
    TriggerClientEvent('qb-weathersync:client:SyncTime', -1, baseTime, timeOffset, freezeTime)
end)

RegisterNetEvent('qb-weathersync:server:setWeather', function(weather)
    local src = getSource(source)
        local success = setWeather(weather)
        if src > 0 then
            if (success) then TriggerClientEvent ('codem-notification:Create', source, '🌞 Időjárás átállítva ' ..weather..' -re', 'info', nil, 5000)
            else TriggerClientEvent ('codem-notification:Create', source, '🌞 Ismeretlen időjárás', 'info', nil, 5000)
            end
        end
end)

RegisterNetEvent('qb-weathersync:server:setTime', function(hour, minute)
    local src = getSource(source)
        local success = setTime(hour, minute)
        if src > 0 then
            if (success) then TriggerClientEvent ('codem-notification:Create', source, 'Idő átállítva ' ..hour.. ':' ..minute or "00", 'info', nil, 5000)
            else TriggerClientEvent ('codem-notification:Create', src, 'Ismeretlen időformátum', 'info', nil, 5000)
            end
        end
end)

RegisterNetEvent('qb-weathersync:server:toggleBlackout', function(state)
    local src = getSource(source)
        local newstate = setBlackout(state)
        if src > 0 then
            if (newstate) then TriggerClientEvent ('codem-notification:Create', src, '🟢 Blackout bekapcsolva', 'info', nil, 5000)
            else TriggerClientEvent ('codem-notification:Create', src, '🔴 Blackout kikapcsolva', 'info', nil, 5000)
            end
        end
end)

RegisterNetEvent('qb-weathersync:server:toggleFreezeTime', function(state)
    local src = getSource(source)
        local newstate = setTimeFreeze(state)
        if src > 0 then
            if (newstate) then TriggerClientEvent ('codem-notification:Create', src, '🟢 Idő lefagyasztva', 'info', nil, 5000)
            else TriggerClientEvent ('codem-notification:Create', src, '🔴 Idő fagyasztás kikapcsolva', 'info', nil, 5000)
            end
        end
end)

RegisterNetEvent('qb-weathersync:server:toggleDynamicWeather', function(state)
    local src = getSource(source)
        local newstate = setDynamicWeather(state)
        if src > 0 then
            if (newstate) then TriggerClientEvent ('codem-notification:Create', src, '🔴 Idő fagyasztás kikapcsolva', 'info', nil, 5000)
            else TriggerClientEvent ('codem-notification:Create', src, '🟢 Idő lefagyasztva', 'info', nil, 5000)
            end
        end
end)

-- COMMANDS


RegisterCommand("freezetime", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local newstate = setTimeFreeze()
    local group = xPlayer.getGroup()
    if group == 'tulajdonos' then
        if source > 0 then
            if (newstate) then return TriggerClientEvent ('codem-notification:Create', source, '🟢 Idő lefagyasztva', 'info', nil, 5000) end
            return TriggerClientEvent ('codem-notification:Create', source, '🔴 Idő fagyasztás kikapcsolva', 'info', nil, 5000)
        end
        if (newstate) then return print('🟢 Idő lefagyasztva') end
        return print('🔴 Idő fagyasztás kikapcsolva')
    end
end, true) 

RegisterCommand("freezeweather", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local newstate = setDynamicWeather()
    if group == 'tulajdonos' then
        if source > 0 then
            if (newstate) then return TriggerClientEvent ('codem-notification:Create', source, '🟢 Dinamikus időjárás bekapcsolva', 'info', nil, 5000) end
            return TriggerClientEvent ('codem-notification:Create', source, '🔴 Dinamikus időjárás kikapcsolva', 'info', nil, 5000)
        end
        if (newstate) then return print('🔴 Dinamikus időjárás kikapcsolva') end
        return print('🟢 Dinamikus időjárás bekapcsolva')
    end
end, true) 

RegisterCommand("weather", function(source, args)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local success = setWeather(args[1])
    if group == 'tulajdonos' then
        if source > 0 then
            if (success) then return TriggerClientEvent ('codem-notification:Create', source, '🌞 Időjárás átállítva ' ..string.lower(args[1])..' -ra', 'info', nil, 5000) end
            return TriggerClientEvent ('codem-notification:Create', source, '🌞 Ismeretlen időjárás', 'info', nil, 5000)
        end
        if (success) then return print('🌞 Időjárás átállítva ' ..string.lower(args[1])..' -ra') end
        return print("Ismeretlen időjárás")
    end
end, true) 

RegisterCommand("blackout", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local newstate = setBlackout()
    if group == 'tulajdonos' then
        if source > 0 then
            if (newstate) then return TriggerClientEvent ('codem-notification:Create', source, '🟢 Blackout bekapcsolva', 'info', nil, 5000) end
            return TriggerClientEvent ('codem-notification:Create', source, '🔴 Blackout kikapcsolva', 'info', nil, 5000)
        end
        if (newstate) then return print('🟢 Blackout bekapcsolva') end
        return print('🔴 Blackout kikapcsolva')
    end
end, true) 

RegisterCommand("morning", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    if group == 'tulajdonos' then
        setTime(9, 0)
    if source > 0 then return TriggerClientEvent ('codem-notification:Create', source, 'Az idő átállítva reggelre', 'info', nil, 5000) end
    end
end, true) 

RegisterCommand("noon", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    if group == 'tulajdonos' then
        setTime(12, 0)
    if source > 0 then return TriggerClientEvent ('codem-notification:Create', source, 'Az idő átállítva délre', 'info', nil, 5000) end
    end
end, true) 


RegisterCommand("evening", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    if group == 'tulajdonos' then
        setTime(18, 0)
        if source > 0 then return TriggerClientEvent ('codem-notification:Create', source, 'Az idő átállítva délutánra', 'info', nil, 5000) end
    end
end, true) 

RegisterCommand("night", function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    if group == 'tulajdonos' then
        setTime(23, 0)
    if source > 0 then return TriggerClientEvent ('codem-notification:Create', source, 'Az idő átállítva estére', 'info', nil, 5000) end
    end
end, true) 

RegisterCommand("time", function(source, args)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local success = setTime(args[1], args[2])
    if group == 'tulajdonos' then
        if source > 0 then
            if (success) then return TriggerClientEvent ('codem-notification:Create', source, 'Idő átállítva ' ..args[1] .. ':' .. (args[2] or "00"), 'info', nil, 5000) end
            return TriggerClientEvent ('codem-notification:Create', source, 'Ismeretlen időformátum', 'info', nil, 5000)
        end
        if (success) then return print('Idő átállítva ' ..args[1] .. ':' .. (args[2] or "00")) end
        return print('Ismeretlen időformátum')
    end
end, true) 

-- THREAD LOOPS
CreateThread(function()
    local previous = 0
    while true do
        Wait(0)
        local newBaseTime = os.time(os.date("!*t")) / 2 + 360 --Set the server time depending of OS time
        if (newBaseTime % 60) ~= previous then --Check if a new minute is passed
            previous = newBaseTime % 60 --Only update time with plain minutes, seconds are handled in the client
            if freezeTime then
                timeOffset = timeOffset + baseTime - newBaseTime
            end
            baseTime = newBaseTime
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)--Change to send every minute in game sync
        TriggerClientEvent('qb-weathersync:client:SyncTime', -1, baseTime, timeOffset, freezeTime)
    end
end)

CreateThread(function()
    while true do
        Wait(300000)
        TriggerClientEvent('qb-weathersync:client:SyncWeather', -1, CurrentWeather, blackout)
    end
end)

CreateThread(function()
    while true do
        newWeatherTimer = newWeatherTimer - 1
        Wait((1000 * 60) * Config.NewWeatherTimer)
        if newWeatherTimer == 0 then
            if Config.DynamicWeather then
                nextWeatherStage()
            end
            newWeatherTimer = Config.NewWeatherTimer
        end
    end
end)

-- EXPORTS
exports('nextWeatherStage', nextWeatherStage)
exports('setWeather', setWeather)
exports('setTime', setTime)
exports('setBlackout', setBlackout)
exports('setTimeFreeze', setTimeFreeze)
exports('setDynamicWeather', setDynamicWeather)
exports('getBlackoutState', function() return blackout end)
exports('getTimeFreezeState', function() return freezeTime end)
exports('getWeatherState', function() return CurrentWeather end)
exports('getDynamicWeather', function() return Config.DynamicWeather end)

exports('getTime', function()
    local hour = math.floor(((baseTime+timeOffset)/60)%24)
    local minute = math.floor((baseTime+timeOffset)%60)

    return hour,minute
end)
