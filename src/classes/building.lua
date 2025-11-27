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
        self.coolDown = 0
        self.maxCoolDown = 3
        self.coolDownDone = false

        self.EnergyConsumption = buildingTypesData[self.type].EnergyConsumption
        self.ResourceConsumption = buildingTypesData[self.type].ResourceConsumption
        self.working = true
    end

    self.energy = buildingTypesData[self.type].energy
    self.resource = buildingTypesData[self.type].resource
    self.produced = false


    return self
end

function building:update(dt)
    self.x = self.world.x+(self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2)
    self.y = self.world.y+(self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing))
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    if self.team == Player.team then
        if (self.energy) then
            if (self.type == "barracks") then
                if (self.coolDown == 1) then
                    Player.energyNextTurn = Player.energyNextTurn + self.energy  
                end
            else
                Player.energyNextTurn = Player.energyNextTurn + self.energy
            end
        end

        if (self.resource) then
            if (self.type == "barracks") then
                if (self.coolDown == 1) then
                    Player.resourcesNextTurn = Player.resourcesNextTurn + self.resource
                end
            else
                Player.resourcesNextTurn = Player.resourcesNextTurn + self.resource
            end
        end
    end
    
    if (self.type == "city") then
        if (self.base == true) then
            if (Player.team == self.team) then
                if (not (World.tiles[self.girdY][self.girdX].data.unit == 0)) then
                    if (not (Player.team == World.tiles[self.girdY][self.girdX].data.unit.team)) then
                        gameLost = true
                    end
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

                    Player.resources = Player.resources - self.resource
                    Player.energy = Player.energy - self.energy

                    if (Player.resources < 0) and (Player.energy < 0) then
                        Player.resources = Player.resources + -self.resource
                        Player.energy = Player.energy + -self.energy
                    else
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
    else
        if (self.team == Player.team) then
            if self.produced == false then
                if (Player.phases[Player.currentPhase] == "move") then
                    self.produced = true
                    Player.energy = Player.energy + self.energy
                    Player.resources = Player.resources + self.resource

                    if ((Player.energy < 0) or (Player.resources < 0)) then
                        Player.resource = Player.resource + -self.resource
                        Player.energy = Player.energy + -self.energy
                    end
                end
            else
                if (Player.phases[Player.currentPhase] == "done") then
                    self.produced = false
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
        love.graphics.setColor(self.color[1]-0.2,self.color[2]-0.2,self.color[3]-0.2)
        local coolDownArc = 0
        if self.coolDown == 2 then
            coolDownArc = math.pi
        end
        if self.coolDown == 1 then
            coolDownArc = 2*math.pi
        end
        love.graphics.arc("fill", self.x, self.y, self.world.tileInnerRadius/2, math.pi/2, coolDownArc+math.pi/2)
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