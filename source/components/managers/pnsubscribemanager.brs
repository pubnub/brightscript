Function PNSubscribeManager(config as Object, networkManager as Object, listenerManager as Object, stateManager as Object, heartbeatManager as Object) as Object
    this = {
        private: {
            config: config
            channels: []
            presenceChannels: []
            channelGroups: []
            presenceChannelGroups: []
            filterExpression: invalid
            escapedFilterExpression: invalid
            shouldHandleRunLoopMessages: true
            readyForNextSubscriptionLoop: false
            nextSubscriptionLoopAsinitial: false
            currentTimeToken: "0"
            lastTimeToken: invalid
            currentTimeTokenRegion: invalid
            lastTimeTokenRegion: invalid
            overrideTimetoken: invalid
            mayRequireSubscriptionRestore: false
            state: "initialized"
            
            retryTimer: invalid
            shouldRetrySubscription: false
            
            networkManager: networkManager
            listenerManager: listenerManager
            stateManager: stateManager
            heartbeatManager: heartbeatManager
        }
        channels: function():return m.private.channels:end function
        channelGroups: function():return m.private.channelGroups:end function
    }

    this.private.addChannels = pn_subscriptionManagerAddChannels
    this.private.removeChannels = pn_subscriptionManagerRemoveChannels
    this.private.channelObjects = pn_subscriptionManagerAllChannelObjects

    this.private.addChannelGroups = pn_subscriptionManagerAddChannelGroups
    this.private.removeChannelGroups = pn_subscriptionManagerRemoveChannelGroups
    this.private.channelGroupObjects = pn_subscriptionManagerAllChannelGroupObjects
    
    this.private.subscribeRequest = pn_subscriptionManagerSubscribeRequest
    this.private.startRetryTimer = pn_subscriptionManagerStartRetryTimer
    this.private.stopRetryTimer = pn_subscriptionManagerStopRetryTimer
    this.private.handleRetryTimer = pn_subscriptionManagerHandleRetryTimer

    this.private.allObjects = pn_subscriptionManagerAllObjects

    this.presenceEnabledForChannel = pn_subscriptionManagerPresenceEnabledForChannel
    this.presenceEnabledForChannelGroup = pn_subscriptionManagerPresenceEnabledForChannelGroup

    this.subscribe = pn_subscriptionManagerSubscribe
    this.cancelSubscriptionRetry = pn_subscriptionManagerCancelSubscriptionRetry

    this.unsubscribe = pn_subscriptionManagerUnsubscribe
    this.unsubscribeAll = pn_subscriptionManagerUnsubscribeFromAll
    
    this.handleMessage = pn_subscriptionManagerHandleMessage
    this.destroy = pn_subscriptionManagerDestroy

    return this
end function


'******************************************************
'
' Public API
'
'******************************************************

