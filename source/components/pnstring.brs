' brief:      String manipulation helper.
' discussion: This object contain set of functions which simplify routine string operations.
'
' stringValue  Reference on object with which helper should work.
'
function PNString(stringValue = invalid as Dynamic) as Object
    this = {private: {value: stringValue}}
    this.hasPrefix = pn_stringHasPrefix
    this.hasSuffix = pn_stringHasSuffix
    this.trim = pn_stringTrim
    this.repeat = pn_stringRepeat
    this.isEmpty = pn_stringIsEmpty
    this.escape = pn_stringEscape
    this.unescape = pn_stringUnescape
    this.isString = pn_stringValidObject
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Check whether string has specified prefix or not.
'
' prefix  Reference on string which should be searched at the 'value' beginning.
' 
function pn_stringHasPrefix(prefix as String) as Boolean
    prefixLen = prefix.len()
    hasPrefix = m.isString() = true AND m.private.value.len() >= prefixLen
    hasPrefix = hasPrefix = true AND m.private.value.left(prefixLen) = prefix
    
    return hasPrefix
end function

' brief:  Check whether string has specified suffix or not.
'
' prefix  Reference on string which should be searched at the 'value' end.
' 
function pn_stringHasSuffix(suffix as String) as Boolean
    suffixLen = suffix.len()
    hasSuffix = m.isString() = true AND m.private.value.len() >= suffixLen
    hasSuffix = hasSuffix = true AND m.private.value.right(suffixLen) = suffix
    
    return hasSuffix
end function

' brief:  Trim provided string beginning and ending from provided 'char'.
'
' trimmedChar  Reference on char which is searched and removed from provided string beginning and 
'              ending.
' 
function pn_stringTrim(trimmedChar = invalid as Dynamic) as Dynamic
    timmedString = invalid
    if m.isString() = true AND PNString(trimmedChar).isString() = true then
        while m.hasPrefix(trimmedChar)
            if m.isEmpty() = false then m.private.value = m.private.value.mid(1) else exit while
        end while
    
        while m.hasSuffix(trimmedChar)
            if m.isEmpty() = false then 
                m.private.value = m.private.value.mid(m.private.value.len() - 1) 
            else
                exit while
            end if
        end while
        timmedString = m.private.value
    end if
    
    return timmedString
end function

function pn_stringRepeat(count = -1 as Integer) as Dynamic
    if count = -1 then repeatedString = "" else repeatedString = m.private.value
    if count > 0 then
        repeatedString = ""
        for idx=0 to count - 1 step 1
            repeatedString = repeatedString + m.private.value
        end for
    end if
    
    return repeatedString
end function

' brief:  Perform URL encoding on provided string object.
' 
function pn_stringEscape() as Dynamic
    escapedString = invalid
    if m.isString() = true then
        escapedString = createObject("roUrlTransfer").escape(m.private.value)
    end if
    
    return escapedString
end function

' brief:  Perform URL decoding on provided string object.
' 
function pn_stringUnescape() as Dynamic
    unescapedString = invalid
    if m.isString() = true then 
        unescapedString = CreateObject("roUrlTransfer").unescape(m.private.value)
    end if
    
    return unescapedString
end function

' brief:  Check whether specified object represent empty string or not.
'
' stringValue  Reference on object which should be verified for zero-length string.
' 
function pn_stringIsEmpty() as Boolean
    isString = m.isString()
    
    return isString = true AND m.private.value.len() = 0 OR isString = false
end function

' brief:  Check whether specified object is string or not.
'
function pn_stringValidObject() as Boolean
    return m.private.value <> invalid AND getInterface(m.private.value, "ifString") <> invalid
end function
