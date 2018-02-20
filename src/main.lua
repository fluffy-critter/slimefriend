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

local canvas = love.graphics.newCanvas(640, 480)
canvas:setFilter("nearest")

local background

local uiOffset = {
    x = 0, y = 0, sx = 1, sy = 1
}

local mx, my

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
    local blitSX = blitSize[1]*sx/canvasWidth
    local blitSY = blitSize[2]/canvasHeight
    love.graphics.draw(canvas, blitX, blitY, 0, blitSX, blitSY)

    uiOffset.x = blitX
    uiOffset.y = blitY
    uiOffset.sx = blitSX
    uiOffset.sy = blitSY
end

function love.load()
    Game.slime = Slime.new({width=640, height=480})

    for _=1,50 do
        local size = math.random(1, 100)
        local hue = math.random()*math.pi*2
        table.insert(Game.slime.blobs, {
            x = math.random(320 - size/4, 320 + size/4),
            y = math.random(240 - size, 240 - size/4),
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

    mx, my = love.mouse.getPosition()
    mx = (mx - uiOffset.x)/uiOffset.sx
    my = (my - uiOffset.y)/uiOffset.sy

    Game.mouseOver = Game.slime:atPosition(mx, my)
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

        -- mouse cursor
        love.graphics.circle("fill", mx, my, 10)
    end)

    blitCanvas(canvas)
end
