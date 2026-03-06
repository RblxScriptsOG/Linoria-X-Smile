-- Mobile Support Configuration
local function GetDeviceType()
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    
    -- Check for mobile indicators
    local IsMobile = UserInputService.TouchEnabled 
        and not UserInputService.KeyboardEnabled 
        and not UserInputService.MouseEnabled
    
    local IsConsole = UserInputService.GamepadEnabled 
        and not UserInputService.TouchEnabled
    
    local IsPC = not IsMobile and not IsConsole
    
    return {
        IsMobile = IsMobile,
        IsConsole = IsConsole,
        IsPC = IsPC,
        Platform = IsMobile and "Mobile" or IsConsole and "Console" or "PC"
    }
end

local DeviceInfo = GetDeviceType()
local ViewportSize = workspace.CurrentCamera.ViewportSize

-- Scale factors for different devices
local ScaleFactors = {
    Mobile = {
        WindowScale = 0.9,      -- 90% of screen width
        HeightScale = 0.8,      -- 80% of screen height
        FontScale = 0.85,       -- Slightly smaller fonts
        ElementScale = 0.9,     -- Scale UI elements
        MinWidth = 280,         -- Minimum window width
        MinHeight = 350,        -- Minimum window height
    },
    PC = {
        WindowScale = 1,
        HeightScale = 1,
        FontScale = 1,
        ElementScale = 1,
        MinWidth = 550,         -- Default PC size
        MinHeight = 600,
    }
}

-- Get appropriate scale factor
local CurrentScale = DeviceInfo.IsMobile and ScaleFactors.Mobile or ScaleFactors.PC

-- Calculate optimal window size
local function CalculateWindowSize()
    local screenWidth = ViewportSize.X
    local screenHeight = ViewportSize.Y
    
    if DeviceInfo.IsMobile then
        -- For mobile: use most of the screen but keep margins
        local width = math.max(CurrentScale.MinWidth, screenWidth * CurrentScale.WindowScale)
        local height = math.max(CurrentScale.MinHeight, screenHeight * CurrentScale.HeightScale)
        
        -- Ensure it fits on screen
        width = math.min(width, screenWidth - 20)
        height = math.min(height, screenHeight - 40)
        
        return UDim2.fromOffset(width, height)
    else
        -- For PC: use default size or scaled if screen is small
        local width = math.max(CurrentScale.MinWidth, math.min(550, screenWidth * 0.8))
        local height = math.max(CurrentScale.MinHeight, math.min(600, screenHeight * 0.8))
        
        return UDim2.fromOffset(width, height)
    end
end

-- Calculate position (centered)
local function CalculateWindowPosition()
    local size = CalculateWindowSize()
    if DeviceInfo.IsMobile then
        -- Center on mobile
        return UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    else
        -- Default PC position
        return UDim2.fromOffset(175, 50)
    end
end

-- Mobile-optimized font sizes
local MobileFontSizes = {
    Title = DeviceInfo.IsMobile and 16 or 16,
    Tab = DeviceInfo.IsMobile and 14 or 16,
    Label = DeviceInfo.IsMobile and 13 or 14,
    Button = DeviceInfo.IsMobile and 14 or 14,
    Slider = DeviceInfo.IsMobile and 13 or 14,
    Dropdown = DeviceInfo.IsMobile and 13 or 14,
    Input = DeviceInfo.IsMobile and 13 or 14,
    Notification = DeviceInfo.IsMobile and 13 or 14,
}

