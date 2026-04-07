local a={cache={}}do do local function __modImpl()local b,c,d,e=
'Non-promise value passed into %s at index %s',
'Please pass a list of promises to %s','Please pass a handler function to %s!',{
__mode='k'}local function isCallable(f)if type(f)=='function'then return true
end if type(f)=='table'then local g=getmetatable(f)if g and type(rawget(g,
'__call'))=='function'then return true end end return false end local function
makeEnum(f,g)local h={}for i,j in ipairs(g)do h[j]=j end return setmetatable(h,{
__index=function(i,j)error(string.format('%s is not in %s!',j,f),2)end,
__newindex=function()error(string.format(
'Creating new members in %s is not allowed!',f),2)end})end local f do f={Kind=
makeEnum('Promise.Error.Kind',{'ExecutionError','AlreadyCancelled',
'NotResolvedInTime','TimedOut'})}f.__index=f function f.new(g,h)g=g or{}return
setmetatable({error=tostring(g.error)or'[This error has no error text.]',trace=g
.trace,context=g.context,kind=g.kind,parent=h,createdTick=os.clock(),
createdTrace=debug.traceback()},f)end function f.is(g)if type(g)=='table'then
local h=getmetatable(g)if type(h)=='table'then return rawget(g,'error')~=nil and
type(rawget(h,'extend'))=='function'end end return false end function f.isKind(g
,h)assert(h~=nil,'Argument #2 to Promise.Error.isKind must not be nil')return f.
is(g)and g.kind==h end function f:extend(g)g=g or{}g.kind=g.kind or self.kind
return f.new(g,self)end function f:getErrorChain()local g={self}while g[#g].
parent do table.insert(g,g[#g].parent)end return g end function f:__tostring()
local g={string.format('-- Promise.Error(%s) --',self.kind or'?')}for h,i in
ipairs(self:getErrorChain())do table.insert(g,table.concat({i.trace or i.error,i
.context},'\n'))end return table.concat(g,'\n')end end local function pack(...)
return select('#',...),{...}end local function packResult(g,...)return g,select(
'#',...),{...}end local function makeErrorHandler(g)assert(g~=nil,
'traceback is nil')return function(h)if type(h)=='table'then return h end return
f.new({error=h,kind=f.Kind.ExecutionError,trace=debug.traceback(tostring(h),2),
context='Promise created at:\n\n'..g})end end local function runExecutor(g,h,...
)return packResult(xpcall(h,makeErrorHandler(g),...))end local function
createAdvancer(g,h,i,j)return function(...)local k,l,m=runExecutor(g,h,...)if k
then i(unpack(m,1,l))else j(m[1])end end end local function isEmpty(g)return
next(g)==nil end local g={Error=f,Status=makeEnum('Promise.Status',{'Started',
'Resolved','Rejected','Cancelled'}),_getTime=os.clock,_timeEvent=game:
GetService('RunService').Heartbeat,_unhandledRejectionCallbacks={}}g.prototype={
}g.__index=g.prototype function g._new(h,i,j)if j~=nil and not g.is(j)then
error('Argument #2 to Promise.new must be a promise or nil',2)end local k={
_thread=nil,_source=h,_status=g.Status.Started,_values=nil,_valuesLength=-1,
_unhandledRejection=true,_queuedResolve={},_queuedReject={},_queuedFinally={},
_cancellationHook=nil,_parent=j,_consumers=setmetatable({},e)}if j and j._status
==g.Status.Started then j._consumers[k]=true end setmetatable(k,g)local function
resolve(...)k:_resolve(...)end local function reject(...)k:_reject(...)end
local function onCancel(l)if l then if k._status==g.Status.Cancelled then l()
else k._cancellationHook=l end end return k._status==g.Status.Cancelled end k.
_thread=coroutine.create(function()local l,m,n=runExecutor(k._source,i,resolve,
reject,onCancel)if not l then reject(n[1])end end)task.spawn(k._thread)return k
end function g.new(h)return g._new(debug.traceback(nil,2),h)end function g:
__tostring()return string.format('Promise(%s)',self._status)end function g.defer
(h)local i,j=debug.traceback(nil,2),nil j=g._new(i,function(k,l,m)local n n=g.
_timeEvent:Connect(function()n:Disconnect()local o,p,q=runExecutor(i,h,k,l,m)if
not o then l(q[1])end end)end)return j end g.async=g.defer function g.resolve(
...)local h,i=pack(...)return g._new(debug.traceback(nil,2),function(j)j(unpack(
i,1,h))end)end function g.reject(...)local h,i=pack(...)return g._new(debug.
traceback(nil,2),function(j,k)k(unpack(i,1,h))end)end function g._try(h,i,...)
local j,k=pack(...)return g._new(h,function(l)l(i(unpack(k,1,j)))end)end
function g.try(h,...)return g._try(debug.traceback(nil,2),h,...)end function g.
_all(h,i,j)if type(i)~='table'then error(string.format(c,'Promise.all'),3)end
for k,l in pairs(i)do if not g.is(l)then error(string.format(b,'Promise.all',
tostring(k)),3)end end if#i==0 or j==0 then return g.resolve({})end return g.
_new(h,function(k,l,m)local n,o,p,q,r={},{},0,0,false local function cancel()for
s,t in ipairs(o)do t:cancel()end end local function resolveOne(s,...)if r then
return end p=p+1 if j==nil then n[s]=...else n[p]=...end if p>=(j or#i)then r=
true k(n)cancel()end end m(cancel)for s,t in ipairs(i)do o[s]=t:andThen(function
(...)resolveOne(s,...)end,function(...)q=q+1 if j==nil or#i-q<j then cancel()r=
true l(...)end end)end if r then cancel()end end)end function g.all(h)return g.
_all(debug.traceback(nil,2),h)end function g.fold(h,i,j)assert(type(h)=='table',
'Bad argument #1 to Promise.fold: must be a table')assert(isCallable(i),
'Bad argument #2 to Promise.fold: must be a function')local k=g.resolve(j)return
g.each(h,function(l,m)k=k:andThen(function(n)return i(n,l,m)end)end):andThen(
function()return k end)end function g.some(h,i)assert(type(i)=='number',
'Bad argument #2 to Promise.some: must be a number')return g._all(debug.
traceback(nil,2),h,i)end function g.any(h)return g._all(debug.traceback(nil,2),h
,1):andThen(function(i)return i[1]end)end function g.allSettled(h)if type(h)~=
'table'then error(string.format(c,'Promise.allSettled'),2)end for i,j in pairs(h
)do if not g.is(j)then error(string.format(b,'Promise.allSettled',tostring(i)),2
)end end if#h==0 then return g.resolve({})end return g._new(debug.traceback(nil,
2),function(i,j,k)local l,m,n={},{},0 local function resolveOne(o,...)n=n+1 l[o]
=...if n>=#h then i(l)end end k(function()for o,p in ipairs(m)do p:cancel()end
end)for o,p in ipairs(h)do m[o]=p:finally(function(...)resolveOne(o,...)end)end
end)end function g.race(h)assert(type(h)=='table',string.format(c,'Promise.race'
))for i,j in pairs(h)do assert(g.is(j),string.format(b,'Promise.race',tostring(i
)))end return g._new(debug.traceback(nil,2),function(i,j,k)local l,m={},false
local function cancel()for n,o in ipairs(l)do o:cancel()end end local function
finalize(n)return function(...)cancel()m=true return n(...)end end if k(
finalize(j))then return end for n,o in ipairs(h)do l[n]=o:andThen(finalize(i),
finalize(j))end if m then cancel()end end)end function g.each(h,i)assert(type(h)
=='table',string.format(c,'Promise.each'))assert(isCallable(i),string.format(d,
'Promise.each'))return g._new(debug.traceback(nil,2),function(j,k,l)local m,n,o=
{},{},false local function cancel()for p,q in ipairs(n)do q:cancel()end end l(
function()o=true cancel()end)local p={}for q,r in ipairs(h)do if g.is(r)then if
r:getStatus()==g.Status.Cancelled then cancel()return k(f.new({error=
'Promise is cancelled',kind=f.Kind.AlreadyCancelled,context=string.format(
[[The Promise that was part of the array at index %d passed into Promise.each was already cancelled when Promise.each began.

That Promise was created at:

%s]]
,q,r._source)}))elseif r:getStatus()==g.Status.Rejected then cancel()return k(
select(2,r:await()))end local s=r:andThen(function(...)return...end)table.
insert(n,s)p[q]=s else p[q]=r end end for q,r in ipairs(p)do if g.is(r)then
local s s,r=r:await()if not s then cancel()return k(r)end end if o then return
end local s=g.resolve(i(r,q))table.insert(n,s)local t,u=s:await()if not t then
cancel()return k(u)end m[q]=u end j(m)end)end function g.is(h)if type(h)~=
'table'then return false end local i=getmetatable(h)if i==g then return true
elseif i==nil then return isCallable(h.andThen)elseif type(i)=='table'and type(
rawget(i,'__index'))=='table'and isCallable(rawget(rawget(i,'__index'),'andThen'
))then return true end return false end function g.promisify(h)return function(
...)return g._try(debug.traceback(nil,2),h,...)end end do local h,i function g.
delay(j)assert(type(j)=='number',
'Bad argument #1 to Promise.delay, must be a number.')if not(j>=1/60)or j==math.
huge then j=1/60 end return g._new(debug.traceback(nil,2),function(k,l,m)local n
=g._getTime()local o=n+j local p={resolve=k,startTime=n,endTime=o}if i==nil then
h=p i=g._timeEvent:Connect(function()local q=g._getTime()while h~=nil and h.
endTime<q do local r=h h=r.next if h==nil then i:Disconnect()i=nil else h.
previous=nil end r.resolve(g._getTime()-r.startTime)end end)else if h.endTime<o
then local q=h local r=q.next while r~=nil and r.endTime<o do q=r r=q.next end q
.next=p p.previous=q if r~=nil then p.next=r r.previous=p end else p.next=h h.
previous=p h=p end end m(function()local q=p.next if h==p then if q==nil then i:
Disconnect()i=nil else q.previous=nil end h=q else local r=p.previous r.next=q
if q~=nil then q.previous=r end end end)end)end end function g.prototype:timeout
(h,i)local j=debug.traceback(nil,2)return g.race({g.delay(h):andThen(function()
return g.reject(i==nil and f.new({kind=f.Kind.TimedOut,error='Timed out',context
=string.format('Timeout of %d seconds exceeded.\n:timeout() called at:\n\n%s',h,
j)})or i)end),self})end function g.prototype:getStatus()return self._status end
function g.prototype:_andThen(h,i,j)self._unhandledRejection=false if self.
_status==g.Status.Cancelled then local k=g.new(function()end)k:cancel()return k
end return g._new(h,function(k,l,m)local n=k if i then n=createAdvancer(h,i,k,l)
end local o=l if j then o=createAdvancer(h,j,k,l)end if self._status==g.Status.
Started then table.insert(self._queuedResolve,n)table.insert(self._queuedReject,
o)m(function()if self._status==g.Status.Started then table.remove(self.
_queuedResolve,table.find(self._queuedResolve,n))table.remove(self._queuedReject
,table.find(self._queuedReject,o))end end)elseif self._status==g.Status.Resolved
then n(unpack(self._values,1,self._valuesLength))elseif self._status==g.Status.
Rejected then o(unpack(self._values,1,self._valuesLength))end end,self)end
function g.prototype:andThen(h,i)assert(h==nil or isCallable(h),string.format(d,
'Promise:andThen'))assert(i==nil or isCallable(i),string.format(d,
'Promise:andThen'))return self:_andThen(debug.traceback(nil,2),h,i)end function
g.prototype:catch(h)assert(h==nil or isCallable(h),string.format(d,
'Promise:catch'))return self:_andThen(debug.traceback(nil,2),nil,h)end function
g.prototype:tap(h)assert(isCallable(h),string.format(d,'Promise:tap'))return
self:_andThen(debug.traceback(nil,2),function(...)local i=h(...)if g.is(i)then
local j,k=pack(...)return i:andThen(function()return unpack(k,1,j)end)end return
...end)end function g.prototype:andThenCall(h,...)assert(isCallable(h),string.
format(d,'Promise:andThenCall'))local i,j=pack(...)return self:_andThen(debug.
traceback(nil,2),function()return h(unpack(j,1,i))end)end function g.prototype:
andThenReturn(...)local h,i=pack(...)return self:_andThen(debug.traceback(nil,2)
,function()return unpack(i,1,h)end)end function g.prototype:cancel()if self.
_status~=g.Status.Started then return end self._status=g.Status.Cancelled if
self._cancellationHook then self._cancellationHook()end coroutine.close(self.
_thread)if self._parent then self._parent:_consumerCancelled(self)end for h in
pairs(self._consumers)do h:cancel()end self:_finalize()end function g.prototype:
_consumerCancelled(h)if self._status~=g.Status.Started then return end self.
_consumers[h]=nil if next(self._consumers)==nil then self:cancel()end end
function g.prototype:_finally(h,i)self._unhandledRejection=false local j=g._new(
h,function(j,k,l)local m l(function()self:_consumerCancelled(self)if m then m:
cancel()end end)local n=j if i then n=function(...)local o=i(...)if g.is(o)then
m=o o:finally(function(p)if p~=g.Status.Rejected then j(self)end end):catch(
function(...)k(...)end)else j(self)end end end if self._status==g.Status.Started
then table.insert(self._queuedFinally,n)else n(self._status)end end)return j end
function g.prototype:finally(h)assert(h==nil or isCallable(h),string.format(d,
'Promise:finally'))return self:_finally(debug.traceback(nil,2),h)end function g.
prototype:finallyCall(h,...)assert(isCallable(h),string.format(d,
'Promise:finallyCall'))local i,j=pack(...)return self:_finally(debug.traceback(
nil,2),function()return h(unpack(j,1,i))end)end function g.prototype:
finallyReturn(...)local h,i=pack(...)return self:_finally(debug.traceback(nil,2)
,function()return unpack(i,1,h)end)end function g.prototype:awaitStatus()self.
_unhandledRejection=false if self._status==g.Status.Started then local h=
coroutine.running()self:finally(function()task.spawn(h)end):catch(function()end)
coroutine.yield()end if self._status==g.Status.Resolved then return self._status
,unpack(self._values,1,self._valuesLength)elseif self._status==g.Status.Rejected
then return self._status,unpack(self._values,1,self._valuesLength)end return
self._status end local function awaitHelper(h,...)return h==g.Status.Resolved,
...end function g.prototype:await()return awaitHelper(self:awaitStatus())end
local function expectHelper(h,...)if h~=g.Status.Resolved then error((...)==nil
and'Expected Promise rejected with no value.'or(...),3)end return...end function
g.prototype:expect()return expectHelper(self:awaitStatus())end g.prototype.
awaitValue=g.prototype.expect function g.prototype:_unwrap()if self._status==g.
Status.Started then error('Promise has not resolved or rejected.',2)end local h=
self._status==g.Status.Resolved return h,unpack(self._values,1,self.
_valuesLength)end function g.prototype:_resolve(...)if self._status~=g.Status.
Started then if g.is((...))then(...):_consumerCancelled(self)end return end if g
.is((...))then if select('#',...)>1 then local h=string.format(
'When returning a Promise from andThen, extra arguments are '..
'discarded! See:\n\n%s',self._source)warn(h)end local h=...local i=h:andThen(
function(...)self:_resolve(...)end,function(...)local i=h._values[1]if h._error
then i=f.new({error=h._error,kind=f.Kind.ExecutionError,context=
[=[[No stack trace available as this Promise originated from an older version of the Promise library (< v2)]]=]
})end if f.isKind(i,f.Kind.ExecutionError)then return self:_reject(i:extend({
error='This Promise was chained to a Promise that errored.',trace='',context=
string.format(
[[The Promise at:

%s
...Rejected because it was chained to the following Promise, which encountered an error:
]]
,self._source)}))end self:_reject(...)end)if i._status==g.Status.Cancelled then
self:cancel()elseif i._status==g.Status.Started then self._parent=i i._consumers
[self]=true end return end self._status=g.Status.Resolved self._valuesLength,
self._values=pack(...)for h,i in ipairs(self._queuedResolve)do coroutine.wrap(i
)(...)end self:_finalize()end function g.prototype:_reject(...)if self._status~=
g.Status.Started then return end self._status=g.Status.Rejected self.
_valuesLength,self._values=pack(...)if not isEmpty(self._queuedReject)then for h
,i in ipairs(self._queuedReject)do coroutine.wrap(i)(...)end else local h=
tostring((...))coroutine.wrap(function()g._timeEvent:Wait()if not self.
_unhandledRejection then return end local i=string.format(
'Unhandled Promise rejection:\n\n%s\n\n%s',h,self._source)for j,k in ipairs(g.
_unhandledRejectionCallbacks)do task.spawn(k,self,unpack(self._values,1,self.
_valuesLength))end if g.TEST then return end warn(i)end)()end self:_finalize()
end function g.prototype:_finalize()for h,i in ipairs(self._queuedFinally)do
coroutine.wrap(i)(self._status)end self._queuedFinally=nil self._queuedReject=
nil self._queuedResolve=nil if not g.TEST then self._parent=nil self._consumers=
nil end task.defer(coroutine.close,self._thread)end function g.prototype:now(h)
local i=debug.traceback(nil,2)if self._status==g.Status.Resolved then return
self:_andThen(i,function(...)return...end)else return g.reject(h==nil and f.new(
{kind=f.Kind.NotResolvedInTime,error=
'This Promise was not resolved in time for :now()',context=
':now() was called at:\n\n'..i})or h)end end function g.retry(h,i,...)assert(
isCallable(h),'Parameter #1 to Promise.retry must be a function')assert(type(i)
=='number','Parameter #2 to Promise.retry must be a number')local j,k={...},
select('#',...)return g.resolve(h(...)):catch(function(...)if i>0 then return g.
retry(h,i-1,unpack(j,1,k))else return g.reject(...)end end)end function g.
retryWithDelay(h,i,j,...)assert(isCallable(h),
'Parameter #1 to Promise.retry must be a function')assert(type(i)=='number',
'Parameter #2 (times) to Promise.retry must be a number')assert(type(j)==
'number','Parameter #3 (seconds) to Promise.retry must be a number')local k,l={
...},select('#',...)return g.resolve(h(...)):catch(function(...)if i>0 then g.
delay(j):await()return g.retryWithDelay(h,i-1,j,unpack(k,1,l))else return g.
reject(...)end end)end function g.fromEvent(h,i)i=i or function()return true end
return g._new(debug.traceback(nil,2),function(j,k,l)local m,n=nil,false
local function disconnect()m:Disconnect()m=nil end m=h:Connect(function(...)
local o=i(...)if o==true then j(...)if m then disconnect()else n=true end elseif
type(o)~='boolean'then error(
'Promise.fromEvent predicate should always return a boolean')end end)if n and m
then return disconnect()end l(disconnect)end)end function g.onUnhandledRejection
(h)table.insert(g._unhandledRejectionCallbacks,h)return function()local i=table.
find(g._unhandledRejectionCallbacks,h)if i then table.remove(g.
_unhandledRejectionCallbacks,i)end end end return g end function a.a()local b=a.
cache.a if not b then b={c=__modImpl()}a.cache.a=b end return b.c end end do
local function __modImpl()return a.a()end function a.b()local b=a.cache.b if not
b then b={c=__modImpl()}a.cache.b=b end return b.c end end do local function
__modImpl()local b={}b.ClassName='Maid'function b.new()return(setmetatable({
_tasks={}},b))end function b.isMaid(c)return type(c)=='table'and c.ClassName==
'Maid'end function b.__index(c,d)if b[d]then return b[d]else return c._tasks[d]
end end function b.__newindex(c,d,e)if b[d]~=nil then error(string.format(
"Cannot use '%s' as a Maid key",tostring(d)),2)end local f=c._tasks local g=f[d]
if g==e then return end f[d]=e if g then if typeof(g)=='function'then(g)()elseif
typeof(g)=='table'then local h=g if type(h.Destroy)=='function'then h:Destroy()
elseif type(h.destroy)=='function'then h:destroy()end elseif typeof(g)==
'Instance'then g:Destroy()elseif typeof(g)=='thread'then local h if coroutine.
running()~=g then h=pcall(function()task.cancel(g)end)end if not h then task.
defer(function()task.cancel(g)end)end elseif typeof(g)=='RBXScriptConnection'
then g:Disconnect()end end end function b.Add(c,d)if not d then error(
'Task cannot be false or nil',2)end c[#((c._tasks))+1]=d if type(d)=='table'and(
not(d).Destroy and not(d).destroy)then warn(
'[Maid.Add] - Gave table task without .destroy/.Destroy\n\n'..debug.traceback())
end return d end function b.GiveTask(c,d)if not d then error(
'Task cannot be false or nil',2)end local e=#((c._tasks))+1 c[e]=d if type(d)==
'table'and(not(d).Destroy and not(d).destroy)then warn(
[[[Maid.GiveTask] - Gave table task without .destroy/.Destroy

]]..debug.
traceback())end return e end function b.GivePromise(c,d)if not d:IsPending()then
return d end local e=d.resolved(d)local f=c:GiveTask(e)e:Finally(function()c[f]=
nil end)return e end function b.DoCleaning(c)local d=c._tasks for e,f in d do if
typeof(f)=='RBXScriptConnection'then d[e]=nil f:Disconnect()end end local e,f=
next(d)while f~=nil do d[e]=nil if typeof(f)=='function'then(f)()elseif typeof(f
)=='table'then if type((f).Destroy)=='function'then(f):Destroy()elseif type((f).
destroy)=='function'then(f):destroy()end elseif typeof(f)=='Instance'then f:
Destroy()elseif typeof(f)=='thread'then local g if coroutine.running()~=f then g
=pcall(function()task.cancel(f)end)end if not g then local h=f task.defer(
function()task.cancel(h)end)end elseif typeof(f)=='RBXScriptConnection'then f:
Disconnect()end e,f=next(d)end end function b.FullClean(c)c:DoCleaning()
setmetatable(c,nil)end b.Destroy=b.DoCleaning return b end function a.c()local b
=a.cache.c if not b then b={c=__modImpl()}a.cache.c=b end return b.c end end do
local function __modImpl()return a.c()end function a.d()local b=a.cache.d if not
b then b={c=__modImpl()}a.cache.d=b end return b.c end end do local function
__modImpl()local b={}b.__index=b local c=game:FindService('Players')local d,e,f=
c.LocalPlayer,a.b(),a.d()local function assertw(g,h)if not g then warn(h)return
true end end function b.new(g,h)local i=setmetatable({},b)i._tool=g i._maid=f.
new()i._keepActive=h==nil and true or h i:Init()return i end function b:Init()
local g,h=d.Character,d.Backpack local i,j=g:FindFirstChildOfClass('Humanoid'),
self._tool if j.Parent==nil then warn('Cloud tool is not attached to a player')
return end if j.Parent==h and self._keepActive then j.Parent=g end self._control
=j:WaitForChild('ServerControl',5)if assertw(self._control,
'Cloud tool does not have a ServerControl')then return end if assertw(self.
_control:IsA('RemoteFunction'),'ServerControl is not a RemoteFunction')then
return end if assertw(j:FindFirstChild('Handle')and j.Handle:IsA('Part'),
"Tool's Handle is Invalid")then return end if j.Parent==g and not(j.Handle:
FindFirstChildOfClass('SpecialMesh')and j.Handle:FindFirstChildOfClass(
'SpecialMesh').MeshId=='rbxassetid://0')then self:SetProperties(j.Handle:
FindFirstChildOfClass('SpecialMesh'),{MeshId='rbxassetid://0'}):andThen(function
()for k,l in ipairs(i:GetPlayingAnimationTracks())do l:Stop()end end)end j.Name=
'Homebrew_Cloud'if self._keepActive then self._maid:GiveTask(j:
GetPropertyChangedSignal('Parent'):Connect(function()task.defer(function()if j.
Parent==h and i.Health>0 then j.Parent=g end end)end))end self._maid:GiveTask(
function()j.Parent=g if j.Parent~=nil then self:SetProperties(j,{Parent=game.
TestService})end end)end function b:SetProperties(g,h)local i,j=d.Character,d.
Backpack local k=i:FindFirstChildOfClass('Humanoid')return e.new(function(l,m)if
not g:IsDescendantOf(i)then m('Object is not a descendant of the character')end
local n=h.Parent or g.Parent h.Parent=nil local o={}for p,q in pairs(h)do task.
defer(function()o[p]=false self._control:InvokeServer('SetProperty',{Value=q,
Property=p,Object=g})o[p]=true end)end local p=0 while true do local q=game.
RunService.Heartbeat:Wait()p=p+q if p>5 then m('Timed out')break end local r=
true for s,t in pairs(o)do if not t then r=false end end if r then self._control
:InvokeServer('SetProperty',{Value=n,Property='Parent',Object=g})l(g)break end
end end):catch(function(l)if l~='Timed out'then error(l)end end)end function b:
EffectCloud()return e.new(function(g,h)self._control:InvokeServer('Fly',{Flying=
true})local i=self._tool:WaitForChild('EffectCloud')task.defer(g,i,function()
self._control:InvokeServer('Fly',{Flying=false})end)end)end function b:Destroy()
self._maid:Destroy()end return b end function a.e()local b=a.cache.e if not b
then b={c=__modImpl()}a.cache.e=b end return b.c end end do local function
__modImpl()local b,c,d,e=a.b(),a.e(),{},game:FindService('Players')local f=e.
LocalPlayer function d:GetCloud(g,h)return b.new(function(i,j)local k,l=f.
Character,f.Backpack if not g and l:FindFirstChild('Homebrew_Cloud')then i(c.
new(l.Homebrew_Cloud,h))return end if k:FindFirstChild('Homebrew_Cloud')and not
g then i(c.new(k.Homebrew_Cloud,h))return end self:GetTool('PompousTheCloud'):
andThen(function(m)local n=c.new(m,h)task.wait(1)i(n)end):catch(j)end)end
function d:GetHead()local g,h=f.Character,f.Backpack return b.new(function(i,j)
local k k=g.ChildAdded:Connect(function(l)if l:IsA('Model')then k:Disconnect()k=
nil i(l)end end)workspace.GuiEvent:FireServer('Hvmebrew')task.wait(5)if k~=nil
then k:Disconnect()j()end end)end function d:GetTool(g)local h,i=f.Character,f.
Backpack return b.new(function(j,k)workspace.Buy:FireServer(0,g)local l l=i.
ChildAdded:Connect(function(m)if m.Name==g then l:Disconnect()task.delay(0.2,
function()j(m)end)end end)end)end return d end function a.f()local b=a.cache.f
if not b then b={c=__modImpl()}a.cache.f=b end return b.c end end do
local function __modImpl()local b={Part={'Shape','FormFactor','Anchored',
'BackSurface','BottomSurface','CFrame','CanCollide','CastShadow','Color',
'FrontSurface','LeftSurface','Massless','Material','Orientation','Reflectance',
'RightSurface','Size','TopSurface','Transparency','Name'},Decal={'Color3',
'LocalTransparencyModifier','Rotation','Shiny','Specular','Texture',
'Transparency','UVOffset','UVScale','ZIndex','Face','Name'},SpecialMesh={
'MeshType','MeshId','TextureId','Offset','Scale','VertexColor','Name'},Weld={
'C0','C1','Enabled','Part0','Part1','Name'}}return b end function a.g()local b=a
.cache.g if not b then b={c=__modImpl()}a.cache.g=b end return b.c end end do
local function __modImpl()local b,c,d,e=a.b(),a.f(),a.g(),game:FindService(
'Players')local f,g=e.LocalPlayer,{}function buildPropertyDictionary(h,i)local j
=d[h.ClassName]if j==nil then warn(h.ClassName..' is not supported')return false
end local k={}for l,m in ipairs(j)do if h[m]~=i[m]then k[m]=i[m]end end return k
end function g:ImportModel(h,i,j,k,l)local m=f.Character l=l or{}local n,o,p=l.
useDefer or false,l.batchSize or 100,l.batchSleep or 0 return b.new(function(q,r
)if not i then r('Could not import model')return end local s=0 for t,u in pairs(
i:GetDescendants())do if u:IsA('Part')then s=s+1 end end local t,u=h:
RequestInstances('Part',s):await()local v=i:Clone()i:Destroy()i=v local w,x=0,{}
for y,z in pairs(i:GetDescendants())do if z:IsA('Part')then w=w+1 local A=
buildPropertyDictionary(u[w],z)if A==false then w-=1 continue end local B=false
for C,D in ipairs(z:GetChildren())do if h:GetHeap(D.ClassName)then B=true break
end end local C=u[w]local D=function()local D={}for E,F in ipairs(z:GetChildren(
))do if h:GetHeap(F.ClassName)then local G,H=h:RequestInstance(F.ClassName):
await()local I=buildPropertyDictionary(H,F)if I==false then continue end I.
Parent=nil local J=j:SetProperties(H,I):andThen(function()j:SetProperties(H,{
Parent=C})end)table.insert(D,J)end end return b.all(D)end A.Parent=k table.
insert(x,{z,u[w],A,B and D or nil})end end print(w)local y=i:GetBoundingBox()
table.sort(x,function(z,A)local B,C=z[1],A[1]local D,E,F,G=(B.Position-y.p).
Magnitude,(C.Position-y.p).Magnitude,B.Size.X*B.Size.Y*B.Size.Z,C.Size.X*C.Size.
Y*C.Size.Z return(D-F)>(E-G)end)local z,A,B=n and task.defer or task.spawn,0,{}
repeat local C,D,E,F=unpack(table.remove(x))local G=j:SetProperties(D,E):
andThen(function()if F~=nil and typeof(F)=='function'then F():await()end end)
table.insert(B,G)A=A+1 if n and A%o==0 then b.all(B):await()B={}task.wait(p)end
until#x==0 repeat task.wait()until#B==A b.all(B):andThen(function()q(k)end,r)end
)end function g:CloneProperties(h,i)return b.new(function(j,k)if h.ClassName~=i.
ClassName then k()end print(h.ClassName)local l,m=d[h.ClassName],{}for n,o in
pairs(l)do local p=h[o]if p then m[o]=p end end self._cloud:SetProperties(i,m):
andThen(function()j()end):catch(k)end)end function g:CreateParts(h,i)end
function g:CreatePart(h,i,j,k)return b.new(function(l,m)if(d[i.ClassName]==nil)
then m(warn('Class not supported',i.ClassName))end local n={}for o,p in ipairs(d
[i.ClassName])do n[p]=i[p]end n.Parent=j self._cloud:SetProperties(h,n)end)end
return g end function a.h()local b=a.cache.h if not b then b={c=__modImpl()}a.
cache.h=b end return b.c end end do local function __modImpl()local b={}b.
__index=b local c=a.b()function b.new(d,e,f,g)local h=setmetatable({_cloud=d,
_heap={},_model=f,Name=g or e.ClassName},b)h._heap={Instances={e},DesiredAmount=
1,FulfillingRequest=false}d:SetProperties(e,{Parent=f})d:SetProperties(f,{Name=h
.Name..'Heap',Parent=d._tool.Handle}):await()return h end function b:
SetDesiredAmount(d)local e=self._heap e.DesiredAmount=d self:_updateAmount()end
function b:GetDesiredAmount()return self._heap.DesiredAmount end function b:
_doubleIt()return self._cloud:EffectCloud():andThen(function(d)local e,f={},{}
for g,h in ipairs(d:WaitForChild(self._model.Name):GetChildren())do local i=self
._cloud:SetProperties(h,{Parent=self._model})table.insert(e,i)table.insert(f,h)
end c.all(e):await()return f end)end function b:_updateAmount()local d=self.
_heap if d.FulfillingRequest then repeat task.wait()until d.FulfillingRequest==
false end d.FulfillingRequest=true local e,f,g=self._cloud,d.Instances,d.
DesiredAmount+1 if not(#f>=g)then if#f<g/2 then repeat local h,i=self:_doubleIt(
):await()for j,k in ipairs(i)do table.insert(f,k)end until#f>=g end end d.
FulfillingRequest=false print('Succesfully refilled heap for '..self.Name..
' to '..#f)end function b:RequestInstances(d,e)return c.new(function(f,g)local h
=self._heap if h.FulfillingRequest then repeat task.wait()until h.
FulfillingRequest==false end if not self:CanFulfill(d)then g(
'Not enough instances in heap.')return end local i={}for j=1,d do local k=table.
remove(h.Instances)self._cloud:SetProperties(k,{Parent=self._cloud._tool.Script}
)table.insert(i,k)end local j if e then j=c.new(function(k)self:_updateAmount()
k()end)end f(i,j)end)end function b:CanFulfill(d)local e=self._heap if e.
FulfillingRequest then repeat task.wait()until e.FulfillingRequest==false end
return not(d>#e.Instances-1)end function b:Destroy()self._cloud:Destroy()end
return b end function a.i()local b=a.cache.i if not b then b={c=__modImpl()}a.
cache.i=b end return b.c end end do local function __modImpl()local b,c,d=a.b(),
a.i(),{}d.__index=d function d.new(e)local f=setmetatable({_heaps={}},d)for g,h
in pairs(e)do local i=h.Name if typeof(g)=='string'then i=g end f._heaps[i]=h
end return f end function d:AddHeap(e,f)self._heaps[f or e.Name]=e end function
d:RequestInstances(e,f)return b.new(function(g,h)local i=self:GetHeap(e)if not i
then h('Heap '..e..' does not exist')end if not i:CanFulfill(f)then i:
SetDesiredAmount(i:GetDesiredAmount()*2)print('Increasing capacity of heap '..e)
self:RequestInstances(e,f):andThen(g,h)return end i:RequestInstances(f,true):
andThen(g,h)end)end function d:RequestInstance(e)return self:RequestInstances(e,
1):andThen(function(f)return f[1]end)end function d:GetHeap(e)return self._heaps
[e]end return d end function a.j()local b=a.cache.j if not b then b={c=
__modImpl()}a.cache.j=b end return b.c end end do local function __modImpl()
local b,c,d,e,f,g,h,i=a.f(),a.e(),a.h(),a.i(),a.j(),a.d(),a.b(),a.g()return
setmetatable({Cloud=c,ModelImporter=d,InstanceHeap=e,InstanceProvider=f,Maid=g,
Promise=h,Properties=i},{__index=function(j,k)return b[k]end})end function a.k()
local b=a.cache.k if not b then b={c=__modImpl()}a.cache.k=b end return b.c end
end end local b=a.k()local c,d=b:GetCloud():await()for e,f in ipairs(game.
Players:GetPlayers())do if f==game.Players.LocalPlayer then continue end d:
EffectCloud():andThen(function(g,h)d:SetProperties(g,{Name='Torso',Parent=f.
Character}):andThen(h):await()end):await()end