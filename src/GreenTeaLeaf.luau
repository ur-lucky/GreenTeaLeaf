--!strict

type PrimitiveKind =
	"nil"
	| "boolean"
	| "number"
	| "string"
	| "table"
	| "function"
	| "thread"
	| "userdata"
	| "vector"
	| "buffer"

type RangeInput = string | number | {
	min: number?,
	minExclusive: boolean?,
	max: number?,
	maxExclusive: boolean?,
}

type Pack = { n: number, [number]: unknown }

type function ValueOf(schema: type)
	if schema:is("table") then
		local phantom = schema:readproperty(types.singleton("__type"))
		if phantom and phantom:is("function") then
			local returns = phantom:returns()
			if returns.head and returns.head[1] then
				return returns.head[1]
			end
		end

		local member = schema:readproperty(types.singleton("type"))
		if member and member:is("function") then
			local returns = member:returns()
			if returns.head and returns.head[1] then
				return returns.head[1]
			end
		end
	end

	return schema
end

type function StructOf(shape: type)
	if not shape:is("table") then
		return types.unknown
	end

	local result = types.newtable()
	for key, property in shape:properties() do
		local value = property.read or property.write
		if value then
			result:setproperty(key, ValueOf(value))
		end
	end

	return result
end

type function Union2(a: type, b: type)
	return types.unionof(ValueOf(a), ValueOf(b))
end

type function Union3(a: type, b: type, c: type)
	return types.unionof(ValueOf(a), ValueOf(b), ValueOf(c))
end

type function Union4(a: type, b: type, c: type, d: type)
	return types.unionof(ValueOf(a), ValueOf(b), ValueOf(c), ValueOf(d))
end

type function Union5(a: type, b: type, c: type, d: type, e: type)
	return types.unionof(ValueOf(a), ValueOf(b), ValueOf(c), ValueOf(d), ValueOf(e))
end

type function Intersection2(a: type, b: type)
	return types.intersectionof(ValueOf(a), ValueOf(b))
end

type function Intersection3(a: type, b: type, c: type)
	return types.intersectionof(ValueOf(a), ValueOf(b), ValueOf(c))
end

type function Intersection4(a: type, b: type, c: type, d: type)
	return types.intersectionof(ValueOf(a), ValueOf(b), ValueOf(c), ValueOf(d))
end

type function Intersection5(a: type, b: type, c: type, d: type, e: type)
	return types.intersectionof(ValueOf(a), ValueOf(b), ValueOf(c), ValueOf(d), ValueOf(e))
end

type function OptionalOf(schema: type)
	return types.optional(ValueOf(schema))
end

type function StripLiteralSentinel(values: type)
	local sentinel = types.singleton("__GreenTeaLeafLiteralInferenceSentinel")

	if values.tag ~= "union" then
		if values.tag == "singleton" and values:value() == sentinel:value() then
			return types.never
		end

		return values
	end

	local members = {} :: { type }
	for _, value in values:components() do
		if value.tag == "singleton" and value:value() == sentinel:value() then
			continue
		end

		table.insert(members, value)
	end

	if members[1] == nil then
		return types.never
	elseif members[2] == nil then
		return members[1]
	end

	return types.unionof(unpack(members))
end

--- @class GreenTeaLeaf
---
--- @class Type
--- Represents a type we can check against or inspect.\
--- Use the methods to check against the type.\
--- Use the properties to inspect the type.
---
--- @type Range { min: number?, minExclusive: boolean, max: number?, maxExclusive: boolean }
--- @within Type
---
--- @type RangeInput string | number | { min: number?, minExclusive: boolean?, max: number?, maxExclusive: boolean? }
--- @within GreenTeaLeaf
--- A value that can be parsed as a range.\
--- As a string, can be "[min, max]", "(min, max)", "(min, max]", "(, max]" etc. or a number max inclusive.
--- As a number, it's interpreted as a number max inclusive.
---
--- @type Cause { ok: boolean, errs: { { type: any, input: any?, message: string? } }, formatErr: (self: Cause) -> string }
--- @within Type
--- Represents the result of a :matches() call.
---
--- @within Type
--- @prop kind string
---
--- @within Type
--- @prop meta { [string]: any }?
--- Contains user-specified metadata about the type.
---
--- @within Type
--- @prop basic { typeof: string? }?
---
--- @within Type
--- @prop any { allowNil: boolean? }?
---
--- @within Type
--- @prop unknown { allowNil: boolean? }?
---
--- @within Type
--- @prop custom { type: Type?, name: string, typechecker: (any) -> (boolean, any?) }?
---
--- @within Type
--- @prop number { range: Range?, integer: boolean? }?
---
--- @within Type
--- @prop string { pattern: string?, bytes: Range?, graphemes: Range?, unicode: boolean? }?
---
--- @within Type
--- @prop thread { status: { [string]: boolean }? }?
---
--- @within Type
--- @prop instanceIsA { class: string }?
---
--- @within Type
--- @prop literal { value: any }?
---
--- @within Type
--- @prop tuple { contents: { Type }, vararg: Type? }?
---
--- @within Type
--- @prop vararg { type: Type, length: Range? }?
---
--- @within Type
--- @prop fn { args: Type, returns: Type }?
---
--- @within Type
--- @prop table { contents: { [string]: Type }, indexer: { key: Type, value: Type }, array: boolean?, count: Range?, raw: boolean? }?
---
--- @within Type
--- @prop intersection { contents: { Type } }?
---
--- @within Type
--- @prop union { contents: { Type }, optional: boolean? }?
export type Range = {
	min: number?,
	minExclusive: boolean,
	max: number?,
	maxExclusive: boolean,
}

export type ErrorInfo = {
	type: unknown?,
	input: unknown,
	message: string,
	path: string?,
	verbatim: boolean?,
}

export type Cause = {
	ok: boolean,
	errs: { ErrorInfo },
	formatErr: (self: Cause) -> string,
}

export type Type<T = unknown> = {
	kind: string,
	meta: { [string]: unknown }?,
	__type: () -> T,

	basic: unknown?,
	any: unknown?,
	unknown: unknown?,
	custom: unknown?,
	number: unknown?,
	string: unknown?,
	thread: unknown?,
	instanceIsA: unknown?,
	literal: unknown?,
	tuple: unknown?,
	vararg: unknown?,
	fn: unknown?,
	table: unknown?,
	intersection: unknown?,
	union: unknown?,

	matches: (self: unknown, ...unknown) -> (boolean, Cause),
	assert: (self: unknown, ...unknown) -> T,
	format: (self: unknown) -> string,
	type: (self: unknown) -> T,
}

