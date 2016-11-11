function PNNetwork(config as Object, port as Object) as Object
    instance = {
        private: {
            config: config
            urlBuilder: PNURLBuilder()
            subscriptionRequest: invalid
            requests: {}
            messagePort: port
            operationsWithResult: [
                PNOperationType().PNHistoryOperation
                PNOperationType().PNWhereNowOperation
                PNOperationType().PNHereNowGlobalOperation
                PNOperationType().PNHereNowForChannelOperation
                PNOperationType().PNHereNowForChannelGroupOperation
                PNOperationType().PNStateForChannelOperation
                PNOperationType().PNStateForChannelGroupOperation
                PNOperationType().PNChannelsForGroupOperation
                PNOperationType().PNTimeOperation
            ]
        }
    }
    
    scheme = "http://"
    if instance.private.config.secure = true then scheme = "https://"
    instance.private.baseURL = scheme+instance.private.config.origin

    instance.private.appendRequiredParameters = pn_networkingAppendRequiredParameters
    instance.private.requestURL = pn_networkingRequestURL
    instance.private.requestWithURL = pn_networkingRequestWithURL
    instance.private.getDefaultHeaders = pn_networkingGetDefaultHeaders

    instance.private.parseData = pn_networkingParseData
    
    instance.private.handleOperationCompletion = pn_networkingHandleOperationCompletion
    instance.private.handleOperationDidComplete = pn_networkingHandleOperationDidComplete
    instance.private.handleOperationDidFail = pn_networkingHandleOperationDidFail
    instance.private.handleParsedData = pn_networkingHandleParsedData
    
    instance.private.cancelSubscriptionRequest = pn_networkingCancelSubscriptionRequest
    instance.private.clientInformation = pn_networkingClientInformation
    
    instance.processOperation = pn_networkingProcessOperation
    instance.handleMessage = pn_networkingHandleMessage
    
    return instance
end function


'******************************************************
'
' Public API
'
'******************************************************
    
' brief:      Call REST API specific for passed operation type.
' discussion: This function take care about request execution and results parsing. As soon as 
'             data will be received and wrapped into objects it will be returned to data 
'             requesting code using completion function.
'
' operation      Reference on one of operation types described in PNOperationType().
' params         Set of data which is required by chosen operation type.
' postData       Reference on data which should be sent as POST body.
' completionData Set of data which should be passed to completion function after response / error 
'                will be processed.
' completion     Reference on function which is will be used by network layer to report about data
'                processing results.
function pn_networkingProcessOperation(operation as String, params as Object, postData = invalid as Dynamic, completionData = {} as Object, completion = invalid as Dynamic)
    
    ' Default values initialization
    if type(completion) = "<uninitialized>" then completion = invalid
    
    ' Cancel previously started subscription / unsubscription request.
    isSubscriptionRequest = operation = PNOperationType().PNSubscribeOperation OR operation = PNOperationType().PNUnsubscribeOperation
    if isSubscriptionRequest = true then m.private.cancelSubscriptionRequest()
    
    ' Configure request timeout.
    requestTimeout = m.private.config.nonSubscribeRequestTimeout
    if operation = PNOperationType().PNSubscribeOperation then requestTimeout = m.private.config.subscribeMaximumIdleTime
    
    ' Compose REST API URL using user-provided data.
    m.private.appendRequiredParameters(params)
    requestURL = m.private.requestURL(m.private.urlBuilder.URLForOperation(operation, params))
    if requestURL <> invalid then
        
        ' Create and configure request object.
        request = m.private.requestWithURL(requestURL, postData)
        request.setTimeout(requestTimeout)
        request.setUserInfo({operation: operation, completionData: completionData, completion: completion})
        
        ' Schedule request processing.
        if request.perform(m.private.messagePort) = true 
            if isSubscriptionRequest then m.private.subscriptionRequest = request
            m.private.requests[request.identity] = request
            ?"{INFO} Send request: "+requestURL
        else if completionData.callback <> invalid then
            ' Extract completion data information.
            cbContext = completionData.context
            cb = completionData.callback
        
            networkIssuesStatus = PNStatus(request)
            networkIssuesStatus.append(m.private.clientInformation())
            networkIssuesStatus.private.updateCategory(networkIssuesStatus, PNStatusCategory().PNNetworkIssuesCategory)
            
            if PNArray(m.private.operationsWithResult).contains(operation) = true then
                if cbContext <> invalid then cb(invalid, networkIssuesStatus, cbContext) else cb(invalid, networkIssuesStatus)
            else
                if cbContext <> invalid then cb(networkIssuesStatus, cbContext) else cb(networkIssuesStatus)
            end if
            networkIssuesStatus.delete("private")
        end if
    else if completionData.callback <> invalid then
        ' Compose dummy request object which should be used with result/status object constructor.
        request = m.private.requestWithURL(invalid, invalid)
        request.setUserInfo({operation: operation, category: PNStatusCategory().PNBadRequestCategory, handleResponse: false})
        
        ' Extract completion data information.
        cbContext = completionData.context
        cb = completionData.callback
        
        ' Report bad request status.
        badRequestStatus = PNErrorStatus(request)
        badRequestStatus.append(m.private.clientInformation())
        if PNArray(m.private.operationsWithResult).contains(operation) = true then
            if cbContext <> invalid then cb(invalid, badRequestStatus, cbContext) else cb(invalid, badRequestStatus)
        else
            if cbContext <> invalid then cb(badRequestStatus, cbContext) else cb(badRequestStatus)
        end if
        badRequestStatus.delete("private")
    end if
