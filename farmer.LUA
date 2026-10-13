-- Services
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local LOG_FILE = "ServerLogger_Logs.json"
local SETTINGS_FILE = "ServerLogger_Settings.json"
local SCRIPT_FILE = "ServerLogger_Main.lua"
local VERSION = "v7"

print("[ServerLogger] " .. VERSION .. " loading...")

local function killOldGuis(container)
    if not container then return end
    pcall(function()
        for _, gui in ipairs(container:GetChildren()) do
            if gui.Name == "ServerLoggerGui" then gui:Destroy() end
        end
    end)
end
killOldGuis(CoreGui)
if gethui then killOldGuis(gethui()) end
local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if pg then killOldGuis(pg) end

local currentScriptSource = [==[
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end
if getgenv and getgenv().ServerLoggerLoaded then return end
if getgenv then getgenv().ServerLoggerLoaded = true end

local LOG_FILE = "ServerLogger_Logs.json"
local SETTINGS_FILE = "ServerLogger_Settings.json"
local VERSION = "v7"

local function killOldGuis(container)
    if not container then return end
    pcall(function()
        for _, gui in ipairs(container:GetChildren()) do
            if gui.Name == "ServerLoggerGui" then gui:Destroy() end
        end
    end)
end
killOldGuis(CoreGui)
if gethui then killOldGuis(gethui()) end
local pg0 = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if pg0 then killOldGuis(pg0) end

local settingsData = {
    huntSpook = true,
    huntSinister = true,
    huntLoneCave = false,
    huntBlueSpruce = false,
    huntVolcano = false,
    huntFrost = false,
    huntPalm = false,
    huntBirch = false,
    huntCherry = false,
    huntKoa = false,
    huntOak = false,
    huntPine = false,
    huntGold = false,
    hopAfterFind = true,
    isPaused = false,
    autofarmActive = true
}

if writefile and readfile and pcall(function() return readfile(SETTINGS_FILE) end) then
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(SETTINGS_FILE)) end)
    if success and decoded then
        for k, v in pairs(decoded) do settingsData[k] = v end
    end
end

local savedData = { spook = {}, sinister = {}, other = {} }
if writefile and readfile and pcall(function() return readfile(LOG_FILE) end) then
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(LOG_FILE)) end)
    if success and decoded then
        for k, v in pairs(decoded) do
            if type(v) == "table" then savedData[k] = v end
        end
    end
end

local function saveData()
    if writefile then pcall(function() writefile(LOG_FILE, HttpService:JSONEncode(savedData)) end) end
end
local function saveSettings()
    if writefile then pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(settingsData)) end) end
end

local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queueFunction then
    pcall(function()
        queueFunction('if loadfile then loadfile("ServerLogger_Main.lua")() elseif readfile then loadstring(readfile("ServerLogger_Main.lua"))() end')
    end)
end

local safeTeleport
local setStatus
local isTeleporting = false
local hopAttempts = 0
local currentJobId = game.JobId

-- =====================  GUI SETUP  =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerLoggerGui"
ScreenGui.ResetOnSpawn = false

local guiParented = false
if syn and syn.protect_gui then
    guiParented = pcall(function()
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    end)
elseif gethui then
    guiParented = pcall(function() ScreenGui.Parent = gethui() end)
end
if not guiParented then
    guiParented = pcall(function() ScreenGui.Parent = CoreGui end)
end
if not guiParented then
    ScreenGui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 566)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -283)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 260, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 2)
Title.BackgroundTransparency = 1
Title.Text = "Tree Hunter " .. VERSION
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 22)
StatusLabel.Position = UDim2.new(0, 10, 0, 32)
StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
StatusLabel.Text = "Status: Starting Auto-Scan..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 4)

setStatus = function(text, color)
    pcall(function()
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or Color3.fromRGB(255, 200, 0)
    end)
end

