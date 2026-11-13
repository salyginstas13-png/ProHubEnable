repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

repeat task.wait() until Players.LocalPlayer and workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local function getUiParent()
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local okCore, cg = pcall(function() return CoreGui end)
	if okCore and cg then return cg end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function unwrapValue(v)
	if type(v) == "table" then return v.Value or v.Default or v[1] end
	return v
end

local function safeDrawing(c)
	local ok, o = pcall(function()
		if type(Drawing) == "table" and type(Drawing.new) == "function" then return Drawing.new(c) end
	end)
	if ok and o then return o end
	return {Visible=false,Color=Color3.new(1,1,1),Radius=150,Position=Vector2.zero,From=Vector2.zero,To=Vector2.zero,Thickness=1.5,Transparency=1,Filled=false,NumSides=64,Remove=function()end}
end

local THEMES = {
	Black = {Accent=Color3.fromRGB(150,150,150),Outline=Color3.fromRGB(50,50,60),Background=Color3.fromRGB(16,16,20),ButtonTop=Color3.fromRGB(30,30,35),ButtonBot=Color3.fromRGB(15,15,20)},
	Purple = {Accent=Color3.fromRGB(185,85,255),Outline=Color3.fromRGB(120,50,180),Background=Color3.fromRGB(28,14,42),ButtonTop=Color3.fromRGB(130,45,200),ButtonBot=Color3.fromRGB(55,18,95)},
	Red = {Accent=Color3.fromRGB(255,65,80),Outline=Color3.fromRGB(170,40,50),Background=Color3.fromRGB(42,12,16),ButtonTop=Color3.fromRGB(190,35,50),ButtonBot=Color3.fromRGB(85,15,22)}
}

pcall(function()
	for n, d in pairs(THEMES) do
		WindUI:AddTheme({
			Name = "ProHub_"..n, Accent = d.Accent, Outline = d.Outline, Background = d.Background,
			Text = Color3.fromRGB(245,245,250), Placeholder = Color3.fromRGB(150,150,160), PlaceholderText = Color3.fromRGB(150,150,160),
			Button = d.ButtonTop, Icon = Color3.fromRGB(220,220,230), Dialog = d.Background, Tab = d.ButtonBot
		})
	end
end)

local okWin, Window = pcall(function()
	return WindUI:CreateWindow({
		Title = "ProHub", Icon = "zap", Author = "Murder Mystery 2", Folder = "ProHub",
		Size = UDim2.fromOffset(520, 360), Theme = "Dark", Transparent = true, Acrylic = false
	})
end)
if not okWin or not Window then
	Window = WindUI:CreateWindow({Title = "ProHub", Icon = "zap", Author = "Murder Mystery 2", Size = UDim2.fromOffset(520, 360)})
end

local function elevateMenuDisplayOrder()
	pcall(function()
		local conts = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
		if type(gethui) == "function" then pcall(function() table.insert(conts, gethui()) end) end
		for _, c in ipairs(conts) do
			for _, sg in ipairs(c:GetChildren()) do
				if sg:IsA("ScreenGui") and sg.Name ~= "ProHub_OverlayButtons" and sg.DisplayOrder < 50 then
					sg.DisplayOrder = 50
				end
			end
		end
	end)
end

local function applyMenuTheme(themeName)
	local t = THEMES[themeName] or THEMES.Black
	pcall(function() WindUI:SetTheme("ProHub_"..themeName) end)
	pcall(function()
		Window:EditOpenButton({
			Title = "ProHub", Icon = "zap", CornerRadius = UDim.new(1, 0), StrokeThickness = 2,
			Color = ColorSequence.new(t.ButtonTop, t.ButtonBot), Draggable = true
		})
	end)
	pcall(function()
		local conts = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
		if type(gethui) == "function" then pcall(function() table.insert(conts, gethui()) end) end
		for _, c in ipairs(conts) do
			for _, g in ipairs(c:GetDescendants()) do
				if g:IsA("Frame") and g.Size.X.Offset == 520 and g.Size.Y.Offset == 360 then
					g.BackgroundColor3 = t.Background
					g.BackgroundTransparency = 0.15
					local sg = g:FindFirstAncestorOfClass("ScreenGui")
					if sg then sg.DisplayOrder = 100 end
				end
			end
		end
	end)
	elevateMenuDisplayOrder()
end
applyMenuTheme("Black")

local Tabs = {
	Teleports = Window:Tab({Title="Teleports",Icon="map-pin"}),
	Movement = Window:Tab({Title="Movement",Icon="move"}),
	Combat = Window:Tab({Title="Combat",Icon="sword"}),
	Buttons = Window:Tab({Title="Buttons",Icon="layers"}),
	Visuals = Window:Tab({Title="Visuals",Icon="eye"}),
	AutoFarm = Window:Tab({Title="AutoFarm",Icon="coins"}),
	Fling = Window:Tab({Title="Fling",Icon="wind"}),
	Misc = Window:Tab({Title="Misc",Icon="wrench"}),
	Settings = Window:Tab({Title="Settings",Icon="settings"})
}

local S = {
	ClickTP=false,TouchFling=false,TouchFlingPower=50000,AntiFling=false,SelectedFlingPlayer="",
	KillAllMode=1,AutoGun=false,AutoWin=false,Trail=false,TrailLifetime=0.5,JumpCircle=false,Aura=false,Pentagram=false,
	StarHalo=false,OrbitOrbs=false,FootstepRings=false,
	FovSize=70,ESP_Roles=false,ESP_Tracers=false,ESP_Skeletons=false,ESP_Candyes=false,ESP_GunDrop=false,
	WeaponChams=false,SelfGhost=false,RainbowVisuals=false,Fullbright=false,ThirdPerson=false,UserTag=false,
	EnableCamlock=false,CamlockMode="Torso",CamlockSmoothness=1,CamlockPrediction=25,
	EnableAimbot=false,AimbotMode="Torso",ShowFovAimbot=false,RainbowAimbotCircle=false,AimbotRadius=150,AimbotSmoothness=1,AimbotPrediction=20,
	EnableNight=false,Fly=false,FlySpeed=50,
	WalkSpeed=16,JumpPower=50,EnableAirJump=false,EnableNoclip=false,SpeedGlitch=false,SpinBot=false,SpinSpeed=20,
	EnableShaders=false,Theme="Black",AutoFarm=false,AutoFarmMode=2,FarmPosition=2,
	WalkFarmSpeed=26,FlyFarmSpeed=24,AntiAfk=false,
	TriggerBot=false,KillAura=false,KillAuraRange=25,
	ThrowKnifeAura=false,HitboxExpander=false,HitboxSize=14,HitboxTransparency=0.65,
	AntiMurderDodge=false,DodgeDistance=15,AntiKnifeThrow=false,KnifeReach=false,KnifeReachSize=18,
	HideBtnsWithMenu=true,BtnCamlock=false,BtnSpeedGlitch=false,BtnFlingMurder=false,BtnFlingSheriff=false,
	BtnKillAll=false,BtnGrabGun=false,BtnFly=false,BtnNoclip=false,BtnSpinBot=false,BtnFarm=false,BtnEsp=false
}

local COLORS = {
	Murderer=Color3.fromRGB(255,70,90),
	Sheriff=Color3.fromRGB(70,160,255),
	Innocent=Color3.fromRGB(70,230,130),
	CandyFill=Color3.fromRGB(255,215,0),
	CandyOutline=Color3.fromRGB(255,255,0),
	GunDrop=Color3.fromRGB(80,255,150)
}

local activeUsers = {[LocalPlayer.UserId] = true}
local commRemote = ReplicatedStorage:FindFirstChild("SakuraHub_UserSync")
if commRemote and commRemote:IsA("RemoteEvent") then
	pcall(function() commRemote.OnClientEvent:Connect(function(u) if type(u) == "number" then activeUsers[u] = true end end) end)
	task.spawn(function()
		while commRemote and commRemote.Parent do
			pcall(function() commRemote:FireServer(LocalPlayer.UserId) end)
			task.wait(5)
		end
	end)
end

local function getDynamicColor(baseColor)
	if S.RainbowVisuals then return Color3.fromHSV((tick() * 0.38) % 1, 0.85, 1) end
	return baseColor
end

local function getObservedCharacter()
	local subj = Camera and Camera.CameraSubject
	if subj then
		if subj:IsA("Humanoid") and subj.Parent and subj.Parent:IsA("Model") then return subj.Parent
		elseif subj:IsA("BasePart") and subj.Parent and subj.Parent:IsA("Model") then return subj.Parent
		elseif subj:IsA("Model") then return subj end
	end
	return LocalPlayer.Character
end

local function getObservedHead()
	local obsChar = getObservedCharacter()
	if obsChar then
		local h = obsChar:FindFirstChild("Head") or obsChar:FindFirstChild("HumanoidRootPart")
		if h then return h, obsChar end
	end
	local myCh = LocalPlayer.Character
	return myCh and (myCh:FindFirstChild("Head") or myCh:FindFirstChild("HumanoidRootPart")), myCh
end

local function isShiftLockOrFirstPerson()
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then return true end
	if Camera and (Camera.CFrame.Position - Camera.Focus.Position).Magnitude <= 1.6 then return true end
	local obsHead = getObservedHead()
	if obsHead and Camera and (Camera.CFrame.Position - obsHead.Position).Magnitude <= 1.75 then return true end
	return false
end

local function spawnSurfaceRing(pos, col, endSize, duration)
	pcall(function()
		local p = Instance.new("Part", workspace)
		p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false
		p.Transparency = 1 p.Size = Vector3.new(1.0, 0.05, 1.0)
		p.CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0))
		for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
			local sg = Instance.new("SurfaceGui", p)
			sg.Face = face sg.CanvasSize = Vector2.new(256, 256) sg.LightInfluence = 0
			local fr = Instance.new("Frame", sg)
			fr.AnchorPoint = Vector2.new(0.5, 0.5) fr.Position = UDim2.fromScale(0.5, 0.5)
			fr.Size = UDim2.fromScale(0.88, 0.88) fr.BackgroundColor3 = col fr.BackgroundTransparency = 0.74
			Instance.new("UICorner", fr).CornerRadius = UDim.new(1, 0)
			local st = Instance.new("UIStroke", fr)
			st.Color = col st.Thickness = 7 st.Transparency = 0.05
			TweenService:Create(fr, TweenInfo.new(duration), {BackgroundTransparency = 1}):Play()
			TweenService:Create(st, TweenInfo.new(duration), {Transparency = 1, Thickness = 1}):Play()
		end
		TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(endSize, 0.05, endSize)}):Play()
		task.delay(duration + 0.05, function() if p and p.Parent then p:Destroy() end end)
	end)
end

local function spawnJumpCircle(roleCol)
	local ch = LocalPlayer.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {ch}
	local res = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rp)
	local pos = res and res.Position or (hrp.Position - Vector3.new(0, 2.8, 0))
	spawnSurfaceRing(pos, getDynamicColor(roleCol or Color3.fromRGB(220, 245, 255)), 8.2, 0.55)
end

local lastFootstepTime = 0
local function updateFootstepRings(ch, roleCol)
	if (tick() - lastFootstepTime) < 0.22 then return end
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.MoveDirection.Magnitude < 0.1 or hum.FloorMaterial == Enum.Material.Air then return end
	lastFootstepTime = tick()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {ch}
	local res = workspace:Raycast(hrp.Position, Vector3.new(0, -5, 0), rp)
	local pos = res and res.Position or (hrp.Position - Vector3.new(0, 2.8, 0))
	spawnSurfaceRing(pos, getDynamicColor(roleCol), 3.6, 0.42)
end

local auraObjs = {}
local function clearAura()
	for _, v in ipairs(auraObjs) do pcall(function() v:Destroy() end) end
	table.clear(auraObjs)
end

local function ensureAura(ch)
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local head = ch:FindFirstChild("Head")
	if not hrp or not head then return end
	if hrp:FindFirstChild("ProHub_AuraLight") and ch:FindFirstChild("ProHub_AuraFloor") then return end
	clearAura()
	pcall(function()
		local pl = Instance.new("PointLight", hrp)
		pl.Name = "ProHub_AuraLight" pl.Color = Color3.fromRGB(130, 220, 255) pl.Brightness = 2.5 pl.Range = 11
		pl.Enabled = not S.JumpCircle
		table.insert(auraObjs, pl)

		local fp = Instance.new("Part", ch)
		fp.Name = "ProHub_AuraFloor" fp.Anchored = false fp.CanCollide = false fp.CanQuery = false fp.Massless = true
		fp.Transparency = 1 fp.Size = Vector3.new(6.8, 0.05, 6.8)
		fp.CFrame = hrp.CFrame * CFrame.new(0, -2.85, 0)
		local fw = Instance.new("WeldConstraint", fp) fw.Part0 = hrp fw.Part1 = fp
		for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
			local fsg = Instance.new("SurfaceGui", fp)
			fsg.Face = face fsg.CanvasSize = Vector2.new(320, 320) fsg.LightInfluence = 0
			local glw = Instance.new("Frame", fsg)
			glw.Name = "AuraGlow" glw.AnchorPoint = Vector2.new(0.5, 0.5) glw.Position = UDim2.fromScale(0.5, 0.5)
			glw.Size = UDim2.fromScale(0.65, 0.65) glw.BackgroundColor3 = Color3.fromRGB(130, 225, 255) glw.BackgroundTransparency = 0.62
			glw.Visible = not S.JumpCircle
			Instance.new("UICorner", glw).CornerRadius = UDim.new(1, 0)
			for i = 1, 4 do
				local r = Instance.new("Frame", fsg)
				r.AnchorPoint = Vector2.new(0.5, 0.5) r.Position = UDim2.fromScale(0.5, 0.5)
				local sc = 0.94 - (i - 1) * 0.19
				r.Size = UDim2.fromScale(sc, sc) r.BackgroundTransparency = 1
				Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)
				local rst = Instance.new("UIStroke", r)
				rst.Thickness = 7 - i rst.Color = Color3.fromRGB(185, 240, 255)
				local gr = Instance.new("UIGradient", rst)
				gr.Color = ColorSequence.new(Color3.fromRGB(95, 205, 255), Color3.fromRGB(255, 255, 255))
				gr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.15), NumberSequenceKeypoint.new(0.8, 0.75), NumberSequenceKeypoint.new(1, 0.95)})
			end
		end
		table.insert(auraObjs, fp)

		local hp = Instance.new("Part", ch)
		hp.Name = "ProHub_AuraHalo" hp.Anchored = false hp.CanCollide = false hp.CanQuery = false hp.Massless = true
		hp.Transparency = 1 hp.Size = Vector3.new(3.1, 0.05, 3.1)
		hp.CFrame = head.CFrame * CFrame.new(0, 1.15, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-15))
		local hw = Instance.new("WeldConstraint", hp) hw.Part0 = head hw.Part1 = hp
		for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
			local hsg = Instance.new("SurfaceGui", hp)
			hsg.Face = face hsg.AlwaysOnTop = true hsg.CanvasSize = Vector2.new(240, 240) hsg.LightInfluence = 0
			for i = 1, 2 do
				local hr = Instance.new("Frame", hsg)
				hr.AnchorPoint = Vector2.new(0.5, 0.5) hr.Position = UDim2.fromScale(0.5, 0.5)
				local sc = i == 1 and 0.84 or 0.72
				hr.Size = UDim2.fromScale(sc, sc) hr.BackgroundTransparency = 1
				Instance.new("UICorner", hr).CornerRadius = UDim.new(1, 0)
				local hst = Instance.new("UIStroke", hr)
				hst.Thickness = i == 1 and 8 or 4
				hst.Color = i == 1 and Color3.fromRGB(240, 252, 255) or Color3.fromRGB(125, 220, 255)
				local hgr = Instance.new("UIGradient", hst)
				hgr.Color = ColorSequence.new(Color3.fromRGB(130, 225, 255), Color3.fromRGB(255, 255, 255))
				hgr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.1), NumberSequenceKeypoint.new(1, 0.65)})
			end
		end
		table.insert(auraObjs, hp)
	end)
