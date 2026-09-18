return function(require)

    local ContentProvider = game:GetService("ContentProvider")

    --[[
        @type IconPackLoader {
            loaded: boolean,
            Icons: { [string]: string },
            Icon: (string) -> string,
            Preload: ({ string }, (({ string }, { string }, number) -> nil)) -> nil,
            Load: () -> nil
        }
    ]]

    --[[
        Creates an IconPackLoader.

        @param url string

        @return IconPackLoader
    ]]
    local function IconPackLoader(url)
        if typeof(url) ~= "string" then
            error("Error: Pack provided is invalid!")
        end

        local loader = {
            loaded = false,
            Icons = {},
        }

        function loader.Preload(icons, updateCb)
            if not loader.loaded then
                loader.Load()
            end

            local assetIds = {}
            local iconIndex = {}

            for _, icon in icons do

                local assetId = loader.Icon(icon)

                if not iconIndex[assetId] then
                    iconIndex[assetId] = icon
                    table.insert(assetIds, assetId)
                end

            end

            local succeeded = {}
            local failed = {}

            ContentProvider:PreloadAsync(assetIds, function(assetId, status)

                local iconName = iconIndex[assetId]

                if status == Enum.AssetFetchStatus.Success then
                    table.insert(succeeded, iconName)

                elseif status == Enum.AssetFetchStatus.Failure then
                    table.insert(failed, iconName)
                end

                updateCb(succeeded, failed, #assetIds)

            end)
        end

        function loader.Load()

            if loader.loaded then
                return
            end

            local code = httpget(url)

            if not code then
                error("Error: Pack provided is invalid!")
            end

            local icons = loadstring(code)()

            if typeof(icons) ~= "table" then
                error("Error: Icon pack returned invalid data!")
            end

            for name, asset in icons do
                loader.Icons[name:lower()] = asset
            end

            loader.loaded = true
        end

        function loader.Icon(icon)

            if typeof(icon) ~= "string" then
                error("Error: Icon name must be a string!")
            end

            loader.Load()

            local key = icon:lower()
            local asset = loader.Icons[key]

            if not asset then
                error(
                    `Error: Requested icon "{icon}" does not exist in pack.`
                )
            end

            return asset
        end

        return loader
    end

    return IconPackLoader
end