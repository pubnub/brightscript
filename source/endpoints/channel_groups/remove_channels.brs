
Function ChannelGroupRemoveChannels(config as Object, callback as Function)
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
    ]

    requestSetup.config.query.remove = implode(",", config.channels)

    ChannelGroupRemoveChannelsCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNRemoveChannelsFromGroupOperation"
        callback(status, invalid)
    end Function

    HTTPRequest(requestSetup, ChannelGroupRemoveChannelsCallback)

end Function
