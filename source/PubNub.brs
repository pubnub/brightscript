Function PubNub(config as Object) as Object
    instance = {
        version: "0.0.1"
        publishKey: config.publishKey
        subscribeKey: config.subscribeKey
        authKey: config.authKey
        uuid: pnDefaultValue(config.uuid, CreateObject("roDeviceInfo").GetRandomUUID())
        origin: pnDefaultValue(config.origin, "pubsub.pubnub.com")
        secure: pnDefaultValue(config.secure, false)
        logVerbosity: pnDefaultValue(config.logVerbosity, false)
    }

    listenerManager = PubNubListenerManager()
    subscriptionManagerConfig = {listenerManager: instance.listenerManager}
    subscriptionManagerConfig.append(instance)
    instance.listenerManager = PubNubListenerManager()
    instance.subscriptionManager = PubNubSubscriptionManager(subscriptionManagerConfig)

    ' start mounting endpoints
    instance.Publish = Publish
    instance.Time = Time
    instance.History = History

    ' channel groups
    instance.ChannelGroups = {
      ListGroups: ChannelGroupListGroups
      ListChannels: ChannelGroupListChannels
      AddChannels: ChannelGroupAddChannels
      RemoveChannels: ChannelGroupRemoveChannels
      DeleteGroup: ChannelGroupDeleteGroup
    }

    ' push
    instance.Push = {
      AddChannels: PushAddChannels
      RemoveChannels: PushRemoveChannels
      DeleteDevice: PushRemoveDevice
      ListChannels: PushListChannels
    }
    ' end Push

    instance.subscribeEndpoint = Subscribe(instance)

    ' presence
    instance.WhereNow = WhereNow
    ' end presence

    ' end mounting endpoints
    instance.append({AddListener: instance.listenerManager.addListener})
    instance.AddListener = instance.listenerManager.addListener
    instance.RemoveListener = instance.listenerManager.removeListener
    instance.RemoveAllListeners = instance.listenerManager.removeAllListeners

    return instance
end Function
