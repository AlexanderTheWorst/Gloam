local Module = loadstring(httpget(
	"https://raw.githubusercontent.com/AlexanderTheWorst/Gloam/main/v1/utils/require.luau?v=2"
))()

Module.cwd =
	"https://raw.githubusercontent.com/AlexanderTheWorst/Gloam/main/v1/"

local IconPack =
	Module.require(
		"./utils/icons/IconPack.luau"
	)

local Icon =
	Module.require(
		"./utils/icons/Icon.luau"
	)

local Component =
	Module.require(
		"./classes/Component.luau"
	)

local ComponentRegistry =
	Module.require(
		"./registry/ComponentRegistry.luau"
	)

Component.setRegistry(
	ComponentRegistry
)

return {
	Screen =
		Module.require(
			"./components/Screen.luau"
		),

	Events =
		Module.require(
			"./utils/events/Events.luau"
		).EventsDescriptor,

	IconPack =
		IconPack.IconPack,

	Icon =
		Icon.Icon,
}