local InputService  = game:GetService('UserInputService')
local TextService   = game:GetService('TextService')
local CoreGui       = game:GetService('CoreGui')
local Teams         = game:GetService('Teams')
local Players       = game:GetService('Players')
local RunService    = game:GetService('RunService')
local TweenService  = game:GetService('TweenService')
local Lighting      = game:GetService('Lighting')

local RenderStepped = RunService.RenderStepped
local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)
local ScreenGui  = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local IsMobile = InputService.TouchEnabled
    and not InputService.KeyboardEnabled
    and not InputService.MouseEnabled

local Camera       = workspace.CurrentCamera
local ScreenWidth  = Camera.ViewportSize.X
local ScreenHeight = Camera.ViewportSize.Y

local SCALE = 1
if IsMobile then
    SCALE = math.clamp(math.min(ScreenWidth, ScreenHeight) / 400, 0.6, 1.4)
end

local function S(v)
    if IsMobile then return math.round(v * SCALE) end
    return v
end

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry        = {};
    RegistryMap     = {};
    HudRegistry     = {};
    FontColor       = Color3.fromRGB(255, 255, 255);
    MainColor       = Color3.fromRGB(28,  28,  28 );
    BackgroundColor = Color3.fromRGB(20,  20,  20 );
    AccentColor     = Color3.fromRGB(140, 0,   255);
    OutlineColor    = Color3.fromRGB(50,  50,  50 );
    RiskColor       = Color3.fromRGB(255, 50,  50 );
    Black           = Color3.new(0, 0, 0);
    Font            = Enum.Font.SourceSans;
    OpenedFrames    = {};
    DependencyBoxes = {};
    Signals         = {};
    ScreenGui       = ScreenGui;
    IsMobile        = IsMobile;
    Scale           = SCALE;
}

do
    local step, hue = 0, 0
    table.insert(Library.Signals, RenderStepped:Connect(function(dt)
        step = step + dt
        if step >= 1/60 then
            step = 0
            hue  = (hue + 1/400) % 1
            Library.CurrentRainbowHue   = hue
            Library.CurrentRainbowColor = Color3.fromHSV(hue, 0.8, 1)
        end
    end))
end

local function GetPlayersString()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do t[#t+1] = p.Name end
    table.sort(t)
    return t
end

local function GetTeamsString()
    local t = {}
    for _, tm in ipairs(Teams:GetTeams()) do t[#t+1] = tm.Name end
    table.sort(t)
    return t
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(':%d+: ')
        Library:Notify(i and err:sub(i+1) or err, 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Props)
    local inst = type(Class) == 'string' and Instance.new(Class) or Class
    for k, v in next, Props do inst[k] = v end
    return inst
end

function Library:CreateLabel(Props, IsHud)
    local inst = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font                   = Library.Font;
        TextColor3             = Library.FontColor;
        TextSize               = S(Props.TextSize or 16);
        TextStrokeTransparency = 0;
    })
    Library:AddToRegistry(inst, { TextColor3 = 'FontColor' }, IsHud)
    local p2 = {}
    for k, v in next, Props do p2[k] = v end
    if p2.TextSize then p2.TextSize = S(p2.TextSize) end
    return Library:Create(inst, p2)
end

function Library:CursorPos()
    if IsMobile then
        local loc = InputService:GetMouseLocation()
        return loc.X, loc.Y
    end
    return Mouse.X, Mouse.Y
end

function Library:IsPointerInput(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch
end

function Library:MouseIsOverOpenedFrame()
    local px, py = Library:CursorPos()
    for Frame in next, Library.OpenedFrames do
        local ap, as = Frame.AbsolutePosition, Frame.AbsoluteSize
        if px >= ap.X and px <= ap.X + as.X and py >= ap.Y and py <= ap.Y + as.Y then
            return true
        end
    end
    return false
end

function Library:IsMouseOverFrame(Frame)
    local px, py = Library:CursorPos()
    local ap, as = Frame.AbsolutePosition, Frame.AbsoluteSize
    return px >= ap.X and px <= ap.X + as.X and py >= ap.Y and py <= ap.Y + as.Y
end

function Library:UpdateDependencyBoxes()
    for _, db in next, Library.DependencyBoxes do db:Update() end
end

function Library:MapValue(v, a0, a1, b0, b1)
    local t = (v - a0) / (a1 - a0)
    return b0 + t * (b1 - b0)
end

function Library:GetTextBounds(Text, Font, Size, Res)
    local b = TextService:GetTextSize(Text, Size, Font, Res or Vector2.new(1920, 1080))
    return b.X, b.Y
end

function Library:GetDarkerColor(c)
    local h, s, v = Color3.toHSV(c)
    return Color3.fromHSV(h, s, v / 1.5)
end

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(inst, props, isHud)
    local data = { Instance = inst; Properties = props }
    table.insert(Library.Registry, data)
    Library.RegistryMap[inst] = data
    if isHud then table.insert(Library.HudRegistry, data) end
end

function Library:RemoveFromRegistry(inst)
    local data = Library.RegistryMap[inst]
    if not data then return end
    for i = #Library.Registry, 1, -1 do
        if Library.Registry[i] == data then table.remove(Library.Registry, i) end
    end
    for i = #Library.HudRegistry, 1, -1 do
        if Library.HudRegistry[i] == data then table.remove(Library.HudRegistry, i) end
    end
    Library.RegistryMap[inst] = nil
end

function Library:UpdateColorsUsingRegistry()
    for _, obj in next, Library.Registry do
        for prop, idx in next, obj.Properties do
            if type(idx) == 'string' then
                obj.Instance[prop] = Library[idx]
            elseif type(idx) == 'function' then
                obj.Instance[prop] = idx()
            end
        end
    end
end

function Library:GiveSignal(sig)
    table.insert(Library.Signals, sig)
end

function Library:Unload()
    for i = #Library.Signals, 1, -1 do
        table.remove(Library.Signals, i):Disconnect()
    end
    if Library.MenuBlur and Library.MenuBlur.Parent then
        pcall(function() Library.MenuBlur.Size = 0 end)
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

function Library:OnUnload(cb)
    Library.OnUnload = cb
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(inst)
    if Library.RegistryMap[inst] then Library:RemoveFromRegistry(inst) end
end))

-- FIXED DRAGGING SYSTEM
function Library:MakeDraggable(Frame, Cutoff)
    local cutY = Cutoff or S(40)
    Frame.Active = true

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    Frame.InputBegan:Connect(function(Input)
        if not Library:IsPointerInput(Input) then return end
        
        local inputY = Input.Position.Y - Frame.AbsolutePosition.Y
        if inputY > cutY then return end

        dragging = true
        dragStart = Input.Position
        startPos = Frame.Position
    end)

    Frame.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            dragInput = Input
        end
    end)

    InputService.InputChanged:Connect(function(Input)
        if Input == dragInput and dragging then
            local delta = Input.Position - dragStart
            Frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    InputService.InputEnded:Connect(function(Input)
        if Library:IsPointerInput(Input) then
            dragging = false
            dragInput = nil
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local tw, th = Library:GetTextBounds(InfoStr, Library.Font, S(14))
    local tip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        Size             = UDim2.fromOffset(tw + S(6), th + S(4));
        ZIndex           = 100;
        Visible          = false;
        Parent           = ScreenGui;
    })
    Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font                   = Library.Font;
        Position               = UDim2.fromOffset(S(3), S(2));
        Size                   = UDim2.fromOffset(tw, th);
        Text                   = InfoStr;
        TextColor3             = Library.FontColor;
        TextSize               = S(14);
        TextXAlignment         = Enum.TextXAlignment.Left;
        ZIndex                 = 101;
        Parent                 = tip;
    })
    Library:AddToRegistry(tip, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })

    if IsMobile then
        HoverInstance.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.Touch then return end
            tip.Position = UDim2.fromOffset(Input.Position.X + S(12), Input.Position.Y + S(10))
            tip.Visible  = true
            task.delay(2.5, function() tip.Visible = false end)
        end)
    else
        local hovering = false
        HoverInstance.MouseEnter:Connect(function()
            hovering = true
            tip.Visible = true
            while hovering do
                tip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 10)
                RunService.Heartbeat:Wait()
            end
        end)
        HoverInstance.MouseLeave:Connect(function()
            hovering   = false
            tip.Visible = false
        end)
    end
end

function Library:OnHighlight(HoverInst, TargetInst, OnProps, OffProps)
    local function apply(props)
        local reg = Library.RegistryMap[TargetInst]
        for prop, idx in next, props do
            TargetInst[prop] = Library[idx] or idx
            if reg and reg.Properties[prop] then reg.Properties[prop] = idx end
        end
    end

    if IsMobile then
        HoverInst.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then apply(OnProps) end
        end)
        HoverInst.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then apply(OffProps) end
        end)
    else
        HoverInst.MouseEnter:Connect(function() apply(OnProps) end)
        HoverInst.MouseLeave:Connect(function() apply(OffProps) end)
    end
end

-- FIXED DRAG HANDLER FOR SLIDERS/COLOR PICKERS
local function HandleDrag(Frame, onMove, onEnd)
    local dragging = false
    local dragInput = nil

    Frame.InputBegan:Connect(function(Input)
        if not Library:IsPointerInput(Input) then return end
        dragging = true
        onMove(Input.Position.X, Input.Position.Y)
    end)

    Frame.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            dragInput = Input
        end
    end)

    InputService.InputChanged:Connect(function(Input)
        if dragging and Input == dragInput then
            onMove(Input.Position.X, Input.Position.Y)
        end
    end)

    InputService.InputEnded:Connect(function(Input)
        if Library:IsPointerInput(Input) and dragging then
            dragging = false
            dragInput = nil
            if onEnd then onEnd() end
        end
    end)
end