end function


'******************************************************
'
' Private functions
'
'******************************************************
    
'******************************************************
'
' URL builder helpers
'
'******************************************************

' brief:      Append general information which may be required during REST call to user-provided
'             parameters.
' discussion: Use client's configuration to complete REST API configuration.
'
' params  reference on object which represent request configuration object to which required 
'         parameters will be added.
function pn_networkingAppendRequiredParameters(params as Object)
    if m.config.subscribeKey <> invalid then params.path["{sub-key}"] = m.config.subscribeKey
    if m.config.publishKey <> invalid then params.path["{pub-key}"] = m.config.publishKey
    params.query.uuid = m.config.uuid
    params.query.deviceid = m.config.deviceID
    params.query.instanceid = m.config.instanceID
    params.query.requestid = createObject("roDeviceInfo").getRandomUUID()
    params.query.pnsdk = "PubNub-Roku%2F"+m.config.version
    if m.config.authKey <> invalid then params.query.authKey = m.config.authKey
end function

' brief: Compose full REST API URL using API end point path.
'
' requestURL  Reference on REST API endpoint path component.
'
function pn_networkingRequestURL(requestURL = invalid as Dynamic) as Dynamic
    fullURL = invalid
    if requestURL <> invalid then fullURL = m.baseURL+requestURL
    
    return fullURL
end function

' brief:      Prepare URL request object.
' discussion: Use provided information about REST API to build request object which will be used
'             to push or pull data from PubNub service.
'
' requestURL  reference on REST API URL which should be used during request.
' postData    reference on data which should be sent as POST body along with API call.
'
function pn_networkingRequestWithURL(requestURL= invalid as Dynamic, postData = invalid as Dynamic) as Object
    request = PNRequest(requestURL, postData)
    request.setHeaders(m.getDefaultHeaders())
    
    return request
end function

' brief:      Compose default request headers set.
' discussion: All requests share same set of request headers. This function allow to compose 
'             them once and re-use with every request.
'
function pn_networkingGetDefaultHeaders() as Object
    if m.defaultHeaders = invalid then
        headers = {"Accept": "*/*", "Accept-Encoding": "gzip,deflate", "Connection":"keep-alive"}
        deviceInfo = createObject("roDeviceInfo")
        firmwareVersion$ = deviceInfo.getVersion().mid(2, 4)
        userAgent$ = "Roku; CPU "+deviceInfo.getModel()+" OS "+firmwareVersion$+" Version"
        headers["User-Agent"] = userAgent$
        m.defaultHeaders = headers
    end if
    
    return m.defaultHeaders
end function
    
    
'******************************************************
'
' Parsers
'
'******************************************************

' brief:      Process service response using provided parser.
' discussion: Each operation can be processed with specific parser and it's response later will 
'             be used with corresponding status/result object.
'
' request          Reference on completed REST API call request object which contain all required 
'                  information.
' parser           Reference on service response data parser function.
' parseCompletion  reference on function which should be called when data processing will be 
'                  completed and data parsing results will be returned using it.
function pn_networkingParseData(request as Object, parser as Function, parseCompletion as Function)
    ' Default values initialization
    if type(completion) = "<uninitialized>" then completion = invalid
    userInfo = request.getUserInfo()
    parsedData = invalid

    ' Parse service response.
    requireAdditionalData = userInfo.operation = PNOperationType().PNSubscribeOperation OR userInfo.operation = PNOperationType().PNHistoryOperation
    if requireAdditionalData = true AND parser = PNErrorParser then requireAdditionalData = false
    if requireAdditionalData = true then
        parsedData = parser().parse(request.response.data, {cipherKey: m.config.cipherKey})
    else
        parsedData = parser().parse(request.response.data)
    end if
    if parsedData <> invalid OR parser = PNErrorParser then
        if parser = PNErrorParser then ?"{ERROR} Data parse error: ",request.response.data
        parseCompletion(m, request, parsedData, parser = PNErrorParser) 
    else
        m.parseData(request, PNErrorParser, parseCompletion)
    end if
