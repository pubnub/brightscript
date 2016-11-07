' brief:  User's presence information parser.
'
function PNPresenceWhereNowParser() as Object
    return {parse: pn_presenceWhereNowParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive user's presence information.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_presenceWhereNowParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).valueAtKeyPath("payload.channels") <> invalid then
        processedResponse = {"channels": response.payload.channels}
    end if
    
    return processedResponse
end function
