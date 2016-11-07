' brief:  Send user-provided data to remote data consumer.
' discussion:  It is possible to send any JSON serializable objects to remote data consumer. Also 
'              this API allow to encrypt message and send push notifications to different platforms.
'
' params   Object with values which should be used with API call.
' callback Reference on function which will be responsible for received status and result objects 
'          handling.
'
sub PNPublish(params as Object, callback = invalid as Function, context = invalid as Dynamic)
    ' Default values initialization
    if type(callback) = "<uninitialized>" then callback = invalid
    pn_publishDefaults(params)
    
    ' Prepare information which should be used during REST API call URL preparation.
    request = pn_publishRequest(params, m)
    request.operation = PNOperationType().PNPublishOperation
    postData = request.post
    if postData <> invalid then request.delete("post")
    
    callbackData = {callback: callback, context: context, params: params, client: m, func: "publish"}
    m.private.networkManager.processOperation(request.operation, request, postData, callbackData, invalid)
end sub


REM ******************************************************
REM
REM Private functions
REM
REM ******************************************************

' brief:      Prepare user-provided message to be published.
' discussion: Depending from provided client configuration it may be required to encrypt message or
'             in addition merge it with mobile push payloads (if provided). This function allow to
'             perform all required modifications on provided object and make it possible to send
'             using PubNub publish API.
'
' params  Stores reference on object which contain information about where and how message should be
'         sent.
'
function pn_publishPreparedMessage(params as Object, context as Object) as Dynamic
    encrypted = false
    messageForPublish = formatJSON(params.message)
    if messageForPublish <> invalid then
        encryptedMessage = pn_publishEncryptedMessage(messageForPublish, context.private.config.cipherKey)
        encrypted = messageForPublish <> encryptedMessage
    end if
    
    if params.payloads.count() > 0 then
        messageForMerge = params.message
        if encrypted = true then messageForMerge = messageForPublish
        messageForPublish = pn_publishMessageMergedWithPayloads(messageForMerge, params.payloads)
    end if
    
    return messageForPublish
end function

' brief:      Encrypt message if possible.
' discussion: If during client configuration cipher key has been provided client should encrypt 
'             message before sending it.
'
' message    Reference on user-provided object which should be encrypted.
' cipherKey  Reference on encryption key which should be used with AES-128-CBC algorithm.
'
function pn_publishEncryptedMessage(message = invalid as Dynamic, cipherKey = "" as Object) as Dynamic
    encryptedMessage = message
    if PNString(message).isEmpty() = false AND PNString(cipherKey).isEmpty() = false then
        ' TODO: ADD CONTENT ENCRYPTION HERE
    end if  

    return message
end function

' brief: Merge provided message with mobile payload.
' discussion: Basing on 'message' data type it may be required to create associative array before
'             merging it with mobile payloads.
' 
' message   Reference on user-provided object which should be merged with payloads.
' payloads  Reference on associative array with mobile payload contents.
'
function pn_publishMessageMergedWithPayloads(message = invalid as Dynamic, payloads = {} as Dynamic) as Dynamic
    mergedMessage = PNObject(message).default({})
    if mergedMessage <> "roAssociativeArray" then mergedMessage = {"pn_other": params.message}
    for each pushProviderType in payloads
        payload = payloads[pushProviderType]
        providerKey = pushProviderType
        if PNString(providerKey).hasPrefix("pn_") = false then providerKey = "pn_"+pushProviderType
        if pushProviderType = "aps" then
            payload = {}
            payload[pushProviderType] = payloads[pushProviderType]
            providerKey = "pn_apns"
        end if
        mergedMessage[providerKey] = payload
    end for
    
    return formatJSON(mergedMessage)
end function

' brief:  Prepare information which should be used during REST API call URL preparation.
'
' params  Object with values which should be used with API call.
'
function pn_publishRequest(params as Object, context as Object) as Object
    request = {path:{}, query: {}}
    messageForPublish = pn_publishPreparedMessage(params, context)
    request.query.seqn = context.private.publishSequenceManager.nextSequenceNumber(true)
    
    metadataForPublish = invalid
    if params.metadata <> invalid then metadataForPublish = formatJSON(params.metadata)
    if PNString(params.channel).isEmpty() = false then request.path["{channel}"] = PNString(params.channel).escape()
    if params.storeInHistory = false then 
        request.query.store = 0
        params.delete("ttl")
    end if
    if params.ttl <> invalid then request.query.ttl = params.ttl
    if params.replicate = false then request.query.norep = "true"
    if PNString(messageForPublish).isEmpty() = false AND params.sendByPost = false then
        request.path["{message}"] = PNString(messageForPublish).escape()
    end if
    if PNString(messageForPublish).isEmpty() = false then
        if params.sendByPost = false then 
            request.path["{message}"] = PNString(messageForPublish).escape()
        else 
            request.path["{message}"] = ""
            request.post = messageForPublish
        end if
    end if 
    
    if PNString(metadataForPublish).isEmpty() = false then
        request.query["meta"] = PNString(metadataForPublish).escape()
    end if
    
    return request
end function

' brief:  Default values initialization.
'
' params  Object with values which should be used with API call.
'
sub pn_publishDefaults(params as Object)
    if getInterface(params.storeInHistory, "ifBoolean") = invalid then params.storeInHistory = true
    if getInterface(params.sendByPost, "ifBoolean") = invalid then params.sendByPost = false
    if getInterface(params.replicate, "ifBoolean") = invalid then params.replicate = true
    if PNObject(params.payloads).isDictionary() = false then params.payloads = {}
end sub
