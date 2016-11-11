' brief:      Status of API endpoints which return data.
' discussion: Base object which is used to represent status of API call basing on service response.
'
' request  Reference on object which contain information about performed request and it's 
'          processing results.
'
function PNStatus(request as Object) as Object
    userInfo = request.getUserInfo()
    this = PNResult(request)
    this.category = PNObject(userInfo.category).default(PNStatusCategory().PNUnknownCategory)
    this.automaticallyRetry = false
    this.private.updateCategory = pn_statusUpdateCategory
    
    ' Process special case with client's connection state change or incomplete REST API request.
    if userInfo.handleResponse <> invalid then 
        nonErrorCategories = [
            PNStatusCategory().PNConnectedCategory
            PNStatusCategory().PNReconnectedCategory
            PNStatusCategory().PNDisconnectedCategory
            PNStatusCategory().PNUnexpectedDisconnectCategory
            PNStatusCategory().PNCancelledCategory
            PNStatusCategory().PNAcknowledgmentCategory
        ]
        if PNArray(nonErrorCategories).contains(this.category) = true then 
            this.error = false
            this.statusCode = 200
        else if this.category <> PNStatusCategory().PNUnknownCategory then 
            this.error = true
            this.statusCode = 400
            if this.category = PNStatusCategory().PNAccessDeniedCategory then this.statusCode = 403
        end if 
    else
        errorDescription = PNObject(request.request.error).default(request.response.data)
        this.error = request.error = true OR this.statusCode <> 200
        if this.error = true AND errorDescription <> invalid then
            this.private.updateData(this, pn_statusDataFromError(errorDescription))
        end if 
        
        if this.statusCode = 200 AND this.error = false then
            this.category = PNStatusCategory().PNAcknowledgmentCategory
        else if this.category = PNStatusCategory().PNUnknownCategory then
            ' Try extract category basing on response status codes.
            this.category = pn_statusCategoryTypeFromStatusCode(this.statusCode)
            
            ' Extract status category from passed error object.
            if this.category = PNStatusCategory().PNUnknownCategory AND errorDescription <> invalid then
                this.category = pn_statusCategoryTypeFromError(errorDescription)
            end if
            
            
            ' Extract status category from status code.
            if this.category = PNStatusCategory().PNUnknownCategory AND this.statusCode = 400 then
                this.category = PNStatusCategory().PNBadRequestCategory
            end if
        end if
        if this.category = PNStatusCategory().PNCancelledCategory then this.error = false
    end if
    
    return this
end function


REM ******************************************************
REM
REM Private functions
REM
REM ******************************************************
    
' brief: Alter status category.
'
' 'obj'  Reference on object who's service category should be changed ('subclass' or PNStatus).
'
function pn_statusUpdateCategory(obj as Object, category as String)
    connectionStateCategories = [
        PNOperationType().PNConnectedCategory
        PNOperationType().PNReconnectedCategory
        PNOperationType().PNDisconnectedCategory
        PNOperationType().PNUnexpectedDisconnectCategory
    ]
    obj.category = category
    if category = PNStatusCategory().PNDecryptionErrorCategory then 
        obj.error = true
    else if PNArray(connectionStateCategories).contains(category) = true then
        obj.error = false
    end if
end function

' brief: Try interpret response status code meaningful status object state.
'
function pn_statusCategoryTypeFromStatusCode(statusCode as Integer) as String
    category = PNStatusCategory().PNUnknownCategory
    if statusCode = 403 then 
        category = PNStatusCategory().PNAccessDeniedCategory
    else if statusCode = 481 then 
        category = PNStatusCategory().PNMalformedFilterExpressionCategory
    end if
    
    return category
end function

' brief: Try interpret error object to meaningful status object state.
'
function pn_statusCategoryTypeFromError(error as Object) as String
    category = PNStatusCategory().PNUnknownCategory
    
    ' CURLE_SSL_CACERT_BADFILE = -28
    if error.code = -28 then 
        category = PNStatusCategory().PNTimeoutCategory
        
    ' CURLE_COULDNT_RESOLVE_HOST = -6
    ' CURLE_COULDNT_CONNECT = -7
    ' CURLE_FTP_CANT_GET_HOST = -15
    ' CURLE_INTERFACE_FAILED = -45
    else if error.code = -6 OR error.code = -7 OR error.code = -15 OR error.code = -45 then
        category = PNStatusCategory().PNNetworkIssuesCategory
        
    ' CURLE_GOT_NOTHING = -52
    ' CURLE_BAD_CONTENT_ENCODING = -61
    else if error.code = -52 OR error.code = -61 then
        category = PNStatusCategory().PNMalformedResponseCategory
    
    ' Unexpected service response.
    else if error.service <> invalid AND error.information <> invalid then
        category = PNStatusCategory().PNMalformedResponseCategory
    ' CURLE_URL_MALFORMAT = -3
    else if error.code = -3 then
        category = PNStatusCategory().PNBadRequestCategory
        
    ' CURLE_SSL_CONNECT_ERROR = -35
    ' CURLE_SSL_ENGINE_NOTFOUND = -53
    ' CURLE_SSL_ENGINE_SETFAILED = -54
    ' CURLE_SSL_CERTPROBLEM = -58
    ' CURLE_SSL_CIPHER = -59
    ' CURLE_SSL_ENGINE_INITFAILED = -66
    ' CURLE_SSL_CACERT_BADFILE = -77
    else if error.code = -35 OR error.code = -53 OR error.code = -54 OR error.code = -58 OR error.code = -59 OR error.code = -66 OR error.code = -77 then
        category = PNStatusCategory().PNTLSConnectionFailedCategory
        
    ' CURLE_PEER_FAILED_VERIFICATION = -51
    else if error.code = -51 then
        category = PNStatusCategory().PNTLSUntrustedCertificateCategory
        
    ' CANCELLED = -10001 (NOT DOCUMENTED)
    else if error.code = -10001 then
        category = PNStatusCategory().PNCancelledCategory
    end if
    
    if category = PNStatusCategory().PNUnknownCategory then
        if PNObject(error).valueAtKeyPath("response.service") = "Access Manager" then
            category = PNStatusCategory().PNAccessDeniedCategory
        end if
    end if
    
    return category
end function

' brief: Try extract useful data from error object (in case if service provided some feedback).
'
function pn_statusDataFromError(error as Object) as Dynamic
    details = invalid
    
    if error.information <> invalid then details = error.information
    if details <> invalid AND PNObject(details).isDictionary() = false then details = {"information": details}
     
    return details
end function