sub pn_subscriptionManagerSubscribe(params as Object, initialSubscribe = true as Boolean, callback = invalid as Dynamic)
    ' Initialize default values.
    if type(callback) = "<uninitialized>" then callback = invalid
    
    ' Break subscription loop and stop subscription retry timer.
    m.private.readyForNextSubscriptionLoop = false
    m.private.nextSubscriptionLoopAsinitial = false
    m.private.stopRetryTimer()
    
    ' Ensure what there is some data objects to which client should be able to subscribe
    if m.private.allObjects().count() > 0 then
        m.private.overrideTimetoken = params.timetoken
        if PNString(params.filterExpression).isEmpty() = false then
            m.private.filterExpression = params.filterExpression
            m.private.escapedFilterExpression = PNString(params.filterExpression).escape()
        end if
        if initialSubscribe = true then
            m.private.mayRequireSubscriptionRestore = false
            if PNObject(m.private.currentTimeToken).default("0") > "0" then
                m.private.lastTimeToken = m.private.currentTimeToken
            end if
            if PNObject(m.private.currentTimeTokenRegion).default(0) > 0 then
                m.private.lastTimeTokenRegion = m.private.currentTimeTokenRegion
            end if
            m.private.currentTimeToken = "0"
            m.private.currentTimeTokenRegion = invalid
        end if

        ' Configure subscribe request
        request = m.private.subscribeRequest(params)
        request.operation = PNOperationType().PNSubscribeOperation
        callbackData = {callback: callback, context: m, params: params, client: invalid, func: "subscribe"}
        callbackData.initialSubscribe = initialSubscribe
        m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, pn_subscriptionManagerSubscribeHandler)
    else
        emptyRequest = PNRequest()
        emptyRequest.setUserInfo({
            operation: PNOperationType().PNSubscribeOperation
            category: PNStatusCategory().PNDisconnectedCategory
            handleResponse: false
        })
        status = PNStatus(emptyRequest)
        status.append(m.private.networkManager.private.clientInformation())
        m.private.currentTimeToken = "0"
        m.private.lastTimeToken = "0"
        m.private.currentTimeTokenRegion = invalid
        m.private.lastTimeTokenRegion = invalid
        
        if callback <> invalid then callback(status)
        pn_subscriptionManagerHandleStateChange(status, "disconnected", {context: m})
        m.private.networkManager.private.cancelSubscriptionRequest()
    end if
end sub

sub pn_subscriptionManagerUnsubscribeFromAll()
    unsubscriptionCallback = function(data as Object)
        channelGroups = data.context.private.channelGroupObjects()
        data.context.unsubscribe({channelGroups: channelGroups, informingListener: true, subscribeOnRest: false})
    end function
    
    if m.private.channelObjects().count() > 0 then
        hasChannelGroups = m.private.channelGroupObjects().count() > 0
        if hasChannelGroups = false then channelsUnsubscriptionCallback = invalid
        objects = PNObject(m.private.channelObjects()).copy()
        m.removeChannels(objects, true)
        m.unsubscribe({channels: objects, informingListener: hasChannelGroups = false, subscribeOnRest: false}, unsubscriptionCallback)
    else if m.private.channelGroupObjects().count() > 0 then
        unsubscriptionCallback({context: m})
    end if
end sub

sub pn_subscriptionManagerUnsubscribe(params as Object, callback = invalid as Dynamic) 
    ' Initialize default values.
    if type(callback) = "<uninitialized>" then callback = invalid
    
    ' Break subscription loop and stop subscription retry timer.
    m.private.readyForNextSubscriptionLoop = false
    m.private.nextSubscriptionLoopAsinitial = false
    
    m.private.stateManager.removeStateForObjects(params.channels)
    m.private.stateManager.removeStateForObjects(params.channelGroups)
    channels = PNChannel().objectsWithOutPresenceFrom(params.channels)
    channelGroups = PNChannel().objectsWithOutPresenceFrom(params.channelGroups)
    emptyRequest = PNRequest()
    emptyRequest.setUserInfo({
        operation: PNOperationType().PNUnsubscribeOperation
        category: PNStatusCategory().PNAcknowledgmentCategory
        handleResponse: false
    })
    successStatus = PNStatus(emptyRequest)
    successStatus.append(m.private.networkManager.private.clientInformation())
    
    subscriptionObjects = PNObject(m.private.allObjects()).default([])
    if subscriptionObjects.count() = 0 then
        m.private.currentTimeToken = "0"
        m.private.lastTimeToken = "0"
        m.private.currentTimeTokenRegion = invalid
        m.private.lastTimeTokenRegion = invalid
    end if
    
    if subscriptionObjects.count() > 0 then
        channelsList = PNChannel().namesForRequestWithDefaultValue(channels, ",")
        groupsList = PNChannel().namesForRequest(channelGroups)

        ' Configure unsubscribe request
        request = {path:{"{channels}": channelsList}, query: {}}
        if channelsList = invalid AND groupsList <> invalid then request.query["channel-group"] = groupsList
        request.operation = PNOperationType().PNUnsubscribeOperation
        callbackData = {callback: callback, context: m, params: params, allObjects: PNObject(subscriptionObjects).copy()}
        m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, pn_subscriptionManagerUnsubscribeHandler)
    else
        subscribeCallback = function(status = invalid as Dynamic, data = {} as Object)
            if data.callback <> invalid then data.callback(data)
            if PNObject(data.params.informingListener).default(true) = true then
                successStatus = data.successStatus
                data.delete("successStatus")
                pn_subscriptionManagerHandleStateChange(data.successStatus, "disconnected", {context: data})
            end if
        end function
        m.subscribe({callback: callback, context: m, params: params, successStatus: successStatus}, true, subscribeCallback)
    end if
