' brief:  Full list of known status categories.
'
function PNStatusCategory() as Object
    return {
        ' brief: Service response or client state change produced some unknown status which can't
        '        be handled by PubNub client on it's own.
        PNUnknownCategory: "PNUnknownCategory"
        
        ' brief:      PubNub request acknowledgment status.
        ' discussion: Some API endpoints respond with request processing status w/o useful data.
        PNAcknowledgmentCategory: "PNAcknowledgmentCategory"
        
        ' brief:      PubNub Access Manager forbidden access to particular API.
        ' discussion: It is possible what at the moment when API has been used access rights hasn't
        '             been applied to the client.
        PNAccessDeniedCategory: "PNAccessDeniedCategory"
        
        ' brief:      API processing failed because of request time out.
        ' discussion: This type of status is possible in case of very slow connection when request 
        '             doesn't have enough time to complete processing (send request body and receive 
        '             server response).
        PNTimeoutCategory: "PNTimeoutCategory"
        
        ' brief:      API request is impossible because there is no connection.
        ' discussion: At the moment when API has been used there was no active connection to the 
        '             Internet.
        PNNetworkIssuesCategory: "PNNetworkIssuesCategory"
        
        ' brief:      Subscribe returned more than specified number of messages / events.
        ' discussion: At the moment when client recover after network issues there is a chance what
        '             a lot of messages queued to return in subscribe response. If number of 
        '             received objects will be larger than specified threshold this status will be 
        '             sent (maybe history request required).
        PNRequestMessageCountExceededCategory: "PNRequestMessageCountExceededCategory"
        
        ' brief:      Status sent when client successfully subscribed to remote data objects live
        '             feed.
        ' discussion: Connected mean what client will receive live updates from PubNub service at 
        '             specified set of data objects.
        PNConnectedCategory: "PNConnectedCategory"
        
        ' brief: Status sent when client successfully restored subscription to remote data objects
        '        live feed after unexpected disconnection.
        PNReconnectedCategory: "PNReconnectedCategory"
        
        ' brief: Status sent when client successfully unsubscribed from one of remote data objects
        '        live feeds.
        PNDisconnectedCategory: "PNDisconnectedCategory"
        
        ' brief: Status sent when client unexpectedly lost ability to receive live updates from
        '        PubNub service.
        PNUnexpectedDisconnectCategory: "PNUnexpectedDisconnectCategory"
        
        ' brief:      Status which is used to notify about API call cancellation.
        ' discussion: Mostly cancellation possible only for connection based operations 
        '             (subscribe/leave).
        PNCancelledCategory: "PNCancelledCategory"
        
        ' brief:      Status is used to notify what API request from client is malformed.
        ' discussion: In case if this status arrive, it is better to print out status object debug
        '             description and contact support@pubnub.com
        PNBadRequestCategory: "PNBadRequestCategory"
        
        ' brief:      Status is used to notify what client has been configured with malformed 
        '             filtering expression.
        ' discussion: In case if this status arrive, check syntax used for -setFilterExpression: method.
        ' ^ TODO: CHANGE LINE ABOVE WHEN FILTER EXPRESSION WILL BE ADDED
        PNMalformedFilterExpressionCategory: "PNMalformedFilterExpressionCategory"
        
        ' brief:      PubNub because of some issues sent malformed response.
        ' discussion: In case if this status arrive, it is better to print out status object debug
        '             description and contact support@pubnub.com
        PNMalformedResponseCategory: "PNMalformedResponseCategory"
        
        ' brief: Looks like PubNub client can't use provided 'cipherKey' to decrypt received
        '        message.
        PNDecryptionErrorCategory: "PNDecryptionErrorCategory"
        
        ' brief:      Status is sent in case if client was unable to use API using secured 
        '             connection.
        ' discussion: In case if this issue happens, client can be re-configured to use insecure 
        '             connection. If insecure connection is impossible then it is better to print 
        '             out status object debug description and contact support@pubnub.com
        PNTLSConnectionFailedCategory: "PNTLSConnectionFailedCategory"
        
        ' brief:      Status is sent in case if client unable to check certificates trust chain.
        ' discussion: If this state arrive it is possible what proxy or VPN has been used to connect
        '             to internet. In another case it is better to get output of 
        '             "nslookup pubsub.pubnub.com" status object debug description and mail to
        '             support@pubnub.com
        PNTLSUntrustedCertificateCategory: "PNTLSUntrustedCertificateCategory"
    }
end function
