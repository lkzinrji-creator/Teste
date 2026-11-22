local __LK_ok, __LK_err = pcall(function()


Players = game:GetService("Players")
Workspace = game:GetService("Workspace")
RunService = game:GetService("RunService")
Lighting = game:GetService("Lighting")
UIS = game:GetService("UserInputService")
CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)
ProximityPromptService = game:GetService("ProximityPromptService")
TweenService = game:GetService("TweenService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
HttpService = game:GetService("HttpService")

Player = Players.LocalPlayer

-- [CORRIGIDO] Assets base64 embutidos removidos (eram dados inválidos e deixavam o script enorme).
-- O script usa ícones de texto como alternativa automaticamente.
LKEmbeddedAssets = {}

LK_ROOT = ""
LK_ASSET_FOLDERS = {"LK_DOORS_SOM", "LK_DOORS_ICONS", "LK_DOORS_UI", "LK_DOORS_FX"}
function LKMakeFolder(path)
    if type(makefolder) == "function" then
        pcall(function() if type(isfolder) ~= "function" or not isfolder(path) then makefolder(path) end end)
    end
end
function LKBase64Decode(data)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local map = {}
    for i = 1, #chars do map[chars:sub(i,i)] = i - 1 end
    data = data:gsub("[^%w%+/%=]", "")
    local out, buffer, bits = {}, 0, 0
    for i = 1, #data do
        local c = data:sub(i,i)
        if c ~= "=" then
            local v = map[c]
            if v then
                buffer = buffer * 64 + v
                bits = bits + 6
                if bits >= 8 then
                    bits = bits - 8
                    local byte = math.floor(buffer / (2 ^ bits)) % 256
                    out[#out+1] = string.char(byte)
                    buffer = buffer % (2 ^ bits)
                end
            end
        end
    end
    return table.concat(out)
end
function LKInstallAssets()
    if type(writefile) ~= "function" then
        warn("[LK] Delta não oferece writefile; instalação automática de ícones/sons indisponível.")
        return false
    end
    for _,folder in ipairs(LK_ASSET_FOLDERS) do LKMakeFolder(folder) end
    local installed, skipped, failed = 0, 0, 0
    for relative,encoded in pairs(LKEmbeddedAssets) do
        local path = relative
        local exists = false
        if type(isfile) == "function" then
            local ok, value = pcall(isfile, path)
            exists = ok and value == true
        end
        
        if exists then
            skipped = skipped + 1
        else
            local ok, bytes = pcall(LKBase64Decode, encoded)
            if ok then
                local wrote = pcall(writefile, path, bytes)
                if wrote then installed = installed + 1 else failed = failed + 1 end
            else
                failed = failed + 1
            end
        end
    end
    local cfg = [[{"version":1,"sound_folder":"LK_DOORS_SOM","icon_folder":"LK_DOORS_ICONS","ui_folder":"LK_DOORS_UI","volume":0.7,"enabled":true}]]
    local cfgExists = false
    if type(isfile) == "function" then pcall(function() cfgExists = isfile("LK_DOORS_SOUND_CONFIG.json") end) end
    if not cfgExists then pcall(writefile, "LK_DOORS_SOUND_CONFIG.json", cfg) end
    print("[LK] Recursos locais: "..installed.." instalados, "..skipped.." preservados, "..failed.." falhas.")
    return failed == 0
end

pcall(LKInstallAssets)

Running = true
Connections = {}
CleanupHooks = {}
WeakMode = {__mode = "k"}

function Track(connection)
    Connections[#Connections + 1] = connection
    return connection
end

function SafeDestroy(instance)
    if instance then
        pcall(function() instance:Destroy() end)
    end
end

function Cleanup()
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
    if CoreGui then
        local old = CoreGui:FindFirstChild("LKDoorsSystem")
        if old then old:Destroy() end
        local oldCode = CoreGui:FindFirstChild("LKAutoCode50")
        if oldCode then oldCode:Destroy() end
    end
end)

local GuiParent = CoreGui or Player:WaitForChild("PlayerGui")

Settings = {
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
    MenuIconStyle = "LK",
    Language = "English",
    LanguageChosen = false,
    Chest = false,
    SaveConfig = true
}

CONFIG_FILE = "LK_DOORS_SYSTEM_V10_CONFIG.json"
ConfigKeys = {
    "Entities","Doors","Items","Books","Lever","Notifier","Speed","Optimize",
    "AutoKey","AutoItems","AutoCoins","AutoDrawers","Players","Batteries",
    "EntitySkin","SpeedValue","MenuIconStyle","Language","LanguageChosen","Chest"
}

function LoadSettings()
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

function SaveSettings(force)
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

Purple = Color3.fromRGB(145,75,255)
Dark = Color3.fromRGB(11,12,20)
Panel = Color3.fromRGB(19,21,33)
ButtonColor = Color3.fromRGB(29,32,48)
White = Color3.fromRGB(245,245,255)
Muted = Color3.fromRGB(145,150,170)
Accent2 = Color3.fromRGB(85,210,255)

Gui = Instance.new("ScreenGui")
Gui.Name = "LKDoorsSystem"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = GuiParent
CleanupHooks[#CleanupHooks + 1] = function() SafeDestroy(Gui) end

Camera = Workspace.CurrentCamera
viewport = Camera and Camera.ViewportSize or Vector2.new(800,600)
compact = viewport.X < 520
width = math.clamp(viewport.X - 20, 310, 620)
height = math.clamp(viewport.Y - 76, 320, 470)
sideWidth = compact and 82 or 126

function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(width,height)
Main.Position = UDim2.new(0.5,-width/2,0.5,-height/2)
Main.BackgroundColor3 = Color3.fromRGB(9,11,19)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui
Corner(Main,16)
Stroke(Main,Color3.fromRGB(103,74,170),1.5,0.08)

MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(17,18,31)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(8,10,17))
})
MainGradient.Rotation = 35
MainGradient.Parent = Main

Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1,0,0,58)
Header.BackgroundColor3 = Color3.fromRGB(22,20,37)
Header.BorderSizePixel = 0
Header.Parent = Main

HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new(Color3.fromRGB(39,26,65),Color3.fromRGB(17,28,43))
HeaderGradient.Rotation = 0
HeaderGradient.Parent = Header

HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1,0,0,2)
HeaderLine.Position = UDim2.new(0,0,1,-2)
HeaderLine.BackgroundColor3 = Accent2
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

Title = Instance.new("TextLabel")
Title.Position = UDim2.fromOffset(15,5)
Title.Size = UDim2.new(1,-125,0,27)
Title.BackgroundTransparency = 1
Title.Text = "LK  DOORS ULTIMATE"
Title.TextColor3 = White
Title.Font = Enum.Font.GothamBlack
Title.TextSize = compact and 14 or 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.fromOffset(16,32)
Subtitle.Size = UDim2.new(1,-130,0,14)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "CONTROL CENTER  •  DOORS"
Subtitle.TextColor3 = Accent2
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

WindowButtons = Instance.new("Frame")
WindowButtons.BackgroundTransparency = 1
WindowButtons.Size = UDim2.fromOffset(76,34)
WindowButtons.Position = UDim2.new(1,-86,0,12)
WindowButtons.Parent = Header

WindowLayout = Instance.new("UIListLayout")
WindowLayout.FillDirection = Enum.FillDirection.Horizontal
WindowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
WindowLayout.Padding = UDim.new(0,7)
WindowLayout.Parent = WindowButtons

Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.Size = UDim2.fromOffset(32,30)
Minimize.BackgroundColor3 = Color3.fromRGB(47,43,67)
Minimize.Text = "—"
Minimize.TextColor3 = White
Minimize.Font = Enum.Font.GothamBlack
Minimize.TextSize = 17
Minimize.AutoButtonColor = false
Minimize.Parent = WindowButtons
Corner(Minimize,9)

CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseMenu"
CloseButton.Size = UDim2.fromOffset(32,30)
CloseButton.BackgroundColor3 = Color3.fromRGB(115,45,66)
CloseButton.Text = "×"
CloseButton.TextColor3 = White
CloseButton.Font = Enum.Font.GothamBlack
CloseButton.TextSize = 20
CloseButton.AutoButtonColor = false
CloseButton.Parent = WindowButtons
Corner(CloseButton,9)

Tabs = Instance.new("ScrollingFrame")
Tabs.Name = "Navigation"
Tabs.Position = UDim2.fromOffset(9,67)
Tabs.Size = UDim2.new(0,sideWidth,1,-76)
Tabs.BackgroundColor3 = Color3.fromRGB(17,19,31)
Tabs.BorderSizePixel = 0
Tabs.ScrollBarThickness = 2
Tabs.ScrollBarImageColor3 = Purple
Tabs.CanvasSize = UDim2.new(0,0,0,0)
Tabs.Parent = Main
Corner(Tabs,12)
Stroke(Tabs,Color3.fromRGB(49,46,72),1,0.25)

TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0,7)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Parent = Tabs

TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0,9)
TabPadding.PaddingLeft = UDim.new(0,6)
TabPadding.PaddingRight = UDim.new(0,6)
TabPadding.Parent = Tabs

TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Tabs.CanvasSize = UDim2.fromOffset(0,TabLayout.AbsoluteContentSize.Y+20)
end)

Content = Instance.new("Frame")
Content.Name = "Content"
Content.Position = UDim2.fromOffset(sideWidth+18,67)
Content.Size = UDim2.new(1,-(sideWidth+27),1,-76)
Content.BackgroundColor3 = Color3.fromRGB(16,18,29)
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = Main
Corner(Content,12)
Stroke(Content,Color3.fromRGB(49,46,72),1,0.25)

