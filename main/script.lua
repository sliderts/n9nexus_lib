local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local NineNexusLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	ToggleKey = Enum.KeyCode.Insert, -- Default toggle key
	Themes = {
		Default = {
			Main = Color3.fromRGB(15, 15, 15),
			Second = Color3.fromRGB(25, 25, 25),
			Stroke = Color3.fromRGB(45, 45, 45),
			Divider = Color3.fromRGB(55, 55, 55),
			Text = Color3.fromRGB(255, 255, 255),
			TextDark = Color3.fromRGB(175, 175, 175),
			Accent = Color3.fromRGB(100, 150, 255)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false,
	WindowVisible = true
}

-- Lucide Icons from GitHub
local Icons = {}
local Success, Response = pcall(function()
	local IconData = game:HttpGetAsync("https://raw.githubusercontent.com/frappedevs/lucideblox/master/src/modules/util/icons.json")
	Icons = HttpService:JSONDecode(IconData).icons
end)

if not Success then
	warn("\nNineNexus Library - Failed to load Lucide Icons. Using fallback icons. Error: " .. tostring(Response))
	-- Fallback icons
	Icons = {
		["home"] = "rbxassetid://10734884548",
		["settings"] = "rbxassetid://10734886004", 
		["user"] = "rbxassetid://10734884302",
		["check"] = "rbxassetid://10734884548",
		["x"] = "rbxassetid://10734884302",
		["minus"] = "rbxassetid://10734884548",
		["plus"] = "rbxassetid://10734884549", -- Added plus icon
		["chevron-down"] = "rbxassetid://10734884302",
		["chevron-right"] = "rbxassetid://10734884548",
		["bell"] = "rbxassetid://10734884550",
		["eye"] = "rbxassetid://10734884551",
		["eye-off"] = "rbxassetid://10734884552"
	}
end

local function GetIcon(IconName)
	if Icons[IconName] ~= nil then
		return Icons[IconName]
	else
		return "rbxassetid://10734884548" -- Default fallback
	end
end

local NineNexus = Instance.new("ScreenGui")
NineNexus.Name = "NineNexus"
NineNexus.ResetOnSpawn = false

-- Better GUI protection
if syn and syn.protect_gui then
	syn.protect_gui(NineNexus)
	NineNexus.Parent = game.CoreGui
elseif gethui then
	NineNexus.Parent = gethui()
else
	NineNexus.Parent = game.CoreGui
end

-- Clean up existing instances
local function CleanupExisting()
	local parent = gethui and gethui() or game.CoreGui
	for _, Interface in ipairs(parent:GetChildren()) do
		if Interface.Name == NineNexus.Name and Interface ~= NineNexus then
			Interface:Destroy()
		end
	end
end

CleanupExisting()

function NineNexusLib:IsRunning()
	if gethui then
		return NineNexus.Parent == gethui()
	else
		return NineNexus.Parent == game:GetService("CoreGui")
	end
end

function NineNexusLib:SetToggleKey(Key)
	self.ToggleKey = Key
end

function NineNexusLib:GetToggleKey()
	return self.ToggleKey
end

local function AddConnection(Signal, Function)
	if not NineNexusLib:IsRunning() then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(NineNexusLib.Connections, SignalConnect)
	return SignalConnect
end

-- Connection cleanup
task.spawn(function()
	while NineNexusLib:IsRunning() do
		task.wait(1)
	end
	for _, Connection in next, NineNexusLib.Connections do
		if Connection then
			Connection:Disconnect()
		end
	end
end)

-- Fixed dragging functionality
local function AddDraggingFunctionality(DragPoint, Main)
	local Dragging, DragInput, MousePos, FramePos = false

	AddConnection(DragPoint.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dragging = true
			MousePos = Input.Position
			FramePos = Main.Position

			AddConnection(Input.Changed, function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	AddConnection(DragPoint.InputChanged, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			DragInput = Input
		end
	end)

	AddConnection(UserInputService.InputChanged, function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			local NewPosition = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
			Main.Position = NewPosition
		end
	end)
end

local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
	end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	NineNexusLib.Elements[ElementName] = function(...)
		return ElementFunction(...)
	end
end

local function MakeElement(ElementName, ...)
	return NineNexusLib.Elements[ElementName](...)
end

local function SetProps(Element, Props)
	for Property, Value in pairs(Props) do
		Element[Property] = Value
	end
	return Element
end

local function SetChildren(Element, Children)
	for _, Child in pairs(Children) do
		Child.Parent = Element
	end
	return Element
end

local function Round(Number, Factor)
	local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
	if Result < 0 then Result = Result + Factor end
	return Result
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then
		return "BackgroundColor3"
	elseif Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	elseif Object:IsA("UIStroke") then
		return "Color"
	elseif Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		return "ImageColor3"
	end
end

local function AddThemeObject(Object, Type)
	if not NineNexusLib.ThemeObjects[Type] then
		NineNexusLib.ThemeObjects[Type] = {}
	end
	table.insert(NineNexusLib.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = NineNexusLib.Themes[NineNexusLib.SelectedTheme][Type]
	return Object
end

local function SetTheme()
	for Name, Type in pairs(NineNexusLib.ThemeObjects) do
		for _, Object in pairs(Type) do
			if Object and Object.Parent then
				Object[ReturnProperty(Object)] = NineNexusLib.Themes[NineNexusLib.SelectedTheme][Name]
			end
		end
	end
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
	local Data = HttpService:JSONDecode(Config)
	for a, b in pairs(Data) do
		if NineNexusLib.Flags[a] then
			task.spawn(function()
				if NineNexusLib.Flags[a].Type == "Colorpicker" then
					NineNexusLib.Flags[a]:Set(UnpackColor(b))
				else
					NineNexusLib.Flags[a]:Set(b)
				end
			end)
		else
			warn("NineNexus Library Config Loader - Could not find flag:", a, b)
		end
	end
end

local function SaveCfg(Name)
	if not NineNexusLib.SaveCfg then return end
	local Data = {}
	for i, v in pairs(NineNexusLib.Flags) do
		if v.Save then
			if v.Type == "Colorpicker" then
				Data[i] = PackColor(v.Value)
			else
				Data[i] = v.Value
			end
		end
	end
	if writefile then
		writefile(NineNexusLib.Folder .. "/" .. Name .. ".txt", HttpService:JSONEncode(Data))
	end
end

-- UI Elements
CreateElement("Corner", function(Scale, Offset)
	return Create("UICorner", {
		CornerRadius = UDim.new(Scale or 0, Offset or 8)
	})
end)

CreateElement("Stroke", function(Color, Thickness)
	return Create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1
	})
end)

CreateElement("List", function(Scale, Offset)
	return Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", {
		BackgroundTransparency = 1
	})
end)

