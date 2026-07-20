-- Broadcasts server-authoritative config to clients and keeps each client's local cache
-- (BCORE.Config.Values on the client realm) in sync. Every netstream call here is deferred
-- into InitPostEntity/hook callbacks so it never runs before BCORE.netstream itself has
-- loaded, regardless of which order the "config"/"networking" library folders happen to load in.

if SERVER then
    local function BuildFullSyncPayload()
        local payload = {}
        for addonId, values in pairs(BCORE.Config.Values) do
            payload[addonId] = {}
            for key, value in pairs(values) do
                payload[addonId][key] = value
            end
        end
        return payload
    end

    function BCORE:BroadcastConfigValue(addonId, key)
        local addon = BCORE.Config.Values[addonId]
        local value = addon and addon[key]
        BCORE.netstream.Start(nil, "BCORE.Config.Value", addonId, key, value)

        -- Fire the same local hook clients get from their sync receiver, so server-side
        -- code (e.g. an addon mirroring BCORE.Config into its own legacy config table) can
        -- react to a live admin edit without needing a restart to see it.
        hook.Run("BCORE.Config.ValueChanged", addonId, key)
    end

    hook.Add("PlayerInitialSpawn", "BCORE.Config.SyncNewPlayer", function(ply)
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            BCORE.netstream.Start(ply, "BCORE.Config.Full", BuildFullSyncPayload())
        end)
    end)

    hook.Add("InitPostEntity", "BCORE.Config.RegisterSetHook", function()
        BCORE.netstream.Hook("BCORE.Config.Set", function(ply, addonId, key, value)
            BCORE:SetConfig(ply, addonId, key, value)
        end)
    end)
else
    local function ApplySyncedValue(addonId, key, rawValue)
        BCORE.Config.Values[addonId] = BCORE.Config.Values[addonId] or {}

        local def = BCORE:GetConfigDefinition(addonId, key)
        BCORE.Config.Values[addonId][key] = def and BCORE:ReviveConfigValue(def, rawValue) or rawValue
    end

    hook.Add("InitPostEntity", "BCORE.Config.RegisterSyncHooks", function()
        BCORE.netstream.Hook("BCORE.Config.Full", function(payload)
            for addonId, values in pairs(payload or {}) do
                for key, value in pairs(values) do
                    ApplySyncedValue(addonId, key, value)
                end
            end
            hook.Run("BCORE.Config.Synced")
        end)

        BCORE.netstream.Hook("BCORE.Config.Value", function(addonId, key, value)
            ApplySyncedValue(addonId, key, value)
            hook.Run("BCORE.Config.ValueChanged", addonId, key)
        end)
    end)

    function BCORE:RequestSetConfig(addonId, key, value)
        BCORE.netstream.Start("BCORE.Config.Set", addonId, key, value)
    end
end