end sub


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Prepare information which should be used during REST API call URL preparation.
'
' params  Object with values which should be used with API call.
'
function pn_subscriptionManagerSubscribeRequest(params as Object) as Object
    request = {path:{}, query: {}}
    allObjects = m.allObjects()
    channelsList = PNChannel().namesForRequestWithDefaultValue(m.channelObjects(), ",")
    groupsList = PNChannel().namesForRequest(m.channelGroupObjects())
    mergedState = m.stateManager.stateMergedWith(params.state, allObjects)
    m.stateManager.mergeWithState(mergedState, allObjects)
    request.path["{channels}"] = channelsList
    request.query["tt"] = m.currentTimeToken
    if m.currentTimeTokenRegion <> invalid then request.query["tr"] = m.currentTimeTokenRegion
    if PNObject(m.config.presenceHeartbeatInterval).default(0) > 0 then
        request.query["heartbeat"] = m.config.presenceHeartbeatInterval
    end if
    if PNString(groupsList).isEmpty() = false then request.query["channel-group"] = groupsList
    if mergedState <> invalid AND mergedState.count() > 0 then
        mergedStateString = formatJSON(mergedState)
        if PNString(mergedStateString).isEmpty() = false then request.query["state"] = PNString(mergedStateString).escape()
    end if
    
    if PNString(m.escapedFilterExpression).isEmpty() = false then 
        request.query["filter-expr"] = m.escapedFilterExpression
    end if
    request.query["string_message_token"] = "true"
    
    return request
end function

' brief:      Launch subscription retry timer.
' discussion: Launch timer with default 1 second interval after each subscribe attempt. In most of 
'             cases timer used to retry subscription after PubNub Access Manager denial because of 
'             client doesn't has enough rights.
'
sub pn_subscriptionManagerStartRetryTimer()
    m.stopRetryTimer()
    m.retryTimer = PNTimer(1, {context: m}, m.handleRetryTimer, false)
    m.retryTimer.start()
end sub

' brief:      Terminate previously launched subscription retry counter.
' discussion: In case if another subscribe request from user client better to stop retry timer to 
'             eliminate race of conditions.
'
sub pn_subscriptionManagerStopRetryTimer()
    if m.retryTimer <> invalid then m.retryTimer.invalidate()
    m.delete("retryTimer")
    m.shouldRetrySubscription = false
end sub

sub pn_subscriptionManagerCancelSubscriptionRetry()
    m.private.stopRetryTimer()
end sub


REM ******************************************************
REM
REM Data objects management
REM
REM ******************************************************

function pn_subscriptionManagerAddChannels(channels = invalid as Dynamic, withPresence = false as Boolean)
    if PNArray(channels).isArray() = true then
        for each channel in channels
            isPresenceChannel = PNString(channel).hasSuffix("-pnpres")
            if isPresenceChannel = true then objects = m.presenceChannels else objects = m.channels
            if withPresence = true AND isPresenceChannel = false then
                presenceChannel = channel + "-pnpres"
                if PNArray(m.presenceChannels).contains(presenceChannel) = false then
                    m.presenceChannels.push(presenceChannel)
                end if
            end if
            if PNArray(objects).contains(channel) = false then objects.push(channel)
        end for
    end if
end function

