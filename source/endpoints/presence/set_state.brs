' brief:      Update client's state information.
' discussion: API allow to manage small piece of data which is available for remote clients via 
'             presence API. This data is sent by PubNub's presence service along with remote user 
'             presence change event.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
'
sub PNPresenceSetState(params as Object, callback = invalid as Function, context = invalid as Dynamic)
    ' Default values initialization
    if type(callback) = "<uninitialized>" then callback = invalid
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_presenceSetStateRequest(params)
    request.operation = PNOperationType().PNSetStateOperation
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "setState"}
    m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, pn_presenseSetStateHandler)
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
function pn_presenceSetStateRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.channel).isEmpty() = false OR PNString(params.group).isEmpty() = false then
        if PNString(params.channel).isEmpty() = false then
            request.path["{channel}"] = PNString(params.channel).escape()
        else if PNString(params.group).isEmpty() = false then
            request.path["{channel}"] = ","
            request.query["channel-group"] = PNString(params.group).escape()
        end if
        if PNString(params.uuid).isEmpty() = false then request.path["{uuid}"] = params.uuid
        stateString = invalid
        if params.state <> invalid then stateString = formatJSON(params.state)
        if PNString(stateString).isEmpty() = false then request.query["state"] = PNString(stateString).escape() else request.query["state"] = "{}"
    end if

    return request
end function


REM ******************************************************
REM
REM Handlers
REM
REM ******************************************************

' brief:       Handle client's state modification completion.
' discussion:  Additional processing required to keep state manager in sync with states which is 
'              set by user. State used with subscription to channels and groups.
'
' status  Reference on API calling status object.
' data    Reference on object which contain information which is required to retry API call.
'
sub pn_presenseSetStateHandler(status = invalid as Dynamic, data = {} as Object)
    if status <> invalid AND status.error = false then
        clientUUID = data.client.private.config.uuid
        uuid = data.params.uuid
        obj = PNObject(data.params.channel).default(data.params.group)
        if PNString(clientUUID).isEmpty() = false AND PNString(uuid).isEmpty() = false AND clientUUID = uuid then
            data.client.private.stateManager.setState(PNObject(status.data.state).default({}), obj)
        end if
    end if
    
    pn_networkingDefaultStatusHandler(status, data)
end sub
