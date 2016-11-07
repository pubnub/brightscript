' brief:  Unsubscribe / leave response parser.
'
function PNLeaveParser() as Object
    return {parse: pn_leaveParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive unsubscribe / leave API call results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_leaveParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true then processedResponse = {}
    
    return processedResponse
end function