local ToggleFarmBtn = Instance.new("TextButton")
ToggleFarmBtn.Size = UDim2.new(0, 95, 0, 24)
ToggleFarmBtn.Position = UDim2.new(0, 235, 0, 5)
ToggleFarmBtn.BackgroundColor3 = settingsData.autofarmActive and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(170, 50, 50)
ToggleFarmBtn.Text = settingsData.autofarmActive and "RUNNING" or "STOPPED"
ToggleFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleFarmBtn.Font = Enum.Font.GothamBold
ToggleFarmBtn.TextSize = 11
ToggleFarmBtn.Parent = MainFrame
Instance.new("UICorner", ToggleFarmBtn).CornerRadius = UDim.new(0, 6)

local function updateStartButton()
    ToggleFarmBtn.BackgroundColor3 = settingsData.autofarmActive and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(170, 50, 50)
    ToggleFarmBtn.Text = settingsData.autofarmActive and "RUNNING" or "STOPPED"
end

ToggleFarmBtn.MouseButton1Click:Connect(function()
    settingsData.autofarmActive = not settingsData.autofarmActive
    settingsData.isPaused = false
    saveSettings()
    updateStartButton()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        if input.KeyCode == Enum.KeyCode.H then
            settingsData.autofarmActive = not settingsData.autofarmActive
            saveSettings()
            updateStartButton()
        elseif input.KeyCode == Enum.KeyCode.G then
            settingsData.isPaused = not settingsData.isPaused
            saveSettings()
        end
    end
end)

-- Tree Toggles
local TreeScroll = Instance.new("ScrollingFrame")
TreeScroll.Size = UDim2.new(1, -20, 0, 120)
TreeScroll.Position = UDim2.new(0, 10, 0, 60)
TreeScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TreeScroll.ScrollBarThickness = 4
TreeScroll.Parent = MainFrame
Instance.new("UICorner", TreeScroll).CornerRadius = UDim.new(0, 6)

local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.CellSize = UDim2.new(0, 95, 0, 22)
UIGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
UIGridLayout.Parent = TreeScroll

UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TreeScroll.CanvasSize = UDim2.new(0, 0, 0, UIGridLayout.AbsoluteContentSize.Y + 10)
end)

local function createToggle(name, activeKey)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = settingsData[activeKey] and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(100, 50, 50)
    btn.Text = name .. ": " .. (settingsData[activeKey] and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = TreeScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        settingsData[activeKey] = not settingsData[activeKey]
        btn.BackgroundColor3 = settingsData[activeKey] and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(100, 50, 50)
        btn.Text = name .. ": " .. (settingsData[activeKey] and "ON" or "OFF")
        saveSettings()
    end)
end

createToggle("Spook", "huntSpook")
createToggle("Sinister", "huntSinister")
createToggle("LoneCave", "huntLoneCave")
createToggle("BlueSpruce", "huntBlueSpruce")
createToggle("Volcano", "huntVolcano")
createToggle("Frost", "huntFrost")
createToggle("Palm", "huntPalm")
createToggle("Birch", "huntBirch")
createToggle("Cherry", "huntCherry")
createToggle("Koa", "huntKoa")
createToggle("Oak", "huntOak")
createToggle("Pine", "huntPine")
createToggle("Gold", "huntGold")
createToggle("HopAfter", "hopAfterFind")

-- =====================  SERVER LOG LIST  =====================
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -20, 1, -268)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 258)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
ScrollingFrame.ScrollingEnabled = true
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollingFrame.ClipsDescendants = true
ScrollingFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollingFrame

local function getMaxScroll()
    local canvasH = ScrollingFrame.CanvasSize.Y.Offset
    local windowH = ScrollingFrame.AbsoluteSize.Y
    if canvasH <= windowH then return 0 end
    return canvasH - windowH
end

local function scrollBy(delta)
    local maxScroll = getMaxScroll()
    local newY = ScrollingFrame.CanvasPosition.Y + delta
    if newY < 0 then newY = 0 end
    if newY > maxScroll then newY = maxScroll end
    ScrollingFrame.CanvasPosition = Vector2.new(0, newY)
end

