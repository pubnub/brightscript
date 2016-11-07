' brief:      Client subscription state change object.
' discussion: Object used by PubNub client to represent changes of client's subscription state.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNSubscribeStatus(request as Object) as Object
    ' Current client state will be provided by subscribe manager.
    this = {
        currentTimetoken: invalid
        lastTimeToken: invalid
        subscribedChannels: invalid
        subscribedChannelGroups: invalid
    }
    this.append(PNErrorStatus(request))
    response = PNObject(this.private.response).default({})
    this.data = {
        channel: response.channel
        subscription: response.subscription
        timetoken: PNObject(response.timetoken).default("0")
        region: PNObject(response.region).default(0)
        envelope: response.envelope
    }
    this.data.userMetadata = PNObject(this.private.response).valueAtKeyPath("envelope.metadata")
    
    return this
end function
