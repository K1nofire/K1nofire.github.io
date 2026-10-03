--==================================================
-- EVIL MORTY PORTAL GUN (С HUD И БЫСТРЫМИ ЦВЕТАМИ)
-- FULL LOCAL SCRIPT
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Backpack = LocalPlayer:WaitForChild("Backpack")

--==================================================
-- НАСТРОЙКИ
--==================================================

local PORTAL_TEXTURE = "rbxassetid://77878374203347"

local portalColor = Color3.fromRGB(255, 195, 35)
local portalColorLight = Color3.fromRGB(255, 225, 90)
local portalColorDark = Color3.fromRGB(210, 145, 10)

local PORTAL_GUN_SOUND = "rbxassetid://1013378689"
local PORTAL_SPAWN_SOUND = "rbxassetid://756847338"

--==================================================
-- МОДЕЛЬ ПУШКИ (MESH)
--==================================================

local GUN_MESH_ID = "rbxassetid://18285138864"
local GUN_TEXTURE_ID = "rbxassetid://18285139635"

local GUN_SIZE = Vector3.new(1.2, 1.5, 1.3)
local GUN_GRIP = CFrame.new(0, -0.3, -0.2) * CFrame.Angles(0, math.rad(90), 0)

--==================================================
-- PLAYER PORTAL HEIGHT
--==================================================

local PLAYER_PORTAL_HEIGHT = 1.0

--==================================================
-- PORTAL VARIABLES
--==================================================

local portalA = nil
local portalB = nil
local spawnedPortals = {}

local pointStage = 0
local pointA = nil
local pointB = nil
local pointSelecting = false

local teleportDebounce = false
local currentMode = "POINT"

--==================================================
-- GUN VARIABLES
--==================================================

local portal_gun = nil
local portal_sound = nil
local Handle = nil

--==================================================
-- BACKPACK
--==================================================

local function getBackpack()
	Backpack = LocalPlayer:WaitForChild("Backpack")
	return Backpack
end

--==================================================
-- REMOVE OLD GUNS
--==================================================

local function removeOldGuns()
	local backpack = getBackpack()
	for _, container in ipairs({ backpack, LocalPlayer.Character }) do
		if container then
			for _, obj in ipairs(container:GetChildren()) do
				if obj:IsA("Tool") and (obj.Name == "Portal_Gun" or obj.Name == "EVIL_MORTY_PORTAL_GUN" or obj.Name == "Portal gun by GamzeeChert") then
					obj:Destroy()
				end
			end
		end
	end
end

removeOldGuns()

--==================================================
-- CLEAR GUI
--==================================================

local oldGui = PlayerGui:FindFirstChild("evil_morty_portal_GUI")
if oldGui then oldGui:Destroy() end
local oldRickGui = PlayerGui:FindFirstChild("rick_portal_GUI")
if oldRickGui then oldRickGui:Destroy() end

--==================================================
-- PORTAL CLEANUP
--==================================================

local function destroyPortal(portal)
	if portal and portal.Parent then
		portal:Destroy()
	end
end

local function clearPointSelection()
	pointStage = 0
	pointA = nil
	pointB = nil
	pointSelecting = false
end

local function clearAllPortals()
	for _, portal in ipairs(spawnedPortals) do
		destroyPortal(portal)
	end
	table.clear(spawnedPortals)
	portalA = nil
	portalB = nil
	clearPointSelection()
	teleportDebounce = false
end

--==================================================
-- CREATE GUN (MESH)
--==================================================

local function createGun()
	if portal_gun and portal_gun.Parent then
		return portal_gun
	end

	portal_gun = nil
	Handle = nil
	portal_sound = nil

	portal_gun = Instance.new("Tool")
	portal_gun.Name = "Portal gun by GamzeeChert"
	portal_gun.RequiresHandle = true
	portal_gun.CanBeDropped = false

	Handle = Instance.new("MeshPart")
	Handle.Name = "Handle"
	Handle.MeshId = GUN_MESH_ID
	Handle.TextureID = GUN_TEXTURE_ID
	Handle.Size = GUN_SIZE
	Handle.Material = Enum.Material.Plastic
	Handle.Anchored = false
	Handle.CanCollide = false
	Handle.CanTouch = false
	Handle.CanQuery = false
	Handle.Massless = true
	Handle.Parent = portal_gun

	portal_gun.Grip = GUN_GRIP

	portal_sound = Instance.new("Sound")
	portal_sound.Name = "PortalGunSound"
	portal_sound.SoundId = PORTAL_GUN_SOUND
	portal_sound.Volume = 2.5
	portal_sound.Parent = Handle

	return portal_gun
end

--==================================================
-- MUZZLE FLASH
--==================================================

