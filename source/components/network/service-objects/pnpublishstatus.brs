' brief:      Data publish results object.
' discussion: Object used by PubNub client to represent status of data publish to remote data 
'             consumers.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNPublishStatus(request as Object) as Object
    this = PNAcknowledgmentStatus(request)
    response = PNObject(this.private.response).default({})
    this.data = {
        timetoken: PNObject(response.timetoken).default(0)
        information: PNObject(response.information).default("No Information")
    }

    return this
end function
