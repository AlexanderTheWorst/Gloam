local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
return function (require)
    local Component = require("../classes/Component.luau")

    local IconPackUtils = require("../utils/icons/IconPack.luau")
    local IconPack = IconPackUtils.IconPack

    --[[
        @type ScreenProps {
            id: string,

            iconPack?: IconPack -- default: IconPack<RemixIcon>
        }

        @type Screen {
            Instance: ScreenGUI,

            props: ScreenProps,
            context: Context,

            Destroy: (Screen) -> ()
        }
    ]]

    --[[
	    Creates a screen component.

        @param props: ScreenProps

        @return Screen
    ]]
    return function (props)
        -- Validation

        if typeof(props) ~= "table" then
            return error("Error: Provided screen props is invalid.")
        end
        
        if not props.id then
            return error("Error: Provided screen props is missing `id`.")
        end

        -- Cleaning up if there is a previous with same `id`

        if _G._Contexts and _G._Contexts[props.id] then
            _G._Contexts[props.id]:Destroy()
        end

        -- Creating `self`

        local self = Component.new(
            {
                props = props
            }, 
            "Screen",
            { "Window" }
        )

        -- Kickstarting GUI

        local ScreenGUI = Instance.new("ScreenGui")

        -- Creating top-level settings

        local screenContext = {
            settings = {
                iconPack = props.iconPack or IconPack("Remix")
            },
            globalGUI = ScreenGUI
        }

        -- Creating `context`

        setmetatable(self.context, {
            __index = screenContext
        })

        -- Registering context with identity `id`

        if not _G._Contexts then
            _G._Contexts = {}
        end

        _G._Contexts[props.id] = self.context

        -- UI

        ScreenGUI.IgnoreGuiInset = true
        ScreenGUI.ResetOnSpawn = false
        ScreenGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGUI.Parent = RunService:IsStudio() and Players.LocalPlayer.PlayerGui or game:GetService("CoreGui")

        self.context:Add(ScreenGUI)

        -- Runtime

        self.OnComponentAdded = function(comp) 
            if typeof(comp) ~= "table" or not comp.type then
                return error("Error: Provided component is invalid.")
            end

            if comp.type == "Window" then
                if not comp.Instance then
                    return error("Error: Provided window component is invalid.")
                end

                comp.Instance.Parent = ScreenGUI
            end

            return
        end

        -- Handling all the loading UI animations

        local LoadingUIs = {}

        local LOADING_UI_SPACING = 50
        local LOADING_UI_TWEEN = TweenInfo.new(
            .5,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.InOut
        )

        local function UpdateLoadingUIs()
            for i, entry in ipairs(LoadingUIs) do
                local offset = i * -LOADING_UI_SPACING

                TweenService:Create(entry.ui.Instance, LOADING_UI_TWEEN, {
                    Position = UDim2.new(.5, 0, 1, offset - 10 * (i - 1)),
                }):Play()
            end
        end

        local function AddLoadingUI(ui)
            table.insert(LoadingUIs, {
                ui = ui,
            })

            ui.Instance.Parent = ScreenGUI
            self.context:Add(ui.Context)

            UpdateLoadingUIs()
        end

        local LOADING_UI_REMOVE_DELAY = .2

        local function RemoveLoadingUI(ui)
            local index

            for i, entry in ipairs(LoadingUIs) do
                if entry.ui == ui then
                    index = i
                    break
                end
            end

            if not index then
                return
            end

            -- Delay based on its position in the stack.
            task.delay((index - 1) * LOADING_UI_REMOVE_DELAY, function()
                -- Re-check because the stack may have changed while waiting.
                local currentIndex

                for i, entry in ipairs(LoadingUIs) do
                    if entry.ui == ui then
                        currentIndex = i
                        break
                    end
                end

                if not currentIndex then
                    return
                end

                table.remove(LoadingUIs, currentIndex)

                TweenService:Create(ui.Instance, LOADING_UI_TWEEN, {
                    Position = UDim2.new(.5, 0, 1, 50),
                }):Play()

                UpdateLoadingUIs()

                task.delay(.5, function()
                    ui.Context:Destroy()
                end)
            end)
        end
        -- Creating and handling loading states

        local loadingStates = {
            icons = false,
        }

        local loadingStateKilled = false

        self.context:Add(function()
            loadingStateKilled = true
        end)

        if screenContext.settings.iconPack.options and screenContext.settings.iconPack.options.preload then
            local icons = screenContext.settings.iconPack.options.preload

            local iconsLoadingUI = LoadingUI(context, {
                count = #icons,
                label = "Icons",
            })

            AddLoadingUI(iconsLoadingUI)

            loadingStates.icons = true

            task.delay(.5, function()
                ResolveIconPack(screenContext.settings.iconPack).Preload(
                    icons,
                    function(succeeded, failed, count)
                        local completed = #succeeded + #failed
                        iconsLoadingUI:UpdateProgress(completed, count)
                        if completed == count then
                            task.delay(.5, function() 
                                loadingStates.icons = false
                            end)

                            RemoveLoadingUI(iconsLoadingUI)
                        end
                    end
                )
            end)
        end

        local function finishedLoading()
            for key, loading in ipairs(loadingStates) do
                if loading then
                    return false
                end
            end

            return true
        end

        while not finishedLoading() and not loadingStateKilled do
            task.wait() 
        end

        return self
    end
end