local SmileUILib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

SmileUILib.Theme = {
	Background        = Color3.fromRGB(15,  15,  20 ),
	Surface           = Color3.fromRGB(20,  20,  27 ),
	SurfaceLight      = Color3.fromRGB(27,  27,  36 ),
	SurfaceLighter    = Color3.fromRGB(33,  33,  44 ),
	Header            = Color3.fromRGB(18,  18,  25 ),
	Accent            = Color3.fromRGB(120, 80,  220),
	AccentDark        = Color3.fromRGB(90,  55,  170),
	AccentDarker      = Color3.fromRGB(55,  35,  110),
	AccentVeryDark    = Color3.fromRGB(28,  18,  55 ),
	AccentHover       = Color3.fromRGB(140, 100, 240),
	Text              = Color3.fromRGB(240, 240, 255),
	TextDim           = Color3.fromRGB(140, 140, 165),
	StrokeColor       = Color3.fromRGB(45,  45,  60 ),
	BorderAccent      = Color3.fromRGB(80,  55,  160),
	CornerRadius      = UDim.new(0, 4),
	StrokeThickness   = 1,
	StrokeTransparency= 0,
	Font              = Enum.Font.GothamSemibold,
	NotificationCornerRadius   = UDim.new(0, 6),
	NotificationHeaderHeight   = 30,
	NotificationStrokeThickness= 1,
	WindowHeaderHeight         = 36,
	WindowMinButtonSize        = UDim2.new(0, 26, 0, 20),
	WindowIconSize             = UDim2.new(0, 36, 0, 36),
	TabButtonHeight            = 28,
	TabButtonCornerRadius      = UDim.new(0, 4),
	ElementCornerRadius        = UDim.new(0, 4),
	ButtonHeight               = 28,
	ToggleHeight               = 28,
	SliderHeight               = 50,
	DropdownHeight             = 28,
	KeybindHeight              = 28,
	TextboxHeight              = 28,
	SpacerDefaultHeight        = 6,
	AnimationSpeed             = 0.15,
	NotificationInSpeed        = 0.5,
	NotificationOutSpeed       = 0.4,
	WindowOpenSpeed            = 0.5,
}

SmileUILib.Windows           = {}
SmileUILib.ThemeableElements = {}
SmileUILib.ButtonRegistry    = {}

local function RegisterElement(windowId, element, property, themeKey)
	if not SmileUILib.ThemeableElements[windowId] then
		SmileUILib.ThemeableElements[windowId] = {}
	end
	table.insert(SmileUILib.ThemeableElements[windowId], {
		Element  = element,
		Property = property,
		ThemeKey = themeKey
	})
end

local function RegisterButton(windowId, button, isAccentButton)
	if not SmileUILib.ButtonRegistry[windowId] then
		SmileUILib.ButtonRegistry[windowId] = {}
	end
	table.insert(SmileUILib.ButtonRegistry[windowId], {
		Button          = button,
		IsAccentButton  = isAccentButton
	})
end

function SmileUILib:SetTheme(newTheme)
	for key, value in pairs(newTheme) do
		self.Theme[key] = value
	end
	for windowId, elements in pairs(self.ThemeableElements) do
		for _, data in ipairs(elements) do
			if data.Element and data.Element.Parent then
				local color = self.Theme[data.ThemeKey]
				if color then
					data.Element[data.Property] = color
				end
			end
		end
	end
	for windowId, buttons in pairs(self.ButtonRegistry) do
		for _, data in ipairs(buttons) do
			if data.Button and data.Button.Parent then
				if data.IsAccentButton then
					data.Button.BackgroundColor3 = self.Theme.AccentDarker
				end
			end
		end
	end
end

local function Color3ToHSV(color)
	local r, g, b = color.R, color.G, color.B
	local max   = math.max(r, g, b)
	local min   = math.min(r, g, b)
	local delta = max - min
	local h, s, v = 0, 0, max
	if delta ~= 0 then
		s = delta / max
		if max == r then
			h = (g - b) / delta + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / delta + 2
		else
			h = (r - g) / delta + 4
		end
		h = h / 6
	end
	return h, s, v
end

local function HSVToColor3(h, s, v)
	local r, g, b
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
	return Color3.new(r, g, b)
end

local notifContainer
local function initNotifications()
	if notifContainer then return end
	local screen = Instance.new("ScreenGui")
	screen.Name = "SmileNotifications"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 999999
	screen.Parent = CoreGui
	notifContainer = Instance.new("Frame")
	notifContainer.Size = UDim2.new(0, 320, 1, -20)
	notifContainer.Position = UDim2.new(1, -330, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.Parent = screen
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = notifContainer
end

function SmileUILib:Notify(options)
	local title    = options.title    or "INFO"
	local message  = options.message  or ""
	local duration = options.duration or 3.7
	local width    = options.width    or 320
	local theme    = options.theme    or SmileUILib.Theme
	initNotifications()

	local notif = Instance.new("Frame")
	notif.BackgroundColor3 = theme.Surface or theme.Background
	notif.BorderSizePixel  = 0
	notif.ZIndex           = 999999
	notif.Parent           = notifContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = theme.NotificationCornerRadius
	corner.Parent = notif

	local stroke = Instance.new("UIStroke")
	stroke.Color       = theme.StrokeColor
	stroke.Thickness   = theme.NotificationStrokeThickness
	stroke.Transparency= theme.StrokeTransparency
	stroke.Parent      = notif

	local accentBar = Instance.new("Frame")
	accentBar.Size            = UDim2.new(0, 3, 1, 0)
	accentBar.BackgroundColor3= theme.Accent
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex          = 1000000
	accentBar.Parent          = notif
	local abc = Instance.new("UICorner")
	abc.CornerRadius = UDim.new(0, 3)
	abc.Parent = accentBar

	local header = Instance.new("Frame")
	header.Size            = UDim2.new(1, -3, 0, theme.NotificationHeaderHeight)
	header.Position        = UDim2.new(0, 3, 0, 0)
	header.BackgroundColor3= theme.Header
	header.BorderSizePixel = 0
	header.Parent          = notif

	local hcorner = Instance.new("UICorner")
	hcorner.CornerRadius = theme.CornerRadius
	hcorner.Parent = header

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size             = UDim2.new(1, -20, 1, 0)
	titleLbl.Position         = UDim2.new(0, 10, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text             = title
	titleLbl.TextColor3       = theme.Text
	titleLbl.Font             = theme.Font
	titleLbl.TextSize         = 13
	titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
	titleLbl.TextTruncate     = Enum.TextTruncate.AtEnd
	titleLbl.Parent           = header

	local content = Instance.new("TextLabel")
	content.Position          = UDim2.new(0, 10, 0, theme.NotificationHeaderHeight + 4)
	content.BackgroundTransparency = 1
	content.Text              = message
	content.TextColor3        = theme.TextDim
	content.Font              = theme.Font
	content.TextSize          = 12
	content.TextXAlignment    = Enum.TextXAlignment.Left
	content.TextYAlignment    = Enum.TextYAlignment.Top
	content.TextWrapped       = true
	content.AutomaticSize     = Enum.AutomaticSize.Y
	content.Size              = UDim2.new(1, -20, 0, 0)
	content.Parent            = notif

	task.wait()
	local textHeight  = content.TextBounds.Y
	local notifHeight = theme.NotificationHeaderHeight + textHeight + 12

	notif.Size = UDim2.new(0, 0, 0, notifHeight)
	notif.BackgroundTransparency = 1

	TweenService:Create(notif, TweenInfo.new(theme.NotificationInSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, width, 0, notifHeight),
		BackgroundTransparency = 0
	}):Play()

	task.delay(duration, function()
		local out = TweenService:Create(notif, TweenInfo.new(theme.NotificationOutSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, notifHeight),
			BackgroundTransparency = 1
		})
		out:Play()
		out.Completed:Connect(function() notif:Destroy() end)
	end)
