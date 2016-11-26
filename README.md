# brightscript



## Initialization

```brightscript
client = PubNub({
    subscribeKey: "demo-36",
    publishKey: "demo-36",
    uuid: "roku-client",
}, messagePort)
```  
Full list of parameters which can be used for client configuration listed below:  

|              Name              |   Type   | Required | Description |
| ------------------------------ |:--------:|:--------:|:------------|
| `subscribeKey`                 | roString |   Yes    | Reference on key which is used to fetch data/state from **PubNub** service.<br>This key can be obtained on PubNub's administration portal after free registration https://admin.pubnub.com |
| `publishKey`                   | roString |   Yes    | Reference on key which is used to push data/state to **PubNub** service.<br>This key can be obtained on PubNub's administration portal after free registration https://admin.pubnub.com |
| `authKey`                      | roString |    No    | Reference on key which is used along with every request to **PubNub** service to identify client user. |
| `uuid`                         | roString |    No    | Reference on unique client identifier used to identify concrete client user from another which currently use **PubNub** services. |
| `origin`                       | roString |    No    | Reference on host name or IP address which should be used by client to get access to **PubNub** services.<br>**Default**: _pubsub.pubnub.com_ |
| `secure`                       | Boolean  |    No    | Whether client should use secured connection to **PubNub** service or not.<br>**Default**: _true_ |
| `subscribeMaximumIdleTime`     | Integer  |    No    | Reference on maximum number of seconds which client should wait for events from live feed.<br>**Default**: _310 seconds_ |
| `nonSubscribeRequestTimeout`   | Integer  |    No    | Reference on number of seconds which is used by client during non-subscription operations to check whether response potentially failed with 'timeout' or not.<br>**Default**: _10 seconds_ |
| `presenceHeartbeatValue`       | Integer  |    No    | Number of seconds which is used by server to track whether client still subscribed on remote data objects live feed or not. |
| `presenceHeartbeatInterval`    | Integer  |    No    | Number of seconds which is used by client to issue heartbeat requests to **PubNub** service. |
| `notifyHeartbeatFailure`       | Boolean  |    No    | Whether client's state observer should be notified about heartbeat request processing failure or not.<br>**Default**: _true_ |
| `notifyHeartbeatSuccess`       | Boolean  |    No    | Whether client's state observer should be notified about heartbeat request processing success or not.<br>**Default**: _false_ |
| `keepTimeTokenOnListChange`    | Boolean  |    No    | Whether client should keep previous time token when subscribe on new set of remote data objects live feeds.<br>**Default**: _true_ |
| `restoreSubscription`          | Boolean  |    No    | Whether client should restore subscription on remote data objects live feed after network connection restoring or not.<br>**Default**: _true_ |
| `catchUpOnSubscriptionRestore` | Boolean  |    No    | client should try to catch up for events which occurred on previously subscribed remote data objects feed while client was off-line.<br>**Default**: _true_ |
| `requestMessageCountThreshold` | Boolean  |    No    | Number of maximum expected messages from **PubNub** service in single response.<br>**Default**: _0_ |


## Callbacks
All API expect subscribe/unsubscribe accept `callback` functions as second function parameter.  
```brightscript
client.<api-function>({<parameters>}, <callback>, <context>)
```  

Data pulling API require callbacks and data modification API allow to pass _invalid_ or completelly ignore it and pass only list of parameters.  
Because callback functions will be called outside of scope where they has been called it maybe required to do something in response on modified/fetched data - for this purpose _context_ should be used. _context_ is optional parameter and can be ignored, but if it has been passed then additional parameter should be added to callback function declaration:  
```brightscript
publishCallback = function(status as Object, context as Object)
end function
```  

## Integration
To properly integrate **PubNub** client into your application it should be called from `run-loop`. After client has been created and configured it need to start handling **roUrlEvent** events and trigger internal timers - to make it happen client provide function `handleMessage` which should be called by application.  
Here is how client can be _integrated_:  
```brightscript
' Prepare shared message port.
' Message port should be used for both application / user events handling and PubNub client
' 'run-loop'
messagePort = createObject("roMessagePort")

' Create and configure PubNub client instance.
client = PubNub({
    subscribeKey: "demo-36",
    publishKey: "demo-36",
    uuid: "roku-client",
}, messagePort)

while true
    message = wait(250, messagePort)
    pubnubCanHandle = client.handleMessage(message)
    if type(message) = "roUrlEvent" AND pubnubCanHandle = false then
        ' Application request handling code. If client's 'handleMessage' function return
        ' 'false' - it mean what client doesn't recognize request and probably it has been sent
        ' by application and should be handled by it.
    end if

    if message = "roSGScreenEvent" AND message.isScreenClosed() = true then
        client.destroy()
        exit while
    end if

    ' Handle any other user interactions.
end while
```  