do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position               = UDim2.new(0, 0, 0, S(40));
        Size                   = UDim2.new(0, S(320), 1, -S(50));
        ZIndex                 = 100;
        Parent                 = ScreenGui;
    })
    Library:Create('UIListLayout', {
        Padding           = UDim.new(0, S(4));
        FillDirection     = Enum.FillDirection.Vertical;
        SortOrder         = Enum.SortOrder.LayoutOrder;
        Parent            = Library.NotificationArea;
    })

    local WMOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0,0,0);
        Position     = UDim2.fromOffset(S(1000), -S(25));
        Size         = UDim2.fromOffset(S(213), S(20));
        ZIndex       = 200;
        Visible      = false;
        Parent       = ScreenGui;
    })
    local WMInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.AccentColor;
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 201;
        Parent           = WMOuter;
    })
    Library:AddToRegistry(WMInner, { BorderColor3 = 'AccentColor' })
    local WMGradFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1,1,1);
        BorderSizePixel  = 0;
        Position         = UDim2.new(0,1,0,1);
        Size             = UDim2.new(1,-2,1,-2);
        ZIndex           = 202;
        Parent           = WMInner;
    })
    local WMGrad = Library:Create('UIGradient', {
        Color    = ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) });
        Rotation = -90;
        Parent   = WMGradFrame;
    })
    Library:AddToRegistry(WMGrad, { Color = function() return ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }) end })
    local WMLabel = Library:CreateLabel({
        Position       = UDim2.new(0, S(5), 0, 0);
        Size           = UDim2.new(1, -S(4), 1, 0);
        TextSize       = S(14);
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 203;
        Parent         = WMGradFrame;
    })
    Library.Watermark     = WMOuter
    Library.WatermarkText = WMLabel
    Library:MakeDraggable(WMOuter)

    local KBOuter = Library:Create('Frame', {
        AnchorPoint  = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0,0,0);
        Position     = UDim2.new(0, S(10), 0.5, 0);
        Size         = UDim2.fromOffset(S(210), S(20));
        Visible      = false;
        ZIndex       = 100;
        Parent       = ScreenGui;
    })
    local KBInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 101;
        Parent           = KBOuter;
    })
    Library:AddToRegistry(KBInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' }, true)
    Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(1,0,0,2);
        ZIndex           = 102;
        Parent           = KBInner;
    })
    Library:AddToRegistry(KBInner:GetChildren()[1], { BackgroundColor3 = 'AccentColor' }, true)
    Library:CreateLabel({
        Size             = UDim2.new(1,0,0,S(20));
        Position         = UDim2.fromOffset(0, S(2));
        TextXAlignment   = Enum.TextXAlignment.Center;
        TextTransparency = 0.3;
        Text             = 'Keybinds';
        ZIndex           = 104;
        Parent           = KBInner;
    })
    local KBContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position               = UDim2.new(0,0,0,S(20));
        Size                   = UDim2.new(1,0,1,-S(20));
        ZIndex                 = 1;
        Parent                 = KBInner;
    })
    Library:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = KBContainer })
    Library:Create('UIPadding',    { PaddingLeft = UDim.new(0, S(5)); Parent = KBContainer })
    Library.KeybindFrame     = KBOuter
    Library.KeybindContainer = KBContainer
    Library:MakeDraggable(KBOuter)
end

function Library:SetWatermarkVisibility(b)  Library.Watermark.Visible = b end
function Library:SetWatermark(Text)
    local x = Library:GetTextBounds(Text, Library.Font, S(14))
    Library.Watermark.Size = UDim2.fromOffset(x + S(15), S(20))
    Library.WatermarkText.Text = Text
    Library:SetWatermarkVisibility(true)
end

