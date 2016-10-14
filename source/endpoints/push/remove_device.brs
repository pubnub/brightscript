
Function PushRemoveDevice(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "v1",
        "push",
        "sub-key",
        m.subscribeKey,
        "devices",
        config.device,
        "remove"
    ]

    requestSetup.config.query.type = config.pushGateway

    PushRemoveDeviceCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNRemoveAllPushNotificationsOperation"
        callback(status, invalid)
    end Function

    HTTPRequest(requestSetup, PushRemoveDeviceCallback)

end Function
