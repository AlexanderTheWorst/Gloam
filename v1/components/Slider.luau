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
        @type SliderProps = {
            label: string,
            icon?: Icon -- default: DefaultIcons<Slider>,
            default?: number -- default: 0,
            min?: number -- default: 0,
            max?: number -- default: 100,
            step?: number -- default: 1,

        }

        @type Slider {
            Instance: Frame,
            Parent: Window | Page | Section,
            props: SliderProps,
            context: Context,

            Destroy: (Slider) -> ()
        }
    ]]

	--[[

        Creates a Slider component

        @param props = SliderProps
        @param parentContext = Context
        @return Slider
    ]]

	return function(props, parentContext)
		-- Creating `self`

		local self = Component.new({
			props = props,
		}, "Slider")

		-- Hooking up context

		setmetatable(self.context, {
			__index = parentContext,
		})

		-- Variables

		local _Value = Instance.new("NumberValue")
		_Value.Value = props.default or 0

		local _SliderValue = Instance.new("NumberValue")
		_SliderValue.Value = props.default or 0

		local _Dragging = Instance.new("BoolValue")
		local _Hovering = Instance.new("BoolValue")
		local _DragStart = Vector2.new(0, 0)
		local _DragOld = Vector2.new(0, 0)

		local _LastThumbX = nil

        local THUMB_IDLE_WIDTH = 16
        local THUMB_DRAG_WIDTH = 16
        local THUMB_HEIGHT = 16

        local MAX_THUMB_STRETCH = 24
        local VELOCITY_TO_STRETCH = .025

        local THUMB_STRETCH_SPEED = 20
        local THUMB_RELEASE_SPEED = 12

        local _ThumbWidth = THUMB_IDLE_WIDTH
        local _ThumbHeight = THUMB_HEIGHT

        -- Functions
        
		local function getPrecision(step)
			local str = tostring(step)

			local decimal = str:find(".", 1, true)

			if not decimal then
				return 0
			end

			return #str - decimal
		end

		local function normalizeValue(value)
			local min = props.min or 0
			local max = props.max or 100
			local step = props.step or 1

			value = min + math.round((value - min) / step) * step
			value = math.clamp(value, min, max)

			return value
		end

        -- Calulcated before UI

        local min = props.min or 0
        local max = props.max or 100
        local step = props.step or 1

        local precision = getPrecision(step)

        local minText = string.format(
            "%." .. precision .. "f",
            min
        )

        local maxText = string.format(
            "%." .. precision .. "f",
            max
        )

        local TextService = game:GetService("TextService")

        local minSize = TextService:GetTextSize(
            minText,
            18,
            Enum.Font.Roboto,
            Vector2.new(math.huge, math.huge)
        )

        local maxSize = TextService:GetTextSize(
            maxText,
            18,
            Enum.Font.Roboto,
            Vector2.new(math.huge, math.huge)
        )

        local valueWidth = math.max(
            minSize.X,
            maxSize.X
        )

		-- UI

		local Slider = Instance.new("Frame")
        Slider.AutomaticSize = Enum.AutomaticSize.Y
        Slider.Size = UDim2.fromScale(1, 0)
        Slider.BorderSizePixel = 0
        Slider.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        Slider.BackgroundTransparency = 0.35

		local Slider_UIListLayout = Instance.new("UIListLayout")
        Slider_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Slider_UIListLayout.Padding = UDim.new(0, 12)
        Slider_UIListLayout.Parent = Slider

		local Slider_UIPadding = Instance.new("UIPadding")
        Slider_UIPadding.PaddingBottom = UDim.new(0, 12)
        Slider_UIPadding.PaddingTop = UDim.new(0, 12)
        Slider_UIPadding.PaddingRight = UDim.new(0, 16)
        Slider_UIPadding.PaddingLeft = UDim.new(0, 12)
        Slider_UIPadding.Parent = Slider

		local Slider_UICorner = Instance.new("UICorner")
        Slider_UICorner.CornerRadius = UDim.new(0, 8)
        Slider_UICorner.Parent = Slider

		local Slider_Label_Section = Instance.new("Frame")
        Slider_Label_Section.AutomaticSize = Enum.AutomaticSize.Y
        Slider_Label_Section.Size = UDim2.fromScale(1, 0)
        Slider_Label_Section.BackgroundTransparency = 1
        Slider_Label_Section.Parent = Slider

		local Slider_Label_Section_UIListLayout = Instance.new("UIListLayout")
        Slider_Label_Section_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Slider_Label_Section_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Slider_Label_Section_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        Slider_Label_Section_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Slider_Label_Section_UIListLayout.Padding = UDim.new(0, 0)
        Slider_Label_Section_UIListLayout.Parent = Slider_Label_Section

		local Slider_Label_Section_Left = Instance.new("Frame")
        Slider_Label_Section_Left.AutomaticSize = Enum.AutomaticSize.XY
        Slider_Label_Section_Left.Size = UDim2.fromScale(0, 0)
        Slider_Label_Section_Left.BackgroundTransparency = 1
        Slider_Label_Section_Left.Parent = Slider_Label_Section

		local Slider_Label_Section_Left_UIListLayout = Instance.new("UIListLayout")
        Slider_Label_Section_Left_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        Slider_Label_Section_Left_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        Slider_Label_Section_Left_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Slider_Label_Section_Left_UIListLayout.Padding = UDim.new(0, 12)
        Slider_Label_Section_Left_UIListLayout.Parent = Slider_Label_Section_Left

		local Slider_Label_Section_Left_UIFlexItem = Instance.new("UIFlexItem")
        Slider_Label_Section_Left_UIFlexItem.FlexMode = Enum.UIFlexMode.Grow
        Slider_Label_Section_Left_UIFlexItem.Parent = Slider_Label_Section_Left

		local Slider_Label_Section_Left_UIPadding = Instance.new("UIPadding")
        Slider_Label_Section_Left_UIPadding.PaddingRight = UDim.new(0, valueWidth * 2 + 6)
        Slider_Label_Section_Left_UIPadding.Parent = Slider_Label_Section_Left

		local Slider_Label_Icon = Instance.new("ImageLabel")
        Slider_Label_Icon.Image = if not props.icon then IconPackUtils.resolveIconPack(self.context.settings.iconPack).Icon(
            DefaultIcons[table.concat({
                self.context.settings.iconPack.pack,
                self.context.settings.iconPack.variant,
            }, "/")].Slider) else IconUtils.resolveIcon(props.icon, self.context.settings.iconPack)
        Slider_Label_Icon.BackgroundTransparency = 1
        Slider_Label_Icon.LayoutOrder = 1
        Slider_Label_Icon.Size = UDim2.fromOffset(22, 22)
        Slider_Label_Icon.Parent = Slider_Label_Section_Left

		local Slider_Label = Instance.new("TextLabel")
        Slider_Label.Text = props.label or "Slider"
        Slider_Label.TextSize = 18
        Slider_Label.TextColor3 = Color3.new(1, 1, 1)
        Slider_Label.BackgroundTransparency = 1
        Slider_Label.Size = UDim2.fromScale(0, 0)
        Slider_Label.TextWrapped = true
        Slider_Label.TextXAlignment = Enum.TextXAlignment.Left
        Slider_Label.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        Slider_Label.AutomaticSize = Enum.AutomaticSize.XY
        Slider_Label.LayoutOrder = 2
        Slider_Label.Parent = Slider_Label_Section_Left

		local Slider_Value = Instance.new("TextLabel")
        Slider_Value.Text = props.min or 0
        Slider_Value.TextSize = 18
        Slider_Value.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        Slider_Value.BackgroundTransparency = 1
        Slider_Value.Size = UDim2.fromOffset(valueWidth * 3 + 6, 0)
        Slider_Value.TextWrapped = true
        Slider_Value.LayoutOrder = 4
        Slider_Value.TextXAlignment = Enum.TextXAlignment.Right
        Slider_Value.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        Slider_Value.AutomaticSize = Enum.AutomaticSize.Y
        Slider_Value.Parent = Slider_Label_Section

		local Slider_Value_UIFlexItem = Instance.new("UIFlexItem")
        Slider_Value_UIFlexItem.FlexMode = Enum.UIFlexMode.Custom
        Slider_Value_UIFlexItem.Parent = Slider_Value

		local Slider_Container = Instance.new("TextButton")
        Slider_Container.Size = UDim2.new(1, 0, 0, 15)
        Slider_Container.TextTransparency = 1
        Slider_Container.BackgroundTransparency = 1
        Slider_Container.LayoutOrder = 3
        Slider_Container.Parent = Slider_Label_Section

		local Slider_Container_UIFlexItem = Instance.new("UIFlexItem")
        Slider_Container_UIFlexItem.FlexMode = Enum.UIFlexMode.Fill
        Slider_Container_UIFlexItem.Parent = Slider_Container

		local Slider_Track = Instance.new("Frame")
        Slider_Track.Size = UDim2.new(1, 0, 0, 8)
        Slider_Track.BackgroundColor3 = Color3.new(1, 1, 1)
        Slider_Track.BackgroundTransparency = 0.35
        Slider_Track.AnchorPoint = Vector2.new(0.5, 0.5)
        Slider_Track.Position = UDim2.fromScale(0.5, 0.5)
        Slider_Track.Parent = Slider_Container

		local Slider_Track_UIGradient = Instance.new("UIGradient")
        Slider_Track_UIGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0.45, 0.3, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.new(0.45, 0.3, 1)),
            ColorSequenceKeypoint.new(0.501, Color3.new(0.25, 0.25, 0.25)),
            ColorSequenceKeypoint.new(1, Color3.new(0.25, 0.25, 0.25)),
		})
        Slider_Track_UIGradient.Parent = Slider_Track

		local Slider_Track_UICorner = Instance.new("UICorner")
        Slider_Track_UICorner.CornerRadius = UDim.new(1, 0)
        Slider_Track_UICorner.Parent = Slider_Track

		local Slider_Thumb = Instance.new("Frame")
		Slider_Thumb.Size = UDim2.fromOffset(32, 16)
		Slider_Thumb.BackgroundColor3 = Color3.new(1, 1, 1)
		Slider_Thumb.Position = UDim2.new(0, 16, 0.5, 0)
		Slider_Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
		Slider_Thumb.ZIndex = 2
		Slider_Thumb.Parent = Slider_Track

		local Slider_Thumb_UICorner = Instance.new("UICorner")
		Slider_Thumb_UICorner.CornerRadius = UDim.new(1, 0)
		Slider_Thumb_UICorner.Parent = Slider_Thumb

		local Slider_Thumb_UIShadow = Instance.new("UIShadow")
		Slider_Thumb_UIShadow.BlurRadius = UDim.new(0, 15)
		Slider_Thumb_UIShadow.Transparency = 0.75
		Slider_Thumb_UIShadow.Parent = Slider_Thumb

		local Slider_Popover_Container = Instance.new("Frame")
		Slider_Popover_Container.Size = UDim2.fromOffset(40, 45)
		Slider_Popover_Container.AnchorPoint = Vector2.new(0.5, 0)
		Slider_Popover_Container.BackgroundTransparency = 1
		Slider_Popover_Container.Parent = self.context.globalGUI

		local Slider_Popover_Container_UIShadow = Instance.new("UIShadow")
		Slider_Popover_Container_UIShadow.BlurRadius = UDim.new(0, 20)
		Slider_Popover_Container_UIShadow.Transparency = 0.75
		Slider_Popover_Container_UIShadow.Parent = Slider_Popover_Container

		local Slider_Popover = Instance.new("CanvasGroup")
		Slider_Popover.Size = UDim2.fromScale(1, 1)
		Slider_Popover.BackgroundTransparency = 1
		Slider_Popover.Parent = Slider_Popover_Container

		local Slider_Popover_UIScale = Instance.new("UIScale")
		Slider_Popover_UIScale.Parent = Slider_Popover

		local Slider_Popover_Value = Instance.new("TextLabel")
		Slider_Popover_Value.BackgroundTransparency = 1
		Slider_Popover_Value.TextSize = 16
		Slider_Popover_Value.TextColor3 = Color3.new(1, 1, 1)
		Slider_Popover_Value.AnchorPoint = Vector2.new(0.5, 0)
		Slider_Popover_Value.Position = UDim2.new(0.5, 0, 0, 19)
		Slider_Popover_Value.Text = "50"
		Slider_Popover_Value.FontFace =
			Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		Slider_Popover.ZIndex = 2
		Slider_Popover_Value.Parent = Slider_Popover

		local Slider_Popover_Background = Instance.new("CanvasGroup")
		Slider_Popover_Background.Size = UDim2.fromScale(1, 1)
		Slider_Popover_Background.BackgroundTransparency = 1
		Slider_Popover_Background.GroupTransparency = 0.125
		Slider_Popover_Background.ZIndex = 0
		Slider_Popover_Background.Parent = Slider_Popover

		local Slider_Popover_Background_Container = Instance.new("Frame")
		Slider_Popover_Background_Container.Size = UDim2.new(1, -2, 1, -10)
		Slider_Popover_Background_Container.Position = UDim2.new(0, 1, 0, 1)
		Slider_Popover_Background_Container.ZIndex = 1
		Slider_Popover_Background_Container.BackgroundColor3 = Color3.new(0.20, 0.20, 0.20)
		Slider_Popover_Background_Container.BorderSizePixel = 0
		Slider_Popover_Background_Container.Parent = Slider_Popover_Background

		local Slider_Popover_Background_Container_UICorner = Instance.new("UICorner")
		Slider_Popover_Background_Container_UICorner.CornerRadius = UDim.new(0, 8)
		Slider_Popover_Background_Container_UICorner.Parent = Slider_Popover_Background_Container

		local Slider_Popover_Background_Container_Stroke = Instance.new("Frame")
		Slider_Popover_Background_Container_Stroke.Size = UDim2.new(1, 0, 1, -8)
		Slider_Popover_Background_Container_Stroke.Position = UDim2.new(0, 0, 0, 0)
		Slider_Popover_Background_Container_Stroke.BackgroundColor3 = Color3.new(0.35, 0.35, 0.35)
		Slider_Popover_Background_Container_Stroke.ZIndex = 0
		Slider_Popover_Background_Container_Stroke.Parent = Slider_Popover_Background

		local Slider_Popover_Background_Container_Stroke_UICorner = Instance.new("UICorner")
		Slider_Popover_Background_Container_Stroke_UICorner.CornerRadius = UDim.new(0, 8)
		Slider_Popover_Background_Container_Stroke_UICorner.Parent = Slider_Popover_Background_Container_Stroke

		local Slider_Popover_Background_Arrow = Instance.new("Frame")
		Slider_Popover_Background_Arrow.Rotation = 45
		Slider_Popover_Background_Arrow.Size = UDim2.new(0, 10, 0, 10)
		Slider_Popover_Background_Arrow.AnchorPoint = Vector2.new(0.5, 1)
		Slider_Popover_Background_Arrow.BackgroundColor3 = Color3.new(0.20, 0.20, 0.20)
		Slider_Popover_Background_Arrow.BorderSizePixel = 0
		Slider_Popover_Background_Arrow.Position = UDim2.new(0.5, 1, 1, -6)
		Slider_Popover_Background_Arrow.Parent = Slider_Popover_Background

		local Slider_Popover_Background_Arrow_UICorner = Instance.new("UICorner")
		Slider_Popover_Background_Arrow_UICorner.CornerRadius = UDim.new(0, 2)
		Slider_Popover_Background_Arrow_UICorner.Parent = Slider_Popover_Background_Arrow

		local Slider_Popover_Background_Arrow_Stroke = Instance.new("Frame")
		Slider_Popover_Background_Arrow_Stroke.Size = UDim2.new(0, 12, 0, 12)
		Slider_Popover_Background_Arrow_Stroke.AnchorPoint = Vector2.new(0.5, 1)
        Slider_Popover_Background_Arrow_Stroke.Position = UDim2.new(0.5, 1, 1, -4)
        Slider_Popover_Background_Arrow_Stroke.BorderSizePixel = 0
        Slider_Popover_Background_Arrow_Stroke.BackgroundColor3 = Color3.new(0.35, 0.35, 0.35)
        Slider_Popover_Background_Arrow_Stroke.ZIndex = 0
        Slider_Popover_Background_Arrow_Stroke.Rotation = 45
        Slider_Popover_Background_Arrow_Stroke.Parent = Slider_Popover_Background

		local Slider_Popover_Background_Arrow_Stroke_UICorner = Instance.new("UICorner")
        Slider_Popover_Background_Arrow_Stroke_UICorner.CornerRadius = UDim.new(0, 2)
        Slider_Popover_Background_Arrow_Stroke_UICorner.Parent = Slider_Popover_Background_Arrow_Stroke

		-- Component data

		self.Instance = Slider

		-- Runtime

		local events = EventHandler.ExtractEvents(props)

		local function getSliderValue()
			local location = UserInputService:GetMouseLocation()

			local scale =
				math.clamp((location.X - Slider_Container.AbsolutePosition.X) / Slider_Container.AbsoluteSize.X, 0, 1)

			local min = props.min or 0
			local max = props.max or 100
			local step = props.step or 1
			local value = min + (max - min) * scale

			value = min + math.round((value - min) / step) * step
			value = math.clamp(value, min, max)

			local valueScale = (value - min) / (max - min)

			local offset = 5 - (valueScale * 10)

			return value, valueScale, offset
		end

		local function renderValue(value)
			local min = props.min or 0
			local max = props.max or 100
			local step = props.step or 1

			value = normalizeValue(value)

			local valueScale = (value - min) / (max - min)
			local offset = 5 - (valueScale * 10)

			TweenService:Create(Slider_Thumb, TweenInfo.new(0.125), {
				Position = UDim2.new(valueScale, offset, 0.5, 0),
			}):Play()

			TweenService:Create(Slider_Track_UIGradient, TweenInfo.new(0.125), {
				Offset = Vector2.new(valueScale - 0.5, 0),
			}):Play()

			local precision = getPrecision(step)
			value = tonumber(string.format("%." .. precision .. "f", value))

			_Value.Value = value
			_SliderValue.Value = value
		end

		local function updateSlider()
			local location = UserInputService:GetMouseLocation()

			local scale =
				math.clamp((location.X - Slider_Container.AbsolutePosition.X) / Slider_Container.AbsoluteSize.X, 0, 1)
			local min = props.min or 0
			local max = props.max or 100
			local value = min + (max - min) * scale

			renderValue(value)
		end

		self.context:Add(Slider_Container.MouseButton1Click:Connect(function()
			if events.Has("onClick") then
				events.Fire("onClick")
			end

			updateSlider()
		end))

		self.context:Add(Slider_Container.MouseButton1Down:Connect(function()
			_Dragging.Value = true

			_DragStart = UserInputService:GetMouseLocation()
			_DragOld = _DragStart

			updateSlider()
		end))

		self.context:Add(UserInputService.InputChanged:Connect(function(input)
			if _Dragging.Value and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateSlider()
			end
		end))

		self.context:Add(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and _Dragging.Value then
				_Dragging.Value = false
			end
		end))

		self.context:Add(Slider_Container.MouseEnter:Connect(function()
			_Hovering.Value = true
		end))

		self.context:Add(Slider_Container.MouseLeave:Connect(function()
			_Hovering.Value = false
		end))

		self.context:Add(_Value.Changed:Connect(function(new)
			Slider_Popover_Value.Text = new

			Slider_Popover_Container.Size = UDim2.fromOffset(Slider_Popover_Value.TextBounds.X + 20, 45)
		end))

		self.context:Add(_SliderValue.Changed:Connect(function(new)
			Slider_Value.Text = new

			if events.Has("onChange") then
				events.Fire("onChange", new)
			end
		end))

        self.context:Add(
            RunService.RenderStepped:Connect(function(dt)
                local thumbX =
                    Slider_Thumb.AbsolutePosition.X
                    + Slider_Thumb.AbsoluteSize.X / 2

                local targetStretch = 0

                if _LastThumbX then
                    local velocity =
                        math.abs(thumbX - _LastThumbX)
                        / math.max(dt, 1 / 240)

                    targetStretch = math.clamp(
                        velocity * VELOCITY_TO_STRETCH,
                        0,
                        MAX_THUMB_STRETCH
                    )
                end

                _LastThumbX = thumbX

                -- Width stretch
                local baseWidth =
                    _Dragging.Value
                        and THUMB_DRAG_WIDTH
                    or THUMB_IDLE_WIDTH

                local targetWidth =
                    baseWidth + targetStretch

                local widthSpeed =
                    targetWidth > _ThumbWidth
                        and THUMB_STRETCH_SPEED
                    or THUMB_RELEASE_SPEED

                _ThumbWidth +=
                    (targetWidth - _ThumbWidth)
                    * (1 - math.exp(-widthSpeed * dt))

                -- Height squish
                local targetHeight = math.clamp(
                    THUMB_HEIGHT - targetStretch * 1,
                    12,
                    THUMB_HEIGHT
                )

                local heightSpeed =
                    targetHeight < _ThumbHeight
                        and THUMB_STRETCH_SPEED
                    or THUMB_RELEASE_SPEED

                _ThumbHeight +=
                    (targetHeight - _ThumbHeight)
                    * (1 - math.exp(-heightSpeed * dt))

                Slider_Thumb.Size = UDim2.fromOffset(
                    _ThumbWidth,
                    _ThumbHeight
                )

                -- Popover
                if
                    not _Hovering.Value
                    and not _Dragging.Value
                then
                    return
                end

                local value, valueScale, offset =
                    getSliderValue()

                if
                    _Hovering.Value
                    and not _Dragging.Value
                then
                    local precision =
                        getPrecision(props.step or 1)

                    value = tonumber(string.format(
                        "%." .. precision .. "f",
                        value
                    ))

                    _Value.Value = value
                end

                local absPos =
                    Slider_Container.AbsolutePosition.X
                    + Slider_Container.AbsoluteSize.X
                        * valueScale

                Slider_Popover_Container.Position =
                    UDim2.new(
                        0,
                        absPos + offset,
                        0,
                        Slider_Container.AbsolutePosition.Y + 5
                    )
            end)
        )

        self.context:Add(_Dragging.Changed:Connect(function()
            TweenService:Create(Slider_Thumb_UIShadow, TweenInfo.new(.125), {
                Transparency = _Dragging.Value and 0.75 or 0.85,
                BlurRadius = _Dragging.Value and UDim.new(0, 15) or UDim.new(0, 10),
            }):Play()
        end))

		local shadowTween
		local canvasTween
		local scaleTween

		local function updatePopover()
			if shadowTween then
				shadowTween:Cancel()
				shadowTween = nil
			end

			if canvasTween then
				canvasTween:Cancel()
				canvasTween = nil
			end

			if scaleTween then
				scaleTween:Cancel()
				scaleTween = nil
			end

			local visible = _Dragging.Value or _Hovering.Value

			shadowTween = TweenService:Create(Slider_Popover_Container_UIShadow, TweenInfo.new(0.075), {
				Transparency = visible and 0.75 or 1,
			})

			canvasTween = TweenService:Create(Slider_Popover, TweenInfo.new(0.075), {
				GroupTransparency = visible and 0 or 1,
				Position = visible and UDim2.fromOffset(0, 0) or UDim2.fromOffset(0, 5),
			})

			scaleTween = TweenService:Create(Slider_Popover_UIScale, TweenInfo.new(0.075), {
				Scale = visible and 1 or 0.85,
			})

			shadowTween:Play()

			canvasTween:Play()

			scaleTween:Play()
		end

		self.context:Add(_Dragging.Changed:Connect(updatePopover))

		self.context:Add(_Hovering.Changed:Connect(updatePopover))

		renderValue(props.default or props.min or 0)

		return self
	end
end