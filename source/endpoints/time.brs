sub Time(callback as Function)
    requestSetup = createRequestConfig(m)
    requestSetup.append({"callback": callback, "path": ["time", "0"]})

    TimeCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNTimeOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, { timetoken: response[0] })
        end if
    end Function

    HTTPRequest(requestSetup, PublishCallback)
end sub
