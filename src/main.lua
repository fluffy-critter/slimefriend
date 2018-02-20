--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to gverbal variable " .. name, 2)
    end
})

local DEBUG = false

local gfx = require('gfx')
local Slime = require('slime')

local Game = {}

local canvas = love.graphics.newCanvas(1024, 1024)

local background

local function blitCanvas(canvas, aspect)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local canvasHeight = canvas:getHeight()
    local canvasWidth = aspect and (canvasHeight * aspect) or canvas:getWidth()
    local sx = canvasWidth/canvas:getWidth()

    local blitSize = { screenWidth, screenWidth*canvasHeight/canvasWidth }
    if screenHeight < blitSize[2] then
        blitSize = { screenHeight*canvasWidth/canvasHeight, screenHeight }
    end

    local blitX = (love.graphics.getWidth() - blitSize[1])/2
    local blitY = (love.graphics.getHeight() - blitSize[2])/2
    love.graphics.draw(canvas, blitX, blitY, 0,
        blitSize[1]*sx/canvasWidth, blitSize[2]/canvasHeight)
end

function love.load()
    Game.slime = Slime.new()

    for _=1,50 do
        local size = math.random(1, 200)
        local hue = math.random()*math.pi*2
        table.insert(Game.slime.blobs, {
            x = math.random(512 - size/4, 512 + size/4),
            y = math.random(512 - size, 512 - size/4),
            size = size,
            vx = 0,
            vy = 0,
            ax = 0,
            ay = 0,
            color = {128 + 128*math.cos(hue),
                128 + 128*math.cos(hue + math.pi*2/3),
                128 + 128*math.cos(hue - math.pi*2/3)}
        })
    end

    background = love.graphics.newImage('background.png')
end

function love.update(dt)
    Game.slime:update(dt)

    Game.mouseOver = Game.slime:atPosition(love.mouse.getPosition())
end

function love.draw()
    local slimeCanvas = Game.slime:draw(background, Game.mouseOver)

    canvas:renderTo(function()
        love.graphics.setColor(255,255,255)
        love.graphics.draw(background)

        love.graphics.setColor(0,0,0)
        love.graphics.draw(slimeCanvas, -1, -1)
        love.graphics.draw(slimeCanvas, -1, 1)
        love.graphics.draw(slimeCanvas, 1, -1)
        love.graphics.draw(slimeCanvas, 1, 1)

        love.graphics.setColor(255,255,255)
        love.graphics.draw(slimeCanvas)
    end)

    blitCanvas(canvas)
end
