-- Anticheat bypass
local d = false
local h = {}
local x, y
setthreadidentity(2)
for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
        if typeof(a) == "function" and not x then
            x = a
            local o; o = hookfunction(x, function(c, f, n)
                if c ~= "_" then
                    if d then warn(`Adonis flagged\nMethod: {c}\nInfo: {f}`) end
                end
                return true
            end)
            table.insert(h, x)
        end
        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f)
                if d then warn(`Adonis tried to kill: {f}`) end
            end)
            table.insert(h, y)
        end
    end
end
local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...
    if x and a == x then return coroutine.yield(coroutine.running()) end
    return o(...)
end))
setthreadidentity(7)
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(2)
local Player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local scriptSource = readfile and readfile("nznt_officefarm.lua") or ""
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        warn("Detected kick, rejoining...")
        if queue_on_teleport then queue_on_teleport(scriptSource) end
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
end)
local function safeFireServer(remote, ...) local args = {...} task.spawn(function() setthreadidentity(2) remote:FireServer(unpack(args)) setthreadidentity(7) end) end
warn("1. Firing menuToggleRequest...")

local menuToggleRemote = RS:WaitForChild("menuToggleRequest")
safeFireServer(menuToggleRemote)
task.wait(1)
warn("2. Firing TeamChangeRequest...")
local teamChangeRemote = RS:WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
safeFireServer(teamChangeRemote, "Office Worker", 0, 0, 0, "MainMenu")
task.wait(3)
warn("3. Waiting for character...")
repeat task.wait(0.5) until Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Humanoid")
local POS_CHAIR = Vector3.new(-5927.33, 4.57, -228.61)
local PRINTER_POS = {Print_1 = Vector3.new(-6008.84, 4.58, -210.84), Print_2 = Vector3.new(-6008.84, 4.58, -224.52), Print_3 = Vector3.new(-6008.84, 4.58, -238.36), Print_4 = Vector3.new(-5868.43, 4.58, -213.19), Print_5 = Vector3.new(-5868.43, 4.58, -249.96)}
local JE = RS:WaitForChild("JobEvents")
local remCorrectAnswer = JE:WaitForChild("CorrectAnswer")
local remGenQuestion = JE:WaitForChild("GenerateQuestion")
local remAssignPrint = JE:WaitForChild("AssignPrintJob")
local pendingPrint, active, currentSeat = nil, true, nil
local function getChar() return Player.Character or Player.CharacterAdded:Wait() end
local function teleportTo(pos) getChar():WaitForChild("HumanoidRootPart").CFrame = CFrame.new(pos) end
local function solveQuestion(q) local a, op, b = q:match("(%d+)%s*([%+%-%*%/])%s*(%d+)") if not a then return nil end a, b = tonumber(a), tonumber(b) if op == "+" then return a + b elseif op == "-" then return a - b elseif op == "*" then return a * b elseif op == "/" then return math.floor(a / b) end end
local function findAnswerID(answers, val) for _, ans in pairs(answers) do if typeof(ans) == "table" and tonumber(ans.Text) == val then return ans.ID end end end
remGenQuestion.OnClientEvent:Connect(function(question, answers, sessionId) pcall(function() warn("Question: " .. tostring(question)) local val = solveQuestion(question) warn("Solved: " .. tostring(val)) local id = findAnswerID(answers, val) warn("Answer ID: " .. tostring(id)) if id then safeFireServer(remCorrectAnswer, id, sessionId) warn("Fired CorrectAnswer") task.spawn(function() local char = getChar() local hum = char:FindFirstChild("Humanoid") if hum and hum.Health > 0 and currentSeat then hum.Jump = true currentSeat:Sit(hum) end end) end end) end)
remAssignPrint.OnClientEvent:Connect(function(printerName) warn("Print job: " .. tostring(printerName)) pendingPrint = printerName end)
task.spawn(function() while active do local char = getChar() local hum = char:WaitForChild("Humanoid") warn("4. Finding seat...") local seat = nil for _, obj in pairs(workspace:GetDescendants()) do if (obj:IsA("Seat") or obj:IsA("VehicleSeat")) and (obj.Position - POS_CHAIR).Magnitude < 10 then seat = obj break end end if seat then currentSeat = seat warn("5. Teleporting to chair...") teleportTo(POS_CHAIR) task.wait(0.5) if hum and hum.Health > 0 then seat:Sit(hum) warn("Seated! Starting autofarm...") end else warn("No seat found!") task.wait(3) end while active do if pendingPrint then local pos = PRINTER_POS[pendingPrint] local computers = workspace:FindFirstChild("Computers") local printerObj = computers and computers:FindFirstChild(pendingPrint) local prompt = printerObj and printerObj:FindFirstChild("Part") and printerObj.Part:FindFirstChildOfClass("ProximityPrompt") warn("Going to printer: " .. pendingPrint) hum.Jump = true task.wait(1) if pos then teleportTo(pos) warn("Teleported to printer") end task.wait(0.5) if prompt then warn("Firing proximityprompt") fireproximityprompt(prompt) task.wait(1.5) end pendingPrint = nil warn("Returning to chair...") teleportTo(POS_CHAIR) task.wait(2) hum.Jump = true task.wait(0.5) if seat and hum and hum.Health > 0 then seat:Sit(hum) warn("Re-seated!") end task.wait(0.5) else if hum.SeatPart == nil then warn("Got unseated, re-sitting...") if seat and hum and hum.Health > 0 then seat:Sit(hum) task.wait(0.5) else break end end end task.wait(0.2) end task.wait(1) end end)
warn("=== Office farm started ===")
