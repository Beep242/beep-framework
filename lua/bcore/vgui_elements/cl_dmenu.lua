local PANEL = {}

function PANEL:Init()
    self:SetSize(180, 30)
    self:BUi():ClearPaint():Background(Color(28,28,30),6)
    self:SetVisible(false)
    self:DockPadding(0,5,0,5)
    self.Buttons = {}
    self.SubMenus = {}
    self.Created = true

    self.Scroll = BUi.Create("BUi.Scroll", self)
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(2,2,2,2)
    self.Scroll:DockPadding(2,2,2,2)
end

function PANEL:AddOption(text, func)
    local btn = BUi.Create("DButton", self.Scroll)
    btn:SetText("")
    btn:SetTall(BUi:Scale(35))
    btn:Dock(TOP)
    btn:DockMargin(0,0,0,2)
    btn:ClearPaint():Background(Color(28,28,30))
    btn:FadeHover(Color(55,54,60,90),6)
    btn.Text = text
    btn.Paint = function(s,w,h)
        draw.RoundedBox(6,1,1,w-2,h-2,Color(28,28,30))
        draw.SimpleText(text,"BCORE.configb.18",10,h/2,Color(255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end
    if func then
        btn.DoClick = function()
            func()
            self:CloseAll()
        end
    end
    table.insert(self.Buttons, btn)
    return btn
end

function PANEL:AddSubMenu(text)
    local sub = vgui.Create("BUi.DMenu")
    sub:SetWide(self:GetWide())
    sub.ParentMenu = self
    table.insert(self.SubMenus, sub)

    local arrow = Material("icon16/arrow_right.png")
    local btn = self:AddOption(text)
    btn.Paint = function(s,w,h)
        draw.RoundedBox(6,1,1,w-2,h-2,Color(28,28,30))
        draw.SimpleText(text,"BCORE.configb.18",10,h/2,Color(255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(arrow)
        surface.DrawTexturedRect(w-18,h/2-8,16,16)
    end
    btn.DoClick = nil

    btn.OnCursorEntered = function()
        if not IsValid(sub) then return end
        for _, s in ipairs(self.SubMenus) do
            if s ~= sub and IsValid(s) then s:Close() end
        end
        local x, y = self:LocalToScreen(self:GetWide()-4, btn:GetY())
        sub:SetPos(x, y)
        sub:Open()
        self.ActiveSubMenu = sub
    end

    sub.Think = function(s)
        local hovered = s:IsHovered()
        local parentBtnHovered = IsValid(btn) and btn:IsHovered()
        local parentHovered = IsValid(s.ParentMenu) and s.ParentMenu:IsHovered()
        if hovered or parentBtnHovered or parentHovered then
            s.LastHover = SysTime()
        elseif SysTime() - (s.LastHover or 0) > 0.35 then
            s:Close()
        end
    end

    return sub
end

function PANEL:Open()
    if #self.Buttons == 0 then return end
    self:SetVisible(true)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    local mouseX, mouseY = input.GetCursorPos()
    local screenW, screenH = ScrW(), ScrH()
    local totalHeight = math.min(#self.Buttons * BUi:Scale(37) + 10, ScrH() * 0.5)
    local menuW, menuH = self:GetWide(), totalHeight
    if mouseX + menuW > screenW then mouseX = screenW - menuW end
    if mouseY + menuH > screenH then mouseY = screenH - menuH end
    self:SetPos(mouseX, mouseY)
    self:SetTall(menuH)
end

function PANEL:Close()
    if not self.Created then return end
    self:SetVisible(false)
    for _, s in ipairs(self.SubMenus) do
        if IsValid(s) then s:Close() end
    end
    for _, btn in ipairs(self.Buttons) do
        if IsValid(btn) then btn:Remove() end
    end
    self.Buttons = {}
    self.SubMenus = {}
    self.Created = false
end

function PANEL:CloseAll()
    self:Close()
    if self.ParentMenu and IsValid(self.ParentMenu) then
        self.ParentMenu:CloseAll()
    end
end

vgui.Register("BUi.DMenu", PANEL, "DPanel")