export type BuiltType<T = unknown> = Type<T>
export type TuplePacked<T...> = () -> T...

type Matcher = (pack: Pack) -> Cause
type TupleRole = "argument" | "return"

type Internal = {
	_greenTeaLeafType: true,
	_matches: Matcher,
	_format: string,
	_basicTypeof: PrimitiveKind?,
	_fnInfo: { args: RuntimeType<unknown>, returns: RuntimeType<unknown> }?,
	_tupleRole: TupleRole?,
}
type RuntimeType<T = unknown> = Type<T> & Internal

local GreenTeaLeaf = {}

local MAX_RECEIVED_DISPLAY = 80

local function formatReceived(input: unknown): string
	if input == nil then
		return "nil"
	end

	local luauType = typeof(input)
	if luauType == "string" then
		local text = input :: string
		if #text > MAX_RECEIVED_DISPLAY then
			text = string.sub(text, 1, MAX_RECEIVED_DISPLAY - 3) .. "..."
		end
		return `string {string.format("%q", text)}`
	elseif luauType == "number" then
		local value = input :: number
		if value ~= value then
			return "number NaN"
		end
		if value == math.huge then
			return "number inf"
		end
		if value == -math.huge then
			return "number -inf"
		end
		return `number {value}`
	elseif luauType == "boolean" then
		return `boolean {tostring(input)}`
	elseif luauType == "table" then
		local record = input :: { [unknown]: unknown }
		local arrayLength = #record
		local entryCount = 0
		for _ in record do
			entryCount += 1
		end
		if arrayLength > 0 and arrayLength == entryCount then
			if arrayLength <= 4 then
				local parts: { string } = {}
				for index = 1, arrayLength do
					table.insert(parts, formatReceived(record[index]))
				end
				return `[{table.concat(parts, ", ")}]`
			end
			return `array [{arrayLength}]`
		end
		return `table ({entryCount} keys)`
	elseif luauType == "function" then
		return "function"
	elseif luauType == "buffer" then
		return "buffer"
	elseif luauType == "thread" then
		return "thread"
	end

	local robloxType = type(input)
	if robloxType ~= "userdata" and robloxType ~= luauType then
		local ok, asString = pcall(function()
			return tostring(input)
		end)
		if ok and asString ~= "" and asString ~= robloxType then
			if #asString > MAX_RECEIVED_DISPLAY then
				asString = string.sub(asString, 1, MAX_RECEIVED_DISPLAY - 3) .. "..."
			end
			return `{robloxType} {asString}`
		end
		return robloxType
	end

	return luauType
end

local function extendPath(outer: string, inner: string?): string
	if inner == nil or inner == "" then
		return outer
	end
	return `{outer} > {inner}`
end

local SKIP_ERROR_MESSAGES: { [string]: boolean } = {
	["did not match any union member"] = true,
	["table did not match"] = true,
	["did not match every intersection member"] = true,
	["did not match any literal"] = true,
}

local function trimPathPart(part: string): string
	return (string.match(part, "^%s*(.-)%s*$") :: string?) or part
end

local function splitPath(path: string): { string }
	local parts: { string } = {}
	for part in string.gmatch(path, "[^>]+") do
		table.insert(parts, trimPathPart(part))
	end
	return parts
end

local function receivedType(input: unknown): string
	if input == nil then
		return "nil"
	end

	local luauType = typeof(input)
	if luauType == "table" then
		local record = input :: { [unknown]: unknown }
		if #record > 0 then
			return "table"
		end
	end

	local robloxType = type(input)
	if robloxType ~= "userdata" and robloxType ~= luauType then
		return robloxType
	end

	return luauType
end

local function expectedFromMessage(message: string): string
	if string.sub(message, 1, 9) == "expected " then
		return string.sub(message, 10)
	end
	return message
end

local function formatReceivedWithValue(input: unknown): string
	if input == nil then
		return "nil"
	end

	local kind = receivedType(input)
	if typeof(input) == "string" then
		return `string ({string.format("%q", input :: string)})`
	end

	return `{kind} ({tostring(input)})`
end

local function formatExpectedGot(info: ErrorInfo): string
	if info.verbatim == true then
		if string.find(info.message, " literal", 1, true) then
			return `{info.message}, got {formatReceivedWithValue(info.input)}`
		end
		return `{info.message}, got {receivedType(info.input)}`
	end

	local got = string.find(info.message, " got ", 1, true)
	if got then
		local expectedPart = string.sub(info.message, 1, got - 1)
		local gotPart = string.sub(info.message, got + 5)
		if string.sub(expectedPart, -9) == " expected" then
			expectedPart = string.sub(expectedPart, 1, -10)
		end
		return `{expectedPart} expected, got {gotPart}`
	end

	return `{expectedFromMessage(info.message)} expected, got {receivedType(info.input)}`
end

local function pathDepth(path: string?): number
	if path == nil or path == "" then
		return 0
	end

	local depth = 1
	for _ in string.gmatch(path, ">") do
		depth += 1
	end
	return depth
end

local function pickPrimaryError(errs: { ErrorInfo }): ErrorInfo
	local best: ErrorInfo = errs[1]
	local bestDepth = pathDepth(best.path)

	for index = 2, #errs do
		local info = errs[index]
		if SKIP_ERROR_MESSAGES[info.message] then
			continue
		end

		local depth = pathDepth(info.path)
		if depth > bestDepth or (depth == bestDepth and SKIP_ERROR_MESSAGES[best.message]) then
			best = info
			bestDepth = depth
		end
	end

	if SKIP_ERROR_MESSAGES[best.message] then
		for _, info in errs do
			if not SKIP_ERROR_MESSAGES[info.message] then
				return info
			end
		end
	end

	return best
end

