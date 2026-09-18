local module = {}

module.cwd = "http://127.0.0.1:5500/v1/"

module.cache = {}

local HttpService = game:GetService("HttpService")


--[[
	URL helpers
]]

local function stripQuery(url)
	return url:match("^([^?]+)") or url
end

local function getQuery(url)
	return url:match("(%?.*)$")
end

local function isGithubContents(url)
	return url:match(
		"^https://api%.github%.com/repos/[^/]+/[^/]+/contents"
	) ~= nil
end

local function isGithubRaw(url)
	return url:match(
		"^https://raw%.githubusercontent%.com/"
	) ~= nil
end

local function appendPath(url, path)
	local query = getQuery(url)
	local base = stripQuery(url)

	base = base:gsub("/+$", "")
	path = path:gsub("^/+", "")

	local result = base .. "/" .. path

	if query then
		result ..= query
	end

	return result
end

local function normalizeUrl(url)
	local query = getQuery(url)
	local base = stripQuery(url)

	local protocol, rest =
		base:match("^(https?://)(.*)$")

	if not protocol then
		return url
	end

	local host, path =
		rest:match("^([^/]+)/(.*)$")

	if not host then
		return url
	end

	local parts = {}

	for part in path:gmatch("[^/]+") do
		if part == ".." then
			if #parts > 0 then
				table.remove(parts)
			end
		elseif part ~= "." and part ~= "" then
			table.insert(parts, part)
		end
	end

	local result =
		protocol
		.. host
		.. "/"
		.. table.concat(parts, "/")

	if query then
		result ..= query
	end

	return result
end


--[[
	Convert:

	https://raw.githubusercontent.com/User/Repo/main/path/file.luau

	into:

	https://api.github.com/repos/User/Repo/contents/path/file.luau?ref=main
]]

local function rawToContents(url)
	local owner, repo, ref, path =
		url:match(
			"^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.*)$"
		)

	if not owner then
		return nil
	end

	local result =
		"https://api.github.com/repos/"
		.. owner
		.. "/"
		.. repo
		.. "/contents"

	if path and path ~= "" then
		result ..= "/" .. path
	end

	result ..= "?ref=" .. ref

	return result
end


--[[
	Resolve module paths
]]

function module.resolve(to, from)
	-- Already absolute.
	if to:match("^https?://") then
		return to
	end

	-- Resolve against cwd.
	if not from then
		return appendPath(
			module.cwd,
			to:gsub("^%./", "")
		)
	end

	local query = getQuery(from)
	local cleanFrom = stripQuery(from)

	local origin =
		cleanFrom:match("^(https?://[^/]+)")

	local currentPath =
		cleanFrom:match("^https?://[^/]+/(.*)$")

	if not origin or not currentPath then
		error(
			"Invalid module URL: "
				.. tostring(from)
		)
	end

	-- Remove filename from parent.
	local directory =
		currentPath:match("^(.*)/[^/]+$")
		or ""

	local path =
		directory
		.. "/"
		.. to

	local parts = {}

	for part in path:gmatch("[^/]+") do
		if part == ".." then
			if #parts > 0 then
				table.remove(parts)
			end
		elseif part ~= "." then
			table.insert(parts, part)
		end
	end

	local result =
		origin
		.. "/"
		.. table.concat(parts, "/")

	-- Preserve ?ref=main for GitHub Contents URLs.
	if
		query
		and isGithubContents(from)
	then
		result ..= query
	end

	return result
end

--[[
	Read a module source.

	Supports:

	- static-web-server
	- raw.githubusercontent.com
	- api.github.com/repos/.../contents/...
]]

local function fetchSource(url)
	-- GitHub Contents API.
	if isGithubContents(url) then
		local response = httpget(url)

		if not response then
			error(
				"Failed to retrieve GitHub file: "
					.. url
			)
		end

		local data =
			HttpService:JSONDecode(response)

		if typeof(data) ~= "table" then
			error(
				"Invalid GitHub Contents response: "
					.. url
			)
		end

		if data.type ~= "file" then
			error(
				"Expected a file from GitHub Contents API: "
					.. url
			)
		end

		-- Prefer raw source.
		if data.download_url then
			local source =
				httpget(data.download_url)

			if not source then
				error(
					"Failed to retrieve GitHub raw file: "
						.. data.download_url
				)
			end

			return source
		end

		error(
			'GitHub file did not contain a "download_url": '
				.. url
		)
	end

	-- Raw GitHub / static server.
	local source = httpget(url)

	if not source then
		error(
			"Failed to retrieve module: "
				.. url
		)
	end

	return source
