
Function PubNub(config as Object) as Object
    instance = {
        publishKey: config.publishKey
        subscribeKey: config.subscribeKey
        authKey: config.authKey
        uuid: config.uuid
        origin: config.origin
        secure: config.secure
        logVerbosity: config.logVerbosity
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
    instance.publish = Publish
    instance.time = Time
    instance.history = History

    ' channel groups
    instance.channelGroups = {
      listGroups: ChannelGroupListGroups
      listChannels: ChannelGroupListChannels
      addChannels: ChannelGroupAddChannels
      removeChannels: ChannelGroupRemoveChannels
      deleteGroup: ChannelGroupDeleteGroup
    };

    ' push
    instance.push = {
      addChannels: PushAddChannels
      removeChannels: PushRemoveChannels
      deleteDevice: PushRemoveDevice
      listChannels: PushListChannels
    }
    ' end Push

    ' presence
    instance.whereNow = WhereNow

    ' end presence

    ' end mounting endpoints

    return instance
end Function
