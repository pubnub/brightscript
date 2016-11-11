' brief:  Channels / groups subscription response parser.
'
function PNSubscribeParser() as Object
    return {parse: pn_subscriptionParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive events and messages from subscription.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse       Reference on REST API call results from PubNub service.
' additionalData  Reference on object which store additional data which can be used during parse 
'                 process (for example cipher key for data decryption).
'
function pn_subscriptionParse(response = invalid as Dynamic, additionalData = invalid as Dynamic) as Dynamic
    if type(additionalData) = "<uninitialized>" then additionalData = {}
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true AND response.t <> invalid then
        timetokenObject = response.t
        timetoken = timetokenObject.t
        region = timetokenObject.r
        feedEvents = response.m
        if feedEvents.count() > 0 then
            events = []
            for each evt in feedEvents
                parsedEvent = pn_subscriptionParseEvent(evt, additionalData)
                if parsedEvent.timetoken = invalid then parsedEvent.timetoken = timetoken
                events.push(parsedEvent)
            end for
            feedEvents = events
        end if
        
        processedResponse = {events: feedEvents, timetoken: timetoken, region: region}
    end if
    
    return processedResponse
end function

' brief:      Extract message or presence event from received object.
' discussion: Depending from name of channel from which object has been received it can be processed
'             as message or presence event.
'
' data            Reference on single event object from which message should be extracted.
' additionalData  Reference on object which store additional data which can be used during parse 
'                 process (for example cipher key for data decryption).
'
function pn_subscriptionParseEvent(event = invalid as Dynamic, additionalData = invalid as Dynamic) as Dynamic
    isPresenceEvent = PNString(event.c).hasSuffix("-pnpres")
    parsedEvent = {}
    channel = event.c.replace("-pnpres", "")
    subscriptionMatch = event.b
    if subscriptionMatch = channel then subscriptionMatch = invalid
    parsedEvent.envelope = pn_subscriptionParseEnvelopeInformation(event)
    parsedEvent.subscription = PNObject(subscriptionMatch).default(channel)
    parsedEvent.channel = channel

    timetokenObject = PNObject(event.o).default(event.p)
    if PNObject(timetokenObject).isDictionary() = true then
        parsedEvent.timetoken = timetokenObject.t
        parsedEvent.region = timetokenObject.r
    end if
    
    if isPresenceEvent = true then
        presenceEvent = pn_subscriptionPresenceFromData(event.d)
        if presenceEvent <> invalid then parsedEvent.append(presenceEvent)
    else
        message = pn_subscriptionMessageFromData(event.d, additionalData)
        if message <> invalid then parsedEvent.append(message)
    end if

    return parsedEvent
end function

' brief:      Extract presence event information from received event.
' discussion: Function allow extract remote client presence change notification.
'
' data  Reference on single event object from which presence information should be extracted.
'
function pn_subscriptionPresenceFromData(data = invalid as Dynamic) as Object
    presence = {
        presenceEvent: PNObject(data.action).default("interval")
        presence: {
            timetoken: data.timestamp
            occupancy: PNObject(data.occupancy).default(0)
        }
    }
    if data.uuid <> invalid then presence.presence.uuid = data.uuid
    if data.data <> invalid then presence.presence.state = data.data
    
    return presence
end function

' brief:      Extract sent message from received event.
' discussion: Function allow extract message which has been published by remote client and 
'             additionally pre-process it before returning to callbacks. Decryption can be one of 
'             possible pre-processing stages.
'
' data            Reference on single event object from which message should be extracted.
' additionalData  Reference on object which store additional data which can be used during parse 
'                 process (for example cipher key for data decryption).
'
function pn_subscriptionMessageFromData(data = invalid as Dynamic, additionalData = invalid as Dynamic) as Object
    message = invalid
    
    if PNString(additionalData.cipherKey).isEmpty() = false then
        decryptedEvent = invalid
        decryptionError = false
        message = {}
        if PNObject(data).isDictionary() = true then dataForDecryption = data["pn_other"] else dataForDecryption = data
        if PNString(dataForDecryption).isString() = true then
            ' TODO: Add message body decryption.
            decryptedEventData = dataForDecryption
            ' TODO: Convert bytearray to JSON object (roObject).
            decryptedEvent = decryptedEventData
        end if
        
        if decryptionError = true OR decryptedEvent = invalid then
            message = {decryptError: true, message: dataForDecryption}
        else
            if PNObject(data).isDictionary() = true
                dataCopy = PNObject(data).copy()
                dataCopy.delete("pn_other")
                if PNObject(decryptedEvent).isDictionary() = false then
                    dataCopy["pn_other"] = decryptedEvent
                else
                    dataCopy.append(decryptedEvent)
                end if
                decryptedEvent = dataCopy
            end if
            message.message = decryptedEvent
        end if
    else
        message = {message: data}
    end if
    
    return message
end function

' brief:      Extract delivered object envelope information.
' discussion: Enveloper object contain critical information which may help during issues resolve 
'             process.
'
' information  Reference on single event information (received from list of objects on subscribe 
'              long-poll completion).
'
function pn_subscriptionParseEnvelopeInformation(information as Object) as Object
    return {
        shard: information.a
        flags: information.f
        senderIdenrifier: information.i
        sequence: information.s
        subscribeKey: information.k
        replicationMap: information.r
        eatAfterReading: information.ear
        metadata: information.u
        waypoints: information.w
    }
end function
