-- Pure validation/coercion helpers shared by the server-side setter and the persistence
-- loader. Nothing in this file touches networking or disk, so it has no load-order
-- dependency on anything else in BCORE.

local IsColorValue = BCORE.Config.IsColorValue

local function ReviveColor(raw, fallback)
    if not istable(raw) then return fallback end
    return Color(
        math.Clamp(math.floor(tonumber(raw.r) or 0), 0, 255),
        math.Clamp(math.floor(tonumber(raw.g) or 0), 0, 255),
        math.Clamp(math.floor(tonumber(raw.b) or 0), 0, 255),
        math.Clamp(math.floor(tonumber(raw.a) or 255), 0, 255)
    )
end

local function ClampNumber(raw, def)
    local n = tonumber(raw)
    if not n then return nil end
    if def.min ~= nil then n = math.max(def.min, n) end
    if def.max ~= nil then n = math.min(def.max, n) end
    if def.decimals ~= nil then n = math.Round(n, def.decimals) end
    return n
end

--[[
    Validates/coerces `value` against `def` (a config definition, or a lightweight
    { type=, min=, max=, ... } shape when validating one field of a "records" entry).

    Returns cleaned, err — cleaned is nil only on outright rejection (err explains why).
    A "list"/"colors"/"records" value that's merely malformed drops the bad parts rather than
    rejecting the whole thing outright, matching the rest of this codebase's "skip the
    unsafe part, keep going" discipline instead of failing the whole edit over one bad entry.
]]
function BCORE:ValidateConfigValue(def, value)
    if not def then return nil, "unknown config entry" end

    if def.type == "bool" then
        if type(value) ~= "boolean" then return nil, "expected a true/false value" end
        return value

    elseif def.type == "number" then
        local n = ClampNumber(value, def)
        if not n then return nil, "expected a number" end
        return n

    elseif def.type == "string" then
        if type(value) ~= "string" then return nil, "expected text" end
        if def.maxLength and #value > def.maxLength then
            value = string.sub(value, 1, def.maxLength)
        end
        return value

    -- Real, reproduced bug: this type was never actually handled here at all - it fell through
    -- to the final "unsupported config type" rejection at the bottom of this function. For a
    -- scalar "code" entry that's harmless (SetConfig's own acceptsEmpty check doesn't cover it,
    -- so the whole save is rejected with a visible chat error) - but for a "code" FIELD INSIDE A
    -- RECORD (Suits' OnHitCode, SuitAbilities' Action), the records branch below silently
    -- swallows the nil by falling back to `field.default` (empty string) instead of erroring,
    -- meaning every OnHitCode/Action script an admin wrote was SILENTLY DISCARDED and saved as
    -- blank on every single edit - "I try to save settings and they go unchanged" for anyone
    -- editing a suit/ability's own code field. A code snippet is just free-form text from this
    -- validator's point of view (CompileString/CompileSuitCode do the real syntax checking at
    -- USE time, not here), so it's validated exactly like "string".
    elseif def.type == "code" then
        if type(value) ~= "string" then return nil, "expected text" end
        return value

    elseif def.type == "color" then
        if not IsColorValue(value) then return nil, "expected a color" end
        return ReviveColor(value)

    elseif def.type == "choice" then
        for _, c in ipairs(def.choices or {}) do
            if c == value then return value end
        end
        return nil, "not a valid choice"

    elseif def.type == "list" then
        if not istable(value) then return nil, "expected a list" end
        local out = {}
        for _, v in ipairs(value) do
            if def.itemType == "number" then
                local n = tonumber(v)
                if n then out[#out + 1] = n end
            else
                if type(v) == "string" and v ~= "" then out[#out + 1] = v end
            end
        end
        return out

    elseif def.type == "colors" then
        local out = {}
        if istable(value) then
            for _, field in ipairs(def.fields or {}) do
                local raw = value[field.key]
                if IsColorValue(raw) then
                    out[field.key] = ReviveColor(raw)
                end
            end
        end
        return out

    elseif def.type == "records" then
        if not istable(value) then return nil, "expected a list of entries" end
        local out = {}
        for _, record in ipairs(value) do
            if istable(record) then
                local cleanRecord = {}
                for _, field in ipairs(def.fields or {}) do
                    local fieldDef = {
                        type = field.type, min = field.min, max = field.max,
                        decimals = field.decimals, choices = field.choices, maxLength = field.maxLength,
                    }
                    local cleaned = BCORE:ValidateConfigValue(fieldDef, record[field.key])
                    if cleaned == nil then
                        cleaned = field.default
                    end
                    cleanRecord[field.key] = cleaned
                end
                out[#out + 1] = cleanRecord
            end
        end
        return out
    end

    return nil, "unsupported config type"
end

--[[
    Re-wraps plain {r,g,b,a} tables (the only shape a Color value survives JSON storage or
    pON network transport as) back into real Color() objects. Applied after loading from disk
    and after receiving a synced value - both strip Lua metatables the same way.
]]
function BCORE:ReviveConfigValue(def, raw)
    if raw == nil then return nil end
    if not def then return raw end

    if def.type == "color" then
        return ReviveColor(raw, nil)

    elseif def.type == "colors" then
        local out = {}
        if istable(raw) then
            for _, field in ipairs(def.fields or {}) do
                if raw[field.key] then
                    out[field.key] = ReviveColor(raw[field.key])
                end
            end
        end
        return out

    elseif def.type == "records" then
        local out = {}
        if istable(raw) then
            for _, rec in ipairs(raw) do
                local cleanRec = {}
                for _, field in ipairs(def.fields or {}) do
                    if field.type == "color" then
                        cleanRec[field.key] = ReviveColor(rec[field.key])
                    else
                        cleanRec[field.key] = rec[field.key]
                    end
                end
                out[#out + 1] = cleanRec
            end
        end
        return out
    end

    return raw
end