local function muzzleFlash()
	if not Handle then return end

	local flash = Instance.new("Part")
	flash.Name = "EvilMortyMuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = portalColorLight
	flash.Size = Vector3.new(0.35, 0.35, 0.35)
	flash.Transparency = 0
	flash.CanCollide = false
	flash.CanTouch = false
	flash.CanQuery = false
	flash.Anchored = true
	flash.CFrame = Handle.CFrame * CFrame.new(0, 0, -0.9)
	flash.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = portalColorLight
	light.Brightness = 7
	light.Range = 10
	light.Parent = flash

	TweenService:Create(flash, TweenInfo.new(0.18), {
		Size = Vector3.new(1.3, 1.3, 1.3),
		Transparency = 1
	}):Play()

	task.delay(0.2, function()
		if flash then flash:Destroy() end
	end)

	return flash.CFrame.Position
end

--==================================================
-- MUZZLE BEAM
--==================================================

local function createBeam(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	if distance < 0.05 then return end

	local beam = Instance.new("Part")
	beam.Name = "EvilMortyPortalBeam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanTouch = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = portalColor
	beam.Size = Vector3.new(0.18, 0.18, distance)
	beam.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = portalColorLight
	light.Brightness = 2
	light.Range = 6
	light.Parent = beam

	local tween = TweenService:Create(beam, TweenInfo.new(0.15), {
		Size = Vector3.new(0, 0, distance),
		Transparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		beam:Destroy()
	end)
end

--==================================================
-- PORTAL SOUND
--==================================================

local function playPortalSpawnSound(portal)
	if not portal then return end

	local sound = Instance.new("Sound")
	sound.Name = "EvilMortyPortalSpawnSound"
	sound.SoundId = PORTAL_SPAWN_SOUND
	sound.Volume = 2
	sound.RollOffMode = Enum.RollOffMode.Inverse
	sound.RollOffMaxDistance = 60
	sound.RollOffMinDistance = 8
	sound.Parent = portal
	sound:Play()

	task.delay(8, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

--==================================================
-- CREATE PORTAL
--==================================================

local function create_portal(position, lookDirection, surfaceNormal, hitPart)
	local portal = Instance.new("Part")
	portal.Name = "EvilMortyGoldenPortal"
	portal.Size = Vector3.new(0.6, 0.6, 0.6)
	portal.Transparency = 1
	portal.Anchored = (hitPart == nil)
	portal.CanCollide = false
	portal.CanTouch = true
	portal.CanQuery = false
	portal.CastShadow = false

	local center

	if surfaceNormal then
		center = position + (surfaceNormal * 0.05)
		portal.CFrame = CFrame.lookAt(center, center + surfaceNormal)
	else
		local direction = Vector3.new(lookDirection.X, 0, lookDirection.Z)
		if direction.Magnitude < 0.01 then
			direction = Vector3.new(0, 0, -1)
		else
			direction = direction.Unit
		end
		center = position + Vector3.new(0, 2.8, 0)
		portal.CFrame = CFrame.lookAt(center, center + direction)
	end

	portal.Parent = workspace
	portal:SetAttribute("PortalNormal", surfaceNormal or Vector3.new(0, 0, 0))
	table.insert(spawnedPortals, portal)

	if hitPart then
		local weld = Instance.new("Weld")
		weld.Name = "PortalAttachmentWeld"
		weld.Part0 = hitPart
		weld.Part1 = portal
		local relativeCF = hitPart.CFrame:Inverse() * portal.CFrame
		weld.C0 = relativeCF
		weld.Parent = portal
	end

	local surface = Instance.new("Part")
	surface.Name = "PortalTextureSurface"
	surface.Transparency = 1
	surface.Anchored = true
	surface.CanCollide = false
	surface.CanTouch = false
	surface.CanQuery = false
	surface.CastShadow = false
	surface.CFrame = portal.CFrame
	surface.Parent = portal

	local FULL_SIZE = Vector3.new(9.3, 9.3, 0.06)
	surface.Size = Vector3.new(0.15, 0.15, 0.04)
	surface.Parent = portal

	local front = Instance.new("Decal")
	front.Name = "PortalTextureFront"
	front.Face = Enum.NormalId.Front
	front.Texture = PORTAL_TEXTURE
	front.Color3 = portalColor
	front.Transparency = 0
	front.Parent = surface

	local back = Instance.new("Decal")
	back.Name = "PortalTextureBack"
	back.Face = Enum.NormalId.Back
	back.Texture = PORTAL_TEXTURE
	back.Color3 = portalColor
	back.Transparency = 0
	back.Parent = surface

	local light = Instance.new("PointLight")
	light.Name = "SoftPortalLight"
	light.Color = portalColorLight
	light.Brightness = 0.2
	light.Range = 8
	light.Shadows = false
	light.Parent = surface

	local attachment = Instance.new("Attachment")
	attachment.Name = "EvilMortyPortalAttachment"
	attachment.Parent = surface

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "PortalParticles"
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(portalColor)
	particles.LightEmission = 0.7
	particles.Rate = 0
	particles.Lifetime = NumberRange.new(0.35, 0.7)
	particles.Speed = NumberRange.new(0.3, 0.8)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.10),
		NumberSequenceKeypoint.new(0.5, 0.06),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Parent = attachment

	local expandTween = TweenService:Create(
		surface,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = FULL_SIZE }
	)
	local lightTween = TweenService:Create(
		light,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 1.8 }
	)
	expandTween:Play()
	lightTween:Play()
	particles:Emit(24)
	particles.Rate = 6

	local rotation = 0
	local rotationConnection
	rotationConnection = RunService.RenderStepped:Connect(function(dt)
		if not portal or not portal.Parent then
			if rotationConnection then rotationConnection:Disconnect() end
			return
		end
		rotation += dt * 0.65
		surface.CFrame = portal.CFrame * CFrame.Angles(0, 0, rotation)
	end)

	task.spawn(function()
		local pulseTime = 0
		while portal and portal.Parent do
			pulseTime += 0.08
			local pulse = (math.sin(pulseTime * 2) + 1) / 2
			front.Transparency = 0.02 + pulse * 0.06
			back.Transparency = 0.02 + pulse * 0.06
			light.Brightness = 1.5 + pulse * 0.5
			task.wait(0.08)
		end
	end)

	playPortalSpawnSound(portal)
	return portal