function pn_subscriptionManagerRemoveChannels(channels = invalid as Dynamic, withPresence = false as Boolean)
    if PNArray(channels).isArray() = true then
        for each channel in channels
            isPresenceChannel = PNString(channel).hasSuffix("-pnpres")
            if isPresenceChannel = true then objects = m.presenceChannels else objects = m.channels
            if withPresence = true AND isPresenceChannel = false then
                presenceChannel = channel + "-pnpres"
                PNArray(m.presenceChannels).delete(presenceChannel)
            end if
            PNArray(objects).delete(channel)
        end for
    end if
end function

function pn_subscriptionManagerPresenceEnabledForChannel(channel as String) as Boolean
    return PNArray(m.private.presenceChannels).contains(channel + "-pnpres")
end function

function pn_subscriptionManagerAllChannelObjects() as Object
    objects = []
    objects.append(m.channels)
    objects.append(m.presenceChannels)

    return objects
end function

function pn_subscriptionManagerAddChannelGroups(groups = invalid as Dynamic, withPresence = false as Boolean)
    if PNArray(groups).isArray() = true then
        for each group in groups
            isPresenceGroup = PNString(group).hasSuffix("-pnpres")
            if isPresenceGroup = true then objects = m.presenceChannelGroups else objects = m.channelGroups
            if withPresence = true AND isPresenceGroup = false then
                presenceGroup = group + "-pnpres"
                if PNArray(m.presenceChannelGroups).contains(presenceGroup) = false then
                    m.presenceChannelGroups.push(private.presenceChannelGroups)
                end if
            end if
            if PNArray(objects).contains(group) = false then objects.push(group)
        end for
    end if
end function

function pn_subscriptionManagerRemoveChannelGroups(groups as Object, withPresence as Boolean)
    if PNArray(groups).isArray() = true then
        for each group in groups
            isPresenceGroup = PNString(group).hasSuffix("-pnpres")
            if isPresenceGroup = true then objects = m.presenceChannelGroups else objects = m.channelGroups
            if withPresence = true AND isPresenceGroup = false then
                presenceGroup = group + "-pnpres"
                PNArray(m.presenceChannelGroups).delete(presenceGroup)
            end if
            PNArray(objects).delete(group)
        end for
    end if
end function

function pn_subscriptionManagerPresenceEnabledForChannelGroup(channelGroup as String) as Boolean
    return PNArray(m.private.presenceChannelGroups).contains(channelGroup + "-pnpres")
end function

function pn_subscriptionManagerAllChannelGroupObjects() as Object
    objects = []
    objects.append(m.channelGroups)
    objects.append(m.presenceChannelGroups)

    return objects
end function

function pn_subscriptionManagerAllObjects() as Object
    objects = []
    objects.append(m.channelObjects())
    objects.append(m.channelGroupObjects())

    return objects
end function


'******************************************************
'
' Handlers
'
'******************************************************

' brief:      Handle single 'run-loop tick'.
' discussion: Function called by PubNub client on every 'run-loop tick' to check whether some 
'             scheduled data retrieval arrived and should be processed or not.
'
' message  Reference on event/message received from messages port object at 'run-loop tick'.
' 
sub pn_subscriptionManagerHandleMessage(message = invalid as Dynamic)
    if m.private.shouldHandleRunLoopMessages = true then
        if m.private.retryTimer <> invalid then m.private.retryTimer.tick()
        if m.private.readyForNextSubscriptionLoop = true OR m.private.shouldRetrySubscription = true then
            m.subscribe({}, m.private.nextSubscriptionLoopAsinitial)
        end if
    end if
end sub

' brief:       Handle subscription request completion completion.
' discussion:  Handler additionally process received data and prepare manager for next subscription
'              loop (if no failure has been found).
'
' status  Reference on API calling status object.
' data    Reference on object which contain information which is required to retry API call.
'
sub pn_subscriptionManagerSubscribeHandler(status = invalid as Dynamic, data = {} as Object)
    pn_subscriptionManagerSubsciptionStatusHandle(status, data)
    if data.callback <> invalid then
        if data.context <> invalid then data.callback(status, data.context) else data.callback(status)
    end if
