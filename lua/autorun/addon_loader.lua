BCORE = BCORE or {}

-- Prints one "[PREFIX][SH] -> path/to/file.lua"-style line as each file loads.
local function LogFileLoad(prefix, filePrefix, filePath, color)
    local label = {
        sh_ = "[SH]",
        sv_ = "[SV]",
        cl_ = "[CL]"
    }
    MsgC(color, prefix .. (label[filePrefix] or "[UNK]") .. " -> ", Color(255, 255, 255, 200), filePath, "\n")
end

-- Includes one file according to its sh_/sv_/cl_ filename prefix: sh_ on both realms,
-- sv_ server-only, cl_ sent to (and only included on) the client.
local function LoadFileByPrefix(filePath, fileName, prefix)
    local loadAction = string.StartWith(fileName, "sh_") and function()
        LogFileLoad(prefix, "sh_", filePath, Color(0, 255, 4, 200))
        if SERVER then AddCSLuaFile(filePath) end
        include(filePath)
    end or string.StartWith(fileName, "sv_") and function()
        LogFileLoad(prefix, "sv_", filePath, Color(0, 255, 255, 200))
        if SERVER then include(filePath) end
    end or string.StartWith(fileName, "cl_") and function()
        LogFileLoad(prefix, "cl_", filePath, Color(255, 251, 0, 200))
        if SERVER then AddCSLuaFile(filePath) else include(filePath) end
    end

    if loadAction then loadAction() end
end

-- Recursively walks `folder`, loading every sh_/sv_/cl_-prefixed file it finds. Files listed
-- in `priorityFiles` load first (checked at every folder depth, not just the top level - see
-- the call site below for why that matters), then everything else in each folder loads in
-- alphabetical order before recursing into subfolders. `loadedFiles` dedupes so a
-- priority-loaded file is never included a second time by the normal pass.
local function LoadFilesInFolder(folder, priorityFiles, loadedFiles, prefix)
    loadedFiles = loadedFiles or {}
    prefix = prefix or "[BCORE]"
    local files, subfolders = file.Find(folder .. "/*", "LUA")

    if priorityFiles then
        for _, priorityFileName in ipairs(priorityFiles) do
            local priorityFilePath = folder .. "/" .. priorityFileName
            if file.Exists(priorityFilePath, "LUA") and not loadedFiles[priorityFilePath] then
                loadedFiles[priorityFilePath] = true
                LoadFileByPrefix(priorityFilePath, priorityFileName, prefix)
            end
        end
    end

    for _, fileName in ipairs(files) do
        local filePath = folder .. "/" .. fileName
        if (not priorityFiles or not priorityFiles[fileName]) and not loadedFiles[filePath] then
            loadedFiles[filePath] = true
            LoadFileByPrefix(filePath, fileName, prefix)
        end
    end

    for _, subfolderName in ipairs(subfolders) do
        LoadFilesInFolder(folder .. "/" .. subfolderName, priorityFiles, loadedFiles, prefix)
    end
end

function BCORE:LoadAddon(folder, priorityFiles, prefix)
    prefix = prefix or "[BCORE]"
    MsgC(Color(30, 0, 255, 200), "\n" .. prefix .. " Loading \n")
    LoadFilesInFolder(folder, priorityFiles, {}, prefix)
    MsgC(Color(30, 0, 255, 200), prefix .. " Loaded \n \n")
end

-- sh_config_registry.lua has to load before sh_config_admin.lua/sh_whitelist.lua (both of
-- which call BCORE:RegisterConfig at their own file scope, immediately, to register their
-- own settings) - but alphabetically "sh_config_admin.lua" < "sh_config_registry.lua" within
-- their shared folder, so without this priority entry the registry loses that race and
-- everything call BCORE:RegisterConfig before it exists, throwing an uncaught error that
-- aborts the rest of this whole script (including the networking/saving/ui folders below it).
-- This priority list is checked at every folder depth during the walk (that's how sh_pon.lua/
-- sh_netstream2.lua below already work despite living in bcore/libs/networking/, not bcore/
-- itself), so this one extra entry is enough regardless of which folder it actually lives in.
BCORE:LoadAddon("bcore", {"sh_pon.lua", "sh_netstream2.lua", "sh_config_registry.lua"}, "[BCORE]")

-- Server access control now lives in bcore/libs/config (BCORE.Config's "bcore" namespace:
-- WhitelistEnabled / WhitelistedSteamIDs), editable in-game via the config panel instead of
-- being hardcoded here. See lua/bcore/libs/config/sh_whitelist.lua.
