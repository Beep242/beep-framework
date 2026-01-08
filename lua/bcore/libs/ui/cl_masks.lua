//Credits to Garryspins
//This file is part of the BUi library, which provides various UI components and utilities.
//The code below handles the drawing of masks without using stencil buffers.
 
local BUi = BUi or {}
local surface = surface
local draw = draw
local cam = cam
local color_white = color_white
local ScrW, ScrH = ScrW, ScrH
local masks = {}
BUi.masks = masks

masks.source = {}
masks.dest   = {}

masks.source.rt = GetRenderTargetEx("Masks_Source",      ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)
masks.dest.rt   = GetRenderTargetEx("Masks_Destination", ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)

masks.source.mat = CreateMaterial("Masks_Source", "UnlitGeneric", {
    ["$basetexture"] = masks.source.rt:GetName(),
    ["$translucent"] = "1",
    ["$vertexalpha"] = "1",
    ["$vertexcolor"] = "1",
})
masks.dest.mat    = CreateMaterial("Masks_Destination", "UnlitGeneric", {
    ["$basetexture"] = masks.dest.rt:GetName(),
    ["$translucent"] = "1",
    ["$vertexalpha"] = "1",
    ["$vertexcolor"] = "1",
})


masks.KIND_CUT   = {BLEND_ZERO, BLEND_SRC_ALPHA, BLENDFUNC_ADD}
masks.KIND_STAMP = {BLEND_ZERO, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD}


function masks.Start()
    render.PushRenderTarget(masks.dest.rt)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
end


function masks.Source()
    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.source.rt)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
end


function masks.And(kind)
    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.dest.rt)
    cam.Start2D()
        render.OverrideBlend(true,
            kind[1], kind[2], kind[3]
        )
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(masks.source.mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.OverrideBlend(false)
    masks.Source()
end


function masks.End(kind)
    kind = kind or masks.KIND_CUT

    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.dest.rt)
    cam.Start2D()
        render.OverrideBlend(true,
            kind[1], kind[2], kind[3]
        )
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(masks.source.mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.OverrideBlend(false)
    cam.End2D()
    render.PopRenderTarget()

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(masks.dest.mat)
    surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end


if not melon then return masks end


