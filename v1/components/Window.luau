return function (require)
    local Component = require("../classes/Component.luau")

    local IconPackUtils = require("../utils/icons/IconPack.luau")
    local IconUtils = require("../utils/icons/Icon.luau")

    local DefaultIcons = require("../utils/defaults/Icons.luau")

    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    --[[
        @type WindowProps = {
            title: string,
            subtitle?: string -- default: nil,
        }

        @type Window {
            Instance: Frame,
            Parent: Screen

            props: WindowProps,
            context: Context,

            Destroy: (Window) -> ()
        }
    ]]

    --[[
        Creates a Window component

        @param props = WindowProps
        @param parentContext = Context

        @return Window
    ]]
    return function (props, parentContext) 
        -- Creating `self`

        local self = Component.new(
            {
                props = props
            }, 
            "Window", 
            { "Page" }
        )

        -- Hooking up context

        setmetatable(self.context, {
            __index = parentContext
        })

        -- Variables

        -- Page variables
        local _CurrentPage = Instance.new("IntValue")
        _CurrentPage.Value = 1
        self.context:Add(_CurrentPage)

        local _PageNum = 0
        local _Pages = {}

        -- Dragging variables
        local _MouseDown = false
        local _MouseDragStart = UDim2.fromOffset(0, 0)
        local _MouseDragLast = UDim2.fromOffset(0, 0)

        local _DraggingAllowed = false
        
        -- UI

        -- Creating the UI container

        local Camera = workspace.CurrentCamera

        local ParentCanvas = Instance.new("CanvasGroup")
        ParentCanvas.Size = UDim2.fromOffset(800, 600)
        ParentCanvas.BackgroundTransparency = 1
        ParentCanvas.GroupTransparency = 1
        ParentCanvas.Position = UDim2.fromOffset(
            Camera.ViewportSize.X / 2 - 800 / 2,
            Camera.ViewportSize.Y / 2 - 600 / 2 + 50
        )

        self.context:Add(ParentCanvas)

        local ParentCanvas_UIShadow = Instance.new("UIShadow")
        ParentCanvas_UIShadow.BlurRadius = UDim.new(0, 0)
        ParentCanvas_UIShadow.Transparency = 1
        ParentCanvas_UIShadow.Parent = ParentCanvas

        local ParentCanvas_UICorner = Instance.new("UICorner")
        ParentCanvas_UICorner.CornerRadius = UDim.new(0, 6)
        ParentCanvas_UICorner.Parent = ParentCanvas

        local WindowContainer = Instance.new("TextButton")
        WindowContainer.Size = UDim2.fromOffset(800, 600)
        WindowContainer.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
        WindowContainer.BorderSizePixel = 0
        WindowContainer.LayoutOrder = -1
        WindowContainer.BackgroundTransparency = 1
        WindowContainer.TextTransparency = 1
        WindowContainer.AutoButtonColor = false
        WindowContainer.Parent = ParentCanvas

        local CanvasGroup = Instance.new("CanvasGroup")
        CanvasGroup.Size = UDim2.fromScale(1, 1)
        CanvasGroup.BackgroundTransparency = 1
        CanvasGroup.GroupTransparency = 0.15
        CanvasGroup.Parent = WindowContainer

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.fromOffset(800, 600)
        Frame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
        Frame.BorderSizePixel = 0
        Frame.LayoutOrder = -1
        Frame.Parent = CanvasGroup

        local Frame_UICorner = Instance.new("UICorner")
        Frame_UICorner.CornerRadius = UDim.new(0, 6)
        Frame_UICorner.Parent = Frame

        local Border = Frame:Clone()
        Border.BackgroundColor3 = Color3.new(.2, .2, .2)
        Border.Parent = CanvasGroup

        Frame.Size = UDim2.fromOffset(798, 598)
        Frame.AnchorPoint = Vector2.new(0.5, 0.5)
        Frame.Position = UDim2.fromScale(0.5, 0.5)
        Frame.Parent = Border

        local VisualContainer = Instance.new("Frame")
        VisualContainer.Size = UDim2.new(1, 0, 1, 0)
        VisualContainer.BackgroundTransparency = 1
        VisualContainer.Parent = WindowContainer

        local VisualContainer_UIListLayout = Instance.new("UIListLayout")
        VisualContainer_UIListLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        VisualContainer_UIListLayout.FillDirection = Enum.FillDirection.Vertical
        VisualContainer_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        VisualContainer_UIListLayout.Parent = VisualContainer

        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 0)
        Container.BackgroundTransparency = 1
        Container.LayoutOrder = 1
        Container.Parent = VisualContainer

        local Container_UIFlexItem = Instance.new("UIFlexItem")
        Container_UIFlexItem.FlexMode = Enum.UIFlexMode.Fill
        Container_UIFlexItem.Parent = Container

        local Container_UIListLayout = Instance.new("UIListLayout")
        Container_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Container_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        Container_UIListLayout.Parent = Container

        -- Creating the UI topbar

        local Topbar = Instance.new("Frame")
        Topbar.Size = UDim2.new(1, 0, 0, 0)
        Topbar.AutomaticSize = Enum.AutomaticSize.Y
        Topbar.BorderSizePixel = 0
        Topbar.BackgroundTransparency = 1
        Topbar.Parent = VisualContainer

        local Topbar_UIFlexItem = Instance.new("UIFlexItem")
        Topbar_UIFlexItem.FlexMode = Enum.UIFlexMode.None
        Topbar_UIFlexItem.Parent = Topbar

        local Title_Section = Instance.new("Frame")
        Title_Section.AutomaticSize = Enum.AutomaticSize.XY
        Title_Section.BackgroundTransparency = 1
        Title_Section.Size = UDim2.fromScale(0, 0)
        Title_Section.Parent = Topbar

        local Title_Section_UIListLayout = Instance.new("UIListLayout")
        Title_Section_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Title_Section_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Title_Section_UIListLayout.Padding = UDim.new(0, 0)
        Title_Section_UIListLayout.Parent = Title_Section

        local Title_Section_UIPadding = Instance.new("UIPadding")
        Title_Section_UIPadding.PaddingLeft = UDim.new(0, 14)
        Title_Section_UIPadding.PaddingRight = UDim.new(0, 14)
        Title_Section_UIPadding.PaddingTop = UDim.new(0, 14)
        Title_Section_UIPadding.PaddingBottom = UDim.new(0, 14)
        Title_Section_UIPadding.Parent = Title_Section

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(0, 0, 0, 0)
        Title.AutomaticSize = Enum.AutomaticSize.XY
        Title.BackgroundTransparency = 1
        Title.BorderSizePixel = 0
        Title.Text = props.title
        Title.TextColor3 = Color3.new(1, 1, 1)
        Title.TextSize = 18
        Title.RichText = true
        Title.FontFace = Font.new(
            "rbxasset://fonts/families/Roboto.json",
            Enum.FontWeight.Medium,
            Enum.FontStyle.Normal
        )
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.TextYAlignment = Enum.TextYAlignment.Center
        Title.Parent = Title_Section

        if props.subtitle then
            local Subtitle = Instance.new("TextLabel")
            Subtitle.Size = UDim2.new(0, 0, 0, 0)
            Subtitle.AutomaticSize = Enum.AutomaticSize.XY
            Subtitle.BackgroundTransparency = 1
            Subtitle.BorderSizePixel = 0
            Subtitle.RichText = true
            Subtitle.Text =  " " .. props.subtitle
            Subtitle.TextColor3 = Color3.new(.5, .5, .5)
            Subtitle.TextSize = 18
            Subtitle.FontFace = Font.new(
                "rbxasset://fonts/families/Roboto.json",
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            Subtitle.TextXAlignment = Enum.TextXAlignment.Left
            Subtitle.TextYAlignment = Enum.TextYAlignment.Center
            Subtitle.Parent = Title_Section
        end

        local Topbar_Buttons = Instance.new("Frame")
        Topbar_Buttons.Size = UDim2.new(0, 0, 1, 0)
        Topbar_Buttons.AutomaticSize = Enum.AutomaticSize.X
        Topbar_Buttons.Position = UDim2.fromScale(1, 0)
        Topbar_Buttons.BackgroundColor3 = Color3.new(1, 0, 0)
        Topbar_Buttons.BackgroundTransparency = 1
        Topbar_Buttons.AnchorPoint = Vector2.new(1, 0)
        Topbar_Buttons.Parent = Topbar

        local Topbar_Buttons_UIPadding = Instance.new("UIPadding")
        Topbar_Buttons_UIPadding.PaddingLeft = UDim.new(0, 12)
        Topbar_Buttons_UIPadding.PaddingRight = UDim.new(0, 12)
        Topbar_Buttons_UIPadding.Parent = Topbar_Buttons

        local Topbar_Buttons_UIListLayout = Instance.new("UIListLayout")
        Topbar_Buttons_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Topbar_Buttons_UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Topbar_Buttons_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Topbar_Buttons_UIListLayout.Padding = UDim.new(0, 8)
        Topbar_Buttons_UIListLayout.Parent = Topbar_Buttons

        local CloseButton = Instance.new("TextButton")
        CloseButton.Size = UDim2.fromOffset(24, 24)
        CloseButton.BackgroundTransparency = 1
        CloseButton.TextTransparency = 1
        CloseButton.Parent = Topbar_Buttons

        local CloseButton_Image = Instance.new("ImageLabel")
        CloseButton_Image.Image = "rbxassetid://113924054668267"
        CloseButton_Image.ImageTransparency = 0
        CloseButton_Image.BackgroundTransparency = 1
        CloseButton_Image.Size = UDim2.fromScale(1, 1)
        CloseButton_Image.Parent = CloseButton

        -- Creating the page selector

        local PageSelector = Instance.new("Frame")
        PageSelector.Size = UDim2.new(0, 200, 1, 0)
        PageSelector.BackgroundTransparency = 1
        PageSelector.BorderSizePixel = 0
        PageSelector.Parent = Container

        local PageSelector_UIFlexItem = Instance.new("UIFlexItem")
        PageSelector_UIFlexItem.FlexMode = Enum.UIFlexMode.Custom
        PageSelector_UIFlexItem.Parent = PageSelector

        local PageSelector_Container = Instance.new("ScrollingFrame")
        PageSelector_Container.Size = UDim2.new(1, 0, 1, 0)
        PageSelector_Container.BackgroundTransparency = 1
        PageSelector_Container.BorderSizePixel = 0
        PageSelector_Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        PageSelector_Container.ScrollingDirection = Enum.ScrollingDirection.X
        PageSelector_Container.Parent = PageSelector

        local PageSelector_Container_UIPadding = Instance.new("UIPadding")
        PageSelector_Container_UIPadding.PaddingLeft = UDim.new(0, 10)
        PageSelector_Container_UIPadding.PaddingBottom = UDim.new(0, 10)
        -- PageSelector_Container_UIPadding.PaddingTop = UDim.new(0, 10)
        PageSelector_Container_UIPadding.Parent = PageSelector_Container

        local PageSelector_Container_UIListLayout = Instance.new("UIListLayout")
        PageSelector_Container_UIListLayout.FillDirection = Enum.FillDirection.Vertical
        PageSelector_Container_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        PageSelector_Container_UIListLayout.Padding = UDim.new(0, 10)
        PageSelector_Container_UIListLayout.Parent = PageSelector_Container

        local PageView = Instance.new("Frame")
        PageView.Size = UDim2.new(0, 0, 1, 0)
        PageView.BackgroundTransparency = 1
        PageView.BorderSizePixel = 0
        PageView.ClipsDescendants = true
        PageView.Parent = Container
        
        local PageView_UIFlexItem = Instance.new("UIFlexItem")
        PageView_UIFlexItem.FlexMode = Enum.UIFlexMode.Fill
        PageView_UIFlexItem.Parent = PageView

        local PageView_UIPadding = Instance.new("UIPadding")
        PageView_UIPadding.PaddingLeft = UDim.new(0, 15)
        PageView_UIPadding.PaddingRight = UDim.new(0, 5)
        -- PageView_UIPadding.PaddingTop = UDim.new(0, 5)
        PageView_UIPadding.PaddingBottom = UDim.new(0, 5)
        PageView_UIPadding.Parent = PageView

        TweenService:Create(ParentCanvas, TweenInfo.new(.25), {
            Position = UDim2.fromOffset(
                Camera.ViewportSize.X / 2 - 800 / 2,
                Camera.ViewportSize.Y / 2 - 600 / 2
            ),
            GroupTransparency = 0
        }):Play()

        TweenService:Create(ParentCanvas_UIShadow, TweenInfo.new(.25), {
        Transparency = 0.25,
        BlurRadius = UDim.new(0, 30)
        }):Play()

        task.delay(.25, function() 
            _DraggingAllowed = true
        end)

        -- Component data

        self.Instance = ParentCanvas

        -- Events

        self.context:Add(WindowContainer.MouseButton1Down:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()

            _MouseDown = true
            _MouseDragStart = mousePos
            _MouseDragLast = mousePos
        end))

        self.context:Add(UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and _MouseDown then
                if not _DraggingAllowed then return end
            
                local mousePos = UserInputService:GetMouseLocation()
                local delta = mousePos - _MouseDragLast

                ParentCanvas.Position = UDim2.fromOffset(
                    ParentCanvas.Position.X.Offset + delta.X,
                    ParentCanvas.Position.Y.Offset + delta.Y
                )

                _MouseDragLast = mousePos
            end
        end))

        self.context:Add(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and _MouseDown then
                _MouseDown = false
            end
        end))

        -- Runtime

        self.OnComponentAdded = function(comp) 
            if typeof(comp) ~= "table" or not comp.type then
                return error("Error: Provided component is invalid.")
            end

            if not comp["type"] then 
                return error("Error: Provided component is missing type.")
            end

            if comp.type == "Page" then
                local PageButton = Instance.new("TextButton")
                PageButton.TextTransparency = 1
                PageButton.Size = UDim2.new(1, 0, 0, 45)
                PageButton.BackgroundColor3 = Color3.new(.15, .15, .15)
                PageButton.BackgroundTransparency = .35
                PageButton.AutoButtonColor = false
                PageButton.Parent = PageSelector_Container

                local PageButton_UICorner = Instance.new("UICorner")
                PageButton_UICorner.CornerRadius = UDim.new(0, 4)
                PageButton_UICorner.Parent = PageButton

                local PageButton_Container = Instance.new("Frame")
                PageButton_Container.Size = UDim2.fromScale(1, 1)
                PageButton_Container.BackgroundTransparency = 1
                PageButton_Container.Parent = PageButton

                local PageButton_Container_UIPadding = Instance.new("UIPadding")
                PageButton_Container_UIPadding.PaddingLeft = UDim.new(0, 12)
                PageButton_Container_UIPadding.PaddingRight = UDim.new(0, 12)
                PageButton_Container_UIPadding.Parent = PageButton_Container

                local PageButton_Container_UIListLayout = Instance.new("UIListLayout")
                PageButton_Container_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                PageButton_Container_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                PageButton_Container_UIListLayout.Padding = UDim.new(0, 10)
                PageButton_Container_UIListLayout.Parent = PageButton_Container

                local PageButton_Active = Instance.new("Frame")
                PageButton_Active.Size = UDim2.new(0, 4, .45, 0)
                PageButton_Active.AnchorPoint = Vector2.new(0.5, .5)
                PageButton_Active.Position = UDim2.fromScale(0, 0.5)
                PageButton_Active.BackgroundColor3 = Color3.new(.45, .3, 1)
                PageButton_Active.Parent = PageButton
                
                local PageButton_Active_UICorner = Instance.new("UICorner")
                PageButton_Active_UICorner.CornerRadius = UDim.new(1, 0)
                PageButton_Active_UICorner.Parent = PageButton_Active

                local IconId = ""
                if typeof(comp.props.icon) == "string" then
                    IconId = comp.props.icon
                elseif typeof(comp.props.icon) == "table" or not comp.props.icon then
                    IconId = 
                        comp.props.icon and IconUtils.resolveIcon(comp.props.icon, self.context.settings.iconPack)
                        or IconPackUtils.resolveIconPack(self.context.settings.iconPack).Icon(
                            DefaultIcons[table.concat({
                                self.context.settings.iconPack.pack,
                                self.context.settings.iconPack.variant
                            }, "/")].Page
                        )
                end

                local PageButton_Icon = Instance.new("ImageLabel")
                PageButton_Icon.Size = UDim2.fromOffset(22, 22)
                PageButton_Icon.Image = IconId
                PageButton_Icon.BackgroundTransparency = 1
                PageButton_Icon.Parent = PageButton_Container

                local PageButton_Label = Instance.new("TextLabel")
                PageButton_Label.Text = comp.props.title or "Yooo"
                PageButton_Label.Size = UDim2.fromScale(0, 1)
                PageButton_Label.TextSize = 18
                PageButton_Label.FontFace = Font.new(
                    "rbxasset://fonts/families/Roboto.json",
                    Enum.FontWeight.Medium,
                    Enum.FontStyle.Normal
                )
                PageButton_Label.BackgroundTransparency = 1
                PageButton_Label.TextColor3 = Color3.new(1, 1, 1)
                PageButton_Label.AutomaticSize = Enum.AutomaticSize.X
                PageButton_Label.Parent = PageButton_Container

                local PageView_Wrapped = Instance.new("CanvasGroup")
                PageView_Wrapped.Size = UDim2.fromScale(1, 1)
                PageView_Wrapped.BackgroundTransparency = 1
                comp.Instance.Parent = PageView_Wrapped
                PageView_Wrapped.Parent = PageView
                self.context:Add(PageView_Wrapped)

                local id = _PageNum + 1
                _PageNum = id
                
                self.context:Add(PageButton.MouseButton1Click:Connect(function()
                    _CurrentPage.Value = id
                end))

                local PageTween
                local IndicatorTween
                local ButtonTween
                local ButtonIconTween
                local ButtonLabelTween

                local function update(skipAnimate)
                    local duration = if skipAnimate and skipAnimate == true then 0 else .15

                    local active = _CurrentPage.Value == id

                    if PageTween and PageTween.PlaybackState == Enum.PlaybackState.Playing then
                        PageTween:Cancel()
                    end

                    if IndicatorTween and IndicatorTween.PlaybackState == Enum.PlaybackState.Playing then
                        IndicatorTween:Cancel()
                    end

                    if ButtonTween and ButtonTween.PlaybackState == Enum.PlaybackState.Playing then
                        ButtonTween:Cancel()
                    end

                    if ButtonIconTween and ButtonIconTween.PlaybackState == Enum.PlaybackState.Playing then
                        ButtonIconTween:Cancel()
                    end

                    if ButtonLabelTween and ButtonLabelTween.PlaybackState == Enum.PlaybackState.Playing then
                        ButtonLabelTween:Cancel()
                    end

                    if not active then
                        -- Tweening the button

                        ButtonTween = TweenService:Create(PageButton, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                            BackgroundTransparency = 1
                        })

                        ButtonTween:Play()

                        -- Tweening the button icon

                        ButtonIconTween = TweenService:Create(PageButton_Icon, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                            ImageTransparency = 0.5
                        })

                        ButtonIconTween:Play()

                        -- Tweening the button label

                        ButtonLabelTween = TweenService:Create(PageButton_Label, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                            TextTransparency = 0.5
                        })

                        ButtonLabelTween:Play()

                        -- Tweening the indicator

                        IndicatorTween = TweenService:Create(PageButton_Active, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                            Size = UDim2.new(0, 4, 0, 0),
                            BackgroundTransparency = 1
                        })

                        IndicatorTween:Play()

                        self.context:Add(IndicatorTween.Completed:Connect(function()
                            PageButton_Active.Visible = false
                        end))

                        -- Tweening the page

                        PageTween = TweenService:Create(PageView_Wrapped, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            GroupTransparency = 1,
                            Position = UDim2.fromOffset(0, -10)
                        })
                        
                        self.context:Add(PageTween.Completed:Connect(function()
                            PageView_Wrapped.Visible = false
                        end))

                        PageTween:Play()
                    elseif active then
                        task.delay(duration/2, function()
                            -- Tweening the button

                            PageButton.BackgroundTransparency = 1

                            ButtonTween = TweenService:Create(PageButton, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                BackgroundTransparency = .35
                            })

                            ButtonTween:Play()

                            -- Tweening the button icon

                            ButtonIconTween = TweenService:Create(PageButton_Icon, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                ImageTransparency = 0
                            })

                            ButtonIconTween:Play()
                            
                            -- Tweening the button label

                            ButtonLabelTween = TweenService:Create(PageButton_Label, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                TextTransparency = 0
                            })

                            ButtonLabelTween:Play()

                            -- Tweening the indicator

                            PageButton_Active.Size = UDim2.new(0, 4, 0, 0)
                            PageButton_Active.Visible = true
                            PageButton_Active.BackgroundTransparency = 1

                            IndicatorTween = TweenService:Create(PageButton_Active, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                                Size = UDim2.new(0, 4, 0.45, 0),
                                BackgroundTransparency = 0
                            })

                            IndicatorTween:Play()

                            -- Tweening the page

                            PageView_Wrapped.Position = UDim2.fromOffset(0, 10)
                            PageView_Wrapped.Visible = true

                            PageTween = TweenService:Create(PageView_Wrapped, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                GroupTransparency = 0,
                                Position = UDim2.fromOffset(0, 0)
                            })

                            PageTween:Play()
                        end)
                    end
                end

                update(true)

                self.context:Add(_CurrentPage.Changed:Connect(update))

                table.insert(_Pages, {
                    id = id,
                    comp = comp
                })

                print("Page!", comp.props.title)
            end

            return
        end

        return self
    end
end