**NOTE:** Don't use zero timeout for _wait_ because **PubNub** client won't be able to maintain internal timers and trigger requests timeout events.  
**NOTE:** If it will be required to create another **PubNub** client and invalidate previous one you need to call:  
```brightscript
client.destroy()
```  

## Subscription
### Subscribing
Subscription API use 'event listeners' to provide information about received events / messages or client subscription state change. Listeners is regular associative arrays with fields (status, presence and message) which represent desired events which should be handled by observer.  
Here is an example of event listener which will be used later:  

```brightscript
objectEventListener = {
    status: function(client as Object, status as Object)
        ?"Status change:", status
        ' Check example application for possible state variations.
        if status.error = true AND status.operation = PNOperationType().PNSubscribeOperation then
            if status.automaticallyRetry = true then
                ' It is possible to cancel automatic retry
                ' if required using client's function:
                client.cancelSubscriptionRetry()
            end if
        end if
    end function
    presence: function(client as Object, presence as Object)
        ?"Received '"+presence.data.presenceEvent+"' presence event with details:", presence.data.presence
    end function
    message: function(client as Object, message as Object)
        ?"Received message on '"+message.data.channel+"': ",message.data.message
    end function
}
```  

After observer object has been created it should be registered with corresponding function:  
```brightscript
client.addListener(objectEventListener)
```  

**NOTE:** When client's state change and messages observation not required anymore, it can be disabled:  
```brightscript
' Unregister specific listener.
client.removeListener(objectEventListener)

' Unregister all listeners.  
client.removeAllListeners()
```  

To perform regular subscription to channel and groups with presence state next subscribe request can be used:  
```brightscript
client.subscribe({
    channels: ["pubnub-channel", "roku-channel"]
    channelGroups: ["pubnub-group", "brightscript-group"]
    withPresence: false
    "state": {"pubnub-channel": {"welcome": "online"}}
})
```  

Full list of parameters which can be used with this API listed below:  

|        Name        |        Type        | Required | Description |
| ------------------ |:------------------:|:--------:|:------------|
| `channels`         |      roArray       |    No    | List of channel names on which client should try to subscribe. |
| `channelGroups`    |      roArray       |    No    | List of channel group names on which client should try to subscribe. |
| `withPresence`     |      Boolean       |    No    | Whether presence observation should be enabled for `channels` and/or `groups` or not. |
| `state`            | roAssociativeArray |    No    | Reference on associative array which stores key-value pairs based on channel / group names and value which should be assigned to them. |
| `filterExpression` |      roString      |    No    | Expression which defined conditions basing on which published message should be accepted by client. |  


### Unsubscribing
**PubNub** client provide two functions which can be used to unsubscribe from channels and/or groups: `unsubscribe` and `unsubscribeAll`.  
`unsubscribeAll` is function which with single call unsubscribe client from all channel and groups (including presence channels and groups). Usage example:  
```brightscript
client.unsubscribeAll()
```  

`unsubscribe` allow to unsubscribe from particular channel(s) and / or group(s). Usage example:  
```brightscript
client.unsubscribe({
    channels: ["pubnub-channel", "roku-channel"]
    channelGroups: ["brightscript-group"]
})
```  

Full list of parameters which can be used with this API listed below:  

|        Name        |        Type        | Required | Description |
| ------------------ |:------------------:|:--------:|:------------|
| `channels`         |      roArray       |    No    | List of channel names from which client should try to unsubscribe. |
| `channelGroups`    |      roArray       |    No    | List of channel group names from which client should try to unsubscribe. |
| `withPresence`     |      Boolean       |    No    | Whether client should disable presence observation on specified channel(s) and / or

### List of channels / groups
**PubNub** provide interface which allow to retrieve list of channels and groups on which client subscribed at this moment: `channels` and `channelGroups`. Usage example:  
```brightscript
channels = client.channels()
channelGroups = client.channelGroups()
```  

### Presence observation
**PubNub** client provide interface which allow to check whether presence observation enabled for particular channel or channel group. In example below shown how to enabled presence observation on channel if not enabled yet:  
```brightscript
if client.presenceEnabledForChannel("roku-channel") = false then
    client.subscribe({channels: ["roku-channel-pnpres"]})
end if
```  

## Publishing
```brightscript
publishCallback = function(status as Object)
    if status.error = false then
        ' Handle successful message publish.
    else
        ' Handle message publish error.
        ?"Message publish did fail with error details:",status.errorData
    end if
end function

client.publish({
    channel: "roku-channel"
    message: {hello: "world"}
}, publishCallback)
```  

