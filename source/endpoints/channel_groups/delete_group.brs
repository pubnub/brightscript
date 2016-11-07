' brief:      Existing channel group removal from 'stream controller'.
' discussion: 'Remove' existing channel group by it's name.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status object handling.
'
sub PNChannelGroupDeleteGroup(params as Object, callback = invalid as Dynamic, context = invalid as Dynamic)
    ' Default values initialization
    if type(callback) = "<uninitialized>" then callback = invalid
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_channelGroupDeleteGroupRequest(params)
    request.operation = PNOperationType().PNRemoveGroupOperation

    callbackData = {callback: callback, context: context, params: params, client: m, func: "streamController.deleteGroup"}
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
'
function pn_channelGroupDeleteGroupRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.group).isEmpty() = false then request.path["{channel-group}"] = PNString(params.group).escape()
    
    return request
end function
