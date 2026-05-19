--!strict

local GreenTeaLeaf = require("@self/GreenTeaLeaf")
local InstanceClasses = require(script.InstanceClasses)
local tCompat = require(script.tCompat)

export type Cause = GreenTeaLeaf.Cause
export type Type<T = unknown> = GreenTeaLeaf.Type<T>
export type BuiltType<T = unknown> = GreenTeaLeaf.BuiltType<T>
export type TuplePacked<T...> = GreenTeaLeaf.TuplePacked<T...>

local export = {
	t = tCompat,

	isGreenTeaType = GreenTeaLeaf.isGreenTeaLeafType,
	isGtType = GreenTeaLeaf.isGtType,

	any = GreenTeaLeaf.any,
	unknown = GreenTeaLeaf.unknown,
	never = GreenTeaLeaf.never,

	boolean = GreenTeaLeaf.boolean,
	bool = GreenTeaLeaf.bool,

	Instance = GreenTeaLeaf.Instance,
	isA = InstanceClasses,
	IsA = InstanceClasses,

	coroutine = GreenTeaLeaf.coroutine,
	thread = GreenTeaLeaf.thread,

	buffer = GreenTeaLeaf.buffer,
	userdata = GreenTeaLeaf.userdata,

	Vector2 = GreenTeaLeaf.Vector2,
	vector = GreenTeaLeaf.vector,
	Vector3 = GreenTeaLeaf.Vector3,
	CFrame = GreenTeaLeaf.CFrame,
	Color3 = GreenTeaLeaf.Color3,
	UDim = GreenTeaLeaf.UDim,
	UDim2 = GreenTeaLeaf.UDim2,
	Ray = GreenTeaLeaf.Ray,
	Rect = GreenTeaLeaf.Rect,
	Region3 = GreenTeaLeaf.Region3,
	BrickColor = GreenTeaLeaf.BrickColor,
	Font = GreenTeaLeaf.Font,

	Enum = GreenTeaLeaf.Enum,
	EnumItem = GreenTeaLeaf.EnumItem,

	none = GreenTeaLeaf.none,
	literal = GreenTeaLeaf.literal,
	literals = GreenTeaLeaf.literals,
	literalUnion = GreenTeaLeaf.literalUnion,
	oneOfLiterals = GreenTeaLeaf.oneOfLiterals,

	withCustom = GreenTeaLeaf.withCustom,
	custom = GreenTeaLeaf.custom,

	number = GreenTeaLeaf.number,
	string = GreenTeaLeaf.string,

	isTypeof = GreenTeaLeaf.isTypeof,
	isType = GreenTeaLeaf.isType,

	vararg = GreenTeaLeaf.vararg,
	tuple = GreenTeaLeaf.tuple,

	args = GreenTeaLeaf.args,
	returns = GreenTeaLeaf.returns,
	fn = GreenTeaLeaf.fn,
	anyfn = GreenTeaLeaf.anyfn,

	tuplePacked = GreenTeaLeaf.tuplePacked,

	table = GreenTeaLeaf.table,
	struct = GreenTeaLeaf.struct,

	anyTable = GreenTeaLeaf.anyTable,
	array = GreenTeaLeaf.array,
	dictionary = GreenTeaLeaf.dictionary,

	union = GreenTeaLeaf.union,
	oneOf = GreenTeaLeaf.oneOf,

	intersection = GreenTeaLeaf.intersection,
	allOf = GreenTeaLeaf.allOf,

	optional = GreenTeaLeaf.optional,
	opt = GreenTeaLeaf.opt,

	typeof = GreenTeaLeaf.typeof,

	typecast = GreenTeaLeaf.typecast,
	asGreenTeaType = GreenTeaLeaf.asGreenTeaLeafType,
	asGtType = GreenTeaLeaf.asGtType,

	build = GreenTeaLeaf.build,
	meta = GreenTeaLeaf.meta,

	wrapFn = GreenTeaLeaf.wrapFn,
	wrapFnArgs = GreenTeaLeaf.wrapFnArgs,
	wrapFnReturns = GreenTeaLeaf.wrapFnReturns,
}

table.freeze(export)

return export
