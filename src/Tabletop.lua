--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

stuff on the table

]]

local Tabletop = {}

local Sprites = require('sprites')
local util = require('util')

function Tabletop.new(o)
    local self = o or {}
    setmetatable(self, {__index = Tabletop})

    util.applyDefaults(self, {
        width = 640,
        height = 480,
        items = {},
        cx = 320,
        cy = 370,
        rx = 192,
        ry = 370-335,
        bg = love.graphics.newImage("table.png")
    })

    self.canvasFront = love.graphics.newCanvas(self.width, self.height)
    self.canvasBack = love.graphics.newCanvas(self.width, self.height)

    self.hoverShader = love.graphics.newShader("hover.fs")

    return self
end

Tabletop.Item = {}

function Tabletop.Item:onMouseOver()
    self.hover = true
end

function Tabletop.Item:onMouseOut()
    self.hover = false
end

function Tabletop.Item:onMouseDown(x, y)
    self.pressed = true
    self.tableTop.activeItem = self
    self.x = x
    self.y = y

    return true
end

function Tabletop.Item:onDragMove(x, y)
    self.x = x
    self.y = y
    self.depth = self.y - self.tableTop.cy
end

function Tabletop.Item:onMouseUp()
    self.pressed = false
    self.tableTop.activeItem = nil
end

function Tabletop:addItem(item)
    setmetatable(item, {__index = Tabletop.Item})

    table.insert(self.items, item)
    item.tableTop = self
end

function Tabletop:removeItem(item)
    util.runQueue(self.items, function(ii)
        return ii == item
    end)
end

function Tabletop:update(dt)
    for _,item in ipairs(self.items) do
        if not item.depth then
            item.depth = item.y - self.cy
        end
    end
end

local function drawItem(item, x, y)
    love.graphics.draw(item.sprite.image, Sprites.quad, x, y, item.r,
        item.size, item.size, 1, 1)
end

function Tabletop:draw()
    -- sort the items front to back
    table.sort(self.items, function(a,b)
        return a.depth < b.depth
    end)

    -- draw the front-side buffer (player's view)
    self.canvasFront:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setBlendMode("alpha")

        love.graphics.draw(self.bg)

        for _,item in ipairs(self.items) do

            local y = item.y

            if item.hover or item.pressed then
                love.graphics.setShader(self.hoverShader)
                drawItem(item, item.x, y - 1)
                drawItem(item, item.x, y + 1)
                drawItem(item, item.x - 1, y)
                drawItem(item, item.x + 1, y)
                love.graphics.setShader()
            end

            drawItem(item, item.x, y)
        end
    end)

    -- draw the back-side buffer (slime's view)
    self.canvasBack:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setBlendMode("alpha")

        love.graphics.draw(self.bg)

        for _,item in util.rpairs(self.items) do
            local y = item.y - 2*item.depth
            drawItem(item, item.x, y)
        end
    end)

    return self.canvasFront, self.canvasBack
end

function Tabletop:atPosition(x, y)
    if self.activeItem then
        return nil
    end

    local nearest

    for _,item in ipairs(self.items) do
        if not item.pressed then
            local dx, dy = x - item.x, y - item.y
            local dd2 = dx*dx + dy*dy
            if dd2 < item.size*item.size then
                nearest = item
            end
        end
    end

    return nearest
end

return Tabletop