Pages = {}
TabButtons = {}

function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Position = UDim2.fromOffset(8,8)
    page.Size = UDim2.new(1,-16,1,-16)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Accent2
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,3)
    padding.PaddingBottom = UDim.new(0,8)
    padding.PaddingLeft = UDim.new(0,2)
    padding.PaddingRight = UDim.new(0,5)
    padding.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+16)
    end)
    Pages[name] = page
end

function SelectTab(name)
    for tabName,page in pairs(Pages) do
        page.Visible = tabName == name
    end
    for tabName,button in pairs(TabButtons) do
        local active = tabName == name
        button.BackgroundColor3 = active and Color3.fromRGB(65,43,101) or Color3.fromRGB(28,30,46)
        button.TextColor3 = active and White or Muted
        local bar = button:FindFirstChild("ActiveBar")
        if bar then bar.Visible = active end
        local icon = button:FindFirstChild("TabIcon")
        if icon then icon.ImageColor3 = active and Accent2 or Muted end
    end
end

LKTabIconFiles = {
    ESP = "esp_icon.png", ENTIDADES = "entity_icon.png", ITENS = "item_icon.png",
    PLAYER = "player_icon.png", EXTRAS = "extras_icon.png", AUTO = "auto_icon.png",
    CONFIG = "config_icon.png"
}
function LKGetIconAsset(fileName)
    if type(fileName) ~= "string" then return nil end
    local paths = {"LK_DOORS_ICONS/"..fileName, "Delta/LK_DOORS_ICONS/"..fileName,
        "/storage/emulated/0/Delta/LK_DOORS_ICONS/"..fileName}
    for _,path in ipairs(paths) do
        local fn = type(getcustomasset)=="function" and getcustomasset or (type(getsynasset)=="function" and getsynasset)
        if fn then
            local ok, asset = pcall(fn,path)
            if ok and type(asset)=="string" then return asset end
        end
    end
    return nil
end

local LK_LANG = {
    ["Português"] = {
        AUTO="AUTO", CONFIG="CONFIG", ENTIDADES="ENTIDADES", ESP="ESP", EXTRAS="EXTRAS", ITENS="ITENS", PLAYER="PLAYER",
        ["ESP Baús"]="ESP Baús", ["Salvar configurações"]="Salvar configurações",
        ["Otimizador inteligente"]="Otimizador inteligente", ["Limpar ESP"]="Limpar ESP",
        ["ESP Portas (somente Door)"]="ESP Portas (somente Door)", ["ESP Livros (LiveHintBook)"]="ESP Livros (LiveHintBook)",
        ["ESP Alavanca (LeverForGate)"]="ESP Alavanca (LeverForGate)", ["ESP Itens"]="ESP Itens",
        ["ESP PLAYERS"]="ESP JOGADORES", ["ESP BATTERIES"]="ESP BATERIAS",
        ["Idioma: escolher"]="Idioma: escolher", ["Salvar agora"]="Salvar agora",
        ["Ícone do botão flutuante: escolher"]="Ícone do botão flutuante: escolher",
        ["ESP Entidades"]="ESP Entidades", ["Skin do jogador nas entidades"]="Skin do jogador nas entidades",
        ["Notificador de entidades"]="Notificador de entidades", ["Informação: candle_medium removido"]="Informação: candle_medium removido",
        ["Atualizar busca de itens"]="Atualizar busca de itens", ["Aumentar velocidade"]="Aumentar velocidade",
        ["Velocidade padrão: 16"]="Velocidade padrão: 16", ["AUTO KEY"]="AUTO KEY", ["AUTO ITEMS"]="AUTO ITEMS",
        ["AUTO COINS"]="AUTO COINS", ["AUTO DRESSER/TABLE"]="AUTO DRESSER/TABLE",
        ["Diagnóstico prompts próximos (console)"]="Diagnóstico prompts próximos (console)",
        ["Diagnóstico Code 50 (console)"]="Diagnóstico Code 50 (console)",
        ["Restaurar padrão"]="Restaurar padrão", ["🌐 MUDAR IDIOMA / CHANGE LANGUAGE"]="🌐 MUDAR IDIOMA / CHANGE LANGUAGE"
    },
    ["English"] = {
        AUTO="AUTO", CONFIG="SETTINGS", ENTIDADES="ENTITIES", ESP="ESP", EXTRAS="EXTRAS", ITENS="ITEMS", PLAYER="PLAYER",
        ["ESP Baús"]="ESP Chests", ["Salvar configurações"]="Save settings",
        ["Otimizador inteligente"]="Smart optimizer", ["Limpar ESP"]="Clear ESP",
        ["ESP Portas (somente Door)"]="Door ESP (Door only)", ["ESP Livros (LiveHintBook)"]="Book ESP (LiveHintBook)",
        ["ESP Alavanca (LeverForGate)"]="Lever ESP (LeverForGate)", ["ESP Itens"]="Item ESP",
        ["ESP PLAYERS"]="PLAYER ESP", ["ESP BATTERIES"]="BATTERY ESP",
        ["Idioma: escolher"]="Language: change", ["Salvar agora"]="Save now",
        ["Ícone do botão flutuante: escolher"]="Choose floating button icon",
        ["ESP Entidades"]="Entity ESP", ["Skin do jogador nas entidades"]="Player skin on entities",
        ["Notificador de entidades"]="Entity notifier", ["Informação: candle_medium removido"]="Info: candle_medium removed",
        ["Atualizar busca de itens"]="Refresh item search", ["Aumentar velocidade"]="Increase speed",
        ["Velocidade padrão: 16"]="Default speed: 16", ["AUTO KEY"]="AUTO KEY", ["AUTO ITEMS"]="AUTO ITEMS",
        ["AUTO COINS"]="AUTO COINS", ["AUTO DRESSER/TABLE"]="AUTO DRESSER/TABLE",
        ["Diagnóstico prompts próximos (console)"]="Nearby prompt diagnostics (console)",
        ["Diagnóstico Code 50 (console)"]="Code 50 diagnostics (console)",
        
        ["Speed"]="Speed",
        ["Entre em um armário ou esconderijo e espere ele passar."]="Hide in a closet or hiding spot and wait for it to pass.",
        ["Corra seguindo as indicações e desvie dos obstáculos."]="Run along the directions and avoid the obstacles.",
        ["Quando aparecer VIRE-SE e ande na direção oposta."]="When TURN AROUND appears, walk in the opposite direction.",
        ["Não olhe para os olhos; mantenha a câmera apontada para longe."]="Do not look at the eyes; keep your camera pointed away.",
        ["Confira o número da sala e os sons antes de abrir uma porta."]="Check the room number and sounds before opening a door.",
        ["Olhe para cima e use a luz para afastá-lo, se disponível."]="Look up and use light to repel it, if available.",
        ["Afaste-se dos tentáculos e procure uma rota segura."]="Stay away from the tentacles and find a safe route.",
        ["PERIGO CRÍTICO: procure abrigo imediatamente; não há garantia de escape."]="CRITICAL DANGER: find shelter immediately; escape is not guaranteed.",
        ["candle_medium não será detectado"]="candle_medium will not be detected",
        ["CONFIGURAÇÕES SERÃO SALVAS"]="SETTINGS WILL BE SAVED",
        ["SALVAMENTO AUTOMÁTICO DESATIVADO"]="AUTO-SAVE DISABLED",
        ["CONFIGURAÇÕES SALVAS"]="SETTINGS SAVED",
        ["ÍCONE DO BOTÃO: "]="BUTTON ICON: ",
        ["Notificação"]="Notification",
        ["Número confirmado"]="Number confirmed",
        ["Código completo"]="Full code",
        ["TESTAR NOTIFICAÇÃO"]="TEST NOTIFICATION",
        ["CÓDIGO CONFIRMADO"]="CODE CONFIRMED",
        ["Código pronto — use os 5 números"]="Code ready — use the 5 numbers",
        ["NÃO FOI POSSÍVEL IDENTIFICAR O CÓDIGO"]="UNABLE TO IDENTIFY THE CODE",
        ["O código atualiza conforme os dados são encontrados"]="The code updates as data is found",
        ["DIAGNÓSTICO ENVIADO AO CONSOLE"]="DIAGNOSTICS SENT TO CONSOLE",
        ["VIDEO INDISPONÍVEL"]="VIDEO UNAVAILABLE",
        ["O Delta não conseguiu abrir o MP4 local"]="Delta could not open the local MP4",
        ["MP4 NÃO ENCONTRADO"]="MP4 NOT FOUND",
        ["Limpar ESP"]="Clear ESP",
        ["Atualizar busca de itens"]="Refresh item search",
        ["Aumentar velocidade"]="Increase speed",
        ["Velocidade padrão: 16"]="Default speed: 16",
        ["Salvar agora"]="Save now",
        ["Restaurar padrão"]="Restore defaults",
        ["Salvar configurações"]="Save settings",
        ["ESP Baús"]="ESP Chests",
        ["Ícone do botão flutuante: escolher"]="Choose floating button icon",
        ["Informação: candle_medium removido"]="Info: candle_medium removed",
        ["Diagnóstico prompts próximos (console)"]="Nearby prompt diagnostics (console)",
        ["Diagnóstico Code 50 (console)"]="Code 50 diagnostics (console)",
        ["Restaurar padrão"]="Restore defaults", ["🌐 MUDAR IDIOMA / CHANGE LANGUAGE"]="🌐 LANGUAGE / IDIOMA"
    },
    ["Español"] = {
        AUTO="AUTO", CONFIG="AJUSTES", ENTIDADES="ENTIDADES", ESP="ESP", EXTRAS="EXTRAS", ITENS="OBJETOS", PLAYER="JUGADOR",
        ["ESP Baús"]="ESP Cofres", ["Salvar configurações"]="Guardar ajustes",
        ["Otimizador inteligente"]="Optimizador inteligente", ["Limpar ESP"]="Limpiar ESP",
        ["ESP Portas (somente Door)"]="ESP Puertas (solo Door)", ["ESP Livros (LiveHintBook)"]="ESP Libros (LiveHintBook)",
        ["ESP Alavanca (LeverForGate)"]="ESP Palanca (LeverForGate)", ["ESP Itens"]="ESP Objetos",
        ["ESP PLAYERS"]="ESP JUGADORES", ["ESP BATTERIES"]="ESP BATERÍAS",
        ["Idioma: escolher"]="Cambiar idioma", ["Salvar agora"]="Guardar ahora",
        ["Ícone do botão flutuante: escolher"]="Elegir icono flotante",
        ["ESP Entidades"]="ESP Entidades", ["Skin do jogador nas entidades"]="Apariencia del jugador en entidades",
        ["Notificador de entidades"]="Notificador de entidades", ["Informação: candle_medium removido"]="Info: candle_medium eliminado",
        ["Atualizar busca de itens"]="Actualizar búsqueda de objetos", ["Aumentar velocidade"]="Aumentar velocidad",
        ["Velocidade padrão: 16"]="Velocidad predeterminada: 16", ["AUTO KEY"]="AUTO LLAVE", ["AUTO ITEMS"]="AUTO OBJETOS",
        ["AUTO COINS"]="AUTO MONEDAS", ["AUTO DRESSER/TABLE"]="AUTO CAJONES/MESAS",
        ["Diagnóstico prompts próximos (console)"]="Diagnóstico de prompts cercanos (consola)",
        ["Diagnóstico Code 50 (console)"]="Diagnóstico Code 50 (consola)",
        
        ["Speed"]="Velocidad",
        ["Entre em um armário ou esconderijo e espere ele passar."]="Escóndete en un armario o escondite y espera a que pase.",
        ["Corra seguindo as indicações e desvie dos obstáculos."]="Corre siguiendo las indicaciones y esquiva los obstáculos.",
        ["Quando aparecer VIRE-SE e ande na direção oposta."]="Cuando aparezca DATE LA VUELTA, camina en dirección contraria.",
        ["Não olhe para os olhos; mantenha a câmera apontada para longe."]="No mires a los ojos; apunta la cámara en otra dirección.",
        ["Confira o número da sala e os sons antes de abrir uma porta."]="Comprueba el número de la sala y los sonidos antes de abrir una puerta.",
        ["Olhe para cima e use a luz para afastá-lo, se disponível."]="Mira hacia arriba y usa la luz para ahuyentarlo, si está disponible.",
        ["Afaste-se dos tentáculos e procure uma rota segura."]="Aléjate de los tentáculos y busca una ruta segura.",
        ["PERIGO CRÍTICO: procure abrigo imediatamente; não há garantia de escape."]="PELIGRO CRÍTICO: busca refugio inmediatamente; no se garantiza escapar.",
        ["candle_medium não será detectado"]="candle_medium no será detectado",
        ["CONFIGURAÇÕES SERÃO SALVAS"]="SE GUARDARÁN LOS AJUSTES",
        ["SALVAMENTO AUTOMÁTICO DESATIVADO"]="GUARDADO AUTOMÁTICO DESACTIVADO",
        ["CONFIGURAÇÕES SALVAS"]="AJUSTES GUARDADOS",
        ["ÍCONE DO BOTÃO: "]="ICONO DEL BOTÓN: ",
        ["Notificação"]="Notificación",
        ["Número confirmado"]="Número confirmado",
        ["Código completo"]="Código completo",
        ["TESTAR NOTIFICAÇÃO"]="PROBAR NOTIFICACIÓN",
        ["CÓDIGO CONFIRMADO"]="CÓDIGO CONFIRMADO",
        ["Código pronto — use os 5 números"]="Código listo — usa los 5 números",
        ["NÃO FOI POSSÍVEL IDENTIFICAR O CÓDIGO"]="NO SE PUDO IDENTIFICAR EL CÓDIGO",
        ["O código atualiza conforme os dados são encontrados"]="El código se actualiza a medida que se encuentran datos",
        ["DIAGNÓSTICO ENVIADO AO CONSOLE"]="DIAGNÓSTICO ENVIADO A LA CONSOLA",
        ["VIDEO INDISPONÍVEL"]="VIDEO NO DISPONIBLE",
        ["O Delta não conseguiu abrir o MP4 local"]="Delta no pudo abrir el MP4 local",
        ["MP4 NÃO ENCONTRADO"]="MP4 NO ENCONTRADO",
        ["Limpar ESP"]="Limpiar ESP",
        ["Atualizar busca de itens"]="Actualizar búsqueda de objetos",
        ["Aumentar velocidade"]="Aumentar velocidad",
        ["Velocidade padrão: 16"]="Velocidad predeterminada: 16",
        ["Salvar agora"]="Guardar ahora",
        ["Restaurar padrão"]="Restaurar valores",
        ["Salvar configurações"]="Guardar ajustes",
        ["ESP Baús"]="ESP Cofres",
        ["Ícone do botão flutuante: escolher"]="Elegir icono flotante",
        ["Informação: candle_medium removido"]="Info: candle_medium eliminado",
        ["Diagnóstico prompts próximos (console)"]="Diagnóstico de prompts cercanos (consola)",
        ["Diagnóstico Code 50 (console)"]="Diagnóstico Code 50 (consola)",
        ["Restaurar padrão"]="Restaurar valores", ["🌐 MUDAR IDIOMA / CHANGE LANGUAGE"]="🌐 CAMBIAR IDIOMA"
    }
}
if Settings.LanguageChosen ~= true then
    Settings.Language = "English"
