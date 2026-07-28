-- Shared "house style" card/tab-button chrome, generalized from the ONE real recipe every page
-- in this codebase already hand-rolled independently (beep-f4's cl_dashboard.lua card paint and
-- cl_tabs.lua's CreateButton, beep-inventory's panels) instead of pulling from a shared place.
-- Framework-level so every addon draws from ONE implementation going forward - the opposite of
-- what bcore/vgui_elements/cl_config.lua did (a fresh, unrelated palette/hover mechanism that
-- matched nothing else in the codebase); that file has been rewired to call these instead.
--
-- Colors default to BCORE.F4.colors, resolved LAZILY inside each function call rather than
-- captured once at file-load time - beep-framework loads before beep-f4 (this addon has no
-- business hard-depending on a downstream one), so BCORE.F4 may not exist yet when this file
-- itself loads. A plain Color() fallback (the exact same real values, just inlined) keeps both
-- functions usable even if beep-f4 isn't installed at all.
local function DefaultColors()
    local c = BCORE.F4 and BCORE.F4.colors
    return {
        border        = (c and c.border)        or Color(55, 54, 60),
        surface       = (c and c.surface)        or Color(35, 34, 38),
        surfaceRaised = (c and c.surfaceRaised)  or Color(40, 39, 44),
        highlight     = (c and c.highlight)      or Color(194, 55, 9),
        highlightAlt  = (c and c.highlightAlt)   or Color(255, 78, 217),
    }
end

local function MergedColors(opts)
    local col = DefaultColors()
    if opts and opts.colors then
        for k, v in pairs(opts.colors) do col[k] = v end
    end
    return col
end

