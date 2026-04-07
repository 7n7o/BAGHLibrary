local __TAD__={cache={}}do do local function __modImpl()



local ERROR_NON_PROMISE_IN_LIST = 'Non-promise value passed into %s at index %s'
local ERROR_NON_LIST = 'Please pass a list of promises to %s'
local ERROR_NON_FUNCTION = 'Please pass a handler function to %s!'
local MODE_KEY_METATABLE = {
    __mode = 'k',
}

local function isCallable(value)
    if type(value) == 'function' then
        return true
    end
    if type(value) == 'table' then
        local metatable = getmetatable(value)

        if metatable and type(rawget(metatable, '__call')) == 'function' then
            return true
        end
    end

    return false
end
local function makeEnum(enumName, members)
    local enum = {}

    for _, memberName in ipairs(members)do
        enum[memberName] = memberName
    end

    return setmetatable(enum, {
        __index = function(_, k)
            error(string.format('%s is not in %s!', k, enumName), 2)
        end,
        __newindex = function()
            error(string.format('Creating new members in %s is not allowed!', enumName), 2)
        end,
    })
end

local Error

do
    Error = {
        Kind = makeEnum('Promise.Error.Kind', {
            'ExecutionError',
            'AlreadyCancelled',
            'NotResolvedInTime',
            'TimedOut',
        }),
    }
    Error.__index = Error

    function Error.new(options, parent)
        options = options or {}

        return setmetatable({
            error = tostring(options.error) or '[This error has no error text.]',
            trace = options.trace,
            context = options.context,
            kind = options.kind,
            parent = parent,
            createdTick = os.clock(),
            createdTrace = debug.traceback(),
        }, Error)
    end
    function Error.is(anything)
        if type(anything) == 'table' then
            local metatable = getmetatable(anything)

            if type(metatable) == 'table' then
                return rawget(anything, 'error') ~= nil and type(rawget(metatable, 'extend')) == 'function'
            end
        end

        return false
    end
    function Error.isKind(anything, kind)
        assert(kind ~= nil, 'Argument #2 to Promise.Error.isKind must not be nil')

        return Error.is(anything) and anything.kind == kind
    end
    function Error:extend(options)
        options = options or {}
        options.kind = options.kind or self.kind

        return Error.new(options, self)
    end
    function Error:getErrorChain()
        local runtimeErrors = {self}

        while runtimeErrors[#runtimeErrors].parent do
            table.insert(runtimeErrors, runtimeErrors[#runtimeErrors].parent)
        end

        return runtimeErrors
    end
    function Error:__tostring()
        local errorStrings = {
            string.format('-- Promise.Error(%s) --', self.kind or '?'),
        }

        for _, runtimeError in ipairs(self:getErrorChain())do
            table.insert(errorStrings, table.concat({
                runtimeError.trace or runtimeError.error,
                runtimeError.context,
            }, '\n'))
        end

        return table.concat(errorStrings, '\n')
    end
end

local function pack(...)
    return select('#', ...), {...}
end
local function packResult(success, ...)
    return success, select('#', ...), {...}
end
local function makeErrorHandler(traceback)
    assert(traceback ~= nil, 'traceback is nil')

    return function(err)
        if type(err) == 'table' then
            return err
        end

        return Error.new({
            error = err,
            kind = Error.Kind.ExecutionError,
            trace = debug.traceback(tostring(err), 2),
            context = 'Promise created at:\n\n' .. traceback,
        })
    end
end
local function runExecutor(
    traceback,
    callback,
    ...
)
    return packResult(xpcall(callback, makeErrorHandler(traceback), 
...))
end
local function createAdvancer(
    traceback,
    callback,
    resolve,
    reject
)
    return function(...)
        local ok, resultLength, result = runExecutor(traceback, callback, 
...)

        if ok then
            resolve(unpack(result, 1, resultLength))
        else
            reject(result[1])
        end
    end
end
local function isEmpty(t)
    return next(t) == nil
end

local Promise = {
    Error = Error,
    Status = makeEnum('Promise.Status', {
        'Started',
        'Resolved',
        'Rejected',
        'Cancelled',
    }),
    _getTime = os.clock,
    _timeEvent = game:GetService('RunService').Heartbeat,
    _unhandledRejectionCallbacks = {},
}

Promise.prototype = {}
Promise.__index = Promise.prototype

function Promise._new(
    traceback,
    callback,
    parent
)
    if parent ~= nil and not Promise.is(parent) then
        error('Argument #2 to Promise.new must be a promise or nil', 2)
    end

    local self = {
        _thread = nil,
        _source = traceback,
        _status = Promise.Status.Started,
        _values = nil,
        _valuesLength = -1,
        _unhandledRejection = true,
        _queuedResolve = {},
        _queuedReject = {},
        _queuedFinally = {},
        _cancellationHook = nil,
        _parent = parent,
        _consumers = setmetatable({}, MODE_KEY_METATABLE),
    }

    if parent and parent._status == Promise.Status.Started then
        parent._consumers[self] = true
    end

    setmetatable(self, Promise)

    local function resolve(...)
        self:_resolve(...)
    end
    local function reject(...)
        self:_reject(...)
    end
    local function onCancel(cancellationHook)
        if cancellationHook then
            if self._status == Promise.Status.Cancelled then
                cancellationHook()
            else
                self._cancellationHook = cancellationHook
            end
        end

        return self._status == Promise.Status.Cancelled
    end

    self._thread = coroutine.create(function()
        local ok, _, result = runExecutor(self._source, callback, resolve, reject, onCancel)

        if not ok then
            reject(result[1])
        end
    end)

    task.spawn(self._thread)

    return self
end
function Promise.new(executor)
    return Promise._new(debug.traceback(nil, 2), executor)
end
function Promise:__tostring()
    return string.format('Promise(%s)', self._status)
end
function Promise.defer(executor)
    local traceback = debug.traceback(nil, 2)
    local promise

    promise = Promise._new(traceback, function(
        resolve,
        reject,
        onCancel
    )
        local connection

        connection = Promise._timeEvent:Connect(function(
        )
            connection:Disconnect()

            local ok, _, result = runExecutor(traceback, executor, resolve, reject, onCancel)

            if not ok then
                reject(result[1])
            end
        end)
    end)

    return promise
end

Promise.async = Promise.defer

function Promise.resolve(...)
    local length, values = pack(...)

    return Promise._new(debug.traceback(nil, 2), function(
        resolve
    )
        resolve(unpack(values, 1, length))
    end)
end
function Promise.reject(...)
    local length, values = pack(...)

    return Promise._new(debug.traceback(nil, 2), function(
        _,
        reject
    )
        reject(unpack(values, 1, length))
    end)
end
function Promise._try(traceback, callback, ...)
    local valuesLength, values = pack(...)

    return Promise._new(traceback, function(
        resolve
    )
        resolve(callback(unpack(values, 1, valuesLength)))
    end)
end
function Promise.try(callback, ...)
    return Promise._try(debug.traceback(nil, 2), callback, 
...)
end
function Promise._all(
    traceback,
    promises,
    amount
)
    if type(promises) ~= 'table' then
        error(string.format(ERROR_NON_LIST, 'Promise.all'), 3)
    end

    for i, promise in pairs(promises)do
        if not Promise.is(promise) then
            error(string.format(ERROR_NON_PROMISE_IN_LIST, 'Promise.all', tostring(i)), 3)
        end
    end

    if #promises == 0 or amount == 0 then
        return Promise.resolve({})
    end

    return Promise._new(traceback, function(
        resolve,
        reject,
        onCancel
    )
        local resolvedValues = {}
        local newPromises = {}
        local resolvedCount = 0
        local rejectedCount = 0
        local done = false

        local function cancel()
            for _, promise in ipairs(newPromises)do
                promise:cancel()
            end
        end
        local function resolveOne(i, ...)
            if done then
                return
            end

            resolvedCount = resolvedCount + 1

            if amount == nil then
                resolvedValues[i] = ...
            else
                resolvedValues[resolvedCount] = 
...
            end
            if resolvedCount >= (amount or #promises) then
                done = true

                resolve(resolvedValues)
                cancel()
            end
        end

        onCancel(cancel)

        for i, promise in ipairs(promises)do
            newPromises[i] = promise:andThen(function(
                ...
            )
                resolveOne(i, ...)
            end, function(...)
                rejectedCount = rejectedCount + 1

                if amount == nil or #promises - rejectedCount < amount then
                    cancel()

                    done = true

                    reject(...)
                end
            end)
        end

        if done then
            cancel()
        end
    end)
end
function Promise.all(promises)
    return Promise._all(debug.traceback(nil, 2), promises)
end
function Promise.fold(
    list,
    reducer,
    initialValue
)
    assert(type(list) == 'table', 'Bad argument #1 to Promise.fold: must be a table')
    assert(isCallable(reducer), 'Bad argument #2 to Promise.fold: must be a function')

    local accumulator = Promise.resolve(initialValue)

    return Promise.each(list, function(
        resolvedElement,
        i
    )
        accumulator = accumulator:andThen(function(
            previousValueResolved
        )
            return reducer(previousValueResolved, resolvedElement, i)
        end)
    end):andThen(function()
        return accumulator
    end)
end
function Promise.some(promises, count)
    assert(type(count) == 'number', 'Bad argument #2 to Promise.some: must be a number')

    return Promise._all(debug.traceback(nil, 2), promises, count)
end
function Promise.any(promises)
    return Promise._all(debug.traceback(nil, 2), promises, 1):andThen(function(
        values
    )
        return values[1]
    end)
end
function Promise.allSettled(promises)
    if type(promises) ~= 'table' then
        error(string.format(ERROR_NON_LIST, 'Promise.allSettled'), 2)
    end

    for i, promise in pairs(promises)do
        if not Promise.is(promise) then
            error(string.format(ERROR_NON_PROMISE_IN_LIST, 'Promise.allSettled', tostring(i)), 2)
        end
    end

    if #promises == 0 then
        return Promise.resolve({})
    end

    return Promise._new(debug.traceback(nil, 2), function(
        resolve,
        _,
        onCancel
    )
        local fates = {}
        local newPromises = {}
        local finishedCount = 0

        local function resolveOne(i, ...)
            finishedCount = finishedCount + 1
            fates[i] = ...

            if finishedCount >= #promises then
                resolve(fates)
            end
        end

        onCancel(function()
            for _, promise in ipairs(newPromises)do
                promise:cancel()
            end
        end)

        for i, promise in ipairs(promises)do
            newPromises[i] = promise:finally(function(
                ...
            )
                resolveOne(i, ...)
            end)
        end
    end)
end
function Promise.race(promises)
    assert(type(promises) == 'table', string.format(ERROR_NON_LIST, 'Promise.race'))

    for i, promise in pairs(promises)do
        assert(Promise.is(promise), string.format(ERROR_NON_PROMISE_IN_LIST, 'Promise.race', tostring(i)))
    end

    return Promise._new(debug.traceback(nil, 2), function(
        resolve,
        reject,
        onCancel
    )
        local newPromises = {}
        local finished = false

        local function cancel()
            for _, promise in ipairs(newPromises)do
                promise:cancel()
            end
        end
        local function finalize(callback)
            return function(...)
                cancel()

                finished = true

                return callback(...)
            end
        end

        if onCancel(finalize(reject)) then
            return
        end

        for i, promise in ipairs(promises)do
            newPromises[i] = promise:andThen(finalize(resolve), finalize(reject))
        end

        if finished then
            cancel()
        end
    end)
end
function Promise.each(list, predicate)
    assert(type(list) == 'table', string.format(ERROR_NON_LIST, 'Promise.each'))
    assert(isCallable(predicate), string.format(ERROR_NON_FUNCTION, 'Promise.each'))

    return Promise._new(debug.traceback(nil, 2), function(
        resolve,
        reject,
        onCancel
    )
        local results = {}
        local promisesToCancel = {}
        local cancelled = false

        local function cancel()
            for _, promiseToCancel in ipairs(promisesToCancel)do
                promiseToCancel:cancel()
            end
        end

        onCancel(function()
            cancelled = true

            cancel()
        end)

        local preprocessedList = {}

        for index, value in ipairs(list)do
            if Promise.is(value) then
                if value:getStatus() == Promise.Status.Cancelled then
                    cancel()

                    return reject(Error.new({
                        error = 'Promise is cancelled',
                        kind = Error.Kind.AlreadyCancelled,
                        context = string.format(
[[The Promise that was part of the array at index %d passed into Promise.each was already cancelled when Promise.each began.

That Promise was created at:

%s]], index, value._source),
                    }))
                elseif value:getStatus() == Promise.Status.Rejected then
                    cancel()

                    return reject(select(2, value:await()))
                end

                local ourPromise = value:andThen(function(
                    ...
                )
                    return ...
                end)

                table.insert(promisesToCancel, ourPromise)

                preprocessedList[index] = ourPromise
            else
                preprocessedList[index] = value
            end
        end
        for index, value in ipairs(preprocessedList)do
            if Promise.is(value) then
                local success

                success, value = value:await()

                if not success then
                    cancel()

                    return reject(value)
                end
            end
            if cancelled then
                return
            end

            local predicatePromise = Promise.resolve(predicate(value, index))

            table.insert(promisesToCancel, predicatePromise)

            local success, result = predicatePromise:await()

            if not success then
                cancel()

                return reject(result)
            end

            results[index] = result
        end

        resolve(results)
    end)
end
function Promise.is(object)
    if type(object) ~= 'table' then
        return false
    end

    local objectMetatable = getmetatable(object)

    if objectMetatable == Promise then
        return true
    elseif objectMetatable == nil then
        return isCallable(object.andThen)
    elseif type(objectMetatable) == 'table' and type(rawget(objectMetatable, '__index')) == 'table' and isCallable(rawget(rawget(objectMetatable, '__index'), 'andThen')) then
        return true
    end

    return false
end
function Promise.promisify(callback)
    return function(...)
        return Promise._try(debug.traceback(nil, 2), callback, 
...)
    end
end

do
    local first
    local connection

    function Promise.delay(seconds)
        assert(type(seconds) == 'number', 'Bad argument #1 to Promise.delay, must be a number.')

        if not (seconds >= 1 / 60) or seconds == math.huge then
            seconds = 1 / 60
        end

        return Promise._new(debug.traceback(nil, 2), function(
            resolve,
            _,
            onCancel
        )
            local startTime = Promise._getTime()
            local endTime = startTime + seconds
            local node = {
                resolve = resolve,
                startTime = startTime,
                endTime = endTime,
            }

            if connection == nil then
                first = node
                connection = Promise._timeEvent:Connect(function(
                )
                    local threadStart = Promise._getTime()

                    while first ~= nil and first.endTime < threadStart do
                        local current = first

                        first = current.next

                        if first == nil then
                            connection:Disconnect()

                            connection = nil
                        else
                            first.previous = nil
                        end

                        current.resolve(Promise._getTime() - current.startTime)
                    end
                end)
            else
                if first.endTime < endTime then
                    local current = first
                    local next = current.next

                    while next ~= nil and next.endTime < endTime do
                        current = next
                        next = current.next
                    end

                    current.next = node
                    node.previous = current

                    if next ~= nil then
                        node.next = next
                        next.previous = node
                    end
                else
                    node.next = first
                    first.previous = node
                    first = node
                end
            end

            onCancel(function()
                local next = node.next

                if first == node then
                    if next == nil then
                        connection:Disconnect()

                        connection = nil
                    else
                        next.previous = nil
                    end

                    first = next
                else
                    local previous = node.previous

                    previous.next = next

                    if next ~= nil then
                        next.previous = previous
                    end
                end
            end)
        end)
    end
end

function Promise.prototype:timeout(
    seconds,
    rejectionValue
)
    local traceback = debug.traceback(nil, 2)

    return Promise.race({
        Promise.delay(seconds):andThen(function()
            return Promise.reject(rejectionValue == nil and Error.new({
                kind = Error.Kind.TimedOut,
                error = 'Timed out',
                context = string.format('Timeout of %d seconds exceeded.\n:timeout() called at:\n\n%s', seconds, traceback),
            }) or rejectionValue)
        end),
        self,
    })
end
function Promise.prototype:getStatus()
    return self._status
end
function Promise.prototype:_andThen(
    traceback,
    successHandler,
    failureHandler
)
    self._unhandledRejection = false

    if self._status == Promise.Status.Cancelled then
        local promise = Promise.new(function() end)

        promise:cancel()

        return promise
    end

    return Promise._new(traceback, function(
        resolve,
        reject,
        onCancel
    )
        local successCallback = resolve

        if successHandler then
            successCallback = createAdvancer(traceback, successHandler, resolve, reject)
        end

        local failureCallback = reject

        if failureHandler then
            failureCallback = createAdvancer(traceback, failureHandler, resolve, reject)
        end
        if self._status == Promise.Status.Started then
            table.insert(self._queuedResolve, successCallback)
            table.insert(self._queuedReject, failureCallback)
            onCancel(function()
                if self._status == Promise.Status.Started then
                    table.remove(self._queuedResolve, table.find(self._queuedResolve, successCallback))
                    table.remove(self._queuedReject, table.find(self._queuedReject, failureCallback))
                end
            end)
        elseif self._status == Promise.Status.Resolved then
            successCallback(unpack(self._values, 1, self._valuesLength))
        elseif self._status == Promise.Status.Rejected then
            failureCallback(unpack(self._values, 1, self._valuesLength))
        end
    end, self)
end
function Promise.prototype:andThen(
    successHandler,
    failureHandler
)
    assert(successHandler == nil or isCallable(successHandler), string.format(ERROR_NON_FUNCTION, 'Promise:andThen'))
    assert(failureHandler == nil or isCallable(failureHandler), string.format(ERROR_NON_FUNCTION, 'Promise:andThen'))

    return self:_andThen(debug.traceback(nil, 2), successHandler, failureHandler)
end
function Promise.prototype:catch(failureHandler)
    assert(failureHandler == nil or isCallable(failureHandler), string.format(ERROR_NON_FUNCTION, 'Promise:catch'))

    return self:_andThen(debug.traceback(nil, 2), nil, failureHandler)
end
function Promise.prototype:tap(tapHandler)
    assert(isCallable(tapHandler), string.format(ERROR_NON_FUNCTION, 'Promise:tap'))

    return self:_andThen(debug.traceback(nil, 2), function(
        ...
    )
        local callbackReturn = tapHandler(...)

        if Promise.is(callbackReturn) then
            local length, values = pack(...)

            return callbackReturn:andThen(function(
            )
                return unpack(values, 1, length)
            end)
        end

        return ...
    end)
end
function Promise.prototype:andThenCall(
    callback,
    ...
)
    assert(isCallable(callback), string.format(ERROR_NON_FUNCTION, 'Promise:andThenCall'))

    local length, values = pack(...)

    return self:_andThen(debug.traceback(nil, 2), function(
    )
        return callback(unpack(values, 1, length))
    end)
end
function Promise.prototype:andThenReturn(...)
    local length, values = pack(...)

    return self:_andThen(debug.traceback(nil, 2), function(
    )
        return unpack(values, 1, length)
    end)
end
function Promise.prototype:cancel()
    if self._status ~= Promise.Status.Started then
        return
    end

    self._status = Promise.Status.Cancelled

    if self._cancellationHook then
        self._cancellationHook()
    end

    coroutine.close(self._thread)

    if self._parent then
        self._parent:_consumerCancelled(self)
    end

    for child in pairs(self._consumers)do
        child:cancel()
    end

    self:_finalize()
end
function Promise.prototype:_consumerCancelled(
    consumer
)
    if self._status ~= Promise.Status.Started then
        return
    end

    self._consumers[consumer] = nil

    if next(self._consumers) == nil then
        self:cancel()
    end
end
function Promise.prototype:_finally(
    traceback,
    finallyHandler
)
    self._unhandledRejection = false

    local promise = Promise._new(traceback, function(
        resolve,
        reject,
        onCancel
    )
        local handlerPromise

        onCancel(function()
            self:_consumerCancelled(self)

            if handlerPromise then
                handlerPromise:cancel()
            end
        end)

        local finallyCallback = resolve

        if finallyHandler then
            finallyCallback = function(...)
                local callbackReturn = finallyHandler(
...)

                if Promise.is(callbackReturn) then
                    handlerPromise = callbackReturn

                    callbackReturn:finally(function(
                        status
                    )
                        if status ~= Promise.Status.Rejected then
                            resolve(self)
                        end
                    end):catch(function(...)
                        reject(...)
                    end)
                else
                    resolve(self)
                end
            end
        end
        if self._status == Promise.Status.Started then
            table.insert(self._queuedFinally, finallyCallback)
        else
            finallyCallback(self._status)
        end
    end)

    return promise
end
function Promise.prototype:finally(
    finallyHandler
)
    assert(finallyHandler == nil or isCallable(finallyHandler), string.format(ERROR_NON_FUNCTION, 'Promise:finally'))

    return self:_finally(debug.traceback(nil, 2), finallyHandler)
end
function Promise.prototype:finallyCall(
    callback,
    ...
)
    assert(isCallable(callback), string.format(ERROR_NON_FUNCTION, 'Promise:finallyCall'))

    local length, values = pack(...)

    return self:_finally(debug.traceback(nil, 2), function(
    )
        return callback(unpack(values, 1, length))
    end)
end
function Promise.prototype:finallyReturn(...)
    local length, values = pack(...)

    return self:_finally(debug.traceback(nil, 2), function(
    )
        return unpack(values, 1, length)
    end)
end
function Promise.prototype:awaitStatus()
    self._unhandledRejection = false

    if self._status == Promise.Status.Started then
        local thread = coroutine.running()

        self:finally(function()
            task.spawn(thread)
        end):catch(function() end)
        coroutine.yield()
    end
    if self._status == Promise.Status.Resolved then
        return self._status, unpack(self._values, 1, self._valuesLength)
    elseif self._status == Promise.Status.Rejected then
        return self._status, unpack(self._values, 1, self._valuesLength)
    end

    return self._status
end

local function awaitHelper(status, ...)
    return status == Promise.Status.Resolved, ...
end

function Promise.prototype:await()
    return awaitHelper(self:awaitStatus())
end

local function expectHelper(status, ...)
    if status ~= Promise.Status.Resolved then
        error((...) == nil and 'Expected Promise rejected with no value.' or (
...), 3)
    end

    return ...
end

function Promise.prototype:expect()
    return expectHelper(self:awaitStatus())
end

Promise.prototype.awaitValue = Promise.prototype.expect

function Promise.prototype:_unwrap()
    if self._status == Promise.Status.Started then
        error('Promise has not resolved or rejected.', 2)
    end

    local success = self._status == Promise.Status.Resolved

    return success, unpack(self._values, 1, self._valuesLength)
end
function Promise.prototype:_resolve(...)
    if self._status ~= Promise.Status.Started then
        if Promise.is((...)) then
            (...):_consumerCancelled(self)
        end

        return
    end
    if Promise.is((...)) then
        if select('#', ...) > 1 then
            local message = string.format('When returning a Promise from andThen, extra arguments are ' .. 'discarded! See:\n\n%s', self._source)

            warn(message)
        end

        local chainedPromise = ...
        local promise = chainedPromise:andThen(function(
            ...
        )
            self:_resolve(...)
        end, function(...)
            local maybeRuntimeError = chainedPromise._values[1]

            if chainedPromise._error then
                maybeRuntimeError = Error.new({
                    error = chainedPromise._error,
                    kind = Error.Kind.ExecutionError,
                    context = 
[=[[No stack trace available as this Promise originated from an older version of the Promise library (< v2)]]=],
                })
            end
            if Error.isKind(maybeRuntimeError, Error.Kind.ExecutionError) then
                return self:_reject(maybeRuntimeError:extend({
                    error = 'This Promise was chained to a Promise that errored.',
                    trace = '',
                    context = string.format(
[[The Promise at:

%s
...Rejected because it was chained to the following Promise, which encountered an error:
]], self._source),
                }))
            end

            self:_reject(...)
        end)

        if promise._status == Promise.Status.Cancelled then
            self:cancel()
        elseif promise._status == Promise.Status.Started then
            self._parent = promise
            promise._consumers[self] = true
        end

        return
    end

    self._status = Promise.Status.Resolved
    self._valuesLength, self._values = pack(...)

    for _, callback in ipairs(self._queuedResolve)do
        coroutine.wrap(callback)(...)
    end

    self:_finalize()
end
function Promise.prototype:_reject(...)
    if self._status ~= Promise.Status.Started then
        return
    end

    self._status = Promise.Status.Rejected
    self._valuesLength, self._values = pack(...)

    if not isEmpty(self._queuedReject) then
        for _, callback in ipairs(self._queuedReject)do
            coroutine.wrap(callback)(...)
        end
    else
        local err = tostring((...))

        coroutine.wrap(function()
            Promise._timeEvent:Wait()

            if not self._unhandledRejection then
                return
            end

            local message = string.format('Unhandled Promise rejection:\n\n%s\n\n%s', err, self._source)

            for _, callback in ipairs(Promise._unhandledRejectionCallbacks)do
                task.spawn(callback, self, unpack(self._values, 1, self._valuesLength))
            end

            if Promise.TEST then
                return
            end

            warn(message)
        end)()
    end

    self:_finalize()
end
function Promise.prototype:_finalize()
    for _, callback in ipairs(self._queuedFinally)do
        coroutine.wrap(callback)(self._status)
    end

    self._queuedFinally = nil
    self._queuedReject = nil
    self._queuedResolve = nil

    if not Promise.TEST then
        self._parent = nil
        self._consumers = nil
    end

    task.defer(coroutine.close, self._thread)
end
function Promise.prototype:now(rejectionValue)
    local traceback = debug.traceback(nil, 2)

    if self._status == Promise.Status.Resolved then
        return self:_andThen(traceback, function(
            ...
        )
            return ...
        end)
    else
        return Promise.reject(rejectionValue == nil and Error.new({
            kind = Error.Kind.NotResolvedInTime,
            error = 'This Promise was not resolved in time for :now()',
            context = ':now() was called at:\n\n' .. traceback,
        }) or rejectionValue)
    end
end
function Promise.retry(callback, times, ...)
    assert(isCallable(callback), 'Parameter #1 to Promise.retry must be a function')
    assert(type(times) == 'number', 'Parameter #2 to Promise.retry must be a number')

    local args, length = {...}, select('#', ...)

    return Promise.resolve(callback(...)):catch(function(
        ...
    )
        if times > 0 then
            return Promise.retry(callback, times - 1, unpack(args, 1, length))
        else
            return Promise.reject(...)
        end
    end)
end
function Promise.retryWithDelay(
    callback,
    times,
    seconds,
    ...
)
    assert(isCallable(callback), 'Parameter #1 to Promise.retry must be a function')
    assert(type(times) == 'number', 'Parameter #2 (times) to Promise.retry must be a number')
    assert(type(seconds) == 'number', 'Parameter #3 (seconds) to Promise.retry must be a number')

    local args, length = {...}, select('#', ...)

    return Promise.resolve(callback(...)):catch(function(
        ...
    )
        if times > 0 then
            Promise.delay(seconds):await()

            return Promise.retryWithDelay(callback, times - 1, seconds, unpack(args, 1, length))
        else
            return Promise.reject(...)
        end
    end)
end
function Promise.fromEvent(event, predicate)
    predicate = predicate or function()
        return true
    end

    return Promise._new(debug.traceback(nil, 2), function(
        resolve,
        _,
        onCancel
    )
        local connection
        local shouldDisconnect = false

        local function disconnect()
            connection:Disconnect()

            connection = nil
        end

        connection = event:Connect(function(...)
            local callbackValue = predicate(...)

            if callbackValue == true then
                resolve(...)

                if connection then
                    disconnect()
                else
                    shouldDisconnect = true
                end
            elseif type(callbackValue) ~= 'boolean' then
                error('Promise.fromEvent predicate should always return a boolean')
            end
        end)

        if shouldDisconnect and connection then
            return disconnect()
        end

        onCancel(disconnect)
    end)
end
function Promise.onUnhandledRejection(callback)
    table.insert(Promise._unhandledRejectionCallbacks, callback)

    return function()
        local index = table.find(Promise._unhandledRejectionCallbacks, callback)

        if index then
            table.remove(Promise._unhandledRejectionCallbacks, index)
        end
    end
end

return Promise
end function __TAD__.a()local v=__TAD__.cache.a if not v then v={c=__modImpl()}__TAD__.cache.a=v end return v.c end end do local function __modImpl()
return __TAD__.a()
end function __TAD__.b()local v=__TAD__.cache.b if not v then v={c=__modImpl()}__TAD__.cache.b=v end return v.c end end do local function __modImpl()local Maid = {}

Maid.ClassName = 'Maid'



function Maid.new()    
return (setmetatable({_tasks = {}}, Maid))
end
function Maid.isMaid(value)    
return type(value) == 'table' and value.ClassName == 'Maid'
end
function Maid.__index(
    self,
    index
)
    if Maid[index] then
        return Maid[index]
    else
        return self._tasks[index]
    end
end
function Maid.__newindex(
    self,
    index,
    newTask
)
    if Maid[index] ~= nil then
        error(string.format("Cannot use '%s' as a Maid key", tostring(index)), 2)
    end

    local tasks = self._tasks
    local job = tasks[index]

    if job == newTask then
        return
    end

    tasks[index] = newTask

    if job then
        if typeof(job) == 'function' then
            (job)()
        elseif typeof(job) == 'table' then
            local destructable= job

            if type(destructable.Destroy) == 'function' then
                destructable:Destroy()
            elseif type(destructable.destroy) == 'function' then
                destructable:destroy()
            end
        elseif typeof(job) == 'Instance' then
            job:Destroy()
        elseif typeof(job) == 'thread' then
            local cancelled

            if coroutine.running() ~= job then
                cancelled = pcall(function()
                    task.cancel(job)
                end)
            end
            if not cancelled then
                task.defer(function()
                    task.cancel(job)
                end)
            end
        elseif typeof(job) == 'RBXScriptConnection' then
            job:Disconnect()
        end
    end
end
function Maid.Add(
    self,
    task
)    
if not task then
        error('Task cannot be false or nil', 2)
    end

    self[#((self._tasks)) + 1] = task
    
if type(task) == 'table' and (not (task).Destroy and not (task).destroy) then
        warn('[Maid.Add] - Gave table task without .destroy/.Destroy\n\n' .. debug.traceback())
    end

    return task
end
function Maid.GiveTask(
    self,
    task
)    
if not task then
        error('Task cannot be false or nil', 2)
    end

    local taskId = #((self._tasks)) + 1

    self[taskId] = task

    if type(task) == 'table' and (not (task).Destroy and not (task).destroy) then
        warn(
[[[Maid.GiveTask] - Gave table task without .destroy/.Destroy

]] .. debug.traceback())
    end

    return taskId
end
function Maid.GivePromise(
    self,
    promise
)    
if not promise:IsPending() then
        return promise
    end

    local newPromise = promise.resolved(promise)
    local id = self:GiveTask(newPromise)

    newPromise:Finally(function()
        self[id] = nil
    end)

    return newPromise
end
function Maid.DoCleaning(self)
    local tasks = self._tasks

    for index, job in tasks do
        if typeof(job) == 'RBXScriptConnection' then
            tasks[index] = nil

            job:Disconnect()
        end
    end

    local index, job = next(tasks)

    while job ~= nil do
        tasks[index] = nil

        if typeof(job) == 'function' then
            (job)()
        elseif typeof(job) == 'table' then
            if type((job).Destroy) == 'function' then
                (job):Destroy()
            elseif type((job).destroy) == 'function' then
                (job):destroy()
            end
        elseif typeof(job) == 'Instance' then
            job:Destroy()
        elseif typeof(job) == 'thread' then
            local cancelled

            if coroutine.running() ~= job then
                cancelled = pcall(function()
                    task.cancel(job)
                end)
            end
            if not cancelled then
                local toCancel = job

                task.defer(function()
                    task.cancel(toCancel)
                end)
            end
        elseif typeof(job) == 'RBXScriptConnection' then
            job:Disconnect()
        end

        index, job = next(tasks)
    end
end
function Maid.FullClean(self)
    self:DoCleaning()
    setmetatable(self, nil)
end

Maid.Destroy = Maid.DoCleaning

return Maid
end function __TAD__.c()local v=__TAD__.cache.c if not v then v={c=__modImpl()}__TAD__.cache.c=v end return v.c end end do local function __modImpl()
return __TAD__.c()
end function __TAD__.d()local v=__TAD__.cache.d if not v then v={c=__modImpl()}__TAD__.cache.d=v end return v.c end end do local function __modImpl()
local Cloud = {}
Cloud.__index = Cloud

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

local Promise = __TAD__.b()
local Maid = __TAD__.d()


local function assertw(condition, message)
    if not condition then
        warn(message)
        return true
    end
end

function Cloud.new(CloudTool, keepActive)
    local self = setmetatable({}, Cloud)
    self._tool = CloudTool
	self._maid = Maid.new()
	self._keepActive = keepActive == nil and true or keepActive
    self:Init()
    return self
end

function Cloud:Init()
	local Character = LocalPlayer.Character
	local Backpack = LocalPlayer.Backpack



	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    local Tool = self._tool
    if Tool.Parent == nil then
        warn("Cloud tool is not attached to a player")
        return
    end
    if Tool.Parent == Backpack and self._keepActive then
        Tool.Parent = Character
    end
    self._control = Tool:WaitForChild("ServerControl", 5)
    if assertw(self._control, "Cloud tool does not have a ServerControl") then return end
    if assertw(self._control:IsA("RemoteFunction"), "ServerControl is not a RemoteFunction") then return end
    if assertw(Tool:FindFirstChild("Handle") and Tool.Handle:IsA("Part"), "Tool's Handle is Invalid") then return end
    
    if Tool.Parent == Character and not (Tool.Handle:FindFirstChildOfClass("SpecialMesh") and Tool.Handle:FindFirstChildOfClass("SpecialMesh").MeshId == "rbxassetid://0") then
        self:SetProperties(Tool.Handle:FindFirstChildOfClass("SpecialMesh"), {
            MeshId = "rbxassetid://0"
        }):andThen(function()
            for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do track:Stop() end
        end)
    end
    Tool.Name = "Homebrew_Cloud"
    if self._keepActive then
	    self._maid:GiveTask(Tool:GetPropertyChangedSignal("Parent"):Connect(function()
	        task.defer(function()
		        if Tool.Parent == Backpack and Humanoid.Health > 0 then
		           Tool.Parent = Character 
		        end
		    end)
		end))
	end
	
	self._maid:GiveTask(function()
		Tool.Parent = Character
		if Tool.Parent ~= nil then
			self:SetProperties(Tool, {Parent = game.TestService})
		end
	end)

end

function Cloud:SetProperties(object, propertyTable)
	local Character = LocalPlayer.Character
	local Backpack = LocalPlayer.Backpack



	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    return Promise.new(function(res, rej)
        if not object:IsDescendantOf(Character) then rej("Object is not a descendant of the character") end
        local Parent = propertyTable.Parent or object.Parent
        propertyTable.Parent = nil
        local bools = {}
        for k, v in pairs(propertyTable) do
            task.defer(function()
                bools[k] = false
                self._control: InvokeServer("SetProperty", {
                    Value = v,
                    Property = k,
                    Object = object
                })
                bools[k] = true
            end)
        end
        local timer = 0
        while true do
            local dt = game.RunService.Heartbeat:Wait()
            timer = timer + dt
            if timer > 5 then
                rej("Timed out")
                break
            end
            local a = true
            for k, v in pairs(bools) do
                if not v then a = false end
            end
            if a then
                self._control:InvokeServer("SetProperty", {
                    Value = Parent,
                    Property = "Parent",
                    Object = object
                })
                res(object)
                break
            end
        end
	end):catch(function(reason)
		if reason ~= "Timed out" then
			error(reason)	
		end
	end)
end

function Cloud:EffectCloud()
    return Promise.new(function(res, rej)
        self._control:InvokeServer("Fly", {Flying = true})
        local EffectCloud = self._tool:WaitForChild("EffectCloud")
		
		task.defer(res, EffectCloud, function() self._control:InvokeServer("Fly", {Flying = false}) end)
    end)
end

function Cloud:Destroy()
    self._maid:Destroy()
end

return Cloud end function __TAD__.e()local v=__TAD__.cache.e if not v then v={c=__modImpl()}__TAD__.cache.e=v end return v.c end end do local function __modImpl()local Promise = __TAD__.b()

local Cloud = __TAD__.e()

local BAGH = {}

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

function BAGH:GetCloud(forceNew, keepActive)
    return Promise.new(function(res, rej)
        local Character = LocalPlayer.Character
        local Backpack = LocalPlayer.Backpack
        if not forceNew and Backpack:FindFirstChild("Homebrew_Cloud") then
			res(Cloud.new(Backpack.Homebrew_Cloud, keepActive))
			return
        end
		if Character:FindFirstChild("Homebrew_Cloud") and not forceNew then
			res(Cloud.new(Character.Homebrew_Cloud, keepActive))
			return
        end
		self:GetTool("PompousTheCloud"):andThen(function(tool) local c = Cloud.new(tool, keepActive); task.wait(1) res(c) end):catch(rej)
    end)
end

function BAGH:GetHead()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer.Backpack
	return Promise.new(function(res, rej)
		local con; con = Character.ChildAdded:Connect(function(t)
			if t:IsA("Model") then
				con:Disconnect()
				con = nil
				res(t)
			end
		end)
		
        workspace.GuiEvent:FireServer("Hvmebrew")
		task.wait(5)
		if con ~= nil then
			con:Disconnect()
			rej()
		end
    end)
end

function BAGH:GetTool(Name)
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer.Backpack
    return Promise.new(function(res, rej)
        workspace.Buy:FireServer(0, Name)
        local c
        c = Backpack.ChildAdded:Connect(function(child)
            if child.Name == Name then
                c:Disconnect()
                task.delay(0.2, function()
                    res(child)
                end)
            end
        end)
    end)
end

return BAGH end function __TAD__.f()local v=__TAD__.cache.f if not v then v={c=__modImpl()}__TAD__.cache.f=v end return v.c end end do local function __modImpl()
	
local _ = {
		Part = {
			"Shape", "FormFactor", "Anchored",
			"BackSurface",
			"BottomSurface",
			"CFrame", "CanCollide",
			"CastShadow", "Color",
			"FrontSurface",
			"LeftSurface",
			"Massless", "Material",
			"Orientation",
			"Reflectance", "RightSurface",
			"Size", "TopSurface",
			"Transparency",
			"Name"
		},
		Decal = {
			"Color3",
			"LocalTransparencyModifier", "Rotation", "Shiny", "Specular",
			"Texture", "Transparency", "UVOffset", "UVScale",
			"ZIndex", "Face", "Name"
		},
		SpecialMesh = {
			"MeshType", "MeshId", "TextureId", "Offset", "Scale", "VertexColor","Name",
		},
		Weld = {
			"C0", "C1", "Enabled", "Part0", "Part1", "Name"
		}
	};
	return _ end function __TAD__.g()local v=__TAD__.cache.g if not v then v={c=__modImpl()}__TAD__.cache.g=v end return v.c end end do local function __modImpl()

local Promise = __TAD__.b()
local BAGH = __TAD__.f()
local PropertyDict = __TAD__.g()

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

local ModelImporter = {}

function buildPropertyDictionary(i1, i2)
	local pDict = PropertyDict[i1.ClassName]
	if pDict == nil then
		warn(i1.ClassName.." is not supported")
		return false
	end
	
	local Properties = {}
	for _, Property in ipairs(pDict) do
		if i1[Property] ~= i2[Property] then
			Properties[Property] = i2[Property]
		end
	end
	
	return Properties
	
end


function ModelImporter:ImportModel(Provider, Model, Cloud, Parent, options)
	local Character = LocalPlayer.Character
	options = options or {}
	
	local useDefer = options.useDefer or false
	local batchSize = options.batchSize or 100
	local batchSleep = options.batchSleep or 0
	
    return Promise.new(function(res, rej)
        if not Model then
            rej("Could not import model")
            return
        end
        local numParts = 0
        for _, part in pairs(Model:GetDescendants()) do
            if part:IsA("Part") then
                numParts = numParts + 1
            end
		end
		


        
		local _, parts = Provider:RequestInstances("Part", numParts):await()
		local m = Model:Clone()
		Model:Destroy()
		Model = m
		
		
		local count = 0
		local Assigns = {}
		for _, part in pairs(Model:GetDescendants()) do
			if part:IsA("Part") then
				count = count + 1
				


				local Properties = buildPropertyDictionary(parts[count], part)
				if Properties == false then
					count -= 1
					continue
				end

				local hasAfter = false
				for _, v in ipairs(part:GetChildren()) do
					if Provider:GetHeap(v.ClassName) then
						hasAfter = true
						break
					end
				end
				
				local peePee = parts[count]
				
				local After = function()
					local ps = {}
					for _, v in ipairs(part:GetChildren()) do
						if Provider:GetHeap(v.ClassName) then
							
							local _, ins = Provider:RequestInstance(v.ClassName):await()
							local Properties = buildPropertyDictionary(ins, v)
							
							if Properties == false then
								continue
							end
							
							Properties.Parent = nil
							local p = Cloud:SetProperties(ins, Properties):andThen(function()
								Cloud:SetProperties(ins, {
									Parent = peePee
								})
							end)
							table.insert(ps, p)
						end
					end
					return Promise.all(ps)
				end
			
				Properties.Parent = Parent
				table.insert(Assigns, {part, parts[count], Properties, hasAfter and After or nil})
				
			end
		end
		
		print(count)
		
		local centre = Model:GetBoundingBox()
		
		-- sort assigns by distance to model pivot and size of part
		table.sort(Assigns, function(a, b)
			local A, B = a[1], b[1]
			
			local distA = (A.Position - centre.p).Magnitude
			local distB = (B.Position - centre.p).Magnitude
			
			local sizeA = A.Size.X * A.Size.Y * A.Size.Z
			local sizeB = B.Size.X * B.Size.Y * B.Size.Z
			
			return (distA - sizeA) > (distB - sizeB)
		end)
		
		local spawner = useDefer and task.defer or task.spawn
		
		local ctr = 0
		
		
		local Promises = {}
		repeat
			
			local _, p, prop, after = unpack(table.remove(Assigns))
			local r = Cloud:SetProperties(p, prop):andThen(function()
				if after ~= nil and typeof(after) == "function" then
					after():await()
				end
			end)
			table.insert(Promises, r)
			ctr = ctr + 1
			if useDefer and ctr % batchSize == 0 then
				Promise.all(Promises):await()
				Promises = {}
				task.wait(batchSleep)
			end
		until #Assigns == 0 
        repeat task.wait() until #Promises == ctr
		Promise.all(Promises):andThen(function()
			res(Parent)
		end, rej)
    end)
end

function ModelImporter:CloneProperties(Instance1, Instance2)
    return Promise.new(function(res, rej)
        if Instance1.ClassName ~= Instance2.ClassName then
            rej()
        end
        print(Instance1.ClassName)
        local Properties = PropertyDict[Instance1.ClassName]
        local Props = {}
        for _, Property in pairs(Properties) do
            local Value = Instance1[Property]
            if Value then
                Props[Property] = Value
            end
        end
        self._cloud:SetProperties(Instance2, Props):andThen(function() res() end):catch(rej)
    end)
end

function ModelImporter:CreateParts(Cloud, Num)
	
end

function ModelImporter:CreatePart(P1, Part, Parent, Flag)
	return Promise.new(function(res, rej)
		if (PropertyDict[Part.ClassName] == nil) then
			rej(warn("Class not supported", Part.ClassName))
		end
		
        local Properties = {}
        for _, Property in ipairs(PropertyDict[Part.ClassName]) do
            Properties[Property] = Part[Property]
        end
        Properties.Parent = Parent



        self._cloud:SetProperties(P1, Properties)
    end)
end

return ModelImporter end function __TAD__.h()local v=__TAD__.cache.h if not v then v={c=__modImpl()}__TAD__.cache.h=v end return v.c end end do local function __modImpl()--[=[
    @class InstanceHeap
]=]

local InstanceHeap = {}
InstanceHeap.__index = InstanceHeap

local Promise = __TAD__.b()

--[=[
    @within InstanceHeap
    @function new
    @param F3X F3X
    @param BaseInstances {T}
    @param Parent Instance

    @return InstanceHeap<{T}>
]=]
function InstanceHeap.new(Cloud, BaseInstance, Model, Name)
	local self = setmetatable({
		_cloud = Cloud,
		_heap = {},
		_model = Model,
		Name = Name or BaseInstance.ClassName,
	}, InstanceHeap)



	self._heap = { 
		Instances = { BaseInstance }, 
		DesiredAmount = 1,
		FulfillingRequest = false 
	}
	
	Cloud:SetProperties(BaseInstance, {Parent = Model})
	Cloud:SetProperties(Model, {Name = self.Name.."Heap", Parent = Cloud._tool.Handle}):await()

	return self
end
--[=[
    @within InstanceHeap
    @method SetDesiredAmount
    @param ClassName string
    @param Amount amount
]=]
function InstanceHeap:SetDesiredAmount(Amount)
	local Heap = self._heap

	Heap.DesiredAmount = Amount
	self:_updateAmount()
end

function InstanceHeap:GetDesiredAmount()
	return self._heap.DesiredAmount
end

function InstanceHeap:_doubleIt()
	return self._cloud:EffectCloud():andThen(function(e)
		local ps = {}
		local is = {}
		for _,v in ipairs(e:WaitForChild(self._model.Name):GetChildren()) do
			local p = self._cloud:SetProperties(v, {Parent = self._model})
			table.insert(ps, p)
			table.insert(is, v)
		end
		Promise.all(ps):await()
		return is
	end)
end

function InstanceHeap:_updateAmount()
	local Heap = self._heap

	if Heap.FulfillingRequest then
		repeat task.wait() until Heap.FulfillingRequest == false
	end

	Heap.FulfillingRequest = true

	local cloud = self._cloud
	local Instances = Heap.Instances
	local amt = Heap.DesiredAmount + 1
	if not (#Instances >= amt) then
		if #Instances < amt / 2  then
			repeat
				local _,clones = self:_doubleIt():await()
				for _, v in ipairs(clones) do table.insert(Instances, v) end
			until #Instances >= amt
		end
	end
	Heap.FulfillingRequest = false
	print("Succesfully refilled heap for "..self.Name.." to "..#Instances)
end


--[=[
    @within InstanceHeap
    @method RequestInstances
    @param ClassName string
    @param Amount number
    @param Refill boolean

    @return Promise<{T}, Promise>
]=]
function InstanceHeap:RequestInstances(Amount, Refill)
	return Promise.new(function(res, rej)
		local Heap = self._heap
		if Heap.FulfillingRequest then
			repeat task.wait() until Heap.FulfillingRequest == false
		end

		if not self:CanFulfill(Amount) then
			rej("Not enough instances in heap.")
			return
		end

		local Instances = {}
		for _ = 1, Amount do 
			local i = table.remove(Heap.Instances)
			self._cloud:SetProperties(i, {Parent = self._cloud._tool.Script})
			table.insert(Instances, i) 
		end
		local onRefill
		if Refill then onRefill = Promise.new(function(res) self:_updateAmount() res() end) end
		res(Instances, onRefill)
	end)
end

function InstanceHeap:CanFulfill(Amount)
	local Heap = self._heap
	if Heap.FulfillingRequest then
		repeat task.wait() until Heap.FulfillingRequest == false
	end
	
	return not (Amount > #Heap.Instances - 1)
end


--[=[
    @within InstanceHeap
    @method Destroy
]=]
function InstanceHeap:Destroy()
	--local heaps = self._heap
	--local toRemove = {}
	--for _,heap in ipairs(heaps) do
	--	for _ = 1, #heap.Instances do table.insert(toRemove, table.remove(heap.Instances)) end
	--end
	self._cloud:Destroy()
end

return InstanceHeap
end function __TAD__.i()local v=__TAD__.cache.i if not v then v={c=__modImpl()}__TAD__.cache.i=v end return v.c end end do local function __modImpl()
local Promise = __TAD__.b()
local InstanceHeap = __TAD__.i()

local InstanceProvider = {}
InstanceProvider.__index = InstanceProvider

function InstanceProvider.new(Heaps)
	local self = setmetatable({
		_heaps = {}
	}, InstanceProvider)
	
	for k, Heap in pairs(Heaps) do
		local index = Heap.Name
		if typeof(k) == "string" then
			index = k
		end
		
		self._heaps[index] = Heap
	end
	
	return self
end


function InstanceProvider:AddHeap(Heap, Name)
	self._heaps[Name or Heap.Name] = Heap
end

function InstanceProvider:RequestInstances(Name, Amount)
	return Promise.new(function(res, rej)
		local Heap = self:GetHeap(Name)
		if not Heap then
			rej("Heap "..Name.." does not exist")
		end
		
		if not Heap:CanFulfill(Amount) then
			Heap:SetDesiredAmount(Heap:GetDesiredAmount() * 2)
			
			print("Increasing capacity of heap "..Name)
			
			self:RequestInstances(Name, Amount):andThen(res, rej)
			return
		end
		
		Heap:RequestInstances(Amount, true):andThen(res, rej)
	end)
end

function InstanceProvider:RequestInstance(Name)
	return self:RequestInstances(Name, 1):andThen(function(Instances)
		return Instances[1]
	end)
end

function InstanceProvider:GetHeap(Name)
	return self._heaps[Name]
end

return InstanceProvider end function __TAD__.j()local v=__TAD__.cache.j if not v then v={c=__modImpl()}__TAD__.cache.j=v end return v.c end end do local function __modImpl()
local BAGH = __TAD__.f()
local Cloud = __TAD__.e()
local ModelImporter = __TAD__.h()
local InstanceHeap = __TAD__.i()
local InstanceProvider = __TAD__.j()
local Maid = __TAD__.d()
local Promise = __TAD__.b()
local Properties = __TAD__.g()

return setmetatable({
        Cloud=Cloud,
        ModelImporter=ModelImporter,
        InstanceHeap=InstanceHeap,
        InstanceProvider=InstanceProvider,
        Maid=Maid,
        Promise=Promise,
        Properties=Properties
    }, {
    __index = function(self, key)
        return BAGH[key]
    end
})end function __TAD__.k()local v=__TAD__.cache.k if not v then v={c=__modImpl()}__TAD__.cache.k=v end return v.c end end do local function __modImpl()
local BAGH = __TAD__.k()

local Promise = __TAD__.b()

local LocalPlayer = game.Players.LocalPlayer

local function clone(instance, parent)
    local originalParent = instance.Parent
    return Promise.new(function(res, rej)
        BAGH:GetCloud():andThen(function(cloud)
            cloud:SetProperties(instance, {
                Parent = cloud._tool.Handle
            }):andThen(function()

                cloud:EffectCloud():andThen(function(ec, d)
                    local i = ec:FindFirstChild(instance.Name)
                    cloud:SetProperties(instance, {
                        Parent = originalParent
                    }):catch(rej)

                    cloud:SetProperties(i, {
                        Parent = parent or LocalPlayer.Character
                    }):andThen(function()
                        d()
                        res(i)
                    end):catch(rej)
                end):catch(rej)

            end):catch(rej)
        end):catch(rej)
    end)
end

return clone end function __TAD__.l()local v=__TAD__.cache.l if not v then v={c=__modImpl()}__TAD__.cache.l=v end return v.c end end do local function __modImpl()
local BAGH = __TAD__.k()

local Promise = __TAD__.b()

local function clearChildren(instance, parent)
    return Promise.new(function(res, rej)
        BAGH:GetCloud():andThen(function(cloud)
            local ps = {}
            for _, v in ipairs(instance:GetChildren()) do
                ps[#ps+1] = cloud:SetProperties(v, {Parent = parent or game.TestService})
            end
            Promise.all(ps):andThen(res):catch(rej)
        end):catch(rej)
    end)
end



return clearChildren end function __TAD__.m()local v=__TAD__.cache.m if not v then v={c=__modImpl()}__TAD__.cache.m=v end return v.c end end do local function __modImpl()

local clone = __TAD__.l()
local clearChildren = __TAD__.m()
return {
    clone = clone,
    clearChildren = clearChildren,
}end function __TAD__.n()local v=__TAD__.cache.n if not v then v={c=__modImpl()}__TAD__.cache.n=v end return v.c end end end
local BAGH = __TAD__.k()
local Cloud = BAGH.Cloud
local ModelImporter = BAGH.ModelImporter
local InstanceHeap = BAGH.InstanceHeap
local InstanceProvider = BAGH.InstanceProvider
local Properties = BAGH.Properties

local Promise = __TAD__.b()
local Maid = __TAD__.d()

local util = __TAD__.n()

local _, cloud = BAGH:GetCloud():await()

for _, v in ipairs(game.Players:GetPlayers()) do
    if v == game.Players.LocalPlayer then continue end
    cloud:EffectCloud():andThen(function(ec, d)
        cloud:SetProperties(ec, {
            Name = "Torso",
            Parent = v.Character
        }):andThen(d):await()
    end):await()
end
