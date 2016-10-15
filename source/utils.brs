Function pnMinValue(val1 as Object, val2 as Object) as Object
    if val1 = invalid then val1 = 0
    if val2 = invalid then val2 = 0
    if val1 < val2 then return val1 else return val2
end Function

Function pnMaxValue(val1 as Object, val2 as Object) as Object
    if val1 = invalid then val1 = 0
    if val2 = invalid then val2 = 0
    if val1 > val2 then return val1 else return val2
end Function

Function pnDefaultValue(value as Object, default as Object) as Object
    if value <> invalid then return value else return default
end Function

function pnArrayContainsValue(array as Object, value as Object) as Boolean
    return pnIndexOfValueInArray(array, value) <> invalid
end function

function pnIndexOfValueInArray(array as Object, value as Object)
    index = invalid
    For itemIdx=0 To array.count() Step 1
        if array.getEntry(itemIdx) = value then index = itemIdx
        if index <> invalid then exit for
    end for
    return index
end function

function pnRemoveValueFromArray(array as Object, value as Object)
    index = pnIndexOfValueInArray(array, value)
    if index <> invalid then array.delete(index)
end function

function pnStringHasPrefix(stringValue as String, prefix as String) as Boolean
    return stringValue.left(suffix.len()) = prefix
end function

function pnStringHasSuffix(stringValue as String, suffix as String) as Boolean
    return stringValue.right(suffix.len()) = suffix
end function

Function createRequestConfig(m as Object) as Object
    queryParams = {
      pnsdk: "Pubnub-Roku/" + m.version
      uuid: m.uuid
      auth: m.authKey
    }

    return {
        secure: m.secure
        origin: m.origin
        logVerbosity: m.logVerbosity
        query: queryParams
    }
end Function

Function implode(glue, pieces)
    result = ""
    if pieces <> invalid
        for each piece in pieces
            if result <> "" then result = result + glue
            result = result + piece
        end for
    end if

    if pieces <> invalid AND result.len() > 0 then return result else return glue
end Function

Function createQueryString(queryParams as Object) as String
    chunks = []

    For Each key In queryParams
      value = queryParams[key]
      if value <> invalid then chunks.push(key + "=" + value.ToStr())
    End For

    return implode("&", chunks)
end Function

Function createRequestURL(config as Object) as String
    path = ""

    if config.secure then path = "https://" else path = "http://"

    path = path + config.origin + "/" + implode("/", config.path)
    path = path + "?" + createQueryString(config.query)

    return path
end Function

function createRequest(config as Object) as Object
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.RetainBodyOnError(true)
    request.SetUrl(createRequestURL(config))
    print "Request URL: ",request.GetUrl()
    return request
end function

Function HTTPRequest(config as Object, callback as Function, context = invalid as Object) as Object
    request = createRequest(config)
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if (request.AsyncGetToString())
        while (true)
            response = wait(0, port)
            print "HTTP event type: ",type(response)
            status = {}
            if (type(response) = "roUrlEvent") then
                code = response.GetResponseCode()
                print "HTTP status code: ",code
                print "Response code: ",response.GetResponseCode()
                status.code = code
                if code = 200 then status.error = false else status.error = true
                json = ParseJSON(response.GetString())
                if context <> invalid then
                    callback(status, json, config.callback, context)
                else
                    callback(status, json, config.callback)
                end if
                exit while
            else if response = invalid then
                status.error = true
                request.AsyncCancel()
                if context <> invalid then
                    callback(status, invalid, config.callback, context)
                else
                    callback(status, invalid, config.callback)
                end if
                exit while
            endif
        end while
    end if
    return request
end Function
