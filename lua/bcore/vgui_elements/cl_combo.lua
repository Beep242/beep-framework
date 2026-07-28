local PANEL = {}

function PANEL:Init()
    self:SetTall(30)
    self.Selected = nil
    self.Choices = {}

    -- Was BCORE.config.colors.* - BUi.Combo is a generic, addon-agnostic shared component
    -- (bcore/vgui_elements/), so it can never assume any one addon's own config/colors table
    -- exists at all; a bare top-level BCORE.config has never existed anywhere in this
    -- codebase (every addon keeps its own, e.g. BCORE.Inventory.config, BCORE.F4.colors), so
    -- indexing it always threw the moment this panel type was actually created - hardcoded
    -- colors here instead, matching the dark palette this same file already uses for its own
    -- dropdown menu/hover colors below.
    self:BUi():Stick(LEFT,104):ClearPaint():Background(Color(40, 40, 46), 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(60, 60, 70))
        -- Real, reproduced bug: this was the bare string "MKP8lUR" - not a URL at all (no "/"),
        -- so BUi.GetImgur's own filename extraction (url:match("/([^/]+)$")) always failed and
        -- fell back to Material("nil") - GMod's real checkerboard "missing texture" material,
        -- guaranteed every single time regardless of network/cache state. Every BUi.Combo
        -- anywhere in this codebase shares this one icon slot, so the broken checker square
        -- showed up on all of them at once. Fixed to the same real, valid placeholder URL used
        -- everywhere else in this codebase.
        BUi.DrawImgur(h * 0.15, h * 0.15, h * 0.7, h * 0.7, "https://invisibalfan-ui.github.io/bui_images/images/mkp8lur.png", color_white)
    end)

    self.Input = BUi.Create("DTextEntry", self)
    self.Input:Stick(FILL,nil,40)
    self.Input:ReadyTextbox()
    self.Input:SetText("")
    self.Input:SetPlaceholderText("Select or type...")
    self.Input:SetUpdateOnType(true)
    self.Input:SetFont("BCORE.configb.22")
    self.Input:SetTextColor(color_white)
    self.Input:SetCursorColor(color_white)

    self.Input.OnGetFocus = function()
        self:OpenMenu()
    end

    self.Input.OnValueChange = function(_, val)
        if IsValid(self.Menu) then
            self:PopulateChoices(val or "")
        end
    end

    -- Real, reproduced bug: this called self.Menu:Close() - but self.Menu is a plain BUi.Create
    -- ("DPanel") (see OpenMenu below), and DPanel has no :Close() method at all (that's a
    -- DFrame-family thing) - pressing Enter while the dropdown was open, the ordinary thing to do
    -- right after typing, always threw "attempt to call method 'Close' (a nil value)". On top of
    -- that, Enter never actually committed the typed text as a value in the first place - the
    -- placeholder promises "Select OR type...", but typing something and pressing Enter did
    -- nothing but (attempt to, and fail to) close the menu; only clicking a listed choice ever
    -- called SetComboValue/fired OnSelect. Fixed both: :Remove() instead of the nonexistent
    -- :Close() (matching every other menu-dismissal in this file), and actually committing
    -- whatever's typed - matching an existing choice's own data if the text exactly matches one
    -- (so typing an existing option's name still yields its real data, not a bare nil), otherwise
    -- committing the free-typed text with data=nil.
    self.Input.OnEnter = function()
        local text = self.Input:GetValue() or ""
        if text ~= "" then
            local data = nil
            for _, v in ipairs(self.Choices) do
                if v.text == text then data = v.data; break end
            end
            self:SetComboValue(text, data)
        end
        if IsValid(self.Menu) then
            self.Menu:Remove()
            self.Menu = nil
        end
    end
end

function PANEL:AddChoice(text, data)
    table.insert(self.Choices, { text = text or "", data = data })
end

-- Real, reproduced bug: this menu is a TOP-LEVEL popup (BUi.Create("DPanel") with no parent,
-- then :MakePopup()) with no "click elsewhere closes it" behavior at all - a stock DMenu gets
-- this for free, a bare DPanel doesn't. Left open (never explicitly selected/dismissed) and the
-- OWNING combo then gets torn down by whatever created it (e.g. BuildRecordsRow's own
-- RebuildCards(), which Clear()s the whole card on every Add/Remove Entry click), the menu had
-- no cleanup path tied to that at all - it just kept floating on screen, on top of literally
-- everything (including menus opened later, elsewhere), fully interactive. Clicking one of its
-- still-alive choice buttons then called `self:SetComboValue(...)` on the now-removed combo -
-- reproduced directly as "attempt to call method 'SetComboValue' (a nil value)", since a
-- removed panel's own metatable methods aren't guaranteed to stay resolvable.
--
-- Fixed two ways together: PANEL:OnRemove (below) closes the menu the INSTANT its owning combo
-- is removed, and the menu's own Think here closes it once neither the menu itself nor the
-- combo that opened it is still hovered - real "click away to dismiss" behavior, checked via
-- IsHovered() (true for a panel OR any of its children, so clicking a choice button keeps this
-- true right up until DoClick actually runs).
function PANEL:OpenMenu()
    if #self.Choices == 0 then return end

    if IsValid(self.Menu) then
        self.Menu:Remove()
        self.Menu = nil
    end

    local owner = self
    self.Menu = BUi.Create("DPanel")
    self.Menu:SetSize(self:GetWide(), 300)
    self.Menu:BUi():ClearPaint():Background(Color(28,28,30), 6)
    self.Menu:MakePopup()
    self.Menu:SetKeyboardInputEnabled(false)

    function self.Menu:Think()
        if not IsValid(owner) then
            if IsValid(self) then self:Remove() end
            return
        end
        if not (self:IsHovered() or owner:IsHovered()) then
            self:Remove()
        end
    end

    local x, y = self:LocalToScreen(0, self:GetTall())
    self.Menu:SetPos(x, y)

    self:PopulateChoices(self.Input:GetText() or "")
end

function PANEL:OnRemove()
    if IsValid(self.Menu) then
        self.Menu:Remove()
        self.Menu = nil
    end
end

function PANEL:PopulateChoices(filter)
    if not IsValid(self.Menu) then return end

    local scroll = self.Menu.scroll
    if not IsValid(scroll) then
        scroll = BUi.Create("BUi.Scroll", self.Menu)
        scroll:Dock(FILL)
        self.Menu.scroll = scroll
    end

    scroll:Clear()
    filter = filter or ""
    filter = tostring(filter)

    local filteredChoices = {}

    for _, v in ipairs(self.Choices) do
        local text = tostring(v.text or "")
        if filter == "" or string.find(string.lower(text), string.lower(filter), 1, true) then
            table.insert(filteredChoices, v)
        end
    end

    for _, v in ipairs(filteredChoices) do
        local btn = BUi.Create("DButton", scroll)
        btn:SetText(tostring(v.text or ""))
        btn:SetTall(30)
        btn:Dock(TOP)
        btn:SetFont("BCORE.F4b.18")
        btn:SetTextColor(color_white)
        btn:ClearPaint()
        btn:Background(Color(28,28,30))
        btn:FadeHover(Color(55,54,60,90), 6)

        btn.DoClick = function()
            -- Belt-and-suspenders alongside OnRemove/the menu's own Think above - if this combo
            -- was somehow removed while its menu was still (improbably) still both alive and
            -- clicked, don't call a method that removal may have made unresolvable.
            if not IsValid(self) then return end
            self:SetComboValue(v.text, v.data)
            if IsValid(self.Menu) then
                self.Menu:Remove()
                self.Menu = nil
            end
            self.Input:KillFocus()
        end
    end

    local newHeight = math.min(#filteredChoices * 35 + 35, 300)
    self.Menu:SetSize(self:GetWide(), newHeight)
end

-- Deliberately NOT named SetSelected - Panel:SetSelected(bool) is a real GMod ENGINE method
-- (lua/includes/extensions/client/panel/selections.lua, used for text-selection highlighting on
-- every panel) with a totally different signature/purpose. Defining a same-named method here
-- didn't reliably override it - the built-in kept winning at the actual call site (DoClick above),
-- so clicking a choice called INTO the engine's own SetSelected(bool) with a (string, data) pair
-- instead, which then tried to operate on internal selection state that doesn't apply to this
-- panel at all: "Tried to use a NULL Panel!" inside selections.lua's own implementation. A unique
-- name sidesteps the collision entirely rather than fighting GMod's own method resolution.
function PANEL:SetComboValue(text, data)
    self.Selected = data
    self.Input:SetText(tostring(text or ""))
    if self.OnSelect then
        self:OnSelect(text, data)
    end
end

function PANEL:Paint(w, h)
end

vgui.Register("BUi.Combo", PANEL, "DPanel")
