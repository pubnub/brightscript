' brief:      Current client state cache manager.
' discussion: When client use 'state' API which allow to pull and push client state, this manager 
'             stores all information locally. Locally cached data used by PubNub subscriber and 
'             presence modules to deliver actual client state information to PubNub network.
'
function PNStateManager() as Object
    this = {private: {state: {}}}
    this.state = pn_stateManagerGetState
    this.setState = pn_stateManagerSetState
    this.removeStateForObjects = pn_stateManagerRemoveStateForObject
    this.stateMergedWith = pn_stateManagerStateMergedWith
    this.mergeWithState = pn_stateManagerMergeWithState
    this.destroy = pn_stateManagerDestroy
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:      Receive currently used clien't state.
' discussion: State information used by subscriber and heartbeat managers to keep client's state 
'             up-to-date for remote clients.
'
function pn_stateManagerGetState() as Dynamic
    if m.private.state.count() > 0 then return PNObject(m.private.state).copy(1) else return invalid
end function

' brief:      Update client's state for particular channel/group.
' discussion: In case if used provided new state or it has been changed remotely it should be 
'             updates in local cache so proper version will be used with subscriber and heartbeat 
'             managers.
'
' state  Reference on object which should be used as state for 'obj' name. If 'invalid' passed data
'        for object will be removed from local cache.
' obj    Reference on name of object for which state information should be updated.
'
sub pn_stateManagerSetState(state = invalid as Dynamic, obj = invalid as Dynamic)
    if state <> invalid AND state.count() > 0 then 
        if obj <> invalid then m.private.state[obj] = state
    else 
        if obj <> invalid then m.private.state.delete(obj)
    end if
end sub

' brief:  Remove client's state information for set of objects.
'
' objects  Reference on list of objects for which state information should be removed from local 
'          cache.
'
sub pn_stateManagerRemoveStateForObject(objects = invalid as Dynamic)
    if objects <> invalid AND objects.count() > 0 then
        for each objectName in objects
            m.private.state.delete(objectName)
        end for
    end if
end sub

' brief:  Retrieve merges new client's state based on cached clinet's state and provided state 
'         information.
'
' state   Reference on object with which local cache should be merged.
' object  Reference on list of object names for which merged state required. If resulting state 
'         contain state for object which is not part of this list it will be removed. 
'
function pn_stateManagerStateMergedWith(state = invalid as Dynamic, objects = invalid as Dynamic) as Dynamic
    mergedState = PNObject(PNObject(m.private.state).default({})).copy(1)
    if state <> invalid AND objects <> invalid then
        mergedState.append(state)
        cachedObjects = PNObject(mergedState).allKeys()
        for each objectName in cachedObjects
            if PNArray(objects).contains(objectName) = false then mergedState.delete(objectName)
        end for
    end if
    
    if mergedState.count() > 0 then return mergedState else return invalid
end function

' brief:      Update cached client's state information.
' discussion: Add state information for objects in provided 'state' object.
'
' state  Reference on object with which contain information for object for which local cache should 
'        be rewritten.
'
sub pn_stateManagerMergeWithState(state = invalid as Dynamic, objects = invalid as Dynamic)
    if state <> invalid AND state.count() > 0 then
        m.private.state.append(state)
        cachedObjects = PNObject(m.private.state).allKeys()
        PNArray(cachedObjects).deleteObjects(objects)
        m.removeStateForObjects(cachedObjects)
    end if
end sub

' brief:      Help garbage collector to destroy this instance.
' discussion: Function allow to ensure what there is no circular references between components and 
'             they can free memory.
'
sub pn_stateManagerDestroy()
    m.delete("private")
end sub
