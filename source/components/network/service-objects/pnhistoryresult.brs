' brief:      History results object.
' discussion: Object used by PubNub client to represent loaded channel's history.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNHistoryResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {
        messages: PNObject(response.messages).default([])
        "start": PNObject(response.start).default(0)
        "end": PNObject(response["end"]).default(0)
    }
    
    return this
end function
