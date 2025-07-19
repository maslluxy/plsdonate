-- BetterAssistantPlugin.lua
-- Enhanced AI Assistant Plugin for Roblox Studio with Modern UI

-- Services
local Plugin = plugin
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- CONFIGURATION
local GEMINI_API_KEY = "AIzaSyCLmhJrLc_BkQwLPZYID0KrlEAoG_QvOqM" -- Replace with your actual API key
local GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
local ASSISTANT_NAME = "Better Assistant"
local VERSION = "2.0"

-- Theme Configuration
local THEME = {
    Background = Color3.fromRGB(13, 17, 23),
    Surface = Color3.fromRGB(22, 27, 34),
    SurfaceLight = Color3.fromRGB(33, 38, 45),
    Primary = Color3.fromRGB(33, 136, 255),
    PrimaryHover = Color3.fromRGB(26, 117, 255),
    Success = Color3.fromRGB(35, 134, 54),
    Warning = Color3.fromRGB(251, 188, 4),
    Error = Color3.fromRGB(248, 81, 73),
    TextPrimary = Color3.fromRGB(248, 248, 242),
    TextSecondary = Color3.fromRGB(139, 148, 158),
    TextMuted = Color3.fromRGB(110, 118, 129),
    Border = Color3.fromRGB(48, 54, 61),
    UserBubble = Color3.fromRGB(33, 136, 255),
    AssistantBubble = Color3.fromRGB(33, 38, 45),
    Accent = Color3.fromRGB(64, 200, 255)
}

-- Utility Functions
local function createCorner(radius, parent)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createPadding(padding, parent)
    local uiPadding = Instance.new("UIPadding")
    if type(padding) == "number" then
        uiPadding.PaddingTop = UDim.new(0, padding)
        uiPadding.PaddingBottom = UDim.new(0, padding)
        uiPadding.PaddingLeft = UDim.new(0, padding)
        uiPadding.PaddingRight = UDim.new(0, padding)
    else
        uiPadding.PaddingTop = UDim.new(0, padding.Top or 0)
        uiPadding.PaddingBottom = UDim.new(0, padding.Bottom or 0)
        uiPadding.PaddingLeft = UDim.new(0, padding.Left or 0)
        uiPadding.PaddingRight = UDim.new(0, padding.Right or 0)
    end
    uiPadding.Parent = parent
    return uiPadding
end

local function animateButton(button)
    local originalSize = button.Size
    local hoverTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 2, originalSize.Y.Scale, originalSize.Y.Offset + 2)
    })
    local normalTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = originalSize
    })
    
    button.MouseEnter:Connect(function() hoverTween:Play() end)
    button.MouseLeave:Connect(function() normalTween:Play() end)
end

-- Toolbar & Widget Setup
local toolbar = Plugin:CreateToolbar("AI Studio Enhanced")
local toggleButton = toolbar:CreateButton("Better Assistant", "Toggle the enhanced AI assistant", "rbxassetid://4458901886")
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right, 
    false, 
    false, 
    420, 
    600, 
    350, 
    450
)
local widget = Plugin:CreateDockWidgetPluginGui("BetterAssistantConsole", widgetInfo)
widget.Title = ASSISTANT_NAME .. " " .. VERSION

-- Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.BackgroundColor3 = THEME.Background
mainContainer.Size = UDim2.new(1, 0, 1, 0)
mainContainer.BorderSizePixel = 0
mainContainer.Parent = widget

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundColor3 = THEME.Surface
header.Size = UDim2.new(1, 0, 0, 50)
header.BorderSizePixel = 0
header.Parent = mainContainer
createCorner(0, header)

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "HeaderTitle"
headerTitle.BackgroundTransparency = 1
headerTitle.Size = UDim2.new(1, -60, 1, 0)
headerTitle.Position = UDim2.new(0, 15, 0, 0)
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 18
headerTitle.TextColor3 = THEME.TextPrimary
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Text = ASSISTANT_NAME
headerTitle.Parent = header

local statusIndicator = Instance.new("Frame")
statusIndicator.Name = "StatusIndicator"
statusIndicator.BackgroundColor3 = THEME.Success
statusIndicator.Size = UDim2.new(0, 8, 0, 8)
statusIndicator.Position = UDim2.new(1, -45, 0.5, -4)
statusIndicator.BorderSizePixel = 0
statusIndicator.Parent = header
createCorner(4, statusIndicator)

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(0, 30, 1, 0)
statusLabel.Position = UDim2.new(1, -35, 0, 0)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = THEME.TextSecondary
statusLabel.Text = "Online"
statusLabel.Parent = header

-- Chat Container
local chatContainer = Instance.new("Frame")
chatContainer.Name = "ChatContainer"
chatContainer.BackgroundTransparency = 1
chatContainer.Size = UDim2.new(1, 0, 1, -100)
chatContainer.Position = UDim2.new(0, 0, 0, 50)
chatContainer.Parent = mainContainer

