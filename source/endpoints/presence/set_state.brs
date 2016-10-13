
Function SetState(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    stringifiedChannelList = ","

    if config.channels then
      stringifiedChannelList = implode(",", channels)
    end if

    requestSetup.path = [
        "v2",
        "presence",
        "sub-key",
        m.subscribeKey,
        "uuid"
    ]

    '' TODO

end Function
