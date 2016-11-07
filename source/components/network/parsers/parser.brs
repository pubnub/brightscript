' brief:  Response parsers factory.
' discussion: Function allow to receive proper parser for concrete API call operation.
'
' operation Reference on one of operation types which is listed in 'PNOperationType'.
'
function PNParser(operation as String) as Function
    parser = invalid
    operations = PNOperationType()
    
    if operation = operations.PNChannelsForGroupOperation then
        parser = PNChannelGroupAuditionParser
    else if operation = operations.PNAddChannelsToGroupOperation OR operation = operations.PNRemoveChannelsFromGroupOperation OR operation = operations.PNRemoveGroupOperation then
        parser = PNChannelGroupModificationParser
    else if operation = operations.PNSetStateOperation OR operation = operations.PNStateForChannelOperation OR operation = operations.PNStateForChannelGroupOperation then
        parser = PNClientStateParser
    else if operation = operations.PNHeartbeatOperation then
        parser = PNHeartbeatParser
    else if operation = operations.PNHistoryOperation then
        parser = PNHistoryParser
    else if operation = operations.PNUnsubscribeOperation then
        parser = PNLeaveParser
    else if operation = operations.PNPublishOperation then
        parser = PNMessagePublishParser
    else if operation = operations.PNHereNowGlobalOperation OR operation = operations.PNHereNowForChannelOperation OR operation = operations.PNHereNowForChannelGroupOperation then
        parser = PNPresenceHereNowParser
    else if operation = operations.PNWhereNowOperation then
        parser = PNPresenceWhereNowParser
    else if operation = operations.PNSubscribeOperation then
        parser = PNSubscribeParser
    else if operation = operations.PNTimeOperation then
        parser = PNTimeParser
    end if
    
    return parser
end function
