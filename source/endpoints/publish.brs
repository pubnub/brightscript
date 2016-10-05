

Function Publish(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    requestSetup.path = [
        "publish",
        m.publishKey,
        m.subscribeKey,
        "0",
        config.channel,
        "0",
        urlt.Escape(FormatJson(config.message))
    ]
        
    PublishCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNPublishOperation"

        if status.error then
            callback(status, invalid)
        else
            callback(status, { timestamp: response[2] })
        end if
    end Function
    
    HTTPRequest(requestSetup, PublishCallback)

end Function

