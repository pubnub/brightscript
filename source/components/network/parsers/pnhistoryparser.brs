' brief:  History response parser.
'
function PNHistoryParser() as Object
    return {parse: pn_historyParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive history API call results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse       Reference on REST API call results from PubNub service.
' additionalData  Reference on object which store additional data which can be used during parse 
'                 process (for example cipher key for data decryption).
'
function pn_historyParse(response = invalid as Dynamic, additionalData = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    if type(additionalData) = "<uninitialized>" then additionalData = {}
    processedResponse = invalid
    
    if PNArray(response).isArray() = true AND response.count() = 3 then
        data = {
            start: PNObject(response[1]).default(0)
            "end": PNObject(response[2]).default(0)
            messages: []
        }
        messages = response[0]
        for each messageObject in messages
            timeToken = invalid
            message = messageObject
            if PNObject(messageObject).isDictionary() = true AND messageObject.message <> invalid AND messageObject.timetoken <> invalid then
                timeToken = messageObject.timetoken
                message = messageObject.message
            end if
            
            if PNString(additionalData.cipherKey).isEmpty() = false then
                decryptedMessage = invalid
                decryptionError = false
                if PNObject(message).isDictionary() = true then dataForDecryption = message["pn_other"] else dataForDecryption = message 
                if PNString(dataForDecryption).isString() = true then
                    ' TODO: Add message body decryption.
                    eventData = dataForDecryption
                    ' TODO: Convert bytearray to JSON object (roObject).
                    decryptedMessage = eventData
                end if
                
                if decryptionError = true OR decryptedMessage = invalid then
                    data.decryptError = true
                    message = messageObject
                else
                    if PNObject(message).isDictionary() = true
                        messageCopy = PNObject(message).copy()
                        messageCopy.delete("pn_other")
                        if PNObject(decryptedMessage).isDictionary() = false then
                            messageCopy["pn_other"] = decryptedMessage
                        else
                            messageCopy.append(decryptedMessage)
                        end if
                        decryptedMessage = messageCopy
                    end if
                    message = decryptedMessage
                end if
            end if
            
            if message <> invalid then
                if timeToken <> invalid then message = {message: message, timetoken: timeToken}
                data.messages.push(message)
            end if
        end for
        
        processedResponse = data
    end if
    
    return processedResponse
end function