CreateElement("Frame", function(Color)
	return Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	})
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	return Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(Scale or 0, Offset or 8)
		})
	})
end)

CreateElement("Button", function()
	return Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
end)

CreateElement("ScrollFrame", function(Color, Width)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width or 4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y
	})
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {
		Image = ImageID or "",
		BackgroundTransparency = 1
	})
	return ImageNew
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	return Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 14,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
end)

CreateElement("TextBox", function(Text, PlaceholderText)
	return Create("TextBox", {
		Text = Text or "",
		PlaceholderText = PlaceholderText or "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClearButtonOnFocus = false
	})
end)

-- Enhanced Notification System with Progress Bar
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8)
	})
}), {
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.new(0, 350, 1, -20),
	AnchorPoint = Vector2.new(1, 1),
	Parent = NineNexus
})

function NineNexusLib:MakeNotification(NotificationConfig)
	task.spawn(function()
		NotificationConfig.Name = NotificationConfig.Name or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Test"
		NotificationConfig.Image = NotificationConfig.Image or GetIcon("bell")
		NotificationConfig.Time = NotificationConfig.Time or 5

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		-- Progress Bar
		local ProgressBar = AddThemeObject(SetProps(MakeElement("Frame", NineNexusLib.Themes.Default.Accent), {
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, -3)
		}), "Accent")

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", NineNexusLib.Themes.Default.Second, 0, 12), {
			Parent = NotificationParent,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, 50, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1),
			MakeElement("Padding", 16, 16, 16, 16),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size = UDim2.new(0, 24, 0, 24),
				ImageColor3 = NineNexusLib.Themes.Default.Accent,
				Name = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 16), {
				Size = UDim2.new(1, -34, 0, 24),
				Position = UDim2.new(0, 34, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 30),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = NineNexusLib.Themes.Default.TextDark,
				TextWrapped = true,
				Name = "Content"
			}),
			ProgressBar
		})

		-- Animate notification in
		TweenService:Create(NotificationFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()

		-- Animate progress bar
		TweenService:Create(ProgressBar, TweenInfo.new(NotificationConfig.Time, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 0, 3)
		}):Play()

		task.wait(NotificationConfig.Time - 0.5)

		-- Animate out
		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 50, 0, 0),
			BackgroundTransparency = 1
		}):Play()

		task.wait(0.5)
		NotificationParent:Destroy()
	end)
