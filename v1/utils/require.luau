local module = {}

module.cwd =
	"http://127.0.0.1:5500/v1/"

module.cache = {}

local HttpService =
	game:GetService("HttpService")


--[[
	URL
]]

local function stripQuery(url)
	return url:match("^([^?]+)")
		or url
end


local function splitUrl(url)
	url = stripQuery(url)

	local origin, path =
		url:match(
			"^(https?://[^/]+)/(.*)$"
		)

	if origin then
		return origin, path
	end

	origin =
		url:match(
			"^(https?://[^/]+)$"
		)

	if origin then
		return origin, ""
	end

	return nil, nil
end


local function splitPath(path)
	local result = {}

	for part in path:gmatch("[^/]+") do
		table.insert(
			result,
			part
		)
	end

	return result
end


local function normalizePath(path)
	local parts = {}

	for part in path:gmatch("[^/]+") do
		if part == ".." then
			if #parts > 0 then
				table.remove(parts)
			end

		elseif
			part ~= "."
			and part ~= ""
		then
			table.insert(
				parts,
				part
			)
		end
	end

	return table.concat(
		parts,
		"/"
	)
end


local function joinUrl(
	base,
	path
)
	base =
		base:gsub("/+$", "")

	path =
		path:gsub("^/+", "")

	if path == "" then
		return base
	end

	return base
		.. "/"
		.. path
end


local function dirname(path)
	return path:match(
		"^(.*)/[^/]+$"
	) or ""
end


local function isGithubRaw(url)
	return url:match(
		"^https://raw%.githubusercontent%.com/"
	) ~= nil
end


local function parseGithubRaw(url)
	url = stripQuery(url)

	local owner,
		repo,
		ref,
		path =
		url:match(
			"^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.*)$"
		)

	if not owner then
		return nil
	end

	local root =
		"https://raw.githubusercontent.com/"
		.. owner
		.. "/"
		.. repo
		.. "/"
		.. ref
		.. "/"

	return {
		owner = owner,
		repo = repo,
		ref = ref,

		root = root,
		path = path,
	}
end


--[[
	Resolve

	All non-absolute paths are relative.

	./Foo
	../Foo
	Foo

	all work.
]]

function module.resolve(
	to,
	from
)
	if type(to) ~= "string" then
		error(
			"resolve expected string, got "
				.. typeof(to)
				.. "\nFrom: "
				.. tostring(from),
			2
		)
	end

	-- Already absolute.
	if to:match("^https?://") then
		return to
	end

	local baseUrl
	local baseIsDirectory

	if from then
		baseUrl = from
		baseIsDirectory = false
	else
		baseUrl = module.cwd
		baseIsDirectory = true
	end

	local origin, basePath =
		splitUrl(baseUrl)

	if
		not origin
		or basePath == nil
	then
		error(
			"Invalid base URL: "
				.. tostring(baseUrl)
		)
	end

	local baseDirectory

	if baseIsDirectory then
		baseDirectory =
			basePath:gsub("/+$", "")
	else
		baseDirectory =
			dirname(basePath)
	end

	local path

	if to:sub(1, 1) == "/" then
		path =
			to:sub(2)
	else
		path =
			baseDirectory
			.. "/"
			.. to
	end

	path =
		normalizePath(path)

	return joinUrl(
		origin,
		path
	)
end


--[[
	HTTP
]]

local function get(url)
	local response =
		httpget(url)

	if
		not response
		or response == ""
	then
		error(
			"Empty HTTP response"
				.. "\nURL: "
				.. tostring(url)
		)
	end

	return response
end


--[[
	Source
]]

local function fetchSource(url)
	return get(url)
end


--[[
	Relative paths
]]

local function relativeUrl(
	target,
	base
)
	local targetOrigin,
		targetPath =
		splitUrl(target)

	local baseOrigin,
		basePath =
		splitUrl(base)

	if
		not targetOrigin
		or not baseOrigin
	then
		error(
			"Invalid URL while creating relative path."
		)
	end

	if targetOrigin ~= baseOrigin then
		return target
	end

	local baseDirectory =
		dirname(basePath)

	local targetParts =
		splitPath(targetPath)

	local baseParts =
		splitPath(baseDirectory)

	local common = 0

	while
		common < #targetParts
		and common < #baseParts
		and targetParts[common + 1]
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

	for i = common + 1, #targetParts do
		table.insert(
			result,
			targetParts[i]
		)
	end

	if #result == 0 then
		return "./"
	end

	return "./"
		.. table.concat(
			result,
			"/"
		)
