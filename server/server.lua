
Sx = {}
Sx.warns = {}
Sx.players = {}
i = 0
while i < 65 do
    Sx.warns[i] = tonumber(0)
    Sx.players[i] = false
    i = i +1 
end

Sx.version = "1.4" 

RegisterNetEvent("SX:onStartingScript")

AddEventHandler("SX:onStartingScript", function()
    print ("^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=")
    print ("[^5SXAdmin^7] Script Loaded Correctly - Version: ^5" .. Sx.version)
    print ("^7Script Developed by ^5DoktorSAS")
    print ("^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=")
    print ("If there any problems report it on discord")
    print ("Dsicord: Discord.io/Sorex on google")
    print ("^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=^1=^7=")
end)

TriggerEvent("SX:onStartingScript")

-- When Player Connect

local function OnPlayerConnecting(name, setKickReason, deferrals)
    print(name .. " ^3Joined the server^7")
    local _source = source
    local identifier = GetPlayerIdentifier(_source)
    local number_of_user = 1
    deferrals.defer()
    -- mandatory wait!
    Wait(0)
    -- addchatmessage( name .. " Welcome to " .. server_name)
    -- addchatmessage("This server have a total of " .. number_of_user)
    MySQL.Async.fetchAll(
        "SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier",
        {['@identifier'] = identifier},
        function (results)
            if Config.LOGBot then
                MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = name, ['@msg'] = "Connected to the server", ['@typology'] = "Connect"})
            end
            MySQL.Async.execute("UPDATE sx_adminclients SET fristtime = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = identifier})
            if results[1] == nil then
                MySQL.Async.fetchAll("INSERT INTO sx_adminclients (identifier, username) VALUES(@identifier, @username)",     
                {["@identifier"] = identifier, ["@username"] = name})
            end
        end)
    deferrals.done()
end

function addchatmessage(msg)
    TriggerClientEvent("chatMessage",  -1 ,"[^5SXAdmin^7]", {255,255,255}, msg)
end

AddEventHandler("playerConnecting", OnPlayerConnecting)

-- When player Disconnect

AddEventHandler('playerDropped', function (reason)
    print('^3Player ^5' .. GetPlayerName(source) .. " ^3left the game^7")
    if Config.LOGBot then
        MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(source), ['@msg'] = "Disconnected to the server", ['@typology'] = "Disconnect"})
    end
    local player_ped =  GetPlayerPed(source)
	local player_pos = GetEntityCoords(player_ped)
    local identifier = GetPlayerIdentifier(source)
    Sx.players[source] = false
	MySQL.Async.execute("UPDATE sx_adminclients SET disconnect_x = @x , disconnect_y = @y , disconnect_z = @z WHERE identifier LIKE @identifier " , {['@identifier'] = identifier , ['@x'] = player_pos.x , ['@y'] = player_pos.y , ['@z'] = player_pos.z})
end)

-- Spawn Manager
RegisterNetEvent('SX:Spawn', name)
AddEventHandler('SX:Spawn', function (name)
    local _source = source
    if Sx.players[_source] == false then
        Sx.players[_source] = true
    end
    MySQL.Async.fetchAll(
        "SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier",
        {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            MySQL.Async.execute("UPDATE sx_adminclients SET  TempBanned = DATEDIFF(NOW() , banned_date) WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)})
            MySQL.Async.fetchAll(
                "SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier",
                {['@identifier'] = GetPlayerIdentifier(_source)},
                function (results)
                    if tonumber(results[1].TempBanned) < 0 and results[1].TempBanned ~= nil then
                        n = -2
                        for _, playerId in ipairs(GetPlayers()) do
                            if GetPlayerName(playerId) == results[1].username then
                                n = playerId
                                if Config.LOGBot then
                                    MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(playerId), ['@msg'] = "Kicked because he/she is banned", ['@typology'] = "Spawn"})
                                end
                                print ("Player kicked because he is banned -> " .. GetPlayerName(playerId))
                                DropPlayer(playerId, results[1].reason)   
                            end
                        end 
                    else
                       -- TriggerClientEvent('SX:Teleport_to_cords', _source, results[1].disconnect_x, results[1].disconnect_y, results[1].disconnect_z)
                    end

                end)
            if results[1].frist_connection == false and Config.FristSpawnOnHUB then
                MySQL.Async.execute("UPDATE sx_adminclients SET frist_connection = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(_source)})
                print ("Player teleported: " .. GetPlayerName(_source))
                TriggerClientEvent('SX:Teleport_to_spawn', _source)
            end
            if results[1].fristtime == true and Config.SpawnOnDisconnectedPos then
                print(results[1].disconnect_x)
                MySQL.Async.execute("UPDATE sx_adminclients SET fristtime = @res WHERE identifier LIKE @identifier", {['@res'] = false, ['@identifier'] = GetPlayerIdentifier(_source)})
                TriggerClientEvent('SX:Teleport_to_cords', _source, results[1].disconnect_x, results[1].disconnect_y, results[1].disconnect_z)
            end
            if results[1].permanentBan == true then
                n = -2
                for _, playerId in ipairs(GetPlayers()) do
                    if GetPlayerName(playerId) == results[1].username then
                        n = playerId
                    end
                end 
                DropPlayer(n, results[1].reason)   
            end
		end)
end)

-- Commands Manager
RegisterServerEvent('announce')
AddEventHandler('announce', function( param )
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group >= 3 then
                print('^7[^1Announcement^7]^5:'.. param)
                TriggerClientEvent('chatMessage', -1, '^7[^1Announcement^7]^2', {0,0,0}, param .. "^7")
            end
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
        end)
end)

