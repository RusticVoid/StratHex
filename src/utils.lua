function isMouseOver(x, y, width, height)
    if mouseX > x and mouseX < x+width
    and mouseY > y and mouseY < y+height then
        return true
    end
end

function getDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function initGame(MapSize)
    World = world.new({tileRadius = 30, tileSpacing = 2, MapSize = MapSize})
    Player = player.new({camSpeed = 300, world = World})
    BuildMenu = buildMenu.new({world = World})
    NextPhase = nextPhase.new()
end

function initUnits()
    unitTypes = {}
    unitTypes["basic"] = {moveSpeed = 1}
end

function recenterToCity()
    for y = 1, World.MapSize do
        for x = 1, World.MapSize do
            if (not (World.tiles[y][x].data.building == 0)) then
                if (World.tiles[y][x].data.building.base == true) then
                    if (World.tiles[y][x].data.building.team == Player.team) then
                        World.x = (-World.tiles[y][x].data.building.x)+windowWidth/2
                        World.y = (-World.tiles[y][x].data.building.y)+windowHeight/2
                        return
                    end
                end
            end
        end
    end
end

function initTileTypes()
    tileTypes = {}
    tileTypes["plains"] = {canWalkOn = true, color = {0.2,0.4,0.2}}
    tileTypes["water"] = {canWalkOn = false, color = {0,0,0.5}}
    tileTypes["mountain"] = {canWalkOn = false, color = {0.5,0.5,0.5}}
end

