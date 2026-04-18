local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
-- ⬇️ PASTE YOUR NGROK BASE URL HERE
local SERVER_URL = "https://786b-51-75-118-171.ngrok-free.app"
local SERVER_ID = game.JobId
local BUBBLE_SOUND_ID = "rbxassetid://130766061" -- Standard Roblox chat pop

local allowedPlayers = {}
local processedMsgs = {}
local playerBubbles = {}
local isMinimized = false
local isDragging = false
local dragStart = Vector2.new()
local startPos = UDim2.new()

-- ================= GUI SETUP =================
local screen = Instance.new("ScreenGui")
screen.Name = "CoreChat"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main Chat Frame
local chatFrame = Instance.new("Frame")
chatFrame.Name = "ChatFrame"
chatFrame.Size = UDim2.new(0.32, 0, 0.28, 0)
chatFrame.Position = UDim2.new(0.02, 0, 0.05, 0)
chatFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
chatFrame.BackgroundTransparency = 0.25
chatFrame.BorderSizePixel = 0
chatFrame.Parent = screen
local chatCorner = Instance.new("UICorner"); chatCorner.CornerRadius = UDim.new(0, 12); chatCorner.Parent = chatFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.14, 0)
header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
header.BorderSizePixel = 0
header.Parent = chatFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "💬 Chat"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 14
title.Font = Enum.Font.GothamSemibold
title.Parent = header

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.3, 0, 1, 0)
toggleBtn.Position = UDim2.new(0.7, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
toggleBtn.Text = "➖"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = header

-- Scroll History
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ChatHistory"
scroll.Size = UDim2.new(1, 0, 0.68, 0)
scroll.Position = UDim2.new(0, 0, 0.14, 0)
scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scroll.BackgroundTransparency = 0.5
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 4
scroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
scroll.Parent = chatFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 3)
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.VerticalAlignment = Enum.VerticalAlignment.Bottom
list.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6)
pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4)
pad.Parent = scroll

-- Input Area
local inputArea = Instance.new("Frame")
inputArea.Size = UDim2.new(1, 0, 0.18, 0)
inputArea.Position = UDim2.new(0, 0, 0.82, 0)
inputArea.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
inputArea.BorderSizePixel = 0
inputArea.Parent = chatFrame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.75, 0, 0.8, 0)
textBox.Position = UDim2.new(0, 0, 0.1, 0)
textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(230, 230, 230)
textBox.TextSize = 13
textBox.PlaceholderText = "Type message..."
textBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
textBox.Font = Enum.Font.Gotham
textBox.BorderSizePixel = 0
textBox.Parent = inputArea
local textCorner = Instance.new("UICorner"); textCorner.CornerRadius = UDim.new(0, 8); textCorner.Parent = textBox

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
sendBtn.Position = UDim2.new(0.75, 0, 0.1, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(55, 95, 155)
sendBtn.Text = "Send"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 12
sendBtn.Font = Enum.Font.GothamSemibold
sendBtn.BorderSizePixel = 0
sendBtn.Parent = inputArea
local sendCorner = Instance.new("UICorner"); sendCorner.CornerRadius = UDim.new(0, 8); sendCorner.Parent = sendBtn

-- Minimized Floating Icon
local minimizedIcon = Instance.new("TextButton")
minimizedIcon.Name = "ChatIcon"
minimizedIcon.Size = UDim2.new(0, 48, 0, 48)
minimizedIcon.Position = chatFrame.Position
minimizedIcon.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizedIcon.BackgroundTransparency = 0.3
minimizedIcon.Text = "💬"
minimizedIcon.TextSize = 22
minimizedIcon.BorderSizePixel = 0
minimizedIcon.Visible = false
minimizedIcon.Parent = screen
local iconCorner = Instance.new("UICorner"); iconCorner.CornerRadius = UDim.new(1, 0); iconCorner.Parent = minimizedIcon

-- ================= DRAG LOGIC =================
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = chatFrame.Position
    end
end)