end

function NineNexusLib:Init()
	if NineNexusLib.SaveCfg then
		task.spawn(function()
			if isfile and isfile(NineNexusLib.Folder .. "/" .. game.GameId .. ".txt") then
				LoadCfg(readfile(NineNexusLib.Folder .. "/" .. game.GameId .. ".txt"))
				NineNexusLib:MakeNotification({
					Name = "Configuration Loaded",
					Content = "Auto-loaded configuration for game " .. game.GameId,
					Time = 4
				})
			end
		end)
	end
end

function NineNexusLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local UIHidden = false
	local MainWindow -- Define MainWindow early for global access

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "NineNexus"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.HidePremium = WindowConfig.HidePremium or false

	if WindowConfig.IntroEnabled == nil then
		WindowConfig.IntroEnabled = true
	end

	WindowConfig.IntroText = WindowConfig.IntroText or "NineNexus"
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = WindowConfig.Icon or GetIcon("home")
	WindowConfig.IntroIcon = WindowConfig.IntroIcon or GetIcon("home")
	WindowConfig.ToggleKey = WindowConfig.ToggleKey or NineNexusLib.ToggleKey

	NineNexusLib.Folder = WindowConfig.ConfigFolder
	NineNexusLib.SaveCfg = WindowConfig.SaveConfig
	NineNexusLib.ToggleKey = WindowConfig.ToggleKey

	if WindowConfig.SaveConfig and makefolder then
		if not isfolder(WindowConfig.ConfigFolder) then
			makefolder(WindowConfig.ConfigFolder)
		end
	end

	-- Tab Holder
	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", NineNexusLib.Themes.Default.Stroke, 4), {
		Size = UDim2.new(1, 0, 1, -60)
	}), {
		MakeElement("List", 0, 4),
		MakeElement("Padding", 8, 8, 8, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	-- Window Controls
	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0)
	}), {
		AddThemeObject(SetProps(MakeElement("Image", GetIcon("x")), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5)
		}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0)
	}), {
		AddThemeObject(SetProps(MakeElement("Image", GetIcon("minus")), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Name = "Ico"
		}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 50)
	})

	-- Sidebar
	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
		Size = UDim2.new(0, 200, 1, -50),
		Position = UDim2.new(0, 0, 0, 50)
	}), {
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.new(0, 0, 0, 0)
		}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(0, 12, 1, 0),
			Position = UDim2.new(1, -12, 0, 0)
		}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -1, 0, 0)
		}), "Stroke"),
		TabHolder,
		-- User Info Section
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.new(0, 0, 1, -60)
		}), {
			AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1)
			}), "Stroke"),
			-- User Avatar
			AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 36, 0, 36),
				Position = UDim2.new(0, 12, 0.5, 0)
			}), {
				SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"), {
					Size = UDim2.new(1, 0, 1, 0)
				}),
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
					Size = UDim2.new(1, 0, 1, 0)
				}), "Second"),
				MakeElement("Corner", 1)
			}), "Divider"),
			SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 36, 0, 36),
				Position = UDim2.new(0, 12, 0.5, 0)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				MakeElement("Corner", 1)
			}),
			-- User Name
			AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, 14), {
				Size = UDim2.new(1, -60, 0, 16),
				Position = UDim2.new(0, 56, 0, 15),
				Font = Enum.Font.GothamBold,
				ClipsDescendants = true
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", "@" .. LocalPlayer.Name, 12), {
				Size = UDim2.new(1, -60, 0, 14),
				Position = UDim2.new(0, 56, 0, 32),
				TextColor3 = NineNexusLib.Themes.Default.TextDark
			}), "TextDark")
		})
	}), "Second")

	-- Window Title
	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 18), {
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, WindowConfig.ShowIcon and 50 or 20, 0, 0),
		Font = Enum.Font.GothamBold,
		TextYAlignment = Enum.TextYAlignment.Center
	}), "Text")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1)
	}), "Stroke")

	-- Main Window
	MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
		Parent = NineNexus,
		Position = UDim2.new(0.5, -350, 0.5, -200),
		Size = UDim2.new(0, 700, 0, 400),
		ClipsDescendants = true,
		Name = "MainWindow"
	}), {
		-- Top Bar
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			WindowName,
			WindowTopBarLine,
			-- Window Controls
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
				Size = UDim2.new(0, 80, 0, 32),
				Position = UDim2.new(1, -100, 0, 9)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0)
				}), "Stroke"),
				CloseBtn,
				MinimizeBtn
			}), "Second")
		}),
		DragPoint,
		WindowStuff
	}), "Main")

	-- Window Icon
	if WindowConfig.ShowIcon then
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 20, 0, 13),
			ImageColor3 = NineNexusLib.Themes.Default.Accent
		})
		WindowIcon.Parent = MainWindow.TopBar
	end

	AddDraggingFunctionality(DragPoint, MainWindow)

	-- Global Toggle Function
	local function ToggleWindow()
		if NineNexusLib.WindowVisible then
			MainWindow.Visible = false
			UIHidden = true
			NineNexusLib.WindowVisible = false
			NineNexusLib:MakeNotification({
				Name = "Interface Hidden",
				Content = "Press " .. WindowConfig.ToggleKey.Name .. " to show the interface again",
				Time = 4
			})
		else
			MainWindow.Visible = true
			UIHidden = false
			NineNexusLib.WindowVisible = true
		end
	end

	-- Window Controls Events
	AddConnection(CloseBtn.MouseButton1Up, function()
		ToggleWindow()
		WindowConfig.CloseCallback()
	end)

	-- Global keybind for toggling
	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == WindowConfig.ToggleKey then
			ToggleWindow()
		end
	end)

	-- Fixed minimize functionality
	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 700, 0, 400)
			}):Play()
			MinimizeBtn.Ico.Image = GetIcon("minus")
			task.wait(0.1)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			WindowStuff.Visible = false
			MinimizeBtn.Ico.Image = GetIcon("plus")
			TweenService:Create(MainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, math.max(WindowName.TextBounds.X + 150, 300), 0, 50)
			}):Play()
		end
		Minimized = not Minimized
	end)

	-- Intro Animation
	local function LoadSequence()
		MainWindow.Visible = false

		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = NineNexus,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 32, 0, 32),
			ImageColor3 = NineNexusLib.Themes.Default.Accent,
			ImageTransparency = 1
		})

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 16), {
			Parent = NineNexus,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 20, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()

		task.wait(0.8)

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)
		}):Play()

		task.wait(0.3)

		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0
		}):Play()

		task.wait(1.5)

		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 1
		}):Play()
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageTransparency = 1
		}):Play()

		task.wait(0.3)

		MainWindow.Visible = true
		LoadSequenceLogo:Destroy()
		LoadSequenceText:Destroy()
	end

	if WindowConfig.IntroEnabled then
		LoadSequence()
	end

	local TabFunction = {}

	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or "home"
		TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 36),
			Parent = TabHolder
		}), {
			AddThemeObject(SetProps(MakeElement("Image", GetIcon(TabConfig.Icon)), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 20, 0, 20),
				Position = UDim2.new(0, 12, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -44, 1, 0),
				Position = UDim2.new(0, 40, 0, 0),
				Font = Enum.Font.GothamMedium,
				TextTransparency = 0.4,
				Name = "Title"
			}), "Text")
		})

		-- Content Container
		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", NineNexusLib.Themes.Default.Stroke, 6), {
			Size = UDim2.new(1, -200, 1, -50),
			Position = UDim2.new(0, 200, 0, 50),
			Parent = MainWindow,
			Visible = false,
			Name = "ItemContainer"
		}), {
			MakeElement("List", 0, 8),
			MakeElement("Padding", 20, 16, 16, 20)
		}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 40)
		end)

		if FirstTab then
			FirstTab = false
			TabFrame.Ico.ImageTransparency = 0
			TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBold
			Container.Visible = true
		end

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamMedium
					TweenService:Create(Tab.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						ImageTransparency = 0.4
					}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						TextTransparency = 0.4
					}):Play()
				end
			end

			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end
			end

			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				TextTransparency = 0
			}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBold
			Container.Visible = true
		end)

		-- Element Functions
		local function GetElements(ItemParent)
			local ElementFunction = {}

			function ElementFunction:AddSection(SectionConfig)
				SectionConfig = SectionConfig or {}
				SectionConfig.Name = SectionConfig.Name or "Section"

				local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 32),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 16), {
						Size = UDim2.new(1, 0, 0, 20),
						Position = UDim2.new(0, 0, 0, 0),
						Font = Enum.Font.GothamBold
					}), "Text"),
					SetChildren(SetProps(MakeElement("TFrame"), {
						Size = UDim2.new(1, 0, 1, -28),
						Position = UDim2.new(0, 0, 0, 28),
						Name = "Holder"
					}), {
						MakeElement("List", 0, 8)
					})
				})

				AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 36)
					SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
				end)

				local SectionFunction = {}
				for i, v in next, GetElements(SectionFrame.Holder) do
					SectionFunction[i] = v
				end
				return SectionFunction
			end

			function ElementFunction:AddLabel(Text)
				local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
						Size = UDim2.new(1, -16, 1, 0),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				local LabelFunction = {}
				function LabelFunction:Set(ToChange)
					LabelFrame.Content.Text = ToChange
				end
				return LabelFunction
			end

			function ElementFunction:AddParagraph(Text, Content)
				Text = Text or "Paragraph"
				Content = Content or "Content"

				local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -16, 0, 18),
						Position = UDim2.new(0, 16, 0, 8),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", "", 13), {
						Size = UDim2.new(1, -32, 0, 0),
						Position = UDim2.new(0, 16, 0, 28),
						Font = Enum.Font.GothamMedium,
						Name = "Content",
						TextWrapped = true
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -32, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 40)
				end)

				ParagraphFrame.Content.Text = Content

				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange)
					ParagraphFrame.Content.Text = ToChange
				end
				return ParagraphFunction
			end

			function ElementFunction:AddButton(ButtonConfig)
				ButtonConfig = ButtonConfig or {}
				ButtonConfig.Name = ButtonConfig.Name or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end
				ButtonConfig.Icon = ButtonConfig.Icon or "chevron-right"

				local Button = {}
				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 40),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 14), {
						Size = UDim2.new(1, -50, 1, 0),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", GetIcon(ButtonConfig.Icon)), {
						Size = UDim2.new(0, 18, 0, 18),
						Position = UDim2.new(1, -30, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5)
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					Click
				}), "Second")

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(
							NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8,
							NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8,
							NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8
						)
					}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second
					}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					task.spawn(function()
						ButtonConfig.Callback()
					end)
				end)

				function Button:Set(ButtonText)
					ButtonFrame.Content.Text = ButtonText
				end

				return Button
			end

			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig = ToggleConfig or {}
				ToggleConfig.Name = ToggleConfig.Name or "Toggle"
				ToggleConfig.Default = ToggleConfig.Default or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color = ToggleConfig.Color or NineNexusLib.Themes.Default.Accent
				ToggleConfig.Flag = ToggleConfig.Flag or nil
				ToggleConfig.Save = ToggleConfig.Save or false

				local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save, Type = "Toggle"}

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 6), {
					Size = UDim2.new(0, 28, 0, 28),
					Position = UDim2.new(1, -40, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5)
				}), {
					SetProps(MakeElement("Stroke"), {
						Color = ToggleConfig.Color,
						Name = "Stroke",
						Transparency = 0.5
					}),
					SetProps(MakeElement("Image", GetIcon("check")), {
						Size = UDim2.new(0, 16, 0, 16),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Name = "Ico"
					})
				})

				local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 44),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 14), {
						Size = UDim2.new(1, -60, 1, 0),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					ToggleBox,
					Click
				}), "Second")

				function Toggle:Set(Value)
					Toggle.Value = Value
					TweenService:Create(ToggleBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = Toggle.Value and ToggleConfig.Color or NineNexusLib.Themes.Default.Divider
					}):Play()
					TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Color = Toggle.Value and ToggleConfig.Color or NineNexusLib.Themes.Default.Stroke
					}):Play()
					TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						ImageTransparency = Toggle.Value and 0 or 1,
						Size = Toggle.Value and UDim2.new(0, 16, 0, 16) or UDim2.new(0, 8, 0, 8)
					}):Play()
					ToggleConfig.Callback(Toggle.Value)
				end

				Toggle:Set(Toggle.Value)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(
							NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8,
							NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8,
							NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8
						)
					}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second
					}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					Toggle:Set(not Toggle.Value)
					if NineNexusLib.SaveCfg then
						SaveCfg(game.GameId)
					end
				end)

				if ToggleConfig.Flag then
					NineNexusLib.Flags[ToggleConfig.Flag] = Toggle
				end

				return Toggle
			end

			-- Slider Element
			function ElementFunction:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Default = SliderConfig.Default or SliderConfig.Min
				SliderConfig.Color = SliderConfig.Color or NineNexusLib.Themes.Default.Accent
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Callback = SliderConfig.Callback or function() end
				SliderConfig.Flag = SliderConfig.Flag or nil
				SliderConfig.Save = SliderConfig.Save or false

				local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save, Type = "Slider"}
				local Dragging = false

				local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 54),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 14), {
						Size = UDim2.new(1, -16, 0, 20),
						Position = UDim2.new(0, 16, 0, 8),
						Font = Enum.Font.GothamMedium,
						Name = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", tostring(SliderConfig.Default) .. SliderConfig.ValueName, 13), {
						Size = UDim2.new(0.3, 0, 0, 20),
						Position = UDim2.new(0.7, 0, 0, 8),
						Font = Enum.Font.GothamMedium,
						Name = "Value",
						TextXAlignment = Enum.TextXAlignment.Right
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				-- Slider Bar
				local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", NineNexusLib.Themes.Default.Divider, 0, 4), {
					Size = UDim2.new(1, -32, 0, 6),
					Position = UDim2.new(0, 16, 1, -18),
					Parent = SliderFrame
				}), {
					SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 4), {
						Size = UDim2.new(0, 0, 1, 0),
						Name = "Fill"
					}),
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 1, 0), {
						Size = UDim2.new(0, 12, 0, 12),
						Position = UDim2.new(0, -6, 0.5, -6),
						Name = "Knob",
						BorderSizePixel = 0
					})
				})

				local function UpdateSlider(Value)
					Slider.Value = Round(math.clamp(Value, SliderConfig.Min, SliderConfig.Max), SliderConfig.Increment)
					SliderFrame.Value.Text = tostring(Slider.Value) .. SliderConfig.ValueName
					
					local Percent = (Slider.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
					
					TweenService:Create(SliderBar.Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(Percent, 0, 1, 0)
					}):Play()
					
					TweenService:Create(SliderBar.Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(Percent, -6, 0.5, -6)
					}):Play()
					
					SliderConfig.Callback(Slider.Value)
				end

				function Slider:Set(Value)
					UpdateSlider(Value)
				end

				AddConnection(SliderBar.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = true
						local function Update()
							local MousePos = Mouse.X
							local BarPos = SliderBar.AbsolutePosition.X
							local BarSize = SliderBar.AbsoluteSize.X
							local Percent = math.clamp((MousePos - BarPos) / BarSize, 0, 1)
							local Value = SliderConfig.Min + (Percent * (SliderConfig.Max - SliderConfig.Min))
							UpdateSlider(Value)
						end
						Update()
						local MoveConnection = AddConnection(Mouse.Move, Update)
						local ReleaseConnection
						ReleaseConnection = AddConnection(UserInputService.InputEnded, function(EndInput)
							if EndInput.UserInputType == Enum.UserInputType.MouseButton1 then
								Dragging = false
								MoveConnection:Disconnect()
								ReleaseConnection:Disconnect()
								if NineNexusLib.SaveCfg then
									SaveCfg(game.GameId)
								end
							end
						end)
					end
				end)

				UpdateSlider(SliderConfig.Default)

				if SliderConfig.Flag then
					NineNexusLib.Flags[SliderConfig.Flag] = Slider
				end

				return Slider
			end

			-- Dropdown Element  
			function ElementFunction:AddDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
				DropdownConfig.Default = DropdownConfig.Default or ""
				DropdownConfig.Options = DropdownConfig.Options or {"Option 1", "Option 2"}
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag = DropdownConfig.Flag or nil
				DropdownConfig.Save = DropdownConfig.Save or false

				local Dropdown = {Value = DropdownConfig.Default, Save = DropdownConfig.Save, Type = "Dropdown", Options = DropdownConfig.Options}
				local Opened = false

				local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 44),
					Parent = ItemParent,
					ClipsDescendants = true
				}), {
					AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 14), {
						Size = UDim2.new(1, -50, 0, 44),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Title",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Default, 13), {
						Size = UDim2.new(0.4, -24, 0, 44),
						Position = UDim2.new(0.6, 0, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Selected",
						TextXAlignment = Enum.TextXAlignment.Right,
						TextYAlignment = Enum.TextYAlignment.Center
					}), "TextDark"),
					AddThemeObject(SetProps(MakeElement("Image", GetIcon("chevron-down")), {
						Size = UDim2.new(0, 16, 0, 16),
						Position = UDim2.new(1, -28, 0.5, -8),
						Name = "Arrow"
					}), "TextDark"),
					SetProps(MakeElement("Button"), {
						Size = UDim2.new(1, 0, 0, 44),
						Name = "ClickDetector"
					}),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				local OptionsList = SetChildren(SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 0, 44),
					Parent = DropdownFrame,
					Name = "Options"
				}), {
					MakeElement("List", 0, 0)
				})

				local function CreateOption(OptionText)
					local OptionFrame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame", Color3.fromRGB(255, 255, 255)), {
						Size = UDim2.new(1, 0, 0, 32),
						Parent = OptionsList
					}), {
						AddThemeObject(SetProps(MakeElement("Label", OptionText, 13), {
							Size = UDim2.new(1, -16, 1, 0),
							Position = UDim2.new(0, 16, 0, 0),
							Font = Enum.Font.GothamMedium,
							TextYAlignment = Enum.TextYAlignment.Center
						}), "Text"),
						SetProps(MakeElement("Button"), {
							Size = UDim2.new(1, 0, 1, 0)
						})
					}), "Divider")

					AddConnection(OptionFrame.TextButton.MouseButton1Click, function()
						Dropdown:Set(OptionText)
						Dropdown:Close()
					end)

					return OptionFrame
				end

				function Dropdown:Set(Value)
					Dropdown.Value = Value
					DropdownFrame.Selected.Text = Value
					DropdownConfig.Callback(Value)
				end

				function Dropdown:Refresh(NewOptions)
					for _, Option in pairs(OptionsList:GetChildren()) do
						if Option:IsA("Frame") then
							Option:Destroy()
						end
					end
					Dropdown.Options = NewOptions
					for _, Option in pairs(NewOptions) do
						CreateOption(Option)
					end
				end

				function Dropdown:Open()
					if Opened then return end
					Opened = true
					
					local OptionsCount = #Dropdown.Options
					local TargetHeight = 44 + (OptionsCount * 32)
					
					TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, TargetHeight)
					}):Play()
					
					TweenService:Create(DropdownFrame.Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 180
					}):Play()
				end

				function Dropdown:Close()
					if not Opened then return end
					Opened = false
					
					TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 44)
					}):Play()
					
					TweenService:Create(DropdownFrame.Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 0
					}):Play()
				end

				AddConnection(DropdownFrame.ClickDetector.MouseButton1Click, function()
					if Opened then
						Dropdown:Close()
					else
						Dropdown:Open()
					end
				end)

				for _, Option in pairs(DropdownConfig.Options) do
					CreateOption(Option)
				end

				if DropdownConfig.Flag then
					NineNexusLib.Flags[DropdownConfig.Flag] = Dropdown
				end

				return Dropdown
			end

			-- TextBox Element
			function ElementFunction:AddTextbox(TextboxConfig)
				TextboxConfig = TextboxConfig or {}
				TextboxConfig.Name = TextboxConfig.Name or "TextBox"
				TextboxConfig.Default = TextboxConfig.Default or ""
				TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
				TextboxConfig.Callback = TextboxConfig.Callback or function() end
				TextboxConfig.Flag = TextboxConfig.Flag or nil
				TextboxConfig.Save = TextboxConfig.Save or false

				local Textbox = {Value = TextboxConfig.Default, Save = TextboxConfig.Save, Type = "Textbox"}

				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 44),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 14), {
						Size = UDim2.new(0.5, -8, 1, 0),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Title",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", NineNexusLib.Themes.Default.Main, 0, 6), {
						Size = UDim2.new(0.5, -8, 0, 28),
						Position = UDim2.new(0.5, 8, 0.5, -14),
						Name = "InputFrame"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("TextBox", TextboxConfig.Default, ""), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 6, 0, 0),
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							Name = "Input"
						}), "Text")
					}), "Main"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				function Textbox:Set(Value)
					Textbox.Value = Value
					TextboxFrame.InputFrame.Input.Text = Value
					TextboxConfig.Callback(Value)
				end

				AddConnection(TextboxFrame.InputFrame.Input.FocusLost, function(EnterPressed)
					if EnterPressed then
						Textbox:Set(TextboxFrame.InputFrame.Input.Text)
						if TextboxConfig.TextDisappear then
							TextboxFrame.InputFrame.Input.Text = ""
						end
						if NineNexusLib.SaveCfg then
							SaveCfg(game.GameId)
						end
					end
				end)

				if TextboxConfig.Flag then
					NineNexusLib.Flags[TextboxConfig.Flag] = Textbox
				end

				return Textbox
			end

			-- Colorpicker Element
			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Color Picker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
				ColorpickerConfig.Save = ColorpickerConfig.Save or false

				local Colorpicker = {Value = ColorpickerConfig.Default, Save = ColorpickerConfig.Save, Type = "Colorpicker"}

				local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 44),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 14), {
						Size = UDim2.new(1, -50, 1, 0),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Title",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					SetChildren(SetProps(MakeElement("RoundFrame", ColorpickerConfig.Default, 0, 6), {
						Size = UDim2.new(0, 28, 0, 28),
						Position = UDim2.new(1, -40, 0.5, -14),
						Name = "Preview"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						SetProps(MakeElement("Button"), {
							Size = UDim2.new(1, 0, 1, 0)
						})
					}),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				function Colorpicker:Set(Color)
					Colorpicker.Value = Color
					ColorpickerFrame.Preview.BackgroundColor3 = Color
					ColorpickerConfig.Callback(Color)
				end

				-- Simple color picker (you can expand this with a full color wheel)
				AddConnection(ColorpickerFrame.Preview.TextButton.MouseButton1Click, function()
					-- This is a simple implementation - you could add a full color picker GUI here
					local RandomColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
					Colorpicker:Set(RandomColor)
					if NineNexusLib.SaveCfg then
						SaveCfg(game.GameId)
					end
				end)

				if ColorpickerConfig.Flag then
					NineNexusLib.Flags[ColorpickerConfig.Flag] = Colorpicker
				end

				return Colorpicker
			end

			-- Keybind Element
			function ElementFunction:AddKeybind(KeybindConfig)
				KeybindConfig = KeybindConfig or {}
				KeybindConfig.Name = KeybindConfig.Name or "Keybind"
				KeybindConfig.Default = KeybindConfig.Default or Enum.KeyCode.F
				KeybindConfig.Callback = KeybindConfig.Callback or function() end
				KeybindConfig.Flag = KeybindConfig.Flag or nil
				KeybindConfig.Save = KeybindConfig.Save or false

				local Keybind = {Value = KeybindConfig.Default, Save = KeybindConfig.Save, Type = "Keybind"}
				local WaitingForKey = false

				local KeybindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 44),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", KeybindConfig.Name, 14), {
						Size = UDim2.new(1, -100, 1, 0),
						Position = UDim2.new(0, 16, 0, 0),
						Font = Enum.Font.GothamMedium,
						Name = "Title",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", NineNexusLib.Themes.Default.Main, 0, 6), {
						Size = UDim2.new(0, 80, 0, 28),
						Position = UDim2.new(1, -92, 0.5, -14),
						Name = "KeyFrame"
					}), {
						AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", KeybindConfig.Default.Name, 12), {
							Size = UDim2.new(1, 0, 1, 0),
							Font = Enum.Font.GothamMedium,
							TextYAlignment = Enum.TextYAlignment.Center,
							Name = "KeyLabel"
						}), "Text"),
						SetProps(MakeElement("Button"), {
							Size = UDim2.new(1, 0, 1, 0)
						})
					}), "Main"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				function Keybind:Set(Key)
					Keybind.Value = Key
					KeybindFrame.KeyFrame.KeyLabel.Text = Key.Name
				end

				AddConnection(KeybindFrame.KeyFrame.TextButton.MouseButton1Click, function()
					if WaitingForKey then return end
					WaitingForKey = true
					KeybindFrame.KeyFrame.KeyLabel.Text = "..."
					
					local Connection
					Connection = AddConnection(UserInputService.InputBegan, function(Input, GameProcessed)
						if GameProcessed then return end
						if Input.UserInputType == Enum.UserInputType.Keyboard then
							Keybind:Set(Input.KeyCode)
							WaitingForKey = false
							Connection:Disconnect()
							if NineNexusLib.SaveCfg then
								SaveCfg(game.GameId)
							end
						end
					end)
				end)

				-- Handle the keybind press
				AddConnection(UserInputService.InputBegan, function(Input, GameProcessed)
					if GameProcessed then return end
					if Input.KeyCode == Keybind.Value then
						KeybindConfig.Callback()
					end
				end)

				if KeybindConfig.Flag then
					NineNexusLib.Flags[KeybindConfig.Flag] = Keybind
				end

				return Keybind
			end

			return ElementFunction
		end

		local ElementFunction = {}
		function ElementFunction:AddSection(SectionConfig)
			return GetElements(Container):AddSection(SectionConfig)
		end

		for i, v in next, GetElements(Container) do
			ElementFunction[i] = v
		end

		return ElementFunction
	end

	NineNexusLib:MakeNotification({
		Name = "NineNexus Loaded",
		Content = "UI Library successfully initialized with all elements",
		Time = 3
	})

	return TabFunction
end

function NineNexusLib:Destroy()
	NineNexus:Destroy()
end

return NineNexusLib