local ScrollUpBtn = Instance.new("TextButton")
ScrollUpBtn.Size = UDim2.new(0, 24, 0, 24)
ScrollUpBtn.Position = UDim2.new(1, -32, 0, 262)
ScrollUpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ScrollUpBtn.Text = "^"
ScrollUpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollUpBtn.TextSize = 14
ScrollUpBtn.Font = Enum.Font.GothamBold
ScrollUpBtn.ZIndex = 5
ScrollUpBtn.Parent = MainFrame
Instance.new("UICorner", ScrollUpBtn).CornerRadius = UDim.new(0, 6)
ScrollUpBtn.MouseButton1Click:Connect(function() scrollBy(-90) end)

local ScrollDownBtn = Instance.new("TextButton")
ScrollDownBtn.Size = UDim2.new(0, 24, 0, 24)
ScrollDownBtn.Position = UDim2.new(1, -32, 1, -36)
ScrollDownBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ScrollDownBtn.Text = "v"
ScrollDownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollDownBtn.TextSize = 14
ScrollDownBtn.Font = Enum.Font.GothamBold
ScrollDownBtn.ZIndex = 5
ScrollDownBtn.Parent = MainFrame
Instance.new("UICorner", ScrollDownBtn).CornerRadius = UDim.new(0, 6)
ScrollDownBtn.MouseButton1Click:Connect(function() scrollBy(90) end)

-- =====================  LOG HELPERS  =====================
local function relTime(t)
    t = tonumber(t) or 0
    if t <= 0 then return "LEGACY" end
    local d = os.time() - t
    if d < 0 then d = 0 end
    if d < 60 then return "just now" end
    if d < 3600 then return math.floor(d / 60) .. "m ago" end
    if d < 86400 then return math.floor(d / 3600) .. "h ago" end
    return math.floor(d / 86400) .. "d ago"
end

local function fmtVol(v)
    v = tonumber(v) or 0
    if v <= 0 then return "-" end
    if v >= 1000 then return string.format("%.1fk", v / 1000) end
    return tostring(math.floor(v))
end

local function scoreOf(e)
    local ageMin = 99999
    if (tonumber(e.time) or 0) > 0 then
        ageMin = (os.time() - e.time) / 60
        if ageMin < 0 then ageMin = 0 end
    end
    return (tonumber(e.size) or 0) / (1 + ageMin)
end

local function removeByJobId(jobId)
    for _, cat in ipairs({ "spook", "sinister", "other" }) do
        local list = savedData[cat]
        for i = #list, 1, -1 do
            if list[i].jobId == jobId then
                table.remove(list, i)
            end
        end
    end
    saveData()
end

local function logCurrentServer(category, size, treeClass)
    if not savedData[category] then savedData[category] = {} end
    local list = savedData[category]
    local now = os.time()
    for _, e in ipairs(list) do
        if e.jobId == game.JobId then
            e.time = now
            e.players = #Players:GetPlayers()
            if size then e.size = size end
            if treeClass then e.treeClass = treeClass end
            saveData()
            return
        end
    end
    table.insert(list, {
        placeId = game.PlaceId,
        jobId = game.JobId,
        players = #Players:GetPlayers(),
        time = now,
        size = size or 0,
        treeClass = treeClass or "?"
    })
    table.sort(list, function(a, b) return (a.time or 0) > (b.time or 0) end)
    saveData()
end

local activeCategory = "top"
local RENDER_CAP = 100
local lastRowCount = 0

local function updateCanvas()
    local contentH = UIListLayout.AbsoluteContentSize.Y + 8
    local h = contentH
    if lastRowCount > 0 and h < 600 then
        h = 600
    end
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, h)
end

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    pcall(updateCanvas)
end)

-- =====================  LIVE TREE CHECK (v7 - minimal)  =====================
-- v6 required Owner + Model type + WoodSection -> everything got filtered.
-- v7: a tree is ANY TreeClass whose parent has a WoodSection part.
-- Sawmilled planks use "Wood" parts, not "WoodSection", so they still get ignored.
local function isLiveTree(tree)
    if not tree then return false end
    for _, p in ipairs(tree:GetDescendants()) do
        if p:IsA("BasePart") and string.find(p.Name, "WoodSection") then
            return true
        end
    end
    return false
end

