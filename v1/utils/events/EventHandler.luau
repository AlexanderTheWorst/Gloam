return function (require)
    local events = {}

    local validEvents = require("./Events.luau").Events

    function events.ExtractEvents(props) 
        local extracted = {}
        
        for _, prop in ipairs(props) do
            if typeof(prop) == "table" and prop.type and prop.type == "Event" then
                if not table.find(validEvents, prop.key) then error(`Error: {prop.key} is not a valid event.`) end
                extracted[prop.key] = prop.cb
            end
        end

        return {
            Has = function(ev) return not not extracted[ev] end,
            Fire = function(ev, ...) return extracted[ev](...) end
        }
    end

    return events
end