local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

local Running = true
local Connections = {}
local CleanupHooks = {}
local WeakMode = {__mode = "k"}

local function Track(connection)
    Connections[#Connections + 1] = connection
    return connection
end

local function SafeDestroy(instance)
    if instance then
        pcall(function() instance:Destroy() end)
    end
end

local function Cleanup()
    Running = false

    for _,connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Connections)

    for _,hook in ipairs(CleanupHooks) do
        pcall(hook)
    end
end

pcall(function()
    local env = getgenv()
    if type(env.LK_DOORS_CLEANUP) == "function" then
        pcall(env.LK_DOORS_CLEANUP)
    end
    env.LK_DOORS_CLEANUP = Cleanup
end)

pcall(function()
    local old = CoreGui:FindFirstChild("LKDoorsSystem")
    if old then old:Destroy() end
    local oldCode = CoreGui:FindFirstChild("LKAutoCode50")
    if oldCode then oldCode:Destroy() end
end)

local Settings = {
    Entities = false,
    Doors = false,
    Items = false,
    Books = false,
    Lever = false,
    Notifier = false,
    Speed = false,
    Optimize = false,
    AutoKey = false,
    AutoItems = false,
    AutoCoins = false,
    AutoDrawers = false,
    Players = false,
    Batteries = false,
    EntitySkin = false,
    SpeedValue = 20,
    SaveConfig = true
}

local CONFIG_FILE = "LK_DOORS_SYSTEM_V10_CONFIG.json"
local ConfigKeys = {
    "Entities","Doors","Items","Books","Lever","Notifier","Speed","Optimize",
    "AutoKey","AutoItems","AutoCoins","AutoDrawers","Players","Batteries",
    "EntitySkin","SpeedValue"
}

local function LoadSettings()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not ok or not exists then return end

    local readOk, raw = pcall(readfile, CONFIG_FILE)
    if not readOk or type(raw) ~= "string" then return end

    local decodeOk, saved = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not decodeOk or type(saved) ~= "table" then return end

    if saved.SaveConfig == false then
        Settings.SaveConfig = false
        return
    end

    for _, key in ipairs(ConfigKeys) do
        if saved[key] ~= nil and typeof(Settings[key]) == typeof(saved[key]) then
            Settings[key] = saved[key]
        end
    end
    if typeof(saved.SaveConfig) == "boolean" then
        Settings.SaveConfig = saved.SaveConfig
    end
end

local function SaveSettings(force)
    if not Settings.SaveConfig and not force then return end
    if type(writefile) ~= "function" then return end

    local data = {SaveConfig = Settings.SaveConfig}
    for _, key in ipairs(ConfigKeys) do
        data[key] = Settings[key]
    end

    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

LoadSettings()

local Purple = Color3.fromRGB(145,75,255)
local Dark = Color3.fromRGB(15,15,23)
local Panel = Color3.fromRGB(25,25,37)
local ButtonColor = Color3.fromRGB(38,38,53)
local White = Color3.fromRGB(245,245,255)

local Gui = Instance.new("ScreenGui")
Gui.Name = "LKDoorsSystem"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

CleanupHooks[#CleanupHooks + 1] = function() SafeDestroy(Gui) end

local Camera = Workspace.CurrentCamera
local viewport = Camera and Camera.ViewportSize or Vector2.new(800,600)

local width = math.clamp(viewport.X - 20,320,510)
local height = math.clamp(viewport.Y - 80,280,370)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(width,height)
Main.Position = UDim2.new(0.5,-width/2,0.5,-height/2)
Main.BackgroundColor3 = Dark
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner",Main).CornerRadius = UDim.new(0,14)

local Outline = Instance.new("UIStroke")
Outline.Color = Color3.fromRGB(95,60,145)
Outline.Thickness = 1.5
Outline.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,52)
Header.BackgroundColor3 = Panel
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner",Header).CornerRadius = UDim.new(0,14)

local Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(13,3)
Title.Size = UDim2.new(1,-100,0,27)
Title.BackgroundTransparency = 1
Title.Text = "LK DOORS SYSTEM"
Title.TextColor3 = White
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.fromOffset(14,29)
Subtitle.Size = UDim2.new(1,-100,0,15)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "DOORS ORIGINAL  •  VERSION 10.1"
Subtitle.TextColor3 = Purple
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(32,30)
Minimize.Position = UDim2.new(1,-42,0,11)
Minimize.BackgroundColor3 = ButtonColor
Minimize.Text = "—"
Minimize.TextColor3 = White
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 17
Minimize.Parent = Header

Instance.new("UICorner",Minimize).CornerRadius = UDim.new(0,8)

local Tabs = Instance.new("Frame")
Tabs.Position = UDim2.fromOffset(9,59)
Tabs.Size = UDim2.new(1,-18,0,38)
Tabs.BackgroundTransparency = 1
Tabs.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0,3)
TabLayout.Parent = Tabs

local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(10,105)
Content.Size = UDim2.new(1,-20,1,-115)
Content.BackgroundColor3 = Panel
Content.BorderSizePixel = 0
Content.Parent = Main

Instance.new("UICorner",Content).CornerRadius = UDim.new(0,10)

local Pages = {}
local TabButtons = {}

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Position = UDim2.fromOffset(8,8)
    page.Size = UDim2.new(1,-16,1,-16)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Purple
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7)
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(
            0,layout.AbsoluteContentSize.Y+10
        )
    end)

    Pages[name] = page
end

local function SelectTab(name)
    for tabName,page in pairs(Pages) do
        page.Visible = tabName == name
    end

    for tabName,button in pairs(TabButtons) do
        button.BackgroundColor3 =
            tabName == name and Purple or ButtonColor
    end
end

local function CreateTab(name,icon)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1/7,-3,1,0)
    button.BackgroundColor3 = ButtonColor
    button.Text = icon.." "..name
    button.TextColor3 = White
    button.TextSize = math.clamp(width/43,8,11)
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = Tabs

    Instance.new("UICorner",button).CornerRadius = UDim.new(0,7)

    TabButtons[name] = button
    CreatePage(name)

    button.Activated:Connect(function()
        SelectTab(name)
    end)
end

CreateTab("ESP","👁")
CreateTab("ENTIDADES","👻")
CreateTab("ITENS","🔑")
CreateTab("PLAYER","🏃")
CreateTab("EXTRAS","⚙")
CreateTab("AUTO","⚡")
CreateTab("CONFIG","⚙")

local function AddButton(pageName,name,key,callback)
    local page = Pages[pageName]
    if not page then return end

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1,-3,0,39)
    button.BackgroundColor3 = ButtonColor
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = page

    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(11,0)
    label.Size = UDim2.new(1,-75,1,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = White
    label.TextSize = 11
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(43,21)
    status.Position = UDim2.new(1,-51,0.5,-10)
    status.BackgroundColor3 = Color3.fromRGB(65,65,80)
    status.Text = "OFF"
    status.TextColor3 = White
    status.Font = Enum.Font.GothamBold
    status.TextSize = 9
    status.Parent = button

    Instance.new("UICorner",status).CornerRadius = UDim.new(0,6)

    local enabled = key and Settings[key] == true or false

    local function PaintStatus()
        status.Text = enabled and "ON" or "OFF"
        status.BackgroundColor3 = enabled and Purple
            or Color3.fromRGB(65,65,80)
    end

    PaintStatus()

    button.Activated:Connect(function()
        enabled = not enabled
        PaintStatus()

        if key then
            Settings[key] = enabled
            SaveSettings()
        end

        if callback then
            local ok,err = pcall(callback,enabled)
            if not ok then
                warn("LK DOORS BUTTON ERROR ["..tostring(name).."]:",err)
            end
        end
    end)

    if enabled and callback then
        task.defer(function()
            if Running and button.Parent then
                local ok,err = pcall(callback,true)
                if not ok then
                    warn("LK DOORS INIT ERROR ["..tostring(name).."]:",err)
                end
            end
        end)
    end

    return button
end

local function AddAction(pageName,name,callback)
    local page = Pages[pageName]
    if not page then return end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-3,0,39)
    button.BackgroundColor3 = ButtonColor
    button.Text = name
    button.TextColor3 = White
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = page

    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)
    button.Activated:Connect(function()
        local ok,err = pcall(callback)
        if not ok then
            warn("LK DOORS ACTION ERROR ["..tostring(name).."]:",err)
        end
    end)
end

local NotificationCount = 0

