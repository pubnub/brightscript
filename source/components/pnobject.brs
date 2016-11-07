' brief:      Object fields manipulation helper.
' discussion: This object contain set of functions which simplify routine object (associative array) 
'             data manipulation.
'
' obj  Reference on object with which helper should work.
'
function PNObject(obj = invalid as Dynamic) as Object
    this = {private: {value: obj}}
    this.default = pn_objectDefaultValue
    this.allKeys = pn_objectAllKeys
    this.valueAtKeyPath = pn_objectValueAtKeyPath
    this.copy = pn_objectShallowCopy
    this.toQueryString = pn_objectToQueryString
    this.isDictionary = pn_objectIsDictionary
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Return 'value' if set or 'default' in another case.
'
' default  Reference on value which should be returned in case if 'value' not set.
'
function pn_objectDefaultValue(default = invalid as Dynamic) as Dynamic
    if m.private.value <> invalid then return m.private.value else return default
end function

' brief:  Retrieve list of keys for which value is stored in object.
'
function pn_objectAllKeys() as Object
    objects = []
    for each objectName in m.private.value
        objects.push(objectName)
    end for
    
    return objects
end function

' brief:  Retrieve value which is stored inside of referenced object at specified key-path.
'
' keyPath  Reference on key-path string for which value from object should be retrieved.
'
function pn_objectValueAtKeyPath(keyPath as String) as Dynamic
    value = invalid
    if m.isDictionary() then
        value = m.private.value[keyPath]
        if keyPath.instr(0, ".") <> -1 then
            value = m.private.value
            components = keyPath.split(".")
            while components.count() > 0
                path = components.shift()
                if PNObject(value).isDictionary() then
                    value = value[path]
                else if components.count() = 0 then
                    value = invalid
                end if
            end while
        end if
    end if
    m.delete("private")
    
    return value
end function

' brief:  Make shallow copy from receiver.
' discussion: Iterate through object entries and create copies from them and place into new object.
'
' depth  Maximum copy depth (deeper objects will be passed by reference).
'
function pn_objectShallowCopy(depth = 0 as Integer) as Dynamic
    copy = m.private.value
    if PNArray(m.private.value).isArray() = true then
        copy = []
        for each entry in m.private.value
            copy.push(PNObject(entry).copy(depth))
        end for
    else if m.isDictionary() then
        copy = {}
        for each key in m.private.value
            value = m.private.value[key]
            if depth > 0 then copy[key] = PNObject(value).copy(depth - 1) else copy[key] = value
        end for
    end if
    m.delete("private")
    
    return copy
end function

function pn_objectToQueryString() as Dynamic
    chunks = []
    for each key in m.private.value
      chunks.push(key + "=" + box(m.private.value[key]).toStr())
    end for
    m.delete("private")

    return PNArray(chunks).componentsJoinedByString("&")
end function

' brief:  Check whether represented object is associative array / dictionary or not.
'
function pn_objectIsDictionary() as Boolean
    return m.private.value <> invalid AND type(m.private.value) = "roAssociativeArray"
end function