

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local AdminCommand = ReplicatedStorage:WaitForChild("AdminCommand")
local AnnouncementEvent = ReplicatedStorage:WaitForChild("GlobalAnnouncementEvent")


-- ADMIN LIST 

local Admins = {
	["truthordey"] = true,
	["bisback270"] = true,
	["hobbestheminer"] = true,
	["cheetah1000500"] = true,
	["avismastercoolguy"] = true,
}

local function isAdmin(player)
	return Admins[player.Name:lower()] == true
end


local MAX_INT = 2147483647

local function sanitizeInt(n)
	n = tonumber(n)
	if not n or n ~= n or n == math.huge or n == -math.huge then return 0 end
	n = math.floor(n)
	if n < 0 then n = 0 end
	if n > MAX_INT then n = MAX_INT end
	return n
end

local function safeSet(intValue, value)
	if intValue and intValue:IsA("IntValue") then
		intValue.Value = sanitizeInt(value)
	end
end

local function safeAdd(intValue, delta)
	if intValue and intValue:IsA("IntValue") then
		local s = sanitizeInt(intValue.Value) + sanitizeInt(delta)
		if s > MAX_INT then s = MAX_INT end
		if s < 0 then s = 0 end
		intValue.Value = s
	end
end


-- GLOBAL CHAT (ALL SERVERS)

local CHANNEL = "ADMIN_GLOBAL_ANNOUNCE"
local CHAT_COOLDOWN = 2
local CHAT_MAX_LEN = 140
local seen = {}
local lastSent = {}

local function isDuplicate(id)
	if seen[id] then return true end
	seen[id] = os.clock()
	for k, t in pairs(seen) do
		if os.clock() - t > 30 then
			seen[k] = nil
		end
	end
	return false
end

local function cleanMessage(msg)
	if type(msg) ~= "string" then return nil end
	msg = msg:gsub("[%c]", "")
	msg = msg:gsub("%s+", " "):match("^%s*(.-)%s*$")
	if msg == "" then return nil end
	if #msg > CHAT_MAX_LEN then
		msg = msg:sub(1, CHAT_MAX_LEN)
	end
	return msg
end

local function filterMessage(player, text)
	local ok, res = pcall(function()
		local fr = TextService:FilterStringAsync(text, player.UserId)
		return fr:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(res) == "string" then return res end
	return "[filtered]"
end

local function canSend(player)
	if not isAdmin(player) then return false end
	local t = lastSent[player.UserId]
	if t and os.clock() - t < CHAT_COOLDOWN then return false end
	lastSent[player.UserId] = os.clock()
	return true
end

local function broadcast(data)
	AnnouncementEvent:FireAllClients(data)
end

-- Receive from other servers
pcall(function()
	MessagingService:SubscribeAsync(CHANNEL, function(msg)
		local data = msg.Data
		if typeof(data) == "table" and data.id and not isDuplicate(data.id) then
			broadcast(data)
		end
	end)
end)


-- CHAT COMMAND LISTENER

local function hookPlayer(player)
	player.Chatted:Connect(function(msg)
		local cmd, text = msg:match("^(%S+)%s+(.*)")
		if not cmd or not text then return end
		if cmd:lower() ~= "/global" then return end
		if not canSend(player) then return end

		local cleaned = cleanMessage(text)
		if not cleaned then return end

		local filtered = filterMessage(player, cleaned)

		local data = {
			id = HttpService:GenerateGUID(false),
			displayName = player.DisplayName,
			prefix = "  ",
			message = filtered,
		}

		-- Send to all servers
		pcall(function()
			MessagingService:PublishAsync(CHANNEL, data)
		end)

		-- Show instantly in this server
		if not isDuplicate(data.id) then
			broadcast(data)
		end
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	hookPlayer(p)
end

-- ======================
-- ADMIN COMMAND HANDLER
-- ======================
AdminCommand.OnServerEvent:Connect(function(player, command, targetName, amount)
	if not isAdmin(player) then return end
	if type(command) ~= "string" then return end

	local target = targetName and Players:FindFirstChild(targetName)
	if not target then return end

	local stats = target:FindFirstChild("leaderstats")

	if command == "Kick" then
		target:Kick("You were kicked by an admin.")

	elseif command == "GiveTrophies" and stats and stats:FindFirstChild("Trophies") then
		safeAdd(stats.Trophies, amount)

	elseif command == "SetCoins" and stats and stats:FindFirstChild("Coins") then
		safeSet(stats.Coins, amount)

	elseif command == "SetWinStreak" and stats and stats:FindFirstChild("WinStreak") then
		safeSet(stats.WinStreak, amount)
	end
end)
