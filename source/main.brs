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
    
    canvas = CreateObject("roImageCanvas")
    canvas.setLayer(0, { color: "#884400" })
    print "canvas shown"
    
    ' Create and configure PubNub client instance.
    client = PubNub({ subscribeKey: "demo-36", publishKey: "demo-36", secure: false, presenceHeartbeatValue: 30}, messagePort)
    
    ' Publish message.
'    publishCallback = Function(status as Object)
'       print "{publish} operation", status.operation
'       print "{publish} category", status.category
'       print "{publish} error", status.error
'       print "{publish} data", status.data
'       print "{publish} error data", status.errordata
'       print "{publish} status", status
'    end Function
'    client.publish({ channel: "hello-channel", message: { such: "wow"}, sendByPost: true }, publishCallback)

    ' PubNub events listener configuration.
    client.addListener(PNObjectEventListener())
    client.subscribe({channels: ["hello-channel"], withPresence: true, "state":{"hello-channel":{"some":"data"}}})

    
   
    
    ' Create and configure main 'run-loop'. This 'run-loop' will be used by application to handle 
    ' events and notify PubNub client about any of them.
    ' If new 'while' should be started, reference on PubNub client should be passed to it and 
    ' updates should be sent from new 'while' cycle. Same 'roMessagePort' object should be reused!
    while true
        message = wait(250, messagePort)
        pubnubCanHandle = client.handleMessage(message)
        if type(message) = "roUrlEvent" AND pubnubCanHandle = false then
            ' Application request handling code. If client's 'handleMessage' function return 
            ' 'false' - it mean what client doesn't recognize request and probably it has been sent
            ' by application and should be handled by it.
        end if
        
        if message = "roSGScreenEvent" AND message.isScreenClosed() = true then
            ?"Application has been closed" 
            client.destroy()
            exit while
        end if
    end while
end sub

function PNObjectEventListener() as Object
    return {
        status: function(client as Object, status as Dynamic)
            if status.error = false then
                if status.category = PNStatusCategory().PNAcknowledgmentCategory then ?"^^^^ Non-error status: ACK"
                if status.operation = PNOperationType().PNSubscribeOperation then
                    if status.category = PNStatusCategory().PNConnectedCategory then 
                        ?"^^^^ Non-error status: Connected, Channel Info:",status.subscribedChannels
                    else if status.category = PNStatusCategory().PNReconnectedCategory then 
                        ?"^^^^ Non-error status: Reconnected, Channel Info:",status.subscribedChannels
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
            else
                if status.category = PNStatusCategory().PNAccessDeniedCategory then
                    ?"^^^^ handleErrorStatus: PAM Error: for resource Will Auto Retry?:", status.automaticallyRetry
                else if status.category = PNStatusCategory().PNDecryptionErrorCategory then
                    ?"Decryption error. Be sure the data is encrypted and/or encrypted with the correct cipher key."
                    ?"You can find the raw data returned from the server in the status.data attribute:", status.associatedObject
                    if status.operation = PNOperationType().PNSubscribeOperation then
                        associatedObject = status.associatedObject
                        ?"Decryption failed for message from channel: '"+associatedObject.channel+"' message:",associatedObject.message
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
                    ?"email the output of debugDescription to support along with all available log info: ",status
                    ?"Error data",status.errorData
                end if
                
                if status.operation = PNStatusCategory().PNHeartbeatOperation then
                    ?"Heartbeat operation failed."
                end if
            end if
        end function
        presence: function(client as Object, presence as Object)
            ?"{INFO} Received '"+presence.data.presenceEvent+"' presence event with details:", presence.data.presence
        end function
        message: function(client as Object, message as Object)
            ?"{INFO} Received message on '"+message.data.channel+"': ",message.data.message
        end function
    }
end function
