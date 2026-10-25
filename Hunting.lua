local print = function() end
local warn = function() end


if not game:IsLoaded() then
    repeat
        game.Loaded:Wait()
    until game:IsLoaded()
end

local GuiService = game:GetService("GuiService")

local ok, err = pcall(function()
    GuiService:SetGameplayPausedNotificationEnabled(false)
end)

if not ok then
    warn("[Zero X / Streaming] Cannot hide pause notification: "
        .. tostring(err))
end

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
	Profile = {
		Title = "Zero X Script",
		Subtitle = "Zero X Script",
	},
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

do
    local CUSTOM_NAME = "Zero X Script"
    local active = true

    local watchedCharacter
    local watchedLabel
    local originalText
    local textConnection
    local treeConnections = {}
    local refreshQueued = false

    local function UnbindLabel()
        if textConnection then
            textConnection:Disconnect()
            textConnection = nil
        end

        if watchedLabel and watchedLabel.Parent
            and watchedLabel.Text == CUSTOM_NAME
            and originalText ~= nil then
            watchedLabel.Text = originalText
        end

        watchedLabel = nil
        originalText = nil
    end

    local function ResolveLabel()
        local character = watchedCharacter

        if not character
            or LocalPlayer.Character ~= character then
            return nil
        end

        local head = character:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then
            return nil
        end

        local gui = head:FindFirstChild("LumiNameTag")
        if not gui or not gui:IsA("BillboardGui") then
            return nil
        end

        local nameTag = gui:FindFirstChild("NameTag")
        if not nameTag or not nameTag:IsA("Frame") then
            return nil
        end

        local plate = nameTag:FindFirstChild("Plate")
        if not plate or not plate:IsA("Frame") then
            return nil
        end

        local label = plate:FindFirstChild("Name")

        if label and label:IsA("TextLabel") then
            return label
        end

        return nil
    end

    local function Refresh()
        if not active then return end

        local label = ResolveLabel()
        if label == watchedLabel then return end

        UnbindLabel()
        if not label then return end

        watchedLabel = label
        originalText = label.Text

        textConnection =
            label:GetPropertyChangedSignal("Text"):Connect(function()
                if not active or watchedLabel ~= label then
                    return
                end

                -- เกมอัปเดตชื่อใหม่เมื่อ Level / Job / Title เปลี่ยน
                if label.Text ~= CUSTOM_NAME then
                    originalText = label.Text
                    label.Text = CUSTOM_NAME
                end
            end)

        label.Text = CUSTOM_NAME
    end

    local function QueueRefresh()
        if not active or refreshQueued then return end
        refreshQueued = true

        task.defer(function()
            refreshQueued = false

            if active then
                Refresh()
            end
        end)
    end

    local function ClearCharacter()
        for _, connection in ipairs(treeConnections) do
            connection:Disconnect()
        end

        table.clear(treeConnections)
        watchedCharacter = nil
        UnbindLabel()
    end

    local function BindCharacter(character)
        ClearCharacter()
        if not active then return end

        watchedCharacter = character

        -- ตรวจเส้นทางสั้น ๆ เมื่อมีการสร้าง/ลบป้าย
        -- ไม่สแกน GetDescendants และไม่ใช้ Loop
        table.insert(treeConnections,
            character.DescendantAdded:Connect(QueueRefresh)
        )

        table.insert(treeConnections,
            character.DescendantRemoving:Connect(QueueRefresh)
        )

        Refresh()
    end

    local addedConnection =
        LocalPlayer.CharacterAdded:Connect(BindCharacter)

    local removingConnection =
        LocalPlayer.CharacterRemoving:Connect(function(character)
            if watchedCharacter == character then
                ClearCharacter()
            end
        end)

    if LocalPlayer.Character then
        BindCharacter(LocalPlayer.Character)
    end

    MacUI:OnUnload(function()
        active = false
        addedConnection:Disconnect()
        removingConnection:Disconnect()
        ClearCharacter()
    end)