end function
    
    
'******************************************************
'
' Handlers
'
'******************************************************

' brief:      Handle single 'run-loop tick'.
' discussion: Function called by PubNub client on every 'run-loop tick' to check whether some 
'             scheduled data retrieval arrived and should be processed or not.
'
' message  Reference on event/message received from messages port object at 'run-loop tick'.
'  
function pn_networkingHandleMessage(message = invalid as Dynamic) as Boolean
    handled = false
    
    ' Handle request response event.
    if type(message) = "roUrlEvent" then
        handled = true
        requestIdentifier = box(message.getSourceIdentity()).toStr()
        request = m.private.requests[requestIdentifier]
        request.handleResponse(message)
        
        ' Process received request response.
        m.private.handleOperationCompletion(request)
        
        ' Remove request object from further processing.
        m.private.requests.delete(requestIdentifier)
        request.destroy()
    end if 
    
    ' Check timed out / failed requests and report about failure.
    invalidatedRequests = []
    for each requestIdentifier in m.private.requests
        request = m.private.requests[requestIdentifier]
        failedRequest = PNString(request.getFailureReason()).isString() = true AND request.getFailureReason().len() > 0
        if request.isTimedOut() = true OR failedRequest = true then
            if failedRequest = true then request.handleResponse(invalid)
            if failedRequest = true then ?"{ERROR} Failure reason:",request.getFailureReason()
        
            ' Process failed request.
            m.private.handleOperationCompletion(request)
            invalidatedRequests.push(requestIdentifier)
        end if
    end for
    
    for each requestIdentifier in invalidatedRequests
        request = m.private.requests[requestIdentifier]
        
        ' Remove request object from further processing.
        m.private.requests.delete(requestIdentifier)
        request.destroy()
    end for
    
    return handled
end function

' brief:      Handle request processing completion.
' discussion: Function used by networking layer to process completed request response.
'
' request  Reference on request which execution has been completed and service-provided data should
'          be handled.
'
function pn_networkingHandleOperationCompletion(request as Object)
    statusCode = PNObject(PNObject(request).valueAtKeyPath("response.statusCode")).default(0)
    if statusCode = 200 then m.handleOperationDidComplete(request) else m.handleOperationDidFail(request)
    m.cancelSubscriptionRequest(request)
end function

' brief:      Handle successful operation completion.
' discussion: Process successful operation request completion and perform corresponding data 
'             parsing.
'
' request  Reference on request which execution has been completed and service-provided data should
'          be handled.
'
function pn_networkingHandleOperationDidComplete(request as Object)
    parseCompletion = function(context as Object, request as Object, parsedData = invalid as Dynamic, parseError = false as Boolean)
        if parsedData <> invalid then request.response.data = parsedData
        context.handleParsedData(request, parseError)
    end function
    m.parseData(request, PNParser(request.getUserInfo().operation), parseCompletion)
end function

' brief:      Handle operation processing failure.
' discussion: Process request failure information and perform corresponding data parsing.
'
' request  Reference on request which execution has been completed and service-provided data should
'          be handled.
'
function pn_networkingHandleOperationDidFail(request as Object)
    parseCompletion = function(context as Object, request as Object, parsedData = invalid as Dynamic, parseError = false as Boolean)
        userInfo = PNObject(PNObject(request.getUserInfo()).default({})).copy()
        if parsedData <> invalid then request.response.data = parsedData
        
        ' Set category to 'Timeout' in case if no service response has been provided.
        if parseError = false AND request.response.statusCode = 0 then 
            userInfo.category = PNStatusCategory().PNTimeoutCategory
        end if
        request.setUserInfo(userInfo)
        
        context.handleParsedData(request, parseError)
    end function
    
    if request.response.data <> invalid then 
        if request.response.data.code = -10001 then
            m.handleOperationDidComplete(request)
        else
            m.parseData(request, PNErrorParser, parseCompletion)
        end if
    else
        parseCompletion(m, request, invalid, false)
    end if
end function

