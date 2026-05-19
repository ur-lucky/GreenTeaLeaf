--!strict
-- Exercises GreenTeaLeaf type checks and collects error messages.

local gt = require("../src/GreenTeaLeaf")

type Case = {
	name: string,
	schema: gt.Type<unknown>,
	input: unknown,
	pack: { unknown }?,
}

type Result = {
	name: string,
	ok: boolean,
	error: string?,
	inputDesc: string,
}

local results: { Result } = {}

local function describeInput(input: unknown): string
	if input == nil then
		return "nil"
	end
	local kind = typeof(input)
	if kind == "string" then
		return `string {string.format("%q", input :: string)}`
	end
	if kind == "table" then
		local n = #(input :: { unknown })
		if n > 0 then
			return `table [{n}]`
		end
		return "table {}"
	end
	if kind == "function" then
		return "function"
	end
	return `{kind} {tostring(input)}`
end

local function runCase(case: Case)
	local ok: boolean
	local cause: gt.Cause

	if case.pack then
		ok, cause = case.schema:matches(table.unpack(case.pack))
	else
		ok, cause = case.schema:matches(case.input)
	end

	local inputDesc: string
	if case.pack then
		local packed = table.pack(table.unpack(case.pack))
		local parts: { string } = {}
		for i = 1, packed.n do
			parts[i] = describeInput(packed[i])
		end
		inputDesc = `pack({table.concat(parts, ", ")})`
	else
		inputDesc = describeInput(case.input)
	end

	table.insert(results, {
		name = case.name,
		ok = ok,
		error = if ok then nil else cause:formatErr(),
		inputDesc = inputDesc,
	})
end

local cases: { Case } = {
	-- Primitives
	{ name = "boolean", schema = gt.boolean(), input = "true" },
	{ name = "number", schema = gt.number(), input = "42" },
	{ name = "string", schema = gt.string(), input = 42 },
	{ name = "none", schema = gt.none(), input = 0 },
	{ name = "never", schema = gt.never(), input = nil },
	{ name = "any (reject nil)", schema = gt.any(), input = nil },
	{ name = "any (allowNil)", schema = gt.any { allowNil = true }, input = {} },
	{ name = "unknown (reject nil)", schema = gt.unknown(), input = nil },
	{ name = "buffer", schema = gt.buffer(), input = "buf" },
	{ name = "userdata", schema = gt.userdata(), input = 1 },
	{ name = "thread", schema = gt.thread(), input = {} },

	-- number limits
	{ name = "number.integer", schema = gt.number { integer = true }, input = 3.5 },
	{ name = "number.range", schema = gt.number { range = "[0, 10]" }, input = 11 },
	{ name = "number.nan (reject)", schema = gt.number(), input = 0 / 0 },
	{ name = "number.nan (allow)", schema = gt.number { nan = true }, input = true },

	-- string limits
	{ name = "string.pattern", schema = gt.string { pattern = "^%d+$" }, input = "abc" },

	-- literals
	{ name = "literal string", schema = gt.literal("One"), input = "Four" },
	{ name = "literal number", schema = gt.literal(42), input = 43 },
	{ name = "literal boolean", schema = gt.literal(true), input = false },
	{
		name = "literals union",
		schema = gt.literals({ "One", "Two", "Three" }),
		input = "Four",
	},
	{
		name = "union of literals",
		schema = gt.union(gt.literal("A"), gt.literal("B")),
		input = "C",
	},

	-- typeof / isType
	{ name = "isTypeof string", schema = gt.isTypeof("string"), input = 1 },
	{ name = "isType number", schema = gt.isType("number"), input = "x" },

	-- custom
	{
		name = "custom",
		schema = gt.custom(function(v)
			return typeof(v) == "number" and v > 0, "must be positive"
		end),
		input = -1,
	},
	{
		name = "withCustom",
		schema = gt.withCustom(gt.string(), function(v)
			return #v :: string > 3, "too short"
		end),
		input = "hi",
	},

	-- tuple / args / returns
	{ name = "tuple", schema = gt.tuple(gt.number(), gt.string()), pack = { 1 } },
	{ name = "tuple index 2", schema = gt.tuple(gt.number(), gt.string()), pack = { 1, 1 } },
	{
		name = "args (missing)",
		schema = gt.args(gt.any(), gt.optional(gt.any())),
		pack = {},
	},
	{
		name = "args (nil via pack)",
		schema = gt.args(gt.any(), gt.optional(gt.any())),
		pack = table.pack(nil),
	},
	{
		name = "returns (bad array element)",
		schema = gt.returns(gt.any { allowNil = true }, gt.optional(gt.array(gt.number()))),
		pack = table.pack(nil, { "123" }),
	},
	{
		name = "returns (3-tuple)",
		schema = gt.returns(
			gt.any { allowNil = true },
			gt.optional(gt.array(gt.number())),
			gt.optional(gt.dictionary(gt.string(), gt.number()))
		),
		pack = table.pack(1, { 1, "x" }),
	},
	{ name = "function", schema = gt.fn(gt.args(), gt.returns()), input = 1 },
	{ name = "anyfn", schema = gt.anyfn(), input = "not fn" },

	-- vararg
	{
		name = "vararg",
		schema = gt.tuple(gt.vararg(gt.number())),
		pack = { 1, 2, "three" },
	},

	-- table / struct / array / dictionary
	{ name = "table", schema = gt.table({ a = gt.number() }), input = "x" },
	{
		name = "table field",
		schema = gt.table({ name = gt.string(), count = gt.number() }),
		input = { name = 123, count = 1 },
	},
	{
		name = "array",
		schema = gt.array(gt.number()),
		input = { 1, 2, "three" },
	},
	{
		name = "array (not contiguous)",
		schema = gt.array(gt.number()),
		input = { [1] = 1, [3] = 3 },
	},
	{
		name = "dictionary",
		schema = gt.dictionary(gt.string(), gt.number()),
		input = { hello = "world" } :: { [string]: string },
	},
	{
		name = "dictionary key",
		schema = gt.dictionary(gt.number(), gt.string()),
		input = { ["1"] = "ok" },
	},
	{ name = "anyTable", schema = gt.anyTable(), input = 42 },

	-- union / intersection / optional
	{ name = "union", schema = gt.union(gt.number(), gt.boolean()), input = "x" },
	{
		name = "optional (reject value)",
		schema = gt.optional(gt.number()),
		input = "x",
	},
	{
		name = "intersection",
		schema = gt.intersection(gt.number(), gt.boolean()),
		input = 1,
	},

	-- typeof inference
	{
		name = "typeof inferred struct",
		schema = gt.typeof({ x = 1, y = "a" }),
		input = { x = "wrong", y = 2 },
	},

	-- fn wrap
	{
		name = "wrapFn returns",
		schema = gt.fn(
			gt.args(gt.number()),
			gt.returns(gt.number(), gt.string())
		),
		input = nil, -- placeholder, handled below
	},
}

