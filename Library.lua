local SmileUILib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

SmileUILib.Theme = {
	Background     = Color3.fromRGB(15,  15,  20 ),
	Surface        = Color3.fromRGB(20,  20,  27 ),
	SurfaceLight   = Color3.fromRGB(27,  27,  36 ),
	SurfaceLighter = Color3.fromRGB(33,  33,  44 ),
	Header         = Color3.fromRGB(18,  18,  25 ),
	Accent         = Color3.fromRGB(120, 80,  220),
	AccentDark     = Color3.fromRGB(90,  55,  170),
	AccentDarker   = Color3.fromRGB(55,  35,  110),
	AccentVeryDark = Color3.fromRGB(28,  18,  55 ),
	AccentHover    = Color3.fromRGB(140, 100, 240),
	Text           = Color3.fromRGB(240, 240, 255),
	TextDim        = Color3.fromRGB(140, 140, 165),
	StrokeColor    = Color3.fromRGB(45,  45,  60 ),
	BorderAccent   = Color3.fromRGB(80,  55,  160),
	CornerRadius              = UDim.new(0, 4),
	StrokeThickness           = 1,
	StrokeTransparency        = 0,
	Font                      = Enum.Font.GothamSemibold,
	NotificationCornerRadius  = UDim.new(0, 6),
	NotificationHeaderHeight  = 30,
	NotificationStrokeThickness = 1,
	WindowHeaderHeight        = 36,
	WindowMinButtonSize       = UDim2.new(0, 26, 0, 20),
	WindowIconSize            = UDim2.new(0, 36, 0, 36),
	TabButtonHeight           = 28,
	TabButtonCornerRadius     = UDim.new(0, 4),
	ElementCornerRadius       = UDim.new(0, 4),
	ButtonHeight              = 28,
	ToggleHeight              = 28,
	SliderHeight              = 50,
	DropdownHeight            = 28,
	KeybindHeight             = 28,
	TextboxHeight             = 28,
	SpacerDefaultHeight       = 6,
	AnimationSpeed            = 0.15,
	NotificationInSpeed       = 0.5,
	NotificationOutSpeed      = 0.4,
	WindowOpenSpeed           = 0.5,
}

SmileUILib.Windows            = {}
SmileUILib.ThemeableElements  = {}
SmileUILib.ButtonRegistry     = {}

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

local function RegisterButton(windowId, button)
	if not SmileUILib.ButtonRegistry[windowId] then
		SmileUILib.ButtonRegistry[windowId] = {}
	end
	table.insert(SmileUILib.ButtonRegistry[windowId], button)
end

local function lerpColor(a, b, t)
	return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

SmileUILib._gradients = {}

local function applyDerivedTheme(newTheme)
	local T  = SmileUILib.Theme
	for k, v in pairs(newTheme) do T[k] = v end
	local A  = T.Accent
	local BG = T.Background
	local W  = Color3.new(1,1,1)
	if not newTheme.AccentHover    then T.AccentHover    = lerpColor(A, W,  0.18) end
	if not newTheme.AccentDark     then T.AccentDark     = lerpColor(A, BG, 0.25) end
	if not newTheme.AccentDarker   then T.AccentDarker   = lerpColor(A, BG, 0.55) end
	if not newTheme.AccentVeryDark then T.AccentVeryDark = lerpColor(A, BG, 0.82) end
	if not newTheme.BorderAccent   then T.BorderAccent   = lerpColor(A, BG, 0.38) end
	if not newTheme.Surface        then T.Surface        = lerpColor(BG, W, 0.04) end
	if not newTheme.SurfaceLight   then T.SurfaceLight   = lerpColor(BG, W, 0.09) end
	if not newTheme.SurfaceLighter then T.SurfaceLighter = lerpColor(BG, W, 0.14) end
	if not newTheme.Header         then T.Header         = lerpColor(BG, W, 0.06) end
	if not newTheme.StrokeColor    then T.StrokeColor    = lerpColor(BG, W, 0.18) end
end

function SmileUILib:SetTheme(newTheme)
	applyDerivedTheme(newTheme)
	for windowId, elements in pairs(self.ThemeableElements) do
		for _, data in ipairs(elements) do
			if data.Element and data.Element.Parent then
				local color = self.Theme[data.ThemeKey]
				if color then
					pcall(function() data.Element[data.Property] = color end)
				end
			end
		end
	end
	for _, g in ipairs(self._gradients) do
		if g.instance and g.instance.Parent then
			if g.gtype == "progressFill" then
				g.instance.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, self.Theme.AccentHover),
					ColorSequenceKeypoint.new(1, self.Theme.Accent)
				})
			end
		end
	end
end

