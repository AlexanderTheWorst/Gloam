return function (require)
    local Component = require("../classes/Component.luau")

    local EventHandler = require("../utils/events/EventHandler.luau")

    local IconUtils = require("../utils/icons/Icon.luau")
    local IconPackUtils = require("../utils/icons/IconPack.luau")

    local DefaultIcons = require("../utils/defaults/Icons.luau")

    local TweenService = game:GetService("TweenService")

    --[[
        @type SectionProps = {
            label: string,
            icon?: Icon -- default: DefaultIcons<Section>
        }

        @type Section {
            Instance: Frame,
            Parent: Window | Page | Section,

            props: SectionProps,
            context: Context,

            Destroy: (Section) -> ()
        }
    ]]

    --[[
        Creates a Section component

        @param props = SectionProps
        @param parentContext = Context
        
        @return Section
    ]]
    return function (props, parentContext)
        -- Creating `self`

        local self = Component.new(
            {
                props = props
            },
            "Section",
            {
                "Section",
                "Button",
                "Slider",
                "Toggle"
            }
        )

        -- Hooking up context

        setmetatable(self.context, {
            __index = parentContext
        })

        -- Services

        local TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        -- Variables

        local _Expanded = Instance.new("BoolValue")
        _Expanded.Value = true

        local _ActiveTweens = {}
        local _Tweening = false

        -- UI

        local SectionComponent = Instance.new("Frame")
        SectionComponent.Size = UDim2.fromScale(1, 0)
        SectionComponent.BackgroundTransparency = 1
        SectionComponent.AutomaticSize = Enum.AutomaticSize.Y

        local Section_UIListLayout = Instance.new("UIListLayout")
        Section_UIListLayout.FillDirection = Enum.FillDirection.Vertical
        Section_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Section_UIListLayout.Padding = UDim.new(0, 0) -- starts at 0, tweens to 6 on expand
        Section_UIListLayout.Parent = SectionComponent

        local Section_Top = Instance.new("TextButton")
        Section_Top.Size = UDim2.fromScale(1, 0)
        Section_Top.BackgroundTransparency = 1
        Section_Top.TextTransparency = 1
        Section_Top.AutomaticSize = Enum.AutomaticSize.Y
        Section_Top.LayoutOrder = -1
        Section_Top.Parent = SectionComponent

        local Section_Top_UIListLayout = Instance.new("UIListLayout")
        Section_Top_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Section_Top_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Section_Top_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
        Section_Top_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Section_Top_UIListLayout.Parent = Section_Top

        local Section_Chevron_Container = Instance.new("Frame")
        Section_Chevron_Container.Size = UDim2.fromOffset(24, 24)
        Section_Chevron_Container.BackgroundTransparency = 1
        Section_Chevron_Container.LayoutOrder = 1
        Section_Chevron_Container.Parent = if props.collapsible ~= nil and not props.collapsible then nil else Section_Top

        local Section_Chevron = Instance.new("ImageLabel")
        Section_Chevron.Image = "rbxassetid://114919840527584"
        Section_Chevron.Size = UDim2.fromOffset(24, 24)
        Section_Chevron.BackgroundTransparency = 1
        Section_Chevron.Rotation = 0
        Section_Chevron.Parent = Section_Chevron_Container

        local Section_Label_Container = Instance.new("Frame")
        Section_Label_Container.BackgroundTransparency = 1
        Section_Label_Container.AutomaticSize = Enum.AutomaticSize.XY
        Section_Label_Container.Parent = Section_Top
        
        local Section_Label_Container_UIListLayout = Instance.new("UIListLayout")
        Section_Label_Container_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Section_Label_Container_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Section_Label_Container_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Section_Label_Container_UIListLayout.Padding = UDim.new(0, 8)
        Section_Label_Container_UIListLayout.Parent = Section_Label_Container

        local Section_Icon = Instance.new("ImageLabel")
        Section_Icon.BackgroundTransparency = 1
        Section_Icon.Image = (function() 
            if typeof(props.icon) == "string" then
                return props.icon
            end

            return 
                props.icon and (typeof(props.icon) == "table" and IconUtils.resolveIcon(props.icon, self.context.settings.iconPack)) or 
                IconPackUtils.resolveIconPack(self.context.settings.iconPack).Icon(
                    DefaultIcons[
                        table.concat({
                            self.context.settings.iconPack.pack,
                            self.context.settings.iconPack.variant
                        }, "/")
                    ].Section
                )
        end)()
        Section_Icon.Size = UDim2.fromOffset(18, 18)
        Section_Icon.Parent = Section_Label_Container

        local Section_Label = Instance.new("TextLabel")
        Section_Label.Text = props.label
        Section_Label.TextSize = 16
        Section_Label.BackgroundTransparency = 1
        Section_Label.AutomaticSize = Enum.AutomaticSize.XY
        Section_Label.TextColor3 = Color3.new(1, 1, 1)
        Section_Label.TextXAlignment = Enum.TextXAlignment.Left
        Section_Label.FontFace = Font.new(
            "rbxasset://fonts/families/Roboto.json",
            Enum.FontWeight.Bold,
            Enum.FontStyle.Normal
        )
        Section_Label.Parent = Section_Label_Container

        local Section_Container = Instance.new("Frame")
        Section_Container.AutomaticSize = Enum.AutomaticSize.Y
        Section_Container.Size = UDim2.fromScale(1, 0)
        Section_Container.BackgroundTransparency = 1
        Section_Container.Parent = SectionComponent

        local Section_Container_UIPadding = Instance.new("UIPadding")
        Section_Container_UIPadding.PaddingLeft = UDim.new(0, 9)
        Section_Container_UIPadding.PaddingTop = UDim.new(0, 0)
        Section_Container_UIPadding.PaddingBottom = UDim.new(0, 0)
        Section_Container_UIPadding.Parent = Section_Container

        local Section_Container_UIListLayout = Instance.new("UIListLayout")
        Section_Container_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Section_Container_UIListLayout.Parent = Section_Container

        local Section_Container_Border = Instance.new("Frame")
        Section_Container_Border.Size = UDim2.fromOffset(1, 0) -- starts collapsed
        Section_Container_Border.BorderSizePixel = 0
        Section_Container_Border.BackgroundColor3 = Color3.new(.15, .15, .15)
        Section_Container_Border.Parent = Section_Container

        local Section_Container_Overflow = Instance.new("ScrollingFrame")
        Section_Container_Overflow.ScrollingEnabled = false
        Section_Container_Overflow.ScrollBarImageTransparency = 1
        Section_Container_Overflow.ScrollBarThickness = 0
        Section_Container_Overflow.ClipsDescendants = true
        Section_Container_Overflow.BackgroundTransparency = 1
        Section_Container_Overflow.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Section_Container_Overflow.Size = UDim2.new(1, 0, 0, 0) -- starts collapsed
        Section_Container_Overflow.Parent = Section_Container

        local Section_Visual_Container = Instance.new("Frame")
        Section_Visual_Container.Size = UDim2.fromScale(1, 0)
        Section_Visual_Container.AutomaticSize = Enum.AutomaticSize.Y
        Section_Visual_Container.BackgroundTransparency = 1
        Section_Visual_Container.ClipsDescendants = true
        Section_Visual_Container.Parent = Section_Container_Overflow

        local Section_Visual_Container_UIListLayout = Instance.new("UIListLayout")
        Section_Visual_Container_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Section_Visual_Container_UIListLayout.Padding = UDim.new(0, 9)
        Section_Visual_Container_UIListLayout.Parent = Section_Visual_Container

        local Section_Visual_Container_UIPadding = Instance.new("UIPadding")
        Section_Visual_Container_UIPadding.PaddingLeft = UDim.new(0, 9)
        Section_Visual_Container_UIPadding.Parent = Section_Visual_Container

        -- Component data

        self.Instance = SectionComponent

        -- Runtime

        local function cancelTweens()
            for _, tween in _ActiveTweens do
                tween:Cancel()
            end
            _ActiveTweens = {}
            _Tweening = false
        end

        local function setExpanded(expanded, animate)
            cancelTweens()

            local targetHeight = expanded and Section_Visual_Container.AbsoluteSize.Y or 0
            local targetPadding = expanded and UDim.new(0, 6) or UDim.new(0, 0)
            local targetRotation = expanded and 180 or 0
            local targetPaddingTop = expanded and UDim.new(0, 0) or UDim.new(0, 0)
            local targetPaddingBottom = expanded and UDim.new(0, 0) or UDim.new(0, 0)

            if animate == false then
                Section_Container_Overflow.Size = UDim2.new(1, 0, 0, targetHeight)
                Section_Container_Border.Size = UDim2.fromOffset(1, targetHeight)
                Section_UIListLayout.Padding = targetPadding
                Section_Chevron.Rotation = targetRotation
                return
            end

            local sizeTween = TweenService:Create(Section_Container_Overflow, TWEEN_INFO, {
                Size = UDim2.new(1, 0, 0, targetHeight)
            })

            local borderTween = TweenService:Create(Section_Container_Border, TWEEN_INFO, {
                Size = UDim2.fromOffset(1, targetHeight)
            })

            local paddingTween = TweenService:Create(Section_UIListLayout, TWEEN_INFO, {
                Padding = targetPadding
            })

            local chevronTween = TweenService:Create(Section_Chevron, TWEEN_INFO, {
                Rotation = targetRotation
            })

            local containerPaddingTween = TweenService:Create(Section_Container_UIPadding, TWEEN_INFO, {
                PaddingTop = targetPaddingTop,
                PaddingBottom = targetPaddingBottom,
            })

            _ActiveTweens = { sizeTween, borderTween, paddingTween, chevronTween, containerPaddingTween }
            _Tweening = true

            local remaining = #_ActiveTweens
            for _, tween in _ActiveTweens do
                tween.Completed:Connect(function()
                    remaining -= 1
                    if remaining <= 0 then
                        _Tweening = false
                    end
                end)
            end

            for _, tween in _ActiveTweens do
                tween:Play()
            end
        end

        self.context:Add(Section_Visual_Container_UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if _Expanded.Value == true and not _Tweening then
                local height = Section_Visual_Container_UIListLayout.AbsoluteContentSize.Y
                Section_Container_Overflow.Size = UDim2.new(1, 0, 0, height)
                Section_Container_Border.Size = UDim2.fromOffset(1, height)
            end
        end))

        setExpanded(_Expanded.Value, false) -- snap, don't animate, on initial build

        self.context:Add(_Expanded.Changed:Connect(function(c)
            setExpanded(c == true, true)
        end))

        self.context:Add(Section_Top.MouseButton1Click:Connect(function()
            if props.collapsible ~= nil and props.collapsible == false then
                return
            end

            _Expanded.Value = not _Expanded.Value
        end))

        self.OnComponentAdded = function(comp) 
            if typeof(comp) ~= "table" or not comp.type then
                return error("Error: Provided component is invalid.")
            end

            if not comp["type"] then 
                return error("Error: Provided component is missing type.")
            end

            if comp.Instance then
                comp.Instance.Parent = Section_Visual_Container
            end

            return
        end

        return self
    end
end