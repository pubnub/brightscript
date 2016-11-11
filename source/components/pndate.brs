function PNDate(date as Object) as Object
    this = {private: {value: date}}
    this.toTimeToken = pn_dateToTimeToken
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Convert date object to PubNub supported time token.
'
function pn_dateToTimeToken() as String
    seconds$ = box(m.private.value.asSeconds()).toStr()
    milliseconds$ = box(m.private.value.getMilliseconds()).toStr()
    nanoseconds$ = "0000000"
    
    return seconds$+milliseconds$+nanoseconds$.mid(milliseconds$.len())
end function