end

--[[
	List a directory.

	Normalizes static-web-server and GitHub Contents
	into:

	{
		{
			name = "...",
			type = "file" | "directory",
			url = "..."
		}
	}
]]

local function listDirectory(directory)
	local requestUrl = directory

	-- raw.githubusercontent.com cannot list directories.
	if isGithubRaw(requestUrl) then
		requestUrl = rawToContents(requestUrl)

		if not requestUrl then
			error(
				"Failed to convert raw GitHub URL to Contents API: "
					.. tostring(directory)
			)
		end
	end

	-- static-web-server expects trailing slash for directories
	if
		not isGithubContents(requestUrl)
		and requestUrl:sub(-1) ~= "/"
	then
		requestUrl ..= "/"
	end

	local response = httpget(requestUrl)

	if not response then
		error(
			"Failed to retrieve directory: "
				.. tostring(requestUrl)
		)
	end

	local success, listing =
		pcall(
			HttpService.JSONDecode,
			HttpService,
			response
		)

	if not success then
		error(
			"Failed to parse directory JSON"
				.. "\nURL: "
				.. tostring(requestUrl)
				.. "\nResponse:\n"
				.. tostring(response):sub(1, 1000)
		)
	end

	if typeof(listing) ~= "table" then
		error(
			"Directory response was not a table"
				.. "\nURL: "
				.. tostring(requestUrl)
		)
	end

	local result = {}

	-- GitHub Contents API
	if isGithubContents(requestUrl) then
		-- Directory responses are arrays.
		-- A file response is an object with .type.
		if listing.type ~= nil then
			error(
				"Expected GitHub directory, received "
					.. tostring(listing.type)
					.. "\nURL: "
					.. tostring(requestUrl)
			)
		end

		for _, file in listing do
			local fileType =
				if file.type == "dir"
					then "directory"
					else "file"

			table.insert(result, {
				name = file.name,
				type = fileType,

				-- Keep Contents API URLs internally
				url = file.url,

				apiUrl = file.url,
				downloadUrl = file.download_url,
			})
		end

		return result
	end

	-- static-web-server
	for _, file in listing do
		local fileType =
			if
				file.type == "directory"
				or file.type == "dir"
			then
				"directory"
			else
				"file"

		table.insert(result, {
			name = file.name,
			type = fileType,
			url = appendPath(
				directory,
				file.name
			),
		})
	end

	return result
end


--[[
	Glob
]]