Full list of parameters which can be used with this API listed below:  

|       Name       |        Type        | Required | Description |
| ---------------- |:------------------:|:--------:|:------------|
| `channel`        |      roString      |   Yes    | Reference on name of the channel to which message should be published. |
| `message`        |       Object       |    No    | Reference on object (which can be serialized to JSON string) which will be published. |
| `sendByPost`     |      Boolean       |    No    | Specify whether message should be gzip compressed and sent as POST body.  |
| `storeInHistory` |      Boolean       |    No    | Specify whether published message should be stored in channel's storage or not.   |
| `replicate`      |      Boolean       |    No    | Specify whether published message should be replicated across data centers or not.    |
| `ttl`            |      Integer       |    No    | Specify for how many days message can be stored in channel's storage.      |
| `payloads`       | roAssociativeArray |    No    | Associative array with configured payloads for each platform for which push notification should be delivered.  |
| `metadata`       | roAssociativeArray |    No    | Associative array which is used with _subscribe_ API and help it figure out whether message should be received or not.  |  

**NOTE:** `message` may not be required only if `payloads` has been passed. `publish` function should contain in configuration: `message` and / or `payloads`.  

## History
```brightscript
historyCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    if result <> invalid then
        ' Handle successful history fetch.
        ?"Messages between "+box(result.data.start).toStr()+" .. "+box(result.data["end"]).toStr()+": "+PNObject(result.data.messages).toString()
    else
        ' Handle messages history request error.
        ?"Messages history fetch did fail with error details:",status.errorData
    end if
end function
client.history({channel: "hello-channel"}, historyCallback)
```  

Full list of parameters which can be used with this API listed below:  

|    Name   |   Type   | Required | Description |
| --------- |:--------:|:--------:|:------------|
| `start`   | roString |    No    | Specify timetoken starting from which messages should be received. |
| `end`     | roString |    No    | Specify time token starting till which messages should be received. |
| `reverse` |  Boolean |    No    | Specify whether messages order should be reversed or not.**Default**: _false_ |
| `count`   |  Integer |    No    | Specify how many messages should be returned with single call.**Default**: _100_ |

**NOTE:** Timetoken is 17-digit precision unix-timestamp and can't be stored even in *roLongInteger* component, so string is used for this purpose.  
**NOTE:** Maximum number of messages which can be retrieved with single history API call is **100**.  


## Channel Groups

### Adding Channels to Channel Group
```brightscript
channelsAddCallback = function(status as Object)
    if status.error = false then
        ' Handle successful channels addition from group.
    else
        ' Handle channels addition error.
        ?"Channels addition did fail with error details:",status.errorData
    end if
end function

client.addChannels({
    channels: ["brightscript", "roku"]
    group: "roku-developers-community"
}, channelsAddCallback)
```  

Full list of parameters which can be used with this API listed below:  

|    Name    |   Type   | Required | Description |
| ---------- |:--------:|:--------:|:------------|
| `channels` |  roArray |    Yes   | List of channel names which should be added to the 'group'. |
| `group`    | roString |    Yes   | Name of the group into which channels should be added. |  


### Removing Channels From Channel Group
```brightscript
channelsRemoveCallback = function(status as Object)
    if status.error = false then
        ' Handle successful channels removal from group.
    else
        ' Handle channels removal error.
        ?"Channels remove did fail with error details:",status.errorData
    end if
end function

client.removeChannels({
    channels: ["brightscript"]
    group: "roku-developers-community"
}, channelsRemoveCallback)
```  

Full list of parameters which can be used with this API listed below:  

|    Name    |   Type   | Required | Description |
| ---------- |:--------:|:--------:|:------------|
| `channels` |  roArray |    Yes   | List of channel names which should be removed from 'group'. |
| `group`    | roString |    Yes   | Name of the group from which channels should be removed. |  


### Deleting Channel Group
```brightscript
groupRemoveCallback = function(status as Object)
    if status.error = false then
        ' Handle successful channel group removal.
    else
        ' Handle channel group removal error.
        ?"Channel group remove did fail with error details:",status.errorData
    end if
end function

client.deleteGroup({group: "roku-developers-community"}, groupRemoveCallback)
```  

Full list of parameters which can be used with this API listed below:  

|  Name   |   Type   | Required | Description |
| ------- |:--------:|:--------:|:------------|
| `group` | roString |    Yes   | Name of the group from which all channels should be removed. |  


### Listing Channels In Channel Group
```brightscript
channelsAuditCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    if result <> invalid then
        ' Handle successful group's channels fetch.
        ?"Channels:",result.data.channels
    else
        ' Handle group's channels request error.
        ?"Group's channels fetch did fail with error details:",status.errorData
    end if
end function

client.listChannels({group: "roku-developers-community"}, channelsAuditCallback)
```  

