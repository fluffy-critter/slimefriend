--[[
Slimefriend

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

conf.lua - LÖVE configuration

]]

function love.conf(t)
    t.modules.joystick = true
    t.modules.physics = false
    t.window.resizable = true
    t.window.fullscreen = false
    t.window.width = 512
    t.window.height = 512

    t.version = "0.10.2"

    t.identity = "SlimeFriend"
    t.window.title = "Slime Friend!"
end
