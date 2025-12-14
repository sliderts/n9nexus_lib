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
	Themes = {
		Default = {
			Main = Color3.fromRGB(22, 22, 26),
			Second = Color3.fromRGB(28, 28, 32),
			Stroke = Color3.fromRGB(52, 52, 58),
			Divider = Color3.fromRGB(65, 65, 70),
			Text = Color3.fromRGB(245, 245, 245),
			TextDark = Color3.fromRGB(160, 160, 160),
			Accent = Color3.fromRGB(88, 166, 255)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false
}

--Feather Icons https://github.com/evoincorp/lucideblox/tree/master/src/modules/util - Created by 7kayoh
local Icons = {}

local Success, Response = pcall(function()
	Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/frappedevs/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
	warn("\nNineNexus Library - Failed to load Feather Icons. Error code: " .. Response .. "\n")
end	

local function GetIcon(IconName)
	if Icons[IconName] ~= nil then
		return Icons[IconName]
	else
		return nil
	end
end   

local NineNexus = Instance.new("ScreenGui")
NineNexus.Name = "NineNexus"
if syn then
	syn.protect_gui(NineNexus)
	NineNexus.Parent = game.CoreGui
else
	NineNexus.Parent = gethui() or game.CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == NineNexus.Name and Interface ~= NineNexus then
			Interface:Destroy()
		end
	end
else
	for _, Interface in ipairs(game.CoreGui:GetChildren()) do
		if Interface.Name == NineNexus.Name and Interface ~= NineNexus then
			Interface:Destroy()
		end
	end
end

function NineNexusLib:IsRunning()
	if gethui then
		return NineNexus.Parent == gethui()
	else
		return NineNexus.Parent == game:GetService("CoreGui")
	end
end

local function AddConnection(Signal, Function)
	if (not NineNexusLib:IsRunning()) then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(NineNexusLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while (NineNexusLib:IsRunning()) do
		wait()
	end

	for _, Connection in next, NineNexusLib.Connections do
		Connection:Disconnect()
	end
end)

local function AddDraggingFunctionality(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				DragInput = Input
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position  = UDim2.new(FramePos.X.Scale,FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)}):Play()
			end
		end)
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
	local NewElement = NineNexusLib.Elements[ElementName](...)
	return NewElement
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value)
		Element[Property] = Value
	end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child)
		Child.Parent = Element
	end)
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
	end 
	if Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	end 
	if Object:IsA("UIStroke") then
		return "Color"
	end 
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	end   
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
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
			Object[ReturnProperty(Object)] = NineNexusLib.Themes[NineNexusLib.SelectedTheme][Name]
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
	table.foreach(Data, function(a,b)
		if NineNexusLib.Flags[a] then
			spawn(function() 
				if NineNexusLib.Flags[a].Type == "Colorpicker" then
					NineNexusLib.Flags[a]:Set(UnpackColor(b))
				else
					NineNexusLib.Flags[a]:Set(b)
				end    
			end)
		else
			warn("NineNexus Library Config Loader - Could not find ", a ,b)
		end
	end)
end

local function SaveCfg(Name)
	local Data = {}
	for i,v in pairs(NineNexusLib.Flags) do
		if v.Save then
			if v.Type == "Colorpicker" then
				Data[i] = PackColor(v.Value)
			else
				Data[i] = v.Value
			end
		end	
	end
	writefile(NineNexusLib.Folder .. "/" .. Name .. ".txt", tostring(HttpService:JSONEncode(Data)))
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
	for _, v in next, Table do
		if v == Key then
			return true
		end
	end
end

CreateElement("Corner", function(Scale, Offset)
	local Corner = Create("UICorner", {
		CornerRadius = UDim.new(Scale or 0, Offset or 12)
	})
	return Corner
end)

CreateElement("Stroke", function(Color, Thickness)
	local Stroke = Create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1.2
	})
	return Stroke
end)

CreateElement("List", function(Scale, Offset)
	local List = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
	return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	local Padding = Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 6),
		PaddingLeft = UDim.new(0, Left or 6),
		PaddingRight = UDim.new(0, Right or 6),
		PaddingTop = UDim.new(0, Top or 6)
	})
	return Padding
end)

CreateElement("TFrame", function()
	local TFrame = Create("Frame", {
		BackgroundTransparency = 1
	})
	return TFrame
end)

