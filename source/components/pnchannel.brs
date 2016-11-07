' brief:      Channel/group names manipulation helper.
' discussion: This object contain set of functions which simplify routine names manipulation tasks.
'
function PNChannel() as Object
    this = {}
    this.namesForRequest = pn_channelNamesForRequest
    this.namesForRequestWithDefaultValue = pn_channelNamesForRequestWithDefaultValue
    this.objectsWithOutPresenceFrom = pn_channelObjectsWithOutPresenceFrom
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

function pn_channelNamesForRequest(channels = invalid as Dynamic) as Dynamic
    return pn_channelNamesForRequestWithDefaultValue(channels, invalid)
end function

function pn_channelNamesForRequestWithDefaultValue(channels = invalid as Dynamic, default = invalid as Dynamic) as Dynamic
    names = default
    if PNArray(channels).isEmpty() = false then
        urlEncoder = createObject("roUrlTransfer")
        names = ""
        for each channel in channels
            if names.len() > 0 then names = names+","
            names = names + urlEncoder.escape(channel)
        end for
    end if
    
    return names
end function

function pn_channelObjectsWithOutPresenceFrom(channels = invalid as Dynamic) as Dynamic
    names = invalid
    if PNArray(channels).isEmpty() = false then
        names = []
        for each channel in channels
            if PNString(channel).hasSuffix("-pnpres") = false AND PNArray(names).contains(channel) = false then
                names.push(channel)
            end if
        end for
    end if
    
    return names
end function