function Library:Notify(Text, Time)
    local xw = Library:GetTextBounds(Text, Library.Font, S(14))
    local H   = S(22)
    local Outer = Library:Create('Frame', {
        BorderColor3     = Color3.new(0,0,0);
        Size             = UDim2.fromOffset(0, H);
        ClipsDescendants = true;
        ZIndex           = 100;
        Parent           = Library.NotificationArea;
    })
    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        BorderMode       = Enum.BorderMode.Inset;
        Size             = UDim2.new(1,0,1,0);
        ZIndex           = 101;
        Parent           = Outer;
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' }, true)
    local GF = Library:Create('Frame', { BackgroundColor3 = Color3.new(1,1,1); BorderSizePixel = 0; Position = UDim2.new(0,1,0,1); Size = UDim2.new(1,-2,1,-2); ZIndex = 102; Parent = Inner })
    local G  = Library:Create('UIGradient', { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }); Rotation = -90; Parent = GF })
    Library:AddToRegistry(G, { Color = function() return ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }) end })
    Library:CreateLabel({ Position = UDim2.new(0, S(8), 0, 0); Size = UDim2.new(1, -S(8), 1, 0); Text = Text; TextXAlignment = Enum.TextXAlignment.Left; TextSize = S(13); ZIndex = 103; Parent = GF })
    Library:Create('Frame', { BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0; Position = UDim2.new(0,-1,0,-1); Size = UDim2.new(0, S(3), 1, 2); ZIndex = 104; Parent = Outer })
    Library:AddToRegistry(Outer:GetChildren()[#Outer:GetChildren()], { BackgroundColor3 = 'AccentColor' }, true)
    pcall(Outer.TweenSize, Outer, UDim2.fromOffset(xw + S(16), H), 'Out', 'Quad', 0.35, true)
    task.spawn(function()
        task.wait(Time or 5)
        pcall(Outer.TweenSize, Outer, UDim2.fromOffset(0, H), 'Out', 'Quad', 0.35, true)
        task.wait(0.4)
        Outer:Destroy()
    end)
end

function Library:SetAccentColor(Color)
    Library.AccentColor     = Color
    Library.AccentColorDark = Library:GetDarkerColor(Color)
    Library:UpdateColorsUsingRegistry()
end

local BaseAddons  = {}
local BaseGroupbox = {}

do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        assert(Info.Default, 'AddColorPicker: Missing default value.')
        local TL = self.TextLabel

        local CP = {
            Value        = Info.Default;
            Transparency = Info.Transparency or 0;
            Type         = 'ColorPicker';
            Title        = tostring(Info.Title or 'Color picker');
            Callback     = Info.Callback or function() end;
        }

        local function RGB2HSV(c) local h,s,v = Color3.toHSV(c); CP.Hue = h; CP.Sat = s; CP.Vib = v end
        RGB2HSV(CP.Value)

        local DispW, DispH = S(28), S(14)
        local Swatch = Library:Create('Frame', {
            BackgroundColor3 = CP.Value;
            BorderColor3     = Library:GetDarkerColor(CP.Value);
            BorderMode       = Enum.BorderMode.Inset;
            Size             = UDim2.fromOffset(DispW, DispH);
            ZIndex           = 6;
            Parent           = TL;
        })
        if Info.Transparency then
            Library:Create('ImageLabel', { BorderSizePixel = 0; Size = UDim2.new(0, DispW-1, 0, DispH-1); ZIndex = 5; Image = 'rbxassetid://12977615774'; Parent = Swatch })
        end

        local pickerW = S(230)
        local pickerH = Info.Transparency and S(271) or S(253)
        local mapSz   = S(200)

        local PFOuter = Library:Create('Frame', { Name = 'Color'; BackgroundColor3 = Color3.new(1,1,1); BorderColor3 = Color3.new(0,0,0); Size = UDim2.fromOffset(pickerW, pickerH); Visible = false; ZIndex = 15; Parent = ScreenGui })
        local PFInner = Library:Create('Frame', { BackgroundColor3 = Library.BackgroundColor; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 16; Parent = PFOuter })
        Library:AddToRegistry(PFInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })

        local function UpdatePickerPos()
            PFOuter.Position = UDim2.fromOffset(Swatch.AbsolutePosition.X, Swatch.AbsolutePosition.Y + DispH + S(2))
        end
        Swatch:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdatePickerPos)
        UpdatePickerPos()

        local AccBar = Library:Create('Frame', { BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0; Size = UDim2.new(1,0,0,2); ZIndex = 17; Parent = PFInner })
        Library:AddToRegistry(AccBar, { BackgroundColor3 = 'AccentColor' })

        Library:CreateLabel({ Size = UDim2.new(1,0,0,S(14)); Position = UDim2.fromOffset(S(5), S(4)); TextSize = S(13); Text = CP.Title; TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = false; ZIndex = 17; Parent = PFInner })

        local SVOuter = Library:Create('Frame', { BorderColor3 = Color3.new(0,0,0); Position = UDim2.new(0, S(4), 0, S(24)); Size = UDim2.fromOffset(mapSz, mapSz); ZIndex = 17; Parent = PFInner })
        local SVInner = Library:Create('Frame', { BackgroundColor3 = Library.BackgroundColor; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 18; Parent = SVOuter })
        local SVMap   = Library:Create('ImageLabel', { BorderSizePixel = 0; Size = UDim2.new(1,0,1,0); ZIndex = 18; Image = 'rbxassetid://4155801252'; Parent = SVInner })
        Library:AddToRegistry(SVInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })

        local CurOut = Library:Create('ImageLabel', { AnchorPoint = Vector2.new(0.5,0.5); Size = UDim2.fromOffset(S(6),S(6)); BackgroundTransparency=1; Image='rbxassetid://9619665977'; ImageColor3=Color3.new(0,0,0); ZIndex=19; Parent=SVMap })
        Library:Create('ImageLabel', { Size=UDim2.fromOffset(S(4),S(4)); Position=UDim2.fromOffset(1,1); BackgroundTransparency=1; Image='rbxassetid://9619665977'; ZIndex=20; Parent=CurOut })

        local HUOuter = Library:Create('Frame', { BorderColor3 = Color3.new(0,0,0); Position = UDim2.new(0, S(208), 0, S(24)); Size = UDim2.fromOffset(S(15), mapSz); ZIndex = 17; Parent = PFInner })
        local HUInner = Library:Create('Frame', { BackgroundColor3 = Color3.new(1,1,1); BorderSizePixel = 0; Size = UDim2.new(1,0,1,0); ZIndex = 18; Parent = HUOuter })
        local hueSKP  = {}
        for i = 0, 1, 0.1 do table.insert(hueSKP, ColorSequenceKeypoint.new(math.min(i,1), Color3.fromHSV(i,1,1))) end
        Library:Create('UIGradient', { Color = ColorSequence.new(hueSKP); Rotation = 90; Parent = HUInner })

        local HexOuter = Library:Create('Frame', { BorderColor3 = Color3.new(0,0,0); Position = UDim2.new(0, S(4), 0, S(228)); Size = UDim2.new(0.5, -S(6), 0, S(20)); ZIndex = 18; Parent = PFInner })
        local HexInner = Library:Create('Frame', { BackgroundColor3 = Library.MainColor; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 18; Parent = HexOuter })
        Library:Create('UIGradient', { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(212,212,212)) }); Rotation = 90; Parent = HexInner })
        local HexBox = Library:Create('TextBox', { BackgroundTransparency=1; Position=UDim2.new(0,S(4),0,0); Size=UDim2.new(1,-S(4),1,0); Font=Library.Font; PlaceholderText='Hex'; PlaceholderColor3=Color3.fromRGB(190,190,190); Text='#FFFFFF'; TextColor3=Library.FontColor; TextSize=S(13); TextXAlignment=Enum.TextXAlignment.Left; ZIndex=20; Parent=HexInner })
        Library:AddToRegistry(HexInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(HexBox,   { TextColor3 = 'FontColor' })

        local RgbOuter = Library:Create('Frame', { BorderColor3 = Color3.new(0,0,0); Position = UDim2.new(0.5, S(2), 0, S(228)); Size = UDim2.new(0.5, -S(6), 0, S(20)); ZIndex = 18; Parent = PFInner })
        local RgbInner = Library:Create('Frame', { BackgroundColor3 = Library.MainColor; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 18; Parent = RgbOuter })
        Library:Create('UIGradient', { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(212,212,212)) }); Rotation = 90; Parent = RgbInner })
        local RgbBox = Library:Create('TextBox', { BackgroundTransparency=1; Position=UDim2.new(0,S(4),0,0); Size=UDim2.new(1,-S(4),1,0); Font=Library.Font; PlaceholderText='R,G,B'; PlaceholderColor3=Color3.fromRGB(190,190,190); Text='255,255,255'; TextColor3=Library.FontColor; TextSize=S(13); TextXAlignment=Enum.TextXAlignment.Left; ZIndex=20; Parent=RgbInner })
        Library:AddToRegistry(RgbInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(RgbBox,   { TextColor3 = 'FontColor' })

        local TransInner
        if Info.Transparency then
            local TransOuter = Library:Create('Frame', { BorderColor3 = Color3.new(0,0,0); Position = UDim2.fromOffset(S(4), S(251)); Size = UDim2.new(1, -S(8), 0, S(14)); ZIndex = 19; Parent = PFInner })
            TransInner = Library:Create('Frame', { BackgroundColor3 = CP.Value; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 19; Parent = TransOuter })
            Library:AddToRegistry(TransInner, { BorderColor3 = 'OutlineColor' })
            Library:Create('ImageLabel', { BackgroundTransparency=1; Size=UDim2.new(1,0,1,0); Image='rbxassetid://12978095818'; ZIndex=20; Parent=TransInner })
        end

        function CP:Display()
            CP.Value = Color3.fromHSV(CP.Hue, CP.Sat, CP.Vib)
            SVMap.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
            Swatch.BackgroundColor3 = CP.Value
            Swatch.BackgroundTransparency = CP.Transparency
            Swatch.BorderColor3 = Library:GetDarkerColor(CP.Value)
            if TransInner then TransInner.BackgroundColor3 = CP.Value end
            CurOut.Position = UDim2.new(CP.Sat, 0, 1 - CP.Vib, 0)
            HexBox.Text = '#'..CP.Value:ToHex()
            RgbBox.Text = math.floor(CP.Value.R*255)..','..math.floor(CP.Value.G*255)..','..math.floor(CP.Value.B*255)
            Library:SafeCallback(CP.Callback, CP.Value)
            Library:SafeCallback(CP.Changed,  CP.Value)
        end

        function CP:Show()
            for f in next, Library.OpenedFrames do if f.Name == 'Color' then f.Visible = false; Library.OpenedFrames[f] = nil end end
            UpdatePickerPos()
            PFOuter.Visible = true
            Library.OpenedFrames[PFOuter] = true
        end
        function CP:Hide()
            PFOuter.Visible = false
            Library.OpenedFrames[PFOuter] = nil
        end
        function CP:SetValue(hsv, trans)
            CP.Hue, CP.Sat, CP.Vib = hsv[1], hsv[2], hsv[3]
            CP.Transparency = trans or 0
            CP:Display()
        end
        function CP:SetValueRGB(c, trans)
            CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(c)
            CP.Transparency = trans or 0
            CP:Display()
        end
        function CP:OnChanged(fn) CP.Changed = fn; fn(CP.Value) end

        HandleDrag(SVMap, function(x,y)
            local ap, as = SVMap.AbsolutePosition, SVMap.AbsoluteSize
            CP.Sat = math.clamp((x - ap.X) / as.X, 0, 1)
            CP.Vib = 1 - math.clamp((y - ap.Y) / as.Y, 0, 1)
            CP:Display()
        end, function() Library:AttemptSave() end)

        HandleDrag(HUInner, function(x,y)
            local ap, as = HUInner.AbsolutePosition, HUInner.AbsoluteSize
            CP.Hue = math.clamp((y - ap.Y) / as.Y, 0, 1)
            CP:Display()
        end, function() Library:AttemptSave() end)

        if TransInner then
            HandleDrag(TransInner, function(x,y)
                local ap, as = TransInner.AbsolutePosition, TransInner.AbsoluteSize
                CP.Transparency = 1 - math.clamp((x - ap.X) / as.X, 0, 1)
                CP:Display()
            end, function() Library:AttemptSave() end)
        end

        HexBox.FocusLost:Connect(function(enter)
            if enter then
                local ok, c = pcall(Color3.fromHex, HexBox.Text)
                if ok then CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(c) end
            end
            CP:Display()
        end)
        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r,g,b = RgbBox.Text:match('(%d+),(%d+),(%d+)')
                if r then CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(Color3.fromRGB(r,g,b)) end
            end
            CP:Display()
        end)

        Swatch.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input) then return end
            if Library:MouseIsOverOpenedFrame() then return end
            if Input.UserInputType == Enum.UserInputType.MouseButton2 then return end
            if PFOuter.Visible then CP:Hide() else CP:Show() end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input) then return end
            local px = IsMobile and Input.Position.X or Mouse.X
            local py = IsMobile and Input.Position.Y or Mouse.Y
            local ap, as = PFOuter.AbsolutePosition, PFOuter.AbsoluteSize
            if px < ap.X or px > ap.X+as.X or py < ap.Y-DispH-2 or py > ap.Y+as.Y then
                CP:Hide()
            end
        end))

        CP:Display()
        CP.DisplayFrame = Swatch
        Options[Idx] = CP
        return self
    end

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local TL        = self.TextLabel
        assert(Info.Default, 'AddKeyPicker: Missing default value.')

        local KP = {
            Value          = Info.Default;
            Toggled        = false;
            Mode           = Info.Mode or 'Toggle';
            Type           = 'KeyPicker';
            Callback       = Info.Callback       or function() end;
            ChangedCallback= Info.ChangedCallback or function() end;
            SyncToggleState= Info.SyncToggleState or false;
        }
        if KP.SyncToggleState then Info.Modes = { 'Toggle' }; Info.Mode = 'Toggle' end

        local PickOut = Library:Create('Frame', { BorderColor3 = Color3.new(0,0,0); Size = UDim2.fromOffset(S(28), S(15)); ZIndex = 6; Parent = TL })
        local PickIn  = Library:Create('Frame', { BackgroundColor3 = Library.BackgroundColor; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 7; Parent = PickOut })
        Library:AddToRegistry(PickIn, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
        local DispLabel = Library:CreateLabel({ Size = UDim2.new(1,0,1,0); TextSize = S(12); Text = Info.Default; TextWrapped = true; ZIndex = 8; Parent = PickIn })

        local Modes = IsMobile and { 'Toggle', 'Hold' } or (Info.Modes or { 'Always', 'Toggle', 'Hold' })
        local ModeOut = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Size         = UDim2.fromOffset(S(60), #Modes * S(15) + S(4));
            Visible      = false;
            ZIndex       = 14;
            Parent       = ScreenGui;
        })
        local ModeIn = Library:Create('Frame', { BackgroundColor3 = Library.BackgroundColor; BorderColor3 = Library.OutlineColor; BorderMode = Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex = 15; Parent = ModeOut })
        Library:AddToRegistry(ModeIn, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor' })
        Library:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Parent = ModeIn })

        local function UpdateModePos()
            ModeOut.Position = UDim2.fromOffset(TL.AbsolutePosition.X + TL.AbsoluteSize.X + S(4), TL.AbsolutePosition.Y + 1)
        end
        TL:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModePos)
        UpdateModePos()

        local HudLabel = Library:CreateLabel({ TextXAlignment = Enum.TextXAlignment.Left; Size = UDim2.new(1,0,0,S(18)); TextSize = S(12); Visible = false; ZIndex = 110; Parent = Library.KeybindContainer }, true)

        local ModeButtons = {}
        for _, mode in ipairs(Modes) do
            local btn = {}
            local lbl = Library:CreateLabel({ Active = false; Size = UDim2.new(1,0,0,S(15)); TextSize = S(12); Text = mode; ZIndex = 16; Parent = ModeIn })
            function btn:Select()
                for _, b in next, ModeButtons do b:Deselect() end
                KP.Mode = mode
                lbl.TextColor3 = Library.AccentColor
                Library.RegistryMap[lbl].Properties.TextColor3 = 'AccentColor'
                ModeOut.Visible = false
            end
            function btn:Deselect()
                lbl.TextColor3 = Library.FontColor
                Library.RegistryMap[lbl].Properties.TextColor3 = 'FontColor'
            end
            lbl.InputBegan:Connect(function(Input)
                if Library:IsPointerInput(Input) then btn:Select(); Library:AttemptSave() end
            end)
            if mode == KP.Mode then btn:Select() end
            ModeButtons[mode] = btn
        end

        function KP:Update()
            if Info.NoUI then return end
            local state = KP:GetState()
            HudLabel.Text    = string.format('[%s] %s (%s)', KP.Value, Info.Text or '', KP.Mode or '')
            HudLabel.Visible = true
            HudLabel.TextColor3 = state and Library.AccentColor or Library.FontColor
            Library.RegistryMap[HudLabel].Properties.TextColor3 = state and 'AccentColor' or 'FontColor'
            local ys, xs = 0, 0
            for _, ch in ipairs(Library.KeybindContainer:GetChildren()) do
                if ch:IsA('TextLabel') and ch.Visible then
                    ys = ys + S(18)
                    xs = math.max(xs, ch.TextBounds.X)
                end
            end
            Library.KeybindFrame.Size = UDim2.fromOffset(math.max(xs + S(10), S(210)), ys + S(23))
        end

        function KP:GetState()
            if KP.Mode == 'Always' then return true end
            if KP.Mode == 'Hold' then
                if KP.Value == 'None' then return false end
                if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                if KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                return InputService:IsKeyDown(Enum.KeyCode[KP.Value])
            end
            return KP.Toggled
        end

        function KP:SetValue(data)
            DispLabel.Text = data[1]; KP.Value = data[1]
            if ModeButtons[data[2]] then ModeButtons[data[2]]:Select() end
            KP:Update()
        end
        function KP:OnClick(fn)    KP.Clicked = fn end
        function KP:OnChanged(fn)  KP.Changed = fn; fn(KP.Value) end
        if ParentObj.Addons then table.insert(ParentObj.Addons, KP) end

        function KP:DoClick()
            if ParentObj.Type == 'Toggle' and KP.SyncToggleState then ParentObj:SetValue(not ParentObj.Value) end
            Library:SafeCallback(KP.Callback, KP.Toggled)
            Library:SafeCallback(KP.Clicked,  KP.Toggled)
        end

        local Picking = false
        PickOut.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then return end
            if Input.UserInputType == Enum.UserInputType.MouseButton2 then
                ModeOut.Visible = true; return
            end
            if not Library:IsPointerInput(Input) then return end
            if IsMobile then
                KP.Toggled = not KP.Toggled; KP:DoClick(); KP:Update(); return
            end
            Picking = true; DispLabel.Text = ''
            local dots = ''
            local dotTask = task.spawn(function()
                while Picking do
                    dots = #dots >= 3 and '' or dots..'.'
                    DispLabel.Text = dots
                    task.wait(0.3)
                end
            end)
            task.wait(0.15)
            local ev
            ev = InputService.InputBegan:Connect(function(In)
                local key
                if In.UserInputType == Enum.UserInputType.Keyboard    then key = In.KeyCode.Name
                elseif In.UserInputType == Enum.UserInputType.MouseButton1 then key = 'MB1'
                elseif In.UserInputType == Enum.UserInputType.MouseButton2 then key = 'MB2' end
                if not key then return end
                Picking = false; task.cancel(dotTask)
                DispLabel.Text = key; KP.Value = key
                Library:SafeCallback(KP.ChangedCallback, In.KeyCode or In.UserInputType)
                Library:SafeCallback(KP.Changed,         In.KeyCode or In.UserInputType)
                Library:AttemptSave()
                ev:Disconnect()
            end)
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Picking then
                if KP.Mode == 'Toggle' then
                    local k = KP.Value
                    if k == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1 then KP.Toggled = not KP.Toggled; KP:DoClick()
                    elseif k == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then KP.Toggled = not KP.Toggled; KP:DoClick()
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == k then KP.Toggled = not KP.Toggled; KP:DoClick() end
                end
                KP:Update()
            end
            if Library:IsPointerInput(Input) then
                local px = IsMobile and Input.Position.X or Mouse.X
                local py = IsMobile and Input.Position.Y or Mouse.Y
                local ap, as = ModeOut.AbsolutePosition, ModeOut.AbsoluteSize
                if px < ap.X or px > ap.X+as.X or py < ap.Y-S(20)-1 or py > ap.Y+as.Y then
                    ModeOut.Visible = false
                end
            end
        end))
        Library:GiveSignal(InputService.InputEnded:Connect(function() if not Picking then KP:Update() end end))
        KP:Update()
        Options[Idx] = KP
        return self
    end

    BaseAddons.__index     = Funcs
    BaseAddons.__namecall  = function(t, k, ...) return Funcs[k](...) end
