return function(require)
    local registry = {}

    local directory = require.resolve("../components/")

    for _, path in require.glob("../components/*.luau") do
        local name = path:sub(#directory + 2, -6)

        if registry[name] then
            return registry[name]
        end

        registry[name] = require(path)
    end

    return registry
end