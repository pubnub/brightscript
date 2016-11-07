' brief:      Published messages sequence tracking manager.
' discussion: PubNub client allow to assign for each published messages it's sequence number. 
'             Manager allow to keep track on published sequence number even after application 
'             restart.
'
' config  Reference on object which is used to configure PubNub client.
'
function PNPublishSequence(config as Object) as Object
    this = {}
    this.private = {
        registry: createObject("roRegistrySection", config.publishKey)
        sequenceNumber: 0
        loadFromRegistry: pn_publishSequenceLoadFromRegistry
        storeToRegistry: pn_publishSequenceStoreToRegistry
    }
    this.sequenceNumber = pn_publishSequenceNumber
    this.nextSequenceNumber = pn_publishSequenceNextNumber
    
    ' Load initial information from registry / persistent storage.
    this.private.loadFromRegistry()
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Retrieve current sequence number value.
'
function pn_publishSequenceNumber() as Integer
    return m.private.sequenceNumber
end function

' brief:      Retrieve next sequence number which should be used.
' discussion: Depending from configuration it is possible only receive or also update stored 
'             sequence number.
'
' shouldUpdateCurrent  Whether current sequence number should be updated with next by order value 
'                      or not.
'
function pn_publishSequenceNextNumber(shouldUpdateCurrent as Boolean) as Integer
    nextSequenceNumber = m.private.sequenceNumber
    if nextSequenceNumber = 2147483647 then nextSequenceNumber = 1 else nextSequenceNumber = nextSequenceNumber + 1
    if shouldUpdateCurrent = true then
        m.private.sequenceNumber = nextSequenceNumber
        m.private.storeToRegistry()
    end if
    
    return nextSequenceNumber
end function

' brief:      Load previously used publish sequence number.
' discussion: Registry section used as persistent storage for this information.
'
sub pn_publishSequenceLoadFromRegistry()
    m.sequenceNumber = 0
    if m.registry.exists("pn_publishSequenceNumber") then
        m.sequenceNumber = m.registry.read("pn_publishSequenceNumber").toInt()
    end if
end sub

' brief:      Store current publish sequence number.
' discussion: Use registry section to persistently store currently used publish sequence number.
'
sub pn_publishSequenceStoreToRegistry()
    m.registry.write("pn_publishSequenceNumber", box(m.sequenceNumber).toStr())
    m.registry.flush()
end sub
