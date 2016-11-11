' brief:      Result of API endpoints which return data.
' discussion: Base object which is used to represent service-provided data (in response on API 
'             call).
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNResult(request as Object) as Object
    userInfo = request.getUserInfo()
    this = {
        ' brief: PubNub service REST API response status code.
        '
        statusCode: PNObject(PNObject(request).valueAtKeyPath("response.statusCode")).default(0)
        
        ' brief: One of existing operation types for which object has been created.
        '
        operation: userInfo.operation
        
        ' brief: Whether REST API call has been done using secured connection or not.
        '
        secure: false
        
        ' brief: Reference on unique user identifier with which PubNub client has been configured.
        '
        uuid: invalid
        
        ' brief:      Reference on authorization key used with PAM add-on
        ' discussion: If PAM add-on enabled PubNub service will use this key to check whether PubNub
        '             client has access to requested resource or not enough of access rights.  
        '
        authKey: invalid
        
        ' brief: Stores reference on origin name which is used with REST API calls. 
        '
        origin: invalid
        
        ' brief: Stores reference on URL which is used to perform REST API call.
        '
        request: request.getURL()
        
        ' brief: Stores whether received service response is unexpected or not.
        '
        unexpectedResponse: false
        
        ' brief:      Reference on set of private variables and functions.
        ' discussion: Members of associative array used by PubNub client itself and shouldn't be 
        '             called directly.
        '
        private: {response: PNObject(PNObject(request).valueAtKeyPath("response.data")).default({})}
    }
    this.private.normalizedResponse = pn_resultNormalizedResponse
    this.private.copy = pn_resultCopy
    this.private.copyWithMutatedData = pn_resultCopyWithMutatedData
    this.private.copyWithServiceData = pn_resultCopyWithServiceData
    this.private.updateData = pn_resultUpdateData
    
    if this.statusCode = 0 then this.statusCode = 200
    if PNNumber(PNObject(this.private.response).valueAtKeyPath("status")).isNumber() = true then
        statusCode% = this.private.response["status"]
        this.private.response.delete("status")
        if statusCode% > 200 then this.statusCode = statusCode%
    else if this.private.response <> invalid AND PNObject(this.private.response).isDictionary() = false then
        this.unexpectedResponse = true
        this.private.response = this.private.normalizedResponse(this.private.response)
    end if
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:      Ensure what passed 'response' has required data type (dictionary). If 'response' 
'             has different data type, it will be wrapped into dictionary.
' discussion: If unexpected data type will be passes, object will set corresponding flag, so it 
'             will be processed and printed out to log file for further investigation.
'
function pn_resultNormalizedResponse(serviceResponse = invalid as Dynamic) as Dynamic
    normalizedResponse = serviceResponse
    if serviceResponse <> invalid then
        if PNObject(serviceResponse).isDictionary() = false then
            normalizedResponse = {"information": serviceResponse} 
        end if
    else
        normalizedResponse = invalid
    end if
    
    return normalizedResponse
end function

' brief:      Make deep object copy.
' discussion: Method will create copy of all fields and functions which is used as entries in 
'             'object' definition.
'
' 'obj'  Reference on object who's structure should be copied ('subclass' or PNResult).
'
function pn_resultCopy(obj as Object) as Object
    return obj.private.copyWithServiceData(obj)
end function

' brief:      Make copy of current result object with mutated data which should be stored in it.
' discussion: Method can be used to create sub-events (for example one for each message or 
'             presence event).
'
' 'obj'  Reference on object who's service response should be updated with 'data' ('subclass' or 
'        PNResult).
'
function pn_resultCopyWithMutatedData(obj = invalid as Dynamic, data = invalid as Dynamic) as Object
    copy = obj.private.copyWithServiceData(obj, false)
    copy.private.updateData(copy, data)
    
    return copy
end function

' brief: Create instance copy with additional adjustments on whether service data information 
'        should be copied or not.
'
' 'obj'  Reference on object from which copy should be created('subclass' or PNResult).
'
function pn_resultCopyWithServiceData(obj as Object, shouldCopyResponse = true as Boolean) as Object
    copy = PNObject(obj).copy(1)
    if shouldCopyResponse = false then copy.private.delete("response")
    
    return copy
end function

' brief: Update data stored for result object.
'
' 'obj'  Reference on object who's service response should be updated with 'data' ('subclass' or 
'        PNResult).
'
function pn_resultUpdateData(obj as Object, data = invalid as Dynamic)
    obj.private.response = obj.private.normalizedResponse(data)
    obj.unexpectedResponse = PNObject(data).isDictionary() = false
    if obj.data <> invalid AND obj.unexpectedResponse = false then obj.data = data
end function
