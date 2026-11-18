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

local function Track(c) Connections[#Connections+1] = c; return c end
local function SafeDestroy(i) if i then pcall(function() i:Destroy() end) end end

local function Cleanup()
    Running = false
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    for _, hook in ipairs(CleanupHooks) do pcall(hook) end
end

pcall(function()
    local env = getgenv()
    if type(env.LK_DOORS_CLEANUP) == "function" then pcall(env.LK_DOORS_CLEANUP) end
    env.LK_DOORS_CLEANUP = Cleanup
end)

pcall(function()
    for _, name in ipairs({"LKDoorsSystem","LKAutoCode50"}) do
        local old = CoreGui:FindFirstChild(name)
        if old then old:Destroy() end
    end
end)

local Settings = {
    Entities=false, Doors=false, Items=false, Books=false, Lever=false,
    Notifier=false, Speed=false, Optimize=false, AutoKey=false, AutoItems=false,
    AutoCoins=false, AutoDrawers=false, Players=false, Batteries=false,
    EntitySkin=false, SpeedValue=20, SaveConfig=true
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
    local rok, raw = pcall(readfile, CONFIG_FILE)
    if not rok or type(raw) ~= "string" then return end
    local dok, saved = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or type(saved) ~= "table" then return end
    if saved.SaveConfig == false then Settings.SaveConfig = false; return end
    for _, key in ipairs(ConfigKeys) do
        if saved[key] ~= nil and typeof(Settings[key]) == typeof(saved[key]) then
            Settings[key] = saved[key]
        end
    end
    if typeof(saved.SaveConfig) == "boolean" then Settings.SaveConfig = saved.SaveConfig end
end

local function SaveSettings(force)
    if not Settings.SaveConfig and not force then return end
    if type(writefile) ~= "function" then return end
    local data = {SaveConfig = Settings.SaveConfig}
    for _, key in ipairs(ConfigKeys) do data[key] = Settings[key] end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(data)) end)
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
CleanupHooks[#CleanupHooks+1] = function() SafeDestroy(Gui) end

local Camera = Workspace.CurrentCamera
local viewport = Camera and Camera.ViewportSize or Vector2.new(800,600)
local width = math.clamp(viewport.X - 20, 320, 510)
local height = math.clamp(viewport.Y - 80, 280, 370)

local Main = Instance.new("Frame")
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
Subtitle.Text = "DOORS ORIGINAL  •  VERSION 10.4"
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
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10)
    end)
    Pages[name] = page
end

local function SelectTab(name)
    for tabName, page in pairs(Pages) do page.Visible = tabName == name end
    for tabName, button in pairs(TabButtons) do
        button.BackgroundColor3 = tabName == name and Purple or ButtonColor
    end
end

local function CreateTab(name, icon)
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
    button.Activated:Connect(function() SelectTab(name) end)
end

CreateTab("ESP","👁"); CreateTab("ENTIDADES","👻"); CreateTab("ITENS","🔑")
CreateTab("PLAYER","🏃"); CreateTab("EXTRAS","⚙"); CreateTab("AUTO","⚡"); CreateTab("CONFIG","⚙")

local function AddButton(pageName, name, key, callback)
    local page = Pages[pageName]; if not page then return end
    local button = Instance.new("TextButton")
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
    local function Paint()
        status.Text = enabled and "ON" or "OFF"
        status.BackgroundColor3 = enabled and Purple or Color3.fromRGB(65,65,80)
    end
    Paint()

    button.Activated:Connect(function()
        enabled = not enabled; Paint()
        if key then Settings[key] = enabled; SaveSettings() end
        if callback then
            local ok, err = pcall(callback, enabled)
            if not ok then warn("LK ["..name.."]:", err) end
        end
    end)

    if enabled and callback then
        task.defer(function()
            if Running and button.Parent then
                local ok, err = pcall(callback, true)
                if not ok then warn("LK INIT ["..name.."]:", err) end
            end
        end)
    end
    return button
end

local function AddAction(pageName, name, callback)
    local page = Pages[pageName]; if not page then return end
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
        local ok, err = pcall(callback)
        if not ok then warn("LK ACTION ["..name.."]:", err) end
    end)
end

local NotifCount = 0
local function Notify(message)
    NotifCount = NotifCount + 1
    local notice = Instance.new("Frame")
    notice.Size = UDim2.fromOffset(270,0)
    notice.AnchorPoint = Vector2.new(1,0)
    notice.Position = UDim2.new(1,-14,0,62 + ((NotifCount-1)%4)*62)
    notice.BackgroundColor3 = Panel
    notice.BorderSizePixel = 0
    notice.ClipsDescendants = true
    notice.Parent = Gui
    Instance.new("UICorner",notice).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Purple; stroke.Thickness = 1.5; stroke.Parent = notice
    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(12,5); title.Size = UDim2.new(1,-24,0,17)
    title.BackgroundTransparency = 1; title.Text = "LK DOORS SYSTEM"
    title.TextColor3 = Purple; title.TextSize = 11; title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = notice
    local ml = Instance.new("TextLabel")
    ml.Position = UDim2.fromOffset(12,24); ml.Size = UDim2.new(1,-24,0,23)
    ml.BackgroundTransparency = 1; ml.Text = tostring(message)
    ml.TextColor3 = White; ml.TextSize = 12; ml.Font = Enum.Font.GothamBold
    ml.TextXAlignment = Enum.TextXAlignment.Left
    ml.TextTruncate = Enum.TextTruncate.AtEnd; ml.Parent = notice
    TweenService:Create(notice, TweenInfo.new(0.35,Enum.EasingStyle.Back), {
        Size = UDim2.fromOffset(270,55),
        Position = UDim2.new(1,-14,0,62 + ((NotifCount-1)%4)*62)
    }):Play()
    task.delay(3.2, function()
        if not notice.Parent then return end
        local t = TweenService:Create(notice, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {
            Position = UDim2.new(1,285,0,62 + ((NotifCount-1)%4)*62),
            BackgroundTransparency = 1
        })
        TweenService:Create(title, TweenInfo.new(0.25), {TextTransparency=1}):Play()
        TweenService:Create(ml, TweenInfo.new(0.25), {TextTransparency=1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency=1}):Play()
        t:Play(); t.Completed:Wait(); notice:Destroy()
    end)
end

local function Norm(t) return (tostring(t):lower():gsub("[%s_%-%.]","")) end
local function HasAny(t, words)
    for _, w in ipairs(words) do if t:find(w,1,true) then return true end end
    return false
end

-- ESP Básico
local ESPObjects = {}
local EntityNames = {
    "rush","ambush","figure","seek","screech","a60","a120","blitz",
    "lookman","halt","dupe","dread","eyes","grumble","giggle"
}
local ItemNames = {
    "key","lighter","flashlight","crucifix","vitamin",
    "lockpick","shears","bandage","candle"
}

local function GetPart(o)
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
    if o:IsA("Tool") then return o:FindFirstChildWhichIsA("BasePart",true) end
end

local function IsEntity(name)
    local n = name:lower():gsub("[%s_%-]","")
    if n:find("painting",1,true) or n == "seekarm" or n:find("sideroom",1,true) then
        return false
    end
    for _, e in ipairs(EntityNames) do if n:find(e,1,true) then return true end end
    return false
end

local function IsItem(name)
    local n = name:lower()
    if n:find("candle_medium",1,true) then return false end
    for _, i in ipairs(ItemNames) do if n:find(i,1,true) then return true end end
    return false
end

local function AddESP(object, cat, color, label)
    if not object or not object.Parent or ESPObjects[object] then return end
    local h = Instance.new("Highlight")
    h.Adornee = object; h.FillColor = color; h.OutlineColor = color
    h.FillTransparency = 0.78; h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = Gui
    local part = GetPart(object); local bb
    if part then
        bb = Instance.new("BillboardGui")
        bb.Adornee = part
        bb.Size = UDim2.fromOffset(150,28)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        bb.Parent = Gui
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.fromScale(1,1); txt.BackgroundTransparency = 1
        txt.Text = label; txt.TextColor3 = color; txt.TextStrokeTransparency = 0
        txt.TextSize = 12; txt.Font = Enum.Font.GothamBold; txt.Parent = bb
    end
    ESPObjects[object] = {Category=cat, Highlight=h, Billboard=bb}
