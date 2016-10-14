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

  request.publish({ channel: "hello", message: { such: "wow"} }, publishCallback)

```

## History

```brightscript

  historyCallback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  request.publish({
      channel: "hello",
      start: "first timetoken (optional)",
      end: "last timetoken (optional)",
      reverse: "boolean to reverse the order (optional)",
      count: "integer to return max results (defaults to 100)"
  }, historyCallback)

```

## Subscribing

```brightscript

  subscribeCallback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  request.subscribe({
      timetoken: "<insert integer time token>"
      channels: ["ch1", "ch2", "ch3"],
      channelGroups: ["cg1", "cg2", "cg3"]
  }, subscribeCallback)

```

## Push Notifications

### add channels to push

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  request.push.AddChannels({
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

  request.push.RemoveChannels({
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

  request.push.DeleteDevice({
      device: "<device id>"
      type: "<gcm | apns | mpns>"
  }, callback)

```

### list channels for device

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  request.push.ListChannels({
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

  request.ChannelGroups.AddChannels({
      channels: ["ch1", "ch2", "ch3"],
      channelGroup: "cg1"
  }, callback)

```

### Removing Channels From Channel Group

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
  end Function

  request.ChannelGroups.RemoveChannels({
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

  request.ChannelGroups.DeleteGroup({
      channelGroup: "cg1"
  }, callback)
```

### Listing Channels In Channel Group

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  request.ChannelGroups.ListChannels({
      channelGroup: "cg1"
  }, callback)
```

### Listing Channel Groups

```brightscript

  callback = Function(status as Object, response as Object)
    print "status", status
    print "response", response
  end Function

  request.ChannelGroups.ListGroups({}, callback)
```
