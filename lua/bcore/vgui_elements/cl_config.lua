-- The real in-game config panel. Every addon's settings, registered via BCORE:RegisterConfig,
-- show up here automatically - nothing here is aware of any specific addon.
BCORE.ConfigUI = BCORE.ConfigUI or {}

-- Third visual pass. The first (see git history) fixed raw contrast; the second borrowed the
-- SHAPE of the real house style (masked gradient wash, accent stripe) but invented its own
-- palette (Color(130,136,255), unrelated to anything else in this codebase) and its own hover
-- mechanism (an RGB-channel color lerp that matches nothing else here either) - exactly the
-- "not the shitty ones you've been doing" complaint. This pass drops both inventions: colors now
-- come from BCORE.F4.colors (the real, already-established accent - Color(194,55,9) - used
-- verbatim across F4/Unbox/Inventory), and the shell/button chrome itself is now built on the
-- shared BUi:PaintCardShell/BUi:StyleTabButton helpers (beep-framework's own
-- libs/ui/cl_bui_shell.lua) instead of a third bespoke local implementation - the same shared
-- components beep_unboxing's own rework now also draws from, so this panel and every Unbox page
-- are finally drawing from ONE real recipe instead of three separate ones.
local function F4Colors()
    local c = BCORE.F4 and BCORE.F4.colors
    return {
        background    = (c and c.background)    or Color(28, 28, 28),
        surface       = (c and c.surface)        or Color(35, 34, 38),
        surfaceRaised = (c and c.surfaceRaised)  or Color(40, 39, 44),
        border        = (c and c.border)         or Color(55, 54, 60),
        textMuted     = (c and c.textMuted)      or Color(202, 202, 202),
        highlight     = (c and c.highlight)      or Color(194, 55, 9),
        highlightAlt  = (c and c.highlightAlt)   or Color(255, 78, 217),
    }
end

local COL_PANEL_BG    = F4Colors().background
local COL_BG_SHELL        = F4Colors().surface  -- header/outer-frame inner fill
local COL_BG_SHELL_BORDER = F4Colors().border   -- outer frame's own border color
local COL_NAV_BG      = Color(26, 26, 30)   -- sidebar's own slightly-lifted backdrop
local COL_TEXT        = Color(255, 255, 255)
local COL_TEXT_DIM    = F4Colors().textMuted
local COL_TEXT_FAINT  = Color(120, 120, 132)
local COL_INPUT_BG    = Color(22, 22, 26)
local COL_BTN_NEUTRAL = Color(54, 54, 64)
local COL_BTN_GOOD    = Color(40, 130, 68)
local COL_BTN_BAD     = Color(150, 52, 52)
-- Alias kept for every call site below that still refers to "the accent color" - now the real
-- one instead of an invented one.
local COL_ACCENT = F4Colors().highlight

-- Every shell (scalar rows and the list/colors/records shells) calls this - a thin wrapper over
-- the shared BUi:PaintCardShell with an accent stripe, matching this panel's own original shape
-- but with the real palette/recipe underneath it now.
local function PaintShell(pnl, w, h)
    BUi:PaintCardShell(w, h, { accentStripe = true })
end

