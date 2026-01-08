//Don't Know who made this so sorry if I didn't credit you
local PANEL = {}
AccessorFunc(PANEL, "bounceHeight", "BounceHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "scrollSpeed", "ScrollSpeed", FORCE_NUMBER)

function PANEL:Init()
    self:SetMouseInputEnabled(true)
    self:SetBounceHeight(75)
    self:SetScrollSpeed(75)
    self.Hover = 0
    self.Canvas = vgui.Create("Panel", self)

    self.Canvas.OnMousePressed = function(s, code)
        self:OnMousePressed(code)
    end

    self.Canvas.PerformLayout = function(s, w, h)
        self:PerformLayout(w, h)
        self:InvalidateParent()
    end

    self.VBar = vgui.Create("DPanel", self)
    self.VBar:Dock(RIGHT)
    self.VBar:DockMargin(10, 0, 0, 0)
    self.VBar:InvalidateParent(true)
    self.VBar:SetWide(5)

    self.VBar.Paint = function(s, w, h)
        draw.RoundedBox(w / 2, 0, 0, w, h, Color(255, 255, 255, 5))
    end

    self.Grip = vgui.Create("DButton", self.VBar)
    self.Grip:SetWide(self.VBar:GetWide())
    self.Grip:SetPos(0, 0)
    self.Grip:SetText("")
    self.Grip.Hover = 0

    self.Grip.Paint = function(s, w, h)
        draw.RoundedBox(w / 2, 0, 0, w, h, Color(255, 255, 255, 10 + s.Hover * 15))
    end

    self.Grip.OnMousePressed = function(s, key)
        if (key == MOUSE_FIRST) then
            s.StartDrag = select(2, s:CursorPos())
        end
    end

    self.Grip.OnMouseReleased = function(s, key)
        if (key == MOUSE_FIRST) then
            s.StartDrag = nil
        end
    end

    self.Grip.Think = function(s)
        if (not s.StartDrag) then return end

        if (not input.IsMouseDown(MOUSE_FIRST)) then
            self.Grip:OnMouseReleased(MOUSE_FIRST)

            return
        end

        local x, y = self.VBar:CursorPos()
        local frac = (y - s.StartDrag) / self.VBar:GetTall()
        self.Target = self.Canvas:GetTall() * frac
    end

    self.Target = 0
    self.DisplayOffset = 0
end

function PANEL:AddItem(pnl)
    pnl:SetParent(self.Canvas)
end

function PANEL:OnChildAdded(child)
    self:AddItem(child)
end

function PANEL:VBarSetWide(num)
    self.VBar:SetWide(num)
end

function PANEL:Clear()
    self.DisplayOffset = 0
    self.Target = 0

    return self.Canvas:Clear()
end

function PANEL:GetInnerHeight()
    return math.max(0, self.Canvas:GetTall() - self:GetTall())
end

function PANEL:OnMouseWheeled(d)
    local bh = self:GetBounceHeight()
    self.Target = math.Clamp(self.Target - d * self:GetScrollSpeed(), -bh, self:GetInnerHeight() + bh)

    return true
end

function PANEL:Think()
    self.Target = Lerp(FrameTime() * 10, self.Target, math.Clamp(self.Target, 0, self:GetInnerHeight()))
    self.DisplayOffset = Lerp(FrameTime() * 10, self.DisplayOffset, self.Target)
    self.Canvas:SetPos(0, -self.DisplayOffset)
    local dFrac = self.DisplayOffset / self.Canvas:GetTall()
    self.Grip:SetPos(0, dFrac * self.VBar:GetTall())
end

function PANEL:PerformLayout(w, h)
    self.Canvas:SizeToChildren(false, true)
    self.Canvas:SetWide(w - self.VBar:GetWide())

    if (self.Grip) then
        self.Grip:SetTall(self.VBar:GetTall() * self:GetTall() / self.Canvas:GetTall())
    end
end

function PANEL:Paint()
end

vgui.Register("BUi.Scroll", PANEL, "DPanel")