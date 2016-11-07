' brief:  Heartbeat call results parser.
'
function PNHeartbeatParser() as Object
    return {parse: pn_heartbeatParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive heartbeat API call results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_heartbeatParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true AND response["status"] <> invalid AND response.service <> invalid then
        if response["status"] = 200 AND response.service = "Presence" then processedResponse = {}
    end if
    
    return processedResponse
end function
