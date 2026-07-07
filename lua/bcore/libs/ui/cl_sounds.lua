//////////////////////////////////////////////////
//             BUi Web Sound Library            //
//////////////////////////////////////////////////
//I use catbox can be ran thru github like the image library, just change the url and it should work, but here is an example of how to use it with catbox
//https://files.catbox.moe/yourfile.wav
//BUi.Sounds:PlayURL("https://files.catbox.moe/yourfile.wav")   

BUi = BUi or {}
BUi.Sounds = BUi.Sounds or {}

local sounds = BUi.Sounds
local cache = {}
local soundPath = "beeps_ui/sounds/"

file.CreateDir("beeps_ui")
file.CreateDir(soundPath)

local function sanitize(url)
    return util.CRC(url) .. ".dat"
end

function sounds:Download(url, callback)
    local fileName = sanitize(url)
    local dataPath = soundPath .. fileName

    if cache[url] then
        if callback then
            callback(cache[url])
        end
        return
    end

    if file.Exists(dataPath, "DATA") then
        local snd = "data/" .. dataPath

        cache[url] = snd

        if callback then
            callback(snd)
        end

        return
    end

    http.Fetch(url, function(body, len)
        if not body or len <= 0 then return end

        file.Write(dataPath, body)

        local snd = "data/" .. dataPath
        cache[url] = snd

        if callback then
            callback(snd)
        end
    end)
end

function sounds:PlayURL(url, volume)
    self:Download(url, function(path)
        sound.PlayFile(path, "", function(station, errCode, errStr)
            if not IsValid(station) then
                print(errStr)
                return
            end

            station:SetVolume(volume or 1)
            station:Play()
        end)
    end)
end

function sounds:PlayPanel(url, panel, volume, pitch)
    if not IsValid(panel) then return end

    self:Download(url, function(path)
        panel:EmitSound(
            path,
            volume or 75,
            pitch or 100,
            1,
            CHAN_AUTO
        )
    end)
end

function sounds:Play3D(url, ent, level, pitch, volume)
    if not IsValid(ent) then return end

    self:Download(url, function(path)
        ent:EmitSound(
            path,
            level or 75,
            pitch or 100,
            volume or 1
        )
    end)
end

//////////////////////////////////////////////////
//                 Usage Example                //
//////////////////////////////////////////////////

-- BUi.Sounds:PlayURL(
--     "https://example.com/click.wav"
-- )

-- BUi.Sounds:PlayPanel(
--     "https://example.com/hover.wav",
--     panel
-- )

-- BUi.Sounds:Play3D(
--     "https://example.com/ambient.wav",
--     Entity(1)
-- )