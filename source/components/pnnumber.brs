' brief:      Number (integer) values manipulation helper.
' discussion: This object contain set of functions which simplify routine number operations.
'
' number  Reference on object with which helper should work.
'
function PNNumber(number = invalid as Dynamic) as Object
    this = {private: {value: number}}
    this.min = pn_numberMinValue
    this.max = pn_numberMaxValue
    this.isBoolean = pn_numberBoolean
    this.isNumber = pn_numberValidObject
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:      Find minimum value.
' discussion: Use provided values to find which one of them is smaller.
'
' val1  First value which take part in comparison.
' val2  Second value which take part in comparison.
'
function pn_numberMinValue(val1 = invalid as Dynamic, val2 = invalid as Dynamic, check = true as Boolean) as Dynamic
    minimalValue = invalid
    if check = true AND PNNumber(val1).isNumber() = true AND PNNumber(val2).isNumber() = true OR check = false then
        if val1 < val2 then minimalValue = val1 else minimalValue = val2
    end if
    
    return minimalValue
end function

' brief:      Find maximum value.
' discussion: Use provided values to find which one of them is larger.
'
' val1  First value which take part in comparison.
' val2  Second value which take part in comparison.
'
function pn_numberMaxValue(val1 = invalid as Dynamic, val2 = invalid as Dynamic, check = true as Boolean) as Dynamic
    maximumValue = invalid
    if check = true AND PNNumber(val1).isNumber() = true AND PNNumber(val2).isNumber() = true OR check = false then
        if val1 > val2 then maximumValue = val1 else maximumValue = val2
    end if
    
    return maximumValue
end function

' brief:  Check whether specified object is boolean or not.
'
function pn_numberBoolean() as Boolean
    isBoolean = false
    if m.private.value <> invalid then
        isBoolean = getInterface(m.private.value, "ifBoolean") <> invalid
    end if
    
    return isBoolean
end function

' brief:  Check whether specified object is number or not.
'
function pn_numberValidObject() as Boolean
    valid = false
    if m.private.value <> invalid then
        valid = getInterface(m.private.value, "ifInt") <> invalid OR getInterface(m.private.value, "ifFloat") <> invalid
        if valid = false then
            valid = getInterface(m.private.value, "ifDouble") <> invalid OR getInterface(m.private.value, "ifLongInt") <> invalid
        end if
    end if
    
    return valid
end function