end

--==================================================
-- TELEPORT EFFECT
--==================================================

local function spawnTeleportEffect(position)
    local flash = Instance.new("Part")
    flash.Name = "TeleportFlash"
    flash.Shape = Enum.PartType.Ball
    flash.Material = Enum.Material.Neon
    flash.Color = portalColorLight
    flash.Size = Vector3.new(2, 2, 2)
    flash.Transparency = 0.3
    flash.Anchored = true
    flash.CanCollide = false
    flash.CFrame = CFrame.new(position)
    flash.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = portalColorLight
    light.Brightness = 8
    light.Range = 20
    light.Parent = flash

    local att = Instance.new("Attachment")
    att.Parent = flash

    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(portalColor)
    particles.LightEmission = 0.8
    particles.Rate = 0
    particles.Lifetime = NumberRange.new(0.2, 0.5)
    particles.Speed = NumberRange.new(1, 3)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Parent = att
    particles:Emit(40)

    TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(8, 8, 8),
        Transparency = 1
    }):Play()

    task.delay(0.7, function()
        if flash then flash:Destroy() end
    end)
end

--==================================================
-- TWO WAY TELEPORT
--==================================================

local function connectPortalTeleport(entrance, destination)
	if not entrance or not destination then return end

	entrance.Touched:Connect(function(hit)
		if teleportDebounce then return end

		local character = LocalPlayer.Character
		if not character then return end
		if not hit:IsDescendantOf(character) then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if not destination or not destination.Parent then return end

		teleportDebounce = true
		if portal_sound then portal_sound:Play() end

		spawnTeleportEffect(hrp.Position)

			-- На полу/потолке портал больше НЕ переворачивает игрока.
		-- Поворот применяется только для боковых (вертикальных) порталов.
		local destinationPosition = (destination.CFrame * CFrame.new(0, 0, -4)).Position
		local destinationNormal = destination:GetAttribute("PortalNormal")

		if typeof(destinationNormal) == "Vector3" and math.abs(destinationNormal.Y) < 0.7 then
			-- Боковой портал: разворачиваем игрока по направлению портала, но без наклона.
			local wallDirection = Vector3.new(destinationNormal.X, 0, destinationNormal.Z)
			if wallDirection.Magnitude > 0.01 then
				wallDirection = wallDirection.Unit
				hrp.CFrame = CFrame.lookAt(destinationPosition, destinationPosition + wallDirection, Vector3.yAxis)
			else
				hrp.CFrame = CFrame.new(destinationPosition) * CFrame.Angles(0, hrp.Orientation.Y * math.pi / 180, 0)
			end
		else
			-- Пол/потолок: сохраняем исходный поворот игрока полностью.
			hrp.CFrame = CFrame.new(destinationPosition) * CFrame.Angles(
				math.rad(hrp.Orientation.X),
				math.rad(hrp.Orientation.Y),
				math.rad(hrp.Orientation.Z)
			)
		end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		task.wait(0.1)
		spawnTeleportEffect(hrp.Position)

		task.delay(0.7, function()
			teleportDebounce = false
		end)
	end)
end

--==================================================
-- PORTAL PAIR
--==================================================

local function createPortalPair(pointDataA, pointDataB)
	-- Лимита на количество пар порталов нет.
	-- Каждая новая пара работает независимо: 1↔2, 3↔4, 5↔6 и т.д.
	local entrance = create_portal(pointDataA.Position, nil, pointDataA.Normal, pointDataA.HitPart)
	local destination = create_portal(pointDataB.Position, nil, pointDataB.Normal, pointDataB.HitPart)

	portalA = entrance
	portalB = destination

	connectPortalTeleport(entrance, destination)
	connectPortalTeleport(destination, entrance)
end

--==================================================
-- SCREEN RAYCAST
--==================================================

local function raycastFromScreen(screenPosition)
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local exclusions = {}
	local character = LocalPlayer.Character
	if character then table.insert(exclusions, character) end
	if portal_gun then table.insert(exclusions, portal_gun) end
	for _, portal in ipairs(spawnedPortals) do
		if portal and portal.Parent then
			table.insert(exclusions, portal)
		end
	end
	params.FilterDescendantsInstances = exclusions

	return workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
