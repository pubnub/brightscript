' brief:      Add channels to channel group managed by 'stream controller'.
' discussion: 'Add' new list of channels to channel group.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status object handling.
'
sub PNChannelGroupAddChannels(params as Object, callback = invalid as Dynamic, context = invalid as Dynamic)
    ' Default values initialization
    if type(callback) = "<uninitialized>" then callback = invalid
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_channelGroupAddChannelsRequest(params)
    request.operation = PNOperationType().PNAddChannelsToGroupOperation
    
    if PNArray(params.channels).isEmpty() = false then
        callbackData = {callback: callback, context: context, params: params, client: m, func: "addChannels"}
        m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, invalid)
    else
        ?"{INFO} There is no channels to add."
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
function pn_channelGroupAddChannelsRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.group).isEmpty() = false then request.path["{channel-group}"] = PNString(params.group).escape()
    if PNArray(params.channels).isEmpty() = false then
        request.query["add"] = PNChannel().namesForRequest(params.channels)
    end if
    
    return request
end function