end

local function RemoveCategory(cat)
    for o, d in pairs(ESPObjects) do
        if d.Category == cat then
            SafeDestroy(d.Highlight); SafeDestroy(d.Billboard)
            ESPObjects[o] = nil
        end
    end
end

local function ClearESPObjects()
    for _, d in pairs(ESPObjects) do
        SafeDestroy(d.Highlight); SafeDestroy(d.Billboard)
    end
    table.clear(ESPObjects)
end
CleanupHooks[#CleanupHooks+1] = ClearESPObjects

local Buckets = {entity={}, book={}, lever={}, door={}, item={}, battery={}}
local BatteryNameExclude = {"charger","station","socket","slot","icon","indicator","meter","gauge"}

local function IsBatteryName(name)
    local n = Norm(name)
    if n:find("^livebreakerpolepickup") then return true end
    if not (n:find("^battery") or n:find("^batteries")) then return false end
    return not HasAny(n, BatteryNameExclude)
end

local function IndexObject(object)
    local name = object.Name
    local cls = object.ClassName
    if cls == "Model" or cls == "Tool" then
        if cls == "Model" and IsEntity(name) then Buckets.entity[object] = true end
        if name == "LiveHintBook" then Buckets.book[object] = true
        elseif name == "LeverForGate" then Buckets.lever[object] = true end
        if IsItem(name) then Buckets.item[object] = true end
        if IsBatteryName(name) then Buckets.battery[object] = true end
        return
    end
    local first = name:byte(1)
    if first == 68 or first == 76 or first == 66 or first == 98 then
        if not object:IsA("BasePart") then return end
        if name == "Door" then Buckets.door[object] = true
        elseif name == "LiveHintBook" then Buckets.book[object] = true
        elseif name == "LeverForGate" then Buckets.lever[object] = true
        elseif IsBatteryName(name) then Buckets.battery[object] = true end
    end
end

local SeenEntities = {}
local function EntitySpawned(object)
    if not object or not object:IsA("Model") then return end
    if not object.Parent or not IsEntity(object.Name) then return end
    if SeenEntities[object] then return end
    SeenEntities[object] = true
    if Settings.Notifier then Notify("ENTIDADE SPAWNOU: "..object.Name) end
end

Track(Workspace.DescendantAdded:Connect(function(o)
    pcall(IndexObject, o)
    if not o:IsA("Model") then return end
    task.delay(0.15, function()
        if Running and o.Parent then EntitySpawned(o) end
    end)
end))

Track(Workspace.DescendantRemoving:Connect(function(o)
    local wasEntity = Buckets.entity[o]
    for _, b in pairs(Buckets) do b[o] = nil end
    if wasEntity then
        task.delay(1, function()
            if not o:IsDescendantOf(Workspace) then SeenEntities[o] = nil end
        end)
    end
end))

task.spawn(function()
    local count = 0
    for _, o in ipairs(Workspace:GetDescendants()) do
        if not Running then return end
        pcall(IndexObject, o)
        if Buckets.entity[o] then SeenEntities[o] = true end
        count = count + 1
        if count % 1500 == 0 then task.wait() end
    end
end)

local function Scan()
    local desired = {}
    for o in pairs(Buckets.entity) do
        if not o:IsDescendantOf(Workspace) then Buckets.entity[o] = nil
        else
            EntitySpawned(o)
            if Settings.Entities then
                desired[o] = {"ENTITY", Color3.fromRGB(255,45,55), o.Name}
            end
        end
    end
    for o in pairs(Buckets.book) do
        if not o:IsDescendantOf(Workspace) then Buckets.book[o] = nil
        elseif Settings.Books then
            desired[o] = {"BOOK", Color3.fromRGB(40,255,110), "LIVRO"}
        end
    end
    for o in pairs(Buckets.lever) do
        if not o:IsDescendantOf(Workspace) then Buckets.lever[o] = nil
        elseif Settings.Lever then
            desired[o] = {"LEVER", Color3.fromRGB(255,165,30), "ALAVANCA"}
        end
    end
    for o in pairs(Buckets.door) do
        if not o:IsDescendantOf(Workspace) then Buckets.door[o] = nil
        elseif Settings.Doors then
            desired[o] = {"DOOR", Color3.fromRGB(40,170,255), "DOOR"}
        end
    end
    for o in pairs(Buckets.item) do
        if not o:IsDescendantOf(Workspace) then Buckets.item[o] = nil
        elseif Settings.Items then
            desired[o] = {"ITEM", Color3.fromRGB(255,220,35), o.Name}
        end
    end
    for o, info in pairs(desired) do
        if not ESPObjects[o] then AddESP(o, info[1], info[2], info[3]) end
    end
    for o, d in pairs(ESPObjects) do
        if not o.Parent or not desired[o] or desired[o][1] ~= d.Category then
            SafeDestroy(d.Highlight); SafeDestroy(d.Billboard)
            ESPObjects[o] = nil
        end
    end
end

-- Player ESP
local PlayerESP = {Active=false, Data={}, GlobalConns={}}
local function PE_DisconnectList(list)
    for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end
    table.clear(list)
end
local function PE_DestroyVisuals(d)
    SafeDestroy(d.Highlight); SafeDestroy(d.Billboard)
    d.Highlight = nil; d.Billboard = nil; d.NameLabel = nil
end
local function PE_Detach(d)
    PE_DestroyVisuals(d)
    if d.CharConn then pcall(function() d.CharConn:Disconnect() end); d.CharConn = nil end
    d.Char = nil
end
local function PE_Attach(player, d, character)
    PE_Detach(d)
    if not character or not PlayerESP.Active then return end
    d.Char = character
    local h = Instance.new("Highlight")
    h.Adornee = character
    h.FillColor = Purple; h.OutlineColor = Purple
    h.FillTransparency = 0.6; h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = Gui; d.Highlight = h
    d.CharConn = character.AncestryChanged:Connect(function(_, p)
        if not p and d.Char == character then PE_Detach(d) end
    end)
    task.spawn(function()
        local head = character:WaitForChild("Head", 10)
        if not head or d.Char ~= character or not PlayerESP.Active or d.Billboard then return end
        local bb = Instance.new("BillboardGui")
        bb.Adornee = head; bb.Size = UDim2.fromOffset(150,34)
        bb.StudsOffset = Vector3.new(0,2.6,0); bb.AlwaysOnTop = true; bb.Parent = Gui
        local dl = Instance.new("TextLabel")
        dl.Size = UDim2.new(1,0,0.55,0); dl.BackgroundTransparency = 1
        dl.Text = player.DisplayName; dl.TextColor3 = White
        dl.TextStrokeTransparency = 0; dl.TextSize = 13
        dl.Font = Enum.Font.GothamBold; dl.Parent = bb
        local ul = Instance.new("TextLabel")
        ul.Position = UDim2.fromScale(0,0.55); ul.Size = UDim2.new(1,0,0.45,0)
        ul.BackgroundTransparency = 1; ul.Text = "@"..player.Name
        ul.TextColor3 = Purple; ul.TextStrokeTransparency = 0
        ul.TextSize = 11; ul.Font = Enum.Font.GothamSemibold; ul.Parent = bb
        d.Billboard = bb; d.NameLabel = dl
    end)
end
local function PE_Track(player)
    if player == Player or PlayerESP.Data[player] then return end
    local d = {Conns={}}; PlayerESP.Data[player] = d
    d.Conns[#d.Conns+1] = player.CharacterAdded:Connect(function(c) PE_Attach(player, d, c) end)
    d.Conns[#d.Conns+1] = player.CharacterRemoving:Connect(function() PE_Detach(d) end)
    d.Conns[#d.Conns+1] = player:GetPropertyChangedSignal("DisplayName"):Connect(function()
        if d.NameLabel then d.NameLabel.Text = player.DisplayName end
    end)
    if player.Character then PE_Attach(player, d, player.Character) end
end
local function PE_Untrack(player)
    local d = PlayerESP.Data[player]; if not d then return end
    PE_Detach(d); PE_DisconnectList(d.Conns); PlayerESP.Data[player] = nil
end
local function PE_Disable()
    PlayerESP.Active = false
    PE_DisconnectList(PlayerESP.GlobalConns)
    for p in pairs(PlayerESP.Data) do PE_Untrack(p) end
end
local function PE_Enable()
    if PlayerESP.Active then return end
    PlayerESP.Active = true
    PlayerESP.GlobalConns[#PlayerESP.GlobalConns+1] = Players.PlayerAdded:Connect(PE_Track)
    PlayerESP.GlobalConns[#PlayerESP.GlobalConns+1] = Players.PlayerRemoving:Connect(PE_Untrack)
    for _, p in ipairs(Players:GetPlayers()) do PE_Track(p) end
end
local function PE_Rebuild()
    if not PlayerESP.Active then return end
    for p, d in pairs(PlayerESP.Data) do PE_Attach(p, d, p.Character) end
end
CleanupHooks[#CleanupHooks+1] = PE_Disable

-- Battery ESP (mantido igual, funcional)
local BatteryESP = {Active=false, Items={}, Token=nil}
local function IsInsideCharacter(o)
    local c = o.Parent
    for _ = 1,8 do
        if not c or c == Workspace then return false end
        if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then return true end
        c = c.Parent
    end
    return false
end
local function HasCollectPrompt(o)
    local function ok(p)
        local a = (p.ActionText or ""):lower()
        local n = Norm(p.Name)
        if HasAny(a, {"unlock","hide","open","destranc","esconder"}) then return false end
        if n:find("hide",1,true) or n:find("unlock",1,true) then return false end
        return true
    end
    if o:IsA("ProximityPrompt") then return ok(o) end
    local c = 0
    for _, d in ipairs(o:GetDescendants()) do
        c = c + 1; if c > 150 then break end
        if d:IsA("ProximityPrompt") and ok(d) then return true end
    end
    return false
end
local function ClassifyBattery(o)
    if not o.Parent or not o:IsDescendantOf(Workspace) then return false end
    if not (o:IsA("Model") or o:IsA("Tool") or o:IsA("BasePart")) then return false end
    if IsInsideCharacter(o) then return false end
    local a = o.Parent
    for _ = 1,3 do
        if not a or a == Workspace then break end
        if (a:IsA("Model") or a:IsA("Tool")) and IsBatteryName(a.Name) then return false end
        a = a.Parent
    end
    if not GetPart(o) then return false end
    if Norm(o.Name):find("^livebreakerpolepickup") then return true end
    if o:IsA("Tool") then return true end
    if o:IsA("BasePart") then
        local p = o:FindFirstChildOfClass("ProximityPrompt")
        return p ~= nil and HasCollectPrompt(p)
    end
    return HasCollectPrompt(o)
end
local function BE_Remove(o)
    local d = BatteryESP.Items[o]; if not d then return end
    SafeDestroy(d.Highlight); SafeDestroy(d.Billboard); BatteryESP.Items[o] = nil
end
local function BE_Add(o)
    if BatteryESP.Items[o] then return end
    local c = Color3.fromRGB(0,255,200)
    local h = Instance.new("Highlight")
    h.Adornee = o; h.FillColor = c; h.OutlineColor = c
    h.FillTransparency = 0.7; h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = Gui
    local bb, part = nil, GetPart(o)
    if part then
        bb = Instance.new("BillboardGui")
        bb.Adornee = part; bb.Size = UDim2.fromOffset(110,24)
        bb.StudsOffset = Vector3.new(0,2.5,0); bb.AlwaysOnTop = true; bb.Parent = Gui
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromScale(1,1); t.BackgroundTransparency = 1
        t.Text = "BATTERY"; t.TextColor3 = c; t.TextStrokeTransparency = 0
        t.TextSize = 12; t.Font = Enum.Font.GothamBold; t.Parent = bb
    end
    BatteryESP.Items[o] = {Highlight=h, Billboard=bb}
end
local function BE_Refresh()
    for o in pairs(Buckets.battery) do
        if not o:IsDescendantOf(Workspace) then
            Buckets.battery[o] = nil; BE_Remove(o)
        elseif ClassifyBattery(o) then BE_Add(o)
        else BE_Remove(o) end
    end
    for o in pairs(BatteryESP.Items) do
        if not o.Parent or not Buckets.battery[o] then BE_Remove(o) end
    end
end
local function BE_ClearVisuals() for o in pairs(BatteryESP.Items) do BE_Remove(o) end end
local function BE_Disable() BatteryESP.Active = false; BatteryESP.Token = nil; BE_ClearVisuals() end
local function BE_Enable()
    if BatteryESP.Active then return end
    BatteryESP.Active = true
    local token = {}; BatteryESP.Token = token
    task.spawn(function()
        while Running and BatteryESP.Token == token do
            pcall(BE_Refresh); task.wait(1)
        end
    end)
end
CleanupHooks[#CleanupHooks+1] = BE_Disable

-- ============================================================
-- ENTITY SKIN (CORRIGIDO E MELHORADO)
-- ============================================================
local EntitySkinObjects = {}
local BuildEntitySkinMap, BuildEntityAccessoryMap

local function NormalizePartName(name)
    return tostring(name or ""):lower():gsub("[^%w]","")
end

local EntityPartAliases = {
    head = {"head","skull","face"},
    uppertorso = {"uppertorso","torso","body","chest","mainbody"},
    lowertorso = {"lowertorso","torso","body","abdomen","mainbody"},
    leftupperarm = {"leftupperarm","leftarm","armleft","leftarm1","arml"},
    leftlowerarm = {"leftlowerarm","leftforearm","leftarm","armleft","leftarm2"},
    lefthand = {"lefthand","leftarm","handleft","leftclaw"},
    rightupperarm = {"rightupperarm","rightarm","armright","rightarm1","armr"},
    rightlowerarm = {"rightlowerarm","rightforearm","rightarm","armright","rightarm2"},
    righthand = {"righthand","rightarm","handright","rightclaw"},
    leftupperleg = {"leftupperleg","leftleg","legleft","leftleg1","legl"},
    leftlowerleg = {"leftlowerleg","leftleg","legleft","leftleg2"},
    leftfoot = {"leftfoot","leftleg","footleft"},
    rightupperleg = {"rightupperleg","rightleg","legright","rightleg1","legr"},
    rightlowerleg = {"rightlowerleg","rightleg","legright","rightleg2"},
    rightfoot = {"rightfoot","rightleg","footright"}
}

BuildEntitySkinMap = function(model, avatar)
    local sourceParts, sourceList = {}, {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local key = NormalizePartName(part.Name)
            sourceParts[key] = sourceParts[key] or part
            if part.Name ~= "HumanoidRootPart" then
                sourceList[#sourceList+1] = part
            end
        end
    end
    local map, used = {}, {}
    local _, avatarSize = avatar:GetBoundingBox()
    local _, entitySize = model:GetBoundingBox()
    local avatarPivot, entityPivot = avatar:GetPivot(), model:GetPivot()
    for _, ap in ipairs(avatar:GetDescendants()) do
        if ap:IsA("BasePart") and ap.Name ~= "HumanoidRootPart" then
            local key = NormalizePartName(ap.Name)
            local source = sourceParts[key]
            if not source then
                for _, alias in ipairs(EntityPartAliases[key] or {}) do
                    source = sourceParts[NormalizePartName(alias)]
                    if source then break end
                end
            end
            if not source and #sourceList > 0 then
                local rel = avatarPivot:PointToObjectSpace(ap.Position)
                local target = Vector3.new(
                    rel.X / math.max(avatarSize.X, 0.01),
                    rel.Y / math.max(avatarSize.Y, 0.01),
                    rel.Z / math.max(avatarSize.Z, 0.01)
                )
                local best = math.huge
                for _, c in ipairs(sourceList) do
                    if not used[c] then
                        local pos = entityPivot:PointToObjectSpace(c.Position)
                        local n = Vector3.new(
                            pos.X / math.max(entitySize.X, 0.01),
                            pos.Y / math.max(entitySize.Y, 0.01),
                            pos.Z / math.max(entitySize.Z, 0.01)
                        )
                        local score = (target - n).Magnitude
                        local vol = c.Size.X * c.Size.Y * c.Size.Z
                        if vol < 0.002 then score = score + 2 end
                        if score < best then best, source = score, c end
                    end
                end
            end
            if source then map[ap] = source; used[source] = true end
        end
    end
    return map
end

-- CORREÇÃO CRÍTICA: forward declare já feito acima (BuildEntityAccessoryMap)
-- e agora atribuímos via `= function` em vez de `local function`
BuildEntityAccessoryMap = function(avatar, partMap)
    local attachmentOwners = {}
    for ap, sourcePart in pairs(partMap or {}) do
        if ap and ap.Parent and sourcePart and sourcePart.Parent then
            for _, obj in ipairs(ap:GetChildren()) do
                if obj:IsA("Attachment") then
                    attachmentOwners[obj.Name] = {Part = sourcePart, Attachment = obj}
                end
            end
        end
    end
    local list = {}
    for _, obj in ipairs(avatar:GetDescendants()) do
        if obj:IsA("Accessory") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                for _, hAtt in ipairs(handle:GetChildren()) do
                    if hAtt:IsA("Attachment") then
                        local owner = attachmentOwners[hAtt.Name]
                        if owner then
                            list[#list+1] = {
                                Handle = handle,
                                HandleAttachment = hAtt,
                                TargetPart = owner.Part,
                                TargetAttachment = owner.Attachment
                            }
                            break
                        end
                    end
                end
            end
        end
    end
    return list
end

-- Ocultação robusta: BaseParts (LTM), Decals, Textures, Particles, Trails, Beams, Billboards, Highlights
local function HideEntityVisual(item, record, hide)
    if item:IsA("BasePart") then
        record.PartData = record.PartData or {}
        if record.PartData[item] == nil then
            record.PartData[item] = {
                LTM = item.LocalTransparencyModifier,
                Transparency = item.Transparency
            }
        end
        if hide then
            item.LocalTransparencyModifier = 1
            item.Transparency = 1
        else
            local d = record.PartData[item]
            item.LocalTransparencyModifier = d.LTM
            item.Transparency = d.Transparency
        end
    elseif item:IsA("Decal") or item:IsA("Texture") then
        record.DecalData = record.DecalData or {}
        if record.DecalData[item] == nil then
            record.DecalData[item] = item.Transparency
        end
        item.Transparency = hide and 1 or record.DecalData[item]
    elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam")
        or item:IsA("Smoke") or item:IsA("Fire") or item:IsA("Sparkles") then
        record.EnabledData = record.EnabledData or {}
        if record.EnabledData[item] == nil then
            record.EnabledData[item] = item.Enabled
        end
        item.Enabled = hide and false or record.EnabledData[item]
    elseif item:IsA("BillboardGui") then
        record.BillboardData = record.BillboardData or {}
        if record.BillboardData[item] == nil then
            record.BillboardData[item] = item.Enabled
        end
        item.Enabled = hide and false or record.BillboardData[item]
    elseif item:IsA("Highlight") then
        if not item.Name:find("LK_") then
            record.HighlightData = record.HighlightData or {}
            if record.HighlightData[item] == nil then
                record.HighlightData[item] = item.Enabled
            end
            item.Enabled = hide and false or record.HighlightData[item]
        end
    end
end

local function ApplyEntityVisuals(model, record, hide)
    for _, item in ipairs(model:GetDescendants()) do
        HideEntityVisual(item, record, hide)
    end
end

local function RemoveEntitySkin(model)
    local record = EntitySkinObjects[model]
    if not record then return end
    ApplyEntityVisuals(model, record, false)
    if record.DescendantConn then
        pcall(function() record.DescendantConn:Disconnect() end)
        record.DescendantConn = nil
    end
    SafeDestroy(record.Avatar)
    EntitySkinObjects[model] = nil
end

local function ApplyEntitySkin(model)
    if not Settings.EntitySkin or not model or not model:IsA("Model") then return end
    if not model.Parent or EntitySkinObjects[model] then return end

    local character = Player.Character
    if not character then return end

    local oldArch = character.Archivable
    local clone
    local ok = pcall(function()
        character.Archivable = true
        clone = character:Clone()
        character.Archivable = oldArch
    end)
    character.Archivable = oldArch
    if not ok or not clone then return end

    clone.Name = "LK_EntityPlayerSkin"
    for _, item in ipairs(clone:GetDescendants()) do
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

    local record = {Avatar = clone}
    EntitySkinObjects[model] = record

    -- Parent primeiro, DEPOIS mapear (para PivotTo/CFrame funcionar)
    pcall(function()
        clone:PivotTo(model:GetPivot())
        clone.Parent = Workspace
    end)

    record.PartMap = BuildEntitySkinMap(model, clone)
    record.AccessoryMap = BuildEntityAccessoryMap(clone, record.PartMap)

    -- Oculta a entidade original (CORRIGIDO: agora executa de verdade)
    ApplyEntityVisuals(model, record, true)

    -- Escuta novas partes adicionadas na entidade
    record.DescendantConn = model.DescendantAdded:Connect(function(desc)
        if Running and EntitySkinObjects[model] == record then
            task.defer(function()
                if desc.Parent and EntitySkinObjects[model] == record then
                    HideEntityVisual(desc, record, true)
                end
            end)
        end
    end)
end

local function SyncEntityAccessories(record)
    for _, e in ipairs(record.AccessoryMap or {}) do
        if e.Handle and e.Handle.Parent and e.HandleAttachment and e.HandleAttachment.Parent
        and e.TargetPart and e.TargetPart.Parent then
            local targetCF = e.TargetAttachment and e.TargetAttachment.CFrame or CFrame.new()
            pcall(function()
                e.Handle.CFrame = e.TargetPart.CFrame * targetCF * e.HandleAttachment.CFrame:Inverse()
            end)
        end
    end
end

local function SyncEntitySkinPose(model, record)
    if not record or not record.Avatar or not record.Avatar.Parent then return end
    local avatar = record.Avatar
    pcall(function() avatar:PivotTo(model:GetPivot()) end)
    for ap, source in pairs(record.PartMap or {}) do
        if ap and ap.Parent and source and source.Parent then
            pcall(function() ap.CFrame = source.CFrame end)
        end
    end
    SyncEntityAccessories(record)
end

local function RefreshEntitySkins()
    if not Settings.EntitySkin then
        for model in pairs(EntitySkinObjects) do RemoveEntitySkin(model) end
        return
    end
    for model in pairs(Buckets.entity) do
        if model and model.Parent and model:IsDescendantOf(Workspace) then
            if not EntitySkinObjects[model] then
                pcall(ApplyEntitySkin, model)
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

CleanupHooks[#CleanupHooks+1] = function()
    for model in pairs(EntitySkinObjects) do RemoveEntitySkin(model) end
end

-- Sync visual (a cada frame) e re-ocultação periódica (a cada 0.75s)
Track(RunService.RenderStepped:Connect(function()
    if not Settings.EntitySkin then return end
    for model, record in pairs(EntitySkinObjects) do
        if model.Parent and record.Avatar and record.Avatar.Parent then
            pcall(SyncEntitySkinPose, model, record)
        end
    end
end))

local lastHide = 0
Track(RunService.Heartbeat:Connect(function()
    if not Settings.EntitySkin then return end
    local now = os.clock()
    if now - lastHide < 0.75 then return end
    lastHide = now
    for model, record in pairs(EntitySkinObjects) do
        if model.Parent and model:IsDescendantOf(Workspace) then
            pcall(ApplyEntityVisuals, model, record, true)
        else
            RemoveEntitySkin(model)
        end
    end
end))

Track(RunService.Heartbeat:Connect(function()
    if Settings.EntitySkin then RefreshEntitySkins() end
end))

-- BOTÕES ESP
AddButton("ESP","ESP Portas (somente Door)","Doors",function(v) if not v then RemoveCategory("DOOR") end end)
AddButton("ESP","ESP Livros (LiveHintBook)","Books",function(v) if not v then RemoveCategory("BOOK") end end)
AddButton("ESP","ESP Alavanca (LeverForGate)","Lever",function(v) if not v then RemoveCategory("LEVER") end end)
AddButton("ESP","ESP Itens","Items",function(v) if not v then RemoveCategory("ITEM") end end)
AddButton("ESP","ESP PLAYERS","Players",function(v) if v then PE_Enable() else PE_Disable() end end)
AddButton("ESP","ESP BATTERIES","Batteries",function(v) if v then BE_Enable() else BE_Disable() end end)
AddButton("ENTIDADES","ESP Entidades","Entities",function(v) if not v then RemoveCategory("ENTITY") end end)
AddButton("ENTIDADES","Skin do jogador nas entidades","EntitySkin",function(v)
    if v then Notify("SKIN ATIVADA - entidades ficarão invisíveis")
    else Notify("SKIN DESATIVADA") end
    RefreshEntitySkins()
end)
AddButton("ENTIDADES","Notificador de entidades","Notifier")

AddAction("ITENS","Informação: candle_medium removido",function()
    Notify("candle_medium não será detectado")
end)
AddAction("ITENS","Atualizar busca de itens",function()
    task.spawn(function() pcall(Scan); Notify("BUSCA ATUALIZADA") end)
end)

AddButton("PLAYER","Speed","Speed")
AddAction("PLAYER","Aumentar velocidade",function()
    Settings.SpeedValue = Settings.SpeedValue + 5
    if Settings.SpeedValue > 50 then Settings.SpeedValue = 16 end
    SaveSettings(); Notify("SPEED: "..Settings.SpeedValue)
end)
AddAction("PLAYER","Velocidade padrão: 16",function()
    Settings.SpeedValue = 16; SaveSettings(); Notify("VELOCIDADE: 16")
end)
Track(RunService.Heartbeat:Connect(function()
    if not Settings.Speed then return end
    local c = Player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = Settings.SpeedValue end
end))

local origShadows, origFog = Lighting.GlobalShadows, Lighting.FogEnd
AddButton("EXTRAS","Otimizador","Optimize",function(v)
    if v then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.GlobalShadows = origShadows
        Lighting.FogEnd = origFog
    end
end)
AddAction("EXTRAS","Limpar ESP",function()
    ClearESPObjects()
    for _, d in pairs(PlayerESP.Data) do PE_DestroyVisuals(d) end
    BE_ClearVisuals(); PE_Rebuild(); Notify("ESP LIMPO")
end)
CleanupHooks[#CleanupHooks+1] = function()
    if Settings.Optimize then
        Lighting.GlobalShadows = origShadows
        Lighting.FogEnd = origFog
    end
end

-- AUTO systems
local function GetChain(prompt, maxDepth)
    local chain = {}
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local current = prompt.Parent
    for depth = 1, (maxDepth or 6) do
        if not current or current == Workspace or current == game then break end
        if rooms and current.Parent == rooms then break end
        chain[#chain+1] = {Inst = current, Name = Norm(current.Name), Depth = depth}
        current = current.Parent
    end
    return chain
end
local function NearestDepth(chain, pred)
    for _, n in ipairs(chain) do
        if pred(n.Name, n.Inst) then return n.Depth end
    end
end

local UnlockWords = {"unlock","destranc","desbloque","use key","usar chave","picklock","pick lock"}
local HideWords = {"hide","esconder"}
local PickupWords = {"take","collect","pick up","pickup","grab","pegar","coletar","loot"}
local OpenWords = {"open","search","abrir"}
local ClosetWords = {"wardrobe","closet","cabinet","armoire","cupboard","locker","armario","hidingspot"}

local function IsDoorName(n) return n == "door" or n:find("^door") ~= nil end
local function IsLockNodeName(n)
    if n == "lock" or n == "doorlock" then return true end
    return n:find("^lock") ~= nil and not n:find("lockpick",1,true) and not n:find("locker",1,true)
end
local function IsClosetName(n) return HasAny(n, ClosetWords) end
local function IsDrawerName(n) return n:find("drawer",1,true) ~= nil end
local function IsDresserOrTableName(n)
    return n:find("dresser",1,true) ~= nil or n:find("table",1,true) ~= nil
end
local function IsPadlockName(n)
    return n:find("padlock",1,true) ~= nil or n:find("keypad",1,true) ~= nil or n:find("^code") ~= nil
end
local function IsCoinName(n)
    return n == "coin" or n == "coins" or n == "gold" or n == "goldpile"
        or n == "goldcoin" or n == "goldcoins" or n == "coinpile"
        or n:match("^goldpile%d+$") ~= nil or n:match("^coin%d+$") ~= nil or n:match("^gold%d+$") ~= nil
end

local ItemPrefixes = {
    {"lighter","Lighter"},{"flashlight","Flashlight"},{"crucifix","Crucifix"},
    {"vitamin","Vitamins"},{"lockpick","Lockpick"},{"shears","Shears"},
    {"bandage","Bandage"},{"candle","Candle"},
    {"livebreakerpolepickup","Batteries"},{"battery","Batteries"},
    {"batteries","Batteries"},{"key","Keys"}
}
local ItemExcludes = {"keyhole","keypad","keyboard","keycard","candlemedium","candlestick","candleholder","candlestand"}

local function ItemCategory(n)
    for _, e in ipairs(ItemPrefixes) do
        if n:find("^"..e[1]) then
            if HasAny(n, ItemExcludes) then return nil end
            return e[2]
        end
    end
end

local function HasHidePrompt(node)
    local c = 0
    for _, d in ipairs(node:GetDescendants()) do
        c = c + 1; if c > 200 then break end
        if d:IsA("ProximityPrompt") then
            local a = (d.ActionText or ""):lower()
            if HasAny(a, HideWords) or Norm(d.Name):find("hide",1,true) then return true end
        end
    end
    return false
end

local function ClassifyKey(prompt, chain, text)
    local pname = Norm(prompt.Name)
    if IsPadlockName(pname) then return false end
    for _, node in ipairs(chain) do if IsPadlockName(node.Name) then return false end end
    if HasAny(text.action, HideWords) or HasAny(text.action, PickupWords) then return false end
    local doorDepth = NearestDepth(chain, IsDoorName); if not doorDepth then return false end
    local lockDepth = NearestDepth(chain, IsLockNodeName)
    local foreignDepth = NearestDepth(chain, function(n)
        return ItemCategory(n) or IsCoinName(n) or IsDrawerName(n) or IsClosetName(n)
    end)
    local anchor = lockDepth or doorDepth
    if foreignDepth and foreignDepth <= anchor then return false end
    local unlockText = HasAny(text.action, UnlockWords) or HasAny(text.object, UnlockWords)
    local unlockName = pname:find("unlock",1,true) ~= nil
    if unlockText or unlockName then return true end
    if lockDepth and text.action == "" then return true end
    return false
end

local function ClassifyItem(prompt, chain, text)
    if HasAny(text.action, UnlockWords) or HasAny(text.action, HideWords) or HasAny(text.action, OpenWords) then return false end
    local itemDepth
    for _, n in ipairs(chain) do
        if ItemCategory(n.Name) and (n.Inst:IsA("Model") or n.Inst:IsA("Tool") or n.Inst:IsA("BasePart")) then
            itemDepth = n.Depth; break
        end
    end
    if not itemDepth then return false end
    local vetoDepth = NearestDepth(chain, function(n)
        return IsDoorName(n) or IsLockNodeName(n) or IsDrawerName(n) or IsClosetName(n) or IsCoinName(n) or IsPadlockName(n)
    end)
    if vetoDepth and vetoDepth <= itemDepth then return false end
    return true
end

local function ClassifyCoin(prompt, chain, text)
    if HasAny(text.action, UnlockWords) or HasAny(text.action, HideWords) or HasAny(text.action, OpenWords) then return false end
    local coinDepth = NearestDepth(chain, IsCoinName); if not coinDepth then return false end
    local vetoDepth = NearestDepth(chain, function(n)
        return IsDoorName(n) or IsLockNodeName(n) or IsDrawerName(n) or IsClosetName(n) or ItemCategory(n) ~= nil or IsPadlockName(n)
    end)
    if vetoDepth and vetoDepth <= coinDepth then return false end
    return true
end

local function ClassifyDrawer(prompt, chain, text)
    if HasAny(text.action, HideWords) or HasAny(text.action, UnlockWords) or HasAny(text.action, PickupWords) then return false end
    local pname = Norm(prompt.Name)
    if pname:find("hide",1,true) or IsPadlockName(pname) then return false end
    local fDepth, fNode
    for _, n in ipairs(chain) do
        if IsDresserOrTableName(n.Name) then fDepth, fNode = n.Depth, n.Inst; break end
    end
    if not fDepth then return false end
    for _, n in ipairs(chain) do
        if IsDoorName(n.Name) or IsPadlockName(n.Name) or IsLockNodeName(n.Name) then return false end
        if n.Depth < fDepth and IsDrawerName(n.Name) then return false end
        if IsClosetName(n.Name) then return false end
        if n.Depth < fDepth and (ItemCategory(n.Name) or IsCoinName(n.Name)) then return false end
    end
    if fNode and (fNode:IsA("Model") or fNode:IsA("Folder")) and HasHidePrompt(fNode) then return false end
    return true
end

local function FindKeyTools()
    local key, lp
    local function check(c)
        if not c then return end
        for _, tool in ipairs(c:GetChildren()) do
            if tool:IsA("Tool") then
                local n = Norm(tool.Name)
                if n:find("lockpick",1,true) then lp = lp or tool
                elseif n:find("^key") and not HasAny(n, ItemExcludes) then key = key or tool end
            end
        end
    end
    check(Player.Character); check(Player:FindFirstChildOfClass("Backpack"))
    return key, lp
end

local function PrepareKey()
    local key, lp = FindKeyTools()
    if key then return true end
    if lp then
        local c = Player.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and lp.Parent ~= c then
            pcall(function() h:EquipTool(lp) end); task.wait(0.15)
        end
        return true
    end
    return false
end

local HasFirePrompt = type(fireproximityprompt) == "function"
local function FirePrompt(prompt)
    if HasFirePrompt then
        if pcall(fireproximityprompt, prompt) then return true end
    end
    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0) + 0.05)
        prompt:InputHoldEnd()
    end)
end
if not HasFirePrompt then
    task.delay(1, function() Notify("fireproximityprompt indisponível: modo alternativo") end)
end

local AutoSystems = {
    {Name="AutoKey", Setting="AutoKey", Classify=ClassifyKey, Prepare=PrepareKey, Interval=0.35, Cooldown=0.9, Attempts=2},
    {Name="AutoItems", Setting="AutoItems", Classify=ClassifyItem, Interval=0.12, Cooldown=0.35, Attempts=2},
    {Name="AutoCoins", Setting="AutoCoins", Classify=ClassifyCoin, Interval=0.10, Cooldown=0.30, Attempts=2},
    {Name="AutoDrawers", Setting="AutoDrawers", Classify=ClassifyDrawer, Interval=0.25, Cooldown=0.50, Attempts=1}
}

local ShownPrompts, PromptActive, PromptNext, LastFire = {}, {}, {}, {}

task.spawn(function()
    while Running do
        task.wait(20)
        for p in pairs(ShownPrompts) do if not p.Parent then ShownPrompts[p] = nil end end
        for p, t in pairs(PromptNext) do
            if not p.Parent or os.clock() > t then PromptNext[p] = nil end
        end
    end
end)

local function StartAuto(system, prompt)
    PromptActive[prompt] = system.Name
    task.spawn(function()
        pcall(function()
            for _ = 1, system.Attempts do
                if not Running or not Settings[system.Setting] then break end
                if not prompt.Parent or not prompt.Enabled or not ShownPrompts[prompt] then break end
                if system.Prepare and not system.Prepare(prompt) then break end
                local rem = system.Interval - (os.clock() - (LastFire[system.Name] or 0))
                if rem > 0 then task.wait(rem) end
                if not prompt.Parent or not prompt.Enabled or not Settings[system.Setting] then break end
                LastFire[system.Name] = os.clock()
                FirePrompt(prompt)
                task.wait(system.Cooldown)
            end
        end)
        PromptActive[prompt] = nil
        PromptNext[prompt] = os.clock() + 0.75
    end)
end

Track(ProximityPromptService.PromptHidden:Connect(function(p) ShownPrompts[p] = nil end))
Track(ProximityPromptService.PromptShown:Connect(function(prompt)
    if not Running or not prompt or not prompt.Parent then return end
    ShownPrompts[prompt] = true
    if PromptActive[prompt] then return end
    local nextAllowed = PromptNext[prompt]
    if nextAllowed and os.clock() < nextAllowed then return end
    local any = false
    for _, s in ipairs(AutoSystems) do if Settings[s.Setting] then any = true; break end end
    if not any then return end
    pcall(function()
        local chain = GetChain(prompt, 6)
        local text = {
            action = (prompt.ActionText or ""):lower(),
            object = (prompt.ObjectText or ""):lower()
        }
        for _, s in ipairs(AutoSystems) do
            if Settings[s.Setting] then
                local ok, m = pcall(s.Classify, prompt, chain, text)
                if ok and m then StartAuto(s, prompt); return end
            end
        end
    end)
end)

local DiagnosePrompts = function()
    local count = 0
    for p in pairs(ShownPrompts) do
        if p.Parent then
            count = count + 1
            local chain = GetChain(p, 6)
            local names = {}
            for _, n in ipairs(chain) do names[#names+1] = n.Inst.Name.."["..n.Inst.ClassName.."]" end
            local text = {action=(p.ActionText or ""):lower(), object=(p.ObjectText or ""):lower()}
            local res = {}
            for _, s in ipairs(AutoSystems) do
                local ok, m = pcall(s.Classify, p, chain, text)
                res[#res+1] = s.Name.."="..tostring(ok and m)
            end
            print(string.format("[LK] %s | acao=%q | cadeia: %s | %s",
                p.Name, p.ActionText or "", table.concat(names, " < "), table.concat(res, ", ")))
        end
    end
    print("[LK] prompts visiveis:", count)
    Notify("DIAGNÓSTICO NO CONSOLE ("..count..")")
end

AddButton("AUTO","AUTO KEY","AutoKey")
AddButton("AUTO","AUTO ITEMS","AutoItems")
AddButton("AUTO","AUTO COINS","AutoCoins")
AddButton("AUTO","AUTO DRESSER/TABLE","AutoDrawers")
AddAction("AUTO","Diagnóstico prompts próximos (console)",DiagnosePrompts)

AddButton("CONFIG","Salvar configurações","SaveConfig",function(v)
    if v then SaveSettings(true); Notify("CONFIGURAÇÕES SERÃO SALVAS")
    else SaveSettings(true); Notify("SALVAMENTO AUTOMÁTICO DESATIVADO") end
end)
AddAction("CONFIG","Salvar agora",function()
    if type(writefile) ~= "function" then Notify("EXECUTOR SEM writefile"); return end
    SaveSettings(true); Notify("CONFIGURAÇÕES SALVAS")
end)
AddAction("CONFIG","Restaurar padrão",function()
    for _, k in ipairs(ConfigKeys) do Settings[k] = (k == "SpeedValue") and 20 or false end
    Settings.SaveConfig = true; SaveSettings(); Notify("PADRÕES APLICADOS; REEXECUTE")
end)

-- Code 50 (mantido)
local CodeGui = Instance.new("ScreenGui")
CodeGui.Name = "LKAutoCode50"
CodeGui.ResetOnSpawn = false
CodeGui.Parent = CoreGui
CleanupHooks[#CleanupHooks+1] = function() SafeDestroy(CodeGui) end

local CodeFrame = Instance.new("Frame")
CodeFrame.AnchorPoint = Vector2.new(1,0)
CodeFrame.Position = UDim2.new(1,-6,0.28,0)
CodeFrame.Size = UDim2.fromOffset(150,108)
CodeFrame.BackgroundColor3 = Dark
CodeFrame.BorderSizePixel = 0
CodeFrame.Parent = CodeGui
Instance.new("UICorner",CodeFrame).CornerRadius = UDim.new(0,10)
local CS = Instance.new("UIStroke")
CS.Color = Color3.fromRGB(95,60,145); CS.Thickness = 1.3; CS.Parent = CodeFrame

local CodeHeader = Instance.new("Frame")
CodeHeader.Size = UDim2.new(1,0,0,24); CodeHeader.BackgroundColor3 = Panel
CodeHeader.BorderSizePixel = 0; CodeHeader.Parent = CodeFrame
Instance.new("UICorner",CodeHeader).CornerRadius = UDim.new(0,10)

local CodeTitle = Instance.new("TextLabel")
CodeTitle.Position = UDim2.fromOffset(8,0); CodeTitle.Size = UDim2.new(1,-34,1,0)
CodeTitle.BackgroundTransparency = 1; CodeTitle.Text = "LK AUTO CODE 50"
CodeTitle.TextColor3 = White; CodeTitle.Font = Enum.Font.GothamBlack
CodeTitle.TextSize = 10; CodeTitle.TextXAlignment = Enum.TextXAlignment.Left
CodeTitle.Parent = CodeHeader

local CodeMin = Instance.new("TextButton")
CodeMin.Size = UDim2.fromOffset(22,18); CodeMin.Position = UDim2.new(1,-25,0,3)
CodeMin.BackgroundColor3 = ButtonColor; CodeMin.Text = "—"
CodeMin.TextColor3 = White; CodeMin.Font = Enum.Font.GothamBold
CodeMin.TextSize = 12; CodeMin.Parent = CodeHeader
Instance.new("UICorner",CodeMin).CornerRadius = UDim.new(0,6)

local DigitRow = Instance.new("Frame")
DigitRow.Position = UDim2.fromOffset(8,30); DigitRow.Size = UDim2.new(1,-16,0,32)
DigitRow.BackgroundTransparency = 1; DigitRow.Parent = CodeFrame
local DigitLayout = Instance.new("UIListLayout")
DigitLayout.FillDirection = Enum.FillDirection.Horizontal
DigitLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
DigitLayout.Padding = UDim.new(0,4); DigitLayout.Parent = DigitRow

local DigitLabels = {}
for i = 1, 5 do
    local b = Instance.new("TextLabel")
    b.Size = UDim2.fromOffset(23,32); b.BackgroundColor3 = ButtonColor
    b.Text = "-"; b.TextColor3 = White; b.Font = Enum.Font.GothamBlack
    b.TextSize = 18; b.LayoutOrder = i; b.Parent = DigitRow
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    DigitLabels[i] = b
end

local CodeStatus = Instance.new("TextLabel")
CodeStatus.Position = UDim2.fromOffset(6,66); CodeStatus.Size = UDim2.new(1,-12,0,22)
CodeStatus.BackgroundTransparency = 1; CodeStatus.Text = ""
CodeStatus.TextColor3 = Purple; CodeStatus.Font = Enum.Font.GothamBold
CodeStatus.TextSize = 9; CodeStatus.TextWrapped = true; CodeStatus.Parent = CodeFrame

local CodeSub = Instance.new("TextLabel")
CodeSub.Position = UDim2.fromOffset(6,88); CodeSub.Size = UDim2.new(1,-12,0,16)
CodeSub.BackgroundTransparency = 1; CodeSub.Text = ""
CodeSub.TextColor3 = Color3.fromRGB(170,170,190); CodeSub.Font = Enum.Font.Gotham
CodeSub.TextSize = 8; CodeSub.TextWrapped = true; CodeSub.Parent = CodeFrame

local CodeMini = Instance.new("TextButton")
CodeMini.AnchorPoint = Vector2.new(1,0)
CodeMini.Position = UDim2.new(1,-6,0.28,0)
CodeMini.Size = UDim2.fromOffset(38,30); CodeMini.BackgroundColor3 = Purple
CodeMini.Text = "50"; CodeMini.TextColor3 = White
CodeMini.Font = Enum.Font.GothamBlack; CodeMini.TextSize = 13
CodeMini.Visible = false; CodeMini.Parent = CodeGui
Instance.new("UICorner",CodeMini).CornerRadius = UDim.new(0,8)

CodeMin.Activated:Connect(function() CodeFrame.Visible = false; CodeMini.Visible = true end)
CodeMini.Activated:Connect(function() CodeFrame.Visible = true; CodeMini.Visible = false end)

local CodeState = {InLibrary=false, Since=0, Slots={}, Conflict={}}
local SEARCH_TIMEOUT = 20

local function GetLibraryRoom()
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local room = rooms and rooms:FindFirstChild("50")
    if not room then return nil end
    for book in pairs(Buckets.book) do
        if book.Parent and book:IsDescendantOf(room) then return room end
    end
    if room:FindFirstChild("LiveHintBook", true) then return room end
end

local function PlayerInsideRoom(room)
    local c = Player.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local ok, cf, size = pcall(function() return room:GetBoundingBox() end)
    if ok and cf and size then
        local rel = cf:PointToObjectSpace(root.Position)
        local pad = 12
        return math.abs(rel.X) <= size.X/2 + pad
            and math.abs(rel.Y) <= size.Y/2 + pad
            and math.abs(rel.Z) <= size.Z/2 + pad
    end
    local data = ReplicatedStorage:FindFirstChild("GameData")
    local latest = data and data:FindFirstChild("LatestRoom")
    return latest ~= nil and latest.Value == 50
end

local function KeyNorm(key) return (tostring(key):lower():gsub("[^%w]","")) end
local CompleteKeys = {code=true, libcode=true, librarycode=true, padlockcode=true,
    answer=true, solution=true, correctcode=true, actualcode=true,
    finalcode=true, secretcode=true, combination=true}
local SlotPrefixes = {"digit","code","hint","number","num","slot","pos","d","n"}
local SlotKeys = {index=true, slot=true, position=true, order=true, pos=true}
local DigitKeys = {digit=true, number=true, value=true, num=true}

local function DigitFrom(v)
    if type(v) == "number" then
        if v >= 0 and v <= 9 and v % 1 == 0 then return v end
        return nil
    end
    if type(v) == "string" and v:match("^%d$") then return tonumber(v) end
end

local function FiveFrom(v)
    if type(v) == "number" then
        if v >= 10000 and v <= 99999 and v % 1 == 0 then return string.format("%d", v) end
        return nil
    end
    if type(v) == "string" then
        if not v:match("^[%d%s%-]+$") then return nil end
        local d = v:gsub("[%s%-]","")
        if #d == 5 then return d end
    end
end

local function AddEvidence(ev, slot, digit)
    ev[slot] = ev[slot] or {}; ev[slot][digit] = true
end

local function ConsiderKV(ev, key, value)
    local nk = KeyNorm(key)
    if CompleteKeys[nk] then
        local five = FiveFrom(value)
        if five then
            for s = 1, 5 do AddEvidence(ev, s, tonumber(five:sub(s,s))) end
        end
        return
    end
    for _, prefix in ipairs(SlotPrefixes) do
        local slot = nk:match("^"..prefix.."(%d)$")
        if slot then
            slot = tonumber(slot)
            local d = DigitFrom(value)
            if slot >= 1 and slot <= 5 and d then AddEvidence(ev, slot, d) end
            return
        end
    end
end

local RelevantWords = {"code","hint","digit","padlock","clue","answer","number","solution","paper","book"}
local function RelevantName(name) return HasAny(name:lower(), RelevantWords) end

local function CollectInstance(ev, inst)
    local cls = inst.ClassName
    if cls == "StringValue" or cls == "IntValue" or cls == "NumberValue" then
        local ok, v = pcall(function() return inst.Value end)
        if ok then ConsiderKV(ev, inst.Name, v) end
    end
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if not ok or not attrs then return end
    local pairSlot, pairDigit
    for k, v in pairs(attrs) do
        ConsiderKV(ev, k, v)
        local nk = KeyNorm(k)
        if SlotKeys[nk] then
            local s = DigitFrom(v); if s and s >= 1 and s <= 5 then pairSlot = s end
        elseif DigitKeys[nk] then
            pairDigit = DigitFrom(v) or pairDigit
        end
    end
    if pairSlot and pairDigit then AddEvidence(ev, pairSlot, pairDigit) end
end

local function CollectRoom(ev, room)
    local c = 0
    for _, inst in ipairs(room:GetDescendants()) do
        c = c + 1
        if c % 600 == 0 then task.wait() end
        if RelevantName(inst.Name) then CollectInstance(ev, inst) end
    end
end

local GuiVetoWords = {"padlock","input","entry","keypad","lock","guess","selector","current"}

local function CollectGui(ev)
    local pg = Player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local c = 0
    for _, inst in ipairs(pg:GetDescendants()) do
        c = c + 1; if c % 800 == 0 then task.wait() end
        if inst.ClassName == "TextLabel" and inst.Text:match("^%s*%d%s*$") then
            local slot = KeyNorm(inst.Name):match("^%a*(%d)$")
            slot = slot and tonumber(slot)
            if slot and slot >= 1 and slot <= 5 then
                local hinted, vetoed = false, false
                local cur = inst.Parent
                for _ = 1,6 do
                    if not cur or cur == pg then break end
                    local ln = cur.Name:lower()
                    if ln:find("hint",1,true) then hinted = true end
                    if HasAny(ln, GuiVetoWords) then vetoed = true end
                    cur = cur.Parent
                end
                if hinted and not vetoed then
                    AddEvidence(ev, slot, tonumber(inst.Text:match("%d")))
                end
            end
        end
    end
end

local function RenderPanel(inside, elapsed)
    local confirmed, conflicts = 0, 0
    if inside then
        for s = 1, 5 do
            if CodeState.Slots[s] ~= nil then confirmed = confirmed + 1
            elseif CodeState.Conflict[s] then conflicts = conflicts + 1 end
        end
    end
    for s = 1, 5 do
        local lbl = DigitLabels[s]
        local d = CodeState.Slots[s]
        if not inside then lbl.Text = "-"
        elseif d ~= nil then lbl.Text = tostring(d)
        elseif CodeState.Conflict[s] then lbl.Text = "!"
        else lbl.Text = "?" end
        lbl.TextColor3 = (inside and d ~= nil) and Color3.fromRGB(70,255,130) or White
        lbl.BackgroundColor3 = (inside and confirmed == 5) and Purple or ButtonColor
    end
    if not inside then
        CodeStatus.Text = "AGUARDANDO LIBRARY (SALA 50)"
        CodeSub.Text = ""; CodeStatus.TextColor3 = Color3.fromRGB(170,170,190); return
    end
    CodeStatus.TextColor3 = Purple
    if confirmed == 5 then
        CodeStatus.Text = "CÓDIGO CONFIRMADO"
        CodeStatus.TextColor3 = Color3.fromRGB(70,255,130)
        CodeSub.Text = "lido de dados do cliente"
    elseif confirmed > 0 then
        CodeStatus.Text = "PARCIAL: "..confirmed.."/5 CONFIRMADOS"
        CodeSub.Text = (conflicts > 0) and "! = dados contraditórios"
            or (elapsed >= SEARCH_TIMEOUT) and "demais dígitos não acessíveis" or "? = ainda desconhecido"
    elseif elapsed >= SEARCH_TIMEOUT then
        CodeStatus.Text = "NÃO FOI POSSÍVEL IDENTIFICAR O CÓDIGO"
        CodeSub.Text = "dados não acessíveis no cliente"
    else
        CodeStatus.Text = "PROCURANDO CÓDIGO..."; CodeSub.Text = ""
    end
end

local function CodeStep()
    local room = GetLibraryRoom()
    local inside = room ~= nil and PlayerInsideRoom(room)
    if not inside then
        CodeState.InLibrary = false
        table.clear(CodeState.Slots); table.clear(CodeState.Conflict)
        RenderPanel(false, 0); return
    end
    if not CodeState.InLibrary then
        CodeState.InLibrary = true; CodeState.Since = os.clock()
        table.clear(CodeState.Slots); table.clear(CodeState.Conflict)
        RenderPanel(true, 0)
    end
    local ev = {}
    pcall(CollectRoom, ev, room); pcall(CollectGui, ev)
    local slots, conflict = {}, {}
    for s = 1, 5 do
        local digits = ev[s]
        if digits then
            local count, only = 0, nil
            for d in pairs(digits) do count = count + 1; only = d end
            if count == 1 then slots[s] = only
            elseif count > 1 then conflict[s] = true end
        end
    end
    for s = 1, 5 do
        if conflict[s] then CodeState.Slots[s] = nil; CodeState.Conflict[s] = true
        elseif slots[s] ~= nil then CodeState.Slots[s] = slots[s]; CodeState.Conflict[s] = nil end
    end
    RenderPanel(true, os.clock() - CodeState.Since)
end

task.spawn(function()
    RenderPanel(false, 0)
    while Running and CodeGui.Parent do
        pcall(CodeStep); task.wait(CodeState.InLibrary and 2.5 or 2)
    end
end)

AddAction("EXTRAS","Diagnóstico Code 50 (console)",function()
    local lines = {}
    local function add(t) if #lines < 160 then lines[#lines+1] = t end end
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local room = rooms and rooms:FindFirstChild("50")
    add("[LK CODE50] sala 50 presente: "..tostring(room ~= nil))
    add("[LK CODE50] library detectada: "..tostring(GetLibraryRoom() ~= nil))
    if room then
        local prefix = room:GetFullName()
        for _, inst in ipairs(room:GetDescendants()) do
            local isV = inst:IsA("ValueBase")
            if RelevantName(inst.Name) or isV then
                local attrs = {}
                for k, v in pairs(inst:GetAttributes()) do attrs[#attrs+1] = k.."="..tostring(v) end
                local vt = ""
                if isV then
                    local ok, v = pcall(function() return inst.Value end)
                    if ok then vt = " = "..tostring(v) end
                end
                add(string.format("  %s [%s]%s%s",
                    (inst:GetFullName():gsub(prefix,"",1)), inst.ClassName, vt,
                    #attrs > 0 and (" {"..table.concat(attrs,", ").."}") or ""))
            end
        end
    end
    for _, line in ipairs(lines) do print(line) end
    Notify("DIAGNÓSTICO ENVIADO AO CONSOLE")
end)

-- Open button + drag
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.fromOffset(55,48)
OpenButton.Position = UDim2.new(0,10,0.5,0)
OpenButton.BackgroundColor3 = Purple
OpenButton.Text = "LK"; OpenButton.TextColor3 = White
OpenButton.Font = Enum.Font.GothamBlack; OpenButton.TextSize = 17
OpenButton.Visible = false; OpenButton.Parent = Gui
Instance.new("UICorner",OpenButton).CornerRadius = UDim.new(0,10)

Minimize.Activated:Connect(function() Main.Visible = false; OpenButton.Visible = true end)
OpenButton.Activated:Connect(function() Main.Visible = true; OpenButton.Visible = false end)

local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
Track(UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))
Track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

SelectTab("ESP")

task.spawn(function()
    while Running and Gui.Parent do
        if Settings.Entities or Settings.Doors or Settings.Items or Settings.Books or Settings.Lever or Settings.Notifier then
            pcall(Scan)
        end
        task.wait(1.5)
    end
end)

Notify("LK DOORS V10.4 CARREGADO!")
print("LK DOORS SYSTEM V10.4 carregado!")
