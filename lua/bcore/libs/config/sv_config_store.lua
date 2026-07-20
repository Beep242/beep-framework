-- Server-side authoritative config store: validates edits, persists them, and hands off to
-- sh_config_sync.lua to broadcast. All cross-library calls here (BCORE:SaveData/GetData,
-- BCORE.netstream) only ever happen inside function bodies or hook callbacks that run well
-- after every addon's Lua has finished loading, so this file has no load-order dependency on
-- where "config" happens to sit relative to "saving"/"networking" alphabetically.

function BCORE:SetConfig(ply, addonId, key, rawValue)
    if not BCORE:IsConfigAdmin(ply) then
        BCORE:AddText(ply, "[Config] You do not have permission to edit the server config.")
        return false
    end

    -- Editing who counts as a config admin always requires a real SuperAdmin, so an admin
    -- can never grant themselves broader access by editing this one list.
    if addonId == "bcore" and key == "AdminGroups" and not ply:IsSuperAdmin() then
        BCORE:AddText(ply, "[Config] Only SuperAdmins may edit Config Admin Groups.")
        return false
    end

    local def = BCORE:GetConfigDefinition(addonId, key)
    if not def then
        BCORE:AddText(ply, "[Config] Unknown config entry.")
        return false
    end

    local cleaned, err = BCORE:ValidateConfigValue(def, rawValue)
    local acceptsEmpty = def.type == "list" or def.type == "records" or def.type == "colors"

    if cleaned == nil and not acceptsEmpty then
        BCORE:AddText(ply, "[Config] Rejected value for " .. tostring(def.label or key) .. ": " .. tostring(err))
        return false
    end

    BCORE.Config.Values[addonId] = BCORE.Config.Values[addonId] or {}
    BCORE.Config.Values[addonId][key] = cleaned

    BCORE:SaveConfigAddon(addonId)
    BCORE:BroadcastConfigValue(addonId, key)

    return true
end

function BCORE:SaveConfigAddon(addonId)
    local values = BCORE.Config.Values[addonId]
    if not values then return end

    BCORE:SaveData("server", "bcore_config_" .. addonId, values, true)
end

-- Runs before BCORE.Config.RegisterSetHook (same hook name, alphabetically-later identifier
-- isn't relied on for ordering - both are plain top-level Lua functions, this one just needs
-- to run once after every addon's RegisterConfig calls have already executed, which
-- InitPostEntity already guarantees regardless of hook registration order).
hook.Add("InitPostEntity", "BCORE.Config.LoadPersisted", function()
    for addonId, definitions in pairs(BCORE.Config.Definitions) do
        local saved = BCORE:GetData("server", "bcore_config_" .. addonId, true)

        if istable(saved) then
            for key, def in pairs(definitions) do
                if saved[key] ~= nil then
                    local revived = BCORE:ReviveConfigValue(def, saved[key])
                    local cleaned, err = BCORE:ValidateConfigValue(def, revived)
                    local acceptsEmpty = def.type == "list" or def.type == "records" or def.type == "colors"

                    if cleaned ~= nil or acceptsEmpty then
                        BCORE.Config.Values[addonId][key] = cleaned
                    else
                        ErrorNoHalt("[BCORE.Config] Discarded corrupt saved value for " .. addonId .. "." .. key .. ": " .. tostring(err) .. "\n")
                    end
                end
            end
        end
    end

    -- Give server-side code the same "config is now fully loaded" signal the client gets
    -- from its own full sync, so anything mirroring BCORE.Config into a legacy table (like
    -- beeps-printers' BCORE.Printers.Config) picks up persisted overrides on boot too.
    hook.Run("BCORE.Config.Synced")
end)
