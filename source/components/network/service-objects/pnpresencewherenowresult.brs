' brief:      Remote client's presence information object.
' discussion: Object used by PubNub client to represent list of channels on which subscribed 
'             specified remote user.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNPresenceWhereNowResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {channels: PNObject(response.channels).default([])}

    return this
end function
