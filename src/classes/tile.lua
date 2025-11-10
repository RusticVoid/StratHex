tile = {}
tile.__index = tile

function tile.new(settings)
    local self = setmetatable({}, tile)

    self.girdX = settings.x
    self.girdY = settings.y

    self.world = settings.world

    self.x = self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2
    self.y = self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing)

    self.color = {0.3,0.3,0.3,1}
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    self.selected = false
    self.highlight = false

    self.data = {
        unit = 0,
        building = 0
    }

    return self
end

function tile:update(dt)
    self.x = self.world.x+(self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2)
    self.y = self.world.y+(self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing))
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    if love.mouse.isDown(1) then
        if (getDistance(mouseX, mouseY, self.x, self.y) < self.world.tileInnerRadius) then
            self.selected = true
            Player.selectedTile = self
        else
            self.selected = false
            self:highlightNear(false)
        end
    end

    if (not (self.data.building == 0)) then
        self.data.building:update(dt)
    end      
    if (not (self.data.unit == 0)) then
        self.data.unit:update(dt)
    end
end

function tile:draw()
    if (self.highlight == true) then
        love.graphics.setColor(0,0.6,0)
    else
        love.graphics.setColor(self.color)
    end
    
    love.graphics.circle('fill', self.x, self.y, self.world.tileRadius, 6)

    if (getDistance(mouseX, mouseY, self.x, self.y) < self.world.tileInnerRadius) then
        self:drawBorder()
    end

    if (Player.selectedTile == self) then
        self.selected = true
    end


    if ((Player.phases[Player.currentPhase] == "move")) then
        if love.mouse.isDown(2) then
            if (not (Player.selectedTile == 0)) then
                if (not (Player.selectedTile == self)) then
                    if (getDistance(mouseX, mouseY, self.x, self.y) < self.world.tileInnerRadius) then
                        if ((not (Player.selectedTile.data.unit == 0)) and (Player.selectedTile.data.unit.moved == false)) then
                            if (self.highlight == true) then
                                if (Player.selectedTile.data.unit.team == Player.team) then
                                    local canMove = true
                                    if not (self.data.unit == 0) then
                                        if (self.data.unit.team == Player.team) then
                                            canMove = false
                                        end
                                    end

                                    if canMove == true then
                                        moveUnit(self, Player.selectedTile)
                                        if (isHost == true) then
                                            for i = 1, #players do
                                                sendWorld(players[i].event)
                                            end
                                        else
                                            host:service(10)
                                            server:send("movedUnit:"..self.girdX..":"..self.girdY..":"..Player.selectedTile.girdX..":"..Player.selectedTile.girdY..";")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if (self.selected == true) then
        self:drawBorder()

        if (not (self.data.unit == 0)) then
            self:highlightNear(true)
        end
    end

    love.graphics.setLineWidth(self.world.tileRadius/11)
    love.graphics.setColor(0,0,0)
    love.graphics.circle('line', self.x, self.y, self.world.tileRadius, 6)
    
    if (not (self.data.building == 0)) then
        self.data.building:draw()
    end
    if (not (self.data.unit == 0)) then
        self.data.unit:draw()
    end
end

function tile:drawBorder()
    love.graphics.setColor(0,1,0)
    love.graphics.setLineWidth(self.world.tileRadius/10)
    love.graphics.circle('line', self.x, self.y, self.world.tileRadius-(self.world.tileRadius/10), 6)
end

function tile:highlightNear(highlight)
    for y = 1, self.world.MapSize do
        for x = 1, self.world.MapSize do
            local nearX = self.world.tiles[y][x].x
            local nearY = self.world.tiles[y][x].y
            
            if (not (self.data.unit == 0)) then
                if (getDistance(nearX, nearY, self.x, self.y) < self.data.unit.moveSpeed*(self.world.tileRadius*self.world.tileSpacing)) then
                    if (not (self.world.tiles[y][x] == self)) then
                        self.world.tiles[y][x].highlight = highlight
                    end
                end
            end
        end
    end
end