for _, case in cases do
	if case.name == "wrapFn returns" then
		local schema = case.schema
		local wrapped = gt.wrapFn(schema, function(n: number): (number, string)
			return n, 123
		end)
		local ok, errMsg = pcall(function()
			wrapped(1)
		end)
		if not ok and typeof(errMsg) == "string" then
			errMsg = errMsg:match(": (.+)$") or errMsg
		end
		table.insert(results, {
			name = case.name,
			ok = ok,
			error = if ok then "no error (unexpected)" else errMsg,
			inputDesc = "wrapped(1) -> returns (number, 123)",
		})
	else
		runCase(case)
	end
end

-- t compat sample
do
	local t = require("../src/tCompat")
	local checker = t.number
	local success, errMsg = checker("x")
	table.insert(results, {
		name = "t.number",
		ok = success,
		error = errMsg,
		inputDesc = 'string "x"',
	})
end

-- Print markdown report
print("# GreenTeaLeaf Error Message Report")
print("")
print(`Generated by lune/error-report.luau`)
print("")
print("| Type | Input | Error |")
print("|------|-------|-------|")

local passCount = 0
local failCount = 0

for _, result in results do
	if result.ok then
		passCount += 1
		continue
	end
	failCount += 1

	local err = (result.error or ""):gsub("\n", "<br>")
	err = err:gsub("|", "\\|")
	local inputDesc = result.inputDesc:gsub("|", "\\|")
	print(`| {result.name} | {inputDesc} | {err} |`)
end

print("")
print(`**Summary:** {failCount} type checks produced errors (expected), {passCount} unexpectedly passed.`)
print("")

-- Also print plain-text block for easy reading
print("---")
print("## Plain text")
print("")

for _, result in results do
	if result.ok then
		print(`[PASS (unexpected)] {result.name}`)
		print(`  input: {result.inputDesc}`)
	else
		print(`[FAIL] {result.name}`)
		print(`  input: {result.inputDesc}`)
		print(`  error:`)
		for line in string.gmatch(result.error or "", "[^\n]+") do
			print(`    {line}`)
		end
	end
	print("")
end
