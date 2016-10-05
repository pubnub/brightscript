

Function Time(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "time",
        "0"
    ]

    PublishCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNTimeOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, { timetoken: response[0] })
        end if
    end Function

    HTTPRequest(requestSetup, PublishCallback)

end Function
