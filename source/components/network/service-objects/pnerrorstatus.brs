' brief:      Error object.
' discussion: Base object which is used to represent API call failure and contain failure reason.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNErrorStatus(request as Object) as Object
    this = {associatedObject: invalid}
    this.append(PNStatus(request))
    response = PNObject(this.private.response).default({})
    this.errorData = {
        channels: PNObject(response.channels).default([])
        channelGroups: PNObject(response.channelGroups).default([])
        information: PNObject(response.information).default("No Error Information")
        data: response.data
    }
    
    return this
end function
