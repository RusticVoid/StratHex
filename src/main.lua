require "utils"
require "classes.world"
require "classes.tile"
require "classes.unit"
require "classes.player"
require "classes.buildMenu"
require "classes.building"
require "classes.nextPhase"
require "classes.button"
require "classes.label"

enet = require "enet"

-- Notes
-- Added barracks cooldown indicator
-- Added next turn resource preview
-- Added bridges and tunnels
-- Rebalance building resources

function love.load()
    math.randomseed(os.clock())

    font = love.graphics.newFont("fonts/baseFont.ttf", 17)
    font:setFilter("nearest")
    love.graphics.setFont(font)

    titleFont = love.graphics.newFont("fonts/baseFont.ttf", 60)
    titleFont:setFilter("nearest")

    mouseX, mouseY = love.mouse.getPosition()
    windowWidth, windowHeight = love.graphics.getDimensions()

    menu = "main"
    menuInit = false
    onlineGame = false
    isHost = false
    joinedGame = false

    titleLabel = label.new({centered = true, color = {1,1,1,0.5}, font = titleFont, x = (windowWidth/2), y = 50, text = "StartHex"})

    resourceLabel = label.new({color = {1,1,1,0.5}, font = font, x = 0, y = windowHeight-font:getHeight(), text = ""})

    hostButton = button.new({color = {1,1,1,0.5}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = 10, y = (windowHeight/2)-44, text = "host", code = 'menu = "host"'})
    joinButton = button.new({color = {1,1,1,0.5}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = 10, y = (windowHeight/2)+44, text = "join", code = 'menu = "join"'})

    selectedInput = 0
    gamePort = "6789"
    serverIP = "localhost:"..gamePort
    canJoinGame = false
    usernameButton = button.new({centered = true, color = {1,1,1}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = windowWidth/2, y = (windowHeight/2)-70, text = "Username", code = 'selectedInput = usernameButton usernameButton.text = "" selectedInput:recenter()'})
    inputButton = button.new({centered = true, color = {1,1,1}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = windowWidth/2, y = (windowHeight/2), text = "Game IP", code = 'selectedInput = inputButton inputButton.text = "" selectedInput:recenter()'})
    joinGameButton = button.new({centered = true, color = {1,0,0}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = windowWidth/2, y = (windowHeight/2)+70, text = "join game", code = 'serverIP = inputButton.text..gamePort canJoinGame = true'})

    playerColors = {
        {1,0.2,0.2}, --red
        {0.2,1,0.2}, --green
        {0.2,0.2,1}, --blue
        {1,1,1},     --white
        {0.5,0.2,1}, --purple
        {1,1,0.2},   --yellow
        {1,0.5,0.2}, --orange
    }

    selectedColor = 1

    colorSelector = button.new({centered = true, color = {1,0,0}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = windowWidth/2, y = windowHeight/2, text = "Color", code = 'selectedColor = selectedColor + 1 if (selectedColor > #playerColors) then selectedColor = 1 end colorSelector.color = playerColors[selectedColor] if (not (isHost)) then host:service(10) server:send(usernameButton.text..":"..selectedColor..";") end'})

    startGameButton = button.new({centered = true, color = {1,0,0}, font = love.graphics.newFont("fonts/baseFont.ttf", 40), x = windowWidth/2, y = 44, text = "Start Game", code = 'menu = "game" event = host:service(100) for i = 1, #players do players[i].event.peer:send("STARTING GAME:"..World.MapSize) end'})

    gameLost = false

    recenteredAtCity = false

    initUnits()
    initTileTypes()
    initBuildingTypes()
end

function love.resize()
    windowWidth, windowHeight = love.graphics.getDimensions()

    titleLabel.x = (windowWidth/2)
    titleLabel.y = 50
    titleLabel:windowResize()
    hostButton.y = (windowHeight/2)-44
    joinButton.y = (windowHeight/2)+44

    startGameButton.x = windowWidth/2
    startGameButton.y = 44
    startGameButton:windowResize()

    colorSelector.x = windowWidth/2
    colorSelector.y = windowHeight/2
    colorSelector:windowResize()

    usernameButton.x = windowWidth/2
    usernameButton.y = (windowHeight/2)-70
    usernameButton:windowResize()
    inputButton.x = windowWidth/2
    inputButton.y = windowHeight/2
    inputButton:windowResize()
    joinGameButton.x = windowWidth/2
    joinGameButton.y = (windowHeight/2)+70
    joinGameButton:windowResize()


    if (menu == "game") then
        BuildMenu.width = font:getWidth("building type Cost: 000 \nEnergy Consumption: 000 \nResource Consumption: 000 \nEnergy Production: 000 \nResource Production: 000")
        BuildMenu.height = windowHeight
        BuildMenu.x = windowWidth-(BuildMenu.width)
        BuildMenu.y = 0
    end
