Function PubNubListenerManager() as Object

    instance = {
        listeners: []
    }

    instance.addListener = Function (listener as Object)
        m.listenermanager.listeners.push(listener)
    end Function

    instance.removeListener = Function (listener as Object)
        newListeners = []

        For Each oldListener in m.listenermanager.listeners
            if oldListener <> listener then newListeners.push(oldListener)
        End For

        m.listenermanager.listeners = newListeners
    end Function

    instance.removeAllListeners = Function (listener as Object)
        m.listenermanager.listeners = []
    end Function

    instance.announceStatus = Function (announce as Object)
        For Each listener in m.listenermanager.listeners
            if listener.status <> invalid then listener.status(announce)
        End For
    end Function

    instance.announcePresence = Function (announce as Object)
        For Each listener in m.listenermanager.listeners
            if listener.presence <> invalid then listener.presence(announce)
        End For
    end Function

    instance.announceMessage = Function (announce as Object)
        For Each listener in m.listenermanager.listeners
            if listener.message <> invalid then listener.message(announce)
        End For
    end Function

    return instance
end Function
