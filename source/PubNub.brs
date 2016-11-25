function PubNub(config as Object, port as Object) as Object
    this = {
        private: {
            config: {
                version: "4.0.0"
                publishKey: PNObject(config.publishKey).default("")
                subscribeKey: PNObject(config.subscribeKey).default("")
                authKey: config.authKey
                uuid: PNObject(config.uuid).default(createObject("roDeviceInfo").getRandomUUID())
                origin: PNObject(config.origin).default("pubsub.pubnub.com")
                secure: PNObject(config.secure).default(true)
                cipherKey: config.cipherKey
                deviceID: createObject("roDeviceInfo").getDeviceUniqueId()
                instanceID: createObject("roDeviceInfo").getRandomUUID()
                subscribeMaximumIdleTime: PNObject(config.subscribeMaximumIdleTime).default(310)
                nonSubscribeRequestTimeout: PNObject(config.nonSubscribeRequestTimeout).default(10)
                presenceHeartbeatValue: config.presenceHeartbeatValue
                presenceHeartbeatInterval: config.presenceHeartbeatInterval
                notifyHeartbeatFailure: PNObject(config.notifyHeartbeatFailure).default(true)
                notifyHeartbeatSuccess: PNObject(config.notifyHeartbeatSuccess).default(false)
                keepTimeTokenOnListChange: PNObject(config.keepTimeTokenOnListChange).default(true)
                restoreSubscription: PNObject(config.restoreSubscription).default(true)
                catchUpOnSubscriptionRestore: PNObject(config.catchUpOnSubscriptionRestore).default(true)
                requestMessageCountThreshold: PNObject(config.requestMessageCountThreshold).default(0)
                maximumMessagesCacheSize: PNObject(config.maximumMessagesCacheSize).default(100)
            }
        }
    }
    if PNObject(this.private.config.presenceHeartbeatValue).default(0) > 0 then
        if PNObject(this.private.config.presenceHeartbeatInterval).default(0) = 0 then
            interval% = this.private.config.presenceHeartbeatValue * 0.5
            this.private.config.presenceHeartbeatInterval = interval%
        end if
    else
        this.private.config.presenceHeartbeatValue = invalid
        this.private.config.presenceHeartbeatInterval = invalid
    end if
    configuration = PNObject(this.private.config).copy(1)
    this.private.publishSequenceManager = PNPublishSequence(configuration)
    this.private.networkManager = PNNetwork(configuration, port)
    this.private.listenerManager = PNStateListener(this)
    this.private.stateManager = PNStateManager()
    this.private.heartbeatManager = PNPNHeartbeatManager(configuration, this.private.networkManager, this.private.listenerManager, this.private.stateManager)
    this.private.subscriptionManager = PNSubscribeManager(configuration, this.private.networkManager, this.private.listenerManager, this.private.stateManager, this.private.heartbeatManager)
    this.private.heartbeatManager.private.setSubscribeManager(this.private.subscriptionManager)
    
    this.configuration = function() as Object
        return PNObject(m.private.config).copy(1)
    end function

'******************************************************
'
' Start mounting endpoints
'
'******************************************************

    ' Stream controller - start
    this.listChannels = PNChannelGroupListChannels
    this.addChannels = PNChannelGroupAddChannels
    this.removeChannels = PNChannelGroupRemoveChannels
    this.deleteGroup = PNChannelGroupDeleteGroup
    ' Stream controller - end
    
    ' Message history
    this.history = PNHistory
    
    ' Message publish
    this.publish = PNPublish
    
    ' Presence - start
    this.hereNow = PNPresenceHereNow
    this.whereNow = PNPresenceWhereNow
    this.setState = PNPresenceSetState
    this.getState = PNPresenceGetState
    ' Presence - end
    
    ' Time
    this.time = PNTime

    ' Subscribe / unsubscribe - start
    subscribeEndpoint = PNSubscribe(this)
    this.subscribe = subscribeEndpoint.subscribe
    this.cancelSubscriptionRetry = subscribeEndpoint.cancelSubscriptionRetry
    this.unsubscribe = subscribeEndpoint.unsubscribe
    this.unsubscribeAll = subscribeEndpoint.unsubscribeAll
    this.channels = subscribeEndpoint.channels
    this.presenceEnabledForChannel = subscribeEndpoint.presenceEnabledForChannel
    this.channelGroups = subscribeEndpoint.channelGroups
    this.presenceEnabledForChannelGroup = subscribeEndpoint.presenceEnabledForChannelGroup
    ' Subscribe / unsubscribe - start

    ' Event listener - start
    this.addListener = this.private.listenerManager.addListener
    this.removeListener = this.private.listenerManager.removeListener
    this.removeAllListeners = this.private.listenerManager.removeAllListeners
    ' Event listener - end
    
    ' Run-loop message handler
    this.handleMessage = pn_pubnubHandleMessage
    
    ' Destructor
    this.destroy = pn_pubnubDestroy

    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:      Handle single 'run-loop tick'.
' discussion: Function called by PubNub client on every 'run-loop tick' to check whether some 
'             scheduled data retrieval arrived and should be processed or not.
'
' message  Reference on event/message received from messages port object at 'run-loop tick'.
' 
function pn_pubnubHandleMessage(message = invalid as Dynamic) as Boolean
    handled = m.private.networkManager.handleMessage(message)
    m.private.subscriptionManager.handleMessage(message)
    m.private.heartbeatManager.handleMessage(message)
    
    return handled
end function

' brief:      Destroy PubNub client 'instance'.
' discussion: This function allow to break circular references for some components which has been 
'             set during client initialization.
'
sub pn_pubnubDestroy()
    m.private.subscriptionManager.destroy()
    m.private.heartbeatManager.destroy()
    m.private.listenerManager.destroy()
end sub
