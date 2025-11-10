player = {}
player.__index = player

function player.new(settings)
    local self = setmetatable({}, player)

    self.selectedTile = 0
    self.world = settings.world
    self.camSpeed = settings.camSpeed
    self.currentPhase = 3

    self.phases = {
        "move",
        "attack",
        "build",
        "done"
    }

    self.doneSent = false
    self.team = 0

    self.resources = 500
    self.energy = 200

    return self
end

function player:update(dt)
    self:input(dt)
end

function player:draw()
end

function player:input(dt)
    if (love.keyboard.isDown("w")) then
        self.world.y = self.world.y + (self.camSpeed * dt)
    end
    if (love.keyboard.isDown("s")) then
        self.world.y = self.world.y - (self.camSpeed * dt)
    end
    if (love.keyboard.isDown("a")) then
        self.world.x = self.world.x + (self.camSpeed * dt)
    end
    if (love.keyboard.isDown("d")) then
        self.world.x = self.world.x - (self.camSpeed * dt)
    end
end