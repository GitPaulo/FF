local love = _G.love
local SoundManager = {}

function SoundManager:loadSound(filePath)
    return love.audio.newSource(filePath, 'static')
end

function SoundManager:playSound(sound, params)
    params = params or {}
    local delay = params.delay or 0
    local repeatCount = params.repeatCount or 1
    local volume = params.volume or 1
    local pitch = params.pitch or 1

    if delay > 0 then
        self:scheduleSound(sound, delay, repeatCount, volume, pitch)
    else
        self:executeSound(sound, repeatCount, volume, pitch)
    end
end

function SoundManager:scheduleSound(sound, delay, repeatCount, volume, pitch)
    local currentTime = love.timer.getTime()
    table.insert(
        self.scheduledSounds,
        {
            time = currentTime + delay,
            sound = sound,
            repeatCount = repeatCount,
            volume = volume,
            pitch = pitch
        }
    )
end

function SoundManager:executeSound(sound, repeatCount, volume, pitch)
    sound:setVolume(volume)
    sound:setPitch(pitch)
    for i = 1, repeatCount do
        sound:play()
    end
end

SoundManager.scheduledSounds = {}

function SoundManager:update()
    local currentTime = love.timer.getTime()
    for i = #self.scheduledSounds, 1, -1 do
        local soundData = self.scheduledSounds[i]
        if currentTime >= soundData.time then
            self:executeSound(soundData.sound, soundData.repeatCount, soundData.volume, soundData.pitch)
            table.remove(self.scheduledSounds, i)
        end
    end
end

return SoundManager
