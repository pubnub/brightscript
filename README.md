# brightscript



## Initialization

```brightscript
  pubnub = PubNub({
    subscribeKey: "<subKey>",
    publishKey: "<pubKey> (optional)",
    authKey: "<authKey> (optional)",
    uuid: "<client unique identifier> (optional)",
    origin: "custom origin to point the client to (optional)",
    secure: "boolean true / false; true will push data over SSL"
  })
```

## Publishing

```brightscript

  publishCallback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.publish({ channel: "hello", message: { such: "wow"} }, publishCallback)

```

## History

```brightscript

  historyCallback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.publish({
      channel: "hello",
      start: < integer, first timetoken (optional)> ,
      end: <integer, last timetoken (optional)>,
      reverse: <boolean, reverse the order (optional)",
      count: <integer, to return max results (defaults to 100)>
  }, historyCallback)

```

## Subscribing


subscriptions always start with a timetoken 0 which will return the last timetoken of the message.

```brightscript

  subscribeCallback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.subscribeEndpoint({
      timetoken: 0
      channels: ["ch1", "ch2", "ch3"],
      channelGroups: ["cg1", "cg2", "cg3"]
  }, subscribeCallback)

```

as part of the response from the initial subscription, a new timetoken will be returned inside the response as `response.metadata.timetoken`
the new timetoken needs to be passed to the subscribe


```brightscript

  subscribeCallback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.subscribeEndpoint({
      timetoken: <integer, new timetoken>
      channels: ["ch1", "ch2", "ch3"],
      channelGroups: ["cg1", "cg2", "cg3"]
  }, subscribeCallback)

```

if the subscribe call times out or errors, restart the subscribe call with the same timetoken.

## Push Notifications

### add channels to push

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  pubnub.push.AddChannels({
      channels: ["ch1", "ch2", "ch3"],
      device: "<device id>"
      type: "<gcm | apns | mpns>"
  }, callback)

```

### remove channels from push

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  pubnub.push.RemoveChannels({
      channels: ["ch1", "ch2", "ch3"],
      device: "<device id>"
      type: "<gcm | apns | mpns>"
  }, callback)

```

### delete device from push

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  pubnub.push.DeleteDevice({
      device: "<device id>"
      type: "<gcm | apns | mpns>"
  }, callback)

```

### list channels for device

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  pubnub.push.ListChannels({
      device: "<device id>"
      type: "<gcm | apns | mpns>"
  }, callback)

```

## Channel Groups

### Adding Channels to Channel Group

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  pubnub.ChannelGroups.AddChannels({
      channels: ["ch1", "ch2", "ch3"],
      channelGroup: "cg1"
  }, callback)

```

### Removing Channels From Channel Group

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  pubnub.ChannelGroups.RemoveChannels({
      channels: ["ch1", "ch2", "ch3"],
      channelGroup: "cg1"
  }, callback)

```

### Deleting Channel Group

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.ChannelGroups.DeleteGroup({
      channelGroup: "cg1"
  }, callback)
```

### Listing Channels In Channel Group

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.ChannelGroups.ListChannels({
      channelGroup: "cg1"
  }, callback)
```

### Listing Channel Groups

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  pubnub.ChannelGroups.ListGroups({}, callback)
```
