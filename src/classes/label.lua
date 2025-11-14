label = {}
label.__index = label

function label.new(settings)
    local self = setmetatable({}, label)

    self.x = settings.x or 0
    self.y = settings.y or 0

    self.text = settings.text
    self.font = settings.font
    self.font:setFilter("nearest")
    self.textSpace = 5

    self.width = self.font:getWidth(self.text)
    self.height = self.font:getHeight()

    self.color = settings.color

    self.centered = settings.centered or false
    if (self.centered == true) then
        self.x = self.x-(self.width/2)
        self.y = self.y-(self.height/2)
    end

    self.roundEdge = 10

    return self
end

function label:windowResize()
    self.width = self.font:getWidth(self.text)
    self.height = self.font:getHeight()

    if (self.centered == true) then
        self.x = self.x-(self.width/2)
        self.y = self.y-(self.height/2)
    end
end

function label:draw()
    love.graphics.setFont(self.font)

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x-self.textSpace, self.y-self.textSpace, self.width+(self.textSpace*2), self.height+(self.textSpace*2), self.roundEdge)

    love.graphics.setColor(0,0,0)
    love.graphics.print(self.text, self.x, self.y)

end