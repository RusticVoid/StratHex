button = {}
button.__index = button

function button.new(settings)
    local self = setmetatable({}, button)

    self.x = settings.x or 0
    self.y = settings.y or 0

    self.baseX = settings.x or 0
    self.baseY = settings.y or 0

    self.text = settings.text
    self.font = settings.font
    self.font:setFilter("nearest")
    self.textSpace = 5

    self.width = self.font:getWidth(self.text)
    self.height = self.font:getHeight()

    self.color = settings.color

    self.code = settings.code

    self.defaultCoolDown = 0.5
    self.coolDown = 0.5

    self.hovered = false

    self.centered = settings.centered or false
    if (self.centered == true) then
        self.x = self.x-(self.width/2)
        self.y = self.y-(self.height/2)
    end

    self.roundEdge = 10

    return self
end

function button:windowResize()
    self.width = self.font:getWidth(self.text)
    self.height = self.font:getHeight()

    if (self.centered == true) then
        self.x = self.x-(self.width/2)
        self.y = self.y-(self.height/2)
    end


    self.baseX = self.x
    self.baseY = self.y
end

function button:recenter()
    self.width = self.font:getWidth(self.text)
    self.height = self.font:getHeight()

    if (self.centered == true) then
        self.x = self.baseX-(self.width/2)
        self.y = self.baseY-(self.height/2)
    end
end

function button:update(dt)
    self.width = self.font:getWidth(self.text)
    if self.width < 10 then
        self.width = 10
    end
    self.coolDown = self.coolDown - (1*dt)
    if (isMouseOver(self.x, self.y, self.width, self.height)) then
        self.hovered = true
        if ((love.mouse.isDown(1)) and (self.coolDown < 0)) then
            self.coolDown = self.defaultCoolDown
            local func, err = load(self.code)
            if func then
                func()
            else
                print("Error loading code from string. "..err)
            end
        end
    else
        self.hovered = false
    end
end

function button:draw()
    love.graphics.setFont(self.font)

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x-self.textSpace, self.y-self.textSpace, self.width+(self.textSpace*2), self.height+(self.textSpace*2), self.roundEdge)

    if (self.hovered == true) then
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.rectangle("fill", self.x-self.textSpace, self.y-self.textSpace, self.width+(self.textSpace*2), self.height+(self.textSpace*2), self.roundEdge)
    end

    love.graphics.setColor(0,0,0)
    love.graphics.print(self.text, self.x, self.y)

end