RegisterServerEvent('SX:kick')
AddEventHandler('SX:kick', function( player_to_kick , reason)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            if results[1].sx_group >= 3 then
                validate = true
                kicked = true
                if player_to_kick == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing player name or player id of the player to kick")
                    validate = false
                end
                if string.len(player_to_kick) > 2 and validate then
                    validate = true
                    c = 0
                    id = -2
                    for _, playerId in ipairs(GetPlayers()) do
                        local name = GetPlayerName(playerId)
                        if string.match(name, player_to_kick) then
                            c = c + 1
                            id = playerId
                            TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "["..playerId.."]".. name .. "^7")
                        end
                    end
                    if reason == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                        validate = false
                    end
                    if c > 1 then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "There more players with similar name, use the id to kick him^7")
                        for _, playerId in ipairs(GetPlayers()) do
                            local name = GetPlayerName(playerId)
                            if string.match(name, player_to_warn) then
                                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "[ID: "..playerId.." ]".. name .. "^7")
                            end
                        end
                    end
                    if c == 1 and validate then
                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(id) .. " has been kicked for " .. reason)
                        if Config.LOGBot then
                            MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(id), ['@msg'] = "Kicked from the server for " .. reason, ['@typology'] = "Kick"})
                        end
                        DropPlayer(id, reason)
                        kicked = false
                    end
                elseif validate then
                    if reason == nil and reason == "" then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                        validate = false
                    end
                    if validate then
                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(player_to_kick) .. " has been kicked for " .. reason)
                        if Config.LOGBot then
                            MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(player_to_kick), ['@msg'] = "Kicked from the server for " .. reason, ['@typology'] = "Kick"})
                        end
                        DropPlayer(player_to_kick, reason)
                    end
                end
            end
        end)
end)

RegisterServerEvent('SX:ban')
AddEventHandler('SX:ban', function( player_to_ban , reason)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            if results[1].sx_group >= 4 then
                validate = true
                kicked = true
                if player_to_ban == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing player name or player id of the player to ban")
                    validate = false
                end
                if string.len(player_to_ban) > 2 and validate then
                    c = 0
                    id = -2
                    for _, playerId in ipairs(GetPlayers()) do
                        n = ""
                        local name = GetPlayerName(playerId)
                        if string.match(name, player_to_ban) then
                            c = c + 1
                            id = playerId
                            n = name
                            TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "["..playerId.."]".. name .. "^7")
                        end
                    end
                    if reason == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                        validate = false
                    end
                    if c > 1 then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "There more players with similar name, use the id to ban him^7")
                        for _, playerId in ipairs(GetPlayers()) do
                            local name = GetPlayerName(playerId)
                            if string.match(name, player_to_warn) then
                                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "[ID: "..playerId.." ]".. name .. "^7")
                            end
                        end
                    end
                    if c == 1 and validate then
                        MySQL.Async.execute("UPDATE sx_adminclients SET permanentBan = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        MySQL.Async.execute("UPDATE sx_adminclients SET reason = @reason WHERE identifier LIKE @identifier", {['@reason'] = reason, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(id) .. " has been kicked for " .. reason)
                        if Config.LOGBot then
                            MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(id), ['@msg'] = "Banned from the server for " .. reason, ['@typology'] = "Ban"})
                        end
                        DropPlayer(id, reason)
                        kicked = false
                    end
                elseif validate then
                    if reason == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                        validate = false
                    end
                    if validate and kicked then
                        n = ""
                        id = -2
                        for _, playerId in ipairs(GetPlayers()) do
                            if playerId == player_to_ban then
                                n = GetPlayerName(playerId)
                                id = playerId
                            end
                        end 
                        MySQL.Async.execute("UPDATE sx_adminclients SET permanentBan = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        MySQL.Async.execute("UPDATE sx_adminclients SET reason = @reason WHERE identifier LIKE @identifier", {['@reason'] = reason, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        if Config.LOGBot then
                            MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(player_to_ban), ['@msg'] = "Banned from the server for " .. reason, ['@typology'] = "Ban"})
                        end
                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(player_to_ban) .. " has been kicked for " .. reason)
                        DropPlayer(player_to_ban, reason)
                    end
                end
            end
        end)
