
Function ChannelGroupDeleteGroup(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "v1",
        "channel-registration",
        "sub-key",
        m.subscribeKey,
        "channel-group",
        config.channelGroup,
        "remove"
    ]

    ChannelGroupDeleteGroupCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNRemoveGroupOperation"
        callback(status, invalid)
    end Function

    HTTPRequest(requestSetup, ChannelGroupDeleteGroupCallback)

end Function
