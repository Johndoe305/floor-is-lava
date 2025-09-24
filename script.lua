-- LocalScript Combinado para The Floor is Lava (Speed, Jump, Infinite Jump, AutoWin, Auto Farm com Loop Contínuo, Coin Collector)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart", 5)
local humanoid = character:WaitForChild("Humanoid", 5)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configurações
local originalPosition = hrp.Position -- Posição original
local autoWinActive = false
local autoFarmActive = false
local infiniteJumpActive = false
local collectActive = false
local delayBetweenTeleports = 0.5 -- Delay para coleta de coins
local collectedCoins = 0
local totalCoins = 0
local coinList = {} -- Lista de coins
local autoFarmCooldown = 10 -- Cooldown do Auto Farm
local autoFarmCanTeleport = true
local autoFarmTimeRemaining = 0
local isAutoFarmLoopRunning = false -- Controla se o loop está rodando
local autoWinCFrame = CFrame.new(
    35.2371368, 233.955505, -187.988831,
    -0.999950469, 0, -0.00995137542,
    0, 1, 0,
    0.00995137542, 0, -0.999950469
)
local progressLabel = nil -- Label para Coin Collector
local autoFarmLabel = nil -- Label para Auto Farm cooldown

-- Função para verificar se o jogador está vivo
local function isPlayerAlive()
    local success, result = pcall(function()
        return humanoid and humanoid.Health > 0
    end)
    if not success then
        print("Erro ao verificar Humanoid:", result)
        return false
    end
    return result
end

-- Função para encontrar todos os coins
local function findAllCoins()
    local success, result = pcall(function()
        coinList = {}
        totalCoins = 0
        local currentMap = Workspace:WaitForChild("CurrentMap", 5)
        if not currentMap then
            print("Erro: CurrentMap não encontrado")
            return false
        end
        print("CurrentMap encontrado:", currentMap.Name)
        for _, subMap in pairs(currentMap:GetChildren()) do
            print("Verificando subMap:", subMap.Name)
            local coinsFolder = subMap:FindFirstChild("Coins")
            if coinsFolder then
                print("Coins folder encontrado em", subMap.Name)
                for _, coin in pairs(coinsFolder:GetChildren()) do
                    local coinPart
                    if coin:IsA("BasePart") then
                        coinPart = coin
                    elseif coin:FindFirstChild("Handle") then
                        coinPart = coin:FindFirstChild("Handle")
                    end
                    if coinPart then
                        table.insert(coinList, coinPart)
                        totalCoins = #coinList
                        print("Coin encontrado:", coin.Name, "em", subMap.Name, "Posição:", coinPart.Position)
                    else
                        print("Coin sem BasePart ou Handle:", coin.Name)
                    end
                end
            else
                print("Nenhuma pasta Coins em", subMap.Name)
            end
        end
        if progressLabel then
            progressLabel.Text = "Coins coletados: 0/" .. totalCoins
        end
        print("Total de coins encontrados:", totalCoins)
        return totalCoins > 0
    end)
    if not success then
        print("Erro ao buscar coins:", result)
        return false
    end
    return result
end

-- Função para coletar coins
local function collectCoins()
    if not collectActive or not isPlayerAlive() then
        collectActive = false
        if progressLabel then
            progressLabel.Text = "Coins coletados: " .. collectedCoins .. "/" .. totalCoins .. " (Parado)"
        end
        return
    end
    local success, err = pcall(function()
        if #coinList > 0 then
            local coin = coinList[1]
            if coin and coin.Parent then
                hrp.CFrame = coin.CFrame * CFrame.new(0, 0, -2) -- Teleport para 2 studs do coin
                print("Teleportado para coin:", coin.Name, "Posição:", coin.Position)
                collectedCoins = collectedCoins + 1
                if progressLabel then
                    progressLabel.Text = "Coins coletados: " .. collectedCoins .. "/" .. totalCoins
                end
                table.remove(coinList, 1)
                wait(delayBetweenTeleports)
                spawn(collectCoins) -- Continuar para o próximo coin
            else
                print("Coin inválido ou destruído:", coin and coin.Name or "nil")
                table.remove(coinList, 1)
                spawn(collectCoins)
            end
        else
            hrp.CFrame = CFrame.new(originalPosition)
            print("Todos os coins coletados! Voltando à posição original:", originalPosition)
            collectActive = false
            if progressLabel then
                progressLabel.Text = "Coins coletados: " .. collectedCoins .. "/" .. totalCoins .. " (Finalizado)"
            end
        end
    end)
    if not success then
        print("Erro ao coletar coins:", err)
        collectActive = false
        if progressLabel then
            progressLabel.Text = "Coins coletados: " .. collectedCoins .. "/" .. totalCoins
        end
    end
