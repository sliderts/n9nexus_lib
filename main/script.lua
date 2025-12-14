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
			Main = Color3.fromRGB(20, 20, 25),
			Second = Color3.fromRGB(28, 28, 35),
			Stroke = Color3.fromRGB(55, 55, 65),
			Divider = Color3.fromRGB(45, 45, 55),
			Text = Color3.fromRGB(245, 245, 250),
			TextDark = Color3.fromRGB(160, 160, 170),
			Accent = Color3.fromRGB(88, 101, 242)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false
}

-- Иконки
local Icons = {}
local Success, Response = pcall(function()
	Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/frappedevs/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
	warn("NineNexus Library - Failed to load icons. Error: " .. Response)
end	

local function GetIcon(IconName)
	if Icons[IconName] then
		return Icons[IconName]
	else
		return "rbxassetid://3944680095"
	end
end   

-- Создание ScreenGui
local NineNexus = Instance.new("ScreenGui")
NineNexus.Name = "NineNexus"
NineNexus.ResetOnSpawn = false
NineNexus.IgnoreGuiInset = true

if syn then
	syn.protect_gui(NineNexus)
	NineNexus.Parent = game.CoreGui
else
	NineNexus.Parent = gethui() or game.CoreGui
end

-- Удаление старых интерфейсов
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
	if not NineNexusLib:IsRunning() then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(NineNexusLib.Connections, SignalConnect)
	return SignalConnect
end

-- Очистка соединений при закрытии
task.spawn(function()
	while NineNexusLib:IsRunning() do
		wait()
	end
	for _, Connection in pairs(NineNexusLib.Connections) do
		Connection:Disconnect()
	end
end)

-- Функция перетаскивания
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
			TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
			}):Play()
		end
	end)
end   

-- Вспомогательные функции создания элементов
local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in pairs(Properties or {}) do
		Object[i] = v
	end
	for i, v in pairs(Children or {}) do
		v.Parent = Object
	end
	return Object
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

-- Контейнер для уведомлений
local NotificationHolder = Create("Frame", {
	Name = "NotificationHolder",
	Position = UDim2.new(1, -320, 1, -20),
	Size = UDim2.new(0, 300, 1, -20),
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1,
	Parent = NineNexus
}, {
	Create("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8)
	})
})

-- Функция уведомлений с прогресс-баром
function NineNexusLib:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig.Name = NotificationConfig.Name or "NineNexus"
		NotificationConfig.Content = NotificationConfig.Content or "Notification"
		NotificationConfig.Image = NotificationConfig.Image or "bell"
		NotificationConfig.Time = NotificationConfig.Time or 5

		local NotificationFrame = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 80),
			Position = UDim2.new(1, 50, 0, 0),
			BackgroundColor3 = NineNexusLib.Themes.Default.Second,
			BorderSizePixel = 0,
			Parent = NotificationHolder
		}, {
			Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
			Create("UIStroke", {
				Color = NineNexusLib.Themes.Default.Stroke,
				Thickness = 1.5
			}),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12)
			}),
			Create("ImageLabel", {
				Name = "Icon",
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Image = GetIcon(NotificationConfig.Image),
				ImageColor3 = NineNexusLib.Themes.Default.Accent
			}),
			Create("TextLabel", {
				Name = "Title",
				Size = UDim2.new(1, -35, 0, 20),
				Position = UDim2.new(0, 35, 0, 0),
				BackgroundTransparency = 1,
				Text = NotificationConfig.Name,
				TextColor3 = NineNexusLib.Themes.Default.Text,
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Create("TextLabel", {
				Name = "Content",
				Size = UDim2.new(1, -35, 0, 16),
				Position = UDim2.new(0, 35, 0, 22),
				BackgroundTransparency = 1,
				Text = NotificationConfig.Content,
				TextColor3 = NineNexusLib.Themes.Default.TextDark,
				TextSize = 14,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true
			}),
			Create("Frame", {
				Name = "ProgressBar",
				Size = UDim2.new(1, 0, 0, 3),
				Position = UDim2.new(0, 0, 1, -3),
				BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
				BorderSizePixel = 0
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
				Create("Frame", {
					Name = "Fill",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = NineNexusLib.Themes.Default.Accent,
					BorderSizePixel = 0
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 2)})
				})
			})
		})

		-- Анимация появления
		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()

		-- Анимация прогресс-бара
		TweenService:Create(NotificationFrame.ProgressBar.Fill, TweenInfo.new(NotificationConfig.Time, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0)
		}):Play()

		-- Удаление уведомления
		wait(NotificationConfig.Time)
		TweenService:Create(NotificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 50, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		wait(0.3)
		NotificationFrame:Destroy()
	end)
