local json = require 'lib.json'
local table = require 'lib.table'

local KeyMappings, Fighter, love = _G.KeyMappings, _G.Fighter, _G.love
local Loading = {}

function Loading:enter(params)
    self.useAI = params.useAI or false
    self.selectedFighters = params.selectedFighters
    self.songs = params.songs

    assert(self.songs, 'Songs must be provided to the loading state')
    assert(self.selectedFighters, 'Selected fighters must be provided to the loading state')

    self.currentSongIndex = 1
    self.loadingStarted = false
    self.startTime = love.timer.getTime()
    self.loadingCoroutine =
        coroutine.create(
        function()
            self:loadSongs()
            self:loadFighters()
            self.stateMachine:change(
                'game',
                {useAI = self.useAI, songs = self.songs, fighter1 = self.fighter1, fighter2 = self.fighter2}
            )
        end
    )
end

function Loading:loadFighters()
    local fighter1Data = table.deepcopy(require('fighters.' .. self.selectedFighters[1]))
    local fighter2Data = table.deepcopy(require('fighters.' .. self.selectedFighters[2]))

    -- TODO: Move to config
    local startPos1 = {100, 200}
    local startPos2 = {600, 200}
    self.fighter1 =
        Fighter:new(
        1,
        false, -- AI
        fighter1Data.name,
        startPos1[1],
        startPos1[2],
        fighter1Data.scale,
        KeyMappings.fighter1Controls,
        fighter1Data.traits,
        fighter1Data.hitboxes,
        fighter1Data.spriteConfig,
        fighter1Data.soundFXConfig
    )

    self.fighter2 =
        Fighter:new(
        2,
        self.useAI, -- AI
        fighter2Data.name,
        startPos2[1],
        startPos2[2],
        fighter2Data.scale,
        KeyMappings.fighter2Controls,
        fighter2Data.traits,
        fighter2Data.hitboxes,
        fighter2Data.spriteConfig,
        fighter2Data.soundFXConfig
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