end

local orbitOrbParts = {}
local function clearOrbitOrbs()
	for _, v in ipairs(orbitOrbParts) do pcall(function() v:Destroy() end) end
	table.clear(orbitOrbParts)
end

local function updateOrbitOrbs(ch)
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if #orbitOrbParts ~= 3 or not orbitOrbParts[1] or orbitOrbParts[1].Parent ~= ch then
		clearOrbitOrbs()
		for i = 1, 3 do
			local orb = Instance.new("Part", ch)
			orb.Name = "ProHub_OrbitOrb" .. i
			orb.Shape = Enum.PartType.Ball
			orb.Size = Vector3.new(1.15, 1.15, 1.15)
			orb.Material = Enum.Material.Neon
			orb.Anchored = true orb.CanCollide = false orb.CanQuery = false orb.CanTouch = false
			orbitOrbParts[i] = orb
		end
	end
	local t = tick() * 2.8
	local baseHue = (tick() * 0.42) % 1
	for i = 1, 3 do
		local orb = orbitOrbParts[i]
		if orb and orb.Parent then
			local ang = t + (i - 1) * ((math.pi * 2) / 3)
			orb.Position = hrp.Position + Vector3.new(math.cos(ang) * 3.6, math.sin(t * 1.7 + i) * 1.15, math.sin(ang) * 3.6)
			orb.Color = Color3.fromHSV((baseHue + (i - 1) / 3) % 1, 0.88, 1)
		end
	end
end

local function getLobbyCFrame()
	local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("LobbyMap") or workspace:FindFirstChild("LobbyModel")
	if lobby then
		local sp = lobby:FindFirstChild("Spawns") or lobby:FindFirstChild("SpawnLocation") or lobby:FindFirstChild("Spawn")
		local p = (sp and (sp:IsA("BasePart") and sp or sp:FindFirstChildWhichIsA("BasePart"))) or (lobby:IsA("BasePart") and lobby or lobby:FindFirstChildWhichIsA("BasePart"))
		if p then return p.CFrame end
	end
	for _, o in ipairs(workspace:GetDescendants()) do
		if (o.Name == "Lobby" or o.Name == "LobbySpawn") and o:IsA("BasePart") then return o.CFrame end
	end
	return nil
end

local function getMapCFrame()
	local c = workspace:FindFirstChild("CoinContainer", true)
	if c and c.Parent then
		local p = c.Parent:FindFirstChildWhichIsA("BasePart", true)
		if p then return p.CFrame end
	end
	for _, o in ipairs(workspace:GetChildren()) do
		local n = o.Name:lower()
		if o:IsA("Model") and n ~= "lobby" and n ~= "camera" and not n:find("lobby") then
			local p = o:FindFirstChildWhichIsA("BasePart", true)
			if p then return p.CFrame end
		end
	end
	return nil
end

local function isInLobby(ch)
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local lcf = getLobbyCFrame()
	if not lcf then return false end
	local diff = hrp.Position - lcf.Position
	return Vector2.new(diff.X, diff.Z).Magnitude < 75 and math.abs(diff.Y) < 35
end

local predictedRoles = {}
local function parseRoleTable(tbl)
	if type(tbl) ~= "table" then return end
	local nextRoles, foundAnyRole = {}, false
	for k, v in pairs(tbl) do
		if type(v) == "table" and type(v.Role) == "string" then
			foundAnyRole = true
			local r = (v.Role == "Hero") and "Sheriff" or v.Role
			nextRoles[tostring(k)] = (v.Dead or v.Killed or r == "Innocent") and "Innocent" or r
		elseif type(v) == "string" and (v == "Murderer" or v == "Sheriff" or v == "Hero" or v == "Innocent") then
			foundAnyRole = true
			local pName = typeof(k) == "Instance" and k.Name or tostring(k)
			nextRoles[pName] = (v == "Hero") and "Sheriff" or v
		end
	end
	if foundAnyRole then predictedRoles = nextRoles end
end

pcall(function()
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			local n = obj.Name:lower()
			if n:find("playerdata") or n:find("role") or n:find("round") or n:find("start") or n:find("update") or n:find("end") then
				obj.OnClientEvent:Connect(function(a, b)
					if n:find("end") or n:find("victory") or n:find("gameover") then table.clear(predictedRoles) return end
					if type(a) == "table" then parseRoleTable(a)
					elseif type(b) == "table" then parseRoleTable(b)
					elseif type(a) == "string" and (a == "Murderer" or a == "Sheriff" or a == "Hero" or a == "Innocent") then
						predictedRoles[LocalPlayer.Name] = (a == "Hero") and "Sheriff" or a
					end
				end)
			end
		end
	end
end)

local function hookRespawnReset(p)
	p.CharacterAdded:Connect(function() predictedRoles[p.Name] = nil end)
end
for _, p in ipairs(Players:GetPlayers()) do hookRespawnReset(p) end
Players.PlayerAdded:Connect(hookRespawnReset)

task.spawn(function()
	local getDataRemote = nil
	while true do
		task.wait(0.4)
		pcall(function()
			if not getDataRemote or not getDataRemote.Parent then
				getDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
			end
			if getDataRemote and getDataRemote:IsA("RemoteFunction") then
				local ok, data = pcall(function() return getDataRemote:InvokeServer() end)
				if ok and type(data) == "table" then parseRoleTable(data) end
			end
		end)
	end
end)

local function findWeaponTool(container, roleType)
	if not container then return nil end
	for _, item in ipairs(container:GetChildren()) do
		if item:IsA("Tool") then
			local n = item.Name:lower()
			if roleType == "Murderer" and (n == "knife" or n:find("knife") or n:find("blade") or n:find("scythe") or item:FindFirstChild("Stab", true)) then
				return item
			elseif roleType == "Sheriff" and (n == "gun" or n == "revolver" or n:find("gun") or n:find("revolver") or item:FindFirstChild("Shoot", true) or item:FindFirstChild("CreateBeam", true)) then
				return item
			end
		end
	end
	return nil
end

local function hasWeaponType(container, roleType)
	return findWeaponTool(container, roleType) ~= nil
end

local function getRoleSafe(p)
	if not p or not p.Character then return "Innocent" end
	local ch, bp = p.Character, p:FindFirstChild("Backpack")
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return "Innocent" end
	if hasWeaponType(ch, "Murderer") or hasWeaponType(bp, "Murderer") then return "Murderer"
	elseif hasWeaponType(ch, "Sheriff") or hasWeaponType(bp, "Sheriff") then return "Sheriff" end
	local atRole = p:GetAttribute("Role") or ch:GetAttribute("Role")
	if type(atRole) == "string" then
		if atRole == "Murderer" then return "Murderer"
		elseif atRole == "Sheriff" or atRole == "Hero" then return "Sheriff" end
	end
	local pred = predictedRoles[p.Name]
	if pred == "Murderer" or pred == "Sheriff" then return pred end
	return "Innocent"
end

local function getTargetPartByMode(ch, mode)
	if not ch then return nil end
	if mode == "Torso" then
		return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")
	end
	return ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
end

local trackedVel = setmetatable({}, {__mode = "k"})
local trackedLastPos = setmetatable({}, {__mode = "k"})

RunService.Heartbeat:Connect(function(dt)
	if dt <= 0 then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local curPos = hrp.Position
				local lastPos = trackedLastPos[hrp]
				if lastPos then
					local rawDeltaVel = (curPos - lastPos) / dt
					if rawDeltaVel.Magnitude < 250 then
						local prevVel = trackedVel[hrp] or rawDeltaVel
						trackedVel[hrp] = prevVel:Lerp(rawDeltaVel, 0.45)
					end
				end
				trackedLastPos[hrp] = curPos
			end
		end
	end
end)

local function getPredictedPosition(targetPart, predSetting)
	if not targetPart then return nil end
	local ch = targetPart.Parent
	local hrp = (ch and ch:FindFirstChild("HumanoidRootPart")) or targetPart
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local vel = trackedVel[hrp] or Vector3.zero
	if vel.Magnitude < 0.5 then vel = hrp.AssemblyLinearVelocity end
	if vel.Magnitude < 0.5 and hum and hum.MoveDirection.Magnitude > 0 then
		vel = hum.MoveDirection * (hum.WalkSpeed > 0 and hum.WalkSpeed or 16)
	end
	local ping = 0
	pcall(function() ping = math.clamp(LocalPlayer:GetNetworkPing(), 0, 0.3) end)
	local totalPred = ((tonumber(predSetting) or 25) / 100) + (ping * 0.6)
	return targetPart.Position + Vector3.new(vel.X * totalPred, math.clamp(vel.Y * (totalPred * 0.4), -6, 8), vel.Z * totalPred)
end

local function getMurderer()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and getRoleSafe(p) == "Murderer" then
			local hrp, hum = p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then return p.Character, p end
		end
	end
	return nil, nil
end

local function getSheriff()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and getRoleSafe(p) == "Sheriff" then
			local hrp, hum = p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then return p.Character, p end
		end
	end
	return nil, nil
end

local camlockBeam, camlockAtt0, camlockAtt1 = nil, nil, nil
local function clearCamlockBeam()
	if camlockBeam then pcall(function() camlockBeam:Destroy() end) camlockBeam = nil end
	if camlockAtt0 then pcall(function() camlockAtt0:Destroy() end) camlockAtt0 = nil end
	if camlockAtt1 then pcall(function() camlockAtt1:Destroy() end) camlockAtt1 = nil end
end

local function updateCamlockBeam(sourceHead, targetPart)
	if not sourceHead or not targetPart or sourceHead == targetPart or sourceHead:IsDescendantOf(targetPart.Parent) then
		clearCamlockBeam()
		return
	end
	if not camlockAtt0 or camlockAtt0.Parent ~= sourceHead then
		if camlockAtt0 then pcall(function() camlockAtt0:Destroy() end) end
		camlockAtt0 = Instance.new("Attachment", sourceHead)
		camlockAtt0.Name = "ProHub_CamlockAtt0"
	end
	if not camlockAtt1 or camlockAtt1.Parent ~= targetPart then
		if camlockAtt1 then pcall(function() camlockAtt1:Destroy() end) end
		camlockAtt1 = Instance.new("Attachment", targetPart)
		camlockAtt1.Name = "ProHub_CamlockAtt1"
	end
	if not camlockBeam or not camlockBeam.Parent then
		if camlockBeam then pcall(function() camlockBeam:Destroy() end) end
		camlockBeam = Instance.new("Beam", workspace)
		camlockBeam.Name = "ProHub_CamlockBeam"
		camlockBeam.FaceCamera = true
		camlockBeam.Color = ColorSequence.new(Color3.fromRGB(255, 35, 35))
		camlockBeam.LightEmission = 1 camlockBeam.LightInfluence = 0
		camlockBeam.Transparency = NumberSequence.new(0.05)
		camlockBeam.Width0 = 0.14 camlockBeam.Width1 = 0.14
	end
	camlockBeam.Attachment0 = camlockAtt0
	camlockBeam.Attachment1 = camlockAtt1
end

local aimbotCircle = safeDrawing("Circle")
aimbotCircle.Visible = false aimbotCircle.Thickness = 1.5 aimbotCircle.NumSides = 64
aimbotCircle.Radius = S.AimbotRadius aimbotCircle.Filled = false
aimbotCircle.Color = Color3.fromRGB(255, 255, 255) aimbotCircle.Transparency = 0.8

local function isVisible(tp, customOriginPart)
	local ch = LocalPlayer.Character
	if not ch or not tp then return false end
	local orig = (customOriginPart and customOriginPart.Position) or (ch:FindFirstChild("Head") and ch.Head.Position) or (Camera and Camera.CFrame.Position)
	if not orig then return false end
	local flt = {ch, tp.Parent}
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.IgnoreWater = true
	for _ = 1, 10 do
		rp.FilterDescendantsInstances = flt
		local res = workspace:Raycast(orig, tp.Position - orig, rp)
		if not res or res.Instance:IsDescendantOf(tp.Parent) then return true end
		if res.Instance.Transparency >= 0.9 or not res.Instance.CanCollide then table.insert(flt, res.Instance) else return false end
	end
	return true
end

local function applyShaders()
	pcall(function()
		local cc = Lighting:FindFirstChild("ProHub_CC")
		local bl = Lighting:FindFirstChild("ProHub_Bloom")
		if S.EnableShaders then
			if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) cc.Name = "ProHub_CC" end
			cc.Saturation = 0.28 cc.Contrast = 0.22
			if not bl then bl = Instance.new("BloomEffect", Lighting) bl.Name = "ProHub_Bloom" end
			bl.Intensity = 1.15 bl.Size = 28 bl.Threshold = 1.65
		else
			if cc then cc:Destroy() end if bl then bl:Destroy() end
		end
	end)
end

local function SafeTeleport(cf)
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = cf + Vector3.new(0, 3, 0)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and S.ClickTP and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and Mouse and Mouse.Hit then
		SafeTeleport(CFrame.new(Mouse.Hit.Position))
	end
end)

local isKillingAll, isFlingingTarget, isPickingUpGun = false, false, false

