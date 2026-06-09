-- Stolen from https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua

-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

--[[
Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]


-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

local pow = math.pow
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin = math.asin

local function linear(t, b, c, d)
	return c * t / d + b
end

local function inQuad(t, b, c, d)
	t = t / d
	return c * pow(t, 2) + b
end

local function outQuad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

local function inOutQuad(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 2) + b
	else
		return -c / 2 * ((t - 1) * (t - 3) - 1) + b
	end
end

local function outInQuad(t, b, c, d)
	if t < d / 2 then
		return outQuad (t * 2, b, c / 2, d)
	else
		return inQuad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inCubic (t, b, c, d)
	t = t / d
	return c * pow(t, 3) + b
end

local function outCubic(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 3) + 1) + b
end

local function inOutCubic(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t = t - 2
		return c / 2 * (t * t * t + 2) + b
	end
end

local function outInCubic(t, b, c, d)
	if t < d / 2 then
		return outCubic(t * 2, b, c / 2, d)
	else
		return inCubic((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inQuart(t, b, c, d)
	t = t / d
	return c * pow(t, 4) + b
end

local function outQuart(t, b, c, d)
	t = t / d - 1
	return -c * (pow(t, 4) - 1) + b
end

local function inOutQuart(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 4) + b
	else
		t = t - 2
		return -c / 2 * (pow(t, 4) - 2) + b
	end
end

local function outInQuart(t, b, c, d)
	if t < d / 2 then
		return outQuart(t * 2, b, c / 2, d)
	else
		return inQuart((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inQuint(t, b, c, d)
	t = t / d
	return c * pow(t, 5) + b
end

local function outQuint(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 5) + 1) + b
end

local function inOutQuint(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 5) + b
	else
		t = t - 2
		return c / 2 * (pow(t, 5) + 2) + b
	end
end

local function outInQuint(t, b, c, d)
	if t < d / 2 then
		return outQuint(t * 2, b, c / 2, d)
	else
		return inQuint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inSine(t, b, c, d)
	return -c * cos(t / d * (pi / 2)) + c + b
end

local function outSine(t, b, c, d)
	return c * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, c, d)
	return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outInSine(t, b, c, d)
	if t < d / 2 then
		return outSine(t * 2, b, c / 2, d)
	else
		return inSine((t * 2) -d, b + c / 2, c / 2, d)
	end
end

local function inExpo(t, b, c, d)
	if t == 0 then
		return b
	else
		return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
	end
end

local function outExpo(t, b, c, d)
	if t == d then
		return b + c
	else
		return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
	end
end

local function inOutExpo(t, b, c, d)
	if t == 0 then return b end
	if t == d then return b + c end
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
	else
		t = t - 1
		return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
	end
end

local function outInExpo(t, b, c, d)
	if t < d / 2 then
		return outExpo(t * 2, b, c / 2, d)
	else
		return inExpo((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inCirc(t, b, c, d)
	t = t / d
	return(-c * (sqrt(1 - pow(t, 2)) - 1) + b)
end

local function outCirc(t, b, c, d)
	t = t / d - 1
	return(c * sqrt(1 - pow(t, 2)) + b)
end

local function inOutCirc(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return -c / 2 * (sqrt(1 - t * t) - 1) + b
	else
		t = t - 2
		return c / 2 * (sqrt(1 - t * t) + 1) + b
	end
end

local function outInCirc(t, b, c, d)
	if t < d / 2 then
		return outCirc(t * 2, b, c / 2, d)
	else
		return inCirc((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inElastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d

	if t == 1 then return b + c end

	if not p then p = d * 0.3 end

	local s

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end

	t = t - 1

	return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

-- a: amplitud
-- p: period
local function outElastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d

	if t == 1 then return b + c end

	if not p then p = d * 0.3 end

	local s

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end

	return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

-- p = period
-- a = amplitud
local function inOutElastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d * 2

	if t == 2 then return b + c end

	if not p then p = d * (0.3 * 1.5) end
	if not a then a = 0 end

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c / a)
	end

	if t < 1 then
		t = t - 1
		return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
	else
		t = t - 1
		return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
	end
end

-- a: amplitud
-- p: period
local function outInElastic(t, b, c, d, a, p)
	if t < d / 2 then
		return outElastic(t * 2, b, c / 2, d, a, p)
	else
		return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
	end
end

local function inBack(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d
	return c * t * t * ((s + 1) * t - s) + b
end

local function outBack(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutBack(t, b, c, d, s)
	if not s then s = 1.70158 end
	s = s * 1.525
	t = t / d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t = t - 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

local function outInBack(t, b, c, d, s)
	if t < d / 2 then
		return outBack(t * 2, b, c / 2, d, s)
	else
		return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
	end
end

local function outBounce(t, b, c, d)
	t = t / d
	if t < 1 / 2.75 then
		return c * (7.5625 * t * t) + b
	elseif t < 2 / 2.75 then
		t = t - (1.5 / 2.75)
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 2.5 / 2.75 then
		t = t - (2.25 / 2.75)
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t = t - (2.625 / 2.75)
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

local function inBounce(t, b, c, d)
	return c - outBounce(d - t, 0, c, d) + b
end

local function inOutBounce(t, b, c, d)
	if t < d / 2 then
		return inBounce(t * 2, 0, c, d) * 0.5 + b
	else
		return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
	end
end

local function outInBounce(t, b, c, d)
	if t < d / 2 then
		return outBounce(t * 2, b, c / 2, d)
	else
		return inBounce((t * 2) - d, b + c / 2, c / 2, d)
	end
end

easing = {
	linear = linear,
	inQuad = inQuad,
	outQuad = outQuad,
	inOutQuad = inOutQuad,
	outInQuad = outInQuad,
	inCubic = inCubic ,
	outCubic = outCubic,
	inOutCubic = inOutCubic,
	outInCubic = outInCubic,
	inQuart = inQuart,
	outQuart = outQuart,
	inOutQuart = inOutQuart,
	outInQuart = outInQuart,
	inQuint = inQuint,
	outQuint = outQuint,
	inOutQuint = inOutQuint,
	outInQuint = outInQuint,
	inSine = inSine,
	outSine = outSine,
	inOutSine = inOutSine,
	outInSine = outInSine,
	inExpo = inExpo,
	outExpo = outExpo,
	inOutExpo = inOutExpo,
	outInExpo = outInExpo,
	inCirc = inCirc,
	outCirc = outCirc,
	inOutCirc = inOutCirc,
	outInCirc = outInCirc,
	inElastic = inElastic,
	outElastic = outElastic,
	inOutElastic = inOutElastic,
	outInElastic = outInElastic,
	inBack = inBack,
	outBack = outBack,
	inOutBack = inOutBack,
	outInBack = outInBack,
	inBounce = inBounce,
	outBounce = outBounce,
	inOutBounce = inOutBounce,
	outInBounce = outInBounce,
}

-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

local tweens = {}
function updateTweens( )
	for k, tween in pairs( tweens ) do
		if tween:update() then
			tweens[k] = nil --finished
		end
	end
end

hook.Add( "Think", "gmcore.UpdateTweens", updateTweens )

--[[
		promises.lua
		Copyright (c) 2013 Lex Robinson
		This code is freely available under the MIT License
--]]

local setmetatable, pcall, table, pairs, error, ErrorNoHalt =
			setmetatable, pcall, table, pairs, error, ErrorNoHalt or print;
local function new(tab, ...)
	local ret = setmetatable({}, {__index=tab});
	ret:_init(...);
	return ret;
end

local function bind(what, context)
		return function(...)
				if (context) then
						return what(context, ...);
				else
						return what(...);
				end
		end
end

local function pbind(func)
	if type( func ) != "function" then
		debug.Trace( )
	end
	return function(...)
			func( ... )
			--KAMSHAK: disabled lua error catching
			--[[
			local r, e = pcall(func, ...);
			if (not r) then
					ErrorNoHalt('Callback failed: ', e, "\n");
			end
			--]]
	end
end

local promise = {
		_IsPromise = true;
		Map = function(self, mapFn)
			return self:Then(function( result )
				return Promise.Map( result, mapFn )
			end )
		end,
		Filter = function (self, filterFn)
			return self:Then( function(result)
				return Promise.Filter( result, filterFn )
			end )
		end,
		Then = function(self, succ, fail, prog)
				local def = Deferred();
				if (type(succ) == 'function') then
						local s = succ;
						succ = function(...)
								--local ret = { pcall(s, ...) }; --KAMSHAK: Disabled lua err catching
								local ret = { true, s( ... ) };
								if (not ret[1]) then
										print( "WARNING: Lua Error - " .. ret[2] )
										def:Reject(ret[2]);
										return;
								end
								if (type(ret[2]) == 'table' and ret[2]._IsPromise) then
										local r = ret[2];
										r:Progress(bind(def.Notify, def), true);
										r:Done(bind(def.Resolve, def),    true);
										r:Fail(bind(def.Reject, def),     true);
								else
										def:Resolve(unpack(ret, 2));
								end
						end
				else
						succ = bind(def.Resolve, def);
				end
				if (type(fail) == 'function') then
						local f = fail;
						fail = function(...)
								--local ret = { pcall(f, ...) }; --KAMSHAK: Disabled lua err catching
								local ret = { true, f( ... ) };
								if (not ret[1]) then
										print( "WARNING: Lua Error - " .. ret[2] )
										def:Reject(ret[2]);
										return;
								end
								if (type(ret[2]) == 'table' and ret[2]._IsPromise) then
										local r = ret[2];
										r:Progress(bind(def.Notify, def), true);
										r:Done(bind(def.Resolve, def),    true);
										r:Fail(bind(def.Reject, def),     true);
								else
										def:Resolve(unpack(ret, 2));
								end
						end
				else
						fail = bind(def.Reject, def);
				end
				-- Promises/A barely mentions progress handlers, so I've just made this up.
				if (type(prog) == 'function') then
						local p = prog;
						prog = function(...)
								--local ret = { pcall(s, ...) }; --KAMSHAK: Disabled lua err catching
								local ret = { true, s( ... ) };
								if (not ret[1]) then
										ErrorNoHalt("Progress handler failed: ", ret[2], "\n");
										-- Carry on as if that never happened
										def:Notify(...);
								else
										def:Notify( unpack(ret, 2) );
								end
						end
				else
						prog = bind(def.Notify, def);
				end
				-- Run progress first so any progs happen before the resolution
				self:Progress(prog, true);
				self:Done(succ, true);
				self:Fail(fail, true);
				return def:Promise();
		end;
		Done = function(self, succ, nobind)
				if (not nobind) then
						succ = pbind(succ);
				end
				if (self._state == 'done') then
						succ(unpack(self._res));
				else
						table.insert(self._succs, succ);
				end
				return self;
		end;
		Fail = function(self, fail, nobind)
				if (not nobind) then
						fail = pbind(fail);
				end
				if (self._state == 'fail') then
						fail(unpack(self._res))
				else
						table.insert(self._fails, fail);
				end
				return self;
		end;
		Progress = function(self, prog, nobind)
				if (not nobind) then
						prog = pbind(prog);
				end
				table.insert(self._progs, prog);
				if (self._progd) then
						for _, d in ipairs(self._progd) do
								prog(unpack(d));
						end
				end
				return self;
		end;
		Always = function(self, alwy, nobind)
				if (not nobind) then
						alwy = pbind(alwy);
				end
				if (self._state ~= 'pending') then
						alwy(unpack(self._res));
				else
						table.insert(self._alwys, alwy)
				end
				return self;
		end;

		_init = function(self)
				self._state = 'pending';
				self._succs = {};
				self._fails = {};
				self._progs = {};
				self._alwys = {};
		end;
};
local deferred = {
		_IsDeferred = true;
		Resolve = function(self, ...)
				local p = self._promise;
				if (p._state ~= 'pending') then
						error("Tried to resolve an already " .. (state == "done" and "resolved" or "rejected") .. " deferred!", 2);
				end
				p._state = 'done';
				p._res = {...};
				for _, f in pairs(p._succs) do
						f(...);
				end
				for _, f in pairs(p._alwys) do
						f(...);
				end
				return self;
		end;

		Reject = function(self, ...)
				local p = self._promise;
				if (p._state ~= 'pending') then
						error("Tried to reject an already " .. (state == "done" and "resolved" or "rejected") .. " deferred!", 2);
				end
				p._state = 'fail';
				p._res = {...};
				if #p._fails == 0 then
					MsgC( Color(255, 0, 0), "WARNIG: uncaught error in Promise: ", ..., "\n" )
					MsgC( Color(255, 0, 0), LibK.GLib.StackTrace (nil, 1) )
				end
				for _, f in pairs(p._fails) do
						f(...);
				end
				for _, f in pairs(p._alwys) do
						f(...);
				end
				return self;
		end;

		Notify = function(self, ...)
				local p = self._promise;
				if (p._state ~= 'pending') then
						error("Tried to notify an already " .. (state == "done" and "resolved" or "rejected") .. " deferred!", 2);
				end
				p._progd = p._progd or {};
				table.insert(p._progd, {...});
				for _, f in pairs(p._progs) do
						f(...);
				end
				return self;
		end;

		_init = function(self)
				self._promise = new(promise);
		end;

		Promise = function(self) return self._promise; end;

		-- Proxies
		_IsPromise = true;
		Then = function(self, ...) return self._promise:Then(...); end;
		Done = function(self, ...) self._promise:Done(...); return self; end;
		Fail = function(self, ...) self._promise:Fail(...); return self; end;
		Progress = function(self, ...) self._promise:Progress(...); return self; end;
		Always = function(self, ...) self._promise:Always(...); return self; end;
};

function Deferred()
		return new(deferred);
end

function getPromiseState( promise )
	if promise and promise._IsDeferred then
		return promise._promise._state
	elseif promise and ( promise._IsPromise or promise._promise ) then
		return promise._state
	else
		debug.Trace( )
		error( "Invalid object passed to getPromiseState(expected deferred/promise got " .. type( promise ) ..")" )
	end
end

--Kamshak

-- Waits for all promises to be finished, when one errors it rejects, else it returns the results in order
function WhenAllFinished( tblPromises, options )
	local def = Deferred( )
	local results = {}
	local options = options or {}

	if #tblPromises == 0 then
		if options.noUnpack then
			def:Resolve({})
		else
			def:Resolve()
		end
		return def:Promise( )
	end

	--Add result fetching Done funcs first
	--to make sure that instant returning promises are fetched correctly
	for k, v in pairs( tblPromises ) do
		v:Done( function( ... )
			local args = {...}
			if #args > 1 then
				results[k] = args
			else
				results[k] = args[1]
			end
		end )
	end

	for k, v in pairs( tblPromises ) do
		v:Done( function( )
			if def._promise._state == 'fail' or def._promise._state == 'done' then --might have errored or finished already
				return
			end
			local allDone = true
			for _, promise in pairs( tblPromises ) do
				if promise == v then continue end
				if promise._state == 'pending' then
					allDone = false
				end
			end
			if allDone then
				if options.noUnpack then
					def:Resolve( results )
				else
					def:Resolve( unpack( results ) )
				end
			end
		end )
		v:Fail( function( ... )
			if def._promise._state == 'pending' then
				def:Reject( ... )
			end
		end )
	end
	return def:Promise( ), def
end

Promise = {}

function Promise.Reject( ... )
	local def = Deferred( )

	local args = { ... }
	LibK.GLib.Threading.Thread():Start( function()
		def:Reject( unpack( args ) )
	end )

	return def:Promise()
end

function ispromise( val )
		return val and istable(val) and ( val._IsDeferred or val._IsPromise )
end

-- Maps promises to results and resolves to the map when finished
function Promise.Map( tbl, mapFn )
	local opts = opts or {}
		local promises = {}
		for k, v in pairs( tbl ) do
				local promise = Promise.Resolve()
				:Then( function( )
						if ispromise( v ) then
								return v:Then( mapFn )
						end
						return mapFn( v )
				end )

				table.insert( promises, promise )
		end

		return WhenAllFinished( promises, { noUnpack = true } )
end

function Promise.Wrap( valueOrPromise )
	if ispromise( valueOrPromise ) then
		return valueOrPromise
	end
	return Promise.Resolve( valueOrPromise )
end

function Promise.Filter( tbl, filterFn )
	local promises = {}
		for k, v in ipairs( tbl ) do
		local promise = Promise.Wrap( v ):Then( function( resolved )
			local result = filterFn( resolved )
			return Promise.Wrap( result ):Then( function( included )
				return {
					included = included,
					value = resolved
				}
			end )
		end )

				table.insert( promises, promise )
		end

	return WhenAllFinished( promises, { noUnpack = true } ):Then( function( results )
		return LibK._(results):chain():filter( function( result )
			return result.included
		end ):pluck( "value" ):value()
	end )
end

function Promise.Resolve( ... )
	local def = Deferred( )
	def:Resolve( ... )
	return def:Promise()
end

-- Delay the calling of a function or resolving of a value through a promise.
function Promise.Delay( delay, funcOrValue )
		local def = Deferred( )
		timer.Simple( delay, function( )
				if type(funcOrValue) == "function" then
						-- CAll the function and forward results. If the function returns a promise wait for completion and handle resolve and reject
						local results = {funcOrValue()}
						if #results == 1 and ispromise( results[1] ) then
								results[1]:Then( function( ... )
										def:Resolve( ... )
								end, function( ... )
										def:Reject( ... )
								end )
						end
						def:Resolve( unpack( results ) )
				else
						def:Resolve( funcOrValue )
				end
		end )
		return def:Promise( )
end


--method one of easing.*
--duration is duration
--callback is function callback( progress ) progress is float between 0 and 1
function tween( method, duration, callback )
	local def = Deferred( )

	local tweenInstance = {
		method = method,
		update = function(self)
			local elapsed = RealTime( ) - self.begin
			local progress = self.method( elapsed, 0, 1, self.duration )
			progress = math.Clamp( progress, 0, 1 ) --clamp to valid range
			self.callback( progress )
			if elapsed >= self.duration then
				if getPromiseState(self.def) == 'pending' then
					self.def:Resolve( )
				end
				return true
			end
		end,
		begin = RealTime( ),
		duration = duration,
		callback = callback,
		def = def
	}
	table.insert( tweens, tweenInstance )

	return def:Promise( ), tweenInstance
end
