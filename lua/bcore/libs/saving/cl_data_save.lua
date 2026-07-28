-- Client-side receiver for BCORE:AddText (sv_data_save.lua). The server side already existed
-- and correctly called net.Send(ply) - but nothing anywhere ever registered a matching
-- net.Receive("BCORE.Chat", ...) on the client, so every message it ever sent was silently
-- dropped with zero feedback to the player. In practice this meant every config-edit rejection
-- BCORE:SetConfig sends (no permission, SuperAdmin-only field, unknown entry, validation
-- failure) was completely invisible - an admin typing into a config field and having it
-- rejected server-side looked identical to the field just "not working" at all, with no way to
-- tell the two apart.
net.Receive("BCORE.Chat", function()
    local message = net.ReadString()
    if not message or message == "" then return end
    chat.AddText(Color(255, 150, 60), message)
end)
