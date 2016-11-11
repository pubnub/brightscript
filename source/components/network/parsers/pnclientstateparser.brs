' brief:  Client's state audition / modification response parser.
'
function PNClientStateParser() as Object
    return {parse: pn_clientStateParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive client's state audition / modification
'              results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_clientStateParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true AND response["status"] = 200 then
        payload = PNObject(response.payload).default({})
        processedResponse = {channels: PNObject(payload.channels).default([]), state: payload}
    end if
    
    return processedResponse
end function