local function grabDroppedGunOnce()
	if isPickingUpGun or isFlingingTarget or getRoleSafe(LocalPlayer) == "Murderer" then return false end
	local ch = LocalPlayer.Character
	local hum, hrp = ch and ch:FindFirstChildOfClass("Humanoid"), ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp or not hum or hum.Health <= 0 or isInLobby(ch) then return false end
	local drop = workspace:FindFirstChild("GunDrop", true)
	local gp = drop and (drop:IsA("BasePart") and drop or (drop:IsA("Model") and (drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart"))))
	if gp and gp.Parent and gp.Position.Y > -10 then
		isPickingUpGun = true
		task.spawn(function()
			hrp.Anchored = false
			local orig = hrp.CFrame
			hrp.CFrame = gp.CFrame + Vector3.new(0, 2, 0)
			if type(firetouchinterest) == "function" then
				pcall(function() firetouchinterest(hrp, gp, 0) firetouchinterest(hrp, gp, 1) end)
			end
			task.wait(0.25)
			if hrp and hrp.Parent and hum.Health > 0 then hrp.CFrame = orig end
			task.wait(0.45)
			isPickingUpGun = false
		end)
		return true
	end
	return false
end

local lastTriggerTime = 0
RunService.RenderStepped:Connect(function()
	if not S.TriggerBot or (tick() - lastTriggerTime) < 0.18 then return end
	local ch = LocalPlayer.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not hrp or not hum or hum.Health <= 0 or isInLobby(ch) then return end

	local hitPart = Mouse and Mouse.Target
	if not hitPart and Camera then
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {ch}
		local res = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 250, rp)
		hitPart = res and res.Instance
	end
	if not hitPart then return end

	local hitPlayer = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and hitPart:IsDescendantOf(p.Character) then
			local tHum = p.Character:FindFirstChildOfClass("Humanoid")
			if tHum and tHum.Health > 0 and not isInLobby(p.Character) then hitPlayer = p end
			break
		end
	end
	if not hitPlayer then return end

	if getRoleSafe(LocalPlayer) == "Murderer" then
		local knife = findWeaponTool(ch, "Murderer")
		if knife then
			lastTriggerTime = tick()
			local stab = knife:FindFirstChild("Stab") or knife:FindFirstChildWhichIsA("RemoteEvent", true)
			local h = knife:FindFirstChild("Handle") or hrp
			pcall(function() knife:Activate() end)
			if stab then pcall(function() stab:FireServer("Slash") stab:FireServer("Down") end) end
			local tHrp = hitPlayer.Character and hitPlayer.Character:FindFirstChild("HumanoidRootPart")
			if tHrp and (hrp.Position - tHrp.Position).Magnitude <= 18 and type(firetouchinterest) == "function" then
				pcall(function() firetouchinterest(tHrp, h, 0) firetouchinterest(tHrp, h, 1) end)
			end
		end
	end
end)

local function runFlingOnTargets(list)
	if isFlingingTarget or #list == 0 then return end
	local ch = LocalPlayer.Character
	local hrp, hum = ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end
	isFlingingTarget = true
	task.spawn(function()
		hrp.Anchored = false
		local origCF = hrp.CFrame
		local oldFH = workspace.FallenPartsDestroyHeight
		if oldFH ~= oldFH then oldFH = -500 end
		pcall(function()
			workspace.FallenPartsDestroyHeight = 0/0
			hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		end)

		for _, tp in ipairs(list) do
			ch = LocalPlayer.Character
			hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if not ch or not hrp or not hum or hum.Health <= 0 then break end
			hrp.Anchored = false
			local tCh = tp and tp.Character
			local tHrp = tCh and (tCh:FindFirstChild("HumanoidRootPart") or tCh:FindFirstChild("Torso") or tCh:FindFirstChild("UpperTorso"))
			local tHum = tCh and tCh:FindFirstChildOfClass("Humanoid")
			if tp and tp ~= LocalPlayer and tCh and tHrp and (not tHum or tHum.Health > 0) and tHrp.Position.Y > -80 then
				local startPos = tHrp.Position
				local t0, stepIdx = tick(), 0
				while (tick() - t0) < 1.8 and hrp.Parent and tHrp.Parent do
					if hum.Health <= 0 or (tHum and tHum.Health <= 0) then break end
					if tHrp.AssemblyLinearVelocity.Magnitude > 280 or tHrp.Position.Y < -80 or (tHrp.Position - startPos).Magnitude > 160 then break end
					stepIdx = stepIdx + 1
					local tVel = trackedVel[tHrp] or tHrp.AssemblyLinearVelocity
					local horizVel = Vector3.new(tVel.X, 0, tVel.Z)
					local sweep = math.sin(stepIdx * 1.6) * 2.2
					local predOffset = horizVel.Magnitude > 0.5 and (horizVel * 0.16 + horizVel.Unit * sweep) or Vector3.new(sweep, 0, math.cos(stepIdx * 1.6) * 2.2)
					local targetPart = tCh:FindFirstChild("UpperTorso") or tCh:FindFirstChild("Torso") or tHrp
					local fPos = targetPart.Position + predOffset + Vector3.new(0, math.sin(stepIdx * 0.9) * 0.5, 0)
					local ang = (stepIdx * 75) % 360

					hrp.CFrame = CFrame.new(fPos) * CFrame.Angles(math.rad(ang), math.rad(ang * 1.4), math.rad(ang * 0.8))
					hrp.Velocity = Vector3.new(9e7, 9e7, 9e7)
					hrp.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
					hrp.RotVelocity = Vector3.new(9e7, 9e7, 9e7)
					hrp.AssemblyAngularVelocity = Vector3.new(9e7, 9e7, 9e7)

					RunService.RenderStepped:Wait()
					if hrp and hrp.Parent then
						hrp.CFrame = origCF
						hrp.Velocity = Vector3.zero hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.RotVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero
					end
					RunService.Heartbeat:Wait()
				end
			end
		end

		pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
		if hrp and hrp.Parent then
			for _ = 1, 18 do
				if not hrp or not hrp.Parent then break end
				hrp.CFrame = origCF
				for _, pt in ipairs(ch:GetDescendants()) do
					if pt:IsA("BasePart") then
						pt.Velocity = Vector3.zero pt.AssemblyLinearVelocity = Vector3.zero
						pt.RotVelocity = Vector3.zero pt.AssemblyAngularVelocity = Vector3.zero
					end
				end
				RunService.Heartbeat:Wait()
			end
			pcall(function()
				hrp.Anchored = false hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		pcall(function() workspace.FallenPartsDestroyHeight = oldFH end)
		isFlingingTarget = false
	end)
end

local function hasAliveTargetsInMap()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local tHum = p.Character:FindFirstChildOfClass("Humanoid")
			local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
			if tHum and tHum.Health > 0 and tHrp and tHrp.Position.Y > -80 and not isInLobby(p.Character) then
				return true
			end
		end
	end
	return false
end

local function executeInstantKillAll()
	if isKillingAll then return end
	local ch = LocalPlayer.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local knife = ch and (ch:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) or findWeaponTool(ch, "Murderer") or findWeaponTool(bp, "Murderer"))
	if not knife or not hrp or not hum then return end
	local stab = knife:FindFirstChild("Stab") or knife:FindFirstChildWhichIsA("RemoteEvent", true)

	local function swingKnife()
		pcall(function() knife:Activate() end)
		if stab then pcall(function() stab:FireServer("Down") stab:FireServer("Slash") end) end
	end

	local function hitTargetOnDistance(tChar, h)
		if not tChar or not h then return end
		pcall(function()
			if type(firetouchinterest) == "function" then
				for _, partName in ipairs({"HumanoidRootPart", "UpperTorso", "Torso", "Head"}) do
					local pt = tChar:FindFirstChild(partName)
					if pt and pt:IsA("BasePart") then
						firetouchinterest(pt, h, 0)
						firetouchinterest(pt, h, 1)
					end
				end
			end
		end)
	end

	local function pullTargetToKnife(tHrp, h)
		if not tHrp or not h then return end
		pcall(function()
			tHrp.CanCollide = false
			tHrp.AssemblyLinearVelocity = Vector3.zero
			tHrp.CFrame = h.CFrame * CFrame.new(0, 0, -0.5)
			if type(firetouchinterest) == "function" then
				firetouchinterest(tHrp, h, 0)
				firetouchinterest(tHrp, h, 1)
			end
		end)
	end

	if S.KillAllMode == 3 then
		isKillingAll = true
		task.spawn(function()
			pcall(function()
				hrp.Anchored = false
				local skip = {}
				while isKillingAll do
					ch = LocalPlayer.Character
					hrp = ch and ch:FindFirstChild("HumanoidRootPart")
					hum = ch and ch:FindFirstChildOfClass("Humanoid")
					bp = LocalPlayer:FindFirstChild("Backpack")
					knife = ch and (ch:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) or findWeaponTool(ch, "Murderer") or findWeaponTool(bp, "Murderer"))
					if not hrp or not hum or hum.Health <= 0 or not knife or isInLobby(ch) then break end
					if knife.Parent == ch and bp then pcall(function() hum:UnequipTools() knife.Parent = bp end) end
					local near, sDist = nil, math.huge
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LocalPlayer and not skip[p] and p.Character then
							local tHum = p.Character:FindFirstChildOfClass("Humanoid")
							local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
							if tHum and tHum.Health > 0 and tHrp and tHrp.Position.Y > -80 and not isInLobby(p.Character) then
								local d = (hrp.Position - tHrp.Position).Magnitude
								if d < sDist then sDist = d near = p end
							end
						end
					end
					if not near then break end
					local tCh = near.Character
					local tHum = tCh:FindFirstChildOfClass("Humanoid")
					local tHrp = tCh:FindFirstChild("HumanoidRootPart")
					local f0 = tick()
					while tCh.Parent and tHum.Health > 0 and tHrp.Parent and not isInLobby(tCh) do
						if not hrp.Parent or hum.Health <= 0 or isInLobby(ch) then break end
						local d = (hrp.Position - tHrp.Position).Magnitude
						if d <= 3.5 or (tick() - f0) > 8 then break end
						local dt = RunService.Heartbeat:Wait()
						hrp.AssemblyLinearVelocity = Vector3.zero
						local step = math.min(d, math.max(tonumber(S.FlySpeed) or 50, 10) * dt)
						local np = hrp.Position + (tHrp.Position - hrp.Position).Unit * step
						hrp.CFrame = CFrame.lookAt(np, Vector3.new(tHrp.Position.X, np.Y, tHrp.Position.Z))
					end
					if tHum.Health > 0 and tHrp.Parent and not isInLobby(tCh) then
						if knife.Parent ~= ch then pcall(function() hum:EquipTool(knife) knife.Parent = ch end) task.wait(0.05) end
						stab = knife:FindFirstChild("Stab") or knife:FindFirstChildWhichIsA("RemoteEvent", true)
						local h = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
						local k0 = tick()
						while tHum.Health > 0 and tHrp.Parent and (tick() - k0) < 0.55 do
							hrp.AssemblyLinearVelocity = Vector3.zero
							hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.2)
							swingKnife()
							pullTargetToKnife(tHrp, h or hrp)
							RunService.Heartbeat:Wait()
						end
						if tHum.Health > 0 then skip[near] = true end
						if bp and knife.Parent == ch then pcall(function() hum:UnequipTools() knife.Parent = bp end) end
						task.wait(0.05)
					else
						skip[near] = true
					end
				end
			end)
			isKillingAll = false
		end)
		return
	end

	isKillingAll = true
	task.spawn(function()
		pcall(function()
			hrp.Anchored = false
			if knife.Parent == bp then hum:EquipTool(knife) task.wait(0.05) end
			stab = knife:FindFirstChild("Stab") or knife:FindFirstChildWhichIsA("RemoteEvent", true)
			local h = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart") or hrp
			swingKnife()
			local t0 = tick()
			while (tick() - t0) < 0.35 do
				swingKnife()
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character then
						local tHum = p.Character:FindFirstChildOfClass("Humanoid")
						local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
						if tHum and tHum.Health > 0 and tHrp and not isInLobby(p.Character) then
							if S.KillAllMode == 1 then hitTargetOnDistance(p.Character, h)
							else pullTargetToKnife(tHrp, h) end
						end
					end
				end
				RunService.Heartbeat:Wait()
			end
		end)
		isKillingAll = false
	end)
end

local lastKnifeThrowTime = 0
task.spawn(function()
	while true do
		task.wait(0.18)
		pcall(function()
			local ch = LocalPlayer.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local bp = LocalPlayer:FindFirstChild("Backpack")
			if not ch or not hrp or not hum or hum.Health <= 0 or isInLobby(ch) then return end

			local myRole = getRoleSafe(LocalPlayer)

			if S.AutoWin and not isKillingAll and not isFlingingTarget and not isPickingUpGun then
				if myRole == "Murderer" then
					if hasAliveTargetsInMap() then executeInstantKillAll() end
				else
					local mCh, mPlayer = getMurderer()
					if mCh and mPlayer then
						local mHrp = mCh:FindFirstChild("HumanoidRootPart")
						local mHum = mCh:FindFirstChildOfClass("Humanoid")
						if mHrp and mHum and mHum.Health > 0 and mHrp.Position.Y > -80 and not isInLobby(mCh) then
							runFlingOnTargets({mPlayer})
						end
					end
				end
			end

			if myRole == "Murderer" and not isKillingAll then
				local knife = findWeaponTool(ch, "Murderer") or findWeaponTool(bp, "Murderer")
				if knife then
					local h = knife:FindFirstChild("Handle")
					if h and h:IsA("BasePart") and S.KnifeReach then
						h.Massless = true h.CanCollide = false
						for _, p in ipairs(Players:GetPlayers()) do
							if p ~= LocalPlayer and p.Character and not isInLobby(p.Character) then
								local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
								local tHum = p.Character:FindFirstChildOfClass("Humanoid")
								if tHrp and tHum and tHum.Health > 0 and (hrp.Position - tHrp.Position).Magnitude <= S.KnifeReachSize and knife.Parent == ch then
									if type(firetouchinterest) == "function" then
										pcall(function() firetouchinterest(tHrp, h, 0) firetouchinterest(tHrp, h, 1) end)
									end
								end
							end
						end
					end

					if S.KillAura or S.ThrowKnifeAura then
						for _, p in ipairs(Players:GetPlayers()) do
							if p ~= LocalPlayer and p.Character and not isInLobby(p.Character) then
								local tHum = p.Character:FindFirstChildOfClass("Humanoid")
								local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
								if tHum and tHum.Health > 0 and tHrp then
									local dist = (hrp.Position - tHrp.Position).Magnitude
									if S.KillAura and dist <= S.KillAuraRange then
										if knife.Parent ~= ch then pcall(function() hum:EquipTool(knife) end) task.wait(0.04) end
										local handle = knife:FindFirstChild("Handle") or hrp
										local stab = knife:FindFirstChild("Stab") or knife:FindFirstChildWhichIsA("RemoteEvent", true)
										pcall(function() knife:Activate() end)
										if stab then pcall(function() stab:FireServer("Slash") stab:FireServer("Down") end) end
										if type(firetouchinterest) == "function" then
											pcall(function() firetouchinterest(tHrp, handle, 0) firetouchinterest(tHrp, handle, 1) end)
										end
									elseif S.ThrowKnifeAura and (tick() - lastKnifeThrowTime) > 0.75 and dist <= 65 and isVisible(tHrp, ch:FindFirstChild("Head") or hrp) then
										lastKnifeThrowTime = tick()
										if knife.Parent ~= ch then pcall(function() hum:EquipTool(knife) end) task.wait(0.05) end
										local throwRem = knife:FindFirstChild("Throw", true)
										if throwRem and throwRem:IsA("RemoteEvent") then
											local pred = getPredictedPosition(tHrp, 22) or tHrp.Position
											pcall(function() throwRem:FireServer(CFrame.new(hrp.Position, pred), pred) end)
										end
										break
									end
								end
							end
						end
					end
				end
			end

			if S.AntiMurderDodge and myRole ~= "Murderer" and not isFlingingTarget then
				local mCh = getMurderer()
				local mHrp = mCh and mCh:FindFirstChild("HumanoidRootPart")
				if mHrp and not isInLobby(mCh) then
					local diff = hrp.Position - mHrp.Position
					if diff.Magnitude <= S.DodgeDistance then
						local baseDir = Vector3.new(diff.X, 0, diff.Z)
						baseDir = baseDir.Magnitude > 0.1 and baseDir.Unit or Vector3.new(1, 0, 0)
						local rp = RaycastParams.new()
						rp.FilterType = Enum.RaycastFilterType.Exclude
						rp.FilterDescendantsInstances = {ch, mCh}
						local candidateDirs = {baseDir, Vector3.new(-baseDir.Z, 0, baseDir.X), Vector3.new(baseDir.Z, 0, -baseDir.X), -baseDir}
						local jumpDist = S.DodgeDistance + 12
						for _, dir in ipairs(candidateDirs) do
							local hit = workspace:Raycast(hrp.Position, dir * jumpDist, rp)
							local safeDist = hit and math.max(hit.Distance - 3, 0) or jumpDist
							if safeDist >= 7 then
								local targetPos = hrp.Position + dir * safeDist + Vector3.new(0, 1.5, 0)
								local floorCheck = workspace:Raycast(targetPos, Vector3.new(0, -18, 0), rp)
								if floorCheck then
									hrp.Anchored = false
									hrp.CFrame = CFrame.new(targetPos)
									break
								end
							end
						end
					end
				end
			end
		end)
	end
end)