end

-- Função para Auto Farm cooldown
local function startAutoFarmCooldown()
    autoFarmCanTeleport = false
    autoFarmTimeRemaining = autoFarmCooldown
    while autoFarmTimeRemaining > 0 and autoFarmActive do
        if autoFarmLabel then
            autoFarmLabel.Text = "Aguarde: " .. autoFarmTimeRemaining .. "s"
        end
        task.wait(1)
        autoFarmTimeRemaining = autoFarmTimeRemaining - 1
    end
    if autoFarmLabel and autoFarmActive then
        autoFarmLabel.Text = "Auto Farm ativo" -- Indica que o loop está ativo
    end
    autoFarmCanTeleport = true
end

-- Função para realizar o teleporte do Auto Farm
local function performAutoFarmTeleport()
    local success, err = pcall(function()
        local obbyHead = Workspace:WaitForChild("Obby1", 5):WaitForChild("Head", 5)
        if obbyHead then
            originalPosition = hrp.CFrame
            hrp.CFrame = obbyHead.CFrame + Vector3.new(0, 5, 0)
            print("Auto Farm: Teleportado para Obby1.Head")
            if autoFarmLabel then
                autoFarmLabel.Text = "Teleportando..."
            end
            spawn(startAutoFarmCooldown)
        else
            print("Erro: Obby1.Head não encontrado")
            autoFarmActive = false
            autoFarmButton.Text = "Auto Farm: OFF"
            autoFarmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            if autoFarmLabel then
                autoFarmLabel.Text = "Obby1.Head não encontrado"
            end
        end
    end)
    if not success then
        print("Erro ao teleportar Auto Farm:", err)
        autoFarmActive = false
        autoFarmButton.Text = "Auto Farm: OFF"
        autoFarmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        if autoFarmLabel then
            autoFarmLabel.Text = "Erro ao teleportar"
        end
    end
end

-- Função para Auto Farm (loop contínuo)
local function autoFarmLoop()
    if isAutoFarmLoopRunning then return end -- Evita múltiplos loops
    isAutoFarmLoopRunning = true
    while autoFarmActive and isPlayerAlive() do
        if autoFarmCanTeleport then
            performAutoFarmTeleport() -- Teleporta automaticamente
        end
        task.wait(0.1) -- Aguarda para não travar o jogo
    end
    -- Quando autoFarmActive for false ou jogador morrer, reseta o estado
    isAutoFarmLoopRunning = false
    autoFarmCanTeleport = true
    autoFarmTimeRemaining = 0
    if autoFarmLabel then
        autoFarmLabel.Text = "Auto Farm desativado"
    end
    if isPlayerAlive() then
        hrp.CFrame = originalPosition
        print("Auto Farm: Retornado à posição original")
    end
end

-- Função para Infinite Jump
local function onJumpRequest()
    if infiniteJumpActive and isPlayerAlive() then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        print("Pulo infinito ativado")
    end
end
UserInputService.JumpRequest:Connect(onJumpRequest)

-- Função para AutoWin
local function updateAutoWin()
    if autoWinActive and isPlayerAlive() then
        local dist = (hrp.Position - autoWinCFrame.Position).Magnitude
        if dist > 10 then
            hrp.CFrame = autoWinCFrame + Vector3.new(0, 5, 0)
            print("AutoWin: Teleportado para", autoWinCFrame.Position)
        end
    end
end

