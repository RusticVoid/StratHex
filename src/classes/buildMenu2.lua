buildMenu2 = {}
buildMenu2.__index = buildMenu2

function buildMenu2.new(settings)
    local self = setmetatable({}, buildMenu2)

    self.width = 0
    self.height = 0
    self.x = 0
    self.y = 0

    self.world = settings.world

    self.coolDown = 0.5
    self.maxCoolDown = 0.5

    return self
end
