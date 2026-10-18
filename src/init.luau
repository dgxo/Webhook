--!strict
-- Used to send Discord webhooks, replacing WebhookService with a nicer,
-- builder interface. Supports everything you can do with a webhook, except
-- uploading files (yet), and retries when rate limited (configurable).

-- You need to firstly define URLs for your webhooks. Define them in the child
-- Config module, along with any settings you'd like. It is heavily recommended
-- to use Secrets for URLs, for security, but you can use strings.
-- About secrets: https://create.roblox.com/docs/cloud-services/secrets

-- Example:
--[[
const ServerStorage = game:GetService("ServerStorage")
const Webhook = require(ServerStorage.Webhook)
const Component = require(ServerStorage.Webhook.Component)

const webhook = Webhook.new("Test") -- where Test's URL is defined in Config
webhook
	:SetUsername("Thing Error")
	:SetAvatarUrl("https://idk.com/image.png")
	:SetFlags({ Webhook.MessageFlags.IsComponentsV2 })
	:AddComponents(
		Component.new(Component.Type.Container, {}, {
			Component.textDisplay("# Big Title"),
			Component.new(Component.Type.Separator),
			Component.textDisplay("Wow!"),
			Component.new(Component.Type.ActionRow, {}, {
				Component.new(Component.Type.Button, {
					Label = "Join",
					Url = "https://idk.com/join",
					Style = Component.ButtonType.Link,
				}),
			})
		})
	)
	:SendAsync()
]]

const HttpService = game:GetService("HttpService")
const RunService = game:GetService("RunService")
const Component = require("@self/Component")
const Utility = require("@self/Utility")
const Embed = require("@self/Embed")
const Config = require("@self/Config")

const module = {}
const Webhook = {}
Webhook.__index = Webhook
Webhook.ClassName = "Webhook"

export type WebhookName = Config.WebhookName
export type WebhookConfig = Config.WebhookConfig

const warnedWebhooks: { [WebhookName]: boolean } = {}

module.MessageFlags = {
	SuppressEmbeds = bit32.lshift(1, 2),
	SuppressNotifications = bit32.lshift(1, 12),
	IsComponentsV2 = bit32.lshift(1, 15),
}

module.PollLayoutType = {
	Default = 1,
}

export type AllowedMentions = {
	Parse: { "users" | "roles" | "everyone" }?,
	Roles: { string }?,
	Users: { string }?,
	RepliedUser: boolean?,
}
export type Attachment = {
	Id: number | string,
	Filename: string,
	Title: string?,
	Description: string?,
	DurationSecs: number?,
	Waveform: string?,
	IsSpoiler: boolean?,
}
export type Emoji = {
	Id: string?,
	Name: string?,
}
type PollMedia = {
	Text: string?,
	Emoji: Emoji?,
}
type PollAnswer = { PollMedia: PollMedia }
export type Poll = {
	Question: { Text: string },
	--- max of 10
	Answers: { PollAnswer },
	--- hours, defaults to 24
	Duration: number?,
	AllowMultiselect: boolean?,
	--- defaults to 1
	LayoutType: number?,
}
type HttpRequestResponse = {
	Success: boolean,
	StatusCode: number,
	StatusMessage: string,
	Headers: { [string]: any },
	Body: unknown,
}

type self = {
	Name: WebhookName,
	Config: WebhookConfig,

	Content: string?,
	Username: string?,
	AvatarUrl: string?,
	Tts: boolean?,
	Embeds: { Embed.Embed },
	AllowedMentions: AllowedMentions?,
	Components: { Component.Component },
	Flags: number?,
	Poll: Poll?,
	ThreadName: string?,
	AppliedTags: { string }?,
}

export type Webhook = typeof(setmetatable({} :: self, Webhook))

-- Create a Webhook instance using a name as defined in Webhook/Config
function module.new(name: WebhookName)
	const config = Config.Webhooks[name]
	assert(config, `Unknown webhook {name} - add it to Config`)

	const self = setmetatable(
		{
			Name = name,
			Config = config,
			Components = {},
			Embeds = {},
		} :: self,
		Webhook
	) :: Webhook

	return self
end

--- Webhook URL should instead be defined as a Secret (or string) in the Webhook/Config module, for security and to avoid repetition.
@deprecated
function Webhook.SetUrl(self: Webhook, url: string | Secret)
	self.Config = table.clone(self.Config)
	self.Config.Url = url

	return self
end

function Webhook.SetContent(self: Webhook, content: string?)
	if content and #content > 2000 then
		warn(`[Webhook/{self.Name}] Content longer than 2000 characters, truncating`)
	end
	self.Content = Utility.truncate(content, 2000)
	return self
end

function Webhook.SetUsername(self: Webhook, username: string?)
	self.Username = username
	return self
end

function Webhook.SetAvatarUrl(self: Webhook, avatarUrl: string?)
	self.AvatarUrl = avatarUrl
	return self
end

function Webhook.SetTts(self: Webhook, tts: boolean?)
	self.Tts = tts
	return self
end

function Webhook.SetFlags(self: Webhook, flags: (number | { number })?)
	if typeof(flags) == "table" then
		flags = bit32.bor(table.unpack(flags))
	end
	self.Flags = flags :: number
	return self
end

function Webhook.SetAllowedMentions(self: Webhook, allowedMentions: AllowedMentions?)
	self.AllowedMentions = allowedMentions
	return self
end

