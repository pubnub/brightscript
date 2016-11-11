' brief:      Received message representation object.
' discussion: Object used by PubNub client to provide information about received message object.
'
' status      Reference on object which contain subscription information.
' messageData Reference on parsed received messages which should be provided to user.
'
function PNMessageResult(subscribeStatus as Object, messageData = invalid as Dynamic) as Object
    this = subscribeStatus.private.copyWithMutatedData(subscribeStatus, messageData)
    this.data = messageData
    this.data.publisher = PNObject(messageData).valueAtKeyPath("envelope.senderidenrifier")
    this.data.delete("region")
    this.delete("private")
    
    return this
end function