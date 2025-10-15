-- Foremen Animations Universal Loader
-- GitHub: https://raw.githubusercontent.com/yourusername/yourrepo/main/foremen_animations.lua

local success, error = pcall(function()
    -- Проверка на наличие необходимых сервисов
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    
    local player = Players.LocalPlayer
    while not player do
        wait(1)
        player = Players.LocalPlayer
    end
    
    local playerGui = player:WaitForChild("PlayerGui")

    -- Конфигурация анимаций
    local Config = {
        Killers = {
            Zero = {
                Name = "Zero",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "616161997",
                    Jump = "616156119",
                    Fall = "616157476",
                    Land = "616158929"
                }
            },
            Ghost = {
                Name = "Ghost",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "6323269776", -- Анимация удара
                    Jump = "616156119",
                    Fall = "616157476",
                    Land = "616158929"
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
                    Attack = "6323269776", -- Анимация удара
                    Jump = "616156119",
                    Fall = "616157476",
                    Land = "616158929"
                }
            },
            Runner = {
                Name = "Runner",
                Animations = {
                    Idle = "616158929",
                    Walk = "72602868477947",
                    Run = "126369311177328",
                    Attack = "6323269776", -- Анимация удара
                    Jump = "616156119",
                    Fall = "616157476",
                    Land = "616158929"
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
    local attackCooldown = false

    -- Переменные персонажа
    local CHARACTER, HUMANOID, ROOT_PART, ANIMATOR

    -- Инициализация персонажа
    local function initializeCharacter()
        CHARACTER = player.Character
        if not CHARACTER then
            player.CharacterAdded:Wait()
            CHARACTER = player.Character
        end
        
        HUMANOID = CHARACTER:WaitForChild("Humanoid")
        ROOT_PART = CHARACTER:WaitForChild("HumanoidRootPart")
        ANIMATOR = HUMANOID:FindFirstChild("Animator") or Instance.new("Animator")
        ANIMATOR.Parent = HUMANOID
        
        -- Установка начальной скорости
        HUMANOID.WalkSpeed = 16
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
                    local track = ANIMATOR:LoadAnimation(animation)
                    
                    -- Установка приоритетов
                    if name == "Jump" then
                        track.Priority = Enum.AnimationPriority.Action4
                    elseif name == "Fall" then
                        track.Priority = Enum.AnimationPriority.Action3
                    elseif name == "Attack" then
                        track.Priority = Enum.AnimationPriority.Action2
                    elseif name == "Land" then
                        track.Priority = Enum.AnimationPriority.Action1
                    elseif name == "Run" or name == "Walk" then
                        track.Priority = Enum.AnimationPriority.Movement
                    else
                        track.Priority = Enum.AnimationPriority.Idle
                    end
                    
                    return track
                end)
                
                if success then
                    ANIM_TRACKS[name] = result
                else
                    warn("[ForemenAnim] Failed to load animation: " .. name .. " - " .. tostring(result))
                end
            end
        end
        
        print("[ForemenAnim] Animations loaded successfully!")
    end

    -- Функция проигрывания анимации
    local function playAnimation(name, fadeTime)
        if not ANIM_TRACKS[name] then return end
        if not HUMANOID or HUMANOID.Health <= 0 then return end

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
        local success, err = pcall(function()
            ANIM_TRACKS[name]:Play(fadeTime or 0.15)
        end)
        
        if success then
            currentTrack = ANIM_TRACKS[name]
        else
            warn("[ForemenAnim] Failed to play animation: " .. name .. " - " .. err)
        end

        -- Блокировка прыжка
        if name == "Jump" then
            jumpLock = true
            delay(0.5, function() jumpLock = false end)
        end
        
        -- Блокировка атаки
        if name == "Attack" then
            attackCooldown = true
            delay(0.6, function() attackCooldown = false end)
        end
    end

    -- Проверка нахождения на земле
    local function isGrounded()
        if not HUMANOID or not ROOT_PART then return false end
        return HUMANOID.FloorMaterial ~= Enum.Material.Air
    end

    -- Инициализация системы анимаций
    local function initAnimationSystem()
        local runSpeed = 40
        local walkSpeed = 16
        
        -- Обработка ввода для бега (ЛЕВЫЙ CTRL)
        local runConnection
        runConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.LeftControl then
                isRunning = true
                if HUMANOID then
                    HUMANOID.WalkSpeed = runSpeed
                end
            end
        end)

        local runEndConnection
        runEndConnection = UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.LeftControl then
                isRunning = false
                if HUMANOID then
                    HUMANOID.WalkSpeed = walkSpeed
                end
            end
        end)
        
        -- Обработка атаки (ЛКМ)
        local attackConnection
        attackConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not attackCooldown and ANIM_TRACKS.Attack and HUMANOID and HUMANOID.Health > 0 then
                    playAnimation("Attack", 0.1)
                end
            end
        end)

        -- Основной обработчик состояний
        local heartbeatConnection
        heartbeatConnection = RunService.Heartbeat:Connect(function()
            if not CHARACTER or not HUMANOID or not ROOT_PART or HUMANOID.Health <= 0 then return end
            
            local vel = ROOT_PART.Velocity
            local grounded = isGrounded()
            local moving = HUMANOID.MoveDirection.Magnitude > 0.1
            
            -- Если атака активна, не меняем другие анимации
            if ANIM_TRACKS.Attack and ANIM_TRACKS.Attack.IsPlaying then
                return
            end

            -- Воздушные состояния
            if not grounded then
                if vel.Y > 5 then
                    playAnimation("Jump", 0.1)
                elseif vel.Y < -5 then
                    playAnimation("Fall", 0.1)
                end
            else
                if moving then
                    if isRunning and ANIM_TRACKS.Run then
                        playAnimation("Run", 0.1)
                    elseif ANIM_TRACKS.Walk then
                        playAnimation("Walk", 0.1)
                    end
                elseif ANIM_TRACKS.Idle then
                    playAnimation("Idle", 0.2)
                end
            end
        end)

        -- Обработчик прыжка
        local jumpConnection
        jumpConnection = HUMANOID.Jumping:Connect(function()
            if ANIM_TRACKS.Jump then
                playAnimation("Jump")
            end
        end)

        -- Обработчик приземления
        local stateConnection
        stateConnection = HUMANOID.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Landed then
                if ANIM_TRACKS.Land then
                    playAnimation("Land", 0.05)
                end
            end
        end)

        -- Обработка смерти персонажа
        local diedConnection
        diedConnection = HUMANOID.Died:Connect(function()
            if currentTrack then
                currentTrack:Stop()
            end
        end)

        -- Обработка смены персонажа
        local characterConnection
        characterConnection = player.CharacterAdded:Connect(function(character)
            -- Отключаем старые соединения
            if runConnection then runConnection:Disconnect() end
            if runEndConnection then runEndConnection:Disconnect() end
            if attackConnection then attackConnection:Disconnect() end
            if heartbeatConnection then heartbeatConnection:Disconnect() end
            if jumpConnection then jumpConnection:Disconnect() end
            if stateConnection then stateConnection:Disconnect() end
            if diedConnection then diedConnection:Disconnect() end
            
            wait(1) -- Ждем полной загрузки персонажа
            
            initializeCharacter()
            loadAnimations(currentAnimSet)
            initAnimationSystem() -- Перезапускаем систему для нового персонажа
        end)
    end

    -- Создание GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForemenAnimations"
    screenGui.Parent = playerGui

    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Parent = mainFrame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "FOREMEN ANIMATIONS"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title

    -- Кнопки управления окном
    local closeButton = Instance.new("ImageButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.Image = "http://www.roblox.com/asset/?id=118955245038416"
    closeButton.BackgroundTransparency = 1
    closeButton.Parent = mainFrame

    local minimizeButton = Instance.new("ImageButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 25, 0, 25)
    minimizeButton.Position = UDim2.new(1, -60, 0, 5)
    minimizeButton.Image = "http://www.roblox.com/asset/?id=74729089697042"
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.Parent = mainFrame

    -- Область выбора
    local selectionFrame = Instance.new("Frame")
    selectionFrame.Name = "SelectionFrame"
    selectionFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
    selectionFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    selectionFrame.BackgroundTransparency = 1
    selectionFrame.Parent = mainFrame

    -- Кнопка убийц
    local killerButton = Instance.new("TextButton")
    killerButton.Name = "KillerButton"
    killerButton.Size = UDim2.new(1, 0, 0, 40)
    killerButton.Position = UDim2.new(0, 0, 0, 0)
    killerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    killerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    killerButton.Text = "KILLER ANIMATIONS"
    killerButton.Font = Enum.Font.GothamBold
    killerButton.TextSize = 12
    killerButton.Parent = selectionFrame

    -- Кнопка выживших
    local survivorButton = Instance.new("TextButton")
    survivorButton.Name = "SurvivorButton"
    survivorButton.Size = UDim2.new(1, 0, 0, 40)
    survivorButton.Position = UDim2.new(0, 0, 0, 50)
    survivorButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    survivorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    survivorButton.Text = "SURVIVOR ANIMATIONS"
    survivorButton.Font = Enum.Font.GothamBold
    survivorButton.TextSize = 12
    survivorButton.Parent = selectionFrame

    -- Фрейм выбора убийцы
    local killerSelectFrame = Instance.new("Frame")
    killerSelectFrame.Name = "KillerSelectFrame"
    killerSelectFrame.Size = UDim2.new(1, 0, 0, 200)
    killerSelectFrame.Position = UDim2.new(0, 0, 0, 110)
    killerSelectFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    killerSelectFrame.Visible = false
    killerSelectFrame.Parent = selectionFrame

    local killerScroll = Instance.new("ScrollingFrame")
    killerScroll.Name = "KillerScroll"
    killerScroll.Size = UDim2.new(1, 0, 1, 0)
    killerScroll.BackgroundTransparency = 1
    killerScroll.ScrollBarThickness = 4
    killerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    killerScroll.Parent = killerSelectFrame

    local killerListLayout = Instance.new("UIListLayout")
    killerListLayout.Padding = UDim.new(0, 5)
    killerListLayout.Parent = killerScroll

    -- Фрейм выбора выжившего
    local survivorSelectFrame = Instance.new("Frame")
    survivorSelectFrame.Name = "SurvivorSelectFrame"
    survivorSelectFrame.Size = UDim2.new(1, 0, 0, 200)
    survivorSelectFrame.Position = UDim2.new(0, 0, 0, 110)
    survivorSelectFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    survivorSelectFrame.Visible = false
    survivorSelectFrame.Parent = selectionFrame

    local survivorScroll = Instance.new("ScrollingFrame")
    survivorScroll.Name = "SurvivorScroll"
    survivorScroll.Size = UDim2.new(1, 0, 1, 0)
    survivorScroll.BackgroundTransparency = 1
    survivorScroll.ScrollBarThickness = 4
    survivorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    survivorScroll.Parent = survivorSelectFrame

    local survivorListLayout = Instance.new("UIListLayout")
    survivorListLayout.Padding = UDim.new(0, 5)
    survivorListLayout.Parent = survivorScroll

    -- Кнопка восстановления
    local restoreButton = Instance.new("TextButton")
    restoreButton.Name = "RestoreButton"
    restoreButton.Size = UDim2.new(0, 100, 0, 30)
    restoreButton.Position = UDim2.new(0, 10, 0, 10)
    restoreButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    restoreButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    restoreButton.Text = "SHOW MENU"
    restoreButton.Visible = false
    restoreButton.Font = Enum.Font.Gotham
    restoreButton.TextSize = 11
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
            killerBtn.Size = UDim2.new(0.95, 0, 0, 40)
            killerBtn.Position = UDim2.new(0.025, 0, 0, 0)
            killerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            killerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            killerBtn.Text = killerData.Name
            killerBtn.Font = Enum.Font.Gotham
            killerBtn.TextSize = 11
            killerBtn.Parent = killerScroll
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = killerBtn
            
            killerBtn.MouseButton1Click:Connect(function()
                loadAnimations(killerData.Animations)
                killerSelectFrame.Visible = false
                survivorSelectFrame.Visible = false
            end)
            
            setupButtonHover(killerBtn)
        end
    end

    -- Создание кнопок для выживших
    local function createSurvivorButtons()
        for survivorName, survivorData in pairs(Config.Survivors) do
            local survivorBtn = Instance.new("TextButton")
            survivorBtn.Size = UDim2.new(0.95, 0, 0, 40)
            survivorBtn.Position = UDim2.new(0.025, 0, 0, 0)
            survivorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            survivorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            survivorBtn.Text = survivorData.Name
            survivorBtn.Font = Enum.Font.Gotham
            survivorBtn.TextSize = 11
            survivorBtn.Parent = survivorScroll
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = survivorBtn
            
            survivorBtn.MouseButton1Click:Connect(function()
                loadAnimations(survivorData.Animations)
                survivorSelectFrame.Visible = false
                killerSelectFrame.Visible = false
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
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = killerButton
    buttonCorner:Clone().Parent = survivorButton

    local restoreCorner = Instance.new("UICorner")
    restoreCorner.CornerRadius = UDim.new(0, 5)
    restoreCorner.Parent = restoreButton

    local killerFrameCorner = Instance.new("UICorner")
    killerFrameCorner.CornerRadius = UDim.new(0, 6)
    killerFrameCorner.Parent = killerSelectFrame

    local survivorFrameCorner = Instance.new("UICorner")
    survivorFrameCorner.CornerRadius = UDim.new(0, 6)
    survivorFrameCorner.Parent = survivorSelectFrame

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
    initializeCharacter()
    loadAnimations(currentAnimSet)
    initAnimationSystem()

    print("🎮 Foremen Animations loaded successfully!")
    print("📖 Controls: Left Ctrl - Toggle Run | LMB - Attack")
    print("💡 Use the GUI to select different animations")

end)

if not success then
    warn("[ForemenAnim] Error loading script: " .. tostring(error))
else
    print("✅ Foremen Animations loaded without errors!")
end
