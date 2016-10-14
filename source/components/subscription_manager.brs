
Function PubNubSubscriptionManager(config as Object) as Object

    instance = {
      channels: []
      channelGroups: []
      listenerManager: config.listenerManager
      timetoken: 0
      region: invalid
    }


    instance.subscribe = Function (config as Object)

    end Function

    instance.unsubscribe = Function (config as Object)

    end Function

    return instance