-- BUi's ClearPaint/Background/FadeHover/ReadyTextbox etc. are all installed onto a panel
-- INSTANCE the first time :BUi() is called on it (BUi.Create does this automatically; a plain
-- vgui.Create(...) panel doesn't have any of them yet). StyleButton calls :BUi() first so it
-- works regardless of which one the caller used - calling :BUi() again on an already-BUi'd
-- panel is harmless, it just re-installs the same methods.
--
-- Text entries don't follow that same "call :Background() on the entry itself" pattern -
-- every other text box in this codebase (e.g. beep-f4's search bar) gives the DTextEntry its
-- OWN plain holder panel that owns the background paint, and docks the entry FILL inside it
-- with no paint override of its own. CreateStyledTextEntry below matches that: it returns the
-- HOLDER (which the caller docks/sizes/positions) and the entry itself (which the caller sets
-- text/value on) as two separate panels, rather than trying to style one panel as both.
local function CreateStyledTextEntry(parent)
    local holder = BUi.Create("DPanel", parent)
    holder:ClearPaint():Background(COL_INPUT_BG, 5)

    local entry = vgui.Create("DTextEntry", holder)
    entry:Dock(FILL)
    entry:DockMargin(8, 0, 8, 0)
    entry:BUi()
    entry:SetPaintBackground(false)
    entry:ReadyTextbox()
    -- Bumped from 16 - the user's own "the text is way too small, i can barely read anything"
    -- feedback, applied across this whole panel (every font size below got a matching bump, plus
    -- the row/shell heights that size text against, so nothing clips).
    entry:SetFont("BCORE.config.19")
    entry:SetTextColor(COL_TEXT)
    entry:SetCursorColor(COL_TEXT)

    return holder, entry
end

-- Was an RGB-channel color lerp on hover - a mechanism that doesn't exist anywhere else in this
-- codebase (confirmed: F4's own sidebar tabs, Unbox's buttons all use a flat FadeHover overlay
-- instead). Fixed to use that same real, established FadeHover pattern.
local function StyleButton(btn, bg, hoverAlpha)
    btn:BUi()
    btn:SetFont("BCORE.configb.18")
    btn:SetTextColor(COL_TEXT)
    btn:ClearPaint()
    btn:On("Paint", function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, bg)
        surface.SetDrawColor(255, 255, 255, 18)
        surface.DrawRect(1, 1, w - 2, 1)
    end)
    btn:FadeHover(ColorAlpha(color_white, hoverAlpha or 30), 6, 6)
end

-- Small icon-only buttons (a list/record row's own "remove this entry") use the SAME door-icon
-- visual language every real exit/close button in this codebase already uses (F4, the Unbox
-- frame, the socket menu, this panel's own header/nav), including the identical red hover glow -
-- not a bespoke bare "X" glyph, which was the whole reason this needed a second pass.
local function StyleIconButton(btn, iconURL)
    iconURL = iconURL or "https://invisibalfan-ui.github.io/bui_images/images/0cjxwbc.png"
    btn:BUi():ClearPaint():Background(Color(56, 56, 64, 200), 5):FadeIn(0.3):On("Paint", function(s, w, h)
        draw.RoundedBox(5, 1, 1, w - 2, h - 2, COL_ACCENT)
        BUi.DrawImgur(0, 0, w, h, iconURL, color_white)
    end):FadeHover(Color(100, 0, 0, 90), 6, 8)
end

-- Nav sidebar tabs - now a thin wrapper over the shared BUi:StyleTabButton (the real,
-- established F4 CreateButton recipe: two-tone border/surface unselected, rotating dual-gradient
-- + click-flash selected) instead of the flat solid-fill pill this used to invent. isSelected is
-- static per call (this panel fully rebuilds its whole nav list on every selection change - see
-- PANEL:Rebuild below - so a fixed boolean decided at creation time is exactly right here).
local function StyleNavButton(btn, isSelected)
    btn:SetFont(isSelected and "BCORE.configb.18" or "BCORE.configs.18")
    btn:SetTextColor(isSelected and COL_TEXT or COL_TEXT_DIM)
    btn:SetContentAlignment(4)
    btn:SetTextInset(14, 0)
    BUi:StyleTabButton(btn, function() return isSelected end, { radius = 7 })
end

-- BUi.Combo bakes a Dock(LEFT)+104px margin into its own Init (meant for one specific
-- original layout) - always reset both after creating one anywhere else.
local function CreateComboFor(parent, dock, wide)
    local combo = BUi.Create("BUi.Combo", parent)
    combo:Dock(dock)
    combo:DockMargin(0, 0, 0, 0)
    if wide then combo:SetWide(wide) end
    return combo
end

--------------------------------------------------------------------------------
-- Scalar row shell: label on the left, control on the right, optional description below.
--------------------------------------------------------------------------------
local function CreateScalarShell(parent, def)
    local hasDesc = def.description ~= nil and def.description ~= ""

    local shell = BUi.Create("DPanel", parent)
    shell:Dock(TOP)
    shell:DockMargin(10, 6, 10, 0)
    shell:SetTall(hasDesc and 74 or 54)
    shell:SetPaintBackground(false)
    shell:On("Paint", PaintShell)
    shell:DockPadding(16, 8, 14, 8)

    local top = BUi.Create("DPanel", shell)
    top:Dock(TOP)
    top:SetTall(34)
    top:ClearPaint()

    local label = BUi.Create("DLabel", top)
    label:Dock(LEFT)
    label:SetWide(280)
    label:SetFont("BCORE.configb.19")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or "")
    label:SetContentAlignment(4)

    local controlHolder = BUi.Create("DPanel", top)
    controlHolder:Dock(FILL)
    controlHolder:ClearPaint()

    if hasDesc then
        local desc = BUi.Create("DLabel", shell)
        desc:Dock(TOP)
        desc:DockMargin(0, 2, 0, 0)
        desc:SetTall(26)
        desc:SetFont("BCORE.config.15")
        desc:SetTextColor(COL_TEXT_DIM)
        desc:SetText(def.description)
        desc:SetWrap(true)
    end

    return controlHolder
end

local function BuildBoolRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local chk = vgui.Create("DCheckBox", holder)
    chk:Dock(RIGHT)
    chk:SetWide(26)
    chk:DockMargin(0, 2, 0, 2)
    chk:SetChecked(BCORE:GetConfig(addonId, key) and true or false)
    chk:BUi():SquareCheckbox(COL_ACCENT, Color(255, 255, 255))
    chk.OnChange = function(_, val)
        BCORE:RequestSetConfig(addonId, key, val and true or false)
    end
end

local function BuildNumberRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local entryHolder, entry = CreateStyledTextEntry(holder)
    entryHolder:Dock(RIGHT)
    entryHolder:SetWide(140)
    entry:SetNumeric(true)
    entry:SetText(tostring(BCORE:GetConfig(addonId, key) or 0))

    local function Commit()
        local n = tonumber(entry:GetText())
        if n then
            BCORE:RequestSetConfig(addonId, key, n)
        else
            entry:SetText(tostring(BCORE:GetConfig(addonId, key) or 0))
        end
    end

    entry.OnEnter = Commit
    entry.OnLoseFocus = Commit
end

local function BuildStringRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local entryHolder, entry = CreateStyledTextEntry(holder)
    entryHolder:Dock(RIGHT)
    entryHolder:SetWide(260)
    entry:SetText(tostring(BCORE:GetConfig(addonId, key) or ""))

    local function Commit()
        BCORE:RequestSetConfig(addonId, key, entry:GetText())
    end

    entry.OnEnter = Commit
    entry.OnLoseFocus = Commit
end

local function BuildChoiceRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local combo = CreateComboFor(holder, RIGHT, 240)
    for _, c in ipairs(def.choices or {}) do
        combo:AddChoice(tostring(c), c)
    end

    local current = BCORE:GetConfig(addonId, key)
    combo:SetComboValue(tostring(current or ""), current)
    combo.OnSelect = function(_, _, data)
        BCORE:RequestSetConfig(addonId, key, data)
    end
end

local function BuildColorRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local swatch = vgui.Create("BUi.ColorSwatch", holder)
    swatch:Dock(RIGHT)
    swatch:SetWide(60)
    swatch:SetColor(BCORE:GetConfig(addonId, key) or Color(255, 255, 255))
    swatch.OnValueConfirmed = function(_, col)
        BCORE:RequestSetConfig(addonId, key, col)
    end
end

--------------------------------------------------------------------------------
-- List row: array of strings/numbers, editable rows + add/remove/save.
--------------------------------------------------------------------------------
local function BuildListRow(parent, addonId, key, def)
    local hasDesc = def.description ~= nil and def.description ~= ""

    local shell = BUi.Create("DPanel", parent)
    shell:Dock(TOP)
    shell:DockMargin(10, 6, 10, 0)
    shell:SetPaintBackground(false)
    shell:On("Paint", PaintShell)
    shell:DockPadding(16, 10, 14, 10)

    local label = BUi.Create("DLabel", shell)
    label:Dock(TOP)
    label:SetTall(24)
    label:SetFont("BCORE.configb.21")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or key)

    if hasDesc then
        local desc = BUi.Create("DLabel", shell)
        desc:Dock(TOP)
        desc:DockMargin(0, 2, 0, 0)
        desc:SetTall(24)
        desc:SetFont("BCORE.config.15")
        desc:SetTextColor(COL_TEXT_DIM)
        desc:SetText(def.description)
        desc:SetWrap(true)
    end

    local itemsHolder = BUi.Create("DPanel", shell)
    itemsHolder:Dock(TOP)
    itemsHolder:DockMargin(0, 8, 0, 4)
    itemsHolder:ClearPaint()

    -- Trimmed and blank entries dropped here too, not just on Save - a whitespace-only entry
    -- (e.g. an accidental space typed into a fresh "+ Add" row) used to pass the old
    -- `v ~= ""` filter and get saved as a real, invisible-but-present list entry: a row with
    -- no visible text but a very visible remove button next to it, which is exactly the kind
    -- of "floating, unexplained element" this whole pass is fixing.
    local working = {}
    for _, v in ipairs(BCORE:GetConfig(addonId, key) or {}) do
        local s = string.Trim(tostring(v))
        if s ~= "" then working[#working + 1] = s end
    end

    local emptyLabel

    -- Matches shell's own DockPadding(16, 10, 14, 10) + each child's real height/margins
    -- exactly, rather than an approximate magic number - top padding(10) + label(24) +
    -- desc(24, only if present) + itemsHolder's own top/bottom margin(8+4) + itemsTall +
    -- buttons(34) + bottom padding(10).
    local function Resize()
        local itemsTall = #working > 0 and (#working * 36) or 30
        itemsHolder:SetTall(itemsTall)
        shell:SetTall(10 + 24 + (hasDesc and 24 or 0) + 8 + itemsTall + 4 + 34 + 10)
    end

    local RebuildItems

    RebuildItems = function()
        itemsHolder:Clear()

        if #working == 0 then
            emptyLabel = BUi.Create("DLabel", itemsHolder)
            emptyLabel:Dock(TOP)
            emptyLabel:SetTall(30)
            emptyLabel:SetFont("BCORE.config.16")
            emptyLabel:SetTextColor(COL_TEXT_DIM)
            emptyLabel:SetText("No entries yet - click + Add to create one.")
        end

        for i, val in ipairs(working) do
            local row = BUi.Create("DPanel", itemsHolder)
            row:Dock(TOP)
            row:SetTall(34)
            row:DockMargin(0, 0, 0, 2)
            row:ClearPaint()

            local entryHolder, entry = CreateStyledTextEntry(row)
            entryHolder:Dock(FILL)
            entryHolder:DockMargin(0, 0, 6, 0)
            entry:SetText(val)
            entry.OnValueChange = function(_, v)
                working[i] = v
            end

            local remove = vgui.Create("DButton", row)
            remove:Dock(RIGHT)
            remove:SetWide(28)
            remove:SetText("")
            StyleIconButton(remove)
            remove.DoClick = function()
                table.remove(working, i)
                RebuildItems()
            end
        end

        Resize()
    end

    RebuildItems()

    local buttons = BUi.Create("DPanel", shell)
    buttons:Dock(TOP)
    buttons:DockMargin(0, 0, 0, 0)
    buttons:SetTall(34)
    buttons:ClearPaint()

    local add = vgui.Create("DButton", buttons)
    add:Dock(LEFT)
    add:SetWide(100)
    add:SetText("+ Add")
    StyleButton(add, COL_BTN_NEUTRAL)
    add.DoClick = function()
        table.insert(working, "")
        RebuildItems()
    end

    local save = vgui.Create("DButton", buttons)
    save:Dock(RIGHT)
    save:SetWide(100)
    save:SetText("Save")
    StyleButton(save, COL_BTN_GOOD)
    save.DoClick = function()
        local clean = {}
        for _, v in ipairs(working) do
            local s = string.Trim(v)
            if s ~= "" then clean[#clean + 1] = s end
        end
        BCORE:RequestSetConfig(addonId, key, clean)
    end
end

--------------------------------------------------------------------------------
-- Colors row: named map of Color values, rendered as a grid of swatches.
--------------------------------------------------------------------------------
local function BuildColorsRow(parent, addonId, key, def)
    local fieldsList = def.fields or {}
    local perRow = 3
    local rows = math.max(1, math.ceil(#fieldsList / perRow))

    local shell = BUi.Create("DPanel", parent)
    shell:Dock(TOP)
    shell:DockMargin(10, 6, 10, 0)
    shell:SetTall(10 + 24 + rows * 58 + 10)
    shell:SetPaintBackground(false)
    shell:On("Paint", PaintShell)
    shell:DockPadding(16, 10, 14, 10)

    local label = BUi.Create("DLabel", shell)
    label:Dock(TOP)
    label:SetTall(24)
    label:SetFont("BCORE.configb.21")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or key)

    local current = BCORE:GetConfig(addonId, key) or {}
    local swatches = {}

    local function Commit()
        local full = {}
        for k, sw in pairs(swatches) do
            if IsValid(sw) then full[k] = sw:GetColor() end
        end
        BCORE:RequestSetConfig(addonId, key, full)
    end

    local rowPanel
    for i, field in ipairs(fieldsList) do
        if (i - 1) % perRow == 0 then
            rowPanel = BUi.Create("DPanel", shell)
            rowPanel:Dock(TOP)
            rowPanel:DockMargin(0, 6, 0, 0)
            rowPanel:SetTall(52)
            rowPanel:ClearPaint()
        end

        local cell = BUi.Create("DPanel", rowPanel)
        cell:Dock(LEFT)
        cell:SetWide(160)
        cell:DockMargin(0, 0, 10, 0)
        cell:ClearPaint()

        local swatchLabel = BUi.Create("DLabel", cell)
        swatchLabel:Dock(TOP)
        swatchLabel:SetTall(20)
        swatchLabel:SetFont("BCORE.config.16")
        swatchLabel:SetTextColor(COL_TEXT_DIM)
        swatchLabel:SetText(field.label or field.key)

        local swatch = vgui.Create("BUi.ColorSwatch", cell)
        swatch:Dock(TOP)
        swatch:SetTall(26)
        swatch:SetColor(current[field.key] or Color(255, 255, 255))
        swatch.OnValueConfirmed = function() Commit() end

        swatches[field.key] = swatch
    end
end

--------------------------------------------------------------------------------
-- Records row: array of objects, one expandable card per record, add/remove/save.
--------------------------------------------------------------------------------
-- A "code" field is a full multi-line Lua snippet (an ability's Action body, a suit's OnHit
-- logic, ...) - the same "admin writes real Lua, compiled + pcall'd at use-time" pattern
-- beep_unboxing's own item/type OnUseCode editor already established, just surfaced through
-- BCORE.Config's generic records UI instead of a bespoke admin panel, so any addon's config can
-- offer one without building its own editor widget. Needs real vertical room a normal 28px
-- field row can't give it - RecordFieldHeight/BuildRecordsRow's own cardHeight math both key off
-- this same constant so the card never clips it.
local CODE_FIELD_HEIGHT = 170

local function RecordFieldHeight(field)
    return field.type == "code" and CODE_FIELD_HEIGHT or 34
end

local function BuildRecordFieldControl(parent, field, record)
    local wrap = BUi.Create("DPanel", parent)
    wrap:Dock(TOP)
    wrap:DockMargin(0, 0, 0, 4)
    wrap:SetTall(RecordFieldHeight(field))
    wrap:ClearPaint()

    if field.type == "code" then
        local lbl = BUi.Create("DLabel", wrap)
        lbl:Dock(TOP)
        lbl:SetTall(20)
        lbl:SetFont("BCORE.config.15")
        lbl:SetTextColor(COL_TEXT_DIM)
        lbl:SetText((field.label or field.key) .. " (Lua - " .. (field.codeArgsHint or "no locals provided") .. ")")

        local holder, entry = CreateStyledTextEntry(wrap)
        holder:Dock(FILL)
        holder:DockMargin(0, 4, 0, 0)
        entry:SetMultiline(true)
        entry:SetFont("BCORE.config.16")
        entry:SetText(tostring(record[field.key] or ""))
        entry.OnValueChange = function(_, v)
            record[field.key] = v
        end
        return
    end

    local lbl = BUi.Create("DLabel", wrap)
    lbl:Dock(LEFT)
    lbl:SetWide(140)
    lbl:SetFont("BCORE.config.17")
    lbl:SetTextColor(COL_TEXT_DIM)
    lbl:SetText(field.label or field.key)

    if field.type == "bool" then
        local chk = vgui.Create("DCheckBox", wrap)
        chk:Dock(LEFT)
        chk:SetWide(22)
        chk:SetChecked(record[field.key] and true or false)
        chk:BUi():SquareCheckbox(COL_ACCENT, Color(255, 255, 255))
        chk.OnChange = function(_, v)
            record[field.key] = v
        end

    elseif field.type == "color" then
        local swatch = vgui.Create("BUi.ColorSwatch", wrap)
        swatch:Dock(LEFT)
        swatch:SetWide(60)
        swatch:SetColor(record[field.key] or Color(255, 255, 255))
        swatch.OnValueConfirmed = function(_, col)
            record[field.key] = col
        end

    elseif field.type == "choice" then
        local combo = CreateComboFor(wrap, FILL)
        for _, c in ipairs(field.choices or {}) do
            combo:AddChoice(tostring(c), c)
        end
        combo:SetComboValue(tostring(record[field.key] or ""), record[field.key])
        combo.OnSelect = function(_, _, data)
            record[field.key] = data
        end

    else -- "string" or "number"
        local entryHolder, entry = CreateStyledTextEntry(wrap)
        entryHolder:Dock(FILL)
        if field.type == "number" then entry:SetNumeric(true) end
        entry:SetText(tostring(record[field.key] or ""))

        -- Real, reproduced bug: OnValueChange alone (the only handler this used to have) is NOT
        -- a reliable place to commit a record field - unlike BuildNumberRow's own TOP-LEVEL
        -- scalar number field (just above in this same file), which has always committed on
        -- OnEnter/OnLoseFocus instead, this one only ever wrote into `record[field.key]` as
        -- individual keystrokes fired OnValueChange. A user who edits a Records number field
        -- (e.g. a Rarity's own Sockets count) and clicks Save WITHOUT the entry ever losing
        -- focus/firing Enter first could see the click register before the last keystroke's
        -- OnValueChange had actually landed, so Save sent the field's OLD value - "I changed it
        -- and pressed Save, but it didn't change." Committing on EVERY path (typing, Enter, and
        -- losing focus by clicking Save itself) removes that race entirely.
        local function Commit()
            local v = entry:GetValue()
            record[field.key] = (field.type == "number") and (tonumber(v) or record[field.key]) or v
        end
        entry.OnValueChange = Commit
        entry.OnEnter = Commit
        entry.OnLoseFocus = Commit
    end
end

local function BuildRecordsRow(parent, addonId, key, def)
    local hasDesc = def.description ~= nil and def.description ~= ""
    local fields = def.fields or {}
    -- Was a flat `#fields * 34` - correct only while every field was the same fixed-height
    -- row. A "code" field (RecordFieldHeight above) is far taller than 34px, so this now sums
    -- each field's own real row height (34 or CODE_FIELD_HEIGHT, both +6 margin) instead of
    -- assuming uniformity - otherwise a card with a code field clipped its own bottom half.
    local cardHeight = 54
    for _, field in ipairs(fields) do
        cardHeight = cardHeight + RecordFieldHeight(field) + 6
    end

    local shell = BUi.Create("DPanel", parent)
    shell:Dock(TOP)
    shell:DockMargin(10, 6, 10, 0)
    shell:SetPaintBackground(false)
    shell:On("Paint", PaintShell)
    shell:DockPadding(16, 10, 14, 10)

    local label = BUi.Create("DLabel", shell)
    label:Dock(TOP)
    label:SetTall(24)
    label:SetFont("BCORE.configb.21")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or key)

    if hasDesc then
        local desc = BUi.Create("DLabel", shell)
        desc:Dock(TOP)
        desc:DockMargin(0, 2, 0, 0)
        desc:SetTall(24)
        desc:SetFont("BCORE.config.15")
        desc:SetTextColor(COL_TEXT_DIM)
        desc:SetText(def.description)
        desc:SetWrap(true)
    end

    local cardsHolder = BUi.Create("DPanel", shell)
    cardsHolder:Dock(TOP)
    cardsHolder:DockMargin(0, 8, 0, 4)
    cardsHolder:ClearPaint()

    local working = {}
    for _, rec in ipairs(BCORE:GetConfig(addonId, key) or {}) do
        local copy = {}
        for _, field in ipairs(fields) do
            copy[field.key] = rec[field.key]
        end
        working[#working + 1] = copy
    end

    -- Matches shell's DockPadding(16, 10, 14, 10) + real child heights, same reasoning as
    -- BuildListRow's own Resize().
    local function Resize()
        local cardsTall = #working > 0 and (#working * (cardHeight + 6)) or 30
        cardsHolder:SetTall(cardsTall)
        shell:SetTall(10 + 24 + (hasDesc and 24 or 0) + 8 + cardsTall + 4 + 34 + 10)
    end

    local RebuildCards

    RebuildCards = function()
        cardsHolder:Clear()

        if #working == 0 then
            local emptyLabel = BUi.Create("DLabel", cardsHolder)
            emptyLabel:Dock(TOP)
            emptyLabel:SetTall(30)
            emptyLabel:SetFont("BCORE.config.16")
            emptyLabel:SetTextColor(COL_TEXT_DIM)
            emptyLabel:SetText("No entries yet - click + Add Entry to create one.")
        end

        for i, record in ipairs(working) do
            local card = BUi.Create("DPanel", cardsHolder)
            card:Dock(TOP)
            card:SetTall(cardHeight)
            card:DockMargin(0, 0, 0, 6)
            card:SetPaintBackground(false)
            card:On("Paint", function(pnl, w, h)
                draw.RoundedBox(6, 0, 0, w, h, COL_INPUT_BG)
            end)
            card:DockPadding(10, 8, 10, 8)

            for _, field in ipairs(fields) do
                BuildRecordFieldControl(card, field, record)
            end

            local removeBtn = vgui.Create("DButton", card)
            removeBtn:Dock(TOP)
            removeBtn:DockMargin(0, 4, 0, 0)
            removeBtn:SetTall(30)
            removeBtn:SetText("Remove Entry")
            StyleButton(removeBtn, COL_BTN_BAD)
            removeBtn.DoClick = function()
                table.remove(working, i)
                RebuildCards()
            end
        end

        Resize()
    end

    RebuildCards()

    local buttons = BUi.Create("DPanel", shell)
    buttons:Dock(TOP)
    buttons:SetTall(34)
    buttons:ClearPaint()

    local add = vgui.Create("DButton", buttons)
    add:Dock(LEFT)
    add:SetWide(140)
    add:SetText("+ Add Entry")
    StyleButton(add, COL_BTN_NEUTRAL)
    add.DoClick = function()
        local blank = {}
        for _, field in ipairs(fields) do
            blank[field.key] = field.default
        end
        table.insert(working, blank)
        RebuildCards()
    end

    local save = vgui.Create("DButton", buttons)
    save:Dock(RIGHT)
    save:SetWide(100)
    save:SetText("Save")
    StyleButton(save, COL_BTN_GOOD)
    save.DoClick = function()
        BCORE:RequestSetConfig(addonId, key, working)
    end
end

--------------------------------------------------------------------------------
-- Dispatcher
--------------------------------------------------------------------------------
local BUILDERS = {
    bool = BuildBoolRow,
    number = BuildNumberRow,
    string = BuildStringRow,
    choice = BuildChoiceRow,
    color = BuildColorRow,
    list = BuildListRow,
    colors = BuildColorsRow,
    records = BuildRecordsRow,
}

function BCORE.ConfigUI.BuildRow(parent, addonId, key, def)
    local builder = BUILDERS[def.type]
    if not builder then return end
    builder(parent, addonId, key, def)
end

--------------------------------------------------------------------------------
-- The embeddable nav+content panel. Works framed (BCORE:OpenConfigMenu) or embedded
-- (e.g. beep-f4's Server Config tab).
--------------------------------------------------------------------------------
local PANEL = {}

function PANEL:Init()
    -- BuildConfigPanel creates this via plain vgui.Create (it needs to be embeddable inside
    -- another addon's own panel tree, e.g. beep-f4's Server Config tab, so it can't assume a
    -- BUi.Create caller) - without this, the panel has no BUi methods and no real background
    -- at all, showing the default DPanel derma skin (plain white) through every gap.
    self:BUi():ClearPaint():Background(COL_PANEL_BG, 8)

    -- Nav gets its own slightly-lifted background (COL_NAV_BG vs the panel's own COL_PANEL_BG)
    -- so the two halves read as genuinely separate regions instead of one undifferentiated slab
    -- with a scrollbar in the middle of it.
    local navHolder = BUi.Create("DPanel", self)
    navHolder:Dock(LEFT)
    navHolder:SetWide(260)
    navHolder:DockMargin(0, 0, 10, 0)
    navHolder:ClearPaint():Background(COL_NAV_BG, 8)

    self.Nav = BUi.Create("BUi.Scroll", navHolder)
    self.Nav:Dock(FILL)
    self.Nav:DockMargin(0, 4, 0, 4)

    self.ContentHolder = BUi.Create("DPanel", self)
    self.ContentHolder:Dock(FILL)
    self.ContentHolder:SetPaintBackground(false)

    self.Header = BUi.Create("DPanel", self.ContentHolder)
    self.Header:Dock(TOP)
    self.Header:SetTall(60)
    self.Header:DockMargin(0, 0, 0, 4)
    self.Header:SetPaintBackground(false)

    self.Content = BUi.Create("BUi.Scroll", self.ContentHolder)
    self.Content:Dock(FILL)

    self.Selected = nil

    self._hookId = "BCORE.Config.UI." .. tostring(self)

    hook.Add("BCORE.Config.Synced", self._hookId, function()
        if not IsValid(self) then hook.Remove("BCORE.Config.Synced", self._hookId) return end
        self:Rebuild()
    end)

    hook.Add("BCORE.Config.ValueChanged", self._hookId, function()
        if not IsValid(self) then hook.Remove("BCORE.Config.ValueChanged", self._hookId) return end
        self:RefreshContent()
    end)

    self:Rebuild()
end

function PANEL:OnRemove()
    hook.Remove("BCORE.Config.Synced", self._hookId)
    hook.Remove("BCORE.Config.ValueChanged", self._hookId)
end

function PANEL:Rebuild()
    if not IsValid(self.Nav) then return end
    self.Nav:Clear()

    local addonIds = BCORE:GetConfigAddonIds()
    local firstAddon, firstCategory

    for _, addonId in ipairs(addonIds) do
        local order = BCORE:GetConfigAddonOrder(addonId)
        local defs = BCORE:GetConfigAddonDefinitions(addonId)

        local categories, seen = {}, {}
        for _, key in ipairs(order) do
            local def = defs[key]
            local cat = (def and def.category) or "General"
            if not seen[cat] then
                seen[cat] = true
                categories[#categories + 1] = cat
            end
        end

        if #categories > 0 then
            local header = BUi.Create("DPanel", self.Nav)
            header:Dock(TOP)
            header:DockMargin(10, 16, 10, 6)
            header:SetTall(20)
            header:SetPaintBackground(false)
            header:On("Paint", function(_, w, h)
                draw.SimpleText(string.upper(addonId), "BCORE.configb.15", 0, h / 2, COL_TEXT_FAINT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.RoundedBox(0, 0, h - 1, w, 1, Color(255, 255, 255, 12))
            end)

            for _, cat in ipairs(categories) do
                if not firstAddon then firstAddon, firstCategory = addonId, cat end

                local isSelected = self.Selected and self.Selected.addonId == addonId and self.Selected.category == cat

                local btn = vgui.Create("DButton", self.Nav)
                btn:Dock(TOP)
                btn:DockMargin(8, 3, 8, 0)
                btn:SetTall(40)
                btn:SetText(cat)
                StyleNavButton(btn, isSelected)

                btn.DoClick = function()
                    self.Selected = { addonId = addonId, category = cat }
                    self:Rebuild()
                end
            end
        end
    end

    if not self.Selected and firstAddon then
        self.Selected = { addonId = firstAddon, category = firstCategory }
    end

    self:RefreshContent()
end

function PANEL:RefreshContent()
    if not IsValid(self.Content) then return end
    self.Content:Clear()

    -- Real, previously-missing context: the content area used to drop straight into a list of
    -- rows with nothing above them saying which addon/category you were even looking at - fine
    -- once you already know the panel, disorienting for anyone glancing at it for the first
    -- time. A plain title + a colored underline, matching this panel's own accent, same idea
    -- every other page/tab header in this codebase already uses.
    if IsValid(self.Header) then
        self.Header:ClearPaint()
        if self.Selected then
            local addonId, category = self.Selected.addonId, self.Selected.category
            self.Header:On("Paint", function(_, w, h)
                draw.SimpleText(category, "BCORE.configb.25", 4, h * 0.32, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(string.upper(addonId), "BCORE.configs.14", 4, h * 0.32 + 26, COL_TEXT_FAINT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.RoundedBox(0, 4, h - 1, math.min(w - 8, 46), 2, COL_ACCENT)
            end)
        end
    end

    if not self.Selected then return end

    local addonId, category = self.Selected.addonId, self.Selected.category
    local order = BCORE:GetConfigAddonOrder(addonId)
    local defs = BCORE:GetConfigAddonDefinitions(addonId)

    for _, key in ipairs(order) do
        local def = defs[key]
        if def and (def.category or "General") == category then
            BCORE.ConfigUI.BuildRow(self.Content, addonId, key, def)
        end
    end
end

vgui.Register("BCORE.ConfigPanel", PANEL, "DPanel")

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
function BCORE:BuildConfigPanel(parent)
    local pnl = vgui.Create("BCORE.ConfigPanel", parent)
    pnl:Dock(FILL)
    return pnl
end

function BCORE:OpenConfigMenu()
    if IsValid(BCORE.ConfigUI.OpenFrame) then
        BCORE.ConfigUI.OpenFrame:Remove()
        BCORE.ConfigUI.OpenFrame = nil
        return
    end

    local frame = BUi.Create("EditablePanel", nil)
    frame:SetSize(math.max(900, ScrW() * 0.6), math.max(600, ScrH() * 0.7))
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame:ClearPaint():Shadow(255):Background(COL_BG_SHELL_BORDER, 12):On("Paint", function(_, w, h)
        draw.RoundedBox(12, 1, 1, w - 2, h - 2, COL_PANEL_BG)
    end)
    frame:DockPadding(10, 10, 10, 10)

    local ox, oy = frame:GetPos()
    frame:SetAlpha(0)
    frame:SetPos(ox, oy + 24)
    frame:AlphaTo(255, 0.2, 0)
    frame:MoveTo(ox, oy, 0.2, 0, -1)

    local header = BUi.Create("DPanel", frame)
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, 10)
    header:SetTall(60)
    header:ClearPaint():Background(COL_NAV_BG, 10):On("Paint", function(_, w, h)
        draw.RoundedBox(10, 1, 1, w - 2, h - 2, COL_BG_SHELL)
        draw.RoundedBox(10, 0, 0, 4, h, COL_ACCENT)
    end)

    local title = BUi.Create("DPanel", header)
    title:Dock(LEFT)
    title:DockMargin(16, 0, 0, 0)
    title:SetWide(420)
    title:SetPaintBackground(false)
    title:On("Paint", function(_, w, h)
        draw.SimpleText("Server Configuration", "BCORE.configb.23", 0, h * 0.36, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Every addon's settings, in one place", "BCORE.configs.14", 0, h * 0.36 + 22, COL_TEXT_FAINT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    local closeBtn = BUi.Create("DButton", header)
    closeBtn:Dock(RIGHT)
    closeBtn:DockMargin(0, 8, 8, 8)
    closeBtn:SetWide(40)
    closeBtn:SetText("")
    closeBtn:BUi():ClearPaint():Background(Color(56, 56, 56, 200), 5):FadeIn(0.5):On("Paint", function(s, w, h)
        draw.RoundedBox(5, 1, 1, w - 2, h - 2, COL_ACCENT)
        BUi.DrawImgur(0, 0, w, h, "https://invisibalfan-ui.github.io/bui_images/images/0cjxwbc.png", color_white)
    end):FadeHover(Color(100, 0, 0, 90), 6, 8)
    closeBtn.DoClick = function()
        if IsValid(frame) then frame:Remove() end
    end

    local body = BUi.Create("DPanel", frame)
    body:Dock(FILL)
    body:ClearPaint()

    BCORE:BuildConfigPanel(body)

    frame.OnRemove = function()
        BCORE.ConfigUI.OpenFrame = nil
    end

    BCORE.ConfigUI.OpenFrame = frame
end

concommand.Add("bcore_config", function()
    if not BCORE:IsConfigAdmin(LocalPlayer()) then
        chat.AddText(Color(255, 80, 80), "[Config] You don't have permission to open the server config.")
        return
    end
    BCORE:OpenConfigMenu()
end)

hook.Add("OnPlayerChat", "BCORE.Config.ChatCommand", function(ply, text)
    if ply ~= LocalPlayer() then return end
    if string.Trim(string.lower(text)) ~= "!config" then return end

    if BCORE:IsConfigAdmin(LocalPlayer()) then
        BCORE:OpenConfigMenu()
    else
        chat.AddText(Color(255, 80, 80), "[Config] You don't have permission to use this command.")
    end

    return true
end)
