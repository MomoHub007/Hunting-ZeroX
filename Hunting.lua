local print = function() end
local warn = function() end

local BASE = (getgenv and getgenv().MacUIBase) or "https://raw.githubusercontent.com/Kiwzu/Mac-OS-UI-LUA/refs/heads/main/"

local MacUI = loadstring(game:HttpGet(BASE .. "MacUIFramework.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE .. "SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(BASE .. "InterfaceManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE .. "ThemeManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[Zero X] This UI must run on the client.")
    return
end
local Options = MacUI.Options

--------------------------------------------------------------------------------
-- Original theme definitions retained unchanged.
--------------------------------------------------------------------------------

local rgb = Color3.fromRGB
MacUI:AddTheme("Ocean", {
	Background = rgb(14, 26, 40),
	Sidebar = rgb(19, 34, 52),
	SidebarDivider = rgb(8, 16, 26),
	Group = rgb(22, 39, 58),
	GroupStroke = rgb(34, 56, 80),
	Separator = rgb(36, 58, 82),
	SubText = rgb(150, 172, 196),
	Tertiary = rgb(96, 120, 146),
	Control = rgb(44, 70, 98),
	ControlHover = rgb(54, 84, 116),
	ControlStroke = rgb(58, 88, 120),
	Button = rgb(40, 66, 94),
	ButtonHover = rgb(50, 80, 112),
	Field = rgb(12, 22, 34),
	FieldStroke = rgb(40, 64, 90),
	Search = rgb(28, 48, 70),
	SwitchOff = rgb(44, 70, 98),
	Track = rgb(40, 64, 90),
	SegmentBg = rgb(30, 52, 76),
	SegmentSelected = rgb(64, 98, 134),
	Menu = rgb(22, 39, 58),
	MenuStroke = rgb(48, 76, 106),
	Code = rgb(10, 19, 30),
}, "Dark")

MacUI:AddTheme("Rose", {
	Background = rgb(252, 245, 247),
	Sidebar = rgb(246, 231, 236),
	Group = rgb(255, 255, 255),
	Search = rgb(238, 222, 228),
	SegmentBg = rgb(240, 225, 231),
}, "Light")

--------------------------------------------------------------------------------
-- Window: original theme, accent, layout and sizing retained.
--------------------------------------------------------------------------------

local Window = MacUI:CreateWindow({
	Title = "Zero X",
	SubTitle = "",
	Icon = "command", -- Lucide icon name, rbxassetid:// or a number
	IconColor = "Blue", -- tile colour for that icon (dock, dialogs)
	Size = UDim2.fromOffset(820, 600),
	MinSize = Vector2.new(620, 420),
	TabWidth = 214, -- sidebar width
	Theme = "Dark", -- "Dark" | "Light" | "Midnight" | "Ocean" | "Rose"
	Accent = "Blue", -- accent name, hex string or Color3
	SidebarStyle = "Tile", -- "Tile" | "Tinted" | "Plain"
	Profile = { Title = LocalPlayer.DisplayName, Subtitle = "@" .. LocalPlayer.Name }, -- or true
	MinimizeKey = Enum.KeyCode.RightControl,
	Acrylic = false, -- frosted-glass sidebar (graphics quality 8+)
	KeybindList = false, -- floating list of keybinds and shortcuts
	Search = true, -- toolbar search field
	SearchPlaceholder = "Search",
	Spotlight = true, -- Ctrl/Cmd + K command palette
	SpotlightKey = Enum.KeyCode.K,
	Resizable = true,
	ConfirmClose = true, -- the red button asks before unloading
	ReplaceExisting = true, -- running the script again replaces this window
	ShowDock = false, -- dock icon while minimised
	Loading = false,
	Undo = true, -- Ctrl + Z / Ctrl + Shift + Z for changes you make
	PerformanceGuard = true, -- pause blur and animations if the game slows down
})

--------------------------------------------------------------------------------
-- ANTI AFK: เปิดอัตโนมัติระหว่างใช้งานสคริปต์
--------------------------------------------------------------------------------
do
    local virtualUser = game:GetService("VirtualUser")
    local active = true
    local lastAttempt = -math.huge
    local warned = false

    local idleConnection = LocalPlayer.Idled:Connect(function()
        if not active or os.clock() - lastAttempt < 30 then
            return
        end

        lastAttempt = os.clock()

        local camera = workspace.CurrentCamera
        if not camera then return end

        local ok, err = pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(
                Vector2.new(0, 0),
                camera.CFrame
            )
        end)

        if not ok then
            if not warned then
                warned = true
                warn("[Zero X / Anti AFK] Input unavailable: "
                    .. tostring(err))
            end
            return
        end

        warned = false
        print("[Zero X / Anti AFK] Idle input sent")
    end)

    MacUI:OnUnload(function()
        active = false
        idleConnection:Disconnect()
    end)

    print("[Zero X / Anti AFK] Enabled")
end

--------------------------------------------------------------------------------
-- ZERO X: macOS-style logo / draggable / visible while UI is hidden
--------------------------------------------------------------------------------

do
	local screenGui = Window.ScreenGui

	if screenGui and screenGui:IsA("ScreenGui") then
		local UserInputService = game:GetService("UserInputService")
		local TweenService = game:GetService("TweenService")

		-- ปรับค่าเองตรงนี้
		local LOGO_IMAGE = "rbxassetid://138334792995002"
		local ICON_SIZE = 64
		local TOP_OFFSET = 12
		local DRAG_THRESHOLD = 6
		local EDGE_MARGIN = 8

		local connections = {}

		local function Connect(signal, callback)
			local connection = signal:Connect(callback)
			table.insert(connections, connection)
			return connection
		end

		-- ตัวครอบ: รวมไอคอนและชื่อไว้ด้วยกัน
		local holder = Instance.new("Frame")
		holder.Name = "ZeroXLogoHolder"
		holder.Size = UDim2.fromOffset(ICON_SIZE + 12, ICON_SIZE + 28)
		holder.Position = UDim2.new(
			0.5,
			-(ICON_SIZE + 12) / 2,
			0,
			TOP_OFFSET
		)
		holder.BackgroundTransparency = 1
		holder.Visible = Window.Shown == false
		holder.ZIndex = 50
		holder.Parent = screenGui

		-- เงาแบบซ้อนชั้น ใช้เฉพาะ Frame ไม่โหลดรูปเพิ่ม
		local shadow = Instance.new("Frame")
		shadow.Name = "Shadow"
		shadow.Position = UDim2.fromOffset(4, 5)
		shadow.Size = UDim2.fromOffset(ICON_SIZE + 4, ICON_SIZE + 4)
		shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		shadow.BackgroundTransparency = 0.65
		shadow.BorderSizePixel = 0
		shadow.ZIndex = 50
		shadow.Parent = holder

		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = UDim.new(0, 20)
		shadowCorner.Parent = shadow

		-- พื้นผิวไอคอน
		local logoButton = Instance.new("ImageButton")
		logoButton.Name = "ZeroXLogoButton"
		logoButton.Position = UDim2.fromOffset(6, 0)
		logoButton.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
		logoButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		logoButton.BorderSizePixel = 0
		logoButton.Image = ""
		logoButton.AutoButtonColor = false
		logoButton.Active = true
		logoButton.ZIndex = 51
		logoButton.Parent = holder


		-- Keep the input target fixed; animate only its visual surface.
		logoButton.BackgroundTransparency = 1
		local visual = Instance.new("Frame")
		visual.Name = "LogoSurface"
		visual.AnchorPoint = Vector2.new(0.5, 0.5)
		visual.Position = UDim2.fromScale(0.5, 0.5)
		visual.Size = UDim2.fromScale(1, 1)
		visual.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		visual.BorderSizePixel = 0
		visual.ZIndex = 51
		visual.Parent = logoButton

		local visualScale = Instance.new("UIScale")
		visualScale.Parent = visual

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 18)
		corner.Parent = visual

		local surface = Instance.new("UIGradient")
		surface.Rotation = 90
		surface.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		surface.Parent = visual

		local border = Instance.new("UIStroke")
		border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		border.Color = Color3.fromRGB(190, 190, 195)
		border.Transparency = 0.65
		border.Thickness = 1
		border.Parent = visual

		-- แยกรูปจากพื้นหลัง เพื่อไม่ให้ Gradient เปลี่ยนสีโลโก้
		local logoImage = Instance.new("ImageLabel")
		logoImage.Name = "Logo"
		logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
		logoImage.Position = UDim2.fromScale(0.5, 0.5)
		logoImage.Size = UDim2.fromOffset(ICON_SIZE - 12, ICON_SIZE - 12)
		logoImage.BackgroundTransparency = 1
		logoImage.Image = LOGO_IMAGE
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.ZIndex = 52
		logoImage.Parent = visual

		local sheen = Instance.new("Frame")
		sheen.Name = "HoverSheen"
		sheen.Size = UDim2.fromScale(1, 1)
		sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		sheen.BorderSizePixel = 0
		sheen.ZIndex = 53
		sheen.Parent = visual
		local sheenCorner = Instance.new("UICorner")
		sheenCorner.CornerRadius = UDim.new(0, 18)
		sheenCorner.Parent = sheen
		local sheenGradient = Instance.new("UIGradient")
		sheenGradient.Rotation = 25
		sheenGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 1),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(0.65, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		sheenGradient.Offset = Vector2.new(-1.5, 0)
		sheenGradient.Parent = sheen

		-- One tween per target; rapid hover changes cancel the previous tween.
		local effectTweens = {}
		local hovered = false
		local function Animate(target, properties, instant, duration)
			if effectTweens[target] then
				effectTweens[target]:Cancel()
				effectTweens[target] = nil
			end
			if instant then
				for key, value in pairs(properties) do
					target[key] = value
				end
				return
			end
			local tween = TweenService:Create(target,
				TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				properties)
			effectTweens[target] = tween
			tween:Play()
		end

		local function SetEffect(pressed, instant)
			local highlighted = hovered or pressed
			Animate(visualScale, { Scale = pressed and 0.96 or (hovered and 1.08 or 1) }, instant)
			Animate(visual, {
				Position = UDim2.new(0.5, 0, 0.5, pressed and 0 or (hovered and -3 or 0)),
			}, instant)
			Animate(border, {
				Color = highlighted and Color3.fromRGB(95, 175, 255) or Color3.fromRGB(190, 190, 195),
				Transparency = highlighted and 0.12 or 0.65,
				Thickness = highlighted and 1.8 or 1,
			}, instant)
			Animate(shadow, {
				BackgroundTransparency = highlighted and 0.5 or 0.65,
				Position = UDim2.fromOffset(4, hovered and 8 or 5),
			}, instant)
		end

		local function ResetEffects()
			hovered = false
			SetEffect(false, true)
			Animate(sheenGradient, { Offset = Vector2.new(-1.5, 0) }, true)
		end


		-- ลากโดยใช้ระยะจากจุดกดเริ่มต้น
		local activeInput
		local startPointer
		local startPosition
		local moved = false

		local function SetPositionClamped(position)
			local bounds = screenGui.AbsoluteSize
			local size = holder.AbsoluteSize

			local marginX = math.min(
				EDGE_MARGIN,
				math.max(0, (bounds.X - size.X) / 2)
			)
			local marginY = math.min(
				EDGE_MARGIN,
				math.max(0, (bounds.Y - size.Y) / 2)
			)

			local x = math.clamp(
				position.X,
				marginX,
				math.max(marginX, bounds.X - size.X - marginX)
			)
			local y = math.clamp(
				position.Y,
				marginY,
				math.max(marginY, bounds.Y - size.Y - marginY)
			)

			holder.Position = UDim2.fromOffset(x, y)
		end

		local function GetLocalPosition()
			local bounds = screenGui.AbsoluteSize
			local position = holder.Position

			return Vector2.new(
				position.X.Scale * bounds.X + position.X.Offset,
				position.Y.Scale * bounds.Y + position.Y.Offset
			)
		end

		local function ResetDrag()
			activeInput = nil
			startPointer = nil
			startPosition = nil
			moved = false
			SetEffect(false)
		end

		Connect(logoButton.MouseEnter, function()
			if MacUI.Unloaded or not holder.Visible then return end
			hovered = true
			SetEffect(activeInput ~= nil)
			if not activeInput then
				Animate(sheenGradient, { Offset = Vector2.new(-1.5, 0) }, true)
				Animate(sheenGradient, { Offset = Vector2.new(1.5, 0) }, false, 0.65)
			end
		end)

		Connect(logoButton.MouseLeave, function()
			hovered = false
			SetEffect(activeInput ~= nil)
		end)

		Connect(logoButton.InputBegan, function(input)
			if activeInput or MacUI.Unloaded or not holder.Visible then
				return
			end

			local inputType = input.UserInputType

			if inputType ~= Enum.UserInputType.MouseButton1
				and inputType ~= Enum.UserInputType.Touch then
				return
			end

			activeInput = input
			startPointer = Vector2.new(input.Position.X, input.Position.Y)
			startPosition = GetLocalPosition()
			moved = false
			SetEffect(true)
		end)

		Connect(UserInputService.InputChanged, function(input)
			if not activeInput or not holder.Visible then
				return
			end

			local isTouch = activeInput.UserInputType
				== Enum.UserInputType.Touch

			if isTouch then
				if input ~= activeInput then
					return
				end
			elseif input.UserInputType
				~= Enum.UserInputType.MouseMovement then
				return
			end

			local pointer = Vector2.new(input.Position.X, input.Position.Y)
			local delta = pointer - startPointer

			if delta.Magnitude >= DRAG_THRESHOLD then
				moved = true
			end

			if moved then
				SetPositionClamped(startPosition + delta)
			end
		end)

		Connect(UserInputService.InputEnded, function(input)
			if not activeInput or input ~= activeInput then
				return
			end

			local shouldOpen = not moved and holder.Visible
				and input.UserInputState ~= Enum.UserInputState.Cancel

			ResetDrag()

			if shouldOpen and not MacUI.Unloaded and not Window.Loading then
				Window:Restore()
			end
		end)

		Connect(UserInputService.WindowFocusReleased, function()
			ResetDrag()
			ResetEffects()
		end)

		Connect(screenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
			ResetDrag()
			ResetEffects()
			SetPositionClamped(GetLocalPosition())
		end)

		-- ซิงก์กับการเปิด / ซ่อน UI ทั้งปุ่มย่อและปุ่มลัด
		local originalSetVisible = Window.SetVisible

		local function SetVisibleWithLogo(self, visible, instant)
			originalSetVisible(self, visible, instant)

			if holder.Parent then
				ResetDrag()
				ResetEffects()
				holder.Visible = self.Shown == false
			end
		end

		Window.SetVisible = SetVisibleWithLogo

		MacUI:OnUnload(function()
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			table.clear(connections)

			if Window.SetVisible == SetVisibleWithLogo then
				Window.SetVisible = originalSetVisible
			end

			for target, tween in pairs(effectTweens) do
				tween:Cancel()
				effectTweens[target] = nil
			end
			holder:Destroy()
		end)
	else
		warn("[Zero X] Cannot create logo: Window.ScreenGui unavailable")
	end
end

local Tabs = {
    AutoFarm = Window:AddTab({
        Title = "Auto Farm",
        Icon = "swords",
        Section = "Main",
    }),
    Shop = Window:AddTab({
        Title = "Shop",
        Icon = "shopping-cart",
    }),
    Player = Window:AddTab({
        Title = "Player",
        Icon = "user",
        Section = "Player",
    }),
    Appearance = Window:AddTab({
        Title = "Settings",
        Icon = "palette",
        Section = "Settings",
    }),
    Profiles = Window:AddTab({
        Title = "Profiles",
        Icon = "folder",
    }),
}


--------------------------------------------------------------------------------
-- ADD YOUR FEATURES HERE
-- Use Tabs.Home:AddSection(...) or Window:AddTab(...) to add your own controls.
-- Register controls with unique indexes so SaveManager can save their values.
-- Add controls before LoadAutoloadConfig at the bottom of this file.
-- Connect callbacks only after the real game functions are available.
--------------------------------------------------------------------------------

do
    local function InitHuntingFarm()
        local RS = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")
        local CollectionService = game:GetService("CollectionService")

        local shared = RS:WaitForChild("Shared", 5)
        local remotes = RS:WaitForChild("Remotes", 5)

        local function FindRequired(parent, name, className)
            local object = parent and parent:WaitForChild(name, 5)
            if object and object:IsA(className) then
                return object
            end
            warn("[Zero X / Farm] Missing " .. name .. " (" .. className .. ")")
            return nil
        end

        local mapModule = FindRequired(shared, "MapData", "ModuleScript")
        local monsterModule = FindRequired(shared, "MonsterData", "ModuleScript")
        local rangeModule = FindRequired(shared, "ClassRange", "ModuleScript")
        local setTarget = FindRequired(remotes, "SetTarget", "RemoteEvent")

        if not mapModule or not monsterModule
            or not rangeModule or not setTarget then
            return
        end

        local function LoadModule(module)
            local ok, result = pcall(require, module)
            if ok and type(result) == "table" then
                return result
            end
            warn("[Zero X / Farm] Cannot load " .. module:GetFullName()
                .. ": " .. tostring(result))
            return nil
        end

        local mapData = LoadModule(mapModule)
        local monsterData = LoadModule(monsterModule)
        local classRange = LoadModule(rangeModule)

        if not mapData or not monsterData or not classRange then
            return
        end

        if type(classRange.Attack) ~= "function"
            or type(classRange.StopInside) ~= "function" then
            warn("[Zero X / Farm] ClassRange contract unavailable")
            return
        end

        local alive = true
        local enabled = false
        local potionTripActive = false
        local farmTravelActive = false
        local dropTripActive = false
        local sellTripActive = false
        local pullEnabled = false
        local farmPullActive = false
        local pullSession
        local pullNextScan = 0
        local pullCount = 3

        -- นโยบายของระบบใหม่ ไม่ใช่ค่ารับประกัน Leash ของเกม
        local PULL_RADIUS = 60
        local PULL_APPROACH_TIMEOUT = 8
        local PULL_THREAT_TIMEOUT = 1.5
        local PULL_GATHER_TIMEOUT = 12
        local PULL_GATHER_RADIUS = 12
        local mode = "Farm Level"
        local selectedId
        local worker
        local target
        local holding = false
        local folder
        local statusText
        local connections = {}
        local monsterConnections = {}
        local monsters = {}
        local zones = {}
        local zoneById = {}
        local requirements = {}
        local optionToId = {}
        local catalog = {}
        local bossGates = {}
        local gatesValid = true

        -- ค่าของระบบใหม่ ไม่ใช่ Config ของเกม
        local UPDATE_INTERVAL = 0.1
        local RANGE_MARGIN = 0.75
        local REPOSITION_DISTANCE = 0.75
        local WAIT_HEIGHT = 4

        local FarmTab = Tabs.AutoFarm
        local ShopTab = Tabs.Shop

        local section = FarmTab:AddSection({
            Title = "Farming",
            Icon = "swords",
        })

        local combatSection = FarmTab:AddSection({
            Title = "Combat",
            Icon = "swords",
        })

        local pullSection = FarmTab:AddSection({
            Title = "Monster Pulling",
            Icon = "swords",
        })

        local recoverySection = FarmTab:AddSection({
            Title = "Recovery & Loot",
        })

        local lastStatusLog = -math.huge

        local function SetStatus(message)
            message = tostring(message)

            if message == statusText then return end
            statusText = message

            local now = os.clock()
            local immediate = message == "Stopped"
                or message:find("Error", 1, true) ~= nil

            if immediate or now - lastStatusLog >= 3 then
                lastStatusLog = now
                print("[Zero X / Farm / Status] " .. message)
            end
        end

        local function Connect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(connections, connection)
            return connection
        end

        -- สร้าง Catalog จาก Schema ที่ตรวจสอบแล้ว
        for zoneId, data in pairs(mapData) do
            if type(zoneId) == "string" and type(data) == "table"
                and type(data.Spawns) == "table"
                and type(data.Order) == "number" then

                local minLevel = type(data.LevelText) == "string"
                    and tonumber(data.LevelText:match("%d+"))

                if minLevel then
                    local zone = {
                        Id = zoneId,
                        Data = data,
                        MinLevel = minLevel,
                        Order = data.Order,
                        Ids = {},
                    }

                    for _, spawn in ipairs(data.Spawns) do
                        local id = type(spawn) == "table" and spawn.Id
                        if type(id) == "string"
                            and type(monsterData[id]) == "table" then
                            zone.Ids[id] = true
                            catalog[id] = monsterData[id]
                        end
                    end

                    table.insert(zones, zone)
                    zoneById[zoneId] = zone
                end
            end
        end

        table.sort(zones, function(a, b)
            if a.Order == b.Order then return a.Id < b.Id end
            return a.Order < b.Order
        end)

        for _, zone in ipairs(zones) do
            local data = zone.Data
            local unlocked = type(data.Unlocks) == "string"
                and zoneById[data.Unlocks]

            if data.BossRoom == true and unlocked
                and type(data.Boss) == "string"
                and type(monsterData[data.Boss]) == "table" then

                table.insert(requirements, {
                    Order = unlocked.Order,
                    GateId = zone.Id, -- Boss01 / Boss02 ไม่ใช่ MonsterId
                    MonsterId = data.Boss,
                    Room = zone,
                })
            end
        end

        table.sort(requirements, function(a, b)
            return a.Order < b.Order
        end)

        local function RefreshGates()
            local json = LocalPlayer:GetAttribute("BossGatesJson")

            if json == nil then
                bossGates = {}
                gatesValid = false
                return
            end

            if type(json) ~= "string" then
                bossGates = {}
                gatesValid = false
                return
            end

            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(json)
            end)

            gatesValid = ok and type(decoded) == "table"
            bossGates = gatesValid and decoded or {}
        end

        RefreshGates()
        Connect(LocalPlayer:GetAttributeChangedSignal("BossGatesJson"),
            RefreshGates)

        local function CanAccess(zone, level)
            return type(level) == "number"
                and type(zone.MinLevel) == "number"
                and level >= zone.MinLevel
        end

        local function GetTracker()
            local object = LocalPlayer:FindFirstChild("CurrentTarget")
            if object and object:IsA("ObjectValue") then
                return object
            end
            return nil
        end

        local farmHover
        local farmSideTarget
        local farmSideRoot
        local farmSideDirection

        local function StopFarmHover()
            local old = farmHover
            farmHover = nil
            if not old then return end

            old.Position:Destroy()
            old.Orientation:Destroy()
            old.Attachment:Destroy()

            if old.Humanoid.Parent
                and old.Humanoid.AutoRotate == false then
                old.Humanoid.AutoRotate = old.AutoRotate
            end
        end

        local function HoldFarmPosition(humanoid, root, position, facing)
            if farmHover and (
                farmHover.Root ~= root
                or farmHover.Humanoid ~= humanoid
                or not farmHover.Position.Parent
                or not farmHover.Orientation.Parent
                or not farmHover.Attachment.Parent
            ) then
                StopFarmHover()
            end

            if not farmHover then
                local attachment = Instance.new("Attachment")
                attachment.Name = "ZeroXFarmHoverAttachment"
                attachment.Parent = root

                local alignment = Instance.new("AlignPosition")
                alignment.Name = "ZeroXFarmHoverPosition"
                alignment.Mode = Enum.PositionAlignmentMode.OneAttachment
                alignment.Attachment0 = attachment
                alignment.ApplyAtCenterOfMass = true
                alignment.RigidityEnabled = false
                alignment.Responsiveness = 35
                alignment.MaxVelocity = 60
                alignment.MaxForce = math.max(
                    10000,
                    root.AssemblyMass * math.max(workspace.Gravity, 1) * 40
                )
                alignment.Position = position
                alignment.Parent = root

                local orientation = Instance.new("AlignOrientation")
                orientation.Name = "ZeroXFarmHoverOrientation"
                orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
                orientation.Attachment0 = attachment
                orientation.RigidityEnabled = false
                orientation.Responsiveness = 35
                orientation.MaxTorque = 500000
                orientation.MaxAngularVelocity = 20
                orientation.CFrame = facing.Rotation
                orientation.Parent = root

                farmHover = {
                    Root = root,
                    Humanoid = humanoid,
                    AutoRotate = humanoid.AutoRotate,
                    Attachment = attachment,
                    Position = alignment,
                    Orientation = orientation,
                }

                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end

            humanoid.AutoRotate = false
            farmHover.Position.Position = position
            farmHover.Orientation.CFrame = facing.Rotation
        end

        local function ClearTarget()
            farmSideTarget = nil
            farmSideRoot = nil
            farmSideDirection = nil
            StopFarmHover()
            local old = target
            target = nil
            holding = false

            if not old then return end

            local tracker = GetTracker()
            if tracker and tracker.Value == old then
                tracker.Value = nil
            end

            if setTarget.Parent then
                setTarget:FireServer(nil, false)
            end
        end

        local function BindMonsters()
            local current = workspace:FindFirstChild("Monsters")
            if current == folder then return end

            for _, connection in ipairs(monsterConnections) do
                connection:Disconnect()
            end
            table.clear(monsterConnections)
            table.clear(monsters)
            folder = current

            if not folder then return end

            local function Add(object)
                if object:IsA("Model") then
                    monsters[object] = true
                end
            end

            table.insert(monsterConnections, folder.ChildAdded:Connect(Add))
            table.insert(monsterConnections,
                folder.ChildRemoved:Connect(function(object)
                    monsters[object] = nil
                end))

            for _, object in ipairs(folder:GetChildren()) do
                Add(object)
            end
        end

        local function GetMonsterPart(model)
            if not folder or model.Parent ~= folder
                or not CollectionService:HasTag(model, "Monster") then
                return nil
            end

            local hp = tonumber(model:GetAttribute("HP"))
            if not hp or hp <= 0 then return nil end

            local part = model.PrimaryPart
                or model:FindFirstChild("HumanoidRootPart")

            if part and part:IsA("BasePart") then
                return part
            end
            return nil
        end

        local function IsRegular(id, model)
            local data = monsterData[id]
            if type(data) ~= "table" then return false end

            if data.Leader or data.MiniBoss or data.Boss then
                return false
            end

            return not model
                or not (model:GetAttribute("IsLeader")
                    or model:GetAttribute("IsMiniBoss")
                    or model:GetAttribute("IsBoss"))
        end

        local function BuildPlan(level)
            if mode == "Select Monster" then
                if not selectedId then
                    return nil, nil, "Select a monster"
                end

                for _, zone in ipairs(zones) do
                    if zone.Ids[selectedId] then
                        return zone, { [selectedId] = true }
                    end
                end

                return nil, nil, "Selected monster missing from MapData"
            end

            local chosen
            for _, zone in ipairs(zones) do
                if zone.Data.BossRoom ~= true
                    and CanAccess(zone, level) then
                    if not chosen or zone.MinLevel > chosen.MinLevel
                        or (zone.MinLevel == chosen.MinLevel
                            and zone.Order < chosen.Order) then
                        chosen = zone
                    end
                end
            end

            if not chosen then
                return nil, nil, "No accessible farming zone"
            end

            if not gatesValid then
                return nil, nil, "Waiting for valid BossGatesJson"
            end

            -- ตรวจบอสตามลำดับประตูจนถึงด่านที่ต้องการไป
            for _, requirement in ipairs(requirements) do
                if requirement.Order > chosen.Order then
                    break
                end

                if bossGates[requirement.GateId] ~= true then
                    if not CanAccess(requirement.Room, level) then
                        return nil, nil,
                            "Boss level requirement: "
                                .. requirement.GateId
                    end

                    return requirement.Room, {
                        [requirement.MonsterId] = true,
                    }, nil, requirement.GateId
                end
            end

            local ids = {}
            local bestLevel

            for id in pairs(chosen.Ids) do
                local data = monsterData[id]
                local monsterLevel = data.Level

                if IsRegular(id) and type(monsterLevel) == "number"
                    and monsterLevel <= level then

                    if not bestLevel or monsterLevel > bestLevel then
                        bestLevel = monsterLevel
                        table.clear(ids)
                    end

                    if monsterLevel == bestLevel then
                        ids[id] = true
                    end
                end
            end

            if not next(ids) then
                return nil, nil, "No suitable regular monster"
            end

            return chosen, ids
        end

        local function GetWaitPosition(zone)
            local map = workspace:FindFirstChild("Map")
            local warps = map and map:FindFirstChild("Warps")
            local marker = warps and warps:FindFirstChild("Warp_" .. zone.Id)

            if marker and marker:IsA("BasePart") then
                return marker.Position
            end

            local zoneFolder = workspace:FindFirstChild("Zones")
            marker = zoneFolder and zoneFolder:FindFirstChild(zone.Id)

            if marker and marker:IsA("BasePart") then
                return marker.Position
            end

            return nil
        end

        local nativeAutoSkillRemote = FindRequired(
            remotes,
            "SetAutoSkill",
            "RemoteEvent"
        )
        local nativeAutoMenu = FindRequired(
            LocalPlayer,
            "LumiMenuToggle",
            "BindableEvent"
        )

        -- รับช่วงร่ายของเกม เพื่อให้ Auto Farm พักการย้ายตำแหน่ง
        local skillCastUntil = 0
        local nativeSkillUsed = FindRequired(
            remotes,
            "SkillUsed",
            "RemoteEvent"
        )

        if nativeSkillUsed then
            Connect(nativeSkillUsed.OnClientEvent,
                function(_, _, castDuration)
                    if not alive then return end

                    if type(castDuration) == "number"
                        and castDuration == castDuration
                        and castDuration > 0
                        and castDuration < math.huge then
                        skillCastUntil = math.max(
                            skillCastUntil,
                            os.clock() + castDuration
                        )
                    end
                end
            )
        end

        Connect(LocalPlayer.CharacterRemoving, function()
            skillCastUntil = 0
        end)

        local function InsidePullZone(zonePart, position)
            if not zonePart or not zonePart.Parent then return false end

            local point = zonePart.CFrame:PointToObjectSpace(position)
            return math.abs(point.X) <= zonePart.Size.X / 2
                and math.abs(point.Z) <= zonePart.Size.Z / 2
        end

        local function FindPullZone(position)
            local zoneFolder = workspace:FindFirstChild("Zones")
            if not zoneFolder then return nil end

            for _, object in ipairs(zoneFolder:GetChildren()) do
                if object:IsA("BasePart")
                    and InsidePullZone(object, position) then
                    return object
                end
            end

            return nil
        end

        local function ResetPull(restoreNative)
            local old = pullSession
            pullSession = nil
            farmPullActive = false
            pullNextScan = os.clock() + 3
            StopFarmHover()

            if not old then return end

            if old.HitConnection then
                old.HitConnection:Disconnect()
                old.HitConnection = nil
            end

            if LocalPlayer.Character == old.Character then
                local humanoid =
                    old.Character:FindFirstChildOfClass("Humanoid")

                if humanoid and humanoid.Health > 0 then
                    humanoid:Move(Vector3.zero, false)
                end
            end

            if restoreNative and alive and not potionTripActive
                and old.AutoWasOn
                and LocalPlayer.Character == old.Character then

                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if menu and menu:IsA("BindableEvent")
                    and LocalPlayer:GetAttribute("AutoOn") ~= true then
                    menu:Fire("autoToggle")
                end
            end
        end

        local function IsPullable(model, eligible)
            local part = eligible(model)
            if not part or model:GetAttribute("IsDummy") == true then
                return nil
            end

            local id = model:GetAttribute("MonsterId")
            local def = type(id) == "string" and monsterData[id]

            if type(def) ~= "table"
                or def.Ranged == true
                or not IsRegular(id, model) then
                return nil
            end

            return part
        end

        local function StepPull(eligible, character, humanoid, root, zone)
            local now = os.clock()

            if not pullEnabled then
                if pullSession then
                    ResetPull(true)
                    ClearTarget()
                end
                return false
            end

            if not pullSession then
                -- ต้องมีมอนหลักที่ Auto Farm กำลังโจมตีอยู่ก่อน
                if not target or not eligible(target) or not holding then
                    return false
                end

                local mainTarget = target

                if now < pullNextScan then return false end
                pullNextScan = now + 2

                local spatialZone = FindPullZone(root.Position)
                if not spatialZone then return false end

                local candidates = {}

                for model in pairs(monsters) do
                    local part = IsPullable(model, eligible)

                    if part then
                        local threat = model:GetAttribute("ThreatUserId")
                        local distance =
                            (part.Position - root.Position).Magnitude

                        if model ~= mainTarget
                            and (threat == nil or threat == 0)
                            and distance <= PULL_RADIUS
                            and InsidePullZone(spatialZone, part.Position) then

                            table.insert(candidates, {
                                Model = model,
                                Distance = distance,
                            })
                        end
                    end
                end

                if #candidates == 0 then
                    return false -- มอนน้อย ใช้ฟาร์มเดิม
                end

                table.sort(candidates, function(a, b)
                    return a.Distance < b.Distance
                end)

                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")
                local autoOn = LocalPlayer:GetAttribute("AutoOn") == true

                if autoOn and not (
                    menu and menu:IsA("BindableEvent")
                ) then
                    return false
                end

                local queue = {}
                for index = 1, math.min(
                    math.max(1, pullCount - 1),
                    #candidates
                ) do
                    table.insert(queue, candidates[index].Model)
                end

                pullSession = {
                    Character = character,
                    Folder = folder,
                    Map = workspace:FindFirstChild("Map"),
                    Zone = spatialZone,
                    ZoneId = zone.Id,
                    Mode = mode,
                    SelectedId = selectedId,
                    MainTarget = mainTarget,
                    Anchor = root.Position,
                    AnchorCFrame = root.CFrame,
                    Queue = queue,
                    Tagged = {},
                    Index = 1,
                    Phase = "Pull",
                    StartedAt = now,
                    TargetAt = now,
                    SentAt = nil,
                    AutoWasOn = autoOn,
                }

                farmPullActive = true
                ClearTarget()

                if autoOn then
                    menu:Fire("autoToggle")
                end

                SetStatus("Pull: pausing native Auto")
                return true
            end

            local session = pullSession

            if session.Character ~= character
                or session.Folder ~= folder
                or session.Map ~= workspace:FindFirstChild("Map")
                or not session.Zone.Parent
                or session.ZoneId ~= zone.Id
                or session.Mode ~= mode
                or session.SelectedId ~= selectedId
                or not InsidePullZone(session.Zone, root.Position)
                or (root.Position - session.Anchor).Magnitude
                    > PULL_RADIUS + 15 then

                ResetPull(true)
                ClearTarget()
                return true
            end

            -- มอนหลักตาย/หาย/ไม่ตรงเงื่อนไขแล้ว จบรอบนี้
            if not eligible(session.MainTarget) then
                ResetPull(true)
                ClearTarget()
                return true
            end

            if session.Phase == "Fight" then
                -- ส่งมอนตัวเดิมกลับให้ระบบโจมตี/ลอยหลังเดิม
                return false, session.MainTarget
            end

            StopFarmHover()

            if LocalPlayer:GetAttribute("AutoOn") == true then
                if now - session.StartedAt >= 5 then
                    ResetPull(true)
                    ClearTarget()
                    SetStatus("Pull cancelled: native Auto remained active")
                end
                return true
            end

            if session.Phase == "Pull" then
                local model = session.Queue[session.Index]

                if not model then
                    ClearTarget()
                    session.Phase = "Fight"
                    farmPullActive = false

                    if session.AutoWasOn then
                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if menu and menu:IsA("BindableEvent")
                            and LocalPlayer:GetAttribute("AutoOn") ~= true then
                            menu:Fire("autoToggle")
                        end
                    end

                    SetStatus("Pull: returning to original monster")
                    return false, session.MainTarget
                end

                local part = IsPullable(model, eligible)
                local threat = part and model:GetAttribute("ThreatUserId")

                local skip = not part
                    or (part and (
                        not InsidePullZone(session.Zone, part.Position)
                        or (part.Position - session.Anchor).Magnitude
                            > PULL_RADIUS + 10
                    ))
                    or (threat ~= nil and threat ~= 0
                        and threat ~= LocalPlayer.UserId)

                if threat == LocalPlayer.UserId and part then
                    session.Tagged[model] = true
                end

                if skip
                    or session.HitObserved
                    or now - session.TargetAt >= PULL_APPROACH_TIMEOUT
                    or (session.SentAt
                        and now - session.SentAt >= PULL_THREAT_TIMEOUT) then

                    if session.HitConnection then
                        session.HitConnection:Disconnect()
                        session.HitConnection = nil
                    end

                    ClearTarget()
                    session.Index = session.Index + 1
                    session.TargetAt = now
                    session.SentAt = nil
                    session.HitObserved = false
                    return true
                end

                local range = classRange.Attack(LocalPlayer)
                local inside = classRange.StopInside(LocalPlayer)

                if type(range) ~= "number"
                    or type(inside) ~= "number"
                    or range <= inside then
                    ResetPull(true)
                    ClearTarget()
                    return true
                end

                local radius = model:GetAttribute("Radius")
                if type(radius) ~= "number" then radius = 1.5 end
                radius = math.max(radius, 0)

                local attackLimit = range - inside
                local distance =
                    (part.Position - root.Position).Magnitude - radius

                if not session.SentAt then
                    if distance > attackLimit then
                        -- วาปเข้าหาแต่ละตัวครั้งเดียว
                        -- หากถูกดึงกลับ ให้ Timeout เดิมข้ามตัวนี้
                        if session.WarpedIndex == session.Index then
                            SetStatus("Pull: waiting for attack range")
                            return true
                        end

                        local delta = root.Position - part.Position
                        local horizontal = Vector3.new(delta.X, 0, delta.Z)

                        local direction = horizontal.Magnitude > 0.01
                            and horizontal.Unit or Vector3.zAxis

                        local standDistance = math.min(
                            4,
                            math.max(
                                0.5,
                                attackLimit + radius - RANGE_MARGIN
                            )
                        )

                        local destination =
                            part.Position + direction * standDistance

                        if not InsidePullZone(session.Zone, destination)
                            or (destination - session.Anchor).Magnitude
                                > PULL_RADIUS + 15 then

                            ClearTarget()
                            session.Index = session.Index + 1
                            session.TargetAt = now
                            session.SentAt = nil
                            return true
                        end

                        humanoid:Move(Vector3.zero, false)
                        root.CFrame = CFrame.lookAt(
                            destination,
                            part.Position
                        )
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        session.WarpedIndex = session.Index

                        SetStatus(string.format(
                            "Pull: warped to %d/%d",
                            session.Index,
                            #session.Queue
                        ))

                        -- ตรวจระยะอีกครั้งในรอบหน้า ก่อนส่งโจมตี
                        return true
                    end

                    humanoid:Move(Vector3.zero, false)

                    local tracker = GetTracker()
                    if not tracker then return true end

                    if target ~= model then
                        ClearTarget()
                    end

                    local beforeHP =
                        tonumber(model:GetAttribute("HP"))

                    if not beforeHP or beforeHP <= 0 then
                        return true
                    end

                    target = model
                    tracker.Value = model
                    session.SentAt = now
                    session.HitObserved = false
                    holding = true

                    if session.HitConnection then
                        session.HitConnection:Disconnect()
                    end

                    local watchedIndex = session.Index

                    session.HitConnection =
                        model:GetAttributeChangedSignal("HP"):Connect(function()
                            if not alive or pullSession ~= session
                                or session.Phase ~= "Pull"
                                or session.Index ~= watchedIndex
                                or session.HitObserved then
                                return
                            end

                            local currentHP =
                                tonumber(model:GetAttribute("HP"))

                            if currentHP and currentHP < beforeHP then
                                session.HitObserved = true

                                if session.HitConnection then
                                    session.HitConnection:Disconnect()
                                    session.HitConnection = nil
                                end

                                -- หยุดโจมตีทันทีเมื่อสังเกต HP ลดครั้งแรก
                                ClearTarget()
                            end
                        end)

                    setTarget:FireServer(model, false, true)
                    SetStatus("Pull: waiting for first HP decrease")
                end

                return true
            end
        end

        Connect(LocalPlayer.CharacterRemoving, function()
            ResetPull(false)
        end)

        local farmTravel

        -- ค่านโยบายตรวจตำแหน่งของสคริปต์
        local TRAVEL_CHECK_DELAY = 1
        local TRAVEL_ARRIVAL_DISTANCE = 12
        local TRAVEL_MAX_ATTEMPTS = 3

        local function FinishFarmTravel(restoreAuto)
            local old = farmTravel
            farmTravel = nil
            farmTravelActive = false

            if old and restoreAuto and alive
                and old.Character == LocalPlayer.Character
                and old.AutoWasOn
                and not potionTripActive
                and not sellTripActive
                and not dropTripActive then

                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if menu and menu:IsA("BindableEvent")
                    and LocalPlayer:GetAttribute("AutoOn") ~= true then
                    menu:Fire("autoToggle")
                end
            end
        end

        local function ZoneContains(zone, position)
            local folder = workspace:FindFirstChild("Zones")
            local part = folder and folder:FindFirstChild(zone.Id)

            return part and part:IsA("BasePart")
                and InsidePullZone(part, position)
        end

        local function TransitAllowed(zone, level)
            if not CanAccess(zone, level) or not gatesValid then
                return false
            end

            for _, requirement in ipairs(requirements) do
                if requirement.Order > zone.Order then break end

                if bossGates[requirement.GateId] ~= true then
                    return false
                end
            end

            return true
        end

        local function BuildTravelHops(goal, position, level)
            local spatial = FindPullZone(position)
            local current = spatial and zoneById[spatial.Name]

            if not current then
                -- นอกโซน: ใช้จุดโซนที่มีอยู่จริงและอยู่ใกล้ที่สุด
                local nearestDistance = math.huge

                for _, candidate in ipairs(zones) do
                    if candidate.Data.BossRoom ~= true
                        and TransitAllowed(candidate, level) then
                        local point = GetWaitPosition(candidate)

                        if point then
                            local distance = (point - position).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                current = candidate
                            end
                        end
                    end
                end
            end

            if not current then return nil end

            local forward = goal.Order >= current.Order
            local between = {}

            for _, candidate in ipairs(zones) do
                local inPath = forward
                    and candidate.Order > current.Order
                    and candidate.Order < goal.Order
                    or not forward
                    and candidate.Order < current.Order
                    and candidate.Order > goal.Order

                if candidate.Data.BossRoom ~= true and inPath then
                    if not TransitAllowed(candidate, level) then
                        return nil
                    end
                    table.insert(between, candidate)
                end
            end

            table.sort(between, function(a, b)
                if forward then return a.Order < b.Order end
                return a.Order > b.Order
            end)

            table.insert(between, goal)

            local hops = {}

            -- ถ้าอยู่นอกทุกโซน ให้เข้าจุดเริ่มก่อน
            if not spatial and current ~= goal then
                table.insert(hops, current)
            end

            for index = 2, #between, 2 do
                table.insert(hops, between[index])
            end

            if hops[#hops] ~= goal then
                table.insert(hops, goal)
            end

            return hops
        end

        local function StepFarmTravel(zone, level, character, humanoid, root)
            if farmTravel and (
                farmTravel.Goal ~= zone
                or farmTravel.Character ~= character
                or farmTravel.Root ~= root
            ) then
                FinishFarmTravel(true)
            end

            if not farmTravel then
                if ZoneContains(zone, root.Position) then return true end

                local autoOn = LocalPlayer:GetAttribute("AutoOn") == true
                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")

                if autoOn and not (
                    menu and menu:IsA("BindableEvent")
                ) then
                    SetStatus("Travel: cannot pause native Auto")
                    return false
                end

                farmTravel = {
                    Goal = zone,
                    Character = character,
                    Root = root,
                    AutoWasOn = autoOn,
                    StartedAt = os.clock(),
                    Direct = true,
                    Attempts = 0,
                }

                farmTravelActive = true
                ResetPull(false)
                ClearTarget()

                if autoOn then menu:Fire("autoToggle") end
            end

            local travel = farmTravel

            if travel.Blocked then
                SetStatus("Travel paused: " .. travel.Blocked)
                return false
            end

            if LocalPlayer:GetAttribute("AutoOn") == true then
                if os.clock() - travel.StartedAt >= 5 then
                    travel.Blocked = "native Auto did not stop"
                end
                return false
            end

            humanoid:Move(Vector3.zero, false)

            if travel.SentAt then
                if os.clock() - travel.SentAt < TRAVEL_CHECK_DELAY then
                    return false
                end

                local arrived = (
                    root.Position - travel.Destination
                ).Magnitude <= TRAVEL_ARRIVAL_DISTANCE

                travel.SentAt = nil

                if arrived then
                    if travel.Hop == zone then
                        FinishFarmTravel(true)
                        return true
                    end

                    travel.Index += 1
                    travel.Attempts = 0

                elseif travel.Direct then
                    travel.Direct = false
                    travel.Hops = BuildTravelHops(
                        zone, root.Position, level
                    )
                    travel.Index = 1
                    travel.Attempts = 0

                    if not travel.Hops then
                        travel.Blocked = "no valid intermediate route"
                        return false
                    end

                    print("[Zero X / Farm / Travel] Direct arrival "
                        .. "not confirmed; switching to two-zone hops")
                elseif travel.Attempts >= TRAVEL_MAX_ATTEMPTS then
                    travel.Blocked = "arrival not confirmed at "
                        .. travel.Hop.Id
                    return false
                end
            end

            local hop = travel.Direct and zone
                or travel.Hops[travel.Index]

            if not hop then
                travel.Blocked = "route ended before destination"
                return false
            end

            local position = GetWaitPosition(hop)

            if not position then
                if travel.Direct then
                    travel.Direct = false
                    travel.Hops = BuildTravelHops(
                        zone, root.Position, level
                    )
                    travel.Index = 1

                    if not travel.Hops then
                        travel.Blocked = "no loaded route markers"
                    end
                end

                SetStatus("Travel: waiting for marker " .. hop.Id)
                return false
            end

            local destination = position
                + Vector3.new(0, WAIT_HEIGHT, 0)

            StopFarmHover()
            root.CFrame = CFrame.new(destination) * root.CFrame.Rotation
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            travel.Hop = hop
            travel.Destination = destination
            travel.SentAt = os.clock()
            travel.Attempts += 1

            SetStatus("Travel: " .. hop.Id .. " -> " .. zone.Id)
            return false
        end

        Connect(LocalPlayer.CharacterRemoving, function()
            FinishFarmTravel(false)
        end)

        local function Step()
            if sellTripActive then
                FinishFarmTravel(false)
                StopFarmHover()
                SetStatus("Selling: farming paused")
                return
            end

            if dropTripActive then
                FinishFarmTravel(false)
                StopFarmHover()
                SetStatus("Collecting drop: farming paused")
                return
            end

            if potionTripActive then
                FinishFarmTravel(false)
                SetStatus("Buying potions: farming paused")
                return
            end

            BindMonsters()

            if Options.ZeroXFly and Options.ZeroXFly.Value then
                FinishFarmTravel(true)
                ResetPull(true)
                ClearTarget()
                SetStatus("Pause: turn Fly off")
                return
            end

            local character = LocalPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = humanoid and humanoid.RootPart

            if not humanoid or humanoid.Health <= 0
                or not root or not root:IsA("BasePart")
                or not root.Parent or root.Anchored then
                FinishFarmTravel(false)
                ResetPull(false)
                ClearTarget()
                SetStatus("Waiting for character")
                return
            end

            local isCasting = os.clock() < skillCastUntil

            local level = LocalPlayer:GetAttribute("Level")
            if type(level) ~= "number" then
                ClearTarget()
                SetStatus("Waiting for Level")
                return
            end

            local tracker = GetTracker()
            if not tracker then
                ClearTarget()
                SetStatus("Waiting for CurrentTarget")
                return
            end

            local zone, ids, reason, bossGateId = BuildPlan(level)

            if not zone then
                FinishFarmTravel(true)
                ResetPull(true)
                ClearTarget()
                SetStatus(reason)
                return
            end

            if not StepFarmTravel(
                zone, level, character, humanoid, root
            ) then
                return
            end

            local function Eligible(model)
                local id = model:GetAttribute("MonsterId")
                if not ids[id] then return nil end

                -- แผนบอสอนุญาตเฉพาะ MonsterId ที่ BuildPlan เลือก
                if mode == "Farm Level" and not bossGateId
                    and not IsRegular(id, model) then
                    return nil
                end

                return GetMonsterPart(model)
            end

            if bossGateId or isCasting then
                -- หยุดลากมอน เพื่อโฟกัสบอสปลดด่าน
                if pullSession then
                    ResetPull(true)
                    ClearTarget()
                end
            else
                local pullHandled, groupTarget = StepPull(
                    Eligible,
                    character,
                    humanoid,
                    root,
                    zone
                )

                if pullHandled then return end

                if groupTarget and target ~= groupTarget then
                    ClearTarget()
                    target = groupTarget
                end
            end

            local targetPart = target and Eligible(target)

            if not targetPart then
                ClearTarget()
                local nearestDistance = math.huge

                for model in pairs(monsters) do
                    local part = Eligible(model)
                    if part then
                        local distance = (part.Position - root.Position).Magnitude
                        if distance < nearestDistance then
                            nearestDistance = distance
                            target = model
                            targetPart = part
                        end
                    end
                end
            end

            if not target or not targetPart then
                local position = GetWaitPosition(zone)

                if position then
                    local destination = position + Vector3.new(0, WAIT_HEIGHT, 0)
                    local delta = root.Position - destination
                    local horizontal = Vector3.new(delta.X, 0, delta.Z)

                    if bossGateId then
                        SetStatus(
                            "Waiting for boss / clearance: "
                                .. bossGateId
                        )
                    else
                        SetStatus(
                            "Waiting: "
                                .. tostring(zone.Data.DisplayName)
                        )
                    end
                else
                    SetStatus("Waiting for zone marker: " .. zone.Id)
                end
                return
            end

            local range = classRange.Attack(LocalPlayer)
            local inside = classRange.StopInside(LocalPlayer)
            local radius = target:GetAttribute("Radius")

            if type(range) ~= "number" or type(inside) ~= "number"
                or range <= inside then
                ClearTarget()
                SetStatus("Invalid ClassRange")
                return
            end

            if type(radius) ~= "number" then radius = 1.5 end

            -- ค่าของระบบใหม่: ความสูงเหนือ Root ของมอน
            local HOVER_HEIGHT = 30

            -- เลือกด้านหลังครั้งแรกของเป้าหมายนี้
            -- แล้วล็อกเป็นทิศโลก ไม่หมุนตามมอน
            if farmSideTarget ~= target
                or farmSideRoot ~= root
                or not farmSideDirection then

                local look = targetPart.CFrame.LookVector
                local direction = Vector3.new(-look.X, 0, -look.Z)

                if direction.Magnitude <= 0.01 then
                    StopFarmHover()
                    SetStatus("Waiting for valid monster facing")
                    return
                end

                farmSideTarget = target
                farmSideRoot = root
                farmSideDirection = direction.Unit
            end

            local behind = farmSideDirection
            radius = math.max(radius, 0)

            local attackLimit = range - inside
            local reach = math.max(
                0.5,
                attackLimit + radius - RANGE_MARGIN
            )

            -- เผื่อระยะในแนวสูงด้วย ไม่ให้ลอยออกนอกวงโจมตี
            local height = math.min(HOVER_HEIGHT, reach * 0.4)
            local behindDistance = math.sqrt(
                math.max(0, reach * reach - height * height)
            )

            local destination = targetPart.Position
                + behind * behindDistance
                + Vector3.new(0, height, 0)

            -- หันเฉพาะแนวราบ ป้องกันตัวละครเอียงตามมอน
            local facing = CFrame.lookAt(
                destination,
                Vector3.new(
                    targetPart.Position.X,
                    destination.Y,
                    targetPart.Position.Z
                )
            )

            local function ReadDistance()
                return (targetPart.Position - root.Position).Magnitude
                    - radius
            end

            humanoid:Move(Vector3.zero, false)

            if ReadDistance() > attackLimit
                or (root.Position - destination).Magnitude
                    > REPOSITION_DISTANCE then
                root.CFrame = facing
            end

            HoldFarmPosition(humanoid, root, destination, facing)

            local actualDistance = ReadDistance()

            if tracker.Value ~= target then
                tracker.Value = target
                setTarget:FireServer(target, false)
                holding = false
            end

            local inRange = actualDistance <= attackLimit

            if inRange then
                if not holding then
                    setTarget:FireServer(target, false, true)
                    holding = true

                    print(string.format(
                        "[Zero X / Farm] Target=%s Zone=%s Level=%s"
                            .. " HP=%s Distance=%.2f Limit=%.2f HoldSent=true",
                        target:GetFullName(),
                        zone.Id,
                        tostring(level),
                        tostring(target:GetAttribute("HP")),
                        actualDistance,
                        attackLimit
                    ))
                end
            else
                holding = false
            end

            local id = target:GetAttribute("MonsterId")
            local data = type(id) == "string" and monsterData[id]
            local name = target:GetAttribute("DisplayName")
                or (type(data) == "table" and data.Name)
                or target.Name

            SetStatus(string.format(
                "%s | %s | HP %s | Dist %.1f / %.1f | %s",
                zone.Id,
                tostring(name),
                tostring(target:GetAttribute("HP")),
                actualDistance,
                attackLimit,
                inRange and "Hold sent" or "Out of range"
            ))
        end

        local function Stop()
            enabled = false
            FinishFarmTravel(true)
            ResetPull(true)

            if worker then
                task.cancel(worker)
                worker = nil
            end

            ClearTarget()
            SetStatus("Stopped")
        end

        local function Start()
            if not alive or enabled then return end

            if Options.ZeroXFly and Options.ZeroXFly.Value then
                Options.ZeroXFly:SetValue(false)
            end

            enabled = true
            worker = task.defer(function()
                local ok, err = xpcall(function()
                    while alive and enabled do
                        Step()
                        task.wait(UPDATE_INTERVAL)
                    end
                end, debug.traceback)

                worker = nil

                if not ok then
                    enabled = false
                    FinishFarmTravel(true)
                    ResetPull(true)

                    warn("[Zero X / Farm / Original Error]\n"
                        .. tostring(err))

                    ClearTarget()
                    SetStatus("Error: see console")
                end
            end)
        end

        local choices = {}
        for id, data in pairs(catalog) do
            local name = type(data.Name) == "string" and data.Name or id
            local label = name .. " [" .. id .. "]"
            optionToId[label] = id
            table.insert(choices, label)
        end
        table.sort(choices)

        section:AddDropdown("ZeroXFarmMode", {
            Title = "Farm Mode",
            Description = "เลือกฟาร์มตามเลเวล หรือเลือกชนิดมอนเอง",
            Values = { "Farm Level", "Select Monster" },
            Default = "Farm Level",
            Callback = function(value)
                if not alive then return end
                mode = value
                ClearTarget()
            end,
        })

        section:AddDropdown("ZeroXFarmMonster", {
            Title = "Select Monster",
            Description = "ใช้เมื่อเลือกโหมด Select Monster",
            Values = choices,
            Searchable = true,
            AllowNull = true,
            Callback = function(value)
                if not alive then return end
                selectedId = optionToId[value]
                ClearTarget()
            end,
        })

        pullSection:AddToggle("ZeroXPullMonsters", {
            Title = "Pull Monsters Together",
            Description = "เปิดใช้งานฟังชั่นรวบมอน",
            Default = false,

            Callback = function(value)
                if not alive then return end
                pullEnabled = value == true

                if not pullEnabled then
                    ResetPull(true)
                    ClearTarget()
                end
            end,
        })

        pullSection:AddSlider("ZeroXPullCount", {
            Title = "Monsters Per Pull",
            Description = "จำนวนมอนต่อการลาก",
            Min = 2,
            Max = 6,
            Default = 3,
            Increment = 1,

            Callback = function(value)
                if type(value) == "number" and value == value
                    and value >= 2 and value <= 6 then
                    pullCount = math.floor(value)
                end
            end,
        })

        section:AddToggle("ZeroXAutoFarm", {
            Title = "Auto Farm",
            Description = "เปิดฟาร์มและโจมตีตามเป้าหมาย",
            Default = false,
            Callback = function(value)
                if not alive then return end
                if value then Start() else Stop() end
            end,
        })

        if nativeAutoSkillRemote and nativeAutoMenu then
            -- นโยบายตรวจสถานะของสคริปต์ ไม่ใช่ Cooldown ของเกม
            local CHECK_INTERVAL = 1
            local REQUEST_INTERVAL = 1

            local wanted = false
            local watchTask
            local lastSkillRequest = -math.huge
            local lastAutoRequest = -math.huge
            local warnedLocked = false

            local unlockModule = FindRequired(
                shared,
                "UnlockData",
                "ModuleScript"
            )
            local unlockData = unlockModule and LoadModule(unlockModule)

            local function EnsureNativeEnabled()
                if not alive or not wanted
                    or potionTripActive or farmPullActive
                    or dropTripActive or sellTripActive
                    or farmTravelActive then
                    return
                end

                local now = os.clock()

                -- ค้นใหม่เพื่อรองรับ Instance ถูกสร้างแทนตัวเดิม
                local skillRemote = remotes
                    and remotes:FindFirstChild("SetAutoSkill")

                if skillRemote and skillRemote:IsA("RemoteEvent")
                    and LocalPlayer:GetAttribute("AutoSkill") ~= true
                    and now - lastSkillRequest >= REQUEST_INTERVAL then

                    lastSkillRequest = now
                    skillRemote:FireServer(true)
                end

                if LocalPlayer:GetAttribute("AutoOn") == true then
                    warnedLocked = false
                    return
                end

                -- ใช้เงื่อนไขปลดล็อกเดียวกับ toggleAuto ของเกม
                if not unlockData
                    or type(unlockData.HasLevel) ~= "function" then
                    return
                end

                local unlocked = unlockData.HasLevel(
                    LocalPlayer:GetAttribute("UnlockLevel"),
                    "bot"
                )

                if not unlocked then
                    if not warnedLocked then
                        warnedLocked = true
                        warn("[Zero X / Skill] Native Auto ยังไม่ปลดล็อก")
                    end
                    return
                end

                warnedLocked = false

                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")

                if menu and menu:IsA("BindableEvent")
                    and now - lastAutoRequest >= REQUEST_INTERVAL then

                    -- บันทึกก่อน Fire ป้องกัน Event เรียกซ้อน
                    lastAutoRequest = now

                    if LocalPlayer:GetAttribute("AutoOn") ~= true then
                        menu:Fire("autoToggle")
                    end
                end
            end

            local function StopSkillWatch()
                wanted = false

                if watchTask then
                    task.cancel(watchTask)
                    watchTask = nil
                end
            end

            local function StartSkillWatch()
                wanted = true
                if watchTask then return end

                watchTask = task.defer(function()
                    while alive and wanted do
                        EnsureNativeEnabled()
                        task.wait(CHECK_INTERVAL)
                    end
                    watchTask = nil
                end)
            end

            Connect(
                LocalPlayer:GetAttributeChangedSignal("AutoSkill"),
                EnsureNativeEnabled
            )

            Connect(
                LocalPlayer:GetAttributeChangedSignal("AutoOn"),
                EnsureNativeEnabled
            )

            Connect(
                LocalPlayer:GetAttributeChangedSignal("UnlockLevel"),
                EnsureNativeEnabled
            )

            Connect(LocalPlayer.CharacterAdded, function()
                if wanted then
                    EnsureNativeEnabled()
                end
            end)

            combatSection:AddToggle("ZeroXAutoUseSkill", {
                Title = "Auto Use Skill",
                Description = "เปิดระบบใช้สกิล",
                Default = false,

                Callback = function(value)
                    if not alive or type(value) ~= "boolean" then
                        return
                    end

                    if value then
                        StartSkillWatch()
                        return
                    end

                    -- หยุดตรวจให้เรียบร้อยก่อนปิดระบบเกม
                    StopSkillWatch()

                    local skillRemote =
                        remotes:FindFirstChild("SetAutoSkill")

                    if skillRemote and skillRemote:IsA("RemoteEvent")
                        and LocalPlayer:GetAttribute("AutoSkill") ~= false then
                        skillRemote:FireServer(false)
                    end

                    local menu =
                        LocalPlayer:FindFirstChild("LumiMenuToggle")

                    if menu and menu:IsA("BindableEvent")
                        and LocalPlayer:GetAttribute("AutoOn") == true then
                        menu:Fire("autoToggle")
                    end
                end,
            })

            MacUI:OnUnload(StopSkillWatch)
        end

        do
            local respawnChoice = FindRequired(
                remotes,
                "RespawnChoice",
                "RemoteEvent"
            )
            local deathPrompt = FindRequired(
                remotes,
                "DeathPrompt",
                "RemoteEvent"
            )

            if respawnChoice and deathPrompt then
                local respawnEnabled = false
                local respawnRequested = false
                local promptReceived = false
                local queuedCheck

                local function TryRespawn()
                    if not alive or not respawnEnabled
                        or respawnRequested then
                        return
                    end

                    local waiting =
                        LocalPlayer:GetAttribute("HuntRespawnWaiting") == true

                    -- รอให้ระบบเกมเข้าสู่ขั้นตอน Respawn
                    if not promptReceived and not waiting then
                        return
                    end

                    local character = LocalPlayer.Character
                    local humanoid = character
                        and character:FindFirstChildOfClass("Humanoid")

                    -- กัน Attribute หน้าตายค้างหลังเกิดใหม่
                    if humanoid and humanoid.Health > 0 then
                        return
                    end

                    local hereAt =
                        LocalPlayer:GetAttribute("RespawnHereAt")

                    if hereAt == nil then
                        hereAt = 0
                    end

                    -- ตรงกับปุ่ม Town ของเกม:
                    -- หากยังเป็นค่าบวก ต้องรอเกมเปลี่ยนสถานะ
                    if type(hereAt) ~= "number"
                        or hereAt ~= hereAt
                        or hereAt > 0 then
                        return
                    end

                    if not respawnChoice.Parent then
                        warn("[Zero X / Respawn] RespawnChoice unavailable")
                        return
                    end

                    -- ตั้งก่อนส่ง ป้องกันหลาย Event ส่งซ้ำ
                    respawnRequested = true
                    respawnChoice:FireServer("town")

                    print("[Zero X / Respawn] Requested free town respawn")
                end

                local function QueueRespawnCheck()
                    if not alive or not respawnEnabled
                        or respawnRequested or queuedCheck then
                        return
                    end

                    queuedCheck = task.defer(function()
                        queuedCheck = nil
                        TryRespawn()
                    end)
                end

                Connect(deathPrompt.OnClientEvent, function()
                    promptReceived = true
                    QueueRespawnCheck()
                end)

                Connect(
                    LocalPlayer:GetAttributeChangedSignal(
                        "HuntRespawnWaiting"
                    ),
                    QueueRespawnCheck
                )

                Connect(
                    LocalPlayer:GetAttributeChangedSignal("RespawnHereAt"),
                    QueueRespawnCheck
                )

                Connect(LocalPlayer.CharacterAdded, function()
                    respawnRequested = false
                    promptReceived = false
                end)

                recoverySection:AddToggle("ZeroXAutoRespawn", {
                    Title = "Auto Respawn",
                    Description = "เมื่อตาย เลือกเกิดในเมืองแบบฟรีตามเงื่อนไขของเกม",
                    Default = false,

                    Callback = function(value)
                        if not alive then return end

                        respawnEnabled = value == true

                        if respawnEnabled then
                            QueueRespawnCheck()
                        elseif queuedCheck then
                            task.cancel(queuedCheck)
                            queuedCheck = nil
                        end
                    end,
                })

                MacUI:OnUnload(function()
                    respawnEnabled = false

                    if queuedCheck then
                        task.cancel(queuedCheck)
                        queuedCheck = nil
                    end
                end)
            end
        end

        do
            local itemModule = FindRequired(shared, "ItemData", "ModuleScript")
            local shopBuy = FindRequired(remotes, "ShopBuy", "RemoteEvent")
            local items = itemModule and LoadModule(itemModule)

            if items and shopBuy then
                -- ค่านโยบายของสคริปต์
                local CHECK_INTERVAL = 0.2
                local CONFIRM_TIMEOUT = 8

                local buyEnabled = false
                local buyWorker
                local selectedPotions = {}
                local restockAt = 10
                local desiredStock = 100
                local restocking = {}
                local pendingPurchase
                local paused = false
                local lastMessage
                local cachedRaw
                local cachedInventory
                local blueChoices = {}
                local redChoices = {}
                local choiceToId = {}

                local function BuyStatus(message)
                    if message == lastMessage then return end
                    lastMessage = message
                    print("[Zero X / Potion] " .. message)
                end

                local function IsPositive(value)
                    return type(value) == "number"
                        and value == value
                        and value > 0
                        and value < math.huge
                end

                for id, def in pairs(items) do
                    if type(id) == "string"
                        and id:lower():find("potion", 1, true)
                        and type(def) == "table"
                        and def.Kind == "usable"
                        and IsPositive(def.Buy) then

                        local isRed = IsPositive(def.HealPercent)
                            or IsPositive(def.HealMin)
                            or IsPositive(def.HealMax)

                        local isBlue = IsPositive(def.SpPercent)

                        if isRed or isBlue then
                            local name = type(def.Name) == "string"
                                and def.Name or id
                            local label = name .. " [" .. id .. "]"
                            choiceToId[label] = id

                            if isBlue then
                                table.insert(blueChoices, label)
                            end
                            if isRed then
                                table.insert(redChoices, label)
                            end
                        end
                    end
                end

                table.sort(blueChoices)
                table.sort(redChoices)

                local function ReadInventory()
                    local raw = LocalPlayer:GetAttribute("ItemsJson")

                    if raw == cachedRaw and cachedInventory then
                        return cachedInventory
                    end

                    if type(raw) ~= "string" or raw == "" then
                        return nil
                    end

                    local ok, decoded = pcall(function()
                        return HttpService:JSONDecode(raw)
                    end)

                    if not ok or type(decoded) ~= "table" then
                        return nil
                    end

                    cachedRaw = raw
                    cachedInventory = decoded
                    return decoded
                end

                local function ReadCount(inventory, id)
                    local count = inventory[id]
                    if count == nil then return 0 end

                    if type(count) ~= "number" or count ~= count
                        or count < 0 or count == math.huge then
                        return nil
                    end

                    return math.floor(count)
                end

                local function GetMerchantPivot()
                    local map = workspace:FindFirstChild("Map")
                    local npcs = map and map:FindFirstChild("NPCs")
                    local merchant = npcs
                        and npcs:FindFirstChild("merchant")

                    if not merchant or not merchant:IsA("Model") then
                        return nil, nil
                    end

                    -- ไม่ต้องรอ HumanoidRootPart หรือ PrimaryPart
                    return merchant, merchant:GetPivot()
                end

                local function CanAccessShop(root)
                    if LocalPlayer:GetAttribute("Premium") == true
                        or LocalPlayer:GetAttribute("InTown") == true then
                        return true
                    end

                    local _, pivot = GetMerchantPivot()
                    return pivot ~= nil
                        and (root.Position - pivot.Position).Magnitude <= 20
                end

                local potionTrip

                local function FinishPotionTrip(returnToOrigin)
                    local trip = potionTrip
                    potionTrip = nil

                    if not trip then
                        potionTripActive = false
                        return
                    end

                    StopFarmHover()

                    local sameCharacter =
                        LocalPlayer.Character == trip.Character
                    local humanoid = sameCharacter
                        and trip.Character:FindFirstChildOfClass("Humanoid")

                    local canReturn = sameCharacter
                        and humanoid and humanoid.Health > 0
                        and trip.Root.Parent
                        and not trip.Root.Anchored

                    if returnToOrigin and canReturn then
                        humanoid:Move(Vector3.zero, false)

                        local ok, err = pcall(function()
                            trip.Root.CFrame = trip.Origin
                        end)

                        if not ok then
                            warn("[Zero X / Potion] Return failed: "
                                .. tostring(err))
                        end
                    end

                    potionTripActive = false

                    if returnToOrigin and canReturn and trip.AutoWasOn then
                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if menu and menu:IsA("BindableEvent")
                            and LocalPlayer:GetAttribute("AutoOn") ~= true then
                            menu:Fire("autoToggle")
                        end
                    end
                end

                local function PreparePotionTrip(character, humanoid, root)
                    if farmTravelActive then
                        BuyStatus("Waiting for farm zone travel")
                        return false
                    end

                    if dropTripActive or sellTripActive then
                        BuyStatus("Waiting for another shopping / loot trip")
                        return false
                    end

                    if Options.ZeroXFly and Options.ZeroXFly.Value then
                        BuyStatus("Turn Fly off before buying potions")
                        return false
                    end

                    local merchant, pivot = GetMerchantPivot()

                    if not merchant then
                        if potionTrip then
                            FinishPotionTrip(true)
                        end
                        BuyStatus("Waiting for workspace.Map.NPCs.merchant")
                        return false
                    end

                    if not potionTrip then
                        local autoOn =
                            LocalPlayer:GetAttribute("AutoOn") == true
                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if autoOn and not (
                            menu and menu:IsA("BindableEvent")
                        ) then
                            BuyStatus("Cannot pause native Auto")
                            return false
                        end

                        potionTrip = {
                            Character = character,
                            Root = root,
                            Origin = root.CFrame,
                            AutoWasOn = autoOn,
                            StartedAt = os.clock(),
                            Moved = false,
                        }

                        potionTripActive = true
                        ResetPull(false)
                        ClearTarget()

                        if autoOn then
                            menu:Fire("autoToggle")
                        end

                        BuyStatus("Waiting for native Auto to stop")
                        return false
                    end

                    local trip = potionTrip

                    if trip.Character ~= character
                        or trip.Root ~= root
                        or humanoid.Health <= 0
                        or not root.Parent then
                        FinishPotionTrip(false)
                        return false
                    end

                    if root.Anchored then
                        BuyStatus("Waiting: character anchored")
                        return false
                    end

                    if LocalPlayer:GetAttribute("AutoOn") == true then
                        if os.clock() - trip.StartedAt >= 5 then
                            warn("[Zero X / Potion] AutoOn remained true;"
                                .. " purchase was not dispatched")
                            paused = true
                            FinishPotionTrip(true)
                            BuyStatus("Paused: native Auto did not stop")
                        end
                        return false
                    end

                    local destination =
                        (pivot * CFrame.new(0, 0, 4)).Position
                    local facing = CFrame.lookAt(
                        destination,
                        pivot.Position
                    )

                    humanoid:Move(Vector3.zero, false)

                    if not trip.Moved then
                        root.CFrame = facing
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        HoldFarmPosition(
                            humanoid, root, destination, facing
                        )

                        trip.Moved = true
                        trip.MovedAt = os.clock()

                        BuyStatus("At Merchant: waiting for position check")
                        return false
                    end

                    HoldFarmPosition(
                        humanoid, root, destination, facing
                    )

                    -- ใช้ PrimaryPart เมื่อโหลดแล้ว
                    -- ถ้ายังไม่โหลด ใช้ Pivot ที่ตรวจสอบไว้
                    local merchantPart = merchant.PrimaryPart
                    local merchantPosition =
                        merchantPart and merchantPart.Position
                        or pivot.Position

                    local distance =
                        (root.Position - merchantPosition).Magnitude

                    -- เผื่อระยะจาก NpcTalkRange ที่ตรวจพบว่าเป็น 16
                    if distance > 12 then
                        if os.clock() - trip.MovedAt >= 3 then
                            warn(string.format(
                                "[Zero X / Potion] Position check failed:"
                                    .. " Distance=%.2f Root=%s Merchant=%s"
                                    .. " AutoOn=%s InTown=%s",
                                distance,
                                tostring(root.Position),
                                tostring(merchantPosition),
                                tostring(LocalPlayer:GetAttribute("AutoOn")),
                                tostring(LocalPlayer:GetAttribute("InTown"))
                            ))

                            paused = true
                            FinishPotionTrip(true)
                            BuyStatus("Paused: Merchant position not stable")
                        end
                        return false
                    end

                    -- เวลารอตรวจตำแหน่งของสคริปต์
                    -- ไม่ใช่การยืนยันตำแหน่งจาก Server
                    if os.clock() - trip.MovedAt < 0.6 then
                        return false
                    end

                    return true
                end

                Connect(LocalPlayer.CharacterRemoving, function()
                    -- ไม่ย้ายตัวละครใหม่กลับไปพิกัดของชีวิตก่อน
                    FinishPotionTrip(false)
                end)

                local function CheckPotionStock()
                    local inventory = ReadInventory()
                    if not inventory then
                        BuyStatus("Waiting for valid ItemsJson")
                        return
                    end

                    -- ตรวจผลคำขอเดิมก่อนอนุญาตให้ซื้อเพิ่ม
                    if pendingPurchase then
                        local request = pendingPurchase
                        local current = ReadCount(inventory, request.Id)

                        if current == nil then
                            BuyStatus("Invalid inventory count: " .. request.Id)
                            return
                        end

                        if current > request.Before then
                            pendingPurchase = nil
                            paused = false

                            -- รักษาสถานะเติมต่อจนถึงเป้าหมาย
                            -- ไม่หยุดเมื่อจำนวนผ่าน Buy When Left แล้ว
                            for _, selectedId in pairs(selectedPotions) do
                                if selectedId == request.Id
                                    and current < desiredStock then
                                    restocking[request.Id] = true
                                    break
                                end
                            end

                            BuyStatus(string.format(
                                "Purchase observed: %s | Stock=%d / %d",
                                request.Id,
                                current,
                                desiredStock
                            ))

                            -- ไม่ return ตรงนี้:
                            -- ตรวจยอดที่ขาดและซื้อรอบถัดไปต่อ
                        else
                            if os.clock() - request.SentAt
                                >= CONFIRM_TIMEOUT and not paused then
                                paused = true
                                FinishPotionTrip(true)

                                warn(string.format(
                                    "[Zero X / Potion] Purchase unconfirmed:"
                                        .. " Item=%s Before=%d Current=%d",
                                    request.Id,
                                    request.Before,
                                    current
                                ))

                                BuyStatus(
                                    "Purchase unconfirmed: returned to farm. "
                                    .. "Waiting for inventory update; "
                                    .. "no duplicate request sent."
                                )
                            end

                            -- ยังไม่เห็นของเพิ่ม ห้ามส่งซื้อซ้ำ
                            return
                        end
                    end

                    if paused then return end

                    if sellTripActive then
                        BuyStatus("Waiting for selling to finish")
                        return
                    end

                    if desiredStock <= restockAt then
                        FinishPotionTrip(true)
                        BuyStatus("Buy Until must be greater than Buy When Left")
                        return
                    end

                    local id
                    local def
                    local count
                    local targetStock
                    local hasSelection = false

                    for _, category in ipairs({ "Red", "Blue" }) do
                        local candidateId = selectedPotions[category]

                        if candidateId then
                            hasSelection = true

                            local candidateDef = items[candidateId]
                            if type(candidateDef) ~= "table" then
                                continue
                            end

                            local current = ReadCount(inventory, candidateId)
                            if current == nil then
                                BuyStatus("Invalid inventory count: "
                                    .. candidateId)
                                return
                            end

                            local goal = desiredStock

                            if current >= goal then
                                restocking[candidateId] = nil
                            elseif current <= restockAt then
                                restocking[candidateId] = true
                            end

                            -- เมื่อเริ่มเติมแล้ว ให้เติมต่อจนถึงเป้าหมาย
                            -- แม้จำนวนผ่านจุดเริ่มซื้อไปแล้ว
                            if restocking[candidateId] and current < goal then
                                id = candidateId
                                def = candidateDef
                                count = current
                                targetStock = goal
                                break
                            end
                        end
                    end

                    if not id then
                        FinishPotionTrip(true)
                        BuyStatus(hasSelection
                            and "Stock above threshold / refill complete"
                            or "Select Potion Blue or Red")
                        return
                    end

                    local character = LocalPlayer.Character
                    local humanoid = character
                        and character:FindFirstChildOfClass("Humanoid")
                    local root = humanoid and humanoid.RootPart

                    if not humanoid or humanoid.Health <= 0
                        or not root or not root:IsA("BasePart")
                        or not root.Parent then
                        BuyStatus("Waiting for living character")
                        return
                    end

                    if count == 0 then
                        local used = LocalPlayer:GetAttribute("BagSlotsUsed")
                        local maximum = LocalPlayer:GetAttribute("BagSlotsMax")

                        if type(used) ~= "number"
                            or type(maximum) ~= "number" then
                            BuyStatus("Waiting for bag capacity")
                            return
                        end

                        if used >= maximum then
                            FinishPotionTrip(true)
                            BuyStatus("Bag full")
                            return
                        end
                    end

                    local silver = LocalPlayer:GetAttribute("Silver")
                    local discount =
                        LocalPlayer:GetAttribute("BuyDiscountPct")

                    if discount == nil then discount = 0 end

                    if type(silver) ~= "number" or silver ~= silver
                        or silver < 0 or silver == math.huge
                        or type(discount) ~= "number"
                        or discount ~= discount
                        or math.abs(discount) == math.huge then
                        BuyStatus("Invalid currency / discount")
                        return
                    end

                    local unitPrice = math.max(
                        1,
                        math.floor(def.Buy * (100 - discount) / 100)
                    )

                    local quantity = math.min(
                        targetStock - count,
                        99,
                        math.floor(silver / unitPrice)
                    )

                    if quantity < 1 then
                        FinishPotionTrip(true)
                        BuyStatus("Not enough Silver")
                        return
                    end

                    if not shopBuy.Parent then
                        BuyStatus("ShopBuy unavailable")
                        return
                    end

                    if not PreparePotionTrip(character, humanoid, root) then
                        return
                    end

                    pendingPurchase = {
                        Id = id,
                        Before = count,
                        SentAt = os.clock(),
                    }

                    local _, merchantPivot = GetMerchantPivot()

                    print(string.format(
                        "[Zero X / Potion / Send]"
                            .. " Remote=%s Item=%s Quantity=%d"
                            .. " Have=%d Silver=%s InTown=%s Distance=%s",
                        shopBuy:GetFullName(),
                        id,
                        quantity,
                        count,
                        tostring(LocalPlayer:GetAttribute("Silver")),
                        tostring(LocalPlayer:GetAttribute("InTown")),
                        tostring(merchantPivot
                            and (root.Position - merchantPivot.Position).Magnitude)
                    ))

                    shopBuy:FireServer(id, quantity)

                    BuyStatus(string.format(
                        "Requested: %s x%d | Estimated Silver=%d",
                        id,
                        quantity,
                        quantity * unitPrice
                    ))
                end

                local function StopPotionWorker()
                    buyEnabled = false
                    if buyWorker then
                        task.cancel(buyWorker)
                        buyWorker = nil
                    end
                    FinishPotionTrip(true)
                end

                local potionSection = ShopTab:AddSection({
                    Title = "Auto Buy Potion",
                    Icon = "shopping-cart",
                })

                local function SetPotion(category, value)
                    if not alive then return end

                    selectedPotions[category] = choiceToId[value]
                    table.clear(restocking)
                    lastMessage = nil

                    -- ไม่ล้าง pendingPurchase:
                    -- ต้องตรวจผลคำขอเดิมก่อนซื้อรายการใหม่
                end

                potionSection:AddDropdown("ZeroXBuyPotionBlue", {
                    Title = "เลือกน้ำยาฟื้นฟู SP",
                    Description = "เลือกน้ำยาสีฟ้าที่ต้องการซื้ออัตโนมัติ",
                    Values = blueChoices,
                    Searchable = true,
                    AllowNull = true,

                    Callback = function(value)
                        SetPotion("Blue", value)
                    end,
                })

                potionSection:AddDropdown("ZeroXBuyPotionRed", {
                    Title = "เลือกน้ำยาฟื้นฟู HP",
                    Description = "เลือกน้ำยาฟื้นเลือดและขนาดขวดที่ต้องการซื้อ",
                    Values = redChoices,
                    Searchable = true,
                    AllowNull = true,

                    Callback = function(value)
                        SetPotion("Red", value)
                    end,
                })

                -- จำนวนที่ผู้ใช้ตั้งได้ ไม่ใช่ข้อจำกัดของเกม
                local thresholdChoices = {}
                local stockChoices = {}

                for amount = 0, 999 do
                    table.insert(thresholdChoices, tostring(amount))
                    if amount > 0 then
                        table.insert(stockChoices, tostring(amount))
                    end
                end

                potionSection:AddDropdown("ZeroXPotionBuyWhenLeft", {
                    Title = "เริ่มซื้อเมื่อเหลือ (ขวด)",
                    Description = "เมื่อจำนวนเหลือน้อยกว่าหรือเท่าค่านี้ ระบบจะเริ่มเติมน้ำยา",
                    Values = thresholdChoices,
                    Default = "10",
                    Searchable = true,

                    Callback = function(value)
                        local amount = tonumber(value)
                        if not alive or not amount or amount ~= amount
                            or amount < 0 or amount > 999 then
                            return
                        end

                        restockAt = math.floor(amount)
                        table.clear(restocking)
                        lastMessage = nil
                    end,
                })

                potionSection:AddDropdown("ZeroXPotionBuyUntil", {
                    Title = "เติมให้ถึง (ขวด)",
                    Description = "จำนวนรวมที่ต้องการมีในกระเป๋า ต้องมากกว่าจำนวนเริ่มซื้อ",
                    Values = stockChoices,
                    Default = "100",
                    Searchable = true,

                    Callback = function(value)
                        local amount = tonumber(value)
                        if not alive or not amount or amount ~= amount
                            or amount < 1 or amount > 999 then
                            return
                        end

                        desiredStock = math.floor(amount)
                        table.clear(restocking)
                        lastMessage = nil
                    end,
                })

                potionSection:AddToggle("ZeroXAutoBuyPotion", {
                    Title = "เปิดซื้อน้ำยาอัตโนมัติ",
                    Description = "ซื้อน้ำยาอัตโนมัติตามค่าที่ตั้งไว้",
                    Default = false,

                    Callback = function(value)
                        if not alive then return end

                        if value ~= true then
                            StopPotionWorker()
                            return
                        end

                        if buyWorker then return end

                        -- เปิดใหม่หลังพัก = ผู้ใช้ขอลองซื้ออีกครั้ง
                        if paused then
                            pendingPurchase = nil
                            paused = false
                        end

                        buyEnabled = true
                        lastMessage = nil

                        buyWorker = task.defer(function()
                            local ok, err = xpcall(function()
                                while alive and buyEnabled do
                                    CheckPotionStock()
                                    task.wait(CHECK_INTERVAL)
                                end
                            end, debug.traceback)

                            buyWorker = nil

                            if not ok then
                                buyEnabled = false
                                FinishPotionTrip(true)
                                warn("[Zero X / Potion] " .. tostring(err))
                            end
                        end)
                    end,
                })

                MacUI:OnUnload(StopPotionWorker)

                if #blueChoices == 0 then
                    warn("[Zero X / Potion] No SP potions found")
                end
                if #redChoices == 0 then
                    warn("[Zero X / Potion] No HP potions found")
                end
            end
        end

        do
            local pickupDrop = FindRequired(
                remotes, "PickupDrop", "RemoteEvent"
            )
            local configModule = FindRequired(
                shared, "GameConfig", "ModuleScript"
            )
            local config = configModule and LoadModule(configModule)

            if pickupDrop and config then
                local reach = config.DropPickupReach
                local ownerTime = config.DropOwnerTime
                local pickupDelay = config.DropPickupDelay or 0

                local function IsFinite(value)
                    return type(value) == "number"
                        and value == value
                        and math.abs(value) < math.huge
                end

                if IsFinite(reach) and reach > 0
                    and IsFinite(ownerTime) and ownerTime >= 0
                    and IsFinite(pickupDelay) and pickupDelay >= 0 then

                    local enabled = false
                    local collectWorker
                    local drops = {}
                    local lastRequest = -math.huge

                    -- ค่านโยบายของสคริปต์ ปรับได้
                    local SEARCH_RADIUS = 300
                    local REQUEST_TIMEOUT = 2
                    local RETRY_DELAY = 10

                    local trip
                    local retryAt = setmetatable({}, { __mode = "k" })

                    local function FinishDropTrip(returnToOrigin)
                        local old = trip
                        trip = nil

                        if not old then
                            dropTripActive = false
                            return
                        end

                        local humanoid = old.Character
                            :FindFirstChildOfClass("Humanoid")

                        local valid = LocalPlayer.Character == old.Character
                            and humanoid and humanoid.Health > 0
                            and old.Root.Parent
                            and not old.Root.Anchored

                        if returnToOrigin and valid then
                            old.Root.CFrame = old.Origin
                            old.Root.AssemblyLinearVelocity = Vector3.zero
                            old.Root.AssemblyAngularVelocity = Vector3.zero
                        end

                        dropTripActive = false

                        if returnToOrigin and valid and alive
                            and not potionTripActive and old.AutoWasOn then
                            local menu =
                                LocalPlayer:FindFirstChild("LumiMenuToggle")

                            if menu and menu:IsA("BindableEvent")
                                and LocalPlayer:GetAttribute("AutoOn")
                                    ~= true then
                                menu:Fire("autoToggle")
                            end
                        end
                    end

                    local function DropAllowed(drop, folder)
                        if not drop:IsDescendantOf(folder) then
                            return false
                        end

                        local freeAt = drop:GetAttribute("FreeAt")
                        local owner = drop:GetAttribute("OwnerUserId")

                        if freeAt == nil then freeAt = 0 end
                        if owner == nil then owner = 0 end

                        if not IsFinite(freeAt) or not IsFinite(owner) then
                            return false
                        end

                        local now = workspace:GetServerTimeNow()

                        return now >= freeAt - ownerTime + pickupDelay
                            and (
                                owner == 0
                                or owner == LocalPlayer.UserId
                                or now >= freeAt
                            )
                    end

                    Connect(LocalPlayer.CharacterRemoving, function()
                        FinishDropTrip(false)
                    end)

                    local function AddDrop(instance)
                        if instance:IsA("BasePart") then
                            drops[instance] = true
                        end
                    end

                    Connect(
                        CollectionService:GetInstanceAddedSignal("Drop"),
                        AddDrop
                    )

                    Connect(
                        CollectionService:GetInstanceRemovedSignal("Drop"),
                        function(instance)
                            drops[instance] = nil
                        end
                    )

                    for _, instance in ipairs(
                        CollectionService:GetTagged("Drop")
                    ) do
                        AddDrop(instance)
                    end

                    local function CheckDrops()
                        if potionTripActive or sellTripActive
                            or farmPullActive or farmTravelActive
                            or (Options.ZeroXFly
                                and Options.ZeroXFly.Value) then
                            FinishDropTrip(true)
                            return
                        end

                        local character = LocalPlayer.Character
                        local humanoid = character
                            and character:FindFirstChildOfClass("Humanoid")
                        local root = humanoid and humanoid.RootPart

                        if not humanoid or humanoid.Health <= 0
                            or not root or not root:IsA("BasePart")
                            or not root.Parent then
                            FinishDropTrip(false)
                            return
                        end

                        if root.Anchored then
                            FinishDropTrip(true)
                            return
                        end

                        if trip and (
                            trip.Character ~= character or trip.Root ~= root
                        ) then
                            FinishDropTrip(false)
                            return
                        end

                        local folder = workspace:FindFirstChild("Drops")
                        local used = LocalPlayer:GetAttribute("BagSlotsUsed")
                        local maximum = LocalPlayer:GetAttribute("BagSlotsMax")

                        if not folder or not pickupDrop.Parent
                            or not IsFinite(used) or not IsFinite(maximum)
                            or maximum <= 0 or used >= maximum then
                            FinishDropTrip(true)
                            return
                        end

                        local now = os.clock()

                        if trip then
                            local drop = trip.Drop

                            if not DropAllowed(drop, folder) then
                                -- ของหายไม่ได้ยืนยันว่าเราเป็นคนเก็บ
                                FinishDropTrip(true)
                                return
                            end

                            if now - trip.StartedAt >= 5 then
                                retryAt[drop] = now + RETRY_DELAY
                                FinishDropTrip(true)
                                return
                            end

                            if LocalPlayer:GetAttribute("AutoOn") == true then
                                return
                            end

                            humanoid:Move(Vector3.zero, false)

                            if not trip.Moved then
                                local destination = drop.Position
                                    + Vector3.new(0, math.min(2, reach / 2), 0)

                                root.CFrame = CFrame.new(destination)
                                    * root.CFrame.Rotation
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero

                                trip.Moved = true
                                return -- ตรวจระยะใหม่ในรอบหน้า
                            end

                            if not trip.SentAt then
                                if now - lastRequest < 0.6 then return end

                                if (drop.Position - root.Position).Magnitude
                                    > reach then
                                    retryAt[drop] = now + RETRY_DELAY
                                    FinishDropTrip(true)
                                    return
                                end

                                trip.Items = LocalPlayer:GetAttribute("ItemsJson")
                                trip.Gear = LocalPlayer:GetAttribute("GearJson")
                                trip.Silver = LocalPlayer:GetAttribute("Silver")
                                trip.SentAt = now
                                lastRequest = now

                                pickupDrop:FireServer()
                                return
                            end

                            local inventoryChanged =
                                LocalPlayer:GetAttribute("ItemsJson")
                                    ~= trip.Items
                                or LocalPlayer:GetAttribute("GearJson")
                                    ~= trip.Gear
                                or LocalPlayer:GetAttribute("Silver")
                                    ~= trip.Silver

                            if inventoryChanged
                                or now - trip.SentAt >= REQUEST_TIMEOUT then
                                -- ป้องกันวาปซ้ำหาของเดิมที่ยังเก็บไม่ได้
                                retryAt[drop] = now + RETRY_DELAY
                                FinishDropTrip(true)
                            end
                            return
                        end

                        -- รอร่ายจบก่อนเริ่มเดินทางไปเก็บของ
                        if now < skillCastUntil then return end
                        if now - lastRequest < 0.6 then return end

                        local nearest
                        local nearestDistance = SEARCH_RADIUS

                        for drop in pairs(drops) do
                            if now < (retryAt[drop] or 0)
                                or not DropAllowed(drop, folder) then
                                continue
                            end

                            local distance =
                                (drop.Position - root.Position).Magnitude

                            if distance < nearestDistance then
                                nearest = drop
                                nearestDistance = distance
                            end
                        end

                        if not nearest then return end

                        local autoOn =
                            LocalPlayer:GetAttribute("AutoOn") == true
                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if autoOn and not (
                            menu and menu:IsA("BindableEvent")
                        ) then
                            return
                        end

                        trip = {
                            Character = character,
                            Root = root,
                            Origin = root.CFrame,
                            Drop = nearest,
                            StartedAt = now,
                            AutoWasOn = autoOn,
                        }

                        dropTripActive = true
                        ClearTarget()

                        if autoOn then
                            menu:Fire("autoToggle")
                        end
                    end

                    local function StopCollector()
                        enabled = false

                        if collectWorker then
                            task.cancel(collectWorker)
                            collectWorker = nil
                        end

                        FinishDropTrip(true)
                    end

                    recoverySection:AddToggle("ZeroXAutoCollectDrop", {
                        Title = "Auto Collect Drop",
                        Description = "วาปเก็บของออโต้",
                        Default = false,
                        Callback = function(value)
                            StopCollector()
                            if not alive or not value then return end

                            enabled = true
                            collectWorker = task.spawn(function()
                                while alive and enabled do
                                    task.wait(0.2)
                                    if not alive or not enabled then break end
                                    CheckDrops()
                                end
                            end)
                        end,
                    })

                    MacUI:OnUnload(function()
                        StopCollector()
                        table.clear(drops)
                    end)
                else
                    warn("[Zero X / Drop] Invalid pickup configuration")
                end
            end
        end

        do
            local equipItem = FindRequired(
                remotes,
                "EquipItem",
                "RemoteEvent"
            )
            local setAutoEquip = FindRequired(
                remotes,
                "SetAutoEquip",
                "RemoteEvent"
            )

            if equipItem and setAutoEquip then
                local originalAutoEquip =
                    LocalPlayer:GetAttribute("AutoEquip") == true

                local gearEnabled = originalAutoEquip
                local nativeSettingChanged = false
                local queuedEquip
                local lastEquipRequest = -math.huge

                -- จำกัดคำขอของสคริปต์ ไม่ใช่ Cooldown ของเกม
                local REQUEST_INTERVAL = 2

                local function CancelQueuedEquip()
                    if queuedEquip then
                        task.cancel(queuedEquip)
                        queuedEquip = nil
                    end
                end

                local function QueueEquipBest()
                    if not alive or not gearEnabled or queuedEquip then
                        return
                    end

                    local delaySeconds = math.max(
                        0,
                        REQUEST_INTERVAL
                            - (os.clock() - lastEquipRequest)
                    )

                    -- รวม Event ที่มาติดกันเป็นคำขอเดียว
                    queuedEquip = task.delay(delaySeconds, function()
                        queuedEquip = nil

                        if not alive or not gearEnabled
                            or not equipItem.Parent then
                            return
                        end

                        lastEquipRequest = os.clock()
                        equipItem:FireServer("@best")

                        print("[Zero X / Gear] Requested native Equip Best")
                    end)
                end

                local gearSection = FarmTab:AddSection({
                    Title = "Equipment",
                    Icon = "shield",
                })

                gearSection:AddToggle("ZeroXAutoEquipGearBest", {
                    Title = "Auto Equip Best",
                    Description = "เลือกอาวุธ/เกียร์ที่ดีที่สุด และเปิดใส่อุปกรณ์อัตโนมัติ",
                    Default = originalAutoEquip,

                    Callback = function(value)
                        if not alive or type(value) ~= "boolean" then
                            return
                        end

                        gearEnabled = value

                        if not value then
                            CancelQueuedEquip()
                        end

                        if setAutoEquip.Parent
                            and LocalPlayer:GetAttribute("AutoEquip")
                                ~= value then
                            nativeSettingChanged = true
                            setAutoEquip:FireServer(value)
                        end

                        if value then
                            QueueEquipBest()
                        end
                    end,
                })

                -- ของใหม่ให้ Native AutoEquip จัดการ
                -- ตรวจซ้ำเมื่อเงื่อนไขเลือก Gear เปลี่ยน
                for _, attribute in ipairs({
                    "Level",
                    "Job",
                    "RefineJson",
                }) do
                    Connect(
                        LocalPlayer:GetAttributeChangedSignal(attribute),
                        QueueEquipBest
                    )
                end

                Connect(LocalPlayer.CharacterAdded, QueueEquipBest)

                Connect(
                    LocalPlayer:GetAttributeChangedSignal("AutoEquip"),
                    function()
                        if not alive then return end

                        print("[Zero X / Gear] Native AutoEquip="
                            .. tostring(
                                LocalPlayer:GetAttribute("AutoEquip")
                            ))
                    end
                )

                for _, attribute in ipairs({ "EquipJson", "WeaponId" }) do
                    Connect(
                        LocalPlayer:GetAttributeChangedSignal(attribute),
                        QueueEquipBest
                    )
                end

                MacUI:OnUnload(function()
                    gearEnabled = false
                    CancelQueuedEquip()

                    -- คืนค่าตั้งเกมก่อนเริ่มใช้สคริปต์
                    if nativeSettingChanged and setAutoEquip.Parent
                        and LocalPlayer:GetAttribute("AutoEquip")
                            ~= originalAutoEquip then
                        setAutoEquip:FireServer(originalAutoEquip)
                    end
                end)

                if gearEnabled then
                    QueueEquipBest()
                end
            end
        end

        do
            local junkRemote = FindRequired(
                remotes, "ShopSellJunk", "RemoteEvent"
            )
            local bulkRemote = FindRequired(
                remotes, "BagSell", "RemoteEvent"
            )
            local itemModule = FindRequired(
                shared, "ItemData", "ModuleScript"
            )
            local gearModule = FindRequired(
                shared, "GearUtil", "ModuleScript"
            )
            local configModule = FindRequired(
                shared, "GameConfig", "ModuleScript"
            )

            local sellItems = itemModule and LoadModule(itemModule)
            local gearUtil = gearModule and LoadModule(gearModule)
            local gameConfig = configModule and LoadModule(configModule)

            if junkRemote and bulkRemote and sellItems
                and gearUtil and type(gearUtil.Resolve) == "function"
                and gameConfig then

                local junkEnabled = false
                local bulkEnabled = false
                local onlyFull = false
                local interval = 30
                local sellWorker
                local pendingSale
                local blocked = false
                local lastAttempt = -math.huge
                local lastStatus
                local preferBulk = false
                local jsonCache = {}

                -- นโยบายรอผลของสคริปต์ ไม่ใช่ Cooldown ของเกม
                local CONFIRM_TIMEOUT = 3

                local gradeNames = {
                    "Tier I", "Tier II", "Tier III",
                    "Tier IV", "Tier V",
                }
                local gradeIds = {
                    ["Tier I"] = 0,
                    ["Tier II"] = 1,
                    ["Tier III"] = 2,
                    ["Tier IV"] = 3,
                    ["Tier V"] = 4,
                }
                local selectedGrades = { [0] = true, [1] = true }

                local function SellStatus(message)
                    if message == lastStatus then return end
                    lastStatus = message
                    print("[Zero X / Sell] " .. message)
                end

                -- ข้อมูลป้องกันไอเทมอ่านไม่ได้ = ไม่ขาย
                local function ReadSellJson(attribute)
                    local raw = LocalPlayer:GetAttribute(attribute)
                    local cached = jsonCache[attribute]

                    if cached and cached.Raw == raw then
                        return cached.Data
                    end

                    if type(raw) ~= "string" or raw == "" then
                        return nil
                    end

                    local ok, decoded = pcall(function()
                        return HttpService:JSONDecode(raw)
                    end)

                    if not ok or type(decoded) ~= "table" then
                        return nil
                    end

                    jsonCache[attribute] = {
                        Raw = raw,
                        Data = decoded,
                    }
                    return decoded
                end

                local function PositiveNumber(value)
                    return type(value) == "number"
                        and value == value
                        and value > 0
                        and value < math.huge
                end

                local function BagIsFull()
                    local used = LocalPlayer:GetAttribute("BagSlotsUsed")
                    local maximum = LocalPlayer:GetAttribute("BagSlotsMax")
                    local weight = LocalPlayer:GetAttribute("Weight")
                    local maxWeight = LocalPlayer:GetAttribute("MaxWeight")

                    local slotsFull = type(used) == "number"
                        and PositiveNumber(maximum)
                        and used >= maximum

                    local weightFull = type(weight) == "number"
                        and PositiveNumber(maxWeight)
                        and weight >= maxWeight

                    return slotsFull or weightFull
                end

                local function CanSellHere()
                    local character = LocalPlayer.Character
                    local humanoid = character
                        and character:FindFirstChildOfClass("Humanoid")
                    local root = humanoid and humanoid.RootPart

                    if not humanoid or humanoid.Health <= 0
                        or not root or not root:IsA("BasePart")
                        or not root.Parent then
                        return false
                    end

                    if LocalPlayer:GetAttribute("Premium") == true
                        or LocalPlayer:GetAttribute("InTown") == true then
                        return true
                    end

                    local map = workspace:FindFirstChild("Map")
                    local npcs = map and map:FindFirstChild("NPCs")
                    local merchant = npcs
                        and npcs:FindFirstChild("merchant")

                    return merchant ~= nil
                        and merchant:IsA("Model")
                        and (root.Position
                            - merchant:GetPivot().Position).Magnitude <= 20
                end

                local sellTrip

                local function FinishSellTrip(returnToOrigin)
                    local old = sellTrip
                    sellTrip = nil

                    if not old then
                        sellTripActive = false
                        return
                    end

                    local humanoid = old.Character
                        :FindFirstChildOfClass("Humanoid")

                    local valid = LocalPlayer.Character == old.Character
                        and humanoid and humanoid.Health > 0
                        and old.Root.Parent
                        and not old.Root.Anchored

                    if returnToOrigin and valid then
                        old.Root.CFrame = old.Origin
                        old.Root.AssemblyLinearVelocity = Vector3.zero
                        old.Root.AssemblyAngularVelocity = Vector3.zero
                    end

                    sellTripActive = false

                    if returnToOrigin and valid and alive
                        and old.AutoWasOn
                        and not potionTripActive
                        and not dropTripActive then

                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if menu and menu:IsA("BindableEvent")
                            and LocalPlayer:GetAttribute("AutoOn") ~= true then
                            menu:Fire("autoToggle")
                        end
                    end
                end

                local function PrepareSellTrip()
                    local character = LocalPlayer.Character
                    local humanoid = character
                        and character:FindFirstChildOfClass("Humanoid")
                    local root = humanoid and humanoid.RootPart

                    if not humanoid or humanoid.Health <= 0
                        or not root or not root:IsA("BasePart")
                        or not root.Parent then
                        FinishSellTrip(false)
                        return false
                    end

                    if root.Anchored then
                        SellStatus("Waiting: character anchored")
                        return false
                    end

                    if sellTrip and (
                        sellTrip.Character ~= character
                        or sellTrip.Root ~= root
                    ) then
                        FinishSellTrip(false)
                        return false
                    end

                    -- ถ้าขายได้ตรงนี้อยู่แล้ว ไม่ต้องเดินทาง
                    if not sellTrip and CanSellHere() then
                        return true
                    end

                    local map = workspace:FindFirstChild("Map")
                    local npcs = map and map:FindFirstChild("NPCs")
                    local merchant = npcs
                        and npcs:FindFirstChild("merchant")

                    if not merchant or not merchant:IsA("Model") then
                        SellStatus("Waiting for Map.NPCs.merchant")
                        return false
                    end

                    if not sellTrip then
                        local autoOn =
                            LocalPlayer:GetAttribute("AutoOn") == true
                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if autoOn and not (
                            menu and menu:IsA("BindableEvent")
                        ) then
                            SellStatus("Cannot pause native Auto")
                            return false
                        end

                        sellTrip = {
                            Character = character,
                            Root = root,
                            Origin = root.CFrame,
                            AutoWasOn = autoOn,
                            StartedAt = os.clock(),
                        }

                        sellTripActive = true
                        ResetPull(false)
                        ClearTarget()

                        if autoOn then
                            menu:Fire("autoToggle")
                        end

                        SellStatus("Pausing farm before selling")
                        return false
                    end

                    if os.clock() - sellTrip.StartedAt >= 8 then
                        FinishSellTrip(true)
                        lastAttempt = os.clock()
                        SellStatus("Merchant trip timed out")
                        return false
                    end

                    if LocalPlayer:GetAttribute("AutoOn") == true then
                        return false
                    end

                    humanoid:Move(Vector3.zero, false)

                    if not sellTrip.Moved then
                        local pivot = merchant:GetPivot()
                        local position =
                            (pivot * CFrame.new(0, 0, 4)).Position

                        root.CFrame = CFrame.lookAt(
                            position, pivot.Position
                        )
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        sellTrip.Moved = true
                        SellStatus("Moved to Merchant; checking distance")
                        return false
                    end

                    return (root.Position
                        - merchant:GetPivot().Position).Magnitude <= 20
                end

                Connect(LocalPlayer.CharacterRemoving, function()
                    FinishSellTrip(false)
                end)

                local function CollectJunk()
                    local inventory = ReadSellJson("ItemsJson")
                    local locks = ReadSellJson("LocksJson")
                    local keep = gameConfig.JunkKeep

                    if keep == nil then keep = {} end

                    if not inventory or not locks
                        or type(keep) ~= "table" then
                        return nil
                    end

                    local expected = {}

                    for id, count in pairs(inventory) do
                        local def = sellItems[id]

                        if type(id) == "string"
                            and PositiveNumber(count)
                            and type(def) == "table"
                            and def.Kind == "etc"
                            and PositiveNumber(def.Sell)
                            and def.Bound ~= true
                            and not keep[id]
                            and not locks[id] then
                            expected[id] = count
                        end
                    end

                    return expected
                end

                local function CollectGear()
                    local gear = ReadSellJson("GearJson")
                    local equipped = ReadSellJson("EquipJson")
                    local locks = ReadSellJson("LocksJson")
                    local refine = ReadSellJson("RefineJson")
                    local weapon = LocalPlayer:GetAttribute("WeaponId")

                    if not gear or not equipped or not locks or not refine
                        or type(weapon) ~= "string" then
                        return nil, "Bulk waiting for valid equipment data"
                    end

                    local equippedRefs = {}
                    equippedRefs[weapon] = true

                    for _, ref in pairs(equipped) do
                        if type(ref) == "string" then
                            equippedRefs[ref] = true
                        end
                    end

                    local refs = {}

                    for ref, instance in pairs(gear) do
                        if type(ref) ~= "string"
                            or type(instance) ~= "table"
                            or type(instance.Id) ~= "string"
                            or equippedRefs[ref]
                            or locks[ref] then
                            continue
                        end

                        local refinement = refine[ref]
                        if refinement == nil then refinement = 0 end

                        if type(refinement) ~= "number"
                            or refinement ~= refinement
                            or refinement ~= 0 then
                            continue
                        end

                        -- Resolve อาจปฏิเสธข้อมูล Gear ที่ไม่สมบูรณ์
                        local ok, def = pcall(gearUtil.Resolve, ref, gear)

                        if not ok or type(def) ~= "table"
                            or (def.Kind ~= "weapon" and def.Kind ~= "armor")
                            or def.Bound == true
                            or not PositiveNumber(def.Sell) then
                            continue
                        end

                        local rarity = def.Rarity

                        -- ไม่เดาระดับ และไม่ Clamp ระดับสูงลงมา
                        if type(rarity) == "number"
                            and rarity >= 0 and rarity <= 4
                            and rarity == math.floor(rarity)
                            and selectedGrades[rarity] == true then
                            table.insert(refs, ref)
                        end
                    end

                    table.sort(refs)
                    return refs
                end

                local function CheckSaleResult()
                    local request = pendingSale
                    if not request then return end

                    local data = ReadSellJson(
                        request.Mode == "Bulk" and "GearJson" or "ItemsJson"
                    )
                    local complete = data ~= nil

                    if data then
                        for id, before in pairs(request.Expected) do
                            if request.Mode == "Bulk" then
                                if data[id] ~= nil then
                                    complete = false
                                    break
                                end
                            else
                                local current = data[id]
                                if current == nil then current = 0 end

                                if type(current) ~= "number"
                                    or current ~= current
                                    or current < 0
                                    or current >= before then
                                    complete = false
                                    break
                                end
                            end
                        end
                    end

                    if complete then
                        SellStatus(request.Mode
                            .. ": inventory removal/decrease observed")
                        pendingSale = nil
                        blocked = false
                        FinishSellTrip(true)
                    elseif os.clock() - request.SentAt >= CONFIRM_TIMEOUT
                        and not blocked then
                        blocked = true
                        FinishSellTrip(true)
                        SellStatus("Paused: sale not confirmed. "
                            .. "Check inventory before toggling off/on.")
                    end
                end

                local function SellStep()
                    if pendingSale then
                        CheckSaleResult()
                        if pendingSale then return end
                    end

                    if blocked or potionTripActive
                        or dropTripActive or farmTravelActive then
                        return
                    end
                    if os.clock() - lastAttempt < interval then return end

                    if onlyFull and not BagIsFull() then
                        SellStatus("Waiting for full bag")
                        return
                    end

                    local mode
                    local payload
                    local expected

                    -- สลับลำดับเมื่อเปิดสองโหมด ไม่ส่งขายพร้อมกัน
                    local order = preferBulk
                        and { "Bulk", "Junk" } or { "Junk", "Bulk" }

                    for _, candidateMode in ipairs(order) do
                        if candidateMode == "Junk" and junkEnabled then
                            local junk = CollectJunk()

                            if not junk then
                                SellStatus("Junk waiting for valid inventory/locks")
                            elseif next(junk) then
                                mode = "Junk"
                                expected = junk
                                break
                            end

                        elseif candidateMode == "Bulk" and bulkEnabled then
                            local refs, reason = CollectGear()

                            if not refs then
                                SellStatus(reason)
                            elseif #refs > 0 then
                                mode = "Bulk"
                                payload = refs
                                expected = {}

                                for _, ref in ipairs(refs) do
                                    expected[ref] = true
                                end
                                break
                            end
                        end
                    end

                    if not mode then
                        FinishSellTrip(true)
                        return
                    end

                    if not PrepareSellTrip() then return end

                    if mode == "Bulk" then
                        -- อ่านใหม่หลังเดินทาง เพราะ Auto Equip
                        -- อาจเปลี่ยนของสวมใส่ระหว่างไปหาพ่อค้า
                        local beforeEquip =
                            LocalPlayer:GetAttribute("EquipJson")
                        local beforeWeapon =
                            LocalPlayer:GetAttribute("WeaponId")
                        local beforeGear =
                            LocalPlayer:GetAttribute("GearJson")
                        local beforeLocks =
                            LocalPlayer:GetAttribute("LocksJson")
                        local beforeRefine =
                            LocalPlayer:GetAttribute("RefineJson")

                        local freshRefs, reason = CollectGear()

                        if not freshRefs then
                            FinishSellTrip(true)
                            SellStatus(reason)
                            return
                        end

                        if #freshRefs == 0 then
                            FinishSellTrip(true)
                            SellStatus("Bulk: no eligible equipment")
                            return
                        end

                        -- ข้อมูลเปลี่ยนระหว่างตรวจ ให้ตรวจใหม่รอบหน้า
                        if LocalPlayer:GetAttribute("EquipJson")
                                ~= beforeEquip
                            or LocalPlayer:GetAttribute("WeaponId")
                                ~= beforeWeapon
                            or LocalPlayer:GetAttribute("GearJson")
                                ~= beforeGear
                            or LocalPlayer:GetAttribute("LocksJson")
                                ~= beforeLocks
                            or LocalPlayer:GetAttribute("RefineJson")
                                ~= beforeRefine then
                            SellStatus("Bulk: equipment changed; checking again")
                            return
                        end

                        payload = freshRefs
                        expected = {}

                        for _, ref in ipairs(freshRefs) do
                            expected[ref] = true
                        end
                    end

                    local remote = mode == "Bulk"
                        and bulkRemote or junkRemote
                    if not remote.Parent then
                        SellStatus("Sell remote unavailable")
                        return
                    end

                    local now = os.clock()
                    lastAttempt = now
                    pendingSale = {
                        Mode = mode,
                        Expected = expected,
                        SentAt = now,
                    }
                    preferBulk = mode == "Junk"

                    if mode == "Bulk" then
                        bulkRemote:FireServer(payload)
                        SellStatus("Requested Bulk: "
                            .. tostring(#payload) .. " gear")
                    else
                        junkRemote:FireServer()
                        SellStatus("Requested native Sell Junk")
                    end
                end

                local function StopSellWorker()
                    if sellWorker then
                        task.cancel(sellWorker)
                        sellWorker = nil
                    end
                    FinishSellTrip(true)
                end

                local function UpdateSellWorker()
                    if not junkEnabled and not bulkEnabled then
                        StopSellWorker()
                        return
                    end
                    if sellWorker then return end

                    sellWorker = task.defer(function()
                        local ok, err = xpcall(function()
                            while alive and (junkEnabled or bulkEnabled) do
                                SellStep()
                                task.wait(0.5)
                            end
                        end, debug.traceback)

                        sellWorker = nil

                        if not ok then
                            junkEnabled = false
                            bulkEnabled = false
                            warn("[Zero X / Sell] " .. tostring(err))
                        end
                    end)
                end

                local autoSellSection = ShopTab:AddSection({
                    Title = "Auto Sell",
                    Icon = "coins",
                })

                autoSellSection:AddParagraph({
                    Title = "Selling Guide",
                    Content = "Auto Sell Junk ขายวัสดุจิปาถะที่ขายได้ "
                        .. "ข้ามของล็อก ของผูกมัด "
                        .. "และรายการที่เกมกำหนดให้เก็บไว้\n\n"
                        .. "Auto Bulk Sell ขายอาวุธและชุดเกราะ"
                        .. "ข้ามของที่สวมใส่ ล็อก ผูกมัด และตีบวก",
                })

                autoSellSection:AddDropdown("ZeroXSellGrades", {
                    Title = "Bulk Sell Grades",
                    Values = gradeNames,
                    Multi = true,
                    Default = { "Tier I", "Tier II" },

                    Callback = function(values)
                        if not alive or type(values) ~= "table" then
                            return
                        end

                        table.clear(selectedGrades)
                        for label, selected in pairs(values) do
                            local grade = gradeIds[label]
                            if selected == true and grade ~= nil then
                                selectedGrades[grade] = true
                            end
                        end
                    end,
                })

                local function SetSellMode(mode, value)
                    if not alive then return end
                    local enabledValue = value == true

                    -- เปิดใหม่หลังพัก = ผู้ใช้สั่งลองใหม่
                    if enabledValue and blocked then
                        pendingSale = nil
                        blocked = false
                    end

                    if mode == "Junk" then
                        junkEnabled = enabledValue
                    else
                        bulkEnabled = enabledValue
                    end

                    UpdateSellWorker()
                end

                autoSellSection:AddToggle("ZeroXAutoSellJunk", {
                    Title = "Auto Sell Junk",
                    Default = false,
                    Callback = function(value)
                        SetSellMode("Junk", value)
                    end,
                })

                autoSellSection:AddToggle("ZeroXAutoBulkSell", {
                    Title = "Auto Bulk Sell",
                    Default = false,
                    Callback = function(value)
                        SetSellMode("Bulk", value)
                    end,
                })

                local sellSection = ShopTab:AddSection({
                    Title = "Sell Settings",
                    Icon = "coins",
                })


                sellSection:AddSlider("ZeroXSellInterval", {
                    Title = "Sell Interval (Seconds)",
                    Description = "เวลาขั้นต่ำระหว่างคำขอขาย "
                        .. "ใช้ร่วมกันทั้งสองประเภท",
                    Min = 2,
                    Max = 300,
                    Default = 30,
                    Increment = 1,

                    Callback = function(value)
                        if type(value) == "number" and value == value
                            and value >= 2 and value <= 300 then
                            interval = math.floor(value)
                        end
                    end,
                })

                sellSection:AddToggle("ZeroXSellOnlyFull", {
                    Title = "Only When Bag Full",
                    Description = "ขายเมื่อช่องกระเป๋าเต็ม "
                        .. "หรือน้ำหนักถึงขีดจำกัด",
                    Default = false,

                    Callback = function(value)
                        if alive then onlyFull = value == true end
                    end,
                })

                MacUI:OnUnload(function()
                    junkEnabled = false
                    bulkEnabled = false
                    StopSellWorker()
                end)
            end
        end

        Connect(LocalPlayer.CharacterRemoving, ClearTarget)

        MacUI:OnUnload(function()
            alive = false
            Stop()

            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            for _, connection in ipairs(monsterConnections) do
                connection:Disconnect()
            end

            table.clear(connections)
            table.clear(monsterConnections)
            table.clear(monsters)
        end)
    end

    InitHuntingFarm()
end

--------------------------------------------------------------------------------
-- PLAYER: Client utilities
--------------------------------------------------------------------------------
do
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local PromptService = game:GetService("ProximityPromptService")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")

    local state = {
        WalkSpeed = false,
        Speed = 32,
        InfiniteJump = false,
        Noclip = false,
        InstantPrompt = false,
        Fly = false,
        FlySpeed = 60,
        FPSBoost = false,
        UltraFPSBoost = false,
        DisableAnimations = false,
        Reconnect = false,
    }

    local alive = true
    local connections = {}
    local motionConnection
    local flight
    local watchedAnimator
    local animationConnection
    local reconnecting = false
    local reconnectToken = 0
    local renderDisabled = false
    local performanceVersion = 0

    local function WeakKeys()
        return setmetatable({}, { __mode = "k" })
    end

    local speedSaved = WeakKeys()
    local collisionSaved = WeakKeys()
    local promptSaved = WeakKeys()
    local animationSaved = WeakKeys()
    local performanceSaved = WeakKeys()

    local function Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function Report(message)
        warn("[Zero X / Player] " .. tostring(message))
        if alive and not MacUI.Unloaded then
            Window:Toast("Player", {
                Detail = tostring(message),
                Icon = "info",
            })
        end
    end

    -- เก็บค่าก่อนแก้ และคืนเฉพาะค่าที่ยังตรงกับที่ระบบนี้เขียนไว้
    local function Patch(bag, object, property, value)
        if not object then return end

        local ok, current = pcall(function()
            return object[property]
        end)
        if not ok then return end

        local properties = bag[object]
        local record = properties and properties[property]

        if current == value then
            if record then record.Applied = value end
            return
        end

        local written = pcall(function()
            object[property] = value
        end)
        if not written then return end

        if not properties then
            properties = {}
            bag[object] = properties
        end

        if not record then
            record = { Original = current }
            properties[property] = record
        end
        record.Applied = value
    end

    local function Restore(bag)
        for object, properties in pairs(bag) do
            for property, record in pairs(properties) do
                pcall(function()
                    if object[property] == record.Applied then
                        object[property] = record.Original
                    end
                end)
            end
            bag[object] = nil
        end
    end

    local function GetCharacter()
        local character = LocalPlayer.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")
        local root = humanoid and humanoid.RootPart
        return character, humanoid, root
    end

    --------------------------------------------------------------------------
    -- Fly: WASD / Space ขึ้น / LeftControl ลง
    --------------------------------------------------------------------------
    local function StopFlight()
        if not flight then return end

        local old = flight
        flight = nil

        old.Velocity:Destroy()
        old.Orientation:Destroy()
        old.Attachment:Destroy()

        pcall(function()
            if old.Humanoid.AutoRotate == false then
                old.Humanoid.AutoRotate = old.AutoRotate
            end
        end)
    end

    local function StartFlight(humanoid, root)
        StopFlight()

        local attachment = Instance.new("Attachment")
        attachment.Name = "ZeroXFlightAttachment"
        attachment.Parent = root

        local velocity = Instance.new("LinearVelocity")
        velocity.Name = "ZeroXFlightVelocity"
        velocity.Attachment0 = attachment
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        velocity.ForceLimitsEnabled = false
        velocity.VectorVelocity = Vector3.zero
        velocity.Parent = root

        local orientation = Instance.new("AlignOrientation")
        orientation.Name = "ZeroXFlightOrientation"
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Attachment0 = attachment
        orientation.MaxTorque = math.huge
        orientation.Responsiveness = 20
        orientation.CFrame = root.CFrame.Rotation
        orientation.Parent = root

        flight = {
            Root = root,
            Humanoid = humanoid,
            AutoRotate = humanoid.AutoRotate,
            Attachment = attachment,
            Velocity = velocity,
            Orientation = orientation,
        }

        humanoid.AutoRotate = false
    end

    --------------------------------------------------------------------------
    -- Animations: หยุดเวลา Animation ของตัวละครเรา และคืนความเร็วเมื่อปิด
    --------------------------------------------------------------------------
    local function FreezeTrack(track)
        if not alive or not state.DisableAnimations then return end

        pcall(function()
            if animationSaved[track] == nil then
                animationSaved[track] = track.Speed
            end
            track:AdjustSpeed(0)
        end)
    end

    local function ClearAnimations()
        if animationConnection then
            animationConnection:Disconnect()
            animationConnection = nil
        end

        watchedAnimator = nil

        for track, speed in pairs(animationSaved) do
            pcall(function()
                if track.IsPlaying and track.Speed == 0 then
                    track:AdjustSpeed(speed)
                end
            end)
            animationSaved[track] = nil
        end
    end

    local function UpdateAnimator(humanoid)
        local animator = humanoid
            and humanoid:FindFirstChildOfClass("Animator")

        if animator == watchedAnimator then return end

        ClearAnimations()
        watchedAnimator = animator

        if animator then
            animationConnection = animator.AnimationPlayed:Connect(FreezeTrack)

            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                FreezeTrack(track)
            end
        end
    end

    --------------------------------------------------------------------------
    -- Movement: มี Connection เดียวเฉพาะตอนมีฟังก์ชันที่ต้องอัปเดต
    --------------------------------------------------------------------------
    local function UpdateMotion()
        local needed = state.WalkSpeed or state.Noclip
            or state.Fly or state.DisableAnimations

        if not state.WalkSpeed then Restore(speedSaved) end
        if not state.Noclip then Restore(collisionSaved) end
        if not state.Fly then StopFlight() end
        if not state.DisableAnimations then ClearAnimations() end

        if not needed then
            if motionConnection then
                motionConnection:Disconnect()
                motionConnection = nil
            end
            return
        end

        if motionConnection then return end

        motionConnection = RunService.PreSimulation:Connect(function()
            if not alive then return end

            local character, humanoid, root = GetCharacter()

            if state.DisableAnimations then
                UpdateAnimator(humanoid)
            end

            if not humanoid or humanoid.Health <= 0 then
                StopFlight()
                return
            end

            if state.WalkSpeed then
                Patch(speedSaved, humanoid, "WalkSpeed", state.Speed)
            end

            if state.Noclip and character then
                for _, object in ipairs(character:GetDescendants()) do
                    if object:IsA("BasePart") then
                        Patch(collisionSaved, object, "CanCollide", false)
                    end
                end
            end

            if not state.Fly then return end

            if not root or not root.Parent or root.Anchored then
                StopFlight()
                return
            end

            if not flight or flight.Root ~= root
                or not flight.Velocity.Parent
                or not flight.Orientation.Parent then
                StartFlight(humanoid, root)
            end

            local camera = workspace.CurrentCamera
            local direction = Vector3.zero

            if camera and not UIS:GetFocusedTextBox() then
                local cf = camera.CFrame

                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + cf.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - cf.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + cf.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - cf.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    direction = direction + Vector3.yAxis
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    direction = direction - Vector3.yAxis
                end

                flight.Orientation.CFrame = cf.Rotation
            end

            if direction.Magnitude > 1 then
                direction = direction.Unit
            end

            flight.Velocity.VectorVelocity = direction * state.FlySpeed
        end)
    end

    Connect(LocalPlayer.CharacterRemoving, function()
        StopFlight()
        ClearAnimations()
        Restore(speedSaved)
        Restore(collisionSaved)
    end)

    Connect(UIS.JumpRequest, function()
        if not alive or not state.InfiniteJump
            or state.Fly or UIS:GetFocusedTextBox() then
            return
        end

        local _, humanoid = GetCharacter()
        if humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    --------------------------------------------------------------------------
    -- Instant Prompt: ปรับ HoldDuration ฝั่ง Client ไม่ส่ง Remote
    --------------------------------------------------------------------------
    Connect(PromptService.PromptShown, function(prompt)
        if alive and state.InstantPrompt then
            Patch(promptSaved, prompt, "HoldDuration", 0)
        end
    end)

    local function ApplyPrompts()
        if not state.InstantPrompt then
            Restore(promptSaved)
            return
        end

        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                Patch(promptSaved, object, "HoldDuration", 0)
            end
        end
    end

    --------------------------------------------------------------------------
    -- Performance: FPS = เงา/แสง, Ultra = เพิ่ม Material/Texture
    --------------------------------------------------------------------------
    local function ApplyPerformanceObject(object)
        if not (state.FPSBoost or state.UltraFPSBoost) then return end

        if object:IsA("BasePart") then
            Patch(performanceSaved, object, "CastShadow", false)

            if state.UltraFPSBoost then
                Patch(performanceSaved, object, "Material", Enum.Material.SmoothPlastic)
                Patch(performanceSaved, object, "Reflectance", 0)

                if object:IsA("MeshPart") then
                    Patch(performanceSaved, object, "TextureID", "")
                end
            end
        elseif object:IsA("Light") or object:IsA("PostEffect") then
            Patch(performanceSaved, object, "Enabled", false)
        elseif state.UltraFPSBoost then
            if object:IsA("Decal") or object:IsA("Texture") then
                Patch(performanceSaved, object, "Transparency", 1)
            elseif object:IsA("SpecialMesh") then
                Patch(performanceSaved, object, "TextureId", "")
            end
        end
    end

    local function ApplyPerformance()
        performanceVersion = performanceVersion + 1
        local version = performanceVersion

        Restore(performanceSaved)

        if not (state.FPSBoost or state.UltraFPSBoost) then return end

        Patch(performanceSaved, Lighting, "GlobalShadows", false)

        task.spawn(function()
            for _, parent in ipairs({ workspace, Lighting }) do
                for index, object in ipairs(parent:GetDescendants()) do
                    if not alive or version ~= performanceVersion then return end

                    ApplyPerformanceObject(object)

                    if index % 300 == 0 then
                        task.wait()
                    end
                end
            end
        end)
    end

    Connect(workspace.DescendantAdded, function(object)
        if not alive then return end

        ApplyPerformanceObject(object)

        if state.InstantPrompt and object:IsA("ProximityPrompt") then
            Patch(promptSaved, object, "HoldDuration", 0)
        end
    end)

    Connect(Lighting.DescendantAdded, function(object)
        if alive then ApplyPerformanceObject(object) end
    end)

    --------------------------------------------------------------------------
    -- Reconnect: เฉพาะ Kick code 267, กลับ JobId เดิม สูงสุด 3 ครั้ง
    --------------------------------------------------------------------------
    local originalPlaceId = game.PlaceId
    local originalJobId = game.JobId
    local reconnectAvailable = false
    local TryReconnect

    TryReconnect = function(attempt, token)
        if not alive or not state.Reconnect
            or token ~= reconnectToken then
            return
        end

        if attempt > 3 then
            reconnecting = false
            Report("กลับเซิร์ฟเวอร์เดิมไม่สำเร็จหลังลอง 3 ครั้ง")
            return
        end

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                originalPlaceId,
                originalJobId,
                LocalPlayer
            )
        end)

        if not ok then
            warn("[Zero X / Reconnect] " .. tostring(err))
        end

        task.delay(10, function()
            TryReconnect(attempt + 1, token)
        end)
    end

    local connected = pcall(function()
        -- ตรวจสิทธิ์อ่าน API ก่อนเปิดใช้งาน
        GuiService:GetErrorCode()

        Connect(GuiService.ErrorMessageChanged, function()
            if not alive or not state.Reconnect or reconnecting then return end

            local ok, code = pcall(function()
                return GuiService:GetErrorCode()
            end)

            if not ok or not code or code.Value ~= 267 then return end

            reconnecting = true
            reconnectToken = reconnectToken + 1
            TryReconnect(1, reconnectToken)
        end)
    end)

    reconnectAvailable = connected and originalJobId ~= ""

    Connect(LocalPlayer.OnTeleport, function(teleportState)
        if teleportState == Enum.TeleportState.InProgress then
            reconnectToken = reconnectToken + 1
            reconnecting = false
        end
    end)

    --------------------------------------------------------------------------
    -- Controls
    --------------------------------------------------------------------------
    local Movement = Tabs.Player:AddSection({
        Title = "Movement",
        Icon = "move",
    })

    local Performance = Tabs.Player:AddSection({
        Title = "Performance",
        Icon = "monitor",
    })

    local FlySection = Tabs.Player:AddSection({
        Title = "Fly",
        Icon = "send",
    })

    local Session = Tabs.Player:AddSection({
        Title = "Session",
        Icon = "refresh-cw",
    })

    local function AddStateToggle(section, index, title, key, changed)
        return section:AddToggle(index, {
            Title = title,
            Default = false,
            Callback = function(value)
                if not alive then return end
                state[key] = value
                if changed then changed() end
            end,
        })
    end

    AddStateToggle(Movement, "ZeroXWalkSpeed", "WalkSpeed",
        "WalkSpeed", UpdateMotion)

    Movement:AddSlider("ZeroXSpeed", {
        Title = "Speed",
        Min = 0,
        Max = 200,
        Default = 32,
        Increment = 1,
        Callback = function(value)
            state.Speed = value
        end,
    })

    AddStateToggle(Movement, "ZeroXInfiniteJump", "Infinite Jump",
        "InfiniteJump")

    AddStateToggle(Movement, "ZeroXNoclip", "Noclip",
        "Noclip", UpdateMotion)

    AddStateToggle(Movement, "ZeroXInstantPrompt", "Instant ProximityPrompt",
        "InstantPrompt", ApplyPrompts)

    Performance:AddToggle("ZeroXDisable3D", {
        Title = "Disable 3D Rendering",
        Default = false,
        Callback = function(value)
            if not alive then return end

            local ok, err = pcall(function()
                RunService:Set3dRenderingEnabled(not value)
            end)

            if ok then
                renderDisabled = value
            elseif value then
                Report("สภาพแวดล้อมนี้ปิด 3D Rendering ไม่ได้: " .. tostring(err))

                task.defer(function()
                    if alive and Options.ZeroXDisable3D then
                        Options.ZeroXDisable3D:SetValue(false)
                    end
                end)
            end
        end,
    })

    AddStateToggle(Performance, "ZeroXFPSBoost", "FPS Boost",
        "FPSBoost", ApplyPerformance)

    AddStateToggle(Performance, "ZeroXUltraFPSBoost", "Ultra FPS Boost",
        "UltraFPSBoost", ApplyPerformance)

    AddStateToggle(Performance, "ZeroXDisableAnimations",
        "Disable Player Animations", "DisableAnimations", UpdateMotion)

    AddStateToggle(FlySection, "ZeroXFly", "Fly",
        "Fly", UpdateMotion)

    FlySection:AddSlider("ZeroXFlySpeed", {
        Title = "Fly Speed",
        Min = 1,
        Max = 200,
        Default = 60,
        Increment = 1,
        Callback = function(value)
            state.FlySpeed = value
        end,
    })

    FlySection:AddParagraph({
        Title = "Fly controls",
        Content = "WASD: เคลื่อนที่ตามกล้อง\nSpace: ขึ้น\nLeft Ctrl: ลง",
    })

    Session:AddToggle("ZeroXReconnect", {
        Title = "Auto Reconnect on Kick",
        Default = false,
        Callback = function(value)
            if not alive then return end

            if value and not reconnectAvailable then
                Report("สภาพแวดล้อมนี้ไม่รองรับตรวจ Kick หรือไม่มี JobId")

                task.defer(function()
                    if alive and Options.ZeroXReconnect then
                        Options.ZeroXReconnect:SetValue(false)
                    end
                end)
                return
            end

            state.Reconnect = value

            if not value then
                reconnectToken = reconnectToken + 1
                reconnecting = false
            end
        end,
    })

    Session:AddToggle("ZeroXHideOnStart", {
        Title = "Hide UI On Start",
        Description = "มีผลครั้งถัดไปหลังบันทึกและตั้ง Autoload ใน Profiles",
        Default = false,
    })

    --------------------------------------------------------------------------
    -- Cleanup
    --------------------------------------------------------------------------
    MacUI:OnUnload(function()
        alive = false
        performanceVersion = performanceVersion + 1
        reconnectToken = reconnectToken + 1

        if motionConnection then
            motionConnection:Disconnect()
            motionConnection = nil
        end

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)

        StopFlight()
        ClearAnimations()
        Restore(speedSaved)
        Restore(collisionSaved)
        Restore(promptSaved)
        Restore(performanceSaved)

        if renderDisabled then
            pcall(function()
                RunService:Set3dRenderingEnabled(true)
            end)
        end
    end)
end

-- Keep the original settings folders and custom theme loading.
ThemeManager:SetLibrary(MacUI)
ThemeManager:SetFolder("ZeroX")
ThemeManager:LoadCustomThemes()

InterfaceManager:SetLibrary(MacUI)
InterfaceManager:SetFolder("ZeroX")
InterfaceManager:BuildInterfaceSection(Tabs.Appearance)

-- Profiles: saved separately for each PlaceId, as in the supplied file.
SaveManager:SetLibrary(MacUI)
SaveManager:SetFolder("ZeroX/" .. tostring(game.PlaceId))
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Profiles)

-- Keep this call after all controls are created.
SaveManager:LoadAutoloadConfig()

if Options.ZeroXHideOnStart and Options.ZeroXHideOnStart.Value then
    Window:Minimize()
end