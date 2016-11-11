' brief:      List channel group's channels managed by 'stream controller'.
' discussion: Retrieve list of all channels which has been registered with channel group by it's 
'             name.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
'
sub PNChannelGroupListChannels(params as Object, callback as Function, context = invalid as Dynamic)
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_channelGroupListChannelsRequest(params)
    request.operation = PNOperationType().PNChannelsForGroupOperation

    callbackData = {callback: callback, context: context, params: params, client: m, func: "listChannels"}
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
function pn_channelGroupListChannelsRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.group).isEmpty() = false then request.path["{channel-group}"] = PNString(params.group).escape()
    
    return request
end function
