unit = {}
unit.__index = unit

function unit.new(settings)
    local self = setmetatable({}, unit)

    self.girdX = settings.x
    self.girdY = settings.y

    self.world = settings.world

    self.type = settings.type

    self.color = playerColors[selectedColor]
    
    self.x = self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2
    self.y = self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing)
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    self.moveSpeed = settings.moveSpeed
    self.moved = false

    self.team = 0
    self.turnMove = 0

    return self
end

function unit:update(dt)
    self.x = self.world.x+(self.girdX*((self.world.tileRadius/1.34)*self.world.tileSpacing) - self.world.tileRadius/2)
    self.y = self.world.y+(self.girdY*((self.world.tileInnerRadius)*self.world.tileSpacing))
    if (self.girdX % 2 == 0) then
        self.y = self.y - self.world.tileInnerRadius
    end

    if self.moved == true then
        if ((Player.phases[Player.currentPhase] == "done") and (not (self.turnMove == NextPhase.turn))) then
            self.moved = false
        end
    end
end

function unit:draw()
    if (isHost == true) then
        for i = 1, #players do
            if (players[i].team == self.team) then
                self.color = playerColors[players[i].color]
            end
        end
    end

    love.graphics.setColor({self.color[1]-0.2, self.color[2]-0.2, self.color[3]-0.2})
    love.graphics.circle('fill', self.x, self.y, self.world.tileInnerRadius/3)

    if (self.moved == false) then
        love.graphics.setColor(1,1,0)
        love.graphics.circle('line', self.x, self.y, self.world.tileInnerRadius/3)
    end

    love.graphics.setColor(1,1,1)
    love.graphics.print("U", self.x, self.y)
end