end    

-- Основная функция создания окна
function NineNexusLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local UIHidden = false

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "NineNexus"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.HidePremium = WindowConfig.HidePremium or false
	WindowConfig.IntroEnabled = WindowConfig.IntroEnabled ~= false
	WindowConfig.IntroText = WindowConfig.IntroText or "NineNexus"
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = WindowConfig.Icon or "home"

	NineNexusLib.Folder = WindowConfig.ConfigFolder
	NineNexusLib.SaveCfg = WindowConfig.SaveConfig

	if WindowConfig.SaveConfig then
		if not isfolder(WindowConfig.ConfigFolder) then
			makefolder(WindowConfig.ConfigFolder)
		end	
	end

	-- Создание главного окна
	local MainWindow = Create("Frame", {
		Name = "MainWindow",
		Position = UDim2.new(0.5, -400, 0.5, -250),
		Size = UDim2.new(0, 800, 0, 500),
		BackgroundColor3 = NineNexusLib.Themes.Default.Main,
		BorderSizePixel = 0,
		Parent = NineNexus
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
		Create("UIStroke", {
			Color = NineNexusLib.Themes.Default.Stroke,
			Thickness = 2
		})
	})

	-- Заголовок окна
	local TopBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = NineNexusLib.Themes.Default.Second,
		BorderSizePixel = 0,
		Parent = MainWindow
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
		Create("Frame", {
			Size = UDim2.new(1, 0, 0, 25),
			Position = UDim2.new(0, 0, 1, -25),
			BackgroundColor3 = NineNexusLib.Themes.Default.Second,
			BorderSizePixel = 0
		}),
		Create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
			BorderSizePixel = 0
		})
	})

	-- Название окна
	local WindowTitle = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Text = WindowConfig.Name,
		TextColor3 = NineNexusLib.Themes.Default.Text,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar
	})

	-- Кнопки управления
	local ControlButtons = Create("Frame", {
		Name = "Controls",
		Size = UDim2.new(0, 80, 0, 30),
		Position = UDim2.new(1, -90, 0, 10),
		BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
		BorderSizePixel = 0,
		Parent = TopBar
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 8)})
	})

	local MinimizeBtn = Create("TextButton", {
		Name = "Minimize",
		Size = UDim2.new(0.5, -1, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = ControlButtons
	}, {
		Create("ImageLabel", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = GetIcon("minus"),
			ImageColor3 = NineNexusLib.Themes.Default.Text
		})
	})

	local CloseBtn = Create("TextButton", {
		Name = "Close",
		Size = UDim2.new(0.5, -1, 1, 0),
		Position = UDim2.new(0.5, 1, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = ControlButtons
	}, {
		Create("ImageLabel", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = GetIcon("x"),
			ImageColor3 = NineNexusLib.Themes.Default.Text
		})
	})

	-- Разделитель между кнопками
	Create("Frame", {
		Size = UDim2.new(0, 1, 0, 20),
		Position = UDim2.new(0.5, 0, 0, 5),
		BackgroundColor3 = NineNexusLib.Themes.Default.Main,
		BorderSizePixel = 0,
		Parent = ControlButtons
	})

	-- Боковая панель с табами
	local SideBar = Create("Frame", {
		Name = "SideBar",
		Size = UDim2.new(0, 200, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = NineNexusLib.Themes.Default.Second,
		BorderSizePixel = 0,
		Parent = MainWindow
	}, {
		Create("Frame", {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -1, 0, 0),
			BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
			BorderSizePixel = 0
		})
	})

	-- Контейнер для табов
	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = NineNexusLib.Themes.Default.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = SideBar
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4)
		}),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8)
		})
	})

	-- Обновление размера канваса для табов
	AddConnection(TabContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabContainer.UIListLayout.AbsoluteContentSize.Y + 20)
	end)

	-- Информация о пользователе
	local UserInfo = Create("Frame", {
		Name = "UserInfo",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 1, -60),
		BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
		BorderSizePixel = 0,
		Parent = SideBar
	}, {
		Create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = NineNexusLib.Themes.Default.Divider,
			BorderSizePixel = 0
		})
	})

	-- Аватар пользователя с правильным API
	local UserAvatar = Create("Frame", {
		Name = "Avatar",
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Parent = UserInfo
	}, {
		Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
		Create("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=150&height=150&format=png",
			ScaleType = Enum.ScaleType.Crop
		}, {
			Create("UICorner", {CornerRadius = UDim.new(1, 0)})
		}),
		Create("UIStroke", {
			Color = NineNexusLib.Themes.Default.Accent,
			Thickness = 2
		})
	})

	-- Имя пользователя
	Create("TextLabel", {
		Name = "Username",
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.new(0, 55, 0, 12),
		BackgroundTransparency = 1,
		Text = LocalPlayer.DisplayName,
		TextColor3 = NineNexusLib.Themes.Default.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = UserInfo
	})

	Create("TextLabel", {
		Name = "UserTag",
		Size = UDim2.new(1, -60, 0, 14),
		Position = UDim2.new(0, 55, 0, 30),
		BackgroundTransparency = 1,
		Text = "@" .. LocalPlayer.Name,
		TextColor3 = NineNexusLib.Themes.Default.TextDark,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = UserInfo
	})

	-- Основной контент
	local ContentArea = Create("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -200, 1, -50),
		Position = UDim2.new(0, 200, 0, 50),
		BackgroundTransparency = 1,
		Parent = MainWindow
	})

	-- Функции кнопок управления
	AddConnection(CloseBtn.MouseButton1Click, function()
		MainWindow.Visible = false
		UIHidden = true
		NineNexusLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Press Insert to show interface",
			Image = "eye-off",
			Time = 3
		})
		WindowConfig.CloseCallback()
	end)

	AddConnection(MinimizeBtn.MouseButton1Click, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				Size = UDim2.new(0, 800, 0, 500)
			}):Play()
			SideBar.Visible = true
			ContentArea.Visible = true
		else
			TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				Size = UDim2.new(0, math.max(WindowTitle.TextBounds.X + 140, 300), 0, 50)
			}):Play()
			SideBar.Visible = false
			ContentArea.Visible = false
		end
		Minimized = not Minimized
	end)

	-- Клавиша Insert для показа/скрытия
	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == Enum.KeyCode.Insert then
			if UIHidden then
				MainWindow.Visible = true
				UIHidden = false
			else
				MainWindow.Visible = false
				UIHidden = true
				NineNexusLib:MakeNotification({
					Name = "Interface Hidden",
					Content = "Press Insert to show interface",
					Image = "eye-off",
					Time = 3
				})
			end
		end
	end)

	-- Перетаскивание
	AddDraggingFunctionality(TopBar, MainWindow)

	-- Функции для работы с табами
	local TabFunction = {}
	
	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or "home"
		TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

		-- Создание кнопки таба
		local TabButton = Create("TextButton", {
			Name = "TabButton",
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			Parent = TabContainer
		}, {
			Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
			Create("Frame", {
				Name = "Highlight",
				Size = UDim2.new(0, 3, 0, 20),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = NineNexusLib.Themes.Default.Accent,
				BorderSizePixel = 0,
				Visible = false
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0, 2)})
			}),
			Create("ImageLabel", {
				Name = "Icon",
				Size = UDim2.new(0, 20, 0, 20),
				Position = UDim2.new(0, 12, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Image = GetIcon(TabConfig.Icon),
				ImageColor3 = NineNexusLib.Themes.Default.TextDark
			}),
			Create("TextLabel", {
				Name = "Label",
				Size = UDim2.new(1, -45, 1, 0),
				Position = UDim2.new(0, 40, 0, 0),
				BackgroundTransparency = 1,
				Text = TabConfig.Name,
				TextColor3 = NineNexusLib.Themes.Default.TextDark,
				TextSize = 14,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		})

		-- Контейнер для содержимого таба
		local TabContent = Create("ScrollingFrame", {
			Name = "TabContent_" .. TabConfig.Name,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = NineNexusLib.Themes.Default.Stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Parent = ContentArea
		}, {
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8)
			}),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 20)
			})
		})

		-- Обновление размера канваса
		AddConnection(TabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContent.UIListLayout.AbsoluteContentSize.Y + 40)
		end)

		-- Если это первый таб, делаем его активным
		if FirstTab then
			FirstTab = false
			TabButton.BackgroundTransparency = 0.9
			TabButton.Highlight.Visible = true
			TabButton.Icon.ImageColor3 = NineNexusLib.Themes.Default.Accent
			TabButton.Label.TextColor3 = NineNexusLib.Themes.Default.Text
			TabButton.Label.Font = Enum.Font.GothamBold
			TabContent.Visible = true
		end

		-- Обработка клика по табу
		AddConnection(TabButton.MouseButton1Click, function()
			-- Деактивируем все табы
			for _, Tab in pairs(TabContainer:GetChildren()) do
				if Tab:IsA("TextButton") then
					Tab.BackgroundTransparency = 1
					Tab.Highlight.Visible = false
					Tab.Icon.ImageColor3 = NineNexusLib.Themes.Default.TextDark
					Tab.Label.TextColor3 = NineNexusLib.Themes.Default.TextDark
					Tab.Label.Font = Enum.Font.GothamSemibold
				end
			end
			
			-- Скрываем все контенты
			for _, Content in pairs(ContentArea:GetChildren()) do
				if Content.Name:find("TabContent_") then
					Content.Visible = false
				end
			end
			
			-- Активируем текущий таб
			TabButton.BackgroundTransparency = 0.9
			TabButton.Highlight.Visible = true
			TabButton.Icon.ImageColor3 = NineNexusLib.Themes.Default.Accent
			TabButton.Label.TextColor3 = NineNexusLib.Themes.Default.Text
			TabButton.Label.Font = Enum.Font.GothamBold
			TabContent.Visible = true
		end)

		-- Hover эффекты
		AddConnection(TabButton.MouseEnter, function()
			if not TabButton.Highlight.Visible then
				TweenService:Create(TabButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
					BackgroundTransparency = 0.95
				}):Play()
			end
		end)

		AddConnection(TabButton.MouseLeave, function()
			if not TabButton.Highlight.Visible then
				TweenService:Create(TabButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
					BackgroundTransparency = 1
				}):Play()
			end
		end)

		-- Функции для элементов
		local ElementFunction = {}

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = Create("Frame", {
				Name = "Section",
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Parent = TabContent
			}, {
				Create("TextLabel", {
					Name = "SectionTitle",
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = SectionConfig.Name,
					TextColor3 = NineNexusLib.Themes.Default.TextDark,
					TextSize = 16,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				Create("Frame", {
					Name = "SectionContent",
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 0, 25),
					BackgroundTransparency = 1
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6)
					})
				})
			})

			-- Обновление размера секции
			AddConnection(SectionFrame.SectionContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.SectionContent.UIListLayout.AbsoluteContentSize.Y + 30)
				SectionFrame.SectionContent.Size = UDim2.new(1, 0, 0, SectionFrame.SectionContent.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}

			function SectionFunction:AddToggle(ToggleConfig)
				ToggleConfig = ToggleConfig or {}
				ToggleConfig.Name = ToggleConfig.Name or "Toggle"
				ToggleConfig.Default = ToggleConfig.Default or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end

				local Toggle = {Value = ToggleConfig.Default}

				local ToggleFrame = Create("Frame", {
					Name = "Toggle",
					Size = UDim2.new(1, 0, 0, 45),
					BackgroundColor3 = NineNexusLib.Themes.Default.Second,
					BorderSizePixel = 0,
					Parent = SectionFrame.SectionContent
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
					Create("UIStroke", {
						Color = NineNexusLib.Themes.Default.Stroke,
						Thickness = 1
					}),
					Create("TextLabel", {
						Name = "Label",
						Size = UDim2.new(1, -60, 1, 0),
						Position = UDim2.new(0, 15, 0, 0),
						BackgroundTransparency = 1,
						Text = ToggleConfig.Name,
						TextColor3 = NineNexusLib.Themes.Default.Text,
						TextSize = 14,
						Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Create("TextButton", {
						Name = "ToggleButton",
						Size = UDim2.new(0, 45, 0, 25),
						Position = UDim2.new(1, -55, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = ToggleConfig.Default and NineNexusLib.Themes.Default.Accent or NineNexusLib.Themes.Default.Stroke,
						BorderSizePixel = 0,
						Text = ""
					}, {
						Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
						Create("Frame", {
							Name = "Thumb",
							Size = UDim2.new(0, 19, 0, 19),
							Position = ToggleConfig.Default and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 0
						}, {
							Create("UICorner", {CornerRadius = UDim.new(1, 0)})
						})
					})
				})

				function Toggle:Set(Value)
					self.Value = Value
					
					TweenService:Create(ToggleFrame.ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
						BackgroundColor3 = Value and NineNexusLib.Themes.Default.Accent or NineNexusLib.Themes.Default.Stroke
					}):Play()
					
					TweenService:Create(ToggleFrame.ToggleButton.Thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
						Position = Value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
					}):Play()
					
					ToggleConfig.Callback(Value)
				end

				AddConnection(ToggleFrame.ToggleButton.MouseButton1Click, function()
					Toggle:Set(not Toggle.Value)
				end)

				return Toggle
			end

			function SectionFunction:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Default = SliderConfig.Default or 50
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Callback = SliderConfig.Callback or function() end

				local Slider = {Value = SliderConfig.Default}
				local Dragging = false

				local SliderFrame = Create("Frame", {
					Name = "Slider",
					Size = UDim2.new(1, 0, 0, 65),
					BackgroundColor3 = NineNexusLib.Themes.Default.Second,
					BorderSizePixel = 0,
					Parent = SectionFrame.SectionContent
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
					Create("UIStroke", {
						Color = NineNexusLib.Themes.Default.Stroke,
						Thickness = 1
					}),
					Create("TextLabel", {
						Name = "Label",
						Size = UDim2.new(1, -80, 0, 20),
						Position = UDim2.new(0, 15, 0, 10),
						BackgroundTransparency = 1,
						Text = SliderConfig.Name,
						TextColor3 = NineNexusLib.Themes.Default.Text,
						TextSize = 14,
						Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Create("TextLabel", {
						Name = "Value",
						Size = UDim2.new(0, 70, 0, 20),
						Position = UDim2.new(1, -85, 0, 10),
						BackgroundTransparency = 1,
						Text = tostring(SliderConfig.Default) .. SliderConfig.ValueName,
						TextColor3 = NineNexusLib.Themes.Default.Accent,
						TextSize = 14,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Right
					}),
					Create("Frame", {
						Name = "SliderTrack",
						Size = UDim2.new(1, -30, 0, 6),
						Position = UDim2.new(0, 15, 0, 40),
						BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
						BorderSizePixel = 0
					}, {
						Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
						Create("Frame", {
							Name = "SliderFill",
							Size = UDim2.new(((SliderConfig.Default - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)), 0, 1, 0),
							BackgroundColor3 = NineNexusLib.Themes.Default.Accent,
							BorderSizePixel = 0
						}, {
							Create("UICorner", {CornerRadius = UDim.new(0, 3)})
						}),
						Create("Frame", {
							Name = "SliderThumb",
							Size = UDim2.new(0, 16, 0, 16),
							Position = UDim2.new(((SliderConfig.Default - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)), -8, 0.5, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 0
						}, {
							Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
							Create("UIStroke", {
								Color = NineNexusLib.Themes.Default.Accent,
								Thickness = 2
							})
						})
					})
				})

				function Slider:Set(Value)
					self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
					local Percentage = (self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
					
					SliderFrame.Value.Text = tostring(self.Value) .. SliderConfig.ValueName
					
					TweenService:Create(SliderFrame.SliderTrack.SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {
						Size = UDim2.new(Percentage, 0, 1, 0)
					}):Play()
					
					TweenService:Create(SliderFrame.SliderTrack.SliderThumb, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {
						Position = UDim2.new(Percentage, -8, 0.5, 0)
					}):Play()
					
					SliderConfig.Callback(self.Value)
				end

				AddConnection(SliderFrame.SliderTrack.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = true
					end
				end)

				AddConnection(SliderFrame.SliderTrack.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = false
					end
				end)

				AddConnection(UserInputService.InputChanged, function(Input)
					if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
						local SizeScale = math.clamp((Input.Position.X - SliderFrame.SliderTrack.AbsolutePosition.X) / SliderFrame.SliderTrack.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
					end
				end)

				return Slider
			end

			function SectionFunction:AddButton(ButtonConfig)
				ButtonConfig = ButtonConfig or {}
				ButtonConfig.Name = ButtonConfig.Name or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end

				local ButtonFrame = Create("TextButton", {
					Name = "Button",
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundColor3 = NineNexusLib.Themes.Default.Second,
					BorderSizePixel = 0,
					Text = "",
					Parent = SectionFrame.SectionContent
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
					Create("UIStroke", {
						Color = NineNexusLib.Themes.Default.Stroke,
						Thickness = 1
					}),
					Create("TextLabel", {
						Name = "Label",
						Size = UDim2.new(1, -40, 1, 0),
						Position = UDim2.new(0, 15, 0, 0),
						BackgroundTransparency = 1,
						Text = ButtonConfig.Name,
						TextColor3 = NineNexusLib.Themes.Default.Text,
						TextSize = 14,
						Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Create("ImageLabel", {
						Name = "Icon",
						Size = UDim2.new(0, 18, 0, 18),
						Position = UDim2.new(1, -30, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundTransparency = 1,
						Image = GetIcon("play"),
						ImageColor3 = NineNexusLib.Themes.Default.TextDark
					})
				})

				AddConnection(ButtonFrame.MouseButton1Click, function()
					ButtonConfig.Callback()
				end)

				-- Hover эффекты
				AddConnection(ButtonFrame.MouseEnter, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
						BackgroundColor3 = Color3.fromRGB(
							NineNexusLib.Themes.Default.Second.R * 255 + 10,
							NineNexusLib.Themes.Default.Second.G * 255 + 10,
							NineNexusLib.Themes.Default.Second.B * 255 + 10
						)
					}):Play()
				end)

				AddConnection(ButtonFrame.MouseLeave, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
						BackgroundColor3 = NineNexusLib.Themes.Default.Second
					}):Play()
				end)

				return ButtonFrame
			end

			function SectionFunction:AddDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
				DropdownConfig.Options = DropdownConfig.Options or {"Option 1", "Option 2", "Option 3"}
				DropdownConfig.Default = DropdownConfig.Default or DropdownConfig.Options[1]
				DropdownConfig.Callback = DropdownConfig.Callback or function() end

				local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Open = false}

				local DropdownFrame = Create("Frame", {
					Name = "Dropdown",
					Size = UDim2.new(1, 0, 0, 45),
					BackgroundColor3 = NineNexusLib.Themes.Default.Second,
					BorderSizePixel = 0,
					Parent = SectionFrame.SectionContent
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
					Create("UIStroke", {
						Color = NineNexusLib.Themes.Default.Stroke,
						Thickness = 1
					}),
					Create("TextLabel", {
						Name = "Label",
						Size = UDim2.new(1, -120, 1, 0),
						Position = UDim2.new(0, 15, 0, 0),
						BackgroundTransparency = 1,
						Text = DropdownConfig.Name,
						TextColor3 = NineNexusLib.Themes.Default.Text,
						TextSize = 14,
						Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Create("TextButton", {
						Name = "DropdownButton",
						Size = UDim2.new(0, 100, 0, 30),
						Position = UDim2.new(1, -110, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = NineNexusLib.Themes.Default.Stroke,
						BorderSizePixel = 0,
						Text = ""
					}, {
						Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
						Create("TextLabel", {
							Name = "Value",
							Size = UDim2.new(1, -25, 1, 0),
							Position = UDim2.new(0, 8, 0, 0),
							BackgroundTransparency = 1,
							Text = DropdownConfig.Default,
							TextColor3 = NineNexusLib.Themes.Default.Text,
							TextSize = 12,
							Font = Enum.Font.Gotham,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd
						}),
						Create("ImageLabel", {
							Name = "Arrow",
							Size = UDim2.new(0, 12, 0, 12),
							Position = UDim2.new(1, -18, 0.5, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Image = GetIcon("chevron-down"),
							ImageColor3 = NineNexusLib.Themes.Default.TextDark
						})
					}),
					Create("Frame", {
						Name = "DropdownList",
						Size = UDim2.new(0, 100, 0, 0),
						Position = UDim2.new(1, -110, 1, 5),
						BackgroundColor3 = NineNexusLib.Themes.Default.Main,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 10
					}, {
						Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
						Create("UIStroke", {
							Color = NineNexusLib.Themes.Default.Stroke,
							Thickness = 1
						}),
						Create("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder
						})
					})
				})

				-- Создание опций
				for _, Option in pairs(DropdownConfig.Options) do
					local OptionButton = Create("TextButton", {
						Name = "Option",
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = "",
						Parent = DropdownFrame.DropdownList
					}, {
						Create("TextLabel", {
							Size = UDim2.new(1, -10, 1, 0),
							Position = UDim2.new(0, 8, 0, 0),
							BackgroundTransparency = 1,
							Text = Option,
							TextColor3 = NineNexusLib.Themes.Default.Text,
							TextSize = 12,
							Font = Enum.Font.Gotham,
							TextXAlignment = Enum.TextXAlignment.Left
						})
					})

					AddConnection(OptionButton.MouseButton1Click, function()
						Dropdown:Set(Option)
						Dropdown:Toggle()
					end)

					AddConnection(OptionButton.MouseEnter, function()
						OptionButton.BackgroundTransparency = 0.9
					end)

					AddConnection(OptionButton.MouseLeave, function()
						OptionButton.BackgroundTransparency = 1
					end)
				end

				function Dropdown:Set(Value)
					self.Value = Value
					DropdownFrame.DropdownButton.Value.Text = Value
					DropdownConfig.Callback(Value)
				end

				function Dropdown:Toggle()
					self.Open = not self.Open
					DropdownFrame.DropdownList.Visible = self.Open
					
					if self.Open then
						DropdownFrame.DropdownList.Size = UDim2.new(0, 100, 0, #DropdownConfig.Options * 25)
					end
					
					TweenService:Create(DropdownFrame.DropdownButton.Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
						Rotation = self.Open and 180 or 0
					}):Play()
				end

				AddConnection(DropdownFrame.DropdownButton.MouseButton1Click, function()
					Dropdown:Toggle()
				end)

				return Dropdown
			end

			return SectionFunction
		end

		return ElementFunction
	end

	-- Показ уведомления о загрузке
	NineNexusLib:MakeNotification({
		Name = "NineNexus",
		Content = "Interface loaded successfully!",
		Image = "check-circle",
		Time = 3
	})

	return TabFunction
end

function NineNexusLib:Destroy()
	NineNexus:Destroy()
end

return NineNexusLib
