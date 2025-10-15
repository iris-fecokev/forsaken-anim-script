-- Forexiken Killers/Survivors Animations Script (Full Version)
local DebugMode = true

local function debugPrint(message)
	if DebugMode then
		print("[Forexiken Debug]: " .. message)
	end
end

local function errorHandler(errorCode, errorMessage)
	warn("[Forexiken Error " .. errorCode .. "]: " .. errorMessage)
	game.StarterGui:SetCore("SendNotification", {
		Title = "Forexiken Error " .. errorCode,
		Text = errorMessage,
		Duration = 10
	})
end

-- Config section
local Config = {
	CloseButtonTexture = "118955245038416",
	MinimizeButtonTexture = "74729089697042",
	NoliPreview = "124491999410747",
	HealthThreshold = 50, -- Health limit for injured animations

	-- Speed and Stamina settings
	SpeedSettings = {
		NormalSpeed = 16, -- Normal walking speed
		RunSpeed = 36, -- Running speed
		StaminaMax = 100, -- Maximum stamina
		StaminaDrainPerSecond = 15, -- Stamina drain rate when running
		StaminaRegenPerSecond = 10, -- Stamina regeneration rate
		ExhaustedSpeed = 12 -- Speed when exhausted (no stamina)
	},

	-- Survivor animations (default Roblox animations)
	SurvivorAnimations = {
		Normal = {
			Idle = "84748048281351", -- Default Roblox idle
			Walk = "92680738846996", -- Default Roblox walk  
			Run = "115976215666989" -- Default Roblox run
		},
		Injured = {
			Idle = "111614549220138", -- Using Noli idle as example
			Walk = "127958253884259", -- Using Noli walk as example
			Run = "134180042540255" -- Using Noli run as example
		}
	},

	-- Noli animations
	NoliAnimations = {
		Normal = {
			Idle = "106918107833755",
			Walk = "72602868477947", 
			Run = "126369311177328",
			Attack = "82796650227086"
		},
		Injured = {
			Idle = "106918107833755", -- Add injured animations here
			Walk = "72602868477947", 
			Run = "126369311177328",
			Attack = "82796650227086"
		}
	},

	Killers = {
		Noli = {
			Name = "Noli",
			Preview = "124491999410747",
			Animations = {
				Normal = {
					Idle = "106918107833755",
					Walk = "72602868477947", 
					Run = "126369311177328",
					Attack = "82796650227086"
				},
				Injured = {
					Idle = "106918107833755",
					Walk = "72602868477947", 
					Run = "126369311177328",
					Attack = "82796650227086"
				}
			}
		}
	}
}

