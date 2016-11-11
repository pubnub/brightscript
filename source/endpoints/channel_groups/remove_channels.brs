' brief:      Remove existing channels from group managed by 'stream controller'.
' discussion: 'Remove' list of channels from channel group.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status object handling.
'
sub PNChannelGroupRemoveChannels(params as Object, callback = invalid as Dynamic, context = invalid as Dynamic)
    ' Default values initialization
    if type(callback) = "<uninitialized>" then callback = invalid
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_channelGroupRemoveChannelRequest(params)
    request.operation = PNOperationType().PNRemoveChannelsFromGroupOperation
    
    if PNArray(params.channels).isEmpty() = false then
        callbackData = {callback: callback, context: context, params: params, client: m, func: "removeChannels"}
        m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, invalid)
    else
        ?"{WARN} Empty list of channels provided - this may lead for whole group deletion. Please use appropriate API call to explicitly delete group."
    end if
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
function pn_channelGroupRemoveChannelRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.group).isEmpty() = false then request.path["{channel-group}"] = PNString(params.group).escape()
    if PNArray(params.channels).isEmpty() = false then
        request.query["remove"] = PNChannel().namesForRequest(params.channels)
    end if
    
    return request
end function
