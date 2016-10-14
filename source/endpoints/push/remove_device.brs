
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

        if status.error then
            callback(status, invalid)
        else
            callback(status, response)
        end if
    end Function

    HTTPRequest(requestSetup, PushRemoveDeviceCallback)

end Function
