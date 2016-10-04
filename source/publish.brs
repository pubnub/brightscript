

Function Publish(config as Object)
    print config
    requestSetup = {}
    HTTP_request(requestSetup, PublishCallback)

end Function

Function PublishCallback(response as Object)
    print "publish callback"
end Function