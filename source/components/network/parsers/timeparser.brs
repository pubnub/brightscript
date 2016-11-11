' brief:  Time API call response parser.
'
function PNTimeParser() as Object
    return {parse: pn_timeParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive service timetoken information.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_timeParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid     

    if PNArray(response).isArray() = true AND response.count() = 1 then processedResponse = {timetoken: response[0]}
    
    return processedResponse
end function
