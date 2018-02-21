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
local Slime = require('Slime')
local Sprites = require('Sprites')
local Tabletop = require('Tabletop')

local Game = {}

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
    Game.slime = Slime.new({width=640, height=480, yBottom=360})
    Game.emoji = Sprites.loadFolder('emoji')

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

    Game.layers = {}
    Game.layers.background = love.graphics.newImage('background.png')
    Game.layers.reflection = love.graphics.newCanvas(640, 480)

    Game.tabletop = Tabletop.new()

    for _,item in pairs(Game.emoji.objects) do
        table.insert(Game.tabletop.objects, {
            sprite = item,
            size = 16,
            x = math.random(320 - 80, 320 + 80),
            y = math.random(335, 420)
        })
    end

    Game.canvas = love.graphics.newCanvas(640, 480)
    Game.canvas:setFilter("nearest")

    Game.objects = {}
end

function love.update(dt)
    Game.slime:update(dt)
    Game.tabletop:update(dt)

    mx, my = love.mouse.getPosition()
    mx = (mx - uiOffset.x)/uiOffset.sx
    my = (my - uiOffset.y)/uiOffset.sy

    Game.mouseOver = Game.slime:atPosition(mx, my)
end

function love.draw()
    local tableFront, tableBack = Game.tabletop:draw()

    Game.layers.reflection:renderTo(function()
        love.graphics.setBlendMode("alpha")
        love.graphics.clear(0,0,0,0)
        love.graphics.setColor(255,255,255)

        -- mouse cursor
        love.graphics.circle("fill", mx, my, 10)

        love.graphics.draw(tableBack)
    end)

    local slimeCanvas = Game.slime:draw(Game.layers.background, Game.layers.reflection)

    Game.canvas:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(255,255,255)
        love.graphics.draw(Game.layers.background)

        love.graphics.setColor(0,0,0)
        love.graphics.draw(slimeCanvas, -1, -1)
        love.graphics.draw(slimeCanvas, -1, 1)
        love.graphics.draw(slimeCanvas, 1, -1)
        love.graphics.draw(slimeCanvas, 1, 1)

        love.graphics.setColor(255,255,255)
        love.graphics.draw(slimeCanvas)

        love.graphics.draw(tableFront)
    end)

    blitCanvas(Game.canvas)
end