function removeDisconnectedPlayer(event)
    removePlayers = {}
    for i = 1, #players do
        if (players[i].event.peer == event.peer) then
            removePlayers[#removePlayers + 1] = i
        end
    end
    for i = 1, #removePlayers do
        table.remove(players, removePlayers[i])
    end
end

function checkAllPlayersDone()
    local allPlayersDone = true
    for i = 1, #players do 
        if (players[i].done == false) then
            allPlayersDone = false
            break
        end
    end

    if ((allPlayersDone == true) and (Player.phases[Player.currentPhase] == "done"))then
        for i = 1, #players do
            players[i].event.peer:send("allPlayersDone")
            players[i].done = false
        end
        Player.currentPhase = NextPhase.nextPhase
        for y = 1, World.MapSize do
            for x = 1, World.MapSize do
                if (not (World.tiles[y][x].data.unit == 0)) then
                    World.tiles[y][x].data.unit.moved = false
                end
            end
        end
    end
end

function sendWorld(event)
    tileStringList = ""
    for y = 1, World.MapSize do
        for x = 1, World.MapSize do

            local buildingType = 0
            local buildingProduced = 0
            local buildingTeam = 0
            local buildingCooldown = 0
            local buildingCooldownDone = 0
            local buildingIsBase = 0
            if (not (World.tiles[y][x].data.building == 0)) then
                buildingTeam = World.tiles[y][x].data.building.team
                buildingType = World.tiles[y][x].data.building.type
                if (World.tiles[y][x].data.building.base == true) then
                    buildingIsBase = 1
                end
                if (buildingType == "barracks") then
                    if (World.tiles[y][x].data.building.produced) then
                        buildingProduced = 1
                    end
                    buildingCooldown = World.tiles[y][x].data.building.coolDown
                    if (World.tiles[y][x].data.building.coolDownDone) then
                        buildingCooldownDone = 1
                    end
                end
            end

            local unitType = 0
            local unitMoved = 0
            local unitTeam = 0
            if (not (World.tiles[y][x].data.unit == 0)) then
                unitTeam = World.tiles[y][x].data.unit.team
                unitType = World.tiles[y][x].data.unit.type
                if (World.tiles[y][x].data.unit.moved) then
                    unitMoved = 1
                end
            end

            local team = 0
            for i = 1, #players do
                if (players[i].event.peer == event.peer) then
                    team = players[i].team
                end
            end

            local tileType = World.tiles[y][x].type

            tileStringList = tileStringList..x..":"..y..":"..tileType..":"..unitType..":"..unitMoved..":"..unitTeam..":"..buildingType..":"..buildingIsBase..":"..buildingProduced..":"..buildingCooldown..":"..buildingCooldownDone..":"..buildingTeam..":"..team..";"
        end
    end
    event.peer:send("MAP;"..tileStringList)
end

function decryptWorld(event)
    netTiles = {}
    k = 1
    netTiles[k] = ""
    for i = 5, #event.data do
        netTiles[k] = netTiles[k]..event.data:sub(i, i)
        if (event.data:sub(i, i) == ";") then
            k = k + 1
            netTiles[k] = ""
        end
    end
    for i = 1, #netTiles-1 do
        local lookingForList = {"x", "y", "tileType", "unitType", "unitMoved", "unitTeam", "buildingType", "buildingIsBase", "buildingProduced", "buildingCooldown", "buildingCooldownDone", "buildingTeam", "team"}
        local lookingFor = 1
        local x = ""
        local y = ""
        local tileType = ""
        local unitType = ""
        local unitMoved = ""
        local unitTeam = ""
        local buildingType = ""
        local buildingIsBase = ""
        local buildingProduced = ""
        local buildingCooldown = ""
        local buildingCooldownDone = ""
        local buildingTeam = ""
        local team = ""
        for k = 1, #netTiles[i] do
            if (netTiles[i]:sub(k, k) == ":") then
                lookingFor = lookingFor + 1
            elseif (netTiles[i]:sub(k, k) == ";") then
                break
            else
                if (lookingForList[lookingFor] == "x") then
                    x = x..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "y") then
                    y = y..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "tileType") then
                    tileType = tileType..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "unitType") then
                    unitType = unitType..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "unitTeam") then
                    unitTeam = unitTeam..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "unitMoved") then
                    unitMoved = unitMoved..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "buildingIsBase") then
                    buildingIsBase = buildingIsBase..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "buildingType") then
                    buildingType = buildingType..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "buildingProduced") then
                    buildingProduced = buildingProduced..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "buildingCooldown") then
                    buildingCooldown = buildingCooldown..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "buildingCooldownDone") then
                    buildingCooldownDone = buildingCooldownDone..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "buildingTeam") then
                    buildingTeam = buildingTeam..netTiles[i]:sub(k, k)
                end
                if (lookingForList[lookingFor] == "team") then
                    team = team..netTiles[i]:sub(k, k)
                end
            end
        end
        World.tiles[tonumber(y)][tonumber(x)] = tile.new({x = tonumber(x), y = tonumber(y), world = World, type = tileType})
        Player.team = tonumber(team)
        if (not (buildingType == "0")) then
            World.tiles[tonumber(y)][tonumber(x)].data.building = building.new({type = buildingType, x = tonumber(x), y = tonumber(y), world = World})
            World.tiles[tonumber(y)][tonumber(x)].data.building.base = (tonumber(buildingIsBase) == 1)
            if (buildingType == "barracks") then
                World.tiles[tonumber(y)][tonumber(x)].data.building.coolDown = tonumber(buildingCooldown)
                if (buildingProduced == "1") then
                    World.tiles[tonumber(y)][tonumber(x)].data.building.produced = true
                else
                    World.tiles[tonumber(y)][tonumber(x)].data.building.produced = false
                end
                if (buildingCooldownDone == "1") then
                    World.tiles[tonumber(y)][tonumber(x)].data.building.coolDownDone = true
                else
                    World.tiles[tonumber(y)][tonumber(x)].data.building.coolDownDone = false
                end
            end
            World.tiles[tonumber(y)][tonumber(x)].data.building.team = tonumber(buildingTeam)
        end
        if (not (unitType == "0")) then
            World.tiles[tonumber(y)][tonumber(x)].data.unit = unit.new({type = unitType, moveSpeed = unitTypes[unitType].moveSpeed, x = tonumber(x), y = tonumber(y), world = World})
            if (unitMoved == "1") then
                World.tiles[tonumber(y)][tonumber(x)].data.unit.moved = true
            else
                World.tiles[tonumber(y)][tonumber(x)].data.unit.moved = false
            end
            World.tiles[tonumber(y)][tonumber(x)].data.unit.team = tonumber(unitTeam)
        end
    end
end

function decryptBuild(event)
    local lookingForList = {"x", "y", "buildingType", "team"}
    local lookingFor = 1
    local x = ""
    local y = ""
    local buildingType = ""
    local team = ""
    for k = 7, #event.data do
        if (event.data:sub(k, k) == ":") then
            lookingFor = lookingFor + 1
        elseif (event.data:sub(k, k) == ";") then
            break
        else
            if (lookingForList[lookingFor] == "x") then
                x = x..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "y") then
                y = y..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "buildingType") then
                buildingType = buildingType..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "team") then
                team = team..event.data:sub(k, k)
            end
        end
    end
    World.tiles[tonumber(y)][tonumber(x)].data.building = building.new({type = buildingType, x = tonumber(x), y = tonumber(y), world = World})
    World.tiles[tonumber(y)][tonumber(x)].data.building.team = tonumber(team)
    for i = 1, #players do 
        sendWorld(players[i].event)
    end