-- missing Owner = free; Owner present + empty = free; anything else = owned
local function isFree(tree)
    if not tree then return false end
    local owner = tree:FindFirstChild("Owner")
    if not owner then return true end
    local okv, v = pcall(function() return owner.Value end)
    if okv and (v == nil or v == "") then return true end
    return false
end

local CLASS_TO_KEYS = {
    Spooky = { "huntSpook" },
    SpookyNeon = { "huntSinister" },
    CaveCrawler = { "huntLoneCave" },
    BlueSpruce = { "huntBlueSpruce" },
    Volcano = { "huntVolcano" },
    Fire = { "huntVolcano" },
    Frost = { "huntFrost" },
    SnowGlow = { "huntFrost" },
    Palm = { "huntPalm" },
    Birch = { "huntBirch" },
    Cherry = { "huntCherry" },
    Koa = { "huntKoa" },
    Oak = { "huntOak" },
    Generic = { "huntOak" },
    Pine = { "huntPine" },
    Gold = { "huntGold" },
    GoldSwampy = { "huntGold" },
}

local SPECIAL_CLASSES = { Spooky = true, SpookyNeon = true }

local function isClassHunted(class)
    local keys = CLASS_TO_KEYS[class]
    if not keys then return false end
    for _, k in ipairs(keys) do
        if settingsData[k] then return true end
    end
    return false
end

local function scanServerOverview()
    local diag = {
        regionFound = false,
        treeClasses = 0,
        liveTrees = 0,
        filteredOut = 0,
        totalFree = 0,
        sample = {}
    }

    local region = workspace:FindFirstChild("TreeRegion")
    if region then diag.regionFound = true end

    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if not ok or not desc then
        warn("[ServerLogger][LIVE] GetDescendants FAILED")
        return {}, diag
    end

    local agg = {}

    for _, inst in ipairs(desc) do
        if inst:IsA("StringValue") and inst.Name == "TreeClass" then
            diag.treeClasses = diag.treeClasses + 1
            local tree = inst.Parent

            if isLiveTree(tree) then
                diag.liveTrees = diag.liveTrees + 1
                local class = inst.Value
                if class == nil or class == "" then
                    class = "(EMPTY)"
                end

                if #diag.sample < 10 then
                    table.insert(diag.sample, class)
                end

                local a = agg[class]
                if not a then
                    a = { class = class, total = 0, free = 0, vol = 0, biggest = nil, biggestVol = 0 }
                    agg[class] = a
                end
                a.total = a.total + 1

                if isFree(tree) then
                    a.free = a.free + 1
                    diag.totalFree = diag.totalFree + 1
                    for _, p in ipairs(tree:GetDescendants()) do
                        if p:IsA("BasePart") and string.find(p.Name, "WoodSection") then
                            local s = p.Size
                            local v2 = s.X * s.Y * s.Z
                            a.vol = a.vol + v2
                            if v2 > a.biggestVol then
                                a.biggestVol = v2
                                a.biggest = p
                            end
                        end
                    end
                end
            else
                diag.filteredOut = diag.filteredOut + 1
            end
        end
    end

    print("[ServerLogger][LIVE] TC=" .. diag.treeClasses
        .. " live=" .. diag.liveTrees
        .. " filtered=" .. diag.filteredOut
        .. " region=" .. tostring(diag.regionFound)
        .. " sample=" .. table.concat(diag.sample, ","))

    local rows = {}
    for _, a in pairs(agg) do
        a.huntOn = isClassHunted(a.class)
        table.insert(rows, a)
    end
    table.sort(rows, function(x, y)
        local xs = SPECIAL_CLASSES[x.class] and 1 or 0
        local ys = SPECIAL_CLASSES[y.class] and 1 or 0
        if xs ~= ys then return xs > ys end
        if x.total ~= y.total then return x.total > y.total end
        return x.class < y.class
    end)
    return rows, diag
end

