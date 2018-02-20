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
        blobRes = 512,
        blobs = {},
        gravity = 250,
        friction = 0.9
    })

    local fpFormat = gfx.selectCanvasFormat("rgba32f", "rgba", "rgba16f", "rg11b10f")

    self.densityMap = love.graphics.newCanvas(self.width, self.height, fpFormat)
    self.colorMap = love.graphics.newCanvas(self.width, self.height, fpFormat)
    self.canvas = love.graphics.newCanvas(self.width, self.height, gfx.selectCanvasFormat("rgba8", "rgba4"))

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

function Slime:update(dt)
    local friction = math.pow(self.friction, dt)

    for _,blob in ipairs(self.blobs) do
        blob.ax = 0
        blob.ay = self.gravity
    end

    for i=1,#self.blobs do
        local ba = self.blobs[i]

        for j=i + 1,#self.blobs do
            local bb = self.blobs[j]

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
                ba.ax = ba.ax - fx*bb.size/mass
                ba.ay = ba.ay - fy*bb.size/mass

                bb.ax = bb.ax + fx*ba.size/mass
                bb.ay = bb.ay + fy*ba.size/mass
            end

        end
    end

    for _,blob in ipairs(self.blobs) do
        if blob.x + blob.size > 1024 then
            blob.vx = blob.vx + 1024 - (blob.x + blob.size)
        end
        if blob.x - blob.size < 0 then
            blob.vx = blob.vx - (blob.x - blob.size)
        end

        local yBottom = blob.x*(self.width - blob.x)/self.width + self.height/2
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

function Slime:draw(background)

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
            love.graphics.setColor(unpack(blob.color))
            love.graphics.draw(self.sprite, self.quad, blob.x, blob.y, 0, blob.size, blob.size, 1, 1)
        end
    end)

    self.canvas:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setShader(self.shader)
        love.graphics.setColor(255,255,255)
        self.shader:send("lightDir", {-1, -1, 1})
        self.shader:send("densityMap", self.densityMap)
        self.shader:send("size", {self.densityMap:getDimensions()})
        self.shader:send("slimeColor", self.colorMap)
        self.shader:send("specularColor", {1,1,1,1})
        love.graphics.draw(background)
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

return Slime