-- Chat ScrollingFrame
local chatScroll = Instance.new("ScrollingFrame")
chatScroll.Name = "ChatScroll"
chatScroll.BackgroundTransparency = 1
chatScroll.ScrollBarThickness = 6
chatScroll.ScrollBarImageColor3 = THEME.Border
chatScroll.Size = UDim2.new(1, -20, 1, -10)
chatScroll.Position = UDim2.new(0, 10, 0, 5)
chatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
chatScroll.ScrollingDirection = Enum.ScrollingDirection.Y
chatScroll.Parent = chatContainer

local chatLayout = Instance.new("UIListLayout")
chatLayout.Name = "ChatLayout"
chatLayout.Padding = UDim.new(0, 12)
chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
chatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
chatLayout.Parent = chatScroll

-- Input Container
local inputContainer = Instance.new("Frame")
inputContainer.Name = "InputContainer"
inputContainer.BackgroundColor3 = THEME.Surface
inputContainer.Size = UDim2.new(1, 0, 0, 50)
inputContainer.Position = UDim2.new(0, 0, 1, -50)
inputContainer.BorderSizePixel = 0
inputContainer.Parent = mainContainer

local inputBorder = Instance.new("Frame")
inputBorder.BackgroundColor3 = THEME.Border
inputBorder.Size = UDim2.new(1, 0, 0, 1)
inputBorder.BorderSizePixel = 0
inputBorder.Parent = inputContainer

-- Input Frame
local inputFrame = Instance.new("Frame")
inputFrame.Name = "InputFrame"
inputFrame.BackgroundColor3 = THEME.SurfaceLight
inputFrame.Size = UDim2.new(1, -20, 0, 36)
inputFrame.Position = UDim2.new(0, 10, 0.5, -18)
inputFrame.BorderSizePixel = 0
inputFrame.Parent = inputContainer
createCorner(18, inputFrame)

-- Prompt TextBox
local promptBox = Instance.new("TextBox")
promptBox.Name = "PromptBox"
promptBox.BackgroundTransparency = 1
promptBox.Size = UDim2.new(1, -90, 1, 0)
promptBox.Position = UDim2.new(0, 0, 0, 0)
promptBox.Text = ""
promptBox.PlaceholderText = "Ask me anything about Roblox development..."
promptBox.PlaceholderColor3 = THEME.TextMuted
promptBox.TextColor3 = THEME.TextPrimary
promptBox.TextXAlignment = Enum.TextXAlignment.Left
promptBox.TextYAlignment = Enum.TextYAlignment.Center
promptBox.ClearTextOnFocus = false
promptBox.Font = Enum.Font.Gotham
promptBox.TextSize = 14
promptBox.Parent = inputFrame
createPadding(15, promptBox)

-- Send Button
local sendButton = Instance.new("ImageButton")
sendButton.Name = "SendButton"
sendButton.BackgroundColor3 = THEME.Primary
sendButton.Size = UDim2.new(0, 32, 0, 32)
sendButton.Position = UDim2.new(1, -34, 0.5, -16)
sendButton.BorderSizePixel = 0
sendButton.Image = "rbxassetid://3944680095" -- Send icon
sendButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
sendButton.Parent = inputFrame
createCorner(16, sendButton)

-- Variables for chat management
local chatHistory = {}
local isProcessing = false
local messageCount = 0

