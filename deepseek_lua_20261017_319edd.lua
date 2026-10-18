-- ============================================
-- KUKIRIN DELIVERY HUB v4.0 - Dark Modern
-- by Mattix
-- ============================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local FD = RS:WaitForChild("Remotes"):WaitForChild("FoodDelivery")

local pickup = Vector3.new(1430.30, 61.18, -606.11)

-- ============================================
-- CONFIG (tempi ORIGINALI)
-- ============================================
local CONFIG = {
    teleportDelay = 2,
    deliverRetry = 3,
    customerPoll = 0.25,
    customerTimeout = 30,
    loopPause = 0.25,
}

-- ============================================
-- STATE
-- ============================================
local running = false
local closed = false
local loopActive = false

-- GUI parent
local guiParent
pcall(function()
    if typeof(gethui) == "function" then
        guiParent = gethui()
    end
end)
if not guiParent then
    guiParent = game:GetService("CoreGui")
end

pcall(function()
    local old = guiParent:FindFirstChild("MattixDelivery")
    if old then old:Destroy() end
end)

-- ============================================
-- COLORS - Dark Modern
-- ============================================
local C = {
    bg        = Color3.fromRGB(18, 18, 22),
    bgElev    = Color3.fromRGB(28, 28, 34),
    bgHover   = Color3.fromRGB(38, 38, 46),
    border    = Color3.fromRGB(55, 55, 65),
    accent    = Color3.fromRGB(0, 200, 255),      -- cyan
    accentDim = Color3.fromRGB(0, 140, 180),
    green     = Color3.fromRGB(60, 200, 120),
    red       = Color3.fromRGB(230, 70, 90),
    text      = Color3.fromRGB(240, 240, 245),
    textDim   = Color3.fromRGB(150, 150, 160),
    textMute  = Color3.fromRGB(100, 100, 110),
}

-- ============================================
-- GUI
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "MattixDelivery"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

-- ============================================
-- FLOATING BUTTON (clean, no image)
-- ============================================
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0, 20, 0.5, -25)
floatBtn.BackgroundColor3 = C.bgElev
floatBtn.Text = "D"
floatBtn.TextColor3 = C.accent
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 20
floatBtn.AutoButtonColor = false
floatBtn.Parent = gui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = C.accent
floatStroke.Thickness = 2
floatStroke.Transparency = 0.3
floatStroke.Parent = floatBtn

floatBtn.MouseEnter:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.bgHover}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.bgElev}):Play()
end)

-- Drag floating
local dragToggle, dragStart, startPosF
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = true
        dragStart = input.Position
        startPosF = floatBtn.Position
    end
end)
floatBtn.InputChanged:Connect(function(input)
    if dragToggle and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        floatBtn.Position = UDim2.new(startPosF.X.Scale, startPosF.X.Offset + delta.X, startPosF.Y.Scale, startPosF.Y.Offset + delta.Y)
    end
end)
floatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = false
    end
end)

-- ============================================
-- MAIN WINDOW
-- ============================================
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 300, 0, 260)
main.Position = UDim2.new(0.5, -150, 0.5, -130)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Visible = false
main.Active = true
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = C.border
mainStroke.Thickness = 1
mainStroke.Parent = main

-- Subtle gradient overlay
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
}
grad.Rotation = 90
grad.Parent = main

-- ============================================
-- HEADER
-- ============================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = C.bgElev
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Accent line under header
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, -2)
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 2
accentLine.Parent = header

local accentGrad = Instance.new("UIGradient")
accentGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1)
}
accentGrad.Parent = accentLine

-- Status dot in header
local headerDot = Instance.new("Frame")
headerDot.Size = UDim2.new(0, 8, 0, 8)
headerDot.Position = UDim2.new(0, 14, 0.5, -4)
headerDot.BackgroundColor3 = C.textMute
headerDot.BorderSizePixel = 0
headerDot.Parent = header

