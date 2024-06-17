local json = require 'lib/json'
local Fighter, love = _G.Fighter, _G.love
local Loading = {}

function Loading:enter(params)
    self.songs = params.songs
    self.currentSongIndex = 1
    self.loadingStarted = false
    self.startTime = love.timer.getTime()
    self.loadingCoroutine =
        coroutine.create(
        function()
            self:loadSongs()
            self:loadFighters()
            self.stateMachine:change('game', {songs = self.songs, fighter1 = self.fighter1, fighter2 = self.fighter2})
        end
    )
end

function Loading:loadFighters()
    self.fighter1 = Fighter:new(
        1,
        100,
        200,
        {
            left = 'a',
            right = 'd',
            jump = 'w',
            lightAttack = 'e',
            mediumAttack = 'r',
            heavyAttack = 't'
        },
        {speed = 200},
        {
            light = {width = 95, height = 70, recovery = 0.2, damage = 7, duration = 0.5},
            medium = {width = 125, height = 25, recovery = 0.5, damage = 15, duration = 0.8},
            heavy = {width = 125, height = 25, recovery = 1, damage = 20, duration = 1.4}
        },
        {
            idle = {'assets/Fighter1/Idle.png', 8},
            run = {'assets/Fighter1/Run.png', 8},
            jump = {'assets/Fighter1/Jump.png', 2},
            light = {'assets/Fighter1/Attack1.png', 6},
            medium = {'assets/Fighter1/Attack2.png', 6},
            heavy = {'assets/Fighter1/Attack2.png', 6},
            hit = {'assets/Fighter1/Take Hit.png', 4},
            death = {'assets/Fighter1/Death.png', 6}
        },
        {
            light = 'assets/Fighter1/Attack1.wav',
            medium = 'assets/Fighter1/Attack1.wav',
            heavy = 'assets/Fighter1/Attack1.wav',
            hit = 'assets/Fighter1/Hit.mp3',
            block = 'assets/Fighter1/Block.wav',
            jump = 'assets/Fighter1/Jump.mp3'
        }
    )

    self.fighter2 = Fighter:new(
        2,
        600,
        200,
        {
            left = 'h',
            right = 'k',
            jump = 'u',
            lightAttack = 'i',
            mediumAttack = 'o',
            heavyAttack = 'p'
        },
        {speed = 160},
        {
            light = {width = 90, height = 20, recovery = 0.1, damage = 7, duration = 0.5},
            medium = {width = 90, height = 90, recovery = 0.4, damage = 12, duration = 0.7},
            heavy = {width = 90, height = 90, recovery = 0.8, damage = 25, duration = 1.2}
        },
        {
            idle = {'assets/Fighter2/Idle.png', 4},
            run = {'assets/Fighter2/Run.png', 8},
            jump = {'assets/Fighter2/Jump.png', 2},
            light = {'assets/Fighter2/Attack1.png', 4},
            medium = {'assets/Fighter2/Attack2.png', 4},
            heavy = {'assets/Fighter2/Attack2.png', 4},
            hit = {'assets/Fighter2/Take Hit.png', 3},
            death = {'assets/Fighter2/Death.png', 7}
        },
        {
            light = 'assets/Fighter2/Attack1.wav',
            medium = 'assets/Fighter2/Attack1.wav',
            heavy = 'assets/Fighter2/Attack1.wav',
            hit = 'assets/Fighter1/Hit.mp3',
            block = 'assets/Fighter2/Block.wav',
            jump = 'assets/Fighter1/Jump.mp3'
        }
    )
end

function Loading:loadSongs()
    while self.currentSongIndex <= #self.songs do
        local song = self.songs[self.currentSongIndex]
        local fftDataFile = love.filesystem.read(song.fftDataPath)
        song.fftData = json.decode(fftDataFile)
        self.currentSongIndex = self.currentSongIndex + 1
        coroutine.yield()
    end
end

function Loading:update(dt)
    if not self.loadingStarted then
        if love.timer.getTime() - self.startTime > 1 then -- 1-second delay
            self.loadingStarted = true
        else
            return
        end
    end

    if self.loadingCoroutine then
        local success, message = coroutine.resume(self.loadingCoroutine)
        if not success then
            error(message)
        end
        if coroutine.status(self.loadingCoroutine) == 'dead' then
            self.loadingCoroutine = nil
        end
    end
end

function Loading:render()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.printf('Loading...', 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), 'center')
    if self.songs then
        local progress = (self.currentSongIndex - 1) / #self.songs
        love.graphics.rectangle(
            'fill',
            love.graphics.getWidth() / 4,
            love.graphics.getHeight() / 2,
            love.graphics.getWidth() / 2 * progress,
            20
        )
        love.graphics.rectangle(
            'line',
            love.graphics.getWidth() / 4,
            love.graphics.getHeight() / 2,
            love.graphics.getWidth() / 2,
            20
        )
    end
end

return Loading
