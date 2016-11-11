' brief:      User's presence information access API.
' discussion: API allow to receive information about channels to which remote user subscribed now.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
sub PNPresenceWhereNow(params as Object, callback as Function, context = invalid as Dynamic)
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_presenceWhereNowRequest(params)
    request.operation = PNOperationType().PNWhereNowOperation
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "whereNow"}
    m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, invalid)
end sub


REM ******************************************************
REM
REM Private functions
REM
REM ******************************************************

' brief:  Prepare information which should be used during REST API call URL preparation.
'
' params  Object with values which should be used with API call.
function pn_presenceWhereNowRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.uuid).isEmpty() = false then request.path["{uuid}"] = PNString(params.uuid).escape()
    
    return request
end function
