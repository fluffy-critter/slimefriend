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

local Game = {}
local fpFormat = gfx.selectCanvasFormat("rgba32f", "rgba", "rgba16f", "rg11b10f")

local densityMap = love.graphics.newCanvas(1024, 1024, fpFormat)
local colorMap = love.graphics.newCanvas(1024, 1024, fpFormat)

local canvas = love.graphics.newCanvas(1024, 1024)
local slimeShader = love.graphics.newShader("slime.fs")

local background

local Blob = {}

local slime = {}

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
    Blob.density = love.graphics.newCanvas(512, 512, fpFormat)
    Blob.density:renderTo(function()
        local fakeImage = love.image.newImageData(2, 2)
        love.graphics.setShader(love.graphics.newShader("makeDensityMap.fs"))
        love.graphics.draw(love.graphics.newImage(fakeImage), 0, 0, 0, 256, 256)
        love.graphics.setShader()
    end)

    Blob.quad = love.graphics.newQuad(0, 0, 2, 2, 2, 2)

    slime.blobs = {}
    for _=1,50 do
        local size = math.random(1, 200)
        local hue = math.random()*math.pi*2
        table.insert(slime.blobs, {
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
    local gravity = 250
    local friction = math.pow(0.9, dt)

    for _,blob in ipairs(slime.blobs) do
        blob.ax = 0
        blob.ay = gravity
    end

    for i=1,#slime.blobs do
        local ba = slime.blobs[i]
        for j=i + 1,#slime.blobs do
            local bb = slime.blobs[j]

            local dx, dy = bb.x - ba.x, bb.y - ba.y
            local dd2 = dx*dx + dy*dy
            local dd = math.sqrt(dd2) + 1e-12

            -- expected distance
            local ed = math.min(ba.size, bb.size)/2

            if dd < ed then
                -- repulsive force
                local mass = ba.size + bb.size
                local fx = dx*ed/dd
                local fy = dy*ed/dd
                ba.ax, ba.ay = ba.ax - fx*bb.size/mass, ba.ay - fy*bb.size/mass
                bb.ax, bb.ay = bb.ax + fx*ba.size/mass, bb.ay + fy*ba.size/mass
            end

        end
    end

    for _,blob in ipairs(slime.blobs) do
        if blob.x + blob.size > 1024 then
            blob.vx = blob.vx + 1024 - (blob.x + blob.size)
        end
        if blob.x - blob.size < 0 then
            blob.vx = blob.vx - (blob.x - blob.size)
        end

        local yBottom = blob.x*(1024 - blob.x)/1024 + 512
        local depth = blob.y + blob.size - yBottom
        if depth > 0 then
            local nx = blob.x/512 - 1
            local ny = 1
            local nn = math.sqrt(nx*nx + ny*ny)
            blob.vx = blob.vx - nx*depth/nn/2
            blob.vy = blob.vy - ny*depth/nn/2
        end

        if blob.y - blob.size < 0 then
            blob.vy = blob.vy - (blob.y - blob.size)
        end

        blob.x = blob.x + (blob.vx + 0.5*blob.ax*dt)*dt
        blob.y = blob.y + (blob.vy + 0.5*blob.ay*dt)*dt

        blob.vx = blob.vx*friction + blob.ax*dt
        blob.vy = blob.vy*friction + blob.ay*dt
    end
end

function love.draw()

    densityMap:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("add", "premultiplied")
        for _,blob in pairs(slime.blobs) do
            love.graphics.setColor(blob.size, 255, 255)
            love.graphics.draw(Blob.density, Blob.quad, blob.x, blob.y, 0, blob.size, blob.size, 1, 1)
        end
    end)

    colorMap:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("add", "premultiplied")
        for _,blob in pairs(slime.blobs) do
            love.graphics.setColor(unpack(blob.color))
            love.graphics.draw(Blob.density, Blob.quad, blob.x, blob.y, 0, blob.size, blob.size, 1, 1)
        end
    end)

    canvas:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255,255,255)
        love.graphics.draw(background)

        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setShader(slimeShader)
        love.graphics.setColor(255,255,255)
        slimeShader:send("lightDir", {-1, -1, 1})
        slimeShader:send("densityMap", densityMap)
        slimeShader:send("size", {densityMap:getDimensions()})
        slimeShader:send("slimeColor", colorMap)
        slimeShader:send("specularColor", {1,1,1,1})
        love.graphics.draw(background)
        love.graphics.setShader()

        if DEBUG then
            love.graphics.setColor(255,255,255,255)
            for _,blob in pairs(slime.blobs) do
                love.graphics.circle("line", blob.x, blob.y, blob.size)
            end
        end
    end)
    blitCanvas(canvas)
end
