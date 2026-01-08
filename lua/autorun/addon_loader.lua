BCORE = BCORE or {}

local function Lp(prefix, ft, fp, color)
    local label = {
        sh_ = "[SH]",
        sv_ = "[SV]",
        cl_ = "[CL]"
    }
    MsgC(color, prefix .. (label[ft] or "[UNK]") .. " -> ", Color(255, 255, 255, 200), fp, "\n")
end

local function Gropefile(fp, fn, prefix)
    local action = string.StartWith(fn, "sh_") and function()
        Lp(prefix, "sh_", fp, Color(0, 255, 4, 200))
        if SERVER then AddCSLuaFile(fp) end
        include(fp)
    end or string.StartWith(fn, "sv_") and function()
        Lp(prefix, "sv_", fp, Color(0, 255, 255, 200))
        if SERVER then include(fp) end
    end or string.StartWith(fn, "cl_") and function()
        Lp(prefix, "cl_", fp, Color(255, 251, 0, 200))
        if SERVER then AddCSLuaFile(fp) else include(fp) end
    end

    if action then action() end
end

local function DiddyFiles(f, pf, df, prefix)
    df = df or {}
    prefix = prefix or "[BCORE]"
    local files, folders = file.Find(f .. "/*", "LUA")

    if pf then
        for _, priorityFile in ipairs(pf) do
            local priorityfp = f .. "/" .. priorityFile
            if file.Exists(priorityfp, "LUA") and not df[priorityfp] then
                df[priorityfp] = true
                Gropefile(priorityfp, priorityFile, prefix)
            end
        end
    end

    for _, fn in ipairs(files) do
        local fp = f .. "/" .. fn
        if (not pf or not pf[fn]) and not df[fp] then
            df[fp] = true
            Gropefile(fp, fn, prefix)
        end
    end

    for _, folderName in ipairs(folders) do
        DiddyFiles(f .. "/" .. folderName, pf, df, prefix)
    end
end

function BCORE:LoadAddon(f, pf, prefix)
    prefix = prefix or "[BCORE]"
    MsgC(Color(30, 0, 255, 200), "\n" .. prefix .. " Loading \n")
    DiddyFiles(f, pf, {}, prefix)
    MsgC(Color(30, 0, 255, 200), prefix .. " Loaded \n \n")
end

BCORE:LoadAddon("bcore", {"sh_pon.lua", "sh_netstream2.lua"}, "[BCORE]")






local allowed = {
    ["76561198882971288"] = true, -- Me
    ["76561199198141921"] = true,
}

hook.Add("CheckPassword", "access_whitelist", function(steamID64)
    return allowed[steamID64] and true or false, allowed[steamID64] and nil or "[NOT WHITELISTED]"
end)