local headerDotCorner = Instance.new("UICorner")
headerDotCorner.CornerRadius = UDim.new(1, 0)
headerDotCorner.Parent = headerDot

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.fromOffset(30, 0)
title.BackgroundTransparency = 1
title.Text = "DELIVERY HUB"
title.TextColor3 = C.text
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Credit
local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1, -100, 1, 0)
credit.Position = UDim2.fromOffset(140, 0)
credit.BackgroundTransparency = 1
credit.Text = "by Mattix"
credit.TextColor3 = C.textMute
credit.Font = Enum.Font.Gotham
credit.TextSize = 10
credit.TextXAlignment = Enum.TextXAlignment.Left
credit.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
closeBtn.BackgroundColor3 = C.bgHover
closeBtn.Text = "X"
closeBtn.TextColor3 = C.textDim
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.red, TextColor3 = Color3.new(1,1,1)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.bgHover, TextColor3 = C.textDim}):Play()
end)

-- ============================================
-- CONTENT
-- ============================================
-- Section label
local sectionLabel = Instance.new("TextLabel")
sectionLabel.Size = UDim2.new(1, -28, 0, 16)
sectionLabel.Position = UDim2.fromOffset(14, 50)
sectionLabel.BackgroundTransparency = 1
sectionLabel.Text = "CONTROLS"
sectionLabel.TextColor3 = C.textMute
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.TextSize = 9
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = main

-- Toggle button
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -28, 0, 46)
toggle.Position = UDim2.fromOffset(14, 70)
toggle.BackgroundColor3 = C.accentDim
toggle.Text = "START DELIVERY"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.AutoButtonColor = false
toggle.Parent = main

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = C.accent
toggleStroke.Thickness = 1
toggleStroke.Transparency = 0.4
toggleStroke.Parent = toggle

toggle.MouseEnter:Connect(function()
    if not running then
        TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = C.accent}):Play()
    else
        TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 230, 140)}):Play()
    end
end)
toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = running and C.green or C.accentDim}):Play()
end)

-- Status box
local statusBox = Instance.new("Frame")
statusBox.Size = UDim2.new(1, -28, 0, 34)
statusBox.Position = UDim2.fromOffset(14, 124)
statusBox.BackgroundColor3 = C.bgElev
statusBox.BorderSizePixel = 0
statusBox.Parent = main

local statusBoxCorner = Instance.new("UICorner")
statusBoxCorner.CornerRadius = UDim.new(0, 8)
statusBoxCorner.Parent = statusBox

local statusBoxStroke = Instance.new("UIStroke")
statusBoxStroke.Color = C.border
statusBoxStroke.Thickness = 1
statusBoxStroke.Transparency = 0.5
statusBoxStroke.Parent = statusBox

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 12, 0.5, -3)
statusDot.BackgroundColor3 = C.textMute
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBox

local statusDotCorner = Instance.new("UICorner")
statusDotCorner.CornerRadius = UDim.new(1, 0)
statusDotCorner.Parent = statusDot

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 1, 0)
status.Position = UDim2.fromOffset(26, 0)
status.BackgroundTransparency = 1
status.Text = "Idle"
status.TextColor3 = C.textDim
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = statusBox

local function setStatus(msg, color)
    if not closed and status.Parent then
        status.Text = msg
        statusDot.BackgroundColor3 = color or C.textMute
    end
end

-- ============================================
-- STATS ROW
-- ============================================
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -28, 0, 50)
statsFrame.Position = UDim2.fromOffset(14, 166)
statsFrame.BackgroundColor3 = C.bgElev
statsFrame.BorderSizePixel = 0
statsFrame.Parent = main

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsFrame

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = C.border
statsStroke.Thickness = 1
statsStroke.Transparency = 0.5
statsStroke.Parent = statsFrame

-- Stats column helper
local function makeStat(x, label, value)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 80, 0, 14)
    lbl.Position = UDim2.fromOffset(x, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.textMute
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = statsFrame

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 80, 0, 18)
    val.Position = UDim2.fromOffset(x, 24)
    val.BackgroundTransparency = 1
    val.Text = value
    val.TextColor3 = C.text
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.Parent = statsFrame

    return val
end

local statDeliveries = makeStat(12, "DELIVERIES", "0")
local statTime       = makeStat(104, "TIME", "00:00")
local statRate       = makeStat(196, "RATE", "0/min")

-- ============================================
-- DRAG WINDOW
-- ============================================
local dragging = false
local dragStart
local startPos
local dragInput

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput and not closed then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================
-- OPEN / CLOSE
-- ============================================
local menuOpen = false