end)


RegisterServerEvent('SX:banID')
AddEventHandler('SX:banID', function( player_to_ban , reason)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 4 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            elseif results[1].sx_group > 4 then
                MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
                function (results)
                if player_to_ban == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing player name or player id of the player to ban")
                else
                MySQL.Async.execute("UPDATE sx_adminclients SET permanentBan = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                MySQL.Async.execute("UPDATE sx_adminclients SET reason = @reason WHERE identifier LIKE @identifier", {['@reason'] = reason, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(id) .. " has been kicked for " .. reason)
                    for _, playerId in ipairs(GetPlayers()) do
                        if GetPlayerName(playerId) == results[1].username then
                            DropPlayer(id, reason)
                            if Config.LOGBot then
                                MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = results[1].username, ['@msg'] = "Banned from the server for " .. reason, ['@typology'] = "Ban"})
                            end
                            break
                        end
                    end
                end 
            end)
        end
        end)
end)

RegisterServerEvent('SX:TempBanID')
AddEventHandler('SX:TempBanID', function( player_to_tempban, time, type, reason)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")  
            elseif results[1].sx_group >= 3 then
                MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE ID LIKE @identifier", {['@identifier'] = player_to_tempban },
                function (res)
                    print (res[1].username)
                    validate = true
                    if reason == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                        validate = false
                    elseif time == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason time")
                        validate = false
                    elseif type == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing type of the time")
                        validate = false
                    elseif player_to_tempban == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing player ID")
                        validate = false
                    end
                    if type == "d" and validate then
                        MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time DAY WHERE ID LIKE @identifier", {['time'] = time, ['@identifier'] = res[1].ID})
                        MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE ID LIKE @identifier", {['@res'] = true, ['@identifier'] = res[1].ID})
                    elseif type == "w" then
                        MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time DAY WHERE ID LIKE @identifier", {['time'] = time*7, ['@identifier'] = res[1].ID})
                        MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE ID LIKE @identifier", {['@res'] = true, ['@identifier'] = res[1].ID})
                    elseif type == "m" then
                        MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time MONTH WHERE ID LIKE @identifier", {['time'] = time, ['@identifier'] = res[1].ID})
                        MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE ID LIKE @identifier", {['@res'] = true, ['@identifier'] = res[1].ID})
                    elseif type == "h" then
                        MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time HOUR WHERE ID LIKE @identifier", {['time'] = time, ['@identifier'] = res[1].ID})
                        MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE ID LIKE @identifier", {['@res'] = true, ['@identifier'] = res[1].ID})
                    elseif type == "mn" then
                        MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time MINUTE WHERE ID LIKE @identifier", {['time'] = time, ['@identifier'] = res[1].ID})
                        MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE ID LIKE @identifier", {['@res'] = true, ['@identifier'] = res[1].ID})
                    elseif type ~= "d" and type ~= "w" and type ~= "m" and type ~= "h" and type ~= "mn" then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "The type of the ban is not valid {d = day, w = week, m = month, h = hours, mn = minutes}")
                    end
                    MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE ID LIKE @identifier", {['@res'] = true, ['@identifier'] = res[1].ID})
                    MySQL.Async.execute("UPDATE sx_adminclients SET reason = @reason WHERE ID LIKE @identifier", {['@reason'] = reason, ['@identifier'] = res[1].ID})
                    MySQL.Async.execute("UPDATE sx_adminclients SET  TempBanned = DATEDIFF(NOW() , banned_date) WHERE ID LIKE @identifier", {['@identifier'] = res[1].ID})
                    if Config.LOGBot then
                    TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, res[1].username .. " has been kicked for " .. reason)
                    end
                    if Config.LOGBot then
                        MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = res[1].username, ['@msg'] = "Temp Banned from the server for " .. reason, ['@typology'] = "Ban"})
                    end
                    for _, playerId in ipairs(GetPlayers()) do
                        if GetPlayerName(playerId) == res[1].username then
                            DropPlayer(playerId, reason)
                            break
                        end
                    end  
                    end)
            end
        end)
