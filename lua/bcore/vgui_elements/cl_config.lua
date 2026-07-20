-- The real in-game config panel. Every addon's settings, registered via BCORE:RegisterConfig,
-- show up here automatically - nothing here is aware of any specific addon.
BCORE.ConfigUI = BCORE.ConfigUI or {}

local COL_BG_SHELL = Color(30, 30, 33)
local COL_TEXT = Color(255, 255, 255)
local COL_TEXT_DIM = Color(170, 170, 175)
local COL_INPUT_BG = Color(22, 22, 24)
local COL_BTN_NEUTRAL = Color(50, 50, 55)
local COL_BTN_GOOD = Color(0, 130, 0)
local COL_BTN_BAD = Color(90, 30, 30)

local function StyleTextEntry(entry)
    entry:ReadyTextbox()
    entry:SetFont("BCORE.config.16")
    entry:SetTextColor(COL_TEXT)
    entry:SetCursorColor(COL_TEXT)
    entry:BUi():Background(COL_INPUT_BG, 4)
end

local function StyleButton(btn, bg, hover)
    btn:SetFont("BCORE.configb.16")
    btn:SetTextColor(COL_TEXT)
    btn:ClearPaint()
    btn:BUi():Background(bg, 4)
    btn:FadeHover(hover or Color(255, 255, 255, 20), 4, 4)
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
    shell:SetTall(hasDesc and 60 or 44)
    shell:ClearPaint():Background(COL_BG_SHELL, 6)
    shell:DockPadding(12, 7, 12, 7)

    local top = BUi.Create("DPanel", shell)
    top:Dock(TOP)
    top:SetTall(26)
    top:ClearPaint()

    local label = BUi.Create("DLabel", top)
    label:Dock(LEFT)
    label:SetWide(260)
    label:SetFont("BCORE.configb.16")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or "")

    local controlHolder = BUi.Create("DPanel", top)
    controlHolder:Dock(FILL)
    controlHolder:ClearPaint()

    if hasDesc then
        local desc = BUi.Create("DLabel", shell)
        desc:Dock(TOP)
        desc:SetTall(20)
        desc:SetFont("BCORE.config.12")
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
    chk:SetWide(22)
    chk:SetChecked(BCORE:GetConfig(addonId, key) and true or false)
    chk:BUi():SquareCheckbox(Color(0, 200, 0), Color(255, 255, 255))
    chk.OnChange = function(_, val)
        BCORE:RequestSetConfig(addonId, key, val and true or false)
    end
end

local function BuildNumberRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local entry = vgui.Create("DTextEntry", holder)
    entry:Dock(RIGHT)
    entry:SetWide(120)
    entry:SetNumeric(true)
    entry:SetText(tostring(BCORE:GetConfig(addonId, key) or 0))
    StyleTextEntry(entry)

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

    local entry = vgui.Create("DTextEntry", holder)
    entry:Dock(RIGHT)
    entry:SetWide(260)
    entry:SetText(tostring(BCORE:GetConfig(addonId, key) or ""))
    StyleTextEntry(entry)

    local function Commit()
        BCORE:RequestSetConfig(addonId, key, entry:GetText())
    end

    entry.OnEnter = Commit
    entry.OnLoseFocus = Commit
end

