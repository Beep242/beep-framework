//////////////////////////////////////////////////
////////Credits to Code Blue you will be missed//
////////////////////////////////////////////////
// This file is part of the BUi library, which provides various UI components and utilities.
// The code below handles the creation of images from Imgur, including progress indicators and masks.Aswell as avatars. 
local materials = {}
file.CreateDir("beeps_ui")

BUi.GetImgur = function(url, callback, matSettings)
    if materials[url] then return callback(materials[url]) end

    local filename = string.match(url, "/([^/]+)$")
    if not filename then
        materials[url] = Material("nil")
        return callback(materials[url])
    end

    if file.Exists("beeps_ui/" .. filename, "DATA") then
        materials[url] = Material("../data/beeps_ui/" .. filename, matSettings or "noclamp smooth mips")
        return callback(materials[url])
    end
    

    http.Fetch(url, function(body, len)
        if not body or len == 0 or len > 2097152 then
            materials[url] = Material("nil")
            return callback(materials[url])
        end

        file.Write("beeps_ui/" .. filename, body)
        timer.Simple(0, function()
            materials[url] = Material("../data/beeps_ui/" .. filename, matSettings or "noclamp smooth mips")
            callback(materials[url])
        end)
    end, function()
        materials[url] = Material("nil")
        callback(materials[url])
    end)
end

local min = math.min
local curTime = CurTime
local progressMat

BUi.DrawProgressWheel = function(x, y, w, h, col)
    local s = min(w, h)
    surface.SetMaterial(progressMat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRectRotated(x + w * 0.5, y + h * 0.5, s, s, curTime() * 50)
end

drawProgressWheel = BUi.DrawProgressWheel

local materials_img = {}
local grabbingMaterials = {}
local getImgur = BUi.GetImgur


getImgur("https://beep242.github.io/bui_images/9xg5q8d.png", function(mat)
    progressMat = mat
 end)


BUi.DrawImgur = function(x, y, w, h, url, col, r)
    if not materials_img[url] then
        drawProgressWheel(x, y, w, h, col)
        if grabbingMaterials[url] then return end
        grabbingMaterials[url] = true

        getImgur(url, function(mat)
            materials_img[url] = mat
            grabbingMaterials[url] = nil
        end)

        return
    end

    surface.SetMaterial(materials_img[url])
    surface.SetDrawColor(col.r, col.g, col.b, col.a)

    if not r then
        surface.DrawTexturedRect(x, y, w, h)
    else
        BUi.masks.Start()
        surface.DrawTexturedRect(x, y, w, h)
        BUi.masks.Source()
        draw.RoundedBox(r, x, y, w, h, color_white)
        BUi.masks.End()
    end
end

BUi.DrawImgurRotated = function(x, y, w, h, rot, url, col)
    if not materials_img[url] then
        drawProgressWheel(x - w * 0.5, y - h * 0.5, w, h, col)
        if grabbingMaterials[url] then return end
        grabbingMaterials[url] = true

        getImgur(url, function(mat)
            materials_img[url] = mat
            grabbingMaterials[url] = nil
        end)

        return
    end

    surface.SetMaterial(materials_img[url])
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRectRotated(x, y, w, h, rot)
end


//////////////////////////////////////////////////
//Credits to Billy for the AvatarMaterial code////
//////////////////////////////////////////////////

local AVATAR_IMAGE_CACHE_EXPIRES = 86400

function BUi.GetAvatar(steamid64, callback)
	local fallback
	if os.time() - file.Time("avatars/" .. steamid64 .. ".png", "DATA") > AVATAR_IMAGE_CACHE_EXPIRES then
		fallback = Material("../data/avatars/" .. steamid64 .. ".png", "smooth")
	elseif os.time() - file.Exists("avatars/" .. steamid64 .. ".jpg", "DATA") > AVATAR_IMAGE_CACHE_EXPIRES then
		fallback = Material("../data/avatars/" .. steamid64 .. ".jpg", "smooth")
	end

	if not fallback or fallback:IsError() then
		fallback = Material("vgui/avatar_default")
	else
		return callback(fallback)
	end

	http.Fetch("https://steamcommunity.com/profiles/" .. steamid64 .. "?xml=1", function(body, size, headers, code)
		if size == 0 or code < 200 or code > 299 then return callback(fallback, steamid64)end

		local url, fileType = body:match("<avatarFull>.-(https?://%S+%f[%.]%.)(%w+).-</avatarFull>")
		if not url or not fileType then return callback(fallback, steamid64)end
		if fileType == "jpeg" then fileType = "jpg"end

		http.Fetch(url .. fileType, function(body, size, headers, code)
			if size == 0 or code < 200 or code > 299 then return callback(fallback, steamid64)end

			local cachePath = "avatars/" .. steamid64 .. "." .. fileType
			file.CreateDir("avatars")
			file.Write(cachePath, body)

			local material = Material("../data/" .. cachePath, "smooth")
			if material:IsError() then
				file.Delete(cachePath)
				callback(fallback, steamid64)
			else
				callback(material, steamid64)
			end

		end, function()
			callback(fallback, steamid64)end)
	end, function()
		callback(fallback, steamid64)end)
end

local function clearCachedAvatars()
	for _, f in ipairs(file.Find("avatars/*", "DATA")) do
		file.Delete("avatars/" .. f)
	end

	hook.Remove("InitPostEntity", "clearCachedAvatars")
end
hook.Add("InitPostEntity", "clearCachedAvatars", clearCachedAvatars)

local PANEL = {}

function PANEL:Init()
	self.m_Material = Material("vgui/avatar_default")
end

function PANEL:SetPlayer(ply)
	if ply:IsBot() then return end
	self.m_SteamID64 = ply:SteamID64()
	self:Download()
end

function PANEL:SetSteamID64(steamid64)
	self.m_SteamID64 = steamid64
	if steamid64 then
		self:Download()
	end
end

function PANEL:GetPlayer()
	if self.m_SteamID64 == nil then
		return NULL
	else

		return player.GetBySteamID64(self.m_SteamID64)
	end
end

function PANEL:GetMaterial()
	return self.m_Material
end

function PANEL:GetSteamID64()
	return self.m_SteamID64
end

function PANEL:Download()
	assert(self.m_SteamID64 ~= nil, "Tried to download the avatar image of a nil SteamID64!")
	BUi.GetAvatar(self.m_SteamID64, function(mat)
		if not IsValid(self) then return end
		self.m_Material = mat
	end)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(self.m_Material)
	surface.DrawTexturedRect(0, 0, w, h)
end

vgui.Register("AvatarMaterial", PANEL, "Panel")