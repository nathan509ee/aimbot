-- UI e Serviços
local UI = game:GetObjects("rbxassetid://2989692423")[1]
local Services = setmetatable(game:GetChildren(), {
    __index = function(self, ServiceName)
        local Valid, Service = pcall(game.GetService, game, ServiceName)
        if Valid then
            self[ServiceName] = Service
            return Service
        end
    end
})

local Me = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Code = Services.HttpService:GenerateGUID(true)
local DeltaSens
local Holding = false
local TargetPlayer = nil

-- Configurações
local Settings = setmetatable({
    Set = function(self, Setting, Value)
        local Label = UI[Setting]
        if Setting:sub(#Setting - 2) == "Key" then
            Label.State.Text = Value.Name
        else
            Label.State.Text = Value and "ON" or "OFF"
            Label.State.TextColor3 = Value and Color3.new(0,1,0) or Color3.new(1,0,0)
        end
    end,
    Hook = function(self, Setting, Function)
        return UI[Setting].State:GetPropertyChangedSignal("Text"):Connect(function()
                Function(UI[Setting].State.Text == "ON")
        end)
    end
}, {
    __index = function(self, Setting)
        if Setting:sub(#Setting - 2) == "Key" then
            local Setting = UI[Setting].State.Text
            return Setting ~= "Awaiting input..." and ((Setting:match("MouseButton") and Enum.UserInputType[Setting]) or Enum.KeyCode[Setting])
        elseif UI[Setting]:FindFirstChild("Slide") then
            return tonumber(UI[Setting].Value.Text)
        else
            return UI[Setting].State.Text == "ON"
        end
    end
})

-- Utility Functions
local Utility = {
    GetClosestPlayer = function(self)
        local MousePos = Services.UserInputService:GetMouseLocation()
        local Players = Services.Players:GetPlayers()
        local Selected, Distance = nil, Settings.MaxDistance
        for i = 1, #Players do
            local Player = Players[i]
            local Character = Player.Character or workspace:FindFirstChild(Player.Name, true)
            local Head = Character and (Character:FindFirstChild(Settings.AimForHead and "Head" or "HumanoidRootPart", true) or Character.PrimaryPart)
            if (Player ~= Me) and (self:IsValidHead(Head)) and ((Settings.TeamCheck and Player.TeamColor ~= Me.TeamColor) or (not Settings.TeamCheck)) then
                local Point, Visible = Camera:WorldToScreenPoint(Head.Position)
                if Visible then
                    local SelectedDistance = (Vector2.new(Point.X, Point.Y) - MousePos).Magnitude
                    local Eval = SelectedDistance <= Distance
                    Selected = Eval and Head or Selected
                    Distance = Eval and SelectedDistance or Distance
                end
            end
        end
        return Selected
    end,
    IsValidHead = function(self, Head)
        if not Head then
            return false
        end
        local Character = Head:FindFirstAncestorOfClass("Model")
        local Humanoid = Character and (Character:FindFirstChildWhichIsA("Humanoid",true) or {Health = (Character:FindFirstChild("Health",true) or {Value = 1}).Value})
        local _, Visible = Camera:WorldToViewportPoint(Head.Position)
        return Humanoid and Visible and Humanoid.Health > 0
    end
}

-- Círculo de FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = Settings.CircleRadius
FOVCircle.Filled = Settings.CircleFilled
FOVCircle.Color = Settings.CircleColor
FOVCircle.Visible = Settings.CircleVisible
FOVCircle.Transparency = Settings.CircleTransparency
FOVCircle.NumSides = Settings.CircleSides
FOVCircle.Thickness = Settings.CircleThickness

-- Função de movimento da câmera (Aimbot)
local function MoveCameraToTarget()
    local targetPart = TargetPlayer.Character:FindFirstChild(Settings.AimPart)
    if targetPart then
        local targetPos = targetPart.Position
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        local tweenInfo = TweenInfo.new(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local tweenGoal = {CFrame = targetCFrame}
        local tween = TweenService:Create(Camera, tweenInfo, tweenGoal)
        tween:Play()
    end
end

-- Controles de Entrada
Services.UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

-- RenderStep (Aimbot com controle de FOV)
Services.RunService.RenderStepped:Connect(function()
    -- Atualizando o círculo FOV
    FOVCircle.Position = Vector2.new(Services.UserInputService:GetMouseLocation().X, Services.UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = Settings.CircleRadius
    FOVCircle.Filled = Settings.CircleFilled
    FOVCircle.Color = Settings.CircleColor
    FOVCircle.Visible = Settings.CircleVisible
    FOVCircle.Transparency = Settings.CircleTransparency
    FOVCircle.NumSides = Settings.CircleSides
    FOVCircle.Thickness = Settings.CircleThickness

    -- Aimbot (Somente enquanto o botão direito do mouse estiver pressionado)
    if Holding and Settings.Functionality then
        local closestPlayer = Utility:GetClosestPlayer()
        if closestPlayer then
            TargetPlayer = closestPlayer
            MoveCameraToTarget()
        end
    end
end)

-- Ação de ativar/desativar o aimbot
Services.ContextActionService:BindAction(Code.."CloseOpen", function(_, State)
    if State == Enum.UserInputState.Begin and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        UI.Visible = not UI.Visible
    end
end, false, Enum.KeyCode.Tab)

-- Configuração inicial da UI
Settings:Set("TeamCheck", #Services.Teams:GetChildren() > 0)
UI.Name = Code
UI.Parent = game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui")
