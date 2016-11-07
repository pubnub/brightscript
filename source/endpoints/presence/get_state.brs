' brief:      Audit client's state information.
' discussion: API allow to audit small piece of data which has been sent by remote user during 
'             subscription or presence information API usage.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
'
sub PNPresenceGetState(params as Object, callback as Function, context = invalid as Dynamic)
    ' Default values initialization
    operation = PNOperationType().PNStateForChannelOperation
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_presenceGetStateRequest(params)
    if request.path["{channel}"] = "," then operation = PNOperationType().PNStateForChannelGroupOperation
    request.operation = operation
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "presence.getState"}
    m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, pn_presenseGetStateHandler)
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
function pn_presenceGetStateRequest(params as Object) as Object
    request = {path:{}, query: {}}
    if PNString(params.channel).isEmpty() = false OR PNString(params.group).isEmpty() = false then
        if PNString(params.channel).isEmpty() = false then
            request.path["{channel}"] = PNString(params.channel).escape()
        else if PNString(params.group).isEmpty() = false then
            request.path["{channel}"] = ","
            request.query["channel-group"] = PNString(params.group).escape()
        end if
        if PNString(params.uuid).isEmpty() = false then request.path["{uuid}"] = params.uuid
    end if

    return request
end function


REM ******************************************************
REM
REM Handlers
REM
REM ******************************************************

' brief:       Handle client's state audition completion.
' discussion:  Additional processing required to keep state manager in sync because of potential 
'              remote client's state modification. State used with subscription to channels and 
'              groups.
'
' status  Reference on API calling status object.
' data    Reference on object which contain information which is required to retry API call.
'
sub pn_presenseGetStateHandler(result = invalid as Dynamic, status = invalid as Dynamic, data = {} as Object)
    if result <> invalid AND result.operation = PNOperationType().PNStateForChannelOperation then
        clientUUID = data.client.private.config.uuid
        uuid = data.params.uuid
        obj = PNObject(data.params.channel).default(data.params.group)
        if PNString(clientUUID).isEmpty() = false AND PNString(uuid).isEmpty() = false AND clientUUID = uuid then
            data.client.private.stateManager.setState(PNObject(result.data.state).default({}), obj)
        end if
    end if
    
    pn_networkingDefaultResultHandler(result, status, data)
end sub
