return function (require)
    local IconPackLoader = require("./IconPackLoader.luau")

    local packs = require.glob("../../../Icons/**/assets.luau")
    local dir = require.resolve("../../../Icons/")

    local resolvedPacks = {}

    for _, pack in packs do
        local target = pack:split(dir)[2]:sub(2)

        local slashCount = select(2, target:gsub("/", ""))

        local split = target:split("/")
        local name = split[1]

        if slashCount == 1 then
            resolvedPacks[name] = IconPackLoader(pack)
        elseif slashCount == 2 then
            local variant = split[2]
            if not resolvedPacks[name] then
                resolvedPacks[name] = { variants = {} }
            end
            resolvedPacks[name].variants[variant] = IconPackLoader(pack)
        end
    end

    return resolvedPacks
end