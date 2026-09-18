return function (require)
    --[[
        @type Context {
            Add: (Context, any) -> () -> (),
            Destroy: (Context) -> ()
        }
    ]]

    --[[
        Creates a context.

        @return Context
    ]]
    local function Context()
        local context = {
            type = "Context",

            junk = {}
        }

        function context.Add(ctx, junk)
            table.insert(context.junk, junk)

            return function() 
                table.remove(contex.junk, table.find(context.junk, junk))
            end
        end

        function context.Destroy(ctx)
            for _, junk in context.junk do
                if typeof(junk) == "function" then
                    junk()
                    continue
                end

                if typeof(junk) == "Instance" then
                    junk:Destroy()
                    continue
                end

                if typeof(junk) == "RBXScriptConnection" then
                    junk:Disconnect()
                    continue
                end

                if typeof(junk) == "table" then
                    if junk["Destroy"] ~= nil then
                        junk:Destroy()
                    end
                end
            end

            context.junk = {}
        end

        return context
    end

    return Context
end