end sub

sub pn_subscriptionManagerSubsciptionStatusHandle(status as Object, data as Object)
    data.context.private.stopRetryTimer()
    if status.error = false AND status.category <> PNStatusCategory().PNCancelledCategory then
        pn_subscriptionManagerHandleSuccessSubscriptionStatus(status, data)
    else
        pn_subscriptionManagerHandleFailedSubscriptionStatus(status, data)
    end if
end sub

sub pn_subscriptionManagerHandleSuccessSubscriptionStatus(status as Object, data as Object)
    initial = data.initialSubscribe
    if status.data.timetoken <> invalid AND status.request <> invalid then
        tokenInformation = "Did receive next subscription loop information: timetoken = "+status.data.timetoken+", region = "+box(status.data.region).toStr()
        ?tokenInformation
        pn_subscriptionManagerHandleSubscriptionToken(status, data)
    end if
    pn_subscriptionManagerHandleLiveFeedEvents(status, data)
    data.context.private.readyForNextSubscriptionLoop = true
    data.context.private.nextSubscriptionLoopAsinitial = false
    data.context.private.heartbeatManager.startHeartbeatIfRequired()
    if initial then pn_subscriptionManagerHandleStateChange(status, "connected", data)
end sub

sub pn_subscriptionManagerHandleFailedSubscriptionStatus(status as Object, data as Object)
    privateData = data.context.private
    if status.category = PNStatusCategory().PNCancelledCategory then
        privateData.heartbeatManager.stopHeartbeatIfPossible()
    else
        categories = PNStatusCategory()
        autoretryEnabled = [
            categories.PNAccessDeniedCategory
            categories.PNTimeoutCategory
            categories.PNMalformedFilterExpressionCategory
            categories.PNMalformedResponseCategory
            categories.PNTLSConnectionFailedCategory
        ]
        if PNArray(autoretryEnabled).contains(status.category) = true then
            status.automaticallyRetry = status.category <> categories.PNMalformedFilterExpressionCategory
            if status.automaticallyRetry = true then privateData.startRetryTimer()
            
            subscriberState = "accessRightsError"
            if status.category = categories.PNMalformedFilterExpressionCategory then
                subscriberState = "malformedFilterExpressionError"
            end if
            
            if status.category <> categories.PNAccessDeniedCategory AND status.category <> categories.PNMalformedFilterExpressionCategory then
                subscriberState = "disconnectedUnexpectedly"
                status.private.updateCategory(status, categories.PNUnexpectedDisconnectCategory)
            end if 
            pn_subscriptionManagerHandleStateChange(status, subscriberState, data)
            status.delete("private")
            status.delete("data")
        else
            if PNObject(privateData.config.restoreSubscription).default(false) = true then
                status.automaticallyRetry = true
                if PNObject(privateData.config.catchUpOnSubscriptionRestore).default(false) = true then
                    if PNObject(privateData.currentTimeToken).default("0") > "0" then
                        privateData.lastTimeToken = privateData.currentTimeToken
                        privateData.currentTimeToken = "0"
                    end if
                    if PNObject(privateData.currentTimeTokenRegion).default(0) > 0 then
                        privateData.lastTimeTokenRegion = privateData.currentTimeTokenRegion
                        privateData.currentTimeTokenRegion = invalid
                    end if
                else
                    privateData.currentTimeToken = "0"
                    privateData.lastTimeToken = "0"
                    privateData.currentTimeTokenRegion = invalid
                    privateData.lastTimeTokenRegion = invalid
                end if
            else
                privateData.stateManager.removeStateForObjects(privateData.channels)
                privateData.stateManager.removeStateForObjects(privateData.channelGroups)
                privateData.channels = []
                privateData.presenceChannels = []
                privateData.channelGroups = []
                privateData.presenceChannelGroups = []
            end if
            status.private.updateCategory(status, categories.PNUnexpectedDisconnectCategory) 
            privateData.heartbeatManager.stopHeartbeatIfPossible()
            pn_subscriptionManagerHandleStateChange(status, "disconnectedUnexpectedly", data)
            status.delete("private")
            status.delete("data")
        end if
    end if
