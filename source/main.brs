sub main()
    canvas = CreateObject("roImageCanvas")
    canvas.setLayer(0, { color: "#884400" })
    canvas.show()
    print "canvas shown"
    sleep(2000)

    request = PubNub({ subscribeKey: "demo-36", publishKey: "demo-36", logVerbosity: true })

    '
    ''publishCallback = Function(status as Object, response as Object)
    ''    print "status", status
    ''    print "response", response
    'end Function

    'request.publish({ channel: "hello", message: { such: "wow"} }, publishCallback)
    '

    'publishCallback = Function(status as Object, response as Object)
    ''    print "status", status
    ''    print "response", response.messages
    'end Function

    'request.subscribe({ channels: ["hello"], timetoken: 10 }, publishCallback)

end sub