end

--==================================================
-- ПРОВЕРКА ЭКИПИРОВКИ
--==================================================

local function isGunEquipped()
    return portal_gun and portal_gun.Parent == LocalPlayer.Character
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "evil_morty_portal_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

-- ПАНЕЛЬ СЛЕВА ПО ЦЕНТРУ, В СТИЛЕ F3X
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 315)
frame.Position = UDim2.new(0, 14, 0.5, -157)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
frame.Parent = gui

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 0, 0)
frameStroke.Thickness = 0
frameStroke.Transparency = 1
frameStroke.Parent = frame

-- ВЕРХНЯЯ ПОЛОСА
local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, -12, 0, 3)
topLine.Position = UDim2.new(0, 6, 0, 33)
topLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topLine.BorderSizePixel = 0
topLine.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 0, 28)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Text = "EVIL MORTY PORTAL GUN"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local hud = Instance.new("TextLabel")
hud.Size = UDim2.new(1, -20, 0, 22)
hud.Position = UDim2.new(0, 10, 0, 42)
hud.BackgroundTransparency = 1
hud.TextColor3 = portalColorLight
hud.Text = "POINT: FIRE → A → B"
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.TextScaled = true
hud.Font = Enum.Font.Gotham
hud.Parent = frame

local menuToggle = Instance.new("TextButton")
menuToggle.Name = "MenuToggle"
menuToggle.Size = UDim2.new(0, 28, 0, 28)
menuToggle.Position = UDim2.new(1, -36, 0, 3)
menuToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuToggle.BackgroundTransparency = 0
menuToggle.BorderSizePixel = 0
menuToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
menuToggle.TextColor3 = Color3.fromRGB(220, 220, 220)
menuToggle.Text = "?"
menuToggle.TextScaled = true
menuToggle.Font = Enum.Font.GothamBold
menuToggle.Parent = frame
menuToggle.Visible = false

local menuOpen = false
menuToggle.Activated:Connect(function()
    menuOpen = not menuOpen
    frame.Visible = menuOpen
    menuToggle.Visible = false
end)

UserInputService.InputBegan:Connect(function(inputObject, processed)
    if processed then
        return
    end

    if inputObject.KeyCode == Enum.KeyCode.Insert then
        menuOpen = not menuOpen
        frame.Visible = menuOpen
    end
end)

-- КНОПКИ РЕЖИМА
-- F3X-STYLE BUTTON
-- Чёткий чёрный квадрат, прозрачность 0.25 и светлая полоса сверху.
local function applyF3XButtonStyle(btn, selected, topColor)
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.25
    btn.BorderSizePixel = 0
    btn.BorderColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.TextScaled = false
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.ClipsDescendants = true

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 3)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = topColor or Color3.fromRGB(255, 255, 255)
    topBar.BackgroundTransparency = 0
    topBar.BorderSizePixel = 0
    topBar.ZIndex = btn.ZIndex + 1
    topBar.Parent = btn

    btn:SetAttribute("Selected", selected == true)

    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.25
    end)

    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.25
    end)

    return btn
end

local function makeButton(text, x, y, width, height, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width or 80, 0, height or 40)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.Text = text
    btn.Parent = frame
    applyF3XButtonStyle(btn, false, Color3.fromRGB(255, 255, 255))
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.25
    return btn
end

local pointButton = makeButton("POINT", 10, 72, 86, 32, Color3.fromRGB(45, 45, 45))
local playerButton = makeButton("PLAYER", 102, 72, 86, 32, Color3.fromRGB(45, 45, 45))
local placeButton = makeButton("PLACE", 194, 72, 86, 32, Color3.fromRGB(45, 45, 45))

local function updateModeButtonVisuals()
    local mode = currentMode or "POINT"
    for button, name in pairs({
        [pointButton] = "POINT",
        [playerButton] = "PLAYER",
        [placeButton] = "PLACE",
    }) do
        local selected = (mode == name)
        button:SetAttribute("Selected", selected)
        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        button.BackgroundTransparency = 0.25
    end
end


local input = Instance.new("TextBox")
input.Size = UDim2.new(0, 180, 0, 38)
input.Position = UDim2.new(0, 10, 0, 116)
input.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
input.BackgroundTransparency = 0.25
input.BorderSizePixel = 0
input.BorderColor3 = Color3.fromRGB(0, 0, 0)
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
input.PlaceholderText = "Player name / Place ID"
input.Text = ""
input.TextScaled = true
input.Font = Enum.Font.Gotham
input.Parent = frame