-- =====================  RENDER  =====================
local function renderServers(category)
    activeCategory = category
    local prevScroll = ScrollingFrame.CanvasPosition.Y

    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- ============ LIVE TAB ============
    if category == "live" then
        local rows, diag = scanServerOverview()
        lastRowCount = #rows + 1

        local HeadFrame = Instance.new("Frame")
        HeadFrame.Size = UDim2.new(1, 0, 0, 46)
        HeadFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        HeadFrame.Parent = ScrollingFrame
        Instance.new("UICorner", HeadFrame).CornerRadius = UDim.new(0, 6)

        local headText = "LIVE trees: " .. diag.liveTrees
            .. " | free: " .. diag.totalFree
            .. " | ignored: " .. diag.filteredOut

        local HeadLabel = Instance.new("TextLabel")
        HeadLabel.Size = UDim2.new(0, 182, 1, 0)
        HeadLabel.Position = UDim2.new(0, 8, 0, 0)
        HeadLabel.BackgroundTransparency = 1
        HeadLabel.Text = headText
        HeadLabel.TextColor3 = (diag.liveTrees == 0) and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(180, 180, 180)
        HeadLabel.TextSize = 10
        HeadLabel.TextWrapped = true
        HeadLabel.Font = Enum.Font.Gotham
        HeadLabel.TextXAlignment = Enum.TextXAlignment.Left
        HeadLabel.Parent = HeadFrame

        local ScanBtn = Instance.new("TextButton")
        ScanBtn.Size = UDim2.new(0, 80, 0, 24)
        ScanBtn.Position = UDim2.new(0, 200, 0.5, -12)
        ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 90)
        ScanBtn.Text = "SCAN NOW"
        ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ScanBtn.TextSize = 11
        ScanBtn.Font = Enum.Font.GothamBold
        ScanBtn.Parent = HeadFrame
        Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 4)
        ScanBtn.MouseButton1Click:Connect(function()
            renderServers("live")
        end)

        for _, a in ipairs(rows) do
            local isSpecial = SPECIAL_CLASSES[a.class] and true or false

            local ItemFrame = Instance.new("Frame")
            ItemFrame.Size = UDim2.new(1, 0, 0, 46)
            if isSpecial then
                ItemFrame.BackgroundColor3 = Color3.fromRGB(70, 45, 20)
            else
                ItemFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            end
            ItemFrame.Parent = ScrollingFrame
            Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 6)

            local line1 = string.upper(a.class) .. " x" .. a.total .. " | FREE x" .. a.free .. " | " .. fmtVol(a.vol)
            local line2 = "HUNT: " .. (a.huntOn and "ON" or "OFF")
            if a.free == 0 then
                line2 = line2 .. " | all owned"
            end

            local InfoLabel = Instance.new("TextLabel")
            InfoLabel.Size = UDim2.new(0, 182, 1, 0)
            InfoLabel.Position = UDim2.new(0, 8, 0, 0)
            InfoLabel.BackgroundTransparency = 1
            InfoLabel.Text = line1 .. "\n" .. line2
            if isSpecial then
                InfoLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
            else
                InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            InfoLabel.TextSize = 10
            InfoLabel.TextWrapped = true
            InfoLabel.Font = Enum.Font.Gotham
            InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
            InfoLabel.Parent = ItemFrame

            if a.biggest and a.free > 0 then
                local TpBtn = Instance.new("TextButton")
                TpBtn.Size = UDim2.new(0, 55, 0, 24)
                TpBtn.Position = UDim2.new(0, 195, 0.5, -12)
                TpBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
                TpBtn.Text = "TP"
                TpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                TpBtn.TextSize = 11
                TpBtn.Parent = ItemFrame
                Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 4)
                local targetPart = a.biggest
                TpBtn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if targetPart and targetPart.Parent and hrp then
                        pcall(function()
                            hrp.CFrame = targetPart.CFrame * CFrame.new(0, 4, 8)
                        end)
                        setStatus("Status: TP to " .. string.upper(a.class), Color3.fromRGB(0, 255, 127))
                    end
                end)
            end
        end

        task.defer(function()
            pcall(updateCanvas)
            local maxScroll = getMaxScroll()
            local newY = prevScroll
            if newY > maxScroll then newY = maxScroll end
            if newY < 0 then newY = 0 end
            ScrollingFrame.CanvasPosition = Vector2.new(0, newY)
        end)
        return
    end

    -- ============ SAVED LOG TABS ============
    local rows = {}
    if category == "top" then
        for _, cat in ipairs({ "spook", "sinister", "other" }) do
            for _, e in ipairs(savedData[cat] or {}) do
                local row = {}
                for k, v in pairs(e) do row[k] = v end
                row._cat = cat
                table.insert(rows, row)
            end
        end
        table.sort(rows, function(a, b) return scoreOf(a) > scoreOf(b) end)
    else
        for _, e in ipairs(savedData[category] or {}) do
            local row = {}
            for k, v in pairs(e) do row[k] = v end
            table.insert(rows, row)
        end
        table.sort(rows, function(a, b) return (a.time or 0) > (b.time or 0) end)
    end

    lastRowCount = #rows

    local rendered = 0
    for rank, server in ipairs(rows) do
        if rendered >= RENDER_CAP then break end
        rendered = rendered + 1

        local ItemFrame = Instance.new("Frame")
        ItemFrame.Size = UDim2.new(1, 0, 0, 46)
        ItemFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        ItemFrame.Parent = ScrollingFrame
        Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 6)

        local prefix = ""
        if category == "top" then
            prefix = "#" .. rank .. " [" .. string.upper(server._cat or "?") .. "] "
        end
        local line1 = prefix .. string.upper(server.treeClass or "?") .. " - " .. fmtVol(server.size) .. " studs"
        local line2 = relTime(server.time) .. " | " .. tostring(server.players or "?") .. "p | " .. string.sub(tostring(server.jobId), 1, 8)

        local InfoLabel = Instance.new("TextLabel")
        InfoLabel.Size = UDim2.new(0, 182, 1, 0)
        InfoLabel.Position = UDim2.new(0, 8, 0, 0)
        InfoLabel.BackgroundTransparency = 1
        InfoLabel.Text = line1 .. "\n" .. line2
        InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        InfoLabel.TextSize = 10
        InfoLabel.TextWrapped = true
        InfoLabel.Font = Enum.Font.Gotham
        InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
        InfoLabel.Parent = ItemFrame

        local JoinBtn = Instance.new("TextButton")
        JoinBtn.Size = UDim2.new(0, 55, 0, 24)
        JoinBtn.Position = UDim2.new(0, 195, 0.5, -12)
        JoinBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
        JoinBtn.Text = "Join"
        JoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        JoinBtn.TextSize = 11
        JoinBtn.Parent = ItemFrame
        Instance.new("UICorner", JoinBtn).CornerRadius = UDim.new(0, 4)
        JoinBtn.MouseButton1Click:Connect(function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(server.placeId or game.PlaceId, server.jobId, LocalPlayer)
            end)
        end)

        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 24, 0, 24)
        DeleteBtn.Position = UDim2.new(0, 255, 0.5, -12)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
        DeleteBtn.Text = "X"
        DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DeleteBtn.TextSize = 12
        DeleteBtn.Parent = ItemFrame
        Instance.new("UICorner", DeleteBtn).CornerRadius = UDim.new(0, 4)
        DeleteBtn.MouseButton1Click:Connect(function()
            removeByJobId(server.jobId)
            renderServers(activeCategory)
        end)
    end

    if #rows > rendered then
        local MoreFrame = Instance.new("Frame")
        MoreFrame.Size = UDim2.new(1, 0, 0, 26)
        MoreFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        MoreFrame.Parent = ScrollingFrame
        Instance.new("UICorner", MoreFrame).CornerRadius = UDim.new(0, 6)
        local MoreLabel = Instance.new("TextLabel")
        MoreLabel.Size = UDim2.new(1, -10, 1, 0)
        MoreLabel.Position = UDim2.new(0, 5, 0, 0)
        MoreLabel.BackgroundTransparency = 1
        MoreLabel.Text = "...and " .. (#rows - rendered) .. " more saved (showing newest " .. rendered .. ")"
        MoreLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
        MoreLabel.TextSize = 10
        MoreLabel.Font = Enum.Font.Gotham
        MoreLabel.Parent = MoreFrame
    end

    task.defer(function()
        pcall(updateCanvas)
        local maxScroll = getMaxScroll()
        local newY = prevScroll
        if newY > maxScroll then newY = maxScroll end
        if newY < 0 then newY = 0 end
        ScrollingFrame.CanvasPosition = Vector2.new(0, newY)
    end)
end

-- =====================  TABS  =====================
local TAB_DEFS = {
    { id = "live", label = "LIVE" },
    { id = "top", label = "TOP" },
    { id = "spook", label = "SPOOK" },
    { id = "sinister", label = "SINISTER" },
    { id = "other", label = "OTHER" },
}
local tabButtons = {}

local function selectTab(id)
    activeCategory = id
    for tid, bb in pairs(tabButtons) do
        if tid == id then
            bb.BackgroundColor3 = Color3.fromRGB(0, 120, 90)
        else
            bb.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end
    renderServers(id)
end

for i, def in ipairs(TAB_DEFS) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 62, 0, 28)
    b.Position = UDim2.new(0, 10 + (i - 1) * 64, 0, 188)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.Text = def.label
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 10
    b.Font = Enum.Font.GothamSemibold
    b.Parent = MainFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        selectTab(def.id)
    end)
    tabButtons[def.id] = b