local origHitboxProps = setmetatable({}, {__mode = "k"})
RunService.Stepped:Connect(function()
	pcall(function()
		local ch = LocalPlayer.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")

		if S.AntiKnifeThrow and hrp and getRoleSafe(LocalPlayer) ~= "Murderer" and not isFlingingTarget then
			for _, obj in ipairs(workspace:GetChildren()) do
				local n = obj.Name:lower()
				if n:find("knife") or n:find("blade") then
					local kp = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
					if kp and (kp.Position - hrp.Position).Magnitude <= 16 and kp.AssemblyLinearVelocity.Magnitude > 15 then
						local sideDir = kp.AssemblyLinearVelocity.Unit:Cross(Vector3.new(0, 1, 0))
						sideDir = sideDir.Magnitude > 0.1 and sideDir.Unit or Vector3.new(1, 0, 0)
						hrp.CFrame = hrp.CFrame + sideDir * 9
						break
					end
				end
			end
		end

		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
				local tHum = p.Character:FindFirstChildOfClass("Humanoid")
				if tHrp and tHum and tHum.Health > 0 and S.HitboxExpander and not isInLobby(p.Character) then
					if not origHitboxProps[tHrp] then
						origHitboxProps[tHrp] = {Size = tHrp.Size, Mat = tHrp.Material, Col = tHrp.Color}
					end
					tHrp.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
					tHrp.Transparency = S.HitboxTransparency
					tHrp.CanCollide = false tHrp.Massless = true
					tHrp.Color = COLORS[getRoleSafe(p)] or COLORS.Innocent
					tHrp.Material = Enum.Material.Neon
				elseif tHrp and origHitboxProps[tHrp] then
					tHrp.Size = origHitboxProps[tHrp].Size
					tHrp.Material = origHitboxProps[tHrp].Mat
					tHrp.Color = origHitboxProps[tHrp].Col
					tHrp.Transparency = 1 tHrp.CanCollide = false
					origHitboxProps[tHrp] = nil
				end
			end
		end

		if hrp and hrp.Anchored then hrp.Anchored = false end
	end)
end)

local overlayBtnsGui = Instance.new("ScreenGui")
overlayBtnsGui.Name = "ProHub_OverlayButtons"
overlayBtnsGui.ResetOnSpawn = false
overlayBtnsGui.DisplayOrder = -5
overlayBtnsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
overlayBtnsGui.Parent = getUiParent()

local cachedMenuFrame = nil
local function isWindUIMenuOpen()
	local ok, open = pcall(function()
		if cachedMenuFrame and cachedMenuFrame.Parent then
			return cachedMenuFrame.Visible and cachedMenuFrame.AbsoluteSize.X > 100 and cachedMenuFrame.AbsoluteSize.Y > 100
		end
		local conts = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
		if type(gethui) == "function" then pcall(function() table.insert(conts, gethui()) end) end
		for _, c in ipairs(conts) do
			for _, g in ipairs(c:GetDescendants()) do
				if g:IsA("Frame") and g.Size.X.Offset == 520 and g.Size.Y.Offset == 360 then
					cachedMenuFrame = g
					local sg = g:FindFirstAncestorOfClass("ScreenGui")
					if sg then sg.DisplayOrder = 100 end
					return g.Visible
				end
			end
		end
		return false
	end)
	return ok and open or false
end

local function makeDraggableButton(btn, onClick)
	local dragging, dragInput, dragStart, startPos, moved = false, nil, nil, nil, false
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true moved = false dragStart = input.Position startPos = btn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			if delta.Magnitude > 6 then moved = true end
			btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	btn.Activated:Connect(function()
		if not moved and onClick then onClick() end
	end)
end

local function createSquareOverlayButton(name, titleText, iconText, pos, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = name btn.Parent = overlayBtnsGui btn.Visible = false
	btn.AnchorPoint = Vector2.new(0.5, 0.5) btn.Position = pos btn.Size = UDim2.fromOffset(56, 56)
	btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20) btn.BackgroundTransparency = 0.22
	btn.Text = "" btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(90, 90, 105) stroke.Thickness = 1.6

	local title = Instance.new("TextLabel", btn)
	title.BackgroundTransparency = 1 title.Position = UDim2.fromOffset(0, 4) title.Size = UDim2.new(1, 0, 0, 13)
	title.Font = Enum.Font.GothamBold title.Text = titleText title.TextColor3 = Color3.fromRGB(240, 240, 245) title.TextSize = 10

	local icon = Instance.new("TextLabel", btn)
	icon.AnchorPoint = Vector2.new(0.5, 0.5) icon.Position = UDim2.new(0.5, 0, 0.62, 0) icon.Size = UDim2.fromOffset(30, 30)
	icon.BackgroundTransparency = 1 icon.Font = Enum.Font.GothamBlack icon.Text = iconText
	icon.TextColor3 = Color3.fromRGB(255, 255, 255) icon.TextSize = 19

	makeDraggableButton(btn, onClick)
	return btn, stroke, title, icon
end

local camlockScreenBtn = Instance.new("TextButton")
camlockScreenBtn.Name = "CamlockButton" camlockScreenBtn.Parent = overlayBtnsGui camlockScreenBtn.Visible = false
camlockScreenBtn.AnchorPoint = Vector2.new(0.5, 0.5) camlockScreenBtn.Position = UDim2.new(0.5, -160, 0, 56)
camlockScreenBtn.Size = UDim2.fromOffset(56, 56) camlockScreenBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
camlockScreenBtn.BackgroundTransparency = 0.22 camlockScreenBtn.Text = "" camlockScreenBtn.AutoButtonColor = false
Instance.new("UICorner", camlockScreenBtn).CornerRadius = UDim.new(0, 14)

local camlockBtnStroke = Instance.new("UIStroke", camlockScreenBtn)
camlockBtnStroke.Color = Color3.fromRGB(90, 90, 105) camlockBtnStroke.Thickness = 1.6

local camlockBtnTitle = Instance.new("TextLabel", camlockScreenBtn)
camlockBtnTitle.BackgroundTransparency = 1 camlockBtnTitle.Position = UDim2.fromOffset(0, 4)
camlockBtnTitle.Size = UDim2.new(1, 0, 0, 13) camlockBtnTitle.Font = Enum.Font.GothamBold
camlockBtnTitle.Text = "Camlock" camlockBtnTitle.TextColor3 = Color3.fromRGB(240, 240, 245) camlockBtnTitle.TextSize = 10

local camlockBtnSpinner = Instance.new("Frame", camlockScreenBtn)
camlockBtnSpinner.AnchorPoint = Vector2.new(0.5, 0.5) camlockBtnSpinner.Position = UDim2.new(0.5, 0, 0.62, 0)
camlockBtnSpinner.Size = UDim2.fromOffset(30, 30) camlockBtnSpinner.BackgroundTransparency = 1

local camBtnLineConfigs = {
	{Anchor = Vector2.new(0.5, 1), Pos = UDim2.new(0.5, 0, 0.5, -3), Size = UDim2.fromOffset(2.5, 9)},
	{Anchor = Vector2.new(0.5, 0), Pos = UDim2.new(0.5, 0, 0.5, 3),  Size = UDim2.fromOffset(2.5, 9)},
	{Anchor = Vector2.new(1, 0.5), Pos = UDim2.new(0.5, -3, 0.5, 0), Size = UDim2.fromOffset(9, 2.5)},
	{Anchor = Vector2.new(0, 0.5), Pos = UDim2.new(0.5, 3, 0.5, 0),  Size = UDim2.fromOffset(9, 2.5)}
}
local camBtnBars = {}
for _, cfg in ipairs(camBtnLineConfigs) do
	local bar = Instance.new("Frame", camlockBtnSpinner)
	bar.AnchorPoint = cfg.Anchor bar.Position = cfg.Pos bar.Size = cfg.Size
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) bar.BorderSizePixel = 0
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	table.insert(camBtnBars, bar)
end

local function updateCamlockBtnVisual()
	local active = S.EnableCamlock
	camlockBtnStroke.Color = active and Color3.fromRGB(255, 65, 80) or Color3.fromRGB(90, 90, 105)
	camlockBtnTitle.TextColor3 = active and Color3.fromRGB(255, 80, 95) or Color3.fromRGB(240, 240, 245)
	for _, b in ipairs(camBtnBars) do
		b.BackgroundColor3 = active and Color3.fromRGB(255, 80, 95) or Color3.fromRGB(255, 255, 255)
	end
end

makeDraggableButton(camlockScreenBtn, function()
	S.EnableCamlock = not S.EnableCamlock
	if not S.EnableCamlock then clearCamlockBeam() end
	updateCamlockBtnVisual()
end)

local speedScreenBtn, speedBtnStroke, speedBtnTitle, speedBtnIcon
local function updateSpeedBtnVisual()
	if not speedBtnStroke then return end
	local active = S.SpeedGlitch
	speedBtnStroke.Color = active and Color3.fromRGB(255, 190, 40) or Color3.fromRGB(90, 90, 105)
	speedBtnTitle.TextColor3 = active and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(240, 240, 245)
	speedBtnIcon.TextColor3 = active and Color3.fromRGB(255, 190, 40) or Color3.fromRGB(255, 185, 35)
end
speedScreenBtn, speedBtnStroke, speedBtnTitle, speedBtnIcon = createSquareOverlayButton(
	"SpeedButton", "Speed", "⚡", UDim2.new(0.5, 160, 0, 56),
	function() S.SpeedGlitch = not S.SpeedGlitch updateSpeedBtnVisual() end
)
updateSpeedBtnVisual()

local flingMurderBtn = Instance.new("TextButton")
flingMurderBtn.Name = "FlingMurderButton" flingMurderBtn.Parent = overlayBtnsGui flingMurderBtn.Visible = false
flingMurderBtn.AnchorPoint = Vector2.new(0.5, 0.5) flingMurderBtn.Position = UDim2.new(0.5, -64, 0, 43)
flingMurderBtn.Size = UDim2.fromOffset(116, 30) flingMurderBtn.BackgroundColor3 = Color3.fromRGB(55, 14, 20)
flingMurderBtn.BackgroundTransparency = 0.15 flingMurderBtn.Font = Enum.Font.GothamBold
flingMurderBtn.Text = "Fling Murder" flingMurderBtn.TextColor3 = Color3.fromRGB(255, 235, 235)
flingMurderBtn.TextSize = 12 flingMurderBtn.AutoButtonColor = false
Instance.new("UICorner", flingMurderBtn).CornerRadius = UDim.new(1, 0)

local flingMurderStroke = Instance.new("UIStroke", flingMurderBtn)
flingMurderStroke.Color = Color3.fromRGB(255, 55, 70) flingMurderStroke.Thickness = 2
makeDraggableButton(flingMurderBtn, function()
	local _, mPlayer = getMurderer()
	if mPlayer then runFlingOnTargets({mPlayer}) end
end)

local flingSheriffBtn = Instance.new("TextButton")
flingSheriffBtn.Name = "FlingSheriffButton" flingSheriffBtn.Parent = overlayBtnsGui flingSheriffBtn.Visible = false
flingSheriffBtn.AnchorPoint = Vector2.new(0.5, 0.5) flingSheriffBtn.Position = UDim2.new(0.5, 64, 0, 43)
flingSheriffBtn.Size = UDim2.fromOffset(116, 30) flingSheriffBtn.BackgroundColor3 = Color3.fromRGB(14, 32, 62)
flingSheriffBtn.BackgroundTransparency = 0.15 flingSheriffBtn.Font = Enum.Font.GothamBold
flingSheriffBtn.Text = "Fling Sheriff" flingSheriffBtn.TextColor3 = Color3.fromRGB(235, 245, 255)
flingSheriffBtn.TextSize = 12 flingSheriffBtn.AutoButtonColor = false
Instance.new("UICorner", flingSheriffBtn).CornerRadius = UDim.new(1, 0)

local flingSheriffStroke = Instance.new("UIStroke", flingSheriffBtn)
flingSheriffStroke.Color = Color3.fromRGB(65, 155, 255) flingSheriffStroke.Thickness = 2
makeDraggableButton(flingSheriffBtn, function()
	local _, sPlayer = getSheriff()
	if sPlayer then runFlingOnTargets({sPlayer}) end
end)