local function Notify(message)
    NotificationCount = NotificationCount + 1

    local notice = Instance.new("Frame")
    notice.Name = "LKNotification_"..NotificationCount
    notice.Size = UDim2.fromOffset(270,0)
    notice.AnchorPoint = Vector2.new(1,0)
    notice.Position = UDim2.new(1,-14,0,62 + ((NotificationCount-1)%4)*62)
    notice.BackgroundColor3 = Panel
    notice.BorderSizePixel = 0
    notice.ClipsDescendants = true
    notice.Parent = Gui

    Instance.new("UICorner",notice).CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Purple
    stroke.Thickness = 1.5
    stroke.Parent = notice

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(12,5)
    title.Size = UDim2.new(1,-24,0,17)
    title.BackgroundTransparency = 1
    title.Text = "LK DOORS SYSTEM"
    title.TextColor3 = Purple
    title.TextSize = 11
    title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notice

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Position = UDim2.fromOffset(12,24)
    messageLabel.Size = UDim2.new(1,-24,0,23)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = tostring(message)
    messageLabel.TextColor3 = White
    messageLabel.TextSize = 12
    messageLabel.Font = Enum.Font.GothamBold
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.Parent = notice

    TweenService:Create(
        notice,
        TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {
            Size = UDim2.fromOffset(270,55),
            Position = UDim2.new(1,-14,0,62 + ((NotificationCount-1)%4)*62)
        }
    ):Play()

    task.delay(3.2,function()
        if not notice.Parent then return end

        local exitTween = TweenService:Create(
            notice,
            TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {
                Position = UDim2.new(1,285,0,62 + ((NotificationCount-1)%4)*62),
                BackgroundTransparency = 1
            }
        )

        TweenService:Create(title,TweenInfo.new(0.25),{
            TextTransparency = 1
        }):Play()

        TweenService:Create(messageLabel,TweenInfo.new(0.25),{
            TextTransparency = 1
        }):Play()

        TweenService:Create(stroke,TweenInfo.new(0.25),{
            Transparency = 1
        }):Play()

        exitTween:Play()
        exitTween.Completed:Wait()
        notice:Destroy()
    end)
end

local function Norm(text)
    return (tostring(text):lower():gsub("[%s_%-%.]",""))
end

local function HasAny(text,words)
    for _,word in ipairs(words) do
        if text:find(word,1,true) then
            return true
        end
    end

    return false
end

local ESPObjects = {}

local EntityNames = {
    "rush","ambush","figure","seek","screech",
    "a60","a120","blitz","lookman","halt",
    "dupe","dread","eyes","grumble","giggle"
}

local ItemNames = {
    "key","lighter","flashlight","crucifix",
    "vitamin","lockpick","shears","bandage",
    "candle"
}

local function GetPart(object)
    if object:IsA("BasePart") then return object end

    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChildWhichIsA("BasePart",true)
    end

    if object:IsA("Tool") then
        return object:FindFirstChildWhichIsA("BasePart",true)
    end
end

local function IsEntity(name)
    local normalized = name:lower():gsub("[%s_%-]","")

    if normalized:find("painting",1,true)
    or normalized == "seekarm"
    or normalized:find("sideroom",1,true) then
        return false
    end

    for _,entity in ipairs(EntityNames) do
        if normalized:find(entity,1,true) then
            return true
        end
    end

    return false
end

local function IsItem(name)
    local normalized = name:lower()

    if normalized:find("candle_medium",1,true) then
        return false
    end

    for _,item in ipairs(ItemNames) do
        if normalized:find(item,1,true) then
            return true
        end
    end

    return false
end

local function AddESP(object,category,color,label)
    if not object or not object.Parent or ESPObjects[object] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "LK_ESP"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.78
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = Gui

    local part = GetPart(object)
    local billboard

    if part then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "LK_ESP_LABEL"
        billboard.Adornee = part
        billboard.Size = UDim2.fromOffset(150,28)
        billboard.StudsOffset = Vector3.new(0,3,0)
        billboard.AlwaysOnTop = true
        billboard.Parent = Gui

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1,1)
        text.BackgroundTransparency = 1
        text.Text = label
        text.TextColor3 = color
        text.TextStrokeTransparency = 0
        text.TextSize = 12
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
    end

    ESPObjects[object] = {
        Category = category,
        Highlight = highlight,
        Billboard = billboard
    }
end

local function RemoveCategory(category)
    for object,data in pairs(ESPObjects) do
        if data.Category == category then
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            ESPObjects[object] = nil
        end
    end
end

local function ClearESPObjects()
    for object,data in pairs(ESPObjects) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end

    table.clear(ESPObjects)
end