header.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        chatFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        minimizedIcon.Position = chatFrame.Position -- keeps icon synced
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- ================= TOGGLE & RESIZE =================
local function updateVisibility()
    if isMinimized then
        chatFrame.Visible = false
        minimizedIcon.Visible = true
    else
        chatFrame.Visible = true
        minimizedIcon.Visible = false
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    updateVisibility()
end)

minimizedIcon.MouseButton1Click:Connect(function()
    isMinimized = false
    updateVisibility()
end)

local function updateSize()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if cam.ViewportSize.X < 800 then
        chatFrame.Size = UDim2.new(0.85, 0, 0.3, 0)
    else
        chatFrame.Size = UDim2.new(0.32, 0, 0.28, 0)
    end
end
updateSize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)

local function autoScroll()
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ================= MESSAGE & BUBBLE LOGIC =================
local function addMessage(username, content)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("[%s]: %s", username, content)
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextSize = 13
    label.Font = Enum.Font.GothamSemibold
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = scroll
    autoScroll()
end

local function playBubbleSound()
    local sound = Instance.new("Sound")
    sound.SoundId = BUBBLE_SOUND_ID
    sound.Volume = 0.35
    sound.Parent = localPlayer
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

local function showBubble(player, text)
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    local head = player.Character.Head
    local stackIndex = playerBubbles[player.Name] or 0
    playerBubbles[player.Name] = stackIndex + 1

    local bubble = Instance.new("BillboardGui")
    bubble.Adornee = head
    bubble.Size = UDim2.new(0, 150, 0, 26)
    bubble.StudsOffset = Vector3.new(0, 2.5 + (stackIndex * 2.5), 0)
    bubble.AlwaysOnTop = true
    bubble.Parent = head

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = bubble
    local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0, 8); bCorner.Parent = bg

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -8, 1, 0)
    txt.Position = UDim2.new(0, 4, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(0, 0, 0)
    txt.TextSize = 14
    txt.Font = Enum.Font.GothamSemibold
    txt.TextWrapped = true
    txt.Parent = bg

    playBubbleSound()

    task.delay(15, function()
        if bubble and bubble.Parent then bubble:Destroy() end
        if playerBubbles[player.Name] then
            playerBubbles[player.Name] = playerBubbles[player.Name] - 1
            if playerBubbles[player.Name] <= 0 then playerBubbles[player.Name] = nil end
        end
    end)
end

-- ================= SYNC & POLL =================
task.spawn(function()
    while true do
        allowedPlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do allowedPlayers[p.Name] = true end
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        local ok, res = pcall(function()
            return HttpService:RequestAsync({
                Url = SERVER_URL .. "/fetch",
                Method = "GET",
                Headers = { ["Ngrok-Skip-Browser-Warning"] = "true" }
            })
        end)

        if ok and res.StatusCode == 200 then
            local data = HttpService:JSONDecode(res.Body)
            for _, msg in ipairs(data) do
                if not processedMsgs[msg.timestamp] and allowedPlayers[msg.username] and msg.serverId == SERVER_ID then
                    processedMsgs[msg.timestamp] = true
                    addMessage(msg.username, msg.message)
                    local target = Players:FindFirstChild(msg.username)
                    if target then showBubble(target, msg.message) end
                end
            end
        end
        task.wait(1)
    end
end)

-- ================= SEND =================
local function sendMsg()
    local txt = textBox.Text:gsub("^%s*(.-)%s*$", "%1")
    if txt == "" then return end

    pcall(function()
        HttpService:RequestAsync({
            Url = SERVER_URL .. "/send",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Ngrok-Skip-Browser-Warning"] = "true"
            },
            Body = HttpService:JSONEncode({
                username = localPlayer.Name,
                message = txt,
                serverId = SERVER_ID
            })
        })
    end)
    textBox.Text = ""
end

sendBtn.MouseButton1Click:Connect(sendMsg)
textBox.FocusLost:Connect(function(enter) if enter then sendMsg() end end)

updateVisibility()
