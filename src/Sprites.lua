--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

sprite stuff

]]

local Sprites = {
    quad = love.graphics.newQuad(0, 0, 2, 2, 2, 2)
}

local extensions = {
    png = true,
    gif = true,
    jpg = true
}

local function isValidExt(name)
    local ext = string.match(name, '^.+%.(.+)$')
    return extensions[ext]
end

function Sprites.loadFolder(dir)
    local collection = {}
    local files = love.filesystem.getDirectoryItems(dir)
    for _,name in ipairs(files) do
        local fullPath = dir .. '/' .. name
        print(fullPath)
        if love.filesystem.isDirectory(fullPath) then
            collection[name] = Sprites.loadFolder(fullPath)
        elseif isValidExt(name) then
            collection[name] = love.graphics.newImage(fullPath)
        end
    end

    return collection
end

return Sprites