local fireButton = Instance.new("TextButton")
fireButton.Size = UDim2.new(0, 86, 0, 32)
fireButton.Position = UDim2.new(0, 194, 0, 116)
fireButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fireButton.Text = "FIRE"
fireButton.Parent = frame
applyF3XButtonStyle(fireButton, false, portalColor)
fireButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fireButton.BackgroundTransparency = 0.25

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0, 86, 0, 32)
resetButton.Position = UDim2.new(0, 194, 0, 194)
resetButton.TextColor3 = Color3.fromRGB(220, 220, 220)
resetButton.Text = "RESET"
resetButton.Parent = frame
applyF3XButtonStyle(resetButton, false, Color3.fromRGB(255, 255, 255))
resetButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
resetButton.BackgroundTransparency = 0.25

--==================================================
-- ПОЛЗУНОК
--==================================================

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(0, 180, 0, 8)
sliderBg.Position = UDim2.new(0, 10, 0, 170)
sliderBg.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
sliderBg.BackgroundTransparency = 0
sliderBg.BorderSizePixel = 0
sliderBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
sliderBg.Parent = frame

local sliderIndicator = Instance.new("Frame")
sliderIndicator.Size = UDim2.new(0, 16, 0, 16)
sliderIndicator.Position = UDim2.new(0, 0, 0.5, -8)
sliderIndicator.BackgroundColor3 = portalColor
sliderIndicator.BorderSizePixel = 0
sliderIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
sliderIndicator.Parent = sliderBg

local colorLabel = Instance.new("TextBox")
colorLabel.Name = "ColorCodeInput"
colorLabel.Size = UDim2.new(0, 86, 0, 32)
colorLabel.Position = UDim2.new(0, 194, 0, 154)
colorLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
colorLabel.BackgroundTransparency = 0.25
colorLabel.BorderSizePixel = 0
colorLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
colorLabel.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
colorLabel.PlaceholderText = "#RRGGBB"
colorLabel.Text = "#FFC323"
colorLabel.TextXAlignment = Enum.TextXAlignment.Center
colorLabel.TextScaled = false
colorLabel.TextSize = 12
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.ClearTextOnFocus = false
colorLabel.Parent = frame

--==================================================
-- ЛОГИКА ПОЛЗУНКА
--==================================================

local dragging = false
local sliderValue = 0.12

local function updateColorFromSlider(value)
    sliderValue = math.clamp(value, 0, 1)
    local hue = sliderValue * 0.85
    local color = Color3.fromHSV(hue, 1, 1)
    portalColor = color
    portalColorLight = Color3.fromHSV(hue, 1, 0.9)
    portalColorDark = Color3.fromHSV(hue, 1, 0.4)

    sliderIndicator.BackgroundColor3 = portalColor
    colorLabel.Text = string.format("#%02X%02X%02X", portalColor.R*255, portalColor.G*255, portalColor.B*255)
    input.BorderColor3 = Color3.fromRGB(0, 0, 0)
    fireButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fireButton.BackgroundTransparency = 0.25
    hud.TextColor3 = portalColorLight
end

updateColorFromSlider(0.12)

sliderIndicator.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
    end
end)

sliderIndicator.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = input.Position
        local sliderAbsPos = sliderBg.AbsolutePosition
        local sliderSize = sliderBg.AbsoluteSize
        local relativeX = math.clamp((mousePos.X - sliderAbsPos.X) / sliderSize.X, 0, 1)
        updateColorFromSlider(relativeX)
        sliderIndicator.Position = UDim2.new(relativeX, -8, 0.5, -8)
    end
end)

sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local sliderAbsPos = sliderBg.AbsolutePosition
        local sliderSize = sliderBg.AbsoluteSize
        local relativeX = math.clamp((mousePos.X - sliderAbsPos.X) / sliderSize.X, 0, 1)
        updateColorFromSlider(relativeX)
        sliderIndicator.Position = UDim2.new(relativeX, -8, 0.5, -8)
    end
end)

--==================================================
-- КНОПКИ ЦВЕТА
--==================================================

local function createColorButton(text, color, posX, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 32, 0, 32)
    btn.Position = UDim2.new(0, posX, 0, posY)
    btn.Text = ""
    btn.Parent = frame
    applyF3XButtonStyle(btn, false, Color3.fromRGB(255, 255, 255))
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.25

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = UDim2.new(0.5, -9, 0.5, -9)
    circle.BackgroundColor3 = color
    circle.BorderSizePixel = 0
    circle.Parent = btn

    btn.MouseEnter:Connect(function()
        if not btn:GetAttribute("Selected") then
            btn.BackgroundColor3 = Color3.fromRGB(34, 37, 40)
        end
    end)

    btn.MouseLeave:Connect(function()
        if btn:GetAttribute("Selected") then
            btn.BackgroundColor3 = Color3.fromRGB(58, 62, 67)
        else
            btn.BackgroundColor3 = Color3.fromRGB(20, 22, 24)
        end
    end)

    btn.Activated:Connect(function()
        portalColor = color
        portalColorLight = Color3.new(
            math.min(1, color.R * 1.2),
            math.min(1, color.G * 1.2),
            math.min(1, color.B * 1.2)
        )
        portalColorDark = Color3.new(
            color.R * 0.6,
            color.G * 0.6,
            color.B * 0.6
        )

        sliderIndicator.BackgroundColor3 = portalColor
        colorLabel.Text = string.format("#%02X%02X%02X", portalColor.R*255, portalColor.G*255, portalColor.B*255)
        input.BorderColor3 = Color3.fromRGB(0, 0, 0)
        fireButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        local fireTopBar = fireButton:FindFirstChild("TopBar")
        if fireTopBar then
            fireTopBar.BackgroundColor3 = portalColor
        end
        hud.TextColor3 = portalColorLight

        local h, s, v = Color3.toHSV(portalColor)
        local sliderPos = h / 0.85
        sliderValue = math.clamp(sliderPos, 0, 1)
        sliderIndicator.Position = UDim2.new(sliderValue, -8, 0.5, -8)
    end)

    return btn
