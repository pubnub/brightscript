sub main()
    canvas = CreateObject("roImageCanvas")
    canvas.setLayer(0, { color: "#884400" })
    canvas.show()
    print "canvas shown"
    sleep(2000)

    ' Create and configure PubNub client instance.
    client = PubNub({ subscribeKey: "demo-36", publishKey: "demo-36", logVerbosity: true })

    ' PubNub events listener configuration.
    listener = {
        status: function(status):print "status", status:end function
        presence: function(presence):print "presence", presence:end function
        message: function(message):print "message", message:end function
    }
    client.addListener(listener)
    client.subscribe({channels: ["hello"], withPresence: true})
    '
    ''publishCallback = Function(status as Object, response as Object)
    ''    print "status", status
    ''    print "response", response
    'end Function

    'client.publish({ channel: "hello", message: { such: "wow"} }, publishCallback)
    '

    'publishCallback = Function(status as Object, response as Object)
    ''    print "status", status
    ''    print "response", response.messages
    'end Function

    'client.subscribe({ channels: ["hello"], timetoken: 10 }, publishCallback)

end sub