end


local function formatGlobPath(
	path,
	from,
	pathType
)
	if pathType ~= "relative" then
		return path
	end

	if from then
		return relativeUrl(
			path,
			from
		)
	end

	-- Public Module.glob(..., nil, {path="relative"})
	-- makes it relative to cwd.
	local fakeModule =
		module.cwd:gsub("/+$", "")
		.. "/__root__.luau"

	return relativeUrl(
		path,
		fakeModule
	)
end


--[[
	Glob matching
]]

local luaMagic = {
	["^"] = true,
	["$"] = true,
	["("] = true,
	[")"] = true,
	["%"] = true,
	["."] = true,
	["["] = true,
	["]"] = true,
	["+"] = true,
	["-"] = true,
	["?"] = true,
}


local function segmentMatches(
	value,
	pattern
)
	local converted = {}

	for i = 1, #pattern do
		local char =
			pattern:sub(i, i)

		if char == "*" then
			table.insert(
				converted,
				".*"
			)

		elseif luaMagic[char] then
			table.insert(
				converted,
				"%"
					.. char
			)

		else
			table.insert(
				converted,
				char
			)
		end
	end

	local luaPattern =
		"^"
		.. table.concat(converted)
		.. "$"

	return value:match(
		luaPattern
	) ~= nil
end


local function globMatches(
	pattern,
	path
)
	local patternParts =
		splitPath(pattern)

	local pathParts =
		splitPath(path)

	local function match(
		patternIndex,
		pathIndex
	)
		if
			patternIndex
			> #patternParts
		then
			return pathIndex
				> #pathParts
		end

		local patternPart =
			patternParts[
				patternIndex
			]

		if patternPart == "**" then
			-- ** matches zero segments.
			if
				match(
					patternIndex + 1,
					pathIndex
				)
			then
				return true
			end

			-- ** matches one or more segments.
			if
				pathIndex <= #pathParts
			then
				return match(
					patternIndex,
					pathIndex + 1
				)
			end

			return false
		end

		if pathIndex > #pathParts then
			return false
		end

		if
			not segmentMatches(
				pathParts[pathIndex],
				patternPart
			)
		then
			return false
		end

		return match(
			patternIndex + 1,
			pathIndex + 1
		)
	end

	return match(1, 1)
end


--[[
	GitHub manifest

	files.json exists at repository root.

	Example:
	https://raw.githubusercontent.com/
	    user/repo/main/files.json
]]

local githubManifests = {}


local function getGithubManifest(url)
	local github =
		parseGithubRaw(url)

	if not github then
		error(
			"Invalid raw GitHub URL: "
				.. tostring(url)
		)
	end

	local cache =
		githubManifests[
			github.root
		]

	if cache then
		return cache, github
	end

	local manifestUrl =
		github.root
		.. "files.json"

	local response =
		get(manifestUrl)

	local success, manifest =
		pcall(
			HttpService.JSONDecode,
			HttpService,
			response
		)

	if not success then
		error(
			"Failed to parse files.json"
				.. "\nURL: "
				.. manifestUrl
				.. "\nResponse:\n"
				.. response:sub(
					1,
					1000
				)
		)
	end

	if typeof(manifest) ~= "table" then
		error(
			"Invalid files.json manifest: "
				.. manifestUrl
		)
	end

	githubManifests[
		github.root
	] = manifest

	return manifest, github
end


local function globGithub(
	absolutePattern,
	from,
	pathType
)
	local manifest, github =
		getGithubManifest(
			absolutePattern
		)

	-- absolutePattern is already repo-relative
	-- after the raw GitHub prefix.
	local patternPath =
		github.path

	local results = {}

	for _, filePath in manifest do
		if
			type(filePath) == "string"
			and globMatches(
				patternPath,
				filePath
			)
		then
			local url =
				github.root
				.. filePath

			table.insert(
				results,
				formatGlobPath(
					url,
					from,
					pathType
				)
			)
		end
	end

	return results
