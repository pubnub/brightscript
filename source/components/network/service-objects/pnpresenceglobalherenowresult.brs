' brief:      Global presence information object.
' discussion: Object used by PubNub client to represent global presence information.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNPresenceGlobalHereNowResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {
        channels: PNObject(response.channels).default({})
        totalChannels: PNObject(response.totalChannels).default(0)
        totalOccupancy: PNObject(response.totalOccupancy).default(0)
    }
    
    return this
end function
