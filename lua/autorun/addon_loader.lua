BCORE = BCORE or {}

local function LogFileLoad(prefix, filePrefix, filePath, color)
    local label = {
        sh_ = "[SH]",
        sv_ = "[SV]",
        cl_ = "[CL]"
    }
    MsgC(color, prefix .. (label[filePrefix] or "[UNK]") .. " -> ", Color(255, 255, 255, 200), filePath, "\n")
end


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


BCORE:LoadAddon("bcore", {"sh_pon.lua", "sh_netstream2.lua", "sh_config_registry.lua"}, "[BCORE]")