end)

RegisterServerEvent('SX:TempBan')
AddEventHandler('SX:TempBan', function( player_to_tempban, time, type, reason)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            if results[1].sx_group >= 3 then
                validate = true
                kicked = true
                if player_to_tempban == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing player name or player id of the player to ban")
                    validate = false
                end
                if reason == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                    validate = false
                end
                if tonumber(time) < tonumber(0) or time == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing time or not valid time value")
                    validate = false
                end
                if string.len(player_to_tempban) > 2 and validate then
                    c = 0
                    id = -2
                    for _, playerId in ipairs(GetPlayers()) do
                        n = ""
                        local name = GetPlayerName(playerId)
                        if string.match(name, player_to_tempban) then
                            c = c + 1
                            id = playerId
                            n = name
                        end
                    end
                    if c > 1 then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "There more players with similar name, use the id to temp ban him^7")
                        for _, playerId in ipairs(GetPlayers()) do
                            local name = GetPlayerName(playerId)
                            if string.match(name, player_to_warn) then
                                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "[ID: "..playerId.." ]".. name .. "^7")
                            end
                        end
                    end
                    if c == 1 and validate then
                        if type == "d" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time DAY WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "w" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time DAY WHERE identifier LIKE @identifier", {['time'] = time*7, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "m" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time MONTH WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "h" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time HOUR WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "mn" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time MINUTE WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type ~= "d" and type ~= "w" and type ~= "m" and type ~= "h" and type ~= "mn" then
                            TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "The type of the ban is not valid {d = day, w = week, m = month, h = hours, mn = minutes}")
                        end
                        MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        MySQL.Async.execute("UPDATE sx_adminclients SET reason = @reason WHERE identifier LIKE @identifier", {['@reason'] = reason, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        MySQL.Async.execute("UPDATE sx_adminclients SET  TempBanned = DATEDIFF(NOW() , banned_date) WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(id)})
                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(id) .. " has been kicked for " .. reason)
                        if Config.LOGBot then
                            MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(id), ['@msg'] = "Temp Banned from the server for " .. reason, ['@typology'] = "Temp Ban"})
                        end
                        DropPlayer(id, reason)
                        kicked = false
                    end
                elseif validate then
                    if validate and kicked then
                        n = ""
                        id = -2
                        for _, playerId in ipairs(GetPlayers()) do
                            if playerId == player_to_tempban then
                                n = GetPlayerName(playerId)
                                id = playerId
                            end
                        end 
                        if type == "d" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time DAY WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "w" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time DAY WHERE identifier LIKE @identifier", {['time'] = time*7, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "m" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time MONTH WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "h" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time HOUR WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type == "mn" then
                            MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() + INTERVAL @time MINUTE WHERE identifier LIKE @identifier", {['time'] = time, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                        elseif type ~= "d" and type ~= "w" and type ~= "m" and type ~= "h" and type ~= "mn" then
                            TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "The type of the ban is not valid {d = day, w = week, m = month, h = hours, mn = minutes}")
                        end
                            MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = @res WHERE identifier LIKE @identifier", {['@res'] = true, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET reason = @reason WHERE identifier LIKE @identifier", {['@reason'] = reason, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                            MySQL.Async.execute("UPDATE sx_adminclients SET  TempBanned = DATEDIFF(NOW() , banned_date) WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(id)})
                            TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, GetPlayerName(player_to_tempban) .. " has been kicked for " .. reason)
                            if Config.LOGBot then
                                MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(player_to_tempban), ['@msg'] = "Temp Banned from the server for " .. reason, ['@typology'] = "Temp Ban"})
                            end
                            DropPlayer(player_to_tempban, reason)
                    end
                end
            end
        end)
