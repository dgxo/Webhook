local Utility = {}

function Utility.pascalToSnakeCase(input: string): string
	local result = (input :: string):gsub("(%u)", function(letter)
		return "_" .. letter:lower()
	end)
	return (result:gsub("^_", ""))
end

function Utility.pascalKeysToSnakeCase(input: any): any
	if typeof(input) ~= "table" then
		return input
	end

	if getmetatable(input) then
		return input:ToTable()
	end

	const result = {}
	for key, value in input do
		result[if typeof(key) == "string" then Utility.pascalToSnakeCase(key) else key] =
			Utility.pascalKeysToSnakeCase(value)
	end
	return result
end

function Utility.serialiseColor3(color3: Color3?): number?
	return color3 and tonumber(color3:ToHex(), 16) :: number
end

function Utility.serialiseDateTime(dateTime: DateTime?): string?
	return dateTime and dateTime:ToIsoDate()
end

function Utility.map<T, U>(input: { T }, callback: (T) -> U): { U }
	const output = {}
	for _, value in input do
		table.insert(output, callback(value))
	end
	return output
end

function Utility.truncate(value: string?, maxLength: number): string?
	if not value or typeof(value) ~= "string" then
		return value
	end
	if #value > maxLength then
		return value:sub(1, maxLength - 2) .. "…"
	end
	return value
end

return Utility