local function BuildChoiceRow(parent, addonId, key, def)
    local holder = CreateScalarShell(parent, def)

    local combo = CreateComboFor(holder, RIGHT, 220)
    for _, c in ipairs(def.choices or {}) do
        combo:AddChoice(tostring(c), c)
    end

    local current = BCORE:GetConfig(addonId, key)
    combo:SetSelected(tostring(current or ""), current)
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
    shell:ClearPaint():Background(COL_BG_SHELL, 6)

    local label = BUi.Create("DLabel", shell)
    label:Dock(TOP)
    label:DockMargin(12, 8, 12, 0)
    label:SetTall(20)
    label:SetFont("BCORE.configb.18")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or key)

    if hasDesc then
        local desc = BUi.Create("DLabel", shell)
        desc:Dock(TOP)
        desc:DockMargin(12, 0, 12, 2)
        desc:SetTall(18)
        desc:SetFont("BCORE.config.12")
        desc:SetTextColor(COL_TEXT_DIM)
        desc:SetText(def.description)
        desc:SetWrap(true)
    end

    local itemsHolder = BUi.Create("DPanel", shell)
    itemsHolder:Dock(TOP)
    itemsHolder:DockMargin(12, 4, 12, 4)
    itemsHolder:ClearPaint()

    local working = {}
    for _, v in ipairs(BCORE:GetConfig(addonId, key) or {}) do
        working[#working + 1] = tostring(v)
    end

    local function Resize()
        itemsHolder:SetTall(#working * 30)
        shell:SetTall(28 + (hasDesc and 20 or 0) + #working * 30 + 44 + 6)
    end

    local RebuildItems

    RebuildItems = function()
        itemsHolder:Clear()

        for i, val in ipairs(working) do
            local row = BUi.Create("DPanel", itemsHolder)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 0, 0, 2)
            row:ClearPaint()

            local entry = vgui.Create("DTextEntry", row)
            entry:Dock(FILL)
            entry:DockMargin(0, 0, 4, 0)
            entry:SetText(val)
            StyleTextEntry(entry)
            entry.OnValueChange = function(_, v)
                working[i] = v
            end

            local remove = vgui.Create("DButton", row)
            remove:Dock(RIGHT)
            remove:SetWide(28)
            remove:SetText("X")
            StyleButton(remove, COL_BTN_BAD, Color(255, 0, 0, 40))
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
    buttons:DockMargin(12, 4, 12, 8)
    buttons:SetTall(30)
    buttons:ClearPaint()

    local add = vgui.Create("DButton", buttons)
    add:Dock(LEFT)
    add:SetWide(90)
    add:SetText("+ Add")
    StyleButton(add, COL_BTN_NEUTRAL)
    add.DoClick = function()
        table.insert(working, "")
        RebuildItems()
    end

    local save = vgui.Create("DButton", buttons)
    save:Dock(RIGHT)
    save:SetWide(90)
    save:SetText("Save")
    StyleButton(save, COL_BTN_GOOD, Color(0, 255, 0, 40))
    save.DoClick = function()
        local clean = {}
        for _, v in ipairs(working) do
            if v ~= "" then clean[#clean + 1] = v end
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
    shell:SetTall(30 + rows * 50 + 10)
    shell:ClearPaint():Background(COL_BG_SHELL, 6)

    local label = BUi.Create("DLabel", shell)
    label:Dock(TOP)
    label:DockMargin(12, 8, 12, 0)
    label:SetTall(20)
    label:SetFont("BCORE.configb.18")
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
            rowPanel:DockMargin(12, 6, 12, 0)
            rowPanel:SetTall(44)
            rowPanel:ClearPaint()
        end

        local cell = BUi.Create("DPanel", rowPanel)
        cell:Dock(LEFT)
        cell:SetWide(150)
        cell:DockMargin(0, 0, 10, 0)
        cell:ClearPaint()

        local swatchLabel = BUi.Create("DLabel", cell)
        swatchLabel:Dock(TOP)
        swatchLabel:SetTall(16)
        swatchLabel:SetFont("BCORE.config.13")
        swatchLabel:SetTextColor(COL_TEXT_DIM)
        swatchLabel:SetText(field.label or field.key)

        local swatch = vgui.Create("BUi.ColorSwatch", cell)
        swatch:Dock(TOP)
        swatch:SetTall(22)
        swatch:SetColor(current[field.key] or Color(255, 255, 255))
        swatch.OnValueConfirmed = function() Commit() end

        swatches[field.key] = swatch
    end
end

--------------------------------------------------------------------------------
-- Records row: array of objects, one expandable card per record, add/remove/save.
--------------------------------------------------------------------------------
local function BuildRecordFieldControl(parent, field, record)
    local wrap = BUi.Create("DPanel", parent)
    wrap:Dock(TOP)
    wrap:DockMargin(0, 0, 0, 4)
    wrap:SetTall(28)
    wrap:ClearPaint()

    local lbl = BUi.Create("DLabel", wrap)
    lbl:Dock(LEFT)
    lbl:SetWide(120)
    lbl:SetFont("BCORE.config.14")
    lbl:SetTextColor(COL_TEXT_DIM)
    lbl:SetText(field.label or field.key)

    if field.type == "bool" then
        local chk = vgui.Create("DCheckBox", wrap)
        chk:Dock(LEFT)
        chk:SetWide(22)
        chk:SetChecked(record[field.key] and true or false)
        chk:BUi():SquareCheckbox(Color(0, 200, 0), Color(255, 255, 255))
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
        combo:SetSelected(tostring(record[field.key] or ""), record[field.key])
        combo.OnSelect = function(_, _, data)
            record[field.key] = data
        end

    else -- "string" or "number"
        local entry = vgui.Create("DTextEntry", wrap)
        entry:Dock(FILL)
        if field.type == "number" then entry:SetNumeric(true) end
        entry:SetText(tostring(record[field.key] or ""))
        StyleTextEntry(entry)
        entry.OnValueChange = function(_, v)
            record[field.key] = (field.type == "number") and (tonumber(v) or record[field.key]) or v
        end
    end
end

local function BuildRecordsRow(parent, addonId, key, def)
    local hasDesc = def.description ~= nil and def.description ~= ""
    local fields = def.fields or {}
    local cardHeight = #fields * 34 + 46

    local shell = BUi.Create("DPanel", parent)
    shell:Dock(TOP)
    shell:DockMargin(10, 6, 10, 0)
    shell:ClearPaint():Background(COL_BG_SHELL, 6)

    local label = BUi.Create("DLabel", shell)
    label:Dock(TOP)
    label:DockMargin(12, 8, 12, 0)
    label:SetTall(20)
    label:SetFont("BCORE.configb.18")
    label:SetTextColor(COL_TEXT)
    label:SetText(def.label or key)

    if hasDesc then
        local desc = BUi.Create("DLabel", shell)
        desc:Dock(TOP)
        desc:DockMargin(12, 0, 12, 2)
        desc:SetTall(18)
        desc:SetFont("BCORE.config.12")
        desc:SetTextColor(COL_TEXT_DIM)
        desc:SetText(def.description)
        desc:SetWrap(true)
    end

    local cardsHolder = BUi.Create("DPanel", shell)
    cardsHolder:Dock(TOP)
    cardsHolder:DockMargin(12, 4, 12, 4)
    cardsHolder:ClearPaint()

    local working = {}
    for _, rec in ipairs(BCORE:GetConfig(addonId, key) or {}) do
        local copy = {}
        for _, field in ipairs(fields) do
            copy[field.key] = rec[field.key]
        end
        working[#working + 1] = copy
    end

    local function Resize()
        cardsHolder:SetTall(#working * (cardHeight + 6))
        shell:SetTall(28 + (hasDesc and 20 or 0) + #working * (cardHeight + 6) + 44 + 6)
    end

    local RebuildCards

    RebuildCards = function()
        cardsHolder:Clear()

        for i, record in ipairs(working) do
            local card = BUi.Create("DPanel", cardsHolder)
            card:Dock(TOP)
            card:SetTall(cardHeight)
            card:DockMargin(0, 0, 0, 6)
            card:ClearPaint():Background(COL_INPUT_BG, 4)
            card:DockPadding(8, 6, 8, 6)

            for _, field in ipairs(fields) do
                BuildRecordFieldControl(card, field, record)
            end

            local removeBtn = vgui.Create("DButton", card)
            removeBtn:Dock(TOP)
            removeBtn:DockMargin(0, 2, 0, 0)
            removeBtn:SetTall(24)
            removeBtn:SetText("Remove Entry")
            StyleButton(removeBtn, COL_BTN_BAD, Color(255, 0, 0, 40))
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
    buttons:DockMargin(12, 4, 12, 8)
    buttons:SetTall(30)
    buttons:ClearPaint()

    local add = vgui.Create("DButton", buttons)
    add:Dock(LEFT)
    add:SetWide(120)
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
    save:SetWide(90)
    save:SetText("Save")
    StyleButton(save, COL_BTN_GOOD, Color(0, 255, 0, 40))
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
    self.Nav = BUi.Create("BUi.Scroll", self)
    self.Nav:Dock(LEFT)
    self.Nav:SetWide(230)
    self.Nav:DockMargin(0, 0, 8, 0)

    self.Content = BUi.Create("BUi.Scroll", self)
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
            local header = BUi.Create("DLabel", self.Nav)
            header:Dock(TOP)
            header:DockMargin(8, 12, 8, 2)
            header:SetTall(20)
            header:SetFont("BCORE.configb.14")
            header:SetTextColor(Color(140, 140, 150))
            header:SetText(string.upper(addonId))

            for _, cat in ipairs(categories) do
                if not firstAddon then firstAddon, firstCategory = addonId, cat end

                local isSelected = self.Selected and self.Selected.addonId == addonId and self.Selected.category == cat

                local btn = vgui.Create("DButton", self.Nav)
                btn:Dock(TOP)
                btn:DockMargin(6, 2, 6, 0)
                btn:SetTall(32)
                btn:SetText(cat)
                StyleButton(btn, isSelected and Color(70, 70, 140) or Color(38, 38, 42), Color(255, 255, 255, 20))

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

    local frame = BUi.Create("DPanel", nil)
    frame:SetSize(math.max(900, ScrW() * 0.6), math.max(600, ScrH() * 0.7))
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame:ClearPaint():Background(Color(24, 24, 26), 8)

    local header = BUi.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(50)
    header:ClearPaint():Background(Color(32, 32, 34), 8)

    local title = BUi.Create("DLabel", header)
    title:Dock(LEFT)
    title:DockMargin(15, 0, 0, 0)
    title:SetWide(400)
    title:SetFont("BCORE.configb.24")
    title:SetTextColor(Color(255, 255, 255))
    title:SetText("Server Configuration")

    local closeBtn = vgui.Create("DButton", header)
    closeBtn:Dock(RIGHT)
    closeBtn:DockMargin(0, 8, 8, 8)
    closeBtn:SetWide(34)
    closeBtn:SetText("X")
    StyleButton(closeBtn, Color(61, 61, 61), Color(100, 0, 0, 90))
    closeBtn.DoClick = function()
        if IsValid(frame) then frame:Remove() end
    end

    local body = BUi.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(10, 10, 10, 10)
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
