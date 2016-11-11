' brief:      PubNub service acknowledgment object.
' discussion: Object used by PubNub client to inform what called API endpoint successfully 
'             completed.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNAcknowledgmentStatus(request as Object) as Object
    return PNErrorStatus(request)
end function
