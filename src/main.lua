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
    inputButton = button.new({color = {1,1,1}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2)-23, text = "Game IP", code = 'selectedInput = inputButton inputButton.text = ""'})
    joinGameButton = button.new({color = {1,0,0}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = (windowHeight/2)+23, text = "join game", code = 'serverIP = inputButton.text..gamePort canJoinGame = true'})
    
    startGameButton = button.new({color = {1,0,0}, font = love.graphics.newFont("fonts/DePixelKlein.ttf", 40), x = windowWidth/2, y = 22, text = "Start Game", code = 'menu = "game" event = host:service(100) for i = 1, #players do players[i].event.peer:send("STARTING GAME:"..World.MapSize) end'})

    gameLost = false

    initUnits()
end

function love.update(dt)
    mouseX, mouseY = love.mouse.getPosition()

    if (menu == "main") then
        hostButton:update(dt)
        joinButton:update(dt)
    elseif (menu == "host") then
        if onlineGame == false then
            initGame(10)
            host = enet.host_create("localhost:6789")
            onlineGame = true
            isHost = true
            players = {}
        end

        World.tiles[1][1].data.building = building.new({type = "city", x = 1, y = 1, world = World})
        World.tiles[1][1].data.building.base = true
        World.tiles[1][10].data.building = building.new({type = "city", x = 10, y = 1, world = World})
        World.tiles[1][10].data.building.team = 1
        World.tiles[1][10].data.building.base = true
        World.tiles[10][1].data.building = building.new({type = "city", x = 1, y = 10, world = World})
        World.tiles[10][1].data.building.team = 2
        World.tiles[10][1].data.building.base = true
        World.tiles[10][10].data.building = building.new({type = "city", x = 10, y = 10, world = World})
        World.tiles[10][10].data.building.team = 3
        World.tiles[10][10].data.building.base = true

        event = host:service(10)

        if event then
            if event.type == "receive" then
                print("Got message: ", event.data, event.peer)
            elseif event.type == "connect" then
                print(event.peer, "connected.")
                players[#players+1] = {event, done, team}
                players[#players].event = event
                players[#players].done = false
                players[#players].team = #players
            elseif event.type == "disconnect" then
                print(event.peer, "disconnected.")
            end
        end
        
        startGameButton:update(dt)

    elseif (menu == "join") then
        if onlineGame == false then
            host = enet.host_create()
            server = host:connect("localhost:6789")
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
            elseif event.type == "disconnect" then
                print(event.peer, "disconnected.")
            end
        end
    else
        World:update(dt)
        Player:update(dt)
        if gameLost == true then
            Player.phases[Player.currentPhase] = "done"
        else
            NextPhase:update(dt)
            BuildMenu:update(dt)
        end

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
    elseif (menu == "join") then
        
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