end

local function LK_T(text)
    local pack = LK_LANG[Settings.Language] or LK_LANG["Português"]
    return pack[text] or text
end

LKLocalizedObjects = {}
function LK_RegisterText(object, source, formatKind)
    if object then
        object:SetAttribute("LKTranslationSource", source)
        object:SetAttribute("LKTranslationFormat", formatKind or "plain")
        table.insert(LKLocalizedObjects, object)
    end
end
function LK_RefreshLanguage()
    for index = #LKLocalizedObjects, 1, -1 do
        local object = LKLocalizedObjects[index]
        if not object or not object.Parent then
            table.remove(LKLocalizedObjects, index)
        else
            local source = object:GetAttribute("LKTranslationSource")
            local formatKind = object:GetAttribute("LKTranslationFormat")
            if type(source) == "string" then
                local translated = LK_T(source)
                if formatKind == "action" then translated = "   "..translated.."    ›" end
                object.Text = translated
            end
        end
    end
end

function CreateTab(name,icon)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1,0,0,compact and 42 or 40)
    button.BackgroundColor3 = Color3.fromRGB(28,30,46)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = Tabs
    Corner(button,9)

    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "TabIcon"
    iconLabel.Position = UDim2.fromOffset(7,0)
    iconLabel.Size = UDim2.fromOffset(22,22)
    iconLabel.AnchorPoint = Vector2.new(0,0.5)
    iconLabel.Position = UDim2.new(0,7,0.5,0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.ImageColor3 = Muted
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.Parent = button
    local iconAsset = LKGetIconAsset(LKTabIconFiles[name])
    if iconAsset then
        iconLabel.Image = iconAsset
    else
        
        local fallback = Instance.new("TextLabel")
        fallback.Name = "TabIconFallback"
        fallback.Size = UDim2.fromScale(1,1)
        fallback.BackgroundTransparency = 1
        fallback.Text = ({ESP="E",ENTIDADES="EN",ITENS="I",PLAYER="P",EXTRAS="EX",AUTO="A",CONFIG="C"})[name] or "LK"
        fallback.TextSize = 11
        fallback.TextColor3 = Muted
        fallback.Font = Enum.Font.GothamBold
        fallback.Parent = iconLabel
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Position = UDim2.fromOffset(31,0)
    nameLabel.Size = UDim2.new(1,-35,1,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = LK_T(name)
    nameLabel.TextColor3 = Muted
    nameLabel.TextSize = compact and 8 or 10
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = button
    LK_RegisterText(nameLabel,name,"plain")

    local bar = Instance.new("Frame")
    bar.Name = "ActiveBar"
    bar.Size = UDim2.new(0,3,1,-12)
    bar.Position = UDim2.new(0,0,0,6)
    bar.BackgroundColor3 = Accent2
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.Parent = button
    Corner(bar,4)

    TabButtons[name] = button
    CreatePage(name)
    button.Activated:Connect(function() SelectTab(name) end)
end


CreateTab("AUTO","⚡")
CreateTab("CONFIG","☷")
CreateTab("ENTIDADES","👻")
CreateTab("ESP","👁")
CreateTab("EXTRAS","⚙")
CreateTab("ITENS","🔑")
CreateTab("PLAYER","🏃")


function AddButton(pageName,name,key,callback)
    local page = Pages[pageName]
    if not page then return end

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1,-3,0,47)
    button.BackgroundColor3 = Color3.fromRGB(29,32,49)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = page
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,10)
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(55,54,79)
    cardStroke.Transparency = 0.48
    cardStroke.Thickness = 1
    cardStroke.Parent = button

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.fromOffset(3,23)
    indicator.Position = UDim2.new(0,0,0.5,-11)
    indicator.BackgroundColor3 = Purple
    indicator.BorderSizePixel = 0
    indicator.Parent = button
    Instance.new("UICorner",indicator).CornerRadius = UDim.new(1,0)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(11,0)
    label.Size = UDim2.new(1,-76,1,0)
    label.BackgroundTransparency = 1
    label.Text = LK_T(name)
    label.TextColor3 = White
    label.TextSize = 11
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = button
    LK_RegisterText(label,name,"plain")

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(43,22)
    status.Position = UDim2.new(1,-51,0.5,-11)
    status.BackgroundColor3 = Color3.fromRGB(65,68,84)
    status.Text = "OFF"
    status.TextColor3 = White
    status.Font = Enum.Font.GothamBlack
    status.TextSize = 9
    status.Parent = button
    Instance.new("UICorner",status).CornerRadius = UDim.new(0,7)

    local enabled = key and Settings[key] == true or false

    local function PaintStatus()
        status.Text = enabled and "ON" or "OFF"
        status.BackgroundColor3 = enabled and Purple or Color3.fromRGB(65,68,84)
        indicator.BackgroundColor3 = enabled and Accent2 or Purple
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

