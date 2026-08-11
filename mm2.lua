local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local EXEC = {
	name       = "Unknown",
	hasConns   = typeof(getconnections) == "function",
	hasFireSig = typeof(firesignal)     == "function",
	hasDrawing = false,
	hasFiles   = false,
	request    = nil,
	vim        = nil,
	touch  = UserInputService.TouchEnabled,
	keys   = UserInputService.KeyboardEnabled,
	mobile = false,
	aimHold  = false,
	autoAim  = false,
	releases = {},
}
EXEC.mobile = EXEC.touch and not EXEC.keys
pcall(function() if identifyexecutor then EXEC.name = tostring(identifyexecutor()) end end)
pcall(function() if EXEC.name == "Unknown" and getexecutorname then EXEC.name = tostring(getexecutorname()) end end)
pcall(function() if EXEC.name == "Unknown" and EXEC.env and EXEC.env.executor_name then EXEC.name = tostring(EXEC.env.executor_name) end end)
pcall(function() EXEC.vim = game:GetService("VirtualInputManager") end)
pcall(function()
	if Drawing and typeof(Drawing.new) == "function" then
		local probe = Drawing.new("Line")
		probe.Visible = false
		probe:Remove()
		EXEC.hasDrawing = true
	end
end)
EXEC.hasFiles = (typeof(writefile) == "function" or typeof(write_file) == "function")
	and (typeof(readfile) == "function" or typeof(read_file) == "function")
	and (typeof(isfile)   == "function" or typeof(is_file) == "function")
local safeWriteFile = writefile or write_file
local safeReadFile = readfile or read_file
local safeIsFile = isfile or is_file
EXEC.request = (typeof(request) == "function" and request)
	or (typeof(http_request) == "function" and http_request)
	or (syn and typeof(syn.request) == "function" and syn.request)
	or (http and typeof(http.request) == "function" and http.request)
	or (fluxus and typeof(fluxus.request) == "function" and fluxus.request)
	or (Volt and typeof(Volt.request) == "function" and Volt.request)
	or (Delta and typeof(Delta.request) == "function" and Delta.request)
	or nil
local function parentGui(gui)
	local ok = false
	pcall(function()
		if gethui then
			gui.Parent = gethui()
			ok = gui.Parent ~= nil
		end
	end)
	if not ok then
		pcall(function()
			if syn and syn.protect_gui then
				syn.protect_gui(gui)
				gui.Parent = CoreGui
				ok = gui.Parent ~= nil
			end
		end)
	end
	if not ok then
		pcall(function()
			if protectgui then
				protectgui(gui)
				gui.Parent = CoreGui
				ok = gui.Parent ~= nil
			end
		end)
	end
	if not ok then pcall(function() gui.Parent = CoreGui ok = gui.Parent ~= nil end) end
	if not ok then pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) ok = gui.Parent ~= nil end) end
	return gui
end
function EXEC.onHold(btn, onDown, onUp)
	local held = nil
	local function stop()
		if not held then return end
		held = nil
		onUp()
	end
	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end
	btn.InputBegan:Connect(function(input)
		if not isPress(input) or held then return end
		held = input
		onDown()
	end)
	btn.InputEnded:Connect(function(input) if input == held then stop() end end)
	table.insert(EXEC.releases, function(input)
		if input == held then stop() end
	end)
	return stop
end
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
	for _, stop in ipairs(EXEC.releases) do pcall(stop, input) end
end)
local ALIVE = true
do
	local env = (getgenv and getgenv()) or _G
	pcall(function()
		if env.MM2_UNDETECTED and env.MM2_UNDETECTED.unload then env.MM2_UNDETECTED.unload() end
	end)
	env.MM2_UNDETECTED = {unload = function() ALIVE = false end}
	EXEC.env = env
end
local UNLOCKED = true
local ESP_ENABLED        = false
local UI_VISIBLE         = true
local SPECTATING         = false
local AIMBOT_ENABLED     = true
local SETTINGS_OPEN      = false
local NOCLIP_ENABLED     = false
local AUTOFARM_ENABLED   = false
local KILLALL_RUNNING    = false

local MURDERER_COLOR = Color3.fromRGB(255, 59, 48)
local SHERIFF_COLOR  = Color3.fromRGB(10, 132, 255)
local INNOCENT_COLOR = Color3.fromRGB(200, 200, 205)
local WalkSpeed = 16
local MinSpeed, MaxSpeed, SpeedStep = 16, 200, 1
local speedValueLabel, bigSpeedLabel, speedSliderRefresh = nil, nil, nil
local function setWalkSpeed(speed)
	if not UNLOCKED then return end
	WalkSpeed = math.clamp(speed, MinSpeed, MaxSpeed)
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = WalkSpeed end
	end
	if speedValueLabel then speedValueLabel.Text = tostring(WalkSpeed) end
	if bigSpeedLabel then bigSpeedLabel.Text = tostring(WalkSpeed) end
	if speedSliderRefresh then speedSliderRefresh() end
end
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.4)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum and UNLOCKED then hum.WalkSpeed = WalkSpeed end
	if SPECTATING then
		SPECTATING = false
		Camera.CameraSubject = hum
	end
end)
RunService.Heartbeat:Connect(function()
	if not ALIVE or not UNLOCKED then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.WalkSpeed ~= WalkSpeed then hum.WalkSpeed = WalkSpeed end
end)
local cachedMurderer, cachedSheriff, lastRoleUpdate = nil, nil, 0
local function hasTool(container, keywords)
	if not container then return false end
	for _, item in ipairs(container:GetChildren()) do
		if item:IsA("Tool") then
			local name = item.Name:lower()
			for _, key in ipairs(keywords) do if name:find(key) then return true end end
		end
	end
	return false
end
local function updateRoles()
	cachedMurderer, cachedSheriff = nil, nil
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char, bp = player.Character, player:FindFirstChild("Backpack")
			if hasTool(char,{"knife","sword","blade"}) or hasTool(bp,{"knife","sword","blade"}) then cachedMurderer = player end
			if hasTool(char,{"gun","revolver","pistol"}) or hasTool(bp,{"gun","revolver","pistol"}) then cachedSheriff = player end
		end
	end
end
RunService.Heartbeat:Connect(function()
	if not ALIVE then return end
	if tick() - lastRoleUpdate >= 0.45 then lastRoleUpdate = tick() updateRoles() end
end)
local function getMurderer() return cachedMurderer end
local function getSheriff()  return cachedSheriff  end
local function getMyTool()
	local char = LocalPlayer.Character
	if not char then return nil end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local name = item.Name:lower()
			if name:find("knife") or name:find("sword") or name:find("blade") then return "Knife"
			elseif name:find("gun") or name:find("revolver") or name:find("pistol") then return "Gun" end
		end
	end
	return nil
end
local function amIMurderer() return getMyTool() == "Knife" end
local function getTargetPart(player)
	if not player or not player.Character then return nil end
	local char = player.Character
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
end
local function smoothAimAt(target)
	local part = getTargetPart(target)
	if not part then return end
	Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, part.Position), 0.65)
end
local function silentAimAt(target)
	local part = getTargetPart(target)
	if not part then return end
	Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, part.Position)
end
local function aimRequested()
	if EXEC.autoAim or EXEC.aimHold then return true end
	return EXEC.keys and UserInputService:IsKeyDown(Enum.KeyCode.R)
