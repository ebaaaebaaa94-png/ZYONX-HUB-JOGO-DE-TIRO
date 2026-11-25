--[[
	ZYONX HUB v1.5.0  |  By LostSoul404
	TYPE: LocalScript (single file)
	WHERE TO PUT IT: StarterPlayer > StarterPlayerScripts

	Works on its own, with just this LocalScript.
]]

--==================================================================
-- 1. SERVICES
--==================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Workspace = game:GetService("Workspace")
local TextService = game:GetService("TextService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================================
-- 2. SETTINGS
--==================================================================
local CONFIG = {
	Name = "ZYONX HUB",
	Version = "v1.5.0",
	Author = "By LostSoul404",
	Creator = "LostSoul404",
	Discord = "https://discord.gg/S4xqxmkXs",

	-- Image IDs (change them here)
	Images = {
		Background = "rbxassetid://15267862047", -- panel texture (interface)
		HeaderIcon = "rbxassetid://18782542085", -- left of the panel name
		CopyIcon = "rbxassetid://13938346649", -- "Copy Link" button
	},
	BackgroundTint = Color3.fromRGB(150, 150, 150), -- darkens the texture (255 = original)

	-- Loading screen music (plays only while the loading screen is visible)
	LoadingSound = "rbxassetid://95846672786069",
	LoadingVolume = 0.8,
	LoadingSoundFallbacks = {}, -- optional extra audio IDs, tried in order if the main one is blocked (private audio)

	JumpPower = 50,
	NotifyDuration = 2.5,
	ToggleKey = Enum.KeyCode.RightShift, -- minimizes/restores from the keyboard

	-- Roles (EXACT username, not the display name)
	Owner = "LostSoul4044",
	Mods = {
		Fantasma1l40 = true,
		Nao_souNICK = true,
	},

	FOV = { Min = 30, Max = 400, Default = 150 },
}

--==================================================================
-- 3. VISUAL THEME
--==================================================================
local THEME = {
	Bg = Color3.fromRGB(9, 9, 9),
	Panel = Color3.fromRGB(24, 24, 24),
	Element = Color3.fromRGB(33, 33, 33),
	ElementHover = Color3.fromRGB(56, 56, 56),
	Off = Color3.fromRGB(61, 61, 61),
	Text = Color3.fromRGB(246, 246, 246),
	SubText = Color3.fromRGB(168, 168, 168),
	White = Color3.fromRGB(243, 243, 243),
	Gray = Color3.fromRGB(103, 103, 103),
	Dark = Color3.fromRGB(13, 13, 13),
	Good = Color3.fromRGB(255, 255, 255),
	Bad = Color3.fromRGB(90, 90, 90),
	PanelAlpha = 0.55, -- sidebar/content transparency (glass over the ambient background)
	RowAlpha = 0.15, -- buttons/toggles/sliders transparency
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontBlack = Enum.Font.GothamBlack,
}

--==================================================================
-- 4. STATE (everything is OFF on execution)
--==================================================================
local State = {
	FOV = CONFIG.FOV.Default,
	FOVCircle = false,

	Aimbot = false,
	AimAlways = false,
	AimStrength = 100, -- fixed: full lock

	ESP1 = false,
	ESP2 = false,
	ESPName = false,
	ESPLine = false,
	ESPHealth = false,
	ESPUseFOV = false,

	Selected = nil,
	FilterSelected = false,
	ShowList = false,

	JumpEnabled = false,
	JumpPower = CONFIG.JumpPower,

	SpeedEnabled = false,
	Speed = 50,

	GravityEnabled = false,
	Gravity = 100,
}

local connections = {}
local ready = false
local minimized = false

local function track(conn)
	connections[#connections + 1] = conn
	return conn
end

-- Hides Roblox's own UI (chat, player list, backpack, health...) while the
-- loading screen is up, and puts it back exactly as it was afterwards.
local coreGuiBackup = nil

local function setChatConfigs(windowEnabled, inputEnabled)
	pcall(function()
		local chatService = game:GetService("TextChatService")
		local windowCfg = chatService:FindFirstChildOfClass("ChatWindowConfiguration")
		local inputCfg = chatService:FindFirstChildOfClass("ChatInputBarConfiguration")
		if windowCfg and windowEnabled ~= nil then
			windowCfg.Enabled = windowEnabled
		end
		if inputCfg and inputEnabled ~= nil then
			inputCfg.Enabled = inputEnabled
		end
	end)
end

-- Hides every piece of Roblox UI it can (top bar with the Roblox logo, chat,
-- player list, backpack, health...). Safe to call again and again: the first
-- call remembers how things were, the next calls only hide them again.
local function hideCoreGui()
	if not coreGuiBackup then
		coreGuiBackup = {}
		for _, coreType in ipairs(Enum.CoreGuiType:GetEnumItems()) do
			if coreType ~= Enum.CoreGuiType.All then
				local ok, enabled = pcall(function()
					return StarterGui:GetCoreGuiEnabled(coreType)
				end)
				if ok and enabled then
					coreGuiBackup[#coreGuiBackup + 1] = coreType
				end
			end
		end
		local okTop, topEnabled = pcall(function()
			return StarterGui:GetCore("TopbarEnabled")
		end)
		coreGuiBackup.topbar = (not okTop) or topEnabled ~= false
		pcall(function()
			local chatService = game:GetService("TextChatService")
			local windowCfg = chatService:FindFirstChildOfClass("ChatWindowConfiguration")
			local inputCfg = chatService:FindFirstChildOfClass("ChatInputBarConfiguration")
			if windowCfg then
				coreGuiBackup.chatWindow = windowCfg.Enabled
			end
			if inputCfg then
				coreGuiBackup.chatInput = inputCfg.Enabled
			end
		end)
	end
	for _, coreType in ipairs(coreGuiBackup) do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, false)
		end)
	end
	pcall(function()
		StarterGui:SetCore("TopbarEnabled", false)
	end)
	setChatConfigs(false, false)
end

local function restoreCoreGui()
	if not coreGuiBackup then
		return
	end
	local backup = coreGuiBackup
	coreGuiBackup = nil
	for _, coreType in ipairs(backup) do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, true)
		end)
	end
	pcall(function()
		StarterGui:SetCore("TopbarEnabled", backup.topbar ~= false)
	end)
	setChatConfigs(backup.chatWindow, backup.chatInput)
