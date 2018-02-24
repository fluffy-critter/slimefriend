--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

the slime itself

]]

local Slime = {}

local gfx = require('gfx')
local util = require('util')
local config = require('config')

function Slime.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        width = 1024,
        height = 1024,
        blobRes = 256,
        blobs = {},
        gravity = 250,
        friction = 0.5,
        transfer = 0.01,
        yBottom = 768
    })

    local fpFormat = gfx.selectCanvasFormat("rgba32f", "rgba", "rgba16f", "rg11b10f")

    self.densityMap = love.graphics.newCanvas(self.width, self.height, fpFormat)
    self.colorMap = love.graphics.newCanvas(self.width, self.height, fpFormat)
    self.canvas = love.graphics.newCanvas(self.width, self.height,
        gfx.selectCanvasFormat("rgba8", "rgb10a2", "rgb5a1", "rgba4"))

    self.shader = love.graphics.newShader("slime.fs")

    self.sprite = love.graphics.newCanvas(self.blobRes, self.blobRes, fpFormat)
    self.sprite:renderTo(function()
        local fakeImage = love.image.newImageData(2, 2)
        love.graphics.setShader(love.graphics.newShader("makeDensityMap.fs"))
        love.graphics.draw(love.graphics.newImage(fakeImage), 0, 0, 0, self.blobRes/2, self.blobRes/2)
        love.graphics.setShader()
    end)
    self.quad = love.graphics.newQuad(0, 0, 2, 2, 2, 2)

    setmetatable(self, {__index=Slime})
    return self
end

Slime.Blob = {}

function Slime.Blob:onMouseOver()
    self.hover = true
end

function Slime.Blob:onMouseOut()
    self.hover = false
end

function Slime.Blob:onMouseDown(x, y)
    local grabbed = false

    if grabbed then
        self.pinX = x
        self.pinY = y
        self.pressed = true
    end
end

function Slime.Blob:onDragMove(x, y)
    self.pinX = x
    self.pinY = y
end

function Slime.Blob:onMouseUp()
    self.pressed = false
    self.pinX = nil
    self.pinY = nil
end

function Slime.Blob:onMouseDrop(_, _, item)
    print("slurp slurp", item)
    item.tableTop:removeItem(item)
end

function Slime:addBlob(blob)
    setmetatable(blob, {__index=Slime.Blob})
    table.insert(self.blobs, blob)
    blob.slime = self
end

function Slime:update(dt)
    local friction = math.pow(self.friction, dt)
    local transferRate = 1 - math.pow(1 - self.transfer, dt)

    for _,blob in ipairs(self.blobs) do
        blob.ax = 0
        blob.ay = self.gravity
    end

    local flows = {}

    for i=1,#self.blobs do
        local ba = self.blobs[i]

        for j=i + 1,#self.blobs do
            local bb = self.blobs[j]

            local dx, dy = bb.x - ba.x, bb.y - ba.y
            local dd2 = dx*dx + dy*dy
            local dd = math.sqrt(dd2) + 1e-12

            -- expected distance
            local ed = math.min(ba.size, bb.size)/2

            local mass = ba.size + bb.size
            local fx, fy
            if dd < ed then
                -- repulsive force
                mass = ba.size + bb.size
                fx = dx*ed/dd
                fy = dy*ed/dd

                local flow = {
                    ba = ba,
                    bb = bb,
                    delta = (bb.size - ba.size)*transferRate
                }
                table.insert(flows, flow)
            else
                -- attractive force
                fx = -dx/dd2
                fy = -dy/dd2
            end

            ba.ax = ba.ax - fx*bb.size/mass
            ba.ay = ba.ay - fy*bb.size/mass

            bb.ax = bb.ax + fx*ba.size/mass
            bb.ay = bb.ay + fy*ba.size/mass
        end
    end

    for _,f in ipairs(flows) do
        f.ba.size = f.ba.size + f.delta
        f.bb.size = f.bb.size - f.delta
    end

    for _,blob in ipairs(self.blobs) do
        if blob.x + blob.size > self.width then
            blob.vx = blob.vx + self.width - (blob.x + blob.size)
        end
        if blob.x - blob.size < 0 then
            blob.vx = blob.vx - (blob.x - blob.size)
        end

        local yBottom = math.min(self.height, self.yBottom + blob.x*(self.width - blob.x)/self.width - self.width/4)
        local depth = blob.y + blob.size - yBottom
        if depth > 0 then
            local nx = blob.x/(self.width/2) - 1
            local ny = 1
            local nn = math.sqrt(nx*nx + ny*ny)
            blob.vx = blob.vx - nx*depth/nn/2
            blob.vy = blob.vy - ny*depth/nn/2
        end

        if blob.y - blob.size < 0 then
            blob.vy = blob.vy - (blob.y - blob.size)
        end

        -- x' = x + vt + .5att, solve for a
        if blob.pinX then
            blob.ax = (blob.pinX - blob.x - blob.vx*0.1)/0.05
        end
        if blob.pinY then
            blob.ay = (blob.pinY - blob.y - blob.vy*0.1)/0.05
        end

        blob.x = blob.x + (blob.vx + 0.5*blob.ax*dt)*dt
        blob.y = blob.y + (blob.vy + 0.5*blob.ay*dt)*dt

        blob.vx = blob.vx*friction + blob.ax*dt
        blob.vy = blob.vy*friction + blob.ay*dt
    end
end

function Slime:draw(background, foreground)
    self.densityMap:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("add", "premultiplied")
        for _,blob in pairs(self.blobs) do
            love.graphics.setColor(blob.size, 255, 255)
            love.graphics.draw(self.sprite, self.quad, blob.x, blob.y, 0, blob.size, blob.size, 1, 1)
        end
    end)

    self.colorMap:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("add", "premultiplied")
        for _,blob in pairs(self.blobs) do
            local r, g, b = unpack(blob.color)
            if blob.hover then
                r = r + 128
                g = g + 128
                b = b + 128
            end
            love.graphics.setColor(r, g, b)
            love.graphics.draw(self.sprite, self.quad, blob.x, blob.y, 0, blob.size, blob.size, 1, 1)
        end
    end)

    self.canvas:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setShader(self.shader)
        love.graphics.setColor(255,255,255)
        self.shader:send("lightDir", {-10, -10, 1})
        self.shader:send("densityMap", self.densityMap)
        self.shader:send("background", background)
        self.shader:send("foreground", foreground)
        self.shader:send("size", {self.densityMap:getDimensions()})
        self.shader:send("slimeColor", self.colorMap)
        self.shader:send("specularColor", {1,1,1,1})
        love.graphics.draw(self.densityMap)
        love.graphics.setShader()

        if config.debug then
            love.graphics.setColor(255,255,255,255)
            for _,blob in pairs(self.blobs) do
                love.graphics.circle("line", blob.x, blob.y, blob.size)
            end
        end
    end)

    return self.canvas
end

function Slime:atPosition(x, y)
    local nearest, distance

    for _,blob in ipairs(self.blobs) do
        if not blob.pressed then
            local dx, dy = x - blob.x, y - blob.y
            local dd2 = dx*dx + dy*dy
            if dd2 < blob.size*blob.size/2 and (not distance or dd2/blob.size < distance) then
                nearest = blob
                distance = dd2/blob.size
            end
        end
    end

    return nearest
end

return Slime
