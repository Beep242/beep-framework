BCORE:RegisterConfig("bcore", "AdminGroups", {
    label = "Config Admin Groups",
    category = "Access Control",
    description = "Usergroups (besides SuperAdmin, which always has access) allowed to open and edit the server config panel.",
    type = "list",
    default = { "superadmin" },
})

function BCORE:IsConfigAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end

    local groups = BCORE:GetConfig("bcore", "AdminGroups") or {}
    local myGroup = ply:GetUserGroup()

    for _, g in ipairs(groups) do
        if g == myGroup then return true end
    end

    return false
end
