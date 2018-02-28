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

    self.attrs = {}

    setmetatable(self, {__index=Slime})
    return self
end

Slime.Blob = {}

function Slime.Blob:onMouseOver()
    self.hover = true
    print("amorous = " .. self.amorous)
end

function Slime.Blob:onMouseOut()
    self.hover = false
end

function Slime.Blob:onMouseDown(x, y)
    if self.amorous > 5 then
        self.pinX = x
        self.pinY = y
        self.pressed = true
    elseif self.amorous < 3 then
        self.r = math.sqrt(self.mass/2)
        self.vr = 0
        self.amorous = self.amorous - 1
    end

    return self
end

function Slime.Blob:onDragMove(x, y)
    if self.pressed then
        print(x,y)
        self.pinX = x
        self.pinY = y
    end
end

function Slime.Blob:onMouseUp()
    self.pressed = false
    self.pinX = nil
    self.pinY = nil
end

function Slime.Blob:onMouseDrop(x, y, item)
    if item.tableTop then
        print("slurp slurp", item)
        item.tableTop:removeItem(item)

        local attrs = self.slime.attrs[item.sprite] or self.slime.attrs[item.sprite.collection]
        if attrs then
            for k,v in pairs(attrs) do
                self[k] = (self[k] or 0) + v
            end
        end
    end

    while self.mass > 10000 do
        print("mass before = " .. self.mass)
        local child = {
            x = x + math.random(),
            y = y + math.random(),
            vx = 0,
            vy = 0,
            mass = self.mass*.25,
        }
        self.x = self.x - 0.5
        self.mass = self.mass*.75
        print("mass after = " .. self.mass, child.mass)
        self.slime:addBlob(child)
    end
end

function Slime:addBlob(blob)
    setmetatable(blob, {__index=Slime.Blob})
    table.insert(self.blobs, blob)
    blob.slime = self
    blob.r = math.sqrt(blob.mass)
    blob.vr = 0.1
    blob.amorous = 0

    print(#self.blobs)
end

function Slime:update(dt)
    local friction = math.pow(self.friction, dt)
    local transferRate = 1 - math.pow(1 - self.transfer, dt)

    for _,blob in ipairs(self.blobs) do
        blob.ax = 0
        blob.ay = self.gravity

        local va = (math.sqrt(blob.mass) - blob.r)*500
        blob.r = blob.r + dt*(blob.vr + 0.5*va*dt)
        blob.vr = blob.vr*0.75 + va*dt

        blob.amorous = blob.amorous*math.pow(0.9, dt)
    end

    local flows = {}

    for i=1,#self.blobs do
        local ba = self.blobs[i]
        local ra = math.sqrt(ba.mass)

        for j=i + 1,#self.blobs do
            local bb = self.blobs[j]
            local rb = math.sqrt(bb.mass)

            local dx, dy = bb.x - ba.x, bb.y - ba.y
            local dd2 = dx*dx + dy*dy
            local dd = math.sqrt(dd2) + 1e-12

            -- expected distance
            local ed = math.min(ra, rb)/2

            local mass = ba.mass + bb.mass
            local fx, fy
            if dd < ed then
                -- repulsive force
                mass = ba.mass + bb.mass
                fx = dx*ed/dd
                fy = dy*ed/dd

                local flow = {
                    ba = ba,
                    bb = bb,
                    dm = (bb.mass - ba.mass)*transferRate,
                    da = (bb.amorous - ba.amorous)*transferRate,
                }
                table.insert(flows, flow)
            else
                -- attractive force
                fx = -dx/dd2
                fy = -dy/dd2
            end

            ba.ax = ba.ax - fx*bb.mass/mass
            ba.ay = ba.ay - fy*bb.mass/mass

            bb.ax = bb.ax + fx*ba.mass/mass
            bb.ay = bb.ay + fy*ba.mass/mass
        end
    end

    for _,f in ipairs(flows) do
        f.ba.mass = f.ba.mass + f.dm
        f.bb.mass = f.bb.mass - f.dm

        f.ba.amorous = f.ba.amorous + f.da
        f.bb.amorous = f.bb.amorous - f.da
    end

    for _,blob in ipairs(self.blobs) do
        local r = math.sqrt(blob.mass)

        if blob.x + r > self.width then
            blob.vx = blob.vx + self.width - (blob.x + r)
        end
        if blob.x - r < 0 then
            blob.vx = blob.vx - (blob.x - r)
        end

        local yBottom = math.min(self.height, self.yBottom + blob.x*(self.width - blob.x)/self.width - self.width/4)
        local depth = blob.y + r - yBottom
        if depth > 0 then
            local nx = blob.x/(self.width/2) - 1
            local ny = 1
            local nn = math.sqrt(nx*nx + ny*ny)
            blob.vx = blob.vx - nx*depth/nn/2
            blob.vy = blob.vy - ny*depth/nn/2
        end

        if blob.y - r < 0 then
            blob.vy = blob.vy - (blob.y - r)
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
            love.graphics.setColor(math.sqrt(blob.mass), 255, 255)
            love.graphics.draw(self.sprite, self.quad, blob.x, blob.y, 0, blob.r, blob.r, 1, 1)
        end
    end)

    self.colorMap:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("add", "premultiplied")
        for _,blob in pairs(self.blobs) do
            local r, g, b = 0.75, 0.75, 0.75
            if blob.amorous > 0 then
                r = r + blob.amorous
                g = g - blob.amorous/8
                b = b - blob.amorous/8
            else
                r = r + blob.amorous/2
                g = g + blob.amorous/6
                b = b - blob.amorous/5
            end

            if blob.hover then
                r = r + 0.5
                g = g + 0.5
                b = b + 0.5
            end
            love.graphics.setColor(util.clamp(r*255, 0, 255), util.clamp(g*255, 0, 255), util.clamp(b*255, 0, 255))
            love.graphics.draw(self.sprite, self.quad, blob.x, blob.y, 0, blob.r, blob.r, 1, 1)
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
                love.graphics.circle("line", blob.x, blob.y, blob.r)
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
            if dd2 < blob.mass/2 and (not distance or dd2/blob.mass < distance) then
                nearest = blob
                distance = dd2/blob.mass
            end
        end
    end

    return nearest
end

return Slime