end sub

sub pn_subscriptionManagerHandleSubscriptionToken(status as Object, data as Object)
    initial = data.initialSubscribe
    privateData = data.context.private
    configuration = privateData.config
    overrideTimetoken = privateData.overrideTimetoken
    timetoken = status.data.timetoken
    region = status.data.region
    shouldAcceptNewTimeToken = true
    shouldOverrideTimeToken = initial = true AND PNObject(overrideTimetoken).default("0") > "0"
    
    if initial = true then
        ' 'keepTimeTokenOnListChange' property should never allow to reset time tokens in
        ' case if there is a few more subscribe requests is waiting for their turn to be sent.
        shouldUseLastTimetoken = configuration.keepTimeTokenOnListChange = true
        if shouldUseLastTimetoken = false then
            shouldUseLastTimetoken = configuration.restoreSubscription = true AND configuration.catchUpOnSubscriptionRestore = true
        end if
        shouldUseLastTimeToken = shouldUseLastTimeToken = true AND shouldOverrideTimeToken = false
        
        ' Ensure what we already don't use value from previous time token assigned during
        ' previous sessions.
        if shouldUseLastTimeToken = true AND PNObject(privateData.lastTimeToken).default("0") > "0" then
            shouldAcceptNewTimeToken = false
            
            ' Swap time tokens to catch up on events which happened while client changed channels 
            ' and groups list configuration.
            privateData.currentTimeToken = privateData.lastTimeToken
            privateData.lastTimeToken = "0"
            privateData.currentTimeTokenRegion = privateData.lastTimeTokenRegion
            privateData.lastTimeTokenRegion = invalid
        end if
    end if
    
    ' Ensure what client won't handle delayed requests. It is impossible to have non-initial
    ' subscription while current time token report 0.
    if initial = false AND PNObject(privateData.currentTimeToken).default("0") = "0" then shouldAcceptNewTimeToken = false
    
    if shouldAcceptNewTimeToken then
        if PNObject(privateData.currentTimeToken).default("0") > "0" then
            privateData.lastTimeToken = privateData.currentTimeToken
        end if
        if PNObject(privateData.currentTimeTokenRegion).default(0) > 0 then
            privateData.lastTimeTokenRegion = privateData.currentTimeTokenRegion
        end if
        if shouldOverrideTimeToken = true then privateData.currentTimeToken = overrideTimetoken else privateData.currentTimeToken = timetoken
        privateData.currentTimeTokenRegion = region
    end if
    privateData.overrideTimetoken = invalid
end sub

sub pn_subscriptionManagerHandleLiveFeedEvents(status as Object, data as Object)
    events = PNObject(status).valueAtKeyPath("private.response.events")
    requestMessageCountThreshold = data.context.private.config.requestMessageCountThreshold
    if PNArray(events).isEmpty() = false then
        if requestMessageCountThreshold > 0 AND events.count() >= requestMessageCountThreshold then
            exceedStatus = status.private.copyWithMutatedData(status, invalid)
            exceedStatus.private.updateCategory(exceedStatus, PNStatusCategory().PNRequestMessageCountExceededCategory)
            exceedStatus.data.delete("region")
            exceedStatus.delete("private")
            listenerManager = data.context.private.listenerManager
            listenerManager.announceStatus(exceedStatus)
        end if
    
        for each evt in events
            isPresenceEvent = evt.presenceEvent <> invalid
            if isPresenceEvent = true then
                if evt.subscription <> invalid then evt.subscription = evt.subscription.replace("-pnpres", "")
                if evt.channel <> invalid then evt.channel = evt.channel.replace("-pnpres", "")
            end if
            
            if isPresenceEvent = true then
                presenceEvent = PNPresenceEventResult(status, evt)
                pn_subscriptionManagerAppendSubscriberInformation(presenceEvent, data)
                pn_subscriptionManagerHandleNewPresenceEvent(presenceEvent, data)
            else
                message = PNMessageResult(status, evt)
                pn_subscriptionManagerAppendSubscriberInformation(message, data)
                pn_subscriptionManagerHandleNewMessage(message, data)
            end if
        end for
    end if
    
    serviceResponse = PNObject(status).valueAtKeyPath("private.response")
    if serviceResponse <> invalid then
        if data.initialSubscribe = true then pn_subscriptionManagerAppendSubscriberInformation(status, data)
        status.private.updateData(status, {timetoken: serviceResponse.timetoken, region: serviceResponse.region})
    end if