end

local greenColor = Color3.fromRGB(0, 255, 65)
local yellowColor = Color3.fromRGB(255, 195, 35)
local blueColor = Color3.fromRGB(0, 120, 255)

createColorButton("", greenColor, 10, 205)
createColorButton("", yellowColor, 48, 205)
createColorButton("", blueColor, 86, 205)

local bottomLine = Instance.new("Frame")
bottomLine.Size = UDim2.new(1, -12, 0, 3)
bottomLine.Position = UDim2.new(0, 6, 0, 242)
bottomLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bottomLine.BorderSizePixel = 0
bottomLine.Parent = frame

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 155, 0, 24)
hint.Position = UDim2.new(1, -165, 1, -36)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.Text = "By GamzeeChert"
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextYAlignment = Enum.TextYAlignment.Center
hint.TextScaled = false
hint.TextSize = 14
hint.Font = Enum.Font.GothamBold
hint.Parent = frame

local hintGradient = Instance.new("UIGradient")
hintGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 140, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 80)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(100, 80, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 180))
})
hintGradient.Parent = hint

local hueShift = 0
RunService.RenderStepped:Connect(function(dt)
    if not hint or not hint.Parent then
        return
    end
    hueShift = (hueShift + dt * 0.18) % 1
    hintGradient.Offset = Vector2.new(hueShift * 2 - 1, 0)
end)

--==================================================
-- POINT SELECTION
--==================================================

local function startPointSelection()
	if currentMode ~= "POINT" then return end

	clearPointSelection()
	pointSelecting = true
	pointStage = 1

	hud.Text = "TAP / CLICK → SET POINT A"
end

local function setPoint(position, normal, hitPart)
	if currentMode ~= "POINT" then return end
	if not pointSelecting then return end

	if pointStage == 1 then
		pointA = { Position = position, Normal = normal, HitPart = hitPart }
		pointStage = 2

		local muzzlePos = muzzleFlash()
		if muzzlePos then
			createBeam(muzzlePos, position)
		end
		if portal_sound then portal_sound:Play() end

		hud.Text = "POINT A SET → TAP / CLICK POINT B"
		return
	end

	if pointStage == 2 then
		pointB = { Position = position, Normal = normal, HitPart = hitPart }

		local muzzlePos = muzzleFlash()
		if muzzlePos then
			createBeam(muzzlePos, position)
		end
		if portal_sound then portal_sound:Play() end

		createPortalPair(pointA, pointB)

		pointStage = 0
		pointSelecting = false
		pointA = nil
		pointB = nil

		hud.Text = "PORTALS READY → ENTER ONE"
	end
end

--==================================================
-- FIND PLAYER
--==================================================

