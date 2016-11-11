' brief:  Full list of available REST API.
'
function PNOperationType() as Object
    return {
        ' brief:      Subscribe operations.
        ' discussion: These operations allow client to start / stop real-time events listening via 
        '             delegate callbacks.
        PNSubscribeOperation: "PNSubscribeOperation"
        PNUnsubscribeOperation: "PNUnsubscribeOperation"
        
        ' brief:      Data publish operation.
        ' discussion: This operation allow client to send data to one of real-time channels and 
        '             other remote clients will receive it. 
        PNPublishOperation: "PNPublishOperation"
        
        ' brief:      Real-time channel storage access operation.
        ' discussion: This operation allow client to get access to data which has been sent to 
        '             real-time channel some time ago or for time when client has been offline.
        PNHistoryOperation: "PNHistoryOperation"
        
        ' brief:      Presence information access operations.
        ' discussion: These operations allow client to get presence information about particular
        '             channel or group of channels or for particular user presence in those 
        '             channels.
        PNWhereNowOperation: "PNWhereNowOperation"
        PNHereNowGlobalOperation: "PNHereNowGlobalOperation"
        PNHereNowForChannelOperation: "PNHereNowForChannelOperation"
        PNHereNowForChannelGroupOperation: "PNHereNowForChannelGroupOperation"
        
        ' brief:      Client heartbeat operation.
        ' discussion: One of presence operations who's operation related to PubNub client itself and
        '             allow to notify PubNub service about client presence (what client still online
        '             and active).
        PNHeartbeatOperation: "PNHeartbeatOperation"
        
        ' brief:      Client's state manipulation operations.
        ' discussion: These operations allow to get / set client's state on particular channel or 
        '             group of channels.
        PNSetStateOperation: "PNSetStateOperation"
        PNStateForChannelOperation: "PNStateForChannelOperation"
        PNStateForChannelGroupOperation: "PNStateForChannelGroupOperation"
        
        ' brief:      Stream controller manage operations.
        ' discussion: These operations allow client to modify / audit channels group managed by 
        '             stream controller.
        PNAddChannelsToGroupOperation: "PNAddChannelsToGroupOperation"
        PNRemoveChannelsFromGroupOperation: "PNRemoveChannelsFromGroupOperation"
        PNRemoveGroupOperation: "PNRemoveGroupOperation"
        PNChannelsForGroupOperation: "PNChannelsForGroupOperation"
        
        ' brief: Service current time fetch operation.
        PNTimeOperation: "PNTimeOperation"
    }
end function
