//Vectivus made this 
function BCORE:GetData( sid, name, bool ) // sid, filename, istable(bool)
    local a = self:ParseKey( sid )
    local path = ( "BCORE/" .. a .. "/" )
    path = ( path .. name .. ".dat" )
    if file.Exists( path, "DATA" ) then
        local r = file.Read( path, "DATA" )
        return ( bool and util.JSONToTable( r ) or r )
    end
    return false
end