end

--==================================================================
-- 5. UTILITIES
--==================================================================
local function create(class, props)
	local inst = Instance.new(class)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

-- Images. Each image tries several ID formats (direct asset, thumbnail,
-- legacy URL) until one loads, so Decal IDs and Image IDs both work.
local imageFailures = {}

local function imageCandidates(id, w, h)
	local num = tostring(id):match("%d+")
	return {
		"rbxassetid://" .. num,
		"rbxthumb://type=Asset&id=" .. num .. "&w=" .. w .. "&h=" .. h,
		"http://www.roblox.com/asset/?id=" .. num,
	}
end

local function resolveImage(img, id, w, h, onFail)
	for _, candidate in ipairs(imageCandidates(id, w, h)) do
		if not img.Parent then
			return
		end
		img.Image = candidate
		local status
		pcall(function()
			ContentProvider:PreloadAsync({ img }, function(_, s)
				status = s
			end)
		end)
		if status == Enum.AssetFetchStatus.Success or img.IsLoaded then
			return
		end
	end
	img.Image = ""
	img.Visible = false
	imageFailures[#imageFailures + 1] = id
	if onFail then
		onFail(img)
	end
end

local function createImage(parent, id, props)
	props = props or {}
	local img = create("ImageLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		ScaleType = props.ScaleType or Enum.ScaleType.Fit,
		Size = props.Size,
		Position = props.Position,
		ZIndex = props.ZIndex or 1,
		ImageColor3 = props.ImageColor3 or Color3.new(1, 1, 1),
		Parent = parent,
	})
	task.spawn(resolveImage, img, id, props.ThumbW or 420, props.ThumbH or 420, props.OnFail)
	return img
end

-- Metallic palettes ------------------------------------------------
local function palette(dark, light)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, dark),
		ColorSequenceKeypoint.new(0.5, light),
		ColorSequenceKeypoint.new(1, dark),
	})
