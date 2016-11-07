' brief:      Channel(s) and group(s) presence information access API.
' discussion: Depending from configuration passed in 'params' PubNub client will retrieve presence
'             information for single channel or group of channels. Additionally data verbosity can
'             be changed by providing values for 'includeUUIDs' (whether response should include
'             unique user identifiers or only number of participants) and 'includeState' (whether
'             user's state information should be fetched or not).
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
'
sub PNPresenceHereNow(params as Object, callback as Function, context = invalid as Dynamic)
    ' Default values initialization
    pn_presenceHereNowDefaults(params)
    operation = PNOperationType().PNHereNowGlobalOperation
    if PNString(params.channel).isEmpty() = false then
        operation = PNOperationType().PNHereNowForChannelOperation
    else if PNString(params.group).isEmpty() = false then
        operation = PNOperationType().PNHereNowForChannelGroupOperation
    end if
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_presenceHereNowRequest(params)
    request.operation = operation
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "presence.hereNow"}
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
function pn_presenceHereNowRequest(params as Object) as Object
    request = {path:{}, query: {"disable_uuids": "1", "state": "0"}}
    if params.includeUUIDs = true then request.query["disable_uuids"] = "0"
    if params.includeState = true then request.query.state = "1"
    if PNString(params.channel).isEmpty() = false then
        request.path["{channel}"] = PNString(params.channel).escape()
    else if PNString(params.group).isEmpty() = false then
        request.path["{channel}"] = ","
        request.query["channel-group"] = PNString(params.group).escape()
    end if
    
    return request
end function

' brief:  Default values initialization.
'
' params  Object with values which should be used with API call.
'
sub pn_presenceHereNowDefaults(params as Object)
    if type(params.includeUUIDs) <> "Boolean" then params.includeUUIDs = true
    if type(params.includeState) <> "Boolean" then params.includeState = true
    if params.includeUUIDs = false AND params.includeState = true then params.includeUUIDs = true
end sub
