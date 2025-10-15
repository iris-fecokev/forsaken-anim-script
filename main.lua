-- Foremen Animations Universal Loader
-- GitHub: https://raw.githubusercontent.com/yourusername/yourrepo/main/foremen_animations.lua

(function()
    -- Проверка на наличие необходимых сервисов
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Конфигурация анимаций
    local Config = {
        Killers = {
            Zero = {
                Name = "Zero",
                Preview = "124491999410747",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "616161997",
                    Jump = "0",
                    Fall = "0",
                    Land = "0"
                }
            },
            Ghost = {
                Name = "Ghost",
                Preview = "124491999410747",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "616161997",
                    Jump = "0",
                    Fall = "0",
                    Land = "0"
                }
            },
        },
        
        Survivors = {
            Default = {
                Name = "Default Survivor",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "616161997",
                    Jump = "0",
                    Fall = "0",
                    Land = "0"
                }
            },
            Runner = {
                Name = "Runner",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "616161997",
                    Jump = "0",
                    Fall = "0",
                    Land = "0"
                }
            }
        }
    }

    -- Система анимаций
    local currentAnimSet = Config.Survivors.Default.Animations
    local ANIM_TRACKS = {}
    local currentTrack = nil
    local isRunning = false
    local jumpLock = false

    -- Переменные персонажа
    local CHARACTER, HUMANOID, ROOT_PART, ANIMATOR

    -- Дебаг-система
    local DEBUG = {
        enabled = false,
        lastState = "",
        lastVelocity = Vector3.new(),
        lastUpdate = tick(),
        lastGroundCheck = 0
    }

    local function logDebug(message, force)
        if not DEBUG.enabled and not force then return end
        if not ROOT_PART then return end
        
        local now = tick()
        local delta = now - DEBUG.lastUpdate
        DEBUG.lastUpdate = now

        local vel = ROOT_PART.Velocity
        local hVel = Vector3.new(vel.X, 0, vel.Z).Magnitude
        local state = HUMANOID and HUMANOID:GetState() or Enum.HumanoidStateType.None

        print(string.format("[ForemenAnim] %s | VY: %.1f | H: %.1f | State: %s", message, vel.Y, hVel, tostring(state)))
    end

    -- Функция загрузки анимаций
    local function loadAnimations(animSet)
        if not ANIMATOR then return end
        
        -- Останавливаем все текущие анимации
        for name, track in pairs(ANIM_TRACKS) do
            if track and track.IsPlaying then
                track:Stop(0.1)
            end
        end
        
        ANIM_TRACKS = {}
        currentAnimSet = animSet
        
        -- Загружаем новые анимации
        for name, id in pairs(animSet) do
            if id and id ~= "0" then
                local success, result = pcall(function()
                    local animation = Instance.new("Animation")
                    animation.AnimationId = "rbxassetid://" .. id
                    return ANIMATOR:LoadAnimation(animation)
                end)
                
                if success then
                    ANIM_TRACKS[name] = result
                else
                    warn("[ForemenAnim] Failed to load animation: " .. name)
                end
            end
        end
        
        -- Установка приоритетов
        if ANIM_TRACKS.Jump then ANIM_TRACKS.Jump.Priority = Enum.AnimationPriority.Action4 end
        if ANIM_TRACKS.Land then ANIM_TRACKS.Land.Priority = Enum.AnimationPriority.Action3 end
        if ANIM_TRACKS.Fall then ANIM_TRACKS.Fall.Priority = Enum.AnimationPriority.Action2 end
        if ANIM_TRACKS.Run then ANIM_TRACKS.Run.Priority = Enum.AnimationPriority.Movement end
        if ANIM_TRACKS.Walk then ANIM_TRACKS.Walk.Priority = Enum.AnimationPriority.Movement end
        if ANIM_TRACKS.Idle then ANIM_TRACKS.Idle.Priority = Enum.AnimationPriority.Idle end
        if ANIM_TRACKS.Attack then ANIM_TRACKS.Attack.Priority = Enum.AnimationPriority.Action end
        
        logDebug("🔄 Animations loaded: " .. tostring(animSet.Walk), true)
    end

    -- Функция проигрывания анимации
    local function playAnimation(name, fadeTime)
        if not ANIM_TRACKS[name] then return end

        -- Защита от повторного запуска прыжка
        if name == "Jump" and jumpLock then
            return
        end

        -- Не перезапускать ту же анимацию
        if currentTrack == ANIM_TRACKS[name] and currentTrack.IsPlaying then
            return
        end

        -- Остановка текущей анимации
        if currentTrack and currentTrack.IsPlaying then
            currentTrack:Stop(fadeTime or 0.1)
        end

        -- Запуск новой анимации
        ANIM_TRACKS[name]:Play(fadeTime or 0.15)
        currentTrack = ANIM_TRACKS[name]

        -- Блокировка прыжка
        if name == "Jump" then
            jumpLock = true
            delay(0.5, function() jumpLock = false end)
        end
    end

    -- Проверка нахождения на земле
    local function isGrounded()
        if not HUMANOID or not ROOT_PART then return false end
        
        if tick() - DEBUG.lastGroundCheck < 0.1 then
            return HUMANOID.FloorMaterial ~= Enum.Material.Air
        end

        DEBUG.lastGroundCheck = tick()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {CHARACTER}

        local origin = ROOT_PART.Position
        local direction = Vector3.new(0, -4.5, 0)
        local ray = workspace:Raycast(origin, direction, params)

        return ray and ray.Instance ~= nil
    end

    -- Инициализация системы анимаций
    local function initAnimationSystem()
        local runSpeed = 40
        local walkSpeed = 16
        
        -- Обработка ввода для бега (ЛЕВЫЙ CTRL)
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.LeftControl then
                isRunning = true
                if HUMANOID then
                    HUMANOID.WalkSpeed = runSpeed
                end
                logDebug("🏃‍♂️ Run activated")
            end
        end)

        UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.LeftControl then
                isRunning = false
                if HUMANOID then
                    HUMANOID.WalkSpeed = walkSpeed
                end
                logDebug("🚶‍♂️ Run deactivated")
            end
        end)

        -- Основной обработчик состояний
        RunService.Heartbeat:Connect(function(deltaTime)
            if not CHARACTER or not HUMANOID or not ROOT_PART then return end
            
            local vel = ROOT_PART.Velocity
            local hVel = Vector3.new(vel.X, 0, vel.Z).Magnitude
            local grounded = isGrounded()
            local moving = HUMANOID.MoveDirection.Magnitude > 0.2
            local verticalState = "GROUND"

            -- Воздушные состояния
            if not grounded then
                if vel.Y > 10 then
                    verticalState = "JUMP_UP"
                elseif vel.Y < -10 then
                    verticalState = "FALL_DOWN"
                else
                    verticalState = "AIR_NEUTRAL"
                end
            end

            -- Логика анимаций
            if verticalState == "JUMP_UP" and ANIM_TRACKS.Jump then
                playAnimation("Jump", 0.1)
            elseif verticalState == "FALL_DOWN" and ANIM_TRACKS.Fall then
                playAnimation("Fall", 0.1)
            elseif grounded then
                if moving then
                    if isRunning and ANIM_TRACKS.Run then
                        playAnimation("Run", 0.1)
                    elseif ANIM_TRACKS.Walk then
                        playAnimation("Walk", 0.1)
                    end
                elseif ANIM_TRACKS.Idle then
                    playAnimation("Idle", 0.1)
                end
            end
        end)

        -- Обработчик прыжка
        HUMANOID.Jumping:Connect(function()
            logDebug("⬆️ Jump detected")
            if ANIM_TRACKS.Jump then
                playAnimation("Jump")
            end
        end)

        -- Обработчик приземления
        HUMANOID.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Landed then
                logDebug("🟢 Land detected")
                if ANIM_TRACKS.Land then
                    playAnimation("Land", 0.05)
                end
            end
        end)

        -- Обработка смерти персонажа
        HUMANOID.Died:Connect(function()
            logDebug("☠️ Character died", true)
            if currentTrack then
                currentTrack:Stop()
            end
        end)

        -- Обработка смены персонажа
        player.CharacterAdded:Connect(function(character)
            CHARACTER = character
            HUMANOID = character:WaitForChild("Humanoid")
            ROOT_PART = character:WaitForChild("HumanoidRootPart")
            ANIMATOR = HUMANOID:FindFirstChild("Animator") or Instance.new("Animator", HUMANOID)
            
            -- Перезагружаем анимации для нового персонажа
            loadAnimations(currentAnimSet)
            logDebug("🔁 Character changed - reloaded animations", true)
        end)

        if HUMANOID then
            HUMANOID.WalkSpeed = walkSpeed
        end
        logDebug("🚀 Animation system started", true)
    end

    -- Создание GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForemenAnimations"
    screenGui.Parent = playerGui

    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Parent = mainFrame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "FOREMEN ANIMATIONS"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    -- Кнопки управления окном
    local closeButton = Instance.new("ImageButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -30, 0, 8)
    closeButton.Image = "rbxassetid://118955245038416"
    closeButton.BackgroundTransparency = 1
    closeButton.Parent = mainFrame

    local minimizeButton = Instance.new("ImageButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 25, 0, 25)
    minimizeButton.Position = UDim2.new(1, -60, 0, 8)
    minimizeButton.Image = "rbxassetid://74729089697042"
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.Parent = mainFrame

    -- Область выбора
    local selectionFrame = Instance.new("Frame")
    selectionFrame.Name = "SelectionFrame"
    selectionFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
    selectionFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    selectionFrame.BackgroundTransparency = 1
    selectionFrame.Parent = mainFrame

    -- Кнопка убийц
    local killerButton = Instance.new("TextButton")
    killerButton.Name = "KillerButton"
    killerButton.Size = UDim2.new(1, 0, 0, 45)
    killerButton.Position = UDim2.new(0, 0, 0, 0)
    killerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    killerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    killerButton.Text = "START KILLER'S ANIMATIONS"
    killerButton.Font = Enum.Font.GothamBold
    killerButton.TextSize = 14
    killerButton.Parent = selectionFrame

    -- Кнопка выживших
    local survivorButton = Instance.new("TextButton")
    survivorButton.Name = "SurvivorButton"
    survivorButton.Size = UDim2.new(1, 0, 0, 45)
    survivorButton.Position = UDim2.new(0, 0, 0, 60)
    survivorButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    survivorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    survivorButton.Text = "START SURVIVOR'S ANIMATIONS"
    survivorButton.Font = Enum.Font.GothamBold
    survivorButton.TextSize = 14
    survivorButton.Parent = selectionFrame

    -- Фрейм выбора убийцы
    local killerSelectFrame = Instance.new("Frame")
    killerSelectFrame.Name = "KillerSelectFrame"
    killerSelectFrame.Size = UDim2.new(1, 0, 0, 300)
    killerSelectFrame.Position = UDim2.new(0, 0, 0, 120)
    killerSelectFrame.BackgroundTransparency = 1
    killerSelectFrame.Visible = false
    killerSelectFrame.Parent = selectionFrame

    local killerScroll = Instance.new("ScrollingFrame")
    killerScroll.Name = "KillerScroll"
    killerScroll.Size = UDim2.new(1, 0, 1, 0)
    killerScroll.BackgroundTransparency = 1
    killerScroll.ScrollBarThickness = 5
    killerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    killerScroll.Parent = killerSelectFrame

    local killerListLayout = Instance.new("UIListLayout")
    killerListLayout.Padding = UDim.new(0, 5)
    killerListLayout.Parent = killerScroll

    -- Фрейм выбора выжившего
    local survivorSelectFrame = Instance.new("Frame")
    survivorSelectFrame.Name = "SurvivorSelectFrame"
    survivorSelectFrame.Size = UDim2.new(1, 0, 0, 300)
    survivorSelectFrame.Position = UDim2.new(0, 0, 0, 120)
    survivorSelectFrame.BackgroundTransparency = 1
    survivorSelectFrame.Visible = false
    survivorSelectFrame.Parent = selectionFrame

    local survivorScroll = Instance.new("ScrollingFrame")
    survivorScroll.Name = "SurvivorScroll"
    survivorScroll.Size = UDim2.new(1, 0, 1, 0)
    survivorScroll.BackgroundTransparency = 1
    survivorScroll.ScrollBarThickness = 5
    survivorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    survivorScroll.Parent = survivorSelectFrame

    local survivorListLayout = Instance.new("UIListLayout")
    survivorListLayout.Padding = UDim.new(0, 5)
    survivorListLayout.Parent = survivorScroll

    -- Кнопка восстановления
    local restoreButton = Instance.new("TextButton")
    restoreButton.Name = "RestoreButton"
    restoreButton.Size = UDim2.new(0, 120, 0, 35)
    restoreButton.Position = UDim2.new(0, 10, 0, 10)
    restoreButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    restoreButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    restoreButton.Text = "SHOW MENU"
    restoreButton.Visible = false
    restoreButton.Font = Enum.Font.Gotham
    restoreButton.TextSize = 12
    restoreButton.Parent = screenGui

    -- Функция для эффектов при наведении на кнопки
    local function setupButtonHover(button)
        local originalColor = button.BackgroundColor3
        local hoverColor = Color3.fromRGB(80, 80, 80)
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = originalColor
        end)
    end

    -- Создание кнопок для убийцов
    local function createKillerButtons()
        for killerName, killerData in pairs(Config.Killers) do
            local killerBtn = Instance.new("TextButton")
            killerBtn.Size = UDim2.new(1, -10, 0, 50)
            killerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            killerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            killerBtn.Text = killerData.Name
            killerBtn.Font = Enum.Font.Gotham
            killerBtn.TextSize = 12
            killerBtn.Parent = killerScroll
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = killerBtn
            
            killerBtn.MouseButton1Click:Connect(function()
                loadAnimations(killerData.Animations)
                killerSelectFrame.Visible = false
                survivorSelectFrame.Visible = false
                logDebug("🔪 Killer selected: " .. killerData.Name, true)
            end)
            
            setupButtonHover(killerBtn)
        end
    end

    -- Создание кнопок для выживших
    local function createSurvivorButtons()
        for survivorName, survivorData in pairs(Config.Survivors) do
            local survivorBtn = Instance.new("TextButton")
            survivorBtn.Size = UDim2.new(1, -10, 0, 50)
            survivorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            survivorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            survivorBtn.Text = survivorData.Name
            survivorBtn.Font = Enum.Font.Gotham
            survivorBtn.TextSize = 12
            survivorBtn.Parent = survivorScroll
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = survivorBtn
            
            survivorBtn.MouseButton1Click:Connect(function()
                loadAnimations(survivorData.Animations)
                survivorSelectFrame.Visible = false
                killerSelectFrame.Visible = false
                logDebug("🏃 Survivor selected: " .. survivorData.Name, true)
            end)
            
            setupButtonHover(survivorBtn)
        end
    end

    -- Обработчики кнопок GUI
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        restoreButton.Visible = true
    end)

    restoreButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        restoreButton.Visible = false
    end)

    killerButton.MouseButton1Click:Connect(function()
        killerSelectFrame.Visible = not killerSelectFrame.Visible
        survivorSelectFrame.Visible = false
    end)

    survivorButton.MouseButton1Click:Connect(function()
        survivorSelectFrame.Visible = not survivorSelectFrame.Visible
        killerSelectFrame.Visible = false
    end)

    -- Создаем углы для кнопок
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = killerButton
    buttonCorner:Clone().Parent = survivorButton

    local restoreCorner = Instance.new("UICorner")
    restoreCorner.CornerRadius = UDim.new(0, 6)
    restoreCorner.Parent = restoreButton

    -- Настраиваем эффекты наведения
    setupButtonHover(killerButton)
    setupButtonHover(survivorButton)
    setupButtonHover(restoreButton)

    -- Создаем кнопки выбора
    createKillerButtons()
    createSurvivorButtons()

    -- Обновляем размер скролла
    killerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        killerScroll.CanvasSize = UDim2.new(0, 0, 0, killerListLayout.AbsoluteContentSize.Y)
    end)

    survivorListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        survivorScroll.CanvasSize = UDim2.new(0, 0, 0, survivorListLayout.AbsoluteContentSize.Y)
    end)

    -- Добавляем обработку клика вне кнопок для закрытия меню выбора
    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            
            local isClickInKillerFrame = killerSelectFrame.Visible and 
                killerSelectFrame.AbsolutePosition.X <= mousePos.X and 
                mousePos.X <= killerSelectFrame.AbsolutePosition.X + killerSelectFrame.AbsoluteSize.X and
                killerSelectFrame.AbsolutePosition.Y <= mousePos.Y and 
                mousePos.Y <= killerSelectFrame.AbsolutePosition.Y + killerSelectFrame.AbsoluteSize.Y
                
            local isClickInSurvivorFrame = survivorSelectFrame.Visible and 
                survivorSelectFrame.AbsolutePosition.X <= mousePos.X and 
                mousePos.X <= survivorSelectFrame.AbsolutePosition.X + survivorSelectFrame.AbsoluteSize.X and
                survivorSelectFrame.AbsolutePosition.Y <= mousePos.Y and 
                mousePos.Y <= survivorSelectFrame.AbsolutePosition.Y + survivorSelectFrame.AbsoluteSize.Y
            
            if not isClickInKillerFrame and not isClickInSurvivorFrame then
                killerSelectFrame.Visible = false
                survivorSelectFrame.Visible = false
            end
        end
    end

    UserInputService.InputBegan:Connect(onInputBegan)

    -- Инициализация системы
    local function initialize()
        CHARACTER = player.Character or player.CharacterAdded:Wait()
        HUMANOID = CHARACTER:WaitForChild("Humanoid")
        ROOT_PART = CHARACTER:WaitForChild("HumanoidRootPart")
        ANIMATOR = HUMANOID:FindFirstChild("Animator") or Instance.new("Animator", HUMANOID)
        
        loadAnimations(currentAnimSet)
        initAnimationSystem()
        
        print("🎮 Foremen Animations loaded successfully!")
        print("📖 Controls: Left Ctrl - Run")
        print("🎯 Select animations from the GUI")
    end

    -- Запуск инициализации
    initialize()

end)()