local killAllScreenBtn, killAllBtnStroke = createSquareOverlayButton(
	"KillAllButton", "Kill All", "🗡️", UDim2.new(0.5, -64, 0, 94),
	function() executeInstantKillAll() end
)
killAllBtnStroke.Color = Color3.fromRGB(255, 65, 80)

local grabGunScreenBtn, grabGunBtnStroke = createSquareOverlayButton(
	"GrabGunButton", "Grab Gun", "🔫", UDim2.new(0.5, 64, 0, 94),
	function() grabDroppedGunOnce() end
)
grabGunBtnStroke.Color = Color3.fromRGB(70, 165, 255)

local flyScreenBtn, flyBtnStroke, flyBtnTitle, flyBtnIcon
local function updateFlyBtnVisual()
	if not flyBtnStroke then return end
	local active = S.Fly
	flyBtnStroke.Color = active and Color3.fromRGB(80, 235, 140) or Color3.fromRGB(90, 90, 105)
	flyBtnTitle.TextColor3 = active and Color3.fromRGB(80, 235, 140) or Color3.fromRGB(240, 240, 245)
	flyBtnIcon.TextColor3 = active and Color3.fromRGB(80, 235, 140) or Color3.fromRGB(255, 255, 255)
end
flyScreenBtn, flyBtnStroke, flyBtnTitle, flyBtnIcon = createSquareOverlayButton(
	"FlyButton", "Fly", "🕊️", UDim2.new(0.5, -226, 0, 56),
	function() S.Fly = not S.Fly updateFlyBtnVisual() end
)

local noclipScreenBtn, noclipBtnStroke, noclipBtnTitle, noclipBtnIcon
local function updateNoclipBtnVisual()
	if not noclipBtnStroke then return end
	local active = S.EnableNoclip
	noclipBtnStroke.Color = active and Color3.fromRGB(185, 85, 255) or Color3.fromRGB(90, 90, 105)
	noclipBtnTitle.TextColor3 = active and Color3.fromRGB(185, 85, 255) or Color3.fromRGB(240, 240, 245)
	noclipBtnIcon.TextColor3 = active and Color3.fromRGB(185, 85, 255) or Color3.fromRGB(255, 255, 255)
end
noclipScreenBtn, noclipBtnStroke, noclipBtnTitle, noclipBtnIcon = createSquareOverlayButton(
	"NoclipButton", "Noclip", "👻", UDim2.new(0.5, 226, 0, 56),
	function() S.EnableNoclip = not S.EnableNoclip updateNoclipBtnVisual() end
)

local spinScreenBtn, spinBtnStroke, spinBtnTitle, spinBtnIcon
local function updateSpinBtnVisual()
	if not spinBtnStroke then return end
	local active = S.SpinBot
	spinBtnStroke.Color = active and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(90, 90, 105)
	spinBtnTitle.TextColor3 = active and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(240, 240, 245)
	spinBtnIcon.TextColor3 = active and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(255, 255, 255)
end
spinScreenBtn, spinBtnStroke, spinBtnTitle, spinBtnIcon = createSquareOverlayButton(
	"SpinButton", "Spin", "🌪", UDim2.new(0.5, 0, 0, 94),
	function()
		S.SpinBot = not S.SpinBot
		if not S.SpinBot and LocalPlayer.Character then
			local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if h then h.AutoRotate = true end
		end
		updateSpinBtnVisual()
	end
)
updateSpinBtnVisual()

-- КНОПКА FARM (ЧЁРНАЯ С НАДПИСЬЮ "Farm" СВЕРХУ И ЭМОДЗИ "🌾")
local farmScreenBtn, farmBtnStroke, farmBtnTitle, farmBtnIcon
local function updateFarmBtnVisual()
	if not farmBtnStroke then return end
	local active = S.AutoFarm
	farmBtnStroke.Color = active and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(90, 90, 105)
	farmBtnTitle.TextColor3 = active and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(240, 240, 245)
	farmBtnIcon.TextColor3 = active and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(255, 255, 255)
end
farmScreenBtn, farmBtnStroke, farmBtnTitle, farmBtnIcon = createSquareOverlayButton(
	"FarmButton", "Farm", "🌾", UDim2.new(0.5, -128, 0, 94),
	function()
		S.AutoFarm = not S.AutoFarm
		updateFarmBtnVisual()
	end
)
updateFarmBtnVisual()

-- КНОПКА ESP (ЧЁРНАЯ С НАДПИСЬЮ "Esp" СВЕРХУ И ЭМОДЗИ "👁")
local espScreenBtn, espBtnStroke, espBtnTitle, espBtnIcon
local function updateEspBtnVisual()
	if not espBtnStroke then return end
	local active = S.ESP_Roles
	espBtnStroke.Color = active and Color3.fromRGB(80, 240, 140) or Color3.fromRGB(90, 90, 105)
	espBtnTitle.TextColor3 = active and Color3.fromRGB(80, 240, 140) or Color3.fromRGB(240, 240, 245)
	espBtnIcon.TextColor3 = active and Color3.fromRGB(80, 240, 140) or Color3.fromRGB(255, 255, 255)
end
espScreenBtn, espBtnStroke, espBtnTitle, espBtnIcon = createSquareOverlayButton(
	"EspButton", "Esp", "👁", UDim2.new(0.5, 128, 0, 94),
	function()
		S.ESP_Roles = not S.ESP_Roles
		updateEspBtnVisual()
	end
)
updateEspBtnVisual()

LocalPlayer.Idled:Connect(function()
	if S.AntiAfk then pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.zero) end) end
end)

local activeTrail, spinAngle, wasSpinning, pentaAngle, starHaloAngle = nil, 0, false, 0, 0
local tracerLines = {}
local skeletonLines = {}

