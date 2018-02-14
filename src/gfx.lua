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

return gfx
