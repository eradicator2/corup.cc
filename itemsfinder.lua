local TEMPLATE = [=[
local SOURCE = __SOURCE__
local BOOT_STATE = __BOOT_STATE__

local Env = getgenv()

Env.CrimFinder = {
    webhook_url = "", -- discord webhook

    search_x24 = true,
    search_copecoin = false,
    search_corruptis = false,
    search_rpg7 = false,
    search_slayerkit = false,
    search_fallenblade = false,
    search_necromancerkit = false,
    search_bfg1 = false,
    search_frontman = false,
    search_vestb3 = false,
    search_publicairstrike = false,
    search_publicprecisionstrike = false,

    search_rebeldealer = false,
    search_mysterybox = false,
    search_relic = false,

    game_modes = {"Casual"}, -- Casual, Standart
    min_players = 3, -- 3-39
    max_players = 39, -- min_players-39
    blocked_regions = {"HK", "BR"}, -- HK, US, SG, BR, FR, DE, GB, IN, AU, JP
    
    keep_searching = true,
    ping_everyone = true, -- true: ping @everyone, false: no @everyone ping
}

local cfg = Env.CrimFinder

local Kp0 = 1500
local Kp1 = 300
local Kp2 = math.max(0, Kp0 - Kp1)
local Kp3 = 360
local Kp4 = 3600

local Kp5 = {
    search_copecoin = "_CopeCoin26",
    search_corruptis = "Corruptis",
    search_rpg7 = "RPG-7",
    search_slayerkit = "__SlayerKit",
    search_fallenblade = "_FallenBlade",
    search_necromancerkit = "__NecromancerKit",
    search_bfg1 = "BFG-1",
    search_frontman = "FrontMan",
    search_vestb3 = "VestB_3",
    search_publicairstrike = "PublicAirstrike",
    search_publicprecisionstrike = "PublicPrecisionStrike",
    search_x24 = "X24"
}

Env.CrimFinderState = Env.CrimFinderState or {
    visitedServers = {},
    serverCooldowns = {},
    joinAttemptCooldowns = {},
    serverReasons = {},
    serverModes = {},
    reportedFinds = {},
    cachedServers = nil,
    running = false,
    stopped = false,
    runnerToken = 0,
    lastJoinMode = nil,
    lastJoinServerId = nil,
    lastPickedServerId = nil,
    rngSeeded = false,
    teleportPendingUntil = 0,
    lastReturnAt = 0,
    serverEnteredAt = 0,
    serverEnteredId = nil,
    status = "idle",
    lastError = ""
}

local bag = Env.CrimFinderState

local function foldA(source)
    if type(source) ~= "table" then
        return
    end
    for key, value in pairs(source) do
        if type(value) == "table" and type(bag[key]) == "table" then
            for k, v in pairs(value) do
                bag[key][k] = v
            end
        else
            bag[key] = value
        end
    end
end

foldA(BOOT_STATE)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Events = ReplicatedStorage:WaitForChild("Events")

pcall(function()
    local b0 = TeleportService:GetTeleportSetting("CrimFinderState")
    if type(b0) ~= "table" then
        b0 = TeleportService:GetTeleportSetting("ItemsFinderState")
    end
    foldA(b0)
end)

local slotA = nil
local wireA = nil

local function rollA()
    if bag.rngSeeded then
        return
    end
    local seed = os.time()
    local jobId = tostring(game.JobId or "")
    for i = 1, #jobId do
        seed = seed + string.byte(jobId, i)
    end
    math.randomseed(seed)
    bag.rngSeeded = true
end

local function pipeA()
    return (syn and syn.request) or http_request or request or (fluxus and fluxus.request)
end

local function packA()
    return {
        visitedServers = bag.visitedServers,
        serverCooldowns = bag.serverCooldowns,
        joinAttemptCooldowns = bag.joinAttemptCooldowns,
        serverReasons = bag.serverReasons,
        serverModes = bag.serverModes,
        reportedFinds = bag.reportedFinds,
        lastJoinMode = bag.lastJoinMode,
        lastJoinServerId = bag.lastJoinServerId,
        lastPickedServerId = bag.lastPickedServerId,
        rngSeeded = bag.rngSeeded,
        stopped = bag.stopped
    }
end

local function stitchA()
    local chunk = SOURCE
    chunk = chunk:gsub("__SOURCE__", function()
        return string.format("%q", SOURCE)
    end, 1)
    chunk = chunk:gsub("__BOOT_STATE__", function()
        return "nil"
    end, 1)
    return chunk
end

local function carryA()
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport
    if not queue then
        return
    end

    local ok, b1 = pcall(stitchA)
    if not ok then
        bag.lastError = tostring(b1)
        return
    end

    pcall(function()
        TeleportService:SetTeleportSetting("CrimFinderState", packA())
    end)

    pcall(function()
        queue(b1)
    end)
end

local function normA(value)
    if type(value) ~= "string" then
        return nil
    end

    local mode = string.lower(value)
    if mode == "casual" then
        return "Casual"
    end
    if mode == "standard" or mode == "standart" then
        return "Standart"
    end
    return nil
end

local function castA(mode)
    if mode == "Standart" then
        return "Standard"
    end
    return mode
end

local function mapA()
    local map = {}
    for _, mode in ipairs(cfg.game_modes or {}) do
        local normalized = normA(mode)
        if normalized == "Casual" or normalized == "Standart" then
            map[normalized] = true
        end
    end
    return map
end

local function mapB()
    local map = {}
    for _, region in ipairs(cfg.blocked_regions or {}) do
        if type(region) == "string" then
            local up = string.upper(region)
            if up ~= "" then
                map[up] = true
            end
        end
    end
    return map
end

local function hintA(value)
    if type(value) ~= "table" then
        return false
    end
    for _, sample in pairs(value) do
        if type(sample) == "table" and sample.serverId ~= nil and sample.gameMode ~= nil then
            return true
        end
    end
    return false
end

local function shapeA(value)
    if type(value) ~= "table" then
        return {}
    end

    local items = {}
    for key, server in pairs(value) do
        if type(server) == "table" and server.serverId ~= nil then
            local order = tonumber(key)
            if not order then
                order = 10 ^ 9
            end
            items[#items + 1] = {
                order = order,
                server = server
            }
        end
    end

    table.sort(items, function(a, b)
        if a.order == b.order then
            return tostring(a.server.serverId) < tostring(b.server.serverId)
        end
        return a.order < b.order
    end)

    local normalized = {}
    for i, item in ipairs(items) do
        normalized[i] = item.server
    end
    return normalized
end

local function peelA(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if hintA(value) then
            return value
        end
    end
    return nil
end

local function hookA()
    if wireA and wireA.Connected then
        return
    end

    local w0 = Events:FindFirstChild("UpdateClient")
    if not w0 then
        return
    end

    wireA = w0.OnClientEvent:Connect(function(...)
        local list = peelA(...)
        if not list then
            return
        end

        slotA = shapeA(list)
        bag.cachedServers = slotA

        for _, server in ipairs(slotA) do
            if type(server) == "table" and server.serverId then
                local mode = normA(server.gameMode)
                if mode then
                    bag.serverModes[tostring(server.serverId)] = mode
                end
            end
        end
    end)
end

local function seenA(serverId)
    local function inList(list)
        if type(list) ~= "table" then
            return false
        end
        for _, server in ipairs(list) do
            if type(server) == "table" and tostring(server.serverId or "") == serverId then
                return true
            end
        end
        return false
    end

    return inList(slotA) or inList(bag.cachedServers)
end

local function nearA(serverId)
    if type(serverId) ~= "string" or serverId == "" then
        return false
    end

    if bag.serverModes[serverId] or seenA(serverId) then
        return true
    end

    if string.match(serverId, "^[0-9a-fA-F]+$") and #serverId <= 8 then
        return true
    end

    return false
end

local function curA()
    local values = ReplicatedStorage:FindFirstChild("Values")
    if not values then
        return nil
    end
    local serverIdValue = values:FindFirstChild("ServerId")
    if not serverIdValue then
        return nil
    end
    local serverId = tostring(serverIdValue.Value or "")
    if serverId == "" then
        return nil
    end
    if not nearA(serverId) then
        return nil
    end
    return serverId
end

local function dockA()
    local rm0 = Events:FindFirstChild("Play")
    if not rm0 then
        return false
    end
    return curA() == nil
end

local function fmtA(seconds)
    local total = math.max(0, math.floor(tonumber(seconds) or 0))
    local minutes = math.floor(total / 60)
    local sec = total % 60
    return string.format("%dm %ds", minutes, sec)
end

local function hopA(mode, serverId)
    return table.concat({
        "local remote = game:GetService(\"ReplicatedStorage\").Events.Play",
        "local arguments = {[1] = \"connect\", [2] = \"" .. tostring(castA(mode)) .. "\", [3] = \"" .. tostring(serverId) .. "\", [4] = 1}",
        "remote:InvokeServer(unpack(arguments))"
    }, "\n")
end

local function hopB(x1)
    if x1.kind == "rebel_dealer" then
        return "local c=game:GetService(\"Players\").LocalPlayer.Character local d=workspace.Map.Shopz:FindFirstChild(\"RebelDealer\") if c and d then c:PivotTo(d:GetPivot()*CFrame.new(0,0,-3)) end"
    end
    if x1.dealerIndex then
        return "local c=game:GetService(\"Players\").LocalPlayer.Character local d=workspace.Map.Shopz:GetChildren()[" .. tostring(x1.dealerIndex) .. "] if c and d then c:PivotTo(d:GetPivot()*CFrame.new(0,0,-3)) end"
    end
    if x1.dealerName then
        return "local c=game:GetService(\"Players\").LocalPlayer.Character local d=workspace.Map.Shopz:FindFirstChild(\"" .. tostring(x1.dealerName) .. "\") if c and d then c:PivotTo(d:GetPivot()*CFrame.new(0,0,-3)) end"
    end
    return nil
end

local function hopC(playerName)
    return "local c=game:GetService(\"Players\").LocalPlayer.Character local p=game:GetService(\"Players\"):FindFirstChild(\"" .. tostring(playerName) .. "\") if c and p and p.Character then c:PivotTo(p.Character:GetPivot()*CFrame.new(0,0,-3)) end"
end

local function hopD(x1)
    return "local c=game:GetService(\"Players\").LocalPlayer.Character local f=workspace:FindFirstChild(\"Map\") local mb=f and f:FindFirstChild(\"MysteryBoxes\") if c and mb then local pool={} for _,b in ipairs(mb:GetChildren()) do local p=b:FindFirstChild(\"MainPart\") if p then pool[#pool+1]=p end end if #pool>0 then local p=pool[math.random(1,#pool)] c:PivotTo(p.CFrame*CFrame.new(0,0,-3)) end end"
end

local function markA(en0)
    if type(en0) ~= "table" or #en0 == 0 then
        return nil
    end

    local targetsLiteral = HttpService:JSONEncode(en0)
    return table.concat({
        "local HttpService = game:GetService(\"HttpService\")",
        "local Players = game:GetService(\"Players\")",
        "",
        "local map = workspace:FindFirstChild(\"Map\")",
        "local shopz = map and map:FindFirstChild(\"Shopz\")",
        "if not shopz then",
        "    return",
        "end",
        "",
        "local targets = HttpService:JSONDecode(" .. string.format("%q", targetsLiteral) .. ")",
        "local guiName = \"DealerStockESP\"",
        "",
        "local function findDealer(target)",
        "    local index = tonumber(target.dealerIndex)",
        "    if index then",
        "        local list = shopz:GetChildren()",
        "        local byIndex = list[index]",
        "        if byIndex then",
        "            return byIndex",
        "        end",
        "    end",
        "    local name = tostring(target.dealerName or \"\")",
        "    if name ~= \"\" and name ~= \"Dealer\" then",
        "        local byName = shopz:FindFirstChild(name)",
        "        if byName then",
        "            return byName",
        "        end",
        "    end",
        "    return nil",
        "end",
        "",
        "local function dealerPart(dealer)",
        "    return dealer and (dealer:FindFirstChild(\"MainPart\") or dealer.PrimaryPart or dealer:FindFirstChildWhichIsA(\"BasePart\", true)) or nil",
        "end",
        "",
        "local function getAvailableItems(dealer, itemNames)",
        "    local available = {}",
        "    local e3 = dealer and dealer:FindFirstChild(\"CurrentStocks\")",
        "    if not e3 then",
        "        return available",
        "    end",
        "    for _, itemName in ipairs(itemNames) do",
        "        local valueObject = e3:FindFirstChild(itemName)",
        "        if valueObject and tonumber(valueObject.Value) == 1 then",
        "            available[#available + 1] = itemName",
        "        end",
        "    end",
        "    return available",
        "end",
        "",
        "local function removeGui(part)",
        "    if not part then",
        "        return",
        "    end",
        "    local gui = part:FindFirstChild(guiName)",
        "    if gui then",
        "        gui:Destroy()",
        "    end",
        "end",
        "",
        "local function updateGui(part, title, text)",
        "    if not part then",
        "        return",
        "    end",
        "    local gui = part:FindFirstChild(guiName)",
        "    if not gui then",
        "        gui = Instance.new(\"BillboardGui\")",
        "        gui.Name = guiName",
        "        gui.AlwaysOnTop = true",
        "        gui.Size = UDim2.new(0, 260, 0, 24)",
        "        gui.StudsOffset = Vector3.new(0, 2.6, 0)",
        "        gui.Adornee = part",
        "",
        "        local textLabel = Instance.new(\"TextLabel\")",
        "        textLabel.Name = \"Label\"",
        "        textLabel.BackgroundTransparency = 1",
        "        textLabel.Size = UDim2.fromScale(1, 1)",
        "        textLabel.Font = Enum.Font.SourceSansSemibold",
        "        textLabel.TextSize = 13",
        "        textLabel.TextColor3 = Color3.fromRGB(255, 235, 150)",
        "        textLabel.TextStrokeTransparency = 0.55",
        "        textLabel.TextWrapped = false",
        "        textLabel.Parent = gui",
        "",
        "        gui.Parent = part",
        "    end",
        "",
        "    local label = gui:FindFirstChild(\"Label\")",
        "    if label then",
        "        label.Text = title .. \" | \" .. text",
        "    end",
        "end",
        "",
        "task.spawn(function()",
        "    while true do",
        "        if not Players.LocalPlayer then",
        "            task.wait(1)",
        "        else",
        "            for _, target in ipairs(targets) do",
        "                local dealer = findDealer(target)",
        "                local part = dealerPart(dealer)",
        "                local availableItems = getAvailableItems(dealer, target.items or {})",
        "                if #availableItems > 0 then",
        "                    updateGui(part, tostring(target.dealerName or dealer and dealer.Name or \"Dealer\"), table.concat(availableItems, \", \"))",
        "                else",
        "                    removeGui(part)",
        "                end",
        "            end",
        "            task.wait(1)",
        "        end",
        "    end",
        "end)"
    }, "\n")
end

local function stampA(sn0)
    local value = math.max(0, math.floor(tonumber(sn0) or 0))
    local ts = os.time() + value
    return "<t:" .. tostring(ts) .. ":R>"
end

local function wrapA(x0, serverId, mode, f0)
    local l9 = {}
    if f0 then
        l9[#l9 + 1] = "@everyone"
    end
    l9[#l9 + 1] = "Server: " .. tostring(serverId)
    l9[#l9 + 1] = "Mode: " .. tostring(mode)
    l9[#l9 + 1] = "Found: " .. tostring(#x0)

    local j0 = hopA(mode, serverId)
    local l0 = {}
    local l1 = {}
    local l2 = {}
    local l3 = {}
    local p0 = {}
    local p1 = {}
    local p2 = false
    local p3 = {}

    local function push0(key, label, script)
        if not script or script == "" or p1[key] then
            return
        end
        p1[key] = true
        p0[#p0 + 1] = {
            label = label,
            script = script
        }
    end

    for _, x1 in ipairs(x0) do
        if x1.kind == "dealer_item" then
            local restockSeconds = math.max(0, math.floor(tonumber(x1.restockSeconds) or 0))
            l2[#l2 + 1] = tostring(x1.itemName) .. " | " .. tostring(x1.dealerName) .. " | " .. stampA(restockSeconds)

            local d0 = tostring(x1.dealerIndex or 0) .. "|" .. tostring(x1.dealerName or "Dealer")
            if not p3[d0] then
                p3[d0] = {
                    dealerIndex = x1.dealerIndex,
                    dealerName = x1.dealerName,
                    itemSet = {},
                    items = {}
                }
            end
            if not p3[d0].itemSet[x1.itemName] then
                p3[d0].itemSet[x1.itemName] = true
                p3[d0].items[#p3[d0].items + 1] = x1.itemName
            end
        elseif x1.kind == "rebel_dealer" then
            local despawnSeconds = math.max(0, math.floor(tonumber(x1.despawnSeconds) or 0))
            l0[#l0 + 1] = tostring(x1.dealerName) .. " | despawn " .. stampA(despawnSeconds)
            local tp = hopB(x1)
            local key = "rebel:" .. tostring(x1.dealerIndex or x1.dealerName or "")
            push0(key, "RebelDealer: " .. tostring(x1.dealerName), tp)
        elseif x1.kind == "mystery_box" then
            l1[#l1 + 1] = tostring(x1.boxName)
            if not p2 then
                p2 = true
                local tp = hopD(x1)
                push0("mystery:random", "MysteryBox: random active box", tp)
            end
        elseif x1.kind == "relic" then
            l3[#l3 + 1] = "Relic | " .. tostring(x1.playerName) .. " | " .. tostring(x1.location)
            local tp = hopC(x1.playerName)
            local key = "relic:" .. tostring(x1.playerName or "")
            push0(key, "Player Relic: " .. tostring(x1.playerName), tp)
        end
    end

    local d1 = {}
    for _, entry in pairs(p3) do
        if #entry.items > 0 then
            table.sort(entry.items)
            d1[#d1 + 1] = {
                dealerIndex = entry.dealerIndex,
                dealerName = entry.dealerName,
                items = entry.items
            }
        end
    end
    table.sort(d1, function(a, b)
        return (tonumber(a.dealerIndex) or 0) < (tonumber(b.dealerIndex) or 0)
    end)

    local d2 = markA(d1)
    if d2 and #l2 > 0 then
        l2[#l2 + 1] = "ESP script uploaded as file: dealer_esp.lua"
    end

    local function push1(title, values)
        if #values == 0 then
            return
        end
        l9[#l9 + 1] = ""
        l9[#l9 + 1] = title .. ":"
        for _, v in ipairs(values) do
            l9[#l9 + 1] = "- " .. tostring(v)
        end
    end

    push1("Rebel Dealer", l0)
    push1("Mystery Box", l1)
    push1("Dealer Items", l2)
    push1("Player Items", l3)

    l9[#l9 + 1] = ""
    l9[#l9 + 1] = "Join script:"
    l9[#l9 + 1] = "```lua"
    l9[#l9 + 1] = j0
    l9[#l9 + 1] = "```"

    if #p0 > 0 then
        l9[#l9 + 1] = ""
        l9[#l9 + 1] = "TP scripts:"
        for _, entry in ipairs(p0) do
            l9[#l9 + 1] = "- " .. tostring(entry.label)
            l9[#l9 + 1] = "```lua"
            l9[#l9 + 1] = entry.script
            l9[#l9 + 1] = "```"
        end
    end

    return table.concat(l9, "\n"), d2
end

local function postA(x0, serverId, mode)
    local u0 = tostring(cfg.webhook_url or "")
    if u0 == "" then
        return
    end

    if type(x0) ~= "table" or #x0 == 0 then
        return
    end

    local r0 = pipeA()
    if not r0 then
        return
    end

    local f1 = cfg.ping_everyone == true
    local ct0, d2 = wrapA(x0, serverId, mode, f1)
    local pl0 = {
        content = ct0,
        allowed_mentions = {
            parse = f1 and {"everyone"} or {}
        }
    }

    if d2 and d2 ~= "" then
        local bd0 = "----------------CrimFinder" .. tostring(os.time()) .. tostring(math.random(1000, 9999))
        local j1 = HttpService:JSONEncode(pl0)
        local body = table.concat({
            "--" .. bd0,
            "Content-Disposition: form-data; name=\"payload_json\"",
            "",
            j1,
            "--" .. bd0,
            "Content-Disposition: form-data; name=\"files[0]\"; filename=\"dealer_esp.lua\"",
            "Content-Type: text/plain",
            "",
            d2,
            "--" .. bd0 .. "--",
            ""
        }, "\r\n")

        pcall(function()
            r0({
                Url = u0,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "multipart/form-data; boundary=" .. bd0
                },
                Body = body
            })
        end)
    else
        pcall(function()
            r0({
                Url = u0,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(pl0)
            })
        end)
    end
end
local function takeA()
    local list = {}
    for c0, itemName in pairs(Kp5) do
        if cfg[c0] then
            list[#list + 1] = itemName
        end
    end
    table.sort(list)
    return list
end

local function sumA()
    local count = 0
    for c0 in pairs(Kp5) do
        if cfg[c0] then
            count = count + 1
        end
    end
    if cfg.search_rebeldealer then
        count = count + 1
    end
    if cfg.search_mysterybox then
        count = count + 1
    end
    if cfg.search_relic then
        count = count + 1
    end
    return count
end

local function soloA()
    return cfg.search_rebeldealer and sumA() == 1
end

local function soloB()
    return cfg.search_relic and sumA() == 1
end

local function redA(dealer)
    if not dealer then
        return false
    end
    if dealer.Name == "RebelDealer" then
        return true
    end
    local name = string.lower(dealer.Name)
    if string.find(name, "rebel", 1, true) then
        return true
    end
    return false
end

local function tickA()
    local ok, value = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if ok and type(value) == "number" then
        return value
    end
    return os.time()
end

local function leftA(dealer)
    if not dealer then
        return Kp1
    end

    local attrKeys = {
        "DespawnTime", "DeleteIn", "TimeLeft", "TimeToDelete",
        "DestroyIn", "LifetimeLeft", "RemainingTime"
    }
    for _, key in ipairs(attrKeys) do
        local value = dealer:GetAttribute(key)
        if type(value) == "number" then
            return math.max(0, math.floor(value))
        end
    end

    local valueKeys = {
        "DespawnTime", "DeleteIn", "TimeLeft", "TimeToDelete",
        "DestroyIn", "LifetimeLeft", "RemainingTime"
    }
    for _, key in ipairs(valueKeys) do
        local child = dealer:FindFirstChild(key)
        if child and child:IsA("ValueBase") then
            local n = tonumber(child.Value)
            if n then
                return math.max(0, math.floor(n))
            end
        end
    end

    local spawnTick = dealer:GetAttribute("SpawnTick")
        or dealer:GetAttribute("SpawnTime")
        or dealer:GetAttribute("SpawnedAt")
        or dealer:GetAttribute("tick")
    if type(spawnTick) == "number" then
        local elapsed = math.max(0, tickA() - spawnTick)
        local left = Kp1 - elapsed
        return math.max(0, math.floor(left))
    end

    return Kp1
end

local function scanA()
    local map = workspace:FindFirstChild("Map")
    if not map then
        return {}
    end
    local shopz = map:FindFirstChild("Shopz")
    if not shopz then
        return {}
    end

    local e0 = takeA()
    local finds = {}
    local e1 = shopz:GetChildren()
    for index, dealer in ipairs(e1) do
        local e2 = dealer:FindFirstChild("RestockTime")
        local restockSeconds = e2 and tonumber(e2.Value) or 0

        if cfg.search_rebeldealer and redA(dealer) then
            finds[#finds + 1] = {
                kind = "rebel_dealer",
                itemName = "RebelDealer",
                dealerName = dealer.Name,
                dealerIndex = index,
                restockSeconds = restockSeconds,
                despawnSeconds = leftA(dealer)
            }
        end

        local e3 = dealer:FindFirstChild("CurrentStocks")
        if e3 then
            for _, itemName in ipairs(e0) do
                local item = e3:FindFirstChild(itemName)
                if item and tonumber(item.Value) == 1 then
                    finds[#finds + 1] = {
                        kind = "dealer_item",
                        itemName = itemName,
                        dealerName = dealer.Name,
                        dealerIndex = index,
                        restockSeconds = restockSeconds
                    }
                end
            end
        end
    end

    return finds
end

local function scanB()
    if not cfg.search_relic then
        return {}
    end

    local finds = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local backpack = plr:FindFirstChild("Backpack")
        local character = plr.Character
        local inBackpack = backpack and backpack:FindFirstChild("Relic")
        local inCharacter = character and character:FindFirstChild("Relic")

        if inBackpack then
            finds[#finds + 1] = {
                kind = "relic",
                itemName = "Relic",
                playerName = plr.Name,
                location = "Backpack",
                restockSeconds = 0
            }
        end
        if inCharacter then
            finds[#finds + 1] = {
                kind = "relic",
                itemName = "Relic",
                playerName = plr.Name,
                location = "Character",
                restockSeconds = 0
            }
        end
    end

    return finds
end

local function scanC()
    if not cfg.search_mysterybox then
        return {}
    end

    local map = workspace:FindFirstChild("Map")
    if not map then
        return {}
    end

    local e4 = map:FindFirstChild("MysteryBoxes")
    if not e4 then
        return {}
    end

    local finds = {}
    for index, box in ipairs(e4:GetChildren()) do
        local e5 = box:FindFirstChild("MainPart")
        if e5 and e5:IsA("BasePart") then
            finds[#finds + 1] = {
                kind = "mystery_box",
                itemName = "MysteryBox",
                boxName = box.Name,
                boxIndex = index,
                restockSeconds = Kp4
            }
        end
    end

    return finds
end

local function scanD()
    local all = {}

    local dealerFinds = scanA()
    for _, item in ipairs(dealerFinds) do
        all[#all + 1] = item
    end

    local relicFinds = scanB()
    for _, item in ipairs(relicFinds) do
        all[#all + 1] = item
    end

    local mysteryFinds = scanC()
    for _, item in ipairs(mysteryFinds) do
        all[#all + 1] = item
    end

    return all
end

local function keyA(serverId, x1)
    if x1.kind == "dealer_item" then
        return table.concat({
            tostring(serverId),
            tostring(x1.kind),
            tostring(x1.itemName),
            tostring(x1.dealerName),
            tostring(x1.dealerIndex)
        }, ":")
    end

    if x1.kind == "rebel_dealer" then
        return tostring(serverId) .. ":rebel_dealer"
    end

    if x1.kind == "mystery_box" then
        return table.concat({
            tostring(serverId),
            "mystery_box",
            tostring(x1.boxName or ""),
            tostring(x1.boxIndex or "")
        }, ":")
    end

    if x1.kind == "relic" then
        return tostring(serverId) .. ":relic"
    end

    return tostring(serverId) .. ":unknown"
end

local function backA()
    if dockA() then
        return
    end

    local remote = Events:FindFirstChild("RCTNMEUN")
    if not remote then
        return
    end

    carryA()
    pcall(function()
        remote:InvokeServer()
    end)
end
local function sweepA()
    local now = os.time()
    for serverId, expireAt in pairs(bag.serverCooldowns) do
        if type(expireAt) == "number" and now >= expireAt then
            bag.serverCooldowns[serverId] = nil
            bag.visitedServers[serverId] = nil
            bag.serverReasons[serverId] = nil
        end
    end
    for serverId, expireAt in pairs(bag.joinAttemptCooldowns) do
        if type(expireAt) ~= "number" or now >= expireAt then
            bag.joinAttemptCooldowns[serverId] = nil
        end
    end

end

local function rollB()
    rollA()

    local servers = slotA
    if type(servers) ~= "table" then
        servers = bag.cachedServers
    end
    if type(servers) ~= "table" then
        return nil, nil
    end

    sweepA()

    local m0 = mapA()
    local m1 = mapB()
    local n0 = math.max(3, tonumber(cfg.min_players) or 3)
    local n1 = tonumber(cfg.max_players) or 39
    if n1 < n0 then
        n1 = n0
    end
    if n1 > 39 then
        n1 = 39
    end

    local q0 = {}
    for _, server in ipairs(servers) do
        if type(server) == "table" and server.serverId then
            local serverId = tostring(server.serverId)
            local mode = normA(server.gameMode)
            local players = tonumber(server.players) or 0
            local region = type(server.region) == "string" and string.upper(server.region) or ""
            if mode
                and m0[mode]
                and not m1[region]
                and players >= n0
                and players <= n1
                and not bag.visitedServers[serverId]
                and not bag.serverCooldowns[serverId]
                and not bag.joinAttemptCooldowns[serverId] then
                q0[#q0 + 1] = {server = server, mode = mode, serverId = serverId}
            end
        end
    end

    if #q0 == 0 then
        return nil, nil
    end

    if #q0 > 1 and bag.lastPickedServerId then
        local q1 = {}
        for _, item in ipairs(q0) do
            if item.serverId ~= bag.lastPickedServerId then
                q1[#q1 + 1] = item
            end
        end
        if #q1 > 0 then
            q0 = q1
        end
    end

    local q2 = q0[math.random(1, #q0)]
    bag.lastPickedServerId = q2.serverId
    return q2.server, q2.mode
end

local function coolA(x0)
    local q0 = {}
    local a0 = false
    local a1 = nil
    local a2 = false
    local a3 = nil
    local a4 = false
    local a5 = false

    for _, found in ipairs(x0) do
        if found.kind == "dealer_item" then
            a0 = true
            local restockSeconds = math.max(0, math.floor(tonumber(found.restockSeconds) or 0))
            if restockSeconds > 0 and (not a1 or restockSeconds < a1) then
                a1 = restockSeconds
            end
        elseif found.kind == "rebel_dealer" then
            a2 = true
            local despawnSeconds = math.max(0, math.floor(tonumber(found.despawnSeconds) or Kp1))
            local a6 = despawnSeconds + Kp2
            if not a3 or a6 > a3 then
                a3 = a6
            end
        elseif found.kind == "mystery_box" then
            a4 = true
        elseif found.kind == "relic" then
            a5 = true
        end
    end

    if a0 then
        q0[#q0 + 1] = a1 or 180
    end

    if a2 and a3 then
        q0[#q0 + 1] = a3
    end

    if a4 then
        q0[#q0 + 1] = Kp4
    end

    if a5 then
        if soloB() then
            q0[#q0 + 1] = Kp3
        else
            q0[#q0 + 1] = 180
        end
    end

    if soloA() and a2 and a3 then
        return a3
    end

    if #q0 == 0 then
        return 180
    end

    local best = q0[1]
    for i = 2, #q0 do
        if q0[i] < best then
            best = q0[i]
        end
    end
    return best
end

local function loopA(token)
    bag.status = "running"
    bag.lastError = ""
    bag.running = true
    if cfg.keep_searching then
        bag.stopped = false
    end
    if bag.stopped then
        bag.running = false
        bag.status = "stopped"
        return
    end

    hookA()

    while token == bag.runnerToken and not bag.stopped do
        hookA()
        sweepA()

        if dockA() then
            bag.status = "menu"
            bag.serverEnteredId = nil
            bag.serverEnteredAt = 0
            if os.clock() < (tonumber(bag.teleportPendingUntil) or 0) then
                task.wait(0.5)
            else
                local rm0 = Events:FindFirstChild("Play")
                if rm0 then
                    local server, mode = rollB()
                    if server and mode then
                        bag.status = "joining"
                        local serverId = tostring(server.serverId)
                        bag.lastJoinMode = mode
                        bag.lastJoinServerId = serverId
                        bag.serverModes[serverId] = mode

                        carryA()
                        bag.teleportPendingUntil = os.clock() + 8
                        bag.joinAttemptCooldowns[serverId] = os.time() + 20
                        pcall(function()
                            rm0:InvokeServer("connect", castA(mode), serverId, 1)
                        end)
                        task.wait(2)
                    else
                        bag.status = "menu_wait_servers"
                        task.wait(1)
                    end
                else
                    task.wait(1)
                end
            end
        else
            bag.status = "in_server"
            bag.teleportPendingUntil = 0
            local sid0 = curA() or tostring(bag.lastJoinServerId or "")
            if sid0 == "" then
                sid0 = "UNKNOWN_" .. tostring(game.JobId)
            end
            bag.visitedServers[sid0] = true
            bag.joinAttemptCooldowns[sid0] = nil
            if bag.serverEnteredId ~= sid0 then
                bag.serverEnteredId = sid0
                bag.serverEnteredAt = os.clock()
            end

            local x0 = scanD()
            if #x0 > 0 then
                bag.status = "found"
                local mode = bag.serverModes[sid0] or bag.lastJoinMode or "Casual"
                local sentCount = 0
                local x2 = {}

                for _, found in ipairs(x0) do
                    local rk0 = keyA(sid0, found)
                    if not bag.reportedFinds[rk0] then
                        bag.reportedFinds[rk0] = true
                        x2[#x2 + 1] = found
                        sentCount = sentCount + 1
                    end
                end

                if #x2 > 0 then
                    postA(x2, sid0, mode)
                end

                local cooldown = coolA(x0)
                bag.serverCooldowns[sid0] = os.time() + cooldown
                bag.serverReasons[sid0] = "FOUND_COOLDOWN_" .. tostring(cooldown)

                if cfg.keep_searching then
                    if os.clock() - bag.lastReturnAt >= 5 then
                        bag.lastReturnAt = os.clock()
                        bag.teleportPendingUntil = os.clock() + 8
                        backA()
                    end
                else
                    bag.stopped = true
                    bag.status = "stopped"
                end
            else
                bag.status = "not_found"
                local cd0 = 180
                bag.serverCooldowns[sid0] = os.time() + cd0
                bag.serverReasons[sid0] = "NOT_FOUND_COOLDOWN_" .. tostring(cd0)
                if os.clock() - bag.lastReturnAt >= 5 then
                    bag.lastReturnAt = os.clock()
                    bag.teleportPendingUntil = os.clock() + 8
                    backA()
                end
            end

            task.wait(1)
        end
    end

    bag.running = false
    if bag.status ~= "error" and bag.status ~= "stopped" then
        bag.status = "idle"
    end
end

local function kickA()
    bag.runnerToken = (tonumber(bag.runnerToken) or 0) + 1
    local token = bag.runnerToken
    task.spawn(function()
        local ok, err = pcall(loopA, token)
        if not ok then
            bag.lastError = tostring(err)
            bag.status = "error"
            bag.running = false
        end
    end)
end

Env.__CrimFinderRun = kickA
Env.__ItemsFinderRun = kickA
kickA()
]=]

local chunk = TEMPLATE
chunk = chunk:gsub("__SOURCE__", function()
    return string.format("%q", TEMPLATE)
end, 1)
chunk = chunk:gsub("__BOOT_STATE__", function()
    return "nil"
end, 1)

local fn = loadstring(chunk)
if fn then
    fn()
end
