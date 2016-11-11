' brief:  Channel group modification response parser.
'
function PNChannelGroupModificationParser() as Object
    return {parse: pn_channelGroupModificationParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive channel group modification results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_channelGroupModificationParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true AND response.message <> invalid AND response.error <> invalid then
        processedResponse = {}
    end if
    
    return processedResponse
end function
