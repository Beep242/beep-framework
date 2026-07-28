BCORE.Config = BCORE.Config or {}
BCORE.Config.Definitions = BCORE.Config.Definitions or {}
BCORE.Config.Order = BCORE.Config.Order or {} 
BCORE.Config.Values = BCORE.Config.Values or {}

local function IsColorValue(v)
    return istable(v) and v.r ~= nil and v.g ~= nil and v.b ~= nil and v.a ~= nil
end
BCORE.Config.IsColorValue = IsColorValue

local function CopyConfigValue(v)
    if IsColorValue(v) then
        return Color(v.r, v.g, v.b, v.a)
    elseif istable(v) then
        local copy = {}
        for k, val in pairs(v) do
            copy[k] = CopyConfigValue(val)
        end
        return copy
    end
    return v
end
BCORE.Config.CopyValue = CopyConfigValue

--[[
    Registers one config entry. Safe to call at any point during addon load - it never
    touches networking or disk, so it has no ordering dependency on any other BCORE library.

    addonId: string namespace, e.g. "beep_inventory"
    key: string key within that namespace, e.g. "MaxSlots"
    def: {
        label = "Display Name",
        category = "Grouping shown in the config UI",
        description = "optional helper text",
        type = "bool" | "number" | "string" | "color" | "choice" | "list" | "colors" | "records",
        default = <matching value for type>,

        -- number
        min = number, max = number, decimals = number,

        -- string
        maxLength = number,

        -- choice
        choices = { "a", "b", "c" },

        -- list
        itemType = "string" | "number" (default "string"),

        -- colors: named map of Color values
        -- records: array of objects
        fields = {
            { key = "name", label = "Name", type = "string" },
            { key = "weight", label = "Weight", type = "number", min = 0 },
            ...
        },
    }
]]
function BCORE:RegisterConfig(addonId, key, def)
    if not addonId or not key or not istable(def) then
        ErrorNoHalt("[BCORE.Config] RegisterConfig called with missing arguments\n")
        return
    end

    local validTypes = {
        bool = true, number = true, string = true, color = true,
        choice = true, list = true, colors = true, records = true,
    }

    if not validTypes[def.type] then
        ErrorNoHalt("[BCORE.Config] RegisterConfig(" .. tostring(addonId) .. "." .. tostring(key) .. ") has invalid type '" .. tostring(def.type) .. "'\n")
        return
    end

    BCORE.Config.Definitions[addonId] = BCORE.Config.Definitions[addonId] or {}
    BCORE.Config.Order[addonId] = BCORE.Config.Order[addonId] or {}
    BCORE.Config.Values[addonId] = BCORE.Config.Values[addonId] or {}

    if not BCORE.Config.Definitions[addonId][key] then
        table.insert(BCORE.Config.Order[addonId], key)
    end

    BCORE.Config.Definitions[addonId][key] = def

    if BCORE.Config.Values[addonId][key] == nil then
        BCORE.Config.Values[addonId][key] = CopyConfigValue(def.default)
    end
end

function BCORE:GetConfigDefinition(addonId, key)
    local addon = BCORE.Config.Definitions[addonId]
    return addon and addon[key]
end

function BCORE:GetConfigAddonDefinitions(addonId)
    return BCORE.Config.Definitions[addonId] or {}
end

function BCORE:GetConfigAddonOrder(addonId)
    return BCORE.Config.Order[addonId] or {}
end

function BCORE:GetConfigAddonIds()
    local ids = {}
    for addonId in pairs(BCORE.Config.Definitions) do
        ids[#ids + 1] = addonId
    end
    table.sort(ids)
    return ids
end

function BCORE:GetConfig(addonId, key, fallback)
    local addon = BCORE.Config.Values[addonId]
    local value = addon and addon[key]

    if value == nil then
        local def = BCORE:GetConfigDefinition(addonId, key)
        if def then
            return CopyConfigValue(def.default)
        end
        return fallback
    end

    return value
end
