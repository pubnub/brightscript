' brief:      Timer object.
' discussion: Object allow to build and using 'run-loop' trigger delayed events (simulating timer).
'
' delay        After how many seconds passed 'callback' should fire. Actual fire date depends from 
'              used 'timeout' value for 'wait' function.
' callbackData Reference on object which will be passed into 'callback' - this make it possible to 
'              pass context to 'callback' function.
' callback     Reference on callback function which will be called at calculated date (using 'delay'
'              value).
' repeat       Whether after timer 'callback' call new date should be calculated and used or timer 
'              should be invalidated.
'
function PNTimer(delay as Integer, callbackData as Object, callback as Function, repeat = true as Boolean) as Object
    this = {
        private: {
            clock: createObject("roTimespan")
            delay: delay * 1000
            repeat: repeat
            running: false
            callbackData: callbackData
            callback: callback
        }
        start: pn_timerStart
        tick: pn_timerHandleTick
        "stop": pn_timerStart
        invalidate: pn_timerInvalidate
    }
    
    return this
end function


'******************************************************
'
' Private functions
'
'******************************************************

' brief:      Schedule delayed callback execution.
' discussion: During schedule process target execution date is calculated and timer set to 'working' 
'             state.
'
sub pn_timerStart()
    if m.private.clock <> invalid then
        m.private.nextFireDate = m.private.clock.totalMilliseconds() + m.private.delay
        m.private.running = true
    end if
end sub

' brief:      'Run-loop' tick handler function.
' discussion: Called by code which build this timer object on every 'run-loop' tick. With every 
'             handler function call timer object calculate whether callback function should be 
'             called or not.
'
sub pn_timerHandleTick()
    clock = m.private.clock
    if clock <> invalid AND m.private.running = true AND clock.TotalMilliseconds() > m.private.nextFireDate then
        m.private.callback(m.private.callbackData)
        if m.private.repeat = true then
            m.private.nextFireDate = m.private.clock.totalMilliseconds() + m.private.delay
        else
            m.invalidate()
        end if
    end if
end sub

' brief:      Stop 'run-loop' ticks handling.
' discussion: When stopped timer won't process 'run-loop' ticks and execute callback function. 
'
sub pn_timerStop()
    m.private.running = false
end sub

' brief:      Terminate timer object.
' discussion: Timer object will be invalidated and won't be able to run anymore. This also used as 
'             opportunity to break any circular reference inside of 'callbackData' object.
'
sub pn_timerInvalidate()
    m.private = {running: false}
end sub