end
local SILVER = palette(Color3.fromRGB(78, 78, 78), Color3.fromRGB(244, 244, 244))
local PLATINUM = palette(Color3.fromRGB(120, 120, 120), Color3.fromRGB(255, 255, 255))
local STEEL = palette(Color3.fromRGB(52, 52, 52), Color3.fromRGB(190, 190, 190))

-- Animated gradients (rotating) --------------------------------------
local animatedGradients = {}

local function addAnimatedGradient(parent, speed, colors)
	local gradient = create("UIGradient", {
		Color = colors or SILVER,
		Parent = parent,
	})
	animatedGradients[#animatedGradients + 1] = { gradient = gradient, speed = speed or 90 }
	return gradient
end

local function animatedStroke(parent, thickness, speed, colors)
	local stroke = create("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
	addAnimatedGradient(stroke, speed, colors)
	return stroke
end

-- Premium metallic text: a bright band sweeps across the letters
local METAL_TEXT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 135, 135)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(192, 192, 192)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(192, 192, 192)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 135, 135)),
})
local shimmers = {}

local function addShimmer(label, speed, colors)
	local gradient = create("UIGradient", { Color = colors or METAL_TEXT, Parent = label })
	shimmers[#shimmers + 1] = { gradient = gradient, speed = speed or 0.5, phase = math.random() * 2 }
	return gradient
end

track(RunService.RenderStepped:Connect(function(dt)
	for i = #animatedGradients, 1, -1 do
		local entry = animatedGradients[i]
		if entry.gradient:IsDescendantOf(game) then
			entry.gradient.Rotation = (entry.gradient.Rotation + entry.speed * dt) % 360
		else
			table.remove(animatedGradients, i)
		end
	end
	local t = os.clock()
	for i = #shimmers, 1, -1 do
		local entry = shimmers[i]
		if entry.gradient:IsDescendantOf(game) then
			entry.gradient.Offset = Vector2.new(((t * entry.speed + entry.phase) % 2) - 1, 0)
		else
			table.remove(shimmers, i)
		end
	end
end))

-- Dragging (mouse and touch). onTap is called if there was no movement.
local function makeDraggable(handle, target, onTap)
	local dragging, moved = false, false
	local dragStart, startPos

	track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart = input.Position
			startPos = target.Position
		end
	end))

	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 6 then
				moved = true
			end
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved and onTap then
				onTap()
			end
		end
	end))
end

local function fadeOut(root, time)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") then
			tween(d, time, { TextTransparency = 1, BackgroundTransparency = 1 })
		elseif d:IsA("Frame") then
			tween(d, time, { BackgroundTransparency = 1 })
		elseif d:IsA("UIStroke") then
			tween(d, time, { Transparency = 1 })
		end
	end
	if root:IsA("Frame") then
		tween(root, time, { BackgroundTransparency = 1 })
	end
end

-- Click ripple: a soft white circle that expands from the click point
local function ripple(target, x, y)
	if not target.Parent then
		return
	end
	local pos, size = target.AbsolutePosition, target.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(math.clamp((x - pos.X) / size.X, 0, 1), math.clamp((y - pos.Y) / size.Y, 0, 1)),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = target,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	tween(dot, 0.55, { Size = UDim2.fromOffset(360, 360), BackgroundTransparency = 1 })
	task.delay(0.6, function()
		if dot.Parent then
			dot:Destroy()
		end
	end)
end

--==================================================================
-- 6. INTERFACE ROOT
--==================================================================
for _, name in ipairs({ "ZyonxHub", "ZyonxLoading" }) do
	local old = PlayerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local gui = create("ScreenGui", {
	Name = "ZyonxHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
	Parent = PlayerGui,
})

-- ESP layer (behind the panel)
local espLayer = create("Frame", {
	Name = "ESPLayer",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = gui,
})

-- FOV circle: just one thin line
local fovCircle = create("Frame", {
	Name = "FOVCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(State.FOV * 2, State.FOV * 2),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = State.FOVCircle,
	Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fovCircle })
create("UIStroke", {
	Color = Color3.new(1, 1, 1),
	Thickness = 1.5,
	Transparency = 0.1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Parent = fovCircle,
})

local function updateFOVCircle()
	fovCircle.Size = UDim2.fromOffset(State.FOV * 2, State.FOV * 2)
	fovCircle.Visible = State.FOVCircle
