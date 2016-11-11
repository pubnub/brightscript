' brief:  Channel group audition response parser.
'
function PNChannelGroupAuditionParser() as Object
    return {parse: pn_channelGroupAuditionParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive channel group audition results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_channelGroupAuditionParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).valueAtKeyPath("payload") <> invalid then
        payload = PNObject(response.payload).default({})
        processedResponse = {
            channels: PNObject(payload.channels).default([])
            groups: PNObject(payload.groups).default([])
        }
    end if
    
    return processedResponse
end function
