

Function PubNub(config as Object) as Object
    instance = {
        publishKey: config.publishKey,
        subscribeKey: config.subscribeKey,
        origin: config.origin,
        secure: config.secure
    }
    
    if instance.secure = invalid then
        instance.secure = false
    end if

    if instance.origin = invalid then
        instance.origin = "pubsub.pubnub.com"
    end if
        
    instance.publish = Publish

    return instance
end Function