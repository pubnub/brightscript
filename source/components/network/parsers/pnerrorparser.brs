' brief:  API call processing error information parser.
'
function PNErrorParser() as Object
    return {parse: pn_errorParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive API call failure information.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_errorParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true then
        errorData = {}
        if response.message <> invalid OR response.error <> invalid then
            errorData.information = PNObject(response.message).default(response.error)
        end if
        if response.service <> invalid then errorData.service = response.service
        
        if response.payload <> invalid then
            payload = response.payload
            errorData.channels = PNObject(payload.channels).default([])
            errorData.channelGroups = PNObject(payload["channel-groups"]).default([])
            if payload.channels = invalid AND payload["channel-groups"] = invalid then errorData.data = payload
        end if
        if PNNumber(response["status"]).isNumber() = true then errorData["status"] = response["status"]
        processedResponse = errorData
    end if
    
    return processedResponse
end function
