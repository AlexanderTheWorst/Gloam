return function(require)
    local Context = require("./Context.luau")

    local component = {}

    local registry = {}

    function component.setRegistry(value)
        registry = value or {}
    end

    --[[
        @type Component {
            context: Context,
            Destroy: (component) -> ()
        }
    ]]

    --[[
        Creates a component class

        @param inherit?: table
        @return Component
    ]]
    function component.new(inherit, type, viable)
        local self = inherit or {}

        self.context = context or Context()
        self.type = type

        self.OnComponentAdded = function(comp)
            print("I was hooked into the function!", comp.type)
        end

        return setmetatable(self, {
            __index = function(self, index)
                local method = component[index]

                if method then
                    return method
                end

                local constructor = registry[index]

                if constructor and table.find(viable or {}, index) then
                    return function(props)
                        local comp = constructor(props, self.context)

                        self.context:Add(comp.context)
                        comp.Parent = self

                        self.OnComponentAdded(comp)

                        return comp
                    end
                end

                return rawget(self, index)
            end,
        })
    end

    function component.Destroy(self)
        self.context:Destroy()
    end

    return component
end