
Function PushRemoveChannels(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "v1",
        "push",
        "sub-key",
        m.subscribeKey,
        "devices",
        config.device
    ]

    requestSetup.config.query.remove = implode(",", config.channels)
    requestSetup.config.query.type = config.pushGateway

    PushRemoveChannelsCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNPushNotificationEnabledChannelsOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, response)
        end if
    end Function

    HTTPRequest(requestSetup, PushRemoveChannelsCallback)

end Function
