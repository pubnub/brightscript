sub main()
    ' Prepare shared message port.
    ' Message port should be used for both application / user events handling and PubNub client
    ' 'run-loop'
    messagePort = createObject("roMessagePort")

    ' Screen 'instance' will be used as application 'delegate' to understand when user close
    ' application.
    screen = createObject("roSGScreen")
    screen.setMessagePort(messagePort)
    screen.createScene("Scene")
    screen.show()

    canvas = CreateObject("roScreen")
    print "screen shown"

    ' Create and configure PubNub client instance.
    client = PubNub({ subscribeKey: "demo", publishKey: "demo" }, messagePort)

    '******************************************************
    '
    ' PubNub events listener configuration.
    '
    '******************************************************
    client.addListener(PNObjectEventListener())


    '******************************************************
    '
    ' Subscription example.
    '
    '******************************************************
    client.subscribe({ channels: ["roku-channel"], withPresence: false, "state": { "roku-channel": { "welcome": "online" } } })


    '******************************************************
    '
    ' Unsubscription example.
    '
    '******************************************************
    '    client.unsubscribe({
    '        channels: ["pubnub-channel", "roku-channel"]
    '        channelGroups: ["brightscript-group"]
    '    })


    '******************************************************
    '
    ' Publish message.
    '
    '******************************************************
    '    publishCallback = function(status as Object)
    '        if status.error = false then
    '            ' Handle successful message publish.
    '        else
    '            ' Handle message publish error.
    '            ?"Message publish did fail with error details:",status.errorData
    '        end if
    '    end function
    '    pubnub.publish({
    '        channel: "roku-channel"
    '        message: {hello: "world"}
    '    }, publishCallback)


    '******************************************************
    '
    ' History fetch.
    '
    '******************************************************
    '    historyCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    '        if result <> invalid then
    '            ' Handle successful history fetch.
    '            ?"Messages between "+box(result.data.start).toStr()+" .. "+box(result.data["end"]).toStr()+": "+PNObject(result.data.messages).toString()
    '        else
    '            ' Handle messages history request error.
    '            ?"Messages history fetch did fail with error details:",status.errorData
    '        end if
    '    end function
    '    client.history({channel: "hello-channel"}, historyCallback)


    '******************************************************
    '
    ' Stream Controller / Channel groups
    ' Add channels to group.
    '
    '******************************************************
    '    channelsAddCallback = function(status as Object)
    '        if status.error = false then
    '            ' Handle successful channels addition from group.
    '        else
    '            ' Handle channels addition error.
    '            ?"Channels addition error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.addChannels({
    '        channels: ["brightscript", "roku"]
    '        group: "roku-developers-community"
    '    }, channelsAddCallback)


    '******************************************************
    '
    ' Stream Controller / Channel groups
    ' Remove channels from group.
    '
    '******************************************************
    '    channelsRemoveCallback = function(status as Object)
    '        if status.error = false then
    '            ' Handle successful channels removal from group.
    '        else
    '            ' Handle channels removal error.
    '            ?"Channels remove error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.removeChannels({
    '        channels: ["brightscript"]
    '        group: "roku-developers-community"
    '    }, channelsRemoveCallback)

    '******************************************************
    '
    ' Stream Controller / Channel groups
    ' Remove channel group.
    '
    '******************************************************
    '    groupRemoveCallback = function(status as Object)
    '        if status.error = false then
    '            ' Handle successful channel group removal.
    '        else
    '            ' Handle channel group removal error.
    '            ?"Channel group remove error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.deleteGroup({group: "roku-developers-community"}, groupRemoveCallback)


    '******************************************************
    '
    ' Stream Controller / Channel groups
    ' List channels for group.
    '
    '******************************************************
    '    channelsAuditCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    '        if result <> invalid then
    '            ' Handle successful group's channels fetch.
    '            ?"Channels:",result.data.channels
    '        else
    '            ' Handle group's channels request error.
    '            ?"Group's channels fetch did fail with error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.listChannels({group: "roku-developers-community"}, channelsAuditCallback)


    '******************************************************
    '
    ' Presence
    ' Here now.
    '
    '******************************************************
    '    hereNowCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    '        if result <> invalid then
    '            ' Handle users' presence information fetch.
    '            ?"Occupancy:",result.data.occupancy
    '            ?"Participants: "+PNObject(result.data.uuids).toString()
    '        else
    '            ' Handle users' presence information request error.
    '            ?"Users' presence information fetch did fail with error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.hereNow({channel: "roku-channel"}, hereNowCallback)

    '******************************************************
    '
    ' Presence
    ' Where now.
    '
    '******************************************************
    '    whereNowCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    '        if result <> invalid then
    '            ' Handle user channels presence fetch.
    '            ?"Channels:",result.data.channels
    '        else
    '            ' Handle user channels presence request error.
    '            ?"User channels fetch did fail with error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.whereNow({uuid: client.configuration().uuid}, whereNowCallback)


    '******************************************************
    '
    ' Presence
    ' Set client state.
    '
    '******************************************************
    '    setStateCallback = function(status as Object)
    '        if status.error = false then
    '            ' Handle successful client's state change.
    '        else
    '            ' Handle client's state change error.
    '            ?"Did fail to change client's state with error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.setState({
    '        channel: "roku-channel"
    '        uuid: client.configuration().uuid
    '        "state":{welcome:{"to":"Roku channel"}}
    '    }, setStateCallback)


    '******************************************************
    '
    ' Presence
    ' Get client state.
    '
    '******************************************************
    '    getStateCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    '        if result <> invalid then
    '            ' Handle client's state for user fetch.
    '            ?"User state:",result.data.state
    '        else
    '            ' Handle client's state for user request error.
    '            ?"User state fetch did fail with error details:",status.errorData
    '        end if
    '    end function
    '
    '    client.getState({
    '        channel: "roku-channel"
    '        uuid: client.configuration().uuid
    '    }, getStateCallback)


    '******************************************************
    '
    ' Time.
    '
    '******************************************************
    '    timeCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    '        if result <> invalid then
    '            ' Handle time fetch.
    '            ?"Timetoken",result.data.timetoken
    '        else
    '            ' Handle time request error.
    '            ?"Time fetch did fail with error details:",status.errorData
    '        end if
    '    end function
    '    client.time(timeCallback)

    ' Create and configure main 'run-loop'. This 'run-loop' will be used by application to handle
    ' events and notify PubNub client about any of them.
    ' If new 'while' should be started, reference on PubNub client should be passed to it and
    ' updates should be sent from new 'while' cycle. Same 'roMessagePort' object should be reused!
    while true
        message = wait(250, messagePort)
        pubnubCanHandle = client.handleMessage(message)
        if type(message) = "roUrlEvent" and pubnubCanHandle = false then
            ' Application request handling code. If client's 'handleMessage' function return
            ' 'false' - it mean what client doesn't recognize request and probably it has been sent
            ' by application and should be handled by it.
        end if

        if message = "roSGScreenEvent" and message.isScreenClosed() = true then
            ?"Application has been closed"
            client.destroy()
            exit while
        end if
    end while
end sub

function PNObjectEventListener() as object
    return {
        status: function(client as object, status as object)
            ?"STATUS:", status
            if status <> invalid and status.error = false then
                if status.category = PNStatusCategory().PNAcknowledgmentCategory then ?"^^^^ Non-error status: ACK"
                if status.operation = PNOperationType().PNSubscribeOperation then
                    if status.category = PNStatusCategory().PNConnectedCategory then
                        ?"^^^^ Non-error status: Connected, Channel Info:", status.subscribedChannels
                    else if status.category = PNStatusCategory().PNReconnectedCategory then
                        ?"^^^^ Non-error status: Reconnected, Channel Info:", status.subscribedChannels
                    else if status.category = PNStatusCategory().PNRequestMessageCountExceededCategory then
                        ?"^^^^ Non-error status: Message Count Exceeded"
                    end if
                else if status.operation = PNOperationType().PNUnsubscribeOperation then
                    if status.category = PNStatusCategory().PNDisconnectedCategory then
                        ?"^^^^ Non-error status: Expected Disconnect"
                    end if
                else if status.operation = PNOperationType().PNHeartbeatOperation then
                    ?"Heartbeat operation successful."
                end if
            else if status <> invalid then
                if status.category = PNStatusCategory().PNAccessDeniedCategory then
                    ?"^^^^ handleErrorStatus: PAM Error: for resource Will Auto Retry?:", status.automaticallyRetry
                else if status.category = PNStatusCategory().PNDecryptionErrorCategory then
                    ?"Decryption error. Be sure the data is encrypted and/or encrypted with the correct cipher key."
                    ?"You can find the raw data returned from the server in the status.data attribute:", status.associatedObject
                    if status.operation = PNOperationType().PNSubscribeOperation then
                        associatedObject = status.associatedObject
                        ?"Decryption failed for message from channel: '" + associatedObject.channel + "' message:", associatedObject.message
                    end if
                else if status.category = PNStatusCategory().PNMalformedFilterExpressionCategory then
                    ?"Value which has been passed to filterExpression malformed."
                    ?"Please verify specified value with declared filtering expression syntax."
                else if status.category = PNStatusCategory().PNMalformedResponseCategory then
                    ?"We were expecting JSON from the server, but we got HTML, or otherwise not legal JSON."
                    ?"This may happen when you connect to a public WiFi Hotspot that requires you to auth via your web browser first, "
                    ?"or if there is a proxy somewhere returning an HTML access denied error, or if there was an intermittent server issue."
                else if status.category = PNStatusCategory().PNTimeoutCategory then
                    ?"For whatever reason, the request timed out. Temporary connectivity issues, etc."
                else if status.category = PNStatusCategory().PNNetworkIssuesCategory then
                    ?"Request can't be processed because of network issues."
                else
                    ?"Request failed... if this is an issue that is consistently interrupting the performance of your app, "
                    ?"email the output of debugDescription to support along with all available log info: ", status
                    ?"Error data", status.errorData
                end if

                if status.operation = PNStatusCategory().PNHeartbeatOperation then
                    ?"Heartbeat operation failed."
                end if
            end if
        end function
        presence: function(client as object, presence as object)
            ?"{INFO} Received '" + presence.data.presenceEvent + "' presence event with details:", presence.data.presence
        end function
        message: function(client as object, message as object)
            ?"{INFO} Received message from '" + box(message.data.publisher).toStr() + "' on '" + message.data.channel + "': ", message.data.message
        end function
    }
end function
