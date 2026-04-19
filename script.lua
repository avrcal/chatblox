local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local SERVER_ID = game.JobId
local DISCORD_TOKEN = "MTE3NTcxNzUxMzA5OTc1MTQ3NQ.GRPVw5.RmuEAtYUdm3yeGgT5-aFsScBdBrc-xxW78l2rc"
local CHANNEL_ID = "1495385003482157128"
local DISCORD_API = "https://discord.com/api/v10"
local MAX_CHARS = 600

local HEADERS = {
    ["Authorization"] = DISCORD_TOKEN,
    ["Content-Type"] = "application/json"
}

local processedIds = {}
local playerBubbles = {}
local lastMsgId = nil
local initDone = false
local isMinimized = false
local isDragging = false
local dragStart = Vector2.new()
local startPos = UDim2.new()

-- GUI SETUP
local screen = Instance.new("ScreenGui")
screen.Name = "Chatbox"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = localPlayer:WaitForChild("PlayerGui")

local chatFrame = Instance.new("Frame")
chatFrame.Name = "ChatboxFrame"
chatFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
chatFrame.BorderSizePixel = 0
chatFrame.Parent = screen

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = chatFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
header.BorderSizePixel = 0
header.Parent = chatFrame

local title = Instance.new("TextLabel")title.Size = UDim2.new(0.7, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Chat"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.TextSize = 14
title.Font = Enum.Font.GothamSemibold
title.Parent = header

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.3, 0, 1, 0)
toggleBtn.Position = UDim2.new(0.7, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
toggleBtn.Text = "v"
toggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = header

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "History"
scroll.Size = UDim2.new(1, 0, 0.7, 0)
scroll.Position = UDim2.new(0, 0, 0.12, 0)
scroll.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
scroll.BackgroundTransparency = 0.4
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 3
scroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
scroll.Parent = chatFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 2)
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.VerticalAlignment = Enum.VerticalAlignment.Bottom
list.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 6)
pad.PaddingRight = UDim.new(0, 6)
pad.PaddingTop = UDim.new(0, 3)
pad.PaddingBottom = UDim.new(0, 3)
pad.Parent = scroll

local inputArea = Instance.new("Frame")
inputArea.Size = UDim2.new(1, 0, 0.18, 0)
inputArea.Position = UDim2.new(0, 0, 0.82, 0)
inputArea.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
inputArea.BorderSizePixel = 0
inputArea.Parent = chatFrame
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.72, 0, 0.8, 0)
textBox.Position = UDim2.new(0, 0, 0.1, 0)
textBox.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(230, 230, 230)
textBox.TextSize = 13
textBox.PlaceholderText = "Message..."
textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
textBox.Font = Enum.Font.Gotham
textBox.BorderSizePixel = 0
textBox.Parent = inputArea

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 6)
corner2.Parent = textBox

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0.22, 0, 0.8, 0)
sendBtn.Position = UDim2.new(0.73, 0, 0.1, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
sendBtn.Text = "Send"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 12
sendBtn.Font = Enum.Font.GothamSemibold
sendBtn.BorderSizePixel = 0
sendBtn.Parent = inputArea

local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 6)
corner3.Parent = sendBtn

local charLabel = Instance.new("TextLabel")
charLabel.Size = UDim2.new(1, -10, 0, 14)
charLabel.Position = UDim2.new(0, 5, 0, -16)
charLabel.BackgroundTransparency = 1
charLabel.Text = "0/" .. tostring(MAX_CHARS)
charLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
charLabel.TextSize = 10
charLabel.Font = Enum.Font.Gotham
charLabel.TextXAlignment = Enum.TextXAlignment.Right
charLabel.Parent = inputArea

local minimizeIcon = Instance.new("TextButton")
minimizeIcon.Name = "OpenChat"
minimizeIcon.Size = UDim2.new(0, 40, 0, 40)
minimizeIcon.Position = chatFrame.Position
minimizeIcon.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
minimizeIcon.BackgroundTransparency = 0.3
minimizeIcon.Text = "Open"minimizeIcon.TextColor3 = Color3.fromRGB(200, 200, 200)
minimizeIcon.TextSize = 12
minimizeIcon.BorderSizePixel = 0
minimizeIcon.Visible = false
minimizeIcon.Parent = screen

local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(1, 0)
corner4.Parent = minimizeIcon

-- DRAG LOGIC
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
        minimizeIcon.Position = chatFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

local function updateVisibility()
    chatFrame.Visible = not isMinimized
    minimizeIcon.Visible = isMinimized
end

toggleBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    updateVisibility()
end)

minimizeIcon.MouseButton1Click:Connect(function()
    isMinimized = false
    updateVisibility()
end)

local function updateLayout()
    local cam = workspace.CurrentCamera    if not cam then
        return
    end
    local w = cam.ViewportSize.X
    if w < 800 then
        chatFrame.Size = UDim2.new(0.9, 0, 0.38, 0)
        chatFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
    else
        chatFrame.Size = UDim2.new(0.3, 0, 0.28, 0)
        chatFrame.Position = UDim2.new(0.02, 0, 0.05, 0)
    end
end

updateLayout()

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)

local function scrollToBottom()
    task.defer(function()
        if scroll then
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end
    end)
end

-- INPUT LIMIT
textBox:GetPropertyChangedSignal("Text"):Connect(function()
    local len = #textBox.Text
    if len > MAX_CHARS then
        textBox.Text = textBox.Text:sub(1, MAX_CHARS)
        len = MAX_CHARS
    end
    charLabel.Text = tostring(len) .. "/" .. tostring(MAX_CHARS)
    if len >= MAX_CHARS then
        charLabel.TextColor3 = Color3.fromRGB(200, 70, 70)
    else
        charLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
    end
end)

