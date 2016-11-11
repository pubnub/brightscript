' brief:  Message publish response parser.
'
function PNMessagePublishParser() as Object
    return {parse: pn_messagePublishParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive message publish results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_messagePublishParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if response = invalid OR PNArray(response).isArray() = true then
        information = "Message Not Published"
        timeToken = invalid
        if PNArray(response).isArray() = true AND response.count() = 3 then
            information = response[1]
            timeToken = response[2]
        else
            timeToken = PNDate(createObject("roDateTime")).toTimeToken()
        end if
        
        processedResponse = {information: information, timetoken: timeToken}
    end if
    
    return processedResponse
end function