end
RunService.RenderStepped:Connect(function()
	if not ALIVE or not UNLOCKED or SPECTATING then return end
	if not AIMBOT_ENABLED or not aimRequested() then return end
	local toolType = getMyTool()
	if not toolType then return end
	local target = toolType == "Gun" and getMurderer() or (toolType == "Knife" and getSheriff() or nil)
	if not target then return end
	smoothAimAt(target)
end)
local flinging, flingConnection = false, nil
local function startFling()
	if not UNLOCKED or flinging then return end
	local target = amIMurderer() and getSheriff() or getMurderer()
	if not target or not target.Character then return end
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	flinging = true
	for _, part in ipairs(myChar:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false part.Massless = true end
	end
	flingConnection = RunService.Heartbeat:Connect(function()
		if not flinging then return end
		target = amIMurderer() and getSheriff() or getMurderer()
		if not target or not target.Character then return end
		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
		myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not targetRoot or not myRoot then return end
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(math.random(-1.3,1.3), math.random(0,1.6), math.random(-1.3,1.3))
		myRoot.AssemblyAngularVelocity = Vector3.new(16000+math.random(-3000,3000),16000+math.random(-3000,3000),16000+math.random(-3000,3000))
		myRoot.AssemblyLinearVelocity  = Vector3.new(math.random(-180,180),math.random(40,280),math.random(-180,180))
	end)
end
local function stopFling()
	if not flinging then return end
	flinging = false
	if flingConnection then flingConnection:Disconnect() flingConnection = nil end
	local myChar = LocalPlayer.Character
	if myChar then
		for _, part in ipairs(myChar:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = true part.Massless = false end
		end
		local myRoot = myChar:FindFirstChild("HumanoidRootPart")
		if myRoot then myRoot.AssemblyAngularVelocity = Vector3.zero myRoot.AssemblyLinearVelocity = Vector3.zero end
	end
end
local function toggleSpectate()
	if not UNLOCKED then return end
	local target = amIMurderer() and getSheriff() or getMurderer()
	if SPECTATING then
		SPECTATING = false
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then Camera.CameraSubject = hum end
	else
		if target and target.Character then
			local hum = target.Character:FindFirstChildOfClass("Humanoid")
			if hum then SPECTATING = true Camera.CameraSubject = hum end
		end
	end
end
local noclipParts, noclipChar = {}, nil
local function rebuildNoclipParts(char)
	table.clear(noclipParts)
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then table.insert(noclipParts, part) end
	end
end
local function bindNoclipChar(char)
	noclipChar = char
	rebuildNoclipParts(char)
	if not char then return end
	char.DescendantAdded:Connect(function(d)
		if noclipChar == char and d:IsA("BasePart") then table.insert(noclipParts, d) end
	end)
	char.DescendantRemoving:Connect(function(d)
		if noclipChar ~= char or not d:IsA("BasePart") then return end
		for i, p in ipairs(noclipParts) do
			if p == d then table.remove(noclipParts, i) break end
		end
	end)
end
bindNoclipChar(LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(function(char)
	if ALIVE then bindNoclipChar(char) end
end)
RunService.Stepped:Connect(function()
	if not ALIVE or not UNLOCKED or not NOCLIP_ENABLED then return end
	local char = LocalPlayer.Character
	if not char then return end
	if char ~= noclipChar then bindNoclipChar(char) end
	for _, part in ipairs(noclipParts) do
		if part.CanCollide then part.CanCollide = false end
	end
end)
local farmThread   = nil
local touchedCoins = {}
local coinConns    = {}
local farmFlyConn  = nil
local farmOrigGrav = nil
local cachedMap = nil
local function getMap()
	if cachedMap and cachedMap.Parent and cachedMap:FindFirstChild("Spawns") then
		return cachedMap
	end
	cachedMap = nil
	for _, model in ipairs(workspace:GetChildren()) do
		if model.Name ~= "Lobby" and model:FindFirstChild("Spawns") then
			cachedMap = model
			return cachedMap
		end
	end
	for _, v in ipairs(workspace:GetDescendants()) do
		if v.Name == "Spawns" and v.Parent and v.Parent.Name ~= "Lobby" then
			cachedMap = v.Parent
			return cachedMap
		end
	end
	return nil
end
local function markCollected(coin)
	touchedCoins[coin] = true
	if coinConns[coin] then
		pcall(function() coinConns[coin]:Disconnect() end)
		coinConns[coin] = nil
	end
end
local function buildCoinList(coinContainer)
	local list = {}
	for _, desc in ipairs(coinContainer:GetDescendants()) do
		if (desc:IsA("BasePart") or desc:IsA("MeshPart")) and not touchedCoins[desc] then
			if desc:FindFirstChildWhichIsA("TouchTransmitter") then
				table.insert(list, desc)
				local conn
				conn = desc.ChildRemoved:Connect(function(child)
					if child:IsA("TouchTransmitter") then markCollected(desc) end
				end)
				coinConns[desc] = conn
			end
		end
	end
	return list
end
local function getNearestCoin(list, rootPos)
	local nearest, nearDist = nil, math.huge
	for _, coin in ipairs(list) do
		if touchedCoins[coin] then continue end
		if not coin or not coin.Parent then
			touchedCoins[coin] = true
			continue
		end
		local d = (coin.Position - rootPos).Magnitude
		if d < nearDist then nearest = coin nearDist = d end
	end
	return nearest
end
local farmBV  = nil
local farmBG  = nil
local function enableFarmFly(char)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
	if farmBV then pcall(function() farmBV:Destroy() end) end
	farmBV = Instance.new("BodyVelocity")
	farmBV.Velocity  = Vector3.zero
	farmBV.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
	farmBV.P         = 1e9
	farmBV.Parent    = root
	if farmBG then pcall(function() farmBG:Destroy() end) end
	farmBG = Instance.new("BodyGyro")
	farmBG.CFrame    = root.CFrame
	farmBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	farmBG.P         = 1e9
	farmBG.D         = 500
	farmBG.Parent    = root
end
local function disableFarmFly(char)
	if farmBV then pcall(function() farmBV:Destroy() end) farmBV = nil end
	if farmBG then pcall(function() farmBG:Destroy() end) farmBG = nil end
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = true end
	end
	if root then
		root.AssemblyLinearVelocity  = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end
local function flyToPosition(char, targetPos, speed, tolerance)
	speed     = speed or 18
	tolerance = tolerance or 1.2
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not farmBV then return end
	local timeout = tick() + 15
	while AUTOFARM_ENABLED and ALIVE do
		if tick() > timeout then break end
		root = char:FindFirstChild("HumanoidRootPart")
		if not root or not farmBV or not farmBV.Parent then break end
		local diff = targetPos - root.Position
		local dist = diff.Magnitude
		if dist <= tolerance then break end
		farmBV.Velocity = diff.Unit * math.min(speed, dist * 8)
		task.wait(0.05)
	end
	if farmBV and farmBV.Parent then
		farmBV.Velocity = Vector3.zero
	end
end
local function startAutoFarm()
	if farmThread then return end
	table.clear(touchedCoins)
	table.clear(coinConns)
	farmThread = task.spawn(function()
		while AUTOFARM_ENABLED and ALIVE do
			if not UNLOCKED then task.wait(0.5) continue end
			local char = LocalPlayer.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if not char or not hum or hum.Health <= 0 then task.wait(0.5) continue end
			local map = getMap()
			if not map then task.wait(2) continue end
			local coinContainer = map:FindFirstChild("CoinContainer")
			if not coinContainer then task.wait(2) continue end
			local coins = buildCoinList(coinContainer)
			if #coins == 0 then task.wait(2) continue end
			enableFarmFly(char)
			while AUTOFARM_ENABLED and ALIVE do
				char = LocalPlayer.Character
				hum  = char and char:FindFirstChildOfClass("Humanoid")
				if not char or not hum or hum.Health <= 0 then break end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then task.wait(0.2) continue end
				local rootPos = root.Position
				local coin    = getNearestCoin(coins, rootPos)
				if not coin then
					task.wait(1)
					break
				end
				local coinPos = coin.Position + Vector3.new(0, 0.5, 0)
				flyToPosition(char, coinPos, 18, 1.2)
				task.wait(0.08)
				markCollected(coin)
				task.wait(0.1)
			end
			disableFarmFly(char)
			task.wait(0.5)
		end
		local char = LocalPlayer.Character
		if char then disableFarmFly(char) end
		for _, conn in pairs(coinConns) do
			pcall(function() conn:Disconnect() end)
		end
		table.clear(touchedCoins)
		table.clear(coinConns)
		farmThread = nil
	end)
end
local function stopAutoFarm()
	AUTOFARM_ENABLED = false
	farmThread = nil
end
local function tpToGun()
	if not UNLOCKED then return end
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Tool") then
			local name = obj.Name:lower()
			if name:find("gun") or name:find("revolver") or name:find("pistol") then
				local isHeld = false
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character and obj:IsDescendantOf(p.Character) then
						isHeld = true break
					end
				end
				if not isHeld then
					local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
					if handle then
						root.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
						return true
					end
				end
			end
		end
	end
	return false
end
local function killAll()
	if not UNLOCKED or not amIMurderer() then return end
	if KILLALL_RUNNING then return end
	KILLALL_RUNNING = true
	task.spawn(function()
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local myTool = nil
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") then
				local n = item.Name:lower()
				if n:find("knife") or n:find("sword") or n:find("blade") then
					myTool = item break
				end
			end
		end
		if not root or not myTool then KILLALL_RUNNING = false return end
		local targets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					table.insert(targets, p)
				end
			end
		end
		local savedCF = root.CFrame
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
		for _, target in ipairs(targets) do
			if not target.Character then continue end
			local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
			if not tRoot then continue end
			root.CFrame = tRoot.CFrame * CFrame.new(0, 0, -1.2)
			task.wait(0.05)
			local remotes = myTool:GetDescendants()
			for _, r in ipairs(remotes) do
				if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
					pcall(function() r:FireServer(tRoot.Position) end)
				end
			end
			root.CFrame = tRoot.CFrame
			task.wait(0.08)
		end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = true end
		end
		root.CFrame = savedCF
		KILLALL_RUNNING = false
	end)
end

local drawings = {}
local R15_CONNECTIONS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6_CONNECTIONS = {
	{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local C = {
	MetalHi   = Color3.fromRGB(126, 128, 136),
	Metal     = Color3.fromRGB( 78,  80,  86),
	MetalLow  = Color3.fromRGB( 44,  45,  50),
	Chamfer   = Color3.fromRGB(178, 180, 190),
	Glass     = Color3.fromRGB(  9,   9,  11),
	Bg        = Color3.fromRGB( 16,  16,  19),
	Bar       = Color3.fromRGB( 22,  22,  26),
	Card      = Color3.fromRGB( 32,  32,  36),
	CardHi    = Color3.fromRGB( 48,  48,  54),
	Sep       = Color3.fromRGB( 58,  58,  64),
	SwitchOff = Color3.fromRGB( 60,  60,  66),
	White     = Color3.fromRGB(255, 255, 255),
	Text      = Color3.fromRGB(242, 242, 247),
	TextSub   = Color3.fromRGB(152, 152, 160),
	TextDim   = Color3.fromRGB(108, 108, 116),
	Accent    = Color3.fromRGB( 10, 132, 255),
	Green     = Color3.fromRGB( 48, 209,  88),
	Red       = Color3.fromRGB(255,  69,  58),
	Yellow    = Color3.fromRGB(255, 214,  10),
	Orange    = Color3.fromRGB(255, 159,  10),
	Border    = Color3.fromRGB(255, 255, 255),
}
local PH_W,  PH_H  = 302, 610
local LIP          = 5
local SCR_W, SCR_H = 264, 470
local SCR_X, SCR_Y =  14,  60
local BAR_H, NAV_H, TAB_H = 22, 50, 50
local PAGE_Y = BAR_H + NAV_H
local PAGE_H = SCR_H - PAGE_Y - TAB_H
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r)
	new("UICorner", {CornerRadius = typeof(r) == "number" and UDim.new(0, r) or r}, o)
	return o
end
local function strk(o, col, trans, thick)
	return new("UIStroke", {
		Color = col or C.Border,
		Transparency = trans or 0.85,
		Thickness = thick or 1,
	}, o)
end
local function pressFX(o, baseT)
	baseT = baseT or 0
	EXEC.onHold(o,
		function()
			TweenService:Create(o, TweenInfo.new(0.07), {BackgroundTransparency = math.min(baseT + 0.45, 0.85)}):Play()
		end,
		function()
			TweenService:Create(o, TweenInfo.new(0.16), {BackgroundTransparency = baseT}):Play()
		end)
	return o
end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "iPhone7Plus_MM2"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
parentGui(screenGui)
local UI = {}
local function notify(text, colour)
	local toast = corner(new("TextLabel", {
		Size = UDim2.new(0, 250, 0, 34),
		Position = UDim2.new(0.5, -125, 0, -40),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = C.Bar,
		BackgroundTransparency = 0.08,
		Text = text,
		TextColor3 = colour or C.Text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BorderSizePixel = 0,
		ZIndex = 200,
	}, screenGui), 10)
	strk(toast, C.Border, 0.75, 1)
	local slide = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(toast, slide, {Position = UDim2.new(0.5, -125, 0, 14)}):Play()
	task.delay(2.2, function()
		TweenService:Create(toast, slide, {Position = UDim2.new(0.5, -125, 0, -40)}):Play()
		TweenService:Create(toast, slide, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.delay(0.35, function() pcall(function() toast:Destroy() end) end)
	end)
end

local device = new("Frame", {
	Name = "Device",
	Size = UDim2.new(0, PH_W, 0, PH_H),
	Position = UDim2.new(0, 26, 0.5, -PH_H / 2),
	BackgroundTransparency = 1,
	ZIndex = 1,
}, screenGui)
local deviceScale = new("UIScale", {Scale = 0.88}, device)
UI.scale = 1
local function deviceExtent()
	return PH_W * UI.scale, PH_H * UI.scale
end
local function clampDevice()
	local vp = Camera.ViewportSize
	local w, h = deviceExtent()
	local p = device.Position
	local minX = 8 - w * 0.55
	device.Position = UDim2.fromOffset(
		math.clamp(p.X.Offset + p.X.Scale * vp.X, minX, math.max(minX, vp.X - w * 0.45)),
		math.clamp(p.Y.Offset + p.Y.Scale * vp.Y, 4,    math.max(4,    vp.Y - h * 0.35)))
end
local function fitDevice(reposition)
	local vp = Camera.ViewportSize
	if vp.X < 8 or vp.Y < 8 then return end
	UI.scale = math.clamp(math.min((vp.Y - 16) / PH_H, (vp.X * 0.6) / PH_W), 0.5, 1)
	if UI_VISIBLE then deviceScale.Scale = UI.scale end
	if reposition then
		local w, h = deviceExtent()
		device.Position = UDim2.fromOffset(
			EXEC.mobile and math.max(8, vp.X - w - 10) or 26,
			math.max(6, (vp.Y - h) / 2))
	else
		clampDevice()
	end
	if not UI_VISIBLE and UI.updateFloat then pcall(UI.updateFloat) end
end
fitDevice(true)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if ALIVE then fitDevice(false) end
end)
for i = 1, 3 do
	corner(new("Frame", {
		Size = UDim2.new(1, i * 8, 1, i * 8),
		Position = UDim2.new(0, -i * 4, 0, -i * 4 + i * 3),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.80 + i * 0.05,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, device), 46 + i * 4)
end
for _, b in ipairs({
	{0, -3, 128, 22},
	{0, -3, 166, 34},
	{0, -3, 208, 34},
	{1, -1, 150, 48},
}) do
	local s = corner(new("Frame", {
		Size = UDim2.new(0, 4, 0, b[4]),
		Position = UDim2.new(b[1], b[2], 0, b[3]),
		BackgroundColor3 = C.Metal,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, device), 2)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.MetalHi),
			ColorSequenceKeypoint.new(1, C.MetalLow),
		}),
		Rotation = 0,
	}, s)
end
local body = corner(new("Frame", {
	Name = "Body",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = C.Metal,
	BorderSizePixel = 0,
	ZIndex = 2,
}, device), 46)
strk(body, C.Chamfer, 0.42, 1.4)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, C.MetalHi),
		ColorSequenceKeypoint.new(0.05, C.Metal),
		ColorSequenceKeypoint.new(0.50, C.MetalLow),
		ColorSequenceKeypoint.new(0.95, C.Metal),
		ColorSequenceKeypoint.new(1.00, C.MetalHi),
	}),
	Rotation = 0,
}, body)
local glass = corner(new("Frame", {
	Name = "FrontGlass",
	Size = UDim2.new(1, -LIP * 2, 1, -LIP * 2),
	Position = UDim2.new(0, LIP, 0, LIP),
	BackgroundColor3 = C.Glass,
	BorderSizePixel = 0,
	ZIndex = 3,
}, body), 42)
strk(glass, Color3.fromRGB(0, 0, 0), 0.35, 1)
local ear = corner(new("Frame", {
	Size = UDim2.new(0, 62, 0, 6),
	Position = UDim2.new(0.5, -31, 0, 27),
	BackgroundColor3 = Color3.fromRGB(26, 26, 30),
	BorderSizePixel = 0,
	ZIndex = 8,
}, glass), UDim.new(1, 0))
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB( 6,  6,  8)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 40, 46)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB( 6,  6,  8)),
	}),
	Rotation = 90,
}, ear)
strk(ear, Color3.fromRGB(0, 0, 0), 0.5, 1)
corner(new("Frame", {
	Size = UDim2.new(0, 5, 0, 5),
	Position = UDim2.new(0.5, -52, 0, 28),
	BackgroundColor3 = Color3.fromRGB(15, 15, 18),
	BorderSizePixel = 0,
	ZIndex = 8,
}, glass), UDim.new(1, 0))
local camRing = corner(new("Frame", {
	Size = UDim2.new(0, 10, 0, 10),
	Position = UDim2.new(0.5, 44, 0, 25),
	BackgroundColor3 = Color3.fromRGB(13, 13, 16),
	BorderSizePixel = 0,
	ZIndex = 8,
}, glass), UDim.new(1, 0))
strk(camRing, Color3.fromRGB(54, 56, 64), 0.4, 1)
corner(new("Frame", {
	Size = UDim2.new(0, 4, 0, 4),
	Position = UDim2.new(0.5, -2, 0.5, -2),
	BackgroundColor3 = Color3.fromRGB(30, 66, 102),
	BorderSizePixel = 0,
	ZIndex = 9,
}, camRing), UDim.new(1, 0))
local screen = corner(new("Frame", {
	Name = "Display",
	Size = UDim2.new(0, SCR_W, 0, SCR_H),
	Position = UDim2.new(0, SCR_X, 0, SCR_Y),
	BackgroundColor3 = C.Bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 6,
}, glass), 4)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(26, 32, 52)),
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(16, 17, 24)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(11, 11, 15)),
	}),
	Rotation = 155,
}, screen)
local statusBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, BAR_H),
	BackgroundTransparency = 1,
	ZIndex = 30,
}, screen)
UI.dots = {}
for i = 1, 5 do
	UI.dots[i] = corner(new("Frame", {
		Size = UDim2.new(0, 5, 0, 5),
		Position = UDim2.new(0, 9 + (i - 1) * 7, 0, 9),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 31,
	}, statusBar), UDim.new(1, 0))