function module.glob(pattern, from, options)
	options = options or {}

	local pathType =
		options.path
		or "resolved"

	if
		pathType ~= "resolved"
		and pathType ~= "relative"
	then
		error(
			`Invalid glob path type "{pathType}". Expected "resolved" or "relative".`
		)
	end

	local results = {}

	local parts = {}

	for part in pattern:gmatch("[^/]+") do
		table.insert(parts, part)
	end

	-- Find first wildcard.
	local wildcardIndex

	for i, part in parts do
		if part:find("*", 1, true) then
			wildcardIndex = i
			break
		end
	end

	-- No wildcard.
	if not wildcardIndex then
		local path =
			module.resolve(
				pattern,
				from
			)

		if pathType == "relative" then
			return {
				pattern,
			}
		end

		return {
			path,
		}
	end

	-- Resolve everything before wildcard.
	local prefix =
		table.concat(
			parts,
			"/",
			1,
			wildcardIndex - 1
		)

	local directory =
		module.resolve(
			prefix,
			from
		)

	local function matches(name, pattern)
		local luaPattern =
			pattern
				:gsub("%%", "%%%%")
				:gsub("%.", "%%.")
				:gsub("%*", ".*")

		return name:match(
			"^"
				.. luaPattern
				.. "$"
		) ~= nil
	end

	local function relative(path, base)
		local cleanPath =
			stripQuery(path)

		local cleanBase =
			stripQuery(base)

		local pathOrigin =
			cleanPath:match(
				"^(https?://[^/]+)"
			)

		local pathPart =
			cleanPath:match(
				"^https?://[^/]+/(.*)$"
			)

		local baseOrigin =
			cleanBase:match(
				"^(https?://[^/]+)"
			)

		local basePart =
			cleanBase:match(
				"^https?://[^/]+/(.*)$"
			)

		if
			not pathOrigin
			or not pathPart
		then
			error(
				"Invalid path: "
					.. tostring(path)
			)
		end

		if
			not baseOrigin
			or not basePart
		then
			error(
				"Invalid base path: "
					.. tostring(base)
			)
		end

		if pathOrigin ~= baseOrigin then
			return path
		end

		local baseDirectory =
			basePart:match(
				"^(.*)/[^/]+$"
			)
			or ""

		local pathParts = {}
		local baseParts = {}

		for part in pathPart:gmatch("[^/]+") do
			table.insert(
				pathParts,
				part
			)
		end

		for part in baseDirectory:gmatch("[^/]+") do
			table.insert(
				baseParts,
				part
			)
		end

		local common = 0

		while
			common < #pathParts
			and common < #baseParts
			and pathParts[common + 1]
				== baseParts[common + 1]
		do
			common += 1
		end

		local result = {}

		for _ = common + 1, #baseParts do
			table.insert(
				result,
				".."
			)
		end

		for i = common + 1, #pathParts do
			table.insert(
				result,
				pathParts[i]
			)
		end

		return "./"
			.. table.concat(
				result,
				"/"
			)
	end

	local function formatPath(path)
		if
			pathType == "relative"
			and from
		then
			return relative(
				path,
				from
			)
		end

		return path
	end

	local function walk(directory, index)
		local part =
			parts[index]

		if not part then
			return
		end

		local listing =
			listDirectory(directory)

		-- ** = zero or more directories
		if part == "**" then
			-- Zero directories.
			walk(
				directory,
				index + 1
			)

			-- One or more directories.
			for _, file in listing do
				if file.type == "directory" then
					walk(
						file.url,
						index
					)
				end
			end

			return
		end

		for _, file in listing do
			if matches(file.name, part) then
				if index == #parts then
					table.insert(
						results,
						formatPath(
							file.url
						)
					)
				elseif file.type == "directory" then
					walk(
						file.url,
						index + 1
					)
				end
			end
		end
	end

	walk(
		directory,
		wildcardIndex
	)

	return results
end


--[[
	Require
]]

function module.require(str, from)
    if type(str) ~= "string" then
		error(
			"require expected a string, got "
				.. typeof(str)
				.. " ("
				.. tostring(str)
				.. ")"
				.. "\nRequired from: "
				.. tostring(from),
			2
		)
	end

	local target =
		module.resolve(
			str,
			from
		)

	local entry =
		module.cache[target]

	if not entry then
		entry = {
			source = fetchSource(target),
			module = nil,
			loading = false,
			loaded = false,
		}

		module.cache[target] = entry
	end

	-- Already loaded.
	if entry.loaded then
		return entry.module
	end

	-- Cyclic dependency.
	if entry.loading then
		return entry.module
	end

	entry.loading = true
	entry.module = {}

	local chunk, loadError =
		loadstring(entry.source)

	if not chunk then
		entry.loading = false

		error(
			"Failed to compile module "
				.. target
				.. ":\n"
				.. tostring(loadError)
		)
	end

	local factory =
		chunk()

	if typeof(factory) ~= "function" then
		entry.loading = false

		error(
			"Module did not return a factory function: "
				.. target
		)
	end

	local require =
		setmetatable({
			glob = function(pattern, options)
				return module.glob(
					pattern,
					target,
					options
				)
			end,

			resolve = function(to)
				return module.resolve(
					to,
					target
				)
			end,

			source = target,
		}, {
			__call = function(_, path)
				return module.require(
					path,
					target
				)
			end,
		})

	entry.module =
		factory(require)

	entry.loading = false
	entry.loaded = true

	return entry.module
end

return module