CreateElement("Frame", function(Color)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	})
	return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(Scale, Offset)
		})
	})
	return Frame
end)

CreateElement("Button", function()
	local Button = Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
	local ScrollFrame = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
	return ScrollFrame
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {
		Image = ImageID,
		BackgroundTransparency = 1
	})

	if GetIcon(ImageID) ~= nil then
		ImageNew.Image = GetIcon(ImageID)
	end	

	return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
	local Image = Create("ImageButton", {
		Image = ImageID,
		BackgroundTransparency = 1
	})
	return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	local Label = Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(245, 245, 245),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 16,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center
	})
	return Label
end)

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8)
	})
}), {
	Position = UDim2.new(1, -30, 1, -30),
	Size = UDim2.new(0, 350, 1, -30),
	AnchorPoint = Vector2.new(1, 1),
	Parent = NineNexus
})

function NineNexusLib:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig.Name = NotificationConfig.Name or "NineNexus"
		NotificationConfig.Content = NotificationConfig.Content or "Notification content"
		NotificationConfig.Image = NotificationConfig.Image or "bell"
		NotificationConfig.Time = NotificationConfig.Time or 8

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		-- Прогресс бар для уведомления
		local ProgressBar = SetProps(MakeElement("Frame", Color3.fromRGB(88, 166, 255)), {
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, -3),
			BorderSizePixel = 0
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", NineNexusLib.Themes.Default.Second, 0, 12), {
			Parent = NotificationParent, 
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, 50, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5),
			MakeElement("Padding", 16, 16, 16, 16),
			SetProps(MakeElement("Image", GetIcon(NotificationConfig.Image) or "rbxassetid://7072718307"), {
				Size = UDim2.new(0, 24, 0, 24),
				ImageColor3 = NineNexusLib.Themes.Default.Accent,
				Name = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 16), {
				Size = UDim2.new(1, -40, 0, 24),
				Position = UDim2.new(0, 40, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title",
				TextColor3 = NineNexusLib.Themes.Default.Text
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = UDim2.new(1, -8, 0, 0),
				Position = UDim2.new(0, 4, 0, 32),
				Font = Enum.Font.GothamMedium,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = NineNexusLib.Themes.Default.TextDark,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			ProgressBar
		})

		-- Анимация появления
		TweenService:Create(NotificationFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		-- Анимация прогресс бара
		TweenService:Create(ProgressBar, TweenInfo.new(NotificationConfig.Time, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)}):Play()

		-- Исчезновение
		wait(NotificationConfig.Time - 0.6)
		
		TweenService:Create(NotificationFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 50, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Transparency = 1}):Play()
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {ImageTransparency = 1}):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {TextTransparency = 1}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {TextTransparency = 1}):Play()
		
		wait(0.6)
		NotificationFrame:Destroy()
	end)
end    

function NineNexusLib:Init()
	if NineNexusLib.SaveCfg then	
		pcall(function()
			if isfile(NineNexusLib.Folder .. "/" .. game.GameId .. ".txt") then
				LoadCfg(readfile(NineNexusLib.Folder .. "/" .. game.GameId .. ".txt"))
				NineNexusLib:MakeNotification({
					Name = "Configuration Loaded",
					Content = "Auto-loaded configuration for game " .. game.GameId .. ".",
					Image = "settings",
					Time = 6
				})
			end
		end)		
	end	
end	

function NineNexusLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local Loaded = false
	local UIHidden = false

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
	WindowConfig.Icon = WindowConfig.Icon or GetIcon("zap") or "rbxassetid://7072718307"
	WindowConfig.IntroIcon = WindowConfig.IntroIcon or GetIcon("zap") or "rbxassetid://7072718307"
	NineNexusLib.Folder = WindowConfig.ConfigFolder
	NineNexusLib.SaveCfg = WindowConfig.SaveConfig

	if WindowConfig.SaveConfig then
		if not isfolder(WindowConfig.ConfigFolder) then
			makefolder(WindowConfig.ConfigFolder)
		end	
	end

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", NineNexusLib.Themes.Default.Divider, 6), {
		Size = UDim2.new(1, 0, 1, -60)
	}), {
		MakeElement("List", 0, 4),
		MakeElement("Padding", 12, 8, 8, 12)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 24)
	end)

	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", GetIcon("x") or "rbxassetid://7072725342"), {
			Position = UDim2.new(0.5, -9, 0.5, -9),
			Size = UDim2.new(0, 18, 0, 18),
			AnchorPoint = Vector2.new(0.5, 0.5)
		}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", GetIcon("minus") or "rbxassetid://7072719338"), {
			Position = UDim2.new(0.5, -9, 0.5, -9),
			Size = UDim2.new(0, 18, 0, 18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Name = "Ico"
		}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 55)
	})

	-- Улучшенная аватарка пользователя
	local function GetUserAvatar()
		local success, avatarUrl = pcall(function()
			return game:GetService("Players"):GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		return success and avatarUrl or "rbxassetid://7072718307"
	end

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
		Size = UDim2.new(0, 165, 1, -55),
		Position = UDim2.new(0, 0, 0, 55)
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
			Size = UDim2.new(0, 1.5, 1, 0),
			Position = UDim2.new(1, -1.5, 0, 0)
		}), "Stroke"), 
		TabHolder,
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.new(0, 0, 1, -60)
		}), {
			AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1.5)
			}), "Stroke"), 
			AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 36, 0, 36),
				Position = UDim2.new(0, 12, 0.5, 0)
			}), {
				SetProps(MakeElement("Image", GetUserAvatar()), {
					Size = UDim2.new(1, 0, 1, 0),
					Name = "Avatar"
				}),
				MakeElement("Corner", 1)
			}), "Divider"),
			SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 36, 0, 36),
				Position = UDim2.new(0, 12, 0.5, 0)
			}), {
				AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
				MakeElement("Corner", 1)
			}),
			AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, WindowConfig.HidePremium and 15 or 14), {
				Size = UDim2.new(1, -60, 0, 16),
				Position = WindowConfig.HidePremium and UDim2.new(0, 56, 0, 22) or UDim2.new(0, 56, 0, 18),
				Font = Enum.Font.GothamBold,
				ClipsDescendants = true,
				TextColor3 = NineNexusLib.Themes.Default.Text
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", "@" .. LocalPlayer.Name, 12), {
				Size = UDim2.new(1, -60, 0, 14),
				Position = UDim2.new(0, 56, 1, -32),
				Visible = not WindowConfig.HidePremium,
				ClipsDescendants = true,
				TextColor3 = NineNexusLib.Themes.Default.TextDark
			}), "TextDark")
		}),
	}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 18), {
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.GothamBold,
		TextYAlignment = Enum.TextYAlignment.Center
	}), "Text")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1.5),
		Position = UDim2.new(0, 0, 1, -1.5)
	}), "Stroke")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
		Parent = NineNexus,
		Position = UDim2.new(0.5, -325, 0.5, -190),
		Size = UDim2.new(0, 650, 0, 380),
		ClipsDescendants = true
	}), {
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 55),
			Name = "TopBar"
		}), {
			WindowName,
			WindowTopBarLine,
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
				Size = UDim2.new(0, 75, 0, 35),
				Position = UDim2.new(1, -95, 0, 10)
			}), {
				AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size = UDim2.new(0, 1.5, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0)
				}), "Stroke"), 
				CloseBtn,
				MinimizeBtn
			}), "Second"), 
		}),
		DragPoint,
		WindowStuff
	}), "Main")

	if WindowConfig.ShowIcon then
		WindowName.Position = UDim2.new(0, 55, 0, 0)
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 20, 0, 15.5),
			ImageColor3 = NineNexusLib.Themes.Default.Accent
		})
		WindowIcon.Parent = MainWindow.TopBar
	end	

	AddDraggingFunctionality(DragPoint, MainWindow)

	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false
		UIHidden = true
		NineNexusLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Press RightShift to reopen the interface",
			Image = "eye-off",
			Time = 6
		})
		WindowConfig.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
			MainWindow.Visible = true
			UIHidden = false
		end
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 650, 0, 380)}):Play()
			MinimizeBtn.Ico.Image = GetIcon("minus") or "rbxassetid://7072719338"
			wait(.02)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = GetIcon("plus") or "rbxassetid://7072720870"

			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 170, 0, 55)}):Play()
			wait(0.1)
			WindowStuff.Visible = false	
		end
		Minimized = not Minimized    
	end)

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

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 18), {
			Parent = NineNexus,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 24, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1,
			TextColor3 = NineNexusLib.Themes.Default.Text
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
		wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		wait(2)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
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
			AddThemeObject(SetProps(MakeElement("Image", GetIcon(TabConfig.Icon) or "rbxassetid://7072718307"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 20, 0, 20),
				Position = UDim2.new(0, 12, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 15), {
				Size = UDim2.new(1, -44, 1, 0),
				Position = UDim2.new(0, 44, 0, 0),
				Font = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				Name = "Title",
				TextYAlignment = Enum.TextYAlignment.Center
			}), "Text")
		})

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", NineNexusLib.Themes.Default.Divider, 6), {
			Size = UDim2.new(1, -165, 1, -55),
			Position = UDim2.new(0, 165, 0, 55),
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
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end    
			end
			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end    
			end  
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBold
			Container.Visible = true   
		end)

		local function GetElements(ItemParent)
			local ElementFunction = {}
			function ElementFunction:AddLabel(Text)
				local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 16), {
						Size = UDim2.new(1, -20, 1, 0),
						Position = UDim2.new(0, 20, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke")
				}), "Second")

				local LabelFunction = {}
				function LabelFunction:Set(ToChange)
					LabelFrame.Content.Text = ToChange
				end
				return LabelFunction
			end
			function ElementFunction:AddParagraph(Text, Content)
				Text = Text or "Text"
				Content = Content or "Content"

				local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 16), {
						Size = UDim2.new(1, -20, 0, 18),
						Position = UDim2.new(0, 20, 0, 12),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", "", 14), {
						Size = UDim2.new(1, -32, 0, 0),
						Position = UDim2.new(0, 20, 0, 32),
						Font = Enum.Font.GothamMedium,
						Name = "Content",
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke")
				}), "Second")

				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -32, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 44)
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
				ButtonConfig.Icon = ButtonConfig.Icon or "play"

				local Button = {}

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 42),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 16), {
						Size = UDim2.new(1, -52, 1, 0),
						Position = UDim2.new(0, 20, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", GetIcon(ButtonConfig.Icon) or "rbxassetid://7072718307"), {
						Size = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -32, 0.5, -10),
						ImageColor3 = NineNexusLib.Themes.Default.Accent
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					Click
				}), "Second")

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8)}):Play()
					spawn(function()
						ButtonConfig.Callback()
					end)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 15, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 15, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 15)}):Play()
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

				local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 6), {
					Size = UDim2.new(0, 28, 0, 28),
					Position = UDim2.new(1, -40, 0.5, -14),
					AnchorPoint = Vector2.new(0, 0)
				}), {
					SetProps(MakeElement("Stroke"), {
						Color = ToggleConfig.Color,
						Name = "Stroke",
						Transparency = 0.5,
						Thickness = 1.5
					}),
					SetProps(MakeElement("Image", GetIcon("check") or "rbxassetid://7072706796"), {
						Size = UDim2.new(0, 18, 0, 18),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Name = "Ico"
					}),
				})

				local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 46),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 16), {
						Size = UDim2.new(1, -80, 1, 0),
						Position = UDim2.new(0, 20, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					ToggleBox,
					Click
				}), "Second")

				function Toggle:Set(Value)
					Toggle.Value = Value
					TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Toggle.Value and ToggleConfig.Color or NineNexusLib.Themes.Default.Divider}):Play()
					TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = Toggle.Value and ToggleConfig.Color or NineNexusLib.Themes.Default.Stroke}):Play()
					TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						ImageTransparency = Toggle.Value and 0 or 1, 
						Size = Toggle.Value and UDim2.new(0, 18, 0, 18) or UDim2.new(0, 12, 0, 12)
					}):Play()
					ToggleConfig.Callback(Toggle.Value)
				end    

				Toggle:Set(Toggle.Value)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8)}):Play()
					SaveCfg(game.GameId)
					Toggle:Set(not Toggle.Value)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 15, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 15, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 15)}):Play()
				end)

				if ToggleConfig.Flag then
					NineNexusLib.Flags[ToggleConfig.Flag] = Toggle
				end	
				return Toggle
			end  
			function ElementFunction:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Default = SliderConfig.Default or 50
				SliderConfig.Callback = SliderConfig.Callback or function() end
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Color = SliderConfig.Color or NineNexusLib.Themes.Default.Accent
				SliderConfig.Flag = SliderConfig.Flag or nil
				SliderConfig.Save = SliderConfig.Save or false

				local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
				local Dragging = false

				-- Красивый ползунок
				local SliderThumb = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 1, 0), {
					Size = UDim2.new(0, 20, 0, 20),
					Position = UDim2.new(0, 0, 0.5, -10),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ZIndex = 5
				}), {
					MakeElement("Stroke", SliderConfig.Color, 2)
				})

				local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 8), {
					Size = UDim2.new(0, 0, 0, 8),
					Position = UDim2.new(0, 0, 0.5, -4),
					BackgroundTransparency = 0,
					ClipsDescendants = false,
					ZIndex = 3
				}), {
					SliderThumb
				})

				local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", NineNexusLib.Themes.Default.Stroke, 0, 8), {
					Size = UDim2.new(1, -40, 0, 8),
					Position = UDim2.new(0, 20, 0, 46),
					BackgroundTransparency = 0,
					ZIndex = 2
				}), {
					SliderDrag
				})

				local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 72),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 16), {
						Size = UDim2.new(1, -80, 0, 18),
						Position = UDim2.new(0, 20, 0, 12),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", "50", 15), {
						Size = UDim2.new(0, 60, 0, 18),
						Position = UDim2.new(1, -80, 0, 12),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextXAlignment = Enum.TextXAlignment.Right,
						TextColor3 = SliderConfig.Color
					}), "Text"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					SliderBar
				}), "Second")

				SliderBar.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
						Dragging = true 
					end 
				end)
				SliderBar.InputEnded:Connect(function(Input) 
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
						Dragging = false 
					end 
				end)

				UserInputService.InputChanged:Connect(function(Input)
					if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then 
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale)) 
						SaveCfg(game.GameId)
					end
				end)

				function Slider:Set(Value)
					self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
					local ValuePercent = (self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
					
					TweenService:Create(SliderDrag, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = UDim2.fromScale(ValuePercent, 1)
					}):Play()
					
					TweenService:Create(SliderThumb, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Position = UDim2.new(ValuePercent, 0, 0.5, -10)
					}):Play()
					
					SliderFrame.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
					SliderConfig.Callback(self.Value)
				end      

				Slider:Set(Slider.Value)
				if SliderConfig.Flag then				
					NineNexusLib.Flags[SliderConfig.Flag] = Slider
				end
				return Slider
			end  
			function ElementFunction:AddDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
				DropdownConfig.Options = DropdownConfig.Options or {}
				DropdownConfig.Default = DropdownConfig.Default or ""
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag = DropdownConfig.Flag or nil
				DropdownConfig.Save = DropdownConfig.Save or false

				local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
				local MaxElements = 5

				if not table.find(Dropdown.Options, Dropdown.Value) then
					Dropdown.Value = "..."
				end

				local DropdownList = MakeElement("List", 0, 2)

				local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", NineNexusLib.Themes.Default.Divider, 6), {
					DropdownList
				}), {
					Parent = ItemParent,
					Position = UDim2.new(0, 0, 0, 46),
					Size = UDim2.new(1, 0, 1, -46),
					ClipsDescendants = true
				}), "Divider")

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 46),
					Parent = ItemParent,
					ClipsDescendants = true
				}), {
					DropdownContainer,
					SetProps(SetChildren(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 16), {
							Size = UDim2.new(1, -52, 1, 0),
							Position = UDim2.new(0, 20, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content",
							TextYAlignment = Enum.TextYAlignment.Center
						}), "Text"),
						AddThemeObject(SetProps(MakeElement("Image", GetIcon("chevron-down") or "rbxassetid://7072706796"), {
							Size = UDim2.new(0, 18, 0, 18),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(1, -32, 0.5, 0),
							ImageColor3 = NineNexusLib.Themes.Default.Text,
							Name = "Ico"
						}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Label", "Selected", 14), {
							Size = UDim2.new(1, -60, 1, 0),
							Font = Enum.Font.GothamMedium,
							Name = "Selected",
							TextXAlignment = Enum.TextXAlignment.Right,
							TextYAlignment = Enum.TextYAlignment.Center,
							Position = UDim2.new(0, 20, 0, 0)
						}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1.5),
							Position = UDim2.new(0, 0, 1, -1.5),
							Name = "Line",
							Visible = false
						}), "Stroke"), 
						Click
					}), {
						Size = UDim2.new(1, 0, 0, 46),
						ClipsDescendants = true,
						Name = "F"
					}),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					MakeElement("Corner", 0, 8)
				}), "Second")

				AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
				end)  

				local function AddOptions(Options)
					for _, Option in pairs(Options) do
						local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", NineNexusLib.Themes.Default.Second), {
							MakeElement("Corner", 0, 6),
							AddThemeObject(SetProps(MakeElement("Label", Option, 14, 0.4), {
								Position = UDim2.new(0, 12, 0, 0),
								Size = UDim2.new(1, -12, 1, 0),
								Name = "Title",
								TextYAlignment = Enum.TextYAlignment.Center
							}), "Text")
						}), {
							Parent = DropdownContainer,
							Size = UDim2.new(1, 0, 0, 32),
							BackgroundTransparency = 1,
							ClipsDescendants = true
						}), "Divider")

						AddConnection(OptionBtn.MouseButton1Click, function()
							Dropdown:Set(Option)
							SaveCfg(game.GameId)
						end)

						Dropdown.Buttons[Option] = OptionBtn
					end
				end	

				function Dropdown:Refresh(Options, Delete)
					if Delete then
						for _,v in pairs(Dropdown.Buttons) do
							v:Destroy()
						end    
						table.clear(Dropdown.Options)
						table.clear(Dropdown.Buttons)
					end
					Dropdown.Options = Options
					AddOptions(Dropdown.Options)
				end  

				function Dropdown:Set(Value)
					if not table.find(Dropdown.Options, Value) then
						Dropdown.Value = "..."
						DropdownFrame.F.Selected.Text = Dropdown.Value
						for _, v in pairs(Dropdown.Buttons) do
							TweenService:Create(v, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
							TweenService:Create(v.Title, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
						end	
						return
					end

					Dropdown.Value = Value
					DropdownFrame.F.Selected.Text = Dropdown.Value

					for _, v in pairs(Dropdown.Buttons) do
						TweenService:Create(v, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
						TweenService:Create(v.Title, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
					end	
					TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
					return DropdownConfig.Callback(Dropdown.Value)
				end

				AddConnection(Click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					DropdownFrame.F.Line.Visible = Dropdown.Toggled
					TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
					if #Dropdown.Options > MaxElements then
						TweenService:Create(DropdownFrame, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Dropdown.Toggled and UDim2.new(1, 0, 0, 46 + (MaxElements * 34)) or UDim2.new(1, 0, 0, 46)}):Play()
					else
						TweenService:Create(DropdownFrame, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Dropdown.Toggled and UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 50) or UDim2.new(1, 0, 0, 46)}):Play()
					end
				end)

				Dropdown:Refresh(Dropdown.Options, false)
				Dropdown:Set(Dropdown.Value)
				if DropdownConfig.Flag then				
					NineNexusLib.Flags[DropdownConfig.Flag] = Dropdown
				end
				return Dropdown
			end
			function ElementFunction:AddBind(BindConfig)
				BindConfig.Name = BindConfig.Name or "Keybind"
				BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
				BindConfig.Hold = BindConfig.Hold or false
				BindConfig.Callback = BindConfig.Callback or function() end
				BindConfig.Flag = BindConfig.Flag or nil
				BindConfig.Save = BindConfig.Save or false

				local Bind = {Value, Binding = false, Type = "Bind", Save = BindConfig.Save}
				local Holding = false

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
					Size = UDim2.new(0, 36, 0, 28),
					Position = UDim2.new(1, -48, 0.5, -14),
					AnchorPoint = Vector2.new(0, 0)
				}), {
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					AddThemeObject(SetProps(MakeElement("Label", "F", 14), {
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						Name = "Value"
					}), "Text")
				}), "Main")

				local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 46),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 16), {
						Size = UDim2.new(1, -60, 1, 0),
						Position = UDim2.new(0, 20, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					BindBox,
					Click
				}), "Second")

				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, math.max(36, BindBox.Value.TextBounds.X + 20), 0, 28)}):Play()
				end)

				AddConnection(Click.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						if Bind.Binding then return end
						Bind.Binding = true
						BindBox.Value.Text = "..."
					end
				end)

				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
						if BindConfig.Hold then
							Holding = true
							BindConfig.Callback(Holding)
						else
							BindConfig.Callback()
						end
					elseif Bind.Binding then
						local Key
						pcall(function()
							if not CheckKey(BlacklistedKeys, Input.KeyCode) then
								Key = Input.KeyCode
							end
						end)
						pcall(function()
							if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
								Key = Input.UserInputType
							end
						end)
						Key = Key or Bind.Value
						Bind:Set(Key)
						SaveCfg(game.GameId)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
						if BindConfig.Hold and Holding then
							Holding = false
							BindConfig.Callback(Holding)
						end
					end
				end)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second}):Play()
				end)

				function Bind:Set(Key)
					Bind.Binding = false
					Bind.Value = Key or Bind.Value
					Bind.Value = Bind.Value.Name or Bind.Value
					BindBox.Value.Text = Bind.Value
				end

				Bind:Set(BindConfig.Default)
				if BindConfig.Flag then				
					NineNexusLib.Flags[BindConfig.Flag] = Bind
				end
				return Bind
			end  
			function ElementFunction:AddTextbox(TextboxConfig)
				TextboxConfig = TextboxConfig or {}
				TextboxConfig.Name = TextboxConfig.Name or "Textbox"
				TextboxConfig.Default = TextboxConfig.Default or ""
				TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
				TextboxConfig.Callback = TextboxConfig.Callback or function() end

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local TextboxActual = AddThemeObject(Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3 = NineNexusLib.Themes.Default.Text,
					PlaceholderColor3 = NineNexusLib.Themes.Default.TextDark,
					PlaceholderText = "Enter text...",
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextSize = 14,
					ClearTextOnFocus = false
				}), "Text")

				local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
					Size = UDim2.new(0, 80, 0, 28),
					Position = UDim2.new(1, -92, 0.5, -14),
					AnchorPoint = Vector2.new(0, 0)
				}), {
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					TextboxActual
				}), "Main")

				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 46),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 16), {
						Size = UDim2.new(1, -112, 1, 0),
						Position = UDim2.new(0, 20, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextYAlignment = Enum.TextYAlignment.Center
					}), "Text"),
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
					TextContainer,
					Click
				}), "Second")

				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(TextContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, math.max(80, TextboxActual.TextBounds.X + 24), 0, 28)}):Play()
				end)

				AddConnection(TextboxActual.FocusLost, function()
					TextboxConfig.Callback(TextboxActual.Text)
					if TextboxConfig.TextDisappear then
						TextboxActual.Text = ""
					end	
				end)

				TextboxActual.Text = TextboxConfig.Default

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.R * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.G * 255 + 8, NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second.B * 255 + 8)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = NineNexusLib.Themes[NineNexusLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TextboxActual:CaptureFocus()
				end)
			end 
			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(88, 166, 255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
				ColorpickerConfig.Save = ColorpickerConfig.Save or false

				local ColorH, ColorS, ColorV = 1, 1, 1
				local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -30, 1, 0),
					Visible = false,
					Image = "rbxassetid://4155801252"
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
					ColorSelection
				})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, 24, 1, 0),
					Position = UDim2.new(1, -24, 0, 0),
					Visible = false
				}, {
					Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))},}),
					Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
					HueSelection
				})

				local ColorpickerContainer = Create("Frame", {
					Position = UDim2.new(0, 0, 0, 46),
					Size = UDim2.new(1, 0, 1, -46),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {
					Hue,
					Color,
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 20),
						PaddingRight = UDim.new(0, 20),
						PaddingBottom = UDim.new(0, 16),
						PaddingTop = UDim.new(0, 16)
					})
				})

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 6), {
					Size = UDim2.new(0, 28, 0, 28),
					Position = UDim2.new(1, -40, 0.5, -14),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = ColorpickerConfig.Default
				}), {
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke")
				}), "Main")

				local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 46),
					Parent = ItemParent
				}), {
					SetProps(SetChildren(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 16), {
							Size = UDim2.new(1, -80, 1, 0),
							Position = UDim2.new(0, 20, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content",
							TextYAlignment = Enum.TextYAlignment.Center
						}), "Text"),
						ColorpickerBox,
						Click,
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1.5),
							Position = UDim2.new(0, 0, 1, -1.5),
							Name = "Line",
							Visible = false
						}), "Stroke"), 
					}), {
						Size = UDim2.new(1, 0, 0, 46),
						ClipsDescendants = true,
						Name = "F"
					}),
					ColorpickerContainer,
					AddThemeObject(MakeElement("Stroke", NineNexusLib.Themes.Default.Stroke, 1.5), "Stroke"),
				}), "Second")

				AddConnection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					TweenService:Create(ColorpickerFrame, TweenInfo.new(.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 160) or UDim2.new(1, 0, 0, 46)}):Play()
					Color.Visible = Colorpicker.Toggled
					Hue.Visible = Colorpicker.Toggled
					ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)

				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					Colorpicker:Set(ColorpickerBox.BackgroundColor3)
					ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
					SaveCfg(game.GameId)
				end

				ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
				ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
				ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)

				AddConnection(Color.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
						ColorInput = AddConnection(RunService.RenderStepped, function()
							local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
							local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
							ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
							ColorS = ColorX
							ColorV = 1 - ColorY
							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Color.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
					end
				end)

				AddConnection(Hue.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end;

						HueInput = AddConnection(RunService.RenderStepped, function()
							local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

							HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
							ColorH = 1 - HueY

							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Hue.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end
					end
				end)

				function Colorpicker:Set(Value)
					Colorpicker.Value = Value
					ColorpickerBox.BackgroundColor3 = Colorpicker.Value
					ColorpickerConfig.Callback(Colorpicker.Value)
				end

				Colorpicker:Set(Colorpicker.Value)
				if ColorpickerConfig.Flag then				
					NineNexusLib.Flags[ColorpickerConfig.Flag] = Colorpicker
				end
				return Colorpicker
			end  
			return ElementFunction   
		end	

		local ElementFunction = {}

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 32),
				Parent = Container
			}), {
				AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 16), {
					Size = UDim2.new(1, -20, 0, 18),
					Position = UDim2.new(0, 0, 0, 4),
					Font = Enum.Font.GothamBold,
					TextColor3 = NineNexusLib.Themes.Default.Accent
				}), "TextDark"),
				SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size = UDim2.new(1, 0, 1, -28),
					Position = UDim2.new(0, 0, 0, 28),
					Name = "Holder"
				}), {
					MakeElement("List", 0, 8)
				}),
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

		for i, v in next, GetElements(Container) do
			ElementFunction[i] = v 
		end

		if TabConfig.PremiumOnly then
			for i, v in next, ElementFunction do
				ElementFunction[i] = function() end
			end    
			Container:FindFirstChild("UIListLayout"):Destroy()
			Container:FindFirstChild("UIPadding"):Destroy()
			SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 1, 0),
				Parent = Container
			}), {
				AddThemeObject(SetProps(MakeElement("Image", GetIcon("lock") or "rbxassetid://7072706796"), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(0, 20, 0, 20),
					ImageTransparency = 0.4,
					ImageColor3 = NineNexusLib.Themes.Default.TextDark
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Premium Access Required", 18), {
					Size = UDim2.new(1, -50, 0, 18),
					Position = UDim2.new(0, 50, 0, 24),
					TextTransparency = 0.1,
					Font = Enum.Font.GothamBold
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Image", GetIcon("shield") or "rbxassetid://7072706796"), {
					Size = UDim2.new(0, 64, 0, 64),
					Position = UDim2.new(0, 90, 0, 120),
					ImageColor3 = NineNexusLib.Themes.Default.Accent
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 16), {
					Size = UDim2.new(1, -170, 0, 18),
					Position = UDim2.new(0, 170, 0, 124),
					Font = Enum.Font.GothamBold
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "This section contains premium features. Get premium access in our Discord server to unlock all features.", 14), {
					Size = UDim2.new(1, -220, 0, 40),
					Position = UDim2.new(0, 170, 0, 150),
					TextWrapped = true,
					TextTransparency = 0.4,
					Font = Enum.Font.GothamMedium
				}), "Text")
			})
		end
		return ElementFunction   
	end  
	
	NineNexusLib:MakeNotification({
		Name = "NineNexus Library",
		Content = "Successfully initialized with enhanced UI and features!",
		Image = "zap",
		Time = 6
	})
	
	return TabFunction
end   

function NineNexusLib:Destroy()
	NineNexus:Destroy()
end

return NineNexusLib