end


--[[
	Local directory listing
]]

local function listDirectory(
	directory
)
	local requestUrl =
		directory

	if
		requestUrl:sub(-1)
		~= "/"
	then
		requestUrl ..= "/"
	end

	local response =
		get(requestUrl)

	local success, listing =
		pcall(
			HttpService.JSONDecode,
			HttpService,
			response
		)

	if not success then
		error(
			"Failed to parse local directory listing"
				.. "\nURL: "
				.. requestUrl
				.. "\nResponse:\n"
				.. response:sub(
					1,
					1000
				)
		)
	end

	if typeof(listing) ~= "table" then
		error(
			"Invalid local directory listing"
				.. "\nURL: "
				.. requestUrl
		)
	end

	local results = {}

	for _, file in listing do
		local fileType

		if
			file.type == "directory"
			or file.type == "dir"
		then
			fileType = "directory"
		else
			fileType = "file"
		end

		table.insert(
			results,
			{
				name = file.name,

				type = fileType,

				url = joinUrl(
					directory,
					file.name
				),
			}
		)
	end

	return results
end


local function globLocal(
	absolutePattern,
	from,
	pathType
)
	local origin,
		path =
		splitUrl(
			absolutePattern
		)

	if not origin then
		error(
			"Invalid glob URL: "
				.. absolutePattern
		)
	end

	local parts =
		splitPath(path)

	local wildcardIndex

	for i, part in parts do
		if
			part:find(
				"*",
				1,
				true
			)
		then
			wildcardIndex = i
			break
		end
	end

	-- No wildcard.
	if not wildcardIndex then
		return {
			formatGlobPath(
				absolutePattern,
				from,
				pathType
			),
		}
	end

	local prefix = {}

	for i = 1, wildcardIndex - 1 do
		table.insert(
			prefix,
			parts[i]
		)
	end

	local directory =
		joinUrl(
			origin,
			table.concat(
				prefix,
				"/"
			)
		)

	local results = {}


	local function walk(
		currentDirectory,
		index
	)
		local part =
			parts[index]

		if not part then
			return
		end

		local listing =
			listDirectory(
				currentDirectory
			)

		if part == "**" then
			-- Zero directories.
			walk(
				currentDirectory,
				index + 1
			)

			-- One or more directories.
			for _, entry in listing do
				if
					entry.type
					== "directory"
				then
					walk(
						entry.url,
						index
					)
				end
			end

			return
		end

		for _, entry in listing do
			if
				segmentMatches(
					entry.name,
					part
				)
			then
				if index == #parts then
					table.insert(
						results,
						formatGlobPath(
							entry.url,
							from,
							pathType
						)
					)

				elseif
					entry.type
					== "directory"
				then
					walk(
						entry.url,
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
	Glob
]]

function module.glob(
	pattern,
	from,
	options
)
	if type(pattern) ~= "string" then
		error(
			"glob expected string, got "
				.. typeof(pattern),
			2
		)
	end

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

	local absolutePattern =
		module.resolve(
			pattern,
			from
		)

	if isGithubRaw(absolutePattern) then
		return globGithub(
			absolutePattern,
			from,
			pathType
		)
	end

	return globLocal(
		absolutePattern,
		from,
		pathType
	)
end


--[[
	Require
]]

function module.require(
	str,
	from
)
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
			source =
				fetchSource(
					target
				),

			module = nil,

			loading = false,
			loaded = false,
		}

		module.cache[target] =
			entry
	end

	if entry.loaded then
		return entry.module
	end

	-- Circular dependency.
	if entry.loading then
		return entry.module
	end

	entry.loading = true

	entry.module = {}

	local chunk,
		loadError =
		loadstring(
			entry.source
		)

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
		setmetatable(
			{
				glob = function(
					pattern,
					options
				)
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
			},
			{
				__call = function(
					_,
					path
				)
					return module.require(
						path,
						target
					)
				end,
			}
		)

	local success,
		result =
		pcall(
			factory,
			require
		)

	if not success then
		entry.loading = false

		error(
			"Failed to execute module "
				.. target
				.. ":\n"
				.. tostring(result)
		)
	end

	entry.module = result

	entry.loading = false
	entry.loaded = true

	return entry.module
end


return module