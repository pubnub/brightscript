function PNPNHeartbeatManager(configuration as Object, networkManager as Object, listenerManager as Object, stateManager as Object) as Object
    this = {private: {config: configuration, shouldHandleRunLoopMessages: true}}
    this.private.handleHeartbeatTimer = pn_heartbeatHandleTimer
    
    this.private.networkManager = networkManager
    this.private.listenerManager = listenerManager
    this.private.stateManager = stateManager
    this.private.setSubscribeManager = pn_heartbeatManagerSetSubscribeManager
    
    this.startHeartbeatIfRequired = pn_heartbeatManagerStartIfRequired
    this.stopHeartbeatIfPossible = pn_heartbeatManagerStopIfPossible
    this.handleMessage = pn_heartbeatManagerHandleMessage
    this.destroy = pn_heartbeatManagerDestroy
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

sub pn_heartbeatManagerSetSubscribeManager(subscribeManager as Object)
    m.subscribeManager = subscribeManager
end sub

function pn_heartbeatManagerStartIfRequired()
    m.stopHeartbeatIfPossible()
    
    ' Check whether client configured for heartbeat sending or not.
    if PNObject(m.private.config.presenceHeartbeatInterval).default(0) > 0 then
        m.private.clock = PNTimer(m.private.config.presenceHeartbeatInterval, m, m.private.handleHeartbeatTimer, true)
        m.private.clock.start()
    end if
end function

function pn_heartbeatManagerStopIfPossible()
    if m.private.clock <> invalid then m.private.clock.invalidate()
    m.private.delete("clock")
end function

sub pn_heartbeatManagerHandleMessage(message = invalid as Dynamic)
    if m.private.shouldHandleRunLoopMessages = true then
        if m.private.clock <> invalid then m.private.clock.tick()
    end if
end sub

sub pn_heartbeatHandleTimer(context)
    privateData = context.private
    objects = PNChannel().objectsWithOutPresenceFrom(privateData.subscribeManager.private.allObjects())
    if PNObject(objects).default([]).count() > 0 AND PNObject(privateData.config.presenceHeartbeatValue).default(0) > 0 then 
        channels = privateData.subscribeManager.channels()
        groups = privateData.subscribeManager.channelGroups()
        
        ' Prepare information which should be used during REST API call URL preparation.
        request = {path:{}, query: {}, operation: PNOperationType().PNHeartbeatOperation}
        request.path["{channels}"] = PNChannel().namesForRequestWithDefaultValue(channels, ",")
        if groups.count() > 0 then request.query["channel-group"] = PNChannel().namesForRequest(channelGroups)
        request.query["heartbeat"] = privateData.config.presenceHeartbeatValue
        
        state = privateData.stateManager.state()
        if state <> invalid then
            stateString = formatJSON(state)
            if PNString(stateString).isEmpty() = false then request.query["state"] = PNString(stateString).escape()
        end if
        
        callbackData = {context: context}
        privateData.networkManager.processOperation(request.operation, request, invalid, callbackData, pn_heartbeatManagerHandleOperationStatus)
    else
        context.stopHeartbeatIfPossible()
    end if
end sub

' brief:  Handle heartbeat request processing results.
'
' status  Reference on API calling status object.
' data    Reference on object which contain information which is required to retry API call.
'
sub pn_heartbeatManagerHandleOperationStatus(status = invalid as Dynamic, data = {} as Object)
    privateData = data.context.private
    config = privateData.config
    if config.notifyHeartbeatFailure = true OR config.notifyHeartbeatSuccess = true then
        shouldNotify = status.error = true AND config.notifyHeartbeatFailure = true
        if shouldNotify = true OR status.error = false AND config.notifyHeartbeatSuccess = true
            privateData.listenerManager.announceStatus(status)
        end if
    end if
end sub

sub pn_heartbeatManagerDestroy()
    m.private.shouldHandleRunLoopMessages = false
    m.stopHeartbeatIfPossible()
    m.private.networkManager = invalid
    m.private.subscribeManager = invalid
    m.private.listenerManager = invalid
    m.private.stateManager = invalid
end sub