CleanupHooks[#CleanupHooks + 1] = ClearESPObjects

local Buckets = {
    entity = {},
    book = {},
    lever = {},
    door = {},
    item = {},
    battery = {}
}

local BatteryNameExclude = {
    "charger","station","socket","slot","icon",
    "indicator","meter","gauge"
}

local function IsBatteryName(name)
    local n = Norm(name)

    if n:find("^livebreakerpolepickup") then return true end

    if not (n:find("^battery") or n:find("^batteries")) then
        return false
    end

    return not HasAny(n,BatteryNameExclude)
end

local function IndexObject(object)
    local name = object.Name
    local className = object.ClassName

    if className == "Model" or className == "Tool" then
        if className == "Model" and IsEntity(name) then
            Buckets.entity[object] = true
        end

        if name == "LiveHintBook" then
            Buckets.book[object] = true
        elseif name == "LeverForGate" then
            Buckets.lever[object] = true
        end

        if IsItem(name) then
            Buckets.item[object] = true
        end

        if IsBatteryName(name) then
            Buckets.battery[object] = true
        end

        return
    end

    local first = name:byte(1)

    if first == 68 or first == 76 or first == 66 or first == 98 then
        if not object:IsA("BasePart") then return end

        if name == "Door" then
            Buckets.door[object] = true
        elseif name == "LiveHintBook" then
            Buckets.book[object] = true
        elseif name == "LeverForGate" then
            Buckets.lever[object] = true
        elseif IsBatteryName(name) then
            Buckets.battery[object] = true
        end
    end
end

local SeenEntities = {}

local function EntitySpawned(object)
    if not object or not object:IsA("Model") then return end
    if not object.Parent or not IsEntity(object.Name) then return end
    if SeenEntities[object] then return end

    SeenEntities[object] = true

    if Settings.Notifier then
        Notify("ENTIDADE SPAWNOU: "..object.Name)
    end
end

Track(Workspace.DescendantAdded:Connect(function(object)
    pcall(IndexObject,object)

    if not object:IsA("Model") then return end

    task.delay(0.15,function()
        if Running and object.Parent then
            EntitySpawned(object)
        end
    end)
end))

Track(Workspace.DescendantRemoving:Connect(function(object)
    local wasEntity = Buckets.entity[object]

    for _,bucket in pairs(Buckets) do
        bucket[object] = nil
    end

    if wasEntity then
        task.delay(1,function()
            if not object:IsDescendantOf(Workspace) then
                SeenEntities[object] = nil
            end
        end)
    end
end))

task.spawn(function()
    local processed = 0

    for _,object in ipairs(Workspace:GetDescendants()) do
        if not Running then return end

        pcall(IndexObject,object)

        if Buckets.entity[object] then
            SeenEntities[object] = true
        end

        processed = processed + 1
        if processed % 1500 == 0 then
            task.wait()
        end
    end
end)

local function Scan()
    local desired = {}

    for object in pairs(Buckets.entity) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.entity[object] = nil
        else
            EntitySpawned(object)

            if Settings.Entities then
                desired[object] = {
                    "ENTITY",
                    Color3.fromRGB(255,45,55),
                    object.Name
                }
            end
        end
    end

    for object in pairs(Buckets.book) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.book[object] = nil
        elseif Settings.Books then
            desired[object] = {
                "BOOK",
                Color3.fromRGB(40,255,110),
                "LIVRO"
            }
        end
    end

    for object in pairs(Buckets.lever) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.lever[object] = nil
        elseif Settings.Lever then
            desired[object] = {
                "LEVER",
                Color3.fromRGB(255,165,30),
                "ALAVANCA"
            }
        end
    end

    for object in pairs(Buckets.door) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.door[object] = nil
        elseif Settings.Doors then
            desired[object] = {
                "DOOR",
                Color3.fromRGB(40,170,255),
                "DOOR"
            }
        end
    end

    for object in pairs(Buckets.item) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.item[object] = nil
        elseif Settings.Items then
            desired[object] = {
                "ITEM",
                Color3.fromRGB(255,220,35),
                object.Name
            }
        end
    end

    for object,info in pairs(desired) do
        if not ESPObjects[object] then
            AddESP(object,info[1],info[2],info[3])
        end
    end

    for object,data in pairs(ESPObjects) do
        if not object.Parent or not desired[object]
        or desired[object][1] ~= data.Category then

            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end

            ESPObjects[object] = nil
        end
    end
end

local PlayerESP = {Active = false, Data = {}, GlobalConns = {}}

local function PE_DisconnectList(list)
    for _,connection in ipairs(list) do
        pcall(function() connection:Disconnect() end)
    end

    table.clear(list)
end

local function PE_DestroyVisuals(data)
    SafeDestroy(data.Highlight)
    SafeDestroy(data.Billboard)
    data.Highlight = nil
    data.Billboard = nil
    data.NameLabel = nil
end

local function PE_Detach(data)
    PE_DestroyVisuals(data)

    if data.CharConn then
        pcall(function() data.CharConn:Disconnect() end)
        data.CharConn = nil
    end

    data.Char = nil
end

local function PE_Attach(player,data,character)
    PE_Detach(data)

    if not character or not PlayerESP.Active then return end

    data.Char = character

    local highlight = Instance.new("Highlight")
    highlight.Name = "LK_PLAYER_ESP"
    highlight.Adornee = character
    highlight.FillColor = Purple
    highlight.OutlineColor = Purple
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = Gui
    data.Highlight = highlight

    data.CharConn = character.AncestryChanged:Connect(function(_,parent)
        if not parent and data.Char == character then
            PE_Detach(data)
        end
    end)

    task.spawn(function()
        local head = character:WaitForChild("Head",10)

        if not head or data.Char ~= character
        or not PlayerESP.Active or data.Billboard then
            return
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "LK_PLAYER_LABEL"
        billboard.Adornee = head
        billboard.Size = UDim2.fromOffset(150,34)
        billboard.StudsOffset = Vector3.new(0,2.6,0)
        billboard.AlwaysOnTop = true
        billboard.Parent = Gui

        local display = Instance.new("TextLabel")
        display.Size = UDim2.new(1,0,0.55,0)
        display.BackgroundTransparency = 1
        display.Text = player.DisplayName
        display.TextColor3 = White
        display.TextStrokeTransparency = 0
        display.TextSize = 13
        display.Font = Enum.Font.GothamBold
        display.Parent = billboard

        local username = Instance.new("TextLabel")
        username.Position = UDim2.fromScale(0,0.55)
        username.Size = UDim2.new(1,0,0.45,0)
        username.BackgroundTransparency = 1
        username.Text = "@"..player.Name
        username.TextColor3 = Purple
        username.TextStrokeTransparency = 0
        username.TextSize = 11
        username.Font = Enum.Font.GothamSemibold
        username.Parent = billboard

        data.Billboard = billboard
        data.NameLabel = display
    end)
end

local function PE_Track(player)
    if player == Player or PlayerESP.Data[player] then return end

    local data = {Conns = {}}
    PlayerESP.Data[player] = data

    data.Conns[#data.Conns + 1] = player.CharacterAdded:Connect(function(character)
        PE_Attach(player,data,character)
    end)

    data.Conns[#data.Conns + 1] = player.CharacterRemoving:Connect(function()
        PE_Detach(data)
    end)

    data.Conns[#data.Conns + 1] = player:GetPropertyChangedSignal("DisplayName"):Connect(function()
        if data.NameLabel then
            data.NameLabel.Text = player.DisplayName
        end
    end)

    if player.Character then
        PE_Attach(player,data,player.Character)
    end
end

local function PE_Untrack(player)
    local data = PlayerESP.Data[player]
    if not data then return end

    PE_Detach(data)
    PE_DisconnectList(data.Conns)
    PlayerESP.Data[player] = nil
end

local function PE_Disable()
    PlayerESP.Active = false

    PE_DisconnectList(PlayerESP.GlobalConns)

    for player in pairs(PlayerESP.Data) do
        PE_Untrack(player)
    end
end

local function PE_Enable()
    if PlayerESP.Active then return end
    PlayerESP.Active = true

    PlayerESP.GlobalConns[#PlayerESP.GlobalConns + 1] =
        Players.PlayerAdded:Connect(function(player)
            PE_Track(player)
        end)

    PlayerESP.GlobalConns[#PlayerESP.GlobalConns + 1] =
        Players.PlayerRemoving:Connect(function(player)
            PE_Untrack(player)
        end)

    for _,player in ipairs(Players:GetPlayers()) do
        PE_Track(player)
    end
end

local function PE_Rebuild()
    if not PlayerESP.Active then return end

    for player,data in pairs(PlayerESP.Data) do
        PE_Attach(player,data,player.Character)
    end
end

CleanupHooks[#CleanupHooks + 1] = PE_Disable

local BatteryESP = {Active = false, Items = {}, Token = nil}

local function IsInsideCharacter(object)
    local current = object.Parent

    for _ = 1,8 do
        if not current or current == Workspace then return false end

        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            return true
        end

        current = current.Parent
    end

    return false
end

local function HasCollectPrompt(object)
    local function promptOk(prompt)
        local action = (prompt.ActionText or ""):lower()
        local pname = Norm(prompt.Name)

        if HasAny(action,{"unlock","hide","open","destranc","esconder"}) then
            return false
        end

        if pname:find("hide",1,true) or pname:find("unlock",1,true) then
            return false
        end

        return true
    end

    if object:IsA("ProximityPrompt") then return promptOk(object) end

    local count = 0
    for _,descendant in ipairs(object:GetDescendants()) do
        count = count + 1
        if count > 150 then break end

        if descendant:IsA("ProximityPrompt") and promptOk(descendant) then
            return true
        end
    end

    return false
end

local function ClassifyBattery(object)
    if not object.Parent or not object:IsDescendantOf(Workspace) then
        return false
    end

    if not (object:IsA("Model") or object:IsA("Tool") or object:IsA("BasePart")) then
        return false
    end

    if IsInsideCharacter(object) then return false end

    local ancestor = object.Parent
    for _ = 1,3 do
        if not ancestor or ancestor == Workspace then break end

        if (ancestor:IsA("Model") or ancestor:IsA("Tool"))
        and IsBatteryName(ancestor.Name) then
            return false
        end

        ancestor = ancestor.Parent
    end

    if not GetPart(object) then return false end

    if Norm(object.Name):find("^livebreakerpolepickup") then
        return true
    end

    if object:IsA("Tool") then return true end

    if object:IsA("BasePart") then
        local prompt = object:FindFirstChildOfClass("ProximityPrompt")
        return prompt ~= nil and HasCollectPrompt(prompt)
    end

    return HasCollectPrompt(object)
end

local function BE_Remove(object)
    local data = BatteryESP.Items[object]
    if not data then return end

    SafeDestroy(data.Highlight)
    SafeDestroy(data.Billboard)
    BatteryESP.Items[object] = nil
end

local function BE_Add(object)
    if BatteryESP.Items[object] then return end

    local color = Color3.fromRGB(0,255,200)

    local highlight = Instance.new("Highlight")
    highlight.Name = "LK_BATTERY_ESP"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = Gui

    local billboard
    local part = GetPart(object)

    if part then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "LK_BATTERY_LABEL"
        billboard.Adornee = part
        billboard.Size = UDim2.fromOffset(110,24)
        billboard.StudsOffset = Vector3.new(0,2.5,0)
        billboard.AlwaysOnTop = true
        billboard.Parent = Gui

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1,1)
        text.BackgroundTransparency = 1
        text.Text = "BATTERY"
        text.TextColor3 = color
        text.TextStrokeTransparency = 0
        text.TextSize = 12
        text.Font = Enum.Font.GothamBold
        text.Parent = billboard
    end

    BatteryESP.Items[object] = {Highlight = highlight,Billboard = billboard}
end

local function BE_Refresh()
    for object in pairs(Buckets.battery) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.battery[object] = nil
            BE_Remove(object)
        elseif ClassifyBattery(object) then
            BE_Add(object)
        else
            BE_Remove(object)
        end
    end

    for object in pairs(BatteryESP.Items) do
        if not object.Parent or not Buckets.battery[object] then
            BE_Remove(object)
        end
    end
end

local function BE_ClearVisuals()
    for object in pairs(BatteryESP.Items) do
        BE_Remove(object)
    end
end

local function BE_Disable()
    BatteryESP.Active = false
    BatteryESP.Token = nil
    BE_ClearVisuals()
end

local function BE_Enable()
    if BatteryESP.Active then return end

    BatteryESP.Active = true

    local token = {}
    BatteryESP.Token = token

    task.spawn(function()
        while Running and BatteryESP.Token == token do
            local ok,err = pcall(BE_Refresh)

            if not ok then
                warn("LK BATTERY ESP ERROR:",err)
            end

            task.wait(1)
        end
    end)
end

CleanupHooks[#CleanupHooks + 1] = BE_Disable

local EntitySkinObjects = {}
local BuildEntitySkinMap

local function SetEntityOriginalVisible(model, visible, record)
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if visible then
                local old = record and record.OriginalTransparency and record.OriginalTransparency[item]
                item.LocalTransparencyModifier = old or 0
            else
                if record then
                    record.OriginalTransparency = record.OriginalTransparency or {}
                    if record.OriginalTransparency[item] == nil then
                        record.OriginalTransparency[item] = item.LocalTransparencyModifier
                    end
                end
                item.LocalTransparencyModifier = 1
            end
        elseif item:IsA("Decal") or item:IsA("Texture") then
            if visible then
                local old = record and record.OriginalDecalTransparency and record.OriginalDecalTransparency[item]
                item.Transparency = old or 0
            else
                if record then
                    record.OriginalDecalTransparency = record.OriginalDecalTransparency or {}
                    if record.OriginalDecalTransparency[item] == nil then
                        record.OriginalDecalTransparency[item] = item.Transparency
                    end
                end
                item.Transparency = 1
            end
        end
    end
end

local function RemoveEntitySkin(model)
    local record = EntitySkinObjects[model]
    if not record then return end
    SetEntityOriginalVisible(model, true, record)
    SafeDestroy(record.Avatar)
    EntitySkinObjects[model] = nil
end

local function ApplyEntitySkin(model)
    if not Settings.EntitySkin or not model or not model:IsA("Model")
    or not model.Parent or EntitySkinObjects[model] then return end

    local character = Player.Character
    if not character then return end

    local oldArchivable = character.Archivable
    local clone
    local ok = pcall(function()
        character.Archivable = true
        clone = character:Clone()
        character.Archivable = oldArchivable
    end)
    character.Archivable = oldArchivable
    if not ok or not clone then return end

    clone.Name = "LK_EntityPlayerSkin"

    for _,item in ipairs(clone:GetDescendants()) do
        if item:IsA("Tool") then
            item:Destroy()
        elseif item:IsA("Script") or item:IsA("LocalScript") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            item.Massless = true
        elseif item:IsA("Humanoid") then
            item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            item.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            item.NameDisplayDistance = 0
        end
    end

    local avatarParts = {}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            avatarParts[part.Name:lower()] = part
        end
    end

    local record = {
        Avatar = clone,
        AvatarParts = avatarParts,
        OriginalTransparency = {},
        OriginalDecalTransparency = {}
    }
    EntitySkinObjects[model] = record

    pcall(function()
        clone:PivotTo(model:GetPivot())
        clone.Parent = Workspace
    end)
    record.PartMap = BuildEntitySkinMap(model, clone)
    record.AccessoryMap = BuildEntityAccessoryMap(clone, record.PartMap)
    SetEntityOriginalVisible(model, false, record)
end

local function NormalizeEntityPartName(name)
    return tostring(name or ""):lower():gsub("[^%w]", "")
end

local EntityPartAliases = {
    head = {"head", "skull", "face"},
    uppertorso = {"uppertorso", "torso", "body", "chest", "mainbody"},
    lowertorso = {"lowertorso", "torso", "body", "abdomen", "mainbody"},
    leftupperarm = {"leftupperarm", "leftarm", "armleft", "leftarm1", "arml"},
    leftlowerarm = {"leftlowerarm", "leftforearm", "leftarm", "armleft", "leftarm2"},
    lefthand = {"lefthand", "leftarm", "handleft", "leftclaw"},
    rightupperarm = {"rightupperarm", "rightarm", "armright", "rightarm1", "armr"},
    rightlowerarm = {"rightlowerarm", "rightforearm", "rightarm", "armright", "rightarm2"},
    righthand = {"righthand", "rightarm", "handright", "rightclaw"},
    leftupperleg = {"leftupperleg", "leftleg", "legleft", "leftleg1", "legl"},
    leftlowerleg = {"leftlowerleg", "leftleg", "legleft", "leftleg2"},
    leftfoot = {"leftfoot", "leftleg", "footleft"},
    rightupperleg = {"rightupperleg", "rightleg", "legright", "rightleg1", "legr"},
    rightlowerleg = {"rightlowerleg", "rightleg", "legright", "rightleg2"},
    rightfoot = {"rightfoot", "rightleg", "footright"}
}

BuildEntitySkinMap = function(model, avatar)
    local sourceParts, sourceList = {}, {}
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local key = NormalizeEntityPartName(part.Name)
            sourceParts[key] = sourceParts[key] or part
            if part.Name ~= "HumanoidRootPart" then
                sourceList[#sourceList + 1] = part
            end
        end
    end

    local map, used = {}, {}
    local _, avatarSize = avatar:GetBoundingBox()
    local _, entitySize = model:GetBoundingBox()
    local avatarPivot, entityPivot = avatar:GetPivot(), model:GetPivot()

    for _,avatarPart in ipairs(avatar:GetDescendants()) do
        if avatarPart:IsA("BasePart") and avatarPart.Name ~= "HumanoidRootPart" then
            local key = NormalizeEntityPartName(avatarPart.Name)
            local source = sourceParts[key]
            if not source then
                for _,alias in ipairs(EntityPartAliases[key] or {}) do
                    source = sourceParts[NormalizeEntityPartName(alias)]
                    if source then break end
                end
            end

            if not source and #sourceList > 0 then
                local rel = avatarPivot:PointToObjectSpace(avatarPart.Position)
                local target = Vector3.new(
                    rel.X / math.max(avatarSize.X, 0.01),
                    rel.Y / math.max(avatarSize.Y, 0.01),
                    rel.Z / math.max(avatarSize.Z, 0.01)
                )
                local bestScore = math.huge
                for _,candidate in ipairs(sourceList) do
                    if not used[candidate] then
                        local pos = entityPivot:PointToObjectSpace(candidate.Position)
                        local normalized = Vector3.new(
                            pos.X / math.max(entitySize.X, 0.01),
                            pos.Y / math.max(entitySize.Y, 0.01),
                            pos.Z / math.max(entitySize.Z, 0.01)
                        )
                        local score = (target - normalized).Magnitude
                        local volume = candidate.Size.X * candidate.Size.Y * candidate.Size.Z
                        if volume < 0.002 then score = score + 2 end
                        if score < bestScore then
                            bestScore, source = score, candidate
                        end
                    end
                end
            end
            if source then
                map[avatarPart] = source
                used[source] = true
            end
        end
    end
    return map
end

local function BuildEntityAccessoryMap(avatar, partMap)
    local attachmentOwners = {}
    for avatarPart, sourcePart in pairs(partMap or {}) do
        if avatarPart and avatarPart.Parent and sourcePart and sourcePart.Parent then
            for _,obj in ipairs(avatarPart:GetChildren()) do
                if obj:IsA("Attachment") then
                    attachmentOwners[obj.Name] = sourcePart
                end
            end
        end
    end

    local accessoryMap = {}
    for _,obj in ipairs(avatar:GetDescendants()) do
        if obj:IsA("Accessory") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                for _,handleAttachment in ipairs(handle:GetChildren()) do
                    if handleAttachment:IsA("Attachment") then
                        local targetPart = attachmentOwners[handleAttachment.Name]
                        if targetPart then
                            accessoryMap[#accessoryMap + 1] = {
                                Handle = handle,
                                HandleAttachment = handleAttachment,
                                TargetPart = targetPart
                            }
                            break
                        end
                    end
                end
            end
        end
    end
    return accessoryMap
end

local function SyncEntityAccessories(record)
    for _,entry in ipairs(record.AccessoryMap or {}) do
        local handle = entry.Handle
        local attachment = entry.HandleAttachment
        local targetPart = entry.TargetPart
        if handle and handle.Parent and attachment and attachment.Parent
        and targetPart and targetPart.Parent then
            pcall(function()
                handle.CFrame = targetPart.CFrame
                    * attachment.CFrame:Inverse()
            end)
        end
    end
end

local function SyncEntitySkinPose(model, record)
    if not record or not record.Avatar or not record.Avatar.Parent then return end
    local avatar = record.Avatar
    pcall(function() avatar:PivotTo(model:GetPivot()) end)

    for avatarPart, sourcePart in pairs(record.PartMap or {}) do
        if avatarPart and avatarPart.Parent and sourcePart and sourcePart.Parent then
            pcall(function()
                avatarPart.CFrame = sourcePart.CFrame
            end)
        end
    end

    SyncEntityAccessories(record)
end

local function RefreshEntitySkins()
    if not Settings.EntitySkin then
        for model in pairs(EntitySkinObjects) do
            RemoveEntitySkin(model)
        end
        return
    end

    for model in pairs(Buckets.entity) do
        if model and model.Parent and model:IsDescendantOf(Workspace) then
            if not EntitySkinObjects[model] then
                ApplyEntitySkin(model)
            else
                local record = EntitySkinObjects[model]
                SyncEntitySkinPose(model, record)
            end
        else
            RemoveEntitySkin(model)
        end
    end

    for model in pairs(EntitySkinObjects) do
        if not model or not model.Parent or not model:IsDescendantOf(Workspace) then
            RemoveEntitySkin(model)
        end
    end
end

CleanupHooks[#CleanupHooks + 1] = function()
    for model in pairs(EntitySkinObjects) do
        RemoveEntitySkin(model)
    end
end

Track(RunService.Heartbeat:Connect(function()
    if Settings.EntitySkin then
        RefreshEntitySkins()
    end
end))

AddButton("ESP","ESP Portas (somente Door)","Doors",function(v)
    if not v then RemoveCategory("DOOR") end
end)

AddButton("ESP","ESP Livros (LiveHintBook)","Books",function(v)
    if not v then RemoveCategory("BOOK") end
end)

AddButton("ESP","ESP Alavanca (LeverForGate)","Lever",function(v)
    if not v then RemoveCategory("LEVER") end
end)

AddButton("ESP","ESP Itens","Items",function(v)
    if not v then RemoveCategory("ITEM") end
end)

AddButton("ESP","ESP PLAYERS","Players",function(v)
    if v then PE_Enable() else PE_Disable() end
end)

AddButton("ESP","ESP BATTERIES","Batteries",function(v)
    if v then BE_Enable() else BE_Disable() end
end)

AddButton("ENTIDADES","ESP Entidades","Entities",function(v)
    if not v then RemoveCategory("ENTITY") end
end)

AddButton("ENTIDADES","Skin do jogador nas entidades","EntitySkin",function(v)
    if not v then
        RefreshEntitySkins()
    else
        RefreshEntitySkins()
    end
end)

AddButton("ENTIDADES","Notificador de entidades","Notifier",function(v)
end)

AddAction("ITENS","Informação: candle_medium removido",function()
    Notify("candle_medium não será detectado")
end)

AddAction("ITENS","Atualizar busca de itens",function()
    task.spawn(function()
        pcall(Scan)
        Notify("BUSCA ATUALIZADA")
    end)
end)

AddButton("PLAYER","Speed","Speed")

AddAction("PLAYER","Aumentar velocidade",function()
    Settings.SpeedValue = Settings.SpeedValue + 5

    if Settings.SpeedValue > 50 then
        Settings.SpeedValue = 16
    end

    SaveSettings()
    Notify("SPEED: "..Settings.SpeedValue)
end)

AddAction("PLAYER","Velocidade padrão: 16",function()
    Settings.SpeedValue = 16
    SaveSettings()
    Notify("VELOCIDADE: 16")
end)

Track(RunService.Heartbeat:Connect(function()
    if not Settings.Speed then return end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = Settings.SpeedValue
    end
end))

local originalShadows = Lighting.GlobalShadows
local originalFog = Lighting.FogEnd

AddButton("EXTRAS","Otimizador","Optimize",function(v)
    if v then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.GlobalShadows = originalShadows
        Lighting.FogEnd = originalFog
    end
end)

AddAction("EXTRAS","Limpar ESP",function()
    ClearESPObjects()

    for _,data in pairs(PlayerESP.Data) do
        PE_DestroyVisuals(data)
    end
    BE_ClearVisuals()

    PE_Rebuild()

    Notify("ESP LIMPO")
end)

CleanupHooks[#CleanupHooks + 1] = function()
    if Settings.Optimize then
        Lighting.GlobalShadows = originalShadows
        Lighting.FogEnd = originalFog
    end
end

local DiagnosePrompts

AddButton("AUTO","AUTO KEY","AutoKey",function(v)
end)

AddButton("AUTO","AUTO ITEMS","AutoItems",function(v)
end)

AddButton("AUTO","AUTO COINS","AutoCoins",function(v)
end)

AddButton("AUTO","AUTO DRESSER/TABLE","AutoDrawers",function(v)
end)

AddAction("AUTO","Diagnóstico prompts próximos (console)",function()
    DiagnosePrompts()
end)

AddButton("CONFIG","Salvar configurações","SaveConfig",function(v)
    if v then
        SaveSettings(true)
        Notify("CONFIGURAÇÕES SERÃO SALVAS")
    else
        SaveSettings(true)
        Notify("SALVAMENTO AUTOMÁTICO DESATIVADO")
    end
end)

AddAction("CONFIG","Salvar agora",function()
    if type(writefile) ~= "function" then
        Notify("EXECUTOR SEM SUPORTE A writefile")
        return
    end
    SaveSettings(true)
    Notify("CONFIGURAÇÕES SALVAS")
end)

AddAction("CONFIG","Restaurar padrão",function()
    for _,key in ipairs(ConfigKeys) do
        if key == "SpeedValue" then
            Settings[key] = 20
        else
            Settings[key] = false
        end
    end
    Settings.SaveConfig = true
    SaveSettings()
    Notify("PADRÕES APLICADOS; REEXECUTE O SCRIPT")
end)

local UnlockWords = {
    "unlock","destranc","desbloque","use key","usar chave",
    "picklock","pick lock"
}
local HideWords = {"hide","esconder"}
local PickupWords = {
    "take","collect","pick up","pickup","grab",
    "pegar","coletar","loot"
}
local OpenWords = {"open","search","abrir"}

local function GetChain(prompt,maxDepth)
    local chain = {}
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local current = prompt.Parent

    for depth = 1,(maxDepth or 6) do
        if not current or current == Workspace or current == game then
            break
        end

        if rooms and current.Parent == rooms then break end

        chain[#chain + 1] = {
            Inst = current,
            Name = Norm(current.Name),
            Depth = depth
        }

        current = current.Parent
    end

    return chain
end

local function NearestDepth(chain,predicate)
    for _,node in ipairs(chain) do
        if predicate(node.Name,node.Inst) then
            return node.Depth
        end
    end
end

local ClosetWords = {
    "wardrobe","closet","cabinet","armoire",
    "cupboard","locker","armario","hidingspot"
}

local function IsDoorName(n)
    return n == "door" or n:find("^door") ~= nil
end

local function IsLockNodeName(n)
    if n == "lock" or n == "doorlock" then return true end

    return n:find("^lock") ~= nil
        and not n:find("lockpick",1,true)
        and not n:find("locker",1,true)
end

local function IsClosetName(n) return HasAny(n,ClosetWords) end
local function IsDrawerName(n) return n:find("drawer",1,true) ~= nil end

local function IsDresserOrTableName(n)
    return n:find("dresser",1,true) ~= nil
        or n:find("table",1,true) ~= nil
end

local function IsPadlockName(n)
    return n:find("padlock",1,true) ~= nil
        or n:find("keypad",1,true) ~= nil
        or n:find("^code") ~= nil
end

local function IsCoinName(n)
    return n == "coin" or n == "coins"
        or n == "gold" or n == "goldpile"
        or n == "goldcoin" or n == "goldcoins"
        or n == "coinpile"
        or n:match("^goldpile%d+$") ~= nil
        or n:match("^coin%d+$") ~= nil
        or n:match("^gold%d+$") ~= nil
end

local ItemPrefixes = {
    {"lighter","Lighter"},
    {"flashlight","Flashlight"},
    {"crucifix","Crucifix"},
    {"vitamin","Vitamins"},
    {"lockpick","Lockpick"},
    {"shears","Shears"},
    {"bandage","Bandage"},
    {"candle","Candle"},
    {"livebreakerpolepickup","Batteries"},
    {"battery","Batteries"},
    {"batteries","Batteries"},
    {"key","Keys"}
}

local ItemExcludes = {
    "keyhole","keypad","keyboard","keycard",
    "candlemedium","candlestick","candleholder","candlestand"
}

local function ItemCategory(n)
    for _,entry in ipairs(ItemPrefixes) do
        if n:find("^"..entry[1]) then
            if HasAny(n,ItemExcludes) then return nil end
            return entry[2]
        end
    end

    return nil
end

local function HasHidePrompt(node)
    local count = 0

    for _,descendant in ipairs(node:GetDescendants()) do
        count = count + 1
        if count > 200 then break end

        if descendant:IsA("ProximityPrompt") then
            local action = (descendant.ActionText or ""):lower()

            if HasAny(action,HideWords)
            or Norm(descendant.Name):find("hide",1,true) then
                return true
            end
        end
    end

    return false
end

local function ClassifyKey(prompt,chain,text)
    local pname = Norm(prompt.Name)

    if IsPadlockName(pname) then return false end
    for _,node in ipairs(chain) do
        if IsPadlockName(node.Name) then return false end
    end

    if HasAny(text.action,HideWords) or HasAny(text.action,PickupWords) then
        return false
    end

    local doorDepth = NearestDepth(chain,IsDoorName)
    if not doorDepth then return false end

    local lockDepth = NearestDepth(chain,IsLockNodeName)

    local foreignDepth = NearestDepth(chain,function(n)
        return ItemCategory(n) or IsCoinName(n)
            or IsDrawerName(n) or IsClosetName(n)
    end)

    local anchor = lockDepth or doorDepth
    if foreignDepth and foreignDepth <= anchor then return false end

    local unlockText = HasAny(text.action,UnlockWords)
        or HasAny(text.object,UnlockWords)
    local unlockName = pname:find("unlock",1,true) ~= nil

    if unlockText or unlockName then return true end

    if lockDepth and text.action == "" then return true end

    return false
end

local function ClassifyItem(prompt,chain,text)
    if HasAny(text.action,UnlockWords)
    or HasAny(text.action,HideWords)
    or HasAny(text.action,OpenWords) then
        return false
    end

    local itemDepth
    for _,node in ipairs(chain) do
        if ItemCategory(node.Name)
        and (node.Inst:IsA("Model") or node.Inst:IsA("Tool")
            or node.Inst:IsA("BasePart")) then
            itemDepth = node.Depth
            break
        end
    end

    if not itemDepth then return false end

    local vetoDepth = NearestDepth(chain,function(n)
        return IsDoorName(n) or IsLockNodeName(n) or IsDrawerName(n)
            or IsClosetName(n) or IsCoinName(n) or IsPadlockName(n)
    end)

    if vetoDepth and vetoDepth <= itemDepth then return false end

    return true
end

local function ClassifyCoin(prompt,chain,text)
    if HasAny(text.action,UnlockWords)
    or HasAny(text.action,HideWords)
    or HasAny(text.action,OpenWords) then
        return false
    end

    local coinDepth = NearestDepth(chain,IsCoinName)
    if not coinDepth then return false end

    local vetoDepth = NearestDepth(chain,function(n)
        return IsDoorName(n) or IsLockNodeName(n) or IsDrawerName(n)
            or IsClosetName(n) or ItemCategory(n) ~= nil or IsPadlockName(n)
    end)

    if vetoDepth and vetoDepth <= coinDepth then return false end

    return true
end

local function ClassifyDrawer(prompt,chain,text)
    if HasAny(text.action,HideWords)
    or HasAny(text.action,UnlockWords)
    or HasAny(text.action,PickupWords) then
        return false
    end

    local pname = Norm(prompt.Name)
    if pname:find("hide",1,true) or IsPadlockName(pname) then
        return false
    end

    local furnitureDepth,furnitureNode
    for _,node in ipairs(chain) do
        if IsDresserOrTableName(node.Name) then
            furnitureDepth = node.Depth
            furnitureNode = node.Inst
            break
        end
    end

    if not furnitureDepth then return false end

    for _,node in ipairs(chain) do
        local n = node.Name

        if IsDoorName(n) or IsPadlockName(n) or IsLockNodeName(n) then
            return false
        end

        if node.Depth < furnitureDepth and IsDrawerName(n) then
            return false
        end

        if IsClosetName(n) then
            return false
        end

        if node.Depth < furnitureDepth
        and (ItemCategory(n) or IsCoinName(n)) then
            return false
        end
    end

    if furnitureNode and (furnitureNode:IsA("Model") or furnitureNode:IsA("Folder"))
    and HasHidePrompt(furnitureNode) then
        return false
    end

    return true
end

local function FindKeyTools()
    local keyTool,lockpickTool

    local function check(container)
        if not container then return end

        for _,tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = Norm(tool.Name)

                if n:find("lockpick",1,true) then
                    lockpickTool = lockpickTool or tool
                elseif n:find("^key") and not HasAny(n,ItemExcludes) then
                    keyTool = keyTool or tool
                end
            end
        end
    end

    check(Player.Character)
    check(Player:FindFirstChildOfClass("Backpack"))

    return keyTool,lockpickTool
end

local function PrepareKey()
    local keyTool,lockpickTool = FindKeyTools()

    if keyTool then return true end

    if lockpickTool then
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and lockpickTool.Parent ~= character then
            pcall(function() humanoid:EquipTool(lockpickTool) end)
            task.wait(0.15)
        end

        return true
    end

    return false
end

local HasFirePrompt = type(fireproximityprompt) == "function"

local function FirePrompt(prompt)
    if HasFirePrompt then
        if pcall(fireproximityprompt,prompt) then
            return true
        end
    end

    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration,0) + 0.05)
        prompt:InputHoldEnd()
    end)
end

if not HasFirePrompt then
    task.delay(1,function()
        Notify("fireproximityprompt indisponível: modo alternativo")
    end)
end

local AutoSystems = {
    {Name = "AutoKey",Setting = "AutoKey",Classify = ClassifyKey,
        Prepare = PrepareKey,Interval = 0.35,Cooldown = 0.9,Attempts = 2},
    {Name = "AutoItems",Setting = "AutoItems",Classify = ClassifyItem,
        Interval = 0.12,Cooldown = 0.35,Attempts = 2},
    {Name = "AutoCoins",Setting = "AutoCoins",Classify = ClassifyCoin,
        Interval = 0.10,Cooldown = 0.30,Attempts = 2},
    {Name = "AutoDrawers",Setting = "AutoDrawers",Classify = ClassifyDrawer,
        Interval = 0.25,Cooldown = 0.50,Attempts = 1}
}

local ShownPrompts = {}
local PromptActive = {}
local PromptNext = {}

task.spawn(function()
    while Running do
        task.wait(20)

        for prompt in pairs(ShownPrompts) do
            if not prompt.Parent then ShownPrompts[prompt] = nil end
        end

        for prompt,untilTime in pairs(PromptNext) do
            if not prompt.Parent or os.clock() > untilTime then
                PromptNext[prompt] = nil
            end
        end
    end
end)
local LastFire = {}

DiagnosePrompts = function()
    local count = 0

    for prompt in pairs(ShownPrompts) do
        if prompt.Parent then
            count = count + 1

            local chain = GetChain(prompt,6)
            local names = {}
            for _,node in ipairs(chain) do
                names[#names + 1] = node.Inst.Name.."["..node.Inst.ClassName.."]"
            end

            local text = {
                action = (prompt.ActionText or ""):lower(),
                object = (prompt.ObjectText or ""):lower()
            }

            local result = {}
            for _,system in ipairs(AutoSystems) do
                local ok,matched = pcall(system.Classify,prompt,chain,text)
                result[#result + 1] = system.Name.."="..tostring(ok and matched)
            end

            print(string.format("[LK PROMPT] %s | acao=%q obj=%q | cadeia: %s | %s",
                prompt.Name,prompt.ActionText or "",prompt.ObjectText or "",
                table.concat(names," < "),table.concat(result,", ")))
        end
    end

    print("[LK PROMPT] prompts visiveis:",count)
    Notify("DIAGNÓSTICO NO CONSOLE ("..count..")")
end

local function StartAuto(system,prompt)
    PromptActive[prompt] = system.Name

    task.spawn(function()
        pcall(function()
            for _ = 1,system.Attempts do
                if not Running or not Settings[system.Setting] then break end
                if not prompt.Parent or not prompt.Enabled
                or not ShownPrompts[prompt] then
                    break
                end

                if system.Prepare and not system.Prepare(prompt) then
                    break
                end

                local remaining = system.Interval
                    - (os.clock() - (LastFire[system.Name] or 0))

                if remaining > 0 then task.wait(remaining) end

                if not prompt.Parent or not prompt.Enabled
                or not Settings[system.Setting] then
                    break
                end

                LastFire[system.Name] = os.clock()
                FirePrompt(prompt)

                task.wait(system.Cooldown)
            end
        end)

        PromptActive[prompt] = nil
        PromptNext[prompt] = os.clock() + 0.75
    end)
end

Track(ProximityPromptService.PromptHidden:Connect(function(prompt)
    ShownPrompts[prompt] = nil
end))

Track(ProximityPromptService.PromptShown:Connect(function(prompt)
    if not Running or not prompt or not prompt.Parent then return end

    ShownPrompts[prompt] = true

    if PromptActive[prompt] then return end

    local nextAllowed = PromptNext[prompt]
    if nextAllowed and os.clock() < nextAllowed then return end

    local anyEnabled = false
    for _,system in ipairs(AutoSystems) do
        if Settings[system.Setting] then
            anyEnabled = true
            break
        end
    end

    if not anyEnabled then return end

    local ok = pcall(function()
        local chain = GetChain(prompt,6)
        local text = {
            action = (prompt.ActionText or ""):lower(),
            object = (prompt.ObjectText or ""):lower()
        }

        for _,system in ipairs(AutoSystems) do
            if Settings[system.Setting] then
                local classified,matched = pcall(system.Classify,prompt,chain,text)

                if classified and matched then
                    StartAuto(system,prompt)
                    return
                end
            end
        end
    end)

    if not ok then
        PromptNext[prompt] = os.clock() + 2
    end
end))

local CodeGui = Instance.new("ScreenGui")
CodeGui.Name = "LKAutoCode50"
CodeGui.ResetOnSpawn = false
CodeGui.Parent = CoreGui

CleanupHooks[#CleanupHooks + 1] = function() SafeDestroy(CodeGui) end

local CodeFrame = Instance.new("Frame")
CodeFrame.Name = "CodePanel"
CodeFrame.AnchorPoint = Vector2.new(1,0)
CodeFrame.Position = UDim2.new(1,-6,0.28,0)
CodeFrame.Size = UDim2.fromOffset(150,108)
CodeFrame.BackgroundColor3 = Dark
CodeFrame.BorderSizePixel = 0
CodeFrame.Parent = CodeGui

Instance.new("UICorner",CodeFrame).CornerRadius = UDim.new(0,10)

local CodeStroke = Instance.new("UIStroke")
CodeStroke.Color = Color3.fromRGB(95,60,145)
CodeStroke.Thickness = 1.3
CodeStroke.Parent = CodeFrame

local CodeHeader = Instance.new("Frame")
CodeHeader.Size = UDim2.new(1,0,0,24)
CodeHeader.BackgroundColor3 = Panel
CodeHeader.BorderSizePixel = 0
CodeHeader.Parent = CodeFrame

Instance.new("UICorner",CodeHeader).CornerRadius = UDim.new(0,10)

local CodeTitle = Instance.new("TextLabel")
CodeTitle.Position = UDim2.fromOffset(8,0)
CodeTitle.Size = UDim2.new(1,-34,1,0)
CodeTitle.BackgroundTransparency = 1
CodeTitle.Text = "LK AUTO CODE 50"
CodeTitle.TextColor3 = White
CodeTitle.Font = Enum.Font.GothamBlack
CodeTitle.TextSize = 10
CodeTitle.TextXAlignment = Enum.TextXAlignment.Left
CodeTitle.Parent = CodeHeader

local CodeMin = Instance.new("TextButton")
CodeMin.Size = UDim2.fromOffset(22,18)
CodeMin.Position = UDim2.new(1,-25,0,3)
CodeMin.BackgroundColor3 = ButtonColor
CodeMin.Text = "—"
CodeMin.TextColor3 = White
CodeMin.Font = Enum.Font.GothamBold
CodeMin.TextSize = 12
CodeMin.Parent = CodeHeader

Instance.new("UICorner",CodeMin).CornerRadius = UDim.new(0,6)

local DigitRow = Instance.new("Frame")
DigitRow.Position = UDim2.fromOffset(8,30)
DigitRow.Size = UDim2.new(1,-16,0,32)
DigitRow.BackgroundTransparency = 1
DigitRow.Parent = CodeFrame

local DigitLayout = Instance.new("UIListLayout")
DigitLayout.FillDirection = Enum.FillDirection.Horizontal
DigitLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
DigitLayout.Padding = UDim.new(0,4)
DigitLayout.Parent = DigitRow

local DigitLabels = {}

for index = 1,5 do
    local box = Instance.new("TextLabel")
    box.Size = UDim2.fromOffset(23,32)
    box.BackgroundColor3 = ButtonColor
    box.Text = "-"
    box.TextColor3 = White
    box.Font = Enum.Font.GothamBlack
    box.TextSize = 18
    box.LayoutOrder = index
    box.Parent = DigitRow

    Instance.new("UICorner",box).CornerRadius = UDim.new(0,6)

    DigitLabels[index] = box
end

local CodeStatus = Instance.new("TextLabel")
CodeStatus.Position = UDim2.fromOffset(6,66)
CodeStatus.Size = UDim2.new(1,-12,0,22)
CodeStatus.BackgroundTransparency = 1
CodeStatus.Text = ""
CodeStatus.TextColor3 = Purple
CodeStatus.Font = Enum.Font.GothamBold
CodeStatus.TextSize = 9
CodeStatus.TextWrapped = true
CodeStatus.Parent = CodeFrame

local CodeSub = Instance.new("TextLabel")
CodeSub.Position = UDim2.fromOffset(6,88)
CodeSub.Size = UDim2.new(1,-12,0,16)
CodeSub.BackgroundTransparency = 1
CodeSub.Text = ""
CodeSub.TextColor3 = Color3.fromRGB(170,170,190)
CodeSub.Font = Enum.Font.Gotham
CodeSub.TextSize = 8
CodeSub.TextWrapped = true
CodeSub.Parent = CodeFrame

local CodeMini = Instance.new("TextButton")
CodeMini.Name = "CodeMini"
CodeMini.AnchorPoint = Vector2.new(1,0)
CodeMini.Position = UDim2.new(1,-6,0.28,0)
CodeMini.Size = UDim2.fromOffset(38,30)
CodeMini.BackgroundColor3 = Purple
CodeMini.Text = "50"
CodeMini.TextColor3 = White
CodeMini.Font = Enum.Font.GothamBlack
CodeMini.TextSize = 13
CodeMini.Visible = false
CodeMini.Parent = CodeGui

Instance.new("UICorner",CodeMini).CornerRadius = UDim.new(0,8)

CodeMin.Activated:Connect(function()
    CodeFrame.Visible = false
    CodeMini.Visible = true
end)

CodeMini.Activated:Connect(function()
    CodeFrame.Visible = true
    CodeMini.Visible = false
end)

local CodeState = {
    InLibrary = false,
    Since = 0,
    Slots = {},
    Conflict = {}
}

local SEARCH_TIMEOUT = 20

local function GetLibraryRoom()
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local room = rooms and rooms:FindFirstChild("50")
    if not room then return nil end

    for book in pairs(Buckets.book) do
        if book.Parent and book:IsDescendantOf(room) then
            return room
        end
    end

    if room:FindFirstChild("LiveHintBook",true) then
        return room
    end

    return nil
end

local function PlayerInsideRoom(room)
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local ok,boxCFrame,boxSize = pcall(function()
        return room:GetBoundingBox()
    end)

    if ok and boxCFrame and boxSize then
        local rel = boxCFrame:PointToObjectSpace(root.Position)
        local pad = 12

        return math.abs(rel.X) <= boxSize.X/2 + pad
            and math.abs(rel.Y) <= boxSize.Y/2 + pad
            and math.abs(rel.Z) <= boxSize.Z/2 + pad
    end

    local data = ReplicatedStorage:FindFirstChild("GameData")
    local latest = data and data:FindFirstChild("LatestRoom")

    return latest ~= nil and latest.Value == 50
end

local function KeyNorm(key)
    return (tostring(key):lower():gsub("[^%w]",""))
end

local CompleteKeys = {
    code = true,libcode = true,librarycode = true,padlockcode = true,
    answer = true,solution = true,correctcode = true,actualcode = true,
    finalcode = true,secretcode = true,combination = true
}

local SlotPrefixes = {"digit","code","hint","number","num","slot","pos","d","n"}
local SlotKeys = {index = true,slot = true,position = true,order = true,pos = true}
local DigitKeys = {digit = true,number = true,value = true,num = true}

local function DigitFrom(value)
    if type(value) == "number" then
        if value >= 0 and value <= 9 and value % 1 == 0 then return value end
        return nil
    end

    if type(value) == "string" and value:match("^%d$") then
        return tonumber(value)
    end

    return nil
end

local function FiveFrom(value)
    if type(value) == "number" then
        if value >= 10000 and value <= 99999 and value % 1 == 0 then
            return string.format("%d",value)
        end
        return nil
    end

    if type(value) == "string" then
        if not value:match("^[%d%s%-]+$") then return nil end

        local digits = value:gsub("[%s%-]","")
        if #digits == 5 then return digits end
    end

    return nil
end

local function AddEvidence(evidence,slot,digit)
    evidence[slot] = evidence[slot] or {}
    evidence[slot][digit] = true
end

local function ConsiderKV(evidence,key,value)
    local nk = KeyNorm(key)

    if CompleteKeys[nk] then
        local five = FiveFrom(value)

        if five then
            for slot = 1,5 do
                AddEvidence(evidence,slot,tonumber(five:sub(slot,slot)))
            end
        end

        return
    end

    for _,prefix in ipairs(SlotPrefixes) do
        local slot = nk:match("^"..prefix.."(%d)$")

        if slot then
            slot = tonumber(slot)
            local digit = DigitFrom(value)

            if slot >= 1 and slot <= 5 and digit then
                AddEvidence(evidence,slot,digit)
            end

            return
        end
    end
end

local RelevantWords = {
    "code","hint","digit","padlock","clue",
    "answer","number","solution","paper","book"
}

local function RelevantName(name)
    return HasAny(name:lower(),RelevantWords)
end

local function CollectInstance(evidence,instance)
    local className = instance.ClassName

    if className == "StringValue" or className == "IntValue"
    or className == "NumberValue" then
        local ok,value = pcall(function() return instance.Value end)
        if ok then ConsiderKV(evidence,instance.Name,value) end
    end

    local ok,attributes = pcall(function() return instance:GetAttributes() end)
    if not ok or not attributes then return end

    local pairSlot,pairDigit

    for key,value in pairs(attributes) do
        ConsiderKV(evidence,key,value)

        local nk = KeyNorm(key)

        if SlotKeys[nk] then
            local slot = DigitFrom(value)
            if slot and slot >= 1 and slot <= 5 then pairSlot = slot end
        elseif DigitKeys[nk] then
            pairDigit = DigitFrom(value) or pairDigit
        end
    end

    if pairSlot and pairDigit then
        AddEvidence(evidence,pairSlot,pairDigit)
    end
end

local function CollectRoom(evidence,room)
    local processed = 0

    for _,instance in ipairs(room:GetDescendants()) do
        processed = processed + 1
        if processed % 600 == 0 then task.wait() end

        if RelevantName(instance.Name) then
            CollectInstance(evidence,instance)
        end
    end
end

local GuiVetoWords = {
    "padlock","input","entry","keypad","lock","guess","selector","current"
}

local function CollectGui(evidence)
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end

    local processed = 0

    for _,instance in ipairs(playerGui:GetDescendants()) do
        processed = processed + 1
        if processed % 800 == 0 then task.wait() end

        if instance.ClassName == "TextLabel"
        and instance.Text:match("^%s*%d%s*$") then
            local slot = KeyNorm(instance.Name):match("^%a*(%d)$")
            slot = slot and tonumber(slot)

            if slot and slot >= 1 and slot <= 5 then
                local hinted,vetoed = false,false
                local current = instance.Parent

                for _ = 1,6 do
                    if not current or current == playerGui then break end

                    local ln = current.Name:lower()
                    if ln:find("hint",1,true) then hinted = true end
                    if HasAny(ln,GuiVetoWords) then vetoed = true end

                    current = current.Parent
                end

                if hinted and not vetoed then
                    AddEvidence(evidence,slot,tonumber(instance.Text:match("%d")))
                end
            end
        end
    end
end

local function RenderPanel(inside,elapsed)
    local confirmed,conflicts = 0,0

    if inside then
        for slot = 1,5 do
            if CodeState.Slots[slot] ~= nil then
                confirmed = confirmed + 1
            elseif CodeState.Conflict[slot] then
                conflicts = conflicts + 1
            end
        end
    end

    for slot = 1,5 do
        local label = DigitLabels[slot]
        local digit = CodeState.Slots[slot]

        if not inside then
            label.Text = "-"
        elseif digit ~= nil then
            label.Text = tostring(digit)
        elseif CodeState.Conflict[slot] then
            label.Text = "!"
        else
            label.Text = "?"
        end

        label.TextColor3 = (inside and digit ~= nil)
            and Color3.fromRGB(70,255,130) or White
        label.BackgroundColor3 = (inside and confirmed == 5)
            and Purple or ButtonColor
    end

    if not inside then
        CodeStatus.Text = "AGUARDANDO LIBRARY (SALA 50)"
        CodeSub.Text = ""
        CodeStatus.TextColor3 = Color3.fromRGB(170,170,190)
        return
    end

    CodeStatus.TextColor3 = Purple

    if confirmed == 5 then
        CodeStatus.Text = "CÓDIGO CONFIRMADO"
        CodeStatus.TextColor3 = Color3.fromRGB(70,255,130)
        CodeSub.Text = "lido de dados do cliente"
    elseif confirmed > 0 then
        CodeStatus.Text = "PARCIAL: "..confirmed.."/5 CONFIRMADOS"

        if conflicts > 0 then
            CodeSub.Text = "! = dados contraditórios"
        elseif elapsed >= SEARCH_TIMEOUT then
            CodeSub.Text = "demais dígitos não acessíveis"
        else
            CodeSub.Text = "? = ainda desconhecido"
        end
    elseif elapsed >= SEARCH_TIMEOUT then
        CodeStatus.Text = "NÃO FOI POSSÍVEL IDENTIFICAR O CÓDIGO"
        CodeSub.Text = "dados não acessíveis no cliente"
    else
        CodeStatus.Text = "PROCURANDO CÓDIGO..."
        CodeSub.Text = ""
    end
end

local function CodeStep()
    local room = GetLibraryRoom()
    local inside = room ~= nil and PlayerInsideRoom(room)

    if not inside then
        CodeState.InLibrary = false
        table.clear(CodeState.Slots)
        table.clear(CodeState.Conflict)
        RenderPanel(false,0)
        return
    end

    if not CodeState.InLibrary then
        CodeState.InLibrary = true
        CodeState.Since = os.clock()
        table.clear(CodeState.Slots)
        table.clear(CodeState.Conflict)
        RenderPanel(true,0)
    end

    local evidence = {}

    pcall(CollectRoom,evidence,room)
    pcall(CollectGui,evidence)

    local slots,conflict = {},{}

    for slot = 1,5 do
        local digits = evidence[slot]

        if digits then
            local count,only = 0,nil

            for digit in pairs(digits) do
                count = count + 1
                only = digit
            end

            if count == 1 then
                slots[slot] = only
            elseif count > 1 then
                conflict[slot] = true
            end
        end
    end

    for slot = 1,5 do
        if conflict[slot] then
            CodeState.Slots[slot] = nil
            CodeState.Conflict[slot] = true
        elseif slots[slot] ~= nil then
            CodeState.Slots[slot] = slots[slot]
            CodeState.Conflict[slot] = nil
        end
    end

    RenderPanel(true,os.clock() - CodeState.Since)
end

task.spawn(function()
    RenderPanel(false,0)

    while Running and CodeGui.Parent do
        local ok,err = pcall(CodeStep)

        if not ok then
            warn("LK AUTO CODE 50 ERROR:",err)
        end

        task.wait(CodeState.InLibrary and 2.5 or 2)
    end
end)

AddAction("EXTRAS","Diagnóstico Code 50 (console)",function()
    local lines = {}

    local function add(text)
        if #lines < 160 then lines[#lines + 1] = text end
    end

    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local room = rooms and rooms:FindFirstChild("50")

    add("[LK CODE50] sala 50 presente: "..tostring(room ~= nil))
    add("[LK CODE50] library detectada: "..tostring(GetLibraryRoom() ~= nil))

    if room then
        local prefix = room:GetFullName()

        for _,instance in ipairs(room:GetDescendants()) do
            local isValue = instance:IsA("ValueBase")

            if RelevantName(instance.Name) or isValue then
                local attrs = {}

                for key,value in pairs(instance:GetAttributes()) do
                    attrs[#attrs + 1] = key.."="..tostring(value)
                end

                local valueText = ""
                if isValue then
                    local ok,value = pcall(function() return instance.Value end)
                    if ok then valueText = " = "..tostring(value) end
                end

                add(string.format("  %s [%s]%s%s",
                    (instance:GetFullName():gsub(prefix,"",1)),
                    instance.ClassName,
                    valueText,
                    #attrs > 0 and (" {"..table.concat(attrs,", ").."}") or ""
                ))
            end
        end
    end

    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if playerGui then
        for _,instance in ipairs(playerGui:GetDescendants()) do
            if instance.ClassName == "TextLabel"
            and instance.Name:lower():find("hint",1,true) then
                add(string.format("  [GUI] %s = %q",
                    instance:GetFullName(),instance.Text))
            end
        end
    end

    for _,line in ipairs(lines) do
        print(line)
    end

    Notify("DIAGNÓSTICO ENVIADO AO CONSOLE")
end)

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.fromOffset(55,48)
OpenButton.Position = UDim2.new(0,10,0.5,0)
OpenButton.BackgroundColor3 = Purple
OpenButton.Text = "LK"
OpenButton.TextColor3 = White
OpenButton.Font = Enum.Font.GothamBlack
OpenButton.TextSize = 17
OpenButton.Visible = false
OpenButton.Parent = Gui

Instance.new("UICorner",OpenButton).CornerRadius = UDim.new(0,10)

Minimize.Activated:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

local dragging = false
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Track(UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then

        local delta = input.Position-dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,startPos.X.Offset+delta.X,
            startPos.Y.Scale,startPos.Y.Offset+delta.Y
        )
    end
end))

Track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

SelectTab("ESP")

task.spawn(function()
    while Running and Gui.Parent do
        if Settings.Entities or Settings.Doors
        or Settings.Items or Settings.Books
        or Settings.Lever or Settings.Notifier then

            local success,err = pcall(Scan)

            if not success then
                warn("LK DOORS SCAN ERROR:",err)
            end
        end

        task.wait(1.5)
    end
end)

Notify("LK DOORS V10.3 CARREGADO!")
print("LK DOORS SYSTEM V10.3 carregado!")