local function formatRobloxError(info: ErrorInfo): string
	local optional = false
	local array = false
	local location: string? = nil
	local arrayIndex: number? = nil
	local fieldKey: string? = nil

	if info.path then
		for _, part in splitPath(info.path) do
			local returnIndex = string.match(part, "^return #(%d+)$")
			if returnIndex then
				location = `Bad return #{returnIndex}`
				continue
			end

			local argumentIndex = string.match(part, "^argument #(%d+)$")
			if argumentIndex then
				location = `Bad argument #{argumentIndex}`
				continue
			end

			local tupleIndex = string.match(part, "^tuple #(%d+)$")
				or string.match(part, "^tuple index #(%d+)$")
				or string.match(part, "^tuple index (%d+)$")
			if tupleIndex then
				location = `Bad tuple #{tupleIndex}`
				continue
			end

			if string.sub(part, 1, 3) == "as " then
				local typeDesc = string.sub(part, 4)
				if string.sub(typeDesc, -1) == "?" then
					optional = true
				end
				if string.find(typeDesc, "array<", 1, true) == 1 then
					array = true
				end
				continue
			end

			local indexNumber = string.match(part, "^index #(%d+)$") or string.match(part, "^index %[(%d+)%]$")
			if indexNumber then
				arrayIndex = tonumber(indexNumber)
				array = true
				continue
			end

			local fieldName = string.match(part, '^field "(.+)"$')
			if fieldName then
				fieldKey = fieldName
			end
		end
	end

	local core = formatExpectedGot(info)
	if optional then
		core = `(optional) {core}`
	end
	if array then
		core = `[array] {core}`
	end

	if location then
		if fieldKey ~= nil then
			return `{location}:\n\tbad value for key {fieldKey}:\n\t\t{core}`
		end
		if arrayIndex ~= nil then
			return `{location} index #{arrayIndex}:\n\t{core}`
		end
		return `{location}:\n\t{core}`
	end

	if fieldKey ~= nil then
		return `bad value for key {fieldKey}:\n\t{core}`
	end

	return core
end

local function formatCause(self: Cause): string
	if self.ok then
		return "input matched type"
	end

	return formatRobloxError(pickPrimaryError(self.errs))
end

local function makeCause(okValue: boolean, errs: { ErrorInfo }): Cause
	return {
		ok = okValue,
		errs = errs,
		formatErr = function(self: Cause): string
			return formatCause(self)
		end,
	}
end

local function qualifyCause(cause: Cause, segment: string): Cause
	if cause.ok then
		return cause
	end

	local newErrs: { ErrorInfo } = {}
	for _, errorInfo in cause.errs do
		table.insert(newErrs, {
			type = errorInfo.type,
			input = errorInfo.input,
			message = errorInfo.message,
			path = extendPath(segment, errorInfo.path),
			verbatim = errorInfo.verbatim,
		})
	end

	return makeCause(false, newErrs)
end

local function ok(): Cause
	return makeCause(true, {})
end

local function err(typeObject: Type<unknown>?, input: unknown, message: string, verbatim: boolean?): Cause
	return makeCause(false, {
		{
			type = typeObject,
			input = input,
			message = message,
			path = nil,
			verbatim = verbatim,
		},
	})
end

local function errVerbatim(input: unknown, message: string): Cause
	return err(nil, input, message, true)
end

local function literalExpectedLabel(schemas: { RuntimeType<unknown> }): string
	local firstKind: string? = nil

	for _, schema in schemas do
		if schema.literal == nil then
			return "literal"
		end

		local kind = typeof((schema.literal :: { value: unknown }).value)
		if firstKind == nil then
			firstKind = kind
		elseif firstKind ~= kind then
			return "literal"
		end
	end

	return if firstKind then `{firstKind} literal` else "literal"
end

local function isLiteralUnion(contents: { RuntimeType<unknown> }): boolean
	if #contents == 0 then
		return false
	end

	for _, schema in contents do
		if schema.literal == nil then
			return false
		end
	end
	return true
end

local function mergeErrs(message: string, typeObject: Type<unknown>?, input: unknown, causes: { Cause }): Cause
	local errs: { ErrorInfo } = {
		{
			type = typeObject,
			input = input,
			message = message,
			path = nil,
			verbatim = nil,
		},
	}

	for _, cause in causes do
		for _, errorInfo in cause.errs do
			table.insert(errs, errorInfo)
		end
	end

	return makeCause(false, errs)
end

local function matchesType(self: unknown, ...: unknown): (boolean, Cause)
	local runtime = (self :: unknown) :: RuntimeType<unknown>
	local cause = runtime._matches(table.pack(...))
	return cause.ok, cause
end

local function assertType<T>(self: unknown, ...: unknown): T
	local runtime = (self :: unknown) :: Type<T>
	local packed = table.pack(...)
	local success, cause = runtime:matches(table.unpack(packed, 1, packed.n))
	if not success then
		error(cause:formatErr(), 2)
	end

	return packed[1] :: T
end

local function formatType(self: unknown): string
	return ((self :: unknown) :: RuntimeType<unknown>)._format
end

local function phantomType<T>(_self: unknown): T
	error("GreenTeaLeaf.type() is compile-time only; use typeof(schema:type())", 2)
end

local function phantomValue<T>(): T
	error("GreenTeaLeaf.__type() is compile-time only; use typeof(schema:type())", 2)
end

local function makeType(kind: string, format: string, matcher: Matcher): RuntimeType<unknown>
	local runtime: RuntimeType<unknown> = {
		_greenTeaLeafType = true,
		kind = kind,
		_matches = matcher,
		_format = format,
		_basicTypeof = nil,
		_fnInfo = nil,
		_tupleRole = nil,
		__type = phantomValue,
		matches = matchesType,
		assert = assertType,
		format = formatType,
		type = phantomType,
	}

	return runtime
end

local function isTypeObject(value: unknown): boolean
	if typeof(value) ~= "table" then
		return false
	end

	local record = value :: { [string]: unknown }
	return record._greenTeaLeafType == true
end

local function asRuntime(value: unknown): RuntimeType<unknown>
	if isTypeObject(value) then
		return (value :: unknown) :: RuntimeType<unknown>
	end

	return (GreenTeaLeaf.typeof(value) :: unknown) :: RuntimeType<unknown>
end

local function describeType(schema: RuntimeType<unknown>): string
	if schema._basicTypeof == "nil" then
		return "nil"
	end

	if schema.literal ~= nil then
		return `literal {tostring((schema.literal :: { value: unknown }).value)}`
	end

	if schema.number ~= nil then
		if (schema.number :: { integer: boolean? }).integer == true then
			return "integer"
		end
		return "number"
	end

	if schema.string ~= nil then
		return "string"
	end

	if schema.table ~= nil then
		local tableInfo = schema.table :: {
			array: boolean?,
			indexer: { key: RuntimeType<unknown>, value: RuntimeType<unknown> }?,
		}
		if tableInfo.array and tableInfo.indexer ~= nil then
			return `array<{describeType(tableInfo.indexer.value)}>`
		end
		if tableInfo.indexer ~= nil then
			return `dictionary<{describeType(tableInfo.indexer.key)}, {describeType(tableInfo.indexer.value)}>`
		end
		return "table"
	end

	if schema.fn ~= nil then
		return "function"
	end

	if schema.tuple ~= nil then
		return "tuple"
	end

	if schema.union ~= nil then
		local unionInfo = schema.union :: { contents: { Type<unknown> }, optional: boolean? }
		if unionInfo.optional == true then
			for _, member in unionInfo.contents do
				local runtime = asRuntime(member)
				if runtime._basicTypeof ~= "nil" then
					return `{describeType(runtime)}?`
				end
			end
		end
		return "union"
	end

	return schema:format()