local function openMenu()
    if menuOpen then return end
    menuOpen = true
    main.Visible = true
    main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 260)
    }):Play()
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    local t = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    })
    t:Play()
    t.Completed:Wait()
    main.Visible = false
end

floatBtn.MouseButton1Click:Connect(function()
    if menuOpen then closeMenu() else openMenu() end
end)
closeBtn.MouseButton1Click:Connect(closeMenu)

-- ============================================
-- DELIVERY LOGIC
-- ============================================
local deliveriesDone = 0
local startTime = 0

local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function teleport(pos)
    if not running or closed then return false end
    local ok, err = pcall(function()
        getRoot().CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end)
    if not ok then
        warn("Teleport error:", err)
        return false
    end
    task.wait(CONFIG.teleportDelay)
    return running and not closed
end

local function invoke(name)
    if not running or closed then return false end
    local ok, result = pcall(function()
        return FD:WaitForChild(name):InvokeServer()
    end)
    return ok and result == true
end

local function readCustomerPosition()
    local customer = workspace:FindFirstChild("DeliveryCustomer")
    if not customer then return nil end
    if customer:IsA("Model") then
        return customer:GetPivot().Position
    elseif customer:IsA("BasePart") then
        return customer.Position
    end
    return nil
end

local function waitForCustomer()
    local deadline = os.clock() + CONFIG.customerTimeout
    repeat
        if not running or closed then return nil end
        local pos = readCustomerPosition()
        if pos then return pos end
        task.wait(CONFIG.customerPoll)
    until os.clock() >= deadline
    return nil
end

local function startLoop()
    if loopActive then return end
    loopActive = true
    if startTime == 0 then startTime = tick() end

    task.spawn(function()
        while running and not closed do
            setStatus("Going to pickup...", C.accent)
            if not teleport(pickup) then break end

            if not invoke("Start") then
                setStatus("Pickup failed, retrying", C.red)
                task.wait(3)
                continue
            end

            setStatus("Waiting for customer...", C.accent)
            local customerPos = waitForCustomer()
            if not running or closed then break end
            if not customerPos then
                setStatus("Customer not found", C.red)
                task.wait(3)
                continue
            end

            setStatus("Travelling to customer...", C.accent)
            if not teleport(customerPos) then break end

            setStatus("Delivering...", C.accent)

            while running and not closed do
                if invoke("Deliver") then
                    deliveriesDone = deliveriesDone + 1
                    statDeliveries.Text = tostring(deliveriesDone)
                    setStatus("Delivery complete", C.green)
                    break
                end

                local updatedPos = readCustomerPosition()
                if updatedPos then
                    local ok, root = pcall(getRoot)
                    if ok and (root.Position - updatedPos).Magnitude > 10 then
                        setStatus("Following customer...", C.accent)
                        if not teleport(updatedPos) then break end
                    end
                end

                task.wait(CONFIG.deliverRetry)
            end

            if running and not closed then
                task.wait(0.25)
            end
        end

        loopActive = false
        if not closed then
            running = false
            toggle.Text = "START DELIVERY"
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = C.accentDim}):Play()
            setStatus("Idle", C.textMute)
        end
    end)
end

-- ============================================
-- STATS UPDATE
-- ============================================
task.spawn(function()
    while not closed and gui.Parent do
        if running and startTime > 0 then
            local elapsed = tick() - startTime
            local mins = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            statTime.Text = string.format("%02d:%02d", mins, secs)
            if elapsed > 0 then
                local rate = (deliveriesDone / elapsed) * 60
                statRate.Text = string.format("%.1f/min", rate)
            end
        end
        task.wait(1)
    end
end)

-- ============================================
-- TOGGLE
-- ============================================
toggle.MouseButton1Click:Connect(function()
    if closed then return end
    running = not running

    if running then
        toggle.Text = "STOP DELIVERY"
        TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = C.green}):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 255, 160)}):Play()
        setStatus("Starting...", C.accent)
        startLoop()
    else
        toggle.Text = "START DELIVERY"
        TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = C.accentDim}):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {Color = C.accent}):Play()
        setStatus("Stopping...", C.textMute)
    end
end)

print("[Mattix] Delivery Hub v4.0 loaded")