-- Override CreateWindow to support mobile
local OriginalCreateWindow = Library.CreateWindow
Library.CreateWindow = function(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }
    
    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end
    
    -- Apply mobile optimizations
    if DeviceInfo.IsMobile then
        Config.Center = true
        Config.Size = CalculateWindowSize()
        Config.Position = CalculateWindowPosition()
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        
        -- Adjust tab padding for smaller screens
        if type(Config.TabPadding) ~= 'number' then 
            Config.TabPadding = 2 
        end
    else
        -- PC defaults
        if typeof(Config.Position) ~= 'UDim2' then 
            Config.Position = UDim2.fromOffset(175, 50) 
        end
        if typeof(Config.Size) ~= 'UDim2' then 
            Config.Size = UDim2.fromOffset(550, 600) 
        end
        if Config.Center then
            Config.AnchorPoint = Vector2.new(0.5, 0.5)
            Config.Position = UDim2.fromScale(0.5, 0.5)
        end
    end
    
    -- Create the window
    local Window = OriginalCreateWindow(Config)
    
    -- Mobile-specific adjustments after creation
    if DeviceInfo.IsMobile and Window.Holder then
        -- Ensure window stays on screen
        local function ConstrainToScreen()
            local holder = Window.Holder
            if not holder then return end
            
            local absPos = holder.AbsolutePosition
            local absSize = holder.AbsoluteSize
            local screenSize = workspace.CurrentCamera.ViewportSize
            
            local newX = math.clamp(absPos.X, 0, math.max(0, screenSize.X - absSize.X))
            local newY = math.clamp(absPos.Y, 0, math.max(0, screenSize.Y - absSize.Y))
            
            if newX ~= absPos.X or newY ~= absPos.Y then
                holder.Position = UDim2.fromOffset(newX, newY)
            end
        end
        
        -- Connect to size changes
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if Window.Holder and Window.Holder.Visible then
                local newSize = CalculateWindowSize()
                Window.Holder.Size = newSize
                Window.Holder.Position = UDim2.new(0.5, -newSize.X.Offset / 2, 0.5, -newSize.Y.Offset / 2)
            end
        end)
        
        -- Make drag handle larger on mobile for easier touch
        -- This is handled in the MakeDraggable function
    end
    
    return Window
end

-- Override MakeDraggable for better mobile support
local OriginalMakeDraggable = Library.MakeDraggable
Library.MakeDraggable = function(Instance, Cutoff)
    if DeviceInfo.IsMobile then
        -- Increase touch area for mobile
        local TouchHandle = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, math.max(Cutoff or 40, 50)), -- Larger touch area
            ZIndex = Instance.ZIndex + 1,
            Parent = Instance,
        })
        
        -- Visual indicator for drag area on mobile
        local DragIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, -20, 0, 8),
            Size = UDim2.new(0, 40, 0, 4),
            ZIndex = Instance.ZIndex + 2,
            Parent = TouchHandle,
        })
        Library:AddToRegistry(DragIndicator, { BackgroundColor3 = 'AccentColor' })
        
        Instance.Active = true
        
        TouchHandle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ObjPos = Vector2.new(
                    Input.Position.X - Instance.AbsolutePosition.X,
                    Input.Position.Y - Instance.AbsolutePosition.Y
                )
                
                -- Only drag if touching the top area
                if ObjPos.Y > (Cutoff or 50) then
                    return
                end
                
                local Dragging = true
                
                local Connection
                Connection = RunService.RenderStepped:Connect(function()
                    if not Dragging then
                        Connection:Disconnect()
                        return
                    end
                    
                    -- Get current input position
                    local currentPos = Input.Position
                    
                    local newX = currentPos.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X)
                    local newY = currentPos.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                    
                    -- Constrain to screen bounds
                    local screenSize = workspace.CurrentCamera.ViewportSize
                    local absSize = Instance.AbsoluteSize
                    
                    newX = math.clamp(newX, 0, math.max(0, screenSize.X - absSize.X))
                    newY = math.clamp(newY, 0, math.max(0, screenSize.Y - absSize.Y))
                    
                    Instance.Position = UDim2.new(0, newX, 0, newY)
                end)
                
                local EndConnection
                EndConnection = InputService.InputEnded:Connect(function(endInput)
                    if endInput == Input then
                        Dragging = false
                        EndConnection:Disconnect()
                    end
                end)
            end
        end)
    else
        -- Use original PC drag behavior
        OriginalMakeDraggable(Instance, Cutoff)
    end
end

-- Touch-friendly input handling for buttons and toggles
local function MakeTouchFriendly(Instance)
    if not DeviceInfo.IsMobile then return end
    
    local OriginalInputBegan = Instance.InputBegan
    
    -- Increase touch area if needed
    if Instance:IsA("GuiObject") then
        -- Ensure minimum touch size (44x44 points is iOS standard)
        local minTouchSize = 44
        if Instance.AbsoluteSize.X < minTouchSize or Instance.AbsoluteSize.Y < minTouchSize then
            local TouchExpander = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, math.max(Instance.AbsoluteSize.X, minTouchSize), 
                               0, math.max(Instance.AbsoluteSize.Y, minTouchSize)),
                Position = UDim2.new(0.5, -math.max(Instance.AbsoluteSize.X, minTouchSize) / 2,
                                   0.5, -math.max(Instance.AbsoluteSize.Y, minTouchSize) / 2),
                ZIndex = Instance.ZIndex,
                Parent = Instance,
            })
        end
    end
