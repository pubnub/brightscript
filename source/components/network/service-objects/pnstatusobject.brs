' brief:      Status object constructor.
' discussion: Basing on operation type different object constructors will be provided.
'
' operation  One of operations which is specified in 'PNOperationType'.
'
function PNStatusObjectForOperation(operation as String) as Function
    operations = PNOperationType()
    constructor = invalid
    
    failableOperations = [
        operations.PNHistoryOperation
        operations.PNWhereNowOperation
        operations.PNHereNowGlobalOperation
        operations.PNHereNowForChannelOperation
        operations.PNHereNowForChannelGroupOperation
        operations.PNStateForChannelOperation
        operations.PNStateForChannelGroupOperation
        operations.PNChannelsForGroupOperation
        operations.PNTimeOperation
    ]
    acknowledgeableOperations = [
        operations.PNUnsubscribeOperation
        operations.PNHeartbeatOperation
        operations.PNAddChannelsToGroupOperation
        operations.PNRemoveChannelsFromGroupOperation
        operations.PNRemoveGroupOperation
    ]
    if operation = operations.PNSubscribeOperation then
        constructor = PNSubscribeStatus
    else if operation = operations.PNPublishOperation then
        constructor = PNPublishStatus
    else if operation = operations.PNSetStateOperation then
        constructor = PNClientStateUpdateStatus
    else if PNArray(failableOperations).contains(operation) = true then
        constructor = PNErrorStatus
    else if PNArray(acknowledgeableOperations).contains(operation) = true then
        constructor = PNAcknowledgmentStatus
    end if
        
    return constructor
end function