end)
-- Show Moderators online
local AdminsText = ""
RegisterServerEvent('SX:Admins')
AddEventHandler('SX:Admins', function()
    local _source = source
    TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, "Moderators ^2ONLINE^7:" )
    for _, playerId in ipairs(GetPlayers()) do
        name = GetPlayerName(playerId)
        MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group == 2 then
               AdminsText  ="^7["..Config.ranks.vip.."^7] "..name  
               TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, AdminsText )
            elseif results[1].sx_group == 3 then
               AdminsText  ="^7["..Config.ranks.mod.."^7] "..name 
               TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, AdminsText )
            elseif results[1].sx_group == 4 then
               AdminsText  ="^7["..Config.ranks.admin.."^7] "..name  
               TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, AdminsText )
            elseif results[1].sx_group == 5 then
               AdminsText  ="^7["..Config.ranks.senior_admin.."^7] "..name 
               TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, AdminsText ) 
            elseif results[1].sx_group == 6 then
               AdminsText  ="^7["..Config.ranks.owner.."^7] "..name  
               TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, AdminsText )
            end
        end)
    end
end)

-- Unban command
RegisterServerEvent('SX:unban')
AddEventHandler('SX:unban', function(player_to_unban)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group >= 5 then
                if player_to_unban == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                else
                    MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = 0 WHERE username LIKE @username", {['@username'] = player_to_unban})
                    MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() WHERE username LIKE @username", {['@username'] = player_to_unban})
                    MySQL.Async.execute("UPDATE sx_adminclients SET permanentBan = @res WHERE username LIKE @username", {['@res'] = false, ['@username'] = player_to_unban})
                    if Config.LOGBot then
                        MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(player_to_unban), ['@msg'] = "Unbanned from the server", ['@typology'] = "Unban"})
                    end
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, player_to_unban .. " has been unbanned" .. "^7")
                end
            else
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            
        end)
end)
RegisterServerEvent('SX:unbanID')
AddEventHandler('SX:unbanID', function(player_to_unban)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group >= 5 then
                if player_to_unban == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                else
                    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE ID LIKE @ID", {['@ID'] = player_to_unban},
                        function (results)
                            if results[1] == nil then
                            else
                                MySQL.Async.execute("UPDATE sx_adminclients SET TempBanned = 0 WHERE ID LIKE @ID", {['@ID'] = player_to_unban})
                                MySQL.Async.execute("UPDATE sx_adminclients SET banned_date = NOW() WHERE ID LIKE @ID", {['@ID'] = player_to_unban})
                                MySQL.Async.execute("UPDATE sx_adminclients SET permanentBan = @res WHERE ID LIKE @ID", {['@res'] = false, ['@ID'] = player_to_unban})
                                if Config.LOGBot then
                                    MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = results[1].username, ['@msg'] = "Unbanned from the server", ['@typology'] = "Unban"})
                                end
                                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, results[1].username .. " has been unbanned" .. "^7")
                            end
                        end)
                end
            else
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            
        end)
