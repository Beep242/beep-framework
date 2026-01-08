//Vectivus made this 
function BCORE:ParseKey( k )
    local a = string.lower( k )
    a = string.Replace( a, ":", "_" )
    return a
end

function BCORE:SaveData( sid, name, data, bool ) // sid, filename, data, istable(bool)
    local a = self:ParseKey( sid )
    file.CreateDir( "BCORE" )
    file.CreateDir( "BCORE/" .. a )
    local path = ( "BCORE/" .. a .. "/" )
    path = ( path .. name .. ".dat" )
    file.Write( path, ( bool and util.TableToJSON( data, true ) or data ) )
end


util.AddNetworkString( "BCORE.Chat" )
function BCORE:AddText( p, txt )
    if !IsValid( p ) then return end
    if !txt then return end
    net.Start( "BCORE.Chat" )
        net.WriteString( txt )
    net.Send( p )
end