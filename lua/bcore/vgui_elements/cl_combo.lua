local PANEL = {}

function PANEL:Init()
    self:SetTall(30)
    self.Selected = nil
    self.Choices = {}

    self:BUi():Stick(LEFT,104):ClearPaint():Background(BCORE.config.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.config.colors.accent)
        BUi.DrawImgur(h * 0.15, h * 0.15, h * 0.7, h * 0.7, "MKP8lUR", color_white)
    end)

    self.Input = BUi.Create("DTextEntry", self)
    self.Input:Stick(FILL,nil,40)
    self.Input:ReadyTextbox()
    self.Input:SetText("")
    self.Input:SetPlaceholderText("Select or type...")
    self.Input:SetUpdateOnType(true)
    self.Input:SetFont("BCORE.configb.22")
    self.Input:SetTextColor(BCORE.config.colors.cwhite)
    self.Input:SetCursorColor(BCORE.config.colors.cwhite)

    self.Input.OnGetFocus = function()
        self:OpenMenu()
    end

    self.Input.OnValueChange = function(_, val)
        if IsValid(self.Menu) then
            self:PopulateChoices(val or "")
        end
    end

    self.Input.OnEnter = function()
        if IsValid(self.Menu) then
            self.Menu:Close()
        end
    end
end

function PANEL:AddChoice(text, data)
    table.insert(self.Choices, { text = text or "", data = data })
end

function PANEL:OpenMenu()
    if #self.Choices == 0 then return end

    if IsValid(self.Menu) then
        self.Menu:Remove()
        self.Menu = nil
    end

    self.Menu = BUi.Create("DPanel")
    self.Menu:SetSize(self:GetWide(), 300)
    self.Menu:BUi():ClearPaint():Background(Color(28,28,30), 6)
    self.Menu:MakePopup()
    self.Menu:SetKeyboardInputEnabled(false)

    local x, y = self:LocalToScreen(0, self:GetTall())
    self.Menu:SetPos(x, y)

    self:PopulateChoices(self.Input:GetText() or "")
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
            self:SetSelected(v.text, v.data)
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

function PANEL:SetSelected(text, data)
    self.Selected = data
    self.Input:SetText(tostring(text or ""))
    if self.OnSelect then
        self:OnSelect(text, data)
    end
end

function PANEL:Paint(w, h)
end

vgui.Register("BUi.Combo", PANEL, "DPanel")