end

local function singlePack(value: unknown): Pack
	return { value, n = 1 }
end

local function parseNumber(text: string): number?
	if text == "inf" or text == "+inf" then
		return math.huge
	elseif text == "-inf" then
		return -math.huge
	end

	return tonumber(text)
end

local function parseRange(input: RangeInput?): Range?
	if input == nil then
		return nil
	end

	if typeof(input) == "number" then
		return {
			min = nil,
			minExclusive = false,
			max = input,
			maxExclusive = false,
		}
	end

	if typeof(input) == "table" then
		local rangeInput = input :: {
			min: number?,
			minExclusive: boolean?,
			max: number?,
			maxExclusive: boolean?,
		}

		return {
			min = rangeInput.min,
			minExclusive = rangeInput.minExclusive == true,
			max = rangeInput.max,
			maxExclusive = rangeInput.maxExclusive == true,
		}
	end

	local text = input :: string
	local left = string.sub(text, 1, 1)
	local right = string.sub(text, #text, #text)
	local body = string.sub(text, 2, #text - 1)
	local comma = string.find(body, ",", 1, true)

	if comma == nil then
		error(`invalid range: {text}`, 3)
	end

	local minText = string.gsub(string.sub(body, 1, comma - 1), "%s+", "")
	local maxText = string.gsub(string.sub(body, comma + 1), "%s+", "")

	return {
		min = if minText == "" then nil else parseNumber(minText),
		minExclusive = left == "(",
		max = if maxText == "" then nil else parseNumber(maxText),
		maxExclusive = right == ")",
	}
end

local function inRange(value: number, range: Range?): boolean
	if range == nil then
		return true
	end

	if range.min ~= nil then
		if range.minExclusive then
			if value <= range.min then
				return false
			end
		elseif value < range.min then
			return false
		end
	end

	if range.max ~= nil then
		if range.maxExclusive then
			if value >= range.max then
				return false
			end
		elseif value > range.max then
			return false
		end
	end

	return true
end

local function basic(kind: PrimitiveKind): RuntimeType<unknown>
	local schema: RuntimeType<unknown> = makeType(kind, kind, function(pack)
		local input = pack[1]
		if kind == "nil" then
			return if input == nil then ok() else err(nil, input, "expected nil")
		end

		return if typeof(input) == kind then ok() else err(nil, input, `expected {kind}`)
	end)

	schema.basic = { typeof = kind }
	schema._basicTypeof = kind
	return schema
end

function GreenTeaLeaf.__newBasicType(kind: PrimitiveKind): Type<unknown>
	return basic(kind)
end

--- Returns whether or not the input value is a GreenTeaLeaf.Type object.
function GreenTeaLeaf.isGreenTeaLeafType(value: unknown): boolean
	return isTypeObject(value)
end

GreenTeaLeaf.isGtType = GreenTeaLeaf.isGreenTeaLeafType

--- Creates a new GreenTeaLeaf Type that matches any value, excluding nil.
function GreenTeaLeaf.any(options: { allowNil: boolean? }?): Type<any>
	local allowNil = if options then options.allowNil == true else false
	local schema = (
		makeType("any", if allowNil then "any?" else "any", function(pack)
			local input = pack[1]
			return if input == nil and not allowNil then err(nil, input, "expected non-nil value") else ok()
		end) :: unknown
	) :: RuntimeType<any>

	schema.any = { allowNil = allowNil }
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches any value, excluding nil.\
--- This returns the unknown type, which has different behavior from any.\
--- The runtime typechecking behavior is the same as GreenTeaLeaf.any.
function GreenTeaLeaf.unknown(options: { allowNil: boolean? }?): Type<unknown>
	local allowNil = if options then options.allowNil == true else false
	local schema: RuntimeType<unknown> = makeType("unknown", if allowNil then "unknown?" else "unknown", function(pack)
		local input = pack[1]
		return if input == nil and not allowNil then err(nil, input, "expected non-nil value") else ok()
	end)

	schema.unknown = { allowNil = allowNil }
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches no values.
function GreenTeaLeaf.never(): Type<never>
	local schema = (
		makeType("never", "never", function(pack)
			return err(nil, pack[1], "expected never")
		end) :: unknown
	) :: RuntimeType<never>
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches boolean values.
function GreenTeaLeaf.boolean(): Type<boolean>
	return (basic("boolean") :: unknown) :: RuntimeType<boolean>
end

GreenTeaLeaf.bool = GreenTeaLeaf.boolean

--- Creates a new GreenTeaLeaf Type that matches nil values.
function GreenTeaLeaf.none(): Type<nil>
	return (basic("nil") :: unknown) :: RuntimeType<nil>
end

--- Creates a new GreenTeaLeaf Type that matches number values.\
--- Optionally, you can specify a range and whether the number must be an integer.\
--- Regardless of specified limits, the returned Luau type will be a basic number. Limit checking will only be done at runtime.
function GreenTeaLeaf.number(limits: {
	range: RangeInput?,
	integer: boolean?,
	nan: boolean?,
}?): Type<number>
	local range = if limits then parseRange(limits.range) else nil
	local integer = if limits then limits.integer == true else false
	local nan = if limits then limits.nan == true else false

	local schema = (
		makeType("number", "number", function(pack)
			local input = pack[1]
			if typeof(input) ~= "number" then
				return err(nil, input, "expected number")
			end

			local value = input :: number
			if value ~= value then
				return if nan then ok() else err(nil, input, "expected number, got NaN")
			end

			if integer and value % 1 ~= 0 then
				return err(nil, input, "expected integer")
			end

			if not inRange(value, range) then
				return err(nil, input, "expected number in range")
			end

			return ok()
		end) :: unknown
	) :: RuntimeType<number>

	schema.number = { range = range, integer = integer, nan = nan }
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches string values.\
--- Optionally, you can specify a pattern, a length range, and whether the string must be utf8.
function GreenTeaLeaf.string(limits: {
	pattern: string?,
	bytes: RangeInput?,
	graphemes: RangeInput?,
	unicode: boolean?,
}?): Type<string>
	local bytes = if limits then parseRange(limits.bytes) else nil
	local pattern = if limits then limits.pattern else nil

	local schema = (
		makeType("string", "string", function(pack)
			local input = pack[1]
			if typeof(input) ~= "string" then
				return err(nil, input, "expected string")
			end

			local value = input :: string
			if pattern ~= nil and string.match(value, pattern) == nil then
				return err(nil, input, `expected string matching {pattern}`)
			end

			if not inRange(#value, bytes) then
				return err(nil, input, "expected string byte length in range")
			end

			return ok()
		end) :: unknown
	) :: RuntimeType<string>

	schema.string = {
		pattern = pattern,
		bytes = bytes,
		graphemes = if limits then parseRange(limits.graphemes) else nil,
		unicode = if limits then limits.unicode else nil,
	}
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches a value literally.\
--- This is checked with a basic == comparison.
function GreenTeaLeaf.literal<T>(value: T | "__GreenTeaLeafLiteralInferenceSentinel"): Type<StripLiteralSentinel<T>>
	local schema = (
		makeType("literal", tostring(value), function(pack)
			local input = pack[1]
			return if input == value
				then ok()
				else errVerbatim(input, `expected {typeof(value)} literal`)
		end) :: unknown
	) :: RuntimeType<StripLiteralSentinel<T>>

	schema.literal = { value = value }
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches one of several literal values.\
--- This is especially useful for preserving string literal unions from an array literal.
function GreenTeaLeaf.literals<T>(values: { T } | { "__GreenTeaLeafLiteralInferenceSentinel" }): Type<StripLiteralSentinel<T>>
	assert(typeof(values) == "table", "literals must receive an array of literal values")

	local contents: { RuntimeType<unknown> } = {}
	local exportedContents: { Type<unknown> } = {}

	for _, value in values :: { [unknown]: unknown } do
		local schema = asRuntime(GreenTeaLeaf.literal(value))
		contents[#contents + 1] = schema
		exportedContents[#exportedContents + 1] = schema
	end

	assert(#contents > 0, "literals must contain at least one value")

	local result = (
		makeType("union", "literals", function(pack)
			local causes: { Cause } = {}
			for _, schema in contents do
				local cause = schema._matches(pack)
				if cause.ok then
					return cause
				end
				table.insert(causes, qualifyCause(cause, `as {describeType(schema)}`))
			end

			return errVerbatim(pack[1], `expected {literalExpectedLabel(contents)}`)
		end) :: unknown
	) :: RuntimeType<StripLiteralSentinel<T>>

	result.union = { contents = exportedContents, optional = false }
	return result
end

GreenTeaLeaf.literalUnion = GreenTeaLeaf.literals
GreenTeaLeaf.oneOfLiterals = GreenTeaLeaf.literals

--- Creates a new GreenTeaLeaf Type that matches any `typeof(value)` type.
function GreenTeaLeaf.isTypeof(typeName: PrimitiveKind | string): Type<unknown>
	local schema: RuntimeType<unknown> = makeType("basic", typeName, function(pack)
		local input = pack[1]
		return if typeof(input) == typeName then ok() else err(nil, input, `expected typeof {typeName}`)
	end)

	schema.basic = { typeof = typeName :: PrimitiveKind }
	schema._basicTypeof = typeName :: PrimitiveKind
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches any `type(value)` type.
function GreenTeaLeaf.isType(typeName: PrimitiveKind | string): Type<unknown>
	local schema: RuntimeType<unknown> = makeType("basic", typeName, function(pack)
		local input = pack[1]
		return if type(input) == typeName then ok() else err(nil, input, `expected type {typeName}`)
	end)
	return schema
end

--- Creates a new GreenTeaLeaf Type that matches a custom typechecker
--- with a GreenTeaLeaf type as a base.
function GreenTeaLeaf.withCustom<T>(schema: Type<T>, typechecker: (unknown) -> (boolean, unknown?), name: string?): Type<T>
	local inner = asRuntime(schema)
	local typeName = name or "custom"

	local custom = (
		makeType("custom", typeName, function(pack)
			local innerCause = inner._matches(pack)
			if not innerCause.ok then
				return innerCause
			end

			local success, message = typechecker(pack[1])
			return if success
				then ok()
				else err(nil, pack[1], if message == nil then `expected {typeName}` else tostring(message))
		end) :: unknown
	) :: RuntimeType<T>

	custom.custom = { type = inner, name = typeName, typechecker = typechecker }
	return custom
end

--- Creates a new GreenTeaLeaf Type that matches a custom typechecker
--- with `unknown` as the base type.
function GreenTeaLeaf.custom(typechecker: (unknown) -> (boolean, unknown?), name: string?): Type<unknown>
	return GreenTeaLeaf.withCustom(GreenTeaLeaf.unknown { allowNil = true }, typechecker, name)
end

--- Creates a new GreenTeaLeaf Type that matches coroutine values.
function GreenTeaLeaf.thread(options: { status: string | { string } | nil }?): Type<thread>
	local allowed: { [string]: boolean }? = nil
	if options and options.status ~= nil then
		allowed = {}
		if typeof(options.status) == "table" then
			for _, status in options.status :: { string } do
				allowed[status] = true
			end
		else
			allowed[options.status :: string] = true
		end
	end

	local schema = (
		makeType("thread", "thread", function(pack)
			local input = pack[1]
			if typeof(input) ~= "thread" then
				return err(nil, input, "expected thread")
			end

			if allowed == nil then
				return ok()
			end

			local status = coroutine.status(input :: thread)
			return if allowed[status] then ok() else err(nil, input, `expected thread status {status}`)
		end) :: unknown
	) :: RuntimeType<thread>

	schema.thread = { status = allowed }
	return schema
end

GreenTeaLeaf.coroutine = GreenTeaLeaf.thread

--- Creates a new GreenTeaLeaf Type that matches buffer values.
function GreenTeaLeaf.buffer(): Type<buffer>
	return (basic("buffer") :: unknown) :: RuntimeType<buffer>
end

function GreenTeaLeaf.userdata(): Type<unknown>
	return basic("userdata")
end

--- Creates a new GreenTeaLeaf Type that matches a repeating value.
function GreenTeaLeaf.vararg<T>(schema: Type<T>, options: { count: RangeInput? }?): Type<T>
	local inner = asRuntime(schema)
	local count = if options then parseRange(options.count) else nil

	local result = (
		makeType("vararg", `...{inner:format()}`, function(pack)
			if not inRange(pack.n, count) then
				return err(nil, pack.n, "expected vararg count in range")
			end

			for index = 1, pack.n do
				local cause = inner._matches(singlePack(pack[index]))
				if not cause.ok then
					return qualifyCause(cause, `element {index}`)
				end
			end

			return ok()
		end) :: unknown
	) :: RuntimeType<T>

	result.vararg = { type = inner, length = count }
	return result
end

local function tupleLocationSegment(index: number, role: TupleRole?): string
	if role == "return" then
		return `return #{index}`
	end
	if role == "argument" then
		return `argument #{index}`
	end
	return `tuple #{index}`
end

local function tupleWithRole(role: TupleRole?, ...: unknown): Type<unknown>
	local packed = table.pack(...)
	local contents: { RuntimeType<unknown> } = {}
	local varargType: RuntimeType<unknown>? = nil

	for index = 1, packed.n do
		local schema = asRuntime(packed[index])
		if schema.vararg ~= nil then
			varargType = schema
		else
			table.insert(contents, schema)
		end
	end

	local minimumCount = #contents
	while minimumCount > 0 do
		local schema = contents[minimumCount]
		if schema.union == nil or not ((schema.union :: { optional: boolean? }).optional == true) then
			break
		end
		minimumCount -= 1
	end

	local result: RuntimeType<unknown> = makeType("tuple", "tuple", function(pack)
		if varargType == nil and pack.n > #contents then
			return qualifyCause(err(nil, pack[#contents + 1], "unexpected value"), tupleLocationSegment(#contents + 1, role))
		end

		for index, schema in contents do
			local cause = schema._matches(singlePack(pack[index]))
			if not cause.ok then
				return qualifyCause(cause, tupleLocationSegment(index, role))
			end
		end

		if varargType ~= nil then
			for index = #contents + 1, pack.n do
				local cause = varargType._matches(singlePack(pack[index]))
				if not cause.ok then
					return qualifyCause(cause, tupleLocationSegment(index, role))
				end
			end
		end

		return ok()
	end)

	result.tuple = { contents = contents, vararg = varargType }
	result._tupleRole = role
	return result
end

--- Creates a new GreenTeaLeaf Type that matches a tuple of values.\
--- Specify the final value with GreenTeaLeaf.vararg to match a repeating final value.
function GreenTeaLeaf.tuple(...: unknown): Type<unknown>
	return tupleWithRole(nil, ...)
end

--- Used for GreenTeaLeaf.fn only. This is used to pass args to GreenTeaLeaf.fn ergonomically.
function GreenTeaLeaf.args(...: unknown): Type<unknown>
	return tupleWithRole("argument", ...)
end

--- Used for GreenTeaLeaf.fn only. This is used to pass returns to GreenTeaLeaf.fn ergonomically.
function GreenTeaLeaf.returns(...: unknown): Type<unknown>
	return tupleWithRole("return", ...)
end

--- Creates a new GreenTeaLeaf Type that matches a function.\
--- This cannot perform any runtime checks on the function's args or returns.\
--- The args and returns exist primarily to have an accurate Luau type.\
--- They can also be inspected at runtime with `type.fn.args` and `type.fn.returns`.
function GreenTeaLeaf.fn<Args..., Returns...>(args: unknown, returns: unknown): Type<(Args...) -> Returns...>
	local argsRuntime = asRuntime(args)
	local returnsRuntime = asRuntime(returns)

	local result = (
		makeType("function", "function", function(pack)
			local input = pack[1]
			return if typeof(input) == "function" then ok() else err(nil, input, "expected function")
		end) :: unknown
	) :: RuntimeType<(Args...) -> Returns...>

	result.fn = { args = argsRuntime, returns = returnsRuntime }
	result._fnInfo = { args = argsRuntime, returns = returnsRuntime }
	return result
end

--- Creates a new GreenTeaLeaf Type that matches a function with any args and any returns.
function GreenTeaLeaf.anyfn(): Type<(...unknown) -> ...unknown>
	return (
		GreenTeaLeaf.fn(
			GreenTeaLeaf.args(GreenTeaLeaf.vararg(GreenTeaLeaf.unknown { allowNil = true })),
			GreenTeaLeaf.returns(GreenTeaLeaf.vararg(GreenTeaLeaf.unknown { allowNil = true }))
		) :: unknown
	) :: Type<(...unknown) -> ...unknown>
end

--- Creates a new GreenTeaLeaf Type that "smuggles" a tuple as a single value by
--- packing it into the returns.
function GreenTeaLeaf.tuplePacked<T...>(...: Type<unknown>): Type<TuplePacked<T...>>
	return (GreenTeaLeaf.fn(GreenTeaLeaf.args(), GreenTeaLeaf.returns(...)) :: unknown) :: Type<TuplePacked<T...>>
end

--- Creates a new GreenTeaLeaf Type that matches a table.\
--- The `contents` table should be a dictionary of string keys to types.\
--- An indexer can be provided with `{ [keyGreenTeaLeafType] = valueType }`.
function GreenTeaLeaf.table<T>(contents: T, options: { array: boolean?, count: RangeInput?, raw: boolean? }?): Type<StructOf<T>>
	local rawContents: { [string]: Type<unknown> } = {}
	local indexerKey: RuntimeType<unknown>? = nil
	local indexerValue: RuntimeType<unknown>? = nil
	local count = if options then parseRange(options.count) else nil
	local array = if options then options.array else nil
	local raw = if options then options.raw else nil

	if typeof(contents) ~= "table" then
		error("table contents must be a table", 2)
	end

	for key, value in contents :: { [unknown]: unknown } do
		if isTypeObject(key) then
			indexerKey = asRuntime(key)
			indexerValue = asRuntime(value)
		elseif typeof(key) == "number" then
			indexerKey = asRuntime(GreenTeaLeaf.number())
			indexerValue = asRuntime(value)
		elseif typeof(key) == "string" then
			rawContents[key :: string] = asRuntime(value)
		elseif raw then
			rawContents[tostring(key)] = asRuntime(value)
		else
			error("tables must use string keys, number indexers, or GreenTeaLeaf type keys", 2)
		end
	end

	local result = (
		makeType("table", "table", function(pack)
			local input = pack[1]
			if typeof(input) ~= "table" then
				return err(nil, input, "expected table")
			end

			local inputTable = input :: { [unknown]: unknown }
			local causes: { Cause } = {}

			for key, schema in rawContents do
				local cause = asRuntime(schema)._matches(singlePack(inputTable[key]))
				if not cause.ok then
					table.insert(causes, qualifyCause(cause, `field "{key}"`))
				end
			end

			local indexedCount = 0
			if indexerKey ~= nil and indexerValue ~= nil then
				for key, value in inputTable do
					if typeof(key) ~= "string" or rawContents[key] == nil then
						local keyCause = indexerKey._matches(singlePack(key))
						local valueCause = indexerValue._matches(singlePack(value))
						if not keyCause.ok then
							table.insert(causes, qualifyCause(keyCause, `key {tostring(key)}`))
						elseif not valueCause.ok then
							table.insert(causes, qualifyCause(valueCause, `index #{tostring(key)}`))
						else
							indexedCount += 1
						end
					end
				end
			end

			if array then
				for index = 1, #inputTable do
					if inputTable[index] == nil then
						table.insert(causes, err(nil, input, "expected contiguous array"))
						break
					end
				end
			end

			if not inRange(indexedCount, count) then
				table.insert(causes, err(nil, input, "expected table item count in range"))
			end

			if #causes == 0 then
				return ok()
			end
			if #causes == 1 then
				return causes[1]
			end
			return mergeErrs("table did not match", nil, input, causes)
		end) :: unknown
	) :: RuntimeType<StructOf<T>>

	result.table = {
		contents = rawContents,
		indexer = if indexerKey ~= nil and indexerValue ~= nil then { key = indexerKey, value = indexerValue } else nil,
		array = array,
		count = count,
		raw = raw,
	}

	return result
end

GreenTeaLeaf.struct = GreenTeaLeaf.table

--- Creates a new GreenTeaLeaf Type that matches an array of values.\
--- Convenience function that calls GreenTeaLeaf.table internally.
function GreenTeaLeaf.array<T>(schema: Type<T>, options: { count: RangeInput? }?): Type<{ T }>
	local result = GreenTeaLeaf.table({ schema }, { array = true, count = if options then options.count else nil })
	return result :: Type<{ T }>
end

--- Creates a new GreenTeaLeaf Type that matches a dictionary of values.\
--- Convenience function that calls GreenTeaLeaf.table internally.
function GreenTeaLeaf.dictionary<K, V>(key: Type<K>, value: Type<V>, options: { count: RangeInput? }?): Type<{ [K]: V }>
	local contents: { [unknown]: unknown } = {}
	contents[key] = value
	local result = GreenTeaLeaf.table(contents, { count = if options then options.count else nil })
	return result :: Type<{ [K]: V }>
end

--- Creates a new GreenTeaLeaf Type that matches any table.
function GreenTeaLeaf.anyTable(options: { count: RangeInput? }?): Type<{ [unknown]: unknown }>
	return GreenTeaLeaf.dictionary(GreenTeaLeaf.unknown { allowNil = true }, GreenTeaLeaf.unknown { allowNil = true }, options)
end

type UnionType =
	(<A, B>(A, B) -> Type<Union2<A, B>>)
	& (<A, B, C>(A, B, C) -> Type<Union3<A, B, C>>)
	& (<A, B, C, D>(A, B, C, D) -> Type<Union4<A, B, C, D>>)
	& (<A, B, C, D, E>(A, B, C, D, E) -> Type<Union5<A, B, C, D, E>>)

local unionImpl = function(...: Type<unknown>): Type<unknown>
	local packed = table.pack(...)
	local contents: { RuntimeType<unknown> } = {}
	local exportedContents: { Type<unknown> } = {}
	local optional = false

	for index = 1, packed.n do
		local schema = asRuntime(packed[index])
		contents[index] = schema
		exportedContents[index] = schema
		if schema._basicTypeof == "nil" then
			optional = true
		end
	end

	assert(#contents > 0, "union must have at least one type")

	local result: RuntimeType<unknown> = makeType("union", "union", function(pack)
		local causes: { Cause } = {}
		local input = pack[1]
		for _, schema in contents do
			local cause = schema._matches(pack)
			if cause.ok then
				return cause
			end

			local isNilBranch = schema._basicTypeof == "nil"
			if input == nil or not isNilBranch then
				table.insert(causes, qualifyCause(cause, `as {describeType(schema)}`))
			end
		end

		if isLiteralUnion(contents) then
			return errVerbatim(pack[1], `expected {literalExpectedLabel(contents)}`)
		end

		if #causes == 1 then
			return causes[1]
		end

		return mergeErrs("did not match any union member", nil, pack[1], causes)
	end)

	result.union = { contents = exportedContents, optional = optional }
	return result
end

--- @function union
--- @within GreenTeaLeaf
--- @param ... T...
--- @return T...
--- Creates a new GreenTeaLeaf Type that matches a union of types.\
--- This is analogous to the Luau `type1 | type2 | ...` syntax.
local union = (unionImpl :: unknown) :: UnionType
GreenTeaLeaf.union = union
GreenTeaLeaf.oneOf = union

type IntersectionType =
	(<A, B>(A, B) -> Type<Intersection2<A, B>>)
	& (<A, B, C>(A, B, C) -> Type<Intersection3<A, B, C>>)
	& (<A, B, C, D>(A, B, C, D) -> Type<Intersection4<A, B, C, D>>)
	& (<A, B, C, D, E>(A, B, C, D, E) -> Type<Intersection5<A, B, C, D, E>>)

local intersectionImpl = function(...: Type<unknown>): Type<unknown>
	local packed = table.pack(...)
	local contents: { RuntimeType<unknown> } = {}
	local exportedContents: { Type<unknown> } = {}

	for index = 1, packed.n do
		local schema = asRuntime(packed[index])
		contents[index] = schema
		exportedContents[index] = schema
	end

	assert(#contents > 0, "intersection must have at least one type")

	local result: RuntimeType<unknown> = makeType("intersection", "intersection", function(pack)
		local causes: { Cause } = {}
		for _, schema in contents do
			local cause = schema._matches(pack)
			if not cause.ok then
				table.insert(causes, qualifyCause(cause, `as {describeType(schema)}`))
			end
		end

		return if #causes == 0
			then ok()
			else mergeErrs("did not match every intersection member", nil, pack[1], causes)
	end)

	result.intersection = { contents = exportedContents }
	return result
end

--- @function intersection
--- @within GreenTeaLeaf
--- @param ... T...
--- @return T...
--- Creates a new GreenTeaLeaf Type that matches an intersection of types.\
--- This is analogous to the Luau `type1 & type2 & ...` syntax.
local intersection = (intersectionImpl :: unknown) :: IntersectionType
GreenTeaLeaf.intersection = intersection
GreenTeaLeaf.allOf = intersection

--- Creates a new GreenTeaLeaf Type that makes a value optional,
--- like `type?` or `type | nil` in Luau types.
function GreenTeaLeaf.optional<T>(schema: Type<T>): Type<T?>
	return (GreenTeaLeaf.union(schema, GreenTeaLeaf.none()) :: unknown) :: Type<T?>
end

GreenTeaLeaf.opt = GreenTeaLeaf.optional

--- Creates a new GreenTeaLeaf Type matching the inferred type of `value`.\
--- At runtime, this passes tables to `GreenTeaLeaf.table`, functions to `GreenTeaLeaf.fn`, and so on.
function GreenTeaLeaf.typeof<T>(value: T, recursionCheck: { [unknown]: unknown }?): Type<T>
	if isTypeObject(value) then
		return (value :: unknown) :: Type<T>
	end

	if value == nil then
		return GreenTeaLeaf.none() :: Type<T>
	end

	local kind = typeof(value)
	if kind == "boolean" then
		return GreenTeaLeaf.boolean() :: Type<T>
	elseif kind == "number" then
		return GreenTeaLeaf.number() :: Type<T>
	elseif kind == "string" then
		return GreenTeaLeaf.string() :: Type<T>
	elseif kind == "thread" then
		return GreenTeaLeaf.thread() :: Type<T>
	elseif kind == "buffer" then
		return GreenTeaLeaf.buffer() :: Type<T>
	elseif kind == "function" then
		return GreenTeaLeaf.anyfn() :: Type<T>
	elseif kind ~= "table" then
		return GreenTeaLeaf.isTypeof(kind) :: Type<T>
	end

	local seen: { [unknown]: unknown } = if recursionCheck then recursionCheck else {}
	if seen[value] ~= nil then
		return seen[value] :: Type<T>
	end

	local placeholder = GreenTeaLeaf.anyTable()
	seen[value] = placeholder

	local rawTable = value :: { [unknown]: unknown }
	local shape: { [unknown]: unknown } = {}
	for key, subValue in rawTable do
		shape[key] = GreenTeaLeaf.typeof(subValue, seen)
	end

	return GreenTeaLeaf.table(shape) :: Type<T>
end

--- Typecasts a value to a GreenTeaLeaf type.\
--- At runtime this will error if the passed-in value is not a GreenTeaLeaf type.
function GreenTeaLeaf.typecast<S>(value: S): Type<ValueOf<S>>
	assert(isTypeObject(value), "value must be a GreenTeaLeaf type")
	return (value :: unknown) :: Type<ValueOf<S>>
end

GreenTeaLeaf.asGreenTeaLeafType = GreenTeaLeaf.typecast
GreenTeaLeaf.asGtType = GreenTeaLeaf.typecast

--- Typecasts a value to be a GreenTeaLeaf type.\
--- This is the preferred way to build a GreenTeaLeaf type for typical use.
function GreenTeaLeaf.build<S>(schema: S): Type<ValueOf<S>>
	return GreenTeaLeaf.typecast(schema)
end

--- Adds user-specified metadata to a type.\
--- Each key/value pair is added to the type's `meta` table.
function GreenTeaLeaf.meta<T>(schema: Type<T>, meta: { [string]: unknown }): Type<T>
	local runtime = asRuntime(schema)
	runtime.meta = meta
	return schema
end

--- Wraps a function with type asserts for its input args and returns.
function GreenTeaLeaf.wrapFn<T>(schema: Type<T>, fn: T): T
	local runtime = asRuntime(schema)
	assert(runtime._fnInfo ~= nil, "schema must be a GreenTeaLeaf.fn type")

	return (
		function(...: unknown)
			local fnInfo = runtime._fnInfo
			assert(fnInfo ~= nil)
			fnInfo.args:assert(...)
			return fnInfo.returns:assert((fn :: (...unknown) -> unknown)(...))
		end :: unknown
	) :: T
end

--- Wraps a function with type asserts for its input args only.\
--- See `GreenTeaLeaf.wrapFn` for more information.
function GreenTeaLeaf.wrapFnArgs<T>(schema: Type<T>, fn: T): T
	local runtime = asRuntime(schema)
	assert(runtime._fnInfo ~= nil, "schema must be a GreenTeaLeaf.fn type")

	return (
		function(...: unknown)
			local fnInfo = runtime._fnInfo
			assert(fnInfo ~= nil)
			fnInfo.args:assert(...)
			return (fn :: (...unknown) -> unknown)(...)
		end :: unknown
	) :: T
end

--- Wraps a function with type asserts for its returns only.\
--- See `GreenTeaLeaf.wrapFn` for more information.
function GreenTeaLeaf.wrapFnReturns<T>(schema: Type<T>, fn: T): T
	local runtime = asRuntime(schema)
	assert(runtime._fnInfo ~= nil, "schema must be a GreenTeaLeaf.fn type")

	return (
		function(...: unknown)
			local fnInfo = runtime._fnInfo
			assert(fnInfo ~= nil)
			return fnInfo.returns:assert((fn :: (...unknown) -> unknown)(...))
		end :: unknown
	) :: T
end

--- Creates a new GreenTeaLeaf Type that matches Instance values.
function GreenTeaLeaf.Instance(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Instance")
end

--- Call isA to get a type that matches instances of that class.
function GreenTeaLeaf.isA(className: string): Type<unknown>
	local schema: RuntimeType<unknown> = makeType("instanceIsA", className, function(pack)
		local input = pack[1]
		if typeof(input) ~= "table" and typeof(input) ~= "userdata" then
			return err(nil, input, `expected {className}`)
		end

		local instance = (input :: unknown) :: { IsA: ((unknown, string) -> boolean)? }
		if instance.IsA == nil then
			return err(nil, input, `expected {className}`)
		end

		local success, matches = pcall(instance.IsA, input, className)
		return if success and matches == true then ok() else err(nil, input, `expected {className}`)
	end)

	schema.instanceIsA = { class = className }
	return schema
end

GreenTeaLeaf.IsA = GreenTeaLeaf.isA

function GreenTeaLeaf.Vector2(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Vector2")
end

GreenTeaLeaf.vector = GreenTeaLeaf.Vector2

function GreenTeaLeaf.Vector3(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Vector3")
end

function GreenTeaLeaf.CFrame(): Type<unknown>
	return GreenTeaLeaf.isTypeof("CFrame")
end

function GreenTeaLeaf.Color3(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Color3")
end

function GreenTeaLeaf.UDim(): Type<unknown>
	return GreenTeaLeaf.isTypeof("UDim")
end

function GreenTeaLeaf.UDim2(): Type<unknown>
	return GreenTeaLeaf.isTypeof("UDim2")
end

function GreenTeaLeaf.Ray(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Ray")
end

function GreenTeaLeaf.Rect(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Rect")
end

function GreenTeaLeaf.Region3(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Region3")
end

function GreenTeaLeaf.BrickColor(): Type<unknown>
	return GreenTeaLeaf.isTypeof("BrickColor")
end

function GreenTeaLeaf.Font(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Font")
end

function GreenTeaLeaf.Enum(): Type<unknown>
	return GreenTeaLeaf.isTypeof("Enum")
end

function GreenTeaLeaf.EnumItem(): Type<unknown>
	return GreenTeaLeaf.isTypeof("EnumItem")
end

GreenTeaLeaf.__Cause = {}
GreenTeaLeaf.__Type = {}
GreenTeaLeaf.__greenTeaLeafConstructorsSet = {}

return GreenTeaLeaf