end

function decryptRMBuild(event)
    local lookingForList = {"x", "y"}
    local lookingFor = 1
    local x = ""
    local y = ""
    for k = 9, #event.data do
        if (event.data:sub(k, k) == ":") then
            lookingFor = lookingFor + 1
        elseif (event.data:sub(k, k) == ";") then
            break
        else
            if (lookingForList[lookingFor] == "x") then
                x = x..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "y") then
                y = y..event.data:sub(k, k)
            end
        end
    end
    World.tiles[tonumber(y)][tonumber(x)].data.building = 0
    for i = 1, #players do 
        sendWorld(players[i].event)
    end
end

function decryptMakeUnit(event)
    local lookingForList = {"x", "y", "unitType", "coolDown", "team"}
    local lookingFor = 1
    local x = ""
    local y = ""
    local unitType = ""
    local coolDown = ""
    local team = ""
    for k = 10, #event.data do
        if (event.data:sub(k, k) == ":") then
            lookingFor = lookingFor + 1
        elseif (event.data:sub(k, k) == ";") then
            break
        else
            if (lookingForList[lookingFor] == "x") then
                x = x..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "y") then
                y = y..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "unitType") then
                unitType = unitType..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "coolDown") then
                coolDown = coolDown..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "team") then
                team = team..event.data:sub(k, k)
            end
        end
    end
    World.tiles[tonumber(y)][tonumber(x)].data.unit = unit.new({type = unitType, moveSpeed = unitTypes[unitType].moveSpeed, x = tonumber(x), y = tonumber(y), world = World})
    World.tiles[tonumber(y)][tonumber(x)].data.unit.team = tonumber(team)
    World.tiles[tonumber(y)][tonumber(x)].data.building.coolDown = tonumber(coolDown)
    World.tiles[tonumber(y)][tonumber(x)].data.building.produced = true
    for i = 1, #players do 
        sendWorld(players[i].event)
    end
end

function decryptUpdateCoolDown(event)
    local lookingForList = {"x", "y", "coolDown"}
    local lookingFor = 1
    local x = ""
    local y = ""
    local coolDown = ""
    for k = 16, #event.data do
        if (event.data:sub(k, k) == ":") then
            lookingFor = lookingFor + 1
        elseif (event.data:sub(k, k) == ";") then
            break
        else
            if (lookingForList[lookingFor] == "x") then
                x = x..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "y") then
                y = y..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "coolDown") then
                coolDown = coolDown..event.data:sub(k, k)
            end
        end
    end
    World.tiles[tonumber(y)][tonumber(x)].data.building.coolDown = tonumber(coolDown)
    World.tiles[tonumber(y)][tonumber(x)].data.building.coolDownDone = true
    if (World.tiles[tonumber(y)][tonumber(x)].data.building.coolDown == 0) then
        World.tiles[tonumber(y)][tonumber(x)].data.building.produced = false
    end
    for i = 1, #players do 
        sendWorld(players[i].event)
    end
end

function decryptMovedUnit(event)
    local lookingForList = {"newx", "newy", "x", "y"}
    local lookingFor = 1
    local newx = ""
    local newy = ""
    local x = ""
    local y = ""
    for k = 11, #event.data do
        if (event.data:sub(k, k) == ":") then
            lookingFor = lookingFor + 1
        elseif (event.data:sub(k, k) == ";") then
            break
        else
            if (lookingForList[lookingFor] == "newx") then
                newx = newx..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "newy") then
                newy = newy..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "x") then
                x = x..event.data:sub(k, k)
            end
            if (lookingForList[lookingFor] == "y") then
                y = y..event.data:sub(k, k)
            end
        end
    end

    moveUnit(World.tiles[tonumber(newy)][tonumber(newx)], World.tiles[tonumber(y)][tonumber(x)])
    for i = 1, #players do
        sendWorld(players[i].event)
    end
end

function moveUnit(newtile, tile)
    newtile.data.unit = tile.data.unit
    newtile.data.unit.moved = true
    newtile.data.unit.turnMove = NextPhase.turn
    newtile.data.unit.girdX = newtile.girdX
    newtile.data.unit.girdY = newtile.girdY
    tile:highlightNear(false)
    tile.data.unit = 0
end