-- GUI Unificada
local success, err = pcall(function()
    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "TheFloorIsLavaGui"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 360)
    frame.Position = UDim2.new(0.5, -150, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    local uiCorner = Instance.new("UICorner", frame)
    uiCorner.CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "🔥 The Floor is Lava"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24

    -- Seção Speed
    local speedBox = Instance.new("TextBox", frame)
    speedBox.Size = UDim2.new(0.6, -10, 0, 30)
    speedBox.Position = UDim2.new(0.05, 0, 0, 50)
    speedBox.PlaceholderText = "Speed (ex: 16)"
    speedBox.Text = ""
    speedBox.TextScaled = true
    speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    speedBox.TextColor3 = Color3.new(1, 1, 1)
    speedBox.Font = Enum.Font.SourceSans
    local speedCorner = Instance.new("UICorner", speedBox)
    speedCorner.CornerRadius = UDim.new(0, 8)

    local speedButton = Instance.new("TextButton", frame)
    speedButton.Size = UDim2.new(0.3, 0, 0, 30)
    speedButton.Position = UDim2.new(0.65, 0, 0, 50)
    speedButton.Text = "Aplicar"
    speedButton.TextScaled = true
    speedButton.TextColor3 = Color3.new(1, 1, 1)
    speedButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    local speedButtonCorner = Instance.new("UICorner", speedButton)
    speedButtonCorner.CornerRadius = UDim.new(0, 8)

    -- Seção JumpPower
    local jumpBox = Instance.new("TextBox", frame)
    jumpBox.Size = UDim2.new(0.6, -10, 0, 30)
    jumpBox.Position = UDim2.new(0.05, 0, 0, 90)
    jumpBox.PlaceholderText = "JumpPower (ex: 50)"
    jumpBox.Text = ""
    jumpBox.TextScaled = true
    jumpBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    jumpBox.TextColor3 = Color3.new(1, 1, 1)
    jumpBox.Font = Enum.Font.SourceSans
    local jumpCorner = Instance.new("UICorner", jumpBox)
    jumpCorner.CornerRadius = UDim.new(0, 8)

    local jumpButton = Instance.new("TextButton", frame)
    jumpButton.Size = UDim2.new(0.3, 0, 0, 30)
    jumpButton.Position = UDim2.new(0.65, 0, 0, 90)
    jumpButton.Text = "Aplicar"
    jumpButton.TextScaled = true
    jumpButton.TextColor3 = Color3.new(1, 1, 1)
    jumpButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    local jumpButtonCorner = Instance.new("UICorner", jumpButton)
    jumpButtonCorner.CornerRadius = UDim.new(0, 8)

    -- Seção Infinite Jump
    local infiniteJumpButton = Instance.new("TextButton", frame)
    infiniteJumpButton.Size = UDim2.new(0.9, 0, 0, 30)
    infiniteJumpButton.Position = UDim2.new(0.05, 0, 0, 130)
    infiniteJumpButton.Text = "Infinite Jump: OFF"
    infiniteJumpButton.TextScaled = true
    infiniteJumpButton.TextColor3 = Color3.new(1, 1, 1)
    infiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    local infiniteJumpCorner = Instance.new("UICorner", infiniteJumpButton)
    infiniteJumpCorner.CornerRadius = UDim.new(0, 8)

    -- Seção AutoWin
    local autoWinButton = Instance.new("TextButton", frame)
    autoWinButton.Size = UDim2.new(0.9, 0, 0, 30)
    autoWinButton.Position = UDim2.new(0.05, 0, 0, 170)
    autoWinButton.Text = "AutoWin: OFF"
    autoWinButton.TextScaled = true
    autoWinButton.TextColor3 = Color3.new(1, 1, 1)
    autoWinButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    local autoWinCorner = Instance.new("UICorner", autoWinButton)
    autoWinCorner.CornerRadius = UDim.new(0, 8)

    -- Seção Auto Farm
    local autoFarmButton = Instance.new("TextButton", frame)
    autoFarmButton.Size = UDim2.new(0.9, 0, 0, 30)
    autoFarmButton.Position = UDim2.new(0.05, 0, 0, 210)
    autoFarmButton.Text = "Auto Farm: OFF"
    autoFarmButton.TextScaled = true
    autoFarmButton.TextColor3 = Color3.new(1, 1, 1)
    autoFarmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    local autoFarmCorner = Instance.new("UICorner", autoFarmButton)
    autoFarmCorner.CornerRadius = UDim.new(0, 8)

    autoFarmLabel = Instance.new("TextLabel", frame)
    autoFarmLabel.Size = UDim2.new(0.9, 0, 0, 20)
    autoFarmLabel.Position = UDim2.new(0.05, 0, 0, 245)
    autoFarmLabel.Text = ""
    autoFarmLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    autoFarmLabel.BackgroundTransparency = 1
    autoFarmLabel.TextScaled = true
    autoFarmLabel.Font = Enum.Font.SourceSans

    -- Seção Coin Collector
    local coinCollectButton = Instance.new("TextButton", frame)
    coinCollectButton.Size = UDim2.new(0.9, 0, 0, 30)
    coinCollectButton.Position = UDim2.new(0.05, 0, 0, 270)
    coinCollectButton.Text = "Coin Collector: OFF"
    coinCollectButton.TextScaled = true
    coinCollectButton.TextColor3 = Color3.new(1, 1, 1)
    coinCollectButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    local coinCollectCorner = Instance.new("UICorner", coinCollectButton)
    coinCollectCorner.CornerRadius = UDim.new(0, 8)

    local delayBox = Instance.new("TextBox", frame)
    delayBox.Size = UDim2.new(0.9, 0, 0, 30)
    delayBox.Position = UDim2.new(0.05, 0, 0, 305)
    delayBox.PlaceholderText = "Delay (ex: 0.5)"
    delayBox.Text = tostring(delayBetweenTeleports)
    delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    delayBox.Font = Enum.Font.SourceSans
    delayBox.TextScaled = true
    local delayCorner = Instance.new("UICorner", delayBox)
    delayCorner.CornerRadius = UDim.new(0, 8)

    progressLabel = Instance.new("TextLabel", frame)
    progressLabel.Size = UDim2.new(0.9, 0, 0, 30)
    progressLabel.Position = UDim2.new(0.05, 0, 0, 340)
    progressLabel.Text = "Coins coletados: 0/0"
    progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressLabel.BackgroundTransparency = 1
    progressLabel.TextScaled = true
    progressLabel.Font = Enum.Font.SourceSans

    -- Suporte a arrastar no mobile
    local dragging = false
    local dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Ações dos botões
    speedButton.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            local val = tonumber(speedBox.Text)
            if val and isPlayerAlive() then
                humanoid.WalkSpeed = val
                print("Velocidade ajustada para", val)
            else
                print("Valor de velocidade inválido ou jogador morto")
            end
        end)
        if not success then
            print("Erro ao ajustar velocidade:", err)
        end
    end)

    jumpButton.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            local val = tonumber(jumpBox.Text)
            if val and isPlayerAlive() then
                humanoid.JumpPower = val
                print("JumpPower ajustado para", val)
            else
                print("Valor de JumpPower inválido ou jogador morto")
            end
        end)
        if not success then
            print("Erro ao ajustar JumpPower:", err)
        end
    end)

    infiniteJumpButton.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            infiniteJumpActive = not infiniteJumpActive
            infiniteJumpButton.Text = infiniteJumpActive and "Infinite Jump: ON" or "Infinite Jump: OFF"
            infiniteJumpButton.BackgroundColor3 = infiniteJumpActive and Color3.fromRGB(170, 0, 0) or Color3.fromRGB(70, 130, 180)
            print("Infinite Jump", infiniteJumpActive and "ativado" or "desativado")
        end)
        if not success then
            print("Erro ao ativar/desativar Infinite Jump:", err)
        end
    end)

    autoWinButton.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            autoWinActive = not autoWinActive
            autoWinButton.Text = autoWinActive and "AutoWin: ON" or "AutoWin: OFF"
            autoWinButton.BackgroundColor3 = autoWinActive and Color3.fromRGB(170, 0, 0) or Color3.fromRGB(70, 130, 180)
            print("AutoWin", autoWinActive and "ativado" or "desativado")
            if autoWinActive and isPlayerAlive() then
                originalPosition = hrp.CFrame
                hrp.CFrame = autoWinCFrame + Vector3.new(0, 5, 0)
            elseif not autoWinActive and isPlayerAlive() then
                hrp.CFrame = originalPosition
            end
        end)
        if not success then
            print("Erro ao ativar/desativar AutoWin:", err)
            autoWinActive = false
            autoWinButton.Text = "AutoWin: OFF"
            autoWinButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end
    end)

    autoFarmButton.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            if not autoFarmActive then
                -- Ativar Auto Farm
                autoFarmActive = true
                autoFarmButton.Text = "Auto Farm: ON"
                autoFarmButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                print("Auto Farm ativado")
                if autoWinActive then
                    autoWinActive = false
                    autoWinButton.Text = "AutoWin: OFF"
                    autoWinButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
                    print("AutoWin desativado para evitar conflito com Auto Farm")
                end
                if isPlayerAlive() and not isAutoFarmLoopRunning then
                    spawn(autoFarmLoop) -- Inicia o loop contínuo
                elseif isPlayerAlive() and not autoFarmCanTeleport then
                    print("Auto Farm: Aguarde o cooldown terminar")
                    if autoFarmLabel then
                        autoFarmLabel.Text = "Aguarde: " .. autoFarmTimeRemaining .. "s"
                    end
                end
            else
                -- Desativar Auto Farm
                autoFarmActive = false
                autoFarmButton.Text = "Auto Farm: OFF"
                autoFarmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
                print("Auto Farm desativado")
                if isPlayerAlive() then
                    hrp.CFrame = originalPosition
                    print("Auto Farm: Retornado à posição original")
                end
                autoFarmCanTeleport = true
                autoFarmTimeRemaining = 0
                if autoFarmLabel then
                    autoFarmLabel.Text = "Auto Farm desativado"
                end
            end
        end)
        if not success then
            print("Erro ao ativar/desativar Auto Farm:", err)
            autoFarmActive = false
            autoFarmButton.Text = "Auto Farm: OFF"
            autoFarmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            if autoFarmLabel then
                autoFarmLabel.Text = "Erro ao ativar Auto Farm"
            end
        end
    end)

    coinCollectButton.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            collectActive = not collectActive
            coinCollectButton.Text = collectActive and "Coin Collector: ON" or "Coin Collector: OFF"
            coinCollectButton.BackgroundColor3 = collectActive and Color3.fromRGB(170, 0, 0) or Color3.fromRGB(70, 130, 180)
            print("Coin Collector", collectActive and "ativado" or "desativado")
            if collectActive then
                if isPlayerAlive() and findAllCoins() then
                    collectedCoins = 0
                    originalPosition = hrp.CFrame
                    spawn(collectCoins)
                else
                    collectActive = false
                    coinCollectButton.Text = "Coin Collector: OFF"
                    coinCollectButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
                    print("Falha ao ativar Coin Collector: jogador morto ou nenhum coin encontrado")
                    if progressLabel then
                        progressLabel.Text = "Coins coletados: 0/0"
                    end
                end
            end
        end)
        if not success then
            print("Erro ao ativar/desativar Coin Collector:", err)
            collectActive = false
            coinCollectButton.Text = "Coin Collector: OFF"
            coinCollectButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            if progressLabel then
                progressLabel.Text = "Coins coletados: 0/0"
            end
        end
    end)

    delayBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(delayBox.Text)
            if num and num >= 0.1 and num <= 2 then
                delayBetweenTeleports = num
                print("Delay entre teleports ajustado para", delayBetweenTeleports, "s")
            else
                delayBox.Text = tostring(delayBetweenTeleports)
                print("Delay inválido, mantendo", delayBetweenTeleports, "s")
            end
        end
    end)
