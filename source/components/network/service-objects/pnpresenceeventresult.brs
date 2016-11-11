' brief:      Presence event representation object.
' discussion: Object used by PubNub client to provide information about received presence event.
'
' status       Reference on object which contain subscription information.
' presenceData Reference on parsed presence information which should be provided to user.
'
function PNPresenceEventResult(subscribeStatus as Object, presenceData as Object) as Object
    this = subscribeStatus.private.copyWithMutatedData(subscribeStatus, presenceData)
    this.data = presenceData
    this.data.delete("region")
    this.delete("private")
    
    return this
end function