' brief:      Handle parsed data.
' discussion: Function called by code which triggered data parsing process and used to forward 
'             parsed data to object creation code.
'
' request      Reference on request which execution has been completed and service-provided data should
'              be handled.
' parseError   reference on flag which tell whether data parsing did fail or not.
'
function pn_networkingHandleParsedData(request as Object, parseError = false as Boolean)
    userInfo = request.getUserInfo()
    operation = userInfo.operation
    completion = userInfo.completion
    completionData = userInfo.completionData
    
    if type(completion) = "<uninitialized>" OR completion = invalid then
        if PNArray(m.operationsWithResult).contains(operation) = true then
            completion = pn_networkingDefaultResultHandler
        else
            completion = pn_networkingDefaultStatusHandler
        end if
    end if
    
    resultObject = invalid
    statusObject = invalid
    if PNArray(m.operationsWithResult).contains(operation) = true AND parseError = false then
        constructor = PNResultObjectForOperation(operation)
        resultObject = constructor(request)
    end if
    
    if parseError = true OR PNArray(m.operationsWithResult).contains(operation) = false then
        constructor = PNStatusObjectForOperation(operation)
        statusObject = constructor(request)
        
        if statusObject.category = PNStatusCategory().PNCancelledCategory then
            ?"{INFO} Cancelled request: "+request.getURL()
        end if
    end if
    
    if resultObject <> invalid OR statusObject <> invalid then
        deleteProvateForStatusObject = false
        if resultObject <> invalid then
            resultObject.delete("private")
            resultObject.append(m.clientInformation())
        end if
        
        if statusObject <> invalid then
            subscriptionStatusChange = statusObject.operation = PNOperationType().PNSubscribeOperation AND statusObject.category = PNStatusCategory().PNAcknowledgmentCategory
            if subscriptionStatusChange = false then deleteProvateForStatusObject = true
            if statusObject.error = false then
                statusObject.delete("errorData")
            end if
            statusObject.append(m.clientInformation())
        end if
        
        if completion <> invalid then
            if PNArray(m.operationsWithResult).contains(operation) = true then
                completion(resultObject, statusObject, completionData)
            else
                completion(PNObject(resultObject).default(statusObject), completionData)
            end if
            if statusObject <> invalid AND deleteProvateForStatusObject = true then
                statusObject.delete("private")
            end if
        end if
    end if
end function

' brief:      Default result processing completion handler.
' discussion: Not all API calling code may pass completion handlers in cases if there is no 
'             additional logic which should be done before returning objects to caller code. This
'             function used to handle default results processing.
'
' result  Reference on fetched PubNub service information (if no error).
' status  Reference on API call status object (in case of error)
' data    Reference on object which contain information which is required to retry API call.
'
function pn_networkingDefaultResultHandler(result = invalid as Dynamic, status = invalid as Dynamic, data = {} as Object)
    if status <> invalid AND status.error = true then
        retry = {client: data.client, params: data.params, callback: data.callback, context: data.context}
        status.private = {retryData: retry}
        status.retry = function()
            retryData = m.private.retryData
            retryFunction = PNObject(retryData.client).valueAtKeyPath(retryData.func)
            if retryFunction <> invalid then
                retryFunction(retryData.params, retryData.callback, retryData.context)
            end if
        end function
    end if
    if data.context <> invalid then data.callback(result, status, data.context) else data.callback(result, status)
end function

' brief:      Default status processing completion handler.
' discussion: Not all API calling code may pass completion handlers in cases if there is no 
'             additional logic which should be done before returning objects to caller code. This
'             function used to handle default status processing.
'
' status  Reference on API calling status object.
' data    Reference on object which contain information which is required to retry API call.
'
function pn_networkingDefaultStatusHandler(status = invalid as Dynamic, data = {} as Object)
    if status.error = true then
        retry = {client: data.client, params: data.params, callback: data.callback, context: data.context}
        status.private = {retryData: retry}
        status.retry = function()
            retryData = m.private.retryData
            retryFunction = PNObject(retryData.client).valueAtKeyPath(retryData.func)
            if retryFunction <> invalid then
                retryFunction(retryData.params, retryData.callback, retryData.context)
            end if
        end function
    end if
    if data.context <> invalid then data.callback(status, data.context) else data.callback(status)
end function
    
    
'******************************************************
'
' Misc
'
'******************************************************

' brief:      Cancel currently active subscribe request.
' discussion: At the same moment there can be only one subscribe/unsubscribe requests at a time 
'             and this function allow to cancel previously started request. If request identity
'             has been passed, stored request will be compared against it to verify what it is 
'             stored request itself (subscribe/unsubscribe request).
'
' request  Reference on request which should be checked on whether it represent subscribe request 
'          or not.
'
function pn_networkingCancelSubscriptionRequest(request = invalid as Dynamic)
    if m.subscriptionRequest <> invalid then 
        if request = invalid OR m.subscriptionRequest.isEqual(request) = true then
            m.subscriptionRequest.destroy(true)
            m.subscriptionRequest = invalid
        end if
    end if
end function

' brief:  Shared client information.
'
function pn_networkingClientInformation() as Object
    config = m.config
    
    return {secure: config.secure, uuid: config.uuid, authKey: config.authKey, origin: config.origin}
end function