local R15_BONES = {
	{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local R6_BONES = {
	{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function hidePlayerSkeleton(p)
	if skeletonLines[p] then
		for _, ln in ipairs(skeletonLines[p]) do ln.Visible = false end
	end
end

Players.PlayerRemoving:Connect(function(p)
	predictedRoles[p.Name] = nil
	if tracerLines[p] then pcall(function() tracerLines[p]:Remove() end) tracerLines[p] = nil end
	if skeletonLines[p] then
		for _, ln in ipairs(skeletonLines[p]) do pcall(function() ln:Remove() end) end
		skeletonLines[p] = nil
	end
end)

pcall(function() RunService:UnbindFromRenderStep("ProHub_CameraLock") end)
RunService:BindToRenderStep("ProHub_CameraLock", Enum.RenderPriority.Camera.Value + 1, function()
	Camera = workspace.CurrentCamera
	if not Camera then return end
	local ch = LocalPlayer.Character

	if S.HideBtnsWithMenu then overlayBtnsGui.Enabled = not isWindUIMenuOpen() else overlayBtnsGui.Enabled = true end
	if S.BtnCamlock and camlockScreenBtn.Visible then camlockBtnSpinner.Rotation = (tick() * 140) % 360 end

	if S.EnableCamlock and getRoleSafe(LocalPlayer) ~= "Murderer" then
		local mCh = getMurderer()
		local targetPart = getTargetPartByMode(mCh, S.CamlockMode)
		local obsHead, obsChar = getObservedHead()
		local mHead = (mCh and mCh:FindFirstChild("Head")) or targetPart

		if targetPart and obsHead and mHead and obsChar ~= mCh then
			updateCamlockBeam(obsHead, mHead)
			if isShiftLockOrFirstPerson() then
				local aimPos = getPredictedPosition(targetPart, S.CamlockPrediction)
				local goalCF = CFrame.lookAt(Camera.CFrame.Position, aimPos)
				if S.CamlockSmoothness <= 1 then Camera.CFrame = goalCF
				else Camera.CFrame = Camera.CFrame:Lerp(goalCF, math.clamp(1 / S.CamlockSmoothness, 0.08, 1)) end
				if obsChar == ch and ch and ch:FindFirstChild("HumanoidRootPart") and not S.AutoFarm and not isFlingingTarget and not S.SpinBot and not S.Fly then
					local lHrp = ch.HumanoidRootPart
					local flatAim = Vector3.new(aimPos.X, lHrp.Position.Y, aimPos.Z)
					if (flatAim - lHrp.Position).Magnitude > 0.5 then
						lHrp.CFrame = CFrame.lookAt(lHrp.Position, flatAim)
					end
				end
			end
		else
			clearCamlockBeam()
		end
	else
		clearCamlockBeam()
	end

	local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	aimbotCircle.Color = S.RainbowAimbotCircle and Color3.fromHSV((tick()*0.4)%1, 1, 1) or Color3.fromRGB(255,255,255)
	if S.EnableAimbot and S.ShowFovAimbot then
		aimbotCircle.Visible = true aimbotCircle.Radius = S.AimbotRadius aimbotCircle.Position = sc
	else
		aimbotCircle.Visible = false
	end

	if S.EnableAimbot then
		local best, sDist = nil, S.AimbotRadius
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				local tp = getTargetPartByMode(p.Character, S.AimbotMode)
				if hum and hum.Health > 0 and tp then
					local sp, onS = Camera:WorldToViewportPoint(tp.Position)
					if onS and sp.Z > 0.1 then
						local d = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
						if d <= S.AimbotRadius and d < sDist and isVisible(tp) then sDist = d best = tp end
					end
				end
			end
		end
		if best then
			local aimPos = getPredictedPosition(best, S.AimbotPrediction)
			local goalCF = CFrame.lookAt(Camera.CFrame.Position, aimPos)
			if S.AimbotSmoothness <= 1 then Camera.CFrame = goalCF
			else Camera.CFrame = Camera.CFrame:Lerp(goalCF, math.clamp(1 / S.AimbotSmoothness, 0.08, 1)) end
		end
	end
end)

RunService.RenderStepped:Connect(function(delta)
	Camera = workspace.CurrentCamera
	if not Camera then return end
	if S.EnableNight then
		Lighting.ClockTime = 0 Lighting.Brightness = 0.3
	elseif S.Fullbright then
		Lighting.ClockTime = 14 Lighting.Brightness = 2.5 Lighting.FogEnd = 1e5
		Lighting.GlobalShadows = false Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
	end
	Camera.FieldOfView = S.FovSize

	if S.ThirdPerson then
		pcall(function()
			LocalPlayer.CameraMode = Enum.CameraMode.Classic
			LocalPlayer.CameraMaxZoomDistance = 400
			LocalPlayer.CameraMinZoomDistance = 0.5
		end)
	end

	local ch = LocalPlayer.Character
	if ch and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Head") then
		local hrp, hum, head = ch.HumanoidRootPart, ch:FindFirstChildOfClass("Humanoid"), ch.Head
		local myRoleCol = COLORS[getRoleSafe(LocalPlayer)] or COLORS.Innocent
		local dynRoleCol = getDynamicColor(myRoleCol)

		if S.SpinBot and not S.AutoFarm and not S.Fly and not isKillingAll and not isFlingingTarget then
			wasSpinning = true
			if hum then hum.AutoRotate = false end
			pcall(function() UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative end)
			spinAngle = (spinAngle + S.SpinSpeed) % 360
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
		elseif wasSpinning then
			wasSpinning = false
			if hum then hum.AutoRotate = true end
		end

		if S.Trail then
			if not activeTrail or activeTrail.Parent ~= hrp then
				if activeTrail then pcall(function() activeTrail:Destroy() end) end
				local att0 = hrp:FindFirstChild("VR7_TrailAtt0") or Instance.new("Attachment", hrp)
				att0.Name = "VR7_TrailAtt0"
				att0.Position = Vector3.new(0, -1, 0)

				local att1 = hrp:FindFirstChild("VR7_TrailAtt1") or Instance.new("Attachment", hrp)
				att1.Name = "VR7_TrailAtt1"
				att1.Position = Vector3.new(0, 1, 0)

				activeTrail = Instance.new("Trail")
				activeTrail.Name = "VR7_RoleTrail"
				activeTrail.Attachment0 = att0
				activeTrail.Attachment1 = att1
				activeTrail.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1)
				})
				activeTrail.Lifetime = 0.5
				activeTrail.Parent = hrp
			end
			activeTrail.Color = ColorSequence.new(dynRoleCol)
		elseif activeTrail then
			pcall(function()
				if activeTrail.Attachment0 then activeTrail.Attachment0:Destroy() end
				if activeTrail.Attachment1 then activeTrail.Attachment1:Destroy() end
				activeTrail:Destroy()
			end)
			activeTrail = nil
		end

		if S.OrbitOrbs then updateOrbitOrbs(ch)
		elseif #orbitOrbParts > 0 then clearOrbitOrbs() end

		if S.FootstepRings then updateFootstepRings(ch, dynRoleCol) end

		if S.StarHalo then
			local haloFolder = head:FindFirstChild("ProHub_StarHalo")
			if not haloFolder then
				haloFolder = Instance.new("Folder", head)
				haloFolder.Name = "ProHub_StarHalo"
				local atts = {}
				for i = 1, 10 do
					local a = Instance.new("Attachment", haloFolder)
					a.Name = "StarAtt" .. i
					atts[i] = a
				end
				for i = 1, 10 do
					local nxt = (i == 10) and atts[1] or atts[i + 1]
					local b = Instance.new("Beam", haloFolder)
					b.Attachment0 = atts[i] b.Attachment1 = nxt
					b.Width0 = 0.09 b.Width1 = 0.09 b.FaceCamera = true b.LightEmission = 1
					b.Transparency = NumberSequence.new(0)
				end
			end
			starHaloAngle = (starHaloAngle + delta * math.rad(90)) % (math.pi * 2)
			for i = 1, 10 do
				local a = haloFolder:FindFirstChild("StarAtt" .. i)
				if a then
					local r = (i % 2 == 1) and 1.35 or 0.62
					local ang = starHaloAngle + math.rad((i - 1) * 36)
					a.Position = Vector3.new(math.cos(ang) * r, 1.15, math.sin(ang) * r)
				end
			end
			for _, b in ipairs(haloFolder:GetChildren()) do
				if b:IsA("Beam") then b.Color = ColorSequence.new(dynRoleCol) end
			end
		else
			local hf = head:FindFirstChild("ProHub_StarHalo")
			if hf then hf:Destroy() end
		end

		if S.Pentagram then
			local pentaFolder = hrp:FindFirstChild("MM2_Pentagram")
			if not pentaFolder then
				pentaFolder = Instance.new("Folder", hrp)
				pentaFolder.Name = "MM2_Pentagram"
				local attachments, numPoints = {}, 20
				for i = 1, numPoints do
					local att = Instance.new("Attachment", pentaFolder)
					att.Name = "PentaAtt" .. tostring(i)
					attachments[i] = att
				end
				local function createBeam(att0, att1)
					local beam = Instance.new("Beam", pentaFolder)
					beam.Attachment0, beam.Attachment1 = att0, att1
					beam.Color = ColorSequence.new(dynRoleCol)
					beam.Width0, beam.Width1 = 0.2, 0.2
					beam.FaceCamera = true beam.LightEmission = 1
					beam.Transparency = NumberSequence.new(0)
				end
				for i = 1, numPoints do
					local nextAtt = (i == numPoints) and attachments[1] or attachments[i + 1]
					createBeam(attachments[i], nextAtt)
				end
				createBeam(attachments[1], attachments[9])
				createBeam(attachments[9], attachments[17])
				createBeam(attachments[17], attachments[5])
				createBeam(attachments[5], attachments[13])
				createBeam(attachments[13], attachments[1])
			end

			pentaAngle = (pentaAngle + delta * math.rad(50)) % (math.pi * 2)
			local radius, numPoints = 4, 20
			for i = 1, numPoints do
				local att = pentaFolder:FindFirstChild("PentaAtt" .. tostring(i))
				if att then
					local angle = pentaAngle + math.rad((i - 1) * (360 / numPoints))
					att.Position = Vector3.new(math.cos(angle) * radius, -2.9, math.sin(angle) * radius)
				end
			end
			for _, b in ipairs(pentaFolder:GetChildren()) do
				if b:IsA("Beam") then b.Color = ColorSequence.new(dynRoleCol) end
			end
		else
			local pFolder = hrp:FindFirstChild("MM2_Pentagram")
			if pFolder then pFolder:Destroy() end
		end

		if S.Aura then
			ensureAura(ch)
			local pl = hrp:FindFirstChild("ProHub_AuraLight")
			if pl then pl.Enabled = not S.JumpCircle pl.Color = dynRoleCol end
			for _, partName in ipairs({"ProHub_AuraFloor", "ProHub_AuraHalo"}) do
				local ap = ch:FindFirstChild(partName)
				if ap then
					for i, d in ipairs(ap:GetDescendants()) do
						if d:IsA("UIGradient") then d.Rotation = (tick() * (150 + i * 40)) % 360
						elseif d:IsA("UIStroke") and S.RainbowVisuals then d.Color = dynRoleCol
						elseif d.Name == "AuraGlow" then d.Visible = not S.JumpCircle end
					end
				end
			end
		elseif #auraObjs > 0 then
			clearAura()
		end
	end

	if S.ESP_Tracers then
		local sb = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local tHrp, tHum = p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
				if tHrp and tHum and tHum.Health > 0 then
					local pos, onS = Camera:WorldToViewportPoint(tHrp.Position)
					if onS and pos.Z > 0.1 then
						local ln = tracerLines[p] or safeDrawing("Line")
						tracerLines[p] = ln
						ln.Thickness = 1.5 ln.Transparency = 1
						ln.Color = COLORS[getRoleSafe(p)] or COLORS.Innocent
						ln.From = sb ln.To = Vector2.new(pos.X, pos.Y) ln.Visible = true
					elseif tracerLines[p] then tracerLines[p].Visible = false end
				elseif tracerLines[p] then tracerLines[p].Visible = false end
			elseif tracerLines[p] then tracerLines[p].Visible = false end
		end
	else
		for _, ln in pairs(tracerLines) do ln.Visible = false end
	end

	-- WHITE SKELETON ESP
	if S.ESP_Skeletons then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local pChar = p.Character
				local tHum = pChar:FindFirstChildOfClass("Humanoid")
				if tHum and tHum.Health > 0 then
					local bones = pChar:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
					local pLines = skeletonLines[p]
					if not pLines then
						pLines = {}
						for i = 1, 14 do
							local ln = safeDrawing("Line")
							ln.Thickness = 1.6
							ln.Transparency = 1
							ln.Color = Color3.fromRGB(255, 255, 255)
							pLines[i] = ln
						end
						skeletonLines[p] = pLines
					end
					for i, pair in ipairs(bones) do
						local ln = pLines[i]
						local part0 = pChar:FindFirstChild(pair[1])
						local part1 = pChar:FindFirstChild(pair[2])
						if part0 and part1 then
							local pos0, on0 = Camera:WorldToViewportPoint(part0.Position)
							local pos1, on1 = Camera:WorldToViewportPoint(part1.Position)
							if on0 and on1 and pos0.Z > 0.1 and pos1.Z > 0.1 then
								ln.Color = Color3.fromRGB(255, 255, 255)
								ln.From = Vector2.new(pos0.X, pos0.Y)
								ln.To = Vector2.new(pos1.X, pos1.Y)
								ln.Visible = true
							else
								ln.Visible = false
							end
						else
							ln.Visible = false
						end
					end
					for i = #bones + 1, 14 do
						if pLines[i] then pLines[i].Visible = false end
					end
				else
					hidePlayerSkeleton(p)
				end
			else
				hidePlayerSkeleton(p)
			end
		end
	else
		for p in pairs(skeletonLines) do hidePlayerSkeleton(p) end
	end
end)

local origAntiFlingCollide = setmetatable({}, {__mode = "k"})
local wasAntiFling, touchFlingSavedVel, touchFlingSavedRot, touchFlingMovel = false, nil, nil, 0.1

RunService.Stepped:Connect(function()
	local ch = LocalPlayer.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")

	if isFlingingTarget and ch then
		for _, pt in ipairs(ch:GetDescendants()) do
			if pt:IsA("BasePart") then pt.CanCollide = true end
		end
	end

	if S.AntiFling and not isFlingingTarget then
		wasAntiFling = true
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				for _, v in ipairs(p.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						if origAntiFlingCollide[v] == nil then origAntiFlingCollide[v] = v.CanCollide end
						v.CanCollide = false v.Velocity = Vector3.zero v.RotVelocity = Vector3.zero
						v.AssemblyLinearVelocity = Vector3.zero v.AssemblyAngularVelocity = Vector3.zero
						pcall(function() v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0) end)
					end
				end
			end
		end
	elseif wasAntiFling then
		wasAntiFling = false
		for pt, canCol in pairs(origAntiFlingCollide) do
			if pt and pt.Parent then
				pt.CanCollide = canCol
				pcall(function() pt.CustomPhysicalProperties = nil end)
			end
		end
		table.clear(origAntiFlingCollide)
	end

	if S.TouchFling and not isFlingingTarget and hrp and hum and hum.Health > 0 then
		touchFlingSavedVel = hrp.AssemblyLinearVelocity
		touchFlingSavedRot = hrp.AssemblyAngularVelocity
		touchFlingMovel = -touchFlingMovel
		local impulse = touchFlingSavedVel * S.TouchFlingPower + Vector3.new(0, S.TouchFlingPower, 0) + Vector3.new(0, touchFlingMovel, 0)
		hrp.Velocity = impulse hrp.AssemblyLinearVelocity = impulse
		hrp.RotVelocity = Vector3.new(S.TouchFlingPower, S.TouchFlingPower, S.TouchFlingPower)
		hrp.AssemblyAngularVelocity = Vector3.new(S.TouchFlingPower, S.TouchFlingPower, S.TouchFlingPower)
	end
end)

RunService.Heartbeat:Connect(function()
	local ch = LocalPlayer.Character
	local hrp, hum = ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	if touchFlingSavedVel and not isFlingingTarget then
		hrp.Velocity = touchFlingSavedVel hrp.AssemblyLinearVelocity = touchFlingSavedVel
		hrp.RotVelocity = touchFlingSavedRot or Vector3.zero hrp.AssemblyAngularVelocity = touchFlingSavedRot or Vector3.zero
		touchFlingSavedVel = nil touchFlingSavedRot = nil
	end

	if S.SpinBot and not S.AutoFarm and not S.Fly and not isKillingAll and not isFlingingTarget and hum.Health > 0 then
		hum.AutoRotate = false
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
	end
end)

local ignoredCoins = setmetatable({}, {__mode = "k"})
local coinCache = {}
local wasAutoFarming, collectedCoinsCount = false, 0
LocalPlayer.CharacterAdded:Connect(function() collectedCoinsCount = 0 end)

local function isValidCoin(part)
	return part and part.Parent and (not ignoredCoins[part] or (tick() - ignoredCoins[part] >= 3)) and part.Transparency < 0.9
end

local function refreshCoinCache()
	local newCache = {}
	local container = workspace:FindFirstChild("CoinContainer", true)
	if not container then collectedCoinsCount = 0 end
	for _, obj in ipairs((container or workspace):GetDescendants()) do
		if obj:IsA("BasePart") then
			local name = obj.Name:lower()
			if (name == "coin_server" or name == "coin" or name == "candy" or name:find("coin") or name:find("candy") or name:find("geschenk")) and isValidCoin(obj) then
				table.insert(newCache, obj)
			end
		end
	end
	coinCache = newCache
end

task.spawn(function()
	while true do
		if S.AutoFarm then refreshCoinCache() task.wait(0.2)
		else table.clear(coinCache) task.wait(0.5) end
	end
end)

local function getNearestCandy()
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	if #coinCache == 0 then refreshCoinCache() end
	local nearest, shortestDist = nil, math.huge
	for i = 1, #coinCache do
		local part = coinCache[i]
		if isValidCoin(part) then
			local dist = (hrp.Position - part.Position).Magnitude
			if dist < shortestDist then shortestDist = dist nearest = part end
		end
	end
	return nearest
end

local walkTargetCoin, walkWaypoints, walkWpIdx, lastPathTime = nil, nil, 1, 0

local function hasWallBetween(p1, p2, ch)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local container = workspace:FindFirstChild("CoinContainer", true)
	rp.FilterDescendantsInstances = container and {ch, container} or {ch}
	rp.IgnoreWater = true
	local dir = p2 - p1
	local res = workspace:Raycast(p1, Vector3.new(dir.X, 0, dir.Z), rp)
	return res ~= nil and res.Instance.CanCollide and res.Instance.Transparency < 0.9
end

RunService.RenderStepped:Connect(function(dt)
	local char = LocalPlayer.Character
	local hrp, hum = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
	if not S.AutoFarm or isFlingingTarget or isPickingUpGun or isKillingAll then
		if wasAutoFarming then
			wasAutoFarming = false walkWaypoints = nil
			if hum then hum.PlatformStand = false hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			if hrp then hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero hrp.CFrame = CFrame.new(hrp.Position) end
		end
		return
	end
	if not hrp or not hum or hum.Health <= 0 then return end
	wasAutoFarming = true hrp.Anchored = false
	local candy = getNearestCandy()
	if not candy then
		if S.AutoFarmMode == 2 then hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end
		return
	end
	local currentPos, targetPos = hrp.Position, candy.Position
	local dist = (currentPos - targetPos).Magnitude
	local farmAngles = (S.FarmPosition == 1) and CFrame.Angles(0, 0, 0) or CFrame.Angles(math.rad(90), 0, 0)

	if S.AutoFarmMode == 1 then
		hum.PlatformStand = false hum.WalkSpeed = S.WalkFarmSpeed
		if dist < 2.8 then
			if type(firetouchinterest) == "function" then pcall(function() firetouchinterest(hrp, candy, 0) firetouchinterest(hrp, candy, 1) end) end
			if not ignoredCoins[candy] then collectedCoinsCount = collectedCoinsCount + 1 end
			ignoredCoins[candy] = tick() walkWaypoints = nil walkTargetCoin = nil
			return
		end
		local blocked = hasWallBetween(currentPos, targetPos, char)
		if not blocked and math.abs(targetPos.Y - currentPos.Y) < 5 then
			walkWaypoints = nil hum:MoveTo(targetPos)
		else
			if walkTargetCoin ~= candy or not walkWaypoints or (tick() - lastPathTime) > 0.6 then
				walkTargetCoin = candy lastPathTime = tick()
				task.spawn(function()
					local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 4.5, AgentCanJump = true, WaypointSpacing = 4})
					local ok = pcall(function() path:ComputeAsync(currentPos, targetPos) end)
					if ok and path.Status == Enum.PathStatus.Success then walkWaypoints = path:GetWaypoints() walkWpIdx = 2
					else walkWaypoints = nil end
				end)
			end
			if walkWaypoints and walkWaypoints[walkWpIdx] then
				local wp = walkWaypoints[walkWpIdx]
				if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
				hum:MoveTo(wp.Position)
				if Vector2.new(currentPos.X - wp.Position.X, currentPos.Z - wp.Position.Z).Magnitude < 3.2 then walkWpIdx = walkWpIdx + 1 end
			else
				hum:MoveTo(targetPos)
			end
		end
		if targetPos.Y - currentPos.Y > 2.5 and dist < 8 then hum.Jump = true end
	else
		hum.PlatformStand = true hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero
		local step = S.FlyFarmSpeed * dt
		if dist <= math.max(step, 2.2) then
			hrp.CFrame = CFrame.new(targetPos) * farmAngles
			if type(firetouchinterest) == "function" then pcall(function() firetouchinterest(hrp, candy, 0) firetouchinterest(hrp, candy, 1) end) end
			if not ignoredCoins[candy] then collectedCoinsCount = collectedCoinsCount + 1 end
			ignoredCoins[candy] = tick()
		else
			hrp.CFrame = CFrame.new(currentPos + (targetPos - currentPos).Unit * step) * farmAngles
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.3)
		if S.AutoGun then grabDroppedGunOnce() end
	end
end)

local candyHighlights = {}
local function clearCandyEsp()
	for _, hl in pairs(candyHighlights) do
		if hl and hl.Parent then pcall(function() hl:Destroy() end) end
	end
	table.clear(candyHighlights)
end

local function styleCandyHighlight(hl, target)
	hl.Name = "Candy_ESP" hl.Adornee = target hl.FillColor = COLORS.CandyFill
	hl.OutlineColor = COLORS.CandyOutline hl.FillTransparency = 0.35 hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local origSelfMaterials = setmetatable({}, {__mode = "k"})
local wasSelfGhost = false

