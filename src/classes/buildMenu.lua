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

    self.coolDown = 0.5
    self.maxCoolDown = 0.5

    return self
end

function buildMenu:update(dt)

    if (Player.phases[Player.currentPhase] == "build") then
        if ((not (Player.selectedTile == 0)) and (Player.selectedTile.data.building == 0)) then
            self.canBuild = false
            self.canChange = false
            for y = 1, self.world.MapSize do
                for x = 1, self.world.MapSize do
                    local nearX = self.world.tiles[y][x].x
                    local nearY = self.world.tiles[y][x].y
                    
                    if (getDistance(nearX, nearY, Player.selectedTile.x, Player.selectedTile.y) < 1*(self.world.tileRadius*self.world.tileSpacing)) then
                        if (not (self.world.tiles[y][x] == Player.selectedTile)) then
                            if (not (self.world.tiles[y][x].data.building == 0)) then
                                if (self.world.tiles[y][x].data.building.team == Player.team) then
                                    if (self.world.tiles[y][x].data.building.type == "city") then
                                        if ((Player.selectedTile.type == "plains") or Player.selectedTile.type == "sand") then
                                            self.canBuild = true
                                        elseif (Player.selectedTile.type == "water") then
                                            self.canChange = true
                                        elseif (Player.selectedTile.type == "mountain") then
                                            self.canChange = true
                                        end
                                    end
                                end
                                if ((self.canBuild == true) or (self.canChange == true)) then
                                    break
                                end
                            end
                        end
                    end
                end
                if ((self.canBuild == true) or (self.canChange == true)) then
                    break
                end
            end


            if (self.canChange == true) then
                self.coolDown = self.coolDown - (1*dt)
                for i = 1, #terraformTypes do
                    if (isMouseOver(self.x+4, ((i-1)*(self.height/#terraformTypes))+2, self.width-8, (self.height/#terraformTypes)-4)) then
                        if (love.mouse.isDown(1) and (self.coolDown < 0)) then
                            self.coolDown = self.maxCoolDown
                            if Player.resources >= buildingTypesData[terraformTypes[i]].cost then
                                if (Player.selectedTile.data.building == 0) then
                                    if onlineGame == true then
                                        if (buildingTypesData[terraformTypes[i]].changeTile) then
                                            if (Player.selectedTile.type == buildingTypesData[terraformTypes[i]].baseTile) then
                                                Player.selectedTile.type = buildingTypesData[terraformTypes[i]].changeTile
                                                Player.resources = Player.resources - buildingTypesData[terraformTypes[i]].cost
                                            end
                                        end
                                        if (isHost == true) then
                                            for i = 1, #players do
                                                sendWorld(players[i].event)
                                            end
                                        else
                                            host:service(10)
                                            server:send("build:"..Player.selectedTile.girdX..":"..Player.selectedTile.girdY..":"..terraformTypes[i]..":"..Player.team..";")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if (self.canBuild == true) then
                self.coolDown = self.coolDown - (1*dt)
                for i = 1, #buildingTypes do
                    if (isMouseOver(self.x+4, ((i-1)*(self.height/#buildingTypes))+2, self.width-8, (self.height/#buildingTypes)-4)) then
                        if (love.mouse.isDown(1) and (self.coolDown < 0)) then
                            self.coolDown = self.maxCoolDown
                            if Player.resources >= buildingTypesData[buildingTypes[i]].cost then
                                if (Player.selectedTile.data.building == 0) then
                                    Player.selectedTile.data.building = building.new({x = Player.selectedTile.girdX, y = Player.selectedTile.girdY, world = self.world, type = buildingTypes[i]})
                                    Player.resources = Player.resources - buildingTypesData[buildingTypes[i]].cost
                                    if onlineGame == true then
                                        if (isHost == true) then
                                            for i = 1, #players do
                                                sendWorld(players[i].event)
                                            end
                                        else
                                            host:service(10)
                                            server:send("build:"..Player.selectedTile.girdX..":"..Player.selectedTile.girdY..":"..buildingTypes[i]..":"..Player.team..";")
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
                self.coolDown = self.coolDown - (1*dt)
                if (isMouseOver(self.x+4, 2, self.width-8, (self.height)-4)) then
                    if (love.mouse.isDown(1) and (self.coolDown < 0)) then
                        print("test")
                        self.coolDown = self.maxCoolDown
                        World.tiles[Player.selectedTile.girdY][Player.selectedTile.girdX].data.building = 0
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
                for i = 1, #buildingTypes do
                    local Info = buildingTypesData[buildingTypes[i]].name.." Cost: "..buildingTypesData[buildingTypes[i]].cost
                    love.graphics.setColor(1,0.8,0.8,0.7)
                    love.graphics.rectangle("fill", self.x+4, ((i-1)*(self.height/#buildingTypes))+2, self.width-8, (self.height/#buildingTypes)-4)
                    love.graphics.setColor(0,0,0)
                    --love.graphics.print(buildingTypes[i].." Cost: "..buildingTypesData[buildingTypes[i]].cost.."\nEnergy Consumption: "..buildingTypesData[buildingTypes[i]].EnergyConsumption.."\nResource Consumption: "..buildingTypesData[buildingTypes[i]].ResourceConsumption.."\nEnergy Production: "..buildingTypesData[buildingTypes[i]].EnergyProduction.."\nResource Production: "..buildingTypesData[buildingTypes[i]].ResourceProduction, self.x+4, ((i-1)*(self.height/#buildingTypes))+2)
                    if buildingTypes[i] == "barracks" then
                        Info = Info.."\nPer-Unit Cost:".."\nEnergy: "..buildingTypesData[buildingTypes[i]].EnergyProduction-buildingTypesData[buildingTypes[i]].EnergyConsumption.."\nResource: "..buildingTypesData[buildingTypes[i]].ResourceProduction-buildingTypesData[buildingTypes[i]].ResourceConsumption
                    else
                        Info = Info.."\nEnergy: "..buildingTypesData[buildingTypes[i]].EnergyProduction-buildingTypesData[buildingTypes[i]].EnergyConsumption.."\nResource: "..buildingTypesData[buildingTypes[i]].ResourceProduction-buildingTypesData[buildingTypes[i]].ResourceConsumption
                    end
                    love.graphics.print(Info, self.x+4, ((i-1)*(self.height/#buildingTypes))+2)
                end
            end
            if (self.canChange == true) then
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
                for i = 1, #terraformTypes do
                    love.graphics.setColor(1,0.8,0.8,0.7)
                    love.graphics.rectangle("fill", self.x+4, ((i-1)*(self.height/#terraformTypes))+2, self.width-8, (self.height/#terraformTypes)-4)
                    love.graphics.setColor(0,0,0)
                    love.graphics.print(terraformTypes[i].." Cost: "..buildingTypesData[terraformTypes[i]].cost, self.x+4, ((i-1)*(self.height/#terraformTypes))+2)
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