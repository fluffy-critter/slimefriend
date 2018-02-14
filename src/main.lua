--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to gverbal variable " .. name, 2)
    end
})

local densityMap = love.graphics.newCanvas(1024, 1024)
local slimeShader = love.graphics.newShader("slime.fs")

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
    Blob.density = love.graphics.newCanvas(512, 512)
    Blob.density:renderTo(function()
        local fakeImage = love.image.newImageData(512,512)
        fakeImage:mapPixel(function()
            return math.random(255), math.random(255), math.random(255)
        end)
        love.graphics.setShader(love.graphics.newShader("makeDensityMap.fs"))
        love.graphics.draw(love.graphics.newImage(fakeImage), 0, 0)
        love.graphics.setShader()
    end)

    Blob.quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)

    slime.blobs = {}
    for _=1,100 do
        local size = math.random(256)
        table.insert(slime.blobs, {
            x = math.random(1024 - size),
            y = math.random(1024 - size),
            size = size,
            vx = 0,
            vy = 0,
            ax = 0,
            ay = 0
        })
    end
end

function love.update(dt)
    local gravity = 500

    for i=1,#slime.blobs do
        local ba = slime.blobs[i]
        for j=i + 1,#slime.blobs do
            local bb = slime.blobs[j]

            local dx, dy = bb.x - ba.x, bb.y - ba.y
            local dd2 = dx*dx + dy*dy
            local dd = math.sqrt(dd2) + 1e-12
            local nx, ny = dx/dd, dy/dd


            local attractDistance = ba.size + bb.size
            if dd < attractDistance then
                -- the blobs are touching, so pull them closer
                ba.ax, ba.ay = ba.ax + nx, ba.ay + ny
                bb.ax, bb.ay = bb.ax - nx, bb.ay - ny
            end

            if dd < math.min(ba.size, bb.size) then
                -- but their cores are already touching so repel a bit
                ba.ax, ba.ay = ba.ay - nx/dd2, ba.ax + nx/dd2
                bb.ax, bb.ay = bb.ay + nx/dd2, bb.ax + nx/dd2
            end
        end
    end

    for _,blob in pairs(slime.blobs) do
        if blob.x + blob.size > 1024 then
            blob.vx = blob.vx + 1024 - (blob.x + blob.size)
        end
        if blob.x - blob.size < 0 then
            blob.vx = blob.vx - (blob.x - blob.size)
        end

        if blob.y + blob.size > 1024 then
            blob.vy = blob.vy + 1024 - (blob.y + blob.size)
        end
        if blob.y - blob.size < 0 then
            blob.vy = blob.vy - (blob.y - blob.size)
        end


        blob.x = blob.x + (blob.vx + 0.5*blob.ax*dt)*dt
        blob.y = blob.y + (blob.vy + 0.5*(blob.ay + gravity)*dt)*dt

        blob.vx = blob.vx*0.9 + blob.ax*dt
        blob.vy = blob.vy*0.9 + (blob.ay + gravity)*dt
    end
end

function love.draw()

    densityMap:renderTo(function()
        love.graphics.clear(0,0,0)

        love.graphics.setBlendMode("add", "premultiplied")
        love.graphics.setColor(64,25,64)
        for _,blob in pairs(slime.blobs) do
            love.graphics.draw(Blob.density, Blob.quad, blob.x, blob.y, 0, blob.size)
        end
    end)

    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setShader(slimeShader)
    slimeShader:send("size", {densityMap:getDimensions()})
    love.graphics.setColor(255,255,255)
    blitCanvas(densityMap)
    love.graphics.setShader()

    -- blitCanvas(Blob.density)
end