end)
if not success then
    print("Erro ao criar GUI:", err)
end

-- Loop para AutoWin
RunService.Heartbeat:Connect(function()
    local success, err = pcall(updateAutoWin)
    if not success then
        print("Erro no loop AutoWin:", err)
    end
end)

-- Atualizar character ao respawnar
LocalPlayer.CharacterAdded:Connect(function(newChar)
    local success, err = pcall(function()
        character = newChar
        hrp = character:WaitForChild("HumanoidRootPart", 5)
        humanoid = character:WaitForChild("Humanoid", 5)
        originalPosition = hrp.CFrame
        collectActive = false
        autoWinActive = false
        autoFarmActive = false
        isAutoFarmLoopRunning = false
        if progressLabel then
            progressLabel.Text = "Coins coletados: 0/0 (Respawn)"
        end
        if autoWinButton then
            autoWinButton.Text = "AutoWin: OFF"
            autoWinButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end
        if autoFarmButton then
            autoFarmButton.Text = "Auto Farm: OFF"
            autoFarmButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end
        if coinCollectButton then
            coinCollectButton.Text = "Coin Collector: OFF"
            coinCollectButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end
    end)
    if success then
        print("Personagem atualizado, posição original salva:", originalPosition)
    else
        print("Erro ao atualizar personagem:", err)
    end
end)

-- Monitorar mudanças no CurrentMap
Workspace:WaitForChild("CurrentMap", 5).Changed:Connect(function()
    print("CurrentMap mudou, verificando coins novamente")
    if collectActive then
        findAllCoins()
    end
end)

-- Depuração inicial
print("Script Combinado para The Floor is Lava ativado!")
print("Estrutura inicial: CurrentMap =", Workspace:FindFirstChild("CurrentMap"))
print("Obby1 =", Workspace:FindFirstChild("Obby1"))
if Workspace:FindFirstChild("CurrentMap") then
    for _, subMap in pairs(Workspace.CurrentMap:GetChildren()) do
        print("SubMap:", subMap.Name, "Coins =", subMap:FindFirstChild("Coins"))
    end
end