PlayMenuSound = function() end -- [CORRIGIDO] stub seguro; a versão real é definida mais abaixo
function AddAction(pageName,name,callback)
    local page = Pages[pageName]
    if not page then return end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-3,0,44)
    button.BackgroundColor3 = Color3.fromRGB(29,32,49)
    button.Text = "   "..LK_T(name).."    ›"
    button.TextColor3 = White
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.Parent = page
    LK_RegisterText(button,name,"action")
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,9)

    button.Activated:Connect(function()
        PlayMenuSound("click")
        local ok,err = pcall(callback)
        if not ok then
            warn("LK DOORS ACTION ERROR ["..tostring(name).."]:",err)
        end
    end)
end

NotificationCount = 0
ActiveNotifications = {}

function LK_LayoutNotifications()
    local y = 62
    for index,entry in ipairs(ActiveNotifications) do
        local notice = entry.Frame
        if notice and notice.Parent then
            TweenService:Create(
                notice,
                TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {Position = UDim2.new(1,-14,0,y)}
            ):Play()
            y = y + entry.Height + 8
        end
    end
end

function Notify(message, alertColor, alertTitle, advice)
    PlayMenuSound("notification")
    NotificationCount = NotificationCount + 1

    local hasAdvice = type(advice) == "string" and advice ~= ""
    local cardHeight = hasAdvice and 82 or 55
    local notice = Instance.new("Frame")
    notice.Name = "LKNotification_"..NotificationCount
    notice.Size = UDim2.fromOffset(286,0)
    notice.AnchorPoint = Vector2.new(1,0)
    notice.Position = UDim2.new(1,300,0,62)
    notice.BackgroundColor3 = Panel
    notice.BorderSizePixel = 0
    notice.ClipsDescendants = true
    notice.Parent = Gui

    table.insert(ActiveNotifications,{Frame=notice,Height=cardHeight})
    LK_LayoutNotifications()

    Instance.new("UICorner",notice).CornerRadius = UDim.new(0,10)

    local chosenColor = alertColor or Purple
    local stroke = Instance.new("UIStroke")
    stroke.Color = chosenColor
    stroke.Thickness = 1.8
    stroke.Parent = notice

    local triangle = Instance.new("TextLabel")
    triangle.Position = UDim2.fromOffset(7,15)
    triangle.Size = UDim2.fromOffset(28,34)
    triangle.BackgroundTransparency = 1
    local isBlack = chosenColor.R < 0.18 and chosenColor.G < 0.18 and chosenColor.B < 0.18
    local isRed = chosenColor.R > chosenColor.G * 1.35 and chosenColor.R > chosenColor.B * 1.2
    triangle.Text = "▲"
    triangle.TextColor3 = chosenColor
    triangle.TextSize = 25
    triangle.Font = Enum.Font.GothamBlack
    triangle.Parent = notice

    local left = 39
    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(left,5)
    title.Size = UDim2.new(1,-left-9,0,17)
    title.BackgroundTransparency = 1
    title.Text = alertTitle or "LK DOORS SYSTEM"
    title.TextColor3 = chosenColor
    title.TextSize = 11
    title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notice

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Position = UDim2.fromOffset(left,24)
    messageLabel.Size = UDim2.new(1,-left-9,0,hasAdvice and 20 or 23)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = tostring(message)
    messageLabel.TextColor3 = White
    messageLabel.TextSize = 12
    messageLabel.Font = Enum.Font.GothamBold
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.Parent = notice

    if hasAdvice then
        local adviceLabel = Instance.new("TextLabel")
        adviceLabel.Position = UDim2.fromOffset(left,45)
        adviceLabel.Size = UDim2.new(1,-left-9,0,29)
        adviceLabel.BackgroundTransparency = 1
        adviceLabel.Text = "DICA: "..advice
        adviceLabel.TextColor3 = White
        adviceLabel.TextSize = 10
        adviceLabel.Font = Enum.Font.Gotham
        adviceLabel.TextXAlignment = Enum.TextXAlignment.Left
        adviceLabel.TextYAlignment = Enum.TextYAlignment.Top
        adviceLabel.TextWrapped = true
        adviceLabel.Parent = notice
    end

    local currentIndex = #ActiveNotifications
    local targetY = 62
    for i=1,currentIndex-1 do
        targetY = targetY + ActiveNotifications[i].Height + 8
    end

    TweenService:Create(
        notice,
        TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {
            Size = UDim2.fromOffset(286,cardHeight),
            Position = UDim2.new(1,-14,0,targetY)
        }
    ):Play()

    task.delay(hasAdvice and 5.5 or 3.2,function()
        if not notice.Parent then return end

        local exitTween = TweenService:Create(
            notice,
            TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {
                Position = UDim2.new(1,300,0,notice.Position.Y.Offset),
                BackgroundTransparency = 1
            }
        )
        for _,child in ipairs(notice:GetChildren()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child,TweenInfo.new(0.25),{TextTransparency=1}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child,TweenInfo.new(0.25),{Transparency=1}):Play()
            end
        end
        exitTween:Play()
        exitTween.Completed:Wait()
        notice:Destroy()

        for i=#ActiveNotifications,1,-1 do
            if ActiveNotifications[i].Frame == notice then
                table.remove(ActiveNotifications,i)
                break
            end
        end
        LK_LayoutNotifications()
    end)
end

function Norm(text)
    return (tostring(text):lower():gsub("[%s_%-%.]",""))
end

function HasAny(text,words)
    for _,word in ipairs(words) do
        if text:find(word,1,true) then
            return true
        end
    end

    return false
end

ESPObjects = {}

EntityNames = {
    "rush","ambush","figure","seek","screech",
    "a60","a120","blitz","lookman","halt",
    "dupe","dread","eyes","grumble","giggle"
}

ItemNames = {
    "lighter","flashlight","crucifix",
    "vitamin","lockpick","shears","bandage",
    "candle"
}

function GetPart(object)
    if object:IsA("BasePart") then return object end

    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChildWhichIsA("BasePart",true)
    end

    if object:IsA("Tool") then
        return object:FindFirstChildWhichIsA("BasePart",true)
    end
end

function IsEntity(name)
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

function IsItem(name)
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

function AddESP(object,category,color,label)
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

function RemoveCategory(category)
    for object,data in pairs(ESPObjects) do
        if data.Category == category then
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            ESPObjects[object] = nil
        end
    end
end

function ClearESPObjects()
    for object,data in pairs(ESPObjects) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end

    table.clear(ESPObjects)
end

