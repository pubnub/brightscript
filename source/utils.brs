

Function HTTP_request(config as Object, callback as Function)
    print "m"
    print m

    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.SetUrl("http://www.khanacademy.org/api/v1/playlists")
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()
                if (code = 200)
                    json = ParseJSON(msg.GetString())
                    callback(json)
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif
    return invalid
end Function