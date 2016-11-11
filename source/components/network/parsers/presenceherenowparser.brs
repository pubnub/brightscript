' brief:  Channels / group presence information parser.
'
function PNPresenceHereNowParser() as Object
    return {parse: pn_presenceHereNowParse}
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:       Process service response and try receive channel / groups presence audition results.
' discussion:  Simple verification done by parser and if unknown data has been sent, parse will be 
'              treated as failed and error status object will be constructed.
'
' resoponse  Reference on REST API call results from PubNub service.
'
function pn_presenceHereNowParse(response = invalid as Dynamic) as Dynamic
    if type(response) = "<uninitialized>" then response = invalid
    processedResponse = invalid
    
    if PNObject(response).isDictionary() = true then
        hereNowData = invalid
        
        if PNObject(response).valueAtKeyPath("payload.channels") <> invalid then
            payload = response.payload
            data = {
                totalChannels: PNObject(payload["total_channels"]).default(0)
                totalOccupancy: PNObject(payload["total_occupancy"]).default(0)
                channels: {}
            }
            for each channelName in payload.channels
                channelData = payload.channels[channelName]
                parsedChannelData = {occupancy: channelData.occupancy}
                if channelData.uuids <> invalid then
                    parsedChannelData.uuids = pn_presenceHereNowUUIDsData(channelData.uuids)
                end if
                data.channels[channelName] = parsedChannelData
            end for
            hereNowData = data
        else if response.uuids <> invalid then
            hereNowData = {
                occupancy: PNObject(response.occupancy).default(0)
                uuids: pn_presenceHereNowUUIDsData(response.uuids)
            }
        else if response.occupancy <> invalid then
            hereNowData = {occupancy: PNObject(response.occupancy).default(0)}
        end if
        
        processedResponse = hereNowData
    end if
    
    return processedResponse
end function

' brief:      Extract remote clients information.
' discussion: Depending on whether for channel or group presence information has been requested 
'             there can be different data types in response.
'
function pn_presenceHereNowUUIDsData(uuids = invalid as Dynamic) as Object
    parsedUUIDData = []
    
    for each uuidData in uuids
        parsedData = uuidData
        if type(uuidData) = "roAssociativeArray" then
            data = {uuid: uuidData.uuid}
            if uuidData.state <> invalid then data.state = uuidData.state
            parsedData = data
        end if
        
        parsedUUIDData.push(parsedData)
    end for
    
    return parsedUUIDData
end function
