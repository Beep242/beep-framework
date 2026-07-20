-- Replaces the old hardcoded 2-SteamID CheckPassword hack that used to live in
-- lua/autorun/addon_loader.lua. Off by default, and fully driven by the config system now -
-- an admin turns it on and edits the list through the in-game config panel, no file edits or
-- restarts required.

BCORE:RegisterConfig("bcore", "WhitelistEnabled", {
    label = "Enable Server Whitelist",
    category = "Access Control",
    description = "When on, only players whose SteamID64 is in the list below may connect. Off by default.",
    type = "bool",
    default = false,
})

BCORE:RegisterConfig("bcore", "WhitelistedSteamIDs", {
    label = "Whitelisted SteamIDs",
    category = "Access Control",
    description = "SteamID64s (e.g. 76561198882971288). Only enforced while Enable Server Whitelist is on.",
    type = "list",
    itemType = "string",
    default = {},
})

if SERVER then
    hook.Add("CheckPassword", "BCORE.Config.Whitelist", function(steamID64)
        if not BCORE:GetConfig("bcore", "WhitelistEnabled") then return end

        local list = BCORE:GetConfig("bcore", "WhitelistedSteamIDs") or {}
        for _, sid in ipairs(list) do
            if sid == steamID64 then return end
        end

        return false, "You are not on this server's whitelist."
    end)
end
