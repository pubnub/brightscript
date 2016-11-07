' brief:      Channel presence information object.
' discussion: Object used by PubNub client to represent channel presence information.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNPresenceChannelHereNowResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {uuids: response.uuids, occupancy: PNObject(response.occupancy).default(0)}
    
    return this
end function