end sub

sub pn_subscriptionManagerHandleNewMessage(messageStatus = invalid as Dynamic, data = invalid as Dynamic)
    errorStatus = invalid
    if messageStatus <> invalid then
        if PNObject(PNObject(messageStatus).valueAtKeyPath("private.response.decryptError")).default(false) = true then
            serviceResponse = PNObject(messageStatus).valueAtKeyPath("private.response")
            reportData = {
                operation: PNOperationType().PNSubscribeOperation
                category: PNStatusCategory().PNDecryptionErrorCategory
                handleResponse: false
            }
            errorStatus = PNErrorStatus(reportData)
            serviceResponse.delete("decryptError")
            serviceResponse.delete("envelope")
            errorStatus.associatedObject = PNObject(serviceResponse).copy(1)
            errorStatus.private.updateData(errorStatus, serviceResponse)
            errorStatus.delete("private")
            errorStatus.delete("data")
        end if
    end if
    
    listenerManager = data.context.private.listenerManager
    if errorStatus <> invalid then listenerManager.announceStatus(errorStatus) else listenerManager.announceMessage(messageStatus)
end sub

sub pn_subscriptionManagerHandleNewPresenceEvent(presenceEvent = invalid as Dynamic, data = invalid as Dynamic)
    privateData = data.context.private
    if PNObject(presenceEvent).valueAtKeyPath("data.presenceEvent") = "state-change" then
        if PNObject(presenceEvent).valueAtKeyPath("data.presence.uuid") = privateData.config.uuid then
            state = PNObject(presenceEvent).valueAtKeyPath("data.presence.state")
            privateData.stateManager.setState(state, presenceEvent.data.channel)
        end if
    end if
    privateData.listenerManager.announcePresence(presenceEvent)
end sub

sub pn_subscriptionManagerHandleStateChange(status = invalid as Dynamic, state = "initialized" as String, data = invalid as Dynamic)
    privateData = data.context.private
    category = PNStatusCategory().PNUnknownCategory
    targetState = state
    shouldHandleTransition = false

    if targetState = "connected" then
        privateData.mayRequireSubscriptionRestore = false
        shouldHandleTransition = privateData.state = "initialized" OR privateData.state = "disconnected" OR privateData.state = "connected"
        if shouldHandleTransition = false then shouldHandleTransition = privateData.state = "accessRightsError"
        category = PNStatusCategory().PNConnectedCategory
        if shouldHandleTransition = false AND privateData.state = "disconnectedUnexpectedly" then
            targetState = "connected"
            category = PNStatusCategory().PNReconnectedCategory
            shouldHandleTransition = true
        end if
    else if targetState = "disconnected" OR targetState = "disconnectedUnexpectedly" then
        shouldHandleTransition = privateData.state = "initialized" OR privateData.state = "connected" OR privateData.state = "disconnectedUnexpectedly"
        shouldHandleTransition = shouldHandleTransition = true OR targetState = "disconnectedUnexpectedly" AND targetState = privateData.state
        if targetState = "disconnected" then
            category = PNStatusCategory().PNDisconnectedCategory
        else
            category = PNStatusCategory().PNUnexpectedDisconnectCategory
        end if
        privateData.mayRequireSubscriptionRestore = shouldHandleTransition
    else if targetState = "accessRightsError" then
        privateData.mayRequireSubscriptionRestore = false
        shouldHandleTransition = true
        category = PNStatusCategory().PNAccessDeniedCategory
    else if targetState = "malformedFilterExpressionError" then
        targetState = "disconnectedUnexpectedly"
        privateData.mayRequireSubscriptionRestore = false
        shouldHandleTransition = true
        category = PNStatusCategory().PNMalformedFilterExpressionCategory
    end if
    
    if shouldHandleTransition then
        privateData.state = targetState
        targetStatus = status
        if targetStatus = invalid then
            emptyRequest = PNRequest()
            emptyRequest.setUserInfo({
                operation: PNOperationType().PNSubscribeOperation
                category: category
                handleResponse: false
            })
            targetStatus = PNStatus(emptyRequest)
            targetStatus.append(privateData.networkManager.private.clientInformation())
        end if
        targetStatus.private.updateCategory(targetStatus, category)
        targetStatus.delete("private")
        targetStatus.delete("data")
        privateData.listenerManager.announceStatus(targetStatus)
    end if
