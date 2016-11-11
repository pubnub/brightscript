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
sub PNHistory(params as Object, callback as Function, context = invalid as Dynamic)
    ' Default values initialization
    pn_historyDefaults(params)
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_historyRequest(params)
    request.operation = PNOperationType().PNHistoryOperation
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "history"}
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
function pn_historyRequest(params as Object) as Object
    request = {path:{}, query: {count: params.count, "include_token": true}}
    if params.reverse <> invalid then request.query.reverse = params.reverse
    if params["start"] <> invalid then request.query["start"] = params["start"]
    if params["end"] <> invalid then request.query["end"] = params["end"]
    if PNString(params.channel).isEmpty() = false then request.path["{channel}"] = PNString(params.channel).escape()
    
    return request
end function

' brief:  Default values initialization.
'
' params  Object with values which should be used with API call.
'
sub pn_historyDefaults(params as Object)
    if PNNumber(params.includeTimetoken).isBoolean() = false then params.includeTimetoken = false
    if params["start"] <> invalid AND params["end"] <> invalid then
        if params["start"] > "0" AND params["end"] > "0" AND params["start"] > params["end"] then
            start = ""+params["start"]
            params["start"] = params["end"]
            params["end"] = start
        end if
    end if
    if params.count <> invalid then params.count = PNNumber().min(100, params.count) else params.count = 100
end sub
