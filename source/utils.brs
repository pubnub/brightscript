

Function createRequestConfig(m as Object) as Object
    return {
        secure: m.secure
        origin: m.origin
        logVerbosity: m.logVerbosity
    }
end Function

Function implode(glue, pieces)
    result = ""
    for each piece in pieces
        if result <> ""
            result = result + glue
        end if
        result = result + piece
    end for

    return result
end Function

Function createQueryString(queryParams as Object) as String
    return "a=10&b=15"
end Function

Function createPath(config as Object) as String
    path = ""

    if config.secure then
        path = path + "https://"
    else
        path = path + "http://"
    end if

    path = path + config.origin + "/" + implode("/", config.path)

    if config.query <> invalid then
        path = path + "?" + createQueryString(config.query)
    end if

    return path
end Function

Function HTTPRequest(config as Object, callback as Function)
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.SetUrl(createPath(config))
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            status = {}
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()
                status.code = code
                status.error = false
                if (code = 200)
                    json = ParseJSON(msg.GetString())
                    callback(status, json, config.callback)
                endif
            else if (event = invalid)
                status.error = true
                request.AsyncCancel()
                callback(status, invalid, config.callback)
            endif
        end while
    end if
    return invalid
end Function
