--[[ slimefriend!

(c)2018 fluffy at beesbuzz.biz

sprite stuff

]]

local Sprites = {
    quad = love.graphics.newQuad(0, 0, 2, 2, 2, 2),
    all = {}
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
        if love.filesystem.isDirectory(fullPath) then
            collection[name] = Sprites.loadFolder(fullPath, name)
        elseif isValidExt(name) then
            local item = {
                image = love.graphics.newImage(fullPath),
                name = name,
                collection = collection
            }
            collection[name] = item
            Sprites.all[fullPath] = item
        end
    end

    return collection
end

return Sprites