end
UI.carrier = new("TextLabel", {
	Size = UDim2.new(0, 70, 0, BAR_H),
	Position = UDim2.new(0, 49, 0, 0),
	BackgroundTransparency = 1,
	Text = "MM2",
	TextColor3 = C.Text,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 31,
}, statusBar)
UI.clock = new("TextLabel", {
	Size = UDim2.new(0, 80, 0, BAR_H),
	Position = UDim2.new(0.5, -40, 0, 0),
	BackgroundTransparency = 1,
	Text = "9:41",
	TextColor3 = C.White,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	ZIndex = 31,
}, statusBar)
UI.fpsLabel = new("TextLabel", {
	Size = UDim2.new(0, 34, 0, BAR_H),
	Position = UDim2.new(1, -70, 0, 0),
	BackgroundTransparency = 1,
	Text = "60",
	TextColor3 = C.Text,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 31,
}, statusBar)
local battShell = corner(new("Frame", {
	Size = UDim2.new(0, 24, 0, 11),
	Position = UDim2.new(1, -32, 0, 6),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 31,
}, statusBar), 3)
strk(battShell, C.White, 0.6, 1)
UI.battFill = corner(new("Frame", {
	Size = UDim2.new(0, 20, 1, -4),
	Position = UDim2.new(0, 2, 0, 2),
	BackgroundColor3 = C.Green,
	BorderSizePixel = 0,
	ZIndex = 32,
}, battShell), 2)
corner(new("Frame", {
	Size = UDim2.new(0, 2, 0, 4),
	Position = UDim2.new(1, -7, 0, 10),
	BackgroundColor3 = C.White,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	ZIndex = 31,
}, statusBar), 1)
local nav = new("Frame", {
	Size = UDim2.new(1, 0, 0, NAV_H),
	Position = UDim2.new(0, 0, 0, BAR_H),
	BackgroundColor3 = C.Bar,
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 30,
}, screen)
local appIcon = corner(new("Frame", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(0, 12, 0.5, -15),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	ZIndex = 31,
}, nav), 8)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(92, 178, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB( 0,  82, 200)),
	}),
	Rotation = 120,
}, appIcon)
strk(appIcon, C.White, 0.72, 1)
new("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "M",
	TextColor3 = C.White,
	TextSize = 17,
	Font = Enum.Font.GothamBlack,
	ZIndex = 32,
}, appIcon)
new("TextLabel", {
	Size = UDim2.new(1, -132, 0, 18),
	Position = UDim2.new(0, 50, 0, 9),
	BackgroundTransparency = 1,
	Text = "MM2 UNDETECTED",
	TextColor3 = C.White,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 31,
}, nav)
new("TextLabel", {
	Size = UDim2.new(1, -132, 0, 14),
	Position = UDim2.new(0, 50, 0, 26),
	BackgroundTransparency = 1,
	Text = "by tortorfugstar",
	TextColor3 = C.TextSub,
	TextSize = 10,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 31,
}, nav)
UI.rolePill = corner(new("TextLabel", {
	Size = UDim2.new(0, 66, 0, 20),
	Position = UDim2.new(1, -78, 0.5, -10),
	BackgroundColor3 = C.CardHi,
	BackgroundTransparency = 0.15,
	Text = "INNOCENT",
	TextColor3 = C.TextSub,
	TextSize = 9,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	ZIndex = 31,
}, nav), UDim.new(1, 0))
strk(UI.rolePill, C.Border, 0.86, 1)
new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = C.Sep,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 31,
}, nav)
local page = {}
for _, key in ipairs({"combat", "move", "settings"}) do
	local p = new("ScrollingFrame", {
		Name = key,
		Size = UDim2.new(1, 0, 0, PAGE_H),
		Position = UDim2.new(0, 0, 0, PAGE_Y),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.TextDim,
		ScrollBarImageTransparency = 0.35,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 10,
	}, screen)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, p)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 6),   PaddingBottom = UDim.new(0, 16),
	}, p)
	page[key] = p