local function findPlayer(name)
	name = string.lower(string.gsub(name, "^%s*(.-)%s*$", "%1"))

	for _, player in ipairs(Players:GetPlayers()) do
		if string.lower(player.Name) == name or string.lower(player.DisplayName) == name then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if string.lower(player.Name):sub(1, #name) == name then
			return player
		end
	end

	return nil
end

--==================================================
-- PLAYER PORTAL
--==================================================

local function firePlayerPortal(playerName)
	local target = findPlayer(playerName)
	if not target then return false end
	if not target.Character then return false end

	local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
	local character = LocalPlayer.Character
	if not targetHRP or not character then return false end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	muzzleFlash()
	if portal_sound then portal_sound:Play() end

	clearAllPortals()

	local frontPosition = hrp.Position + hrp.CFrame.LookVector * 5 + Vector3.new(0, PLAYER_PORTAL_HEIGHT - 2.8, 0)
	local targetPosition = targetHRP.Position + Vector3.new(0, PLAYER_PORTAL_HEIGHT - 2.8, 0)

	local entrance = create_portal(frontPosition, hrp.CFrame.LookVector, nil, nil)
	local destination = create_portal(targetPosition, -targetHRP.CFrame.LookVector, nil, nil)

	portalA = entrance
	portalB = destination

	connectPortalTeleport(entrance, destination)
	connectPortalTeleport(destination, entrance)

	return true
end

--==================================================
-- PLACE PORTAL
--==================================================

local function firePlacePortal(placeId)
	placeId = tonumber(placeId)
	if not placeId then return false end

	local character = LocalPlayer.Character
	if not character then return false end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	muzzleFlash()
	if portal_sound then portal_sound:Play() end

	clearAllPortals()

	local position = hrp.Position + hrp.CFrame.LookVector * 5
	local portal = create_portal(position, hrp.CFrame.LookVector, nil, nil)
	portalA = portal

	portal.Touched:Connect(function(hit)
		if teleportDebounce then return end

		local currentCharacter = LocalPlayer.Character
		if not currentCharacter then return end
		if not hit:IsDescendantOf(currentCharacter) then return end

		teleportDebounce = true
		if portal_sound then portal_sound:Play() end

		spawnTeleportEffect(hrp.Position)

		local success = pcall(function()
			TeleportService:Teleport(placeId, LocalPlayer)
		end)

		if not success then
			teleportDebounce = false
		end
	end)

	return true
end

--==================================================
-- MODE
--==================================================

local function setMode(mode)
	clearAllPortals()
	currentMode = mode

	if mode == "POINT" then
		hud.Text = "POINT: FIRE → A → B"
		input.PlaceholderText = "Point mode"
	elseif mode == "PLAYER" then
		hud.Text = "PLAYER: ENTER NAME → FIRE"
		input.PlaceholderText = "Player name"
	elseif mode == "PLACE" then
		hud.Text = "PLACE: ENTER ID → FIRE"
		input.PlaceholderText = "Place ID"
	end
end

--==================================================
-- FIRE
--==================================================

local function fire()
	if currentMode == "PLAYER" then
		if input.Text == "" then
			hud.Text = "ENTER PLAYER NAME"
			return
		end

		local success = firePlayerPortal(input.Text)
		hud.Text = success and "ENTER THE PORTAL" or "PLAYER NOT FOUND"
		return
	end

	if currentMode == "PLACE" then
		if input.Text == "" then
			hud.Text = "ENTER PLACE ID"
			return
		end

		local success = firePlacePortal(input.Text)
		hud.Text = success and "ENTER THE PORTAL" or "INVALID PLACE ID"
		return
	end

	if currentMode == "POINT" then
		if not pointSelecting then
			startPointSelection()
		else
			hud.Text = "TAP / CLICK SCREEN TO SET POINT"
		end
	end
end

--==================================================
-- BUTTON CONNECTIONS
--==================================================

pointButton.Activated:Connect(function() setMode("POINT") end)
playerButton.Activated:Connect(function() setMode("PLAYER") end)
placeButton.Activated:Connect(function() setMode("PLACE") end)
fireButton.Activated:Connect(function() fire() end)

--==================================================
-- TOOL
--==================================================

local function connectTool()
	if not portal_gun then return end
	portal_gun.Activated:Connect(function() fire() end)
end

--==================================================
-- MOBILE FIRE
--==================================================

if UserInputService.TouchEnabled then
	local mobileButton = Instance.new("TextButton")
	mobileButton.Size = UDim2.new(0, 80, 0, 80)
	mobileButton.Position = UDim2.new(1, -100, 1, -130)
	mobileButton.BackgroundColor3 = portalColorDark
	mobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	mobileButton.Text = "FIRE"
	mobileButton.TextScaled = true
	mobileButton.Font = Enum.Font.GothamBold
	mobileButton.BorderSizePixel = 0
	mobileButton.Parent = gui

	local mobileCorner = Instance.new("UICorner")
	mobileCorner.CornerRadius = UDim.new(1, 0)
	mobileCorner.Parent = mobileButton

	mobileButton.Activated:Connect(function() fire() end)
end

--==================================================
-- MOBILE POINT
--==================================================

if UserInputService.TouchEnabled then
	UserInputService.TouchTap:Connect(function(touchPositions, processed)
		if processed then return end
		if currentMode ~= "POINT" then return end
		if not pointSelecting then return end

		if not isGunEquipped() then
			hud.Text = "EQUIP THE GUN TO PLACE PORTAL"
			return
		end

		local touch = touchPositions[1]
		if not touch then return end

		local result = raycastFromScreen(touch)
		if not result then
			hud.Text = "NO TARGET"
			return
		end

		setPoint(result.Position, result.Normal, result.Instance)
	end)
end

--==================================================
-- PC MOUSE
--==================================================

if UserInputService.MouseEnabled then
	UserInputService.InputBegan:Connect(function(inputObject, processed)
		if processed then return end
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if currentMode ~= "POINT" then return end
		if not pointSelecting then return end

		if not isGunEquipped() then
			hud.Text = "EQUIP THE GUN TO PLACE PORTAL"
			return
		end

		local mousePosition = UserInputService:GetMouseLocation()
		local result = raycastFromScreen(mousePosition)
		if not result then
			hud.Text = "NO TARGET"
			return
		end

		setPoint(result.Position, result.Normal, result.Instance)
	end)
end

--==================================================
-- ПРИЦЕЛ: ЛИНИЯ + МАРКЕР
--==================================================

local aimLine = nil
local aimMarker = nil

local function updateAimVisuals()
	if aimLine and aimLine.Parent then aimLine:Destroy() end
	if aimMarker and aimMarker.Parent then aimMarker:Destroy() end
	aimLine = nil
	aimMarker = nil

	if currentMode ~= "POINT" or not pointSelecting then return end

	local mousePos = UserInputService:GetMouseLocation()
	local result = raycastFromScreen(mousePos)
	if not result then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	local origin = camera.CFrame.Position
	local targetPos = result.Position
	local normal = result.Normal

	local distance = (targetPos - origin).Magnitude
	if distance > 0.1 then
		aimLine = Instance.new("Part")
		aimLine.Name = "AimLine"
		aimLine.Anchored = true
		aimLine.CanCollide = false
		aimLine.CanTouch = false
		aimLine.CanQuery = false
		aimLine.CastShadow = false
		aimLine.Material = Enum.Material.Neon
		aimLine.Color = portalColor
		aimLine.Size = Vector3.new(0.06, 0.06, distance)
		aimLine.CFrame = CFrame.lookAt(origin, targetPos) * CFrame.new(0, 0, -distance / 2)
		aimLine.Transparency = 0.3
		aimLine.Parent = workspace

		local light = Instance.new("PointLight")
		light.Color = portalColorLight
		light.Brightness = 0.5
		light.Range = 3
		light.Parent = aimLine
	end

	aimMarker = Instance.new("Part")
	aimMarker.Name = "AimMarker"
	aimMarker.Shape = Enum.PartType.Ball
	aimMarker.Anchored = true
	aimMarker.CanCollide = false
	aimMarker.CanTouch = false
	aimMarker.CanQuery = false
	aimMarker.CastShadow = false
	aimMarker.Material = Enum.Material.Neon
	aimMarker.Color = portalColor
	aimMarker.Size = Vector3.new(0.2, 0.2, 0.2)
	aimMarker.Transparency = 0.2
	aimMarker.CFrame = CFrame.new(targetPos + normal * 0.02)
	aimMarker.Parent = workspace

	local markerLight = Instance.new("PointLight")
	markerLight.Color = portalColorLight
	markerLight.Brightness = 1.5
	markerLight.Range = 4
	markerLight.Parent = aimMarker
end

RunService.RenderStepped:Connect(function()
	updateAimVisuals()
end)

--==================================================
-- RESET
--==================================================

resetButton.Activated:Connect(function()
	clearAllPortals()
	hud.Text = "PORTALS RESET"
end)

--==================================================
-- GIVE GUN
--==================================================

local function giveGun()
	local backpack = getBackpack()

	for _, obj in ipairs(backpack:GetChildren()) do
		if obj:IsA("Tool") and obj.Name == "Portal gun by GamzeeChert" and obj ~= portal_gun then
			obj:Destroy()
		end
	end

	if LocalPlayer.Character then
		for _, obj in ipairs(LocalPlayer.Character:GetChildren()) do
			if obj:IsA("Tool") and obj.Name == "Portal gun by GamzeeChert" and obj ~= portal_gun then
				obj:Destroy()
			end
		end
	end

	if not portal_gun or portal_gun.Parent == nil then
		portal_gun = nil
		Handle = nil
		portal_sound = nil
		createGun()
		connectTool()
	end

	if portal_gun and portal_gun.Parent ~= backpack and portal_gun.Parent ~= LocalPlayer.Character then
		portal_gun.Parent = backpack
	end
end

--==================================================
-- INITIAL GIVE
--==================================================

createGun()

if portal_gun then
	connectTool()
	portal_gun.Parent = getBackpack()
end

--==================================================
-- RESPAWN SAFE
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5)

	local newBackpack = LocalPlayer:WaitForChild("Backpack")
	Backpack = newBackpack

	portal_gun = nil
	Handle = nil
	portal_sound = nil

	task.wait(0.5)

	createGun()

	if portal_gun then
		connectTool()
		portal_gun.Parent = newBackpack
	end

	hud.Text = "POINT: FIRE → TAP A → TAP B"
end)

--==================================================
-- BACKPACK MONITOR
--==================================================

Backpack.ChildRemoved:Connect(function(child)
	if child ~= portal_gun then return end

	task.delay(0.2, function()
		local currentBackpack = getBackpack()

		if not portal_gun then return end

		if portal_gun.Parent == nil then
			portal_gun = nil
			Handle = nil
			portal_sound = nil
			createGun()

			if portal_gun then
				connectTool()
				portal_gun.Parent = currentBackpack
			end
		end
	end)
end)

--==================================================
-- ВЫГРУЗКА ПО F1
--==================================================

local unloadKey = Enum.KeyCode.F1
local shouldUnload = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == unloadKey then
        shouldUnload = true
        clearAllPortals()
        if gui then gui:Destroy() end
        if portal_gun then portal_gun:Destroy() end
        if portal_sound then portal_sound:Destroy() end
        Handle = nil
        print("Portal gun unloaded. Press F1 again to reload script.")
    end
end)

while not shouldUnload do
    task.wait()
end

return
