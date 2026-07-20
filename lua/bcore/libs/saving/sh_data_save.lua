//Vectivus made this
function BCORE:GetData( storageID, fileName, decodeJSON )
    local safeID = self:ParseKey( storageID )
    local path = ( "BCORE/" .. safeID .. "/" )
    path = ( path .. fileName .. ".dat" )
    if file.Exists( path, "DATA" ) then
        local raw = file.Read( path, "DATA" )
        return ( decodeJSON and util.JSONToTable( raw ) or raw )
    end
    return false
end