

Function WhereNow(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "v2",
        "presence",
        "sub-key",
        m.subscribeKey,
        "uuid"
    ]

    if config.uuid <> invalid then
        requestSetup.path.push(config.uuid)
    else
        requestSetup.path.push(m.uuid)
    end if

    WhereNowCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNWhereNowOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, response)
        end if
    end Function

    HTTPRequest(requestSetup, WhereNowCallback)

end Function
