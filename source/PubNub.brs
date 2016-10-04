

Function PubNub(config as Object) as Object
    instance = {
        publishKey: config.publishKey,
        subscribeKey: config.subscribeKey,
        origin: "pubsub.pubnub.com",
        secure: config.secure
    }
    
    if instance.secure = invalid then
        instance.secure = false
    end if
        
    instance.publish = Publish

    return instance
end Function