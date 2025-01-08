local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

_G.AimbotEnabled = true
_G.TeamCheck = false -- Se ativado, só mira nos membros da equipe inimiga
_G.AimPart = "Head" -- Parte do corpo para mira
_G.Sensitivity = 0.0 -- Ajuste a sensibilidade (tempo em segundos para mover para o alvo)
_G.CircleSides = 80 -- Lados do círculo FOV
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- Cor do círculo FOV
_G.CircleTransparency = 0.7 -- Transparência do círculo
_G.CircleRadius = 120 -- Raio do círculo FOV
_G.CircleFilled = false -- Se o círculo deve ser preenchido
_G.CircleVisible = true -- Se o círculo é visível
_G.CircleThickness = 1 -- Espessura do círculo

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

local function GetClosestPlayer()
    local maxDistance = _G.CircleRadius
    local target = nil
    local closestDist = maxDistance

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if _G.TeamCheck == false or (player.Team ~= LocalPlayer.Team) then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
                    if humanoid.Health > 0 then
                        local targetPart = character:FindFirstChild(_G.AimPart)
                        if targetPart then
                            -- Calcule a distância entre o jogador local e o alvo (em studs)
                            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
                            
                            -- Verifique se a distância é menor que 100 studs
                            if distance <= 100 then
                                local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                                if onScreen then
                                    local mouseDist = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                                    if mouseDist < closestDist then
                                        closestDist = mouseDist
                                        target = player
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return target
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- Atualizando a posição e as propriedades do círculo FOV
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    -- Aimbot: Só ativa quando o botão direito do mouse (MouseButton2) estiver pressionado
    if Holding and _G.AimbotEnabled then
        local targetPlayer = GetClosestPlayer()
        if targetPlayer then
            local targetPart = targetPlayer.Character:FindFirstChild(_G.AimPart)
            if targetPart then
                -- Posição do alvo
                local targetPos = targetPart.Position
                -- Cálculo da direção para o alvo
                local direction = (targetPos - Camera.CFrame.Position).unit
                -- Ajustar a CFrame da câmera para olhar diretamente para o alvo
                local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                
                -- Garantir que a câmera sempre olha para o alvo, sem mover demais
                Camera.CFrame = newCFrame
            end
        end
    end
end)
