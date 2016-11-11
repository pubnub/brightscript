' brief:      Results object constructor.
' discussion: Basing on operation type different object constructors will be provided.
'
' operation  One of operations which is specified in 'PNOperationType'.
'
function PNResultObjectForOperation(operation as String) as Function
    operations = PNOperationType()
    constructor = invalid
    
    if operation = operations.PNHistoryOperation then
        constructor = PNHistoryResult
    else if operation = operations.PNWhereNowOperation then
        constructor = PNPresenceWhereNowResult
    else if operation = operations.PNHereNowGlobalOperation then
        constructor = PNPresenceGlobalHereNowResult
    else if operation = operations.PNHereNowForChannelOperation then
        constructor = PNPresenceChannelHereNowResult
    else if operation = operations.PNHereNowForChannelGroupOperation then
        constructor = PNPresenceChannelGroupHereNowResult
    else if operation = operations.PNStateForChannelOperation then
        constructor = PNChannelClientStateResult
    else if operation = operations.PNStateForChannelGroupOperation then
        constructor = PNChannelGroupClientStateResult
    else if operation = operations.PNChannelsForGroupOperation then
        constructor = PNChannelGroupChannelsResult
    else if operation = operations.PNTimeOperation then
        constructor = PNTimeResult
    end if
    
    return constructor
end function