task.spawn(function()
	while true do
		task.wait(0.35)
		pcall(function()
			local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

			if S.SelfGhost and LocalPlayer.Character then
				wasSelfGhost = true
				local col = getDynamicColor(COLORS[getRoleSafe(LocalPlayer)] or COLORS.Innocent)
				for _, pt in ipairs(LocalPlayer.Character:GetDescendants()) do
					if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" and not pt.Name:find("ProHub_") then
						if not origSelfMaterials[pt] then origSelfMaterials[pt] = {Mat = pt.Material, Col = pt.Color} end
						pt.Material = Enum.Material.ForceField pt.Color = col
					end
				end
			elseif wasSelfGhost then
				wasSelfGhost = false
				for pt, info in pairs(origSelfMaterials) do
					if pt and pt.Parent then pt.Material = info.Mat pt.Color = info.Col end
				end
				table.clear(origSelfMaterials)
			end

			if S.WeaponChams and LocalPlayer.Character then
				local col = getDynamicColor(COLORS[getRoleSafe(LocalPlayer)] or COLORS.Innocent)
				for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
					if tool:IsA("Tool") then
						for _, pt in ipairs(tool:GetDescendants()) do
							if pt:IsA("BasePart") then pt.Material = Enum.Material.ForceField pt.Color = col end
						end
					end
				end
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local character = player.Character
					local hum, head = character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("Head")
					if hum and hum.Health > 0 and head then
						local role = getRoleSafe(player)
						local color = COLORS[role] or COLORS.Innocent

						local existingTag = head:FindFirstChild("SakuraUserTag")
						if S.UserTag and activeUsers[player.UserId] then
							if not existingTag then
								local bb = Instance.new("BillboardGui", head)
								bb.Name = "SakuraUserTag" bb.Size = UDim2.new(0, 200, 0, 50) bb.StudsOffset = Vector3.new(0, 2.5, 0) bb.AlwaysOnTop = true
								local txt = Instance.new("TextLabel", bb)
								txt.Name = "TagText" txt.Size = UDim2.new(1, 0, 1, 0) txt.BackgroundTransparency = 1 txt.Font = Enum.Font.GothamBold txt.Text = "User" txt.TextSize = 16 txt.TextStrokeTransparency = 0.2 txt.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
								existingTag = bb
							end
							if existingTag and existingTag:FindFirstChild("TagText") then existingTag.TagText.TextColor3 = color end
						elseif existingTag then existingTag:Destroy() end

						local highlight = character:FindFirstChild("MM2_ChamsHighlight")
						if S.ESP_Roles then
							if not highlight then highlight = Instance.new("Highlight", character) highlight.Name = "MM2_ChamsHighlight" end
							highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							highlight.FillTransparency = 0.35 highlight.OutlineTransparency = 0.1
							highlight.FillColor = color highlight.OutlineColor = color
							for _, tool in ipairs(character:GetChildren()) do
								if tool:IsA("Tool") then
									local tn = tool.Name:lower()
									if (role == "Murderer" and tn:find("knife")) or (role == "Sheriff" and (tn:find("gun") or tn:find("revolver"))) then
										local th = tool:FindFirstChild("Tool_Chams") or Instance.new("Highlight", tool)
										th.Name = "Tool_Chams" th.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop th.FillColor = color th.OutlineColor = color th.FillTransparency = 0.35
									end
								end
							end
						else
							if highlight then highlight:Destroy() end
							for _, tool in ipairs(character:GetChildren()) do
								if tool:IsA("Tool") and tool:FindFirstChild("Tool_Chams") then tool.Tool_Chams:Destroy() end
							end
						end
					else
						local highlight = character:FindFirstChild("MM2_ChamsHighlight")
						if highlight then highlight:Destroy() end
					end
				end
			end

			local drop = workspace:FindFirstChild("GunDrop", true)
			if drop then
				local gp = drop:IsA("BasePart") and drop or drop:FindFirstChildWhichIsA("BasePart")
				local ghl = drop:FindFirstChild("ProHub_GunDropHL")
				local gbb = gp and gp:FindFirstChild("ProHub_GunDropBB")
				if S.ESP_GunDrop and gp then
					if not ghl then
						ghl = Instance.new("Highlight", drop)
						ghl.Name = "ProHub_GunDropHL" ghl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						ghl.FillColor = COLORS.GunDrop ghl.OutlineColor = Color3.fromRGB(255, 255, 255) ghl.FillTransparency = 0.25
					end
					if not gbb then
						gbb = Instance.new("BillboardGui", gp)
						gbb.Name = "ProHub_GunDropBB" gbb.Size = UDim2.new(0, 180, 0, 32) gbb.StudsOffset = Vector3.new(0, 2.2, 0) gbb.AlwaysOnTop = true
						local gl = Instance.new("TextLabel", gbb)
						gl.Name = "GunText" gl.Size = UDim2.new(1, 0, 1, 0) gl.BackgroundTransparency = 1
						gl.Font = Enum.Font.GothamBlack gl.TextColor3 = COLORS.GunDrop gl.TextStrokeTransparency = 0.1 gl.TextSize = 14
					end
					local dist = myHrp and math.floor((myHrp.Position - gp.Position).Magnitude) or 0
					if gbb and gbb:FindFirstChild("GunText") then gbb.GunText.Text = string.format("🔫 GUN DROP [%dm]", dist) end
				else
					if ghl then ghl:Destroy() end
					if gbb then gbb:Destroy() end
				end
			end

			if S.ESP_Candyes then
				for obj, hl in pairs(candyHighlights) do
					if not obj or not obj.Parent or (obj:IsA("BasePart") and obj.Transparency >= 0.9) then
						if hl then hl:Destroy() end
						candyHighlights[obj] = nil
					end
				end
				local container = workspace:FindFirstChild("CoinContainer", true)
				if container then
					if not candyHighlights[container] or not candyHighlights[container].Parent then
						local hl = Instance.new("Highlight", container)
						styleCandyHighlight(hl, container)
						candyHighlights[container] = hl
					end
				end
				for _, obj in ipairs((container or workspace):GetDescendants()) do
					if (obj:IsA("BasePart") or obj:IsA("Model")) and not candyHighlights[obj] then
						local n = obj.Name:lower()
						if (n == "candy" or n == "coin" or n == "coin_server" or n:find("candy") or n:find("coin") or n:find("geschenk")) then
							if not obj:IsA("BasePart") or obj.Transparency < 0.9 then
								local hl = obj:FindFirstChild("Candy_ESP") or Instance.new("Highlight", obj)
								styleCandyHighlight(hl, obj)
								candyHighlights[obj] = hl
							end
						end
					end
				end
			elseif next(candyHighlights) ~= nil then
				clearCandyEsp()
			end
		end)
	end
end)

local flyBV, flyBG
local origLocalCollide = setmetatable({}, {__mode = "k"})
local wasNoclipping = false

RunService.Stepped:Connect(function()
	local ch = LocalPlayer.Character
	local shouldNoclip = (S.EnableNoclip or (S.AutoFarm and S.AutoFarmMode == 2) or isKillingAll) and not isFlingingTarget
	if ch and shouldNoclip then
		wasNoclipping = true
		for _, pt in ipairs(ch:GetDescendants()) do
			if pt:IsA("BasePart") then
				if origLocalCollide[pt] == nil then origLocalCollide[pt] = pt.CanCollide end
				pt.CanCollide = false
			end
		end
	elseif wasNoclipping then
		wasNoclipping = false
		for pt, col in pairs(origLocalCollide) do
			if pt and pt.Parent then pt.CanCollide = col end
		end
		table.clear(origLocalCollide)
	end
end)

RunService.RenderStepped:Connect(function()
	local ch = LocalPlayer.Character
	if S.Fly and not S.AutoFarm and not isKillingAll and not isFlingingTarget and ch and ch:FindFirstChild("HumanoidRootPart") then
		local hrp, hum = ch.HumanoidRootPart, ch:FindFirstChildOfClass("Humanoid")
		hrp.Anchored = false
		if hum then hum.PlatformStand = true end
		if not flyBV or flyBV.Parent ~= hrp then
			if flyBV then flyBV:Destroy() end
			flyBV = Instance.new("BodyVelocity", hrp) flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
		end
		if not flyBG or flyBG.Parent ~= hrp then
			if flyBG then flyBG:Destroy() end
			flyBG = Instance.new("BodyGyro", hrp) flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9) flyBG.P = 9e4
		end
		flyBG.CFrame = Camera.CFrame
		local md = hum and hum.MoveDirection or Vector3.zero
		local cf = Camera.CFrame
		local flatLook = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		flatLook = flatLook.Magnitude > 1e-4 and flatLook.Unit or Vector3.new(0, 0, -1)
		local flatRight = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
		flatRight = flatRight.Magnitude > 1e-4 and flatRight.Unit or Vector3.new(1, 0, 0)

		local fwd = md:Dot(flatLook)
		local rgt = md:Dot(flatRight)
		local fd = (md.Magnitude > 0.05) and ((cf.LookVector * fwd) + (cf.RightVector * rgt)) or Vector3.zero
		local up = (UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E)) and S.FlySpeed or ((UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q)) and -S.FlySpeed or 0)
		flyBV.Velocity = (fd.Magnitude > 0 and fd.Unit * S.FlySpeed or Vector3.zero) + Vector3.new(0, up, 0)
	else
		if flyBV then flyBV:Destroy() flyBV = nil end
		if flyBG then flyBG:Destroy() flyBG = nil end
		if ch and not S.AutoFarm and not isKillingAll and not isFlingingTarget and ch:FindFirstChildOfClass("Humanoid") then
			ch:FindFirstChildOfClass("Humanoid").PlatformStand = false
		end
	end
end)

