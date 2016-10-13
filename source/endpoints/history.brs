

Function History(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "v2",
        "history",
        "sub-key",
        m.subscribeKey,
        "channel",
        config.channel
    ]

    if config.start <> invalid then
        requestSetup.query.start = config.start
    end if

    if config.end <> invalid then
        request.query.end = config.end
    end if

    if config.count <> invalid then
        request.query.count = config.count
    end if

    if config.reverse <> invalid then
        request.query.reverse = config.reverse
    end if

    HistoryCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNHistoryOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, response)
        end if
    end Function

    HTTPRequest(requestSetup, HistoryCallback)

end Function
