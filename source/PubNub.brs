

Function PubNub(config as Object) as Object
    instance = {
        publishKey: config.publishKey,
        subscribeKey: config.subscribeKey,
        authKey: config.authKey,
        uuid: config.uuid,
        origin: config.origin,
        secure: config.secure
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

    ' start mounting endpoints
    instance.publish = Publish
    instance.time = Time
    ' end mounting endpoints

    return instance
end Function
