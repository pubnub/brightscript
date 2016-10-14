
Function ChannelGroupAddChannels(config as Object, callback as Function)
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

    requestSetup.config.query.add = implode(",", config.channels)

    ChannelGroupAddChannelsCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNAddChannelsToGroupOperation"
        callback(status, invalid)
    end Function

    HTTPRequest(requestSetup, ChannelGroupAddChannelsCallback)

end Function