end

function love.update(dt)
    mouseX, mouseY = love.mouse.getPosition()

    if (menu == "main") then
        if (menuInit == false) then
            World = world.new({tileRadius = 30, tileSpacing = 2, MapSize = 50})
            Player = player.new({camSpeed = 300, world = World})
            World.x = -50
            World.y = -50
            menuInit = true
        end

        hostButton:update(dt)
        joinButton:update(dt)
        World:update(dt)
    elseif (menu == "host") then
        colorSelector:update(dt)
        if onlineGame == false then
            initGame(25)
            host = enet.host_create("*:"..gamePort)
            onlineGame = true
            isHost = true
            players = {}
            
            RandPlace = randCityLocation()
            World.tiles[RandPlace.y][RandPlace.x].data.building = building.new({type = "city", x = RandPlace.x, y = RandPlace.y, world = World})
            World.tiles[RandPlace.y][RandPlace.x].data.building.base = true
        end

        event = host:service(10)

        if event then
            if event.type == "receive" then
                print("Got message: ", event.data, event.peer)
                decryptUserData(event)
            elseif event.type == "connect" then
                print(event.peer, "connected.")
                players[#players+1] = {event, done, team, name = 0, color = {}, basex, basey}
                players[#players].event = event
                players[#players].done = false
                players[#players].team = #players

                RandPlace = randCityLocation()
                World.tiles[RandPlace.y][RandPlace.x].data.building = building.new({type = "city", x = RandPlace.x, y = RandPlace.y, world = World})
                World.tiles[RandPlace.y][RandPlace.x].data.building.team = players[#players].team
                World.tiles[RandPlace.y][RandPlace.x].data.building.base = true
                players[#players].basex = RandPlace.x
                players[#players].basey = RandPlace.y

            elseif event.type == "disconnect" then
                print(event.peer, "disconnected.")
                removeDisconnectedPlayer(event)
            end
        end
        
        startGameButton:update(dt)

    elseif (menu == "join") then
        if (canJoinGame == false) then
            usernameButton:update(dt)
            inputButton:update(dt)
            joinGameButton:update(dt)
        else
            colorSelector:update(dt)
            if onlineGame == false then
                host = enet.host_create()
                server = host:connect(inputButton.text..":"..gamePort)
                onlineGame = true
            end

            event = host:service(10)

            if event then
                if event.type == "receive" then
                    print("Got message: ", event.data, event.peer)
                    if (event.data:sub(1, 13) == "STARTING GAME") then
                        menu = "game"
                        initGame(tonumber(event.data:sub(15)))
                    end
                    event.peer:send( "world?" )
                elseif event.type == "connect" then
                    print(event.peer, "connected.")
                    server:send(usernameButton.text..":"..selectedColor..";")
                elseif event.type == "disconnect" then
                    print(event.peer, "disconnected.")
                    love.load()
                end
            end
        end
    else
        Player:update(dt)
        if gameLost == true then
            Player.phases[Player.currentPhase] = "done"
        else
            NextPhase:update(dt)
            BuildMenu.width = font:getWidth("building type Cost: 000 \nEnergy Consumption: 000 \nResource Consumption: 000 \nEnergy Production: 000 \nResource Production: 000")
            BuildMenu.height = windowHeight
            BuildMenu.x = windowWidth-(BuildMenu.width)
            BuildMenu.y = 0
            BuildMenu:update(dt)
        end
        World:update(dt)

        if (Player.phases[Player.currentPhase] == "done") then
            if onlineGame == true then
                if (isHost == true) then
                    checkAllPlayersDone()
                else
                    if (Player.doneSent == false) then
                        host:service(10)
                        server:send("done")
                        Player.doneSent = true
                    end
                end
            end
        end
        
        if onlineGame == true then
            if (isHost == true) then
                if (recenteredAtCity == false) then
                    recenteredAtCity = true
                    recenterToCity()
                end
            end

            event = host:service(10)

            if event then
                if event.type == "receive" then
                    if (isHost == true) then
                        if (event.data == "world?") then
                            sendWorld(event)
                        elseif (event.data:sub(1, 5) == "build") then
                            decryptBuild(event)
                        elseif (event.data:sub(1, 7) == "rmbuild") then
                            decryptRMBuild(event)
                        elseif (event.data:sub(1, 8) == "makeUnit") then
                            decryptMakeUnit(event)
                        elseif (event.data:sub(1, 9) == "movedUnit") then
                            decryptMovedUnit(event)
                        elseif (event.data:sub(1, 14) == "updateCoolDown") then
                            decryptUpdateCoolDown(event)
                        elseif (event.data == "done") then
                            for i = 1, #players do
                                if (players[i].event.peer == event.peer) then
                                    players[i].done = true
                                    break
                                end
                            end
                            checkAllPlayersDone()
                        end
                    else
                        if (event.data:sub(1, 3) == "MAP") then
                            decryptWorld(event)
                            World:update(dt)
                        elseif (event.data == "allPlayersDone") then
                            if (Player.phases[Player.currentPhase] == "done") then
                                Player.currentPhase = NextPhase.nextPhase
                                Player.doneSent = false
                            end
                        else
                            print("Got message: ", event.data, event.peer)
                        end
                    end
                elseif event.type == "disconnect" then
                    if (isHost == true) then
                        removeDisconnectedPlayer(event)
                    else
                        love.load()
                    end
                    print(event.peer, "disconnected.")
                end
            end
        end
    end
end

function love.draw()
    if (menu == "main") then
        World:draw()
        titleLabel:draw()
        hostButton:draw()
        joinButton:draw()
    elseif (menu == "host") then
        startGameButton:draw()
        if onlineGame == true then
            for i = 1, #players do
                love.graphics.setFont(font)
                if (players[i].name == 0) then
                    love.graphics.setColor(1,0,0)
                    love.graphics.rectangle("fill", 0, (i-1)*font:getHeight(), font:getWidth("No Name"), font:getHeight(), 5)
                    love.graphics.setColor(1,1,1)
                    love.graphics.print("No Name", 0, (i-1)*font:getHeight())
                else
                    love.graphics.setColor(playerColors[players[i].color])
                    love.graphics.rectangle("fill", 0, (i-1)*font:getHeight(), font:getWidth(players[i].name), font:getHeight(), 5)
                    love.graphics.setColor(0,0,0)
                    love.graphics.print(players[i].name, 0, (i-1)*font:getHeight())
                end
            end
        end
        colorSelector:draw()
    elseif (menu == "join") then
        if (canJoinGame == false) then
            usernameButton:draw()
            inputButton:draw()
            joinGameButton:draw()
        else
            love.graphics.setColor(1,1,1)
            love.graphics.print("NOW IN GAME")
            colorSelector:draw()
        end
    else
        World:draw()
        if gameLost == true then
            love.graphics.setColor(1,0,0)
            love.graphics.rectangle("fill", 0, 0, font:getWidth("GAME LOST"), font:getHeight())
            
            love.graphics.setColor(1,1,1)
            love.graphics.print("GAME LOST", 0, 0)
        else
            NextPhase:draw()
            BuildMenu:draw()

            resourceLabel.x = 0
            resourceLabel.y = windowHeight-font:getHeight()
            resourceLabel.text = "Resources: "..Player.resources.."+"..Player.resourcesNextTurn.."  Energy: "..Player.energy.."+"..Player.energyNextTurn
            resourceLabel:windowResize()
            resourceLabel:draw()
        end
    end
end

function love.keypressed(key)
    if (key == "c") then
        if (menu == "game") then
            recenterToCity()
        end
    end

    if (not (selectedInput == 0)) then
        if (key == "backspace") then
            selectedInput.text = selectedInput.text:sub(1, -2)
        else
            selectedInput.x = windowWidth/2
            selectedInput.text = selectedInput.text..key
        end
        selectedInput:recenter()
    end
end

function love.quit()
    if (onlineGame == true) then
        if (isHost == true) then
            for i = 1, #players do 
                players[i].event.peer:disconnect()
            end
            host:service(10)
        else
            server:disconnect()
            host:service(10)
        end
    end
    return false
end