-- CHAT FUNCTIONS
local function addChatMessage(username, content)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "[" .. username .. "]: " .. content
    label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextSize = 13
    label.Font = Enum.Font.GothamSemibold
    label.TextWrapped = true    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = scroll
    scrollToBottom()
end

local function getBubbleSize(text)
    local count = 0
    for word in text:gmatch("%S+") do
        count = count + 1
    end
    if count <= 3 then
        return 18, UDim2.new(0, 130, 0, 34)
    elseif count <= 7 then
        return 15, UDim2.new(0, 160, 0, 38)
    else
        return 13, UDim2.new(0, 200, 0, 44)
    end
end

local function showBubble(player, text)
    if not player.Character then
        return
    end
    local head = player.Character:FindFirstChild("Head")
    if not head then
        return
    end

    local bSize, bFrameSize = getBubbleSize(text)

    local bubble = Instance.new("BillboardGui")
    bubble.Adornee = head
    bubble.Size = bFrameSize
    bubble.StudsOffset = Vector3.new(0, 2.0, 0)
    bubble.AlwaysOnTop = true
    bubble.Parent = head

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    bg.BackgroundTransparency = 0.25
    bg.BorderSizePixel = 0
    bg.Parent = bubble

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = bg

    local txt = Instance.new("TextLabel")    txt.Size = UDim2.new(1, -8, 1, 0)
    txt.Position = UDim2.new(0, 4, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(15, 15, 15)
    txt.TextSize = bSize
    txt.Font = Enum.Font.GothamSemibold
    txt.TextWrapped = true
    txt.Parent = bg

    if not playerBubbles[player.Name] then
        playerBubbles[player.Name] = {}
    end

    for i = 1, #playerBubbles[player.Name] do
        local old = playerBubbles[player.Name][i]
        old.StudsOffset = old.StudsOffset + Vector3.new(0, 1.5, 0)
    end

    table.insert(playerBubbles[player.Name], 1, bubble)

    task.delay(35, function()
        if bubble and bubble.Parent then
            bubble:Destroy()
        end
        local t = playerBubbles[player.Name]
        if t then
            for i = 1, #t do
                if t[i] == bubble then
                    table.remove(t, i)
                    break
                end
            end
            if #t == 0 then
                playerBubbles[player.Name] = nil
            end
        end
    end)
end

-- DISCORD FUNCTIONS
local function sendToDiscord(text)
    local content = "[" .. localPlayer.Name .. "]:" .. SERVER_ID .. ":" .. text
    local payload = HttpService:JSONEncode({
        content = content
    })
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = DISCORD_API .. "/channels/" .. CHANNEL_ID .. "/messages",
            Method = "POST",            Headers = HEADERS,
            Body = payload
        })
    end)
    if not success then
        warn("Send failed:", result)
    end
end

local function fetchFromDiscord()
    if not initDone then
        local success, result = pcall(function()
            return HttpService:RequestAsync({
                Url = DISCORD_API .. "/channels/" .. CHANNEL_ID .. "/messages?limit=1",
                Method = "GET",
                Headers = HEADERS
            })
        end)
        if success and result.StatusCode == 200 then
            local msgs = HttpService:JSONDecode(result.Body)
            if #msgs > 0 then
                lastMsgId = msgs[1].id
            end
        end
        initDone = true
        return
    end

    if not lastMsgId then
        return
    end

    local url = DISCORD_API .. "/channels/" .. CHANNEL_ID .. "/messages?limit=10&after=" .. tostring(lastMsgId)
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET",
            Headers = HEADERS
        })
    end)

    if not success then
        return
    end

    if result.StatusCode >= 400 then
        if result.StatusCode == 429 then
            local retry = tonumber(result.Headers["Retry-After"]) or 2
            task.wait(retry)
        end        return
    end

    local messages = HttpService:JSONDecode(result.Body)
    if #messages == 0 then
        return
    end

    lastMsgId = messages[#messages].id

    for i = 1, #messages do
        local msg = messages[i]
        local content = msg.content
        local rbxUser = nil
        local msgServerId = nil
        local msgText = nil

        local startBracket = content:find("%[")
        local endBracket = content:find("%]")
        local firstColon = content:find(":", endBracket)
        local secondColon = content:find(":", firstColon + 1)

        if startBracket and endBracket and firstColon and secondColon then
            rbxUser = content:sub(startBracket + 1, endBracket - 1)
            msgServerId = content:sub(firstColon + 1, secondColon - 1)
            msgText = content:sub(secondColon + 1)
        end

        if rbxUser and msgServerId == SERVER_ID and msgText then
            addChatMessage(rbxUser, msgText)
            local target = Players:FindFirstChild(rbxUser)
            if target then
                showBubble(target, msgText)
            end
        end
    end
end

-- POLLING
task.spawn(function()
    while true do
        fetchFromDiscord()
        task.wait(1.5)
    end
end)

-- SEND HANDLER
local function sendMsg()
    local txt = textBox.Text:gsub("^%s*(.-)%s*$", "%1")
    if txt == "" then        return
    end
    sendToDiscord(txt)
    textBox.Text = ""
end

sendBtn.MouseButton1Click:Connect(sendMsg)

textBox.FocusLost:Connect(function(enter)
    if enter then
        sendMsg()
    end
end)

updateVisibility()