local lastJumpCircle, wasInAir = 0, false
UserInputService.JumpRequest:Connect(function()
	local ch = LocalPlayer.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and S.EnableAirJump then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

RunService.RenderStepped:Connect(function()
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true hum.JumpPower = S.JumpPower
		local st = hum:GetState()
		local inAir = (st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air)
		if wasInAir and not inAir and S.JumpCircle and (tick() - lastJumpCircle) > 0.15 then
			lastJumpCircle = tick()
			spawnJumpCircle(COLORS[getRoleSafe(LocalPlayer)] or COLORS.Innocent)
		end
		wasInAir = inAir
		if not S.Fly and not isKillingAll and not isFlingingTarget then
			if S.AutoFarm and S.AutoFarmMode == 1 then hum.WalkSpeed = S.WalkFarmSpeed
			elseif S.SpeedGlitch and inAir and hum.MoveDirection.Magnitude > 0 then hum.WalkSpeed = 55
			else hum.WalkSpeed = S.WalkSpeed end
		end
	end
end)

-- TELEPORTS TAB
Tabs.Teleports:Toggle({Title="Enable Click Tp",Value=S.ClickTP,Callback=function(v) S.ClickTP=v end})
Tabs.Teleports:Button({Title="Teleport In Lobby",Callback=function() local c=getLobbyCFrame() if c then SafeTeleport(c) end end})
Tabs.Teleports:Button({Title="Teleport In Map",Callback=function() local c=getMapCFrame() if c then SafeTeleport(c) end end})
Tabs.Teleports:Button({Title="Teleport To Murder",Callback=function() local m=getMurderer() if m then SafeTeleport(m.HumanoidRootPart.CFrame) end end})
Tabs.Teleports:Button({Title="Teleport To Sheriff",Callback=function() local s=getSheriff() if s then SafeTeleport(s.HumanoidRootPart.CFrame) end end})
Tabs.Teleports:Button({Title="Teleport To Dropped Gun",Callback=function() grabDroppedGunOnce() end})

-- MOVEMENT TAB
Tabs.Movement:Toggle({Title="Enable Fly",Value=S.Fly,Callback=function(v) S.Fly=v updateFlyBtnVisual() end})
Tabs.Movement:Slider({Title="FlySpeed",Step=1,Value={Min=10,Max=500,Default=S.FlySpeed},Callback=function(v) v=unwrapValue(v) S.FlySpeed=tonumber(v) or S.FlySpeed end})
Tabs.Movement:Toggle({Title="Enable Air Jump",Value=S.EnableAirJump,Callback=function(v) S.EnableAirJump=v end})
Tabs.Movement:Toggle({Title="Enable Noclip",Value=S.EnableNoclip,Callback=function(v) S.EnableNoclip=v updateNoclipBtnVisual() end})
Tabs.Movement:Toggle({Title="Enable Speed Glitch",Value=S.SpeedGlitch,Callback=function(v) S.SpeedGlitch=v updateSpeedBtnVisual() end})
Tabs.Movement:Slider({Title="WalkSpeed",Step=1,Value={Min=16,Max=200,Default=S.WalkSpeed},Callback=function(v) v=unwrapValue(v) S.WalkSpeed=tonumber(v) or S.WalkSpeed end})
Tabs.Movement:Slider({Title="JumpPower",Step=1,Value={Min=50,Max=300,Default=S.JumpPower},Callback=function(v) v=unwrapValue(v) S.JumpPower=tonumber(v) or S.JumpPower end})

-- COMBAT TAB
Tabs.Combat:Button({Title="Kill All",Callback=function() executeInstantKillAll() end})
Tabs.Combat:Dropdown({Title="Kill All Mode",Values={"Distance","Bring","Flying"},Value="Distance",Callback=function(v)
	v = tostring(unwrapValue(v))
	if v == "Distance" then S.KillAllMode = 1
	elseif v == "Bring" then S.KillAllMode = 2
	else S.KillAllMode = 3 end
end})
Tabs.Combat:Toggle({Title="Enable Trigger Bot",Value=S.TriggerBot,Callback=function(v) S.TriggerBot=v end})
Tabs.Combat:Toggle({Title="Enable Camlock (ShiftLock / 1st Person)",Value=S.EnableCamlock,Callback=function(v)
	S.EnableCamlock=v
	if not v then clearCamlockBeam() end
	updateCamlockBtnVisual()
end})
Tabs.Combat:Dropdown({Title="Camlock Mode",Values={"Torso","Head"},Value="Torso",Callback=function(v) S.CamlockMode=tostring(unwrapValue(v)) end})
Tabs.Combat:Slider({Title="Camlock Prediction",Step=1,Value={Min=1,Max=40,Default=S.CamlockPrediction},Callback=function(v) v=unwrapValue(v) S.CamlockPrediction=tonumber(v) or S.CamlockPrediction end})
Tabs.Combat:Slider({Title="Camlock Smoothness",Step=1,Value={Min=1,Max=20,Default=S.CamlockSmoothness},Callback=function(v) v=unwrapValue(v) S.CamlockSmoothness=tonumber(v) or S.CamlockSmoothness end})
Tabs.Combat:Toggle({Title="Enable Aimbot",Value=S.EnableAimbot,Callback=function(v) S.EnableAimbot=v end})
Tabs.Combat:Dropdown({Title="Aimbot Mode",Values={"Torso","Head"},Value="Torso",Callback=function(v) S.AimbotMode=tostring(unwrapValue(v)) end})
Tabs.Combat:Slider({Title="Aimbot Prediction",Step=1,Value={Min=1,Max=40,Default=S.AimbotPrediction},Callback=function(v) v=unwrapValue(v) S.AimbotPrediction=tonumber(v) or S.AimbotPrediction end})
Tabs.Combat:Toggle({Title="Show Fov Aimbot",Value=S.ShowFovAimbot,Callback=function(v) S.ShowFovAimbot=v end})
Tabs.Combat:Toggle({Title="Rainbow Aimbot Circle",Value=S.RainbowAimbotCircle,Callback=function(v) S.RainbowAimbotCircle=v end})
Tabs.Combat:Slider({Title="Aimbot Circle Radius",Step=5,Value={Min=30,Max=400,Default=S.AimbotRadius},Callback=function(v) v=unwrapValue(v) S.AimbotRadius=tonumber(v) or S.AimbotRadius aimbotCircle.Radius=S.AimbotRadius end})
Tabs.Combat:Slider({Title="Aimbot Smoothness",Step=1,Value={Min=1,Max=20,Default=S.AimbotSmoothness},Callback=function(v) v=unwrapValue(v) S.AimbotSmoothness=tonumber(v) or S.AimbotSmoothness end})
Tabs.Combat:Toggle({Title="Enable Auto Win (Every Round)",Value=S.AutoWin,Callback=function(v) S.AutoWin=v end})
Tabs.Combat:Toggle({Title="Enable Kill Aura (Murderer)",Value=S.KillAura,Callback=function(v) S.KillAura=v end})
Tabs.Combat:Slider({Title="Kill Aura Range",Step=1,Value={Min=5,Max=100,Default=S.KillAuraRange},Callback=function(v) v=unwrapValue(v) S.KillAuraRange=tonumber(v) or S.KillAuraRange end})
Tabs.Combat:Toggle({Title="Enable Knife Reach Extender",Value=S.KnifeReach,Callback=function(v) S.KnifeReach=v end})
Tabs.Combat:Slider({Title="Knife Reach Distance",Step=1,Value={Min=8,Max=40,Default=S.KnifeReachSize},Callback=function(v) v=unwrapValue(v) S.KnifeReachSize=tonumber(v) or S.KnifeReachSize end})
Tabs.Combat:Toggle({Title="Enable Throw Knife Aura",Value=S.ThrowKnifeAura,Callback=function(v) S.ThrowKnifeAura=v end})
Tabs.Combat:Toggle({Title="Enable Hitbox Expander",Value=S.HitboxExpander,Callback=function(v) S.HitboxExpander=v end})
Tabs.Combat:Slider({Title="Hitbox Size",Step=1,Value={Min=4,Max=35,Default=S.HitboxSize},Callback=function(v) v=unwrapValue(v) S.HitboxSize=tonumber(v) or S.HitboxSize end})
Tabs.Combat:Toggle({Title="Enable Anti-Murderer Dodge",Value=S.AntiMurderDodge,Callback=function(v) S.AntiMurderDodge=v end})
Tabs.Combat:Slider({Title="Dodge Distance",Step=1,Value={Min=8,Max=35,Default=S.DodgeDistance},Callback=function(v) v=unwrapValue(v) S.DodgeDistance=tonumber(v) or S.DodgeDistance end})
Tabs.Combat:Toggle({Title="Auto Dodge Thrown Knife",Value=S.AntiKnifeThrow,Callback=function(v) S.AntiKnifeThrow=v end})

-- BUTTONS TAB
Tabs.Buttons:Toggle({Title="Hide Overlay Buttons When Menu Open",Value=S.HideBtnsWithMenu,Callback=function(v) S.HideBtnsWithMenu=v end})
Tabs.Buttons:Toggle({Title="Enable Camlock Button",Value=S.BtnCamlock,Callback=function(v) S.BtnCamlock=v camlockScreenBtn.Visible=v updateCamlockBtnVisual() end})
Tabs.Buttons:Toggle({Title="Enable Spin Bot Button",Value=S.BtnSpinBot,Callback=function(v) S.BtnSpinBot=v spinScreenBtn.Visible=v updateSpinBtnVisual() end})
Tabs.Buttons:Toggle({Title="Enable Farm Button",Value=S.BtnFarm,Callback=function(v) S.BtnFarm=v farmScreenBtn.Visible=v updateFarmBtnVisual() end})
Tabs.Buttons:Toggle({Title="Enable Esp Button",Value=S.BtnEsp,Callback=function(v) S.BtnEsp=v espScreenBtn.Visible=v updateEspBtnVisual() end})
Tabs.Buttons:Toggle({Title="Enable Speed Glitch Button",Value=S.BtnSpeedGlitch,Callback=function(v) S.BtnSpeedGlitch=v speedScreenBtn.Visible=v updateSpeedBtnVisual() end})
Tabs.Buttons:Toggle({Title="Enable Fling Murder Button",Value=S.BtnFlingMurder,Callback=function(v) S.BtnFlingMurder=v flingMurderBtn.Visible=v end})
Tabs.Buttons:Toggle({Title="Enable Fling Sheriff Button",Value=S.BtnFlingSheriff,Callback=function(v) S.BtnFlingSheriff=v flingSheriffBtn.Visible=v end})
Tabs.Buttons:Toggle({Title="Enable Kill All Button",Value=S.BtnKillAll,Callback=function(v) S.BtnKillAll=v killAllScreenBtn.Visible=v end})
Tabs.Buttons:Toggle({Title="Enable Grab Gun Button",Value=S.BtnGrabGun,Callback=function(v) S.BtnGrabGun=v grabGunScreenBtn.Visible=v end})
Tabs.Buttons:Toggle({Title="Enable Fly Button",Value=S.BtnFly,Callback=function(v) S.BtnFly=v flyScreenBtn.Visible=v updateFlyBtnVisual() end})
Tabs.Buttons:Toggle({Title="Enable Noclip Button",Value=S.BtnNoclip,Callback=function(v) S.BtnNoclip=v noclipScreenBtn.Visible=v updateNoclipBtnVisual() end})

-- VISUALS TAB
Tabs.Visuals:Toggle({Title="Enable Esp (Chams)",Value=S.ESP_Roles,Callback=function(v) S.ESP_Roles=v updateEspBtnVisual() end})
Tabs.Visuals:Toggle({Title="Enable Esp Tracers",Value=S.ESP_Tracers,Callback=function(v) S.ESP_Tracers=v end})
Tabs.Visuals:Toggle({Title="Enable Skeletons",Value=S.ESP_Skeletons,Callback=function(v) S.ESP_Skeletons=v end})
Tabs.Visuals:Toggle({Title="Enable Gun Drop Esp",Value=S.ESP_GunDrop,Callback=function(v) S.ESP_GunDrop=v end})
Tabs.Visuals:Toggle({Title="Enable Esp Candyes",Value=S.ESP_Candyes,Callback=function(v) S.ESP_Candyes=v if not v then clearCandyEsp() end end})
Tabs.Visuals:Toggle({Title="Enable Pentagram (Role Colored)",Value=S.Pentagram,Callback=function(v)
	S.Pentagram = v
	if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local pf = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("MM2_Pentagram")
		if pf then pf:Destroy() end
	end
end})
Tabs.Visuals:Toggle({Title="Enable Spinning Star Halo",Value=S.StarHalo,Callback=function(v)
	S.StarHalo = v
	if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
		local hf = LocalPlayer.Character.Head:FindFirstChild("ProHub_StarHalo")
		if hf then hf:Destroy() end
	end
end})
Tabs.Visuals:Toggle({Title="Enable Orbiting Orbs",Value=S.OrbitOrbs,Callback=function(v)
	S.OrbitOrbs = v
	if not v then clearOrbitOrbs() end
end})
Tabs.Visuals:Toggle({Title="Enable Neon Footsteps",Value=S.FootstepRings,Callback=function(v) S.FootstepRings=v end})
Tabs.Visuals:Toggle({Title="Enable Aura",Value=S.Aura,Callback=function(v) S.Aura=v if not v then clearAura() end end})
Tabs.Visuals:Toggle({Title="Enable Trail",Value=S.Trail,Callback=function(v) S.Trail=v end})
Tabs.Visuals:Toggle({Title="Enable Jump Circle",Value=S.JumpCircle,Callback=function(v) S.JumpCircle=v end})
Tabs.Visuals:Toggle({Title="Enable ForceField Self",Value=S.SelfGhost,Callback=function(v) S.SelfGhost=v end})
Tabs.Visuals:Toggle({Title="Enable Weapon Chams",Value=S.WeaponChams,Callback=function(v) S.WeaponChams=v end})
Tabs.Visuals:Toggle({Title="Enable Rainbow Visuals",Value=S.RainbowVisuals,Callback=function(v) S.RainbowVisuals=v end})
Tabs.Visuals:Toggle({Title="Enable Fullbright",Value=S.Fullbright,Callback=function(v) S.Fullbright=v end})
Tabs.Visuals:Toggle({Title="Enable Night",Value=S.EnableNight,Callback=function(v) S.EnableNight=v if not v then Lighting.ClockTime=12 Lighting.Brightness=2 end end})
Tabs.Visuals:Toggle({Title="Enable 3 Face",Value=S.ThirdPerson,Callback=function(v) S.ThirdPerson=v if not v then pcall(function() LocalPlayer.CameraMaxZoomDistance=128 end) end end})
Tabs.Visuals:Slider({Title="Fov Size",Step=1,Value={Min=40,Max=120,Default=S.FovSize},Callback=function(v) v=unwrapValue(v) S.FovSize=tonumber(v) or S.FovSize end})
Tabs.Visuals:Toggle({Title="Enable User Tag",Value=S.UserTag,Callback=function(v) S.UserTag=v end})

-- AUTOFARM TAB
Tabs.AutoFarm:Toggle({Title="Enable AutoFarm",Value=S.AutoFarm,Callback=function(v) S.AutoFarm=v updateFarmBtnVisual() end})
Tabs.AutoFarm:Dropdown({Title="AutoFarmMode",Values={"Walking","Flying"},Value="Flying",Callback=function(v) v=tostring(unwrapValue(v)) S.AutoFarmMode=(v=="Walking") and 1 or 2 end})
Tabs.AutoFarm:Dropdown({Title="Character Positions While Farming",Values={"Standing","On The Back"},Value="On The Back",Callback=function(v) v=tostring(unwrapValue(v)) S.FarmPosition=(v=="Standing") and 1 or 2 end})
Tabs.AutoFarm:Slider({Title="WalkFarmSpeed",Step=1,Value={Min=16,Max=26,Default=S.WalkFarmSpeed},Callback=function(v) v=unwrapValue(v) S.WalkFarmSpeed=tonumber(v) or S.WalkFarmSpeed end})
Tabs.AutoFarm:Slider({Title="FlyFarmSpeed",Step=1,Value={Min=15,Max=24,Default=S.FlyFarmSpeed},Callback=function(v) v=unwrapValue(v) S.FlyFarmSpeed=tonumber(v) or S.FlyFarmSpeed end})
Tabs.AutoFarm:Toggle({Title="Anti Afk",Value=S.AntiAfk,Callback=function(v) S.AntiAfk=v end})

-- FLING TAB
local function getOtherNames()
	local l = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(l, p.Name) end end
	if #l == 0 then table.insert(l, "No Players") end
	return l
end
local initList = getOtherNames()
if initList[1] ~= "No Players" then S.SelectedFlingPlayer = initList[1] end

local selDrop = Tabs.Fling:Dropdown({
	Title="Select Player",Values=initList,Value=initList[1],
	Callback=function(v) v=unwrapValue(v) if v and v~="No Players" then S.SelectedFlingPlayer=tostring(v) end end
})
local function updFlingList()
	local n = getOtherNames()
	if not table.find(n, S.SelectedFlingPlayer) then S.SelectedFlingPlayer = (n[1]~="No Players" and n[1]) or "" end
	pcall(function() if selDrop.Refresh then selDrop:Refresh(n) elseif selDrop.SetValues then selDrop:SetValues(n) end end)
end
Players.PlayerAdded:Connect(function() task.wait(0.2) updFlingList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.2) updFlingList() end)

Tabs.Fling:Button({Title="Fling Select Player",Callback=function()
	local p = Players:FindFirstChild(S.SelectedFlingPlayer)
	if p and p ~= LocalPlayer then runFlingOnTargets({p}) end
end})
Tabs.Fling:Button({Title="Fling Murder",Callback=function()
	local _, mPlayer = getMurderer()
	if mPlayer then runFlingOnTargets({mPlayer}) end
end})
Tabs.Fling:Button({Title="Fling Sheriff",Callback=function()
	local _, sPlayer = getSheriff()
	if sPlayer then runFlingOnTargets({sPlayer}) end
end})
Tabs.Fling:Button({Title="Fling All",Callback=function()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then table.insert(t, p) end
	end
	runFlingOnTargets(t)
end})
Tabs.Fling:Toggle({Title="Enable Touch Fling",Value=S.TouchFling,Callback=function(v) S.TouchFling=v end})
Tabs.Fling:Slider({Title="TouchFlingPower",Step=500,Value={Min=1000,Max=50000,Default=S.TouchFlingPower},Callback=function(v) v=unwrapValue(v) S.TouchFlingPower=tonumber(v) or S.TouchFlingPower end})
Tabs.Fling:Toggle({Title="Enable Antifling",Value=S.AntiFling,Callback=function(v) S.AntiFling=v end})

-- MISC TAB
Tabs.Misc:Toggle({Title="Enable Auto Win",Value=S.AutoWin,Callback=function(v) S.AutoWin=v end})
Tabs.Misc:Button({Title="Infinite Yield",Callback=function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end) end})
Tabs.Misc:Toggle({Title="Enable Spinbot",Value=S.SpinBot,Callback=function(v)
	S.SpinBot=v
	if not v and LocalPlayer.Character then
		local h=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h then h.AutoRotate=true end
	end
	updateSpinBtnVisual()
end})
Tabs.Misc:Slider({Title="SpinSpeed",Step=1,Value={Min=1,Max=100,Default=S.SpinSpeed},Callback=function(v) v=unwrapValue(v) S.SpinSpeed=tonumber(v) or S.SpinSpeed end})
Tabs.Misc:Toggle({Title="Enable Auto Grab Gun",Value=S.AutoGun,Callback=function(v) S.AutoGun=v end})

-- SETTINGS TAB
Tabs.Settings:Dropdown({Title="Theme",Values={"Black","Purple","Red"},Value="Black",Callback=function(v)
	S.Theme=tostring(unwrapValue(v)) applyMenuTheme(S.Theme)
end})
Tabs.Settings:Toggle({Title="Enable Shaders",Value=S.EnableShaders,Callback=function(v) S.EnableShaders=v applyShaders() end})
Tabs.Settings:Button({Title="Leave",Callback=function() pcall(function() game:Shutdown() end) end})
Tabs.Settings:Button({Title="Rejoin",Callback=function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end})
Tabs.Settings:Button({Title="Respawn",Callback=function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health=0 end end})
-- КОНЕЦ СКРИПТА