end)
-- Warn command
RegisterServerEvent('SX:WarnServer')
AddEventHandler('SX:WarnServer', function(player_to_warn, reason)
    local _source = source
    print ("Ciao!")
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            if results[1].sx_group > 3 then
                validate = true
                kicked = true
                
                if player_to_warn == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                    validate = false
                elseif string.len(player_to_warn) > 2 and validate then
                    c = 0
                    id = -2
                    for _, playerId in ipairs(GetPlayers()) do
                        n = ""
                        local name = GetPlayerName(playerId)
                        if string.match(name, player_to_warn) then
                            c = c + 1
                            id = playerId
                            n = name
                        end
                    end
                    if reason == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the kick")
                        validate = false
                    end
                    if c > 1 then
                        validate = false
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "There more players with similar name, use the id to warn him^7")
                        for _, playerId in ipairs(GetPlayers()) do
                            local name = GetPlayerName(playerId)
                            if string.match(name, player_to_warn) then
                                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "[ID: "..playerId.." ]".. name .. "^7")
                            end
                        end
                    end
                    if c == 1 and validate then
                        for _, playerId in ipairs(GetPlayers()) do
                            local name = GetPlayerName(playerId) 
                            if string.match(name, GetPlayerName(playerId)) then
                                if Sx.warns[tonumber(playerId)] >= 3 then
                                    TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, name .. " has been kicked for " .. reason .. " after a few of ^1Warns^7")
                                    Sx.warns[tonumber(playerId)] = tonumber(0)
                                    DropPlayer(playerId, reason)
                                else
                                Sx.warns[tonumber(playerId)] = tonumber(Sx.warns[tonumber(playerId)]) + 1
                                if Config.LOGBot then
                                    MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(playerId), ['@msg'] = "Warned for " .. reason, ['@typology'] = "Warn"})
                                end
                                if Sx.warns[tonumber(playerId)] == 3 then
                                    TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, "^7[^1" .. Sx.warns[tonumber(playerId)].. "^3!^5".. name .. "^7] Last Warn: " .. reason)
                                else
                                    TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, "^7[^1" .. Sx.warns[tonumber(playerId)].. "^3 !^5".. name .. "^7]" .. reason)
                                end
                                end
                            end
                        end
                        kicked = false
                    end
                else
                    if reason == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^7', {0,0,0}, "Missing reason of the warn")
                        validate = false
                    end
                    if player_to_warn == nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                        validate = false
                    end
                    if validate and kicked then
                        local p_to_w = GetPlayerName(player_to_warn)
                        for _, playerId in ipairs(GetPlayers()) do
                            local name = GetPlayerName(playerId)
                            if string.match(name, p_to_w) then
                                if Sx.warns[tonumber(playerId)] >= 3 then
                                    TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, name .. " has been kicked for " .. reason .. " after a few of ^1Warns^7")
                                    Sx.warns[tonumber(playerId)] = tonumber(0)
                                    DropPlayer(playerId, reason)
                                else
                                    Sx.warns[tonumber(playerId)] = tonumber(Sx.warns[tonumber(playerId)]) + 1
                                    if Config.LOGBot then
                                        MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = GetPlayerName(playerId), ['@msg'] = "Warned for " .. reason, ['@typology'] = "Warn"})
                                    end
                                    if Sx.warns[tonumber(playerId)] == 3 then
                                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, "^7[^1" .. Sx.warns[tonumber(playerId)].. "^3!^5".. name .. "^7] Last Warn: " .. reason)
                                    else
                                        TriggerClientEvent('chatMessage', -1, '^7[^5SXAdmin^7]^7', {0,0,0}, "^7[^1" .. Sx.warns[tonumber(playerId)].. "^3 !^5".. name .. "^7]" .. reason)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
end)

-- Setlevel
RegisterServerEvent('SX:LevelSet')
AddEventHandler('SX:LevelSet', function(player_name, level)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            if results[1].sx_group >= 6 then
                valid = false
                cont = 0
                id = -2
                name = ""
                for _, playerId in ipairs(GetPlayers()) do
                    if GetPlayerName(playerId) == player_name then
                        name = GetPlayerName(playerId)
                        valid = true
                        cont = cont + 1
                        id = playerId
                    end
                end 
                if player_name == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                    vali = false
                end
                if level == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                    vali = false
                end
                if valid and cont == 1 then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, player_name .. " changed level to ".. level .. "^7")
                    MySQL.Async.execute("UPDATE sx_adminclients SET sx_group = @res WHERE identifier LIKE @identifier", {['@res'] = level, ['@identifier'] = GetPlayerIdentifier(tonumber(id))})
                elseif valid == false then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, player_name .. " is not in the database or is not exist" .. "^7")
                else
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "There more players online with the same name" .. "^7")
                end
            end
        end)
end)

RegisterServerEvent('SX:LevelSetID')
AddEventHandler('SX:LevelSetID', function(player_name, level)
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
        function (results)
            if results[1].sx_group < 3 then
                TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "You dont have enught permissions" .. "^7")
            end
            if results[1].sx_group >= 6 then
                if player_name == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                    vali = false
                end
                if level == nil then
                    TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing the name of the player to unban" .. "^7")
                    vali = false
                end
                MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE ID LIKE @ID", {['@ID'] = player_name},
                function (results)
                    if results[1] ~= nil then
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, results[1].username .. " changed level to ".. level .. "^7")
                        MySQL.Async.execute("UPDATE sx_adminclients SET sx_group = @res WHERE ID LIKE @ID", {['@res'] = level, ['@ID'] = player_name})
                    else
                        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, results[1].username .. " is not in the database or is not exist" .. "^7")
                    end
                end)
            end
        end)