end

do
    local Funcs = {}

    function Funcs:AddBlank(sz)
        Library:Create('Frame', { BackgroundTransparency=1; Size=UDim2.new(1,0,0,S(sz)); ZIndex=1; Parent=self.Container })
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}
        local GB    = self
        local TL    = Library:CreateLabel({
            Size           = UDim2.new(1, -S(4), 0, S(15));
            TextSize       = S(14);
            Text           = Text;
            TextWrapped    = DoesWrap or false;
            RichText        = true;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 5;
            Parent         = GB.Container;
        })
        if DoesWrap then
            local _, y = Library:GetTextBounds(Text, Library.Font, S(14), Vector2.new(TL.AbsoluteSize.X, math.huge))
            TL.Size = UDim2.new(1, -S(4), 0, y)
        else
            Library:Create('UIListLayout', { Padding=UDim.new(0,S(4)); FillDirection=Enum.FillDirection.Horizontal; HorizontalAlignment=Enum.HorizontalAlignment.Right; SortOrder=Enum.SortOrder.LayoutOrder; Parent=TL })
        end
        Label.TextLabel = TL
        Label.Container = GB.Container
        function Label:SetText(t)
            TL.Text = t
            if DoesWrap then
                local _, y = Library:GetTextBounds(t, Library.Font, S(14), Vector2.new(TL.AbsoluteSize.X, math.huge))
                TL.Size = UDim2.new(1, -S(4), 0, y)
            end
            GB:Resize()
        end
        if not DoesWrap then setmetatable(Label, BaseAddons) end
        GB:AddBlank(5); GB:Resize()
        return Label
    end

    function Funcs:AddDivider()
        self:AddBlank(2)
        local o = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-S(4),0,S(5)); ZIndex=5; Parent=self.Container })
        local i = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,1,0); ZIndex=6; Parent=o })
        Library:AddToRegistry(o, { BorderColor3='Black' })
        Library:AddToRegistry(i, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        self:AddBlank(9); self:Resize()
    end

    function Funcs:AddButton(...)
        local Btn = {}
        local args = { ... }
        local info = type(args[1]) == 'table' and args[1] or { Text=args[1]; Func=args[2] }
        Btn.Text = info.Text; Btn.Func = info.Func; Btn.DoubleClick = info.DoubleClick; Btn.Tooltip = info.Tooltip
        assert(type(Btn.Func) == 'function', 'AddButton: `Func` callback is missing.')

        local GB = self

        local function MakeBtn(b)
            local o = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size = UDim2.new(1,-S(4),0,S(IsMobile and 26 or 20)); ZIndex=5 })
            local i = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size = UDim2.new(1,0,1,0); ZIndex=6; Parent=o })
            local l = Library:CreateLabel({ Size=UDim2.new(1,0,1,0); TextSize=S(14); Text=b.Text; ZIndex=6; Parent=i })
            Library:Create('UIGradient', { Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(212,212,212))}); Rotation=90; Parent=i })
            Library:AddToRegistry(o, { BorderColor3='Black' })
            Library:AddToRegistry(i, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
            Library:OnHighlight(o, o, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
            return o, i, l
        end

        local function InitBtnEvents(b)
            local function valid(Input) return Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() end
            b.Outer.InputBegan:Connect(function(Input)
                if not valid(Input) or b.Locked then return end
                if b.DoubleClick then
                    b.Label.TextColor3 = Library.AccentColor
                    b.Label.Text = 'Are you sure?'
                    b.Locked = true
                    local clicked = false
                    local c = b.Outer.InputBegan:Connect(function(In) if valid(In) then clicked = true end end)
                    task.wait(0.5); c:Disconnect()
                    b.Label.TextColor3 = Library.FontColor
                    b.Label.Text = b.Text
                    task.defer(rawset, b, 'Locked', false)
                    if clicked then Library:SafeCallback(b.Func) end
                    return
                end
                Library:SafeCallback(b.Func)
            end)
        end

        Btn.Outer, Btn.Inner, Btn.Label = MakeBtn(Btn)
        Btn.Outer.Parent = GB.Container
        InitBtnEvents(Btn)

        function Btn:AddTooltip(t) if type(t)=='string' then Library:AddToolTip(t, self.Outer) end; return self end
        function Btn:AddButton(...)
            local args2 = { ... }
            local info2 = type(args2[1])=='table' and args2[1] or { Text=args2[1]; Func=args2[2] }
            local Sub = { Text=info2.Text; Func=info2.Func; DoubleClick=info2.DoubleClick; Tooltip=info2.Tooltip }
            assert(type(Sub.Func)=='function', 'AddButton sub: missing Func')
            self.Outer.Size = UDim2.new(0.5, -2, 0, S(IsMobile and 26 or 20))
            Sub.Outer, Sub.Inner, Sub.Label = MakeBtn(Sub)
            Sub.Outer.Position = UDim2.new(1, S(3), 0, 0)
            Sub.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            Sub.Outer.Parent = self.Outer
            InitBtnEvents(Sub)
            function Sub:AddTooltip(t) if type(t)=='string' then Library:AddToolTip(t,self.Outer) end; return Sub end
            if type(Sub.Tooltip)=='string' then Sub:AddTooltip(Sub.Tooltip) end
            return Sub
        end
        if type(Btn.Tooltip)=='string' then Btn:AddTooltip(Btn.Tooltip) end
        GB:AddBlank(5); GB:Resize()
        return Btn
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text`.')
        local Textbox = { Value=Info.Default or ''; Numeric=Info.Numeric; Finished=Info.Finished; Type='Input'; Callback=Info.Callback or function() end }
        local GB = self
        Library:CreateLabel({ Size=UDim2.new(1,0,0,S(15)); TextSize=S(14); Text=Info.Text; TextXAlignment=Enum.TextXAlignment.Left; ZIndex=5; Parent=GB.Container })
        GB:AddBlank(1)
        local BoxH = IsMobile and S(26) or S(20)
        local Outer = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-S(4),0,BoxH); ZIndex=5; Parent=GB.Container })
        local Inner = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,1,0); ZIndex=6; Parent=Outer })
        Library:AddToRegistry(Inner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        Library:OnHighlight(Outer, Outer, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
        Library:Create('UIGradient', { Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(212,212,212))}); Rotation=90; Parent=Inner })
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, Outer) end
        local Clip = Library:Create('Frame', { BackgroundTransparency=1; ClipsDescendants=true; Position=UDim2.new(0,S(5),0,0); Size=UDim2.new(1,-S(5),1,0); ZIndex=7; Parent=Inner })
        local Box  = Library:Create('TextBox', {
            BackgroundTransparency=1; Position=UDim2.fromOffset(0,0); Size=UDim2.fromScale(5,1);
            Font=Library.Font; PlaceholderColor3=Color3.fromRGB(190,190,190); PlaceholderText=Info.Placeholder or '';
            Text=Info.Default or ''; TextColor3=Library.FontColor; TextSize=S(14); TextStrokeTransparency=0;
            TextXAlignment=Enum.TextXAlignment.Left; ZIndex=7; Parent=Clip;
        })
        Library:AddToRegistry(Box, { TextColor3='FontColor' })

        function Textbox:SetValue(t)
            if Info.MaxLength and #t > Info.MaxLength then t = t:sub(1, Info.MaxLength) end
            if Textbox.Numeric and not tonumber(t) and #t > 0 then t = Textbox.Value end
            Textbox.Value = t; Box.Text = t
            Library:SafeCallback(Textbox.Callback, t)
            Library:SafeCallback(Textbox.Changed,  t)
        end
        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter) if enter then Textbox:SetValue(Box.Text); Library:AttemptSave() end end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function() Textbox:SetValue(Box.Text); Library:AttemptSave() end)
        end

        local function UpdateScroll()
            local pad = 2; local rev = Clip.AbsoluteSize.X
            if not Box:IsFocused() or Box.TextBounds.X <= rev - 2*pad then
                Box.Position = UDim2.fromOffset(pad, 0)
            else
                local cur = Box.CursorPosition
                if cur ~= -1 then
                    local w = TextService:GetTextSize(Box.Text:sub(1,cur-1), Box.TextSize, Box.Font, Vector2.new(math.huge,math.huge)).X
                    local cp = Box.Position.X.Offset + w
                    if cp < pad then Box.Position = UDim2.fromOffset(pad-w, 0)
                    elseif cp > rev-pad-1 then Box.Position = UDim2.fromOffset(rev-w-pad-1, 0) end
                end
            end
        end
        Box:GetPropertyChangedSignal('Text'):Connect(UpdateScroll)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(UpdateScroll)
        Box.FocusLost:Connect(UpdateScroll); Box.Focused:Connect(UpdateScroll)
        task.spawn(UpdateScroll)

        function Textbox:OnChanged(fn) Textbox.Changed = fn; fn(Textbox.Value) end
        GB:AddBlank(5); GB:Resize()
        Options[Idx] = Textbox
        return Textbox
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text`.')
        local Toggle = { Value=Info.Default or false; Type='Toggle'; Callback=Info.Callback or function() end; Addons={}; Risky=Info.Risky }
        local GB = self
        local boxSz = IsMobile and S(16) or S(13)
        local TOuter = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size=UDim2.fromOffset(boxSz,boxSz); ZIndex=5; Parent=GB.Container })
        Library:AddToRegistry(TOuter, { BorderColor3='Black' })
        local TInner = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,1,0); ZIndex=6; Parent=TOuter })
        Library:AddToRegistry(TInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        local TLabel = Library:CreateLabel({ Size=UDim2.new(0,S(216),1,0); Position=UDim2.new(1,S(6),0,0); TextSize=S(14); Text=Info.Text; TextXAlignment=Enum.TextXAlignment.Left; ZIndex=6; Parent=TInner })
        Library:Create('UIListLayout', { Padding=UDim.new(0,S(4)); FillDirection=Enum.FillDirection.Horizontal; HorizontalAlignment=Enum.HorizontalAlignment.Right; SortOrder=Enum.SortOrder.LayoutOrder; Parent=TLabel })
        local HitW = IsMobile and S(220) or 170
        local HitRegion = Library:Create('Frame', { BackgroundTransparency=1; Size=UDim2.fromOffset(HitW,boxSz); ZIndex=8; Parent=TOuter })
        Library:OnHighlight(HitRegion, TOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, HitRegion) end

        function Toggle:Display()
            TInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
            TInner.BorderColor3     = Toggle.Value and Library.AccentColorDark or Library.OutlineColor
            Library.RegistryMap[TInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor'
            Library.RegistryMap[TInner].Properties.BorderColor3     = Toggle.Value and 'AccentColorDark' or 'OutlineColor'
        end
        function Toggle:UpdateColors() Toggle:Display() end
        function Toggle:OnChanged(fn)  Toggle.Changed = fn; fn(Toggle.Value) end
        function Toggle:SetValue(b)
            b = not not b; Toggle.Value = b; Toggle:Display()
            for _, addon in next, Toggle.Addons do
                if addon.Type == 'KeyPicker' and addon.SyncToggleState then addon.Toggled = b; addon:Update() end
            end
            Library:SafeCallback(Toggle.Callback, b)
            Library:SafeCallback(Toggle.Changed,  b)
            Library:UpdateDependencyBoxes()
        end

        HitRegion.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value); Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(TLabel)
            TLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(TLabel, { TextColor3='RiskColor' })
        end
        Toggle:Display()
        GB:AddBlank(Info.BlankSize or 7); GB:Resize()
        Toggle.TextLabel = TLabel; Toggle.Container = GB.Container
        setmetatable(Toggle, BaseAddons)
        Toggles[Idx] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default ~= nil, 'AddSlider: Missing default.')
        assert(Info.Text,           'AddSlider: Missing text.')
        assert(Info.Min ~= nil,     'AddSlider: Missing min.')
        assert(Info.Max ~= nil,     'AddSlider: Missing max.')
        assert(Info.Rounding ~= nil,'AddSlider: Missing rounding.')
        local Slider = { Value=Info.Default; Min=Info.Min; Max=Info.Max; Rounding=Info.Rounding; MaxSize=S(232); Type='Slider'; Callback=Info.Callback or function() end }
        local GB = self
        if not Info.Compact then
            Library:CreateLabel({ Size=UDim2.new(1,0,0,S(10)); TextSize=S(14); Text=Info.Text; TextXAlignment=Enum.TextXAlignment.Left; TextYAlignment=Enum.TextYAlignment.Bottom; ZIndex=5; Parent=GB.Container })
            GB:AddBlank(3)
        end
        local slH = IsMobile and S(18) or S(13)
        local SOuter = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-S(4),0,slH); ZIndex=5; Parent=GB.Container })
        Library:AddToRegistry(SOuter, { BorderColor3='Black' })
        local SInner = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,1,0); ZIndex=6; Parent=SOuter })
        Library:AddToRegistry(SInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        local Fill = Library:Create('Frame', { BackgroundColor3=Library.AccentColor; BorderColor3=Library.AccentColorDark; Size=UDim2.fromOffset(0,slH); ZIndex=7; Parent=SInner })
        Library:AddToRegistry(Fill, { BackgroundColor3='AccentColor'; BorderColor3='AccentColorDark' })
        local HideBR = Library:Create('Frame', { BackgroundColor3=Library.AccentColor; BorderSizePixel=0; Position=UDim2.new(1,0,0,0); Size=UDim2.new(0,1,1,0); ZIndex=8; Parent=Fill })
        Library:AddToRegistry(HideBR, { BackgroundColor3='AccentColor' })
        local DLabel = Library:CreateLabel({ Size=UDim2.new(1,0,1,0); TextSize=S(13); Text=''; ZIndex=9; Parent=SInner })
        Library:OnHighlight(SOuter, SOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, SOuter) end

        local function Round(v)
            if Slider.Rounding == 0 then return math.floor(v) end
            return tonumber(string.format('%.'..Slider.Rounding..'f', v))
        end
        function Slider:GetValueFromX(x)
            return Round(Library:MapValue(math.clamp(x,0,Slider.MaxSize), 0, Slider.MaxSize, Slider.Min, Slider.Max))
        end
        function Slider:Display()
            local suf = Info.Suffix or ''
            if Info.Compact then DLabel.Text = Info.Text..': '..Slider.Value..suf
            elseif Info.HideMax then DLabel.Text = Slider.Value..suf
            else DLabel.Text = Slider.Value..suf..'/'..Slider.Max..suf end
            local x = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
            Fill.Size = UDim2.fromOffset(x, slH)
            HideBR.Visible = x ~= Slider.MaxSize and x ~= 0
        end
        function Slider:UpdateColors()
            Fill.BackgroundColor3  = Library.AccentColor
            Fill.BorderColor3      = Library.AccentColorDark
        end
        function Slider:OnChanged(fn) Slider.Changed = fn; fn(Slider.Value) end
        function Slider:SetValue(n)
            n = math.clamp(tonumber(n) or Slider.Min, Slider.Min, Slider.Max)
            Slider.Value = n; Slider:Display()
            Library:SafeCallback(Slider.Callback, n)
            Library:SafeCallback(Slider.Changed,  n)
        end

        HandleDrag(SInner, function(x,y)
            local ap = Fill.AbsolutePosition
            local nx = math.clamp(x - ap.X, 0, Slider.MaxSize)
            local nv = Slider:GetValueFromX(nx)
            if nv ~= Slider.Value then
                Slider.Value = nv; Slider:Display()
                Library:SafeCallback(Slider.Callback, nv)
                Library:SafeCallback(Slider.Changed,  nv)
            end
        end, function() Library:AttemptSave() end)

        Slider:Display()
        GB:AddBlank(Info.BlankSize or 6); GB:Resize()
        Options[Idx] = Slider
        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then Info.Values = GetPlayersString(); Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then Info.Values = GetTeamsString(); Info.AllowNull = true end
        assert(Info.Values, 'AddDropdown: Missing Values.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default or AllowNull.')
        if not Info.Text then Info.Compact = true end

        local DD = { Values=Info.Values; Value=Info.Multi and {}; Multi=Info.Multi; Type='Dropdown'; SpecialType=Info.SpecialType; Callback=Info.Callback or function() end }
        local GB = self
        local RelOff = 0

        if not Info.Compact then
            Library:CreateLabel({ Size=UDim2.new(1,0,0,S(10)); TextSize=S(14); Text=Info.Text; TextXAlignment=Enum.TextXAlignment.Left; TextYAlignment=Enum.TextYAlignment.Bottom; ZIndex=5; Parent=GB.Container })
            GB:AddBlank(3)
        end
        for _, el in ipairs(GB.Container:GetChildren()) do
            if not el:IsA('UIListLayout') then RelOff = RelOff + el.Size.Y.Offset end
        end

        local ddH = IsMobile and S(26) or S(20)
        local DOuter = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-S(4),0,ddH); ZIndex=5; Parent=GB.Container })
        Library:AddToRegistry(DOuter, { BorderColor3='Black' })
        local DInner = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,1,0); ZIndex=6; Parent=DOuter })
        Library:AddToRegistry(DInner, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        Library:Create('UIGradient', { Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(212,212,212))}); Rotation=90; Parent=DInner })
        local Arrow = Library:Create('ImageLabel', { AnchorPoint=Vector2.new(0,0.5); BackgroundTransparency=1; Position=UDim2.new(1,-S(16),0.5,0); Size=UDim2.fromOffset(S(12),S(12)); Image='rbxassetid://6282522798'; ZIndex=8; Parent=DInner })
        local ItemLabel = Library:CreateLabel({ Position=UDim2.new(0,S(5),0,0); Size=UDim2.new(1,-S(20),1,0); TextSize=S(13); Text='--'; TextXAlignment=Enum.TextXAlignment.Left; TextWrapped=true; ZIndex=7; Parent=DInner })
        Library:OnHighlight(DOuter, DOuter, { BorderColor3='AccentColor' }, { BorderColor3='Black' })
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip, DOuter) end

        local MAX = IsMobile and 6 or 8
        local itemH = IsMobile and S(26) or S(20)
        local ListOut = Library:Create('Frame', { BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-S(8),0,MAX*itemH+2); ZIndex=20; Visible=false; Parent=GB.Container.Parent })
        local ListIn  = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; BorderSizePixel=0; Size=UDim2.new(1,0,1,0); ZIndex=21; Parent=ListOut })
        Library:AddToRegistry(ListIn, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
        local Scroll = Library:Create('ScrollingFrame', {
            BackgroundTransparency=1; BorderSizePixel=0; CanvasSize=UDim2.new(0,0,0,0); Size=UDim2.new(1,0,1,0); ZIndex=21; Parent=ListIn;
            TopImage='rbxasset://textures/ui/Scroll/scroll-middle.png'; BottomImage='rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollBarThickness=IsMobile and S(6) or 3; ScrollBarImageColor3=Library.AccentColor;
            ScrollingDirection=Enum.ScrollingDirection.Y; ElasticBehavior=Enum.ElasticBehavior.Never;
        })
        Library:AddToRegistry(Scroll, { ScrollBarImageColor3='AccentColor' })
        Library:Create('UIListLayout', { Padding=UDim.new(0,0); FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Scroll })

        local function UpdateListPos()
            ListOut.Position = UDim2.new(0, S(4), 0, RelOff + ddH + (Info.Compact and 0 or S(13)+S(3)) + S(2))
        end
        DOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateListPos)
        UpdateListPos()

        function DD:Display()
            local s = ''
            if Info.Multi then
                for _, v in ipairs(DD.Values) do if DD.Value[v] then s = s..v..', ' end end
                s = s:sub(1,-3)
            else
                s = DD.Value or ''
            end
            ItemLabel.Text = s == '' and '--' or s
        end

        function DD:GetActiveValues()
            if Info.Multi then local t={} for v in next,DD.Value do t[#t+1]=v end; return t
            else return DD.Value and 1 or 0 end
        end

        local Buttons = {}
        function DD:SetValues()
            for _, ch in ipairs(Scroll:GetChildren()) do if not ch:IsA('UIListLayout') then ch:Destroy() end end
            Buttons = {}
            local count = 0
            for _, val in ipairs(DD.Values) do
                count = count + 1
                local BFrame = Library:Create('Frame', { BackgroundColor3=Library.MainColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Middle; Size=UDim2.new(1,-1,0,itemH); ZIndex=23; Active=true; Parent=Scroll })
                Library:AddToRegistry(BFrame, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })
                local BLabel = Library:CreateLabel({ Active=false; Size=UDim2.new(1,-S(6),1,0); Position=UDim2.new(0,S(6),0,0); TextSize=S(13); Text=val; TextXAlignment=Enum.TextXAlignment.Left; ZIndex=25; Parent=BFrame })
                Library:OnHighlight(BFrame, BFrame, { BorderColor3='AccentColor'; ZIndex=24 }, { BorderColor3='OutlineColor'; ZIndex=23 })
                local selected = Info.Multi and DD.Value[val] or (DD.Value == val)
                local function UpdateBtn()
                    selected = Info.Multi and (DD.Value[val] ~= nil) or (DD.Value == val)
                    BLabel.TextColor3 = selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[BLabel].Properties.TextColor3 = selected and 'AccentColor' or 'FontColor'
                end
                BFrame.InputBegan:Connect(function(Input)
                    if not Library:IsPointerInput(Input) then return end
                    local want = not selected
                    if DD:GetActiveValues() == 1 and not want and not Info.AllowNull then return end
                    if Info.Multi then
                        DD.Value[val] = want or nil
                    else
                        DD.Value = want and val or nil
                        for _, b in ipairs(Buttons) do b() end
                    end
                    UpdateBtn(); DD:Display()
                    Library:SafeCallback(DD.Callback, DD.Value)
                    Library:SafeCallback(DD.Changed,  DD.Value)
                    Library:AttemptSave()
                end)
                UpdateBtn(); DD:Display()
                table.insert(Buttons, UpdateBtn)
            end
            local y = math.clamp(count * itemH, 0, MAX * itemH) + 1
            ListOut.Size = UDim2.new(1, -S(8), 0, y)
            Scroll.CanvasSize = UDim2.new(0, 0, 0, count * itemH + 1)
        end

        function DD:OpenDropdown()  ListOut.Visible = true;  Library.OpenedFrames[ListOut] = true;  Arrow.Rotation = 180 end
        function DD:CloseDropdown() ListOut.Visible = false; Library.OpenedFrames[ListOut] = nil;   Arrow.Rotation = 0   end
        function DD:OnChanged(fn)   DD.Changed = fn; fn(DD.Value) end
        function DD:SetValue(val)
            if DD.Multi then
                local t = {}
                for v in next, val do if table.find(DD.Values, v) then t[v] = true end end
                DD.Value = t
            else
                DD.Value = table.find(DD.Values, val) and val or nil
            end
            DD:SetValues()
            Library:SafeCallback(DD.Callback, DD.Value)
            Library:SafeCallback(DD.Changed,  DD.Value)
        end

        DOuter.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                if ListOut.Visible then DD:CloseDropdown() else DD:OpenDropdown() end
            end
        end)
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input) then return end
            local px = IsMobile and Input.Position.X or Mouse.X
            local py = IsMobile and Input.Position.Y or Mouse.Y
            local ap, as = ListOut.AbsolutePosition, ListOut.AbsoluteSize
            if px < ap.X or px > ap.X+as.X or py < ap.Y-ddH-1 or py > ap.Y+as.Y then DD:CloseDropdown() end
        end))

        DD:SetValues()

        local defaults = {}
        if type(Info.Default) == 'string' then
            local i = table.find(DD.Values, Info.Default); if i then defaults[#defaults+1] = i end
        elseif type(Info.Default) == 'table' then
            for _, v in ipairs(Info.Default) do local i = table.find(DD.Values, v); if i then defaults[#defaults+1] = i end end
        elseif type(Info.Default) == 'number' and DD.Values[Info.Default] then
            defaults[#defaults+1] = Info.Default
        end
        for _, i in ipairs(defaults) do
            if Info.Multi then DD.Value[DD.Values[i]] = true else DD.Value = DD.Values[i]; break end
        end
        if #defaults > 0 then DD:SetValues() end
        DD:Display()
        GB:AddBlank(Info.BlankSize or 5); GB:Resize()
        Options[Idx] = DD
        return DD
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} }
        local GB = self
        local Holder = Library:Create('Frame', { BackgroundTransparency=1; Size=UDim2.new(1,0,0,0); Visible=false; Parent=GB.Container })
        local Inner  = Library:Create('Frame', { BackgroundTransparency=1; Size=UDim2.new(1,0,1,0); Parent=Holder })
        local Layout = Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Inner })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1,0,0, Layout.AbsoluteContentSize.Y)
            GB:Resize()
        end
        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)

        function Depbox:Update()
            for _, dep in ipairs(Depbox.Dependencies) do
                if dep[1].Type == 'Toggle' and dep[1].Value ~= dep[2] then
                    Holder.Visible = false; Depbox:Resize(); return
                end
            end
            Holder.Visible = true; Depbox:Resize()
        end
        function Depbox:SetupDependencies(deps)
            Depbox.Dependencies = deps; Depbox:Update()
        end
        Depbox.Container = Inner
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index    = Funcs
    BaseGroupbox.__namecall = function(t, k, ...) return Funcs[k](...) end
