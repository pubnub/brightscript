' brief:      Channel group audition result object.
' discussion: Object used by PubNub client to represent list of channels which has been registered 
'             with specified group name.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNChannelGroupChannelsResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {channels: PNObject(response.channels).default([])}
    
    return this
end function
