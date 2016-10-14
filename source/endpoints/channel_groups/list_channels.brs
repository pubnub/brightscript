
Function ChannelGroupListChannels(config as Object, callback as Function)
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

    ChannelGroupListChannelsCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNChannelsForGroupOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, { channels: response.payload.channels })
        end if

    end Function

    HTTPRequest(requestSetup, ChannelGroupListChannelsCallback)

end Function