end

local AddBtn = Instance.new("TextButton")
AddBtn.Size = UDim2.new(0, 150, 0, 28)
AddBtn.Position = UDim2.new(0, 10, 0, 222)
AddBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
AddBtn.Text = "+ Manual Log"
AddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddBtn.TextSize = 11
AddBtn.Parent = MainFrame
Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 6)

AddBtn.MouseButton1Click:Connect(function()
    local cat = activeCategory
    if cat == "top" or cat == "live" then cat = "other" end
    logCurrentServer(cat)
    renderServers(activeCategory)
end)

local HopBtn = Instance.new("TextButton")
HopBtn.Size = UDim2.new(0, 150, 0, 28)
HopBtn.Position = UDim2.new(0, 170, 0, 222)
HopBtn.BackgroundColor3 = Color3.fromRGB(170, 120, 50)
HopBtn.Text = "HOP NOW"
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.TextSize = 11
HopBtn.Font = Enum.Font.GothamBold
HopBtn.Parent = MainFrame
Instance.new("UICorner", HopBtn).CornerRadius = UDim.new(0, 6)

selectTab("top")

-- auto refresh: LIVE every 5s, others 15s
task.spawn(function()
    local t = 0
    while true do
        task.wait(1)
        t = t + 1
        if activeCategory == "live" then
            if t % 5 == 0 then
                pcall(renderServers, "live")
            end
        elseif t % 15 == 0 then
            pcall(renderServers, activeCategory)
        end
    end
end)

