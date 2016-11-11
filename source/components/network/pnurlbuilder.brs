' brief:      Responsible for URL construction.
' discussion: Basing on provided operation type and set of parameters builder will try to compose
'             valid REST API request URL.
'             Used by networking object to handle and process API calls.
' 
function PNURLBuilder() as Object

    instance = {
        ' Templates which is used for particular operation type.
        urlTemplates: {
            "PNSubscribeOperation": "/v2/subscribe/{sub-key}/{channels}/0"
            "PNUnsubscribeOperation": "/v2/presence/sub_key/{sub-key}/channel/{channels}/leave"
            "PNPublishOperation": "/publish/{pub-key}/{sub-key}/0/{channel}/0/{message}"
            "PNHistoryOperation": "/v2/history/sub-key/{sub-key}/channel/{channel}"
            "PNWhereNowOperation": "/v2/presence/sub-key/{sub-key}/uuid/{uuid}"
            "PNHereNowGlobalOperation": "/v2/presence/sub-key/{sub-key}"
            "PNHereNowForChannelOperation": "/v2/presence/sub-key/{sub-key}/channel/{channel}"
            "PNHereNowForChannelGroupOperation": "/v2/presence/sub-key/{sub-key}/channel/{channel}"
            "PNHeartbeatOperation": "/v2/presence/sub-key/{sub-key}/channel/{channels}/heartbeat"
            "PNSetStateOperation": "/v2/presence/sub-key/{sub-key}/channel/{channel}/uuid/{uuid}/data"
            "PNStateForChannelOperation": "/v2/presence/sub-key/{sub-key}/channel/{channel}/uuid/{uuid}"
            "PNStateForChannelGroupOperation": "/v2/presence/sub-key/{sub-key}/channel/{channel}/uuid/{uuid}"
            "PNAddChannelsToGroupOperation": "/v1/channel-registration/sub-key/{sub-key}/channel-group/{channel-group}"
            "PNRemoveChannelsFromGroupOperation": "/v1/channel-registration/sub-key/{sub-key}/channel-group/{channel-group}"
            "PNRemoveGroupOperation": "/v1/channel-registration/sub-key/{sub-key}/channel-group/{channel-group}/remove"
            "PNChannelsForGroupOperation": "/v1/channel-registration/sub-key/{sub-key}/channel-group/{channel-group}"
            "PNTimeOperation": "/time/0"
        }
    }
    
    instance.URLForOperation = pn_urlBuilderURLForOperation
    
    return instance
end function


'******************************************************
'
' Public functions
'
'******************************************************

' brief:      Construct REST API path.
' discussion: Basing on operation type and list of provided configuration values compose full path 
'             to call corresponding REST API.
'
' operation  Reference on one of operations specified in 'PNOperationType'.
' config     Object with list of REST API configuration fields.
'
function pn_urlBuilderURLForOperation(operation as String, config as Object) as Dynamic
    urlForOperation = invalid
    
    urlTemplate$ = m.urlTemplates[operation]
    if config <> invalid then
        ' Replace path placeholders with actual values if provided.
        if config.path <> invalid then
            for each pathPlaceholder in config.path
                value = config.path[pathPlaceholder]
                if value <> invalid then urlTemplate$ = urlTemplate$.replace(pathPlaceholder, value.toStr())
            end for
        end if
        if urlTemplate$.inStr(0, "{") = -1 then
            ' Remove trailing '/' char if required.
            if PNString(urlTemplate$).hasSuffix("/") = true then
                urlTemplate$ = urlTemplate$.left(urlTemplate$.len() - 1)
            end if
            ' Append query parameters if provided.
            if config.query <> invalid AND config.query.ifAssociativeArray.count() > 0 then
                urlTemplate$ = urlTemplate$ + "?" + PNObject(config.query).toQueryString()
            end if
            urlForOperation = urlTemplate$
        end if
    end if
    
    return urlForOperation
end function
