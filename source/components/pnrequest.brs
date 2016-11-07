' brief:      Network requests wrapper.
' discussion: Wrapper provide better data handling and request identification in client's 
'             'run-loop'.
'
function PNRequest(requestURL = invalid as Dynamic, postData = invalid as Dynamic) as Object
    if requestURL <> invalid then
        ' Default values initialization
        if type(postData) = "<uninitialized>" then postData = invalid
    
        request = createObject("roUrlTransfer")
        this = {identity: box(request.getIdentity()).toStr(), request: {request: request}, private: {}}
        this.request.postBody = postData
        
        ' Check whether secured connection should be used.
        if PNString(requestURL).hasPrefix("https") then
            request.setCertificatesFile("common:/certs/ca-bundle.crt")
            request.EnablePeerVerification(true)
            request.enableHostVerification(true)
            request.initClientCertificates()
        end if
        request.retainBodyOnError(true)
        request.setUrl(requestURL)
    
        ' Decide on HTTP request method.
        if postData <> invalid then requestMethod = "POST" else requestMethod = "GET"
        request.setRequest(requestMethod)
        
        ' Enable gzip encoding if post request will be done.
        if requestMethod = "POST" then request.enableEncodings(true)
    else 
        this = {request:{}, private: {}}
    end if
    this.error = false

    this.setHeaders = pn_requestSetHeaders
    this.setTimeout = pn_requestSetTimeout
    this.isTimedOut = pn_requestisTimedOut
    this.perform = pn_requestPerform
    this.handleResponse = pn_requestHandlerResponse
    this.getURL = pn_requestGetURL
    this.getFailureReason = pn_requestGetFailureReason
    this.getUserInfo = pn_requestGetUserInfo
    this.setUserInfo = pn_requestSetUserInfo
    this.isEqual = pn_requestIsEqual
    this.destroy = pn_requestDestroy
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:  Set user-provided request headers.
'
' headers  Reference on object which contain required HTTP headers set to get proper response from
'          PubNub service.
'
sub pn_requestSetHeaders(headers as Object)
    if m.request.request <> invalid then
        m.request.headers = PNObject(headers).copy(1)
        m.request.request.setHeaders(m.request.headers)
    end if
end sub

' brief:      Configure request timeout.
' discussion: Object will create timespan object which will be used during timeout check. 
'
' timeout  Maximum request execution time.
'
sub pn_requestSetTimeout(timeout as Integer)
    if m.request.request <> invalid then m.request.timeout = {clock: createObject("roTimespan"), value: (timeout * 1000)}
end sub

' brief:  Check whether REST API call request timed out or not.
'
function pn_requestisTimedOut() as Boolean
    if m.request.request <> invalid then return m.request.timeout.clock.totalMilliseconds() > m.request.timeout.value else return false
end function

' brief:      Schedule asynchronous request execution.
' discussion: To get response on asynchronous request it will use message port (from 'run-loop') to 
'             listen when data will be available.
'
' messagePort  Reference on messages port to which response event will be sent on execution 
'              completion.
function pn_requestPerform(messagePort as Object) as Boolean
    canStart = false
    if m.request.request <> invalid then 
        m.request.request.setMessagePort(messagePort)
        if m.request.postBody <> invalid then
            canStart = m.request.request.asyncPostFromString(m.request.postBody)
        else
            canStart = m.request.request.asyncGetToString()
        end if
    end if
    
    return canStart
end function

' brief:  Perform initial request response processing.
'
' response  Reference on event which contain results of request execution and service response.
'
sub pn_requestHandlerResponse(response = invalid as Dynamic)
    if response <> invalid then
        m.response = {statusCode: PNObject(response.getResponseCode()).default(0)}
        if m.response.statusCode >= 0 then
            m.response.headers = PNObject(response.getResponseHeaders()).default({})
            m.response.rawData = response.getString()
            m.response.data = parseJSON(m.response.rawData)
            isCollection = PNObject(m.response.data).isDictionary() = true OR PNArray(m.response.data).isArray() = true
            if isCollection = false then m.response.data = invalid
        end if
    else
        m.response = {statusCode: 0}
    end if
    
    ' Fetch error information (if request failed).
    failureReason = response.getFailureReason() 
    if m.response.data = invalid AND failureReason <> invalid then
        m.error = true
        m.request.error = {message: failureReason, code: m.response.statusCode}
    end if
end sub

' brief:  Retrieve full REST API URL which has been used for request.
'
function pn_requestGetURL() as String
    if m.request.request <> invalid then return m.request.request.getUrl() else return ""
end function

' brief:  Retrieve requests execution failure reason (if failed).
'
function pn_requestGetFailureReason() as Dynamic
    if m.request.request <> invalid then return m.request.request.getFailureReason() else return invalid
end function

' brief:  Retrieve user-provided data which temporary has been stored along with request.
'
function pn_requestGetUserInfo() as Dynamic
    return m.private.userInformation
end function

' brief:  Persistently store user-provided information till request processing completion.
'
' info  Reference on object which should be temporary persisted along with request.
'
sub pn_requestSetUserInfo(info = invalid as Dynamic)
    if info <> invalid then m.private.userInformation = info
end sub

' brief:  Check whether passed request is equal to receiver or not.
'
' request  Reference on request object against which check should be done.
'
function pn_requestIsEqual(request = invalid as Dynamic) as Boolean
    isEqual = false
    if request <> invalid then isEqual = m.identity = request.identity
    
    return isEqual
end function

' brief:  Destroy request object.
'
sub pn_requestDestroy(cancelOnly = false as Dynamic)
    statusCode = PNObject(PNObject(m.response).valueAtKeyPath("statusCode")).default(0)
    if m.request.request <> invalid AND statusCode = 0 then m.request.request.asyncCancel()
    if cancelOnly = false then m.private.delete("userInformation")
end sub