Full list of parameters which can be used with this API listed below:  

|  Name   |   Type   | Required | Description |
| ------- |:--------:|:--------:|:------------|
| `group` | roString |    Yes   | Name of the group from which channels should be fetched. |


## Presence

### Here now
```brightscript
hereNowCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    if result <> invalid then
        ' Handle users' presence information fetch.
        ?"Occupancy:",result.data.occupancy
        ?"Participants: "+PNObject(result.data.uuids).toString()
    else
        ' Handle users' presence information request error.
        ?"Users' presence information fetch did fail with error details:",status.errorData
    end if
end function

client.hereNow({channel: "roku-channel"}, hereNowCallback)
```  

Full list of parameters which can be used with this API listed below:  

|     Name       |   Type   | Required | Description |
| -------------- |:--------:|:--------:|:------------|
| `channel`      | roString |    No    | Reference on channel for which here now information should be received. |
| `group`        | roString |    No    | Reference on channel group name for which here now information should be received. |
| `includeUUIDs` | Boolean  |    No    | Whether remote user unique identifiers should be returned or not.<br>**Default**: _true_ |
| `includeState` | Boolean  |    No    | Whether remote user state should be returned or not.<br>**Default**: _true_ |

**NOTE:** `channel` may not be required only if `group` has been passed. `hereNow` function should contain in configuration: `channel` and / or `group`.  


### Where now
```brightscript
whereNowCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    if result <> invalid then
        ' Handle user channels presence fetch.
        ?"Channels:",result.data.channels
    else
        ' Handle user channels presence request error.
        ?"User channels fetch did fail with error details:",status.errorData
    end if
end function

client.whereNow({uuid: client.configuration().uuid}, whereNowCallback)
```  

Full list of parameters which can be used with this API listed below:  

|  Name  |   Type   | Required | Description |
| ------ |:--------:|:--------:|:------------|
| `uuid` | roString |    No    | Reference on unique user identifier for which list of channels on which he subscribed should be retrieved. |  


### Set state
```brightscript
setStateCallback = function(status as Object)
    if status.error = false then
        ' Handle successful client's state change.
    else
        ' Handle client's state change error.
        ?"Did fail to change client's state with error details:",status.errorData
    end if
end function

client.setState({
    channel: "roku-channel"
    uuid: client.configuration().uuid
    "state":{welcome:{"to":"Roku channel"}}
}, setStateCallback)
```  

Full list of parameters which can be used with this API listed below:  

|   Name    |        Type        | Required | Description |
| --------- |:------------------:|:--------:|:------------|
| `channel` |      roString      |    No    | Name of the channel which will store provided state information for 'uuid'. |
| `group`   |      roString      |    No    | Name of channel group which will store provided state information for 'uuid'. |
| `uuid`    |      roString      |    Yes   | Reference on unique user identifier for which state should be bound. |
| `state`   | roAssociativeArray |    No    | Reference on dictionary which should be bound to 'uuid' on channel / group.  |

**NOTE:** if `state` will not provided, state for user on specified `channel` / `group` will be removed and remote users will be notified about it.  
**NOTE:** `channel` may not be required only if `group` has been passed. `setState` function should contain in configuration: `channel` and / or `group`.  


### Get state
```brightscript
getStateCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    if result <> invalid then
        ' Handle client's state for user fetch.
        ?"User state:",result.data.state
    else
        ' Handle client's state for user request error.
        ?"User state fetch did fail with error details:",status.errorData
    end if
end function

client.getState({
    channel: "roku-channel"
    uuid: client.configuration().uuid
}, getStateCallback)
```  

Full list of parameters which can be used with this API listed below:  

|   Name    |        Type        | Required | Description |
| --------- |:------------------:|:--------:|:------------|
| `channel` |      roString      |    No    | Name of channel from which state information for 'uuid' will be pulled out. |
| `group`   |      roString      |    No    | Name of channel group from which state information for 'uuid' will be pulled out. |
| `uuid`    |      roString      |    Yes   | Reference on unique user identifier for which state should be retrieved. |

**NOTE:** `channel` may not be required only if `group` has been passed. `getState` function should contain in configuration: `channel` and / or `group`.  


### Time
```brightscript
timeCallback = function(result = invalid as Dynamic, status = invalid as Dynamic)
    if result <> invalid then
        ' Handle time fetch.
        ?"Timetoken",result.data.timetoken
    else
        ' Handle time request error.
        ?"User state fetch did fail with error details:",status.errorData
    end if
end function

client.time(timeCallback)
```  