end)

-- Chat Handler
AddEventHandler('chatMessage', function(Source, Name, Msg)
    args = stringsplit(Msg, " ")
    CancelEvent()
    if Config.LOGBot then
        MySQL.Async.execute("INSERT INTO sx_log (username, msg, typology) VALUES(@username, @msg, @typology)", {['@username'] = Name, ['@msg'] = Msg, ['@typology'] = "Chat"})
    end
    if string.find(args[1], "/") then
        local cmd = args[1]
        table.remove(args, 1)
    else     
        local player = GetPlayerIdentifier(Source)
        MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(Source)},
        function (results)
            if results[1].sx_group <= 1 then 
                TriggerClientEvent('chatMessage', -1, "^7["..Config.ranks.user.."^7]" .. Name, { 255, 0, 0 }, Msg)           
            elseif results[1].sx_group == 2 then
                TriggerClientEvent('chatMessage', -1, "^7["..Config.ranks.vip.."^7]" .. Name, { 255, 0, 0 }, Msg) 
            elseif results[1].sx_group == 3 then
                TriggerClientEvent('chatMessage', -1, "^7["..Config.ranks.mod.."^7]" .. Name, { 255, 0, 0 }, Msg)
            elseif results[1].sx_group == 4 then
                TriggerClientEvent('chatMessage', -1, "^7["..Config.ranks.admin.."^7]" .. Name, { 255, 0, 0 }, Msg)
            elseif results[1].sx_group == 5 then
                TriggerClientEvent('chatMessage', -1, "^7["..Config.ranks.senior_admin.."^7]" .. Name, { 255, 0, 0 }, Msg)
            elseif results[1].sx_group == 6 then
                TriggerClientEvent('chatMessage', -1, "^7["..Config.ranks.owner.."^7]" .. Name, { 255, 0, 0 }, Msg)
            end
        end)
    end
end)

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- Language Manager System

RegisterServerEvent('SX:LanguageSet')
AddEventHandler('SX:LanguageSet', function(args)
    if Config.SXBlips then
    local _source = source
    local identifier = GetPlayerIdentifier(source)
    if args == nil then
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Missing Language parameter {it, ru, esp, fr, en, gr}" .. "^7")
    elseif args == "it" or args == "italian" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'it' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to ITALIAN - Rejoin to have the game translated" .. "^7")
    elseif args == "en" or args == "english" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'en' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to ENGLISH - Rejoin to have the game translated" .. "^7")
    elseif args == "ru" or args == "russian" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'ru' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to RUSSIAN - Rejoin to have the game translated" .. "^7")
    elseif args == "esp" or args == "spanish" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'esp' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to SPANSIH - Rejoin to have the game translated" .. "^7")
    elseif args == "gr" or args == "german" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'gr' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to GERMAN - Rejoin to have the game translated" .. "^7")
    elseif args == "fr" or args == "french" then 
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'fr' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to FRANCH - Rejoin to have the game translated" .. "^7")
    elseif args == "np" or args == "napule" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'np' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to NEAPOLITAN - Rejoin to have the game translated" .. "^7")
    elseif args == "du" or args == "Dutch" then
        MySQL.Async.execute("UPDATE sx_adminclients SET language_user = 'du' WHERE identifier LIKE @identifier", {['@identifier'] = identifier})
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Lenguage set to NEAPOLITAN - Rejoin to have the game translated" .. "^7")
    else
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "Not valid Language parameter {it, ru, esp, fr, en, gr}" .. "^7")
    end
    else 
        TriggerClientEvent('chatMessage', _source, '^7[^5SXAdmin^7]^2', {0,0,0}, "The owner Turned Off SXBlips, Thsi command don't work with SXBlips off" .. "^7")
    end
end)

RegisterServerEvent('SX:LanguageGet')
AddEventHandler('SX:LanguageGet', function()
    local _source = source
    MySQL.Async.fetchAll("SELECT * FROM sx_adminclients WHERE identifier LIKE @identifier", {['@identifier'] = GetPlayerIdentifier(_source)},
    function (res)    
        if res[1].language_user == nil then
            TriggerClientEvent('SX:Langauge', _source, "en")
        else
            TriggerClientEvent('SX:Langauge', _source, res[1].language_user)
        end
    end)
end)

