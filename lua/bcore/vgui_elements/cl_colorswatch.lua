-- A clickable color swatch that opens a small DColorMixer popup. The one genuinely new
-- primitive the config UI needs - BUi has no color picker of its own yet.
local PANEL = {}

function PANEL:Init()
    self:SetCursor("hand")
    self.Colour = Color(255, 255, 255, 255)

    self:BUi():ClearPaint():On("Paint", function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20))
        draw.RoundedBox(4, 2, 2, w - 4, h - 4, s.Colour)
        surface.SetDrawColor(255, 255, 255, 40)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
    end)
end

function PANEL:SetColor(col)
    if not col then return end
    self.Colour = col
end

function PANEL:GetColor()
    return self.Colour
end

-- Set PANEL.OnValueConfirmed = function(self, color) ... end to be notified once the picker closes.

function PANEL:OnMousePressed()
    self:TogglePicker()
end

function PANEL:TogglePicker()
    if IsValid(self.Picker) then
        self.Picker:Remove()
        self.Picker = nil
        return
    end

    local picker = BUi.Create("DPanel", nil)
    picker:SetSize(230, 290)
    picker:BUi():ClearPaint():Background(Color(28, 28, 30), 6)
    picker:MakePopup()
    picker:SetKeyboardInputEnabled(true)

    local x, y = self:LocalToScreen(0, self:GetTall() + 4)
    local sw, sh = ScrW(), ScrH()
    if x + picker:GetWide() > sw then x = sw - picker:GetWide() - 4 end
    if y + picker:GetTall() > sh then y = sh - picker:GetTall() - 4 end
    picker:SetPos(x, y)

    local mixer = vgui.Create("DColorMixer", picker)
    mixer:Dock(TOP)
    mixer:DockMargin(8, 8, 8, 4)
    mixer:SetTall(210)
    mixer:SetPalette(false)
    mixer:SetAlphaBar(true)
    mixer:SetWangs(true)
    mixer:SetColor(self.Colour)
    mixer.ValueChanged = function(_, col)
        if IsValid(self) then
            self.Colour = col
        end
    end

    local done = BUi.Create("DButton", picker)
    done:Dock(BOTTOM)
    done:DockMargin(8, 4, 8, 8)
    done:SetTall(32)
    done:SetText("Done")
    done:SetFont("BCORE.configb.18")
    done:SetTextColor(Color(255, 255, 255))
    done:ClearPaint()
    done:BUi():Background(Color(0, 150, 0), 6)
    done:FadeHover(Color(13, 81, 4, 63), 6, 6)
    done.DoClick = function()
        if IsValid(picker) then picker:Remove() end
    end

    picker.OnRemove = function()
        -- self is already invalid here when this fires as a *result* of self's own
        -- OnRemove (below) removing the picker during the swatch's own removal cascade -
        -- GMod marks a panel invalid before running its OnRemove, so both writes below
        -- need their own guard, not just the OnValueConfirmed call.
        if IsValid(self) then
            self.Picker = nil
            if self.OnValueConfirmed then
                self:OnValueConfirmed(self.Colour)
            end
        end
    end

    self.Picker = picker
end

function PANEL:OnRemove()
    if IsValid(self.Picker) then self.Picker:Remove() end
end

vgui.Register("BUi.ColorSwatch", PANEL, "DPanel")