-- Enhanced Chat Bubble Creation
local function createChatBubble(text, isUser, isError)
    messageCount += 1
    
    local bubbleContainer = Instance.new("Frame")
    bubbleContainer.Name = "BubbleContainer_" .. messageCount
    bubbleContainer.BackgroundTransparency = 1
    bubbleContainer.Size = UDim2.new(1, 0, 0, 0)
    bubbleContainer.AutomaticSize = Enum.AutomaticSize.Y
    bubbleContainer.LayoutOrder = messageCount
    bubbleContainer.Parent = chatScroll

    local bubble = Instance.new("Frame")
    bubble.Name = "Bubble"
    local bubbleColor = isUser and THEME.UserBubble or (isError and THEME.Error or THEME.AssistantBubble)
    bubble.BackgroundColor3 = bubbleColor
    bubble.Size = UDim2.new(0.85, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    bubble.BorderSizePixel = 0
    bubble.Parent = bubbleContainer
    createCorner(12, bubble)
    createPadding(12, bubble)

    -- Avatar/Icon
    local avatar = Instance.new("Frame")
    avatar.Name = "Avatar"
    avatar.BackgroundColor3 = isUser and THEME.Primary or THEME.Accent
    avatar.Size = UDim2.new(0, 24, 0, 24)
    avatar.Position = isUser and UDim2.new(1, 8, 0, 0) or UDim2.new(0, -32, 0, 0)
    avatar.BorderSizePixel = 0
    avatar.Parent = bubbleContainer
    createCorner(12, avatar)

    local avatarIcon = Instance.new("TextLabel")
    avatarIcon.BackgroundTransparency = 1
    avatarIcon.Size = UDim2.new(1, 0, 1, 0)
    avatarIcon.Font = Enum.Font.GothamBold
    avatarIcon.TextSize = 12
    avatarIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    avatarIcon.Text = isUser and "U" or "AI"
    avatarIcon.Parent = avatar

    -- Message Label
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.BackgroundTransparency = 1
    messageLabel.Size = UDim2.new(1, 0, 0, 0)
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.Text = text
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 14
    messageLabel.TextColor3 = isUser and Color3.fromRGB(255, 255, 255) or THEME.TextPrimary
    messageLabel.RichText = true
    messageLabel.Parent = bubble

    -- Timestamp
    local timestamp = Instance.new("TextLabel")
    timestamp.Name = "Timestamp"
    timestamp.BackgroundTransparency = 1
    timestamp.Size = UDim2.new(1, 0, 0, 16)
    timestamp.Position = UDim2.new(0, 0, 1, 2)
    timestamp.Font = Enum.Font.Gotham
    timestamp.TextSize = 10
    timestamp.TextColor3 = THEME.TextMuted
    timestamp.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    timestamp.Text = os.date("%H:%M")
    timestamp.Parent = bubbleContainer

    -- Scroll to bottom
    chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
    
    return bubbleContainer
end

-- Enhanced API Call
local function getGeminiReply(prompt, context)
    local fullPrompt = string.format([[
You are Better Assistant, an advanced AI helper for Roblox Studio development. 
You're knowledgeable about Roblox scripting, game design, UI creation, and Studio workflows.

Context: %s

User Query: %s

Guidelines:
- Provide clear, actionable advice
- Include code examples when relevant
- Be encouraging and supportive
- Focus on Roblox/Studio-specific solutions
- Keep responses concise but thorough
]], context or "General Roblox development assistance", prompt)

    local payload = {
        contents = {{
            parts = {{
                text = fullPrompt
            }}
        }},
        generationConfig = {
            temperature = 0.7,
            maxOutputTokens = 1024,
            topP = 0.8,
            topK = 40
        }
    }
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["x-goog-api-key"] = GEMINI_API_KEY
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(GEMINI_ENDPOINT, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson, false, headers)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        if data.candidates and data.candidates[1] and data.candidates[1].content then
            return data.candidates[1].content.parts[1].text
        else
            return "I apologize, but I couldn't generate a response. Please try again."
        end
    else
        return "Connection error. Please check your internet connection and API key."
    end
end

-- Context Generation
local function generateContext()
    local selection = Selection:Get()
    local context = ""
    
    if #selection > 0 then
        context = "Currently selected objects: "
        for i, obj in ipairs(selection) do
            context = context .. obj.Name .. " (" .. obj.ClassName .. ")"
            if i < #selection then context = context .. ", " end
        end
    end
    
    return context
end

-- Send Message Function
local function sendMessage()
    local prompt = promptBox.Text:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
    if prompt == "" or isProcessing then return end

    isProcessing = true
    statusLabel.Text = "Thinking..."
    statusIndicator.BackgroundColor3 = THEME.Warning
    
    -- Create user message
    createChatBubble(prompt, true)
    promptBox.Text = ""
    
    -- Add to chat history
    table.insert(chatHistory, {type = "user", message = prompt})

    -- Get context
    local context = generateContext()

    -- Create loading message
    local loadingBubble = createChatBubble("🤔 Thinking...", false)

    task.spawn(function()
        local success, result = pcall(getGeminiReply, prompt, context)
        
        -- Remove loading message
        if loadingBubble and loadingBubble.Parent then
            loadingBubble:Destroy()
        end
        
        local response = success and result or "❌ Sorry, I encountered an error. Please try again."
        createChatBubble(response, false, not success)
        
        -- Add to chat history
        table.insert(chatHistory, {type = "assistant", message = response})
        
        -- Update status
        isProcessing = false
        statusLabel.Text = "Online"
        statusIndicator.BackgroundColor3 = THEME.Success
        
        -- Limit chat history
        if #chatHistory > 20 then
            table.remove(chatHistory, 1)
            table.remove(chatHistory, 1)
        end
    end)
end

-- Event Connections
sendButton.MouseButton1Click:Connect(sendMessage)
animateButton(sendButton)

promptBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendMessage()
    end
end)

-- Button hover effects
sendButton.MouseEnter:Connect(function()
    sendButton.BackgroundColor3 = THEME.PrimaryHover
end)

sendButton.MouseLeave:Connect(function()
    sendButton.BackgroundColor3 = THEME.Primary
end)

-- Toggle widget visibility
toggleButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

-- Welcome message
task.wait(0.5)
createChatBubble("👋 Hello! I'm your Better Assistant, ready to help with Roblox development. Ask me anything!", false)

print("Better Assistant Plugin v" .. VERSION .. " loaded successfully!")
return true
