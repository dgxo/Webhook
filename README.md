# Webhook

A nice way to send Discord webhooks in Roblox.

It supports everything you can do with a webhook, except uploading files (yet).

## Getting Started

Download [Webhook.rbxm](https://github.com/dgxo/Webhook/releases/latest/download/Webhook.rbxm)
from Releases, and add it to ServerStorage (or wherever you want it).

> [!WARNING]
> Don't put the module in ReplicatedStorage, or anywhere else the client can
> access. Even if you are using Secrets, it's better to be safe.

You'll need to then define the URLs and config for your webhooks.

In the library's Config module, add a new entry to the table for each webhook
you want. It is highly recommended to use [Secrets](https://create.roblox.com/docs/cloud-services/secrets) for Urls, for security, but
if you must you can use strings.

To use and send a webhook (for example):

```luau
const ServerStorage = game:GetService("ServerStorage")
const Webhook = require(ServerStorage.Modules.Webhook) -- replace with your path
const Component = require(ServerStorage.Modules.Webhook.Component)

const webhook = Webhook.new("Example")
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
```

## Contributing

Clone the repo:

```bash
git clone https://github.com/dgxo/Webhook.git
```

Install dependencies - [install Rokit](https://github.com/rojo-rbx/rokit) if you don't have it:

```bash
rokit install
```

Make your changes, and build:

```bash
rojo build --output Webhook.rbxm
```
