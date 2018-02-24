--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to global variable " .. name, 2)
    end
})

local Slime = require('Slime')
local Sprites = require('Sprites')
local Tabletop = require('Tabletop')

local Game = {}
local mouse = {}

local uiOffset = {
    x = 0, y = 0, sx = 1, sy = 1
}

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

    for _=1,4 do
        local size = math.random(50, 100)
        Game.slime:addBlob({
            x = math.random(320 - size/4, 320 + size/4),
            y = math.random(360 - size, 400 - size),
            size = size,
            vx = 0,
            vy = 0,
            ax = 0,
            ay = 0,
            color = {64, 64, 64}
        })
    end

    Game.layers = {}
    Game.layers.background = love.graphics.newImage('background.png')
    Game.layers.reflection = love.graphics.newCanvas(640, 480)

    Game.tabletop = Tabletop.new()

    for _,sprite in pairs(Game.emoji.entrees) do
        local size = 16
        local x = math.random()*2 - 1
        local y = (math.random()*2 - 1)*math.sqrt(1 - x*x)
        Game.tabletop:addItem({
            sprite = sprite,
            size = size,
            x = Game.tabletop.cx + x*(Game.tabletop.rx - size),
            y = Game.tabletop.cy + y*(Game.tabletop.ry) - size
        })
    end

    Game.canvas = love.graphics.newCanvas(640, 480)
    Game.canvas:setFilter("nearest")

    Game.objects = {}
end

local function uiPos(x, y)
    return (x - uiOffset.x)/uiOffset.sx, (y - uiOffset.y)/uiOffset.sy
end


function love.update(dt)
    Game.slime:update(dt)
    Game.tabletop:update(dt)

    local x, y = uiPos(love.mouse.getPosition())
    mouse.x, mouse.y = x, y

    if mouse.pressed and mouse.activeObject and mouse.activeObject.onDragMove then
        mouse.activeObject:onDragMove(x + mouse.offsetX, y + mouse.offsetY)
    end

    local prevHover = mouse.hoverObject
    mouse.hoverObject = Game.tabletop:atPosition(x, y) or Game.slime:atPosition(x, y)
    if prevHover ~= mouse.hoverObject then
        if prevHover and prevHover.onMouseOut then
            prevHover:onMouseOut(x, y)
        end
        if mouse.hoverObject and mouse.hoverObject.onMouseOver then
            mouse.hoverObject:onMouseOver(x, y)
        end
    end
end

function love.mousepressed(x, y, button)
    x, y = uiPos(x, y)

    mouse.pressed = button == 1

    if button == 1 and mouse.hoverObject then
        local grab = true
        if mouse.hoverObject.onMouseDown then
            mouse.offsetX = mouse.hoverObject.x - x
            mouse.offsetY = mouse.hoverObject.y - y

            grab = mouse.hoverObject:onMouseDown(x + mouse.offsetX, y + mouse.offsetY)
        end
        if grab then
            mouse.activeObject = mouse.hoverObject
            mouse.hoverObject = nil
        end
    end
end

function love.mousereleased(x, y, button)
    x, y = uiPos(x, y)

    mouse.prssed = button == 1

    if button == 1 then
        if mouse.activeObject and mouse.activeObject.onMouseUp then
            mouse.activeObject:onMouseUp(x + mouse.offsetX, y + mouse.offsetY)
            mouse.offsetX, mouse.offsetY = nil, nil
        end
        if mouse.activeObject and mouse.hoverObject and mouse.hoverObject.onMouseDrop then
            mouse.hoverObject:onMouseDrop(x, y, mouse.activeObject)
        end
        mouse.activeObject = nil
    end
end

function love.draw()
    local tableFront, tableBack = Game.tabletop:draw()

    Game.layers.reflection:renderTo(function()
        love.graphics.setBlendMode("alpha")
        love.graphics.clear(0,0,0,0)
        love.graphics.setColor(255,255,255)

        love.graphics.draw(tableBack)

        -- mouse cursor
        if mouse.x and mouse.y then
            love.graphics.circle("fill", mouse.x, mouse.y, 10)
        end

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