end

function Library:CreateWindow(...)
    local args   = { ... }
    local Config = type(args[1]) == 'table' and args[1] or { Title=args[1]; AutoShow=args[2] }
    if type(Config.Title) ~= 'string' then Config.Title = 'Window' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end

    local WinW, WinH
    if IsMobile then
        WinW = math.min(ScreenWidth  - S(16), S(550))
        WinH = math.min(ScreenHeight - S(70), S(600))
        Config.Position  = UDim2.fromOffset(S(8), S(36))
        Config.AnchorPoint = Vector2.zero
    else
        WinW = 550; WinH = 600
        if Config.Center then
            Config.AnchorPoint = Vector2.new(0.5, 0.5)
            Config.Position    = UDim2.fromScale(0.5, 0.5)
        else
            Config.AnchorPoint = Config.AnchorPoint or Vector2.zero
            if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
        end
        if typeof(Config.Size) == 'UDim2' then
            WinW = Config.Size.X.Offset; WinH = Config.Size.Y.Offset
        end
    end

    local Window = { Tabs = {} }

    local Outer = Library:Create('Frame', {
        AnchorPoint          = Config.AnchorPoint;
        BackgroundTransparency = 1;
        BorderSizePixel      = 0;
        Position             = Config.Position;
        Size                 = UDim2.fromOffset(WinW, WinH);
        Visible              = false;
        ZIndex               = 1;
        Parent               = ScreenGui;
    })
    Library:MakeDraggable(Outer, S(25))

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        Position         = UDim2.new(0,1,0,1);
        Size             = UDim2.new(1,-2,1,-2);
        ZIndex           = 1;
        Parent           = Outer;
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' })

    local TitleLabel = Library:CreateLabel({
        Position       = UDim2.new(0,S(7),0,0);
        Size           = UDim2.new(1,0,0,S(25));
        Text           = Config.Title;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 1;
        Parent         = Inner;
    })

    local MSO = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3     = Library.OutlineColor;
        Position         = UDim2.new(0,S(8),0,S(25));
        Size             = UDim2.new(1,-S(16),1,-S(33));
        ZIndex           = 1;
        Parent           = Inner;
    })
    Library:AddToRegistry(MSO, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
    local MSI = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,1,0); ZIndex=1; Parent=MSO })
    Library:AddToRegistry(MSI, { BackgroundColor3='BackgroundColor' })

    local TabArea = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1;
        BorderSizePixel        = 0;
        Position               = UDim2.new(0,S(8),0,S(8));
        Size                   = UDim2.new(1,-S(16),0,S(21));
        CanvasSize             = UDim2.new(0,0,0,0);
        ScrollBarThickness     = 0;
        ScrollingDirection     = Enum.ScrollingDirection.X;
        ZIndex                 = 1;
        Parent                 = MSI;
    })
    local TabLayout = Library:Create('UIListLayout', {
        Padding           = UDim.new(0, Config.TabPadding);
        FillDirection     = Enum.FillDirection.Horizontal;
        SortOrder         = Enum.SortOrder.LayoutOrder;
        Parent            = TabArea;
    })
    TabLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        TabArea.CanvasSize = UDim2.fromOffset(TabLayout.AbsoluteContentSize.X, 0)
    end)

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.OutlineColor;
        Position         = UDim2.new(0,S(8),0,S(30));
        Size             = UDim2.new(1,-S(16),1,-S(38));
        ZIndex           = 2;
        Parent           = MSI;
    })
    Library:AddToRegistry(TabContainer, { BackgroundColor3='MainColor'; BorderColor3='OutlineColor' })

    local sideH = WinH - S(95)

    function Window:SetWindowTitle(t) TitleLabel.Text = t end

    function Window:AddTab(Name)
        local Tab = { Groupboxes={}; Tabboxes={} }

        local tbW = Library:GetTextBounds(Name, Library.Font, S(16)) + S(12)
        local TBtn = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Library.OutlineColor; Size=UDim2.new(0,tbW,1,0); ZIndex=1; Parent=TabArea })
        Library:AddToRegistry(TBtn, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
        Library:CreateLabel({ Size=UDim2.new(1,0,1,-1); Text=Name; ZIndex=1; Parent=TBtn })
        local TUnder = Library:Create('Frame', { BackgroundColor3=Library.AccentColor; BorderSizePixel=0; Position=UDim2.new(0,0,1,-2); Size=UDim2.new(1,0,0,2); Visible=false; ZIndex=3; Parent=TBtn })
        Library:AddToRegistry(TUnder, { BackgroundColor3='AccentColor' })

        local TFrame = Library:Create('Frame', { Name='TabFrame'; BackgroundTransparency=1; Size=UDim2.new(1,0,1,0); Visible=false; ZIndex=2; Parent=TabContainer })

        local function MakeSide(xScale, xOffset)
            local sf = Library:Create('ScrollingFrame', {
                BackgroundTransparency = 1;
                BorderSizePixel        = 0;
                Position               = UDim2.new(xScale, xOffset, 0, S(7));
                Size                   = UDim2.new(0.5, -S(14), 1, -S(7));
                CanvasSize             = UDim2.new(0,0,0,0);
                BottomImage            = '';
                TopImage               = '';
                ScrollBarThickness     = IsMobile and S(5) or 2;
                ScrollBarImageColor3   = Library.AccentColor;
                ScrollingDirection     = Enum.ScrollingDirection.Y;
                ElasticBehavior        = Enum.ElasticBehavior.Never;
                ZIndex                 = 2;
                Parent                 = TFrame;
            })
            Library:AddToRegistry(sf, { ScrollBarImageColor3='AccentColor' })
            local ll = Library:Create('UIListLayout', { Padding=UDim.new(0,S(8)); FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; HorizontalAlignment=Enum.HorizontalAlignment.Center; Parent=sf })
            ll:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                sf.CanvasSize = UDim2.fromOffset(0, ll.AbsoluteContentSize.Y + S(8))
            end)
            return sf
        end
        local LeftSide  = MakeSide(0,   S(7))
        local RightSide = MakeSide(0.5, S(7))

        function Tab:ShowTab()
            for _, t in next, Window.Tabs do t:HideTab() end
            TUnder.Visible = true; TFrame.Visible = true
        end
        function Tab:HideTab()
            TUnder.Visible = false; TFrame.Visible = false
        end
        function Tab:SetLayoutOrder(p) TBtn.LayoutOrder = p; TabLayout:ApplyLayout() end

        function Tab:AddGroupbox(Info2)
            local GB = {}
            local BOut = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,0,S(40)); ZIndex=2; Parent=Info2.Side==1 and LeftSide or RightSide })
            Library:AddToRegistry(BOut, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
            local BIn  = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-2,1,-2); Position=UDim2.new(0,1,0,1); ZIndex=4; Parent=BOut })
            Library:AddToRegistry(BIn, { BackgroundColor3='BackgroundColor' })
            Library:CreateLabel({ Size=UDim2.new(1,0,0,S(18)); Position=UDim2.new(0,S(4),0,S(2)); TextSize=S(14); Text=Info2.Name; TextXAlignment=Enum.TextXAlignment.Left; ZIndex=5; Parent=BIn })
            local Cont = Library:Create('Frame', { BackgroundTransparency=1; Position=UDim2.new(0,S(4),0,S(20)); Size=UDim2.new(1,-S(8),1,-S(20)); ZIndex=1; Parent=BIn })
            Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Cont })

            function GB:Resize()
                local sz = 0
                for _, el in ipairs(GB.Container:GetChildren()) do
                    if not el:IsA('UIListLayout') and el.Visible then sz = sz + el.Size.Y.Offset end
                end
                BOut.Size = UDim2.new(1,0,0, S(20) + sz + 4)
            end
            GB.Container = Cont
            setmetatable(GB, BaseGroupbox)
            GB:AddBlank(3); GB:Resize()
            Tab.Groupboxes[Info2.Name] = GB
            return GB
        end
        function Tab:AddLeftGroupbox(n)  return Tab:AddGroupbox({ Side=1; Name=n }) end
        function Tab:AddRightGroupbox(n) return Tab:AddGroupbox({ Side=2; Name=n }) end

        function Tab:AddTabbox(Info2)
            local Tabbox = { Tabs={} }
            local BOut = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,0,0); ZIndex=2; Parent=Info2.Side==1 and LeftSide or RightSide })
            Library:AddToRegistry(BOut, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
            local BIn = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-2,1,-2); Position=UDim2.new(0,1,0,1); ZIndex=4; Parent=BOut })
            Library:AddToRegistry(BIn, { BackgroundColor3='BackgroundColor' })
            local TabBtns = Library:Create('Frame', { BackgroundTransparency=1; Position=UDim2.new(0,0,0,1); Size=UDim2.new(1,0,0,S(18)); ZIndex=5; Parent=BIn })
            Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Horizontal; SortOrder=Enum.SortOrder.LayoutOrder; Padding=UDim.new(0,0); Parent=TabBtns })

            function Tabbox:AddTab(TabName)
                local TBTab = {}
                local BtnCount = 0
                for _ in next, Tabbox.Tabs do BtnCount = BtnCount + 1 end
                BtnCount = BtnCount + 1

                local Btn = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1/BtnCount,0,1,0); ZIndex=6; Parent=TabBtns })
                Library:AddToRegistry(Btn, { BackgroundColor3='BackgroundColor' })
                local BtnLbl = Library:CreateLabel({ Size=UDim2.new(1,0,1,0); TextSize=S(13); Text=TabName; ZIndex=7; Parent=Btn })
                local Underline = Library:Create('Frame', { BackgroundColor3=Library.AccentColor; BorderSizePixel=0; Position=UDim2.new(0,0,1,-2); Size=UDim2.new(1,0,0,2); Visible=false; ZIndex=8; Parent=Btn })
                Library:AddToRegistry(Underline, { BackgroundColor3='AccentColor' })

                local Cont = Library:Create('Frame', { BackgroundTransparency=1; Position=UDim2.new(0,S(4),0,S(20)); Size=UDim2.new(1,-S(8),1,-S(20)); ZIndex=1; Visible=false; Parent=BIn })
                Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Cont })

                function TBTab:Show()
                    for _, t in next, Tabbox.Tabs do t:Hide() end
                    Cont.Visible = true; Underline.Visible = true
                    TBTab:Resize()
                end
                function TBTab:Hide()
                    Cont.Visible = false; Underline.Visible = false
                end
                function TBTab:Resize()
                    local n = 0
                    for _ in next, Tabbox.Tabs do n = n+1 end
                    for _, ch in ipairs(TabBtns:GetChildren()) do
                        if not ch:IsA('UIListLayout') then ch.Size = UDim2.new(1/n,0,1,0) end
                    end
                    if not Cont.Visible then return end
                    local sz = 0
                    for _, el in ipairs(TBTab.Container:GetChildren()) do
                        if not el:IsA('UIListLayout') and el.Visible then sz = sz + el.Size.Y.Offset end
                    end
                    BOut.Size = UDim2.new(1,0,0, S(20) + sz + 4)
                end

                Btn.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                        TBTab:Show()
                    end
                end)

                TBTab.Container = Cont
                Tabbox.Tabs[TabName] = TBTab
                setmetatable(TBTab, BaseGroupbox)
                TBTab:AddBlank(3)
                TBTab:Resize()
                if BtnCount == 1 then TBTab:Show() end
                return TBTab
            end

            Tab.Tabboxes[Info2.Name or ''] = Tabbox
            return Tabbox
        end
        function Tab:AddLeftTabbox(n)  return Tab:AddTabbox({ Name=n; Side=1 }) end
        function Tab:AddRightTabbox(n) return Tab:AddTabbox({ Name=n; Side=2 }) end

        function Tab:AddSubTabs()
            local SubTabSystem = { Tabs={} }

            local SubArea = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size                   = UDim2.new(1,0,0,S(22));
                ZIndex                 = 3;
                Parent                 = TFrame;
            })
            local SubLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                SortOrder     = Enum.SortOrder.LayoutOrder;
                Padding       = UDim.new(0,0);
                Parent        = SubArea;
            })

            local function MakeSubSide(xScale, xOffset)
                local sf = Library:Create('ScrollingFrame', {
                    BackgroundTransparency = 1;
                    BorderSizePixel        = 0;
                    Position               = UDim2.new(xScale, xOffset, 0, S(30));
                    Size                   = UDim2.new(0.5, -S(14), 1, -S(30));
                    CanvasSize             = UDim2.new(0,0,0,0);
                    BottomImage            = '';
                    TopImage               = '';
                    ScrollBarThickness     = IsMobile and S(5) or 2;
                    ScrollBarImageColor3   = Library.AccentColor;
                    ScrollingDirection     = Enum.ScrollingDirection.Y;
                    ElasticBehavior        = Enum.ElasticBehavior.Never;
                    ZIndex                 = 2;
                    Visible                = false;
                    Parent                 = TFrame;
                })
                Library:AddToRegistry(sf, { ScrollBarImageColor3='AccentColor' })
                local ll = Library:Create('UIListLayout', { Padding=UDim.new(0,S(8)); FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; HorizontalAlignment=Enum.HorizontalAlignment.Center; Parent=sf })
                ll:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    sf.CanvasSize = UDim2.fromOffset(0, ll.AbsoluteContentSize.Y + S(8))
                end)
                return sf
            end

            LeftSide.Visible  = false
            RightSide.Visible = false

            function SubTabSystem:AddTab(SubName)
                local ST = { Groupboxes={}; Tabboxes={} }

                local stW = Library:GetTextBounds(SubName, Library.Font, S(14)) + S(10)
                local STBtn = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Library.OutlineColor; Size=UDim2.new(0,stW,1,0); ZIndex=4; Parent=SubArea })
                Library:AddToRegistry(STBtn, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
                Library:CreateLabel({ Size=UDim2.new(1,0,1,-1); TextSize=S(13); Text=SubName; ZIndex=4; Parent=STBtn })
                local STUnder = Library:Create('Frame', { BackgroundColor3=Library.AccentColor; BorderSizePixel=0; Position=UDim2.new(0,0,1,-2); Size=UDim2.new(1,0,0,2); Visible=false; ZIndex=5; Parent=STBtn })
                Library:AddToRegistry(STUnder, { BackgroundColor3='AccentColor' })

                local STLeft  = MakeSubSide(0,   S(7))
                local STRight = MakeSubSide(0.5, S(7))

                function ST:ShowTab()
                    for _, t in next, SubTabSystem.Tabs do t:HideTab() end
                    STUnder.Visible = true
                    STLeft.Visible  = true
                    STRight.Visible = true
                end
                function ST:HideTab()
                    STUnder.Visible = false
                    STLeft.Visible  = false
                    STRight.Visible = false
                end

                function ST:AddGroupbox(Info3)
                    local GB = {}
                    local BOut = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,0,S(40)); ZIndex=2; Parent=Info3.Side==1 and STLeft or STRight })
                    Library:AddToRegistry(BOut, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
                    local BIn  = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-2,1,-2); Position=UDim2.new(0,1,0,1); ZIndex=4; Parent=BOut })
                    Library:AddToRegistry(BIn, { BackgroundColor3='BackgroundColor' })
                    Library:CreateLabel({ Size=UDim2.new(1,0,0,S(18)); Position=UDim2.new(0,S(4),0,S(2)); TextSize=S(14); Text=Info3.Name; TextXAlignment=Enum.TextXAlignment.Left; ZIndex=5; Parent=BIn })
                    local Cont = Library:Create('Frame', { BackgroundTransparency=1; Position=UDim2.new(0,S(4),0,S(20)); Size=UDim2.new(1,-S(8),1,-S(20)); ZIndex=1; Parent=BIn })
                    Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Cont })
                    function GB:Resize()
                        local sz = 0
                        for _, el in ipairs(GB.Container:GetChildren()) do
                            if not el:IsA('UIListLayout') and el.Visible then sz = sz + el.Size.Y.Offset end
                        end
                        BOut.Size = UDim2.new(1,0,0, S(20) + sz + 4)
                    end
                    GB.Container = Cont
                    setmetatable(GB, BaseGroupbox)
                    GB:AddBlank(3); GB:Resize()
                    ST.Groupboxes[Info3.Name] = GB
                    return GB
                end
                function ST:AddLeftGroupbox(n)  return ST:AddGroupbox({ Side=1; Name=n }) end
                function ST:AddRightGroupbox(n) return ST:AddGroupbox({ Side=2; Name=n }) end

                function ST:AddTabbox(Info3)
                    local Tabbox2 = { Tabs={} }
                    local BOut = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Library.OutlineColor; BorderMode=Enum.BorderMode.Inset; Size=UDim2.new(1,0,0,0); ZIndex=2; Parent=Info3.Side==1 and STLeft or STRight })
                    Library:AddToRegistry(BOut, { BackgroundColor3='BackgroundColor'; BorderColor3='OutlineColor' })
                    local BIn = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1,-2,1,-2); Position=UDim2.new(0,1,0,1); ZIndex=4; Parent=BOut })
                    Library:AddToRegistry(BIn, { BackgroundColor3='BackgroundColor' })
                    local TabBtns2 = Library:Create('Frame', { BackgroundTransparency=1; Position=UDim2.new(0,0,0,1); Size=UDim2.new(1,0,0,S(18)); ZIndex=5; Parent=BIn })
                    Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Horizontal; SortOrder=Enum.SortOrder.LayoutOrder; Padding=UDim.new(0,0); Parent=TabBtns2 })

                    function Tabbox2:AddTab(TN)
                        local TBTab2 = {}
                        local nc = 0; for _ in next, Tabbox2.Tabs do nc=nc+1 end; nc=nc+1
                        local Btn2 = Library:Create('Frame', { BackgroundColor3=Library.BackgroundColor; BorderColor3=Color3.new(0,0,0); Size=UDim2.new(1/nc,0,1,0); ZIndex=6; Parent=TabBtns2 })
                        Library:AddToRegistry(Btn2, { BackgroundColor3='BackgroundColor' })
                        Library:CreateLabel({ Size=UDim2.new(1,0,1,0); TextSize=S(13); Text=TN; ZIndex=7; Parent=Btn2 })
                        local Und2 = Library:Create('Frame', { BackgroundColor3=Library.AccentColor; BorderSizePixel=0; Position=UDim2.new(0,0,1,-2); Size=UDim2.new(1,0,0,2); Visible=false; ZIndex=8; Parent=Btn2 })
                        Library:AddToRegistry(Und2, { BackgroundColor3='AccentColor' })
                        local Cont2 = Library:Create('Frame', { BackgroundTransparency=1; Position=UDim2.new(0,S(4),0,S(20)); Size=UDim2.new(1,-S(8),1,-S(20)); ZIndex=1; Visible=false; Parent=BIn })
                        Library:Create('UIListLayout', { FillDirection=Enum.FillDirection.Vertical; SortOrder=Enum.SortOrder.LayoutOrder; Parent=Cont2 })
                        function TBTab2:Show()
                            for _, t in next, Tabbox2.Tabs do t:Hide() end
                            Cont2.Visible = true; Und2.Visible = true; TBTab2:Resize()
                        end
                        function TBTab2:Hide() Cont2.Visible=false; Und2.Visible=false end
                        function TBTab2:Resize()
                            local n=0; for _ in next,Tabbox2.Tabs do n=n+1 end
                            for _, ch in ipairs(TabBtns2:GetChildren()) do if not ch:IsA('UIListLayout') then ch.Size=UDim2.new(1/n,0,1,0) end end
                            if not Cont2.Visible then return end
                            local sz=0
                            for _, el in ipairs(TBTab2.Container:GetChildren()) do if not el:IsA('UIListLayout') and el.Visible then sz=sz+el.Size.Y.Offset end end
                            BOut.Size = UDim2.new(1,0,0, S(20)+sz+4)
                        end
                        Btn2.InputBegan:Connect(function(Input) if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then TBTab2:Show() end end)
                        TBTab2.Container = Cont2
                        Tabbox2.Tabs[TN] = TBTab2
                        setmetatable(TBTab2, BaseGroupbox)
                        TBTab2:AddBlank(3); TBTab2:Resize()
                        if nc==1 then TBTab2:Show() end
                        return TBTab2
                    end
                    ST.Tabboxes[Info3.Name or ''] = Tabbox2
                    return Tabbox2
                end
                function ST:AddLeftTabbox(n)  return ST:AddTabbox({ Name=n; Side=1 }) end
                function ST:AddRightTabbox(n) return ST:AddTabbox({ Name=n; Side=2 }) end

                STBtn.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) then ST:ShowTab() end
                end)

                SubTabSystem.Tabs[SubName] = ST
                local count = 0; for _ in next, SubTabSystem.Tabs do count=count+1 end
                if count == 1 then ST:ShowTab() end
                return ST
            end

            Tab.SubTabSystem = SubTabSystem
            return SubTabSystem
        end

        TBtn.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then Tab:ShowTab() end
        end)
        local cnt = 0; for _ in next, Window.Tabs do cnt=cnt+1 end
        if cnt == 0 then Tab:ShowTab() end
        Window.Tabs[Name] = Tab
        return Tab
    end

    local Modal = Library:Create('TextButton', { BackgroundTransparency=1; Size=UDim2.new(0,0,0,0); Text=''; Modal=false; Parent=ScreenGui })
    local MenuBlur = Library:Create('BlurEffect', { Name='LibMenuBlur'; Size=0; Parent=Lighting })
    Library.MenuBlur = MenuBlur

    function Library.Toggle()
        Outer.Visible = not Outer.Visible
        Modal.Modal   = Outer.Visible
        if not IsMobile then
            MenuBlur.Size = Outer.Visible and 24 or 0
            local ok, Drawing = pcall(function() return Drawing end)
            if ok and Drawing then
                local Cursor = Drawing.new('Triangle')
                Cursor.Thickness = 1; Cursor.Filled = true
                while Outer.Visible and ScreenGui.Parent do
                    local p = InputService:GetMouseLocation()
                    Cursor.Color  = Library.AccentColor
                    Cursor.PointA = p
                    Cursor.PointB = p + Vector2.new(6, 14)
                    Cursor.PointC = p + Vector2.new(-6, 14)
                    Cursor.Visible = not InputService.MouseIconEnabled
                    RenderStepped:Wait()
                end
                Cursor:Remove()
            end
        end
    end

    if IsMobile then
        local FBtn = Library:Create('TextButton', {
            AnchorPoint      = Vector2.new(1, 0);
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Position         = UDim2.new(1, -S(8), 0, S(8));
            Size             = UDim2.fromOffset(S(46), S(46));
            Text             = '☰';
            TextColor3       = Color3.new(1,1,1);
            TextSize         = S(22);
            Font             = Library.Font;
            ZIndex           = 300;
            Parent           = ScreenGui;
        })
        Library:Create('UICorner', { CornerRadius=UDim.new(0, S(10)); Parent=FBtn })
        Library:AddToRegistry(FBtn, { BackgroundColor3='AccentColor' })
        FBtn.MouseButton1Click:Connect(function() task.spawn(Library.Toggle) end)
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.Touch then return end
            if not Outer.Visible then return end
            task.wait()
            local x, y = Input.Position.X, Input.Position.Y
            local ap, as = Outer.AbsolutePosition, Outer.AbsoluteSize
            if x < ap.X or x > ap.X+as.X or y < ap.Y or y > ap.Y+as.Y then
                if not Library:MouseIsOverOpenedFrame() then
                    Library.Toggle()
                end
            end
        end))
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl
            or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end
    Window.Holder = Outer
    return Window
end

local function OnPlayerChange()
    local list = GetPlayersString()
    for _, v in next, Options do
        if v.Type == 'Dropdown' and v.SpecialType == 'Player' then
            v.Values = list; v:SetValues()
        end
    end
end
Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
