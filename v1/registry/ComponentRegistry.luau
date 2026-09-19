return function(require)
    local registry = {}

    local directory = require.resolve("../components/")
    local paths = require.glob("../components/*.luau")

    for _, path in ipairs(paths) do
        local name = path:sub(#directory + 2, -6)

        if registry[name] then
            return registry[name]
        end

        registry[name] = require(path)
    end

    return registry
end