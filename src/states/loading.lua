local json = require 'lib/json'
local Loading = {}

function Loading:enter(params)
    self.songs = params.songs
    self.currentSongIndex = 1
    self.loadingCoroutine = coroutine.create(function()
        self:loadSongs()
    end)
end

function Loading:loadSongs()
    while self.currentSongIndex <= #self.songs do
        local song = self.songs[self.currentSongIndex]
        local fftDataFile = love.filesystem.read(song.fftDataPath)
        song.fftData = json.decode(fftDataFile)
        self.currentSongIndex = self.currentSongIndex + 1
        coroutine.yield()
    end
    self.stateMachine:change('game', { songs = self.songs })
end

function Loading:update(dt)
    if self.loadingCoroutine then
        local success, message = coroutine.resume(self.loadingCoroutine)
        if not success then
            error(message)
        end
        if coroutine.status(self.loadingCoroutine) == "dead" then
            self.loadingCoroutine = nil
        end
    end
end

function Loading:render()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.printf("Loading...", 0, love.graphics.getHeight() / 2 - 10, love.graphics.getWidth(), "center")
    if self.songs then
        local progress = (self.currentSongIndex - 1) / #self.songs
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, love.graphics.getHeight() / 2, love.graphics.getWidth() / 2 * progress, 20)
        love.graphics.rectangle("line", love.graphics.getWidth() / 4, love.graphics.getHeight() / 2, love.graphics.getWidth() / 2, 20)
    end
end

return Loading
