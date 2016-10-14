Function PubNubSubscriptionManager(config as Object) as Object

    instance = {
        _channels: []
        channels: function():return m._channels:end function
        _presenceChannels: []
        _channelGroups: []
        channelGroups: function():return m._channelGroups:end function
        _presenceChannelGroups: []
        listenerManager: config.listenerManager
        _state: "initialized"
        _filterExpression: invalid
        _timetoken: 0
        _lastTimetoken: invalid
        _region: invalid
        _lastRegion: invalid
        _overrideTimetoken: invalid
        _currentRequest: invalid
    }.append(m)

    instance._addChannels = function(channels as Object, withPresence as Boolean)
        if channels <> invalid
            for channel in channels
                isPresenceChannel = pnStringHasSuffix(channel, "-pnpres")
                if isPresenceChannel then
                    objects = m._presenceChannels
                else
                    objects = m._channels
                end if
                if withPresence AND !isPresenceChannel then
                    presenceChannel = channel + "-pnpres"
                    if !pnArrayContainsValue(m._presenceChannels, presenceChannel) then
                        m._presenceChannels.push(presenceChannel)
                    end if
                end if
                if !pnArrayContainsValue(objects, channel) then objects.push(channel)
            end for
        end if
    end function

    instance._removeChannels = function(channels as Object, withPresence as Boolean)
        if channels <> invalid
            for channel in channels
                isPresenceChannel = pnStringHasSuffix(channel, "-pnpres")
                if isPresenceChannel then
                    objects = m._presenceChannels
                else
                    objects = m._channels
                end if
                if withPresence AND !isPresenceChannel then
                    presenceChannel = channel + "-pnpres"
                    pnRemoveValueFromArray(m._presenceChannels, presenceChannel)
                end if
                pnRemoveValueFromArray(objects, channel)
            end for
        end if
    end function

    ' Create list of channel objects from regular and presence channel names
    instance._channelObjects = function() as Object
        objects = [].append(m._channels)
        objects.append(m._presenceChannels)

        return objects
    end function

    instance._addChannelGroups = function(groups as Object, withPresence as Boolean)
        if groups <> invalid
            for group in groups
                isPresenceGroup = pnStringHasSuffix(group, "-pnpres")
                if isPresenceGroup then
                    objects = m._presenceChannelGroups
                else
                    objects = m._channelGroups
                end if
                if withPresence AND !isPresenceGroup then
                    presenceGroup = group + "-pnpres"
                    if !pnArrayContainsValue(m._presenceChannelGroups, presenceGroup) then
                        m._presenceChannelGroups.push(_presenceChannelGroups)
                    end if
                end if
                if !pnArrayContainsValue(objects, group) then objects.push(group)
            end for
        end if
    end function

    instance._removeChannelGroups = function(groups as Object, withPresence as Boolean)
        if groups <> invalid
            for group in groups
                isPresenceGroup = pnStringHasSuffix(group, "-pnpres")
                if isPresenceGroup then
                    objects = m._presenceChannelGroups
                else
                    objects = m._channelGroups
                end if
                if withPresence AND !isPresenceGroup then
                    presenceGroup = group + "-pnpres"
                    pnRemoveValueFromArray(m._presenceChannelGroups, presenceGroup)
                end if
                pnRemoveValueFromArray(objects, group)
            end for
        end if
    end function

    ' Create list of channel group objects from regular and presence channel group names
    instance._channelGroupObjects = function() as Object
        objects = m._channelGroups
        objects.append(m._presenceChannelGroups)

        return objects
    end function

    instance._allObjects = function() as Object
        objects = m._channelObjects()
        objects.append(m._channelGroupObjects())

        return objects
    end function

    ' Check whether presence enabled for channel or channel group
    instance.presenceEnabledForChannel = Function (channel as String) as Boolean
      return pnArrayContainsValue(m._channels, channel + "-pnpres")
    end function
    instance.presenceEnabledForChannelGroup = Function (channelGroup as String) as Boolean
      return pnArrayContainsValue(m._presenceChannels, channelGroup + "-pnpres")
    end function

    instance.subscribe = Function (config as Object, initialSubscribe = true as Boolean)
        ' Add new channel and groups to subscription list if required
        withPresence = pnDefaultValue(config.withPresence, false)
        if config.channelGroups <> invalid then
            m._addChannelGroups(config.channelGroups, withPresence)
        end if
        if config.channels <> invalid then
            m._addChannels(config.channels, withPresence)
        end if
        ' Cancel previously started long-poll request
        if m._currentRequest <> invalid then m._currentRequest.AsyncCancel()

        ' Ensure what there is some data objects to which client should be able
        ' to subscribe
        if m._allObjects().count > 0 then
            urlt = CreateObject("roUrlTransfer")
            m._overrideTimetoken = config.timetoken
            if config.filterExpression <> invalid then
                m._filterExpression = config.filterExpression
            end if
            if initialSubscribe then
                if m._timetoken > 0 then m._lastTimetoken = m._timetoken
                if m._region <> invalid AND m._region > 0 then m._lastRegion = m._region
                m._timetoken = 0
                m._region = invalid
            end if

            ' Configure subscribe request
            requestSetup = createRequestConfig(m)
            query = {
                tt: m._timetoken
                tr: m._region
                "filter-expr": m._filterExpression
            }
            if m._filterExpression.len() = 0 then query.delete("filter-expr")

            ' Compose list of channel groups which can be used in request
            channelGroupsForSubscription = m._channelGroupObjects()
            if channelGroupsForSubscription.count() > 0 then
                query["channel-group"] = implode(",", channelGroupsForSubscription)
            end if
            requestSetup.append({"query": query})

            ' Compose list of channels which can be used in request
            stringifiedChannelsList = implode(",", m._channelObjects())
            requestSetup.path = [
                "v2",
                "subscribe",
                m.subscribeKey,
                urlt.Escape(stringifiedChannelsList),
                "0"
            ]

            SubscribeCallback = Function (status as Object, response as Object, completionCallback as Function)
                m.currentRequest = invalid
                status.operation = "PNSubscribeOperation"
                if status.error then
                    m._handleFailedSubscriptionStatus(status, initialSubscribe)
                else
                    status.append(serviceResponseParser.parse(response))
                    m._handleSuccessSubscriptionStatus(status, initialSubscribe)
                end if
            end function
            m._currentRequest = HTTPRequest(requestSetup, SubscribeCallback)
        else
            m._timetoken = 0
            m._lastTimetoken = 0
            m._region = invalid
            m._lastRegion = invalid
        end if
    end Function

    instance.unsubscribe = Function (config as Object, callback = invalid as Function)
        if config.channels <> invalid OR config.channelGroups <> invalid then
            ' Add new channel and groups to subscription list if required
            withPresence = pnDefaultValue(config.withPresence, false)
            if config.channelGroups <> invalid then
                m._removeChannelGroups(config.channelGroups, withPresence)
            end if
            if config.channels <> invalid then
                m._removeChannels(config.channels, withPresence)
            end if
            ' Cancel previously started long-poll request
            if m._currentRequest <> invalid then m._currentRequest.AsyncCancel()
            urlt = CreateObject("roUrlTransfer")
            ' Configure subscribe request
            requestSetup = createRequestConfig(m)
            requestSetup.callback = callback

            ' Compose list of channel groups which can be used in request
            query = {}
            if config.channelGroups <> invalid then
                channelGroupsForUnsubscription = []
                for each group in config.channelGroups
                    if !pnStringHasSuffix(group, "-pnpres") then
                        channelGroupsForUnsubscription.push(group)
                    end if
                end for
                query["channel-group"] = implode(",", channelGroupsForUnsubscription)
            end if
            requestSetup.append({"query": query})

            ' Compose list of channels which can be used in request
            channelsForUnsubscription = []
            if config.channels <> invalid then
                for each channel in config.channels
                    if !pnStringHasSuffix(channel, "-pnpres") then
                        channelsForUnsubscription.push(channel)
                    end if
                end for
            end if
            stringifiedChannelsList = implode(",", channelsForUnsubscription)
            requestSetup.path = [
                "v2",
                "presence",
                "sub_key",
                m.subscribeKey,
                "channel",
                urlt.Escape(stringifiedChannelsList),
                "leave"
            ]
            UnsubscribeCallback = Function (status as Object, response as Object, completionCallback as Function)
                m.currentRequest = invalid
                status.operation = "PNUnsubscribeOperation"
                status.error = false
                if completionCallback = invalid then
                    if m._allObjects().count > 0 then
                        m.listenerManager.announceStatus(status)
                    else
                        m._handleStateChange("disconnected")
                    end if
                end if
                if completionCallback <> invalid then completionCallback()
            end function
            m._currentRequest = HTTPRequest(requestSetup, UnsubscribeCallback)
        end if
    end Function

    instance.unsubscribeAll = Function ()
      if m._channelObjects().count > 0 OR m._channelGroupObjects().count > 0 then
          shouldInformObservers = true
          if m._channelObjects().count > 0 AND m._channelGroupObjects().count > 0 then
              shouldInformObservers = false
          end if
          channelsUnsubscriptionCallback = invalid
          if !shouldInformObservers then
              channelsUnsubscriptionCallback = function ()
                  m.unsubscribeAll()
              end function
          end if
          config = {
              channels: m._channelObjects()
              channelGroups: m._channelGroupObjects()
          }
          m.unsubscribe(config, channelsUnsubscriptionCallback)
      end if
    end Function

    instance._handleSuccessSubscriptionStatus = function (status as Object, initial as Boolean)
        if status.timetoken <> invalid then
            m._handleSubscription(initial, status.timetoken, status.region)
        end if
        m._handleLiveFeedEvents(status.events)
        m.subscribe(invalid, false)
        if initial then m._handleStateChange("connected")
    end function

    instance._handleFailedSubscriptionStatus = function (status as Object, initial as Boolean)
        status.error = true
        m.listenerManager.announceStatus(status)
    end function

    instance._handleSubscription = function (initial as Boolean, timetoken as Object, region as Object)
        shouldUseNewTimetoken = true
        shouldOverrideTimeToken = false
        if initial AND m._overrideTimetoken <> invalid then shouldOverrideTimeToken = true
        shouldUseLastTimetoken = !shouldOverrideTimeToken
        if shouldOverrideTimeToken AND m._lastTimetoken <> invalid AND m._lastTimetoken > 0 then
            shouldUseNewTimetoken = false
            m._timetoken = m._lastTimetoken
            m._lastTimetoken = invalid
            m._region = m._lastRegion
            m._lastRegion = invalid
        end if

        if !initial AND m._timetoken = 0 then shouldUseNewTimetoken = false
        if shouldUseNewTimetoken then
            if m._timetoken > 0 then m._lastTimetoken = m._timetoken
            if m._region <> invalid AND m._region > 0 then m._lastRegion = m._region
            if shouldOverrideTimeToken then
                m._timetoken = m._overrideTimetoken
            else
                m._timetoken = timetoken
            end if
            m._region = region
        end if
        m._overrideTimetoken = invalid
    end function

    instance._handleLiveFeedEvents = function(events as Object)
        for event in events
            if event.presenceEvent = invalid
                m.listenerManager.announceMessage(event)
            else
                m.listenerManager.announcePresence(event)
            end if
        end for
    end function

    instance._handleStateChange = function (state as String)
        category = "PNUnknownCategory"
        targetState = state
        shouldHandleTransition = false
        if targetState = "connected" then
            if m._state = "initialized" OR m._state = "disconnected" OR m._state = "connected" then
                shouldHandleTransition = true
            else if m._state = "accessRightsError" then
                shouldHandleTransition = true
            end if
            category = "PNConnectedCategory"
            if !shouldHandleTransition AND m._state = "disconnectedUnexpectedly" then
                targetState = "connected"
                category = "PNReconnectedCategory"
                shouldHandleTransition = true
            end if
        else if targetState = "disconnected" OR targetState = "disconnectedUnexpectedly" then
            if m._state = "initialized" OR m._state = "connected" OR m._state = "disconnectedUnexpectedly" then
                shouldHandleTransition = true
            else if targetState = "disconnectedUnexpectedly" AND targetState = m._state then
                shouldHandleTransition = true
            end if
            if targetState = "disconnected" then
                category = "PNDisconnectedCategory"
            else
                category = "PNUnexpectedDisconnectCategory"
            end if
        else if targetState = "accessRightsError" then
            category = "PNAccessDeniedCategory"
            shouldHandleTransition = true
        else if targetState = "malformedFilterExpressionError" then
            category = "PNMalformedFilterExpressionCategory"
            shouldHandleTransition = true
        end if
        if shouldHandleTransition then
            m._state = targetState
        end if
    end function

    serviceResponseParser = {
        parse: function(response as Object) as Object
            timetokenObject = response.t
            timetoken = timetokenObject.t
            region = timetokenObject.r
            feedEvents = response.m
            if feedEvents.count() > 0
                events = []
                for each event in feedEvents
                    parsedEvent = eventParser.parse(event)
                    if parsedEvent.timetoken = invalid then
                        parsedEvent.timetoken = timetoken
                    end if
                    events.push(parsedEvent)
                end for
                feedEvents = events
            end if
            return {"events": feedEvents, "timetoken": timetoken, "region": region}
        end function
    }

    eventParser = {
        parse: function(event as Object) as Object
            parsedEvent = {}
            isPresenceEvent = pnStringHasSuffix(event.c, "-pnpres")
            channel = event.c.replace("-pnpres", "")
            subscriptionMatch = event.b
            if subscriptionMatch = channel then subscriptionMatch = invalid
            parsedEvent.envelope = envelopeInformationParser.parse(event)
            parsedEvent.channel = channel
            if subscriptionMatch <> invalid then
                parsedEvent.subscription = subscriptionMatch
            else
                parsedEvent.subscription = channel
            end if
            if event.o <> invalid then timetokenObject = event.o else timetokenObject = event.p
            if timetokenObject.r <> invalid then
                parsedEvent.timetoken = timetokenObject.t
                parsedEvent.region = timetokenObject.t
            end if
            payload = event.d
            if isPresenceEvent then
                presence = {
                    presenceEvent: pnDefaultValue(payload.action, "interval")
                    presence: {timetoken: payload.timestamp
                        occupancy: pnDefaultValue(payload.occupancy, 0)
                    }
                }
                if payload.uuid then presence.uuid = payload.uuid
                if payload.data then presence.state = payload.data
            else
                parsedEvent.message = payload
            end if

            return parsedEvent
        end function
    }

    envelopeInformationParser = {
        parse: function(information as Object) as Object
            return {
                shard: information.a
                flags: information.f
                senderIdenrifier: information.i
                sequence: information.s
                subscribeKey: information.k
                replicationMap: information.r
                eatAfterReading: information.ear
                metadata: information.u
                waypoints: information.w
            }
        end function
    }

    return instance
end Function
