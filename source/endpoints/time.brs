' brief:  Retrieve PubNub's current time information.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
'
sub PNTime(params as Object, callback as Function, context = invalid as Dynamic)
    ' Prepare information which should be used during REST API call URL preparation.
    request = {path:{}, query: {}, operation: PNOperationType().PNTimeOperation}
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "time"}
    m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, invalid)
end sub
