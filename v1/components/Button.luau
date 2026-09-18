return function (require)
    local Component = require("../classes/Component.luau")

    local EventHandler = require("../utils/events/EventHandler.luau")

    local IconUtils = require("../utils/icons/Icon.luau")
    local IconPackUtils = require("../utils/icons/IconPack.luau")

    local DefaultIcons = require("../utils/defaults/Icons.luau")

    local TweenService = game:GetService("TweenService")

    --[[
        @type ButtonProps = {
            label: string,
            icon?: Icon -- default: DefaultIcons<Button>
        }

        @type Button {
            Instance: Frame,
            Parent: Window | Page | Section,

            props: ButtonProps,
            context: Context,

            Destroy: (Button) -> ()
        }
    ]]

    --[[
        Creates a Button component

        @param props = ButtonProps
        @param parentContext = Context
        
        @return Button
    ]]
    return function (props, parentContext)
        -- Creating `self`

        local self = Component.new(
            {
                props = props
            },
            "Button"
        )

        -- Hooking up context

        setmetatable(self.context, {
            __index = parentContext
        })

        -- Variables

        -- UI

        local Button = Instance.new("TextButton")
        Button.AutomaticSize = Enum.AutomaticSize.Y
        Button.Size = UDim2.fromScale(1, 0)
        Button.TextTransparency = 1
        Button.BorderSizePixel = 0
        Button.BackgroundColor3 = Color3.new(.15, .15, .15)
        Button.BackgroundTransparency = .35
        Button.AutoButtonColor = false

        local Button_UIListLayout = Instance.new("UIListLayout")
        Button_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Button_UIListLayout.Padding = UDim.new(0, 12)
        Button_UIListLayout.Parent = Button

        local Button_UIPadding = Instance.new("UIPadding")
        Button_UIPadding.PaddingBottom = UDim.new(0, 12)
        Button_UIPadding.PaddingTop = UDim.new(0, 12)
        Button_UIPadding.PaddingRight = UDim.new(0, 12)
        Button_UIPadding.PaddingLeft = UDim.new(0, 12)
        Button_UIPadding.Parent = Button
        
        local Button_UICorner = Instance.new("UICorner")
        Button_UICorner.CornerRadius = UDim.new(0, 8)
        Button_UICorner.Parent = Button

        local Button_Label_Section = Instance.new("Frame")
        Button_Label_Section.AutomaticSize = Enum.AutomaticSize.Y
        Button_Label_Section.Size = UDim2.fromScale(1, 0)
        Button_Label_Section.BackgroundTransparency = 1
        Button_Label_Section.Parent = Button

        local Button_Label_Section_UIListLayout = Instance.new("UIListLayout")
        Button_Label_Section_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Button_Label_Section_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Button_Label_Section_UIListLayout.Padding = UDim.new(0, 12)
        Button_Label_Section_UIListLayout.Parent = Button_Label_Section

        local Button_Label_Icon = Instance.new("ImageLabel")
        Button_Label_Icon.Image = if not props.icon then 
            IconPackUtils.resolveIconPack(self.context.settings.iconPack).Icon(DefaultIcons[table.concat({
                self.context.settings.iconPack.pack, 
                self.context.settings.iconPack.variant
            }, "/")].Button) else 
            IconUtils.resolveIcon(props.icon, self.context.settings.iconPack)
        Button_Label_Icon.BackgroundTransparency = 1
        Button_Label_Icon.Size = UDim2.fromOffset(22, 22)
        Button_Label_Icon.Parent = Button_Label_Section

        local Button_Label = Instance.new("TextLabel")
        Button_Label.Text = props.label
        Button_Label.TextSize = 18
        Button_Label.TextColor3 = Color3.new(1, 1, 1)
        Button_Label.BackgroundTransparency = 1
        Button_Label.Size = UDim2.fromScale(1, 0)
        Button_Label.TextWrapped = true
        Button_Label.TextXAlignment = Enum.TextXAlignment.Left
        Button_Label.FontFace = Font.new(
            "rbxasset://fonts/families/Roboto.json",
            Enum.FontWeight.Bold,
            Enum.FontStyle.Normal
        )
        Button_Label.AutomaticSize = Enum.AutomaticSize.Y
        Button_Label.Parent = Button_Label_Section

        if props.description then
            local Button_Description = Instance.new("TextLabel")
            Button_Description.Text = props.description
            Button_Description.TextSize = 16
            Button_Description.TextColor3 = Color3.new(.7, .7, .7)
            Button_Description.TextTransparency = 0.25
            Button_Description.BackgroundTransparency = 1
            Button_Description.FontFace = Font.new(
                "rbxasset://fonts/families/Roboto.json",
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            Button_Description.Size = UDim2.fromScale(1, 0)
            Button_Description.TextWrapped = true
            Button_Description.TextXAlignment = Enum.TextXAlignment.Left
            Button_Description.AutomaticSize = Enum.AutomaticSize.Y
            Button_Description.Parent = Button
        end

        -- Component data

        self.Instance = Button

        -- Runtime

        local events = EventHandler.ExtractEvents(props)

        self.context:Add(Button.MouseButton1Click:Connect(function()
            if events.Has("onClick") then
                events.Fire("onClick")
            end
        end))

        self.context:Add(Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(.15), {
                BackgroundColor3 = Color3.new(.2, .2, .2)
            }):Play()
        end))

        self.context:Add(Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(.15), {
                BackgroundColor3 = Color3.new(.15, .15, .15)
            }):Play()
        end))

        return self
    end
end