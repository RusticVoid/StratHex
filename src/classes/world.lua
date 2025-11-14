world = {}
world.__index = world

function world.new(settings)
    local self = setmetatable({}, world)

    self.tileRadius = settings.tileRadius
    self.tileInnerRadius = self.tileRadius/1.16
    self.tileSpacing = settings.tileSpacing
    self.MapSize = settings.MapSize

    self.x = 0
    self.y = 0

    self.tiles = {}
    for y = 1, self.MapSize do
        self.tiles[y] = {}
        for x = 1, self.MapSize do
            self.tiles[y][x] = tile.new({x = x, y = y, world = self, type = "plains"})
            if (math.random(1, 10) == 1) then
                if (math.random(1, 2) == 1) then
                    self.tiles[y][x].type = "mountain"
                else
                    --self.tiles[y][x].type = "water"
                end
            end
        end
    end


    
    riverAmount = 10
    for i = 0, riverAmount do    
        local riverLength = 10
        local riverSize = 1
        local riverX = math.random(1, self.MapSize)*((self.tileRadius/1.34)*self.tileSpacing) - self.tileRadius/2
        local riverY = math.random(1, self.MapSize)*((self.tileInnerRadius)*self.tileSpacing)
        local dx = math.random(-1, 1)
        local dy = math.random(-1, 1)
        for i = 1, riverLength do
            if (math.random (1, 10) == 1) then
                dx = math.random(-1, 1)
                dy = math.random(-1, 1)
            end
            riverX = riverX + (dx*50)
            riverY = riverY + (dy*50)
            for y = 1, self.MapSize do
                for x = 1, self.MapSize do
                    if (getDistance(self.tiles[y][x].x, self.tiles[y][x].y, riverX, riverY) < riverSize*(self.tileRadius*self.tileSpacing)) then
                        self.tiles[y][x].type = "water"
                    end
                end
            end
        end
    end

    for iy = 1, self.MapSize do
        for ix = 1, self.MapSize do
            for y = 1, self.MapSize do
                for x = 1, self.MapSize do
                    if (getDistance(self.tiles[y][x].x, self.tiles[y][x].y, self.tiles[iy][ix].x, self.tiles[iy][ix].y) < 1*(self.tileRadius*self.tileSpacing)) then
                        if (self.tiles[iy][ix].type == "water") then
                            if (self.tiles[y][x].type == "plains") then
                                self.tiles[y][x].type = "sand"
                            end
                        end
                    end
                end
            end
        end
    end
    

    return self
end

function world:update(dt)
    for y = 1, self.MapSize do
        for x = 1, self.MapSize do
            self.tiles[y][x]:update(dt)
        end
    end
end

function world:draw()
    for y = 1, self.MapSize do
        for x = 1, self.MapSize do
            self.tiles[y][x]:draw()
        end
    end
end