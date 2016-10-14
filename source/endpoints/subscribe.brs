Function Subscribe(config as Object) as Object

    m.subscribe = function(config as Object)
        if config.channels <> invalid OR config.channelGroups <> invalid then
          m.subscriptionManager.subscribe(config)
          end if
    end function

    m.unsubscribe = function(config as Object)
        if config.channels <> invalid OR config.channelGroups <> invalid then
          m.subscriptionManager.unsubscribe(config)
        end if
    end function

    m.unsubscribeAll = function()
        m.subscriptionManager.unsubscribeAll()
    end function

    m.channels = function() as Object
        return m.subscriptionManager.channels()
    end function

    m.presenceEnabledForChannel = Function (channel as String) as Boolean
        enabled = false
        if channel <> invalid then
          enabled = m.subscriptionManager.presenceEnabledForChannel(channel)
        end if
        return enabled
    end function

    m.channelGroups = function() as Object
        return m.subscriptionManager.channelGroups()
    end function

    m.presenceEnabledForChannelGroup = Function (channelGroup as String) as Boolean
        enabled = false
        if channelGroup <> invalid then
          enabled = m.subscriptionManager.presenceEnabledForChannelGroup(channelGroup)
        end if
        return enabled
    end function
end Function
