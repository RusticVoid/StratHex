buildMenu = {}
buildMenu.__index = buildMenu

function buildMenu.new(settings)
    local self = setmetatable({}, buildMenu)

    
    self.width = font:getWidth("building type Cost: 000 \nEnergy Consumption: 000 \nResource Consumption: 000 \nEnergy Production: 000 \nResource Production: 000")
    self.height = windowHeight
    self.x = windowWidth-(self.width)
    self.y = 0

    self.world = settings.world
    self.canBuild = false

    self.buildables = {
        {type = "barracks",    cost = 150, EnergyConsumption = 25, ResourceConsumption = 50,  EnergyProduction = 0,  ResourceProduction = 0},
        {type = "city",        cost = 300, EnergyConsumption = 0,  ResourceConsumption = 0,   EnergyProduction = 0,  ResourceProduction = 0},
        {type = "power plant", cost = 100, EnergyConsumption = 0,  ResourceConsumption = 20,  EnergyProduction = 50, ResourceProduction = 0},
        {type = "mine",        cost = 50,  EnergyConsumption = 15, ResourceConsumption = 0,   EnergyProduction = 0,  ResourceProduction = 50},
    }

    self.coolDown = 0.5
    self.maxCoolDown = 0.1

    return self
end

function buildMenu:update(dt)
    self.coolDown = self.coolDown - (1*dt)

    if (Player.phases[Player.currentPhase] == "build") then
        if ((not (Player.selectedTile == 0)) and (Player.selectedTile.data.building == 0)) then

            self.canBuild = false
            for y = 1, self.world.MapSize do
                for x = 1, self.world.MapSize do
                    local nearX = self.world.tiles[y][x].x
                    local nearY = self.world.tiles[y][x].y
                    
                    if (getDistance(nearX, nearY, Player.selectedTile.x, Player.selectedTile.y) < 1*(self.world.tileRadius*self.world.tileSpacing)) then
                        if (not (self.world.tiles[y][x] == Player.selectedTile)) then
                            if (not (self.world.tiles[y][x].data.building == 0)) then
                                if (self.world.tiles[y][x].data.building.team == Player.team) then
                                    if (Player.selectedTile.type == "plains") then
                                        self.canBuild = self.world.tiles[y][x].data.building.type == "city"
                                    end
                                end
                                if (self.canBuild == true) then
                                    break
                                end
                            end
                        end
                    end
                end
                if (self.canBuild == true) then
                    break
                end
            end

            if (self.canBuild == true) then
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
                for i = 1, #self.buildables do
                    if (isMouseOver(self.x+4, ((i-1)*(self.height/#self.buildables))+2, self.width-8, (self.height/#self.buildables)-4)) then
                        if (love.mouse.isDown(1) and (self.coolDown < 0)) then
                            self.coolDown = self.maxCoolDown
                            if Player.resources >= self.buildables[i].cost then
                                Player.resources = Player.resources - self.buildables[i].cost
                                if (Player.selectedTile.data.building == 0) then
                                    if onlineGame == true then
                                        Player.selectedTile.data.building = building.new({x = Player.selectedTile.girdX, y = Player.selectedTile.girdY, world = self.world, type = self.buildables[i].type})
                                        if (isHost == true) then
                                            for i = 1, #players do
                                                sendWorld(players[i].event)
                                            end
                                        else
                                            host:service(10)
                                            server:send("build:"..Player.selectedTile.girdX..":"..Player.selectedTile.girdY..":"..self.buildables[i].type..":"..Player.team..";")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            if ((not (Player.selectedTile == 0)) and (Player.selectedTile.data.building.base == false) and (Player.selectedTile.data.building.team == Player.team)) then
                if (isMouseOver(self.x+4, 2, self.width-8, (self.height)-4)) then
                    if (love.mouse.isDown(1) and (self.coolDown < 0)) then
                        self.coolDown = self.maxCoolDown
                        Player.selectedTile.data.building = 0
                        if (isHost == true) then
                            for i = 1, #players do
                                sendWorld(players[i].event)
                            end
                        else
                            host:service(10)
                            server:send("rmbuild:"..Player.selectedTile.girdX..":"..Player.selectedTile.girdY..";")
                        end
                    end
                end
            end
        end
    end
end

function buildMenu:draw(dt)
    love.graphics.setColor(0.8,0.8,0.8,0.7)
    if (Player.phases[Player.currentPhase] == "build") then
        if ((not (Player.selectedTile == 0)) and (Player.selectedTile.data.building == 0)) then
            if (self.canBuild == true) then
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
                for i = 1, #self.buildables do
                    love.graphics.setColor(1,0.8,0.8,0.7)
                    love.graphics.rectangle("fill", self.x+4, ((i-1)*(self.height/#self.buildables))+2, self.width-8, (self.height/#self.buildables)-4)
                    love.graphics.setColor(0,0,0)
                    love.graphics.print(self.buildables[i].type.." Cost: "..self.buildables[i].cost.."\nEnergy Consumption: "..self.buildables[i].EnergyConsumption.."\nResource Consumption: "..self.buildables[i].ResourceConsumption.."\nEnergy Production: "..self.buildables[i].EnergyProduction.."\nResource Production: "..self.buildables[i].ResourceProduction, self.x+4, ((i-1)*(self.height/#self.buildables))+2)
                end
            end
        else
            if ((not (Player.selectedTile == 0)) and (Player.selectedTile.data.building.base == false) and (Player.selectedTile.data.building.team == Player.team)) then
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
                love.graphics.setColor(1,0.8,0.8,0.7)
                love.graphics.rectangle("fill", self.x+4, 2, self.width-8, (self.height)-4)
                love.graphics.setColor(0,0,0)
                love.graphics.print("REMOVE BUILDING", self.x+4, 2)
            end
        end
    end
end