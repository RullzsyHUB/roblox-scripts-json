-- Auto Walk Record & Play System
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Variables
local isRecording = false
local isPlaying = false
local recordedData = {}
local recordingStartTime = 0
local playbackStartTime = 0
local playbackConnection = nil

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoWalkGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame Container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0.5, -125, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.BorderSizePixel = 0
title.Text = "Auto Walk System"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Record Toggle Button
local recordButton = Instance.new("TextButton")
recordButton.Size = UDim2.new(0, 220, 0, 40)
recordButton.Position = UDim2.new(0.5, -110, 0, 40)
recordButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
recordButton.BorderSizePixel = 1
recordButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
recordButton.Text = "Record: OFF"
recordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
recordButton.TextSize = 16
recordButton.Font = Enum.Font.Gotham
recordButton.Parent = mainFrame

-- Play Toggle Button
local playButton = Instance.new("TextButton")
playButton.Size = UDim2.new(0, 220, 0, 40)
playButton.Position = UDim2.new(0.5, -110, 0, 90)
playButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
playButton.BorderSizePixel = 1
playButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
playButton.Text = "Play Record: OFF"
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.TextSize = 16
playButton.Font = Enum.Font.Gotham
playButton.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 1, -20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- Functions
local function updateStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
end

local function startRecording()
    if isPlaying then
        updateStatus("Stop playback first!", Color3.fromRGB(255, 100, 100))
        return
    end
    
    isRecording = true
    recordedData = {}
    recordingStartTime = tick()
    
    recordButton.Text = "Record: ON"
    recordButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    updateStatus("Recording...", Color3.fromRGB(255, 100, 100))
end

local function stopRecording()
    isRecording = false
    
    recordButton.Text = "Record: OFF"
    recordButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    updateStatus("Recording stopped - " .. #recordedData .. " frames", Color3.fromRGB(150, 255, 150))
end

local function startPlayback()
    if #recordedData == 0 then
        updateStatus("No recording found!", Color3.fromRGB(255, 100, 100))
        return
    end
    
    if isRecording then
        updateStatus("Stop recording first!", Color3.fromRGB(255, 100, 100))
        return
    end
    
    isPlaying = true
    playbackStartTime = tick()
    
    playButton.Text = "Play Record: ON"
    playButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    updateStatus("Playing...", Color3.fromRGB(100, 255, 100))
    
    -- Start playback loop
    local frameIndex = 1
    playbackConnection = RunService.Heartbeat:Connect(function()
        if not isPlaying then return end
        
        local currentTime = tick() - playbackStartTime
        
        -- Find the appropriate frame
        while frameIndex <= #recordedData and recordedData[frameIndex].time <= currentTime do
            local frame = recordedData[frameIndex]
            
            -- Apply recorded data
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local hum = character:FindFirstChild("Humanoid")
                
                -- Set position and orientation
                hrp.CFrame = CFrame.new(frame.position) * CFrame.Angles(0, frame.rotation, 0)
                
                -- Set velocity
                hrp.AssemblyLinearVelocity = frame.velocity
                
                -- Set humanoid state
                if hum then
                    if frame.jumping then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    
                    -- Apply movement
                    hum:Move(frame.moveDirection, false)
                end
            end
            
            frameIndex = frameIndex + 1
        end
        
        -- Stop when finished
        if frameIndex > #recordedData then
            stopPlayback()
        end
    end)
end

local function stopPlayback()
    isPlaying = false
    
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end
    
    playButton.Text = "Play Record: OFF"
    playButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    updateStatus("Playback stopped", Color3.fromRGB(150, 255, 150))
end

-- Record Button Click
recordButton.MouseButton1Click:Connect(function()
    if isRecording then
        stopRecording()
    else
        startRecording()
    end
end)

-- Play Button Click
playButton.MouseButton1Click:Connect(function()
    if isPlaying then
        stopPlayback()
    else
        startPlayback()
    end
end)

-- Recording Loop
RunService.Heartbeat:Connect(function()
    if not isRecording then return end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    local hum = character:FindFirstChild("Humanoid")
    
    if hrp and hum then
        local currentTime = tick() - recordingStartTime
        
        -- Get rotation (Y axis only for smoother playback)
        local _, y, _ = hrp.CFrame:ToOrientation()
        
        -- Record frame data
        local frameData = {
            time = currentTime,
            position = hrp.Position,
            rotation = y,
            velocity = hrp.AssemblyLinearVelocity,
            moveDirection = hum.MoveDirection,
            jumping = hum:GetState() == Enum.HumanoidStateType.Jumping,
        }
        
        table.insert(recordedData, frameData)
    end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Stop any active recording/playback
    if isRecording then stopRecording() end
    if isPlaying then stopPlayback() end
end)

print("Auto Walk System loaded!")