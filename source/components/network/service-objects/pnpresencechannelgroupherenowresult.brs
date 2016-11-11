' brief:      Channel group presence information object.
' discussion: Object used by PubNub client to represent channel group's presence information.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNPresenceChannelGroupHereNowResult(request as Object) as Object    
    return PNPresenceGlobalHereNowResult(request)
end function
