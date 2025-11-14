player = {}
player.__index = player

function player.new(settings)
    local self = setmetatable({}, player)

    self.selectedTile = 0
    self.world = settings.world
    self.camSpeed = settings.camSpeed
    self.currentPhase = 1

    self.phases = {
        "move",
        "build",
        "done"
    }

    self.doneSent = false
    self.team = 0

    self.resources = 200
    self.energy = 200

    self.energyNextTurn = 0
    self.resourcesNextTurn = 0

    return self
end

function player:update(dt)
    self:input(dt)
    self.energyNextTurn = 0
    self.resourcesNextTurn = 0
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