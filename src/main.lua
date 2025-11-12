require "utils"
require "classes.world"
require "classes.tile"
require "classes.unit"
require "classes.player"
require "classes.buildMenu"
require "classes.building"
require "classes.nextPhase"
require "classes.button"

enet = require "enet"

function love.load()
    math.randomseed(os.clock())

    font = love.graphics.newFont("fonts/DePixelKlein.ttf", 20)
    font:setFilter("nearest")
    love.graphics.setFont(font)

    mouseX, mouseY = love.mouse.getPosition()
    windowWidth, windowHeight = love.graphics.getDimensions()

    menu = "main"
    onlineGame = false
    isHost = false
    joinedGame = false

    hostButton = button.new({color = {1,0,0}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2)-22, text = "host", code = 'menu = "host"'})
    joinButton = button.new({color = {1,0,0}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2)+22, text = "join", code = 'menu = "join"'})

    selectedInput = 0
    gamePort = "6789"
    serverIP = "localhost:"..gamePort
    canJoinGame = false
    usernameButton = button.new({color = {1,1,1}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2)-44, text = "Username", code = 'selectedInput = usernameButton usernameButton.text = ""'})
    inputButton = button.new({color = {1,1,1}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2), text = "Game IP", code = 'selectedInput = inputButton inputButton.text = ""'})
    joinGameButton = button.new({color = {1,0,0}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2)+44, text = "join game", code = 'serverIP = inputButton.text..gamePort canJoinGame = true'})
    
    startGameButton = button.new({color = {1,0,0}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = 22, text = "Start Game", code = 'menu = "game" event = host:service(100) for i = 1, #players do players[i].event.peer:send("STARTING GAME:"..World.MapSize) end'})

    gameLost = false

    recenteredAtCity = false

    initUnits()
    initTileTypes()
end

function love.update(dt)
    mouseX, mouseY = love.mouse.getPosition()

    if (menu == "main") then
        hostButton:update(dt)
        joinButton:update(dt)
    elseif (menu == "host") then
        if onlineGame == false then
            initGame(25)
            host = enet.host_create("localhost:6789")
            onlineGame = true
            isHost = true
            players = {}

            RandPlace = {
                x = math.random(2, World.MapSize-2),
                y = math.random(2, World.MapSize-2)
            }
            World.tiles[RandPlace.y][RandPlace.x].data.building = building.new({type = "city", x = RandPlace.x, y = RandPlace.y, world = World})
            World.tiles[RandPlace.y][RandPlace.x].data.building.base = true
            print(RandPlace.x, RandPlace.y)
        end

        event = host:service(10)

        if event then
            if event.type == "receive" then
                print("Got message: ", event.data, event.peer)
                players[#players].name = event.data
            elseif event.type == "connect" then
                print(event.peer, "connected.")
                players[#players+1] = {event, done, team, name = 0}
                players[#players].event = event
                players[#players].done = false
                players[#players].team = #players

                RandPlace = {
                    x = math.random(2, World.MapSize-2),
                    y = math.random(2, World.MapSize-2)
                }
                World.tiles[RandPlace.y][RandPlace.x].data.building = building.new({type = "city", x = RandPlace.x, y = RandPlace.y, world = World})
                World.tiles[RandPlace.y][RandPlace.x].data.building.team = players[#players].team
                World.tiles[RandPlace.y][RandPlace.x].data.building.base = true

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
                    server:send(usernameButton.text)
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
                    recenterToCity()
                    recenteredAtCity = true
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
                            if (recenteredAtCity == false) then
                                recenterToCity()
                                recenteredAtCity = true
                            end
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
        hostButton:draw()
        joinButton:draw()
    elseif (menu == "host") then
        startGameButton:draw()
        if onlineGame == true then
            for i = 1, #players do
                love.graphics.setColor(1,0,0)
                love.graphics.setFont(font)
                if (players[i].name == 0) then
                    love.graphics.rectangle("fill", 0, (i-1)*font:getHeight(), font:getWidth("No Name"), font:getHeight())
                    love.graphics.setColor(1,1,1)
                    love.graphics.print("No Name", 0, (i-1)*font:getHeight())
                else
                    love.graphics.rectangle("fill", 0, (i-1)*font:getHeight(), font:getWidth(players[i].name), font:getHeight())
                    love.graphics.setColor(1,1,1)
                    love.graphics.print(players[i].name, 0, (i-1)*font:getHeight())
                end
            end
        end
    elseif (menu == "join") then
        if (canJoinGame == false) then
            usernameButton:draw()
            inputButton:draw()
            joinGameButton:draw()
        else

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

            love.graphics.setColor(1,1,1)
            love.graphics.print("Resources: "..Player.resources, 0, windowHeight-font:getHeight())
            love.graphics.print("Energy: "..Player.energy, font:getWidth("Resources: "..Player.resources)+20, windowHeight-font:getHeight())
        end
    end
end

function love.keypressed(key)
    if (key == "backspace") then
        selectedInput.text = selectedInput.text:sub(1, -2)
    else
        if (not (selectedInput == 0)) then
            selectedInput.text = selectedInput.text..key
        end
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
