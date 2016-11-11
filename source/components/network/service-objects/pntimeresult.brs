' brief:      PubNub timetoken result object.
' discussion: Object used by PubNub client to represent current time on PubNub servers as timetoken.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNTimeResult(request as Object) as Object
    this = PNResult(request)
    response = PNObject(this.private.response).default({})
    this.data = {timetoken: PNObject(response.timetoken).default("0")}
    
    return this
end function
