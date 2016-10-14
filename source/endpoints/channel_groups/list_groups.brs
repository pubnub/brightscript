
Function ChannelGroupListGroups(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "v1",
        "channel-registration",
        "sub-key",
        m.subscribeKey,
        "channel-group"
    ]

    ChannelGroupListGroupsCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNChannelGroupsOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, { groups: response.payload.groups })
        end if

    end Function

    HTTPRequest(requestSetup, ChannelGroupListGroupsCallback)

end Function
