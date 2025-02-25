function PNSubscribeManager(config as object, networkManager as object, listenerManager as object, stateManager as object, heartbeatManager as object) as object
    this = {
        private: {
            config: config
            channels: []
            presenceChannels: []
            channelGroups: []
            presenceChannelGroups: []
            cachedObjects: {}
            cachedObjectIdentifiers: []
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
        channels: function(): return m.private.channels: end function
        channelGroups: function(): return m.private.channelGroups: end function
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

    this.private.deDuplicateMessages = pn_subscriptionManagerDeDuplicateMessages
    this.private.clearCacheFromMessagesNewerThan = pn_subscriptionManagerClearCacheFromMessagesNewerThan
    this.private.cacheObjectIfPossible = pn_subscriptionManagerCacheObjectIfPossible
    this.private.cleanUpCachedObjectsIfRequired = pn_subscriptionManagerCleanUpCachedObjectsIfRequired

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

sub pn_subscriptionManagerSubscribe(params as object, initialSubscribe = true as boolean, callback = invalid as dynamic)
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
        callbackData = { callback: callback, context: m, params: params, client: invalid, func: "subscribe" }
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
        pn_subscriptionManagerHandleStateChange(status, "disconnected", { context: m })
        m.private.networkManager.private.cancelSubscriptionRequest()
    end if
end sub

sub pn_subscriptionManagerUnsubscribeFromAll()
    if m.private.channelObjects().count() > 0 or m.private.channelGroupObjects().count() > 0 then
        channels = PNObject(m.private.channelObjects()).copy()
        groups = PNObject(m.private.channelGroupObjects()).copy()
        m.removeChannels(channels, true)
        m.removeChannelGroups(groups, true)
        m.unsubscribe({ channels: channels, channelGroups: groups, informingListener: true, subscribeOnRest: false })
    end if
end sub

sub pn_subscriptionManagerUnsubscribe(params as object, callback = invalid as dynamic)
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
        request = { path: { "{channels}": channelsList }, query: {} }
        if channelsList = invalid and groupsList <> invalid then request.query["channel-group"] = groupsList
        request.operation = PNOperationType().PNUnsubscribeOperation
        callbackData = { callback: callback, context: m, params: params, allObjects: PNObject(subscriptionObjects).copy() }
        m.private.networkManager.processOperation(request.operation, request, invalid, callbackData, pn_subscriptionManagerUnsubscribeHandler)
    else
        subscribeCallback = function(status = invalid as dynamic, data = {} as object)
            if data.callback <> invalid then data.callback(data)
            if PNObject(data.params.informingListener).default(true) = true then
                successStatus = data.successStatus
                data.delete("successStatus")
                pn_subscriptionManagerHandleStateChange(data.successStatus, "disconnected", { context: data })
            end if
        end function
        m.subscribe({ callback: callback, context: m, params: params, successStatus: successStatus }, true, subscribeCallback)
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
function pn_subscriptionManagerSubscribeRequest(params as object) as object
    request = { path: {}, query: {} }
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
    if mergedState <> invalid and mergedState.count() > 0 then
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
    m.retryTimer = PNTimer(1, { context: m }, m.handleRetryTimer, false)
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

function pn_subscriptionManagerAddChannels(channels = invalid as dynamic, withPresence = false as boolean)
    if PNArray(channels).isArray() = true then
        for each channel in channels
            isPresenceChannel = PNString(channel).hasSuffix("-pnpres")
            if isPresenceChannel = true then objects = m.presenceChannels else objects = m.channels
            if withPresence = true and isPresenceChannel = false then
                presenceChannel = channel + "-pnpres"
                if PNArray(m.presenceChannels).contains(presenceChannel) = false then
                    m.presenceChannels.push(presenceChannel)
                end if
            end if
            if PNArray(objects).contains(channel) = false then objects.push(channel)
        end for
    end if
end function

function pn_subscriptionManagerRemoveChannels(channels = invalid as dynamic, withPresence = false as boolean)
    if PNArray(channels).isArray() = true then
        for each channel in channels
            isPresenceChannel = PNString(channel).hasSuffix("-pnpres")
            if isPresenceChannel = true then objects = m.presenceChannels else objects = m.channels
            if withPresence = true and isPresenceChannel = false then
                presenceChannel = channel + "-pnpres"
                PNArray(m.presenceChannels).delete(presenceChannel)
            end if
            PNArray(objects).delete(channel)
        end for
    end if
end function

function pn_subscriptionManagerPresenceEnabledForChannel(channel as string) as boolean
    return PNArray(m.private.presenceChannels).contains(channel + "-pnpres")
end function

function pn_subscriptionManagerAllChannelObjects() as object
    objects = []
    objects.append(m.channels)
    objects.append(m.presenceChannels)

    return objects
end function

function pn_subscriptionManagerAddChannelGroups(groups = invalid as dynamic, withPresence = false as boolean)
    if PNArray(groups).isArray() = true then
        for each group in groups
            isPresenceGroup = PNString(group).hasSuffix("-pnpres")
            if isPresenceGroup = true then objects = m.presenceChannelGroups else objects = m.channelGroups
            if withPresence = true and isPresenceGroup = false then
                presenceGroup = group + "-pnpres"
                if PNArray(m.presenceChannelGroups).contains(presenceGroup) = false then
                    m.presenceChannelGroups.push(m.presenceChannelGroups)
                end if
            end if
            if PNArray(objects).contains(group) = false then objects.push(group)
        end for
    end if
end function

function pn_subscriptionManagerRemoveChannelGroups(groups as object, withPresence as boolean)
    if PNArray(groups).isArray() = true then
        for each group in groups
            isPresenceGroup = PNString(group).hasSuffix("-pnpres")
            if isPresenceGroup = true then objects = m.presenceChannelGroups else objects = m.channelGroups
            if withPresence = true and isPresenceGroup = false then
                presenceGroup = group + "-pnpres"
                PNArray(m.presenceChannelGroups).delete(presenceGroup)
            end if
            PNArray(objects).delete(group)
        end for
    end if
end function

function pn_subscriptionManagerPresenceEnabledForChannelGroup(channelGroup as string) as boolean
    return PNArray(m.private.presenceChannelGroups).contains(channelGroup + "-pnpres")
end function

function pn_subscriptionManagerAllChannelGroupObjects() as object
    objects = []
    objects.append(m.channelGroups)
    objects.append(m.presenceChannelGroups)

    return objects
end function

function pn_subscriptionManagerAllObjects() as object
    objects = []
    objects.append(m.channelObjects())
    objects.append(m.channelGroupObjects())

    return objects
end function

' brief:      Clean up 'events' list from messages which has been already received.
' discussion: Use messages cache to identify message duplicates and remove them from input 'events'
'             list so listeners won't receive them through callback methods again.
'
' events  Reference on list of received events from real-time channels and should be clean up from
'         message duplicates.
'
sub pn_subscriptionManagerDeDuplicateMessages(events = [] as dynamic)
    maximumMessagesCacheSize = m.config.maximumMessagesCacheSize
    if maximumMessagesCacheSize > 0 then
        for eventIdx = 0 to events.count() - 1 step 1
            event = events[eventIdx]
            if event <> invalid and event.presenceEvent = invalid and m.cacheObjectIfPossible(event, maximumMessagesCacheSize) = false then
                events.delete(eventIdx)
                eventIdx = eventIdx - 1
            end if
        end for
        m.cleanUpCachedObjectsIfRequired(maximumMessagesCacheSize)
    end if
end sub

' brief:      Remove from messages cache those who has date same or newer than passed 'timetoken'.
' discussion: Method used for subscriptions where user pass specific 'timetoken' to which client
'             should catch up. It expensive to run, but subscriptions to specific 'timetoken' pretty
'             rare and shouldn't affect overall performance.
'
' timetoken  Reference on stringified timetoken which should be used as reference to file out
'            messages which should be removed.
'
sub pn_subscriptionManagerClearCacheFromMessagesNewerThan(timetoken as string)
    maximumMessagesCacheSize = m.config.maximumMessagesCacheSize
    if maximumMessagesCacheSize > 0 then
        identifiers = PNObject(m.cachedObjects).allKeys()
        identifiers.sort("i")
        for identifierIdx = 0 to identifiers.count() - 1 step 1
            identifier = identifiers[identifierIdx]
            cachedTimetoken = identifier.split("_")[0]
            if cachedTimetoken >= timetoken then
                m.cachedObjects.delete(identifier)
                PNArray(m.cachedObjectIdentifiers).delete(identifier)
            end if
        end for
    end if
end sub

' brief:      Store to cache passed 'obj'.
' discussion: This method used by 'de-dupe' logic to identify unique objects about which object
'             listeners should be notified.
'
' obj  Reference on object which client should try to store in cache.
' size Maximum number of objects which can be stored in cache and used during messages
'      de-dpublication process.
'
' return Whether object has been added to cache or not.
'
function pn_subscriptionManagerCacheObjectIfPossible(obj = invalid as dynamic, size = 0 as integer) as boolean
    cached = false
    if obj <> invalid then
        identifier = obj.timetoken + "_" + obj.channel
        objects = PNObject(m.cachedObjects[identifier]).default([])
        cachedMessagesCount = objects.count()
        if cachedMessagesCount = 0 or PNArray(objects).contains(obj.message) = false then objects.push(obj.message)
        if cachedMessagesCount = 0 then m.cachedObjects[identifier] = objects
        cached = cachedMessagesCount <> objects.count()

        if cached = true then m.cachedObjectIdentifiers.push(identifier)
    end if

    return cached
end function

' brief:  Shrink messages cache size to specified size if required.
'
' maximumCacheSize Messages cache maximum size.
'
sub pn_subscriptionManagerCleanUpCachedObjectsIfRequired(maximumCacheSize = 0 as integer)
    if m.cachedObjectIdentifiers.count() > maximumCacheSize then
        identifier = m.cachedObjectIdentifiers[0]
        objects = m.cachedObjects[identifier]
        if objects <> invalid and objects.count() = 1 then
            m.cachedObjects.delete(identifier)
        else
            objects.delete(0)
        end if
        m.cachedObjectIdentifiers.delete(0)
    end if
end sub


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
sub pn_subscriptionManagerHandleMessage(message = invalid as dynamic)
    if m.private.shouldHandleRunLoopMessages = true then
        if m.private.retryTimer <> invalid then m.private.retryTimer.tick()
        if m.private.readyForNextSubscriptionLoop = true or m.private.shouldRetrySubscription = true then
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
sub pn_subscriptionManagerSubscribeHandler(status = invalid as dynamic, data = {} as object)
    pn_subscriptionManagerSubsciptionStatusHandle(status, data)
    if data.callback <> invalid then
        if data.context <> invalid then data.callback(status, data.context) else data.callback(status)
    end if
end sub

sub pn_subscriptionManagerSubsciptionStatusHandle(status as object, data as object)
    data.context.private.stopRetryTimer()
    if status.error = false and status.category <> PNStatusCategory().PNCancelledCategory then
        pn_subscriptionManagerHandleSuccessSubscriptionStatus(status, data)
    else
        pn_subscriptionManagerHandleFailedSubscriptionStatus(status, data)
    end if
end sub

sub pn_subscriptionManagerHandleSuccessSubscriptionStatus(status as object, data as object)
    initial = data.initialSubscribe
    data.overrideTimeToken = data.context.private.overrideTimetoken
    if status.data.timetoken <> invalid and status.request <> invalid then
        tokenInformation = "Did receive next subscription loop information: timetoken = " + status.data.timetoken + ", region = " + box(status.data.region).toStr()
        ?tokenInformation
        pn_subscriptionManagerHandleSubscriptionToken(status, data)
    end if
    pn_subscriptionManagerHandleLiveFeedEvents(status, data)
    data.context.private.readyForNextSubscriptionLoop = true
    data.context.private.nextSubscriptionLoopAsinitial = false
    data.context.private.heartbeatManager.startHeartbeatIfRequired()
    if initial then pn_subscriptionManagerHandleStateChange(status, "connected", data)
end sub

sub pn_subscriptionManagerHandleFailedSubscriptionStatus(status as object, data as object)
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

            if status.category <> categories.PNAccessDeniedCategory and status.category <> categories.PNMalformedFilterExpressionCategory then
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

sub pn_subscriptionManagerHandleSubscriptionToken(status as object, data as object)
    initial = data.initialSubscribe
    privateData = data.context.private
    configuration = privateData.config
    overrideTimetoken = privateData.overrideTimetoken
    timetoken = status.data.timetoken
    region = status.data.region
    shouldAcceptNewTimeToken = true
    shouldOverrideTimeToken = initial = true and PNObject(overrideTimetoken).default("0") > "0"

    if initial = true then
        ' 'keepTimeTokenOnListChange' property should never allow to reset time tokens in
        ' case if there is a few more subscribe requests is waiting for their turn to be sent.
        shouldUseLastTimetoken = configuration.keepTimeTokenOnListChange = true
        if shouldUseLastTimetoken = false then
            shouldUseLastTimetoken = configuration.restoreSubscription = true and configuration.catchUpOnSubscriptionRestore = true
        end if
        shouldUseLastTimeToken = shouldUseLastTimeToken = true and shouldOverrideTimeToken = false

        ' Ensure what we already don't use value from previous time token assigned during
        ' previous sessions.
        if shouldUseLastTimeToken = true and PNObject(privateData.lastTimeToken).default("0") > "0" then
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
    if initial = false and PNObject(privateData.currentTimeToken).default("0") = "0" then shouldAcceptNewTimeToken = false

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

sub pn_subscriptionManagerHandleLiveFeedEvents(status as object, data as object)
    initial = data.initialSubscribe
    events = PNObject(status).valueAtKeyPath("private.response.events")
    requestMessageCountThreshold = data.context.private.config.requestMessageCountThreshold
    if PNArray(events).isEmpty() = false then
        eventsCount = events.count()

        if data.initialSubscribe = true and data.overrideTimeToken <> invalid and data.overrideTimeToken > "0" then
            data.context.private.clearCacheFromMessagesNewerThan(data.overrideTimeToken)
        end if
        data.context.private.deDuplicateMessages(events)

        if requestMessageCountThreshold > 0 and eventsCount >= requestMessageCountThreshold then
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
        status.private.updateData(status, { timetoken: serviceResponse.timetoken, region: serviceResponse.region })
    end if
end sub

sub pn_subscriptionManagerHandleNewMessage(messageStatus = invalid as dynamic, data = invalid as dynamic)
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

sub pn_subscriptionManagerHandleNewPresenceEvent(presenceEvent = invalid as dynamic, data = invalid as dynamic)
    privateData = data.context.private
    if PNObject(presenceEvent).valueAtKeyPath("data.presenceEvent") = "state-change" then
        if PNObject(presenceEvent).valueAtKeyPath("data.presence.uuid") = privateData.config.uuid then
            state = PNObject(presenceEvent).valueAtKeyPath("data.presence.state")
            privateData.stateManager.setState(state, presenceEvent.data.channel)
        end if
    end if
    privateData.listenerManager.announcePresence(presenceEvent)
end sub

sub pn_subscriptionManagerHandleStateChange(status = invalid as dynamic, state = "initialized" as string, data = invalid as dynamic)
    privateData = data.context.private
    category = PNStatusCategory().PNUnknownCategory
    targetState = state
    shouldHandleTransition = false

    if targetState = "connected" then
        privateData.mayRequireSubscriptionRestore = false
        shouldHandleTransition = privateData.state = "initialized" or privateData.state = "disconnected" or privateData.state = "connected"
        if shouldHandleTransition = false then shouldHandleTransition = privateData.state = "accessRightsError"
        category = PNStatusCategory().PNConnectedCategory
        if shouldHandleTransition = false and privateData.state = "disconnectedUnexpectedly" then
            targetState = "connected"
            category = PNStatusCategory().PNReconnectedCategory
            shouldHandleTransition = true
        end if
    else if targetState = "disconnected" or targetState = "disconnectedUnexpectedly" then
        shouldHandleTransition = privateData.state = "initialized" or privateData.state = "connected" or privateData.state = "disconnectedUnexpectedly"
        shouldHandleTransition = shouldHandleTransition = true or targetState = "disconnectedUnexpectedly" and targetState = privateData.state
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
sub pn_subscriptionManagerUnsubscribeHandler(status = invalid as dynamic, data = {} as object)
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

    listChanged = PNArray(data.allObjects).isEqualContent(data.context.private.allObjects()) = false
    if PNObject(data.params.subscribeOnRest).default(true) = true and data.context.private.allObjects().count() > 0 and listChanged = false then
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
sub pn_subscriptionManagerHandleRetryTimer(callbackData as object)
    privateData = callbackData.context
    privateData.retryTimer = invalid
    privateData.nextSubscriptionLoopAsinitial = false
    privateData.shouldRetrySubscription = true
end sub

sub pn_subscriptionManagerAppendSubscriberInformation(status as object, data as object)
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
