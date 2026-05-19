--!strict

local GreenTeaLeaf = require("@self/GreenTeaLeaf")
local InstanceClasses = require("@self/InstanceClasses")
local tCompat = require("@self/tCompat")

export type Range = GreenTeaLeaf.Range
export type ErrorInfo = GreenTeaLeaf.ErrorInfo
export type Cause = GreenTeaLeaf.Cause
export type BasicInfo = GreenTeaLeaf.BasicInfo
export type AnyInfo = GreenTeaLeaf.AnyInfo
export type UnknownInfo = GreenTeaLeaf.UnknownInfo
export type CustomInfo = GreenTeaLeaf.CustomInfo
export type NumberInfo = GreenTeaLeaf.NumberInfo
export type StringInfo = GreenTeaLeaf.StringInfo
export type ThreadInfo = GreenTeaLeaf.ThreadInfo
export type InstanceIsAInfo = GreenTeaLeaf.InstanceIsAInfo
export type LiteralInfo = GreenTeaLeaf.LiteralInfo
export type TupleInfo = GreenTeaLeaf.TupleInfo
export type VarargInfo = GreenTeaLeaf.VarargInfo
export type FnInfo = GreenTeaLeaf.FnInfo
export type TableIndexerInfo = GreenTeaLeaf.TableIndexerInfo
export type TableInfo = GreenTeaLeaf.TableInfo
export type IntersectionInfo = GreenTeaLeaf.IntersectionInfo
export type UnionInfo = GreenTeaLeaf.UnionInfo
export type TypeBase = GreenTeaLeaf.TypeBase
export type Schema<T = unknown> = GreenTeaLeaf.Schema<T>
export type Type<T = unknown> = GreenTeaLeaf.Type<T>
export type TupleType<T...> = GreenTeaLeaf.TupleType<T...>
export type VarargType<T = unknown> = GreenTeaLeaf.VarargType<T>
export type FnType<T = (...unknown) -> ...unknown> = GreenTeaLeaf.FnType<T>
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
