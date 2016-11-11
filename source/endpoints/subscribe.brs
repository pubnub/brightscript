function PNSubscribe(client as Object) as Object
    instance = {}
    
    instance.subscribe = function(params as Object)
        params.withPresence = PNObject(params.withPresence).default(false)
        if params.channels <> invalid OR params.channelGroups <> invalid then
            if params.channels <> invalid AND params.channels.count() > 0 then 
                m.private.subscriptionManager.private.addChannels(params.channels, params.withPresence)
            end if
            if params.channelGroups <> invalid AND params.channelGroups.count() > 0 then 
                m.private.subscriptionManager.private.addChannelGroups(params.channelGroups, params.withPresence)
            end if
            m.private.subscriptionManager.subscribe(params)
        end if
    end function
    
    instance.cancelSubscriptionRetry = function()
        m.private.subscriptionManager.cancelSubscriptionRetry()
    end function

    instance.unsubscribe = function(params as Object)
        params.withPresence = PNObject(params.withPresence).default(false)
        if params.channels <> invalid OR params.channelGroups <> invalid then
            if params.channels <> invalid AND params.channels.count() > 0 then 
                m.private.subscriptionManager.private.removeChannels(params.channels, params.withPresence)
            end if
            if params.channelGroups <> invalid AND params.channelGroups.count() > 0 then 
                m.private.subscriptionManager.private.removeChannelGroups(params.channelGroups, params.withPresence)
            end if
            m.private.subscriptionManager.unsubscribe(params)
        end if
    end function

    instance.unsubscribeAll = function()
        m.private.subscriptionManager.unsubscribeAll()
    end function

    instance.channels = function() as Object
        return m.private.subscriptionManager.channels()
    end function

    instance.presenceEnabledForChannel = function(channel as String) as Boolean
        enabled = false
        if channel <> invalid then
          enabled = m.private.subscriptionManager.presenceEnabledForChannel(channel)
        end if
        return enabled
    end function

    instance.channelGroups = function() as Object
        return m.private.subscriptionManager.channelGroups()
    end function

    instance.presenceEnabledForChannelGroup = function(channelGroup as String) as Boolean
        enabled = false
        if channelGroup <> invalid then
          enabled = m.private.subscriptionManager.presenceEnabledForChannelGroup(channelGroup)
        end if
        
        return enabled
    end function
    
    return instance
end function
