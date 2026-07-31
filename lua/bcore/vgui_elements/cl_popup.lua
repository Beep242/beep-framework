local PANEL = {}

function PANEL:Init()
    self:SetSize(math.max(400, ScrW() * 0.28), math.max(180, ScrH() * 0.22))
    self:Center()
    self:MakePopup()
    self:SetKeyboardInputEnabled(true)
    self:BUi():ClearPaint():Background(Color(48,48,48), 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w-2, h-2, Color(28,28,28))
    end)

    self.Header = BUi.Create("DPanel", self)
    self.Header:Stick(TOP,5)
    self.Header:SetTall(45)
    self.Header:BUi():ClearPaint():Background(Color(56,56,56), 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w-2, h-2, Color(28,28,28))
    end)

    self.TitleLabel = BUi.Create("DLabel", self.Header)
    self.TitleLabel:Dock(LEFT)
    self.TitleLabel:SetWide(self.Header:GetWide())
    self.TitleLabel:DockMargin(15, 0, 0, 0)
    self.TitleLabel:SetFont("BCORE.configb.24")
    self.TitleLabel:SetTextColor(Color(255,255,255))
    self.TitleLabel:SetText("23423")

    self.CloseBtn = BUi.Create("DButton", self.Header)
    self.CloseBtn:Stick(RIGHT,5)
    self.CloseBtn:SetWide(35)
    self.CloseBtn:ClearPaint()
    self.CloseBtn:BUi():Background(Color(61,61,61), 4)
    self.CloseBtn.DoClick = function()
        if IsValid(self) then self:Remove() end
    end
    self.CloseBtn:On("Paint", function(s, w, h)
        draw.RoundedBox(4, 1, 1, w-2, h-2, Color(28,28,28))
        BUi.DrawImgur(0, 0, w, h, "https://beep242.github.io/bui_images/images/0cjxwbc.png", Color(255,255,255))
    end)
    self.CloseBtn:Text("")
    self.CloseBtn:FadeHover(Color(100,0,0,90), 6, 4)

    self.Body = BUi.Create("DPanel", self)
    self.Body:Stick(FILL)
    self.Body:BUi():ClearPaint()
end

function PANEL:SetName(t)
    if IsValid(self.TitleLabel) then
        self.TitleLabel:SetText(t or "")
    end
end

function PANEL:ClearBody()
    if not IsValid(self.Body) then return end
    local kids = self.Body:GetChildren()
    for i = #kids, 1, -1 do
        if IsValid(kids[i]) then kids[i]:Remove() end
    end
end

local function safeCall(fn, ...)
    if type(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then
            ErrorNoHalt("[BUi.Popup] callback error: ", tostring(err), "\n")
        end
    end
end

function PANEL:SetMode(mode, data)
    data = data or {}
    self:ClearBody()

    if mode == "textentry" then
        local entryholder = BUi.Create("DPanel", self.Body)
        entryholder:Dock(TOP)
        entryholder:DockMargin(20,20,20,10)
        entryholder:SetTall(40)
        entryholder:ClearPaint():Background(Color(44,44,44), 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(28,28,28))
            BUi.DrawImgur(h * .15, h * .15, h * .7, h * .7, "https://beep242.github.io/bui_images/images/mkp8lur.png", Color(255,255,255))
        end)
        entryholder:DockPadding(40, 0, 0, 0)

        local entry = BUi.Create("DTextEntry", entryholder)
        entry.OnGetFocus = function(self) self:SetValue("") end
        entry:Stick(FILL)
        entry:ReadyTextbox()
        entry:SetFont("BCORE.configb.22")
        entry:SetTextColor(Color(255,255,255))
        entry:SetCursorColor(Color(255,255,255))
        entry:SetPlaceholderText(data.placeholder or "")

        local confirm = BUi.Create("DButton", self.Body)
        confirm:Stick(BOTTOM,10)
        confirm:SetTall(40)
        confirm:SetText(data.confirmText or "Confirm")
        confirm:SetFont("BCORE.configb.22")
        confirm:SetTextColor(Color(255,255,255))
        confirm:ClearPaint()
        confirm:BUi():Background(Color(0,150,0), 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8,1,1,w-2,h-2,Color(28,28,28))
        end)
        confirm:FadeHover(Color(13,81,4,63), 8,8)
        confirm.DoClick = function()
            safeCall(data.callback, entry:GetText())
            if IsValid(self) then self:Remove() end
        end
    end

    if mode == "yesno" then
        local txt = BUi.Create("DLabel", self.Body)
        txt:Stick(FILL,10)
        txt:SetFont("BCORE.configb.22")
        txt:SetTextColor(Color(255,255,255))
        txt:SetText(data.text or "")
        txt:SetWrap(true)

        local btns = BUi.Create("DPanel", self.Body)
        btns:Dock(BOTTOM)
        btns:SetTall(60)
        btns:ClearPaint()

        local yes = BUi.Create("DButton", btns)
        yes:Stick(LEFT,10)
        yes:SetWide(btns:GetWide() * 4)
        yes:SetText(data.yesText or "Yes")
        yes:SetFont("BCORE.configb.22")
        yes:SetTextColor(Color(255,255,255))
        yes:ClearPaint()
        yes:BUi():Background(Color(11,127,7,195), 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8,1,1,w-2,h-2,Color(28,28,28))
        end)
        yes:FadeHover(Color(11,127,7,41), 8,8)
        yes.DoClick = function()
            safeCall(data.yes)
            if IsValid(self) then self:Remove() end
        end

        local no = BUi.Create("DButton", btns)
        no:Stick(RIGHT,10)
        no:SetWide(btns:GetWide() * 4)
        no:SetText(data.noText or "No")
        no:SetFont("BCORE.configb.22")
        no:SetTextColor(Color(255,255,255))
        no:ClearPaint()
        no:BUi():Background(Color(247,56,56,214), 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8,1,1,w-2,h-2,Color(28,28,28))
        end)
        no:FadeHover(Color(247,56,56,53), 8,8)
        no.DoClick = function()
            safeCall(data.no)
            if IsValid(self) then self:Remove() end
        end
    end

    if mode == "multi" then
        local scroll = BUi.Create("BUi.Scroll", self.Body)
        scroll:Dock(FILL)
        for _, opt in ipairs(data.options or {}) do
            local btn = BUi.Create("DButton", scroll)
            btn:Dock(TOP)
            btn:SetTall(40)
            btn:DockMargin(20,10,20,0)
            btn:SetText(opt.text or "")
            btn:SetFont("BCORE.configb.22")
            btn:SetTextColor(Color(255,255,255))
            btn:ClearPaint()
            btn:BUi():Background(Color(33,33,33), 8):On("Paint", function(s, w, h)
                draw.RoundedBox(8,1,1,w-2,h-2,Color(28,28,28))
            end)
            btn:FadeHover(Color(150,150,150,100), 8,8)
            btn.DoClick = function()
                safeCall(opt.func)
                if not data.stay and IsValid(self) then self:Remove() end
            end
        end
    end

    if mode == "custom" and type(data.create) == "function" then
        safeCall(data.create, self.Body, self)
    end
end

vgui.Register("BUi.Popup", PANEL, "EditablePanel")