end

function SmileUILib:CreateWindow(options)
	local title         = options.title         or "SMILE UI"
	local width         = options.width         or 580
	local height        = options.height        or 420
	local theme         = options.theme         or SmileUILib.Theme
	local iconText      = options.iconText      or "☰"
	local tabsWidth     = options.tabsWidth     or 130
	local contentOffset = options.contentOffset or 150

	local windowId = "Window_" .. math.floor(tick() * 1000)
	local screen = Instance.new("ScreenGui")
	screen.Name = "SmileUI_" .. windowId
	screen.ResetOnSpawn = false
	screen.Parent = CoreGui
	self.Windows[windowId] = screen

	local main = Instance.new("Frame")
	main.Name            = "Main"
	main.Size            = UDim2.new(0, width, 0, height)
	main.Position        = UDim2.new(0.5, -width/2, 0.5, -height/2)
	main.BackgroundColor3= theme.Surface
	main.Active          = true
	main.BorderSizePixel = 0
	main.Parent          = screen

	RegisterElement(windowId, main, "BackgroundColor3", "Surface")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color       = theme.StrokeColor
	stroke.Thickness   = theme.StrokeThickness
	stroke.Transparency= theme.StrokeTransparency
	stroke.Parent      = main
	RegisterElement(windowId, stroke, "Color", "StrokeColor")

	local shadow = Instance.new("ImageLabel")
	shadow.AnchorPoint         = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position            = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size                = UDim2.new(1, 30, 1, 30)
	shadow.Image               = "rbxassetid://5028857084"
	shadow.ImageColor3         = Color3.new(0, 0, 0)
	shadow.ImageTransparency   = 0.6
	shadow.ScaleType           = Enum.ScaleType.Slice
	shadow.SliceCenter         = Rect.new(24, 24, 276, 276)
	shadow.ZIndex              = 0
	shadow.Parent              = main

	local header = Instance.new("Frame")
	header.Size            = UDim2.new(1, 0, 0, theme.WindowHeaderHeight)
	header.BackgroundColor3= theme.Header
	header.BorderSizePixel = 0
	header.Parent          = main
	RegisterElement(windowId, header, "BackgroundColor3", "Header")

	local hcorner = Instance.new("UICorner")
	hcorner.CornerRadius = UDim.new(0, 6)
	hcorner.Parent = header

	local hfix = Instance.new("Frame")
	hfix.Size            = UDim2.new(1, 0, 0, 6)
	hfix.Position        = UDim2.new(0, 0, 1, -6)
	hfix.BackgroundColor3= theme.Header
	hfix.BorderSizePixel = 0
	hfix.Parent          = header
	RegisterElement(windowId, hfix, "BackgroundColor3", "Header")

	local accentLine = Instance.new("Frame")
	accentLine.Size            = UDim2.new(1, 0, 0, 1)
	accentLine.Position        = UDim2.new(0, 0, 1, -1)
	accentLine.BackgroundColor3= theme.Accent
	accentLine.BorderSizePixel = 0
	accentLine.ZIndex          = 3
	accentLine.Parent          = header
	RegisterElement(windowId, accentLine, "BackgroundColor3", "Accent")

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size           = UDim2.new(1, -70, 1, 0)
	titleLabel.Position       = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text           = title
	titleLabel.TextColor3     = theme.Text
	titleLabel.Font           = theme.Font
	titleLabel.TextSize       = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate   = Enum.TextTruncate.AtEnd
	titleLabel.Parent         = header
	RegisterElement(windowId, titleLabel, "TextColor3", "Text")

	local minBtn = Instance.new("TextButton")
	minBtn.Size            = theme.WindowMinButtonSize
	minBtn.Position        = UDim2.new(1, -32, 0.5, -10)
	minBtn.BackgroundColor3= theme.AccentVeryDark
	minBtn.Text            = "−"
	minBtn.TextColor3      = theme.TextDim
	minBtn.Font            = theme.Font
	minBtn.TextSize        = 16
	minBtn.AutoButtonColor = false
	minBtn.BorderSizePixel = 0
	minBtn.Parent          = header
	local mbc = Instance.new("UICorner")
	mbc.CornerRadius = UDim.new(0, 4)
	mbc.Parent = minBtn
	RegisterElement(windowId, minBtn, "TextColor3", "TextDim")

	minBtn.MouseEnter:Connect(function()
		TweenService:Create(minBtn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.Accent, TextColor3 = SmileUILib.Theme.Text}):Play()
	end)
	minBtn.MouseLeave:Connect(function()
		TweenService:Create(minBtn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark, TextColor3 = SmileUILib.Theme.TextDim}):Play()
	end)

	local bodyBg = Instance.new("Frame")
	bodyBg.Size            = UDim2.new(1, 0, 1, -theme.WindowHeaderHeight)
	bodyBg.Position        = UDim2.new(0, 0, 0, theme.WindowHeaderHeight)
	bodyBg.BackgroundColor3= theme.Background
	bodyBg.BorderSizePixel = 0
	bodyBg.ClipsDescendants= true
	bodyBg.Parent          = main
	RegisterElement(windowId, bodyBg, "BackgroundColor3", "Background")

	local bodyCorner = Instance.new("UICorner")
	bodyCorner.CornerRadius = UDim.new(0, 6)
	bodyCorner.Parent = bodyBg

	local bodyFix = Instance.new("Frame")
	bodyFix.Size            = UDim2.new(1, 0, 0, 6)
	bodyFix.BackgroundColor3= theme.Background
	bodyFix.BorderSizePixel = 0
	bodyFix.Parent          = bodyBg
	RegisterElement(windowId, bodyFix, "BackgroundColor3", "Background")

	local icon = Instance.new("Frame")
	icon.Size            = theme.WindowIconSize
	icon.BackgroundColor3= theme.Header
	icon.Visible         = false
	icon.Active          = true
	icon.Draggable       = true
	icon.BorderSizePixel = 0
	icon.Parent          = screen
	RegisterElement(windowId, icon, "BackgroundColor3", "Header")

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 4)
	iconCorner.Parent = icon

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color     = theme.StrokeColor
	iconStroke.Thickness = 1
	iconStroke.Parent    = icon
	RegisterElement(windowId, iconStroke, "Color", "StrokeColor")

	local iconTextBtn = Instance.new("TextButton")
	iconTextBtn.Size              = UDim2.new(1, 0, 1, 0)
	iconTextBtn.BackgroundTransparency = 1
	iconTextBtn.Text              = iconText
	iconTextBtn.TextColor3        = theme.Accent
	iconTextBtn.Font              = theme.Font
	iconTextBtn.TextSize          = 18
	iconTextBtn.Parent            = icon
	RegisterElement(windowId, iconTextBtn, "TextColor3", "Accent")

	minBtn.MouseButton1Click:Connect(function()
		main.Visible  = false
		icon.Position = UDim2.new(0, main.AbsolutePosition.X + main.AbsoluteSize.X - icon.AbsoluteSize.X, 0, main.AbsolutePosition.Y)
		icon.Visible  = true
	end)
	iconTextBtn.MouseButton1Click:Connect(function()
		icon.Visible = false
		main.Visible = true
	end)

	local tabs = Instance.new("Frame")
	tabs.Size            = UDim2.new(0, tabsWidth, 1, -16)
	tabs.Position        = UDim2.new(0, 8, 0, 8)
	tabs.BackgroundColor3= theme.SurfaceLight
	tabs.BorderSizePixel = 0
	tabs.Parent          = bodyBg
	RegisterElement(windowId, tabs, "BackgroundColor3", "SurfaceLight")

	local tabsCorner = Instance.new("UICorner")
	tabsCorner.CornerRadius = UDim.new(0, 4)
	tabsCorner.Parent = tabs

	local tabsStroke = Instance.new("UIStroke")
	tabsStroke.Color     = theme.StrokeColor
	tabsStroke.Thickness = 1
	tabsStroke.Parent    = tabs
	RegisterElement(windowId, tabsStroke, "Color", "StrokeColor")

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding    = UDim.new(0, 3)
	tabLayout.SortOrder  = Enum.SortOrder.LayoutOrder
	tabLayout.Parent     = tabs

	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingTop    = UDim.new(0, 6)
	tabPad.PaddingBottom = UDim.new(0, 6)
	tabPad.PaddingLeft   = UDim.new(0, 6)
	tabPad.PaddingRight  = UDim.new(0, 6)
	tabPad.Parent        = tabs

	local content = Instance.new("Frame")
	content.Size            = UDim2.new(1, -(contentOffset), 1, -16)
	content.Position        = UDim2.new(0, contentOffset - 6, 0, 8)
	content.BackgroundTransparency = 1
	content.Parent          = bodyBg

	do
		local dragging   = false
		local dragStartPos, startGuiPos

		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging      = true
				dragStartPos  = input.Position
				startGuiPos   = main.Position

				local dragConn, endConn

				dragConn = UserInputService.InputChanged:Connect(function(input2)
					if dragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
						local delta = input2.Position - dragStartPos
						main.Position = UDim2.new(startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X, startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y)
					end
				end)

				endConn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						dragConn:Disconnect()
						endConn:Disconnect()
					end
				end)
			end
		end)
	end

	local window     = {}
	window.Id        = windowId
	local activePage = nil

	function window:SetTheme(newTheme)
		SmileUILib:SetTheme(newTheme)
	end

	function window:AddTab(tabOptions)
		local tabName = tabOptions.name  or "Tab"
		local theme   = tabOptions.theme or SmileUILib.Theme

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size            = UDim2.new(1, 0, 0, theme.TabButtonHeight)
		tabBtn.BackgroundColor3= theme.Background
		tabBtn.Text            = tabName
		tabBtn.TextColor3      = theme.TextDim
		tabBtn.Font            = theme.Font
		tabBtn.TextSize        = 12
		tabBtn.AutoButtonColor = false
		tabBtn.BorderSizePixel = 0
		tabBtn.TextTruncate    = Enum.TextTruncate.AtEnd
		tabBtn.Parent          = tabs
		RegisterElement(windowId, tabBtn, "TextColor3", "TextDim")

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = theme.TabButtonCornerRadius
		btnCorner.Parent = tabBtn

		local page = Instance.new("ScrollingFrame")
		page.Size               = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.ScrollBarThickness = 2
		page.ScrollBarImageColor3 = theme.Accent
		page.Visible            = false
		page.CanvasSize         = UDim2.new(0, 0, 0, 0)
		page.BorderSizePixel    = 0
		page.Parent             = content
		RegisterElement(windowId, page, "ScrollBarImageColor3", "Accent")

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding   = UDim.new(0, 6)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent    = page

		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingBottom = UDim.new(0, 8)
		pagePad.PaddingRight  = UDim.new(0, 4)
		pagePad.Parent        = page

		pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
		end)

		tabBtn.MouseEnter:Connect(function()
			if activePage ~= page then
				TweenService:Create(tabBtn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = theme.AccentVeryDark}):Play()
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if activePage ~= page then
				TweenService:Create(tabBtn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = theme.Background}):Play()
			end
		end)
		tabBtn.MouseButton1Click:Connect(function()
			if activePage then activePage.Visible = false end
			page.Visible = true
			activePage   = page

			for _, b in tabs:GetChildren() do
				if b:IsA("TextButton") then
					local isActive = (b == tabBtn)
					TweenService:Create(b, TweenInfo.new(theme.AnimationSpeed), {
						BackgroundColor3 = isActive and theme.AccentDarker or theme.Background,
						TextColor3       = isActive and theme.Accent       or theme.TextDim
					}):Play()
					if isActive then
						RegisterElement(windowId, b, "TextColor3", "Accent")
					else
						RegisterElement(windowId, b, "TextColor3", "TextDim")
					end
				end
			end
		end)

		if not activePage then
			tabBtn.BackgroundColor3 = theme.AccentDarker
			tabBtn.TextColor3       = theme.Accent
			page.Visible            = true
			activePage              = page
			RegisterElement(windowId, tabBtn, "TextColor3", "Accent")
		end

		local tabAPI  = {}
		tabAPI.page   = page

		function tabAPI:AddSection(secOptions)
			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(1, -4, 0, 0)
			lbl.AutomaticSize   = Enum.AutomaticSize.Y
			lbl.BackgroundTransparency = 1
			lbl.Text            = (secOptions.title or "Section"):upper()
			lbl.TextColor3      = secOptions.textColor or theme.Accent
			lbl.Font            = theme.Font
			lbl.TextSize        = secOptions.textSize or 10
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextWrapped     = true
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = page

			local lpad = Instance.new("UIPadding")
			lpad.PaddingLeft = UDim.new(0, 4)
			lpad.Parent      = lbl

			RegisterElement(windowId, lbl, "TextColor3", "Accent")
			return lbl
		end

		function tabAPI:AddLabel(lblOptions)
			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(1, -4, 0, 0)
			lbl.AutomaticSize   = Enum.AutomaticSize.Y
			lbl.BackgroundTransparency = 1
			lbl.Text            = lblOptions.text or "Label"
			lbl.TextColor3      = lblOptions.textColor or theme.TextDim
			lbl.Font            = theme.Font
			lbl.TextSize        = lblOptions.textSize or 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextWrapped     = true
			lbl.Parent          = page
			RegisterElement(windowId, lbl, "TextColor3", "TextDim")
			return lbl
		end

		function tabAPI:AddSpacer(spacerOptions)
			local spacer = Instance.new("Frame")
			spacer.Size             = UDim2.new(1, -4, 0, spacerOptions and spacerOptions.height or theme.SpacerDefaultHeight)
			spacer.BackgroundTransparency = 1
			spacer.Parent           = page
			return spacer
		end

		function tabAPI:AddButton(btnOptions)
			local text   = btnOptions.text     or "Button"
			local callback = btnOptions.callback
			local height = btnOptions.height   or theme.ButtonHeight

			local btn = Instance.new("TextButton")
			btn.Size            = UDim2.new(1, -4, 0, height)
			btn.BackgroundColor3= theme.AccentVeryDark
			btn.Text            = ""
			btn.AutoButtonColor = false
			btn.BorderSizePixel = 0
			btn.Parent          = page

			RegisterElement(windowId, btn, "BackgroundColor3", "AccentVeryDark")
			RegisterButton(windowId, btn, true)

			local c = Instance.new("UICorner")
			c.CornerRadius = theme.ElementCornerRadius
			c.Parent = btn

			local s = Instance.new("UIStroke")
			s.Color     = theme.StrokeColor
			s.Thickness = 1
			s.Parent    = btn
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local tick = Instance.new("Frame")
			tick.Size            = UDim2.new(0, 2, 0.5, 0)
			tick.AnchorPoint     = Vector2.new(0, 0.5)
			tick.Position        = UDim2.new(0, 3, 0.5, 0)
			tick.BackgroundColor3= theme.Accent
			tick.BorderSizePixel = 0
			tick.Parent          = btn
			local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,2); tc.Parent = tick
			RegisterElement(windowId, tick, "BackgroundColor3", "Accent")

			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(1, -14, 1, 0)
			lbl.Position        = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text            = text
			lbl.TextColor3      = theme.Text
			lbl.Font            = theme.Font
			lbl.TextSize        = 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = btn
			RegisterElement(windowId, lbl, "TextColor3", "Text")

			btn.MouseButton1Click:Connect(function()
				if callback then callback() end
			end)
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentDarker}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}):Play()
			end)
			return btn
		end

		function tabAPI:AddToggle(togOptions)
			local name     = togOptions.name     or "Toggle"
			local default  = togOptions.default  or false
			local callback = togOptions.callback
			local height   = togOptions.height   or theme.ToggleHeight
			local bgColor  = togOptions.bgColor  or theme.SurfaceLight

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, height)
			frame.BackgroundColor3= bgColor
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(0.65, 0, 1, 0)
			lbl.Position        = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text            = name
			lbl.TextColor3      = theme.Text
			lbl.Font            = theme.Font
			lbl.TextSize        = 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = frame
			RegisterElement(windowId, lbl, "TextColor3", "Text")

			local pillW, pillH = 34, 18
			local pill = Instance.new("Frame")
			pill.Size            = UDim2.new(0, pillW, 0, pillH)
			pill.AnchorPoint     = Vector2.new(1, 0.5)
			pill.Position        = UDim2.new(1, -8, 0.5, 0)
			pill.BackgroundColor3= default and theme.Accent or theme.AccentVeryDark
			pill.BorderSizePixel = 0
			pill.Parent          = frame
			local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pill
			local ps = Instance.new("UIStroke"); ps.Color = theme.BorderAccent; ps.Thickness = 1; ps.Parent = pill
			RegisterElement(windowId, pill, "BackgroundColor3", default and "Accent" or "AccentVeryDark")

			local knob = Instance.new("Frame")
			knob.Size            = UDim2.new(0, pillH - 6, 0, pillH - 6)
			knob.AnchorPoint     = Vector2.new(0, 0.5)
			knob.Position        = UDim2.new(0, default and (pillW - pillH + 3) or 3, 0.5, 0)
			knob.BackgroundColor3= theme.Text
			knob.BorderSizePixel = 0
			knob.Parent          = pill
			local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

			local state = default
			local api   = {}

			function api:GetState() return state end
			function api:SetState(bool)
				state = bool
				TweenService:Create(pill, TweenInfo.new(theme.AnimationSpeed), {
					BackgroundColor3 = state and SmileUILib.Theme.Accent or SmileUILib.Theme.AccentVeryDark
				}):Play()
				TweenService:Create(knob, TweenInfo.new(theme.AnimationSpeed), {
					Position = UDim2.new(0, state and (pillW - pillH + 3) or 3, 0.5, 0)
				}):Play()
				RegisterElement(windowId, pill, "BackgroundColor3", state and "Accent" or "AccentVeryDark")
				if callback then callback(state) end
			end

			frame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					api:SetState(not state)
				end
			end)
			frame.MouseEnter:Connect(function()
				TweenService:Create(frame, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}):Play()
			end)
			frame.MouseLeave:Connect(function()
				TweenService:Create(frame, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.SurfaceLight}):Play()
			end)

			return api
		end

		function tabAPI:AddSlider(sliderOptions)
			local name     = sliderOptions.name    or "Slider"
			local min      = sliderOptions.min     or 0
			local max      = sliderOptions.max     or 100
			local default  = math.clamp(sliderOptions.default or min, min, max)
			local callback = sliderOptions.callback
			local height   = sliderOptions.height  or theme.SliderHeight
			local bgColor  = sliderOptions.bgColor or theme.SurfaceLight
			local step     = sliderOptions.step    or 1

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, height)
			frame.BackgroundColor3= bgColor
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local topRow = Instance.new("Frame")
			topRow.Size            = UDim2.new(1, -16, 0, 20)
			topRow.Position        = UDim2.new(0, 8, 0, 6)
			topRow.BackgroundTransparency = 1
			topRow.Parent          = frame

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size            = UDim2.new(0.65, 0, 1, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text            = name
			nameLbl.TextColor3      = theme.Text
			nameLbl.Font            = theme.Font
			nameLbl.TextSize        = 12
			nameLbl.TextXAlignment  = Enum.TextXAlignment.Left
			nameLbl.TextTruncate    = Enum.TextTruncate.AtEnd
			nameLbl.Parent          = topRow
			RegisterElement(windowId, nameLbl, "TextColor3", "Text")

			local valLbl = Instance.new("TextLabel")
			valLbl.Size            = UDim2.new(0.35, 0, 1, 0)
			valLbl.Position        = UDim2.new(0.65, 0, 0, 0)
			valLbl.BackgroundTransparency = 1
			valLbl.Text            = tostring(default)
			valLbl.TextColor3      = theme.Accent
			valLbl.Font            = theme.Font
			valLbl.TextSize        = 12
			valLbl.TextXAlignment  = Enum.TextXAlignment.Right
			valLbl.Parent          = topRow
			RegisterElement(windowId, valLbl, "TextColor3", "Accent")

			local track = Instance.new("Frame")
			track.Size            = UDim2.new(1, -16, 0, 6)
			track.Position        = UDim2.new(0, 8, 0, height - 14)
			track.BackgroundColor3= theme.AccentVeryDark
			track.BorderSizePixel = 0
			track.Parent          = frame
			local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = track
			RegisterElement(windowId, track, "BackgroundColor3", "AccentVeryDark")

			local fill = Instance.new("Frame")
			fill.Size            = UDim2.new((default - min) / (max - min), 0, 1, 0)
			fill.BackgroundColor3= theme.Accent
			fill.BorderSizePixel = 0
			fill.Parent          = track
			local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill
			RegisterElement(windowId, fill, "BackgroundColor3", "Accent")

			local knobSz = 12
			local knobF  = Instance.new("Frame")
			knobF.Size            = UDim2.new(0, knobSz, 0, knobSz)
			knobF.AnchorPoint     = Vector2.new(0.5, 0.5)
			knobF.Position        = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
			knobF.BackgroundColor3= theme.Text
			knobF.BorderSizePixel = 0
			knobF.ZIndex          = 2
			knobF.Parent          = track
			local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knobF
			local ks = Instance.new("UIStroke"); ks.Color = theme.Accent; ks.Thickness = 2; ks.Parent = knobF
			RegisterElement(windowId, ks, "Color", "Accent")

			local value = default
			local api   = {}

			function api:GetValue() return value end
			function api:SetValue(newVal)
				newVal  = math.clamp(newVal, min, max)
				newVal  = math.floor((newVal / step) + 0.5) * step
				value   = newVal
				local t = (value - min) / (max - min)
				fill.Size      = UDim2.new(t, 0, 1, 0)
				knobF.Position = UDim2.new(t, 0, 0.5, 0)
				valLbl.Text    = tostring(value)
				if callback then callback(value) end
			end

			local dragging = false
			local dragInputConn, dragEndConn

			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragInputConn = UserInputService.InputChanged:Connect(function(input2)
						if not dragging then return end
						if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
							local rel = math.clamp((input2.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
							api:SetValue(min + (max - min) * rel)
						end
					end)
					dragEndConn = UserInputService.InputEnded:Connect(function(input2)
						if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
							dragging = false
							if dragInputConn then dragInputConn:Disconnect() end
							if dragEndConn   then dragEndConn:Disconnect()   end
						end
					end)
				end
			end)

			frame.Destroying:Connect(function()
				if dragInputConn then dragInputConn:Disconnect() end
				if dragEndConn   then dragEndConn:Disconnect()   end
			end)

			return api
		end

		function tabAPI:AddDropdown(dropOptions)
			local name     = dropOptions.name    or "Dropdown"
			local options  = dropOptions.options or {"Option 1", "Option 2"}
			local default  = dropOptions.default or options[1]
			local callback = dropOptions.callback
			local height   = dropOptions.height  or theme.DropdownHeight
			local bgColor  = dropOptions.bgColor or theme.SurfaceLight

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, height)
			frame.BackgroundColor3= bgColor
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(0.45, 0, 1, 0)
			lbl.Position        = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text            = name
			lbl.TextColor3      = theme.Text
			lbl.Font            = theme.Font
			lbl.TextSize        = 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = frame
			RegisterElement(windowId, lbl, "TextColor3", "Text")

			local selected = Instance.new("TextButton")
			selected.Size            = UDim2.new(0.48, 0, 0, height - 8)
			selected.Position        = UDim2.new(0.5, 0, 0, 4)
			selected.BackgroundColor3= theme.AccentVeryDark
			selected.Text            = default
			selected.TextColor3      = theme.Accent
			selected.Font            = theme.Font
			selected.TextSize        = 11
			selected.TextTruncate    = Enum.TextTruncate.AtEnd
			selected.BorderSizePixel = 0
			selected.AutoButtonColor = false
			selected.Parent          = frame
			RegisterElement(windowId, selected, "BackgroundColor3", "AccentVeryDark")
			RegisterElement(windowId, selected, "TextColor3", "Accent")
			RegisterButton(windowId, selected, true)

			local sc = Instance.new("UICorner"); sc.CornerRadius = theme.ElementCornerRadius; sc.Parent = selected
			local ss = Instance.new("UIStroke"); ss.Color = theme.BorderAccent; ss.Thickness = 1; ss.Parent = selected
			RegisterElement(windowId, ss, "Color", "BorderAccent")

			local arrow = Instance.new("TextLabel")
			arrow.Size            = UDim2.new(0, 14, 1, 0)
			arrow.AnchorPoint     = Vector2.new(1, 0.5)
			arrow.Position        = UDim2.new(1, -4, 0.5, 0)
			arrow.BackgroundTransparency = 1
			arrow.Text            = "▾"
			arrow.TextColor3      = theme.Accent
			arrow.Font            = theme.Font
			arrow.TextSize        = 10
			arrow.Parent          = selected
			RegisterElement(windowId, arrow, "TextColor3", "Accent")

			local current   = 1
			for i, v in ipairs(options) do
				if v == default then current = i; break end
			end
			local selection = options[current]

			local api = {}
			function api:GetSelection() return selection end
			function api:SetSelection(choice)
				for i, v in ipairs(options) do
					if v == choice then
						current   = i
						selection = choice
						selected.Text = choice
						if callback then callback(selection) end
						return
					end
				end
			end

			selected.MouseButton1Click:Connect(function()
				current   = (current % #options) + 1
				selection = options[current]
				selected.Text = selection
				if callback then callback(selection) end
			end)
			selected.MouseEnter:Connect(function()
				TweenService:Create(selected, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentDarker}):Play()
			end)
			selected.MouseLeave:Connect(function()
				TweenService:Create(selected, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}):Play()
			end)
			frame.MouseEnter:Connect(function()
				TweenService:Create(frame, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}):Play()
			end)
			frame.MouseLeave:Connect(function()
				TweenService:Create(frame, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.SurfaceLight}):Play()
			end)

			return api
		end

		function tabAPI:AddKeybind(keyOptions)
			local name       = keyOptions.name       or "Keybind"
			local defaultKey = keyOptions.defaultKey  or Enum.KeyCode.Unknown
			local callback   = keyOptions.callback
			local height     = keyOptions.height     or theme.KeybindHeight
			local bgColor    = keyOptions.bgColor    or theme.SurfaceLight
			local allowMouse = keyOptions.allowMouse  or false

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, height)
			frame.BackgroundColor3= bgColor
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(0.6, 0, 1, 0)
			lbl.Position        = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text            = name
			lbl.TextColor3      = theme.Text
			lbl.Font            = theme.Font
			lbl.TextSize        = 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = frame
			RegisterElement(windowId, lbl, "TextColor3", "Text")

			local btn = Instance.new("TextButton")
			btn.Size            = UDim2.new(0, 80, 0, height - 8)
			btn.AnchorPoint     = Vector2.new(1, 0.5)
			btn.Position        = UDim2.new(1, -6, 0.5, 0)
			btn.BackgroundColor3= theme.AccentVeryDark
			btn.Text            = defaultKey.Name
			btn.TextColor3      = theme.Accent
			btn.Font            = theme.Font
			btn.TextSize        = 11
			btn.TextTruncate    = Enum.TextTruncate.AtEnd
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Parent          = frame
			RegisterElement(windowId, btn, "BackgroundColor3", "AccentVeryDark")
			RegisterElement(windowId, btn, "TextColor3", "Accent")
			RegisterButton(windowId, btn, true)

			local bc = Instance.new("UICorner"); bc.CornerRadius = theme.ElementCornerRadius; bc.Parent = btn
			local bs = Instance.new("UIStroke"); bs.Color = theme.BorderAccent; bs.Thickness = 1; bs.Parent = btn
			RegisterElement(windowId, bs, "Color", "BorderAccent")

			local listening  = false
			local currentKey = defaultKey
			local api        = {}

			function api:GetKey() return currentKey end
			function api:SetKey(key)
				currentKey = key
				btn.Text   = currentKey.Name
				if callback then callback(currentKey) end
			end

			btn.MouseButton1Click:Connect(function()
				listening = true
				btn.Text  = "..."
				btn.TextColor3 = theme.TextDim
			end)

			local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
				if processed or not listening then return end
				listening = false
				btn.TextColor3 = theme.Accent
				if input.UserInputType == Enum.UserInputType.Keyboard then
					api:SetKey(input.KeyCode)
				elseif allowMouse and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) then
					api:SetKey(input.UserInputType)
				else
					btn.Text = currentKey.Name
					return
				end
			end)

			btn.MouseEnter:Connect(function()
				if not listening then
					TweenService:Create(btn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentDarker}):Play()
				end
			end)
			btn.MouseLeave:Connect(function()
				if not listening then
					TweenService:Create(btn, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}):Play()
				end
			end)
			frame.Destroying:Connect(function() inputConn:Disconnect() end)

			return api
		end

		function tabAPI:AddTextbox(tbOptions)
			local name     = tbOptions.name    or "Textbox"
			local default  = tbOptions.default or ""
			local callback = tbOptions.callback
			local height   = tbOptions.height  or theme.TextboxHeight
			local bgColor  = tbOptions.bgColor or theme.SurfaceLight

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, height)
			frame.BackgroundColor3= bgColor
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(0.45, 0, 1, 0)
			lbl.Position        = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text            = name
			lbl.TextColor3      = theme.Text
			lbl.Font            = theme.Font
			lbl.TextSize        = 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = frame
			RegisterElement(windowId, lbl, "TextColor3", "Text")

			local textbox = Instance.new("TextBox")
			textbox.Size            = UDim2.new(0.48, 0, 0, height - 8)
			textbox.Position        = UDim2.new(0.5, 0, 0, 4)
			textbox.BackgroundColor3= theme.AccentVeryDark
			textbox.Text            = default
			textbox.TextColor3      = theme.Text
			textbox.PlaceholderColor3 = theme.TextDim
			textbox.Font            = theme.Font
			textbox.TextSize        = 12
			textbox.TextTruncate    = Enum.TextTruncate.AtEnd
			textbox.BorderSizePixel = 0
			textbox.ClearTextOnFocus= false
			textbox.Parent          = frame
			RegisterElement(windowId, textbox, "BackgroundColor3", "AccentVeryDark")
			RegisterElement(windowId, textbox, "TextColor3", "Text")

			local tbc = Instance.new("UICorner"); tbc.CornerRadius = theme.ElementCornerRadius; tbc.Parent = textbox
			local tbs = Instance.new("UIStroke"); tbs.Color = theme.BorderAccent; tbs.Thickness = 1; tbs.Parent = textbox
			RegisterElement(windowId, tbs, "Color", "BorderAccent")

			local text = default
			local api  = {}

			function api:GetText() return text end
			function api:SetText(newText)
				text = newText
				textbox.Text = newText
				if callback then callback(text) end
			end

			textbox.FocusLost:Connect(function(enterPressed)
				if enterPressed then
					api:SetText(textbox.Text)
				else
					textbox.Text = text
				end
			end)
			textbox.Focused:Connect(function()
				TweenService:Create(textbox, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentDarker}):Play()
			end)
			textbox.FocusLost:Connect(function()
				TweenService:Create(textbox, TweenInfo.new(theme.AnimationSpeed), {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}):Play()
			end)

			return api
		end

		function tabAPI:AddProgressBar(pbOptions)
			local name    = pbOptions.name   or "Progress"
			local max     = pbOptions.max    or 100
			local value   = pbOptions.value  or 0
			local height  = pbOptions.height or 46
			local bgColor = pbOptions.bgColor or theme.SurfaceLight

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, height)
			frame.BackgroundColor3= bgColor
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local topRow = Instance.new("Frame")
			topRow.Size            = UDim2.new(1, -16, 0, 20)
			topRow.Position        = UDim2.new(0, 8, 0, 4)
			topRow.BackgroundTransparency = 1
			topRow.Parent          = frame

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size            = UDim2.new(0.65, 0, 1, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text            = name
			nameLbl.TextColor3      = theme.Text
			nameLbl.Font            = theme.Font
			nameLbl.TextSize        = 12
			nameLbl.TextXAlignment  = Enum.TextXAlignment.Left
			nameLbl.TextTruncate    = Enum.TextTruncate.AtEnd
			nameLbl.Parent          = topRow
			RegisterElement(windowId, nameLbl, "TextColor3", "Text")

			local pctLbl = Instance.new("TextLabel")
			pctLbl.Size            = UDim2.new(0.35, 0, 1, 0)
			pctLbl.Position        = UDim2.new(0.65, 0, 0, 0)
			pctLbl.BackgroundTransparency = 1
			pctLbl.Text            = math.floor((value / max) * 100) .. "%"
			pctLbl.TextColor3      = theme.Accent
			pctLbl.Font            = theme.Font
			pctLbl.TextSize        = 12
			pctLbl.TextXAlignment  = Enum.TextXAlignment.Right
			pctLbl.Parent          = topRow
			RegisterElement(windowId, pctLbl, "TextColor3", "Accent")

			local track = Instance.new("Frame")
			track.Size            = UDim2.new(1, -16, 0, 6)
			track.Position        = UDim2.new(0, 8, 0, height - 14)
			track.BackgroundColor3= theme.AccentVeryDark
			track.BorderSizePixel = 0
			track.Parent          = frame
			local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = track
			RegisterElement(windowId, track, "BackgroundColor3", "AccentVeryDark")

			local fill = Instance.new("Frame")
			fill.Size            = UDim2.new(value / max, 0, 1, 0)
			fill.BackgroundColor3= theme.Accent
			fill.BorderSizePixel = 0
			fill.Parent          = track
			local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, theme.AccentHover),
				ColorSequenceKeypoint.new(1, theme.Accent)
			})
			gradient.Rotation = 0
			gradient.Parent   = fill

			RegisterElement(windowId, fill, "BackgroundColor3", "Accent")

			local curValue = value
			local api      = {}

			function api:GetValue() return curValue end
			function api:SetValue(newValue)
				newValue = math.clamp(newValue, 0, max)
				curValue = newValue
				TweenService:Create(fill, TweenInfo.new(theme.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(newValue / max, 0, 1, 0)
				}):Play()
				pctLbl.Text = math.floor((newValue / max) * 100) .. "%"
			end

			return api
		end

		function tabAPI:AddColorPicker(cpOptions)
			local name     = cpOptions.name     or "Color Picker"
			local default  = cpOptions.default  or Color3.fromRGB(120, 80, 220)
			local callback = cpOptions.callback

			local frame = Instance.new("Frame")
			frame.Size            = UDim2.new(1, -4, 0, 32)
			frame.BackgroundColor3= theme.SurfaceLight
			frame.BorderSizePixel = 0
			frame.Parent          = page
			RegisterElement(windowId, frame, "BackgroundColor3", "SurfaceLight")

			local c = Instance.new("UICorner"); c.CornerRadius = theme.ElementCornerRadius; c.Parent = frame
			local s = Instance.new("UIStroke"); s.Color = theme.StrokeColor; s.Thickness = 1; s.Parent = frame
			RegisterElement(windowId, s, "Color", "StrokeColor")

			local lbl = Instance.new("TextLabel")
			lbl.Size            = UDim2.new(1, -70, 1, 0)
			lbl.Position        = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text            = name
			lbl.TextColor3      = theme.Text
			lbl.Font            = theme.Font
			lbl.TextSize        = 12
			lbl.TextXAlignment  = Enum.TextXAlignment.Left
			lbl.TextTruncate    = Enum.TextTruncate.AtEnd
			lbl.Parent          = frame
			RegisterElement(windowId, lbl, "TextColor3", "Text")

			local colorBox = Instance.new("TextButton")
			colorBox.Size            = UDim2.new(0, 46, 0, 22)
			colorBox.AnchorPoint     = Vector2.new(1, 0.5)
			colorBox.Position        = UDim2.new(1, -8, 0.5, 0)
			colorBox.BackgroundColor3= default
			colorBox.Text            = ""
			colorBox.AutoButtonColor = false
			colorBox.BorderSizePixel = 0
			colorBox.Parent          = frame

			local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 4); cbc.Parent = colorBox
			local boxStroke = Instance.new("UIStroke")
			boxStroke.Color     = theme.BorderAccent
			boxStroke.Thickness = 2
			boxStroke.Parent    = colorBox
			RegisterElement(windowId, boxStroke, "Color", "BorderAccent")

			colorBox.MouseEnter:Connect(function()
				TweenService:Create(boxStroke, TweenInfo.new(0.2), {Thickness = 3}):Play()
			end)
			colorBox.MouseLeave:Connect(function()
				TweenService:Create(boxStroke, TweenInfo.new(0.2), {Thickness = 2}):Play()
			end)

			local modalOpen  = false
			local modalFrame = nil

			local function closeModal()
				if modalFrame then
					TweenService:Create(modalFrame, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 280, 0, 0),
						BackgroundTransparency = 1
					}):Play()
					task.wait(0.2)
					if modalFrame then modalFrame:Destroy(); modalFrame = nil end
					modalOpen = false
				end
			end

			local function openModal()
				if modalOpen then closeModal(); return end
				modalOpen = true

				local overlay = Instance.new("Frame")
				overlay.Name            = "ColorPickerModal"
				overlay.Size            = UDim2.new(0, 280, 0, 320)
				overlay.Position        = UDim2.new(0, frame.AbsolutePosition.X + frame.AbsoluteSize.X - 280, 0, frame.AbsolutePosition.Y + 36)
				overlay.BackgroundColor3= SmileUILib.Theme.Surface
				overlay.BorderSizePixel = 0
				overlay.ZIndex          = 100
				overlay.Parent          = screen
				modalFrame              = overlay

				local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 6); oc.Parent = overlay
				local os = Instance.new("UIStroke"); os.Color = SmileUILib.Theme.StrokeColor; os.Thickness = 1; os.Parent = overlay

				local mHeader = Instance.new("Frame")
				mHeader.Size            = UDim2.new(1, 0, 0, 30)
				mHeader.BackgroundColor3= SmileUILib.Theme.Header
				mHeader.BorderSizePixel = 0
				mHeader.ZIndex          = 101
				mHeader.Parent          = overlay
				local mhc = Instance.new("UICorner"); mhc.CornerRadius = UDim.new(0, 6); mhc.Parent = mHeader

				local mTitle = Instance.new("TextLabel")
				mTitle.Size           = UDim2.new(1, -40, 1, 0)
				mTitle.Position       = UDim2.new(0, 10, 0, 0)
				mTitle.BackgroundTransparency = 1
				mTitle.Text           = "Pick a Color"
				mTitle.TextColor3     = SmileUILib.Theme.Text
				mTitle.Font           = SmileUILib.Theme.Font
				mTitle.TextSize       = 13
				mTitle.TextXAlignment = Enum.TextXAlignment.Left
				mTitle.ZIndex         = 102
				mTitle.Parent         = mHeader

				local closeBtn = Instance.new("TextButton")
				closeBtn.Size            = UDim2.new(0, 24, 0, 24)
				closeBtn.Position        = UDim2.new(1, -28, 0, 3)
				closeBtn.BackgroundColor3= SmileUILib.Theme.AccentVeryDark
				closeBtn.Text            = "×"
				closeBtn.TextColor3      = SmileUILib.Theme.Text
				closeBtn.Font            = SmileUILib.Theme.Font
				closeBtn.TextSize        = 16
				closeBtn.BorderSizePixel = 0
				closeBtn.ZIndex          = 102
				closeBtn.Parent          = mHeader
				local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0,4); clc.Parent = closeBtn
				closeBtn.MouseButton1Click:Connect(closeModal)

				local h, s, v = Color3ToHSV(default)
				local currentColor = default

				local spectrumFrame = Instance.new("Frame")
				spectrumFrame.Size            = UDim2.new(0, 200, 0, 140)
				spectrumFrame.Position        = UDim2.new(0, 12, 0, 42)
				spectrumFrame.BackgroundColor3= Color3.new(1, 1, 1)
				spectrumFrame.BorderSizePixel = 0
				spectrumFrame.ZIndex          = 101
				spectrumFrame.Parent          = overlay
				local sfc = Instance.new("UICorner"); sfc.CornerRadius = UDim.new(0, 4); sfc.Parent = spectrumFrame

				local satGradient = Instance.new("UIGradient")
				satGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, HSVToColor3(h, 1, 1))
				})
				satGradient.Parent = spectrumFrame

				local valOverlay = Instance.new("Frame")
				valOverlay.Size            = UDim2.new(1, 0, 1, 0)
				valOverlay.BackgroundTransparency = 0
				valOverlay.BorderSizePixel = 0
				valOverlay.ZIndex          = 102
				valOverlay.Parent          = spectrumFrame
				local voc = Instance.new("UICorner"); voc.CornerRadius = UDim.new(0, 4); voc.Parent = valOverlay

				local valGradient = Instance.new("UIGradient")
				valGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
				})
				valGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0)
				})
				valGradient.Rotation = 90
				valGradient.Parent   = valOverlay

				local cursor = Instance.new("Frame")
				cursor.Size            = UDim2.new(0, 10, 0, 10)
				cursor.Position        = UDim2.new(s, -5, 1 - v, -5)
				cursor.BackgroundColor3= Color3.new(1, 1, 1)
				cursor.BorderSizePixel = 2
				cursor.BorderColor3    = Color3.new(0, 0, 0)
				cursor.ZIndex          = 103
				cursor.Parent          = spectrumFrame
				local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = cursor

				local hueFrame = Instance.new("Frame")
				hueFrame.Size            = UDim2.new(0, 200, 0, 14)
				hueFrame.Position        = UDim2.new(0, 12, 0, 190)
				hueFrame.BackgroundColor3= Color3.new(1, 1, 1)
				hueFrame.BorderSizePixel = 0
				hueFrame.ZIndex          = 101
				hueFrame.Parent          = overlay
				local hfc = Instance.new("UICorner"); hfc.CornerRadius = UDim.new(1, 0); hfc.Parent = hueFrame

				local hueGradient = Instance.new("UIGradient")
				hueGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,     Color3.fromRGB(255, 0,   0  )),
					ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0  )),
					ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,   255, 0  )),
					ColorSequenceKeypoint.new(0.5,   Color3.fromRGB(0,   255, 255)),
					ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,   0,   255)),
					ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0,   255)),
					ColorSequenceKeypoint.new(1,     Color3.fromRGB(255, 0,   0  ))
				})
				hueGradient.Parent = hueFrame

				local hueCursor = Instance.new("Frame")
				hueCursor.Size            = UDim2.new(0, 6, 1, 4)
				hueCursor.Position        = UDim2.new(h, -3, 0, -2)
				hueCursor.BackgroundColor3= Color3.new(1, 1, 1)
				hueCursor.BorderSizePixel = 2
				hueCursor.BorderColor3    = Color3.new(0, 0, 0)
				hueCursor.ZIndex          = 102
				hueCursor.Parent          = hueFrame

				local previewSection = Instance.new("Frame")
				previewSection.Size            = UDim2.new(0, 50, 0, 140)
				previewSection.Position        = UDim2.new(0, 220, 0, 42)
				previewSection.BackgroundTransparency = 1
				previewSection.ZIndex          = 101
				previewSection.Parent          = overlay

				local bigPreview = Instance.new("Frame")
				bigPreview.Size            = UDim2.new(1, 0, 0, 46)
				bigPreview.BackgroundColor3= currentColor
				bigPreview.BorderSizePixel = 0
				bigPreview.ZIndex          = 101
				bigPreview.Parent          = previewSection
				local bpc = Instance.new("UICorner"); bpc.CornerRadius = UDim.new(0, 4); bpc.Parent = bigPreview
				local bps = Instance.new("UIStroke"); bps.Color = SmileUILib.Theme.BorderAccent; bps.Thickness = 1; bps.Parent = bigPreview

				local rLabel = Instance.new("TextLabel")
				rLabel.Size           = UDim2.new(1, 0, 0, 16)
				rLabel.Position       = UDim2.new(0, 0, 0, 54)
				rLabel.BackgroundTransparency = 1
				rLabel.Text           = "R: 0"
				rLabel.TextColor3     = SmileUILib.Theme.Text
				rLabel.Font           = SmileUILib.Theme.Font
				rLabel.TextSize       = 11
				rLabel.TextXAlignment = Enum.TextXAlignment.Left
				rLabel.ZIndex         = 101
				rLabel.Parent         = previewSection

				local gLabel = Instance.new("TextLabel")
				gLabel.Size           = UDim2.new(1, 0, 0, 16)
				gLabel.Position       = UDim2.new(0, 0, 0, 70)
				gLabel.BackgroundTransparency = 1
				gLabel.Text           = "G: 255"
				gLabel.TextColor3     = SmileUILib.Theme.Text
				gLabel.Font           = SmileUILib.Theme.Font
				gLabel.TextSize       = 11
				gLabel.TextXAlignment = Enum.TextXAlignment.Left
				gLabel.ZIndex         = 101
				gLabel.Parent         = previewSection

				local bLabel = Instance.new("TextLabel")
				bLabel.Size           = UDim2.new(1, 0, 0, 16)
				bLabel.Position       = UDim2.new(0, 0, 0, 86)
				bLabel.BackgroundTransparency = 1
				bLabel.Text           = "B: 0"
				bLabel.TextColor3     = SmileUILib.Theme.Text
				bLabel.Font           = SmileUILib.Theme.Font
				bLabel.TextSize       = 11
				bLabel.TextXAlignment = Enum.TextXAlignment.Left
				bLabel.ZIndex         = 101
				bLabel.Parent         = previewSection

				local hexLabel = Instance.new("TextLabel")
				hexLabel.Size           = UDim2.new(1, 0, 0, 18)
				hexLabel.Position       = UDim2.new(0, 0, 0, 106)
				hexLabel.BackgroundTransparency = 1
				hexLabel.Text           = "#7850DC"
				hexLabel.TextColor3     = SmileUILib.Theme.TextDim
				hexLabel.Font           = SmileUILib.Theme.Font
				hexLabel.TextSize       = 10
				hexLabel.TextXAlignment = Enum.TextXAlignment.Center
				hexLabel.ZIndex         = 101
				hexLabel.Parent         = previewSection

				local confirmBtn = Instance.new("TextButton")
				confirmBtn.Size            = UDim2.new(0, 120, 0, 28)
				confirmBtn.Position        = UDim2.new(0.5, -60, 0, 278)
				confirmBtn.BackgroundColor3= SmileUILib.Theme.Accent
				confirmBtn.Text            = "Apply"
				confirmBtn.TextColor3      = Color3.new(1, 1, 1)
				confirmBtn.Font            = SmileUILib.Theme.Font
				confirmBtn.TextSize        = 12
				confirmBtn.BorderSizePixel = 0
				confirmBtn.ZIndex          = 101
				confirmBtn.Parent          = overlay
				local cfc = Instance.new("UICorner"); cfc.CornerRadius = UDim.new(0, 4); cfc.Parent = confirmBtn

				local function updateColor()
					currentColor = HSVToColor3(h, s, v)
					bigPreview.BackgroundColor3 = currentColor
					colorBox.BackgroundColor3   = currentColor
					local r = math.floor(currentColor.R * 255)
					local g = math.floor(currentColor.G * 255)
					local b = math.floor(currentColor.B * 255)
					rLabel.Text   = "R: " .. r
					gLabel.Text   = "G: " .. g
					bLabel.Text   = "B: " .. b
					hexLabel.Text = string.format("#%02X%02X%02X", r, g, b)
				end

				local spectrumDragging = false
				spectrumFrame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						spectrumDragging = true
						local relX = math.clamp((input.Position.X - spectrumFrame.AbsolutePosition.X) / spectrumFrame.AbsoluteSize.X, 0, 1)
						local relY = math.clamp((input.Position.Y - spectrumFrame.AbsolutePosition.Y) / spectrumFrame.AbsoluteSize.Y, 0, 1)
						s = relX; v = 1 - relY
						cursor.Position = UDim2.new(s, -5, 1 - v, -5)
						updateColor()
					end
				end)
				spectrumFrame.InputChanged:Connect(function(input)
					if spectrumDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local relX = math.clamp((input.Position.X - spectrumFrame.AbsolutePosition.X) / spectrumFrame.AbsoluteSize.X, 0, 1)
						local relY = math.clamp((input.Position.Y - spectrumFrame.AbsolutePosition.Y) / spectrumFrame.AbsoluteSize.Y, 0, 1)
						s = relX; v = 1 - relY
						cursor.Position = UDim2.new(s, -5, 1 - v, -5)
						updateColor()
					end
				end)

				local hueDragging = false
				hueFrame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						hueDragging = true
						local relX = math.clamp((input.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
						h = relX
						hueCursor.Position = UDim2.new(h, -3, 0, -2)
						satGradient.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
							ColorSequenceKeypoint.new(1, HSVToColor3(h, 1, 1))
						})
						updateColor()
					end
				end)
				hueFrame.InputChanged:Connect(function(input)
					if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local relX = math.clamp((input.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
						h = relX
						hueCursor.Position = UDim2.new(h, -3, 0, -2)
						satGradient.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
							ColorSequenceKeypoint.new(1, HSVToColor3(h, 1, 1))
						})
						updateColor()
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						spectrumDragging = false
						hueDragging      = false
					end
				end)

				confirmBtn.MouseButton1Click:Connect(function()
					if callback then callback(currentColor) end
					closeModal()
					SmileUILib:Notify({title = "Color Applied", message = "New color has been set!", duration = 2})
				end)
				confirmBtn.MouseEnter:Connect(function()
					TweenService:Create(confirmBtn, TweenInfo.new(0.15), {BackgroundColor3 = SmileUILib.Theme.AccentHover}):Play()
				end)
				confirmBtn.MouseLeave:Connect(function()
					TweenService:Create(confirmBtn, TweenInfo.new(0.15), {BackgroundColor3 = SmileUILib.Theme.Accent}):Play()
				end)

				overlay.Size = UDim2.new(0, 280, 0, 0)
				overlay.BackgroundTransparency = 1
				TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 280, 0, 320),
					BackgroundTransparency = 0
				}):Play()
			end

			colorBox.MouseButton1Click:Connect(openModal)

			local api          = {}
			local currentColor = default

			function api:GetColor() return currentColor end
			function api:SetColor(color)
				currentColor = color
				colorBox.BackgroundColor3 = color
				if callback then callback(color) end
			end

			return api
		end

		return tabAPI
	end

	main.Size = UDim2.new(0, 0, 0, 0)
	main.BackgroundTransparency = 1

	TweenService:Create(main, TweenInfo.new(theme.WindowOpenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, width, 0, height),
		BackgroundTransparency = 0
	}):Play()

	return window
end

return SmileUILib
