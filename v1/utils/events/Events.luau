return function (require)
    local events = { 
        -- Global
        "onClick",
        "onChange",

        -- Toggle
        "onToggle"
    }

    return {
        Events = events,
        EventsDescriptor = setmetatable({}, {
            __index = function(self, index)
                if table.find(events, index) then
                    return function(cb)
                        return {
                            type = "Event",
                            key = index,
                            cb = cb
                        }
                    end
                end
            end
        })
    }
end