end

-- Mobile toggle button (optional floating button)
Library.MobileToggleButton = nil

function Library.CreateMobileToggleButton(Info)
    if not DeviceInfo.IsMobile then return nil end
    
    Info = Info or {}
    local Size = Info.Size or UDim2.fromOffset(50, 50)
    local Position = Info.Position or UDim2.new(0, 10, 0.5, -25)
    local Icon = Info.Icon or "☰" -- Hamburger menu
    
    local ButtonOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = Position,
        Size = Size,
        ZIndex = 1000,
        Parent = ScreenGui,
    })
    
    local ButtonInner = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(1, -4, 1, -4),
        ZIndex = 1001,
        Parent = ButtonOuter,
    })
    
    local ButtonLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 1, 0),
        Text = Icon,
        TextSize = 24,
        ZIndex = 1002,
        Parent = ButtonInner,
    })
    
    Library:AddToRegistry(ButtonOuter, { 
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor'
    })
    Library:AddToRegistry(ButtonInner, { BackgroundColor3 = 'AccentColor' })
    
    -- Make it draggable
    local Dragging = false
    local DragStart = nil
    local StartPos = nil
    
    ButtonOuter.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = Input.Position
            StartPos = ButtonOuter.Position
            
            local MoveConnection
            MoveConnection = InputService.InputChanged:Connect(function(moveInput)
                if moveInput == Input and Dragging then
                    local Delta = Input.Position - DragStart
                    ButtonOuter.Position = UDim2.new(
                        StartPos.X.Scale, 
                        StartPos.X.Offset + Delta.X,
                        StartPos.Y.Scale, 
                        StartPos.Y.Offset + Delta.Y
                    )
                end
            end)
            
            local EndConnection
            EndConnection = InputService.InputEnded:Connect(function(endInput)
                if endInput == Input then
                    Dragging = false
                    MoveConnection:Disconnect()
                    EndConnection:Disconnect()
                    
                    -- Check if it was a tap (minimal movement) vs drag
                    local Delta = Input.Position - DragStart
                    if Delta.Magnitude < 10 then
                        -- It was a tap, toggle menu
                        Library.Toggle()
                    end
                end
            end)
        end
    end)
    
    Library.MobileToggleButton = ButtonOuter
    return ButtonOuter
end

-- Auto-create mobile toggle button on mobile devices
if DeviceInfo.IsMobile then
    -- Delay creation so user can customize if needed
    task.delay(0.1, function()
        if not Library.MobileToggleButton then
            Library.CreateMobileToggleButton({
                Position = UDim2.new(0, 10, 0.5, -25),
                Size = UDim2.fromOffset(50, 50)
            })
        end
    end)
end

-- Enhanced Toggle function for mobile
local OriginalToggle = Library.Toggle
Library.Toggle = function()
    OriginalToggle()
    
    -- Update mobile button visibility
    if Library.MobileToggleButton then
        Library.MobileToggleButton.Visible = not Outer.Visible
    end
    
    -- Ensure window is properly positioned when showing on mobile
    if DeviceInfo.IsMobile and Outer.Visible then
        local screenSize = workspace.CurrentCamera.ViewportSize
        local windowSize = Outer.AbsoluteSize
        
        -- Recenter if needed
        Outer.Position = UDim2.new(
            0.5, -windowSize.X / 2,
            0.5, -windowSize.Y / 2
        )
    end
end

-- Export device info for scripts to use
Library.DeviceInfo = DeviceInfo
Library.IsMobile = DeviceInfo.IsMobile
Library.IsPC = DeviceInfo.IsPC

-- Function to manually set mobile mode (for testing)
function Library.ForceMobileMode(Enabled)
    DeviceInfo.IsMobile = Enabled
    DeviceInfo.IsPC = not Enabled
    CurrentScale = Enabled and ScaleFactors.Mobile or ScaleFactors.PC
end

print(string.format("[LinoriaLib] Device detected: %s (Screen: %dx%d)", 
    DeviceInfo.Platform, 
    ViewportSize.X, 
    ViewportSize.Y))

return Library