-- Main script execution with error handling
local success, errorMessage = pcall(function()
	debugPrint("Script initialization started")

	local player = game.Players.LocalPlayer
	if not player then
		error("GUI_LOAD_FAILED", "Player not found")
		return
	end

	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	if not character then
		error("CHARACTER_NOT_FOUND", "Character not found")
		return
	end

	local humanoid = character:WaitForChild("Humanoid")
	if not humanoid then
		error("HUMANOID_NOT_FOUND", "Humanoid not found")
		return
	end

	if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		error("RIG_TYPE_ERROR", "This script works only for R6 characters!")
		return
	end

	debugPrint("Character validation passed")

	-- Create GUI
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ForexikenAnimations"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Check if GUI already exists
	if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ForexikenAnimations") then
		player.PlayerGui.ForexikenAnimations:Destroy()
		debugPrint("Existing GUI found and destroyed")
	end

	ScreenGui.Parent = player:WaitForChild("PlayerGui")
	debugPrint("ScreenGui created")

	-- Main window
	local okno = Instance.new("Frame")
	okno.Name = "okno"
	okno.Size = UDim2.new(0, 400, 0, 300)
	okno.Position = UDim2.new(0.5, -200, 0.5, -150)
	okno.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	okno.BorderSizePixel = 0
	okno.Active = true
	okno.Draggable = true
	okno.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = okno

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = Color3.fromRGB(80, 80, 80)
	UIStroke.Thickness = 2
	UIStroke.Parent = okno

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	title.BorderSizePixel = 0
	title.Text = "Forexiken Killers/Survivors Animations"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.Font = Enum.Font.Gotham
	title.Parent = okno

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title

	-- Close button
	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = "closeBtn"
	closeBtn.Size = UDim2.new(0, 20, 0, 20)
	closeBtn.Position = UDim2.new(1, -25, 0, 5)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Image = "rbxassetid://" .. Config.CloseButtonTexture
	closeBtn.Parent = title

	closeBtn.MouseButton1Click:Connect(function()
		debugPrint("Close button clicked")
		ScreenGui:Destroy()
	end)

	-- Minimize button
	local minimizeBtn = Instance.new("ImageButton")
	minimizeBtn.Name = "minimizeBtn"
	minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
	minimizeBtn.Position = UDim2.new(1, -50, 0, 5)
	minimizeBtn.BackgroundTransparency = 1
	minimizeBtn.Image = "rbxassetid://" .. Config.MinimizeButtonTexture
	minimizeBtn.Parent = title

	minimizeBtn.MouseButton1Click:Connect(function()
		debugPrint("Minimize button clicked")
		okno.Visible = false
		showWindowBtn.Visible = true
	end)

	-- Content frame
	local sodershanie = Instance.new("Frame")
	sodershanie.Name = "sodershanie"
	sodershanie.Size = UDim2.new(1, -20, 1, -50)
	sodershanie.Position = UDim2.new(0, 10, 0, 40)
	sodershanie.BackgroundTransparency = 1
	sodershanie.Parent = okno

	-- Killers Select frame
	local KillersSelect = Instance.new("Frame")
	KillersSelect.Name = "KillersSelect"
	KillersSelect.Size = UDim2.new(1, 0, 0, 200)
	KillersSelect.Position = UDim2.new(0, 0, 0, 0)
	KillersSelect.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	KillersSelect.BorderSizePixel = 0
	KillersSelect.Parent = sodershanie

	local KillersCorner = Instance.new("UICorner")
	KillersCorner.CornerRadius = UDim.new(0, 6)
	KillersCorner.Parent = KillersSelect

	local KillersStroke = Instance.new("UIStroke")
	KillersStroke.Color = Color3.fromRGB(70, 70, 70)
	KillersStroke.Thickness = 1
	KillersStroke.Parent = KillersSelect

	-- Noli preview
	local NoliPreview = Instance.new("ImageLabel")
	NoliPreview.Name = "Noli"
	NoliPreview.Size = UDim2.new(0, 100, 0, 100)
	NoliPreview.Position = UDim2.new(0, 20, 0, 20)
	NoliPreview.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	NoliPreview.BorderSizePixel = 0
	NoliPreview.Image = "rbxassetid://" .. Config.NoliPreview
	NoliPreview.Parent = KillersSelect

	local NoliCorner = Instance.new("UICorner")
	NoliCorner.CornerRadius = UDim.new(0, 6)
	NoliCorner.Parent = NoliPreview

	local NoliStroke = Instance.new("UIStroke")
	NoliStroke.Color = Color3.fromRGB(80, 80, 80)
	NoliStroke.Thickness = 1
	NoliStroke.Parent = NoliPreview

	-- Noli name
	local NoliName = Instance.new("TextLabel")
	NoliName.Name = "TextLabel"
	NoliName.Size = UDim2.new(0, 100, 0, 20)
	NoliName.Position = UDim2.new(0, 20, 0, 130)
	NoliName.BackgroundTransparency = 1
	NoliName.Text = "Noli"
	NoliName.TextColor3 = Color3.fromRGB(255, 255, 255)
	NoliName.TextSize = 14
	NoliName.Font = Enum.Font.Gotham
	NoliName.Parent = KillersSelect

	-- Buttons frame
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Name = "buttonsFrame"
	buttonsFrame.Size = UDim2.new(0, 150, 0, 120)
	buttonsFrame.Position = UDim2.new(0, 140, 0, 20)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.Parent = KillersSelect

	-- Start Survivor's Animations button
	local survivorBtn = Instance.new("TextButton")
	survivorBtn.Name = "TextButton"
	survivorBtn.Size = UDim2.new(1, 0, 0, 30)
	survivorBtn.Position = UDim2.new(0, 0, 0, 0)
	survivorBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	survivorBtn.BorderSizePixel = 0
	survivorBtn.Text = "Start Survivor's Animations"
	survivorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	survivorBtn.TextSize = 12
	survivorBtn.Font = Enum.Font.Gotham
	survivorBtn.Parent = buttonsFrame

	local survivorCorner = Instance.new("UICorner")
	survivorCorner.CornerRadius = UDim.new(0, 4)
	survivorCorner.Parent = survivorBtn

	-- Start Killer's Animations button
	local killerBtn = Instance.new("TextButton")
	killerBtn.Name = "TextButton"
	killerBtn.Size = UDim2.new(1, 0, 0, 30)
	killerBtn.Position = UDim2.new(0, 0, 0, 40)
	killerBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	killerBtn.BorderSizePixel = 0
	killerBtn.Text = "Start Killer's Animations"
	killerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	killerBtn.TextSize = 12
	killerBtn.Font = Enum.Font.Gotham
	killerBtn.Parent = buttonsFrame

	local killerCorner = Instance.new("UICorner")
	killerCorner.CornerRadius = UDim.new(0, 4)
	killerCorner.Parent = killerBtn

	-- Select button
	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "TextButton"
	selectBtn.Size = UDim2.new(1, 0, 0, 25)
	selectBtn.Position = UDim2.new(0, 0, 0, 80)
	selectBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	selectBtn.BorderSizePixel = 0
	selectBtn.Text = "Select"
	selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectBtn.TextSize = 12
	selectBtn.Font = Enum.Font.Gotham
	selectBtn.Parent = buttonsFrame

	local selectCorner = Instance.new("UICorner")
	selectCorner.CornerRadius = UDim.new(0, 4)
	selectCorner.Parent = selectBtn

	-- Selection frame
	local ramka = Instance.new("Frame")
	ramka.Name = "ramka"
	ramka.Size = UDim2.new(0, 104, 0, 104)
	ramka.Position = UDim2.new(0, 18, 0, 18)
	ramka.BackgroundTransparency = 1
	ramka.BorderColor3 = Color3.fromRGB(0, 255, 0)
	ramka.BorderSizePixel = 2
	ramka.Visible = false
	ramka.Parent = KillersSelect

	local ramkaCorner = Instance.new("UICorner")
	ramkaCorner.CornerRadius = UDim.new(0, 6)
	ramkaCorner.Parent = ramka

	-- Show window button (hidden initially)
	local showWindowBtn = Instance.new("TextButton")
	showWindowBtn.Name = "showWindowBtn"
	showWindowBtn.Size = UDim2.new(0, 40, 0, 40)
	showWindowBtn.Position = UDim2.new(0, 10, 1, -50)
	showWindowBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	showWindowBtn.BorderSizePixel = 0
	showWindowBtn.Text = "Show"
	showWindowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	showWindowBtn.TextSize = 10
	showWindowBtn.Visible = false
	showWindowBtn.Parent = ScreenGui

	local showCorner = Instance.new("UICorner")
	showCorner.CornerRadius = UDim.new(0, 4)
	showCorner.Parent = showWindowBtn

	-- Animation variables
	local currentAnimations = {}
	local currentAnimationTracks = {}
	local isKillerAnimations = false
	local selectedKiller = "Noli"
	local isInjured = false

	-- Stamina and speed variables
	local currentStamina = Config.SpeedSettings.StaminaMax
	local isRunning = false
	local isExhausted = false
	local lastStaminaUpdate = tick()

	-- Functions
	local function loadAnimation(animationId)
		if animationId == "0" or not animationId then
			debugPrint("Using default animation for ID: 0")
			return nil
		end

		local success, result = pcall(function()
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. animationId
			return humanoid:LoadAnimation(animation)
		end)

		if success and result then
			debugPrint("Animation loaded successfully: " .. animationId)
			return result
		else
			errorHandler("ANIMATION_LOAD_FAILED", "Failed to load animation: " .. animationId)
			return nil
		end
	end

	local function stopAllAnimations()
		debugPrint("Stopping all animations")
		for name, track in pairs(currentAnimationTracks) do
			if track and track.IsPlaying then
				track:Stop()
				debugPrint("Stopped animation: " .. name)
			end
		end
		currentAnimationTracks = {}
	end

	local function playAnimation(animationName)
		if currentAnimationTracks[animationName] and not currentAnimationTracks[animationName].IsPlaying then
			currentAnimationTracks[animationName]:Play()
			debugPrint("Playing animation: " .. animationName)
		end
	end

	local function stopAnimation(animationName)
		if currentAnimationTracks[animationName] and currentAnimationTracks[animationName].IsPlaying then
			currentAnimationTracks[animationName]:Stop()
			debugPrint("Stopped animation: " .. animationName)
		end
	end

	local function updateStamina()
		local currentTime = tick()
		local deltaTime = currentTime - lastStaminaUpdate
		lastStaminaUpdate = currentTime

		if isRunning and not isExhausted then
			-- Drain stamina when running
			currentStamina = math.max(0, currentStamina - Config.SpeedSettings.StaminaDrainPerSecond * deltaTime)
			debugPrint("Stamina draining: " .. currentStamina)

			if currentStamina <= 0 then
				isExhausted = true
				isRunning = false
				debugPrint("Exhausted! Can't run anymore")
			end
		else
			-- Regenerate stamina when not running
			if currentStamina < Config.SpeedSettings.StaminaMax then
				currentStamina = math.min(Config.SpeedSettings.StaminaMax, currentStamina + Config.SpeedSettings.StaminaRegenPerSecond * deltaTime)
				debugPrint("Stamina regenerating: " .. currentStamina)

				if currentStamina >= Config.SpeedSettings.StaminaMax * 0.3 then
					isExhausted = false
					debugPrint("No longer exhausted")
				end
			end
		end
	end

	local function updateSpeed()
		if isExhausted then
			humanoid.WalkSpeed = Config.SpeedSettings.ExhaustedSpeed
			debugPrint("Speed set to exhausted: " .. Config.SpeedSettings.ExhaustedSpeed)
		elseif isRunning then
			humanoid.WalkSpeed = Config.SpeedSettings.RunSpeed
			debugPrint("Speed set to run: " .. Config.SpeedSettings.RunSpeed)
		else
			humanoid.WalkSpeed = Config.SpeedSettings.NormalSpeed
			debugPrint("Speed set to normal: " .. Config.SpeedSettings.NormalSpeed)
		end
	end

	local function getCurrentAnimationSet()
		local health = humanoid.Health
		local newInjured = health <= Config.HealthThreshold

		if newInjured ~= isInjured then
			isInjured = newInjured
			debugPrint("Injured state changed: " .. tostring(isInjured))
		end

		if isKillerAnimations then
			local killerConfig = Config.Killers[selectedKiller]
			return isInjured and killerConfig.Animations.Injured or killerConfig.Animations.Normal
		else
			return isInjured and Config.SurvivorAnimations.Injured or Config.SurvivorAnimations.Normal
		end
	end

	local function applyKillerAnimations()
		debugPrint("Applying killer animations for: " .. selectedKiller)
		stopAllAnimations()
		isKillerAnimations = true

		local animSet = getCurrentAnimationSet()

		-- Load killer animations
		for animName, animId in pairs(animSet) do
			currentAnimationTracks[animName] = loadAnimation(animId)
		end

		-- Reset stamina and speed
		currentStamina = Config.SpeedSettings.StaminaMax
		isRunning = false
		isExhausted = false
		updateSpeed()

		-- Play idle animation initially
		playAnimation("Idle")
	end

	local function applySurvivorAnimations()
		debugPrint("Applying survivor animations")
		stopAllAnimations()
		isKillerAnimations = false

		local animSet = getCurrentAnimationSet()

		-- Load survivor animations
		for animName, animId in pairs(animSet) do
			currentAnimationTracks[animName] = loadAnimation(animId)
		end

		-- Reset stamina and speed
		currentStamina = Config.SpeedSettings.StaminaMax
		isRunning = false
		isExhausted = false
		updateSpeed()

		-- Play idle animation initially if not using default
		if animSet.Idle ~= "0" then
			playAnimation("Idle")
		end
	end

	-- Health monitoring
	local function checkHealth()
		local currentAnimSet = getCurrentAnimationSet()

		-- If health state changed, reapply animations
		if isKillerAnimations then
			applyKillerAnimations()
		else
			applySurvivorAnimations()
		end
	end

	-- Button connections
	selectBtn.MouseButton1Click:Connect(function()
		ramka.Visible = not ramka.Visible
		debugPrint("Select button clicked, ramka visible: " .. tostring(ramka.Visible))
	end)

	killerBtn.MouseButton1Click:Connect(function()
		debugPrint("Killer animations button clicked")
		applyKillerAnimations()
	end)

	survivorBtn.MouseButton1Click:Connect(function()
		debugPrint("Survivor animations button clicked")
		applySurvivorAnimations()
	end)

	showWindowBtn.MouseButton1Click:Connect(function()
		okno.Visible = true
		showWindowBtn.Visible = false
		debugPrint("Show window button clicked")
	end)

	-- Animation controllers
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 and isKillerAnimations then
			-- Attack on LMB
			debugPrint("LMB pressed - Attack")
			if currentAnimationTracks.Attack then
				stopAnimation("Idle")
				playAnimation("Attack")

				-- Return to idle after attack
				if currentAnimationTracks.Attack then
					currentAnimationTracks.Attack.Stopped:Connect(function()
						if isKillerAnimations then
							playAnimation("Idle")
						end
					end)
				end
			end
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			-- Run on Left Ctrl
			if not isExhausted and currentStamina > 0 then
				debugPrint("Left Ctrl pressed - Run")
				isRunning = true
				updateSpeed()

				if isKillerAnimations and currentAnimationTracks.Run and currentAnimationTracks.Walk then
					stopAnimation("Walk")
					stopAnimation("Idle")
					playAnimation("Run")
				end
			else
				debugPrint("Can't run - exhausted or no stamina")
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.LeftControl then
			-- Stop running when Left Ctrl released
			debugPrint("Left Ctrl released - Walk")
			isRunning = false
			updateSpeed()

			if isKillerAnimations and currentAnimationTracks.Run and currentAnimationTracks.Walk then
				stopAnimation("Run")
				playAnimation("Walk")
			end
		end
	end)

	-- Character movement detection
	local lastPosition = character:WaitForChild("HumanoidRootPart").Position
	local isMoving = false

	RunService.Heartbeat:Connect(function()
		-- Update stamina
		updateStamina()

		if not isKillerAnimations then return end

		local currentCharacter = player.Character
		if currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart") then
			local currentPosition = currentCharacter.HumanoidRootPart.Position
			local velocity = (currentPosition - lastPosition).Magnitude

			if velocity > 0.1 and not isMoving then
				-- Started moving
				isMoving = true
				debugPrint("Character started moving")
				stopAnimation("Idle")
				if isRunning then
					playAnimation("Run")
				else
					playAnimation("Walk")
				end
			elseif velocity <= 0.1 and isMoving then
				-- Stopped moving
				isMoving = false
				debugPrint("Character stopped moving")
				stopAnimation("Walk")
				stopAnimation("Run")
				playAnimation("Idle")
			end

			lastPosition = currentPosition
		end
	end)

	-- Health monitoring connection
	humanoid.HealthChanged:Connect(checkHealth)

	-- Character added event
	player.CharacterAdded:Connect(function(newCharacter)
		debugPrint("New character added")
		wait(1) -- Wait for character to fully load

		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid")

		-- Reconnect health monitoring
		humanoid.HealthChanged:Connect(checkHealth)

		-- Reset stamina and speed
		currentStamina = Config.SpeedSettings.StaminaMax
		isRunning = false
		isExhausted = false
		updateSpeed()

		-- Reapply current animations
		if isKillerAnimations then
			applyKillerAnimations()
		else
			applySurvivorAnimations()
		end
	end)

	-- Initial animation setup
	applySurvivorAnimations()
	debugPrint("Script initialized successfully")

end)

if not success then
	errorHandler("SCRIPT_INIT_FAILED", "Script initialization failed: " .. tostring(errorMessage))

	-- Self-destruct on critical error
	if game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("PlayerGui") then
		local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ForexikenAnimations")
		if gui then
			gui:Destroy()
		end
	end
end
