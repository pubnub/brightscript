Function Subscribe(interface as Object) as Object

    interface.subscribe = function(config as Object)
        if config.channels <> invalid OR config.channelGroups <> invalid then
          m.subscriptionManager.subscribe(config)
          end if
    end function

    interface.unsubscribe = function(config as Object)
        if config.channels <> invalid OR config.channelGroups <> invalid then
          m.subscriptionManager.unsubscribe(config)
        end if
    end function

    interface.unsubscribeAll = function()
        m.subscriptionManager.unsubscribeAll()
    end function

    interface.channels = function() as Object
        return m.subscriptionManager.channels()
    end function

    interface.presenceEnabledForChannel = Function (channel as String) as Boolean
        enabled = false
        if channel <> invalid then
          enabled = m.subscriptionManager.presenceEnabledForChannel(channel)
        end if
        return enabled
    end function

    interface.channelGroups = function() as Object
        return m.subscriptionManager.channelGroups()
    end function

    interface.presenceEnabledForChannelGroup = Function (channelGroup as String) as Boolean
        enabled = false
        if channelGroup <> invalid then
          enabled = m.subscriptionManager.presenceEnabledForChannelGroup(channelGroup)
        end if
        return enabled
    end function
end Function