end
local function sectionHeader(parent, text, order)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = "  " .. text:upper(),
		TextColor3 = C.TextDim,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = order,
		ZIndex = 11,
	}, parent)
end
local function newGroup(parent, order)
	local g = corner(new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Card,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = order,
		ZIndex = 11,
	}, parent), 12)
	strk(g, C.Border, 0.9, 1)
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, g)
	local n = 0
	return g, function(h)
		n += 1
		local row = new("Frame", {
			Size = UDim2.new(1, 0, 0, h),
			BackgroundTransparency = 1,
			LayoutOrder = n,
			ZIndex = 12,
		}, g)
		if n > 1 then
			new("Frame", {
				Size = UDim2.new(1, -16, 0, 1),
				Position = UDim2.new(0, 16, 0, 0),
				BackgroundColor3 = C.Sep,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				ZIndex = 13,
			}, row)
		end
		return row
	end
end
local function rowText(row, title, sub, rightPad)
	local w = -(rightPad or 84)
	if sub and sub ~= "" then
		new("TextLabel", {
			Size = UDim2.new(1, w, 0, 18), Position = UDim2.new(0, 14, 0, 11),
			BackgroundTransparency = 1, Text = title, TextColor3 = C.Text,
			TextSize = 14, Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13,
		}, row)
		new("TextLabel", {
			Size = UDim2.new(1, w, 0, 14), Position = UDim2.new(0, 14, 0, 31),
			BackgroundTransparency = 1, Text = sub, TextColor3 = C.TextSub,
			TextSize = 11, Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13,
		}, row)
	else
		new("TextLabel", {
			Size = UDim2.new(1, w, 1, 0), Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1, Text = title, TextColor3 = C.Text,
			TextSize = 14, Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13,
		}, row)
	end
end
local function iosSwitch(parent, get, onToggle)
	local track = corner(new("TextButton", {
		Size = UDim2.new(0, 51, 0, 31),
		Position = UDim2.new(1, -65, 0.5, -15),
		BackgroundColor3 = C.SwitchOff,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		ZIndex = 14,
	}, parent), UDim.new(1, 0))
	strk(track, C.Border, 0.92, 1)
	local knob = corner(new("Frame", {
		Size = UDim2.new(0, 27, 0, 27),
		Position = UDim2.new(0, 2, 0.5, -13),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, track), UDim.new(1, 0))
	strk(knob, Color3.fromRGB(0, 0, 0), 0.86, 1)
	local function refresh()
		local on = get() and true or false
		TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{BackgroundColor3 = on and C.Green or C.SwitchOff}):Play()
		TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = on and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)}):Play()
	end
	track.MouseButton1Click:Connect(function()
		if not UNLOCKED then return end
		onToggle()
		refresh()
	end)
	refresh()
	return refresh
