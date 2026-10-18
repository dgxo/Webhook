--!strict
const Utility = require("./Utility")

local module = {}
local Component = {}
Component.__index = Component

type self = {
	Type: number,
	Options: { [string]: any },
	Components: { Component }?,
}

export type Component = typeof(setmetatable({} :: self, Component))

--- Note that interactive components will fail to send in webhooks not owned by
--- an app
module.Type = {
	ActionRow = 1,
	Button = 2,
	StringSelect = 3,
	TextInput = 4,
	UserSelect = 5,
	RoleSelect = 6,
	MentionableSelect = 7,
	ChannelSelect = 8,
	Section = 9,
	TextDisplay = 10,
	Thumbnail = 11,
	MediaGallery = 12,
	File = 13,
	Separator = 14,
	--- Unstable
	ContentInventoryEntry = 16,
	Container = 17,
	Label = 18,
	FileUpload = 19,
	--- Deprecated
	SelectMenu = 3,
}

module.ButtonType = {
	Primary = 1,
	Secondary = 2,
	Success = 3,
	Danger = 4,
	Link = 5,
	Premium = 6,
}

--- Create a new Component for use in a webhook
--- <code>options</code> can be PascalCase or snake_case, it will be converted when sending
--- <code>components</code>, the children components, can be a Component or array of Components
function module.new(componentType: number, options: { [string]: any }?, components: Component | { Component } | nil)
	const self = setmetatable({
		Type = componentType,
		Options = options or {},
		Components = if components == nil
			then nil
			elseif typeof(components) == "table" and (components :: Component).Type == nil then components
			else { components },
	}, Component) :: Component

	return self
end

--- Shorthand helper function to make a TextDisplay component
function module.textDisplay(content: string)
	const self = setmetatable({
		Type = module.Type.TextDisplay,
		Options = { Content = content },
	}, Component) :: Component

	return self
end

function Component.ToTable(self: Component): { [string]: any }
	const result = Utility.pascalKeysToSnakeCase(self.Options)

	result.type = self.Type
	if self.Components then
		result.components = {}
		for _, component in self.Components do
			table.insert(result.components, component:ToTable())
		end
	end

	return result
end

return module