local function HSVToColor3(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	local lut = {
		{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}
	}
	local c = lut[i+1]
	return Color3.new(c[1], c[2], c[3])
end

local function Color3ToHSV(color)
	local r, g, b   = color.R, color.G, color.B
	local max, min  = math.max(r,g,b), math.min(r,g,b)
	local delta     = max - min
	local h, s, v   = 0, 0, max
	if delta ~= 0 then
		s = delta / max
		if     max == r then h = (g - b) / delta + (g < b and 6 or 0)
		elseif max == g then h = (b - r) / delta + 2
		else               h = (r - g) / delta + 4 end
		h = h / 6
	end
	return h, s, v
end

local function mkCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or SmileUILib.Theme.CornerRadius
	c.Parent = parent
	return c
end

local function mkStroke(parent, colorKey, thick)
	local s = Instance.new("UIStroke")
	s.Color     = SmileUILib.Theme[colorKey] or SmileUILib.Theme.StrokeColor
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent    = parent
	return s
end

local function mkPad(parent, t, bo, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, t  or 0)
	p.PaddingBottom = UDim.new(0, bo or 0)
	p.PaddingLeft   = UDim.new(0, l  or 0)
	p.PaddingRight  = UDim.new(0, r  or 0)
	p.Parent = parent
end

local function tw(inst, props, spd)
	TweenService:Create(inst,
		TweenInfo.new(spd or SmileUILib.Theme.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
end

local notifContainer
local function initNotif()
	if notifContainer then return end
	local sc = Instance.new("ScreenGui")
	sc.Name = "SmileNotifications"
	sc.ResetOnSpawn = false
	sc.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sc.DisplayOrder = 999999
	sc.Parent = CoreGui
	notifContainer = Instance.new("Frame")
	notifContainer.Size = UDim2.new(0, 320, 1, -20)
	notifContainer.Position = UDim2.new(1, -330, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.Parent = sc
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Parent = notifContainer
end

function SmileUILib:Notify(options)
	local title    = options.title    or "Info"
	local message  = options.message  or ""
	local duration = options.duration or 3.7
	local width    = options.width    or 320
	local T        = SmileUILib.Theme
	initNotif()

	local card = Instance.new("Frame")
	card.BackgroundColor3  = T.Surface
	card.BorderSizePixel   = 0
	card.ClipsDescendants  = true
	card.ZIndex            = 999999
	card.Parent            = notifContainer
	mkCorner(card, UDim.new(0, 6))
	local cs = mkStroke(card, "StrokeColor")

	local bar = Instance.new("Frame")
	bar.Size             = UDim2.new(0, 3, 1, 0)
	bar.BackgroundColor3 = T.Accent
	bar.BorderSizePixel  = 0
	bar.ZIndex           = 1000000
	bar.Parent           = card
	mkCorner(bar, UDim.new(0, 3))

	local hdr = Instance.new("Frame")
	hdr.Size             = UDim2.new(1, -3, 0, T.NotificationHeaderHeight)
	hdr.Position         = UDim2.new(0, 3, 0, 0)
	hdr.BackgroundColor3 = T.Header
	hdr.BorderSizePixel  = 0
	hdr.Parent           = card
	mkCorner(hdr, UDim.new(0, 4))

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                  = UDim2.new(1, -14, 1, 0)
	titleLbl.Position              = UDim2.new(0, 10, 0, 0)
	titleLbl.BackgroundTransparency= 1
	titleLbl.Text                  = title
	titleLbl.TextColor3            = T.Text
	titleLbl.Font                  = T.Font
	titleLbl.TextSize              = 13
	titleLbl.TextXAlignment        = Enum.TextXAlignment.Left
	titleLbl.TextTruncate          = Enum.TextTruncate.AtEnd
	titleLbl.Parent                = hdr

	local body = Instance.new("TextLabel")
	body.Position               = UDim2.new(0, 13, 0, T.NotificationHeaderHeight + 5)
	body.Size                   = UDim2.new(1, -22, 0, 0)
	body.AutomaticSize          = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.Text                   = message
	body.TextColor3             = T.TextDim
	body.Font                   = T.Font
	body.TextSize               = 12
	body.TextXAlignment         = Enum.TextXAlignment.Left
	body.TextYAlignment         = Enum.TextYAlignment.Top
	body.TextWrapped            = true
	body.Parent                 = card

	task.wait()
	local totalH = T.NotificationHeaderHeight + body.TextBounds.Y + 14
	card.Size = UDim2.new(0, 0, 0, totalH)
	TweenService:Create(card, TweenInfo.new(T.NotificationInSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, width, 0, totalH)
	}):Play()

	task.delay(duration, function()
		local out = TweenService:Create(card, TweenInfo.new(T.NotificationOutSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, totalH)
		})
		out:Play()
		out.Completed:Connect(function() card:Destroy() end)
	end)
end

function SmileUILib:CreateWindow(options)
	local title         = options.title         or "SmileUI"
	local width         = options.width         or 580
	local height        = options.height        or 420
	local iconText      = options.iconText      or "☰"
	local tabsWidth     = options.tabsWidth     or 130
	local contentOffset = options.contentOffset or 150

	local T        = SmileUILib.Theme
	local windowId = "Win_" .. math.floor(tick() * 1000)

	local screen = Instance.new("ScreenGui")
	screen.Name          = "SmileUI_" .. windowId
	screen.ResetOnSpawn  = false
	screen.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
	screen.Parent        = CoreGui
	self.Windows[windowId] = screen

	local main = Instance.new("Frame")
	main.Name             = "Main"
	main.Size             = UDim2.new(0, width, 0, height)
	main.Position         = UDim2.new(0.5, -width/2, 0.5, -height/2)
	main.BackgroundColor3 = T.Surface
	main.Active           = true
	main.BorderSizePixel  = 0
	main.Parent           = screen
	mkCorner(main, UDim.new(0, 6))
	local mainStroke = mkStroke(main, "StrokeColor")
	RegisterElement(windowId, main,        "BackgroundColor3", "Surface")
	RegisterElement(windowId, mainStroke,  "Color",            "StrokeColor")

	local shadow = Instance.new("ImageLabel")
	shadow.AnchorPoint          = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position             = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size                 = UDim2.new(1, 30, 1, 30)
	shadow.Image                = "rbxassetid://5028857084"
	shadow.ImageColor3          = Color3.new(0, 0, 0)
	shadow.ImageTransparency    = 0.6
	shadow.ScaleType            = Enum.ScaleType.Slice
	shadow.SliceCenter          = Rect.new(24, 24, 276, 276)
	shadow.ZIndex               = 0
	shadow.Parent               = main

	local titleBar = Instance.new("Frame")
	titleBar.Name             = "TitleBar"
	titleBar.Size             = UDim2.new(1, 0, 0, T.WindowHeaderHeight)
	titleBar.BackgroundColor3 = T.Header
	titleBar.BorderSizePixel  = 0
	titleBar.ZIndex           = 2
	titleBar.Parent           = main
	mkCorner(titleBar, UDim.new(0, 6))
	RegisterElement(windowId, titleBar, "BackgroundColor3", "Header")

	local tbFix = Instance.new("Frame")
	tbFix.Size             = UDim2.new(1, 0, 0, 6)
	tbFix.Position         = UDim2.new(0, 0, 1, -6)
	tbFix.BackgroundColor3 = T.Header
	tbFix.BorderSizePixel  = 0
	tbFix.ZIndex           = 2
	tbFix.Parent           = titleBar
	RegisterElement(windowId, tbFix, "BackgroundColor3", "Header")

	local accentLine = Instance.new("Frame")
	accentLine.Size             = UDim2.new(1, 0, 0, 1)
	accentLine.Position         = UDim2.new(0, 0, 1, -1)
	accentLine.BackgroundColor3 = T.Accent
	accentLine.BorderSizePixel  = 0
	accentLine.ZIndex           = 3
	accentLine.Parent           = titleBar
	RegisterElement(windowId, accentLine, "BackgroundColor3", "Accent")

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size                  = UDim2.new(1, -70, 1, 0)
	titleLabel.Position              = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency= 1
	titleLabel.Text                  = title
	titleLabel.TextColor3            = T.Text
	titleLabel.Font                  = T.Font
	titleLabel.TextSize              = 13
	titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
	titleLabel.TextTruncate          = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex                = 3
	titleLabel.Parent                = titleBar
	RegisterElement(windowId, titleLabel, "TextColor3", "Text")

	local minBtn = Instance.new("TextButton")
	minBtn.Size             = T.WindowMinButtonSize
	minBtn.Position         = UDim2.new(1, -32, 0.5, -10)
	minBtn.BackgroundColor3 = T.AccentVeryDark
	minBtn.Text             = "−"
	minBtn.TextColor3       = T.TextDim
	minBtn.Font             = T.Font
	minBtn.TextSize         = 16
	minBtn.AutoButtonColor  = false
	minBtn.BorderSizePixel  = 0
	minBtn.ZIndex           = 4
	minBtn.Parent           = titleBar
	mkCorner(minBtn)
	RegisterElement(windowId, minBtn, "BackgroundColor3", "AccentVeryDark")
	RegisterElement(windowId, minBtn, "TextColor3",       "TextDim")

	minBtn.MouseEnter:Connect(function() tw(minBtn, {BackgroundColor3 = SmileUILib.Theme.Accent,         TextColor3 = SmileUILib.Theme.Text   }) end)
	minBtn.MouseLeave:Connect(function() tw(minBtn, {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark, TextColor3 = SmileUILib.Theme.TextDim}) end)

	local bodyBg = Instance.new("Frame")
	bodyBg.Name             = "Body"
	bodyBg.Size             = UDim2.new(1, 0, 1, -T.WindowHeaderHeight)
	bodyBg.Position         = UDim2.new(0, 0, 0, T.WindowHeaderHeight)
	bodyBg.BackgroundColor3 = T.Background
	bodyBg.BorderSizePixel  = 0
	bodyBg.ClipsDescendants = true
	bodyBg.ZIndex           = 1
	bodyBg.Parent           = main
	mkCorner(bodyBg, UDim.new(0, 6))
	RegisterElement(windowId, bodyBg, "BackgroundColor3", "Background")

	local bodyFix = Instance.new("Frame")
	bodyFix.Size             = UDim2.new(1, 0, 0, 6)
	bodyFix.BackgroundColor3 = T.Background
	bodyFix.BorderSizePixel  = 0
	bodyFix.Parent           = bodyBg
	RegisterElement(windowId, bodyFix, "BackgroundColor3", "Background")

	local icon = Instance.new("Frame")
	icon.Size             = UDim2.new(0, 42, 0, 42)
	icon.BackgroundColor3 = T.Header
	icon.Visible          = false
	icon.Active           = true
	icon.BorderSizePixel  = 0
	icon.Parent           = screen
	mkCorner(icon, UDim.new(0, 6))
	local iconStroke = mkStroke(icon, "StrokeColor")
	RegisterElement(windowId, icon,       "BackgroundColor3", "Header")
	RegisterElement(windowId, iconStroke, "Color",            "StrokeColor")

	local iconBtn = Instance.new("TextButton")
	iconBtn.Size                  = UDim2.new(1, 0, 1, 0)
	iconBtn.BackgroundTransparency= 1
	iconBtn.Text                  = iconText
	iconBtn.TextColor3            = T.Accent
	iconBtn.Font                  = Enum.Font.GothamSemibold
	iconBtn.TextSize              = 20
	iconBtn.ZIndex                = 11
	iconBtn.AutoButtonColor       = false
	iconBtn.Parent                = icon
	RegisterElement(windowId, iconBtn, "TextColor3", "Accent")

	do
		local iconDragging, iconDragStart, iconStartPos = false, nil, nil
		icon.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				iconDragging  = true
				iconDragStart = input.Position
				iconStartPos  = icon.Position
				local dc, ec
				dc = UserInputService.InputChanged:Connect(function(i)
					if iconDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
						local d = i.Position - iconDragStart
						icon.Position = UDim2.new(
							iconStartPos.X.Scale, iconStartPos.X.Offset + d.X,
							iconStartPos.Y.Scale, iconStartPos.Y.Offset + d.Y
						)
					end
				end)
				ec = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						iconDragging = false
						dc:Disconnect()
						ec:Disconnect()
					end
				end)
			end
		end)
	end

	minBtn.MouseButton1Click:Connect(function()
		icon.Position = UDim2.new(0, main.AbsolutePosition.X + main.AbsoluteSize.X - 50, 0, main.AbsolutePosition.Y + 4)
		main.Visible  = false
		icon.Visible  = true
	end)
	iconBtn.MouseButton1Click:Connect(function()
		icon.Visible = false
		main.Visible = true
	end)
	iconBtn.MouseEnter:Connect(function() tw(icon, {BackgroundColor3 = SmileUILib.Theme.AccentDarker}) end)
	iconBtn.MouseLeave:Connect(function() tw(icon, {BackgroundColor3 = SmileUILib.Theme.Header})       end)

	local sidebar = Instance.new("Frame")
	sidebar.Name             = "Sidebar"
	sidebar.Size             = UDim2.new(0, tabsWidth, 1, -16)
	sidebar.Position         = UDim2.new(0, 8, 0, 8)
	sidebar.BackgroundColor3 = T.SurfaceLight
	sidebar.BorderSizePixel  = 0
	sidebar.ZIndex           = 2
	sidebar.Parent           = bodyBg
	mkCorner(sidebar, UDim.new(0, 4))
	local sideStroke = mkStroke(sidebar, "StrokeColor")
	RegisterElement(windowId, sidebar,     "BackgroundColor3", "SurfaceLight")
	RegisterElement(windowId, sideStroke,  "Color",            "StrokeColor")

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding   = UDim.new(0, 3)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent    = sidebar
	mkPad(sidebar, 6, 6, 6, 6)

	local contentArea = Instance.new("Frame")
	contentArea.Name                  = "Content"
	contentArea.Size                  = UDim2.new(1, -contentOffset, 1, -16)
	contentArea.Position              = UDim2.new(0, contentOffset - 6, 0, 8)
	contentArea.BackgroundTransparency= 1
	contentArea.ZIndex                = 1
	contentArea.Parent                = bodyBg

	do
		local dragging, dragStart, startPos = false, nil, nil
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging  = true
				dragStart = input.Position
				startPos  = main.Position
				local dc, ec
				dc = UserInputService.InputChanged:Connect(function(i)
					if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
						local d = i.Position - dragStart
						main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
					end
				end)
				ec = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						dc:Disconnect()
						ec:Disconnect()
					end
				end)
			end
		end)
	end

	main.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(main, TweenInfo.new(T.WindowOpenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, width, 0, height)
	}):Play()

	local window      = {}
	window.Id         = windowId
	window._screen    = screen
	local activePage  = nil

	function window:SetTheme(newTheme)
		SmileUILib:SetTheme(newTheme)
	end

	function window:AddTab(tabOptions)
		local tabName = tabOptions.name or "Tab"
		local T       = SmileUILib.Theme

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size             = UDim2.new(1, 0, 0, T.TabButtonHeight)
		tabBtn.BackgroundColor3 = T.Background
		tabBtn.Text             = tabName
		tabBtn.TextColor3       = T.TextDim
		tabBtn.Font             = T.Font
		tabBtn.TextSize         = 12
		tabBtn.AutoButtonColor  = false
		tabBtn.BorderSizePixel  = 0
		tabBtn.TextTruncate     = Enum.TextTruncate.AtEnd
		tabBtn.ZIndex           = 3
		tabBtn.Parent           = sidebar
		mkCorner(tabBtn)
		RegisterElement(windowId, tabBtn, "BackgroundColor3", "Background")
		RegisterElement(windowId, tabBtn, "TextColor3",       "TextDim")

		local page = Instance.new("ScrollingFrame")
		page.Size               = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel    = 0
		page.ScrollBarThickness = 2
		page.ScrollBarImageColor3 = T.Accent
		page.Visible            = false
		page.CanvasSize         = UDim2.new(0, 0, 0, 0)
		page.ZIndex             = 2
		page.Parent             = contentArea
		RegisterElement(windowId, page, "ScrollBarImageColor3", "Accent")

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding   = UDim.new(0, 6)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent    = page
		mkPad(page, 0, 8, 0, 4)

		pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
		end)

		tabBtn.MouseEnter:Connect(function()
			if activePage ~= page then
				tw(tabBtn, {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark})
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if activePage ~= page then
				tw(tabBtn, {BackgroundColor3 = SmileUILib.Theme.Background, TextColor3 = SmileUILib.Theme.TextDim})
			end
		end)
		tabBtn.MouseButton1Click:Connect(function()
			if activePage then activePage.Visible = false end
			page.Visible = true
			activePage   = page
			for _, b in sidebar:GetChildren() do
				if b:IsA("TextButton") then
					local isActive = (b == tabBtn)
					tw(b, {
						BackgroundColor3 = isActive and SmileUILib.Theme.AccentDarker or SmileUILib.Theme.Background,
						TextColor3       = isActive and SmileUILib.Theme.Accent       or SmileUILib.Theme.TextDim,
					})
				end
			end
		end)

		if not activePage then
			tabBtn.BackgroundColor3 = T.AccentDarker
			tabBtn.TextColor3       = T.Accent
			page.Visible            = true
			activePage              = page
		end

		local tabAPI = {}

		local function makeFrame(h)
			local f = Instance.new("Frame")
			f.Size             = UDim2.new(1, -4, 0, h or T.ElementCornerRadius)
			f.BackgroundColor3 = SmileUILib.Theme.SurfaceLight
			f.BorderSizePixel  = 0
			f.Parent           = page
			mkCorner(f, UDim.new(0, 4))
			local s = mkStroke(f, "StrokeColor")
			RegisterElement(windowId, f, "BackgroundColor3", "SurfaceLight")
			RegisterElement(windowId, s, "Color",            "StrokeColor")
			return f
		end

		local function makeLbl(parent, text, xOff, colorKey, size, zIndex)
			local lbl = Instance.new("TextLabel")
			lbl.Size                  = UDim2.new(1, -(xOff or 8) - 10, 1, 0)
			lbl.Position              = UDim2.new(0, xOff or 8, 0, 0)
			lbl.BackgroundTransparency= 1
			lbl.Text                  = text
			lbl.TextColor3            = SmileUILib.Theme[colorKey or "Text"]
			lbl.Font                  = SmileUILib.Theme.Font
			lbl.TextSize              = size or 12
			lbl.TextXAlignment        = Enum.TextXAlignment.Left
			lbl.TextTruncate          = Enum.TextTruncate.AtEnd
			if zIndex then lbl.ZIndex = zIndex end
			lbl.Parent                = parent
			RegisterElement(windowId, lbl, "TextColor3", colorKey or "Text")
			return lbl
		end

		local function makeRightBtn(parent, h)
			local btn = Instance.new("TextButton")
			btn.Size             = UDim2.new(0, 100, 0, (h or T.ElementCornerRadius) - 8)
			btn.AnchorPoint      = Vector2.new(1, 0.5)
			btn.Position         = UDim2.new(1, -6, 0.5, 0)
			btn.BackgroundColor3 = SmileUILib.Theme.AccentVeryDark
			btn.TextColor3       = SmileUILib.Theme.Accent
			btn.Font             = SmileUILib.Theme.Font
			btn.TextSize         = 11
			btn.TextTruncate     = Enum.TextTruncate.AtEnd
			btn.BorderSizePixel  = 0
			btn.AutoButtonColor  = false
			btn.Parent           = parent
			mkCorner(btn)
			local s = mkStroke(btn, "BorderAccent")
			RegisterElement(windowId, btn, "BackgroundColor3", "AccentVeryDark")
			RegisterElement(windowId, btn, "TextColor3",       "Accent")
			RegisterElement(windowId, s,   "Color",            "BorderAccent")
			return btn
		end

		function tabAPI:AddSection(opts)
			local lbl = Instance.new("TextLabel")
			lbl.Size                  = UDim2.new(1, -4, 0, 18)
			lbl.BackgroundTransparency= 1
			lbl.Text                  = (opts.title or "Section"):upper()
			lbl.TextColor3            = SmileUILib.Theme.Accent
			lbl.Font                  = SmileUILib.Theme.Font
			lbl.TextSize              = opts.textSize or 10
			lbl.TextXAlignment        = Enum.TextXAlignment.Left
			lbl.Parent                = page
			mkPad(lbl, 0, 0, 4, 0)
			RegisterElement(windowId, lbl, "TextColor3", "Accent")
			return lbl
		end

		function tabAPI:AddLabel(opts)
			local f = Instance.new("Frame")
			f.Size                  = UDim2.new(1, -4, 0, 0)
			f.AutomaticSize         = Enum.AutomaticSize.Y
			f.BackgroundTransparency= 1
			f.Parent                = page
			local lbl = Instance.new("TextLabel")
			lbl.Size                  = UDim2.new(1, -10, 0, 0)
			lbl.Position              = UDim2.new(0, 4, 0, 0)
			lbl.AutomaticSize         = Enum.AutomaticSize.Y
			lbl.BackgroundTransparency= 1
			lbl.Text                  = opts.text or "Label"
			lbl.TextColor3            = SmileUILib.Theme.TextDim
			lbl.Font                  = SmileUILib.Theme.Font
			lbl.TextSize              = opts.textSize or 12
			lbl.TextXAlignment        = Enum.TextXAlignment.Left
			lbl.TextWrapped           = true
			lbl.Parent                = f
			RegisterElement(windowId, lbl, "TextColor3", "TextDim")
			return lbl
		end

		function tabAPI:AddSpacer(opts)
			local f = Instance.new("Frame")
			f.Size                  = UDim2.new(1, -4, 0, (opts and opts.height) or T.SpacerDefaultHeight)
			f.BackgroundTransparency= 1
			f.Parent                = page
			return f
		end

		function tabAPI:AddButton(opts)
			local h   = opts.height or T.ButtonHeight
			local btn = Instance.new("TextButton")
			btn.Size             = UDim2.new(1, -4, 0, h)
			btn.BackgroundColor3 = SmileUILib.Theme.SurfaceLight
			btn.Text             = ""
			btn.AutoButtonColor  = false
			btn.BorderSizePixel  = 0
			btn.Parent           = page
			mkCorner(btn, UDim.new(0, 4))
			local s = mkStroke(btn, "StrokeColor")
			RegisterElement(windowId, btn, "BackgroundColor3", "SurfaceLight")
			RegisterElement(windowId, s,   "Color",            "StrokeColor")

			local tick = Instance.new("Frame")
			tick.Size             = UDim2.new(0, 2, 0.55, 0)
			tick.AnchorPoint      = Vector2.new(0, 0.5)
			tick.Position         = UDim2.new(0, 3, 0.5, 0)
			tick.BackgroundColor3 = SmileUILib.Theme.Accent
			tick.BorderSizePixel  = 0
			tick.Parent           = btn
			mkCorner(tick)
			RegisterElement(windowId, tick, "BackgroundColor3", "Accent")

			local lbl = makeLbl(btn, opts.text or "Button", 10, "Text", 12)
			lbl.Font  = SmileUILib.Theme.Font

			btn.MouseEnter:Connect(function()    tw(btn, {BackgroundColor3 = SmileUILib.Theme.SurfaceLighter}) end)
			btn.MouseLeave:Connect(function()    tw(btn, {BackgroundColor3 = SmileUILib.Theme.SurfaceLight})   end)
			btn.MouseButton1Click:Connect(function()
				if opts.callback then opts.callback() end
			end)
			return btn
		end

		function tabAPI:AddToggle(opts)
			local h     = opts.height  or T.ToggleHeight
			local state = opts.default or false
			local frame = makeFrame(h)
			makeLbl(frame, opts.name or "Toggle", 10, "Text", 12)

			local pillW, pillH = 34, 18
			local pill = Instance.new("Frame")
			pill.Size             = UDim2.new(0, pillW, 0, pillH)
			pill.AnchorPoint      = Vector2.new(1, 0.5)
			pill.Position         = UDim2.new(1, -8, 0.5, 0)
			pill.BackgroundColor3 = state and SmileUILib.Theme.Accent or SmileUILib.Theme.AccentVeryDark
			pill.BorderSizePixel  = 0
			pill.Parent           = frame
			mkCorner(pill, UDim.new(1, 0))
			local ps = mkStroke(pill, "BorderAccent")
			RegisterElement(windowId, pill, "BackgroundColor3", state and "Accent" or "AccentVeryDark")
			RegisterElement(windowId, ps,   "Color",            "BorderAccent")

			local knob = Instance.new("Frame")
			knob.Size             = UDim2.new(0, pillH - 6, 0, pillH - 6)
			knob.AnchorPoint      = Vector2.new(0, 0.5)
			knob.Position         = UDim2.new(0, state and (pillW - pillH + 3) or 3, 0.5, 0)
			knob.BackgroundColor3 = SmileUILib.Theme.Text
			knob.BorderSizePixel  = 0
			knob.Parent           = pill
			mkCorner(knob, UDim.new(1, 0))
			RegisterElement(windowId, knob, "BackgroundColor3", "Text")

			local api = {}
			function api:GetState() return state end
			function api:SetState(bool)
				state = bool
				tw(pill, {BackgroundColor3 = SmileUILib.Theme[state and "Accent" or "AccentVeryDark"]})
				tw(knob, {Position = UDim2.new(0, state and (pillW - pillH + 3) or 3, 0.5, 0)})
				if opts.callback then opts.callback(state) end
			end
			frame.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then api:SetState(not state) end
			end)
			frame.MouseEnter:Connect(function() tw(frame, {BackgroundColor3 = SmileUILib.Theme.SurfaceLighter}) end)
			frame.MouseLeave:Connect(function() tw(frame, {BackgroundColor3 = SmileUILib.Theme.SurfaceLight})   end)
			return api
		end

		function tabAPI:AddSlider(opts)
			local h       = opts.height  or T.SliderHeight
			local min     = opts.min     or 0
			local max     = opts.max     or 100
			local default = math.clamp(opts.default or min, min, max)
			local step    = opts.step    or 1
			local frame   = makeFrame(h)

			local topRow = Instance.new("Frame")
			topRow.Size                  = UDim2.new(1, -16, 0, 20)
			topRow.Position              = UDim2.new(0, 8, 0, 6)
			topRow.BackgroundTransparency= 1
			topRow.Parent                = frame

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size                  = UDim2.new(0.65, 0, 1, 0)
			nameLbl.BackgroundTransparency= 1
			nameLbl.Text                  = opts.name or "Slider"
			nameLbl.TextColor3            = SmileUILib.Theme.Text
			nameLbl.Font                  = SmileUILib.Theme.Font
			nameLbl.TextSize              = 12
			nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
			nameLbl.TextTruncate          = Enum.TextTruncate.AtEnd
			nameLbl.Parent                = topRow
			RegisterElement(windowId, nameLbl, "TextColor3", "Text")

			local valLbl = Instance.new("TextLabel")
			valLbl.Size                  = UDim2.new(0.35, 0, 1, 0)
			valLbl.Position              = UDim2.new(0.65, 0, 0, 0)
			valLbl.BackgroundTransparency= 1
			valLbl.Text                  = tostring(default)
			valLbl.TextColor3            = SmileUILib.Theme.Accent
			valLbl.Font                  = SmileUILib.Theme.Font
			valLbl.TextSize              = 12
			valLbl.TextXAlignment        = Enum.TextXAlignment.Right
			valLbl.Parent                = topRow
			RegisterElement(windowId, valLbl, "TextColor3", "Accent")

			local track = Instance.new("Frame")
			track.Size             = UDim2.new(1, -16, 0, 6)
			track.Position         = UDim2.new(0, 8, 0, h - 14)
			track.BackgroundColor3 = SmileUILib.Theme.AccentVeryDark
			track.BorderSizePixel  = 0
			track.Parent           = frame
			mkCorner(track, UDim.new(1, 0))
			RegisterElement(windowId, track, "BackgroundColor3", "AccentVeryDark")

			local fill = Instance.new("Frame")
			fill.Size             = UDim2.new((default - min) / (max - min), 0, 1, 0)
			fill.BackgroundColor3 = SmileUILib.Theme.Accent
			fill.BorderSizePixel  = 0
			fill.Parent           = track
			mkCorner(fill, UDim.new(1, 0))
			RegisterElement(windowId, fill, "BackgroundColor3", "Accent")

			local knobF = Instance.new("Frame")
			knobF.Size             = UDim2.new(0, 12, 0, 12)
			knobF.AnchorPoint      = Vector2.new(0.5, 0.5)
			knobF.Position         = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
			knobF.BackgroundColor3 = SmileUILib.Theme.Text
			knobF.BorderSizePixel  = 0
			knobF.ZIndex           = 2
			knobF.Parent           = track
			mkCorner(knobF, UDim.new(1, 0))
			local ks = Instance.new("UIStroke"); ks.Color = SmileUILib.Theme.Accent; ks.Thickness = 2; ks.Parent = knobF
			RegisterElement(windowId, knobF, "BackgroundColor3", "Text")
			RegisterElement(windowId, ks,    "Color",            "Accent")

			local value = default
			local api   = {}
			function api:GetValue() return value end
			function api:SetValue(v)
				v     = math.clamp(math.floor((v / step) + 0.5) * step, min, max)
				value = v
				local t = (v - min) / (max - min)
				fill.Size      = UDim2.new(t, 0, 1, 0)
				knobF.Position = UDim2.new(t, 0, 0.5, 0)
				valLbl.Text    = tostring(v)
				if opts.callback then opts.callback(v) end
			end

			local dragging = false
			local function setFromX(x)
				local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				api:SetValue(min + (max - min) * rel)
			end
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					setFromX(input.Position.X)
					local c1, c2
					c1 = UserInputService.InputChanged:Connect(function(i)
						if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
					end)
					c2 = UserInputService.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false; c1:Disconnect(); c2:Disconnect()
						end
					end)
				end
			end)
			frame.Destroying:Connect(function()  end)
			return api
		end

		function tabAPI:AddDropdown(opts)
			local h       = opts.height  or T.DropdownHeight
			local options = opts.options or {"Option 1", "Option 2"}
			local default = opts.default or options[1]
			local frame   = makeFrame(h)
			makeLbl(frame, opts.name or "Dropdown", 10, "Text", 12)

			local selBtn = makeRightBtn(frame, h)
			selBtn.Size  = UDim2.new(0, 110, 0, h - 8)
			selBtn.Text  = default

			local arrow = Instance.new("TextLabel")
			arrow.Size                  = UDim2.new(0, 14, 1, 0)
			arrow.AnchorPoint           = Vector2.new(1, 0.5)
			arrow.Position              = UDim2.new(1, -4, 0.5, 0)
			arrow.BackgroundTransparency= 1
			arrow.Text                  = "▾"
			arrow.TextColor3            = SmileUILib.Theme.Accent
			arrow.Font                  = SmileUILib.Theme.Font
			arrow.TextSize              = 10
			arrow.Parent                = selBtn
			RegisterElement(windowId, arrow, "TextColor3", "Accent")

			local current   = 1
			for i, v in ipairs(options) do if v == default then current = i; break end end
			local selection = options[current]

			local api = {}
			function api:GetSelection() return selection end
			function api:SetSelection(choice)
				for i, v in ipairs(options) do
					if v == choice then
						current = i; selection = choice; selBtn.Text = choice
						if opts.callback then opts.callback(selection) end
						return
					end
				end
			end
			selBtn.MouseButton1Click:Connect(function()
				current   = (current % #options) + 1
				selection = options[current]
				selBtn.Text = selection
				if opts.callback then opts.callback(selection) end
			end)
			selBtn.MouseEnter:Connect(function() tw(selBtn, {BackgroundColor3 = SmileUILib.Theme.AccentDarker}) end)
			selBtn.MouseLeave:Connect(function() tw(selBtn, {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}) end)
			frame.MouseEnter:Connect(function()  tw(frame,  {BackgroundColor3 = SmileUILib.Theme.SurfaceLighter}) end)
			frame.MouseLeave:Connect(function()  tw(frame,  {BackgroundColor3 = SmileUILib.Theme.SurfaceLight})   end)
			return api
		end

		function tabAPI:AddKeybind(opts)
			local h          = opts.height     or T.KeybindHeight
			local defaultKey = opts.defaultKey or Enum.KeyCode.Unknown
			local allowMouse = opts.allowMouse  or false
			local frame      = makeFrame(h)
			makeLbl(frame, opts.name or "Keybind", 10, "Text", 12)

			local kBtn = makeRightBtn(frame, h)
			kBtn.Size  = UDim2.new(0, 80, 0, h - 8)
			kBtn.Text  = defaultKey.Name

			local listening  = false
			local currentKey = defaultKey
			local api        = {}
			function api:GetKey() return currentKey end
			function api:SetKey(key)
				currentKey = key
				kBtn.Text  = (type(key) == "userdata" and key.Name) or tostring(key)
				if opts.callback then opts.callback(currentKey) end
			end
			kBtn.MouseButton1Click:Connect(function()
				listening = true; kBtn.Text = "..."; kBtn.TextColor3 = SmileUILib.Theme.TextDim
			end)
			local ic = UserInputService.InputBegan:Connect(function(input, processed)
				if processed or not listening then return end
				listening      = false
				kBtn.TextColor3= SmileUILib.Theme.Accent
				if input.UserInputType == Enum.UserInputType.Keyboard then
					api:SetKey(input.KeyCode)
				elseif allowMouse then
					api:SetKey(input.UserInputType)
				else
					kBtn.Text = currentKey.Name
				end
			end)
			kBtn.MouseEnter:Connect(function()  if not listening then tw(kBtn, {BackgroundColor3 = SmileUILib.Theme.AccentDarker})   end end)
			kBtn.MouseLeave:Connect(function()  if not listening then tw(kBtn, {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}) end end)
			frame.MouseEnter:Connect(function()  tw(frame, {BackgroundColor3 = SmileUILib.Theme.SurfaceLighter}) end)
			frame.MouseLeave:Connect(function()  tw(frame, {BackgroundColor3 = SmileUILib.Theme.SurfaceLight})   end)
			frame.Destroying:Connect(function()  ic:Disconnect() end)
			return api
		end

		function tabAPI:AddTextbox(opts)
			local h     = opts.height  or T.TextboxHeight
			local frame = makeFrame(h)
			makeLbl(frame, opts.name or "Textbox", 10, "Text", 12)

			local tb = Instance.new("TextBox")
			tb.Size               = UDim2.new(0, 110, 0, h - 8)
			tb.AnchorPoint        = Vector2.new(1, 0.5)
			tb.Position           = UDim2.new(1, -6, 0.5, 0)
			tb.BackgroundColor3   = SmileUILib.Theme.AccentVeryDark
			tb.Text               = opts.default or ""
			tb.TextColor3         = SmileUILib.Theme.Text
			tb.PlaceholderColor3  = SmileUILib.Theme.TextDim
			tb.Font               = SmileUILib.Theme.Font
			tb.TextSize           = 12
			tb.BorderSizePixel    = 0
			tb.ClearTextOnFocus   = false
			tb.Parent             = frame
			mkCorner(tb)
			local tbs = mkStroke(tb, "BorderAccent")
			mkPad(tb, 0, 0, 5, 5)
			RegisterElement(windowId, tb,  "BackgroundColor3",  "AccentVeryDark")
			RegisterElement(windowId, tb,  "TextColor3",        "Text")
			RegisterElement(windowId, tb,  "PlaceholderColor3", "TextDim")
			RegisterElement(windowId, tbs, "Color",             "BorderAccent")

			local text = opts.default or ""
			local api  = {}
			function api:GetText() return text end
			function api:SetText(v)
				text = v; tb.Text = v
				if opts.callback then opts.callback(text) end
			end
			tb.FocusLost:Connect(function(enter)
				if enter then api:SetText(tb.Text) else tb.Text = text end
			end)
			tb.Focused:Connect(function()   tw(tb, {BackgroundColor3 = SmileUILib.Theme.AccentDarker})   end)
			tb.FocusLost:Connect(function() tw(tb, {BackgroundColor3 = SmileUILib.Theme.AccentVeryDark}) end)
			frame.MouseEnter:Connect(function() tw(frame, {BackgroundColor3 = SmileUILib.Theme.SurfaceLighter}) end)
			frame.MouseLeave:Connect(function() tw(frame, {BackgroundColor3 = SmileUILib.Theme.SurfaceLight})   end)
			return api
		end

		function tabAPI:AddProgressBar(opts)
			local h      = opts.height or 46
			local max    = opts.max    or 100
			local value  = opts.value  or 0
			local frame  = makeFrame(h)

			local topRow = Instance.new("Frame")
			topRow.Size                  = UDim2.new(1, -16, 0, 20)
			topRow.Position              = UDim2.new(0, 8, 0, 6)
			topRow.BackgroundTransparency= 1
			topRow.Parent                = frame

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size                  = UDim2.new(0.65, 0, 1, 0)
			nameLbl.BackgroundTransparency= 1
			nameLbl.Text                  = opts.name or "Progress"
			nameLbl.TextColor3            = SmileUILib.Theme.Text
			nameLbl.Font                  = SmileUILib.Theme.Font
			nameLbl.TextSize              = 12
			nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
			nameLbl.TextTruncate          = Enum.TextTruncate.AtEnd
			nameLbl.Parent                = topRow
			RegisterElement(windowId, nameLbl, "TextColor3", "Text")

			local pctLbl = Instance.new("TextLabel")
			pctLbl.Size                  = UDim2.new(0.35, 0, 1, 0)
			pctLbl.Position              = UDim2.new(0.65, 0, 0, 0)
			pctLbl.BackgroundTransparency= 1
			pctLbl.Text                  = math.floor((value / max) * 100) .. "%"
			pctLbl.TextColor3            = SmileUILib.Theme.Accent
			pctLbl.Font                  = SmileUILib.Theme.Font
			pctLbl.TextSize              = 12
			pctLbl.TextXAlignment        = Enum.TextXAlignment.Right
			pctLbl.Parent                = topRow
			RegisterElement(windowId, pctLbl, "TextColor3", "Accent")

			local track = Instance.new("Frame")
			track.Size             = UDim2.new(1, -16, 0, 6)
			track.Position         = UDim2.new(0, 8, 0, h - 14)
			track.BackgroundColor3 = SmileUILib.Theme.AccentVeryDark
			track.BorderSizePixel  = 0
			track.Parent           = frame
			mkCorner(track, UDim.new(1, 0))
			RegisterElement(windowId, track, "BackgroundColor3", "AccentVeryDark")

			local fill = Instance.new("Frame")
			fill.Size             = UDim2.new(value / max, 0, 1, 0)
			fill.BackgroundColor3 = SmileUILib.Theme.Accent
			fill.BorderSizePixel  = 0
			fill.Parent           = track
			mkCorner(fill, UDim.new(1, 0))
			RegisterElement(windowId, fill, "BackgroundColor3", "Accent")

			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, SmileUILib.Theme.AccentHover),
				ColorSequenceKeypoint.new(1, SmileUILib.Theme.Accent)
			})
			gradient.Parent = fill
			table.insert(SmileUILib._gradients, {instance = gradient, gtype = "progressFill"})

			local curValue = value
			local api      = {}
			function api:GetValue() return curValue end
			function api:SetValue(v)
				v        = math.clamp(v, 0, max)
				curValue = v
				TweenService:Create(fill, TweenInfo.new(T.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(v / max, 0, 1, 0)
				}):Play()
				pctLbl.Text = math.floor((v / max) * 100) .. "%"
			end
			return api
		end

		function tabAPI:AddColorPicker(opts)
			local default  = opts.default  or Color3.fromRGB(120, 80, 220)
			local frame    = makeFrame(32)
			makeLbl(frame, opts.name or "Color Picker", 10, "Text", 12)

			local colorBox = Instance.new("TextButton")
			colorBox.Size             = UDim2.new(0, 46, 0, 22)
			colorBox.AnchorPoint      = Vector2.new(1, 0.5)
			colorBox.Position         = UDim2.new(1, -8, 0.5, 0)
			colorBox.BackgroundColor3 = default
			colorBox.Text             = ""
			colorBox.AutoButtonColor  = false
			colorBox.BorderSizePixel  = 0
			colorBox.Parent           = frame
			mkCorner(colorBox, UDim.new(0, 4))
			local boxStroke = Instance.new("UIStroke")
			boxStroke.Color     = SmileUILib.Theme.BorderAccent
			boxStroke.Thickness = 2
			boxStroke.Parent    = colorBox
			RegisterElement(windowId, boxStroke, "Color", "BorderAccent")

			colorBox.MouseEnter:Connect(function() tw(boxStroke, {Thickness = 3}, 0.15) end)
			colorBox.MouseLeave:Connect(function() tw(boxStroke, {Thickness = 2}, 0.15) end)

			local modalOpen  = false
			local modalFrame = nil

			local function closeModal()
				if modalFrame then
					TweenService:Create(modalFrame, TweenInfo.new(0.18), {
						Size = UDim2.new(0, 280, 0, 0), BackgroundTransparency = 1
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
				overlay.Name             = "ColorPickerModal"
				overlay.Size             = UDim2.new(0, 280, 0, 320)
				overlay.Position         = UDim2.new(0, frame.AbsolutePosition.X + frame.AbsoluteSize.X - 280, 0, frame.AbsolutePosition.Y + 36)
				overlay.BackgroundColor3 = SmileUILib.Theme.Surface
				overlay.BorderSizePixel  = 0
				overlay.ZIndex           = 100
				overlay.Parent           = screen
				modalFrame               = overlay
				mkCorner(overlay, UDim.new(0, 6))
				local os = Instance.new("UIStroke"); os.Color = SmileUILib.Theme.StrokeColor; os.Thickness = 1; os.Parent = overlay

				local mHdr = Instance.new("Frame")
				mHdr.Size             = UDim2.new(1, 0, 0, 30)
				mHdr.BackgroundColor3 = SmileUILib.Theme.Header
				mHdr.BorderSizePixel  = 0
				mHdr.ZIndex           = 101
				mHdr.Parent           = overlay
				mkCorner(mHdr, UDim.new(0, 6))

				local mTitle = Instance.new("TextLabel")
				mTitle.Size                  = UDim2.new(1, -40, 1, 0)
				mTitle.Position              = UDim2.new(0, 10, 0, 0)
				mTitle.BackgroundTransparency= 1
				mTitle.Text                  = "Pick a Color"
				mTitle.TextColor3            = SmileUILib.Theme.Text
				mTitle.Font                  = SmileUILib.Theme.Font
				mTitle.TextSize              = 13
				mTitle.TextXAlignment        = Enum.TextXAlignment.Left
				mTitle.ZIndex                = 102
				mTitle.Parent                = mHdr

				local closeBtn = Instance.new("TextButton")
				closeBtn.Size             = UDim2.new(0, 24, 0, 24)
				closeBtn.Position         = UDim2.new(1, -28, 0, 3)
				closeBtn.BackgroundColor3 = SmileUILib.Theme.AccentVeryDark
				closeBtn.Text             = "×"
				closeBtn.TextColor3       = SmileUILib.Theme.Text
				closeBtn.Font             = SmileUILib.Theme.Font
				closeBtn.TextSize         = 16
				closeBtn.BorderSizePixel  = 0
				closeBtn.ZIndex           = 102
				closeBtn.Parent           = mHdr
				mkCorner(closeBtn, UDim.new(0, 4))
				closeBtn.MouseButton1Click:Connect(closeModal)

				local h, s, v = Color3ToHSV(default)
				local currentColor = default

				local spec = Instance.new("Frame")
				spec.Size             = UDim2.new(0, 200, 0, 140)
				spec.Position         = UDim2.new(0, 12, 0, 42)
				spec.BackgroundColor3 = Color3.new(1, 1, 1)
				spec.BorderSizePixel  = 0
				spec.ZIndex           = 101
				spec.Parent           = overlay
				mkCorner(spec, UDim.new(0, 4))

				local satGrad = Instance.new("UIGradient")
				satGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, HSVToColor3(h, 1, 1))
				})
				satGrad.Parent = spec

				local valOv = Instance.new("Frame")
				valOv.Size             = UDim2.new(1, 0, 1, 0)
				valOv.BackgroundTransparency= 0
				valOv.BorderSizePixel  = 0
				valOv.ZIndex           = 102
				valOv.Parent           = spec
				mkCorner(valOv, UDim.new(0, 4))

				local valGrad = Instance.new("UIGradient")
				valGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
					ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
				})
				valGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0)
				})
				valGrad.Rotation = 90
				valGrad.Parent   = valOv

				local cursor = Instance.new("Frame")
				cursor.Size             = UDim2.new(0, 10, 0, 10)
				cursor.Position         = UDim2.new(s, -5, 1 - v, -5)
				cursor.BackgroundColor3 = Color3.new(1, 1, 1)
				cursor.BorderSizePixel  = 2
				cursor.BorderColor3     = Color3.new(0, 0, 0)
				cursor.ZIndex           = 103
				cursor.Parent           = spec
				mkCorner(cursor, UDim.new(1, 0))

				local hueFrame = Instance.new("Frame")
				hueFrame.Size             = UDim2.new(0, 200, 0, 14)
				hueFrame.Position         = UDim2.new(0, 12, 0, 190)
				hueFrame.BackgroundColor3 = Color3.new(1, 1, 1)
				hueFrame.BorderSizePixel  = 0
				hueFrame.ZIndex           = 101
				hueFrame.Parent           = overlay
				mkCorner(hueFrame, UDim.new(1, 0))

				local hueGrad = Instance.new("UIGradient")
				hueGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,     Color3.fromRGB(255, 0,   0  )),
					ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0  )),
					ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,   255, 0  )),
					ColorSequenceKeypoint.new(0.5,   Color3.fromRGB(0,   255, 255)),
					ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,   0,   255)),
					ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0,   255)),
					ColorSequenceKeypoint.new(1,     Color3.fromRGB(255, 0,   0  )),
				})
				hueGrad.Parent = hueFrame

				local hueCursor = Instance.new("Frame")
				hueCursor.Size             = UDim2.new(0, 6, 1, 4)
				hueCursor.Position         = UDim2.new(h, -3, 0, -2)
				hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
				hueCursor.BorderSizePixel  = 2
				hueCursor.BorderColor3     = Color3.new(0, 0, 0)
				hueCursor.ZIndex           = 102
				hueCursor.Parent           = hueFrame

				local prevSec = Instance.new("Frame")
				prevSec.Size                  = UDim2.new(0, 50, 0, 140)
				prevSec.Position              = UDim2.new(0, 220, 0, 42)
				prevSec.BackgroundTransparency= 1
				prevSec.ZIndex                = 101
				prevSec.Parent                = overlay

				local bigPrev = Instance.new("Frame")
				bigPrev.Size             = UDim2.new(1, 0, 0, 46)
				bigPrev.BackgroundColor3 = currentColor
				bigPrev.BorderSizePixel  = 0
				bigPrev.ZIndex           = 101
				bigPrev.Parent           = prevSec
				mkCorner(bigPrev, UDim.new(0, 4))
				local bps = Instance.new("UIStroke"); bps.Color = SmileUILib.Theme.BorderAccent; bps.Thickness = 1; bps.Parent = bigPrev

				local function makeInfoLbl(y, txt)
					local l = Instance.new("TextLabel")
					l.Size                  = UDim2.new(1, 0, 0, 16)
					l.Position              = UDim2.new(0, 0, 0, y)
					l.BackgroundTransparency= 1
					l.Text                  = txt
					l.TextColor3            = SmileUILib.Theme.Text
					l.Font                  = SmileUILib.Theme.Font
					l.TextSize              = 11
					l.TextXAlignment        = Enum.TextXAlignment.Left
					l.ZIndex                = 101
					l.Parent                = prevSec
					return l
				end
				local rLbl   = makeInfoLbl(54,  "R: 0")
				local gLbl   = makeInfoLbl(70,  "G: 0")
				local bLbl   = makeInfoLbl(86,  "B: 0")
				local hexLbl = makeInfoLbl(106, "#000000")
				hexLbl.TextXAlignment = Enum.TextXAlignment.Center
				hexLbl.TextSize       = 10
				hexLbl.TextColor3     = SmileUILib.Theme.TextDim

				local confirmBtn = Instance.new("TextButton")
				confirmBtn.Size             = UDim2.new(0, 120, 0, 28)
				confirmBtn.Position         = UDim2.new(0.5, -60, 0, 278)
				confirmBtn.BackgroundColor3 = SmileUILib.Theme.Accent
				confirmBtn.Text             = "Apply"
				confirmBtn.TextColor3       = Color3.new(1, 1, 1)
				confirmBtn.Font             = SmileUILib.Theme.Font
				confirmBtn.TextSize         = 12
				confirmBtn.BorderSizePixel  = 0
				confirmBtn.ZIndex           = 101
				confirmBtn.Parent           = overlay
				mkCorner(confirmBtn, UDim.new(0, 4))

				local function updateColor()
					currentColor = HSVToColor3(h, s, v)
					bigPrev.BackgroundColor3  = currentColor
					colorBox.BackgroundColor3 = currentColor
					local r = math.floor(currentColor.R * 255)
					local g = math.floor(currentColor.G * 255)
					local b = math.floor(currentColor.B * 255)
					rLbl.Text   = "R: " .. r
					gLbl.Text   = "G: " .. g
					bLbl.Text   = "B: " .. b
					hexLbl.Text = string.format("#%02X%02X%02X", r, g, b)
				end
				updateColor()

				local specDrag = false
				spec.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						specDrag = true
						local rx = math.clamp((input.Position.X - spec.AbsolutePosition.X) / spec.AbsoluteSize.X, 0, 1)
						local ry = math.clamp((input.Position.Y - spec.AbsolutePosition.Y) / spec.AbsoluteSize.Y, 0, 1)
						s = rx; v = 1 - ry; cursor.Position = UDim2.new(s, -5, 1 - v, -5); updateColor()
					end
				end)
				spec.InputChanged:Connect(function(input)
					if specDrag and (input.UserInputType == Enum.UserInputType.MouseMovement) then
						local rx = math.clamp((input.Position.X - spec.AbsolutePosition.X) / spec.AbsoluteSize.X, 0, 1)
						local ry = math.clamp((input.Position.Y - spec.AbsolutePosition.Y) / spec.AbsoluteSize.Y, 0, 1)
						s = rx; v = 1 - ry; cursor.Position = UDim2.new(s, -5, 1 - v, -5); updateColor()
					end
				end)

				local hueDrag = false
				hueFrame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						hueDrag = true
						local rx = math.clamp((input.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
						h = rx; hueCursor.Position = UDim2.new(h, -3, 0, -2)
						satGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, HSVToColor3(h, 1, 1))})
						updateColor()
					end
				end)
				hueFrame.InputChanged:Connect(function(input)
					if hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement) then
						local rx = math.clamp((input.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
						h = rx; hueCursor.Position = UDim2.new(h, -3, 0, -2)
						satGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, HSVToColor3(h, 1, 1))})
						updateColor()
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then specDrag = false; hueDrag = false end
				end)

				confirmBtn.MouseButton1Click:Connect(function()
					if opts.callback then opts.callback(currentColor) end
					closeModal()
					SmileUILib:Notify({title = "Color Applied", message = string.format("RGB: %d, %d, %d", math.floor(currentColor.R*255), math.floor(currentColor.G*255), math.floor(currentColor.B*255)), duration = 2})
				end)
				confirmBtn.MouseEnter:Connect(function() tw(confirmBtn, {BackgroundColor3 = SmileUILib.Theme.AccentHover}) end)
				confirmBtn.MouseLeave:Connect(function() tw(confirmBtn, {BackgroundColor3 = SmileUILib.Theme.Accent})      end)

				overlay.Size = UDim2.new(0, 280, 0, 0)
				overlay.BackgroundTransparency = 1
				TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 280, 0, 320), BackgroundTransparency = 0
				}):Play()
			end

			colorBox.MouseButton1Click:Connect(openModal)

			local currentColor = default
			local api = {}
			function api:GetColor() return currentColor end
			function api:SetColor(color)
				currentColor = color
				colorBox.BackgroundColor3 = color
				if opts.callback then opts.callback(color) end
			end
			return api
		end

		return tabAPI
	end

	return window
end

return SmileUILib
