building = {}
building.__index = building

function building.new(settings)
    local self = setmetatable({}, building)

    self.base = false

    self.girdX = settings.x
    self.girdY = settings.y

    self.type = settings.type

    self.world = settings.world

    self.team = 0

    self.color = playerColors[selectedColor]

    self.x = self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2
    self.y = self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing)
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    if (self.type == "barracks") then
        self.produced = false
        self.coolDown = 0
        self.maxCoolDown = 3
        self.coolDownDone = false

        self.EnergyConsumption = 25
        self.ResourceConsumption = 50
        self.working = true
    end

    if (self.type == "power plant") then
        self.ResourceConsumption = 20
        self.EnergyProduction = 50
        self.produced = false
        self.working = true
    end

    if (self.type == "mine") then
        self.EnergyConsumption = 15
        self.ResourceProduction = 50
        self.produced = false
        self.working = true
    end


    return self
end

function building:update(dt)
    self.x = self.world.x+(self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2)
    self.y = self.world.y+(self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing))
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    if (self.base == true) then
        if ((not (World.tiles[self.girdX][self.girdY].data.unit == 0))) then
            if (not (World.tiles[self.girdX][self.girdY].data.unit.team == Player.team)) then
                gameLost = true
            end
        end
    end

    if (self.type == "mine") then
        if (self.team == Player.team) then
            if self.produced == false then
                if (Player.phases[Player.currentPhase] == "move") then
                    self.working = true
                    self.produced = true
                    Player.energy = Player.energy - self.EnergyConsumption

                    if (Player.energy < 0) then
                        Player.energy = Player.energy + self.EnergyConsumption
                        self.working = false
                    end

                    if (self.working == true) then
                        Player.resources = Player.resources + self.ResourceProduction
                    end

                end
            else
                if (Player.phases[Player.currentPhase] == "done") then
                    self.produced = false
                end
            end
        end
    end

    if (self.type == "power plant") then
        if (self.team == Player.team) then
            if self.produced == false then
                if (Player.phases[Player.currentPhase] == "move") then
                    self.working = true
                    self.produced = true
                    Player.resources = Player.resources - self.ResourceConsumption

                    if (Player.resources < 0) then
                        Player.resources = Player.resources + self.ResourceConsumption
                        self.working = false
                    end

                    if (self.working == true) then
                        Player.energy = Player.energy + self.EnergyProduction
                    end
                end
            else
                if (Player.phases[Player.currentPhase] == "done") then
                    self.produced = false
                end
            end
        end
    end

    if (self.type == "barracks") then
        if (self.team == Player.team) then
            if self.produced == false then
                if (Player.phases[Player.currentPhase] == "move") then
                    self.produced = true
                    self.coolDown = self.maxCoolDown

                    self.working = true
                    Player.resources = Player.resources - self.ResourceConsumption
                    Player.energy = Player.energy - self.EnergyConsumption

                    if (Player.resources < 0) then
                        Player.resources = Player.resources + self.ResourceConsumption
                        self.working = false
                    end

                    if (Player.energy < 0) then
                        Player.energy = Player.energy + self.EnergyConsumption
                        self.working = false
                    end

                    if (self.working == true) then
                        if (self.world.tiles[self.girdY][self.girdX].data.unit == 0) then
                            if onlineGame == true then
                                self.world.tiles[self.girdY][self.girdX].data.unit = unit.new({type = "basic", moveSpeed = unitTypes["basic"].moveSpeed, x = self.world.tiles[self.girdY][self.girdX].girdX, y = self.world.tiles[self.girdY][self.girdX].girdY, world = World})  
                                if (isHost == true) then 
                                    for i = 1, #players do
                                    sendWorld(players[i].event)
                                    end
                                else
                                    host:service(10)
                                    server:send("makeUnit:"..self.world.tiles[self.girdY][self.girdX].girdX..":"..self.world.tiles[self.girdY][self.girdX].girdY..":".."basic"..":"..self.coolDown..":"..Player.team..";")
                                end
                            end
                        end
                    end
                end
            else
                if (Player.phases[Player.currentPhase] == "done") then
                    if (self.coolDownDone == false) then
                        self.coolDown = self.coolDown - 1
                        if (isHost == true) then 
                            for i = 1, #players do
                                sendWorld(players[i].event)
                            end
                        else
                            host:service(10)
                            server:send("updateCoolDown:"..self.world.tiles[self.girdY][self.girdX].girdX..":"..self.world.tiles[self.girdY][self.girdX].girdY..":"..self.coolDown..";")
                        end
                        if (self.coolDown == 0) then
                            self.produced = false
                        end
                        self.coolDownDone = true
                    end
                elseif (Player.phases[Player.currentPhase] == "move") then
                    self.coolDownDone = false
                end
            end
        end
    end
end

function building:draw()
    if (isHost == true) then
        for i = 1, #players do
            if (players[i].team == self.team) then
                self.color = playerColors[players[i].color]
            end
        end
    end
    
    if self.team == Player.team then
        self.color = playerColors[selectedColor]
    end

    love.graphics.setColor(self.color)
    love.graphics.circle('fill', self.x, self.y, self.world.tileInnerRadius/2)

    if (self.type == "mine") then
        love.graphics.setColor(1,1,1)
        love.graphics.print("M", self.x, self.y)
    end
    if (self.type == "barracks") then
        love.graphics.setColor(1,1,1)
        love.graphics.print("B", self.x, self.y)
    end
    if (self.type == "city") then
        love.graphics.setColor(1,1,1)
        love.graphics.print("C", self.x, self.y)
    end
    if (self.type == "power plant") then
        love.graphics.setColor(1,1,1)
        love.graphics.print("P", self.x, self.y)
    end
end