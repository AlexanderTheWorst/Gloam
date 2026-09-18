return function(require)
    --[[
        @type Icon {
            type: "Icon",
            icon: string,
            pack?: IconPack -- default: nil
        }
    ]]

    local IconPack = require("./IconPack.luau")

    --[[
        Creates an Icon descriptor.

        @param icon: string
        @param pack?: IconPack -- default: nil

        @return Icon
    ]]
    local function Icon(icon, pack)
        if pack and not IconPack.validateIconPack(pack) then
            error("Error: Provided IconPack is not valid.")
        end

        return {
            type = "Icon",
            icon = icon,
            pack = pack
        }
    end

    --[[
        Validates an Icon descriptor.

        @param icon: Icon

        @return boolean
    ]]
    local function validateIcon(icon)
        return typeof(icon) == "table"
            and icon.type
            and icon.type == "Icon"
    end

    --[[
        Resolves an Icon to a roblox asset id

        @param icon: Icon
        @param pack: IconPack

        @return string
    ]]
    local function resolveIcon(icon, pack)
        if not validateIcon(icon) then
            return
        end

        local targetPack = icon.pack or pack
        if not IconPack.validateIconPack(targetPack) then
            return
        end

        local iconPackLoader = IconPack.resolveIconPack(targetPack)
        local resolvedIcon = iconPackLoader.Icon(icon.icon)

        return resolvedIcon
    end

    return {
        Icon = Icon,
        validateIcon = validateIcon,
        resolveIcon = resolveIcon,
    }
end