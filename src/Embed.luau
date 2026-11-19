--!strict
const Utility = require("./Utility")

local module = {}
local Embed = {}
Embed.__index = Embed

type Footer = { Text: string, IconUrl: string? }
type Author = { Name: string, Url: string?, IconUrl: string? }
type Media = { Url: string, Description: string? }
type Field = { Name: string, Value: string, Inline: boolean? }

type self = {
	Title: string?,
	-- `type` is omitted here as webhooks can only use "rich"
	Description: string?,
	Url: string?,
	Timestamp: DateTime?,
	Color: Color3?,
	Footer: Footer?,
	Author: Author?,
	Image: Media?,
	Thumbnail: Media?,
	Fields: { Field },
}

export type Embed = typeof(setmetatable({} :: self, Embed))

function module.new()
	const self = setmetatable({
		Fields = {},
	}, Embed) :: Embed

	return self
end

function Embed.SetTitle(self: Embed, title: string?)
	if title and #title > 256 then
		warn("[Webhook.Embed] Title longer than 256 characters, truncating")
	end

	self.Title = Utility.truncate(title, 256)
	return self
end

function Embed.SetDescription(self: Embed, description: string?)
	if description and #description > 4096 then
		warn("[Webhook.Embed] Description longer than 4096 characters, truncating")
	end
	self.Description = Utility.truncate(description, 4096)
	return self
end

function Embed.SetUrl(self: Embed, url: string?)
	self.Url = url
	return self
end

function Embed.SetTimestamp(self: Embed, timestamp: DateTime?)
	self.Timestamp = timestamp
	return self
end

function Embed.SetColor(self: Embed, color: Color3?)
	self.Color = color
	return self
end

function Embed.SetFooter(self: Embed, footer: Footer)
	if #footer.Text > 2048 then
		warn("[Webhook.Embed] Footer longer than 2048 characters, truncating")
	end
	self.Footer = {
		Text = Utility.truncate(footer.Text, 2048) :: string,
		IconUrl = footer.IconUrl,
	}
	return self
end

function Embed.SetAuthor(self: Embed, author: Author)
	if #author.Name > 256 then
		warn("[Webhook.Embed] Author name longer than 256 characters, truncating")
	end
	self.Author = {
		Name = Utility.truncate(author.Name, 256) :: string,
		Url = author.Url,
		IconUrl = author.IconUrl,
	}
	return self
end

function Embed.SetImage(self: Embed, image: Media)
	self.Image = image
	return self
end

function Embed.SetThumbnail(self: Embed, thumbnail: Media)
	self.Thumbnail = thumbnail
	return self
end

function Embed.AddFields(self: Embed, ...: Field | { Field })
	for _, field in { ... } do
		if #field > 0 then
			self:AddFields(field)
		else
			const fieldValue = field :: Field
			if #fieldValue.Name > 256 then
				warn("[Webhook.Embed] Field name longer than 256 characters, truncating")
			end

			if #fieldValue.Value > 1024 then
				warn("[Webhook.Embed] Field value longer than 1024 characters, truncating")
			end

			table.insert(self.Fields, {
				Name = Utility.truncate(fieldValue.Name, 256) :: string,
				Value = Utility.truncate(fieldValue.Value, 1024) :: string,
				Inline = fieldValue.Inline,
			})
		end
	end

	return self
end

function Embed.ClearFields(self: Embed)
	table.clear(self.Fields)
	return self
end

function Embed.ToTable(self: Embed)
	const fields = {}
	for _, field in self.Fields do
		table.insert(fields, {
			name = field.Name,
			value = field.Value,
			inline = field.Inline,
		})
	end

	return {
		title = self.Title,
		type = "rich",
		description = self.Description,
		url = self.Url,
		timestamp = Utility.serialiseDateTime(self.Timestamp),
		color = Utility.serialiseColor3(self.Color),
		footer = self.Footer and {
			text = self.Footer.Text,
			icon_url = self.Footer.IconUrl,
		},
		author = self.Author and {
			name = self.Author.Name,
			url = self.Author.Url,
			icon_url = self.Author.IconUrl,
		},
		image = self.Image and {
			description = self.Image.Description,
			url = self.Image.Url,
		},
		thumbnail = self.Thumbnail and {
			description = self.Thumbnail.Description,
			url = self.Thumbnail.Url,
		},
		fields = if #fields >= 1 then fields else nil,
	}
end

return module
