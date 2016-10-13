
Function Subscribe(config as Object, callback as Function)
    urlt = CreateObject("roUrlTransfer")
    requestSetup = createRequestConfig(m)
    requestSetup.callback = callback

    stringifiedChannelList = ","

    if config.channels <> invalid then
      stringifiedChannelList = implode(",", config.channels)
    end if

    if config.timetoken <> invalid then
        requestSetup.query.tt = config.timetoken.ToStr()
    end if

    if config.region <> invalid then
        requestSetup.query.tr = config.region
    end if

    if config.filterExpression <> invalid then
        requestSetup.query["filter-expr"] = config.filterExpression
    end if

    if config.channelGroups <> invalid then
        requestSetup.query["channel-group"] = implode(",", config.channelGroups)
    end if

    requestSetup.path = [
        "v2",
        "subscribe",
        m.subscribeKey,
        urlt.Escape(stringifiedChannelList),
        "0"
    ]

    SubscribeCallback = Function (status as Object, response as Object, callback as Function)
        status.operation = "PNSubscribeOperation"

        if status.error then
            callback(status, invalid)
        else
            messages = []
            metadata = {
                timetoken: response.t.t,
                region: response.t.r
            }

            For Each rawMessage In response.m
              publishMetaData = {
                publishTimetoken: rawMessage.p.t,
                region: rawMessage.p.r
              }

              parsedMessage = {
                shard: rawMessage.a,
                subscriptionMatch: rawMessage.b,
                channel: rawMessage.c,
                payload: rawMessage.d,
                flags: rawMessage.f,
                issuingClientId: rawMessage.i,
                subscribeKey: rawMessage.k,
                originationTimetoken: rawMessage.o,
                publishMetaData: publishMetaData
              }

              messages.push(parsedMessage)
            End For

            callback(status, { messages: messages, metadata: metadata })
        end if
    end Function

    HTTPRequest(requestSetup, SubscribeCallback)

end Function
