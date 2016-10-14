
Function PubNubListenerManager() as Object

    instance = {
      listeners: []
    }

    instance.addListener = Function (listener as Object)
        instance.listeners.push(listener)
    end Function

    instance.removeListener = Function (listener as Object)
        newListeners = []

        For Each oldListener in instance.listeners
            if oldListener <> listener then
                newListeners.push(oldListener)
            end if
        End For

        instance.listeners = newListeners

    end Function

    instance.removeAllListeners = Function (listener as Object)
        instance.listeners = []
    end Function

    instance.announceStatus = Function (announce as Object)
        For Each listener in instance.listeners
            if listener.status <> invalid then
                listener.status(announce)
            end if
        End For
    end Function

    instance.announcePresence = Function (announce as Object)
        For Each listener in instance.listeners
            if listener.presence <> invalid then
                listener.presence(announce)
            end if
        End For
    end Function

    instance.announceMessage = Function (announce as Object)
        For Each listener in instance.listeners
            if listener.message <> invalid then
                listener.message(announce)
            end if
        End For
    end Function

    return instance
