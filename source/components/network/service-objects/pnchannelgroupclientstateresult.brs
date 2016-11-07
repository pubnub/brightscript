' brief:      Client state information object (for channel group).
' discussion: Object used by PubNub client to represent requested remote client presence state.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNChannelGroupClientStateResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {channels: PNObject(response.channels).default({})}
    
    return this
end function
