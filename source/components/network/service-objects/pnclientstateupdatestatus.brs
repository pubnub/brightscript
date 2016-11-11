' brief:      Client state information update results object.
' discussion: Object used by PubNub client to represent results of client' presence state 
'             modification.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNClientStateUpdateStatus(request as Object) as Object
    this = PNErrorStatus(request)
    response = PNObject(this.private.response).default({})
    this.data = {state: PNObject(response.state).default({})}
    
    return this
end function
