local love = _G.love;

-- Global
_G.isDebug = true

-- Love Configuration
function love.conf(t)
    t.window.width = 425
    t.window.height = 281
    t.window.title = "FF: A Tiny Fighting Game"
    t.console = _G.isDebug
end