end

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
    Event = Window:AddTab({
        Title = "Event",
        Icon = "gift",
        Section = "Event",
    }),
    Reward = Window:AddTab({
        Title = "Reward",
        Icon = "gift",
    }),
    Party = Window:AddTab({
        Title = "Party",
        Icon = "users",
        Section = "Party",
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

do
    local HttpService = game:GetService("HttpService")
    local RS = game:GetService("ReplicatedStorage")

    local active = true
    local connections = {}
    local playerConnections = {}

    local partyCache = {}
    local knownPlayers = {}
    local labelToId = {}

    local selectedPlayer
    local selectedMember
    local selectedInviter
    local whitelist = {}

    local autoInvite = false
    local autoAccept = false
    local autoInviteAll = false
    local autoAcceptAll = false
    local retrySeconds = 60

    local invitations = {}
    local lastInvite = {}
    local lastSend = -math.huge
    local inviteCursor = 0
    local promotion

    local playerDropdown
    local memberDropdown
    local inviteDropdown
    local whitelistDropdown

    local management = Tabs.Party:AddSection({
        Title = "Party Management",
        Icon = "users",
    })

    local inviteSection = Tabs.Party:AddSection({
        Title = "Invitations",
        Icon = "user-plus",
    })

    local memberSection = Tabs.Party:AddSection({
        Title = "Members",
        Icon = "users",
    })

    local automation = Tabs.Party:AddSection({
        Title = "Party Automation",
        Icon = "settings",
    })

    local status = management:AddLabel({
        Title = "Party Status",
        Value = "กำลังตรวจสอบข้อมูล",
    })

    local roster = management:AddLabel({
        Title = "Party Members",
        Value = "-",
    })

    local function Report(message)
        if active then
            status:SetValue(message)
        end
    end

    local function Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function FiniteNumber(value)
        return type(value) == "number"
            and value == value
            and math.abs(value) < math.huge
    end

    -- false = ไม่มีปาร์ตี้
    -- nil = ข้อมูลไม่ถูกต้อง จึงไม่ส่งคำสั่งอัตโนมัติ
    local function ReadParty(player)
        local raw = player:GetAttribute("PartyJson")

        if raw == nil or raw == "" then
            return false
        end

        if type(raw) ~= "string" then
            return nil
        end

        local ok, data = pcall(
            HttpService.JSONDecode, HttpService, raw
        )

        if not ok or type(data) ~= "table"
            or not FiniteNumber(data.Leader)
            or type(data.Members) ~= "table" then
            return nil
        end

        local count = 0
        local seen = {}

        for key, member in pairs(data.Members) do
            if type(key) ~= "number"
                or key < 1 or key % 1 ~= 0
                or type(member) ~= "table"
                or not FiniteNumber(member.UserId)
                or member.UserId <= 0
                or member.UserId % 1 ~= 0
                or seen[member.UserId] then
                return nil
            end

            count += 1
            seen[member.UserId] = true
        end

        if count ~= #data.Members then
            return nil
        end

        return data
    end

    local maxMembers = 6 -- ค่าที่ตรวจพบจาก GameConfig

    local shared = RS:FindFirstChild("Shared")
    local configModule = shared
        and shared:FindFirstChild("GameConfig")

    if configModule and configModule:IsA("ModuleScript") then
        local ok, config = pcall(require, configModule)

        if ok and type(config) == "table"
            and FiniteNumber(config.PartyMaxMembers)
            and config.PartyMaxMembers >= 1 then
            maxMembers = math.floor(config.PartyMaxMembers)
        end
    end

    local function LocalParty()
        return partyCache[LocalPlayer.UserId]
    end

    local function IsMember(party, userId)
        if type(party) ~= "table" then return false end

        for _, member in ipairs(party.Members) do
            if member.UserId == userId then
                return true
            end
        end

        return false
    end

    local function IsLeader()
        local party = LocalParty()

        return type(party) == "table"
            and party.Leader == LocalPlayer.UserId
    end

    local function Send(action, ...)
        if not active then return false end

        -- ระยะห่างที่สคริปต์กำหนดเอง ไม่ใช่ค่าจำกัดของเซิร์ฟเวอร์
        if os.clock() - lastSend < 1 then
            return false
        end

        local remotes = RS:FindFirstChild("Remotes")
        local remote = remotes
            and remotes:FindFirstChild("PartyAction")

        if not remote or not remote:IsA("RemoteEvent") then
            Report("ไม่พบ PartyAction ที่เป็น RemoteEvent")
            return false
        end

        lastSend = os.clock()
        remote:FireServer(action, ...)

        Report("ส่งคำขอ " .. action .. " แล้ว")
        return true
    end

    local function PlayerLabel(player)
        return string.format(
            "%s [%d]", player.Name, player.UserId
        )
    end

    local function Refresh()
        if not active then return end

        local party = LocalParty()
        local memberValues = {}
        local names = {}

        if type(party) == "table" then
            for _, member in ipairs(party.Members) do
                local name = type(member.Name) == "string"
                    and member.Name or tostring(member.UserId)

                table.insert(names, name)

                if member.UserId ~= LocalPlayer.UserId then
                    local label = string.format(
                        "%s [%d]", name, member.UserId
                    )

                    labelToId[label] = member.UserId
                    table.insert(memberValues, label)
                end
            end

            Report(string.format(
                "%d/%d คน | %s",
                #party.Members,
                maxMembers,
                party.Leader == LocalPlayer.UserId
                    and "หัวหน้าปาร์ตี้" or "สมาชิก"
            ))
        elseif party == false then
            Report("ยังไม่มีปาร์ตี้")
        else
            Report("อ่าน PartyJson ไม่ได้")
        end

        roster:SetValue(
            #names > 0 and table.concat(names, ", ") or "-"
        )

        local onlineValues = {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local label = PlayerLabel(player)

                knownPlayers[player.UserId] = label
                labelToId[label] = player.UserId

                table.insert(onlineValues, label)
            end
        end

        table.sort(onlineValues)
        table.sort(memberValues)

        -- เก็บรายชื่อที่เคยพบไว้ เพื่อไม่ล้าง Whitelist
        -- ทันทีที่ผู้เล่นออกจากเซิร์ฟเวอร์
        local whitelistValues = {}

        for _, label in pairs(knownPlayers) do
            table.insert(whitelistValues, label)
        end

        table.sort(whitelistValues)

        local inviteValues = {}
        local now = os.clock()

        for userId, invitation in pairs(invitations) do
            if invitation.Expires <= now then
                invitations[userId] = nil
            else
                labelToId[invitation.Label] = userId
                table.insert(inviteValues, invitation.Label)
            end
        end

        table.sort(inviteValues)

        if playerDropdown then
            playerDropdown:SetValues(onlineValues)
        end

        if memberDropdown then
            memberDropdown:SetValues(memberValues)
        end

        if whitelistDropdown then
            whitelistDropdown:SetValues(whitelistValues)
        end

        if inviteDropdown then
            inviteDropdown:SetValues(inviteValues)
        end
    end

    local function CanInvite(userId)
        local party = LocalParty()

        if not IsLeader() then return false end
        if #party.Members >= maxMembers then return false end
        if userId == LocalPlayer.UserId then return false end
        if IsMember(party, userId) then return false end

        local player = Players:GetPlayerByUserId(userId)

        return player ~= nil and partyCache[userId] == false
    end

    local function Invite(userId)
        if not userId or not CanInvite(userId) then
            return false
        end

        if Send("invite", userId) then
            lastInvite[userId] = os.clock()
            return true
        end

        return false
    end

    local function RespondInvite(userId, accept)
        local invitation = userId and invitations[userId]

        if not invitation
            or invitation.Expires <= os.clock() then
            Report("คำเชิญหมดอายุหรือยังไม่ได้รับคำเชิญ")
            return false
        end

        if accept and LocalParty() ~= false then
            Report("ต้องไม่มีปาร์ตี้ก่อนรับคำเชิญ")
            return false
        end

        if Send(accept and "accept" or "decline", userId) then
            invitations[userId] = nil
            Refresh()
            return true
        end

        return false
    end

    management:AddButton({
        Title = "Create Party",
        Description = "สร้างปาร์ตี้เมื่อยังไม่ได้อยู่ในปาร์ตี้",
        Callback = function()
            if LocalParty() == false then
                Send("create")
            else
                Report("มีปาร์ตี้อยู่แล้ว หรือข้อมูลยังไม่พร้อม")
            end
        end,
    })

    management:AddButton({
        Title = "Leave Party",
        Description = "ออกจากปาร์ตี้ปัจจุบัน "
            .. "หัวหน้าปาร์ตี้อาจถูกโอนโดยระบบเกม",
        Callback = function()
            if type(LocalParty()) == "table" then
                Send("leave")
            end
        end,
    })

    management:AddDropdown("ZeroXPartyLootMode", {
        Title = "Loot Mode",
        Description = "เลือก share เพื่อแบ่งของ หรือ owner "
            .. "ตามสิทธิ์เจ้าของ แล้วกด Apply Loot Mode",
        Values = { "share", "owner" },
        Default = "owner",
    })

    management:AddButton({
        Title = "Apply Loot Mode",
        Description = "ใช้โหมดแบ่งของที่เลือก เฉพาะหัวหน้าปาร์ตี้",
        Callback = function()
            if not IsLeader() then
                Report("เปลี่ยนโหมดได้เฉพาะหัวหน้าปาร์ตี้")
                return
            end

            local option = Options.ZeroXPartyLootMode
            local value = option and option.Value

            if value == "share" or value == "owner" then
                Send("lootmode", value)
            end
        end,
    })

    playerDropdown = inviteSection:AddDropdown(
        "ZeroXPartyPlayer", {
            Title = "Select Player",
            Description = "เลือกผู้เล่นในเซิร์ฟเวอร์เพื่อเชิญ",
            Values = {},
            AllowNull = true,
            Searchable = true,
            Callback = function(value)
                selectedPlayer = labelToId[value]
            end,
        }
    )

    inviteSection:AddButton({
        Title = "Invite Player",
        Description = "เชิญคนที่เลือก ต้องเป็นหัวหน้า "
            .. "และปาร์ตี้ยังไม่เต็ม",
        Callback = function()
            if not Invite(selectedPlayer) then
                Report("เชิญไม่ได้: ตรวจผู้เล่น หัวหน้าปาร์ตี้ "
                    .. "จำนวนสมาชิก หรือรอส่งคำสั่งรอบถัดไป")
            end
        end,
    })

    memberDropdown = memberSection:AddDropdown(
        "ZeroXPartyMember", {
            Title = "Select Member",
            Description = "เลือกสมาชิกเพื่อจัดการสิทธิ์",
            Values = {},
            AllowNull = true,
            Searchable = true,
            Callback = function(value)
                selectedMember = labelToId[value]
                promotion = nil
            end,
        }
    )

    local function CanManageMember()
        return selectedMember ~= nil
            and selectedMember ~= LocalPlayer.UserId
            and IsLeader()
            and IsMember(LocalParty(), selectedMember)
    end

    memberSection:AddButton({
        Title = "Kick Member",
        Description = "นำสมาชิกที่เลือกออกจากปาร์ตี้ "
            .. "ใช้ได้เฉพาะหัวหน้า",
        Callback = function()
            if CanManageMember() then
                Send("kick", selectedMember)
            else
                Report("ต้องเป็นหัวหน้าและเลือกสมาชิกปัจจุบัน")
            end
        end,
    })

    memberSection:AddButton({
        Title = "Transfer Leader",
        Description = "กดครั้งแรกเพื่อเตรียมโอน "
            .. "แล้วกดซ้ำภายใน 4 วินาทีเพื่อยืนยัน",
        Callback = function()
            if not CanManageMember() then
                promotion = nil
                Report("ต้องเป็นหัวหน้าและเลือกสมาชิกปัจจุบัน")
                return
            end

            local now = os.clock()

            if promotion
                and promotion.UserId == selectedMember
                and now <= promotion.Expires then

                if Send("leader", selectedMember) then
                    promotion = nil
                end
                return
            end

            promotion = {
                UserId = selectedMember,
                Expires = now + 4,
            }

            Report("กด Transfer Leader ซ้ำภายใน 4 วินาที")
        end,
    })

    whitelistDropdown = automation:AddDropdown(
        "ZeroXPartyWhitelist", {
            Title = "Selected Players",
            Description = "รายชื่อสำหรับ Auto Invite และ Auto Accept "
                .. "เลือกได้หลายคน",
            Values = {},
            Multi = true,
            Searchable = true,
            Callback = function(values)
                whitelist = {}

                if type(values) ~= "table" then return end

                for label, selected in pairs(values) do
                    local userId = labelToId[label]

                    if selected == true and userId then
                        whitelist[userId] = true
                    end
                end
            end,
        }
    )

    automation:AddToggle("ZeroXPartyAutoInvite", {
        Title = "Auto Invite",
        Description = "เชิญเฉพาะคนที่เลือก ข้ามคนที่มีปาร์ตี้แล้ว "
            .. "และหยุดเมื่อเต็ม ต้องสร้างปาร์ตี้ก่อน",
        Default = false,
        Callback = function(value)
            autoInvite = value == true
        end,
    })

    automation:AddDropdown("ZeroXPartyInviteRetry", {
        Title = "Invite Retry",
        Description = "ระยะเวลาส่งคำเชิญซ้ำต่อคน หน่วยวินาที "
            .. "เป็นค่าที่สคริปต์กำหนดเอง",
        Values = { "60", "120", "180", "300" },
        Default = "60",
        Callback = function(value)
            retrySeconds = tonumber(value) or 60
        end,
    })

    automation:AddToggle("ZeroXPartyAutoAccept", {
        Title = "Auto Accept",
        Description = "รับเฉพาะคำเชิญจากคนที่เลือก "
            .. "คำเชิญจากคนอื่นยังให้ตัดสินใจเอง",
        Default = false,
        Callback = function(value)
            autoAccept = value == true
        end,
    })

    automation:AddToggle("ZeroXPartyAutoInviteAll", {
        Title = "Auto Invite All",
        Description = "เชิญใครก็ได้ในเซิร์ฟเวอร์ที่ยังไม่มีปาร์ตี้ "
            .. "ต้องเป็นหัวหน้า หยุดเมื่อเต็ม "
            .. "และใช้ระยะส่งซ้ำตาม Invite Retry",
        Default = false,
        Callback = function(value)
            autoInviteAll = value == true
        end,
    })

    automation:AddToggle("ZeroXPartyAutoAcceptAll", {
        Title = "Auto Accept All",
        Description = "รับคำเชิญจากใครก็ได้ "
            .. "ทำงานเมื่อเรายังไม่มีปาร์ตี้และคำเชิญยังไม่หมดอายุ",
        Default = false,
        Callback = function(value)
            autoAcceptAll = value == true
        end,
    })

    local function WatchPlayer(player)
        local userId = player.UserId

        if playerConnections[userId] then return end

        partyCache[userId] = ReadParty(player)

        if player ~= LocalPlayer then
            local label = PlayerLabel(player)
            knownPlayers[userId] = label
            labelToId[label] = userId
        end

        playerConnections[userId] =
            player:GetAttributeChangedSignal("PartyJson"):Connect(
                function()
                    if not active then return end

                    partyCache[userId] = ReadParty(player)

                    if player == LocalPlayer then
                        promotion = nil

                        if type(LocalParty()) == "table" then
                            table.clear(invitations)
                        end
                    end

                    Refresh()
                end
            )
    end

    Connect(Players.PlayerAdded, function(player)
        WatchPlayer(player)
        Refresh()
    end)

    Connect(Players.PlayerRemoving, function(player)
        local userId = player.UserId
        local connection = playerConnections[userId]

        if connection then connection:Disconnect() end

        playerConnections[userId] = nil
        partyCache[userId] = nil
        invitations[userId] = nil
        lastInvite[userId] = nil

        -- PlayerRemoving อาจเกิดก่อน GetPlayers ลบผู้เล่น
        task.defer(function()
            if active then Refresh() end
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        WatchPlayer(player)
    end

    local watchedInviteRemote
    local inviteConnection

    local function BindInviteRemote()
        local remotes = RS:FindFirstChild("Remotes")
        local remote = remotes
            and remotes:FindFirstChild("PartyInvite")

        if remote and not remote:IsA("RemoteEvent") then
            remote = nil
        end

        if remote == watchedInviteRemote then return end

        if inviteConnection then
            inviteConnection:Disconnect()
            inviteConnection = nil
        end

        watchedInviteRemote = remote

        if remote then
            inviteConnection = remote.OnClientEvent:Connect(
                function(userId, senderName, expirySeconds)
                    if not active
                        or not FiniteNumber(userId)
                        or userId <= 0 or userId % 1 ~= 0
                        or type(senderName) ~= "string" then
                        return
                    end

                    if expirySeconds == nil then
                        expirySeconds = 60
                    end

                    if not FiniteNumber(expirySeconds)
                        or expirySeconds <= 0 then
                        return
                    end

                    local label = string.format(
                        "%s [%d]", senderName, userId
                    )

                    invitations[userId] = {
                        Label = label,
                        Expires = os.clock() + expirySeconds,
                    }

                    Refresh()
                end
            )
        end
    end

    Refresh()
    BindInviteRemote()

    MacUI:OnUnload(function()
        active = false

        if inviteConnection then
            inviteConnection:Disconnect()
        end

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        for _, connection in pairs(playerConnections) do
            connection:Disconnect()
        end

        table.clear(connections)
        table.clear(playerConnections)
        table.clear(invitations)
    end)

    task.spawn(function()
        while active do
            task.wait(1)
            if not active then break end

            BindInviteRemote()

            local now = os.clock()
            local changed = false

            for userId, invitation in pairs(invitations) do
                if invitation.Expires <= now then
                    invitations[userId] = nil
                    changed = true
                end
            end

            if changed then Refresh() end

            local accepted = false

            if (autoAccept or autoAcceptAll)
                and LocalParty() == false then

                for userId in pairs(invitations) do
                    if autoAcceptAll or whitelist[userId] then
                        accepted = RespondInvite(userId, true)
                        if accepted then break end
                    end
                end
            end

            if not accepted
                and (autoInvite or autoInviteAll)
                and IsLeader() then

                local candidates = {}

                if autoInviteAll then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if CanInvite(player.UserId) then
                            table.insert(candidates, player.UserId)
                        end
                    end
                else
                    for userId in pairs(whitelist) do
                        if CanInvite(userId) then
                            table.insert(candidates, userId)
                        end
                    end
                end

                table.sort(candidates)

                for offset = 1, #candidates do
                    local index =
                        ((inviteCursor + offset - 1)
                            % #candidates) + 1

                    local userId = candidates[index]

                    if now - (lastInvite[userId] or -math.huge)
                        >= retrySeconds then
                        if Invite(userId) then
                            inviteCursor = index
                            break
                        end
                    end
                end
            end
        end
    end)
end


--------------------------------------------------------------------------------
-- ADD YOUR FEATURES HERE
-- Use Tabs.Home:AddSection(...) or Window:AddTab(...) to add your own controls.
-- Register controls with unique indexes so SaveManager can save their values.
-- Add controls before LoadAutoloadConfig at the bottom of this file.
-- Connect callbacks only after the real game functions are available.
--------------------------------------------------------------------------------

local farmWalkSpeedActive = false
local refreshFarmWalkSpeed

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
        local farmRequested = false
        local pumpkinEnabled = false
        local partyFarmEnabled = false
        local partyFarmRadius = 60
        local partyFarmData
        local partyFarmLeaderRoot
        local partySearch
        local partySearching = false

        -- ค่ารอที่สคริปต์กำหนดเอง
        local PARTY_SEARCH_WAIT = 4
        local PARTY_SEARCH_RETRY = 30
        local potionTripActive = false
        local farmTravelActive = false
        local dropTripActive = false
        local chestTripActive = false
        local bossDodgeActive = false
        local ResetBossDodge
        local sellTripActive = false
        local farmPullActive = false
        local pullSession

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
        local FARM_HOVER_HEIGHT = 30
        local farmMovement = "Walk"
        local nativeFarmIds
        local nativeFarmAttackLeader = false
        local farmWalkActive = false

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

        local lastWalkMessage

        local walkInfo = {
            SetValue = function(_, message)
                message = tostring(message)

                if message == lastWalkMessage then
                    return
                end

                lastWalkMessage = message
                print("[Zero X / Farm / Native] " .. message)
            end,
        }

        local nativeWalkOwned = false
        local lastNativeWalkRequest = -math.huge

        local walkUnlockModule = shared:FindFirstChild("UnlockData")
        local walkUnlockData
        local lastWalkUnlockRead = -math.huge

        if walkUnlockModule
            and walkUnlockModule:IsA("ModuleScript") then
            walkUnlockData = LoadModule(walkUnlockModule)
        end

        -- เก็บชื่อไว้รองรับคำสั่ง cleanup เดิม
        -- ไม่มี Pathfinding หรือ RenderStep เดินแล้ว
        local function StopFarmWalk()
            farmWalkActive = false
        end

        local function ReleaseNativeWalk()
            if not nativeWalkOwned then return end
            nativeWalkOwned = false


            local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")

            if menu and menu:IsA("BindableEvent")
                and LocalPlayer:GetAttribute("AutoOn") == true then
                menu:Fire("autoToggle")
            end
        end

        local lastRoamRequest = -math.huge

        local function EnsureNativeRoam()
            if not alive or not enabled
                or farmMovement ~= "Walk" then
                return false
            end

            -- อ่านค่าล่าสุดเสมอ เพราะ SetBotSettings แทนที่ทั้งชุด
            local raw = LocalPlayer:GetAttribute("BotJson")
            if type(raw) ~= "string" or raw == "" then
                walkInfo:SetValue("Waiting for BotJson")
                return false
            end

            local ok, settings = pcall(function()
                return HttpService:JSONDecode(raw)
            end)

            if not ok then
                walkInfo:SetValue(
                    "BotJson decode failed: " .. tostring(settings)
                )
                return false
            end

            if type(settings) ~= "table" then
                walkInfo:SetValue(
                    "BotJson must decode to table; got "
                        .. type(settings)
                )
                return false
            end

            -- ป้องกันส่งค่าบางส่วนทับการตั้งค่าทั้งชุด
            if next(settings) == nil then
                walkInfo:SetValue("BotJson is empty; waiting for game settings")
                return false
            end

            -- Native default: ไม่ระบุ FixedArea = Roam and fight
            -- แก้เฉพาะตารางที่ Decode แล้ว เก็บฟิลด์อื่นทั้งหมดไว้
            if settings.FixedArea == nil then
                settings.FixedArea = false
            elseif type(settings.FixedArea) ~= "boolean" then
                walkInfo:SetValue(
                    "Invalid FixedArea type: "
                        .. type(settings.FixedArea)
                )
                return false
            end

            local lootOption = Options.ZeroXAutoCollectDrop
            local boxOption = Options.ZeroXAutoOpenChest

            -- ให้ตัวเก็บของของสคริปต์รับผิดชอบการเดิน
            local wantLoot = false
            -- ตัวเปิดกล่องของสคริปต์เป็นผู้เดินและกด E เอง
            local wantBoxes = false

            if type(nativeFarmIds) ~= "table"
                or next(nativeFarmIds) == nil then
                walkInfo:SetValue("Waiting for farm monster plan")
                return false
            end

            local onlyMatches = type(settings.Only) == "table"
            local exclusionsClear = type(settings.Exclude) == "table"

            if onlyMatches then
                for id, selected in pairs(nativeFarmIds) do
                    if settings.Only[id] ~= selected then
                        onlyMatches = false
                        break
                    end
                end
            end

            if onlyMatches then
                for id, selected in pairs(settings.Only) do
                    if selected == true
                        and nativeFarmIds[id] ~= true then
                        onlyMatches = false
                        break
                    end
                end
            end

            if exclusionsClear then
                for id in pairs(nativeFarmIds) do
                    if settings.Exclude[id] ~= nil then
                        exclusionsClear = false
                        break
                    end
                end
            end

            if settings.FixedArea == false
                and settings.Loot == wantLoot
                and settings.OpenBoxes == wantBoxes
                and settings.Mode == "fight"
                and settings.NormalAttack == true
                and settings.AttackLeader == nativeFarmAttackLeader
                and onlyMatches
                and exclusionsClear then
                return true
            end

            local setBotSettings =
                remotes:FindFirstChild("SetBotSettings")

            if not setBotSettings
                or not setBotSettings:IsA("RemoteEvent") then
                walkInfo:SetValue("SetBotSettings unavailable")
                return false
            end

            local now = os.clock()
            if now - lastRoamRequest >= 1 then
                lastRoamRequest = now

                settings.FixedArea = false
                settings.Loot = wantLoot
                settings.OpenBoxes = wantBoxes

                settings.Mode = "fight"
                settings.NormalAttack = true
                settings.AttackLeader = nativeFarmAttackLeader

                settings.Only = table.clone(nativeFarmIds)

                -- เก็บข้อยกเว้นมอนอื่นไว้
                -- เอาออกเฉพาะมอนที่แผนฟาร์มต้องโจมตี
                local exclude = type(settings.Exclude) == "table"
                    and table.clone(settings.Exclude)
                    or {}

                for id in pairs(nativeFarmIds) do
                    exclude[id] = nil
                end

                settings.Exclude = exclude

                setBotSettings:FireServer(settings)
            end

            walkInfo:SetValue("Waiting for Roam and fight")
            return false
        end

        Connect(
            LocalPlayer:GetAttributeChangedSignal("BotJson"),
            function()
                -- หากปรับเป็น Hold position ให้ตรวจและเปลี่ยนกลับ
                task.defer(EnsureNativeRoam)
            end
        )

        local function StepNativeFarmWalk(zone, model, tracker, root)
            StopFarmWalk()
            StopFarmHover()

            -- ล้างเฉพาะตัวล็อกของสคริปต์ที่ตกค้าง
            for _, spec in ipairs({
                { "ZeroXFarmHoverPosition", "AlignPosition" },
                { "ZeroXFarmHoverOrientation", "AlignOrientation" },
                { "ZeroXFarmHoverAttachment", "Attachment" },
            }) do
                local object = root:FindFirstChild(spec[1])

                if object and object:IsA(spec[2]) then
                    object:Destroy()
                end
            end

            if not EnsureNativeRoam() then
                return
            end

            if LocalPlayer:GetAttribute("AutoOn") ~= true then
                -- รองรับ UnlockData ที่มาหลังเริ่มสคริปต์
                if (
                    not walkUnlockData
                    or type(walkUnlockData.HasLevel) ~= "function"
                ) and os.clock() - lastWalkUnlockRead >= 3 then

                    lastWalkUnlockRead = os.clock()

                    local module = shared
                        and shared:FindFirstChild("UnlockData")

                    if module and module:IsA("ModuleScript") then
                        walkUnlockModule = module
                        walkUnlockData = LoadModule(module)
                    end

                    -- require อาจรอระหว่างที่ผู้ใช้ปิดฟาร์ม
                    if not alive or not enabled then
                        return
                    end
                end

                if not walkUnlockData
                    or type(walkUnlockData.HasLevel) ~= "function" then
                    walkInfo:SetValue("Waiting for native unlock data")
                    return
                end

                if not walkUnlockData.HasLevel(
                    LocalPlayer:GetAttribute("UnlockLevel"),
                    "bot"
                ) then
                    walkInfo:SetValue("Native Auto is not unlocked")
                    return
                end

                local menu =
                    LocalPlayer:FindFirstChild("LumiMenuToggle")

                if not menu or not menu:IsA("BindableEvent") then
                    walkInfo:SetValue("Native Auto control unavailable")
                    return
                end

                if os.clock() - lastNativeWalkRequest >= 1 then
                    lastNativeWalkRequest = os.clock()
                    nativeWalkOwned = true
                    menu:Fire("autoToggle")
                end

                walkInfo:SetValue("Waiting for native Auto")
                return
            end

            walkInfo:SetValue("Native Auto")
            SetStatus(
                "Native Walk: " .. zone.Id .. " | "
                    .. (model and model.Name or "Waiting for native target")
            )
        end

        MacUI:OnUnload(ReleaseNativeWalk)

        local function HoldFarmPosition(humanoid, root, position, facing)
            -- Walk ปกติห้ามสร้างตัวล็อกตำแหน่ง
            -- ทริปซื้อขาย/เก็บของ และ Auto Dodge ยังใช้ระบบเดิม
            if farmMovement == "Walk"
                and not potionTripActive
                and not sellTripActive
                and not dropTripActive
                and not chestTripActive
                and not bossDodgeActive then

                StopFarmHover()
                return
            end

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
            StopFarmWalk()

            if ResetBossDodge then
                ResetBossDodge(true)
            end

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

        -- จับคู่บอสกิจกรรมกับโซนจากฐานมอนที่ถูกแทนที่
        local pumpkinZones = {}

        for id, def in pairs(monsterData) do
            if type(id) == "string"
                and type(def) == "table"
                and def.HalloweenPumpkin == true
                and type(def.PumpkinFrom) == "string" then

                for _, zone in ipairs(zones) do
                    if zone.Data.BossRoom ~= true
                        and zone.Ids[def.PumpkinFrom] then
                        pumpkinZones[id] = zone
                        break
                    end
                end
            end
        end

        local cachedActionZone
        local lastActionZoneScan = -math.huge

        local function InsideActionZone(zone, position)
            if not zone or not zone:IsA("BasePart")
                or not zone.Parent then
                return false
            end

            local point = zone.CFrame:PointToObjectSpace(position)

            -- ใช้ขอบโซนจริง ไม่เพิ่มระยะเผื่อข้ามโซน
            return math.abs(point.X) <= zone.Size.X / 2
                and math.abs(point.Z) <= zone.Size.Z / 2
        end

        local function GetActionZone()
            local character = LocalPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = humanoid and humanoid.RootPart
            local zoneFolder = workspace:FindFirstChild("Zones")

            if not humanoid or humanoid.Health <= 0
                or not root or not root:IsA("BasePart")
                or not root.Parent or not zoneFolder then
                cachedActionZone = nil
                return nil
            end

            -- อยู่โซนเดิม ไม่ต้องสแกนรายการซ้ำ
            if cachedActionZone
                and cachedActionZone.Parent == zoneFolder
                and InsideActionZone(cachedActionZone, root.Position) then
                return cachedActionZone
            end

            cachedActionZone = nil

            local now = os.clock()
            if now - lastActionZoneScan < 0.2 then
                return nil
            end
            lastActionZoneScan = now

            for _, zone in ipairs(zoneFolder:GetChildren()) do
                if zone:IsA("BasePart")
                    and InsideActionZone(zone, root.Position) then
                    cachedActionZone = zone
                    return zone
                end
            end

            -- อยู่สะพาน/นอกขอบ/โซนยังไม่โหลด ให้พักทั้งสามระบบ
            return nil
        end

        local function InCurrentActionZone(position)
            local zone = GetActionZone()
            return zone ~= nil and InsideActionZone(zone, position)
        end

        local function PumpkinCandidate(model, level)
            local part = GetMonsterPart(model)
            if not part then return nil end

            local currentZone = GetActionZone()

            if not currentZone
                or not InsideActionZone(currentZone, part.Position) then
                return nil
            end

            local id = model:GetAttribute("MonsterId")
            local def = type(id) == "string" and monsterData[id]
            local zone = type(id) == "string" and pumpkinZones[id]

            if type(def) ~= "table"
                or def.HalloweenPumpkin ~= true
                or not zone
                or not CanAccess(zone, level)
                or not gatesValid then
                return nil
            end

            if zone.Id ~= currentZone.Name then
                return nil
            end

            -- ไม่ข้ามประตูบอสที่ยังไม่ผ่าน
            for _, requirement in ipairs(requirements) do
                if requirement.Order > zone.Order then break end

                if bossGates[requirement.GateId] ~= true then
                    return nil
                end
            end

            return part, zone, id
        end

        local function BuildPumpkinPlan(level)
            -- ตีตัวเดิมต่อจนตายหรือไม่ผ่านเงื่อนไข
            if target then
                local part, zone, id = PumpkinCandidate(target, level)

                if part then
                    return zone, { [id] = true }, nil, nil, target
                end
            end

            local character = LocalPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = humanoid and humanoid.RootPart

            if not root or not root:IsA("BasePart") then
                return nil
            end

            local nearest
            local nearestZone
            local nearestId
            local nearestDistance = math.huge

            -- ใช้รายการ Monsters ที่ระบบเดิม Cache ไว้
            for model in pairs(monsters) do
                local part, zone, id = PumpkinCandidate(model, level)

                if part then
                    local distance =
                        (part.Position - root.Position).Magnitude

                    if distance < nearestDistance then
                        nearest = model
                        nearestZone = zone
                        nearestId = id
                        nearestDistance = distance
                    end
                end
            end

            if nearest then
                return nearestZone, {
                    [nearestId] = true,
                }, nil, nil, nearest
            end

            return nil
        end

        local function UpdateFarmParty()
            partyFarmData = nil

            local raw = LocalPlayer:GetAttribute("PartyJson")
            if type(raw) ~= "string" or raw == "" then
                return
            end

            local ok, data = pcall(
                HttpService.JSONDecode, HttpService, raw
            )

            if not ok or type(data) ~= "table"
                or type(data.Leader) ~= "number"
                or data.Leader ~= data.Leader
                or data.Leader <= 0
                or data.Leader == math.huge
                or data.Leader % 1 ~= 0
                or type(data.Members) ~= "table" then
                return
            end

            local hasLocal = false
            local hasLeader = false

            for _, member in ipairs(data.Members) do
                if type(member) == "table" then
                    if member.UserId == LocalPlayer.UserId then
                        hasLocal = true
                    end

                    if member.UserId == data.Leader then
                        hasLeader = true
                    end
                end
            end

            if hasLocal and hasLeader then
                partyFarmData = data
            end
        end

        Connect(
            LocalPlayer:GetAttributeChangedSignal("PartyJson"),
            UpdateFarmParty
        )

        UpdateFarmParty()

        local function BuildPartySearchPlan(level, leaderId)
            partySearching = true

            local character = LocalPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = humanoid and humanoid.RootPart

            if not root or not root:IsA("BasePart")
                or not humanoid or humanoid.Health <= 0 then
                return nil, nil, "Party Search: waiting for character"
            end

            if not gatesValid then
                return nil, nil, "Party Search: waiting for gate data"
            end

            local gateState =
                LocalPlayer:GetAttribute("BossGatesJson")

            if partySearch and (
                partySearch.LeaderId ~= leaderId
                or partySearch.Character ~= character
                or partySearch.Level ~= level
                or partySearch.GateState ~= gateState
            ) then
                partySearch = nil
            end

            if not partySearch then
                local zoneFolder = workspace:FindFirstChild("Zones")
                if not zoneFolder then
                    return nil, nil, "Party Search: waiting for zones"
                end

                local route = {}
                local nearestIndex
                local nearestDistance = math.huge

                for _, zone in ipairs(zones) do
                    local allowed = zone.Data.BossRoom ~= true
                        and CanAccess(zone, level)

                    if allowed then
                        for _, requirement in ipairs(requirements) do
                            if requirement.Order > zone.Order then
                                break
                            end

                            if bossGates[requirement.GateId] ~= true then
                                allowed = false
                                break
                            end
                        end
                    end

                    local part = zoneFolder:FindFirstChild(zone.Id)

                    if allowed and part and part:IsA("BasePart") then
                        table.insert(route, zone)
                    end
                end

                table.sort(route, function(a, b)
                    return a.Order < b.Order
                end)

                for index, zone in ipairs(route) do
                    local part = zoneFolder:FindFirstChild(zone.Id)
                    local distance =
                        (part.Position - root.Position).Magnitude

                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestIndex = index
                    end
                end

                if not nearestIndex then
                    return nil, nil,
                        "Party Search: no accessible loaded fields"
                end

                partySearch = {
                    LeaderId = leaderId,
                    Character = character,
                    Level = level,
                    GateState = gateState,
                    Route = route,
                    Index = nearestIndex,
                    Direction = 1,
                    Visited = {},
                    ArrivedAt = nil,
                }
            end

            local search = partySearch
            local now = os.clock()

            if search.RetryAt then
                if now < search.RetryAt then
                    return nil, nil,
                        "Party Search: not found; waiting to search again"
                end

                table.clear(search.Visited)
                search.RetryAt = nil
                search.ArrivedAt = nil
            end

            local allVisited = true

            for _, zone in ipairs(search.Route) do
                if not search.Visited[zone.Id] then
                    allVisited = false
                    break
                end
            end

            if allVisited then
                search.RetryAt = now + PARTY_SEARCH_RETRY
                return nil, nil,
                    "Party Search: accessible fields checked; leader not found"
            end

            -- เดินตามลำดับโซน กลับทิศเมื่อสุดทาง
            -- ไม่ข้ามจากปลายแมพกลับต้นแมพในครั้งเดียว
            if search.Advance then
                local nextIndex = search.Index + search.Direction

                if nextIndex < 1 or nextIndex > #search.Route then
                    search.Direction = -search.Direction
                    nextIndex = search.Index + search.Direction
                end

                search.Index = math.clamp(
                    nextIndex, 1, #search.Route
                )

                search.Advance = false
                search.ArrivedAt = nil
            end

            local goal = search.Route[search.Index]

            return goal, {}, "Party Search: " .. goal.Id
        end

        local function BuildPartyFarmPlan(level)
            partyFarmLeaderRoot = nil
            partySearching = false

            if not partyFarmData then
                return nil, nil, "Party Farm: waiting for party"
            end

            local leader = Players:GetPlayerByUserId(
                partyFarmData.Leader
            )

            local character = leader and leader.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = humanoid and humanoid.RootPart

            if not leader then
                partySearch = nil
                return nil, nil, "Party Farm: leader is not in this server"
            end

            if leader:GetAttribute("InTown") == true then
                partySearch = nil
                return nil, nil, "Party Farm: leader is in town"
            end

            if humanoid and humanoid.Health <= 0 then
                return nil, nil, "Party Farm: waiting for leader to respawn"
            end

            if not humanoid
                or not root or not root:IsA("BasePart")
                or not root.Parent then
                return BuildPartySearchPlan(
                    level, partyFarmData.Leader
                )
            end

            -- พบตัวหัวหน้าที่โหลดจริงแล้ว
            partySearch = nil

            local zoneFolder = workspace:FindFirstChild("Zones")
            if not zoneFolder then
                return nil, nil, "Party Farm: waiting for zones"
            end

            local chosen
            local smallestArea = math.huge

            for _, zone in ipairs(zones) do
                local part = zoneFolder:FindFirstChild(zone.Id)

                if part and part:IsA("BasePart") then
                    local point =
                        part.CFrame:PointToObjectSpace(root.Position)

                    if math.abs(point.X) <= part.Size.X / 2
                        and math.abs(point.Z) <= part.Size.Z / 2 then

                        local area = part.Size.X * part.Size.Z

                        if area < smallestArea then
                            smallestArea = area
                            chosen = zone
                        end
                    end
                end
            end

            if not chosen then
                return nil, nil,
                    "Party Farm: waiting for leader field"
            end

            if chosen.Data.BossRoom == true then
                return nil, nil,
                    "Party Farm: waiting for leader in a regular field"
            end

            if not CanAccess(chosen, level) then
                return nil, nil,
                    "Party Farm: leader field requires a higher level"
            end

            if not gatesValid then
                return nil, nil,
                    "Party Farm: waiting for BossGatesJson"
            end

            for _, requirement in ipairs(requirements) do
                if requirement.Order > chosen.Order then break end

                if bossGates[requirement.GateId] ~= true then
                    return nil, nil,
                        "Party Farm: clear "
                            .. requirement.GateId .. " first"
                end
            end

            local ids = {}

            for id in pairs(chosen.Ids) do
                if IsRegular(id) then
                    ids[id] = true
                end
            end

            if not next(ids) then
                return nil, nil,
                    "Party Farm: no regular monsters in this field"
            end

            partyFarmLeaderRoot = root
            return chosen, ids
        end

        local function BuildPlan(level)
            if partyFarmEnabled then
                return BuildPartyFarmPlan(level)
            end

            if pumpkinEnabled then
                local zone, ids, reason, gateId, eventTarget =
                    BuildPumpkinPlan(level)

                if zone then
                    return zone, ids, reason, gateId, eventTarget
                end

                if not farmRequested then
                    return nil, nil,
                        "Waiting for an accessible Pumpkin Spider"
                end
            end

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
            pullSession = nil
            farmPullActive = false
            StopFarmHover()
        end

        -- ระยะเผื่อขอบที่สคริปต์กำหนดเอง
        local FARM_EDGE_MARGIN = 15

        local function SafeFarmDestination(
            zoneId, monsterPosition, preferred, reach
        )
            local zonesFolder = workspace:FindFirstChild("Zones")
            local zonePart = zonesFolder
                and zonesFolder:FindFirstChild(zoneId)

            local map = workspace:FindFirstChild("Map")
            local chunks = map and map:FindFirstChild("BlockFields")
            local chunk = chunks and chunks:FindFirstChild(zoneId)
            local island = chunk and chunk:FindFirstChild("Island")

            if not zonePart or not zonePart:IsA("BasePart")
                or not island then
                return nil
            end

            -- รวมเฉพาะพื้นจริง ไม่รวม Barriers / Decor / โซนข้างเคียง
            local floors = {}

            for _, name in ipairs({ "Base", "Dirt" }) do
                local part = island:FindFirstChild(name)

                if part and part:IsA("BasePart")
                    and part.CanCollide then
                    table.insert(floors, part)
                end
            end

            if #floors == 0 then return nil end

            local halfX = zonePart.Size.X / 2 - FARM_EDGE_MARGIN
            local halfZ = zonePart.Size.Z / 2 - FARM_EDGE_MARGIN

            if halfX <= 0 or halfZ <= 0 then return nil end

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = floors
            params.RespectCanCollide = true

            local function Inside(point)
                local localPoint =
                    zonePart.CFrame:PointToObjectSpace(point)

                return math.abs(localPoint.X) <= halfX
                    and math.abs(localPoint.Z) <= halfZ
            end

            local function HasFloor(point)
                local hit = workspace:Raycast(
                    point + Vector3.new(0, 10, 0),
                    Vector3.new(0, -200, 0),
                    params
                )

                return hit ~= nil
                    and hit.Normal.Y > 0.9
                    and hit.Position.Y < point.Y
            end

            local function InRange(point)
                return (point - monsterPosition).Magnitude <= reach
            end

            -- จุดเดิมปลอดภัยแล้ว ใช้ต่อเพื่อไม่ให้สลับฝั่งไปมา
            if Inside(preferred)
                and InRange(preferred)
                and HasFloor(preferred) then
                return preferred
            end

            local function ClampInside(point)
                local localPoint =
                    zonePart.CFrame:PointToObjectSpace(point)

                local worldPoint =
                    zonePart.CFrame:PointToWorldSpace(Vector3.new(
                        math.clamp(localPoint.X, -halfX, halfX),
                        localPoint.Y,
                        math.clamp(localPoint.Z, -halfZ, halfZ)
                    ))

                return Vector3.new(
                    worldPoint.X, preferred.Y, worldPoint.Z
                )
            end

            local insetPoint = ClampInside(preferred)
            local candidates = {
                insetPoint,
                ClampInside(monsterPosition),
            }

            -- คงความสูงเดิมและคำนวณระยะราบจากระยะโจมตีจริง
            local height = preferred.Y - monsterPosition.Y
            local horizontal = math.sqrt(
                math.max(0, reach * reach - height * height)
            )

            -- ค้นรอบมอนเฉพาะเมื่อจุดเดิมไม่ผ่าน
            for ring = 1, 2 do
                local distance = horizontal
                    * (ring == 1 and 1 or 0.65)

                for index = 0, 31 do
                    local angle = index * math.pi * 2 / 32

                    table.insert(candidates, Vector3.new(
                        monsterPosition.X + math.cos(angle) * distance,
                        preferred.Y,
                        monsterPosition.Z + math.sin(angle) * distance
                    ))
                end
            end

            table.sort(candidates, function(a, b)
                return (a - preferred).Magnitude
                    < (b - preferred).Magnitude
            end)

            for _, point in ipairs(candidates) do
                if Inside(point)
                    and InRange(point)
                    and HasFloor(point) then
                    return point
                end
            end

            -- มอนอยู่นอกระยะที่เข้าถึงได้:
            -- รอด้านในที่มีพื้น ไม่ตามออกขอบ
            if Inside(insetPoint) and HasFloor(insetPoint) then
                return insetPoint
            end

            return nil
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
            StopFarmWalk()

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

        local function BuildTravelHops(goal, position, level, stepSize)
            stepSize = stepSize == 1 and 1 or 2
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

            for index = stepSize, #between, stepSize do
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

                local stepSize = partyFarmEnabled and 1 or 2
                local hops

                if partyFarmEnabled then
                    hops = BuildTravelHops(
                        zone, root.Position, level, stepSize
                    )

                    if not hops or #hops == 0 then
                        SetStatus(
                            "Party Farm: no accessible route to leader"
                        )
                        return false
                    end
                end

                farmTravel = {
                    Goal = zone,
                    Character = character,
                    Root = root,
                    AutoWasOn = autoOn,
                    StartedAt = os.clock(),

                    -- Party เดินทางทีละโซนทันที
                    Direct = not partyFarmEnabled,
                    StepSize = stepSize,
                    Hops = hops,
                    Index = 1,
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
                        zone,
                        root.Position,
                        level,
                        travel.StepSize
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
                        zone,
                        root.Position,
                        level,
                        travel.StepSize
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

            if workspace.StreamingEnabled
                and travel.StreamHop ~= hop then

                local now = os.clock()
                if now < (travel.NextStreamAt or 0) then
                    return false
                end

                if travel.StreamTarget ~= hop then
                    travel.StreamTarget = hop
                    travel.StreamTries = 0
                end

                travel.StreamTries += 1
                SetStatus("Loading destination: " .. hop.Id)

                local loaded, streamError = pcall(function()
                    LocalPlayer:RequestStreamAroundAsync(destination, 5)
                end)

                -- คำขอโหลดมีการ yield ต้องตรวจสถานะใหม่
                if not alive or not enabled
                    or farmTravel ~= travel
                    or LocalPlayer.Character ~= character
                    or not root.Parent
                    or humanoid.Health <= 0 then
                    return false
                end

                if root.Anchored then
                    return false
                end

                local map = workspace:FindFirstChild("Map")
                local fields = map and map:FindFirstChild("BlockFields")
                local field = fields and fields:FindFirstChild(hop.Id)
                local island = field and field:FindFirstChild("Island")
                local floor

                if island then
                    for _, name in ipairs({ "Base", "Dirt" }) do
                        local part = island:FindFirstChild(name)
                        if part and part:IsA("BasePart")
                            and part.CanCollide then
                            floor = part
                            break
                        end
                    end
                end

                if not loaded or not floor then
                    travel.NextStreamAt = os.clock() + 2

                    if travel.StreamTries >= 3 then
                        travel.Blocked =
                            "destination streaming not ready"
                    end

                    SetStatus(
                        loaded and "Waiting for destination floor"
                            or "Streaming error: " .. tostring(streamError)
                    )
                    return false
                end

                travel.StreamHop = hop
                return false
            end

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

        local dodgeEnabled = false
        local dodgeEvents = {}
        local dodgeSession

        -- ไม่สร้างป้าย Debug บนหน้า Auto Farm
        local hiddenDodgeStatus = {
            SetValue = function() end,
        }

        local dodgeStatus = hiddenDodgeStatus
        local dodgeSkillStatus = hiddenDodgeStatus
        local dodgeCheckStatus = hiddenDodgeStatus
        local dodgeDataStatus = hiddenDodgeStatus

        -- ขอบพื้นที่ที่ตรวจยืนยันแล้ว อิงศูนย์กลาง Floor ที่โหลดจริง
        -- เว้นขอบเพิ่มอีก 2 studs ในขั้นตอนเลือกจุด
        local dodgeRooms = {
            Boss01 = { Floor = "Base", HalfX = 65, HalfZ = 49 },
            Boss02 = { Floor = "Dirt", HalfX = 65, HalfZ = 50 },
            Boss03 = { Floor = "Base", HalfX = 65, HalfZ = 49 },
            Boss04 = { Floor = "Base", HalfX = 65, HalfZ = 49 },
        }

        local DODGE_MARGIN = 2
        local DODGE_GRID = 8
        local DODGE_SETTLE = 0.5 -- เผื่อรอคลื่นถัดไป ไม่ใช่เวลา Damage

        local function NumberOK(value)
            return type(value) == "number"
                and value == value
                and math.abs(value) < math.huge
        end

        local function Flat(vector)
            return Vector3.new(vector.X, 0, vector.Z)
        end

        local function ProgressionGate(model)
            local id = model:GetAttribute("MonsterId")

            for _, requirement in ipairs(requirements) do
                if requirement.MonsterId == id then
                    return requirement.GateId
                end
            end

            return nil
        end

        ResetBossDodge = function(restoreAuto)
            local old = dodgeSession
            dodgeSession = nil
            bossDodgeActive = false
            table.clear(dodgeEvents)

            if not old then return end

            local bossPart = old.Boss
                and GetMonsterPart(old.Boss)

            if bossPart and old.Boss == target
                and old.Character == LocalPlayer.Character
                and old.Root and old.Root.Parent then

                local direction = Flat(
                    old.Root.Position - bossPart.Position
                )

                if direction.Magnitude > 0.01 then
                    farmSideTarget = target
                    farmSideRoot = old.Root
                    farmSideDirection = direction.Unit
                end
            end

            StopFarmHover()
            holding = false

            if restoreAuto and alive
                and old.Character == LocalPlayer.Character
                and old.Humanoid.Parent
                and old.Humanoid.Health > 0
                and old.AutoWasOn
                and not potionTripActive
                and not sellTripActive
                and not dropTripActive
                and not chestTripActive
                and not farmTravelActive then

                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if menu and menu:IsA("BindableEvent")
                    and LocalPlayer:GetAttribute("AutoOn") ~= true then
                    menu:Fire("autoToggle")
                end
            end
        end

        -- คืน true = จุดอยู่ในรูปทรง
        -- คืน nil = ข้อมูลรูปทรงไม่ครบ ห้ามเดาจุดหลบ
        local function InsideAttack(zone, position, margin, inner)
            if zone.Safe == true
                or zone.Kind == "circle" then

                if typeof(zone.Center) ~= "Vector3"
                    or not NumberOK(zone.Radius) then
                    return nil
                end

                local distance =
                    Flat(position - zone.Center).Magnitude

                if zone.Safe == true then
                    return distance <= math.max(
                        0, zone.Radius - margin
                    )
                end

                if inner ~= nil then
                    if not NumberOK(inner) then return nil end

                    return distance >= math.max(0, inner - margin)
                        and distance <= zone.Radius + margin
                end

                return distance <= zone.Radius + margin
            end

            if zone.Kind == "cone" then
                local direction = zone.Dir
                local halfAngle = zone.Half

                if typeof(direction) ~= "Vector3" then
                    direction = zone.Facing
                end

                if not NumberOK(halfAngle)
                    and NumberOK(zone.Angle) then
                    halfAngle = math.rad(zone.Angle / 2)
                end

                if typeof(zone.Center) ~= "Vector3"
                    or typeof(direction) ~= "Vector3"
                    or not NumberOK(zone.Radius)
                    or zone.Radius <= 0
                    or not NumberOK(halfAngle)
                    or halfAngle <= 0
                    or halfAngle > math.pi then
                    return nil
                end

                local offset = Flat(position - zone.Center)
                direction = Flat(direction)

                local distance = offset.Magnitude

                if direction.Magnitude <= 0.001 then return nil end
                if distance > zone.Radius + margin then return false end
                if distance <= margin then return true end

                local extra = math.asin(
                    math.clamp(margin / distance, 0, 1)
                )

                local angle = math.acos(math.clamp(
                    direction.Unit:Dot(offset.Unit), -1, 1
                ))

                return angle <= halfAngle + extra
            end

            -- รองรับพื้นที่สี่เหลี่ยมตามข้อมูลที่ Native ใช้วาดจริง
            if zone.Room == true
                or zone.Kind == "room"
                or zone.Kind == "line"
                or zone.Kind == "charge"
                or zone.Kind == "cross"
                or (
                    typeof(zone.CFrame) == "CFrame"
                    and NumberOK(zone.Width)
                    and NumberOK(zone.Length)
                ) then

                if typeof(zone.CFrame) ~= "CFrame"
                    or not NumberOK(zone.Width)
                    or not NumberOK(zone.Length) then
                    return nil
                end

                -- ตัดความสูงออกก่อนแปลงพิกัด
                local point = Vector3.new(
                    position.X,
                    zone.CFrame.Position.Y,
                    position.Z
                )
                local relative =
                    zone.CFrame:PointToObjectSpace(point)

                return math.abs(relative.X)
                        <= zone.Width / 2 + margin
                    and math.abs(relative.Z)
                        <= zone.Length / 2 + margin
            end

            return nil
        end

        local function PointAllowed(position)
            for _, event in ipairs(dodgeEvents) do
                local inSafe = false

                for _, zone in ipairs(event.Zones) do
                    if zone.Safe == true then
                        local inside = InsideAttack(
                            zone, position, DODGE_MARGIN
                        )
                        if inside == nil then return false end
                        if inside then inSafe = true end
                    end
                end

                for _, zone in ipairs(event.Zones) do
                    if zone.Safe ~= true then
                        local inside = InsideAttack(
                            zone, position, DODGE_MARGIN,
                            event.Inner
                        )

                        if inside == nil then return false end

                        if inside then
                            -- วงเขียวยกเว้นเฉพาะพื้นโจมตีทั้งห้อง
                            local room = zone.Room == true
                                or zone.Kind == "room"

                            if not room or not inSafe then
                                return false
                            end
                        end
                    end
                end
            end

            return true
        end

        local function IsDodgeMonster(model)
            if not model or not GetMonsterPart(model) then
                return false
            end

            local id = model:GetAttribute("MonsterId")
            local def = type(id) == "string" and monsterData[id]

            return model:GetAttribute("IsBoss") == true
                or model:GetAttribute("IsMiniBoss") == true
                or model:GetAttribute("IsLeader") == true
                or (
                    type(def) == "table"
                    and (
                        def.Boss == true
                        or def.MiniBoss == true
                        or def.Leader == true
                        or def.HalloweenPumpkin == true
                    )
                )
        end

        local function GetDodgeArea(areaId)
            if type(areaId) ~= "string" then return nil end

            local map = workspace:FindFirstChild("Map")
            local chunks = map and map:FindFirstChild("BlockFields")
            local chunk = chunks and chunks:FindFirstChild(areaId)
            local island = chunk and chunk:FindFirstChild("Island")

            if not island then return nil end

            -- ห้องบอสใช้ขอบที่ตรวจยืนยันไว้เดิม
            local roomBounds = dodgeRooms[areaId]

            if roomBounds then
                local floor = island:FindFirstChild(roomBounds.Floor)

                if floor and floor:IsA("BasePart")
                    and floor.CanCollide and floor.CanQuery then
                    return floor, roomBounds, floor.CFrame
                end

                return nil
            end

            -- โซนปกติ: ใช้ Zone เป็นขอบ และ Base เป็นพื้นเท่านั้น
            local zoneDef = zoneById[areaId]
            if not zoneDef or zoneDef.Data.BossRoom == true then
                return nil
            end

            local zonesFolder = workspace:FindFirstChild("Zones")
            local zonePart = zonesFolder
                and zonesFolder:FindFirstChild(areaId)
            local floor = island:FindFirstChild("Base")

            if not zonePart or not zonePart:IsA("BasePart")
                or not floor or not floor:IsA("BasePart")
                or not floor.CanCollide or not floor.CanQuery then
                return nil
            end

            -- ระยะเผื่อขอบของสคริปต์ ไม่ใช่ขอบเซิร์ฟเวอร์
            local edgeMargin = 15
            local halfX = zonePart.Size.X / 2 - edgeMargin
            local halfZ = zonePart.Size.Z / 2 - edgeMargin

            if halfX <= DODGE_MARGIN
                or halfZ <= DODGE_MARGIN then
                return nil
            end

            return floor, {
                HalfX = halfX,
                HalfZ = halfZ,
            }, zonePart.CFrame
        end

        local bossFx = FindRequired(remotes, "BossFx", "RemoteEvent")

        if bossFx then
            Connect(bossFx.OnClientEvent, function(
                action, bossName, skillName, zonesData, duration
            )
                if not alive or not enabled or not dodgeEnabled
                    or potionTripActive or sellTripActive
                    or dropTripActive or chestTripActive
                    or farmTravelActive
                    or type(bossName) ~= "string"
                    or type(skillName) ~= "string" then
                    return
                end

                -- หาโมเดลบอสจากชื่อโดยตรง ไม่ผูกกับ Target ที่ล็อกอยู่
                -- เพื่อให้จับสัญญาณสกิลได้แม้ไม่ได้ Target บอสตัวนั้น
                local bossModel
                local matching = 0

                for model in pairs(monsters) do
                    if IsDodgeMonster(model) and GetMonsterPart(model) then
                        local modelId = model:GetAttribute("MonsterId")
                        local modelDef = monsterData[modelId]
                        local modelName = model:GetAttribute("DisplayName")
                            or (type(modelDef) == "table" and modelDef.Name)

                        if modelName == bossName then
                            matching += 1
                            bossModel = model
                        end
                    end
                end

                -- Remote มีแค่ชื่อ จึงไม่ใช้เมื่อมีผู้ร่ายชื่อเดียวกันหลายตัว
                if matching ~= 1 or not bossModel then return end

                local id = bossModel:GetAttribute("MonsterId")
                local def = monsterData[id]

                local key = bossName .. "|" .. skillName
                local now = os.clock()

                if action == "cancel" then
                    for index = #dodgeEvents, 1, -1 do
                        local event = dodgeEvents[index]
                        if event.Boss == bossModel
                            and event.Key == key and not event.Hit then
                            table.remove(dodgeEvents, index)
                        end
                    end
                    return
                end

                if action == "hit" then
                    if not NumberOK(duration) or duration < 0 then return end

                    for _, event in ipairs(dodgeEvents) do
                        if event.Boss == bossModel
                            and event.Key == key and not event.Hit then
                            event.Hit = true
                            event.Expires = math.max(
                                event.Expires,
                                now + math.max(
                                    DODGE_SETTLE,
                                    duration,
                                    event.PoolDuration or 0
                                )
                            )
                            break
                        end
                    end
                    return
                end

                if action ~= "warn"
                    or type(zonesData) ~= "table"
                    or not NumberOK(duration) or duration < 0 then
                    return
                end

                local function FindMove(moves)
                    if type(moves) ~= "table" then return nil end

                    for _, candidate in pairs(moves) do
                        if type(candidate) == "table"
                            and candidate.Name == skillName then
                            return candidate
                        end
                    end

                    return nil
                end

                local skill

                if type(def) == "table" then
                    skill = FindMove(def.Skills)
                        or FindMove(def.LeaderMoves)

                    if not skill
                        and def.HalloweenPumpkin == true
                        and type(def.PumpkinFrom) == "string" then

                        local base = monsterData[def.PumpkinFrom]

                        if type(base) == "table" then
                            skill = FindMove(base.Skills)
                                or FindMove(base.LeaderMoves)
                        end
                    end
                end

                if not skill then
                    dodgeStatus:SetValue(
                        "ไม่พบสกิลใน Skills / LeaderMoves: "
                            .. skillName
                    )
                    return
                end

                local poolDuration = 0

                if skill.Pool then
                    if type(skill.Pool) ~= "table"
                        or not NumberOK(skill.Pool.Duration)
                        or skill.Pool.Duration < 0 then
                        return
                    end

                    poolDuration = skill.Pool.Duration
                end

                if skill.Shape == "spin" then
                    dodgeStatus:SetValue(
                        "ยังไม่รองรับ Spin: " .. skillName
                    )
                    return
                end

                local snapshot = {}
                for _, zone in ipairs(zonesData) do
                    if type(zone) ~= "table" then return end
                    table.insert(snapshot, table.clone(zone))
                end
                if #snapshot == 0 then return end

                table.insert(dodgeEvents, {
                    Boss = bossModel,
                    Key = key,
                    Zones = snapshot,
                    Inner = skill.Shape == "donut" and skill.Inner or nil,
                    -- เวลาสิ้นสุดสำรอง กรณีไม่มี hit/cancel ตามมา
                    Expires = now + duration
                        + poolDuration + DODGE_SETTLE,
                    PoolDuration = poolDuration,
                })
            end)
        end

        local function StepBossDodge(
            gate, model, character, humanoid, root
        )
            if not dodgeEnabled or not gate then
                if bossDodgeActive then ResetBossDodge(true) end
                return false
            end

            local now = os.clock()

            -- ล้าง Event ที่หมดอายุ หรือผู้ร่ายตายไปแล้วออกก่อนเสมอ
            -- ไม่ผูกกับ Target ที่ล็อกอยู่ตอนนี้ เพราะอาจไม่มี Target เลย
            for index = #dodgeEvents, 1, -1 do
                local event = dodgeEvents[index]

                if now >= event.Expires
                    or not event.Boss
                    or not GetMonsterPart(event.Boss) then
                    table.remove(dodgeEvents, index)
                end
            end

            if #dodgeEvents == 0 then
                if bossDodgeActive then
                    ResetBossDodge(true)
                    dodgeStatus:SetValue("พ้นช่วงหลบ กลับไปโจมตี")
                end
                return false
            end

            -- ไม่มี Target ล็อกอยู่ก็หลบได้ โดยยึดผู้ร่ายจาก Event
            -- ที่ยังทำงานอยู่แทน (เข้าวงสกิลแล้วต้องหลบทันที)
            if not model or not IsDodgeMonster(model) then
                model = dodgeEvents[1].Boss
            end

            if not model or not IsDodgeMonster(model) then
                if bossDodgeActive then ResetBossDodge(true) end
                return false
            end

            if not dodgeSession then
                dodgeSession = {
                    Character = character,
                    Humanoid = humanoid,
                    Boss = model,
                    Root = root,
                    AutoWasOn =
                        LocalPlayer:GetAttribute("AutoOn") == true,
                }

                bossDodgeActive = true
                StopFarmWalk()
                StopFarmHover()
                holding = false
                setTarget:FireServer(nil, false)

                local menu = LocalPlayer:FindFirstChild("LumiMenuToggle")
                if LocalPlayer:GetAttribute("AutoOn") == true
                    and menu and menu:IsA("BindableEvent") then
                    menu:Fire("autoToggle")
                end
            end

            if LocalPlayer:GetAttribute("AutoOn") == true then
                dodgeStatus:SetValue("รอ Native Auto หยุด")
                return true
            end

            local status = character:GetAttribute("StatusList")
            if type(status) == "string" then
                for token in status:lower():gmatch("[^,%s]+") do
                    if token == "stun" or token == "freeze" then
                        StopFarmHover()
                        dodgeStatus:SetValue("ติด Stun / Freeze")
                        return true
                    end
                end
            end

            local floor, bounds, boundaryFrame = GetDodgeArea(gate)

            if not floor then
                StopFarmHover()
                dodgeStatus:SetValue("รอขอบโซนและพื้นจริงโหลด")
                return true
            end

            local function InBounds(point)
                local relative =
                    boundaryFrame:PointToObjectSpace(point)

                if math.abs(relative.X)
                        > bounds.HalfX - DODGE_MARGIN
                    or math.abs(relative.Z)
                        > bounds.HalfZ - DODGE_MARGIN then
                    return false
                end

                -- ต้องอยู่เหนือกรอบพื้นจริงด้วย
                local floorPoint =
                    floor.CFrame:PointToObjectSpace(point)

                return math.abs(floorPoint.X)
                        <= floor.Size.X / 2 - DODGE_MARGIN
                    and math.abs(floorPoint.Z)
                        <= floor.Size.Z / 2 - DODGE_MARGIN
            end

            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Include
            rayParams.FilterDescendantsInstances = { floor }
            rayParams.RespectCanCollide = true

            local rejected = {
                Bounds = 0,
                Hazard = 0,
                Floor = 0,
                Data = 0,
            }

            local skillNames = {}
            local seenNames = {}
            local geometryOK = true
            local dataIssue

            for _, event in ipairs(dodgeEvents) do
                local name = event.Key:match("%|(.*)$") or event.Key

                if not seenNames[name] then
                    seenNames[name] = true
                    table.insert(skillNames, name)
                end

                for _, zone in ipairs(event.Zones) do
                    if InsideAttack(
                        zone, root.Position, DODGE_MARGIN, event.Inner
                    ) == nil then
                        geometryOK = false

                        if not dataIssue then
                            dataIssue = string.format(
                                "%s | Kind=%s CF=%s W=%s L=%s",
                                name,
                                tostring(zone.Kind),
                                typeof(zone.CFrame),
                                tostring(zone.Width),
                                tostring(zone.Length)
                            )
                        end
                    end
                end
            end

            dodgeSkillStatus:SetValue(table.concat(skillNames, ", "))
            dodgeDataStatus:SetValue(
                dataIssue or "อ่านรูปทรงพื้นที่โจมตีได้"
            )

            local function ValidPoint(point)
                if not geometryOK then
                    rejected.Data += 1
                    return false
                end

                if not InBounds(point) then
                    rejected.Bounds += 1
                    return false
                end

                if not PointAllowed(point) then
                    rejected.Hazard += 1
                    return false
                end

                local hit = workspace:Raycast(
                    point + Vector3.new(0, 100, 0),
                    Vector3.new(0, -500, 0),
                    rayParams
                )

                if not hit or hit.Normal.Y <= 0.9 then
                    rejected.Floor += 1
                    return false
                end

                return true
            end

            local destination = dodgeSession.Point

            if not destination or not ValidPoint(destination) then
                local candidates = { root.Position }

                -- ใส่ศูนย์กลางวงเขียวโดยตรง ไม่พึ่ง Grid อย่างเดียว
                for _, event in ipairs(dodgeEvents) do
                    for _, zone in ipairs(event.Zones) do
                        if zone.Safe == true
                            and typeof(zone.Center) == "Vector3" then
                            table.insert(candidates, Vector3.new(
                                zone.Center.X,
                                root.Position.Y,
                                zone.Center.Z
                            ))

                            if NumberOK(zone.Radius) then
                                local usableRadius = math.max(
                                    0,
                                    zone.Radius - DODGE_MARGIN - 0.25
                                )

                                for ring = 1, 3 do
                                    local radius =
                                        usableRadius * ring / 3
                                    for index = 0, 15 do
                                        local angle =
                                            index * math.pi * 2 / 16

                                        table.insert(
                                            candidates,
                                            Vector3.new(
                                                zone.Center.X
                                                    + math.cos(angle)
                                                        * radius,
                                                root.Position.Y,
                                                zone.Center.Z
                                                    + math.sin(angle)
                                                        * radius
                                            )
                                        )
                                    end
                                end
                            end
                        end
                    end
                end

                for x = -bounds.HalfX + 4, bounds.HalfX - 4, DODGE_GRID do
                    for z = -bounds.HalfZ + 4,
                        bounds.HalfZ - 4, DODGE_GRID do

                        local point = boundaryFrame:PointToWorldSpace(
                            Vector3.new(x, 0, z)
                        )

                        table.insert(candidates, Vector3.new(
                            point.X, root.Position.Y, point.Z
                        ))
                    end
                end

                table.sort(candidates, function(a, b)
                    return (a - root.Position).Magnitude
                        < (b - root.Position).Magnitude
                end)

                destination = nil
                for _, candidate in ipairs(candidates) do
                    if ValidPoint(candidate) then
                        destination = candidate
                        break
                    end
                end

                dodgeSession.Point = destination
            end

            dodgeCheckStatus:SetValue(string.format(
                "Bounds:%d Hazard:%d Floor:%d Data:%d",
                rejected.Bounds,
                rejected.Hazard,
                rejected.Floor,
                rejected.Data
            ))

            if not destination then
                StopFarmHover()
                dodgeStatus:SetValue(
                    "ไม่พบจุดผ่านเงื่อนไข ไม่วาปสุ่ม"
                )
                return true
            end

            local facing = CFrame.new(destination) * root.CFrame.Rotation

            humanoid:Move(Vector3.zero, false)

            local applied = dodgeSession.AppliedPoint

            if not applied
                or Flat(destination - applied).Magnitude > 0.5 then

                root.CFrame = facing
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero

                dodgeSession.AppliedPoint = destination
            end

            HoldFarmPosition(humanoid, root, destination, facing)

            if InBounds(root.Position)
                and PointAllowed(root.Position) then
                dodgeStatus:SetValue(
                    "อยู่นอกพื้นที่เตือน รอผลสกิล"
                )
            else
                dodgeStatus:SetValue(
                    "ตำแหน่งจริงยังไม่พ้นพื้นที่เตือน"
                )
            end

            return true
        end

        combatSection:AddToggle("ZeroXAutoDodgeBossSkill", {
            Title = "Auto Dodge Skill",
            Description = "หลบสกิลบอสปลดด่าน บอสประจำโซน "
                .. "Leader และ Pumpkin Spider ที่กำลังเป็นเป้าหมาย",
            Default = false,

            Callback = function(value)
                dodgeEnabled = value == true
                ResetBossDodge(true)
                dodgeStatus:SetValue(
                    dodgeEnabled and "รอสัญญาณสกิลบอส" or "ปิดใช้งาน"
                )
            end,
        })

        Connect(LocalPlayer.CharacterRemoving, function()
            ResetBossDodge(false)
        end)

        local function InDodgeRoom(gate, position)
            local bounds = dodgeRooms[gate]
            if not bounds then return false end

            local map = workspace:FindFirstChild("Map")
            local chunks = map and map:FindFirstChild("BlockFields")
            local chunk = chunks and chunks:FindFirstChild(gate)
            local island = chunk and chunk:FindFirstChild("Island")
            local floor = island and island:FindFirstChild(bounds.Floor)

            if not floor or not floor:IsA("BasePart") then
                return false
            end

            local relative = floor.CFrame:PointToObjectSpace(position)

            return math.abs(relative.X)
                    <= bounds.HalfX - DODGE_MARGIN
                and math.abs(relative.Z)
                    <= bounds.HalfZ - DODGE_MARGIN
        end

        local CancelNativeFarmNav
        local StepNativeFarmPlan

        do
            local nativeNavRequest
            local farmInputService =
                game:GetService("UserInputService")

            local manualWalkPending = false
            local lastManualWalkAt = -math.huge
            local WALK_RESUME_DELAY = 1

            local farmMoveKeys = {
                Enum.KeyCode.W,
                Enum.KeyCode.A,
                Enum.KeyCode.S,
                Enum.KeyCode.D,
            }

            Connect(farmInputService.InputBegan, function(input, processed)
                if processed or not alive or not enabled
                    or farmMovement ~= "Walk"
                    or farmInputService:GetFocusedTextBox() then
                    return
                end

                if table.find(farmMoveKeys, input.KeyCode) then
                    manualWalkPending = true
                    lastManualWalkAt = os.clock()
                end
            end)

            function CancelNativeFarmNav()
                local request = nativeNavRequest
                nativeNavRequest = nil
                manualWalkPending = false

                -- ยกเลิกเฉพาะเส้นทางที่สคริปต์เป็นผู้สั่ง
                if request
                    and LocalPlayer:GetAttribute("QuestNavId")
                        == request.Value then
                    LocalPlayer:SetAttribute("QuestNavId", "")
                end
            end

            Connect(LocalPlayer.CharacterAdded, CancelNativeFarmNav)
            MacUI:OnUnload(CancelNativeFarmNav)

            function StepNativeFarmPlan(zone, ids, tracker, root)
                if manualWalkPending then
                    local now = os.clock()
                    local keyHeld = false

                    if not farmInputService:GetFocusedTextBox() then
                        for _, key in ipairs(farmMoveKeys) do
                            if farmInputService:IsKeyDown(key) then
                                keyHeld = true
                                break
                            end
                        end
                    end

                    if keyHeld then
                        lastManualWalkAt = now
                        SetStatus("Native Walk: manual movement")
                        return
                    end

                    if now - lastManualWalkAt < WALK_RESUME_DELAY then
                        SetStatus("Native Walk: waiting to resume")
                        return
                    end

                    local current =
                        LocalPlayer:GetAttribute("QuestNavId")
                    local request = nativeNavRequest

                    -- ไม่แทรกเส้นทางใหม่ที่ผู้เล่นเลือกเอง
                    if current == nil or current == ""
                        or (request and current == request.Value) then
                        CancelNativeFarmNav()
                        -- โค้ดด้านล่างจะสร้างคำขอเดินใหม่
                    else
                        manualWalkPending = false
                    end
                end

                StopFarmHover()

                if partyFarmEnabled then
                    CancelNativeFarmNav()
                    SetStatus("Native Walk: party navigation unavailable")
                    return
                end

                if not CanAccess(
                    zone,
                    LocalPlayer:GetAttribute("Level")
                ) then
                    CancelNativeFarmNav()
                    SetStatus("Native Walk: level requirement")
                    return
                end

                -- เลือกจากแผนฟาร์มที่สร้างจากข้อมูลเกมจริง
                local choices = {}
                for id, selected in pairs(ids or {}) do
                    if selected and type(id) == "string"
                        and type(monsterData[id]) == "table" then
                        table.insert(choices, id)
                    end
                end
                table.sort(choices)

                local id = choices[1]
                if not id then
                    CancelNativeFarmNav()
                    SetStatus("Native Walk: no monster in plan")
                    return
                end

                local value = "mon:" .. id
                local request = nativeNavRequest

                if request and (
                    request.Zone ~= zone.Id
                    or request.Value ~= value
                ) then
                    CancelNativeFarmNav()
                    request = nil
                end

                if not request then
                    local current =
                        LocalPlayer:GetAttribute("QuestNavId")

                    -- ไม่เขียนทับเส้นทางที่ผู้เล่นสั่งเอง
                    if current ~= nil and current ~= "" then
                        SetStatus("Native Walk: another navigation is active")
                        return
                    end

                    if not EnsureNativeRoam() then return end

                    ResetPull(false)
                    ClearTarget()

                    nativeNavRequest = {
                        Zone = zone.Id,
                        Value = value,
                    }

                    LocalPlayer:SetAttribute("QuestNavId", value)
                    SetStatus("Native navigation: " .. id)
                    return
                end

                local current = LocalPlayer:GetAttribute("QuestNavId")

                if current == request.Value then
                    -- ระบบเกมเป็นผู้เดิน ข้ามสะพาน และจัดการทางตัน
                    return
                end

                if current ~= nil and current ~= "" then
                    SetStatus("Native Walk: another navigation is active")
                    return
                end

                if not ZoneContains(zone, root.Position) then
                    -- ไม่สั่งเส้นทางเดิมซ้ำเมื่อเกมหยุดเพราะทางตัน
                    local note =
                        LocalPlayer:GetAttribute("QuestNavNote")

                    SetStatus(
                        "Native navigation stopped: "
                            .. (type(note) == "string"
                                and note ~= "" and note
                                or "destination not reached")
                    )
                    return
                end

                -- ถึงโซนแล้ว ให้ Native Auto เลือกเป้าและเดินต่อเอง
                StepNativeFarmWalk(zone, nil, tracker, root)
            end
        end

        local lastNearestTargetRequest = -math.huge

        local function SelectNearestFarmTarget(zone, ids, tracker, root)
            if not alive or not enabled
                or bossDodgeActive
                or potionTripActive or sellTripActive
                or dropTripActive or chestTripActive
                or farmTravelActive
                or LocalPlayer:GetAttribute("AutoOn") ~= true
                or os.clock() < skillCastUntil then
                return
            end

            if not tracker or not tracker:IsA("ObjectValue")
                or not tracker.Parent
                or not root or not root.Parent
                or type(ids) ~= "table"
                or not setTarget.Parent then
                return
            end

            local zoneFolder = workspace:FindFirstChild("Zones")
            local zonePart = zoneFolder
                and zoneFolder:FindFirstChild(zone.Id)

            if not zonePart or not zonePart:IsA("BasePart") then
                return
            end

            local nearest
            local nearestDistance = math.huge

            -- ใช้ Cache เดิม ซึ่งรองรับมอนเกิดใหม่และถูกลบ
            for candidate in pairs(monsters) do
                if not candidate:IsA("Model")
                    or candidate:GetAttribute("IsDummy") == true then
                    continue
                end

                local id = candidate:GetAttribute("MonsterId")
                if ids[id] ~= true then
                    continue
                end

                local part = GetMonsterPart(candidate)
                if not part
                    or not InsideActionZone(zonePart, part.Position) then
                    continue
                end

                local distance = (part.Position - root.Position).Magnitude

                -- ระยะเท่ากันให้ใช้ตัวเดิม ป้องกันสลับโดยไม่จำเป็น
                if distance < nearestDistance
                    or (distance == nearestDistance
                        and candidate == tracker.Value) then
                    nearest = candidate
                    nearestDistance = distance
                end
            end

            if not nearest or tracker.Value == nearest then
                return
            end

            -- จำกัดการเปลี่ยน Target ไม่ยิงทุกเฟรม
            local now = os.clock()
            if now - lastNearestTargetRequest < 0.4 then
                return
            end
            lastNearestTargetRequest = now

            tracker.Value = nearest
            target = nearest
            holding = false

            -- เลือกเป้า แล้วให้ Native Auto เดินและโจมตีตามปกติ
            setTarget:FireServer(nearest, false)
        end

        local function Step()
            if chestTripActive then
                SetStatus("Opening chest: farming paused")
                return
            end

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

            local zone, ids, reason, bossGateId, eventTarget =
                BuildPlan(level)

            if not zone then
                CancelNativeFarmNav()
                FinishFarmTravel(true)
                ResetPull(true)
                ClearTarget()
                SetStatus(reason)
                return
            end

            nativeFarmIds = {}

            nativeFarmAttackLeader = bossGateId ~= nil

            for id, selected in pairs(ids or {}) do
                if selected == true
                    and type(id) == "string"
                    and type(monsterData[id]) == "table" then

                    nativeFarmIds[id] = true

                    local def = monsterData[id]
                    if def.Boss == true
                        or def.MiniBoss == true
                        or def.Leader == true
                        or def.HalloweenPumpkin == true then
                        nativeFarmAttackLeader = true
                    end
                end
            end

            if farmMovement == "Walk" then
                -- ไม่ให้เส้นทางเดินเดิมแทรกระหว่างวาปเปลี่ยนโซน
                CancelNativeFarmNav()

                if not CanAccess(zone, level) then
                    FinishFarmTravel(false)
                    SetStatus("Travel: level requirement")
                    return
                end

                -- ใช้ระบบเดินทางเดิม:
                -- ลองวาปตรง หากไม่ยืนยัน จะใช้เส้นทางข้ามทีละโซน
                if not StepFarmTravel(
                    zone,
                    level,
                    character,
                    humanoid,
                    root
                ) then
                    return
                end

            if partyFarmEnabled and partySearching then
                local search = partySearch

                if not search then
                    ClearTarget()
                    SetStatus("Party Search: preparing route")
                    return
                end

                ResetPull(true)
                ClearTarget()

                humanoid:Move(Vector3.zero, false)

                if farmMovement == "Walk" then
                    StopFarmHover()
                else
                    HoldFarmPosition(
                        humanoid,
                        root,
                        root.Position,
                        root.CFrame
                    )
                end

                -- โซนที่เคยรอโหลดแล้ว ใช้เป็นทางผ่าน
                if search.Visited[zone.Id] then
                    search.Advance = true
                    SetStatus("Party Search: passing " .. zone.Id)
                    return
                end

                if not search.ArrivedAt then
                    search.ArrivedAt = os.clock()
                end

                local elapsed = os.clock() - search.ArrivedAt

                SetStatus(string.format(
                    "Party Search: %s | loading %.1f / %.1fs",
                    zone.Id,
                    elapsed,
                    PARTY_SEARCH_WAIT
                ))

                if elapsed >= PARTY_SEARCH_WAIT then
                    search.Visited[zone.Id] = true
                    search.Advance = true
                    search.ArrivedAt = nil
                end

                return
            end

            if partyFarmEnabled and partyFarmLeaderRoot
                and partyFarmLeaderRoot.Parent
                and partyFarmData
                and partyFarmData.Leader ~= LocalPlayer.UserId then

                local offset =
                    root.Position - partyFarmLeaderRoot.Position

                local distance = Vector3.new(
                    offset.X, 0, offset.Z
                ).Magnitude

                -- ตามเมื่อออกห่างมากพอ ไม่วาปตามทุก Tick
                if distance > partyFarmRadius + 20 then
                    ResetPull(true)
                    ClearTarget()

                    if isCasting then
                        SetStatus("Party Farm: waiting for cast to finish")
                        return
                    end

                    -- ใช้ตำแหน่งหัวหน้าที่โหลดจริง
                    local destination = partyFarmLeaderRoot.Position
                        + Vector3.new(0, 4, 0)

                    local facing = CFrame.new(destination)
                        * root.CFrame.Rotation

                    humanoid:Move(Vector3.zero, false)
                    root.CFrame = facing
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero

                    StopFarmHover()

                    SetStatus("Party Farm: following leader")
                    return
                end
            end


                -- ระหว่างหลบต้องคงผู้ร่ายเดิมไว้
                -- เพราะระบบ Dodge เคลียร์ CurrentTarget ตอนเริ่มหลบ
                local combatTarget = dodgeSession
                    and dodgeSession.Boss
                    or tracker.Value

                local combatPart = combatTarget
                    and GetMonsterPart(combatTarget)

                if not combatPart then
                    if bossDodgeActive then
                        ResetBossDodge(true)
                    end

                    combatTarget = tracker.Value
                    combatPart = combatTarget
                        and GetMonsterPart(combatTarget)
                end

                target = combatPart and combatTarget or nil

                if target and pumpkinEnabled then
                    local id = target:GetAttribute("MonsterId")
                    local def = type(id) == "string"
                        and monsterData[id]

                    if type(def) == "table"
                        and def.HalloweenPumpkin == true
                        and not InCurrentActionZone(
                            combatPart.Position
                        ) then
                        ClearTarget()
                        return
                    end
                end

                -- ให้ Dodge ทำงานก่อนเปิด Native Auto เดินต่อ
                -- ทำงานแม้ไม่ได้ Target บอสอยู่ ถ้ายืนอยู่ในวงสกิลจริง
                if StepBossDodge(
                    bossGateId or zone.Id,
                    target,
                    character,
                    humanoid,
                    root
                ) then
                    return
                end

                StepNativeFarmWalk(
                    zone, target, tracker, root
                )

                SelectNearestFarmTarget(
                    zone, ids, tracker, root
                )

                return
            end

            CancelNativeFarmNav()

            -- อยู่ในห้องหรือไม่ ไม่ขึ้นกับว่ามี Target แล้วหรือยัง
            local bossHere = bossGateId ~= nil
                and InDodgeRoom(bossGateId, root.Position)

            if bossHere then
                if farmTravel then
                    FinishFarmTravel(true)
                end

                local validBoss = target
                    and ids[target:GetAttribute("MonsterId")]
                    and GetMonsterPart(target)
                    and ProgressionGate(target) == bossGateId

                if not validBoss then
                    ClearTarget()

                    local nearestDistance = math.huge

                    for model in pairs(monsters) do
                        local id = model:GetAttribute("MonsterId")

                        if ids[id]
                            and ProgressionGate(model) == bossGateId then

                            local part = GetMonsterPart(model)

                            if part then
                                local distance =
                                    (part.Position - root.Position).Magnitude

                                if distance < nearestDistance then
                                    nearestDistance = distance
                                    target = model
                                end
                            end
                        end
                    end
                end

                if StepBossDodge(
                    bossGateId,
                    target,
                    character,
                    humanoid,
                    root
                ) then
                    return
                elseif not (target and GetMonsterPart(target)) then
                    dodgeStatus:SetValue(
                        "อยู่ในห้องแล้ว รอ Model บอสโหลดหรือเกิด"
                    )
                end
            else
                if not StepFarmTravel(
                    zone, level, character, humanoid, root
                ) then
                    if bossGateId then
                        dodgeStatus:SetValue(
                            "Travel: กำลังเข้าห้อง " .. bossGateId
                        )
                    end
                    return
                end
            end

            local function Eligible(model)
                local id = model:GetAttribute("MonsterId")
                if not ids[id] then return nil end

                if eventTarget and model ~= eventTarget then
                    return nil
                end

                -- แผนบอสอนุญาตเฉพาะ MonsterId ที่ BuildPlan เลือก
                if mode == "Farm Level" and not bossGateId
                    and not eventTarget
                    and not IsRegular(id, model) then
                    return nil
                end

                local part = GetMonsterPart(model)
                if not part then return nil end

                if partyFarmEnabled then
                    local leaderRoot = partyFarmLeaderRoot

                    if not leaderRoot or not leaderRoot.Parent then
                        return nil
                    end

                    local offset = part.Position - leaderRoot.Position
                    local distance = Vector3.new(
                        offset.X, 0, offset.Z
                    ).Magnitude

                    if distance > partyFarmRadius then
                        return nil
                    end
                end

                return part
            end

            local targetPart

            if farmMovement == "Walk" then
                -- เกมเป็นผู้เลือกเป้าหมาย รวมถึงมอนที่เข้ามาคุกคาม
                -- ไม่ ClearTarget หรือส่ง SetTarget สวนการเลือกของเกม
                local nativeTarget = tracker.Value
                local nativePart = nativeTarget
                    and GetMonsterPart(nativeTarget)

                if target ~= nativeTarget and bossDodgeActive then
                    ResetBossDodge(true)
                end

                target = nativePart and nativeTarget or nil
                targetPart = nativePart

                if not targetPart then
                    StepNativeFarmWalk(
                        zone, nil, tracker, root
                    )
                    return
                end
            else
                targetPart = target and Eligible(target)

                if not targetPart then
                    ClearTarget()
                    local nearestDistance = math.huge

                    for model in pairs(monsters) do
                        local part = Eligible(model)

                        if part then
                            local distance =
                                (part.Position - root.Position).Magnitude

                            if distance < nearestDistance then
                                nearestDistance = distance
                                target = model
                                targetPart = part
                            end
                        end
                    end
                end
            end

            if not target or not targetPart then
                StopFarmWalk()

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

            if not bossHere and StepBossDodge(
                bossGateId or zone.Id,
                target,
                character,
                humanoid,
                root
            ) then
                return
            end

            if farmMovement == "Walk" then
                StepNativeFarmWalk(
                    zone, target, tracker, root
                )
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
            local HOVER_HEIGHT = FARM_HOVER_HEIGHT

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

            -- แก้ขอบเฉพาะฟาร์มทั่วไป
            -- ห้องบอสยังใช้ระบบขอบและ Auto Dodge เดิม
            if not bossGateId then
                destination = SafeFarmDestination(
                    zone.Id,
                    targetPart.Position,
                    destination,
                    reach
                )

                if not destination then
                    ClearTarget()
                    SetStatus(
                        "Farm: waiting for verified zone / floor"
                    )
                    return
                end

                -- จำฝั่งด้านในใหม่ ไม่ย้อนกลับไปฝั่งนอกขอบทุก Tick
                local offset = destination - targetPart.Position
                local flat = Vector3.new(offset.X, 0, offset.Z)

                if flat.Magnitude > 0.01 then
                    farmSideDirection = flat.Unit
                end
            end

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
            farmWalkSpeedActive = false
            if refreshFarmWalkSpeed then
                refreshFarmWalkSpeed()
            end

            CancelNativeFarmNav()
            FinishFarmTravel(true)
            ResetPull(true)

            if worker then
                task.cancel(worker)
                worker = nil
            end

            ClearTarget()
            ReleaseNativeWalk()
            SetStatus("Stopped")
        end

        local function Start()
            if not alive or enabled then return end

            if Options.ZeroXFly and Options.ZeroXFly.Value then
                Options.ZeroXFly:SetValue(false)
            end

            enabled = true
            farmWalkSpeedActive = true
            if refreshFarmWalkSpeed then
                refreshFarmWalkSpeed()
            end

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
                    farmWalkSpeedActive = false
                    if refreshFarmWalkSpeed then
                        refreshFarmWalkSpeed()
                    end

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

        section:AddSlider("ZeroXSpeed", {
            Title = "Speed Walk",
            Description = "ความเร็วเดินขณะเปิดฟาร์ม "
                .. "ปิดฟาร์มแล้วคืนความเร็วเดิม",
            Min = 17,
            Max = 24,
            Default = 20,
            Increment = 1,

            Callback = function()
                if refreshFarmWalkSpeed then
                    refreshFarmWalkSpeed()
                end
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

        section:AddToggle("ZeroXAutoFarm", {
            Title = "Auto Farm",
            Description = "เปิดฟาร์มและโจมตีตามเป้าหมาย",
            Default = false,
            Callback = function(value)
                if not alive then return end

                farmRequested = value == true

                if farmRequested or pumpkinEnabled
                    or partyFarmEnabled then
                    Start()
                else
                    Stop()
                end
            end,
        })

        local partyFarmSection = Tabs.Party:AddSection({
            Title = "Party Farming",
            Icon = "swords",
        })

        partyFarmSection:AddToggle("ZeroXFarmWithParty", {
            Title = "Farm With Party",
            Description = "ตามหัวหน้าปาร์ตี้และฟาร์มมอนรอบตัวหัวหน้า "
                .. "ใช้ระยะโจมตีและระบบลอยเดิม "
                .. "พักการลากมอนระหว่างเปิดใช้งาน",
            Default = false,

            Callback = function(value)
                if not alive then return end

                partyFarmEnabled = value == true
                partyFarmLeaderRoot = nil

                FinishFarmTravel(true)
                ResetPull(true)
                ClearTarget()

                if partyFarmEnabled
                    or farmRequested or pumpkinEnabled then
                    Start()
                else
                    Stop()
                end
            end,
        })

        partyFarmSection:AddSlider("ZeroXPartyFarmRadius", {
            Title = "Farm Radius",
            Description = "รัศมีเลือกมอนรอบหัวหน้า หน่วย studs "
                .. "เป็นค่าของสคริปต์ ไม่ใช่ระยะแชร์ EXP ของเกม",
            Min = 20,
            Max = 80,
            Default = 60,
            Increment = 5,

            Callback = function(value)
                if type(value) == "number"
                    and value >= 20 and value <= 80 then
                    partyFarmRadius = value
                end
            end,
        })

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
                    Description = "เมื่อตาย เลือกเกิดในเมืองแบบฟรี",
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
                local CONFIRM_TIMEOUT = 15

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
                    if bossDodgeActive then
                        BuyStatus("Waiting for boss dodge")
                        return false
                    end

                    if chestTripActive then
                        BuyStatus("Waiting for chest collection")
                        return false
                    end

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

                    -- ต้องอยู่ใกล้ Merchant ต่อเนื่องก่อนเปิดร้าน
                    -- เวลารอเป็นนโยบายของสคริปต์ ไม่ใช่ ACK จาก Server
                    local now = os.clock()

                    if distance > 12 then
                        trip.ShopNearSince = nil
                        trip.ShopOpenedAt = nil
                        return false
                    end

                    if LocalPlayer.GameplayPaused then
                        trip.ShopNearSince = nil
                        BuyStatus("Waiting for destination streaming")
                        return false
                    end

                    trip.ShopNearSince = trip.ShopNearSince or now

                    if now - trip.ShopNearSince < 1.5 then
                        BuyStatus("At Merchant: waiting for stable arrival")
                        return false
                    end

                    -- เปิดร้านครั้งเดียวต่อทริป
                    if not trip.ShopOpenedAt then
                        local openNpc = remotes:FindFirstChild("OpenNpc")

                        if not openNpc or not openNpc:IsA("RemoteEvent") then
                            BuyStatus("OpenNpc unavailable")

                            if now - trip.StartedAt >= 20 then
                                paused = true
                                FinishPotionTrip(true)
                                BuyStatus("Stopped: OpenNpc unavailable")
                            end

                            return false
                        end

                        local sent, err = pcall(function()
                            openNpc:FireServer("merchant")
                        end)

                        if not sent then
                            paused = true
                            FinishPotionTrip(true)
                            BuyStatus("Cannot open Merchant: " .. tostring(err))
                            return false
                        end

                        trip.ShopOpenedAt = now
                        BuyStatus("Merchant interaction requested; waiting before purchase")
                        return false
                    end

                    if now - trip.ShopOpenedAt < 1 then
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

                        if old
                            and LocalPlayer.Character == old.Character then
                            local humanoid = old.Character
                                :FindFirstChildOfClass("Humanoid")

                            if humanoid and humanoid.Health > 0
                                and old.Root.Parent then
                                humanoid:MoveTo(old.Root.Position)
                                humanoid:Move(Vector3.zero, false)
                            end
                        end

                        dropTripActive = false

                        -- ไม่วาปกลับ
                        -- Auto Farm จะรับช่วงต่อในรอบถัดไป
                    end

                    local function DropAllowed(drop, folder)
                        if not drop:IsDescendantOf(folder) then
                            return false
                        end

                        if not InCurrentActionZone(drop.Position) then
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
                            or chestTripActive or bossDodgeActive
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
                            if not trip.Zone
                                or trip.Zone ~= GetActionZone() then
                                FinishDropTrip(false)
                                return
                            end

                            local drop = trip.Drop

                            if not DropAllowed(drop, folder) then
                                -- ของหายไม่ได้ยืนยันว่าเราเป็นคนเก็บ
                                FinishDropTrip(true)
                                return
                            end

                            if now - trip.StartedAt >= 45 then
                                retryAt[drop] = now + RETRY_DELAY
                                FinishDropTrip(true)
                                return
                            end

                            if LocalPlayer:GetAttribute("AutoOn") == true then
                                return
                            end

                            local distance =
                                (drop.Position - root.Position).Magnitude

                            if distance > math.max(0.5, reach - 1) then
                                if now - (trip.LastMoveAt or -math.huge)
                                    >= 1 then
                                    trip.LastMoveAt = now

                                    humanoid:MoveTo(Vector3.new(
                                        drop.Position.X,
                                        root.Position.Y,
                                        drop.Position.Z
                                    ))
                                end

                                return
                            end

                            humanoid:MoveTo(root.Position)
                            humanoid:Move(Vector3.zero, false)

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
                            Zone = GetActionZone(),
                            Root = root,
                            Origin = root.CFrame,
                            Drop = nearest,
                            StartedAt = now,
                            AutoWasOn = autoOn,
                        }

                        dropTripActive = true

                        CancelNativeFarmNav()
                        FinishFarmTravel(false)
                        ResetPull(false)
                        ClearTarget()
                        StopFarmHover()

                        if autoOn
                            and LocalPlayer:GetAttribute("AutoOn") == true then
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

        (function()
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
                local SELL_ARRIVAL_DELAY = 1.5
                local SELL_MERCHANT_DISTANCE = 12

                local function FinishSellTrip(returnToOrigin)
                    local old = sellTrip
                    sellTrip = nil

                    if not old then
                        sellTripActive = false
                        return
                    end

                    StopFarmHover()

                    local sameCharacter =
                        LocalPlayer.Character == old.Character
                    local humanoid = sameCharacter
                        and old.Character:FindFirstChildOfClass("Humanoid")

                    local valid = humanoid
                        and humanoid.Health > 0
                        and old.Root.Parent
                        and not old.Root.Anchored

                    if returnToOrigin and valid and old.Moved then
                        humanoid:MoveTo(old.Root.Position)
                        humanoid:Move(Vector3.zero, false)

                        old.Root.CFrame = old.Origin
                        old.Root.AssemblyLinearVelocity = Vector3.zero
                        old.Root.AssemblyAngularVelocity = Vector3.zero
                    end

                    sellTripActive = false

                    if returnToOrigin and valid and alive
                        and old.AutoWasOn
                        and not potionTripActive
                        and not dropTripActive
                        and not chestTripActive
                        and not farmTravelActive then

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

                    if sellTrip and (
                        sellTrip.Character ~= character
                        or sellTrip.Root ~= root
                    ) then
                        FinishSellTrip(false)
                        return false
                    end

                    if not sellTrip then
                        sellTrip = {
                            Character = character,
                            Root = root,
                            Origin = root.CFrame,
                            AutoWasOn =
                                LocalPlayer:GetAttribute("AutoOn") == true,
                            StartedAt = os.clock(),
                            Moved = false,
                        }

                        humanoid:MoveTo(root.Position)
                        humanoid:Move(Vector3.zero, false)

                        sellTripActive = true

                        -- หยุดเส้นทางฟาร์มก่อนเริ่มกลับเมือง
                        CancelNativeFarmNav()
                        FinishFarmTravel(false)
                        ResetPull(false)
                        ClearTarget()
                        StopFarmHover()
                    end

                    local trip = sellTrip
                    local now = os.clock()

                    -- เวลานี้เป็นนโยบายของสคริปต์
                    if now - trip.StartedAt >= 20 then
                        blocked = true
                        FinishSellTrip(true)
                        SellStatus(
                            "Paused: Merchant trip timed out"
                        )
                        return false
                    end

                    if root.Anchored then
                        SellStatus("Waiting: character anchored")
                        return false
                    end

                    if LocalPlayer:GetAttribute("AutoOn") == true then
                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if not menu or not menu:IsA("BindableEvent") then
                            SellStatus("Waiting for native Auto control")
                            return false
                        end

                        if now - (trip.LastAutoRequest or -math.huge)
                            >= 1 then
                            trip.LastAutoRequest = now
                            menu:Fire("autoToggle")
                        end

                        SellStatus("Waiting for native Auto to stop")
                        return false
                    end


                    -- ค้นจาก NpcId ไม่ผูกกับตัวพิมพ์ของชื่อ Model
                    local merchant = trip.Merchant

                    if not merchant
                        or not merchant:IsDescendantOf(workspace) then
                        merchant = nil

                        local map = workspace:FindFirstChild("Map")
                        local npcs = map and map:FindFirstChild("NPCs")

                        if npcs then
                            for _, npc in ipairs(npcs:GetChildren()) do
                                if npc:IsA("Model")
                                    and npc:GetAttribute("NpcId")
                                        == "merchant" then
                                    merchant = npc
                                    break
                                end
                            end
                        end

                        trip.Merchant = merchant
                    end

                    if not merchant then
                        SellStatus("In town: waiting for Merchant")
                        return false
                    end

                    local pivot = merchant:GetPivot()
                    local distance =
                        (root.Position - pivot.Position).Magnitude

                    local destination =
                        (pivot * CFrame.new(0, 0, 4)).Position
                    local facing =
                        CFrame.lookAt(destination, pivot.Position)

                    if not trip.Moved
                        or distance > SELL_MERCHANT_DISTANCE then
                        trip.ArrivedAt = nil

                        humanoid:MoveTo(root.Position)
                        humanoid:Move(Vector3.zero, false)

                        root.CFrame = facing
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        trip.Moved = true

                        HoldFarmPosition(
                            humanoid, root, destination, facing
                        )

                        SellStatus("Moved to Merchant; checking arrival")
                        return false
                    end

                    HoldFarmPosition(
                        humanoid, root, destination, facing
                    )

                    trip.ArrivedAt = trip.ArrivedAt or now
                    local remaining = SELL_ARRIVAL_DELAY
                        - (now - trip.ArrivedAt)

                    if remaining > 0 then
                        SellStatus(string.format(
                            "At Merchant; selling in %.1fs",
                            remaining
                        ))
                        return false
                    end

                    return true
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
                        or dropTripActive or farmTravelActive
                        or chestTripActive or bossDodgeActive then
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
        end)()

        do
            local chestSection = Tabs.Event:AddSection({
                Title = "World Chests",
                Icon = "gift",
            })

            local chestInputStatus = chestSection:AddLabel({
                Title = "Interaction",
                Value = "รอเปิดใช้งาน",
            })



            local halloweenSection = Tabs.Event:AddSection({
                Title = "Halloween",
                Icon = "gift",
            })


            halloweenSection:AddToggle("ZeroXAutoBossHalloween", {
                Title = "Auto Boss Halloween",
                Description = "ตีบอส Pumpkin Spider ออโต้",
                Default = false,

                Callback = function(value)
                    if not alive then return end

                    pumpkinEnabled = value == true

                    FinishFarmTravel(true)
                    ResetPull(true)
                    ClearTarget()

                    if pumpkinEnabled or farmRequested
                        or partyFarmEnabled then
                        Start()
                    else
                        Stop()
                    end
                end,
            })

            local inputAvailable, virtualInput = pcall(function()
                return game:GetService("VirtualInputManager")
            end)

            if not inputAvailable then
                chestInputStatus:SetValue("ไม่สามารถเข้าถึงระบบจำลองปุ่ม")
            end

            if inputAvailable and virtualInput then
                local chestEnabled = false
                local chestWorker
                local chestTrip
                local chests = {}
                local retryAt = setmetatable({}, { __mode = "k" })
                local lastSend = -math.huge

                local promptService =
                    game:GetService("ProximityPromptService")
                local inputService =
                    game:GetService("UserInputService")

                local shownPrompts = setmetatable(
                    {}, { __mode = "k" }
                )

                local keyDown = false
                local releaseTask

                Connect(promptService.PromptShown, function(prompt)
                    shownPrompts[prompt] = true
                end)

                Connect(promptService.PromptHidden, function(prompt)
                    shownPrompts[prompt] = nil
                end)

                local function ReleaseChestKey()
                    if releaseTask then
                        task.cancel(releaseTask)
                        releaseTask = nil
                    end

                    if not keyDown then return end

                    local ok, err = pcall(function()
                        virtualInput:SendKeyEvent(
                            false, Enum.KeyCode.E, false, game
                        )
                    end)

                    if ok then
                        keyDown = false
                    else
                        chestInputStatus:SetValue(
                            "ปล่อย E ไม่สำเร็จ: " .. tostring(err)
                        )
                    end
                end

                local function ChestPromptVisible(prompt, part)
                    if shownPrompts[prompt] then return true end

                    -- รองรับ Prompt ที่แสดงอยู่ก่อนเริ่มติดตาม Event
                    local playerGui =
                        LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    local gui = playerGui
                        and playerGui:FindFirstChild("HuntBoxPrompt")

                    return gui and gui:IsA("BillboardGui")
                        and gui.Enabled and gui.Adornee == part
                end

                -- ค่านโยบายของสคริปต์
                local SEARCH_RADIUS = 120
                local RESULT_TIMEOUT = 2
                local RETRY_DELAY = 10

                local function Finite(value)
                    return type(value) == "number"
                        and value == value
                        and math.abs(value) < math.huge
                end

                local function ChestPart(box)
                    if not box:IsDescendantOf(workspace)
                        or not CollectionService:HasTag(box, "LootBox") then
                        return nil
                    end

                    local part

                    if box:IsA("BasePart") then
                        part = box
                    elseif box:IsA("Model") then
                        part = box.PrimaryPart
                            or box:FindFirstChildWhichIsA("BasePart")
                    end

                    if not part or not part:IsA("BasePart")
                        or not part:IsDescendantOf(workspace) then
                        return nil
                    end

                    if not InCurrentActionZone(part.Position) then
                        return nil
                    end

                    local owner = box:GetAttribute("OwnerUserId")
                    local freeAt = box:GetAttribute("FreeAt") or 0

                    if not Finite(freeAt) then return nil end

                    if owner ~= 0 and owner ~= LocalPlayer.UserId
                        and freeAt > workspace:GetServerTimeNow() then
                        return nil
                    end

                    return part
                end

                local function AddChest(box)
                    if box:IsA("BasePart") or box:IsA("Model") then
                        chests[box] = true
                    end
                end

                Connect(
                    CollectionService:GetInstanceAddedSignal("LootBox"),
                    AddChest
                )

                Connect(
                    CollectionService:GetInstanceRemovedSignal("LootBox"),
                    function(box)
                        chests[box] = nil
                    end
                )

                for _, box in ipairs(
                    CollectionService:GetTagged("LootBox")
                ) do
                    AddChest(box)
                end

                local function FinishChestTrip(returnToOrigin)
                    ReleaseChestKey()

                    local old = chestTrip
                    chestTrip = nil

                    if not old then
                        chestTripActive = false
                        return
                    end

                    StopFarmHover()

                    local humanoid = old.Character
                        :FindFirstChildOfClass("Humanoid")

                    local valid = LocalPlayer.Character == old.Character
                        and humanoid and humanoid.Health > 0
                        and old.Root.Parent
                        and not old.Root.Anchored

                    if valid then
                        humanoid:MoveTo(old.Root.Position)
                        humanoid:Move(Vector3.zero, false)
                    end

                    chestTripActive = false

                    if returnToOrigin and valid and alive
                        and old.AutoWasOn
                        and not potionTripActive
                        and not sellTripActive
                        and not dropTripActive
                        and not farmTravelActive then

                        local menu =
                            LocalPlayer:FindFirstChild("LumiMenuToggle")

                        if menu and menu:IsA("BindableEvent")
                            and LocalPlayer:GetAttribute("AutoOn") ~= true then
                            menu:Fire("autoToggle")
                        end
                    end
                end

                local function CheckChests()

                    if potionTripActive or sellTripActive
                        or dropTripActive or farmTravelActive
                        or bossDodgeActive
                        or (Options.ZeroXFly
                            and Options.ZeroXFly.Value) then
                        FinishChestTrip(true)
                        return
                    end

                    local character = LocalPlayer.Character
                    local humanoid = character
                        and character:FindFirstChildOfClass("Humanoid")
                    local root = humanoid and humanoid.RootPart

                    if not humanoid or humanoid.Health <= 0
                        or not root or not root:IsA("BasePart")
                        or not root.Parent then
                        FinishChestTrip(false)
                        return
                    end

                    if chestTrip and (
                        chestTrip.Character ~= character
                        or chestTrip.Root ~= root
                    ) then
                        FinishChestTrip(false)
                        return
                    end

                    if root.Anchored then
                        FinishChestTrip(true)
                        return
                    end

                    local used = LocalPlayer:GetAttribute("BagSlotsUsed")
                    local maximum = LocalPlayer:GetAttribute("BagSlotsMax")

                    if not Finite(used) or not Finite(maximum)
                        or maximum <= 0 or used >= maximum then
                        FinishChestTrip(true)
                        return
                    end

                    local now = os.clock()

                    if chestTrip then
                        local trip = chestTrip

                        if not trip.Zone
                            or trip.Zone ~= GetActionZone() then
                            FinishChestTrip(false)
                            return
                        end

                        local part = ChestPart(trip.Box)

                        if not part then
                            -- กล่องหายไม่ยืนยันว่าเราเป็นคนได้รับรางวัล
                            FinishChestTrip(true)
                            return
                        end

                        if now - trip.StartedAt >= 45
                            or (trip.SentAt
                                and now - trip.SentAt >= RESULT_TIMEOUT) then
                            retryAt[trip.Box] = now + RETRY_DELAY
                            FinishChestTrip(true)
                            return
                        end

                        if LocalPlayer:GetAttribute("AutoOn") == true then
                            return
                        end

                        if now < skillCastUntil then
                            chestInputStatus:SetValue(
                                "พบกล่องแล้ว รอร่ายจบก่อนเดินทาง"
                            )
                            return
                        end

                        local openPrompt =
                            part:FindFirstChild("OpenPrompt")

                        local walkReach = 6

                        if openPrompt
                            and openPrompt:IsA("ProximityPrompt") then
                            walkReach = math.max(
                                0.5,
                                math.min(
                                    walkReach,
                                    openPrompt.MaxActivationDistance - 1
                                )
                            )
                        end

                        local distance =
                            (part.Position - root.Position).Magnitude

                        if distance > walkReach then
                            if now - (trip.LastMoveAt or -math.huge)
                                >= 1 then
                                trip.LastMoveAt = now

                                humanoid:MoveTo(Vector3.new(
                                    part.Position.X,
                                    root.Position.Y,
                                    part.Position.Z
                                ))
                            end

                            chestInputStatus:SetValue(
                                "กำลังเดินไปเปิดกล่อง"
                            )
                            return
                        end

                        humanoid:MoveTo(root.Position)
                        humanoid:Move(Vector3.zero, false)

                        if not trip.SentAt and now - lastSend >= 0.5 then
                            local prompt = part:FindFirstChild("OpenPrompt")

                            if not prompt
                                or not prompt:IsA("ProximityPrompt") then
                                chestInputStatus:SetValue(
                                    "รอ OpenPrompt ของกล่องโหลด"
                                )
                                return
                            end

                            if not promptService.Enabled
                                or not prompt.Enabled
                                or prompt.KeyboardKeyCode
                                    ~= Enum.KeyCode.E
                                or prompt.HoldDuration ~= 0 then
                                chestInputStatus:SetValue(
                                    "Prompt ยังไม่พร้อม หรือไม่ใช่ E แบบแตะ"
                                )
                                return
                            end

                            if inputService:GetFocusedTextBox() then
                                chestInputStatus:SetValue(
                                    "รอออกจากช่องพิมพ์ข้อความ"
                                )
                                return
                            end

                            if (root.Position - part.Position).Magnitude
                                > prompt.MaxActivationDistance then
                                chestInputStatus:SetValue(
                                    "อยู่นอกระยะ OpenPrompt"
                                )
                                return
                            end

                            if not ChestPromptVisible(prompt, part) then
                                chestInputStatus:SetValue(
                                    "รอป้าย E ของกล่องเป้าหมาย"
                                )
                                return
                            end

                            -- E เป็นปุ่มรวม ตรวจ Prompt อื่นที่อาจแย่งปุ่ม
                            for other in pairs(shownPrompts) do
                                if other ~= prompt
                                    and other.Parent
                                    and other.Enabled
                                    and other.KeyboardKeyCode
                                        == Enum.KeyCode.E then
                                    chestInputStatus:SetValue(
                                        "มี Prompt E อื่นใกล้เคียง"
                                    )
                                    return
                                end
                            end

                            if keyDown then
                                ReleaseChestKey()
                                return
                            end

                            keyDown = true

                            local ok, err = pcall(function()
                                virtualInput:SendKeyEvent(
                                    true, Enum.KeyCode.E, false, game
                                )
                            end)

                            if not ok then
                                ReleaseChestKey()
                                chestEnabled = false
                                FinishChestTrip(true)
                                chestInputStatus:SetValue(
                                    "กด E ไม่สำเร็จ: " .. tostring(err)
                                )
                                return
                            end

                            -- ระยะกดของสคริปต์ สำหรับ Prompt แบบ Instant Tap
                            releaseTask = task.delay(0.05, function()
                                releaseTask = nil
                                ReleaseChestKey()
                            end)

                            lastSend = now
                            trip.SentAt = now

                            chestInputStatus:SetValue(
                                "ส่งปุ่ม E แล้ว รอตรวจผลจากกล่อง"
                            )
                        end
                        return
                    end

                    if now - lastSend < 0.5 then return end

                    local nearest
                    local distanceLimit = SEARCH_RADIUS

                    for box in pairs(chests) do
                        if now < (retryAt[box] or 0) then continue end

                        local part = ChestPart(box)
                        if part then
                            local distance =
                                (part.Position - root.Position).Magnitude

                            if distance < distanceLimit then
                                nearest = box
                                distanceLimit = distance
                            end
                        end
                    end

                    if not nearest then
                        chestInputStatus:SetValue(
                            "ไม่พบกล่องที่มีสิทธิ์เปิดในระยะ "
                                .. tostring(SEARCH_RADIUS)
                        )
                        return
                    end

                    local nativeRunning =
                        LocalPlayer:GetAttribute("AutoOn") == true

                    -- Pull อาจพัก Native Auto ไว้อยู่แล้ว
                    local autoOn = nativeRunning
                        or (
                            pullSession ~= nil
                            and pullSession.AutoWasOn == true
                        )
                    local menu =
                        LocalPlayer:FindFirstChild("LumiMenuToggle")

                    if autoOn and not (
                        menu and menu:IsA("BindableEvent")
                    ) then
                        return
                    end

                    chestTrip = {
                        Box = nearest,
                        Character = character,
                        Zone = GetActionZone(),
                        Root = root,
                        Origin = root.CFrame,
                        AutoWasOn = autoOn,
                        -- ไม่นับช่วงร่ายที่เหลือเป็นเวลารอเปิดกล่อง
                        StartedAt = math.max(now, skillCastUntil),
                    }

                    chestTripActive = true

                    CancelNativeFarmNav()
                    FinishFarmTravel(false)
                    ResetPull(false)
                    ClearTarget()
                    StopFarmHover()

                    if nativeRunning
                        and LocalPlayer:GetAttribute("AutoOn") == true then
                        menu:Fire("autoToggle")
                    end

                    chestInputStatus:SetValue(
                        "พบกล่องแล้ว พักฟาร์มเพื่อไปเปิด"
                    )
                end

                local function StopChestWorker()
                    chestEnabled = false

                    if chestWorker then
                        task.cancel(chestWorker)
                        chestWorker = nil
                    end

                    FinishChestTrip(true)
                end

                Connect(LocalPlayer.CharacterRemoving, function()
                    FinishChestTrip(false)
                end)

                chestSection:AddToggle("ZeroXAutoOpenChest", {
                    Title = "Auto Open Chest",
                    Description = "พักฟาร์มแล้วเดินไปกด E เปิดกล่อง "
                        .. "เสร็จแล้วฟาร์มต่อโดยไม่วาปกลับ",
                    Default = false,

                    Callback = function(value)
                        StopChestWorker()
                        if not alive or value ~= true then return end

                        chestEnabled = true

                        chestWorker = task.defer(function()
                            local ok, err = xpcall(function()
                                while alive and chestEnabled do
                                    CheckChests()
                                    task.wait(0.2)
                                end
                            end, debug.traceback)

                            chestWorker = nil

                            if not ok then
                                chestEnabled = false
                                FinishChestTrip(true)
                                warn("[Zero X / Chest] "
                                    .. tostring(err))
                            end
                        end)
                    end,
                })

                MacUI:OnUnload(function()
                    StopChestWorker()
                    table.clear(chests)
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
        local needed = farmWalkSpeedActive or state.Noclip
            or state.Fly or state.DisableAnimations

        if not farmWalkSpeedActive then
            Restore(speedSaved)
        end
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

            if farmWalkSpeedActive then
                local option = Options.ZeroXSpeed
                local speed = option and option.Value

                if type(speed) == "number"
                    and speed == speed
                    and speed >= 1 and speed <= 200 then
                    Patch(speedSaved, humanoid, "WalkSpeed", speed)
                end
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

    refreshFarmWalkSpeed = function()
        if alive then
            UpdateMotion()
        end
    end

    refreshFarmWalkSpeed()

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

do
    local function InitAutoQuest()
        local RS = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")

        local section = Tabs.AutoFarm:AddSection({
            Title = "Auto Quest",
            Icon = "scroll-text",
        })

        local status = section:AddLabel({
            Title = "Quest Status",
            Value = "ปิดใช้งาน",
        })

        local lastStatus
        local function Report(message)
            if message ~= lastStatus then
                lastStatus = message
                status:SetValue(message)
            end
        end

        local shared = RS:WaitForChild("Shared", 5)
        local remotes = RS:WaitForChild("Remotes", 5)
        local module = shared and shared:WaitForChild("QuestData", 5)

        if not module or not module:IsA("ModuleScript")
            or not remotes then
            Report("ไม่พบ QuestData / Remotes")
            return
        end

        local ok, questData = pcall(require, module)

        if not ok or type(questData) ~= "table"
            or type(questData.Quests) ~= "table" then
            Report("อ่าน QuestData.Quests ไม่ได้")
            return
        end

        local alive = true
        local enabled = false
        local mode = "By Level"
        local selectedId
        local allowSwitch = false
        local connections = {}

        local catalog = {}
        local choices = {}
        local labelToId = {}
        local activeQuests
        local pending
        local attempts = {}

        -- ค่าของสคริปต์ ไม่ใช่ Cooldown ที่เซิร์ฟเวอร์กำหนด
        local ACK_TIMEOUT = 5
        local RETRY_DELAY = 15
        local MAX_ATTEMPTS = 3

        local function NumberOK(value)
            return type(value) == "number"
                and value == value
                and math.abs(value) < math.huge
        end

        local entries = {}

        for id, def in pairs(questData.Quests) do
            if type(id) == "string"
                and type(def) == "table"
                and def.Repeat == true
                and NumberOK(def.ReqLevel)
                and def.ReqLevel >= 0 then

                catalog[id] = def
                table.insert(entries, {
                    Id = id,
                    Def = def,
                })
            end
        end

        table.sort(entries, function(a, b)
            if a.Def.ReqLevel ~= b.Def.ReqLevel then
                return a.Def.ReqLevel < b.Def.ReqLevel
            end
            return a.Id < b.Id
        end)

        for _, entry in ipairs(entries) do
            local name = type(entry.Def.Name) == "string"
                and entry.Def.Name or entry.Id

            local label = string.format(
                "Lv.%d | %s [%s]",
                entry.Def.ReqLevel,
                name,
                entry.Id
            )

            labelToId[label] = entry.Id
            table.insert(choices, label)
        end

        if #choices == 0 then
            Report("ไม่พบเควสที่ Repeat == true")
            return
        end

        local function ReadState()
            activeQuests = nil

            local raw = LocalPlayer:GetAttribute("QuestsJson")
            if type(raw) ~= "string" or raw == "" then return end

            local success, data = pcall(
                HttpService.JSONDecode, HttpService, raw
            )

            if not success or type(data) ~= "table"
                or type(data.Active) ~= "table" then
                return
            end

            for id, progress in pairs(data.Active) do
                if type(id) ~= "string"
                    or not NumberOK(progress)
                    or progress < 0 then
                    return
                end
            end

            activeQuests = data.Active
        end

        local function ResetAttempts()
            -- ไม่ล้างคำขอที่ยังรอยืนยัน เพื่อไม่ส่งซ้อนทันที
            table.clear(attempts)
        end

        local function Step()
            if not alive or not enabled then return end

            if not activeQuests then
                Report("รอข้อมูล QuestsJson ที่ถูกต้อง")
                return
            end

            local now = os.clock()

            if pending then
                if activeQuests[pending.Id] ~= nil then
                    attempts[pending.Id] = nil
                    pending = nil
                elseif now - pending.SentAt < ACK_TIMEOUT then
                    Report("รอยืนยันการรับ: " .. pending.Id)
                    return
                else
                    local request = attempts[pending.Id]

                    if request then
                        request.NextAt = now + RETRY_DELAY
                    end

                    Report(
                        "ยังไม่ยืนยันการรับ: " .. pending.Id
                            .. " — ไม่ถือว่าเซิร์ฟเวอร์ปฏิเสธ"
                    )

                    pending = nil
                    return
                end
            end

            local level = LocalPlayer:GetAttribute("Level")
            if not NumberOK(level) then
                Report("รอข้อมูล Level")
                return
            end

            local id

            if mode == "Select Quest" then
                id = selectedId

                if not id or not catalog[id] then
                    Report("เลือก Repeat Quest ก่อน")
                    return
                end
            else
                local bestLevel = -math.huge

                for _, entry in ipairs(entries) do
                    local required = entry.Def.ReqLevel

                    if required <= level and required > bestLevel then
                        bestLevel = required
                        id = entry.Id
                    end
                end
            end

            local def = id and catalog[id]

            if not def then
                Report("ยังไม่มี Repeat Quest ที่รับได้ตามเลเวล")
                return
            end

            if level < def.ReqLevel then
                Report("ต้องการเลเวล " .. tostring(def.ReqLevel))
                return
            end

            local progress = activeQuests[id]

            if progress ~= nil then
                attempts[id] = nil

                if NumberOK(def.Count) and progress >= def.Count then
                    Report(id .. " สำเร็จแล้ว — กดรับรางวัลในเกมเอง")
                else
                    Report(string.format(
                        "%s | %s / %s",
                        id,
                        tostring(progress),
                        tostring(def.Count or "?")
                    ))
                end

                return
            end

            local otherRepeat

            for activeId in pairs(activeQuests) do
                local activeDef = questData.Quests[activeId]

                if type(activeDef) == "table"
                    and activeDef.Repeat == true then
                    otherRepeat = activeId
                    break
                end
            end

            if otherRepeat and not allowSwitch then
                Report(
                    "มี Repeat อยู่แล้ว: " .. otherRepeat
                        .. " — รอจบหรือเปิด Switch Active Repeat"
                )
                return
            end

            local request = attempts[id]

            if request then
                if request.Count >= MAX_ATTEMPTS then
                    Report(
                        "หยุดลองรับ " .. id
                            .. " หลังไม่ยืนยัน 3 ครั้ง — ปิด/เปิด Auto Quest เพื่อลองใหม่"
                    )
                    return
                end

                if now < request.NextAt then
                    Report("รอลองรับใหม่: " .. id)
                    return
                end
            end

            local remote = remotes:FindFirstChild("QuestAction")

            if not remote or not remote:IsA("RemoteEvent") then
                Report("ไม่พบ QuestAction ที่เป็น RemoteEvent")
                return
            end

            request = request or {
                Count = 0,
                NextAt = 0,
            }

            request.Count += 1
            request.NextAt = now + ACK_TIMEOUT + RETRY_DELAY
            attempts[id] = request

            pending = {
                Id = id,
                SentAt = now,
            }

            remote:FireServer("accept", id)
            Report("ส่งคำขอรับ: " .. id .. " — รอ QuestsJson ยืนยัน")
        end

        section:AddDropdown("ZeroXQuestMode", {
            Title = "Quest Mode",
            Description = "By Level: เลือก Repeat ที่เลเวลรับได้สูงสุด "
                .. "Select Quest: เลือกเควสเอง",
            Values = { "By Level", "Select Quest" },
            Default = "By Level",

            Callback = function(value)
                if not alive
                    or (value ~= "By Level"
                        and value ~= "Select Quest") then
                    return
                end

                mode = value
                ResetAttempts()
            end,
        })

        section:AddDropdown("ZeroXRepeatQuest", {
            Title = "Select Repeat Quest",
            Description = "แสดงเฉพาะ Repeat ใช้เมื่อเลือก Select Quest",
            Values = choices,
            AllowNull = true,
            Searchable = true,

            Callback = function(value)
                if not alive then return end
                selectedId = labelToId[value]
                ResetAttempts()
            end,
        })

        section:AddToggle("ZeroXQuestSwitchRepeat", {
            Title = "Switch Active Repeat",
            Description = "อนุญาตรับ Repeat ใหม่แทนเควสเดิม",
            Default = false,

            Callback = function(value)
                if not alive then return end
                allowSwitch = value == true
                ResetAttempts()
            end,
        })

        section:AddToggle("ZeroXAutoQuest", {
            Title = "Auto Quest",
            Description = "ออโต้รับเฉพาะ Repeat เควสเท่านั้น",
            Default = false,

            Callback = function(value)
                if not alive then return end

                enabled = value == true
                ResetAttempts()

                if not enabled then
                    Report("ปิดใช้งาน")
                end
            end,
        })

        table.insert(connections,
            LocalPlayer:GetAttributeChangedSignal("QuestsJson"):Connect(
                function()
                    if alive then ReadState() end
                end
            )
        )

        ReadState()

        local worker = task.spawn(function()
            while alive do
                task.wait(1)

                if alive and enabled then
                    Step()
                end
            end
        end)

        MacUI:OnUnload(function()
            alive = false
            enabled = false

            task.cancel(worker)

            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end

            table.clear(connections)
        end)
    end

    InitAutoQuest()
end

do
    local RS = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")

    local alive = true
    local rewardsEnabled = false
    local bookEnabled = false
    local nextScan = 0
    local attempts = {}
    local jsonCache = {}
    local moduleCache = {}
    local connections = {}

    local rewardsSection = Tabs.Reward:AddSection({
        Title = "Free Rewards",
        Icon = "gift",
    })

    local rewardStatus = {
        SetValue = function() end,
    }

    local bookSection = Tabs.Reward:AddSection({
        Title = "Adventure Book",
        Icon = "book-open",
    })

    local bookStatus = {
        SetValue = function() end,
    }

    local function Finite(value)
        return type(value) == "number"
            and value == value
            and math.abs(value) < math.huge
    end

    local function CharacterAlive()
        local character = LocalPlayer.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        return humanoid ~= nil and humanoid.Health > 0
    end

    local function FindRemote(name, className)
        local remotes = RS:FindFirstChild("Remotes")
        local object = remotes and remotes:FindFirstChild(name)

        if object and object:IsA(className) then
            return object
        end
        return nil
    end

    local function ReadJson(attribute)
        local raw = LocalPlayer:GetAttribute(attribute)
        local cached = jsonCache[attribute]

        if cached and cached.Raw == raw then
            return cached.Data
        end

        local data
        if type(raw) == "string" and raw ~= "" then
            local ok, result = pcall(function()
                return HttpService:JSONDecode(raw)
            end)

            if ok and type(result) == "table" then
                data = result
            end
        end

        jsonCache[attribute] = { Raw = raw, Data = data }
        return data
    end

    local function ReadModule(name)
        local shared = RS:FindFirstChild("Shared")
        local object = shared and shared:FindFirstChild(name)

        if not object or not object:IsA("ModuleScript") then
            return nil
        end

        local cached = moduleCache[name]
        if cached and cached.Object == object then
            if cached.Data then return cached.Data end
            if os.clock() < cached.RetryAt then return nil end
        end

        local ok, result = pcall(require, object)
        local data = ok and type(result) == "table" and result or nil

        moduleCache[name] = {
            Object = object,
            Data = data,
            RetryAt = os.clock() + 10,
        }
        return data
    end

    -- ค่าลองซ้ำของสคริปต์ ไม่ใช่ rate limit ที่ยืนยันจาก Server
    local function RequestClaim(key, remoteName, args, label)
        local now = os.clock()
        local previous = attempts[key]

        if previous and (
            previous.Count >= 3 or now < previous.RetryAt
        ) then
            return false
        end

        local remote = FindRemote(remoteName, "RemoteEvent")
        if not remote then
            label:SetValue("รอ " .. remoteName)
            return false
        end

        local count = previous and previous.Count + 1 or 1
        attempts[key] = {
            Count = count,
            RetryAt = now + 10,
        }

        remote:FireServer(table.unpack(args, 1, args.n))
        label:SetValue("ส่งคำขอ: " .. key .. " | " .. count .. "/3")
        return true
    end

    local function CollectFreeRewards()
        local daily = ReadJson("DailyJson")

        if daily and daily.CanClaim == true
            and Finite(daily.Day) then
            if RequestClaim(
                "daily:" .. tostring(daily.Day),
                "DailyClaim",
                table.pack(),
                rewardStatus
            ) then return true end
        end

        local data = ReadJson("RewardsJson")
        if not data then return false end

        local online = data.Online
        local definitions = ReadModule("RewardData")

        if type(online) == "table"
            and type(online.Got) == "table"
            and Finite(online.Sec)
            and definitions
            and type(definitions.Online) == "table" then

            local elapsed = 0
            if Finite(online.At) then
                elapsed = math.max(
                    0, workspace:GetServerTimeNow() - online.At
                )
            end

            local seconds = online.Sec + math.min(elapsed, 75)

            for index = 1, 6 do
                local def = definitions.Online[index]

                if type(def) == "table"
                    and Finite(def.Minutes) and def.Minutes >= 0
                    and not table.find(online.Got, index)
                    and seconds >= def.Minutes * 60 then
                    if RequestClaim(
                        "online:" .. index,
                        "RewardAction",
                        table.pack("online", index),
                        rewardStatus
                    ) then return true end
                end
            end
        end

        local c8 = data.C8
        if type(c8) == "table" and c8.Can == true
            and Finite(c8.Day)
            and c8.Day >= 1 and c8.Day <= 8
            and c8.Day % 1 == 0 then
            if RequestClaim(
                "c8:" .. c8.Day,
                "RewardAction",
                table.pack("c8", nil),
                rewardStatus
            ) then return true end
        end

        local month = data.Month
        if type(month) == "table"
            and type(month.Days) == "table"
            and Finite(month.Today)
            and month.Today >= 1 and month.Today <= 31
            and month.Today % 1 == 0
            and not table.find(month.Days, month.Today) then

            local monthKey = os.date(
                "!%Y-%m", workspace:GetServerTimeNow()
            )

            if RequestClaim(
                "month:" .. monthKey .. ":" .. month.Today,
                "RewardAction",
                table.pack("month", nil),
                rewardStatus
            ) then return true end
        end

        return false
    end

    local function CollectBook()
        local data = ReadJson("AchieveJson")
        local definitions = ReadModule("AchievementData")
        local level = LocalPlayer:GetAttribute("Level")

        if not data or type(data.Got) ~= "table"
            or type(data.C) ~= "table"
            or not definitions
            or type(definitions.List) ~= "table" then
            return false
        end

        for _, def in pairs(definitions.List) do
            if type(def) ~= "table"
                or type(def.Id) ~= "string"
                or type(def.Type) ~= "string"
                or not Finite(def.Count)
                or data.Got[def.Id] == true then
                continue
            end

            local progress
            if def.Type == "level" then
                progress = level
            else
                progress = data.C[def.Type]
                if progress == nil then progress = 0 end
            end

            if Finite(progress) and progress >= def.Count then
                if RequestClaim(
                    "book:" .. def.Id,
                    "AchieveAction",
                    table.pack("claim", def.Id, false),
                    bookStatus
                ) then return true end
            end
        end

        return false
    end

    local function ResetAttempts(prefix)
        for key in pairs(attempts) do
            if key:sub(1, #prefix) == prefix then
                attempts[key] = nil
            end
        end
        nextScan = 0
    end

    rewardsSection:AddToggle("ZeroXAutoCollectReward", {
        Title = "Auto Collect Reward",
        Description = "รับ Daily Login, Online Reward, "
            .. "เช็กอิน 8 วัน และปฏิทินรายเดือน เฉพาฐส่วนฟรี",
        Default = false,

        Callback = function(value)
            rewardsEnabled = value == true

            ResetAttempts("daily:")
            ResetAttempts("online:")
            ResetAttempts("c8:")
            ResetAttempts("month:")

            rewardStatus:SetValue(
                rewardsEnabled and "รอตรวจรางวัล" or "ปิดใช้งาน"
            )
        end,
    })

    bookSection:AddToggle("ZeroXAutoCollectAdventureBook", {
        Title = "Auto Collect Adventure Book",
        Description = "รับรายการที่ทำครบเงื่อน็ขแล้ว "
            .. "ไม่เปลี่ยน Title ที่กำลังใช้งาน",
        Default = false,

        Callback = function(value)
            bookEnabled = value == true
            ResetAttempts("book:")

            bookStatus:SetValue(
                bookEnabled and "รอตรวจสมุดผจญภัย" or "ปิดใช้งาน"
            )
        end,
    })


    for _, attribute in ipairs({
        "DailyJson", "RewardsJson", "AchieveJson",
        "AchieveReady", "Level",
    }) do
        table.insert(connections,
            LocalPlayer:GetAttributeChangedSignal(attribute):Connect(
                function()
                    nextScan = 0
                end
            )
        )
    end

    local worker = task.defer(function()
        local ok, err = xpcall(function()
            while alive do
                local now = os.clock()

                if now >= nextScan then
                    nextScan = now + 1

                    if CharacterAlive() then
                        local sent = rewardsEnabled
                            and CollectFreeRewards()

                        if not sent and bookEnabled then
                            CollectBook()
                        end
                    end
                end

                task.wait(0.25)
            end
        end, debug.traceback)

        if not ok and alive then
            rewardsEnabled = false
            bookEnabled = false
            rewardStatus:SetValue("Error: " .. tostring(err))
        end
    end)

    MacUI:OnUnload(function()
        alive = false
        rewardsEnabled = false
        bookEnabled = false

        task.cancel(worker)

        for _, connection in ipairs(connections) do
            connection:Disconnect()
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