end
local function switchRow(addRow, title, sub, get, onToggle)
	local row = addRow(sub and 58 or 46)
	rowText(row, title, sub, 84)
	return iosSwitch(row, get, onToggle)
end
local function actionRow(addRow, title, sub, label, colour, onClick)
	local row = addRow(sub and 58 or 46)
	rowText(row, title, sub, 112)
	local btn = corner(new("TextButton", {
		Size = UDim2.new(0, 80, 0, 30),
		Position = UDim2.new(1, -94, 0.5, -15),
		BackgroundColor3 = colour,
		Text = label,
		TextColor3 = C.White,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 14,
	}, row), 9)
	strk(btn, C.Border, 0.78, 1)
	pressFX(btn)
	btn.MouseButton1Click:Connect(function()
		if not UNLOCKED then return end
		onClick(btn)
	end)
	return btn
end
do
	local strip = new("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		ZIndex = 11,
	}, page.combat)
	local function tile(x, caption, size)
		local f = corner(new("Frame", {
			Size = UDim2.new(0, 76, 0, 54),
			Position = UDim2.new(0, x, 0, 0),
			BackgroundColor3 = C.Card,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ZIndex = 11,
		}, strip), 12)
		strk(f, C.Border, 0.9, 1)
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 9),
			BackgroundTransparency = 1, Text = caption, TextColor3 = C.TextDim,
			TextSize = 9, Font = Enum.Font.GothamBold, ZIndex = 12,
		}, f)
		return new("TextLabel", {
			Size = UDim2.new(1, -6, 0, 22), Position = UDim2.new(0, 3, 0, 23),
			BackgroundTransparency = 1, Text = "—", TextColor3 = C.Text,
			TextSize = size, Font = Enum.Font.GothamBold, ZIndex = 12,
		}, f)
	end
	UI.statFps  = tile(0,   "FPS",  17)
	UI.statPing = tile(82,  "PING", 15)
	UI.statRole = tile(164, "ROLE", 11)
	sectionHeader(page.combat, "Target", 1)
	local card = corner(new("Frame", {
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundColor3 = C.Card,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ZIndex = 11,
	}, page.combat), 12)
	strk(card, C.Border, 0.9, 1)
	UI.avatar = corner(new("ImageLabel", {
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = C.CardHi,
		Image = "",
		BorderSizePixel = 0,
		ZIndex = 12,
	}, card), UDim.new(1, 0))
	UI.avatarRing = strk(UI.avatar, C.Red, 0.1, 2)
	UI.roleBadge = corner(new("Frame", {
		Size = UDim2.new(0, 15, 0, 15),
		Position = UDim2.new(1, -14, 1, -14),
		BackgroundColor3 = C.Red,
		BorderSizePixel = 0,
		ZIndex = 14,
	}, UI.avatar), UDim.new(1, 0))
	strk(UI.roleBadge, C.Card, 0.1, 2)
	UI.targetName = new("TextLabel", {
		Size = UDim2.new(1, -84, 0, 20), Position = UDim2.new(0, 70, 0, 16),
		BackgroundTransparency = 1, Text = "Murderer", TextColor3 = C.White,
		TextSize = 15, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 12,
	}, card)
	UI.targetStatus = new("TextLabel", {
		Size = UDim2.new(1, -84, 0, 16), Position = UDim2.new(0, 70, 0, 37),
		BackgroundTransparency = 1, Text = "Waiting…", TextColor3 = C.TextSub,
		TextSize = 11, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 12,
	}, card)
	local function wideBtn(label, x, colour, faded)
		local b = corner(new("TextButton", {
			Size = UDim2.new(0, 105, 0, 30),
			Position = UDim2.new(0, x, 0, 68),
			BackgroundColor3 = colour,
			BackgroundTransparency = faded and 0.35 or 0,
			Text = label,
			TextColor3 = C.White,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = 13,
		}, card), 9)
		strk(b, C.Border, faded and 0.82 or 0.75, 1)
		pressFX(b, faded and 0.35 or 0)
		return b
	end
	local specBtn  = wideBtn("Spectate", 12,  C.CardHi, true)
	local flingBtn = wideBtn("Fling",    123, C.Red,    false)
	specBtn.MouseButton1Click:Connect(function()
		if not UNLOCKED then return end
		toggleSpectate()
		specBtn.Text = SPECTATING and "Stop" or "Spectate"
	end)
	EXEC.onHold(flingBtn,
		function()
			if not UNLOCKED then return end
			startFling()
			flingBtn.Text = "Flinging…"
		end,
		function()
			stopFling()
			flingBtn.Text = "Fling"
		end)
	sectionHeader(page.combat, "Combat", 3)
	local _, addRow = newGroup(page.combat, 4)
	switchRow(addRow, "Smooth Aimbot", EXEC.keys and "Hold R to lock on" or "Hold AIM on the side pad",
		function() return AIMBOT_ENABLED end,
		function() AIMBOT_ENABLED = not AIMBOT_ENABLED end)
	switchRow(addRow, "Auto Aim", "Lock on without holding anything",
		function() return EXEC.autoAim end,
		function()
			EXEC.autoAim = not EXEC.autoAim
			if UI.aimBtn then
				UI.aimBtn.BackgroundColor3 = EXEC.autoAim and C.Green or C.Accent
			end
		end)
	switchRow(addRow, "Bone ESP", "Skeleton overlay on players",
		function() return ESP_ENABLED end,
		function() ESP_ENABLED = not ESP_ENABLED end)
	actionRow(addRow, "Kill All", "Murderer only · ~2s", "Execute", C.Red, function(btn)
		if not amIMurderer() then
			btn.Text = "Knife only"
			task.delay(1.2, function() btn.Text = "Execute" end)
			return
		end
		btn.Text = "Running…"
		killAll()
		task.delay(2.5, function() btn.Text = "Execute" end)
	end)
	actionRow(addRow, "TP to Gun", "Teleport to the dropped gun", "Teleport", C.Accent, function(btn)
		local found = tpToGun()
		btn.Text = found and "✓ Done" or "No gun"
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = found and C.Green or C.Red}):Play()
		task.delay(1.2, function()
			btn.Text = "Teleport"
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.Accent}):Play()
		end)
	end)
