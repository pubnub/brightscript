
Function PubNub(config as Object) as Object
    instance = {
        version: "0.0.1"
        publishKey: config.publishKey
        subscribeKey: config.subscribeKey
        authKey: config.authKey
        uuid: config.uuid
        origin: config.origin
        secure: config.secure
        logVerbosity: config.logVerbosity
        listenerManager = PubNubListenerManager()
        subscriptionManager = PubNubSubscriptionManager({ listenerManager: listenerManager })
    }

    if instance.secure = invalid then
        instance.secure = false
    end if

    if instance.origin = invalid then
        instance.origin = "pubsub.pubnub.com"
    end if

    if instance.uuid = invalid then
        instance.uuid = CreateObject("roDeviceInfo").GetRandomUUID()
    end if

    if instance.logVerbosity = invalid then
        instance.logVerbosity = false
    end if

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
    };

    ' push
    instance.Push = {
      AddChannels: PushAddChannels
      RemoveChannels: PushRemoveChannels
      DeleteDevice: PushRemoveDevice
      ListChannels: PushListChannels
    }
    ' end Push

    instance.subscribeEndpoint = Subscribe

    ' presence
    instance.WhereNow = WhereNow
    ' end presence

    ' end mounting endpoints

    instance.AddListener = instance.listenerManager.addListener
    instance.RemoveListener = instance.listenerManager.removeListener
    instance.RemoveAllListeners = instance.listenerManager.removeAllListeners

    return instance
end Function
