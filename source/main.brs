sub main()
    canvas = CreateObject("roImageCanvas")
    canvas.setLayer(0, { color: "#884400" })
    canvas.show()
    print "canvas shown"
    sleep(2000)
    
    request = PubNub({ subscribeKey: "demo-36", publishKey: "demo-36" })
    print request
    request.publish({ channel: "hello", message: "hi"})
    print "hello"
    print request
    
    
end sub