end
do
	sectionHeader(page.move, "Movement", 0)
	local _, addRow = newGroup(page.move, 1)
	UI.noclipRefresh = switchRow(addRow, "Noclip", "Pass through walls",
		function() return NOCLIP_ENABLED end,
		function() NOCLIP_ENABLED = not NOCLIP_ENABLED end)
	switchRow(addRow, "Auto Farm", "Collect coins & beach balls",
		function() return AUTOFARM_ENABLED end,
		function()
			AUTOFARM_ENABLED = not AUTOFARM_ENABLED
			if AUTOFARM_ENABLED then
				NOCLIP_ENABLED = true
				startAutoFarm()
			else
				stopAutoFarm()
				NOCLIP_ENABLED = false
			end
			if UI.noclipRefresh then pcall(UI.noclipRefresh) end
		end)
	sectionHeader(page.move, "WalkSpeed", 2)
	local card = corner(new("Frame", {
		Size = UDim2.new(1, 0, 0, 180),
		BackgroundColor3 = C.Card,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		ZIndex = 11,
	}, page.move), 12)
	strk(card, C.Border, 0.9, 1)
	new("TextLabel", {
		Size = UDim2.new(0, 120, 0, 20), Position = UDim2.new(0, 14, 0, 12),
		BackgroundTransparency = 1, Text = "WalkSpeed", TextColor3 = C.Text,
		TextSize = 14, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
	}, card)
	speedValueLabel = new("TextLabel", {
		Size = UDim2.new(0, 70, 0, 20), Position = UDim2.new(1, -84, 0, 12),
		BackgroundTransparency = 1, Text = tostring(WalkSpeed), TextColor3 = C.Accent,
		TextSize = 15, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 12,
	}, card)
	local track = corner(new("Frame", {
		Size = UDim2.new(0, 212, 0, 4), Position = UDim2.new(0, 14, 0, 50),
		BackgroundColor3 = C.SwitchOff, BorderSizePixel = 0, ZIndex = 12,
	}, card), UDim.new(1, 0))
	local fill = corner(new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 13,
	}, track), UDim.new(1, 0))
	local knob = corner(new("Frame", {
		Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, -10, 0.5, -10),
		BackgroundColor3 = C.White, BorderSizePixel = 0, ZIndex = 14,
	}, track), UDim.new(1, 0))
	strk(knob, Color3.fromRGB(0, 0, 0), 0.84, 1)
	speedSliderRefresh = function()
		local a = (WalkSpeed - MinSpeed) / (MaxSpeed - MinSpeed)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, -10, 0.5, -10)
	end
	new("TextLabel", {
		Size = UDim2.new(0, 40, 0, 14), Position = UDim2.new(0, 14, 0, 62),
		BackgroundTransparency = 1, Text = tostring(MinSpeed), TextColor3 = C.TextDim,
		TextSize = 9, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
	}, card)
	new("TextLabel", {
		Size = UDim2.new(0, 40, 0, 14), Position = UDim2.new(0, 186, 0, 62),
		BackgroundTransparency = 1, Text = tostring(MaxSpeed), TextColor3 = C.TextDim,
		TextSize = 9, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 12,
	}, card)
	local hit = new("TextButton", {
		Size = UDim2.new(0, 212, 0, 30), Position = UDim2.new(0, 14, 0, 37),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 15,
	}, card)
	local sliding = false
	local function applyX(px)
		local a = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setWalkSpeed(math.floor(MinSpeed + a * (MaxSpeed - MinSpeed) + 0.5))
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if not UNLOCKED then return end
			sliding = true
			applyX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			applyX(input.Position.X)
		end
	end)
	local function circBtn(label, x)
		local b = corner(new("TextButton", {
			Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, x, 0, 86),
			BackgroundColor3 = C.CardHi, BackgroundTransparency = 0.15,
			Text = label, TextColor3 = C.White, TextSize = 22,
			Font = Enum.Font.GothamBold, AutoButtonColor = false,
			BorderSizePixel = 0, ZIndex = 13,
		}, card), UDim.new(1, 0))
		strk(b, C.Border, 0.82, 1)
		pressFX(b, 0.15)
		return b
	end
	local function repeatHold(btn, step)
		local held = false
		EXEC.onHold(btn,
			function()
				held = true
				setWalkSpeed(WalkSpeed + step)
				task.spawn(function()
					task.wait(0.35)
					while held and ALIVE do
						setWalkSpeed(WalkSpeed + step)
						task.wait(0.05)
					end
				end)
			end,
			function() held = false end)
	end
	repeatHold(circBtn("−", 14),  -SpeedStep)
	repeatHold(circBtn("+", 184),  SpeedStep)
	bigSpeedLabel = new("TextLabel", {
		Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(0.5, -60, 0, 88),
		BackgroundTransparency = 1, Text = tostring(WalkSpeed), TextColor3 = C.Accent,
		TextSize = 26, Font = Enum.Font.GothamBlack, ZIndex = 12,
	}, card)
	new("TextLabel", {
		Size = UDim2.new(0, 120, 0, 14), Position = UDim2.new(0.5, -60, 0, 114),
		BackgroundTransparency = 1, Text = "studs / second", TextColor3 = C.TextDim,
		TextSize = 9, Font = Enum.Font.Gotham, ZIndex = 12,
	}, card)
	for i, v in ipairs({16, 50, 100, 200}) do
		local chip = corner(new("TextButton", {
			Size = UDim2.new(0, 50, 0, 28),
			Position = UDim2.new(0, 14 + (i - 1) * 54, 0, 138),
			BackgroundColor3 = C.CardHi, BackgroundTransparency = 0.2,
			Text = tostring(v), TextColor3 = C.Text, TextSize = 12,
			Font = Enum.Font.GothamBold, AutoButtonColor = false,
			BorderSizePixel = 0, ZIndex = 13,
		}, card), 9)
		strk(chip, C.Border, 0.86, 1)
		pressFX(chip, 0.2)
		chip.MouseButton1Click:Connect(function() setWalkSpeed(v) end)
	end
	speedSliderRefresh()
end
do
	sectionHeader(page.settings, "Shortcuts", 0)
	local _, addRow = newGroup(page.settings, 1)
	local function keyRow(key, what)
		local r = addRow(42)
		rowText(r, what, nil, 98)
		local k = corner(new("TextLabel", {
			Size = UDim2.new(0, 68, 0, 24), Position = UDim2.new(1, -82, 0.5, -12),
			BackgroundColor3 = C.CardHi, BackgroundTransparency = 0.15,
			Text = key, TextColor3 = C.Text, TextSize = 10,
			Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 13,
		}, r), 7)
		strk(k, C.Border, 0.86, 1)
	end
	if EXEC.keys then
		keyRow("Hold R",  "Smooth aimbot")
		keyRow("Hold T",  "Fling target")
		keyRow("Q  /  E", "Speed  −  /  +")
		keyRow("G",       "Kill all (murderer)")
		keyRow("F",       "TP to gun")
		keyRow("N",       "Toggle noclip")
		keyRow("Ctrl",    "Show / hide phone")
	else
		keyRow("AIM",   "Hold to lock on")
		keyRow("FLING", "Hold to fling target")
		keyRow("KILL",  "Kill all (murderer)")
		keyRow("GUN",   "TP to gun")
		keyRow("Home",  "Show / hide phone")
		keyRow("· · ·", "Drag the pad anywhere")
	end

	sectionHeader(page.settings, "About", 4)
	local _, addRow3 = newGroup(page.settings, 5)
	local function infoRow(label, value)
		local r = addRow3(44)
		rowText(r, label, nil, 152)
		new("TextLabel", {
			Size = UDim2.new(0, 122, 1, 0), Position = UDim2.new(1, -136, 0, 0),
			BackgroundTransparency = 1, Text = value, TextColor3 = C.TextSub,
			TextSize = 12, Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13,
		}, r)
	end
	local exec = EXEC.name or "Unknown"
	infoRow("Script",   "MM2 UNDETECTED")
	infoRow("Author",   "tortorfugstar")
	infoRow("Executor", exec)
	infoRow("Input",    EXEC.touch and (EXEC.keys and "Touch + Keys" or "Touch") or "Keyboard")
	infoRow("ESP mode", EXEC.hasDrawing and "Drawing" or "Frames")
	sectionHeader(page.settings, "Display", 6)
	local _, addRow4 = newGroup(page.settings, 7)
	UI.padRefresh = switchRow(addRow4, "Action pad", "On-screen AIM / FLING / KILL / GUN",
		function() return UI.touchPad and UI.touchPad.Visible end,
		function()
			if UI.touchPad then UI.touchPad.Visible = not UI.touchPad.Visible end
		end)
	local r = addRow4(58)
	rowText(r, "Hide phone", EXEC.keys and "Tap home or press Ctrl" or "Tap the home button", 84)
end
local tabBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, TAB_H),
	Position = UDim2.new(0, 0, 1, -TAB_H),
	BackgroundColor3 = C.Bar,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ZIndex = 30,
}, screen)
new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.Sep,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 31,
}, tabBar)
local showTab
do
	local tabs = {
		{key = "combat",   icon = "🎯", label = "Combat"},
		{key = "move",     icon = "🏃", label = "Move"},
		{key = "settings", icon = "⚙",  label = "Settings"},
	}
	local parts, current = {}, nil
	for i, t in ipairs(tabs) do
		local btn = new("TextButton", {
			Size = UDim2.new(0, 88, 1, 0),
			Position = UDim2.new(0, (i - 1) * 88, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 33,
		}, tabBar)
		local hl = corner(new("Frame", {
			Size = UDim2.new(0, 56, 0, 42),
			Position = UDim2.new(0.5, -28, 0.5, -21),
			BackgroundColor3 = C.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 31,
		}, btn), 11)
		local icon = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 6),
			BackgroundTransparency = 1, Text = t.icon, TextColor3 = C.White,
			TextSize = 16, Font = Enum.Font.GothamBold, ZIndex = 34,
		}, btn)
		local label = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 28),
			BackgroundTransparency = 1, Text = t.label, TextColor3 = C.TextDim,
			TextSize = 9, Font = Enum.Font.GothamBold, ZIndex = 34,
		}, btn)
		parts[t.key] = {icon = icon, label = label, hl = hl}
		btn.MouseButton1Click:Connect(function() showTab(t.key) end)
	end
	function showTab(key)
		if current == key then return end
		current = key
		for k, p in pairs(page) do p.Visible = (k == key) end
		local p = page[key]
		p.Position = UDim2.new(0, 14, 0, PAGE_Y)
		TweenService:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = UDim2.new(0, 0, 0, PAGE_Y)}):Play()
		for k, v in pairs(parts) do
			local on = (k == key)
			TweenService:Create(v.icon,  TweenInfo.new(0.18), {TextTransparency = on and 0 or 0.5}):Play()
			TweenService:Create(v.label, TweenInfo.new(0.18), {TextColor3 = on and C.Accent or C.TextDim}):Play()
			TweenService:Create(v.hl,    TweenInfo.new(0.18), {BackgroundTransparency = on and 0.88 or 1}):Play()
		end
	end
