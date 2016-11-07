' brief:      Client's status/events observers manager.
' discussion: To be notified about PubNub client status change or new messages/presence events on 
'             particular channel observers should be registered using this observer manager and 
'             implement functions in which observer is interested (status, presence or message).
'
' client  Reference on PubNub client 'instance' for which listener operate.
'
function PNStateListener(client as Object) as Object
    this = {private: {listeners: [], client: client}}

    this.addListener = pn_stateListenerAdd
    this.removeListener = pn_stateListenerRemove
    this.removeAllListeners = pn_stateListenerRemoveAll

    this.announceStatus = pn_stateListenerAnnounceStatus
    this.announcePresence = pn_stateListenerAnnouncePresence
    this.announceMessage = pn_stateListenerAnnounceMessage
    
    this.destroy = pn_stateListenerDestroy

    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:      Add client status/events observer.
' discussion: Only added listeners will be notified about new PubNub client state change and 
'             messages events.
'
sub pn_stateListenerAdd(listener as Object)
    listeners = m.private.listenermanager.private.listeners
    if PNArray(listeners).contains(listener) = false then listeners.push(listener)
end sub

' brief:      Remove client status/events observer.
' discussion: After observer removed it won't receive any updates from PubNub client.
'
sub pn_stateListenerRemove(listener as Object)
    PNArray(m.private.listenermanager.private.listeners).delete(listener)
end sub

' brief:  Remove all registered status/events observers.
'
sub pn_stateListenerRemoveAll()
    m.private.listenermanager.private.listeners = []
end sub

' brief:      Notify observers about PubNub client state change or information status arrival.
' discussion: Only if observer is able to respond to 'status' function call it will be notified.
'
sub pn_stateListenerAnnounceStatus(statusObject = invalid as Dynamic)
    for each listener in m.private.listeners
        if listener.status <> invalid then listener.status(m.private.client, statusObject)
    end for
end sub

' brief:      Notify observers about channel presence information change.
' discussion: Only if observer is able to respond to 'presence' function call it will be notified.
'
sub pn_stateListenerAnnouncePresence(presenceObject = invalid as Dynamic)
    for each listener in m.private.listeners
        if listener.presence <> invalid then listener.presence(m.private.client, presenceObject)
    end for
end sub

' brief:      Notify observers about new message which has been received on particular channel.
' discussion: Only if observer is able to respond to 'message' function call it will be notified.
'
sub pn_stateListenerAnnounceMessage(messageObject = invalid as Dynamic)
    for each listener in m.private.listeners
        if listener.message <> invalid then listener.message(m.private.client, messageObject)
    end for
end sub

sub pn_stateListenerDestroy()
    m.private.delete("client")
end sub