end

-- Main window
local window = create("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(580, 370),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
corner(window, 20)
create("UIGradient", { -- deep obsidian base
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 28)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 13, 13)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 7, 7)),
	}),
	Rotation = 125,
	Parent = window,
})
local windowStroke = animatedStroke(window, 2, 60, SILVER)
local windowScale = create("UIScale", { Scale = 0.01, Parent = window })
local baseScale = 1

-- Premium background (own design): soft ambient glows, sheen and top light
local ambient = create("CanvasGroup", {
	Name = "Ambient",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 0,
	Parent = window,
})
corner(ambient, 20)

-- Your texture ID (bottom layer of the panel)
local bgImage = createImage(ambient, CONFIG.Images.Background, {
	Size = UDim2.fromScale(1, 1),
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 0,
	ImageColor3 = CONFIG.BackgroundTint,
	ThumbW = 768,
	ThumbH = 432,
})
bgImage.Name = "PanelTexture"
corner(bgImage, 20)

-- dark veil: keeps the text readable and breathes slowly
local veil = create("Frame", {
	Name = "Veil",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = ambient,
})

local function softGlow(pos, size, color, layers)
	for i = 1, layers do
		local g = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = pos,
			Size = UDim2.fromOffset(size * (1 - (i - 1) / layers * 0.85), size * (1 - (i - 1) / layers * 0.85)),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.965,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = ambient,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = g })
	end
end
softGlow(UDim2.fromScale(0.08, 0.02), 420, Color3.fromRGB(135, 135, 135), 7)
softGlow(UDim2.fromScale(0.98, 1.02), 480, Color3.fromRGB(172, 172, 172), 7)
softGlow(UDim2.fromScale(0.55, 0.5), 300, Color3.fromRGB(255, 255, 255), 4)

-- diagonal sheen
local sheen = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.62, 0.35),
	Size = UDim2.fromOffset(120, 700),
	Rotation = 28,
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = ambient,
})
create("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.965),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = sheen,
})

-- top light line
local topLight = create("Frame", {
	Position = UDim2.fromOffset(24, 0),
	Size = UDim2.new(1, -48, 0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = ambient,
})
create("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = topLight,
})

-- Signature texture (own design): blueprint grid + sonar dial with a radar
-- sweep + diagonal hatch + a slow scan beam. All drawn with shapes.
do
	local NSK = NumberSequenceKeypoint.new
	local function fadeEnds(frame, rotation)
		create("UIGradient", {
			Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.5, 0), NSK(1, 1) }),
			Rotation = rotation or 0,
			Parent = frame,
		})
	end
	local function texFrame(props)
		props.BackgroundColor3 = props.BackgroundColor3 or Color3.new(1, 1, 1)
		props.BorderSizePixel = 0
		props.ZIndex = 0
		props.Parent = props.Parent or ambient
		return create("Frame", props)
	end

	-- blueprint grid (major line every 5th)
	local STEP = 29
	for i = 0, 20 do
		local line = texFrame({
			Position = UDim2.fromOffset(i * STEP, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundTransparency = (i % 5 == 0) and 0.88 or 0.95,
		})
		fadeEnds(line, 90)
	end
	for j = 0, 12 do
		local line = texFrame({
			Position = UDim2.fromOffset(0, j * STEP),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = (j % 5 == 0) and 0.88 or 0.95,
		})
		fadeEnds(line, 0)
	end
	for i = 0, 20, 5 do
		for j = 0, 12, 5 do
			local dot = texFrame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(i * STEP, j * STEP),
				Size = UDim2.fromOffset(5, 5),
				BackgroundTransparency = 0.7,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		end
	end

	-- sonar dial (bottom right)
	local DX, DY, R = 488, 296, 170
	for _, radius in ipairs({ R, 124, 80, 38 }) do
		local ring = texFrame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(DX, DY),
			Size = UDim2.fromOffset(radius * 2, radius * 2),
			BackgroundTransparency = 1,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
		create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.86, Parent = ring })
	end
	for i = 0, 47 do
		local major = i % 4 == 0
		local holder = texFrame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(DX, DY),
			Size = UDim2.fromOffset(R * 2, R * 2),
			Rotation =
