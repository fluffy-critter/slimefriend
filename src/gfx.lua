--[[
slimefriend!

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful graphics functions

]]

local gfx = {}

-- Select the most-preferred canvas format from a list of formats
local graphicsFormats = love.graphics.getCanvasFormats()
print("Available graphics formats:")
for k in pairs(graphicsFormats) do print('\t' .. k) end

function gfx.selectCanvasFormat(...)
    for _,k in ipairs({...}) do
        if graphicsFormats[k] then
            return k
        end
    end
    return nil
end

-- render a shader from a source buffer to a destination buffer with a shader and args; return the buffers swapped
function gfx.mapShader(source, dest, shader, args)
    dest:renderTo(function()
        love.graphics.push("all")

        love.graphics.setBlendMode("replace", "premultiplied")
        love.graphics.setShader(shader)
        for k,v in pairs(args) do
            shader:send(k,v)
        end
        love.graphics.draw(source)

        love.graphics.pop()
    end)
    return dest, source
end

return gfx
