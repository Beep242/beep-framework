//Vectivus made this
function BCORE:ParseKey( rawKey )
    local safeKey = string.lower( rawKey )
    safeKey = string.Replace( safeKey, ":", "_" )
    return safeKey
end

function BCORE:SaveData( storageID, fileName, data, encodeAsJSON )
    local safeID = self:ParseKey( storageID )
    file.CreateDir( "BCORE" )
    file.CreateDir( "BCORE/" .. safeID )
    local path = ( "BCORE/" .. safeID .. "/" )
    path = ( path .. fileName .. ".dat" )
    file.Write( path, ( encodeAsJSON and util.TableToJSON( data, true ) or data ) )
end


util.AddNetworkString( "BCORE.Chat" )
function BCORE:AddText( ply, message )
    if !IsValid( ply ) then return end
    if !message then return end
    net.Start( "BCORE.Chat" )
        net.WriteString( message )
    net.Send( ply )
end