--[[
    Draws the card/panel shell itself - a plain drawing function, not panel-bound, meant to be
    called from inside your own :On("Paint", function(s, w, h) ... end) closure (the same shape
    cl_dashboard.lua's own PaintGlowBorder(w, h, radius) already uses). Layers, bottom to top:
    border-color rounded box -> inset surface-color fill -> a masked gradient "wash" tinted with
    highlight/highlightAlt, clipped to the rounded shape -> an optional surfaceRaised header
    strip -> an optional left accent stripe.

    opts (all optional):
      radius       - corner radius, default 10
      colors       - override table (any of border/surface/surfaceRaised/highlight/highlightAlt)
                     - pass a rarity color here for an item/case card, e.g.
                     {highlight = rarityColor, highlightAlt = rarityColor}
      rotate       - true for the real F4 card recipe (a rotating dual-gradient wash); false
                     (default) draws a fixed Down-only single wash instead - cheaper (no
                     CurTime() dependency) and the right choice for a tall list of many rows
                     redrawing every frame at once, which is why the config panel's own cards
                     use this flavor.
      washHeight   - caps the fixed (non-rotating) wash's own height; nil = full card height
      headerStrip  - draws a rounded-top-only surfaceRaised strip this tall at the top, 0/nil = none
      accentStripe - draws a SideBlock-style accent stripe on the left edge, default false
]]
function BUi:PaintCardShell(w, h, opts)
    opts = opts or {}
    local col = MergedColors(opts)
    local radius = opts.radius or 10

    draw.RoundedBox(radius, 0, 0, w, h, col.border)
    draw.RoundedBox(radius, 1, 1, w - 2, h - 2, col.surface)

    BUi.masks.Start()
    if opts.rotate then
        local rot = (CurTime() * 22) % 360
        surface.SetMaterial(BUi.Grad["Right"])
        surface.SetDrawColor(ColorAlpha(col.highlight, 100))
        surface.DrawTexturedRectRotated(w / 2, h / 2, w, h * 2, rot)
        surface.SetMaterial(BUi.Grad["Left"])
        surface.SetDrawColor(ColorAlpha(col.highlightAlt, 70))
        surface.DrawTexturedRectRotated(w / 2, h / 2, w, h * 2, rot + 180)
    else
        surface.SetMaterial(BUi.Grad["Down"])
        surface.SetDrawColor(ColorAlpha(col.highlight, 45))
        surface.DrawTexturedRect(1, 1, w - 2, opts.washHeight or (h - 2))
    end
    BUi.masks.Source()
    draw.RoundedBox(radius, 1, 1, w - 2, h - 2, color_white)
    BUi.masks.End()

    if opts.headerStrip and opts.headerStrip > 0 then
        draw.RoundedBoxEx(radius, 1, 1, w - 2, opts.headerStrip, col.surfaceRaised, true, true, false, false)
    end

    if opts.accentStripe then
        draw.RoundedBox(3, 0, 3, 4, h - 6, col.highlight)
    end
end

--[[
    Generalizes cl_tabs.lua's real CreateButton tab-button recipe: a two-tone border/surface
    fill when unselected, a rotating dual-gradient wash (click-flash driven) over a
    surfaceRaised fill when selected. Deliberately NOT the color-lerp-on-hover mechanism
    bcore/vgui_elements/cl_config.lua's own StyleButton/StyleNavButton invented - nothing else
    in this codebase does that; this is the one real, established pattern.

    isSelectedFn - a zero-arg function returning true/false, called fresh every Paint. A caller
    can check LIVE state this way (F4's own "CurrentTab == idet" pattern - no rebuild needed when
    selection changes) or just close over a fixed boolean decided at button-creation time, for a
    caller that fully rebuilds its whole button list on every selection change instead (the
    pattern the server config panel's own nav sidebar already uses).

    opts (all optional): radius (default 8), colors (override table, see PaintCardShell),
    selectedFont/unselectedFont (swapped automatically based on isSelectedFn's result each
    frame - omit either to leave the button's own SetFont alone), paintExtra(s, w, h, selected)
    for a caller that wants to draw its own icon/label on top (kept generic here since icon URLs
    are per-addon).
]]
function BUi:StyleTabButton(btn, isSelectedFn, opts)
    opts = opts or {}
    local col = MergedColors(opts)
    local radius = opts.radius or 8

    btn:BUi()
    btn:ClearPaint()

    -- Same literal SetupTransition shape cl_tabs.lua's real CreateButton uses (a numeric ramp
    -- rather than a strict boolean predicate) - kept byte-for-byte rather than "corrected", since
    -- matching what's actually on screen in F4 today is the whole point of this pass, not a
    -- reinterpretation of what the original author may have intended.
    btn:SetupTransition("tabanim", 0.6, function(s)
        if BUi.Doclick(s) then return math.min((s.tabanim or 0) + 10, 255) else return math.max((s.tabanim or 0) - 10, 0) end
    end)
    btn:FadeHover(ColorAlpha(col.border, 90), 6, radius)

    btn:On("Paint", function(s, w, h)
        local selected = isSelectedFn and isSelectedFn() or false

        if opts.selectedFont and opts.unselectedFont then
            s:SetFont(selected and opts.selectedFont or opts.unselectedFont)
        end

        if selected then
            local frac = s.tabanim or 0
            draw.RoundedBox(radius, 0, 0, w, h, col.surfaceRaised)
            BUi.masks.Start()
            surface.SetMaterial(BUi.Grad["Right"])
            surface.SetDrawColor(ColorAlpha(col.highlight, col.highlight.a * frac))
            surface.DrawTexturedRect(0, 0, w, h)
            surface.SetMaterial(BUi.Grad["Left"])
            surface.SetDrawColor(ColorAlpha(col.highlightAlt, col.highlightAlt.a * frac))
            surface.DrawTexturedRect(0, 0, w / 2, h)
            BUi.masks.Source()
            draw.RoundedBox(radius, 0, 0, w, h, col.highlight)
            BUi.masks.End()
            draw.RoundedBox(radius, 1, 1, w - 2, h - 2, ColorAlpha(color_black, math.min(230, 230 * frac)))
        else
            draw.RoundedBox(radius, 0, 0, w, h, col.border)
            draw.RoundedBox(radius, 1, 1, w - 2, h - 2, col.surface)
        end

        if opts.paintExtra then opts.paintExtra(s, w, h, selected) end
    end)
end

-- Comma-grouped money formatter ("$1,234,567", never abbreviated) - promoted from
-- BCORE.Inventory:FormatMoneySafe (cl_action_slot.lua), which had already reimplemented
-- beep_unboxing's own separate hand-rolled digit-by-digit version of the exact same thing.
-- Genuinely different from BUi:FormatMoney above (that one abbreviates - "$1.2M" - and is kept
-- as-is for the dashboard/printers callers that specifically want that shorter form).
function BUi:FormatMoneyFull(amount)
    return "$" .. string.Comma(math.floor(tonumber(amount) or 0))
end