end
local home = corner(new("TextButton", {
	Size = UDim2.new(0, 46, 0, 46),
	Position = UDim2.new(0.5, 0, 0, SCR_Y + SCR_H + 35),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(20, 20, 23),
	Text = "",
	AutoButtonColor = false,
	BorderSizePixel = 0,
	ZIndex = 12,
}, glass), UDim.new(1, 0))
local homeRing  = strk(home, Color3.fromRGB(160, 162, 172), 0.2, 1.6)
local homeScale = new("UIScale", {Scale = 1}, home)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 12)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 32, 38)),
	}),
	Rotation = 90,
}, home)
local floatHome = corner(new("TextButton", {
	Size = UDim2.new(0, 52, 0, 52),
	BackgroundColor3 = C.Accent,
	Text = "M",
	TextColor3 = C.White,
	TextSize = 24,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 80,
}, screenGui), 13)
strk(floatHome, C.White, 0.68, 1.2)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(92, 178, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB( 0,  82, 200)),
	}),
	Rotation = 120,
}, floatHome)
local function updateFloatPosition()
	local vp = Camera.ViewportSize
	local w, h = PH_W * UI.scale, PH_H * UI.scale
	local p = device.Position
	floatHome.Position = UDim2.fromOffset(
		math.clamp(p.X.Offset + (w - 52) / 2, 6, math.max(6, vp.X - 58)),
		math.clamp(p.Y.Offset + h - 64,       6, math.max(6, vp.Y - 58)))
end
UI.updateFloat = updateFloatPosition
local function toggleUI()
	UI_VISIBLE = not UI_VISIBLE
	if UI_VISIBLE then
		floatHome.Visible = false
		device.Visible = true
		deviceScale.Scale = UI.scale * 0.88
		TweenService:Create(deviceScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Scale = UI.scale}):Play()
	else
		updateFloatPosition()
		floatHome.Visible = true
		TweenService:Create(deviceScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Scale = UI.scale * 0.86}):Play()
		task.delay(0.17, function()
			if not UI_VISIBLE then device.Visible = false end
		end)
	end
end
EXEC.onHold(home,
	function()
		TweenService:Create(homeScale, TweenInfo.new(0.07), {Scale = 0.92}):Play()
		TweenService:Create(homeRing, TweenInfo.new(0.12), {Color = C.Accent, Transparency = 0}):Play()
	end,
	function()
		TweenService:Create(homeScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Scale = 1}):Play()
		TweenService:Create(homeRing, TweenInfo.new(0.28),
			{Color = Color3.fromRGB(160, 162, 172), Transparency = 0.2}):Play()
	end)
home.MouseButton1Click:Connect(toggleUI)
floatHome.MouseButton1Click:Connect(toggleUI)
do
	local pad = new("Frame", {
		Name = "TouchPad",
		Size = UDim2.new(0, 62, 0, 202),
		BackgroundTransparency = 1,
		Visible = EXEC.touch,
		ZIndex = 78,
	}, screenGui)
	UI.touchPad = pad
	local grip = corner(new("TextButton", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundColor3 = C.Bar,
		BackgroundTransparency = 0.25,
		Text = "· · ·",
		TextColor3 = C.TextDim,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 79,
	}, pad), 9)
	strk(grip, C.Border, 0.82, 1)
	local function padBtn(label, y, colour, hold, action)
		local b = corner(new("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundColor3 = colour,
			BackgroundTransparency = 0.12,
			Text = label,
			TextColor3 = C.White,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = 79,
		}, pad), 11)
		strk(b, C.Border, 0.72, 1)
		pressFX(b, 0.12)
		if hold then
			EXEC.onHold(b,
				function()
					if not UNLOCKED then return end
					action(true, b)
				end,
				function() action(false, b) end)
		else
			b.MouseButton1Click:Connect(function()
				if not UNLOCKED then return end
				action(true, b)
			end)
		end
		return b
	end
	local aimBtn = padBtn("AIM", 22, C.Accent, true, function(down, b)
		EXEC.aimHold = down
		TweenService:Create(b, TweenInfo.new(0.12),
			{BackgroundColor3 = (down or EXEC.autoAim) and C.Green or C.Accent}):Play()
	end)
	UI.aimBtn = aimBtn
	padBtn("FLING", 66, C.Red, true, function(down)
		if down then startFling() else stopFling() end
	end)
	padBtn("KILL", 110, C.Orange, false, function(_, b)
		if not amIMurderer() then
			b.Text = "KNIFE?"
			task.delay(1.2, function() b.Text = "KILL" end)
			return
		end
		b.Text = "…"
		killAll()
		task.delay(2.5, function() b.Text = "KILL" end)
	end)
	padBtn("GUN", 154, C.CardHi, false, function(_, b)
		local found = tpToGun()
		b.Text = found and "✓" or "NONE"
		task.delay(1.2, function() b.Text = "GUN" end)
	end)
	local function placePad()
		local vp = Camera.ViewportSize
		pad.Position = UDim2.fromOffset(math.max(6, vp.X - 70), math.max(6, vp.Y * 0.5 - 101))
	end
	placePad()
	if UI.padRefresh then pcall(UI.padRefresh) end
	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not ALIVE then return end
		local vp = Camera.ViewportSize
		local p  = pad.Position
		pad.Position = UDim2.fromOffset(
			math.clamp(p.X.Offset, 0, math.max(0, vp.X - 62)),
			math.clamp(p.Y.Offset, 0, math.max(0, vp.Y - 202)))
	end)
	local dragging, dragStart, startPos = false, nil, nil
	grip.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging, dragStart, startPos = true, input.Position, pad.Position
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local vp = Camera.ViewportSize
		local d  = input.Position - dragStart
		pad.Position = UDim2.fromOffset(
			math.clamp(startPos.X.Offset + d.X, 0, math.max(0, vp.X - 62)),
			math.clamp(startPos.Y.Offset + d.Y, 0, math.max(0, vp.Y - 202)))
	end)
end
do
	local reflect = corner(new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 70,
	}, glass), 42)
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.94),
			NumberSequenceKeypoint.new(0.26, 0.975),
			NumberSequenceKeypoint.new(0.30, 1.00),
			NumberSequenceKeypoint.new(1.00, 1.00),
		}),
		Rotation = 118,
	}, reflect)
