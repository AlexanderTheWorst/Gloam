return function(require)
    --[[
        @type IconPackOptions {
            variant?: string
        }

        @type IconPack {
            type: "IconPack",
            pack: string,
            variant?: string,
            options?: IconPackOptions
        }
    ]]

    local IconPacks = require("./IconPacks.luau")

    --[[
        Creates an IconPack object.
        
        @param desired: string
        @param options?: IconPackOptions

        @return IconPack
    ]]
    local function IconPack(desired, options)
        if options ~= nil and typeof(options) ~= "table" then
            error("Error: Provided IconPack options is invalid")
        end

        local pack = IconPacks[desired]

        if pack == nil then
            error("Error: Requested IconPack does not exist in the registry.")
        end

        if typeof(pack) ~= "table" then
            error("Error: IconPack in registry is invalid.")
        end

        if options == nil or options.variant == nil then
            return {
                type = "IconPack",
                pack = desired,
                options = options,
            }
        end

        if pack.variants == nil then
            error("Error: Variant was requested but IconPack is static.")
        end

        local variant = pack.variants[options.variant]

        if variant == nil then
            error("Error: Requested variant does not exist in IconPack.")
        end

        return {
            type = "IconPack",
            pack = desired,
            variant = options.variant,
            options = options,
        }
    end

    --[[
        Validates an IconPack object.

        @param pack?: IconPack

        @return boolean
    ]]
    local function validateIconPack(pack)
        return typeof(pack) == "table"
            and pack.type
            and pack.type == "IconPack"
    end

    --[[
        Resolves an IconPack to an IconPackLoader
        
        @param pack?: IconPack

        @return IconPackLoader
    ]]
    local function resolveIconPack(pack)
        if not validateIconPack(pack) then
            return
        end

        if IconPacks[pack.pack] and not pack.variant then
            return IconPacks[pack.pack]
        end

        if pack.variant then
            return IconPacks[pack.pack].variants[pack.variant]
        end

        return
    end

    return {
        IconPack = IconPack,
        validateIconPack = validateIconPack,
        resolveIconPack = resolveIconPack,
    }
end