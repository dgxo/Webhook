const HttpService = game:GetService("HttpService")

export type WebhookConfig = {
	Url: Secret | string,

	--- If false, warn (once) and ignore :SendAsync calls if in Studio - default false
	EnableInStudio: boolean?,
	--- Restrict to a specific place ID - default nil
	RestrictToPlaceId: number?,
	--- Restrict to a specific universe ID - default nil
	RestrictToUniverseId: number?,
}

-- Remember to add new webhooks to this union for autocomplete!
export type WebhookName = "Example"

const webhooks: { [WebhookName]: WebhookConfig } = {
	Example = {
		Url = HttpService:GetSecret("example_webhook_url"),
	},
}

return {
	Webhooks = webhooks,
	--- Webhooks will be retried after the lowest of this or Discord's returned
	--- retry_after value.
	--- Set to -1 to never retry, or math.huge for no limit.
	MaxRetryDelaySeconds = 10,
}
