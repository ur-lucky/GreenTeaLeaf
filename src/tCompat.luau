--!strict

local GreenTeaLeaf = require("./GreenTeaLeaf")

type Typechecker = (unknown) -> (boolean, string?)
type TypecheckerConstructor<T...> = (T...) -> Typechecker

local function fromSchema<T>(schema: GreenTeaLeaf.Schema<T>): Typechecker
	local erased = (schema :: unknown) :: GreenTeaLeaf.Schema<unknown>
	return function(value: unknown): (boolean, string?)
		local success, cause = erased:matches(value)
		return success, if success then nil else cause:formatErr()
	end
end

local function asSchema(value: unknown): GreenTeaLeaf.Schema<unknown>
	if GreenTeaLeaf.isGtType(value) then
		return (value :: unknown) :: GreenTeaLeaf.Schema<unknown>
	end

	if typeof(value) == "function" then
		local checker = (value :: unknown) :: (unknown) -> (boolean, unknown?)
		return GreenTeaLeaf.custom(function(input: unknown): (boolean, unknown?)
			return checker(input)
		end)
	end

	return (GreenTeaLeaf.typeof(value) :: unknown) :: GreenTeaLeaf.Schema<unknown>
end

local t: { [string]: unknown } = {}

t.boolean = fromSchema(GreenTeaLeaf.boolean())
t.buffer = fromSchema(GreenTeaLeaf.buffer())
t.callback = fromSchema(GreenTeaLeaf.anyfn())
t["function"] = t.callback
t.none = fromSchema(GreenTeaLeaf.none())
t["nil"] = t.none
t.string = fromSchema(GreenTeaLeaf.string())
t.table = fromSchema(GreenTeaLeaf.anyTable())
t.userdata = fromSchema(GreenTeaLeaf.userdata())
t.vector = fromSchema(GreenTeaLeaf.Vector3())
t.number = fromSchema(GreenTeaLeaf.number())
t.thread = fromSchema(GreenTeaLeaf.thread())
t.any = function(_value: unknown): (boolean, string?)
	return true, nil
end

t.type = function(typeName: string): Typechecker
	return fromSchema(GreenTeaLeaf.isType(typeName))
end :: TypecheckerConstructor<string>

t.typeof = function(typeName: string): Typechecker
	return fromSchema(GreenTeaLeaf.isTypeof(typeName))
end :: TypecheckerConstructor<string>

t.literal = function(...: unknown): Typechecker
	local count = select("#", ...)
	if count == 0 then
		return t.any :: Typechecker
	end

	local values: { unknown } = {}
	for index = 1, count do
		values[index] = select(index, ...)
	end

	return function(value: unknown): (boolean, string?)
		for _, expected in values do
			if value == expected then
				return true, nil
			end
		end

		return false, "expected literal"
	end
end :: TypecheckerConstructor<...unknown>

t.exactly = t.literal

t.optional = function(checker: unknown): Typechecker
	local inner = fromSchema(asSchema(checker))
	return function(value: unknown): (boolean, string?)
		if value == nil then
			return true, nil
		end

		return inner(value)
	end
end :: TypecheckerConstructor<unknown>

t.tuple = function(...: unknown): Typechecker
	local schemas: { GreenTeaLeaf.Schema<unknown> } = {}
	for index = 1, select("#", ...) do
		schemas[index] = asSchema(select(index, ...))
	end

	local tuple = (GreenTeaLeaf.tuple :: unknown) :: (...unknown) -> GreenTeaLeaf.Schema<unknown>
	return fromSchema(tuple(table.unpack(schemas)))
end :: TypecheckerConstructor<...unknown>

t.union = function(first: unknown, second: unknown, third: unknown?): Typechecker
	local checkers = {
		fromSchema(asSchema(first)),
		fromSchema(asSchema(second)),
		if third == nil then nil else fromSchema(asSchema(third)),
	}

	return function(value: unknown): (boolean, string?)
		local lastMessage = "expected union"
		for _, checker in checkers do
			local success, message = checker(value)
			if success then
				return true, nil
			end
			lastMessage = message or lastMessage
		end

		return false, lastMessage
	end
end :: TypecheckerConstructor<unknown, unknown, unknown?>

t.some = t.union

t.intersection = function(first: unknown, second: unknown, third: unknown?): Typechecker
	local checkers = {
		fromSchema(asSchema(first)),
		fromSchema(asSchema(second)),
		if third == nil then nil else fromSchema(asSchema(third)),
	}

	return function(value: unknown): (boolean, string?)
		for _, checker in checkers do
			local success, message = checker(value)
			if not success then
				return false, message
			end
		end

		return true, nil
	end
end :: TypecheckerConstructor<unknown, unknown, unknown?>

t.every = t.intersection

t.array = function(checker: unknown): Typechecker
	return fromSchema(GreenTeaLeaf.array(asSchema(checker)))
end :: TypecheckerConstructor<unknown>

local function mapFn(key: unknown, value: unknown): Typechecker
	return fromSchema(GreenTeaLeaf.dictionary(asSchema(key), asSchema(value)))
end

t.map = mapFn :: TypecheckerConstructor<unknown, unknown>

t.keys = function(key: unknown): Typechecker
	return mapFn(key, GreenTeaLeaf.unknown({ allowNil = true }))
end :: TypecheckerConstructor<unknown>

t.values = function(value: unknown): Typechecker
	return mapFn(GreenTeaLeaf.unknown({ allowNil = true }), value)
end :: TypecheckerConstructor<unknown>

t.set = function(key: unknown): Typechecker
	return mapFn(key, GreenTeaLeaf.literal(true))
end :: TypecheckerConstructor<unknown>

t.strictInterface = function(fields: { [string]: unknown }): Typechecker
	local shape: { [string]: GreenTeaLeaf.Schema<unknown> } = {}
	for key, checker in fields do
		shape[key] = asSchema(checker)
	end

	return function(value: unknown): (boolean, string?)
		if typeof(value) ~= "table" then
			return false, "expected table"
		end

		local tableValue = value :: { [string]: unknown }
		for key, schema in shape do
			local success, cause = schema:matches(tableValue[key])
			if not success then
				return false, cause:formatErr()
			end
		end

		return true, nil
	end
end :: TypecheckerConstructor<{ [string]: unknown }>

t.interface = t.strictInterface

t.numberMin = function(min: number): Typechecker
	return fromSchema(GreenTeaLeaf.number({ range = `[{min}, inf]` }))
end :: TypecheckerConstructor<number>

t.numberMax = function(max: number): Typechecker
	return fromSchema(GreenTeaLeaf.number({ range = `[-inf, {max}]` }))
end :: TypecheckerConstructor<number>

t.numberConstrained = function(min: number, max: number): Typechecker
	return fromSchema(GreenTeaLeaf.number({ range = `[{min}, {max}]` }))
end :: TypecheckerConstructor<number, number>

t.integer = fromSchema(GreenTeaLeaf.number({ integer = true }))

t.match = function(pattern: string): Typechecker
	return fromSchema(GreenTeaLeaf.string({ pattern = pattern }))
end :: TypecheckerConstructor<string>

t.instanceIsA = function(className: string): Typechecker
	return fromSchema(GreenTeaLeaf.isA(className))
end :: TypecheckerConstructor<string>

t.strict = function(checker: unknown): Typechecker
	return fromSchema(asSchema(checker))
end :: TypecheckerConstructor<unknown>

table.freeze(t)

return t