CleanupHooks[#CleanupHooks + 1] = ClearESPObjects

Buckets = {
    entity = {},
    book = {},
    lever = {},
    door = {},
    item = {},
    chest = {},
    battery = {}
}

BatteryNameExclude = {
    "charger","station","socket","slot","icon",
    "indicator","meter","gauge"
}

function IsBatteryName(name)
    local n = Norm(name)

    
    if n:find("^livebreakerpolepickup") then return true end

    if not (n:find("^battery") or n:find("^batteries")) then
        return false
    end

    return not HasAny(n,BatteryNameExclude)
end

function IndexObject(object)
    local name = object.Name
    local className = object.ClassName

    if className == "Model" or className == "Tool" then
        if className == "Model" and IsEntity(name) then
            Buckets.entity[object] = true
        end
        local lowerName = string.lower(name)
        if className == "Model" and (lowerName == "door" or lowerName:match("^door%d+$")) then
            Buckets.door[object] = true
        end
        local chestName = string.lower(name)
        if className == "Model" and (chestName:find("chest",1,true) or chestName:find("treasurechest",1,true)) then
            Buckets.chest[object] = true
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

        if string.lower(name) == "door" or string.lower(name):match("^door%d+$") then
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

SeenEntities = {}

function EntitySpawned(object)
    if not object or not object:IsA("Model") then return end
    if not object.Parent or not IsEntity(object.Name) then return end
    if SeenEntities[object] then return end

    SeenEntities[object] = true

    if Settings.Notifier then
        local entity = Norm(object.Name)
        local color = Color3.fromRGB(255,205,55)
        local title = "⚠ ALERTA DE ENTIDADE"
        local advice = "Fique atento e observe o ambiente."

        if entity:find("rush",1,true) then
            color = Color3.fromRGB(255,205,55)
            advice = "Entre em um armário ou esconderijo e espere ele passar."
        elseif entity:find("ambush",1,true) then
            color = Color3.fromRGB(255,65,65)
            advice = "Entre no esconderijo; saia quando passar e volte quando retornar. Repita."
        elseif entity:find("figure",1,true) then
            color = Color3.fromRGB(255,65,65)
            advice = "Agache, afaste-se e evite fazer barulho perto dele."
        elseif entity:find("seek",1,true) then
            color = Color3.fromRGB(255,65,65)
            advice = "Corra seguindo as indicações e desvie dos obstáculos."
        elseif entity:find("halt",1,true) then
            color = Color3.fromRGB(255,205,55)
            advice = "Quando aparecer VIRE-SE e ande na direção oposta."
        elseif entity:find("eyes",1,true) then
            color = Color3.fromRGB(255,205,55)
            advice = "Não olhe para os olhos; mantenha a câmera apontada para longe."
        elseif entity:find("screech",1,true) then
            color = Color3.fromRGB(255,205,55)
            advice = "Quando ouvir 'psst', procure o Screech e olhe diretamente para ele."
        elseif entity:find("dupe",1,true) then
            color = Color3.fromRGB(255,205,55)
            advice = "Confira o número da sala e os sons antes de abrir uma porta."
        elseif entity:find("giggle",1,true) then
            color = Color3.fromRGB(255,205,55)
            advice = "Olhe para cima e use a luz para afastá-lo, se disponível."
        elseif entity:find("grumble",1,true) then
            color = Color3.fromRGB(255,65,65)
            advice = "Afaste-se dos tentáculos e procure uma rota segura."
        elseif entity:find("dread",1,true)
        or entity:find("a60",1,true)
        or entity:find("a120",1,true)
        or entity:find("blitz",1,true)
        or entity:find("lookman",1,true) then
            color = Color3.fromRGB(20,20,20)
            advice = "PERIGO CRÍTICO: procure abrigo imediatamente; não há garantia de escape."
        end

        Notify("ENTIDADE: "..object.Name,color,title,advice)
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

function Scan()
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
            local roomNumber = nil
            local node = object
            local realDoor = false
            for _ = 1, 7 do
                if not node or node == Workspace then break end
                local numericName = tonumber(node.Name)
                if numericName then
                    roomNumber = tostring(math.floor(numericName))
                    realDoor = true
                    break
                end
                node = node.Parent
            end
            -- Mostra apenas portas dentro de salas numeradas; ignora portas genéricas/falsas.
            if roomNumber ~= nil then
                desired[object] = {
                    "DOOR",
                    Color3.fromRGB(40,170,255),
                    "DOOR " .. roomNumber
                }
            end
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

    for object in pairs(Buckets.chest) do
        if not object:IsDescendantOf(Workspace) then
            Buckets.chest[object] = nil
        elseif Settings.Chest then
            local locked = false
            for _,desc in ipairs(object:GetDescendants()) do
                local dn = string.lower(desc.Name)
                if dn:find("lock",1,true) or dn:find("padlock",1,true) then
                    locked = true
                    break
                end
            end
            desired[object] = {
                locked and "CHESTLOCK" or "CHEST",
                locked and Color3.fromRGB(255,75,75) or Color3.fromRGB(255,190,55),
                locked and "ChestLock" or "Chest"
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

PlayerESP = {Active = false, Data = {}, GlobalConns = {}}

function PE_DisconnectList(list)
    for _,connection in ipairs(list) do
        pcall(function() connection:Disconnect() end)
    end

    table.clear(list)
end

function PE_DestroyVisuals(data)
    SafeDestroy(data.Highlight)
    SafeDestroy(data.Billboard)
    data.Highlight = nil
    data.Billboard = nil
    data.NameLabel = nil
end

function PE_Detach(data)
    PE_DestroyVisuals(data)

    if data.CharConn then
        pcall(function() data.CharConn:Disconnect() end)
        data.CharConn = nil
    end

    data.Char = nil
end

function PE_Attach(player,data,character)
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

function PE_Track(player)
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

function PE_Untrack(player)
    local data = PlayerESP.Data[player]
    if not data then return end

    PE_Detach(data)
    PE_DisconnectList(data.Conns)
    PlayerESP.Data[player] = nil
end

function PE_Disable()
    PlayerESP.Active = false

    PE_DisconnectList(PlayerESP.GlobalConns)

    for player in pairs(PlayerESP.Data) do
        PE_Untrack(player)
    end
end

function PE_Enable()
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

function PE_Rebuild()
    if not PlayerESP.Active then return end

    for player,data in pairs(PlayerESP.Data) do
        PE_Attach(player,data,player.Character)
    end
end

CleanupHooks[#CleanupHooks + 1] = PE_Disable

BatteryESP = {Active = false, Items = {}, Token = nil}

function IsInsideCharacter(object)
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

function HasCollectPrompt(object)
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

function ClassifyBattery(object)
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

function BE_Remove(object)
    local data = BatteryESP.Items[object]
    if not data then return end

    SafeDestroy(data.Highlight)
    SafeDestroy(data.Billboard)
    BatteryESP.Items[object] = nil
end

function BE_Add(object)
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

function BE_Refresh()
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

function BE_ClearVisuals()
    for object in pairs(BatteryESP.Items) do
        BE_Remove(object)
    end
end

function BE_Disable()
    BatteryESP.Active = false
    BatteryESP.Token = nil
    BE_ClearVisuals()
end

function BE_Enable()
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

EntitySkinObjects = {}
BuildEntitySkinMap = nil
function SetEntityOriginalVisible(model, visible, record)
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

function RemoveEntitySkin(model)
    local record = EntitySkinObjects[model]
    if not record then return end
    SetEntityOriginalVisible(model, true, record)
    SafeDestroy(record.Avatar)
    EntitySkinObjects[model] = nil
end

function ApplyEntitySkin(model)
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

function NormalizeEntityPartName(name)
    return tostring(name or ""):lower():gsub("[^%w]", "")
end

EntityPartAliases = {
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

function BuildEntityAccessoryMap(avatar, partMap)
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

function SyncEntityAccessories(record)
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

function SyncEntitySkinPose(model, record)
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

function RefreshEntitySkins()
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

AddButton("ESP","ESP Baús","Chest",function(v)
    if not v then RemoveCategory("CHEST"); RemoveCategory("CHESTLOCK") end
end)

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

originalShadows = Lighting.GlobalShadows
originalFog = Lighting.FogEnd

local LK_CulledParts = setmetatable({}, {__mode = "k"})
local LK_CullRunning = false

local function LK_IsProtectedPart(part)
    if not part or not part:IsA("BasePart") or not part.Anchored then return true end
    local character = Player and Player.Character
    if character and part:IsDescendantOf(character) then return true end
    local node = part
    for _ = 1, 5 do
        if not node then break end
        if node:FindFirstChildOfClass("Humanoid") or node:FindFirstChildWhichIsA("ProximityPrompt", true) then
            return true
        end
        node = node.Parent
    end
    local n = string.lower(part.Name)
    if n:find("door",1,true) or n:find("hinge",1,true) or n:find("trigger",1,true)
    or n:find("prompt",1,true) or n:find("collider",1,true) then return true end
    return false
end

local function LK_RestoreCulled()
    for part, oldValue in pairs(LK_CulledParts) do
        if part and part.Parent then
            pcall(function() part.LocalTransparencyModifier = oldValue end)
        end
        LK_CulledParts[part] = nil
    end
end

local function LK_StartSmartCull()
    if LK_CullRunning then return end
    LK_CullRunning = true
    task.spawn(function()
        local lastScan = 0
        while Running and Settings.Optimize do
            local camera = Workspace.CurrentCamera
            local character = Player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if camera and root then
                local look = camera.CFrame.LookVector
                local origin = camera.CFrame.Position
                local checked = 0
                for _, part in ipairs(Workspace:GetDescendants()) do
                    if not Settings.Optimize or not Running then break end
                    if part:IsA("BasePart") and not LK_IsProtectedPart(part) then
                        checked = checked + 1
                        if checked > 3500 then break end
                        local offset = part.Position - origin
                        local distance = offset.Magnitude
                        if distance > 28 and distance < 190 and look:Dot(offset.Unit) < -0.12 then
                            if LK_CulledParts[part] == nil then
                                LK_CulledParts[part] = part.LocalTransparencyModifier
                            end
                            part.LocalTransparencyModifier = 1
                        elseif LK_CulledParts[part] ~= nil then
                            part.LocalTransparencyModifier = LK_CulledParts[part]
                            LK_CulledParts[part] = nil
                        end
                    end
                end
                for part, oldValue in pairs(LK_CulledParts) do
                    if not part or not part.Parent then
                        LK_CulledParts[part] = nil
                    end
                end
            end
            task.wait(0.45)
        end
        LK_RestoreCulled()
        LK_CullRunning = false
    end)
end

AddButton("EXTRAS","Otimizador inteligente","Optimize",function(v)
    if v then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        LK_StartSmartCull()
        Notify("OTIMIZADOR INTELIGENTE ATIVADO")
    else
        LK_RestoreCulled()
        Lighting.GlobalShadows = originalShadows
        Lighting.FogEnd = originalFog
        Notify("OTIMIZADOR DESATIVADO")
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
        Settings.Optimize = false
        LK_RestoreCulled()
        Lighting.GlobalShadows = originalShadows
        Lighting.FogEnd = originalFog
    else
        LK_RestoreCulled()
    end
end

DiagnosePrompts = nil
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

AddAction("CONFIG","🌐 MUDAR IDIOMA / CHANGE LANGUAGE",function()
    if LKLanguagePopup and LKLanguagePopup.Parent then
        LKLanguagePopup:Destroy()
        LKLanguagePopup = nil
        return
    end
    LKLanguagePopup = Instance.new("Frame")
    LKLanguagePopup.Name = "LKLanguagePopup"
    LKLanguagePopup.Size = UDim2.fromOffset(190,156)
    LKLanguagePopup.Position = UDim2.new(0.5,-95,0.5,-78)
    LKLanguagePopup.BackgroundColor3 = Color3.fromRGB(20,22,36)
    LKLanguagePopup.BorderSizePixel = 0
    LKLanguagePopup.ZIndex = 50
    LKLanguagePopup.Parent = Gui
    Instance.new("UICorner",LKLanguagePopup).CornerRadius = UDim.new(0,12)
    local outline = Instance.new("UIStroke")
    outline.Color = Accent2
    outline.Thickness = 1.4
    outline.Parent = LKLanguagePopup
    local heading = Instance.new("TextLabel")
    heading.BackgroundTransparency = 1
    heading.Size = UDim2.new(1,-12,0,32)
    heading.Position = UDim2.fromOffset(8,4)
    heading.Text = "SELECT LANGUAGE"
    heading.TextColor3 = White
    heading.Font = Enum.Font.GothamBold
    heading.TextSize = 12
    heading.ZIndex = 51
    heading.Parent = LKLanguagePopup
    local languages = {{"English","🇺🇸 English"},{"Português","🇧🇷 Português"},{"Español","🇪🇸 Español"}}
    for i,entry in ipairs(languages) do
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1,-16,0,32)
        option.Position = UDim2.fromOffset(8,36+(i-1)*37)
        option.BackgroundColor3 = Settings.Language == entry[1] and Color3.fromRGB(70,49,112) or ButtonColor
        option.Text = entry[2]..(Settings.Language == entry[1] and "  ✓" or "")
        option.TextColor3 = White
        option.Font = Enum.Font.GothamBold
        option.TextSize = 11
        option.ZIndex = 51
        option.Parent = LKLanguagePopup
        Instance.new("UICorner",option).CornerRadius = UDim.new(0,8)
        option.Activated:Connect(function()
            Settings.Language = entry[1]
            Settings.LanguageChosen = true
            SaveSettings(true)
            LK_RefreshLanguage()
            if LKLanguagePopup then LKLanguagePopup:Destroy() LKLanguagePopup = nil end
            Notify(({English="Language changed",["Português"]="Idioma alterado",["Español"]="Idioma cambiado"})[Settings.Language])
        end)
    end
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

AddAction("CONFIG","Ícone do botão flutuante: escolher",function()
    local choices = {"LK","MENU","ABRIR","MINIMIZAR","PERSONALIZADO","VIDEO"}
    local current = table.find(choices, Settings.MenuIconStyle) or 1
    Settings.MenuIconStyle = choices[current % #choices + 1]
    if ApplyLauncherIcon then ApplyLauncherIcon() end
    SaveSettings()
    Notify("ÍCONE DO BOTÃO: "..Settings.MenuIconStyle)
end)

AddAction("CONFIG","Restaurar padrão",function()
    for _,key in ipairs(ConfigKeys) do
        if key == "SpeedValue" then
            Settings[key] = 20
        elseif key == "MenuIconStyle" then
            Settings[key] = "LK"
        else
            Settings[key] = false
        end
    end
    Settings.SaveConfig = true
    SaveSettings()
    Notify("PADRÕES APLICADOS; REEXECUTE O SCRIPT")
end)

UnlockWords = {
    "unlock","destranc","desbloque","use key","usar chave",
    "picklock","pick lock"
}
HideWords = {"hide","esconder"}
PickupWords = {
    "take","collect","pick up","pickup","grab",
    "pegar","coletar","loot"
}
OpenWords = {"open","search","abrir"}

function GetChain(prompt,maxDepth)
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

function NearestDepth(chain,predicate)
    for _,node in ipairs(chain) do
        if predicate(node.Name,node.Inst) then
            return node.Depth
        end
    end
end

ClosetWords = {
    "wardrobe","closet","cabinet","armoire",
    "cupboard","locker","armario","hidingspot"
}

function IsDoorName(n)
    return n == "door" or n:find("^door") ~= nil
end

function IsLockNodeName(n)
    if n == "lock" or n == "doorlock" then return true end

    return n:find("^lock") ~= nil
        and not n:find("lockpick",1,true)
        and not n:find("locker",1,true)
end

function IsClosetName(n) return HasAny(n,ClosetWords) end
function IsDrawerName(n) return n:find("drawer",1,true) ~= nil end

function IsDresserOrTableName(n)
    return n:find("dresser",1,true) ~= nil
        or n:find("table",1,true) ~= nil
end

function IsPadlockName(n)
    return n:find("padlock",1,true) ~= nil
        or n:find("keypad",1,true) ~= nil
        or n:find("^code") ~= nil
end

function IsCoinName(n)
    return n == "coin" or n == "coins"
        or n == "gold" or n == "goldpile"
        or n == "goldcoin" or n == "goldcoins"
        or n == "coinpile"
        or n:match("^goldpile%d+$") ~= nil
        or n:match("^coin%d+$") ~= nil
        or n:match("^gold%d+$") ~= nil
end

ItemPrefixes = {
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

ItemExcludes = {
    "keyhole","keypad","keyboard","keycard",
    "candlemedium","candlestick","candleholder","candlestand"
}

function ItemCategory(n)
    for _,entry in ipairs(ItemPrefixes) do
        if n:find("^"..entry[1]) then
            if HasAny(n,ItemExcludes) then return nil end
            return entry[2]
        end
    end

    return nil
end

function HasHidePrompt(node)
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

function ClassifyKey(prompt,chain,text)
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

function ClassifyItem(prompt,chain,text)
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

function ClassifyCoin(prompt,chain,text)
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

function ClassifyDrawer(prompt,chain,text)
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

function FindKeyTools()
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

function PrepareKey()
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

HasFirePrompt = type(fireproximityprompt) == "function"

function FirePrompt(prompt)
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

AutoSystems = {
    {Name = "AutoKey",Setting = "AutoKey",Classify = ClassifyKey,
        Prepare = PrepareKey,Interval = 0.35,Cooldown = 0.9,Attempts = 2},
    {Name = "AutoItems",Setting = "AutoItems",Classify = ClassifyItem,
        Interval = 0.12,Cooldown = 0.35,Attempts = 2},
    {Name = "AutoCoins",Setting = "AutoCoins",Classify = ClassifyCoin,
        Interval = 0.10,Cooldown = 0.30,Attempts = 2},
    {Name = "AutoDrawers",Setting = "AutoDrawers",Classify = ClassifyDrawer,
        Interval = 0.25,Cooldown = 0.50,Attempts = 1}
}

ShownPrompts = {}
PromptActive = {}
PromptNext = {}

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
LastFire = {}

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

function StartAuto(system,prompt)
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

CodeGui = Instance.new("ScreenGui")
CodeGui.Name = "LKAutoCode50"
CodeGui.ResetOnSpawn = false
CodeGui.Parent = GuiParent
CodeGui.Enabled = false 

CleanupHooks[#CleanupHooks + 1] = function() SafeDestroy(CodeGui) end

CodeFrame = Instance.new("Frame")
CodeFrame.Name = "CodePanel"
CodeFrame.AnchorPoint = Vector2.new(1,0)
CodeFrame.Position = UDim2.new(1,-6,0.28,0)
CodeFrame.Size = UDim2.fromOffset(150,108)
CodeFrame.BackgroundColor3 = Dark
CodeFrame.BorderSizePixel = 0
CodeFrame.Parent = CodeGui

Instance.new("UICorner",CodeFrame).CornerRadius = UDim.new(0,10)

CodeStroke = Instance.new("UIStroke")
CodeStroke.Color = Color3.fromRGB(95,60,145)
CodeStroke.Thickness = 1.3
CodeStroke.Parent = CodeFrame

CodeHeader = Instance.new("Frame")
CodeHeader.Size = UDim2.new(1,0,0,24)
CodeHeader.BackgroundColor3 = Panel
CodeHeader.BorderSizePixel = 0
CodeHeader.Parent = CodeFrame

Instance.new("UICorner",CodeHeader).CornerRadius = UDim.new(0,10)

CodeTitle = Instance.new("TextLabel")
CodeTitle.Position = UDim2.fromOffset(8,0)
CodeTitle.Size = UDim2.new(1,-34,1,0)
CodeTitle.BackgroundTransparency = 1
CodeTitle.Text = "LK AUTO CODE 50"
CodeTitle.TextColor3 = White
CodeTitle.Font = Enum.Font.GothamBlack
CodeTitle.TextSize = 10
CodeTitle.TextXAlignment = Enum.TextXAlignment.Left
CodeTitle.Parent = CodeHeader

CodeMin = Instance.new("TextButton")
CodeMin.Size = UDim2.fromOffset(22,18)
CodeMin.Position = UDim2.new(1,-25,0,3)
CodeMin.BackgroundColor3 = ButtonColor
CodeMin.Text = "—"
CodeMin.TextColor3 = White
CodeMin.Font = Enum.Font.GothamBold
CodeMin.TextSize = 12
CodeMin.Parent = CodeHeader

Instance.new("UICorner",CodeMin).CornerRadius = UDim.new(0,6)

DigitRow = Instance.new("Frame")
DigitRow.Position = UDim2.fromOffset(8,30)
DigitRow.Size = UDim2.new(1,-16,0,32)
DigitRow.BackgroundTransparency = 1
DigitRow.Parent = CodeFrame

DigitLayout = Instance.new("UIListLayout")
DigitLayout.FillDirection = Enum.FillDirection.Horizontal
DigitLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
DigitLayout.Padding = UDim.new(0,4)
DigitLayout.Parent = DigitRow

DigitLabels = {}

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

CodeStatus = Instance.new("TextLabel")
CodeStatus.Position = UDim2.fromOffset(6,66)
CodeStatus.Size = UDim2.new(1,-12,0,22)
CodeStatus.BackgroundTransparency = 1
CodeStatus.Text = ""
CodeStatus.TextColor3 = Purple
CodeStatus.Font = Enum.Font.GothamBold
CodeStatus.TextSize = 9
CodeStatus.TextWrapped = true
CodeStatus.Parent = CodeFrame

CodeSub = Instance.new("TextLabel")
CodeSub.Position = UDim2.fromOffset(6,88)
CodeSub.Size = UDim2.new(1,-12,0,16)
CodeSub.BackgroundTransparency = 1
CodeSub.Text = ""
CodeSub.TextColor3 = Color3.fromRGB(170,170,190)
CodeSub.Font = Enum.Font.Gotham
CodeSub.TextSize = 8
CodeSub.TextWrapped = true
CodeSub.Parent = CodeFrame

CodeMini = Instance.new("TextButton")
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

CodeState = {
    InLibrary = false,
    Since = 0,
    Slots = {},      
    Conflict = {}    
}

SEARCH_TIMEOUT = 20
SOUND_CONFIG_FILE = "LK_DOORS_SOUND_CONFIG.json"
SOUND_FOLDER = "LK_DOORS_SOM/"
SoundConfig = {
    notification = "notification.ogg", click = "click.ogg",
    arrival = "room50.ogg", book = "book.ogg",
    digit = "digit.ogg", complete = "complete.ogg"
}
SoundService = game:GetService("SoundService")
ActiveSounds = {}

function LoadSoundConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, exists = pcall(isfile, SOUND_CONFIG_FILE)
    if not ok or not exists then return end
    local good, data = pcall(function() return HttpService:JSONDecode(readfile(SOUND_CONFIG_FILE)) end)
    if good and type(data) == "table" then
        for key in pairs(SoundConfig) do
            if type(data[key]) == "string" then SoundConfig[key] = data[key] end
        end
    end
end

PlayMenuSound = function(kind)
    local filename = SoundConfig[kind]
    if type(filename) ~= "string" or filename == "" then return end
    filename = filename:gsub("^/+", "")
    local candidates = { SOUND_FOLDER .. filename, "Delta/" .. SOUND_FOLDER .. filename, "/storage/emulated/0/Delta/" .. SOUND_FOLDER .. filename }
    local asset
    for _, path in ipairs(candidates) do
        if type(getcustomasset) == "function" then
            local ok, result = pcall(getcustomasset, path)
            if ok and type(result) == "string" then asset = result break end
        elseif type(getsynasset) == "function" then
            local ok, result = pcall(getsynasset, path)
            if ok and type(result) == "string" then asset = result break end
        end
    end
    if not asset then return end
    local sound = Instance.new("Sound")
    sound.Name = "LKMenuSound_" .. kind
    sound.SoundId = asset
    sound.Volume = 0.65
    sound.Parent = SoundService
    ActiveSounds[#ActiveSounds + 1] = sound
    pcall(function() sound:Play() end)
    sound.Ended:Connect(function() sound:Destroy() end)
    task.delay(15, function() if sound.Parent then sound:Destroy() end end)
end

function PlayCodeSound(kind)
    PlayMenuSound(kind)
end

LoadSoundConfig()

SoundToggle = Instance.new("TextButton")
SoundToggle.Name = "SoundSettings"
SoundToggle.Size = UDim2.fromOffset(22,18)
SoundToggle.Position = UDim2.new(1,-50,0,3)
SoundToggle.BackgroundColor3 = ButtonColor
SoundToggle.Text = "♫"
SoundToggle.TextColor3 = White
SoundToggle.Font = Enum.Font.GothamBold
SoundToggle.TextSize = 12
SoundToggle.Parent = CodeHeader
Instance.new("UICorner",SoundToggle).CornerRadius = UDim.new(0,6)

SoundPanel = Instance.new("Frame")
SoundPanel.Name = "SoundSettingsPanel"
SoundPanel.Position = UDim2.new(0,0,1,5)
SoundPanel.Size = UDim2.fromOffset(224,252)
SoundPanel.BackgroundColor3 = Panel
SoundPanel.Visible = false
SoundPanel.ZIndex = 20
SoundPanel.Parent = CodeFrame
Instance.new("UICorner",SoundPanel).CornerRadius = UDim.new(0,8)
soundFields = {}
soundSpecs = {
    {"notification","Notificação"}, {"click","Clique no menu"},
    {"arrival","Entrada sala 50"}, {"book","Pegou livro"},
    {"digit","Número confirmado"}, {"complete","Código completo"}
}
for i, spec in ipairs(soundSpecs) do
    local y = 5+(i-1)*32
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(7, y)
    label.Size = UDim2.fromOffset(91,24)
    label.BackgroundTransparency = 1
    label.Text = spec[2]
    label.TextColor3 = White
    label.TextSize = 9
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 21
    label.Parent = SoundPanel
    local field = Instance.new("TextBox")
    field.Position = UDim2.fromOffset(99, y)
    field.Size = UDim2.fromOffset(117,24)
    field.BackgroundColor3 = ButtonColor
    field.TextColor3 = White
    field.PlaceholderText = "arquivo.ogg"
    field.Text = SoundConfig[spec[1]]
    field.ClearTextOnFocus = false
    field.TextSize = 9
    field.Font = Enum.Font.Gotham
    field.ZIndex = 21
    field.Parent = SoundPanel
    soundFields[spec[1]] = field
end
SaveSounds = Instance.new("TextButton")
SaveSounds.Position = UDim2.fromOffset(7,202)
SaveSounds.Size = UDim2.fromOffset(209,25)
SaveSounds.BackgroundColor3 = Purple
SaveSounds.Text = "SALVAR SONS (.JSON)"
SaveSounds.TextColor3 = White
SaveSounds.TextSize = 9
SaveSounds.Font = Enum.Font.GothamBold
SaveSounds.ZIndex = 21
SaveSounds.Parent = SoundPanel
Instance.new("UICorner",SaveSounds).CornerRadius = UDim.new(0,6)
TestSounds = Instance.new("TextButton")
TestSounds.Position = UDim2.fromOffset(7,231)
TestSounds.Size = UDim2.fromOffset(209,17)
TestSounds.BackgroundColor3 = ButtonColor
TestSounds.Text = "TESTAR NOTIFICAÇÃO"
TestSounds.TextColor3 = White
TestSounds.TextSize = 8
TestSounds.Font = Enum.Font.GothamBold
TestSounds.ZIndex = 21
TestSounds.Parent = SoundPanel
Instance.new("UICorner",TestSounds).CornerRadius = UDim.new(0,5)
SoundToggle.Activated:Connect(function()
    PlayMenuSound("click")
    SoundPanel.Visible = not SoundPanel.Visible
end)
TestSounds.Activated:Connect(function()
    PlayMenuSound("click")
    PlayMenuSound("notification")
end)
SaveSounds.Activated:Connect(function()
    for key, field in pairs(soundFields) do
        local value = field.Text:gsub("[%c]", "")
        if value:find("/", 1, true) then value = value:match("([^/]+)$") or value end
        SoundConfig[key] = value
    end
    local ok = false
    if type(writefile) == "function" then
        ok = pcall(function() writefile(SOUND_CONFIG_FILE, HttpService:JSONEncode(SoundConfig)) end)
    end
    CodeSub.Text = ok and "Nomes dos sons salvos no JSON" or "Delta sem suporte a writefile"
end)

function GetLibraryRoom()
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

function PlayerInsideRoom(room)
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

function KeyNorm(key)
    return (tostring(key):lower():gsub("[^%w]",""))
end

CompleteKeys = {
    code = true,libcode = true,librarycode = true,padlockcode = true,
    answer = true,solution = true,correctcode = true,actualcode = true,
    finalcode = true,secretcode = true,combination = true
}

SlotPrefixes = {"digit","code","hint","number","num","slot","pos","d","n"}
SlotKeys = {index = true,slot = true,position = true,order = true,pos = true}
DigitKeys = {digit = true,number = true,value = true,num = true}

function DigitFrom(value)
    if type(value) == "number" then
        if value >= 0 and value <= 9 and value % 1 == 0 then return value end
        return nil
    end

    if type(value) == "string" and value:match("^%d$") then
        return tonumber(value)
    end

    return nil
end

function FiveFrom(value)
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

function AddEvidence(evidence,slot,digit)
    evidence[slot] = evidence[slot] or {}
    evidence[slot][digit] = true
end

function ConsiderKV(evidence,key,value)
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

RelevantWords = {
    "code","hint","digit","padlock","clue",
    "answer","number","solution","paper","book"
}

function RelevantName(name)
    return HasAny(name:lower(),RelevantWords)
end

function CollectInstance(evidence,instance)
    
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

function CollectRoom(evidence,room)
    local processed = 0

    for _,instance in ipairs(room:GetDescendants()) do
        processed = processed + 1
        if processed % 600 == 0 then task.wait() end

        if RelevantName(instance.Name) then
            CollectInstance(evidence,instance)
        end
    end
end

GuiVetoWords = {
    "padlock","input","entry","keypad","lock","guess","selector","current"
}

function CollectGui(evidence)
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

LastBookCount = nil
CollectedBookCount = 0
function CountLibraryBooks(room)
    local count = 0
    for _, obj in ipairs(room:GetDescendants()) do
        local n = obj.Name:lower()
        if n == "livehintbook" or n == "hintbook" or n == "book" then
            if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool") then
                count = count + 1
            end
        end
    end
    return count
end

function RenderPanel(inside,elapsed)
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
        CodeSub.Text = "Código pronto — use os 5 números"
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
        CodeStatus.Text = "PEGUE A FOLHA E OS LIVROS"
        CodeSub.Text = "O código atualiza conforme os dados são encontrados"
    end
end

function HasLibraryPaper()
    local containers = {
        Player:FindFirstChildOfClass("Backpack"),
        Player.Character,
        Player:FindFirstChildOfClass("PlayerGui")
    }

    for _,container in ipairs(containers) do
        if container then
            for _,item in ipairs(container:GetDescendants()) do
                local n = item.Name:lower()
                if n:find("paper",1,true) or n:find("hintbook",1,true)
                or n:find("libraryhint",1,true) then
                    return true
                end
            end
        end
    end
    return false
end

function CodeStep()
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    local room50 = rooms and rooms:FindFirstChild("50")
    local inside = room50 ~= nil and PlayerInsideRoom(room50)
    local room = inside and room50 or nil

    if not inside then
        if CodeState.InLibrary then CodeGui.Enabled = false end
        CodeState.InLibrary = false
        LastBookCount = nil
        CollectedBookCount = 0
        table.clear(CodeState.Slots)
        table.clear(CodeState.Conflict)
        RenderPanel(false,0)
        return
    end

    if not CodeState.InLibrary then
        CodeState.InLibrary = true
        CodeState.Since = os.clock()
        LastBookCount = CountLibraryBooks(room)
        CollectedBookCount = 0
        CodeGui.Enabled = true
        CodeFrame.Visible = true
        CodeMini.Visible = false
        table.clear(CodeState.Slots)
        table.clear(CodeState.Conflict)
        PlayCodeSound("arrival")
    else
        local currentBooks = CountLibraryBooks(room)
        if LastBookCount ~= nil and currentBooks < LastBookCount then
            CollectedBookCount = CollectedBookCount + (LastBookCount - currentBooks)
            PlayCodeSound("book")
        end
        LastBookCount = currentBooks
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
            local wasUnknown = CodeState.Slots[slot] == nil
            CodeState.Slots[slot] = slots[slot]
            CodeState.Conflict[slot] = nil
            if wasUnknown then PlayCodeSound("digit") end
        end
    end

    -- Recalcula aqui: a variável `confirmed` de RenderPanel é local daquela função.
    local confirmed = 0
    for slot = 1, 5 do
        if CodeState.Slots[slot] ~= nil then
            confirmed = confirmed + 1
        end
    end

    RenderPanel(true,os.clock() - CodeState.Since)
    if confirmed < 5 then
        CodeSub.Text = "Pegue a folha e os livros | livros: "..tostring(CollectedBookCount)
    end
    if confirmed == 5 and not CodeState.CompletedSoundPlayed then
        CodeState.CompletedSoundPlayed = true
        PlayCodeSound("complete")
    elseif confirmed < 5 then
        CodeState.CompletedSoundPlayed = false
    end
end

task.spawn(function()
    RenderPanel(false,0)
    CodeGui.Enabled = false

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

LauncherIcon = nil
function ApplyLauncherIcon()
    if not OpenButton then return end
    local style = Settings.MenuIconStyle or "LK"
    if LauncherIcon then LauncherIcon:Destroy(); LauncherIcon = nil end
    if LauncherVideo then
        pcall(function() LauncherVideo:Pause() end)
        LauncherVideo:Destroy()
        LauncherVideo = nil
    end
    OpenButton.Text = style == "LK" and "LK" or ""
    if style == "VIDEO" then
        local videoAsset = LKGetIconAsset("perso_video.mp4")
        if videoAsset then
            local ok, video = pcall(function()
                local frame = Instance.new("VideoFrame")
                frame.Name = "LauncherVideo"
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.Position = UDim2.fromScale(0,0)
                frame.Size = UDim2.fromScale(1,1)
                frame.AnchorPoint = Vector2.new(0,0)
                frame.Video = videoAsset
                frame.Looped = true
                frame.Volume = 0
                frame.Active = false
                frame.ZIndex = OpenButton.ZIndex + 1
                frame.Parent = OpenButton
                frame:Play()
                return frame
            end)
            if ok then
                LauncherVideo = video
            else
                OpenButton.Text = "VIDEO INDISPONÍVEL"
                Notify("O Delta não conseguiu abrir o MP4 local")
            end
        else
            OpenButton.Text = "MP4 NÃO ENCONTRADO"
            Notify("Coloque perso_video.mp4 em Delta/LK_DOORS_ICONS")
        end
    elseif style ~= "LK" then
        local iconFiles = {
            MENU = "menu_icon.png",
            ABRIR = "open_icon.png",
            MINIMIZAR = "minimize_icon.png",
            PERSONALIZADO = "launcher_icon.png"
        }
        local asset = LKGetIconAsset(iconFiles[style] or "open_icon.png")
        if asset then
            LauncherIcon = Instance.new("ImageLabel")
            LauncherIcon.Name = "LauncherIcon"
            LauncherIcon.BackgroundTransparency = 1
            LauncherIcon.BorderSizePixel = 0
            LauncherIcon.AnchorPoint = Vector2.new(0,0)
            LauncherIcon.Position = UDim2.fromScale(0,0)
            LauncherIcon.Size = UDim2.fromScale(1,1)
            LauncherIcon.Image = asset
            LauncherIcon.ScaleType = Enum.ScaleType.Crop
            LauncherIcon.Parent = OpenButton
            LauncherIcon.ZIndex = OpenButton.ZIndex + 1
        else
            OpenButton.Text = style == "MENU" and "≡" or (style == "MINIMIZAR" and "—" or "↗")
        end
    end
    if OpenSub then OpenSub.Visible = false end
end

OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenMenu"
OpenButton.AnchorPoint = Vector2.new(0,0.5)
OpenButton.Size = UDim2.fromOffset(62,54)
OpenButton.Position = UDim2.new(0,12,0.5,0)
OpenButton.BackgroundColor3 = Color3.fromRGB(48,31,78)
OpenButton.Text = "LK"
OpenButton.TextColor3 = White
OpenButton.Font = Enum.Font.GothamBlack
OpenButton.TextSize = 19
OpenButton.AutoButtonColor = false
OpenButton.Visible = false
OpenButton.Parent = Gui
Corner(OpenButton,16)
Stroke(OpenButton,Accent2,1.4,0.1)

OpenSub = Instance.new("TextLabel")
OpenSub.Size = UDim2.new(1,0,0,13)
OpenSub.Position = UDim2.new(0,0,1,-15)
OpenSub.BackgroundTransparency = 1
OpenSub.Text = "MENU"
OpenSub.TextColor3 = Accent2
OpenSub.Font = Enum.Font.GothamBold
OpenSub.TextSize = 8
OpenSub.Parent = OpenButton
ApplyLauncherIcon()

function HideMenu()
    if not Main.Visible then return end
    local tween = TweenService:Create(Main,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
        Position = UDim2.new(Main.Position.X.Scale,Main.Position.X.Offset,Main.Position.Y.Scale,Main.Position.Y.Offset+14)
    })
    tween:Play()
    task.delay(0.16,function()
        if Main and Main.Parent then
            Main.Visible = false
            OpenButton.Visible = true
        end
    end)
end

function ShowMenu()
    Main.Visible = true
    OpenButton.Visible = false
    local target = UDim2.new(0.5,-width/2,0.5,-height/2)
    Main.Position = UDim2.new(0.5,-width/2,0.5,-height/2+14)
    TweenService:Create(Main,TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
        Position = target
    }):Play()
end

Minimize.Activated:Connect(HideMenu)
CloseButton.Activated:Connect(HideMenu)
OpenButton.Activated:Connect(ShowMenu)

dragging = false
dragStart = nil
startPos = nil
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
        or Settings.Lever or Settings.Notifier
        or Settings.Chest then

            local success,err = pcall(Scan)

            if not success then
                warn("LK DOORS SCAN ERROR:",err)
            end
        end

        task.wait(1.5)
    end
end)

LK_RefreshLanguage()
Notify("LK DOORS V10.3 CARREGADO!")
print("LK DOORS SYSTEM V10.3 carregado!")

end)
if not __LK_ok then
    warn("[LK DOORS] ERRO AO INICIAR: "..tostring(__LK_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{Title="LK DOORS - ERRO",Text=tostring(__LK_err):sub(1,180),Duration=15})
    end)
end
