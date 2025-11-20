world = {}
world.__index = world

function world.new(settings)
    local self = setmetatable({}, world)

    self.tileRadius = settings.tileRadius
    self.tileInnerRadius = self.tileRadius/1.16
    self.tileSpacing = settings.tileSpacing
    self.MapSize = settings.MapSize

    self.loading = false
    self.loaded = false

    self.x = 0
    self.y = 0

    return self
end

function world:smooth(smoothIteration)
    for i = 0, smoothIteration do
        self.changedTiles = self.tiles
        for xi = 1, self.MapSize do
            for yi = 1, self.MapSize do
                local totalHex = 0
                local totalHeight = 0
                for x = 1, self.MapSize do
                    for y = 1, self.MapSize do
                        if (getDistance(self.changedTiles[y][x].x, self.changedTiles[y][x].y, self.changedTiles[yi][xi].x, self.changedTiles[yi][xi].y) < 1*(self.tileRadius*self.tileSpacing)) then
                            if (not (self.changedTiles[y][x] == self.changedTiles[yi][xi])) then
                                totalHeight = totalHeight + self.changedTiles[y][x].height
                                totalHex = totalHex + 1
                            end
                        end
                    end
                end
                self.tiles[yi][xi].height = totalHeight/totalHex
            end
        end
    end
end

function world:update(dt)
    if ((self.loading == true) and (self.loaded == false)) then
        self.tiles = {}
        for y = 1, self.MapSize do
            self.tiles[y] = {}
            for x = 1, self.MapSize do
                self.tiles[y][x] = tile.new({x = x, height = math.random(0, 1), y = y, world = self, type = "water"})
            end
        end

        self:smooth(10)

        for y = 1, self.MapSize do
            for x = 1, self.MapSize do
                if self.tiles[x][y].height > 0.5 then
                    self.tiles[x][y].height = 1
                else
                    self.tiles[x][y].height = 0
                end
            end
        end

        self:smooth(10)

        for y = 1, self.MapSize do
            for x = 1, self.MapSize do
                if (self.tiles[y][x].height > 0.35) then
                    self.tiles[y][x].type = "sand"
                end
                if (self.tiles[y][x].height > 0.5) then
                    self.tiles[y][x].type = "plains"
                end
                if (self.tiles[y][x].height > 0.9) then
                    self.tiles[y][x].type = "mountain"
                end
            end
        end

        self.loaded = true
        self.loading = false
        for y = 1, self.MapSize do
            for x = 1, self.MapSize do
                self.tiles[x][y].building = 0
            end
        end
    end

    if (self.loaded == true) then
        for y = 1, self.MapSize do
            for x = 1, self.MapSize do
                self.tiles[y][x]:update(dt)
            end
        end
    end
end

function world:draw()
    if ((self.loading == false) and (self.loaded == false)) then
        love.graphics.setColor(1,1,1)
        self.loading = true
        love.graphics.print("LOADING TERREAIN")
    end

    if (self.loaded == true) then
        for y = 1, self.MapSize do
            for x = 1, self.MapSize do
                self.tiles[y][x]:draw()
            end
        end
    end
end