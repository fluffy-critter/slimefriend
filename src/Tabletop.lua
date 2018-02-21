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
        objects = {},
        cx = 320,
        cy = 370,
        rx = 192,
        ry = 370-335,
        bg = love.graphics.newImage("table.png")
    })

    self.canvasFront = love.graphics.newCanvas(self.width, self.height)
    self.canvasBack = love.graphics.newCanvas(self.width, self.height)

    return self
end

function Tabletop:update(dt)
    for _,item in ipairs(self.objects) do
        if not item.depth then
            item.depth = item.y - self.cy
            item.y = 0
        end
    end
end

function Tabletop:draw()
    -- sort the objects front to back
    table.sort(self.objects, function(a,b)
        return a.depth < b.depth
    end)

    -- draw the front-side buffer (player's view)
    self.canvasFront:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setBlendMode("alpha")

        love.graphics.draw(self.bg)

        for _,item in ipairs(self.objects) do
            local y = self.cy + item.depth + item.y
            love.graphics.draw(item.sprite, Sprites.quad, item.x, y, item.r, item.size, item.size, 1, 1)
        end
    end)

    -- draw the back-side buffer (slime's view)
    self.canvasBack:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setBlendMode("alpha")

        love.graphics.draw(self.bg)

        for _,item in util.rpairs(self.objects) do
            local y = self.cy - item.depth + item.y
            love.graphics.draw(item.sprite, Sprites.quad, item.x, y, item.r, item.size, item.size, 1, 1)
        end
    end)

    return self.canvasFront, self.canvasBack
end

function Tabletop:atPosition()
end

return Tabletop