function Webhook.SetAppliedTags(self: Webhook, appliedTags: { string }?)
	self.AppliedTags = appliedTags
	return self
end

function Webhook.SetThreadName(self: Webhook, threadName: string?)
	self.ThreadName = threadName
	return self
end

function Webhook.SetPoll(self: Webhook, poll: Poll?)
	self.Poll = poll
	return self
end

function Webhook.AddComponents(self: Webhook, ...: Component.Component | { Component.Component })
	for _, component in { ... } do
		if getmetatable(component :: any) then
			table.insert(self.Components, component :: Component.Component)
		else
			self:AddComponents(table.unpack(component :: { Component.Component }))
		end
	end

	return self
end

function Webhook.AddEmbeds(self: Webhook, ...: Embed.Embed | { Embed.Embed })
	for _, embed in { ... } do
		if typeof(embed) == "table" then
			self:AddEmbeds(embed)
		else
			table.insert(self.Embeds, embed :: Embed.Embed)
		end
	end

	return self
end

--- Returns whether the webhook can be sent and, if not, a human-readable reason
--- The webhook's config may restrict it to Studio or a specific place/universe
function Webhook.CanSend(self: Webhook): (boolean, string?)
	if not self.Config.EnableInStudio and RunService:IsStudio() then
		return false, "disabled in Studio"
	end

	if self.Config.RestrictToPlaceId and game.PlaceId ~= self.Config.RestrictToPlaceId then
		return false, "wrong place"
	end

	if self.Config.RestrictToUniverseId and game.GameId ~= self.Config.RestrictToUniverseId then
		return false, "wrong universe"
	end

	return true, nil
end

function Webhook.ToTable(self: Webhook): { [string]: any }
	return {
		content = Utility.truncate(self.Content, 2000),
		username = self.Username,
		avatar_url = self.AvatarUrl,
		tts = self.Tts,
		embeds = Utility.map(self.Embeds, function(embed: Embed.Embed)
			return embed:ToTable()
		end),
		allowed_mentions = self.AllowedMentions and {
			parse = self.AllowedMentions.Parse,
			roles = self.AllowedMentions.Roles,
			users = self.AllowedMentions.Users,
			replied_user = self.AllowedMentions.RepliedUser,
		},
		components = Utility.map(self.Components, function(component: Component.Component)
			return component:ToTable()
		end),

		flags = self.Flags,
		poll = self.Poll and {
			question = self.Poll.Question and {
				text = self.Poll.Question.Text,
			},
			answers = Utility.map(self.Poll.Answers, function(answer: PollAnswer)
				return {
					poll_media = {
						text = answer.PollMedia.Text,
						emoji = answer.PollMedia.Emoji and {
							id = answer.PollMedia.Emoji.Id,
							name = answer.PollMedia.Emoji.Name,
						},
					},
				}
			end),
			duration = self.Poll.Duration,
			allow_multiselect = self.Poll.AllowMultiselect,
			layout_type = self.Poll.LayoutType or 1,
		},
		thread_name = self.ThreadName,
		applied_tags = self.AppliedTags,
	}
end

const function postJson(url: string | Secret, payload: { [string]: any }): (boolean, string | HttpRequestResponse)
	return pcall(function()
		return HttpService:RequestAsync({
			-- cast can be removed once PR #1652 in luau-lsp is merged
			Url = url :: string,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode(payload),
		})
	end)
end

function Webhook.SendAsync(self: Webhook): (boolean, string?)
	assert(
		self.Content or (self.Components and #self.Components > 0) or (self.Embeds and #self.Embeds > 0) or self.Poll,
		"Webhook must have content, embeds, components or a poll"
	)
	const isComponentsV2 = bit32.btest(self.Flags or 0, module.MessageFlags.IsComponentsV2)
	assert(not (isComponentsV2 and self.Content), "Content cannot be used with MessageFlags.IsComponentsV2")
	assert(self.Config.Url, "Webhook URL must be set, ideally in Webhook/Config")

	const canSend, cannotSendReason = self:CanSend()
	if not canSend and cannotSendReason then
		if not warnedWebhooks[self.Name] then
			warn(`[Webhook/{self.Name}] This webhook is disabled ({cannotSendReason}), not sending`)
			warnedWebhooks[self.Name] = true
		end
		return false, (cannotSendReason:gsub("^%l", string.upper))
	end

	const url = if typeof(self.Config.Url) == "string"
		then self.Config.Url .. "?with_components=true"
		else self.Config.Url:AddSuffix("?with_components=true")

	const payload = self:ToTable()
	local success, result = postJson(url, payload)
	if Config.MaxRetryDelaySeconds >= 0 and success and typeof(result) == "table" and result.StatusCode == 429 then
		const bodySuccess, retryAfter = pcall(function()
			const body = HttpService:JSONDecode(result.Body :: string)
			return body.retry_after :: number
		end)

		task.wait(
			if bodySuccess and typeof(retryAfter) == "number"
				then math.min(retryAfter, Config.MaxRetryDelaySeconds)
				else if Config.MaxRetryDelaySeconds == math.huge then 10 else Config.MaxRetryDelaySeconds
		)
		success, result = postJson(url, payload)
	end

	if not success then
		return false, "Server error: " .. result :: string
	end

	if typeof(result) == "table" and not result.Success then
		return false, "HTTP error: " .. HttpService:JSONEncode(result.Body)
	end

	return true, nil
end

return module
