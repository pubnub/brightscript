Function History(config as Object, callback as Function)
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

    query = {count: pnMinValue(100, config.count)}
    if config.start <> invalid then query.start = config.start
    if config.end <> invalid then query.end = config.end
    if config.includeTimetoken <> invalid then
       query.include_token = config.includeTimetoken
    end if
    if config.reverse <> invalid then query.reverse = config.reverse
    requestSetup.append({"query": query})

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
