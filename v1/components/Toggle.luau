return function(require)
    local Component = require("../classes/Component.luau")
    local EventHandler = require("../utils/events/EventHandler.luau")
    local IconUtils = require("../utils/icons/Icon.luau")
    local IconPackUtils = require("../utils/icons/iconPack.luau")
    local DefaultIcons = require("../utils/defaults/Icons.luau")

    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    --[[
        @type ToggleProps = {
            label: string,
            icon?: Icon -- default: DefaultIcons<Toggle>,
            default?: boolean -- default: false,
        }

        @type Toggle {
            Instance: Frame,
            Parent: Window | Page | Section,
            props: ToggleProps,
            context: Context,
            Destroy: (Toggle) -> ()
        }
    ]]

    --[[
        Creates a Toggle component

        @param props = ToggleProps
        @param parentContext = Context
        @return Toggle
    ]]
    return function (props, parentContext)
        -- Creating `self`

        local self = Component.new(
            {
                props = props
            },
            "Toggle"
        )

        -- Hooking up context

        setmetatable(self.context, {
            __index = parentContext
        })

        -- Variables

        local _Toggled = Instance.new("BoolValue")
        self.context:Add(_Toggled)

        -- UI

        local Toggle = Instance.new("TextButton")
        Toggle.AutomaticSize = Enum.AutomaticSize.Y
        Toggle.Size = UDim2.fromScale(1, 0)
        Toggle.TextTransparency = 1
        Toggle.BorderSizePixel = 0
        Toggle.BackgroundColor3 = Color3.new(.15, .15, .15)
        Toggle.BackgroundTransparency = .35
        Toggle.AutoButtonColor = false

        local Toggle_UIFlexItem = Instance.new("UIFlexItem")
        Toggle_UIFlexItem.FlexMode = Enum.UIFlexMode.Grow
        Toggle_UIFlexItem.Parent = Toggle

        local Toggle_UIListLayout = Instance.new("UIListLayout")
        Toggle_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Toggle_UIListLayout.Padding = UDim.new(0, 12)
        Toggle_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Toggle_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        Toggle_UIListLayout.Parent = Toggle

        local Toggle_UIPadding = Instance.new("UIPadding")
        Toggle_UIPadding.PaddingBottom = UDim.new(0, 12)
        Toggle_UIPadding.PaddingTop = UDim.new(0, 12)
        Toggle_UIPadding.PaddingRight = UDim.new(0, 12)
        Toggle_UIPadding.PaddingLeft = UDim.new(0, 12)
        Toggle_UIPadding.Parent = Toggle
        
        local Toggle_UICorner = Instance.new("UICorner")
        Toggle_UICorner.CornerRadius = UDim.new(0, 8)
        Toggle_UICorner.Parent = Toggle

        local Toggle_Container = Instance.new("Frame")
        Toggle_Container.AutomaticSize = Enum.AutomaticSize.Y
        Toggle_Container.BackgroundTransparency = 1
        Toggle_Container.Parent = Toggle

        local Toggle_Container_UIListLayout = Instance.new("UIListLayout")
        Toggle_Container_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Toggle_Container_UIListLayout.Padding = UDim.new(0, 12)
        Toggle_Container_UIListLayout.Parent = Toggle_Container

        local Toggle_Container_UIFlexItem = Instance.new("UIFlexItem")
        Toggle_Container_UIFlexItem.FlexMode = Enum.UIFlexMode.Fill
        Toggle_Container_UIFlexItem.Parent = Toggle_Container

        local Toggle_Label_Section = Instance.new("Frame")
        Toggle_Label_Section.AutomaticSize = Enum.AutomaticSize.Y
        Toggle_Label_Section.Size = UDim2.fromScale(1, 0)
        Toggle_Label_Section.BackgroundTransparency = 1
        Toggle_Label_Section.Parent = Toggle_Container

        local Toggle_Label_Section_UIListLayout = Instance.new("UIListLayout")
        Toggle_Label_Section_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Toggle_Label_Section_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Toggle_Label_Section_UIListLayout.Padding = UDim.new(0, 12)
        Toggle_Label_Section_UIListLayout.Parent = Toggle_Label_Section

        local Toggle_Label_Icon = Instance.new("ImageLabel")
        Toggle_Label_Icon.Image = if not props.icon then 
            IconPackUtils.resolveIconPack(self.context.settings.iconPack).Icon(DefaultIcons[table.concat({
                self.context.settings.iconPack.pack, 
                self.context.settings.iconPack.variant
            }, "/")].Toggle) else 
            IconUtils.resolveIcon(props.icon, self.context.settings.iconPack)
        Toggle_Label_Icon.BackgroundTransparency = 1
        Toggle_Label_Icon.Size = UDim2.fromOffset(22, 22)
        Toggle_Label_Icon.Parent = Toggle_Label_Section

        local Toggle_Label = Instance.new("TextLabel")
        Toggle_Label.Text = props.label
        Toggle_Label.TextSize = 18
        Toggle_Label.TextColor3 = Color3.new(1, 1, 1)
        Toggle_Label.BackgroundTransparency = 1
        Toggle_Label.Size = UDim2.fromScale(1, 0)
        Toggle_Label.TextWrapped = true
        Toggle_Label.TextXAlignment = Enum.TextXAlignment.Left
        Toggle_Label.FontFace = Font.new(
            "rbxasset://fonts/families/Roboto.json",
            Enum.FontWeight.Bold,
            Enum.FontStyle.Normal
        )
        Toggle_Label.AutomaticSize = Enum.AutomaticSize.Y
        Toggle_Label.Parent = Toggle_Label_Section

        if props.description then
            local Toggle_Description = Instance.new("TextLabel")
            Toggle_Description.Text = props.description
            Toggle_Description.TextSize = 16
            Toggle_Description.TextColor3 = Color3.new(.7, .7, .7)
            Toggle_Description.TextTransparency = 0.25
            Toggle_Description.BackgroundTransparency = 1
            Toggle_Description.FontFace = Font.new(
                "rbxasset://fonts/families/Roboto.json",
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            Toggle_Description.Size = UDim2.fromScale(1, 0)
            Toggle_Description.TextWrapped = true
            Toggle_Description.TextXAlignment = Enum.TextXAlignment.Left
            Toggle_Description.AutomaticSize = Enum.AutomaticSize.Y
            Toggle_Description.Parent = Toggle_Container
        end

        local Toggle_Box = Instance.new("Frame")
        Toggle_Box.Size = UDim2.new(0, 48, 0, 24)
        Toggle_Box.BackgroundTransparency = 0.5
        Toggle_Box.LayoutOrder = 1
        Toggle_Box.Parent = Toggle

        local Toggle_Box_UICorner = Instance.new("UICorner")
        Toggle_Box_UICorner.CornerRadius = UDim.new(0, 9999)
        Toggle_Box_UICorner.Parent = Toggle_Box
        
        local Toggle_Box_UIFlexItem = Instance.new("UIFlexItem")
        Toggle_Box_UIFlexItem.FlexMode = Enum.UIFlexMode.Custom
        Toggle_Box_UIFlexItem.Parent = Toggle_Box

        local Toggle_Box_UIPadding = Instance.new("UIPadding")
        Toggle_Box_UIPadding.PaddingBottom = UDim.new(0, 3)
        Toggle_Box_UIPadding.PaddingTop = UDim.new(0, 3)
        Toggle_Box_UIPadding.PaddingRight = UDim.new(0, 3)
        Toggle_Box_UIPadding.PaddingLeft = UDim.new(0, 3)
        Toggle_Box_UIPadding.Parent = Toggle_Box
        
        local Toggle_Box_Indicator = Instance.new("Frame")
        Toggle_Box_Indicator.Size = UDim2.new(.6, 0, 1, 0)
        Toggle_Box_Indicator.BackgroundColor3 = Color3.new(.45, .3, 1)
        Toggle_Box_Indicator.Parent = Toggle_Box

        local Toggle_Box_Indicator_UIShadow = Instance.new("UIShadow")
        Toggle_Box_Indicator_UIShadow.BlurRadius = UDim.new(0, 4)
        Toggle_Box_Indicator_UIShadow.Transparency = 1
        Toggle_Box_Indicator_UIShadow.Parent = Toggle_Box_Indicator

        local Toggle_Box_Indicator_UICorner = Instance.new("UICorner")
        Toggle_Box_Indicator_UICorner.CornerRadius = UDim.new(0, 9999)
        Toggle_Box_Indicator_UICorner.Parent = Toggle_Box_Indicator

        -- Component data

        self.Instance = Toggle

        -- Runtime

        local events = EventHandler.ExtractEvents(props)

        local _ToggleProgress = _Toggled.Value and 1 or 0
        local _IndicatorWidth = 0.6

        local TOGGLE_SPEED = 18
        local WIDTH_SPEED = 20

        self.context:Add(Toggle.MouseButton1Click:Connect(function()
            if events.Has("onClick") then
                events.Fire("onClick")
            end

            _Toggled.Value = not _Toggled.Value
        end))

        self.context:Add(
            RunService.RenderStepped:Connect(function(dt)
                local targetProgress =
                    _Toggled.Value and 1 or 0

                -- Smoothly move 0 -> 1 or 1 -> 0
                _ToggleProgress +=
                    (targetProgress - _ToggleProgress)
                    * (1 - math.exp(-TOGGLE_SPEED * dt))

                -- How far away the indicator still is from its destination.
                -- 0 at destination, approaches 1 while travelling.
                local distance =
                    math.abs(targetProgress - _ToggleProgress)

                -- Stretch while moving, return to .6 when it settles.
                local targetWidth =
                    0.6 + distance * 0.4

                _IndicatorWidth +=
                    (targetWidth - _IndicatorWidth)
                    * (1 - math.exp(-WIDTH_SPEED * dt))

                -- Width goes from .6 -> 1 -> .6
                --
                -- Position has to account for the changing width so:
                -- OFF = left aligned
                -- ON  = right aligned
                local maxPosition =
                    1 - _IndicatorWidth

                local position =
                    maxPosition * _ToggleProgress

                Toggle_Box_Indicator.Size =
                    UDim2.fromScale(
                        _IndicatorWidth,
                        1
                    )

                Toggle_Box_Indicator.Position =
                    UDim2.fromScale(
                        position,
                        0
                    )
            end)
        )

        local function update(skipAnimate)
            local duration =
                if skipAnimate == true
                    then 0
                    else .15

            local targetPosition =
                _Toggled.Value
                    and UDim2.fromScale(0.4, 0)
                or UDim2.fromScale(0, 0)

            local indicatorColor =
                _Toggled.Value
                    and Color3.new(1, 1, 1)
                    or Color3.new(.4, .4, .4)

            local boxColor =
                _Toggled.Value
                    and Color3.new(.45, .3, 1)
                    or Color3.new(.4, .4, .4)

            local shadowTransparency =
                _Toggled.Value
                    and .5
                    or 1

            TweenService:Create(
                Toggle_Box_Indicator,
                TweenInfo.new(
                    duration,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {
                    BackgroundColor3 = indicatorColor,
                }
            ):Play()

            TweenService:Create(
                Toggle_Box,
                TweenInfo.new(duration),
                {
                    BackgroundColor3 = boxColor,
                }
            ):Play()

            TweenService:Create(
            	Toggle_Box_Indicator_UIShadow,
            	TweenInfo.new(duration),
            	{
            		Transparency = shadowTransparency,
            	}
            ):Play()
        end

        update(true)

        self.context:Add(_Toggled.Changed:Connect(function()
            if events.Has("onToggle") then
                events.Fire("onToggle", _Toggled.Value)
            end

            update()
        end))

        return self
    end
end