-- =====================  TREE FINDER (v7 same minimal filter)  =====================
local WOOD_MAP = {
    huntSpook      = { "Spooky" },
    huntSinister   = { "SpookyNeon" },
    huntLoneCave   = { "CaveCrawler" },
    huntBlueSpruce = { "BlueSpruce" },
    huntVolcano    = { "Volcano", "Fire" },
    huntFrost      = { "Frost", "SnowGlow" },
    huntPalm       = { "Palm" },
    huntBirch      = { "Birch" },
    huntCherry     = { "Cherry" },
    huntKoa        = { "Koa" },
    huntOak        = { "Oak", "Generic" },
    huntPine       = { "Pine" },
    huntGold       = { "Gold", "GoldSwampy" }
}

local CATEGORY = { Spooky = "spook", SpookyNeon = "sinister" }

local function treeVolume(tree)
    local v = 0
    for _, p in ipairs(tree:GetDescendants()) do
        if p:IsA("BasePart") and string.find(p.Name, "WoodSection") then
            local s = p.Size
            v = v + s.X * s.Y * s.Z
        end
    end
    return v
end

local function findTargetTree()
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("StringValue") and inst.Name == "TreeClass" then
            local tree = inst.Parent
            if isLiveTree(tree) and isFree(tree) then
                for key, names in pairs(WOOD_MAP) do
                    if settingsData[key] then
                        for _, n in ipairs(names) do
                            if inst.Value == n then
                                return tree, inst.Value, CATEGORY[n] or "other"
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- =====================  SERVER HOPPER (5s first, 2s retries)  =====================
local function pickServer()
    local success, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/public?sortOrder=Asc&limit=100"))
    end)
    if success and res and res.data then
        local candidates = {}
        for _, s in ipairs(res.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                table.insert(candidates, s.id)
            end
        end
        if #candidates > 0 then
            return candidates[math.random(1, #candidates)]
        end
    end
    return nil
end

local function retryDelay()
    if hopAttempts <= 1 then
        return 5
    end
    return 2
end

safeTeleport = function()
    if isTeleporting then return end
    isTeleporting = true
    hopAttempts = hopAttempts + 1

    task.spawn(function()
        setStatus("Status: Hopping (attempt " .. hopAttempts .. ")...", Color3.fromRGB(255, 200, 0))

        local target = pickServer()
        if not target then
            local d = retryDelay()
            setStatus("Status: No servers found - retrying in " .. d .. "s", Color3.fromRGB(255, 100, 100))
            task.delay(d, function()
                isTeleporting = false
                safeTeleport()
            end)
            return
        end

        local teleportStarted = false
        local conn = LocalPlayer.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started then teleportStarted = true end
        end)

        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
        end)

        local watchdog = retryDelay()
        task.delay(watchdog, function()
            if conn then conn:Disconnect() end
            if not teleportStarted and game.JobId == currentJobId then
                isTeleporting = false
                setStatus("Status: Hop didn't go through - retrying...", Color3.fromRGB(255, 100, 100))
                safeTeleport()
            end
        end)
    end)
end

TeleportService.TeleportInitFailed:Connect(function(plr, reason, msg)
    if plr == LocalPlayer and isTeleporting then
        isTeleporting = false
        setStatus("Status: Teleport failed (" .. tostring(reason) .. ") - retrying...", Color3.fromRGB(255, 100, 100))
        task.wait(2)
        safeTeleport()
    end
end)

HopBtn.MouseButton1Click:Connect(function()
    safeTeleport()
end)

-- =====================  MAIN LOOP  =====================
task.spawn(function()
    while not LocalPlayer.Character do task.wait() end

    while true do
        if not settingsData.autofarmActive or settingsData.isPaused then
            if settingsData.isPaused then
                setStatus("Status: PAUSED (Shift+G)", Color3.fromRGB(180, 180, 180))
            else
                setStatus("Status: STOPPED", Color3.fromRGB(180, 180, 180))
            end
            task.wait(1)
        else
            local tree, className, category = findTargetTree()

            if not tree then
                setStatus("Status: No targets. Server hopping...", Color3.fromRGB(255, 100, 100))
                safeTeleport()
                task.wait(6)
            else
                hopAttempts = 0

                local vol = 0
                pcall(function() vol = treeVolume(tree) end)

                logCurrentServer(category, vol, className)
                renderServers(activeCategory)

                setStatus("Status: FOUND " .. string.upper(className) .. " (" .. fmtVol(vol) .. ") - logged!", Color3.fromRGB(0, 255, 127))

                task.wait(3)

                if settingsData.hopAfterFind then
                    safeTeleport()
                    task.wait(6)
                else
                    task.wait(20)
                end
            end
        end
    end
end)

print("[ServerLogger] " .. VERSION .. " loaded OK")
]==]

-- Save script source locally and queue it for teleports
if writefile then
    pcall(function() writefile(SCRIPT_FILE, currentScriptSource) end)
end

local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queueFunction then
    pcall(function()
        queueFunction('if isfile and isfile("' .. SCRIPT_FILE .. '") then if loadfile then loadfile("' .. SCRIPT_FILE .. '")() else loadstring(readfile("' .. SCRIPT_FILE .. '"))() end end')
    end)
end

if getgenv then getgenv().ServerLoggerLoaded = nil end

do
    local fn, loadErr = loadstring(currentScriptSource)
    if not fn then
        warn("[ServerLogger] Syntax error in main script: " .. tostring(loadErr))
    else
        local ok, runErr = pcall(fn)
        if not ok then
            warn("[ServerLogger] Runtime error: " .. tostring(runErr))
        end
    end
end
