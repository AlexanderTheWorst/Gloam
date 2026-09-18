return function (require)
    local Component = require("../classes/Component.luau")

    --[[
        @type PageProps = {
            title: string,
            icon?: Icon -- default: DefaultIcons<Page>
        }

        @type Page {
            Instance: Frame,
            Parent?: Window,

            props: PageProps,
            context: Context,

            Destroy: (Page) -> ()
        }
    ]]

    --[[
        Creates a Page component

        @param props = PageProps
        @param parentContext = Context
        
        @return Page
    ]]
    return function (props, parentContext) 
        -- Creating `self`

        local self = Component.new(
            {
                props = props
            }, 
            "Page", 
            { "Section", "Toggle", "Button", "Toggle" }
        )

        -- Hooking up context

        setmetatable(self.context, {
            __index = parentContext
        })

        -- Variables

        -- UI

        local Page = Instance.new("Frame")
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.fromScale(1, 1)
        self.context:Add(Page)

        -- Creating all the UI

        local Page_ScrollBackdrop = Instance.new("Frame")
        Page_ScrollBackdrop.Position = UDim2.new(1, 0, 0, 0)
        Page_ScrollBackdrop.BackgroundColor3 = Color3.new(.15, .15, .15)
        Page_ScrollBackdrop.AnchorPoint = Vector2.new(1, 0)
        Page_ScrollBackdrop.BackgroundTransparency = 0.35
        Page_ScrollBackdrop.Size = UDim2.new(0, 5, 1, 0)
        Page_ScrollBackdrop.Parent = Page

        local Page_ScrollBackdrop_UICorner = Instance.new("UICorner")
        Page_ScrollBackdrop_UICorner.CornerRadius = UDim.new(1, 0)
        Page_ScrollBackdrop_UICorner.Parent = Page_ScrollBackdrop

        local Page_ScrollContainer = Instance.new("ScrollingFrame")
        Page_ScrollContainer.BackgroundTransparency = 1
        Page_ScrollContainer.BorderSizePixel = 0
        Page_ScrollContainer.ScrollBarThickness = 5
        Page_ScrollContainer.ScrollBarImageColor3 = Color3.new(.25, .25, .25)
        Page_ScrollContainer.SmoothScroll = true
        Page_ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page_ScrollContainer.CanvasSize = UDim2.fromOffset(0, 0)
        Page_ScrollContainer.ScrollRate = 1
        Page_ScrollContainer.Size = UDim2.fromScale(1, 1)
        Page_ScrollContainer.TopImage = "rbxassetid://91024123446252"
        Page_ScrollContainer.BottomImage = "rbxassetid://104616129547785"
        Page_ScrollContainer.MidImage = "rbxassetid://93447745525354"
        Page_ScrollContainer.Parent = Page

        local PageContainer = Instance.new("Frame")
        PageContainer.AutomaticSize = Enum.AutomaticSize.Y
        PageContainer.Size = UDim2.fromScale(1, 0)
        PageContainer.BackgroundTransparency = 1
        PageContainer.Parent = Page_ScrollContainer
        
        local PageContainer_UIPadding = Instance.new("UIPadding")
        PageContainer_UIPadding.PaddingRight = UDim.new(0, 20)
        PageContainer_UIPadding.PaddingBottom = UDim.new(0, 10)
        PageContainer_UIPadding.Parent = PageContainer
        
        local PageContainer_UIListLayout = Instance.new("UIListLayout")
        PageContainer_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageContainer_UIListLayout.FillDirection = Enum.FillDirection.Vertical
        PageContainer_UIListLayout.Padding = UDim.new(0, 15)
        PageContainer_UIListLayout.Parent = PageContainer

        local PageDescriptorContainer = Instance.new("Frame")
        PageDescriptorContainer.AutomaticSize = Enum.AutomaticSize.Y
        PageDescriptorContainer.Size = UDim2.fromScale(1, 0)
        PageDescriptorContainer.BackgroundTransparency = 1
        PageDescriptorContainer.Parent = PageContainer

        local PageDescriptorContainer_UIListLayout = Instance.new("UIListLayout")
        PageDescriptorContainer_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageDescriptorContainer_UIListLayout.FillDirection = Enum.FillDirection.Vertical
        PageDescriptorContainer_UIListLayout.Padding = UDim.new(0, 8)
        PageDescriptorContainer_UIListLayout.Parent = PageDescriptorContainer
        
        local PageDescriptorContainer_UIPadding = Instance.new("UIPadding")
        PageDescriptorContainer_UIPadding.PaddingBottom = UDim.new(0, 0)
        PageDescriptorContainer_UIPadding.Parent = PageDescriptorContainer

        local Page_Title = Instance.new("TextLabel")
        Page_Title.Text = props.title
        Page_Title.BackgroundTransparency = 1
        Page_Title.TextColor3 = Color3.new(1, 1, 1)
        Page_Title.TextSize = 28
        Page_Title.AutomaticSize = Enum.AutomaticSize.XY
        Page_Title.FontFace = Font.new(
            "rbxasset://fonts/families/Roboto.json",
            Enum.FontWeight.SemiBold,
            Enum.FontStyle.Normal
        )
        Page_Title.Parent = PageDescriptorContainer

        if props.description then
            local Page_Description = Instance.new("TextLabel")
            Page_Description.Text = props.description
            Page_Description.BackgroundTransparency = 1
            Page_Description.RichText = true
            Page_Description.TextColor3 = Color3.new(.6, .6, .6)
            Page_Description.TextSize = 18
            Page_Description.TextWrapped = true
            Page_Description.TextXAlignment = Enum.TextXAlignment.Left
            Page_Description.AutomaticSize = Enum.AutomaticSize.Y
            Page_Description.Size = UDim2.fromScale(1, 0)
            Page_Description.FontFace = Font.new(
                "rbxasset://fonts/families/Roboto.json",
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            Page_Description.Parent = PageDescriptorContainer
        end

        -- Component data

        self.Instance = Page

        -- Runtime

        self.OnComponentAdded = function(comp) 
            comp.Instance.Parent = PageContainer
        end

        return self
    end
end