end
do
	local dragging, dragStart, startPos = false, nil, nil
	local function beginDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = device.Position
		end
	end
	for _, y in ipairs({0, SCR_Y + SCR_H}) do
		local padH = (y == 0) and SCR_Y or (PH_H - LIP * 2 - y)
		new("TextButton", {
			Size = UDim2.new(1, 0, 0, padH),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 7,
		}, glass).InputBegan:Connect(beginDrag)
	end
	nav.InputBegan:Connect(beginDrag)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then clampDevice() end
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			device.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end
local lastTargetId, lastRoleText = nil, nil
local function updateTargetUI()
	local myTool  = getMyTool()
	local iAmMurd = myTool == "Knife"
	local roleText, roleCol = "INNOCENT", C.TextSub
	if iAmMurd then roleText, roleCol = "MURDERER", C.Red
	elseif myTool == "Gun" then roleText, roleCol = "SHERIFF", C.Accent end
	if roleText ~= lastRoleText then
		lastRoleText = roleText
		UI.rolePill.Text = roleText
		UI.rolePill.TextColor3 = roleCol
		UI.statRole.Text = roleText
		UI.statRole.TextColor3 = roleCol
	end
	local target = iAmMurd and getSheriff() or getMurderer()
	if target then
		UI.targetName.Text = target.Name
		if iAmMurd then
			UI.targetStatus.Text = "Has the Gun"
			UI.targetStatus.TextColor3 = C.Accent
			UI.avatarRing.Color = C.Accent
			UI.roleBadge.BackgroundColor3 = C.Accent
		else
			UI.targetStatus.Text = "Has the Knife"
			UI.targetStatus.TextColor3 = C.Red
			UI.avatarRing.Color = C.Red
			UI.roleBadge.BackgroundColor3 = C.Red
		end
		if target.UserId ~= lastTargetId then
			lastTargetId = target.UserId
			task.spawn(function()
				local ok, content = pcall(function()
					return Players:GetUserThumbnailAsync(target.UserId,
						Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				UI.avatar.Image = ok and content
					or ("https://www.roblox.com/headshot-thumbnail/image?userId="
						.. target.UserId .. "&width=48&height=48&format=png")
			end)
		end
	else
		UI.targetName.Text = iAmMurd and "Sheriff" or "Murderer"
		UI.targetStatus.Text = "Not found"
		UI.targetStatus.TextColor3 = C.TextSub
		UI.avatarRing.Color = iAmMurd and C.Accent or C.Red
		UI.roleBadge.BackgroundColor3 = iAmMurd and C.Accent or C.Red
		UI.avatar.Image = ""
		lastTargetId = nil
	end
end
do
	local frames, last = 0, tick()
	RunService.RenderStepped:Connect(function()
		frames += 1
		if tick() - last < 1 then return end
		last = tick()
		local fps  = frames
		frames = 0
		local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
		local lvl = math.clamp(fps / 60, 0.08, 1)
		UI.fpsLabel.Text = tostring(fps)
		UI.battFill.Size = UDim2.new(0, math.floor(20 * lvl), 1, -4)
		UI.battFill.BackgroundColor3 = fps >= 40 and C.Green or (fps >= 22 and C.Yellow or C.Red)
		local bars = ping <= 45 and 5 or (ping <= 80 and 4 or (ping <= 130 and 3 or (ping <= 220 and 2 or 1)))
		for i, d in ipairs(UI.dots) do
			d.BackgroundTransparency = (i <= bars) and 0 or 0.72
		end
		local ok, t = pcall(os.date, "%I:%M")
		if ok and type(t) == "string" then UI.clock.Text = (t:gsub("^0", "")) end
		UI.statFps.Text  = tostring(fps)
		UI.statPing.Text = ping .. "ms"
		UI.statPing.TextColor3 = ping <= 80 and C.Green or (ping <= 160 and C.Yellow or C.Red)
	end)
end
do
	if EXEC.hasDrawing then
		function EXEC.line()
			return Drawing.new("Line")
		end
	else
		local espGui = Instance.new("ScreenGui")
		espGui.Name           = "MM2_ESP"
		espGui.ResetOnSpawn   = false
		espGui.IgnoreGuiInset = true
		espGui.DisplayOrder   = 900
		parentGui(espGui)
		EXEC.espGui = espGui
		function EXEC.line()
			local f = Instance.new("Frame")
			f.AnchorPoint      = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = Color3.new(1, 1, 1)
			f.BorderSizePixel  = 0
			f.Visible          = false
			f.Parent           = espGui
			local from, to, thick = Vector2.zero, Vector2.zero, 1.8
			local function redraw()
				local d = to - from
				local mid = (from + to) / 2
				f.Position = UDim2.fromOffset(mid.X, mid.Y)
				f.Size     = UDim2.fromOffset(math.max(d.Magnitude, 1), thick)
				f.Rotation = math.deg(math.atan2(d.Y, d.X))
			end
			return setmetatable({}, {
				__index = function(_, k)
					if k == "Remove" or k == "Destroy" then
						return function() f:Destroy() end
					elseif k == "From" then return from
					elseif k == "To" then return to
					elseif k == "Thickness" then return thick
					elseif k == "Visible" then return f.Visible
					elseif k == "Color" then return f.BackgroundColor3 end
					return nil
				end,
				__newindex = function(_, k, v)
					if k == "From" then
						if v ~= from then from = v redraw() end
					elseif k == "To" then
						if v ~= to then to = v redraw() end
					elseif k == "Thickness" then
						if v ~= thick then thick = v redraw() end
					elseif k == "Visible" then
						v = v and true or false
						if v ~= f.Visible then f.Visible = v end
					elseif k == "Color" then
						if v ~= f.BackgroundColor3 then f.BackgroundColor3 = v end
					end
				end,
			})
		end
	end
end
local function createESP(player)
	if player == LocalPlayer then return end
	local lines = {}
	for i = 1, 14 do
		local line = EXEC.line()
		line.Thickness = 1.8
		line.Visible = false
		table.insert(lines, line)
	end
	drawings[player] = {lines = lines}
end
local function removeESP(player)
	local data = drawings[player]
	if not data then return end
	for _, line in ipairs(data.lines) do pcall(function() line:Remove() end) end
	drawings[player] = nil
end
local espCleared = true
local function updateESP()
	if not UNLOCKED or not ESP_ENABLED then
		if espCleared then return end
		for _, data in pairs(drawings) do
			for _, line in ipairs(data.lines) do line.Visible = false end
		end
		espCleared = true
		return
	end
	espCleared = false
	for player, data in pairs(drawings) do
		for _, line in ipairs(data.lines) do line.Visible = false end
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if char and humanoid and root and humanoid.Health > 0 then
			local color = INNOCENT_COLOR
			if player == cachedMurderer then color = MURDERER_COLOR
			elseif player == cachedSheriff then color = SHERIFF_COLOR end
			local connections = char:FindFirstChild("UpperTorso") and R15_CONNECTIONS or R6_CONNECTIONS
			local i = 1
			for _, conn in ipairs(connections) do
				local p0 = char:FindFirstChild(conn[1])
				local p1 = char:FindFirstChild(conn[2])
				if p0 and p1 then
					local pos0, on0 = Camera:WorldToViewportPoint(p0.Position)
					local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
					if on0 and on1 and i <= #data.lines then
						local line = data.lines[i]
						line.From    = Vector2.new(pos0.X, pos0.Y)
						line.To      = Vector2.new(pos1.X, pos1.Y)
						line.Color   = color
						line.Visible = true
						i += 1
					end
				end
			end
		end
	end
end
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
do
	local lastESP, lastCard = 0, 0
	local espStep = EXEC.mobile and (1 / 30) or 0
	RunService.RenderStepped:Connect(function()
		if not ALIVE then return end
		local now = tick()
		if now - lastESP >= espStep then
			lastESP = now
			updateESP()
		end
		if now - lastCard >= 0.16 then
			lastCard = now
			updateTargetUI()
		end
	end)
end
if EXEC.keys then
	UserInputService.InputBegan:Connect(function(input, gp)
		if not ALIVE or gp then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			toggleUI()
		end
		if not UNLOCKED then return end
		if input.KeyCode == Enum.KeyCode.Q then setWalkSpeed(WalkSpeed - SpeedStep) end
		if input.KeyCode == Enum.KeyCode.E then setWalkSpeed(WalkSpeed + SpeedStep) end
		if input.KeyCode == Enum.KeyCode.T then startFling() end
		if input.KeyCode == Enum.KeyCode.G then killAll() end
		if input.KeyCode == Enum.KeyCode.F then tpToGun() end
		if input.KeyCode == Enum.KeyCode.N then
			NOCLIP_ENABLED = not NOCLIP_ENABLED
			if UI.noclipRefresh then pcall(UI.noclipRefresh) end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.T then stopFling() end
	end)
end
showTab("combat")
deviceScale.Scale = UI.scale * 0.88
TweenService:Create(deviceScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{Scale = UI.scale}):Play()
EXEC.env.MM2_UNDETECTED.unload = function()
	ALIVE            = false
	ESP_ENABLED      = false
	AUTOFARM_ENABLED = false
	pcall(stopFling)
	pcall(function() disableFarmFly(LocalPlayer.Character) end)
	for player in pairs(drawings) do pcall(removeESP, player) end
	pcall(function() screenGui:Destroy() end)
	pcall(function() if EXEC.espGui then EXEC.espGui:Destroy() end end)
end