end sub

' brief:  Handle unsubscription request completion completion.
'
' status  Reference on API calling status object.
' data    Reference on object which contain information which is required to retry API call.
'
sub pn_subscriptionManagerUnsubscribeHandler(status = invalid as Dynamic, data = {} as Object)
    emptyRequest = PNRequest()
    emptyRequest.setUserInfo({
        operation: PNOperationType().PNUnsubscribeOperation
        category: PNStatusCategory().PNAcknowledgmentCategory
        handleResponse: false
    })
    successStatus = PNStatus(emptyRequest)
    successStatus.append(data.context.private.networkManager.private.clientInformation())
    if PNObject(data.params.informingListener).default(true) = true then
        pn_subscriptionManagerHandleStateChange(successStatus, "disconnected", data)
    end if
    
    listChanged = PNArray(data.allObjects).isEqual(data.context.private.allObjects()) = false
    if  PNObject(data.params.subscribeOnRest).default(true) = true AND data.context.private.allObjects().count() > 0 AND listChanged = false then
        data.context.private.readyForNextSubscriptionLoop = true
        data.context.private.nextSubscriptionLoopAsinitial = true
    else if data.callback <> invalid then
        data.callback(successStatus)
    end if
end sub

' brief:      Handle retry timer fire.
' discussion: If retry handler has been called it mean what client still wasn't able to restore 
'             subscription and repeat attempt. Handler doesn't call client subscribe method 
'             directly, to eliminate stack overflow possibility. 
'
' callbackData  Reference on object which contain 'context' (reference on actual subscribe manager 
'               which started it) which will allow to set corresponding flags.
'
sub pn_subscriptionManagerHandleRetryTimer(callbackData as Object)
    privateData = callbackData.context
    privateData.retryTimer = invalid
    privateData.nextSubscriptionLoopAsinitial = false
    privateData.shouldRetrySubscription = true
end sub

sub pn_subscriptionManagerAppendSubscriberInformation(status as Object, data as Object)
    privateData = data.context.private
    status.currentTimetoken = privateData.currentTimetoken
    status.lastTimeToken = privateData.lastTimeToken
    status.currentTimeTokenRegion = privateData.currentTimeTokenRegion
    status.lastTimeTokenRegion = privateData.lastTimeTokenRegion
    status.subscribedChannels = privateData.channelObjects()
    status.subscribedChannelGroups = privateData.channelGroupObjects()
end sub

sub pn_subscriptionManagerDestroy()
    m.private.shouldHandleRunLoopMessages = false
    m.private.stopRetryTimer()
    m.private.networkManager = invalid
    m.private.listenerManager = invalid
    m.private.stateManager = invalid
    m.private.heartbeatManager = invalid
end sub
