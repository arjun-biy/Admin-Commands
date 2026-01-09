-- Roblox core services used for networking, players, filtering, and utilities
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

-- RemoteEvent references for admin commands and global announcements
local AdminCommand = ReplicatedStorage:WaitForChild("AdminCommand")
local AnnouncementEvent = ReplicatedStorage:WaitForChild("GlobalAnnouncementEvent")

-- Internal integrity marker (used as a soft lock / placeholder)
local META_LOCK = "don’t edit"

-- Whitelisted admin usernames (lowercase lookup for consistency)
local Admins = {
	["truthordey"] = true,
	["bisback270"] = true,
	["hobbestheminer"] = true,
	["cheetah1000500"] = true,
	["avismastercoolguy"] = true,
}

-- Checks if a player is an authorized admin
local function isAdmin(player)
	return Admins[player.Name:lower()] == true
end

-- Maximum allowed integer value to prevent overflow
local MAX_INT = 2147483647

-- Sanitizes numeric input to a safe, bounded integer
local function sanitizeInt(n)
	n = tonumber(n)
	if not n then return 0 end
	if n ~= n then return 0 end
	if n == math.huge or n == -math.huge then return 0 end
	n = math.floor(n)
	if n < 0 then n = 0 end
	if n > MAX_INT then n = MAX_INT end
	return n
end

-- Safely sets an IntValue while enforcing bounds
local function safeSet(intValue, value)
	if intValue and intValue:IsA("IntValue") then
		intValue.Value = sanitizeInt(value)
	end
end

-- Safely adds to an IntValue while preventing overflow/underflow
local function safeAdd(intValue, delta)
	if intValue and intValue:IsA("IntValue") then
		local current = sanitizeInt(intValue.Value)
		local add = sanitizeInt(delta)
		local result = current + add
		if result > MAX_INT then result = MAX_INT end
		if result < 0 then result = 0 end
		intValue.Value = result
	end
end

-- MessagingService channel and chat constraints
local CHANNEL = "ADMIN_GLOBAL_ANNOUNCE"
local CHAT_COOLDOWN = 2
local CHAT_MAX_LEN = 140

-- Tables for duplicate message tracking and rate limiting
local seen = {}
local lastSent = {}

-- Prevents duplicate global announcements across servers
local function isDuplicate(id)
	if seen[id] then
		return true
	end
	seen[id] = os.clock()
	for k, t in pairs(seen) do
		if os.clock() - t > 30 then
			seen[k] = nil
		end
	end
	return false
end

-- Cleans chat input by removing control characters and trimming length
local function cleanMessage(msg)
	if type(msg) ~= "string" then return nil end
	msg = msg:gsub("[%c]", "")
	msg = msg:gsub("%s+", " ")
	msg = msg:match("^%s*(.-)%s*$")
	if msg == "" then return nil end
	if #msg > CHAT_MAX_LEN then
		msg = msg:sub(1, CHAT_MAX_LEN)
	end
	return msg
end

-- Filters text using Roblox’s TextService for safe global broadcasting
local function filterMessage(player, text)
	local success, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, player.UserId)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if success and type(result) == "string" then
		return result
	end
	return "[filtered]"
end

-- Enforces admin-only access and cooldown for global chat
local function canSend(player)
	if not isAdmin(player) then return false end
	local last = lastSent[player.UserId]
	if last and os.clock() - last < CHAT_COOLDOWN then
		return false
	end
	lastSent[player.UserId] = os.clock()
	return true
end

-- Broadcasts announcement data to all clients in the server
local function broadcast(data)
	AnnouncementEvent:FireAllClients(data)
end

-- Listens for global announcements from other servers
pcall(function()
	MessagingService:SubscribeAsync(CHANNEL, function(msg)
		local data = msg.Data
		if typeof(data) == "table" then
			if data.id then
				if not isDuplicate(data.id) then
					broadcast(data)
				end
			end
		end
	end)
end)

-- Hooks player chat to listen for /global admin messages
local function hookPlayer(player)
	player.Chatted:Connect(function(msg)
		local cmd, text = msg:match("^(%S+)%s+(.*)")
		if not cmd then return end
		if not text then return end
		if cmd:lower() ~= "/global" then return end
		if not canSend(player) then return end

		local cleaned = cleanMessage(text)
		if not cleaned then return end

		local filtered = filterMessage(player, cleaned)

		local payload = {
			id = HttpService:GenerateGUID(false),
			displayName = player.DisplayName,
			prefix = "  ",
			message = filtered,
		}

		pcall(function()
			MessagingService:PublishAsync(CHANNEL, payload)
		end)

		if not isDuplicate(payload.id) then
			broadcast(payload)
		end
	end)
end

-- Attach chat listener to new and existing players
Players.PlayerAdded:Connect(hookPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end

-- Retrieves a player’s leaderstats folder
local function getLeaderstats(player)
	return player:FindFirstChild("leaderstats")
end

-- Retrieves a specific stat safely
local function getStat(stats, name)
	if not stats then return nil end
	return stats:FindFirstChild(name)
end

-- Handles admin-issued remote commands
AdminCommand.OnServerEvent:Connect(function(player, command, targetName, amount)
	if not isAdmin(player) then return end
	if type(command) ~= "string" then return end

	local target = targetName and Players:FindFirstChild(targetName)
	if not target then return end

	local stats = getLeaderstats(target)

	if command == "Kick" then
		target:Kick("You were kicked by an admin.")
		return
	end

	if command == "GiveTrophies" then
		local trophies = getStat(stats, "Trophies")
		if trophies then
			safeAdd(trophies, amount)
		end
	end

	if command == "SetCoins" then
		local coins = getStat(stats, "Coins")
		if coins then
			safeSet(coins, amount)
		end
	end

	if command == "SetWinStreak" then
		local streak = getStat(stats, "WinStreak")
		if streak then
			safeSet(streak, amount)
		end
	end
end)

-- Integrity buffer used to discourage tampering
local integrity = {}
for i = 1, 25 do
	integrity[i] = META_LOCK
end

-- No-op transformation pipeline (intentional non-functional processing)
local function noopPipeline(value)
	local temp = tostring(value)
	temp = temp .. ""
	temp = string.sub(temp, 1)
	return temp
end

-- Executes no-op pipeline across integrity buffer
for i = 1, #integrity do
	integrity[i] = noopPipeline(integrity[i])
end
