--!strict

local GreenTeaLeaf = require("./GreenTeaLeaf")

type InstanceSchemaFactory = () -> GreenTeaLeaf.Schema<unknown>

local function class(className: string): InstanceSchemaFactory
	return function()
		return GreenTeaLeaf.isA(className)
	end
end

local classes: { [string]: InstanceSchemaFactory } = {
	Instance = class("Instance"),
	Workspace = class("Workspace"),
	Folder = class("Folder"),
	Model = class("Model"),
	Part = class("Part"),
	MeshPart = class("MeshPart"),
	BasePart = class("BasePart"),
	Humanoid = class("Humanoid"),
	Player = class("Player"),
	Script = class("Script"),
	LocalScript = class("LocalScript"),
	ModuleScript = class("ModuleScript"),
	RemoteEvent = class("RemoteEvent"),
	RemoteFunction = class("RemoteFunction"),
	BindableEvent = class("BindableEvent"),
	BindableFunction = class("BindableFunction"),
	ScreenGui = class("ScreenGui"),
	Frame = class("Frame"),
	TextLabel = class("TextLabel"),
	TextButton = class("TextButton"),
	ImageLabel = class("ImageLabel"),
	ImageButton = class("ImageButton"),
}

table.freeze(classes)

return classes
