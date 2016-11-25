' brief:      Array object content manipulation helper.
' discussion: This object contain set of functions which simplify routine array content manipulation.
'
' array  Reference on object with which helper should work.
'
function PNArray(array = invalid as Dynamic) as Object
    this = {private: {value: array}}
    this.contains = pn_arrayContainsValue
    this.indexOf = pn_arrayIndexOfValue
    this.delete = pn_arrayRemoveValue
    this.deleteObjects = pn_arrayRemoveValues
    this.componentsJoinedByString = pn_arrayComponentsJoinedByString
    this.isEmpty = pn_arrayIsEmpty
    this.isEqualContent = pn_arrayIsEqualContent
    this.isEqualToArray = pn_arrayIsEqualToArray
    this.isArray = pn_arrayValidObject
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Check whether array object contain specified value or not.
'
' value  Reference on object which is searched inside of 'array'.
' check  Whether passed object types should be verified or not.
'
function pn_arrayContainsValue(value = invalid as Dynamic, check = true as Boolean) as Boolean
    contains = false
    if value <> invalid then
        if check = true AND m.isArray() = true OR check = false then
            if check = true then check = false
            contains = m.indexOf(value, check) <> invalid
        end if
    end if
    
    return contains
end function

' brief:  Retrieve reference on 'value' index.
'
' value  Reference on object which for which index inside of 'array' should be found.
' check  Whether passed object types should be verified or not.
'
function pn_arrayIndexOfValue(value = invalid as Dynamic, check = true as Boolean) as Dynamic
    index = invalid
    if value <> invalid then
        if check = true AND m.isArray() = true OR check = false then
            for itemIdx=0 to m.private.value.count() - 1 step 1
                valueAtIndex = m.private.value[itemIdx]
                if PNObject(valueAtIndex).isEqual(value) = true then index = itemIdx
                if index <> invalid then exit for
            end for
        end if
    end if
    
    return index
end function

' brief:  Remove specified value from 'array'.
'
' value  Reference on object which should be removed.
' check  Whether passed object types should be verified or not.
'
sub pn_arrayRemoveValue(value = invalid as Dynamic, check = true as Boolean)
    if value <> invalid then
        if check = true AND m.isArray() = true OR check = false then
            if check = true then check = false
            index = m.indexOf(value, check)
            if index <> invalid then m.private.value.delete(index)
        end if
    end if
end sub

' brief:  Remove specified values from 'array'.
'
' values  Reference on objects which should be removed.
' check   Whether passed object types should be verified or not.
'
sub pn_arrayRemoveValues(values = invalid as Dynamic, check = true as Boolean)
    if values <> invalid then
        if check = true AND m.isArray() = true OR check = false then
            if check = true then check = false
            for each value in values 
                index = m.indexOf(value, check)
                if index <> invalid then m.private.value.delete(index)
            end for
        end if
    end if
end sub

' brief:  Join array elements into single string using provided separator.
'
' separator Reference on string which should be used to join elements into single string.
'
function pn_arrayComponentsJoinedByString(separator as String) as Dynamic
    joinedComponents = invalid
    if m.isArray() = true then
        joinedComponents = ""
        for itemIdx=0 to m.private.value.count() - 1 step 1
            value = m.private.value[itemIdx]
            if value <> invalid then
                if joinedComponents.len() > 0 then joinedComponents = joinedComponents+separator
                joinedComponents = joinedComponents+value
            else
            end if
        end for
    end if
    
    return joinedComponents
end function

' brief:  Check whether specified array object is empty or not.
'
' check  Whether passed object types should be verified or not.
'
function pn_arrayIsEmpty(check = true as Boolean) as Boolean
    isArray = check = true AND m.isArray() = true OR check = false
    
    return isArray = true AND m.private.value.count() = 0 OR isArray = false 
end function

' brief:  Check whether stored and passed objects are arrays and they contain same data.
'
' array  Reference on second object against which check should be done.
'
function pn_arrayIsEqualContent(array = invalid as Dynamic) as Boolean
    isEqualContent = false
    if m.isArray() = true and PNArray(array).isArray() = true then
        isEqualContent = m.private.value.count() = array.count()
        if isEqualContent = true then
            for itemIdx=0 to m.private.value.count() - 1 step 1
                isEqualContent = PNArray(array).contains(m.private.value[itemIdx])
                if isEqualContent = false then exit for
            end for
        end if
    end if
    
    return isEqualContent
end function

' brief:  Check whether stored and passed objects are arrays and their content (including indices)
'         is equal.
'
' array  Reference on second object against which check should be done.
' check  Whether passed object types should be verified or not.
'
function pn_arrayIsEqualToArray(array = invalid as Dynamic, check = true as Boolean) as Boolean
    isEqual = false
    if check = true AND m.isArray() = true and PNArray(array).isArray() = true OR check = false then
        isEqual = m.private.value.count() = array.count()
        if isEqual = true then
            for itemIdx=0 to m.private.value.count() - 1 step 1
                value1 = m.private.value[itemIdx]
                value2 = array[itemIdx]
                if value1 <> invalid AND value2 <> invalid then
                    isEqual = PNObject(value1).isEqual(value2)
                else 
                    isEqual = (value1 = invalid AND value2 = invalid)
                end if
                if isEqual = false then exit for
            end for
        end if
    end if
    
    return isEqual
end function

' brief:  Check whether specified object is array or not.
'
function pn_arrayValidObject() as Boolean
    return m.private.value <> invalid AND type(m.private.value) = "roArray"
end function
