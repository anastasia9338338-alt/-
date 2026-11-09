for _, UI in game.CoreGui:GetChildren() do
    if UI.Name == "TheWorstUIV2" then
        UI:Destroy()
        task.wait()

        break
    end
end

-- TheWorstUI V2
    getgenv().UI = {
        Window = nil,
        ScreenGui = nil,
        Taskbar = nil,

        Connections = {},
        SearchElements = {},

        Elements = {
            Texts = {},
            LittleTexts = {},
            Elements = {},
            SecondElements = {},
            ThirdElements = {},
            Sections = {},
            Noise = {},
            Vingette = {}
        },

        Backgrounds = {},
        BackgroundImage = "",

        NotificationSettings = {
            Enabled = false,
            NotificationOrder = 0,
            NotificationsCounter = 0,
            Sound = "",
            Volume = 0
        },

        AutoCloseSettings = {
            Enabled = false,
            Speed = 0.3,
            Delay = 0.5
        },

        WindowsSettings = {
            AutoUnlockMouse = false,
            MouseUnlocked = false
        },

        Windows = {},
        WindowIcons = {},
        Flags = {},

        PinnedWindowsParent = nil,
        UnpinnedWindowsParent = nil,

        Themes = {
            Original = {
                TaskbarColor = Color3.fromRGB(20, 20, 20),
                TaskbarTransparency = 0.4,
                TaskbarBackgroundImage = "",

                WindowsColor = Color3.fromRGB(20, 20, 20),
                WindowsTransparency = 0.4,
                WindowsBackgroundImage = "",

                StrokeColor = Color3.fromRGB(0, 0, 0),
                StrokeTransparency = 0.85,
                StrokeThickness = 1,

                DividierColor = Color3.fromRGB(240, 240, 240),
                DividierTransparency = 0.5,

                ElementsColor = Color3.fromRGB(20, 20, 20),
                ElementsTransparency = 1,

                Font = Enum.Font.Code,
                TextColor = Color3.fromRGB(240, 240, 240),
                TextTransparency = 0,
                
                LittleFont = Enum.Font.Code,
                LittleTextColor = Color3.fromRGB(240, 240, 240),
                LittleTextTransparency = 0.5,

                CornerRadius = 30,

                PinnedWindows = {},
            }
        },

        CurrentTheme = "Original",

        ElementCounter = 0,
        Loading = 0,
        Loaded = false,
        ElementInput = false,
        LastElementLoaded = true
    }
    UI.__index = UI

    UI.ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    UI.ScreenGui.Name = "TheWorstUIV2"

-- Services
    local Serv = {
        TweenService = game:GetService("TweenService"),
        UserInputService = game:GetService("UserInputService"),
        HttpService = game:GetService("HttpService"),
        RunService = game:GetService("RunService"),
        CoreGui = game.CoreGui,
        Players = game:GetService("Players")
    }

    local LocalPlayer = Serv.Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    local table, string, next, pcall, game, workspace, tostring, tonumber, typeof, TweenInfo_new, math = table, string, next, pcall, game, workspace, tostring, tonumber, typeof, TweenInfo.new, math

    local string_format = string.format
    local string_gsub = string.gsub
    local string_match = string.match
    local string_sub = string.sub
    
    local table_find = table.find

-- Icons
    local LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/latte-soft/lucide-roblox/refs/heads/master/lib/Icons.luau"))()

    local function GetIcon(IconName)
		if IconName == nil then return nil end

		local NameSplit = IconName:split("://")
		if NameSplit and NameSplit[2] ~= nil then return { Image = IconName, Size = Vector2.new(0, 0), Position = Vector2.new(0, 0) } end

		if IconName ~= nil then 
            local Icon = LucideIcons["48px"][IconName]
            return Icon ~= nil and { Image = "rbxassetid://"..Icon[1], Size = Vector2.new(Icon[2][1], Icon[2][2]), Position = Vector2.new(Icon[3][1], Icon[3][2]) } or "" 
        end

		return ""
	end

    UI.GetIcon = GetIcon

-- Local Functions
    local function AddConnection(Signal: RBXScriptSignal, Function: (...any) -> (), Name: string?): RBXScriptConnection
        local Conn = Signal:Connect(Function)
        UI.Connections[Name ~= nil and Name or #UI.Connections+1] = Conn
        return Conn
    end

    local function RemoveConnection(Connection: string)
        if UI.Connections[Connection] ~= nil then
            UI.Connections[Connection]:Disconnect()
            UI.Connections[Connection] = nil
        end
    end

    local function CreateElement(Name: string, Props: table?, Children: { any }?): Instance
        local Element

        if Name == "RoundFrame" then
            Element = Instance.new("Frame")

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, UI.Themes[UI.CurrentTheme].CornerRadius)
            UICorner.Parent = Element
        elseif Name == "FakeFrame" then
            Element = Instance.new("Frame")
            Element.BackgroundTransparency = 1
        elseif Name == "Noise" then
            Element = Instance.new("ImageLabel")
            Element.Name = "Noise"
            Element.Size = UDim2.new(1, 0, 1, 0)
            Element.Image = "rbxassetid://9968344227"
            Element.ScaleType = Enum.ScaleType.Tile
            Element.TileSize = UDim2.new(0, 128, 0, 128)
            Element.BackgroundTransparency = 1
            Element.ImageTransparency = 0.8
            Element.ZIndex = -100

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, UI.Themes[UI.CurrentTheme].CornerRadius)
            UICorner.Parent = Element

        elseif Name == "Vingette" then
            Element = Instance.new("ImageLabel")
            Element.Name = "Vingette"
            Element.Size = UDim2.new(1, 0, 1, 0)
            Element.Image = "rbxassetid://4576475446"
            Element.BackgroundTransparency = 1
            Element.ImageTransparency = 0
            Element.ZIndex = -99

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, UI.Themes[UI.CurrentTheme].CornerRadius)
            UICorner.Parent = Element

            UI.Elements.Noise[#UI.Elements.Noise+1] = Element
            UI.Elements.Vingette[#UI.Elements.Vingette+1] = Element 
        elseif Name == "Stroke" then
            Element = Instance.new("UIStroke")

            Element.Color = UI.Themes[UI.CurrentTheme].StrokeColor
            Element.Thickness = UI.Themes[UI.CurrentTheme].StrokeThickness
            Element.Transparency = UI.Themes[UI.CurrentTheme].StrokeTransparency
        elseif Name == "Corner" then
            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, UI.Themes[UI.CurrentTheme].CornerRadius)
            return UICorner
        elseif Name == "BackgroundImage" then
            Element = Instance.new("ImageLabel")
            Element.Name = "BackgroundImage"
            Element.Size = UDim2.new(1, 0, 1, 0)
            Element.Image = ""
            Element.BackgroundTransparency = 1
            Element.ImageTransparency = 0
            Element.ZIndex = -200
            Element.ScaleType = Enum.ScaleType.Crop

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, UI.Themes[UI.CurrentTheme].CornerRadius)
            UICorner.Parent = Element

            UI.Backgrounds[#UI.Backgrounds+1] = Element
        else
            Element = Instance.new(Name)
        end

        for Prop, Value in Props or {} do Element[Prop] = Value end
        
        for _, Child in Children or {} do
            if type(Child) == "table" and Child.Instance then
                Child.Instance.Parent = Element
            elseif typeof(Child) == "Instance" then
                Child.Parent = Element
            end
        end

        return Element
    end

    local function SetChildren(Parent: Instance, Children: { Instance }): Instance
        for _, Child in Children do Child.Parent = Parent end
        return Parent
    end

    local function PlayTween(...): TweenBase
        local Parent, Info, Args = table.unpack({...})
        Info = TweenInfo_new(typeof(Info) == "table" and table.unpack(Info) or Info)
        
        local Tween = Serv.TweenService:Create(Parent, Info, Args); Tween:Play()
        return Tween
    end

    local function Round(Number: number, Factor: number): number
        if not Number then return 0 end
        Number = tonumber(Number)
        
        local Sign = Number >= 0 and 1 or -1
        local Result = math.floor(Number / Factor + 0.5 * Sign) * Factor

        if Result < 0 then
            Result = Result + Factor
        end

        if Factor < 1 then
            local Str = tostring(Factor)
            local Dot = Str:find("%.")
            Result = tonumber(string_format("%." .. (Dot and #Str - Dot or 0) .. "f", Result))
        end

        return Result
    end

    local function PlaySound(SoundId: string, Volume: number)
        local Sound = Instance.new("Sound", LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack or nil)
        Sound.SoundId = tostring(SoundId):match("rbxassetid://") and tostring(SoundId) or "rbxassetid://"..tostring(SoundId)
        Sound.Volume = Volume
        Sound:Play()
    end

-- Module Functions
    -- Unload
        function UI:Unload()
            for Key, Conn in pairs(UI.Connections) do
                if typeof(Conn) == "RBXScriptConnection" then
                    Conn:Disconnect()
                end
            end

            table.clear(UI.Connections)
            table.clear(UI.Elements)
            
            if UI.ScreenGui then
                UI.ScreenGui:Destroy()
                UI.ScreenGui = nil
            end

            UI.Window = nil
        end

    -- CreateTaskbar
        type TaskbarConfigType = {
            Icon: string,
            Name: string,
            Description: string,
            LoadedSound: string,
        }
        function UI:CreateTaskbar(TaskbarConfig: TaskbarConfigType?)
            -- Create All
                TaskbarConfig = TaskbarConfig or {}
                TaskbarConfig.Icon = GetIcon(TaskbarConfig.Icon) or ""
                TaskbarConfig.LoadedSound = TaskbarConfig.LoadedSound or "rbxassetid://6647897822"
                TaskbarConfig.Name = TaskbarConfig.Name or "Taskbar"
                TaskbarConfig.Description = TaskbarConfig.Description or "Description"

                local Taskbar: table = { 
                    Windows = {},
                    WatermarkConfig = {
                        Enabled = false,
                        ShowScript = true,
                        ShowName = false,
                        ShowFPS = true,
                        ShowPing = true
                    }
                }
                local Theme: table = UI.Themes[UI.CurrentTheme]

                local MainFrame = CreateElement("FakeFrame", {
                    Name = "MainFakeFrame",
                    Size = UDim2.new(1, 0, 0, 70),
                    Position = UDim2.new(0, 0, 1, 0),
                    Parent = UI.ScreenGui,
                }, {
                    CreateElement("FakeFrame", {
                        Name = "MainFakeCenterFrame",
                        Size = UDim2.new(1, 0, 1, 0),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Active = true
                    }, {
                        CreateElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 10)
                        }),

                        CreateElement("TextButton", {
                            Name = "StartButtonFrame",
                            Size = UDim2.new(0, 80, 0, 60),
                            BackgroundColor3 = Theme.TaskbarColor,
                            BackgroundTransparency = 1,
                            Text = "",
                            AutoButtonColor = false,
                            BorderSizePixel = 0
                        }, {
                            CreateElement("ImageLabel", {
                                Name = "Image",
                                Size = UDim2.new(1, -20, 1, -20),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                Image = TaskbarConfig.Icon.Image,
                                ImageRectSize = TaskbarConfig.Icon.Size,
                                ImageRectOffset = TaskbarConfig.Icon.Position,
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                ScaleType = Enum.ScaleType.Crop
                            }),
                            CreateElement("Noise"),
                            CreateElement("Vingette"),
                            CreateElement("Stroke"),
                            CreateElement("BackgroundImage"),
                            CreateElement("Corner")
                        }),

                        CreateElement("RoundFrame", {
                            Name = "FakeMainFrame",
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(0, 300, 1, -5),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundColor3 = Theme.TaskbarColor,
                            BackgroundTransparency = Theme.TaskbarTransparency
                        }, {
                            CreateElement("FakeFrame", {
                                Name = "MainFrame",
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Size = UDim2.new(1, -20, 1, -20),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                            }, {
                                CreateElement("FakeFrame", {
                                    Name = "WindowsFrame",
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Position = UDim2.new(0.5, 0, 0.5, -5)
                                }, {
                                    CreateElement("UIListLayout", {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    })
                                })
                            }),
                            CreateElement("Noise"),
                            CreateElement("Vingette"),
                            CreateElement("Stroke"),
                            CreateElement("BackgroundImage")
                        }),

                        CreateElement("RoundFrame", {
                            Name = "TrayFrame",
                            Size = UDim2.new(0, 100, 0, 60),
                            BackgroundColor3 = Theme.TaskbarColor,
                            BackgroundTransparency = Theme.TaskbarTransparency
                        }, {
                            CreateElement("FakeFrame", {
                                Name = "FakeTrayFrame",
                                Size = UDim2.new(1, 0, 1, 0)
                            }, {
                                CreateElement("UIListLayout", {
                                    FillDirection = Enum.FillDirection.Horizontal,
                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                    Padding = UDim.new(0, 5)
                                }),

                                CreateElement("FakeFrame", {
                                    Name = "TrayButtonFrame",
                                    Size = UDim2.new(0, 50, 0, 60)
                                }, {
                                    CreateElement("ImageLabel", {
                                        Name = "Icon",
                                        Size = UDim2.new(1, -20, 1, -30),
                                        Position = UDim2.new(0, 15, 0, 15),
                                        Image = "rbxassetid://10709791523",
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Crop
                                    })
                                }),
                                CreateElement("TextButton", {
                                    Name = "ClockFrame",
                                    Size = UDim2.new(0, 100, 0, 60),
                                    Position = UDim2.new(0, 50, 0, 0),
                                    BackgroundTransparency = 1,
                                    Text = "",
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, {
                                    CreateElement("TextLabel", {
                                        Name = "Clock",
                                        Text = "0:0",
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        AnchorPoint = Vector2.new(0, 0),
                                        Size = UDim2.new(1, 0, 1, 0),
                                        Position = UDim2.new(0, 0, 0, 0),
                                        TextColor3 = Theme.TextColor,
                                        Font = Theme.Font,
                                        TextSize = 18,
                                        BorderSizePixel = 0,
                                    })
                                })
                            }),
                            CreateElement("Noise"),
                            CreateElement("Vingette"),
                            CreateElement("Stroke"),
                            CreateElement("BackgroundImage")
                        })
                    })
                })

                local StartFrame = CreateElement("RoundFrame", {
                    Name = "StartMainFrame",
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0, -10),
                    AnchorPoint = Vector2.new(0.5, 1),
                    Parent = MainFrame,
                    BackgroundColor3 = Theme.TaskbarColor,
                    BackgroundTransparency = Theme.TaskbarTransparency,
                    Visible = false
                }, {
                    CreateElement("ScrollingFrame", {
                        Name = "AllParentFakeFrame",
                        Size = UDim2.new(1, -20, 1, -20),
                        Position = UDim2.new(0, 10, 0, 10),
                        BackgroundTransparency = 1,
                        ScrollBarThickness = 0
                    }, {
                        CreateElement("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 5)
                        }),
                        CreateElement("FakeFrame", {
                            Name = "StatusFrame",
                            Size = UDim2.new(1, 0, 0, 15),
                            Position = UDim2.new(0, 10, 0, 10)
                        }, {
                            CreateElement("TextLabel", {
                                Name = "NameText",
                                Text = TaskbarConfig.Name,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                BackgroundTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                TextColor3 = Theme.TextColor,
                                Font = Theme.Font,
                                TextSize = 18,
                                BorderSizePixel = 0,
                            }),
                            CreateElement("TextLabel", {
                                Name = "DescriptionText",
                                Text = TaskbarConfig.Description,
                                TextXAlignment = Enum.TextXAlignment.Right,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                BackgroundTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                TextColor3 = Theme.LittleTextColor,
                                Font = Theme.LittleFont,
                                TextTransparency = Theme.LittleTextTransparency,
                                TextSize = 15,
                                BorderSizePixel = 0,
                            }),
                        }),
                        CreateElement("FakeFrame", {
                            Name = "SearchFrame",
                            Size = UDim2.new(1, 0, 0, 40),
                            Position = UDim2.new(0, 0, 0, 25)
                        }, {
                            CreateElement("TextBox", {
                                Name = "SearchBox",
                                Size = UDim2.new(1, 0, 1, -15),
                                Position = UDim2.new(0, 0, 0, 10),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                TextWrapped = false,
                                Text = "",
                                TextSize = 14,
                                TextColor3 = Theme.TextColor,
                                Font = Theme.LittleFont,
                                TextTransparency = Theme.TextTransparency,
                                BackgroundTransparency = 0.9,
                                PlaceholderText = "Search any function",
                                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                            }, { CreateElement("Corner") })
                        }),
                        CreateElement("RoundFrame", {
                            Name = "OtherAppsFake",
                            Size = UDim2.new(1, 0, 0, 0),
                            Position = UDim2.new(0, 0, 0, 65),
                            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                            BackgroundTransparency = 0.9
                        }, {
                            CreateElement("TextLabel", {
                                Name = "NameText",
                                Text = "Other apps",
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                BackgroundTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0),
                                Size = UDim2.new(1, 0, 0, 20),
                                TextColor3 = Theme.TextColor,
                                Font = Theme.Font,
                                TextSize = 18,
                                BorderSizePixel = 0,
                            }),
                            CreateElement("FakeFrame", {
                                Name = "OtherApps",
                                Position = UDim2.new(0, 10, 0, 25),
                                Size = UDim2.new(1, -20, 1, -25)
                            }, { CreateElement("UIGridLayout", { CellSize = UDim2.new(0, 60, 0, 60), SortOrder = Enum.SortOrder.LayoutOrder }) }),
                        }),
                    }),
                    CreateElement("Noise"),
                    CreateElement("Vingette"),
                    CreateElement("BackgroundImage")
                })

                UI.PinnedWindowsParent = MainFrame.MainFakeCenterFrame.FakeMainFrame.MainFrame.WindowsFrame
                UI.UnpinnedWindowsParent = StartFrame.AllParentFakeFrame.OtherAppsFake.OtherApps

                local NotificationsFrame = CreateElement("FakeFrame", {
                    Name = "NotificationsFrame",
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0, -5),
                    AnchorPoint = Vector2.new(0.5, 1),
                    Parent = MainFrame
                }, { 
                    CreateElement("UIListLayout", { 
                        SortOrder = Enum.SortOrder.LayoutOrder, 
                        Padding = UDim.new(0, 5), 
                        VerticalAlignment = Enum.VerticalAlignment.Bottom 
                    }) 
                })

                local NotificationsHubFrame = CreateElement("RoundFrame", {
                    Name = "NotificationsHubFrame",
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0, -10),
                    AnchorPoint = Vector2.new(0.5, 1),
                    Parent = MainFrame,
                    BackgroundColor3 = Theme.TaskbarColor,
                    BackgroundTransparency = Theme.TaskbarTransparency,
                    Visible = false
                }, {
                    CreateElement("ScrollingFrame", {
                        Name = "AllParentFakeFrame",
                        Size = UDim2.new(1, -20, 1, -20),
                        Position = UDim2.new(0, 10, 0, 10),
                        BackgroundTransparency = 1,
                        ScrollBarThickness = 0
                    }, {
                        CreateElement("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 5)
                        }),
                        CreateElement("FakeFrame", {
                            Name = "StatusFrame",
                            Size = UDim2.new(1, 0, 0, 20),
                            Position = UDim2.new(0, 10, 0, 10)
                        }, {
                            CreateElement("TextLabel", {
                                Name = "NameText",
                                Text = "Notifications: 0",
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                BackgroundTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                TextColor3 = Theme.TextColor,
                                Font = Theme.Font,
                                TextSize = 18,
                                BorderSizePixel = 0
                            })
                        })
                    }),
                    CreateElement("Noise"),
                    CreateElement("Vingette"),
                    CreateElement("BackgroundImage")
                })

                local WatermarkFrame = CreateElement("RoundFrame", {
                    Name = "Watermark",
                    Size = UDim2.new(0, 0, 0, 20),
                    Parent = UI.ScreenGui,
                    BackgroundColor3 = Theme.TaskbarColor,
                    BackgroundTransparency = Theme.TaskbarTransparency,
                    Visible = false,
                }, {
                    CreateElement("TextLabel", {
                        Name = "NameText",
                        Text = "",
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0),
                        Size = UDim2.new(1, 0, 0, 40),
                        Position = UDim2.new(0, 0, 0.5, -2),
                        AnchorPoint = Vector2.new(0, 0.5),
                        TextColor3 = Theme.TextColor,
                        Font = Theme.Font,
                        TextSize = 18,
                        BorderSizePixel = 0
                    }),
                    CreateElement("Noise"),
                    CreateElement("Vingette"),
                    CreateElement("BackgroundImage")
                })

                do -- Dragging
                    local Dragging, DragInput, MousePos, FramePos = false
                    AddConnection(WatermarkFrame.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1  or Input.UserInputType == Enum.UserInputType.Touch then
                            Dragging = true
                            MousePos = Input.Position
                            FramePos = WatermarkFrame.Position

                            local Conn; Conn = Input.Changed:Connect(function()
                                if Input.UserInputState == Enum.UserInputState.End then 
                                    Dragging = false
                                    Conn:Disconnect() 
                                end
                            end)
                        end
                    end)
                    
                    AddConnection(WatermarkFrame.InputChanged, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then 
                            DragInput = Input 
                        end
                    end)

                    AddConnection(Serv.UserInputService.InputChanged, function(Input)
                        if Input == DragInput and Dragging then
                            local Delta = Input.Position - MousePos

                            local Pos = UDim2.new(
                                FramePos.X.Scale,
                                FramePos.X.Offset + Delta.X, 
                                FramePos.Y.Scale, 
                                FramePos.Y.Offset + Delta.Y
                            )

                            PlayTween(WatermarkFrame, {0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}, {
                                Position = Pos 
                            }):Play()
                        end
                    end)
                end

                task.spawn(function()
                    local Stats = game:GetService("Stats")

                    local StatsFPS = Stats:WaitForChild("Workspace", 9e9):WaitForChild("Heartbeat", 9e9)
                    local StatsPing = Stats:WaitForChild("Network", 9e9):WaitForChild("ServerStatsItem", 9e9)["Data Ping"]

                    local TextParts = {
                        ["Script"] = TaskbarConfig.Name,
                        ["Name"] = game.Players.LocalPlayer.DisplayName,
                        ["FPS"] = math.round(StatsFPS:GetValue()),
                        ["Ping"] = math.round(StatsPing:GetValue())
                    }

                    local WatermarkText = ""

                    while true do
                        local Parts = {}

                        if Taskbar.WatermarkConfig.ShowScript then
                            table.insert(Parts, tostring(TextParts["Script"]))
                        end

                        if Taskbar.WatermarkConfig.ShowName then
                            table.insert(Parts, tostring(TextParts["Name"]))
                        end

                        if Taskbar.WatermarkConfig.ShowFPS then
                            TextParts["FPS"] = math.round(StatsFPS:GetValue())
                            table.insert(Parts, tostring(TextParts["FPS"].." FPS"))
                        end

                        if Taskbar.WatermarkConfig.ShowPing then
                            TextParts["Ping"] = math.round(StatsPing:GetValue())
                            table.insert(Parts, tostring(TextParts["Ping"]).." ms")
                        end

                        WatermarkFrame.NameText.Text = table.concat(Parts, " | ")

                        task.wait(0.5)
                    end
                end)

                AddConnection(WatermarkFrame.NameText:GetPropertyChangedSignal("TextBounds"), function()
                    local TextBounds = WatermarkFrame.NameText.TextBounds

                    PlayTween(WatermarkFrame, {0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {
                        Size = UDim2.new(0, TextBounds.X + 40, 0, 45)
                    })
                end)

                UI.Elements.Texts[#UI.Elements.Texts+1] = WatermarkFrame.NameText
                UI.Elements.Texts[#UI.Elements.Texts+1] = MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.TrayButtonFrame.Icon
                UI.Elements.Texts[#UI.Elements.Texts+1] = MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.ClockFrame.Clock
                UI.Elements.Texts[#UI.Elements.Texts+1] = StartFrame.AllParentFakeFrame.StatusFrame.NameText
                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = StartFrame.AllParentFakeFrame.StatusFrame.DescriptionText
                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = StartFrame.AllParentFakeFrame.SearchFrame.SearchBox
                UI.Elements.Texts[#UI.Elements.Texts+1] = StartFrame.AllParentFakeFrame.OtherAppsFake.NameText
                UI.Elements.Texts[#UI.Elements.Texts+1] = NotificationsHubFrame.AllParentFakeFrame.StatusFrame.NameText

            -- Sizes
                local ToggledStart = false
                local ToggledNotificationsHub, TogglingNotificationsHub = false, false

                do
                    local function UpdateCenterFrameSize()
                        local AbsoluteContentSize = MainFrame.MainFakeCenterFrame.UIListLayout.AbsoluteContentSize
                        PlayTween(MainFrame.MainFakeCenterFrame, 0.01, {Size = UDim2.new(0, AbsoluteContentSize.X, 0, 65)})
                        StartFrame.Size = UDim2.new(0, AbsoluteContentSize.X, 0, ToggledStart and 300 or 0)
                        NotificationsFrame.Size = UDim2.new(0, AbsoluteContentSize.X, 1, 0)

                        if not TogglingNotificationsHub then
                            NotificationsHubFrame.Size = UDim2.new(0, AbsoluteContentSize.X, 0, ToggledNotificationsHub and 300 or 0)
                        end
                    end

                    UpdateCenterFrameSize()
                    AddConnection(MainFrame.MainFakeCenterFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateCenterFrameSize)

                    AddConnection(MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                        local AbsoluteContentSize = MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.UIListLayout.AbsoluteContentSize
                        PlayTween(MainFrame.MainFakeCenterFrame.TrayFrame, 0.1, {Size = UDim2.new(0, AbsoluteContentSize.X, 0, 60)})
                    end)

                    AddConnection(MainFrame.MainFakeCenterFrame.FakeMainFrame.MainFrame.WindowsFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                        local AbsoluteContentSize = MainFrame.MainFakeCenterFrame.FakeMainFrame.MainFrame.WindowsFrame.UIListLayout.AbsoluteContentSize
                        PlayTween(MainFrame.MainFakeCenterFrame.FakeMainFrame, 0.1, {Size = UDim2.new(0, AbsoluteContentSize.X + 10, 1, -5)})
                    end)

                    AddConnection(StartFrame.AllParentFakeFrame.OtherAppsFake.OtherApps.UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                        local AbsoluteContentSize = StartFrame.AllParentFakeFrame.OtherAppsFake.OtherApps.UIGridLayout.AbsoluteContentSize
                        PlayTween(StartFrame.AllParentFakeFrame.OtherAppsFake, 0.1, {Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 25)})
                    end)

                    AddConnection(NotificationsHubFrame.AllParentFakeFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                        local AbsoluteContentSize = NotificationsHubFrame.AllParentFakeFrame.UIListLayout.AbsoluteContentSize
                        PlayTween(NotificationsHubFrame.AllParentFakeFrame, 0.1, {CanvasSize = UDim2.new(1, -20, 0, AbsoluteContentSize.Y)})
                    end)

                    AddConnection(StartFrame.AllParentFakeFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                        local AbsoluteContentSize = StartFrame.AllParentFakeFrame.UIListLayout.AbsoluteContentSize
                        StartFrame.AllParentFakeFrame.CanvasSize = UDim2.new(0, 0, 0, AbsoluteContentSize.Y)
                    end)
                end
                    
            -- Clock
                do
                    local ClockText = MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.ClockFrame.Clock
                    local NotificationsHubButton = MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.ClockFrame

                    AddConnection(ClockText:GetPropertyChangedSignal("TextBounds"), function()
                        local TextBounds = ClockText.TextBounds.X
                        PlayTween(ClockText, 0.1, {Size = UDim2.new(0, TextBounds, 1, 0)})
                        PlayTween(ClockText.Parent, 0.1, {Size = UDim2.new(0, TextBounds + 20, 1, 0)})
                    end)

                    local Time = os.date("*t")
                    ClockText.Text = string_format("%02d:%02d", Time.hour, Time.min)
                    task.spawn(function() while true do
                        local Time = os.date("*t")
                        ClockText.Text = string_format("%02d:%02d", Time.hour, Time.min)
                        task.wait(1)
                    end end)
                end

            -- Taskbar Functions
                -- Default
                    function Taskbar:ToggleWindow(WindowName: string, Open: boolean)
                        local Window = UI.ScreenGui.WindowsFolder:FindFirstChild(WindowName)
                        local WindowTable = UI.Windows[WindowName]
                        if not Window or WindowTable == nil then return end

                        if Open then
                            task.delay(0.02, function()
                                Window.Visible = true
                            end)
                            local Tween = PlayTween(Window, {0.2, "Quad", "Out"}, { 
                                Size = WindowTable.OldSize, 
                                Position = WindowTable.OldPosition 
                            })
                            Tween.Completed:Once(function() WindowOpen = true end)
                        else
                            WindowOpen = false
                            PlayTween(Window, {0.2, "Quad", "Out"}, { 
                                Size = UDim2.new(0, 0, 0, 0), 
                                Position = UDim2.new(0, WindowTable.TaskbarIcon.AbsolutePosition.X, 1, 0) 
                            })
                            task.wait(0.12)
                            Window.Visible = false
                        end
                    end

                    function Taskbar:ToggleStart(Open: boolean)
                        local SizeX = MainFrame.MainFakeCenterFrame.UIListLayout.AbsoluteContentSize.X
                        
                        if Open and ToggledNotificationsHub then Taskbar:ToggleNotificationsHub(false) end
                        
                        if Open then
                            StartFrame.Visible = true
                            PlayTween(StartFrame, {0.2, "Quad", "Out"}, { Size = UDim2.new(0, SizeX, 0, 300) })
                        else
                            PlayTween(StartFrame, {0.2, "Quad", "Out"}, { Size = UDim2.new(0, SizeX, 0, 0) })
                            task.wait(0.2)
                            StartFrame.Visible = false
                        end
                    end

                    function Taskbar:ToggleNotificationsHub(Open: boolean)
                        local SizeX = MainFrame.MainFakeCenterFrame.UIListLayout.AbsoluteContentSize.X
                        
                        if Open and ToggledStart then Taskbar:ToggleStart(false) end
                        TogglingNotificationsHub = true

                        if Open then
                            NotificationsHubFrame.Visible = true
                            PlayTween(NotificationsHubFrame, {0.2, "Quad", "Out"}, { Size = UDim2.new(0, SizeX, 0, 300) })
                            task.wait(0.2)
                            TogglingNotificationsHub = false
                        else
                            PlayTween(NotificationsHubFrame, {0.2, "Quad", "Out"}, { Size = UDim2.new(0, SizeX, 0, 0) })
                            task.wait(0.2)
                            TogglingNotificationsHub = false
                            NotificationsHubFrame.Visible = false
                        end
                    end

                    function Taskbar:ConfigWatermark(Config: table)
                        Config.Enabled = Config.Enabled or false
                        Config.ShowScript = Config.ShowScript or false
                        Config.ShowName = Config.ShowName or false
                        Config.ShowFPS = Config.ShowFPS or false
                        Config.ShowPing = Config.ShowPing or false

                        Taskbar.WatermarkConfig.Enabled = Config.Enabled
                        Taskbar.WatermarkConfig.ShowScript = Config.ShowScript
                        Taskbar.WatermarkConfig.ShowName = Config.ShowName
                        Taskbar.WatermarkConfig.ShowFPS = Config.ShowFPS
                        Taskbar.WatermarkConfig.ShowPing = Config.ShowPing

                        WatermarkFrame.Visible = Config.Enabled
                    end

                -- Button Connections
                    do -- Start
                        local MouseOn = false
                        AddConnection(MainFrame.MainFakeCenterFrame.StartButtonFrame.MouseButton1Up, function()
                            task.spawn(function()
                                PlayTween(MainFrame.MainFakeCenterFrame.StartButtonFrame.Image, 0.2, { 
                                    Size = UDim2.new(1, -25, 1, -25),
                                    Position = UDim2.new(0.5, 0, 0.5, 0)
                                })
                                task.wait(0.2)
                                PlayTween(MainFrame.MainFakeCenterFrame.StartButtonFrame.Image, 0.2, { 
                                    Size = UDim2.new(1, -20, 1, -20),
                                    Position = MouseOn and UDim2.new(0.5, 0, 0.5, -5) or UDim2.new(0.5, 0, 0.5, 0)
                                })
                            end)

                            ToggledStart = not ToggledStart
                            Taskbar:ToggleStart(ToggledStart)
                        end)

                        AddConnection(MainFrame.MainFakeCenterFrame.StartButtonFrame.MouseEnter, function()
                            MouseOn = true
                            PlayTween(MainFrame.MainFakeCenterFrame.StartButtonFrame.Image, 0.1, { Position = UDim2.new(0.5, 0, 0.5, -5) })
                        end)

                        AddConnection(MainFrame.MainFakeCenterFrame.StartButtonFrame.MouseLeave, function()
                            MouseOn = false
                            PlayTween(MainFrame.MainFakeCenterFrame.StartButtonFrame.Image, 0.1, { Position = UDim2.new(0.5, 0, 0.5, 0) })
                        end)
                    end

                    do -- Notifications Hub
                        local MouseOn = false
                        local ClockFrame = MainFrame.MainFakeCenterFrame.TrayFrame.FakeTrayFrame.ClockFrame
                        local ClockText = ClockFrame.Clock

                        AddConnection(ClockFrame.MouseButton1Up, function()
                            task.spawn(function()
                                PlayTween(ClockText, 0.2, { TextSize = 17 })
                                task.wait(0.2)
                                PlayTween(ClockText, 0.2, { TextSize = MouseOn and 19 or 18 })
                            end)

                            ToggledNotificationsHub = not ToggledNotificationsHub
                            Taskbar:ToggleNotificationsHub(ToggledNotificationsHub)
                        end)

                        AddConnection(ClockFrame.MouseEnter, function()
                            MouseOn = true
                            PlayTween(ClockText, 0.1, { TextSize = 19 })
                        end)
    
                        AddConnection(ClockFrame.MouseLeave, function()
                            MouseOn = false
                            PlayTween(ClockText, 0.2, { TextSize = 18 })
                        end)
                    end

                    do -- Search 
                        local SearchBox = StartFrame.AllParentFakeFrame.SearchFrame.SearchBox
                        local AlreadyClosed = false
                        local FoundElements = {}
                        local Text = SearchBox.Text
                        local IsSearching = false

                        AddConnection(SearchBox.FocusLost, function()
                            task.wait()

                            Text = SearchBox.Text

                            for _, Element in StartFrame.AllParentFakeFrame:GetChildren() do 
                                if Element.Name ~= "FoundElement" then continue end
                                Element:Destroy()
                            end
                            table.clear(FoundElements)

                            if Text ~= "" then
                                if not AlreadyClosed then
                                    AlreadyClosed = true
                                    for _, Element in StartFrame.AllParentFakeFrame:GetChildren() do
                                        if Element.Name == "UIListLayout" or Element.Name == "SearchFrame" or Element.Name == "StatusFrame" then continue end
                                        Element.Visible = false
                                    end
                                end
                            else
                                AlreadyClosed = false

                                for _, Element in StartFrame.AllParentFakeFrame:GetChildren() do
                                    if Element.Name ~= "UIListLayout" then Element.Visible = true end
                                end

                                return
                            end 

                            local OldElementPosition = 0
                            for i, Element in UI.SearchElements do
                                if i % 10 == 0 then task.wait(); end
                                if not Element.Name:find(Text, 1, true) then continue end

                                local ButtonFrame = CreateElement("TextButton", {
                                    Name = "FoundElement",
                                    Size = UDim2.new(1, 0, 0, 30),
                                    Parent = StartFrame.AllParentFakeFrame,
                                    BackgroundColor3 = Theme.ElementsColor,
                                    BackgroundTransparency = Theme.ElementsTransparency,
                                    Visible = false,
                                    Text = "",
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, {
                                    CreateElement("TextLabel", {
                                        Name = "NameText",
                                        Size = UDim2.new(1, -30, 1, 0),
                                        Position = UDim2.new(0, 10, 0, 0),
                                        TextWrapped = true,
                                        Text = Element.Name,
                                        TextSize = 16,
                                        TextColor3 = Theme.TextColor,
                                        Font = Theme.Font,
                                        TextTransparency = Theme.TextTransparency,
                                        BorderSizePixel = 0,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        TextWrap = false
                                    }),
                                    CreateElement("ImageLabel", {
                                        Name = "PressIcon",
                                        Size = UDim2.new(0, 20, 0, 20),
                                        Position = UDim2.new(1, -20, 0.5, 0),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        BackgroundTransparency = 1,
                                        ImageTransparency = Theme.LittleTextTransparency,
                                        Image = "rbxassetid://10709768347",
                                    })
                                })

                                local RealWindow = UI.ScreenGui.WindowsFolder[Element.Window]
                                local SectionsHolderFrame = RealWindow.Holder.TabFrame.SectionsHolderFrame
                                local ElementsHolderFrame = Element.Side == "Left" and SectionsHolderFrame.FakeDescendantClipperFrameLeft.LeftHolderFrame or SectionsHolderFrame.FakeDescendantClipperFrameRight.RightHolderFrame

                                local ElementPosition = OldElementPosition + Element.Frame.AbsoluteSize.Y
                                OldElementPosition = ElementPosition
                                
                                AddConnection(ButtonFrame.MouseButton1Up, function()
                                    Taskbar:ToggleWindow(Element.Window, true)
                                    task.wait(0.1)

                                    local AbsolutePosition = Element.Frame.AbsolutePosition
                                    local ElementsHolderPosition = ElementsHolderFrame.AbsolutePosition
                                    local TargetPosition = Vector2.new(0, AbsolutePosition.Y - ElementsHolderPosition.Y - ElementsHolderFrame.AbsoluteSize.Y / 2 + Element.Frame.AbsoluteSize.Y / 2)

                                    ElementsHolderFrame.CanvasPosition = Vector2.new(0, 0)
                                    task.wait(.1)
                                    PlayTween(ElementsHolderFrame, 0.5, {
                                        CanvasPosition = Vector2.new(
                                            0, math.clamp(
                                                TargetPosition.Y, 0, 
                                                math.max(0, ElementsHolderFrame.AbsoluteCanvasSize.Y - ElementsHolderFrame.AbsoluteSize.Y)
                                            )
                                        )
                                    })

                                    task.spawn(function()
                                        for i = 1, 3 do
                                            PlayTween(Element.Frame.UIStroke, 0.2, { Transparency = 0 })
                                            task.wait(0.2)
                                            PlayTween(Element.Frame.UIStroke, 0.2, { Transparency = 1 })
                                            task.wait(0.2)
                                        end
                                    end)

                                    task.spawn(function()
                                        PlayTween(ButtonFrame.PressIcon, 0.1, { Size = UDim2.new(0, 10, 0, 10) })
                                        task.wait(0.11)
                                        PlayTween(ButtonFrame.PressIcon, 0.1, { Size = UDim2.new(0, 20, 0, 20) })
                                    end)
                                end)

                                AddConnection(ButtonFrame.MouseEnter, function() ButtonFrame.NameText.TextSize = 17 end)
                                AddConnection(ButtonFrame.MouseLeave, function() ButtonFrame.NameText.TextSize = 16 end)

                                FoundElements[#FoundElements+1] = ButtonFrame
                            end
                            OldElementPosition = 0

                            for _, Element in FoundElements do Element.Visible = true end
                        end)
                    end

                -- CreateWindow
                    type WindowConfigType = {
                        Pinned: boolean,
                        Icon: string,
                        BackgroundImage: string,
                        Name: string,
                        Description: string
                    }
                    function Taskbar:CreateWindow(WindowConfig: WindowConfigType?)
                        -- Create All
                            WindowConfig = WindowConfig or {}
                            WindowConfig.Pinned = WindowConfig.Pinned or false
                            WindowConfig.Icon = GetIcon(WindowConfig.Icon) or ""
                            WindowConfig.BackgroundImage = WindowConfig.BackgroundImage or ""
                            WindowConfig.Name = WindowConfig.Name or "Window"
                            WindowConfig.Description = WindowConfig.Description or "Description"

                            local View = workspace.CurrentCamera.ViewportSize
                            local Window = { 
                                OldPosition = UDim2.new(0, 0, 0, 0),
                                OldSize = UDim2.new(0, math.min(600, View.X - 40), 0, math.min(500, View.Y - 110)),
                                Opened = false,
                                Minimized = false,
                                CanSaveSize = false,
                                Pinned = WindowConfig.Pinned,
                                Tabs = {},
                                TabButtons = {},
                                Frame = nil,
                                WindowName = WindowConfig.Name,
                                ContextMenuOpen = false
                            }

                            Window.OldPosition = UDim2.new(
                                0.5, -(Window.OldSize.X.Offset / 2),
                                0.5, -(Window.OldSize.Y.Offset / 2) - 45
                            )

                            local WindowsFrame = MainFrame.MainFakeCenterFrame.FakeMainFrame.MainFrame.WindowsFrame
                            local WindowsFolder = MainFrame.Parent:FindFirstChild("WindowsFolder") or CreateElement("Folder", { Parent = MainFrame.Parent, Name = "WindowsFolder" })

                            local TaskbarIcon = CreateElement("RoundFrame", {
                                Name = WindowConfig.Name,
                                Size = UDim2.new(0, 60, 0, 60),
                                BackgroundTransparency = 1,
                                Parent = WindowConfig.Pinned and WindowsFrame or StartFrame.AllParentFakeFrame.OtherAppsFake.OtherApps
                            }, {
                                CreateElement("ImageLabel", {
                                    Name = "Icon",
                                    Size = UDim2.new(1, -10, 1, -10),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Position = UDim2.new(0.5, -5, 0.5, -5),
                                    Image = WindowConfig.Icon.Image,
                                    ImageRectSize = WindowConfig.Icon.Size,
                                    ImageRectOffset = WindowConfig.Icon.Position,
                                    BackgroundTransparency = 1,
                                    ScaleType = Enum.ScaleType.Crop
                                })
                            })

                            UI.WindowIcons[#UI.WindowIcons+1] = TaskbarIcon

                            local ContextMenu = CreateElement("RoundFrame", {
                                Name = "ContextMenu",
                                Size = UDim2.new(0, 180, 0, 60),
                                Position = UDim2.new(0, -45, 0, -80),
                                BackgroundTransparency = 1,
                                Parent = TaskbarIcon,
                                Visible = false
                            }, {
                                CreateElement("UIListLayout", {
                                    FillDirection = Enum.FillDirection.Vertical,
                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                    Padding = UDim.new(0, 0)
                                }),
                                CreateElement("TextButton", {
                                    Name = "ButtonPin",
                                    Size = UDim2.new(1, 0, 0, 30),
                                    BackgroundColor3 = Theme.ElementsColor,
                                    BackgroundTransparency = Theme.ElementsTransparency,
                                    ZIndex = 100,
                                    Text = "",
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, {
                                    CreateElement("TextLabel", {
                                        Name = "NameText",
                                        Size = UDim2.new(1, -50, 1, 0),
                                        Position = UDim2.new(0, 10, 0, 0),
                                        TextWrapped = true,
                                        Text = Window.Pinned and "Unpin" or "Pin",
                                        TextSize = 16,
                                        TextColor3 = Theme.TextColor,
                                        Font = Theme.Font,
                                        TextTransparency = Theme.TextTransparency,
                                        BorderSizePixel = 0,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        TextWrap = false,
                                        ZIndex = 100
                                    }),
                                    CreateElement("ImageLabel", {
                                        Name = "PressIcon",
                                        Size = UDim2.new(0, 20, 0, 20),
                                        Position = UDim2.new(1, -20, 0.5, 0),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        BackgroundTransparency = 1,
                                        ImageTransparency = Theme.LittleTextTransparency,
                                        Image = Window.Pinned and "rbxassetid://10734922180" or "rbxassetid://10734922324",
                                        ZIndex = 100
                                    }),
                                    CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                }),
                                CreateElement("TextButton", {
                                    Name = "ButtonReset",
                                    Size = UDim2.new(1, 0, 0, 30),
                                    BackgroundColor3 = Theme.ElementsColor,
                                    BackgroundTransparency = Theme.ElementsTransparency,
                                    ZIndex = 100,
                                    Text = "",
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, {
                                    CreateElement("TextLabel", {
                                        Name = "NameText",
                                        Size = UDim2.new(1, -50, 1, 0),
                                        Position = UDim2.new(0, 10, 0, 0),
                                        TextWrapped = true,
                                        Text = "Reset Size & Pos",
                                        TextSize = 16,
                                        TextColor3 = Theme.TextColor,
                                        Font = Theme.Font,
                                        TextTransparency = Theme.TextTransparency,
                                        BorderSizePixel = 0,
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        TextWrap = false,
                                        ZIndex = 100
                                    }),
                                    CreateElement("ImageLabel", {
                                        Name = "PressIcon",
                                        Size = UDim2.new(0, 20, 0, 20),
                                        Position = UDim2.new(1, -20, 0.5, 0),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        BackgroundTransparency = 1,
                                        ImageTransparency = Theme.LittleTextTransparency,
                                        Image = "rbxassetid://10734933222",
                                        ZIndex = 100
                                    }),
                                    CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                })
                            })

                            AddConnection(ContextMenu.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                local SizeY = ContextMenu.UIListLayout.AbsoluteContentSize.Y
                                PlayTween(ContextMenu, 0.1, { Size = UDim2.new(0, 180, 0, SizeY + 10) })
                            end)

                            AddConnection(ContextMenu.ButtonPin.NameText:GetPropertyChangedSignal("TextBounds"), function()
                                ContextMenu.ButtonPin.NameText.Size = UDim2.new(1, -50, 1, 0)
                            end)

                            AddConnection(ContextMenu.ButtonReset.NameText:GetPropertyChangedSignal("TextBounds"), function()
                                ContextMenu.ButtonReset.NameText.Size = UDim2.new(1, -50, 1, 0)
                            end)

                            AddConnection(ContextMenu.ButtonPin.MouseEnter, function() ContextMenu.ButtonPin.NameText.TextSize = 17 end)
                            AddConnection(ContextMenu.ButtonPin.MouseLeave, function() ContextMenu.ButtonPin.NameText.TextSize = 16 end)
                            AddConnection(ContextMenu.ButtonReset.MouseEnter, function() ContextMenu.ButtonReset.NameText.TextSize = 17 end)
                            AddConnection(ContextMenu.ButtonReset.MouseLeave, function() ContextMenu.ButtonReset.NameText.TextSize = 16 end)

                            UI.Elements.Texts[#UI.Elements.Texts+1] = TaskbarIcon.Icon

                            local WindowFrame = CreateElement("FakeFrame", {
                                Visible = false,
                                Name = WindowConfig.Name,
                                Size = UDim2.new(0, 0, 0, 0),
                                Position = UDim2.new(0.5, 0, 1, 0),
                                Parent = WindowsFolder,
                                ClipsDescendants = false,
                                Active = true
                            }, {
                                CreateElement("RoundFrame", {
                                    Name = "TopBar",
                                    Size = UDim2.new(1, -10, 0, 45),
                                    Position = UDim2.new(0, 5, 0, 5),
                                    BackgroundColor3 = Theme.WindowsColor,
                                    BackgroundTransparency = Theme.WindowsTransparency
                                }, {
                                    CreateElement("Noise"),
                                    CreateElement("Vingette"),
                                    CreateElement("BackgroundImage"),
                                    CreateElement("Stroke"),
                                    CreateElement("ImageLabel", {
                                        Name = "Icon",
                                        Size = UDim2.new(0, 40, 1, -10),
                                        Position = UDim2.new(0, 10, 0, 5),
                                        Image = WindowConfig.Icon.Image,
                                        ImageRectSize = WindowConfig.Icon.Size,
                                        ImageRectOffset = WindowConfig.Icon.Position,
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Crop
                                    }),
                                    CreateElement("TextLabel", {
                                        Name = "NameText",
                                        Text = WindowConfig.Name,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        AnchorPoint = Vector2.new(0, 0),
                                        Size = UDim2.new(1, 0, 0.5, 5),
                                        Position = UDim2.new(0, 60, 0, 0),
                                        TextColor3 = Theme.TextColor,
                                        Font = Theme.Font,
                                        TextSize = 18,
                                        BorderSizePixel = 0,
                                    }),
                                    CreateElement("TextLabel", {
                                        Name = "Description",
                                        Text = WindowConfig.Description,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        AnchorPoint = Vector2.new(0, 0),
                                        Size = UDim2.new(1, 0, 0.5, 5),
                                        Position = UDim2.new(0, 61, 0, 18),
                                        TextColor3 = Theme.LittleTextColor,
                                        Font = Theme.LittleFont,
                                        TextTransparency = Theme.LittleTextTransparency,
                                        TextSize = 14,
                                        BorderSizePixel = 0,
                                    })
                                }),
                                CreateElement("RoundFrame", {
                                    Name = "Holder",
                                    Size = UDim2.new(1, -10, 1, -65),
                                    Position = UDim2.new(0.5, 0, 0.5, 25),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundColor3 = Theme.WindowsColor,
                                    BackgroundTransparency = Theme.WindowsTransparency,
                                }, {
                                    CreateElement("Noise"),
                                    CreateElement("Vingette"),
                                    CreateElement("BackgroundImage"),
                                    CreateElement("Stroke")
                                }),
                                CreateElement("FakeFrame", {
                                    Name = "ResizePointFake",
                                    Size = UDim2.new(0, 40, 0, 40),
                                    Position = UDim2.new(1, -10, 1, -10)
                                }, {
                                    CreateElement("RoundFrame", {
                                        Name = "ResizePoint",
                                        Size = UDim2.new(0, 20, 0, 20),
                                        BackgroundColor3 = Theme.WindowsColor,
                                        BackgroundTransparency = Theme.WindowsTransparency
                                    }, {
                                        CreateElement("Noise"),
                                        CreateElement("Vingette"),
                                        CreateElement("BackgroundImage"),
                                        CreateElement("Stroke")
                                    })
                                })
                            })

                            Window.Frame = WindowFrame

                            UI.Elements.Texts[#UI.Elements.Texts+1] = WindowFrame.TopBar.NameText
                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = WindowFrame.TopBar.Description
                            UI.Elements.Texts[#UI.Elements.Texts+1] = WindowFrame.TopBar.Icon

                            local SectionsHolderParent = CreateElement("ScrollingFrame", {
                                Name = "TabFrame",
                                Size = UDim2.new(1, 0, 1, 0),
                                Position = UDim2.new(0, 0, 0, 0),
                                BackgroundTransparency = 1,
                                ScrollBarThickness = 0, 
                                ClipsDescendants = true,
                                ScrollingEnabled = false,
                                ScrollingDirection = Enum.ScrollingDirection.X,
                                ElasticBehavior = Enum.ElasticBehavior.Never,
                                Parent = WindowFrame.Holder
                            }, {
                                CreateElement("UIListLayout", {
                                    FillDirection = Enum.FillDirection.Horizontal,
                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                    Padding = UDim.new(0, 0)
                                })
                            })

                            local IsUpdatingTabFrame = false

                            AddConnection(SectionsHolderParent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                if IsUpdatingTabFrame then return end
                                IsUpdatingTabFrame = true

                                local AbsoluteContentSize = SectionsHolderParent.UIListLayout.AbsoluteContentSize
                                local CanvasPositionSave = SectionsHolderParent.CanvasPosition

                                SectionsHolderParent.CanvasSize = UDim2.new(0, AbsoluteContentSize.X, 0, 0)

                                local CurrentTabIndex = math.floor((CanvasPositionSave.X + SectionsHolderParent.AbsoluteSize.X / 2) / SectionsHolderParent.AbsoluteSize.X) + 1
                                CurrentTabIndex = math.clamp(CurrentTabIndex, 1, #Window.Tabs)

                                for _, HolderFrame in SectionsHolderParent:GetChildren() do
                                    if HolderFrame.Name == "UIListLayout" then continue end
                                    HolderFrame.Size = UDim2.new(0, SectionsHolderParent.AbsoluteSize.X, 1, 0)
                                end

                                local TargetPosition = (CurrentTabIndex - 1) * SectionsHolderParent.AbsoluteSize.X
                                SectionsHolderParent.CanvasPosition = Vector2.new(TargetPosition, 0)

                                task.defer(function() IsUpdatingTabFrame = false end)
                            end)

                            local ButtonsFrame = CreateElement("FakeFrame", {
                                Name = "ButtonsFrame",
                                Size = UDim2.new(0, 80, 1, -20),
                                Position = UDim2.new(1, -90, 0, 10),
                                Parent = WindowFrame.TopBar
                            }, {
                                CreateElement("TextButton", {
                                    Name = "MinimizeButton",
                                    Size = UDim2.new(0.5, 0, 1, 0),
                                    Position = UDim2.new(0.5, -15, 0.5, 0),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundTransparency = 1,
                                    Text = "",
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, {
                                    CreateElement("ImageLabel", {
                                        Name = "Image",
                                        Size = UDim2.new(1, -10, 1, -10),
                                        Position = UDim2.new(0, 5, 0, 5),
                                        Image = "rbxassetid://10734896206",
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Crop
                                    })
                                }),
                                CreateElement("TextButton", {
                                    Name = "CloseButton",
                                    Size = UDim2.new(0.5, 0, 1, 0),
                                    Position = UDim2.new(0.5, 0, 0, 0),
                                    BackgroundTransparency = 1,
                                    Text = "",
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, {
                                    CreateElement("ImageLabel", {
                                        Name = "Image",
                                        Size = UDim2.new(1, -10, 1, -10),
                                        Position = UDim2.new(0, 5, 0, 5),
                                        Image = "rbxassetid://10747384394",
                                        BackgroundTransparency = 1,
                                        ScaleType = Enum.ScaleType.Crop
                                    })
                                }),
                                CreateElement("TextButton", {
                                    Name = "BindBox",
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Position = UDim2.new(0, 0, 0.5, 0),
                                    AnchorPoint = Vector2.new(0, 0.5),
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    TextYAlignment = Enum.TextYAlignment.Center,
                                    TextWrapped = false,
                                    Text = "None",
                                    TextSize = 14,
                                    TextColor3 = Theme.LittleTextColor,
                                    Font = Theme.LittleFont,
                                    BackgroundTransparency = 1,
                                    TextTransparency = Theme.LittleTextTransparency,
                                    AutoButtonColor = false,
                                    BorderSizePixel = 0
                                }, { CreateElement("Corner") })
                            })

                            UI.Elements.Texts[#UI.Elements.Texts+1] = ButtonsFrame.MinimizeButton.Image
                            UI.Elements.Texts[#UI.Elements.Texts+1] = ButtonsFrame.CloseButton.Image
                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = ButtonsFrame.BindBox
                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = ButtonsFrame.BindBox

                            task.defer(function()
                                task.wait(.1)
                                WindowFrame.Position = UDim2.new(0, TaskbarIcon.AbsolutePosition.X, 1, 0) 
                            end)

                        -- Functions
                            local WindowOpen, MouseWasUnlocked = false, false

                            function Window:Toggle(Open: boolean)
                                if Open then
                                    if UI.WindowsSettings.AutoUnlockMouse then
                                        MouseWasUnlocked = true
                                        RemoveConnection("MouseUnlockAutoConnection")
                                        AddConnection(Serv.RunService.RenderStepped, function()
                                            if Serv.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
                                            Serv.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                                            Serv.UserInputService.MouseIconEnabled = true
                                        end, "MouseUnlockAutoConnection")
                                    end

                                    task.delay(0.02, function()
                                        WindowFrame.Visible = Window.Opened
                                    end)

                                    local Tween = PlayTween(WindowFrame, {0.2, "Quad", "Out"}, { 
                                        Size = Window.OldSize, 
                                        Position = Window.OldPosition 
                                    }); Tween.Completed:Once(function() WindowOpen = true; Window.CanSaveSize = true end)
                                else
                                    if MouseWasUnlocked then
                                        RemoveConnection("MouseUnlockAutoConnection")
                                        Serv.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                                        Serv.UserInputService.MouseIconEnabled = false
                                    end

                                    Window.CanSaveSize = false
                                    WindowOpen = false
                                    PlayTween(WindowFrame, {0.2, "Quad", "Out"}, { 
                                        Size = UDim2.new(0, 0, 0, 0), 
                                        Position = UDim2.new(0, TaskbarIcon.AbsolutePosition.X, 1, 0) 
                                    })
                                    task.wait(0.12)
                                    WindowFrame.Visible = Window.Opened
                                end
                            end

                            function Window:MinimizeToggle(Open: boolean)
                                if Open then
                                    PlayTween(WindowFrame.Holder, {0.1, "Quad", "Out"}, {
                                        Size = UDim2.new(0, 0, 0, 0), 
                                        Position = UDim2.new(0.5, 0, 0.5, (#Window.Tabs > 1) and 43 or 25) 
                                    })

                                    PlayTween(ButtonsFrame.MinimizeButton, 0.1, { Size = UDim2.new(0, 0, 0, 0) })
                                    task.wait(0.1)
                                    ButtonsFrame.MinimizeButton.Image.Image = "rbxassetid://10734924532"
                                    PlayTween(ButtonsFrame.MinimizeButton, 0.1, { Size = UDim2.new(0.5, 0, 1, 0) })
                                    WindowFrame.Holder.Visible = not Window.Minimized
                                else
                                    WindowFrame.Holder.Visible = not Window.Minimized

                                    PlayTween(WindowFrame.Holder, {0.1, "Quad", "Out"}, { 
                                        Size = UDim2.new(1, -10, 1, (#Window.Tabs > 1) and -103 or -65), 
                                        Position = UDim2.new(0.5, 0, 0.5, (#Window.Tabs > 1) and 43 or 25)  
                                    })

                                    PlayTween(ButtonsFrame.MinimizeButton, 0.1, { Size = UDim2.new(0, 0, 0, 0) })
                                    task.wait(0.1)
                                    ButtonsFrame.MinimizeButton.Image.Image = "rbxassetid://10734896206"
                                    PlayTween(ButtonsFrame.MinimizeButton, 0.1, { Size = UDim2.new(0.5, 0, 1, 0) })
                                end
                            end

                            function Window:ToggleContextMenu(Open: boolean) 
                                if Open then
                                    ContextMenu.Visible = true
                                else
                                    ContextMenu.Visible = false
                                end
                            end

                            function Window:SetPinned(Pinned: boolean)
                                if Pinned then
                                    TaskbarIcon.Parent = WindowsFrame
                                    ContextMenu.ButtonPin.NameText.Text = "Unpin"
                                    ContextMenu.ButtonPin.PressIcon.Image = "rbxassetid://10734922180"
                                else
                                    TaskbarIcon.Parent = StartFrame.AllParentFakeFrame.OtherAppsFake.OtherApps
                                    ContextMenu.ButtonPin.NameText.Text = "Pin"
                                    ContextMenu.ButtonPin.PressIcon.Image = "rbxassetid://10734922324"
                                end

                                if getgenv().SavePinnedState then
                                    getgenv().SavePinnedState(WindowConfig.Name, Pinned)
                                end
                            end

                            function Window:ResetSizePos()
                                Window.OldSize = UDim2.new(0, math.min(600, View.X - 40), 0, math.min(500, View.Y - 110))
                                Window.OldPosition = UDim2.new(
                                    0.5, -(Window.OldSize.X.Offset / 2),
                                    0.5, -(Window.OldSize.Y.Offset / 2) - 45
                                )
                            end 

                            local TabButton, TabButtonsHolder, TabButton
                            local function ChangeTab(Name, Button)
                                local TabIndex = 0
                                for i, Tab in Window.Tabs do
                                    if Tab.Name == Name then
                                        TabIndex = i
                                        break
                                    end
                                end

                                if TabButtonsHolder then
                                    for _, TabButtons in TabButtonsHolder.ButtonsListFrame:GetChildren() do
                                        if not TabButtons:IsA("Frame") then continue end
                                        TabButtons.NameText.TextTransparency = math.min(1, Theme.TextTransparency + 0.5)
                                    end
                                    Button.NameText.TextTransparency = Theme.TextTransparency
                                end

                                local TargetPosition = (TabIndex - 1) * SectionsHolderParent.AbsoluteSize.X
                                PlayTween(SectionsHolderParent, {0.2, Enum.EasingStyle.Linear}, {
                                    CanvasPosition = Vector2.new(TargetPosition, 0)
                                })

                                Window.CurrentTab = Name
                            end

                            function Window:CreateTab(TabConfig: { Name: string, Icon: string })
                                -- Create All
                                    TabConfig = TabConfig or {}
                                    TabConfig.Name = TabConfig.Name or "Tab"
                                    TabConfig.Icon = TabConfig.Icon or "Tab"

                                    local Tab = { Name = TabConfig.Name, Sections = {}, SectionsButton = {} }
                                    Window.Tabs[#Window.Tabs+1] = Tab

                                    if #Window.Tabs > 1 then
                                        WindowFrame.Holder.ClipsDescendants = true

                                        if not TabButtonsHolder then
                                            TabButtonsHolder = CreateElement("RoundFrame", {
                                                Name = "TabButtonsHolder",
                                                Size = UDim2.new(1, -10, 0, 35),
                                                Position = UDim2.new(0, 5, 0, 55),
                                                BackgroundTransparency = Theme.WindowsTransparency,
                                                BackgroundColor3 = Theme.WindowsColor,
                                                Parent = WindowFrame
                                            }, {    
                                                CreateElement("FakeFrame", {
                                                    Name = "ButtonsListFrame",
                                                    Size = UDim2.new(1, -10, 1, -10),
                                                    Position = UDim2.new(0, 5, 0, 5)
                                                }, {
                                                    CreateElement("UIListLayout", {
                                                        FillDirection = Enum.FillDirection.Horizontal,
                                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                                        Padding = UDim.new(0, 5)
                                                    })
                                                }),
                                                CreateElement("Noise"),
                                                CreateElement("Vingette"),
                                                CreateElement("BackgroundImage")
                                            })

                                            WindowFrame.Holder.Position = UDim2.new(0.5, 0, 0.5, 42)
                                            WindowFrame.Holder.Size = UDim2.new(1, -10, 1, -105)

                                            local function UpdateTabButtonSizes()
                                                local ButtonsCount = #Window.TabButtons
                                                if ButtonsCount == 0 then return end

                                                local Width = TabButtonsHolder.ButtonsListFrame.AbsoluteSize.X - (ButtonsCount - 1) * 5
                                                for _, TabButton in Window.TabButtons do
                                                    TabButton.Visible = true
                                                    TabButton.Size = UDim2.new(0, Width / ButtonsCount, 1, 0)
                                                end
                                            end

                                            AddConnection(TabButtonsHolder.ButtonsListFrame:GetPropertyChangedSignal("AbsoluteSize"), UpdateTabButtonSizes)
                                            AddConnection(TabButtonsHolder.ButtonsListFrame.ChildAdded, function(Child)
                                                if Child.Name == "TabButtonFrame" then
                                                    UpdateTabButtonSizes()
                                                end
                                            end)
                                        end

                                        for _, TabButton in Window.TabButtons do
                                            TabButton.Parent = TabButtonsHolder.ButtonsListFrame
                                        end
                                    end

                                    local TabButton = CreateElement("TextButton", {
                                        Name = "TabButtonFrame",
                                        Size = UDim2.new(1, 0, 0, 30),
                                        BackgroundColor3 = Theme.ElementsColor,
                                        BackgroundTransparency = Theme.ElementsTransparency,
                                        Parent = TabButtonsHolder and TabButtonsHolder.ButtonsListFrame or nil,
                                        Visible = false,
                                        Text = "",
                                        AutoButtonColor = false,
                                        BorderSizePixel = 0
                                    }, {
                                        CreateElement("TextLabel", {
                                            Name = "NameText",
                                            Size = UDim2.new(1, 0, 1, 0),
                                            Position = UDim2.new(0, 0, 0, 0),
                                            TextWrapped = true,
                                            Text = TabConfig.Name,
                                            TextSize = 16,
                                            TextColor3 = Theme.TextColor,
                                            TextTransparency = Theme.TextTransparency,
                                            BorderSizePixel = 0,
                                            TextXAlignment = Enum.TextXAlignment.Center,
                                            TextYAlignment = Enum.TextYAlignment.Center,
                                            BackgroundTransparency = 1,
                                            TextWrap = false,
                                            Font = Theme.Font
                                        }),
                                        CreateElement("ImageLabel", {
                                            Name = "Icon",
                                            Size = UDim2.new(0, 20, 0, 20),
                                            Position = UDim2.new(0, 20, 0.5, 0),
                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                            BackgroundTransparency = 1,
                                            ImageTransparency = Theme.LittleTextTransparency,
                                            Image = TabConfig.Icon,
                                        }),
                                        CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                    }); Window.TabButtons[#Window.TabButtons+1] = TabButton

                                    UI.Elements.Texts[#UI.Elements.Texts+1] = TabButton.NameText

                                    local SectionsHolder = CreateElement("FakeFrame", {
                                        Name = "SectionsHolderFrame",
                                        Size = UDim2.new(1, -10, 1, -10),
                                        Position = UDim2.new(0, 5, 0, 5),
                                        Parent = SectionsHolderParent
                                    }, {
                                        CreateElement("FakeFrame", {
                                            Name = "FakeDescendantClipperFrameLeft",
                                            Size = UDim2.new(0.5, 0, 1, -10),
                                            Position = UDim2.new(0, 0, 0, 5),
                                            ClipsDescendants = true,
                                        }, {    
                                            CreateElement("ScrollingFrame", {
                                                Name = "LeftHolderFrame",
                                                Size = UDim2.new(1, 0, 1, 0),
                                                Position = UDim2.new(0, 5, 0, 0),
                                                BackgroundTransparency = 1,
                                                ScrollBarThickness = 0,
                                                ClipsDescendants = false,
                                                ScrollingDirection = Enum.ScrollingDirection.Y,
                                                ElasticBehavior = Enum.ElasticBehavior.Never
                                            }, {
                                                CreateElement("UIListLayout", {
                                                    FillDirection = Enum.FillDirection.Vertical,
                                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                                    Padding = UDim.new(0, 5)
                                                })
                                            }),
                                        }),
                                        CreateElement("FakeFrame", {
                                            Name = "FakeDescendantClipperFrameRight",
                                            Size = UDim2.new(0.5, 0, 1, -10),
                                            Position = UDim2.new(0.5, 0, 0, 5),
                                            ClipsDescendants = true,
                                        }, {
                                            CreateElement("ScrollingFrame", {
                                                Name = "RightHolderFrame",
                                                Size = UDim2.new(1, 0, 1, 0),
                                                Position = UDim2.new(0, 5, 0, 0),
                                                BackgroundTransparency = 1,
                                                ScrollBarThickness = 0,
                                                ClipsDescendants = false,
                                                ScrollingDirection = Enum.ScrollingDirection.Y,
                                                ElasticBehavior = Enum.ElasticBehavior.Never
                                            }, {
                                                CreateElement("UIListLayout", {
                                                    FillDirection = Enum.FillDirection.Vertical,
                                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                                    Padding = UDim.new(0, 5)
                                                })
                                            })
                                        })
                                    })

                                    local function UpdateSizes()
                                        local AbsoluteContentSize = SectionsHolder.FakeDescendantClipperFrameLeft.LeftHolderFrame.UIListLayout.AbsoluteContentSize
                                        PlayTween(SectionsHolder.FakeDescendantClipperFrameLeft.LeftHolderFrame, 0.1, {
                                            CanvasSize = UDim2.new(1, 0, 0, AbsoluteContentSize.Y)
                                        })

                                        local AbsoluteContentSize2 = SectionsHolder.FakeDescendantClipperFrameRight.RightHolderFrame.UIListLayout.AbsoluteContentSize
                                        PlayTween(SectionsHolder.FakeDescendantClipperFrameRight.RightHolderFrame, 0.1, {
                                            CanvasSize = UDim2.new(1, 0, 0, AbsoluteContentSize2.Y)
                                        })
                                    end
                                    UpdateSizes()

                                    if #Window.Tabs > 1 then ChangeTab(Window.Tabs[1].Name, Window.TabButtons[1]) end

                                    local MouseOnTab = false
                                    AddConnection(TabButton.MouseButton1Up, function()
                                        task.spawn(function()
                                            PlayTween(TabButton.NameText, 0.1, { TextSize = 15 })
                                            task.wait(0.2)
                                            PlayTween(TabButton.NameText, 0.1, { TextSize = MouseOnTab and 18 or 16 })
                                        end)
                                        ChangeTab(TabConfig.Name, TabButton)
                                    end)

                                    AddConnection(TabButton.MouseEnter, function() MouseOnTab = true; TabButton.NameText.TextSize = 18 end)
                                    AddConnection(TabButton.MouseLeave, function() MouseOnTab = false; TabButton.NameText.TextSize = 16 end)

                                    AddConnection(SectionsHolder.FakeDescendantClipperFrameLeft.LeftHolderFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateSizes)
                                    AddConnection(SectionsHolder.FakeDescendantClipperFrameRight.RightHolderFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateSizes)

                                -- Functions
                                    local CurrentOpenSection = nil
                                    local function ChangeSectionTab(Name, Button)
                                        local CurrentSect = nil
                                        
                                        for _, Sect in Tab.Sections do
                                            if Sect.Name == Name then
                                                CurrentSect = Sect
                                                CurrentOpenSection = CurrentSect
                                                break
                                            end
                                        end
                                        
                                        local SectionGroupHolderFrame = CurrentSect.FrameParent
                                        local SectionWidth = SectionGroupHolderFrame.AbsoluteSize.X
                                        local TargetPosition = (CurrentSect.GroupIndex - 1) * SectionWidth
                                        
                                        PlayTween(SectionGroupHolderFrame, {0.2, Enum.EasingStyle.Linear}, {
                                            CanvasPosition = Vector2.new(TargetPosition, 0)
                                        })
                                        
                                        local AbsoluteContentSize = CurrentSect.ItemParent.UIListLayout.AbsoluteContentSize
                                        PlayTween(CurrentSect.RealFrame, 0.1, {Size = UDim2.new(1, -10, 0, AbsoluteContentSize.Y + 30)})
                                        UpdateSizes()
                                    end

                                    function Tab:CreateSection(SectionConfig: { Name: string, Side: string }?)
                                        SectionConfig = SectionConfig or {}
                                        SectionConfig.Name = SectionConfig.Name or "Section"
                                        SectionConfig.Side = SectionConfig.Side or "Left" 
                                        SectionConfig.Group = SectionConfig.Group or string_format("%s_Group", SectionConfig.Name)
                                        
                                        local Section = { ItemParent = nil, TabButtons = {} }
                                        local SectionFrame, IsGroup, SectToCreate = nil, false, nil

                                        for _, Sect in Tab.Sections do
                                            if Sect.Group == SectionConfig.Group then 
                                                IsGroup = true
                                                SectToCreate = Sect
                                                break
                                            end
                                        end

                                        if IsGroup then
                                            local SectionButton = CreateElement("TextButton", {
                                                Name = "SectionText",
                                                Text = SectionConfig.Name,
                                                TextXAlignment = Enum.TextXAlignment.Center,
                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                BackgroundTransparency = 1,
                                                Size = UDim2.new(1, 0, 0, 25),
                                                TextColor3 = Theme.TextColor,
                                                Font = Theme.LittleFont,
                                                TextTransparency = Theme.TextTransparency,
                                                TextSize = 15,
                                                BorderSizePixel = 0,
                                                AutoButtonColor = false,
                                                Parent = SectToCreate.Frame
                                            })

                                            SectionFrame = CreateElement("FakeFrame", {
                                                Name = "SectionFrame",
                                                Size = UDim2.new(1, 0, 1, 0),
                                                Position = UDim2.new(0, 0, 0, 0),
                                                Parent = SectToCreate.FrameParent
                                            }, {
                                                CreateElement("UIListLayout", {
                                                    FillDirection = Enum.FillDirection.Vertical,
                                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                                    Padding = UDim.new(0, 5)
                                                })
                                            })

                                            AddConnection(SectionButton.MouseButton1Up, function()
                                                for _, Button in SectToCreate.Frame:GetChildren() do
                                                    if Button.Name == "UIListLayout" then continue end
                                                    Button.TextColor3 = Theme.LittleTextColor
                                                    Button.TextTransparency = Theme.LittleTextTransparency
                                                end

                                                SectionButton.TextColor3 = Theme.TextColor
                                                SectionButton.TextTransparency = 0

                                                ChangeSectionTab(SectionConfig.Name, SectionButton, SectionConfig.Side)
                                            end)

                                            local GroupIndex = 0
                                            for _, Text in SectToCreate.Frame:GetChildren() do
                                                if Text.Name ~= "SectionText" then continue end
                                                GroupIndex = GroupIndex + 1
                                            end

                                            Tab.Sections[#Tab.Sections+1] = { 
                                                Frame = SectToCreate.Frame, 
                                                Group = SectionConfig.Group,
                                                ItemParent = SectionFrame,
                                                Name = SectionConfig.Name,
                                                FrameParent = SectToCreate.FrameParent,
                                                RealFrame = SectionFrame.Parent.Parent,
                                                Side = SectionConfig.Side,
                                                GroupIndex = GroupIndex
                                            }
                                            Tab.SectionsButton[#Tab.SectionsButton+1] = SectionButton

                                            Section.ItemParent = SectionFrame

                                            AddConnection(SectionFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                if not CurrentOpenSection or CurrentOpenSection.Name ~= SectionConfig.Name then return end
                                                
                                                local AbsoluteContentSize = SectionFrame.UIListLayout.AbsoluteContentSize
                                                PlayTween(SectToCreate.RealFrame, 0.1, {Size = UDim2.new(1, -10, 0, AbsoluteContentSize.Y + 30)})
                                                UpdateSizes()
                                            end)

                                            AddConnection(WindowFrame:GetPropertyChangedSignal("AbsoluteSize"), function()
                                                if CurrentOpenSection and CurrentOpenSection.Name == SectionConfig.Name then
                                                    local SectionWidth = SectToCreate.FrameParent.AbsoluteSize.X
                                                    local TargetPosition = (CurrentOpenSection.GroupIndex - 1) * SectionWidth
                                                    SectToCreate.FrameParent.CanvasPosition = Vector2.new(TargetPosition, 0)
                                                end
                                            end)
                                        else
                                            SectionFrame = CreateElement("RoundFrame", {
                                                Name = "SectionFrameFake",
                                                Size = UDim2.new(1, 0, 0, 20),
                                                Parent = (SectionConfig.Side == "Left") and SectionsHolder.FakeDescendantClipperFrameLeft.LeftHolderFrame or SectionsHolder.FakeDescendantClipperFrameRight.RightHolderFrame,
                                                BackgroundTransparency = 0.85,
                                                BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                            }, {
                                                CreateElement("FakeFrame", {
                                                    Name = "ButtonsHolder",
                                                    Size = UDim2.new(1, 0, 0, 25)
                                                }, {
                                                    CreateElement("UIListLayout", {
                                                        FillDirection = Enum.FillDirection.Horizontal,
                                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                                        Padding = UDim.new(0, 0),
                                                        HorizontalAlignment = Enum.HorizontalAlignment.Left
                                                    }),
                                                    CreateElement("TextButton", {
                                                        Name = "SectionText",
                                                        Text = SectionConfig.Name,
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        Size = UDim2.new(1, 0, 0, 25),
                                                        TextColor3 = Theme.TextColor,
                                                        Font = Theme.LittleFont,
                                                        TextTransparency = Theme.TextTransparency,
                                                        TextSize = 15,
                                                        BorderSizePixel = 0,
                                                        AutoButtonColor = false
                                                    })
                                                }),
                                                CreateElement("ScrollingFrame", {
                                                    Name = "SectionGroupHolderFrame",
                                                    Size = UDim2.new(1, 0, 1, -25),
                                                    Position = UDim2.new(0, 0, 0, 25),
                                                    ClipsDescendants = true,
                                                    ScrollingEnabled = false,
                                                    ScrollingDirection = Enum.ScrollingDirection.X,
                                                    ElasticBehavior = Enum.ElasticBehavior.Never,
                                                    BackgroundTransparency = 1,
                                                    ScrollBarThickness = 0,
                                                    AutomaticCanvasSize = "X"
                                                }, {
                                                    CreateElement("UIListLayout", {
                                                        FillDirection = Enum.FillDirection.Horizontal,
                                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                                        Padding = UDim.new(0, 0)
                                                    }),
                                                    CreateElement("FakeFrame", {
                                                        Name = "SectionFrame",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        Position = UDim2.new(0, 0, 0, 0),
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            FillDirection = Enum.FillDirection.Vertical,
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })
                                                })
                                            })
                                            UI.Elements.Sections[#UI.Elements.Sections+1] = SectionFrame

                                            Section.ItemParent = SectionFrame.SectionGroupHolderFrame.SectionFrame
                                            SectionFrame.ButtonsHolder.SectionText.Size = UDim2.new(0, SectionFrame.ButtonsHolder.SectionText.TextBounds.X, 0, 25)

                                            local GroupIndex = 0
                                            for _, Text in SectionFrame.ButtonsHolder:GetChildren() do
                                                if Text.Name ~= "SectionText" then continue end
                                                GroupIndex = GroupIndex + 1
                                            end

                                            Tab.Sections[#Tab.Sections+1] = { 
                                                Frame = SectionFrame.ButtonsHolder, 
                                                Group = SectionConfig.Group,
                                                FrameParent = SectionFrame.SectionGroupHolderFrame,
                                                ItemParent = Section.ItemParent,
                                                Name = SectionConfig.Name,
                                                RealFrame = SectionFrame,
                                                Side = SectionConfig.Side,
                                                GroupIndex = GroupIndex
                                            }
                                            Tab.SectionsButton[#Tab.SectionsButton+1] = SectionFrame.ButtonsHolder.SectionText
                                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = SectionFrame.ButtonsHolder.SectionText

                                            AddConnection(SectionFrame.ButtonsHolder.SectionText.MouseButton1Up, function()
                                                for _, Button in SectionFrame.ButtonsHolder:GetChildren() do
                                                    if Button.Name == "UIListLayout" then continue end
                                                    Button.TextColor3 = Theme.LittleTextColor
                                                    Button.TextTransparency = Theme.LittleTextTransparency
                                                end

                                                SectionFrame.ButtonsHolder.SectionText.TextColor3 = Theme.TextColor
                                                SectionFrame.ButtonsHolder.SectionText.TextTransparency = 0

                                                ChangeSectionTab(SectionConfig.Name, SectionFrame.ButtonsHolder.SectionText, SectionConfig.Side)
                                            end)

                                            AddConnection(Section.ItemParent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                local AbsoluteContentSize = Section.ItemParent.UIListLayout.AbsoluteContentSize
                                                PlayTween(SectionFrame, 0.1, {Size = UDim2.new(1, -10, 0, AbsoluteContentSize.Y + 30)})
                                                UpdateSizes()
                                            end)

                                            AddConnection(SectionFrame.SectionGroupHolderFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                local AbsoluteContentSize = Section.ItemParent.UIListLayout.AbsoluteContentSize
                                                SectionFrame.SectionGroupHolderFrame.CanvasSize = UDim2.new(0, AbsoluteContentSize.X, 0, 0)
                                            end)

                                            local function UpdateTabButtonSizes()
                                                local ButtonsCount = #SectionFrame.ButtonsHolder:GetChildren() - 1
                                                if ButtonsCount == 0 then return end

                                                local Width = SectionFrame.ButtonsHolder.AbsoluteSize.X
                                                for _, TabButton in SectionFrame.ButtonsHolder:GetChildren() do
                                                    if TabButton.Name == "UIListLayout" then continue end

                                                    TabButton.Visible = true
                                                    TabButton.Size = UDim2.new(0, Width / ButtonsCount, 1, 0)
                                                end
                                            end

                                            AddConnection(SectionFrame.ButtonsHolder:GetPropertyChangedSignal("AbsoluteSize"), UpdateTabButtonSizes)
                                            AddConnection(SectionFrame.ButtonsHolder.ChildAdded, function(Child)
                                                if Child.Name == "TabButtonFrame" then
                                                    UpdateTabButtonSizes()
                                                    Tab.SectionsButton[#Tab.SectionsButton+1] = Child
                                                    UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = Child
                                                end
                                            end)

                                            AddConnection(WindowFrame:GetPropertyChangedSignal("AbsoluteSize"), function()
                                                if CurrentOpenSection and CurrentOpenSection.Name == SectionConfig.Name then
                                                    local SectionWidth = SectionFrame.SectionGroupHolderFrame.AbsoluteSize.X
                                                    local TargetPosition = (CurrentOpenSection.GroupIndex - 1) * SectionWidth
                                                    SectionFrame.SectionGroupHolderFrame.CanvasPosition = Vector2.new(TargetPosition, 0)
                                                end
                                            end)

                                            ChangeSectionTab(SectionConfig.Name, SectionFrame.ButtonsHolder.SectionText, SectionConfig.Side)
                                        end

                                        local function GetParent() 
                                            for _, Sect in Tab.Sections do
                                                if Sect.Group == SectionConfig.Group and Sect.Name == SectionConfig.Name and Sect.Side == SectionConfig.Side then
                                                    return Sect.ItemParent
                                                end
                                            end
                                        end

                                        function Section:CreateDividier() 
                                            UI.ElementCounter += 1; if UI.ElementCounter % 10 == 0 then task.wait() end

                                            local DividierFrame = CreateElement("FakeFrame", {
                                                Name = "DividierFrame",
                                                Size = UDim2.new(1, -20, 0, 2),
                                                Parent = GetParent() 
                                            }, {
                                                CreateElement("RoundFrame", {
                                                    Name = "Frame",
                                                    BackgroundColor3 = Theme.DividierColor,
                                                    BackgroundTransparency = Theme.DividierTransparency,
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Size = UDim2.new(1, 0, 1, 0)
                                                })
                                            })

                                            UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = DividierFrame.Frame
                                        end

                                        function Section:CreateLabel(LabelConfig: { Name: string }?)
                                            UI.ElementCounter += 1; if UI.ElementCounter % 5 == 0 then task.wait() end

                                            LabelConfig = LabelConfig or {}
                                            LabelConfig.Name = LabelConfig.Name or "Label"

                                            local Label = {}

                                            local LabelFrame = CreateElement("FakeFrame", {
                                                Size = UDim2.new(1, -20, 0, 30),
                                                Parent = GetParent() 
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "TextName",
                                                    Text = LabelConfig.Name,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    Size = UDim2.new(1, 0, 1, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextSize = 16,
                                                    TextWrapped = true
                                                }, { CreateElement("Corner") })
                                            })

                                            AddConnection(LabelFrame.TextName:GetPropertyChangedSignal("TextBounds"), function()
                                                local TextBounds = LabelFrame.TextName.TextBounds
                                                PlayTween(LabelFrame, 0.1, { Size = UDim2.new(1, -20, 0, TextBounds.Y + 10) })
                                            end)

                                            function Label:Set(Name: string)
                                                LabelFrame.TextName.Text = Name
                                            end

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = LabelFrame.TextName

                                            return Label
                                        end

                                        function Section:CreateButton(ButtonConfig: { 
                                            Name: string, DoubleTap: boolean, Callback: () -> ()
                                        }?) 
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                            ButtonConfig = ButtonConfig or {}
                                            ButtonConfig.Name = ButtonConfig.Name or "Button"
                                            ButtonConfig.DoubleTap = ButtonConfig.DoubleTap or false
                                            ButtonConfig.Callback = ButtonConfig.Callback or function() end

                                            local Button = { Name = ButtonConfig.Name }

                                            local ButtonFrame = CreateElement("TextButton", {
                                                Name = "ButtonFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent(),
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency,
                                                Text = "",
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 1, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextWrapped = true,
                                                    Text = ButtonConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("ImageLabel", {
                                                    Name = "PressIcon",
                                                    Size = UDim2.new(0, 20, 0, 20),
                                                    Position = UDim2.new(1, -20, 0.5, 0),
                                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                                    BackgroundTransparency = 1,
                                                    ImageTransparency = Theme.LittleTextTransparency,
                                                    Image = "rbxassetid://3944703587",
                                                }),
                                                CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                            }); ButtonFrame.NameText.Size = UDim2.new(0, ButtonFrame.NameText.TextBounds.X, 1, 0)

                                            local ButtonIcon = ButtonFrame.PressIcon
                                            local ButtonText = ButtonFrame.NameText

                                            function Button:Press()
                                                task.spawn(function()
                                                    PlayTween(ButtonIcon, 0.1, { Size = UDim2.new(0, 15, 0, 15) }); task.wait(.1)
                                                    PlayTween(ButtonIcon, 0.1, { Size = UDim2.new(0, 20, 0, 20) })
                                                end)

                                                ButtonConfig.Callback()
                                            end

                                            local BindInput = false
                                            function Button:CreateBind(BindConfig: { Default: Enum, Flag: string }?)
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                BindConfig = BindConfig or {}
                                                BindConfig.Default = BindConfig.Default or "None"
                                                BindConfig.Flag = BindConfig.Flag or string_format("Bind%s", UI.ElementCounter)

                                                local MouseKeys = {
                                                    Enum.UserInputType.MouseButton1,
                                                    Enum.UserInputType.MouseButton2,
                                                    Enum.UserInputType.MouseButton3,
                                                    "MouseButton1", 
                                                    "MouseButton2",
                                                    "MouseButton3"
                                                }; local function GetBind(Key)
                                                    if typeof(Key) == "string" then
                                                        if Key == "" or Key == "None" or Key == "nil" then return nil end
                                                        if table_find(MouseKeys, Key) then
                                                            return Enum.UserInputType[Key]
                                                        else
                                                            return Enum.KeyCode[Key]
                                                        end
                                                    end
                                                    return Key
                                                end

                                                local Bind = { 
                                                    Name = ButtonConfig.Name, 
                                                    Value = GetBind(BindConfig.Default) and GetBind(BindConfig.Default).Name or ""
                                                }

                                                local IsBinding = false

                                                local BindBoxFrame = CreateElement("RoundFrame", {
                                                    Name = "BindBoxFrame",
                                                    Size = UDim2.new(0, 40, 0, 20),
                                                    Position = UDim2.new(1, -75, 0.5, 0),
                                                    AnchorPoint = Vector2.new(0, 0.5),
                                                    BackgroundTransparency = 0.9,
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    Parent = ButtonFrame,
                                                    ZIndex = 101
                                                }, {
                                                    CreateElement("TextButton", {
                                                        Name = "BindBox",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        Position = UDim2.new(0, 0, 0.5, 0),
                                                        AnchorPoint = Vector2.new(0, 0.5),
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        TextWrapped = false,
                                                        Text = "None",
                                                        TextSize = 14,
                                                        TextColor3 = Theme.LittleTextColor,
                                                        Font = Theme.LittleFont,
                                                        BackgroundTransparency = 1,
                                                        TextTransparency = Theme.LittleTextTransparency,
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        ZIndex = 102
                                                    }, { CreateElement("Corner") })
                                                })

                                                local BindBox = BindBoxFrame.BindBox
                                                AddConnection(BindBox:GetPropertyChangedSignal("Text"), function()
                                                    local TextBounds = BindBox.TextBounds
                                                    PlayTween(BindBoxFrame, 0.1, { 
                                                        Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                                        Position = UDim2.new(1, -TextBounds.X - 45, 0.5, 0)
                                                    })
                                                end)

                                                function Bind:Set(Key)
                                                    local BindValue = GetBind(Key)
                                                    if not BindValue or BindValue == Enum.KeyCode.None or BindValue == Enum.UserInputType.None then
                                                        Bind.Value = ""
                                                        BindBox.Text = "None"
                                                        return
                                                    end
                                                    Bind.Value = BindValue.Name
                                                    BindBox.Text = BindValue.Name
                                                end

                                                AddConnection(BindBox.MouseButton1Up, function()
                                                    BindInput = true
                                                    IsBinding = true
                                                    BindBox.Text = "Press any key"
                                                end)

                                                AddConnection(Serv.UserInputService.InputBegan, function(Input)
                                                    if Serv.UserInputService:GetFocusedTextBox() then return end
                                                    if IsBinding then
                                                        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
                                                            Bind:Set(Input.UserInputType ~= Enum.UserInputType.Keyboard and Input.UserInputType or Input.KeyCode)
                                                            IsBinding = false
                                                        end
                                                    else
                                                        if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
                                                        Button:Press()
                                                    end
                                                end)

                                                Bind:Set(BindConfig.Default)

                                                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = BindBox
                                                UI.Flags[BindConfig.Flag] = Bind
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = BindBoxFrame

                                                return Bind
                                            end

                                            AddConnection(ButtonFrame.MouseButton1Up, function()
                                                if BindInput then BindInput = false; return end
                                                Button:Press()
                                            end)

                                            AddConnection(ButtonText:GetPropertyChangedSignal("TextBounds"), function()
                                                ButtonText.Size = UDim2.new(0, ButtonText.TextBounds.X, 1, 0)
                                            end)

                                            AddConnection(ButtonFrame.MouseEnter, function() ButtonText.TextSize = 17 end)
                                            AddConnection(ButtonFrame.MouseLeave, function() ButtonText.TextSize = 16 end)

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = ButtonText
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = ButtonFrame
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Button", 
                                                Name = ButtonConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = ButtonFrame,
                                                Side = SectionConfig.Side
                                            }
                                            UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = ButtonIcon

                                            return Button
                                        end

                                        function Section:CreateToggle(ToggleConfig: {
                                            Name: string, Default: boolean, 
                                            Flag: string, Callback: () -> boolean 
                                        }?)
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                            ToggleConfig = ToggleConfig or {}
                                            ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                                            ToggleConfig.Flag = ToggleConfig.Flag or string_format("Toggle%s", UI.ElementCounter)
                                            ToggleConfig.Default = ToggleConfig.Default or false
                                            ToggleConfig.Callback = ToggleConfig.Callback or function() end

                                            local Toggle = {
                                                Type = "Toggle",
                                                Name = ToggleConfig.Name, 
                                                Value = ToggleConfig.Default
                                            }

                                            local ToggleFrame = CreateElement("TextButton", {
                                                Name = "ToggleFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent(),
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency,
                                                Text = "",
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 0, 20),
                                                    Position = UDim2.new(0, 10, 0, 5),
                                                    TextWrapped = true,
                                                    Text = ToggleConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("FakeFrame", {
                                                    Name = "ItemsHolder",
                                                    Size = UDim2.new(1, -10, 0, 20),
                                                    Position = UDim2.new(0, 0, 0, 5),
                                                }, {
                                                    CreateElement("UIListLayout", {
                                                        FillDirection = Enum.FillDirection.Horizontal,
                                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                                        Padding = UDim.new(0, 5),
                                                        HorizontalAlignment = Enum.HorizontalAlignment.Right
                                                    }),
                                                    CreateElement("RoundFrame", {
                                                        Name = "ToggleBox",
                                                        Size = UDim2.new(0, 40, 1, 0),
                                                        BackgroundTransparency = 0.9,
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        LayoutOrder = 100,
                                                    }, {
                                                        CreateElement("RoundFrame", {
                                                            Name = "Circle",
                                                            Size = UDim2.new(0, 16, 0, 16),
                                                            Position = UDim2.new(0, 2, 0, 2),
                                                            BackgroundColor3 = Theme.DividierColor,
                                                            BackgroundTransparency = Theme.DividierTransparency,
                                                        })
                                                    })
                                                }),
                                                CreateElement("TextButton", {
                                                    Name = "Click",
                                                    Size = UDim2.new(1, 0, 0, 30),
                                                    BackgroundTransparency = 1,
                                                    Text = "",
                                                    AutoButtonColor = false,
                                                    BorderSizePixel = 0,
                                                    ZIndex = 100
                                                }),
                                                CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                            }); ToggleFrame.NameText.Size = UDim2.new(0, ToggleFrame.NameText.TextBounds.X, 0, 20)

                                            local ItemHolderSettings = nil
                                            local SettingsArrow = nil
                                            local ToggleText = ToggleFrame.NameText

                                            function Toggle:Set(Value: boolean)
                                                Toggle.Value = Value

                                                task.spawn(function()
                                                    PlayTween(ToggleFrame.ItemsHolder.ToggleBox.Circle, {0.1, Enum.EasingStyle.Quint}, {
                                                        Position = Value and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
                                                    })
                                                end)

                                                ToggleConfig.Callback(Value)
                                            end

                                            function Toggle:SetName(Name: string)
                                                ToggleText.Text = Name
                                            end

                                            local BindInput = false
                                            function Toggle:CreateBind(BindConfig: { Default: Enum, Flag: string }?)
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                BindConfig = BindConfig or {}
                                                BindConfig.Default = BindConfig.Default or "None"
                                                BindConfig.Flag = BindConfig.Flag or string_format("Bind%s", UI.ElementCounter)

                                                local MouseKeys = {
                                                    Enum.UserInputType.MouseButton1,
                                                    Enum.UserInputType.MouseButton2,
                                                    Enum.UserInputType.MouseButton3,
                                                    "MouseButton1", 
                                                    "MouseButton2",
                                                    "MouseButton3"
                                                }; local function GetBind(Key)
                                                    if typeof(Key) == "string" then
                                                        if Key == "" or Key == "None" or Key == "nil" then return nil end
                                                        if table_find(MouseKeys, Key) then
                                                            return Enum.UserInputType[Key]
                                                        else
                                                            return Enum.KeyCode[Key]
                                                        end
                                                    end
                                                    return Key
                                                end

                                                local Bind = { 
                                                    Value = GetBind(BindConfig.Default) and GetBind(BindConfig.Default).Name or "",
                                                    Type = "Bind"
                                                }

                                                local IsBinding = false

                                                local BindBoxFrame = CreateElement("RoundFrame", {
                                                    Name = "BindBoxFrame",
                                                    Size = UDim2.new(0, 40, 1, 0),
                                                    BackgroundTransparency = 0.9,
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    Parent = ToggleFrame.ItemsHolder,
                                                    LayoutOrder = 99,
                                                    ZIndex = 101
                                                }, {
                                                    CreateElement("TextButton", {
                                                        Name = "BindBox",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        Position = UDim2.new(0, 0, 0.5, 0),
                                                        AnchorPoint = Vector2.new(0, 0.5),
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        TextWrapped = false,
                                                        Text = "None",
                                                        TextSize = 14,
                                                        TextColor3 = Theme.LittleTextColor,
                                                        Font = Theme.LittleFont,
                                                        BackgroundTransparency = 1,
                                                        TextTransparency = Theme.LittleTextTransparency,
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        ZIndex = 102
                                                    }, { CreateElement("Corner") })
                                                })

                                                local BindBox = BindBoxFrame.BindBox
                                                AddConnection(BindBox:GetPropertyChangedSignal("Text"), function()
                                                    local TextBounds = BindBox.TextBounds
                                                    PlayTween(BindBoxFrame, 0.1, { 
                                                        Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                                        Position = UDim2.new(1, -TextBounds.X - 65, 0.5, 0)
                                                    })
                                                end)

                                                function Bind:Set(Key)
                                                    local BindValue = GetBind(Key)
                                                    if not BindValue or BindValue == Enum.KeyCode.None or BindValue == Enum.UserInputType.None then
                                                        Bind.Value = ""
                                                        BindBox.Text = "None"
                                                        return
                                                    end
                                                    Bind.Value = BindValue.Name
                                                    BindBox.Text = BindValue.Name
                                                end

                                                AddConnection(BindBox.MouseButton1Up, function()
                                                    BindInput = true
                                                    IsBinding = true
                                                    BindBox.Text = "Press any key"
                                                end)

                                                AddConnection(Serv.UserInputService.InputBegan, function(Input)
                                                    if Serv.UserInputService:GetFocusedTextBox() then return end
                                                    if IsBinding then
                                                        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
                                                            Bind:Set(Input.UserInputType ~= Enum.UserInputType.Keyboard and Input.UserInputType or Input.KeyCode)
                                                            IsBinding = false
                                                        end
                                                    else
                                                        if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
                                                        Toggle.Value = not Toggle.Value
                                                        Toggle:Set(Toggle.Value)
                                                    end
                                                end)

                                                Bind:Set(BindConfig.Default)

                                                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = BindBox
                                                UI.Flags[BindConfig.Flag] = Bind
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = BindBoxFrame

                                                return Bind
                                            end

                                            local ColorpickerInput = false
                                            function Toggle:CreateColorpicker(ColorpickerConfig: { 
                                                Default: Color3, DefaultTransparency: number, Callback: () -> (Color3, number),
                                                Flag: string
                                            })      
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                ColorpickerConfig = ColorpickerConfig or {}
                                                ColorpickerConfig.DefaultColor = ColorpickerConfig.DefaultColor or Color3.fromRGB(255, 255, 255)
                                                ColorpickerConfig.DefaultTransparency = ColorpickerConfig.DefaultTransparency or 0.5
                                                ColorpickerConfig.Flag = ColorpickerConfig.Flag or string_format("Colorpicker%s", UI.ElementCounter)
                                                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                                            
                                                local Colorpicker = { 
                                                    Name = ToggleConfig.Name,
                                                    Value = ColorpickerConfig.DefaultColor,
                                                    TransparencyValue = ColorpickerConfig.DefaultTransparency,
                                                    Type = "Colorpicker"
                                                }

                                                local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.DefaultColor)
                                                local TransparencyColor = ColorpickerConfig.DefaultTransparency

                                                local ColorpickerBox = CreateElement("TextButton", {
                                                    Name = "ColorpickerCircle",
                                                    Size = UDim2.new(0, 20, 1, 0),
                                                    BackgroundColor3 = ColorpickerConfig.DefaultColor,
                                                    BackgroundTransparency = ColorpickerConfig.DefaultTransparency,
                                                    LayoutOrder = 75,
                                                    Parent = ToggleFrame.ItemsHolder,
                                                    Text = "",
                                                    AutoButtonColor = false,
                                                    BorderSizePixel = 0,
                                                    ZIndex = 101
                                                }, { CreateElement("Corner") })

                                                if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                    ItemHolderSettings = CreateElement("FakeFrame", {
                                                        Name = "SettingsHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        Parent = ToggleFrame
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })

                                                    AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                        PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                        PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                    end)
                                                end

                                                local ItemHolder = CreateElement("RoundFrame", {
                                                    Name = "ColorpickerItemHolder",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    BackgroundTransparency = 1,
                                                    Visible = false,
                                                    Active = true,
                                                    ClipsDescendants = true,
                                                    Parent = ItemHolderSettings
                                                }, {
                                                    CreateElement("ImageLabel", {
                                                        Name = "ColorSelect",
                                                        Size = UDim2.new(1, -100, 1, -40),
                                                        Position = UDim2.new(0, 20, 0, 20),
                                                        BackgroundTransparency = 0,
                                                        ImageTransparency = 0,
                                                        Image = "rbxassetid://4155801252"
                                                    }, {
                                                        CreateElement("Corner"),
                                                        CreateElement("ImageLabel", {
                                                            Name = "Select",
                                                            Size = UDim2.new(0, 18, 0, 18),
                                                            Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                            ScaleType = Enum.ScaleType.Fit,
                                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                                            BackgroundTransparency = 1,
                                                            Image = "http://www.roblox.com/asset/?id=4805639000"
                                                        })
                                                    }),
                                                    CreateElement("Frame", {
                                                        Name = "HueSelect",
                                                        Size = UDim2.new(0, 20, 1, -40),
                                                        Position = UDim2.new(1, -70, 0, 20),
                                                        BackgroundTransparency = 0
                                                    }, {
                                                        CreateElement("Corner"),
                                                        CreateElement("ImageLabel", {
                                                            Name = "Select",
                                                            Size = UDim2.new(0, 18, 0, 18),
                                                            Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                            ScaleType = Enum.ScaleType.Fit,
                                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                                            BackgroundTransparency = 1,
                                                            Image = "http://www.roblox.com/asset/?id=4805639000"
                                                        }),
                                                        CreateElement("UIGradient", {
                                                            Rotation = 270,
                                                            Color = ColorSequence.new{
                                                                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), 
                                                                ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), 
                                                                ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), 
                                                                ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), 
                                                                ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), 
                                                                ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), 
                                                                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
                                                            }
                                                        })
                                                    }),
                                                    CreateElement("ImageLabel", {
                                                        Name = "TransparencySelect",
                                                        Size = UDim2.new(0, 20, 1, -70),
                                                        Position = UDim2.new(1, -40, 0, 20),
                                                        BackgroundTransparency = 1,
                                                        ImageTransparency = 0,
                                                        Image = "rbxassetid://139785960036434",
                                                        ScaleType = Enum.ScaleType.Tile,
                                                        TileSize = UDim2.new(0, 7, 0, 7)
                                                    }, {
                                                        CreateElement("Corner"),
                                                        CreateElement("ImageLabel", {
                                                            Name = "Select",
                                                            Size = UDim2.new(0, 18, 0, 18),
                                                            Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                            ScaleType = Enum.ScaleType.Fit,
                                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                                            BackgroundTransparency = 1,
                                                            Image = "http://www.roblox.com/asset/?id=4805639000"
                                                        }),
                                                        CreateElement("UIGradient", {
                                                            Rotation = 270,
                                                            Color = ColorSequence.new{
                                                                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)), 
                                                                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(234, 255, 255)), 
                                                            }
                                                        })
                                                    }),
                                                    CreateElement("TextButton", {
                                                        Name = "ResetButtonFrame",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        Position = UDim2.new(1, -40, 1, -40),
                                                        BackgroundTransparency = 0.9,
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(0, 20, 1, -0),
                                                            Position = UDim2.new(1, -20, 0, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = 0,
                                                            Image = "rbxassetid://10734933056"
                                                        })
                                                    })
                                                })

                                                local Opened, CanBeClosed = false, false

                                                local Color, ColorSelection = ItemHolder.ColorSelect, ItemHolder.ColorSelect.Select
                                                local Hue, HueSelection = ItemHolder.HueSelect, ItemHolder.HueSelect.Select
                                                local Transparency, TransparencySelection = ItemHolder.TransparencySelect, ItemHolder.TransparencySelect.Select
                                                local ResetButton = ItemHolder.ResetButtonFrame
                                                local SizeXHolder = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X - 30

                                                local function ToggleColorpicker(Open: boolean)
                                                    local SizeX = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X

                                                    if not Open then
                                                        Opened = Open
                                                        PlayTween(ItemHolder, 0.2, { Size = UDim2.new(0, SizeX - 30, 0, 0) })
                                                        task.wait(0.15)

                                                        ItemHolder.Visible = Open
                                                        CanBeClosed = false
                                                    else
                                                        Opened = Open
                                                        ItemHolder.Visible = Opened
                                                        PlayTween(ItemHolder, 0.2, { Size = UDim2.new(0, SizeX - 30, 0, 200) })
                                                        task.wait(0.2)
                                                        CanBeClosed = true
                                                    end
                                                end

                                                local function UpdateColorPicker(NotCallbacking)
                                                    ColorH = ColorH >= 0 and ColorH or 0
                                                    ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                                                    ColorpickerBox.BackgroundTransparency = TransparencyColor
                                                    Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)

                                                    Colorpicker.Value = ColorpickerBox.BackgroundColor3
                                                    Colorpicker.TransparencyValue = ColorpickerBox.BackgroundTransparency

                                                    if NotCallbacking == nil or NotCallbacking == false then
                                                        ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3, ColorpickerBox.BackgroundTransparency)
                                                    end
                                                end

                                                function Colorpicker:Set(Value, Transp)
                                                    Colorpicker.Value = Value
                                                    Colorpicker.TransparencyValue = Transp
                                                    ColorpickerBox.BackgroundColor3 = Colorpicker.Value
                                                    ColorpickerBox.BackgroundTransparency = Colorpicker.TransparencyValue
                                                    
                                                    ColorpickerConfig.Callback(
                                                        Colorpicker.Value, 
                                                        Colorpicker.TransparencyValue
                                                    )
                                                end

                                                AddConnection(ResetButton.MouseButton1Up, function()
                                                    ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.DefaultColor)
                                                    TransparencyColor = ColorpickerConfig.DefaultTransparency

                                                    HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                                                    ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                                                    TransparencySelection.Position = UDim2.new(0.5, 0, 1 - TransparencyColor, 0)

                                                    UpdateColorPicker()
                                                end)

                                                AddConnection(ColorpickerBox.MouseButton1Up, function()
                                                    ColorpickerInput = true
                                                    Opened = not Opened
                                                    ToggleColorpicker(Opened)
                                                    task.delay(0.1, function() ColorpickerInput = false end)
                                                end)

                                                AddConnection(SectionsHolder.FakeDescendantClipperFrameRight:GetPropertyChangedSignal("AbsoluteSize"), function()
                                                    local SizeX = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X
                                                    ItemHolder.Size = UDim2.new(0, SizeX - 30, 0, 200)
                                                    ItemHolder.Position = UDim2.new(0, 0, 0, 30)
                                                end)

                                                local ColorInput = nil
                                                AddConnection(Color.InputBegan, function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        if ColorInput then ColorInput:Disconnect() end
                                                        ColorInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                            CanBeClosed = false
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
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        if ColorInput then 
                                                            task.delay(0.1, function() CanBeClosed = true end)
                                                            ColorInput:Disconnect()
                                                            
                                                            local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                                                            local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
                                                            ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                                                            ColorS = ColorX
                                                            ColorV = 1 - ColorY
                                                            UpdateColorPicker()
                                                        end
                                                    end
                                                end)

                                                local HueInput = nil
                                                AddConnection(Hue.InputBegan, function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        if HueInput then HueInput:Disconnect() end

                                                        HueInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                            CanBeClosed = false
                                                            local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                                                            HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                                                            ColorH = 1 - HueY

                                                            UpdateColorPicker()
                                                        end)
                                                    end
                                                end)

                                                AddConnection(Hue.InputEnded, function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        if HueInput then 
                                                            task.delay(0.1, function() CanBeClosed = true end)
                                                            HueInput:Disconnect()
                                                            
                                                            local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                                                            HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                                                            ColorH = 1 - HueY

                                                            UpdateColorPicker()
                                                        end
                                                    end
                                                end)

                                                local TransparencyInput = nil
                                                AddConnection(Transparency.InputBegan, function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        if TransparencyInput then TransparencyInput:Disconnect() end

                                                        TransparencyInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                            CanBeClosed = false
                                                            local TransparencyY = (math.clamp(Mouse.Y - Transparency.AbsolutePosition.Y, 0, Transparency.AbsoluteSize.Y) / Transparency.AbsoluteSize.Y)

                                                            TransparencySelection.Position = UDim2.new(0.5, 0, TransparencyY, 0)
                                                            TransparencyColor = 1 - TransparencyY

                                                            UpdateColorPicker()
                                                        end)
                                                    end
                                                end)

                                                AddConnection(Transparency.InputEnded, function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        if TransparencyInput then 
                                                            task.delay(0.1, function() CanBeClosed = true end)
                                                            TransparencyInput:Disconnect()
                                                            
                                                            local TransparencyY = (math.clamp(Mouse.Y - Transparency.AbsolutePosition.Y, 0, Transparency.AbsoluteSize.Y) / Transparency.AbsoluteSize.Y)

                                                            TransparencySelection.Position = UDim2.new(0.5, 0, TransparencyY, 0)
                                                            TransparencyColor = 1 - TransparencyY

                                                            UpdateColorPicker()
                                                        end
                                                    end
                                                end)

                                                HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                                                ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                                                TransparencySelection.Position = UDim2.new(0.5, 0, 1 - TransparencyColor, 0)

                                                Colorpicker:Set(ColorpickerConfig.DefaultColor, ColorpickerConfig.DefaultTransparency)

                                                UI.Flags[ColorpickerConfig.Flag] = Colorpicker

                                                return Colorpicker
                                            end

                                            local SliderInput = false
                                            function Toggle:CreateSlider(SliderConfig: {
                                                Name: string, Default: number,
                                                Min: number, Max: number, Increment: number,
                                                ValueName: string, Flag: string,
                                                Callback: () -> number, InputEndedCallback: () -> number
                                            })
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                SliderConfig = SliderConfig or {}
                                                SliderConfig.Name = SliderConfig.Name or "Slider"
                                                SliderConfig.Default = SliderConfig.Default or 50
                                                SliderConfig.Min = SliderConfig.Min or 0
                                                SliderConfig.Max = SliderConfig.Max or 100
                                                SliderConfig.Increment = SliderConfig.Increment or 1
                                                SliderConfig.ValueName = SliderConfig.ValueName or ""
                                                SliderConfig.Flag = SliderConfig.Flag or string_format("Slider%s", UI.ElementCounter)
                                                SliderConfig.Callback = SliderConfig.Callback or function() end
                                                SliderConfig.InputEndedCallback = SliderConfig.InputEndedCallback or function() end

                                                local Slider = {
                                                    Name = SliderConfig.Name,
                                                    Value = SliderConfig.Default,
                                                    Type = "Slider"
                                                }

                                                if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                    ItemHolderSettings = CreateElement("FakeFrame", {
                                                        Name = "SettingsHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        Parent = ToggleFrame
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })

                                                    AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                        PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                        PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                    end)
                                                end

                                                if not ToggleFrame.ItemsHolder:FindFirstChild("SettingsArrow") then
                                                    local ArrowToggled = false
                                                    SettingsArrow = CreateElement("TextButton", {
                                                        Name = "SettingsArrow",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        ZIndex = 101
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = Theme.LittleTextTransparency,
                                                            Image = "rbxassetid://10709790948",
                                                            Rotation = 180,
                                                            LayoutOrder = -100
                                                        })
                                                    })
                                                    
                                                    AddConnection(SettingsArrow.MouseButton1Up, function()
                                                        ArrowToggled = not ArrowToggled
                                                        PlayTween(SettingsArrow.Image, 0.1, { Rotation = ArrowToggled and 0 or 180 })
                                                    end)
                                                end

                                                local SliderParentFrame = CreateElement("RoundFrame", {
                                                    Name = "SliderParentFrame",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    Parent = ItemHolderSettings,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    ClipsDescendants = true,
                                                    Visible = false
                                                })
                                                
                                                local SliderFrame = CreateElement("RoundFrame", {
                                                    Name = "SliderFrame",
                                                    Size = UDim2.new(1, -10, 0, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Parent = SliderParentFrame,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    ClipsDescendants = true,
                                                }, {
                                                    CreateElement("TextLabel", {
                                                        Name = "NameText",
                                                        Size = UDim2.new(1, -30, 0, 30),
                                                        Position = UDim2.new(0, 10, 0, 0),
                                                        TextWrapped = true,
                                                        Text = SliderConfig.Name,
                                                        TextSize = 16,
                                                        TextColor3 = Theme.TextColor,
                                                        Font = Theme.Font,
                                                        TextTransparency = Theme.TextTransparency,
                                                        BorderSizePixel = 0,
                                                        TextXAlignment = Enum.TextXAlignment.Left,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        TextWrap = false
                                                    }),
                                                    CreateElement("TextBox", {
                                                        Name = "Value",
                                                        Size = UDim2.new(0, 50, 0, 20),
                                                        Position = UDim2.new(1, -60, 0, 5),
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        TextWrapped = false,
                                                        Text = string_format("%s%s", Slider.Value, SliderConfig.ValueName),
                                                        TextSize = 14,
                                                        TextColor3 = Theme.LittleTextColor,
                                                        Font = Theme.LittleFont,
                                                        TextTransparency = Theme.LittleTextTransparency,
                                                        BackgroundTransparency = 0.9,
                                                        PlaceholderText = "Enter value",
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    }, { CreateElement("Corner") }),
                                                    CreateElement("RoundFrame", {
                                                        Name = "SliderBar",
                                                        Size = UDim2.new(1, -20, 0, 10),
                                                        Position = UDim2.new(0, 10, 0, 40),
                                                        AnchorPoint = Vector2.new(0, 0.5),
                                                        BackgroundTransparency = 0.9,
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                                    }, {
                                                        CreateElement("RoundFrame", {
                                                            Name = "Bar",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            BackgroundTransparency = Theme.LittleTextTransparency,
                                                            BackgroundColor3 = Theme.LittleTextColor,
                                                        })
                                                    }),
                                                    CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                                }); SliderFrame.NameText.Size = UDim2.new(0, SliderFrame.NameText.TextBounds.X, 0, 30)

                                                local SliderText = SliderFrame.NameText
                                                local SliderValue = SliderFrame.Value
                                                local SliderBar = SliderFrame.SliderBar
                                                local Bar = SliderBar.Bar
                                                local Dragging = false
                                                local Focused = false

                                                function Slider:Set(Value)
                                                    Slider.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                                                    
                                                    PlayTween(Bar, {0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {
                                                        Size = UDim2.fromScale((Slider.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)
                                                    }):Play()

                                                    SliderValue.Text = string_format("%s%s", tostring(Slider.Value), SliderConfig.ValueName)
                                                    SliderConfig.Callback(Slider.Value)
                                                end

                                                function Slider:SetMax(Value)
                                                    SliderConfig.Max = Value
                                                    Slider:Set(Slider.Value)
                                                end

                                                function Slider:SetMin(Value)
                                                    SliderConfig.Min = Value
                                                    Slider:Set(Slider.Value)
                                                end

                                                function Slider:Get()
                                                    return Slider.Value
                                                end

                                                local Opened, CanBeClosed = false, false
                                                AddConnection(SettingsArrow.MouseButton1Up, function()
                                                    SliderInput = true
                                                    Opened = not Opened

                                                    if Opened then
                                                        SliderParentFrame.Visible = true
                                                    else
                                                        task.delay(0.1, function() SliderParentFrame.Visible = false end)
                                                    end

                                                    PlayTween(SliderFrame, 0.1, { Size = UDim2.new(1, -20, 0, Opened and 30 or 0) })
                                                    PlayTween(SliderParentFrame, 0.1, { Size = UDim2.new(1, 0, 0, Opened and 30 or 0) })
                                                end)

                                                AddConnection(SliderBar.InputBegan, function(Input)
                                                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                                                    Dragging = true
                                                end)

                                                AddConnection(SliderBar.InputEnded, function(Input)
                                                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                                                    Dragging = false

                                                    local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                                                    SliderConfig.InputEndedCallback(Round(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale), SliderConfig.Increment))
                                                end)

                                                AddConnection(Serv.UserInputService.InputChanged, function(Input)
                                                    if not Dragging then return end
                                                    if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end

                                                    local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                                                    Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale)) 
                                                end)

                                                local function UpdateSize()
                                                    SliderValue.Text = SliderValue.Text:gsub("[^%d%.%-]", "")
                                                    local TextBounds = SliderValue.TextBounds
                                                    PlayTween(SliderValue, 0.1, {
                                                        Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                                        Position = UDim2.new(1, -TextBounds.X - 20, 0, 5)
                                                    })
                                                end

                                                AddConnection(SliderValue:GetPropertyChangedSignal("Text"), UpdateSize)

                                                AddConnection(SliderValue.Focused, function() Focused = true end)
                                                AddConnection(SliderValue.FocusLost, function()
                                                    Focused = false
                                                    if SliderValue.Text == "" then Slider:Set(Slider.Value); return end

                                                    Slider.Value = SliderValue.Text
                                                    Slider:Set(Slider.Value)
                                                end)

                                                AddConnection(SliderFrame.MouseEnter, function()
                                                    SliderText.TextSize = 17 
                                                    PlayTween(SliderFrame, 0.1, { Size = Opened and UDim2.new(1, -20, 0, 50) or UDim2.new(1, -20, 0, 0) })
                                                    PlayTween(SliderParentFrame, 0.1, { Size = Opened and UDim2.new(1, 0, 0, 50) or UDim2.new(1, 0, 0, 0) })
                                                end)

                                                AddConnection(SliderFrame.MouseLeave, function() 
                                                    if Dragging or Focused then
                                                        while Dragging or Focused do task.wait() end
                                                        task.wait(0.2)
                                                    end

                                                    SliderText.TextSize = 16 
                                                    PlayTween(SliderFrame, 0.1, { Size = Opened and UDim2.new(1, -20, 0, 30) or UDim2.new(1, -20, 0, 0) })
                                                    PlayTween(SliderParentFrame, 0.1, { Size = Opened and UDim2.new(1, 0, 0, 30) or UDim2.new(1, 0, 0, 0) })
                                                end)
                                                
                                                Slider:Set(SliderConfig.Default)
                                                UpdateSize()

                                                UI.Elements.Texts[#UI.Elements.Texts+1] = SliderText
                                                UI.Elements.Elements[#UI.Elements.Elements+1] = SliderFrame
                                                UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = Bar
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = SliderValue
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = SliderBar
                                                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = SliderValue

                                                UI.Flags[SliderConfig.Flag] = Slider

                                                return Slider
                                            end 

                                            local DropdownInput = false
                                            function Toggle:CreateDropdown(DropdownConfig: {
                                                Name: string, Default: any,
                                                Options: table, Multi: boolean,
                                                Flag: string, Callback: () -> any,
                                            })  
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                DropdownConfig = DropdownConfig or {}
                                                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                                                DropdownConfig.Default = DropdownConfig.Default or "None"
                                                DropdownConfig.Options = DropdownConfig.Options or {}
                                                DropdownConfig.Multi = DropdownConfig.Multi or false
                                                DropdownConfig.Flag = DropdownConfig.Flag or string_format("Dropdown%s", UI.ElementCounter)
                                                DropdownConfig.Callback = DropdownConfig.Callback or function() end

                                                local Dropdown = { 
                                                    Name = DropdownConfig.Name,
                                                    Value = DropdownConfig.Default,
                                                    Type = "Dropdown"
                                                }
                                                local SelectedOptions = {}

                                                if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                    ItemHolderSettings = CreateElement("FakeFrame", {
                                                        Name = "SettingsHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        Parent = ToggleFrame
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })

                                                    AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                        PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                        PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                    end)
                                                end

                                                if not ToggleFrame.ItemsHolder:FindFirstChild("SettingsArrow") then
                                                    local ArrowToggled = false
                                                    SettingsArrow = CreateElement("TextButton", {
                                                        Name = "SettingsArrow",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        ZIndex = 101
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = Theme.LittleTextTransparency,
                                                            Image = "rbxassetid://10709790948",
                                                            Rotation = 180,
                                                            LayoutOrder = -100
                                                        })
                                                    })
                                                    
                                                    AddConnection(SettingsArrow.MouseButton1Up, function()
                                                        ArrowToggled = not ArrowToggled
                                                        PlayTween(SettingsArrow.Image, 0.1, { Rotation = ArrowToggled and 0 or 180 })
                                                    end)
                                                end

                                                local DropdownParentFrame = CreateElement("RoundFrame", {
                                                    Name = "DropdownParentFrame",
                                                    Size = UDim2.new(1, -20, 0, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Parent = ItemHolderSettings,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    ClipsDescendants = true,
                                                    Visible = false
                                                })

                                                local DropdownFrame = CreateElement("RoundFrame", {
                                                    Name = "DropdownFrame",
                                                    Size = UDim2.new(1, -20, 0, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Parent = DropdownParentFrame,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    ClipsDescendants = true
                                                }, {
                                                    CreateElement("TextLabel", {
                                                        Name = "NameText",
                                                        Size = UDim2.new(1, -30, 0, 30),
                                                        Position = UDim2.new(0, 10, 0, 0),
                                                        TextWrapped = true,
                                                        Text = DropdownConfig.Name,
                                                        TextSize = 16,
                                                        TextColor3 = Theme.TextColor,
                                                        Font = Theme.Font,
                                                        TextTransparency = Theme.TextTransparency,
                                                        BorderSizePixel = 0,
                                                        TextXAlignment = Enum.TextXAlignment.Left,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        TextWrap = false
                                                    }),
                                                    CreateElement("RoundFrame", {
                                                        Name = "SelectedItemBox",
                                                        Size = UDim2.new(0, 40, 0, 20),
                                                        Position = UDim2.new(1, -50, 0, 5),
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        BackgroundTransparency = 0.9,
                                                    }, {
                                                        CreateElement("TextLabel", {
                                                            Name = "NameText",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            Position = UDim2.new(0, 0, 0, 0),
                                                            TextWrapped = true,
                                                            Text = "None",
                                                            TextSize = 14,
                                                            TextColor3 = Theme.LittleTextColor,
                                                            Font = Theme.LittleFont,
                                                            TextTransparency = Theme.LittleTextTransparency,
                                                            BorderSizePixel = 0,
                                                            TextXAlignment = Enum.TextXAlignment.Center,
                                                            TextYAlignment = Enum.TextYAlignment.Center,
                                                            BackgroundTransparency = 1,
                                                            TextWrap = false
                                                        }),
                                                    }),
                                                    CreateElement("RoundFrame", {
                                                        Name = "ItemHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        BackgroundTransparency = 1,
                                                        Visible = false,
                                                        Active = true,
                                                        ZIndex = 10,
                                                    }, {
                                                        CreateElement("ScrollingFrame", {
                                                            Name = "Holder",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            Position = UDim2.new(0, 0, 0, 0),
                                                            BackgroundTransparency = 1,
                                                            ScrollBarThickness = 0,
                                                            Active = true
                                                        }, {
                                                            CreateElement("UIListLayout", {
                                                                SortOrder = Enum.SortOrder.LayoutOrder,
                                                                Padding = UDim.new(0, 5)
                                                            }),
                                                        })
                                                    }),
                                                    CreateElement("TextButton", {
                                                        Name = "Click",
                                                        Size = UDim2.new(1, 0, 0, 30),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0
                                                    }),
                                                    CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                                }); DropdownFrame.NameText.Size = UDim2.new(0, DropdownFrame.NameText.TextBounds.X, 0, 30)

                                                local DropdownText = DropdownFrame.NameText
                                                local SelectedItemBox = DropdownFrame.SelectedItemBox
                                                local ItemHolder = DropdownFrame.ItemHolder
                                                local Opened, CanBeClosed = false, false

                                                local function DropdownSet(Option: string, FromClick: boolean)
                                                    local OptionButton = ItemHolder.Holder:FindFirstChild(string_format("ButtonFrame_%s", Option))
                                                    if not OptionButton then return end

                                                    local DeSelected = false

                                                    -- De Select
                                                        if FromClick and OptionButton.FakeTextName.BackgroundTransparency ~= 1 then
                                                            DeSelected = true

                                                            PlayTween(OptionButton.FakeTextName, 0.2, { 
                                                                BackgroundTransparency = 1
                                                            }); OptionButton.FakeTextName.TextName.TextSize = 16

                                                            if DropdownConfig.Multi then
                                                                for i, OptionSelect in SelectedOptions do
                                                                    if Option ~= OptionSelect then continue end
                                                                    table.remove(SelectedOptions, i)
                                                                    DropdownConfig.Callback(SelectedOptions)
                                                                end
                                                            else
                                                                Option = ""
                                                            end
                                                        end

                                                    -- Select
                                                        if not DropdownConfig.Multi then
                                                            for _, Button in ItemHolder.Holder:GetChildren() do
                                                                if Button.Name == "UIListLayout" then continue end
                                                                local ButtonText = Button.FakeTextName
                                                                PlayTween(ButtonText, 0.2, { BackgroundTransparency = 1 })
                                                                ButtonText.TextName.TextSize = 16
                                                            end

                                                            DropdownConfig.Callback(Option)
                                                            SelectedItemBox.NameText.Text = Option
                                                            Dropdown.Value = Option
                                                        else
                                                            if not DeSelected then
                                                                local AlreadySelected = false
                                                                for _, OptionSelect in SelectedOptions do
                                                                    if Option == OptionSelect then
                                                                        AlreadySelected = true
                                                                        break
                                                                    end
                                                                end
                                                                
                                                                if not AlreadySelected then
                                                                    table.insert(SelectedOptions, Option)
                                                                    DropdownConfig.Callback(SelectedOptions)
                                                                end
                                                            end
                                                            Dropdown.Value = SelectedOptions

                                                            local SelectedString = ""
                                                            for i, OptionSelect in SelectedOptions do
                                                                local FormOption = string.len(OptionSelect) > 5 and string_format("%s.", OptionSelect:sub(0, 5)) or OptionSelect
                                                                SelectedString = i == 1 and tostring(FormOption) or string.format("%s, %s", SelectedString, tostring(FormOption))
                                                            end

                                                            SelectedItemBox.NameText.Text = string.len(SelectedString) > 25 and string_format("%s, ...", SelectedString:sub(0, 25)) or SelectedString
                                                        end

                                                    -- Init Text
                                                        SelectedItemBox.NameText.Text = SelectedItemBox.NameText.Text:gsub("%(%(", ""):gsub("%)%)", "")
                                                        if SelectedItemBox.NameText.Text == "" then
                                                            SelectedItemBox.NameText.Text = "None"
                                                        end

                                                        if not DeSelected then 
                                                            PlayTween(OptionButton.FakeTextName, 0.2, { 
                                                                BackgroundTransparency = 0.8
                                                            }); OptionButton.FakeTextName.TextName.TextSize = 17
                                                        end

                                                        SelectedItemBox.Size = UDim2.new(0, SelectedItemBox.NameText.TextBounds.X + 10, 0, 20)
                                                        SelectedItemBox.Position = UDim2.new(1, -(SelectedItemBox.NameText.TextBounds.X + 20), 0, 5)
                                                end

                                                function Dropdown:Set(Options: string | table)
                                                    SelectedOptions = {}
                                                    
                                                    for _, Button in ItemHolder.Holder:GetChildren() do
                                                        if Button.Name == "UIListLayout" then continue end
                                                        local ButtonText = Button.FakeTextName
                                                        PlayTween(ButtonText, 0.2, { BackgroundTransparency = 1 })
                                                        ButtonText.TextName.TextSize = 16
                                                    end
                                                    
                                                    SelectedItemBox.NameText.Text = "None"
                                                    SelectedItemBox.Size = UDim2.new(0, SelectedItemBox.NameText.TextBounds.X + 10, 0, 20)
                                                    SelectedItemBox.Position = UDim2.new(1, -(SelectedItemBox.NameText.TextBounds.X + 20), 0, 5)

                                                    if typeof(Options) == "string" then
                                                        DropdownSet(Options, false)
                                                        Dropdown.Value = Options
                                                    else
                                                        for _, Option in Options do DropdownSet(Option, false) end
                                                        Dropdown.Value = SelectedOptions
                                                    end
                                                end

                                                local AbsoluteContentSize = ItemHolder.Holder.UIListLayout.AbsoluteContentSize
                                                local SizeY = math.clamp(AbsoluteContentSize.Y, 1, 200)

                                                local function ToggleDropdown(Open: boolean)
                                                    if not ItemHolder:FindFirstChild("Holder") then return end

                                                    AbsoluteContentSize = ItemHolder.Holder.UIListLayout.AbsoluteContentSize
                                                    SizeY = math.clamp(AbsoluteContentSize.Y, 1, 200)

                                                    if not Open then
                                                        Opened = Open
                                                        PlayTween(ItemHolder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
                                                        PlayTween(DropdownFrame, 0.2, { Size = UDim2.new(1, -20, 0, 30) })
                                                        PlayTween(DropdownParentFrame, 0.2, { Size = UDim2.new(1, 0, 0, 30) })
                                                        task.wait(0.2)

                                                        ItemHolder.Visible = Open
                                                        CanBeClosed = false
                                                    else
                                                        Opened = Open
                                                        ItemHolder.Visible = Opened
                                                        PlayTween(ItemHolder, 0.2, { Size = UDim2.new(1, 0, 0, SizeY) })
                                                        PlayTween(DropdownFrame, 0.2, { Size = UDim2.new(1, -20, 0, SizeY + 30) })
                                                        PlayTween(DropdownParentFrame, 0.2, { Size = UDim2.new(1, 0, 0, SizeY + 30) })
                                                        task.wait(0.2)
                                                        CanBeClosed = true
                                                    end
                                                end
                                                
                                                local function AddOptions(OptionsAdd)
                                                    AddConnection(ItemHolder.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolder.Holder.UIListLayout.AbsoluteContentSize
                                                        ItemHolder.Holder.CanvasSize = UDim2.new(0, 0, 0, AbsoluteContentSize.Y)
                                                        ItemHolder.Size = UDim2.new(1, 0, 0, math.clamp(AbsoluteContentSize.Y, 1, 250)) 
                                                    end)

                                                    for i, Option in OptionsAdd do
                                                        local Split = string_match(Option, "[((]") and Option:split("((")
                                                        local ToGsub = Split and Split[2] or nil
                                                        local Desctiption = ToGsub and ToGsub:gsub("[))]", "") or ""

                                                        local ButtonFrame = CreateElement("TextButton", {
                                                            Name = string_format("ButtonFrame_%s", Option),
                                                            Size = UDim2.new(1, 0, 0, 30),
                                                            Parent = ItemHolder.Holder,
                                                            Active = true,
                                                            ZIndex = 11,
                                                            BackgroundTransparency = 1,
                                                            Text = "",
                                                            AutoButtonColor = false,
                                                            BorderSizePixel = 0
                                                        }, {
                                                            CreateElement("RoundFrame", {
                                                                Name = "FakeTextName",
                                                                Size = UDim2.new(1, -20, 1, -10),
                                                                Position = UDim2.new(0, 10, 0, 5),
                                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                                BackgroundTransparency = 1
                                                            }, {
                                                                CreateElement("TextLabel", {
                                                                    Name = "TextName",
                                                                    Size = UDim2.new(1, -20, 1, 0),
                                                                    Position = UDim2.new(0, 10, 0, 0),
                                                                    TextWrapped = true,
                                                                    Text = Split and Split[1] or Option,
                                                                    TextSize = 16,
                                                                    TextColor3 = Theme.TextColor,
                                                                    Font = Theme.Font,
                                                                    TextTransparency = Theme.TextTransparency,
                                                                    BorderSizePixel = 0,
                                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                                    BackgroundTransparency = 1,
                                                                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                                    TextWrap = true,
                                                                    ZIndex = 12
                                                                }),
                                                                CreateElement("TextLabel", {
                                                                    Name = "TextDescription",
                                                                    Size = UDim2.new(1, -10, 1, 0),
                                                                    Position = UDim2.new(0, 0, 0, 0),
                                                                    TextWrapped = true,
                                                                    Text = Desctiption,
                                                                    TextSize = 15,
                                                                    TextColor3 = Theme.LittleTextColor,
                                                                    Font = Theme.LittleFont,
                                                                    TextTransparency = Theme.LittleTextTransparency,
                                                                    BorderSizePixel = 0,
                                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                                    BackgroundTransparency = 1,
                                                                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                                    TextWrap = true,
                                                                    ZIndex = 12
                                                                })
                                                            })
                                                        })

                                                        local TextName, TextDescription = ButtonFrame.FakeTextName.TextName, ButtonFrame.FakeTextName.TextDescription
                                                        local TextNameBounds = TextName.TextBounds

                                                        AddConnection(TextName:GetPropertyChangedSignal("TextBounds"), function()
                                                            TextDescription.Size = UDim2.new(1, -TextName.TextBounds.X - 25, 1, 0)
                                                            TextDescription.Position = UDim2.new(0, TextName.TextBounds.X + 15, 0, 0)
                                                        end)

                                                        TextDescription.Size = UDim2.new(1, -TextName.TextBounds.X - 25, 1, 0)
                                                        TextDescription.Position = UDim2.new(0, TextName.TextBounds.X + 15, 0, 0)

                                                        AddConnection(ButtonFrame.MouseButton1Up, function()
                                                            CanBeClosed = false
                                                            task.delay(0.2, function() CanBeClosed = true end)

                                                            if typeof(Option) == "string" then
                                                                DropdownSet(Option, true)
                                                            else
                                                                for _, Options in Option do DropdownSet(Options, true) end
                                                            end
                                                        end)
                                                    end

                                                    if NeedSet then
                                                        if typeof(ToSelect) == "string" then
                                                            DropdownSet(ToSelect, true)
                                                        else
                                                            for _, Options in ToSelect do DropdownSet(ToSelect, true) end
                                                        end
                                                    end
                                                end

                                                function Dropdown:Refresh(OptionsAdd, NeedSet, ToSelect)
                                                    local OldDropdownValue = Dropdown.Value
                                                    SelectedOptions = {}

                                                    for _, Button in ItemHolder.Holder:GetChildren() do
                                                        if Button.Name == "UIListLayout" then continue end
                                                        local ButtonText = Button.FakeTextName
                                                        PlayTween(ButtonText, 0.2, { BackgroundTransparency = 1 })
                                                        ButtonText.TextName.TextSize = 16
                                                    end

                                                    SelectedItemBox.NameText.Text = "None"
                                                    SelectedItemBox.Size = UDim2.new(0, SelectedItemBox.NameText.TextBounds.X + 10, 0, 20)
                                                    SelectedItemBox.Position = UDim2.new(1, -(SelectedItemBox.NameText.TextBounds.X + 20), 0, 5)

                                                    for _, Option in ItemHolder.Holder:GetChildren() do
                                                        if Option.Name == "UIListLayout" then continue end
                                                        Option:Destroy(OptionsAdd)
                                                    end

                                                    AddOptions(OptionsAdd, true, OldDropdownValue)
                                                end

                                                AddOptions(DropdownConfig.Options)

                                                local OpenedToggle, CanBeClosedToggle = false, false
                                                AddConnection(SettingsArrow.MouseButton1Up, function()
                                                    DropdownInput = true
                                                    OpenedToggle = not OpenedToggle

                                                    if OpenedToggle then
                                                        DropdownParentFrame.Visible = true
                                                    else
                                                        task.delay(0.1, function() DropdownParentFrame.Visible = false end)
                                                    end

                                                    PlayTween(DropdownFrame, 0.1, { Size = UDim2.new(1, -20, 0, OpenedToggle and 30 or 0) })
                                                    PlayTween(DropdownParentFrame, 0.1, { Size = UDim2.new(1, 0, 0, OpenedToggle and 30 or 0) })
                                                end)

                                                AddConnection(DropdownFrame.Click.MouseButton1Up, function()
                                                    Opened = not Opened
                                                    ToggleDropdown(Opened)
                                                end)

                                                AddConnection(DropdownFrame.MouseEnter, function() DropdownText.TextSize = 17 end)
                                                AddConnection(DropdownFrame.MouseLeave, function() DropdownText.TextSize = 16 end)

                                                UI.Elements.Texts[#UI.Elements.Texts+1] = DropdownText
                                                UI.Elements.Elements[#UI.Elements.Elements+1] = DropdownFrame
                                                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = SelectedItemBox.NameText
                                                for _, Button in ItemHolder.Holder:GetChildren() do
                                                    if Button.Name == "UIListLayout" then continue end
                                                    UI.Elements.Texts[#UI.Elements.Texts+1] = Button.FakeTextName.TextName
                                                end

                                                Dropdown:Set(DropdownConfig.Default)

                                                UI.Flags[DropdownConfig.Flag] = Dropdown
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = SelectedItemBox

                                                return Dropdown
                                            end

                                            function Toggle:CreateToggle(ToggleConfig: {
                                                Name: string, Default: boolean, 
                                                Flag: string, Callback: () -> boolean 
                                            })
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                ToggleConfig = ToggleConfig or {}
                                                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                                                ToggleConfig.Flag = ToggleConfig.Flag or string_format("Toggle%s", UI.ElementCounter)
                                                ToggleConfig.Default = ToggleConfig.Default or false
                                                ToggleConfig.Callback = ToggleConfig.Callback or function() end

                                                local Toggle = { 
                                                    Name = ToggleConfig.Name, 
                                                    Value = ToggleConfig.Default,
                                                    Type = "Toggle"
                                                }

                                                if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                    ItemHolderSettings = CreateElement("FakeFrame", {
                                                        Name = "SettingsHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        Parent = ToggleFrame
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })

                                                    AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                        PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                        PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                    end)
                                                end

                                                if not ToggleFrame.ItemsHolder:FindFirstChild("SettingsArrow") then
                                                    local ArrowToggled = false
                                                    SettingsArrow = CreateElement("TextButton", {
                                                        Name = "SettingsArrow",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        ZIndex = 101
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = Theme.LittleTextTransparency,
                                                            Image = "rbxassetid://10709790948",
                                                            Rotation = 180,
                                                            LayoutOrder = -100
                                                        })
                                                    })
                                                    
                                                    AddConnection(SettingsArrow.MouseButton1Up, function()
                                                        ArrowToggled = not ArrowToggled
                                                        PlayTween(SettingsArrow.Image, 0.1, { Rotation = ArrowToggled and 0 or 180 })
                                                    end)
                                                end

                                                local ToggleParentFrame = CreateElement("RoundFrame", {
                                                    Name = "ToggleParentFrame",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    Parent = ItemHolderSettings,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    Visible = false
                                                })

                                                local ToggleFrame = CreateElement("TextButton", {
                                                    Name = "ToggleFrame",
                                                    Size = UDim2.new(1, 0, 0, 30),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Parent = ToggleParentFrame,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    Text = "",
                                                    AutoButtonColor = false,
                                                    BorderSizePixel = 0
                                                }, {
                                                    CreateElement("TextLabel", {
                                                        Name = "NameText",
                                                        Size = UDim2.new(1, -30, 0, 20),
                                                        Position = UDim2.new(0, 10, 0, 5),
                                                        TextWrapped = true,
                                                        Text = ToggleConfig.Name,
                                                        TextSize = 16,
                                                        TextColor3 = Theme.TextColor,
                                                        Font = Theme.Font,
                                                        TextTransparency = Theme.TextTransparency,
                                                        BorderSizePixel = 0,
                                                        TextXAlignment = Enum.TextXAlignment.Left,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        TextWrap = false
                                                    }),
                                                    CreateElement("FakeFrame", {
                                                        Name = "ItemsHolder",
                                                        Size = UDim2.new(1, -10, 0, 20),
                                                        Position = UDim2.new(0, 0, 0, 5),
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            FillDirection = Enum.FillDirection.Horizontal,
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5),
                                                            HorizontalAlignment = Enum.HorizontalAlignment.Right
                                                        }),
                                                        CreateElement("RoundFrame", {
                                                            Name = "ToggleBox",
                                                            Size = UDim2.new(0, 40, 1, 0),
                                                            BackgroundTransparency = 0.9,
                                                            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                            LayoutOrder = 100,
                                                        }, {
                                                            CreateElement("RoundFrame", {
                                                                Name = "Circle",
                                                                Size = UDim2.new(0, 16, 0, 16),
                                                                Position = UDim2.new(0, 2, 0, 2),
                                                                BackgroundColor3 = Theme.DividierColor,
                                                                BackgroundTransparency = Theme.DividierTransparency,
                                                            })
                                                        })
                                                    }),
                                                    CreateElement("TextButton", {
                                                        Name = "Click",
                                                        Size = UDim2.new(1, 0, 0, 30),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        ZIndex = 100
                                                    }),
                                                    CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                                }); ToggleFrame.NameText.Size = UDim2.new(0, ToggleFrame.NameText.TextBounds.X, 0, 20)

                                                local ToggleText = ToggleFrame.NameText

                                                function Toggle:Set(Value: boolean)
                                                    task.spawn(function()
                                                        PlayTween(ToggleFrame.ItemsHolder.ToggleBox.Circle, {0.1, Enum.EasingStyle.Quint}, {
                                                            Position = Value and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
                                                        })
                                                    end)
                                                    Toggle.Value = Value
                                                    ToggleConfig.Callback(Value)
                                                end

                                                local BindInput = false
                                                function Toggle:CreateBind(BindConfig: { Default: Enum }?)
                                                    BindConfig = BindConfig or {}
                                                    BindConfig.Default = BindConfig.Default or "None"
                                                    BindConfig.Hold = BindConfig.Hold or false

                                                    local MouseKeys = {
                                                        Enum.UserInputType.MouseButton1,
                                                        Enum.UserInputType.MouseButton2,
                                                        Enum.UserInputType.MouseButton3,
                                                        "MouseButton1", 
                                                        "MouseButton2",
                                                        "MouseButton3"
                                                    }; local function GetBind(Key)
                                                        if typeof(Key) == "string" then
                                                            if Key == "" or Key == "None" or Key == "nil" then return nil end
                                                            if table_find(MouseKeys, Key) then
                                                                return Enum.UserInputType[Key]
                                                            else
                                                                return Enum.KeyCode[Key]
                                                            end
                                                        end
                                                        return Key
                                                    end

                                                    local Bind = { 
                                                        Name = ToggleConfig.Name, 
                                                        Value = GetBind(BindConfig.Default) and GetBind(BindConfig.Default).Name or "",
                                                        Type = "Bind"
                                                    }

                                                    local IsBinding = false

                                                    local BindBoxFrame = CreateElement("RoundFrame", {
                                                        Name = "BindBoxFrame",
                                                        Size = UDim2.new(0, 40, 1, 0),
                                                        BackgroundTransparency = 0.9,
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        LayoutOrder = 99,
                                                        ZIndex = 101
                                                    }, {
                                                        CreateElement("TextButton", {
                                                            Name = "BindBox",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            Position = UDim2.new(0, 0, 0.5, 0),
                                                            AnchorPoint = Vector2.new(0, 0.5),
                                                            TextXAlignment = Enum.TextXAlignment.Center,
                                                            TextYAlignment = Enum.TextYAlignment.Center,
                                                            TextWrapped = false,
                                                            Text = "None",
                                                            TextSize = 14,
                                                            TextColor3 = Theme.LittleTextColor,
                                                            Font = Theme.LittleFont,
                                                            BackgroundTransparency = 1,
                                                            TextTransparency = Theme.LittleTextTransparency,
                                                            AutoButtonColor = false,
                                                            BorderSizePixel = 0,
                                                            ZIndex = 102
                                                        }, { CreateElement("Corner") })
                                                    })

                                                    local BindBox = BindBoxFrame.BindBox
                                                    AddConnection(BindBox:GetPropertyChangedSignal("Text"), function()
                                                        local TextBounds = BindBox.TextBounds
                                                        PlayTween(BindBoxFrame, 0.1, { 
                                                            Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                                            Position = UDim2.new(1, -TextBounds.X - 65, 0.5, 0)
                                                        })
                                                    end)

                                                    function Bind:Set(Key)
                                                        local BindValue = GetBind(Key)
                                                        if not BindValue or BindValue == Enum.KeyCode.None or BindValue == Enum.UserInputType.None then
                                                            Bind.Value = ""
                                                            BindBox.Text = "None"
                                                            return
                                                        end
                                                        Bind.Value = BindValue.Name
                                                        BindBox.Text = BindValue.Name
                                                    end

                                                    AddConnection(BindBox.MouseButton1Up, function()
                                                        BindInput = true
                                                        IsBinding = true
                                                        BindBox.Text = "Press any key"
                                                    end)

                                                    AddConnection(Serv.UserInputService.InputBegan, function(Input)
                                                        if Serv.UserInputService:GetFocusedTextBox() then return end
                                                        if IsBinding then
                                                            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
                                                                Bind:Set(Input.UserInputType ~= Enum.UserInputType.Keyboard and Input.UserInputType or Input.KeyCode)
                                                                IsBinding = false
                                                            end
                                                        else
                                                            if Input.KeyCode ~= Bind.Value and Input.UserInputType ~= Bind.Value then return end
                                                            Toggle.Value = not Toggle.Value
                                                            Toggle:Set(Toggle.Value)
                                                        end
                                                    end)

                                                    UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = BindBox
                                                    UI.Flags[BindConfig.Flag] = Bind
                                                    UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = BindBoxFrame

                                                    return Bind
                                                end

                                                local ColorpickerInput = false
                                                function Toggle:CreateColorpicker(ColorpickerConfig: { 
                                                    Default: Color3, DefaultTransparency: number, Callback: () -> (Color3, number)
                                                })  
                                                    ColorpickerConfig = ColorpickerConfig or {}
                                                    ColorpickerConfig.DefaultColor = ColorpickerConfig.DefaultColor or Color3.fromRGB(255, 255, 255)
                                                    ColorpickerConfig.DefaultTransparency = ColorpickerConfig.DefaultTransparency or 0.5
                                                    ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                                                
                                                    local Colorpicker = { 
                                                        Value = ColorpickerConfig.DefaultColor,
                                                        TransparencyValue = ColorpickerConfig.DefaultTransparency
                                                    }

                                                    local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.DefaultColor)
                                                    local TransparencyColor = ColorpickerConfig.DefaultTransparency

                                                    local ColorpickerBox = CreateElement("TextButton", {
                                                        Name = "ColorpickerCircle",
                                                        Size = UDim2.new(0, 20, 1, 0),
                                                        BackgroundColor3 = ColorpickerConfig.DefaultColor,
                                                        BackgroundTransparency = ColorpickerConfig.DefaultTransparency,
                                                        LayoutOrder = 75,
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0
                                                    }, { CreateElement("Corner") })

                                                    if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                        ItemHolderSettings = CreateElement("FakeFrame", {
                                                            Name = "SettingsHolder",
                                                            Size = UDim2.new(1, 0, 0, 0),
                                                            Position = UDim2.new(0, 0, 0, 30),
                                                            Parent = ToggleFrame
                                                        }, {
                                                            CreateElement("UIListLayout", {
                                                                SortOrder = Enum.SortOrder.LayoutOrder,
                                                                Padding = UDim.new(0, 5)
                                                            })
                                                        })

                                                        AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                            local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                            PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                            PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                        end)
                                                    end

                                                    local ItemHolder = CreateElement("RoundFrame", {
                                                        Name = "ColorpickerItemHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        BackgroundTransparency = 1,
                                                        Visible = false,
                                                        Active = true,
                                                        ClipsDescendants = true,
                                                        Parent = ItemHolderSettings
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "ColorSelect",
                                                            Size = UDim2.new(1, -100, 1, -40),
                                                            Position = UDim2.new(0, 20, 0, 20),
                                                            BackgroundTransparency = 0,
                                                            ImageTransparency = 0,
                                                            Image = "rbxassetid://4155801252"
                                                        }, {
                                                            CreateElement("Corner"),
                                                            CreateElement("ImageLabel", {
                                                                Name = "Select",
                                                                Size = UDim2.new(0, 18, 0, 18),
                                                                Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                                ScaleType = Enum.ScaleType.Fit,
                                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                                BackgroundTransparency = 1,
                                                                Image = "http://www.roblox.com/asset/?id=4805639000"
                                                            })
                                                        }),
                                                        CreateElement("Frame", {
                                                            Name = "HueSelect",
                                                            Size = UDim2.new(0, 20, 1, -40),
                                                            Position = UDim2.new(1, -70, 0, 20),
                                                            BackgroundTransparency = 0
                                                        }, {
                                                            CreateElement("Corner"),
                                                            CreateElement("ImageLabel", {
                                                                Name = "Select",
                                                                Size = UDim2.new(0, 18, 0, 18),
                                                                Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                                ScaleType = Enum.ScaleType.Fit,
                                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                                BackgroundTransparency = 1,
                                                                Image = "http://www.roblox.com/asset/?id=4805639000"
                                                            }),
                                                            CreateElement("UIGradient", {
                                                                Rotation = 270,
                                                                Color = ColorSequence.new{
                                                                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), 
                                                                    ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), 
                                                                    ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), 
                                                                    ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), 
                                                                    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), 
                                                                    ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), 
                                                                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
                                                                }
                                                            })
                                                        }),
                                                        CreateElement("ImageLabel", {
                                                            Name = "TransparencySelect",
                                                            Size = UDim2.new(0, 20, 1, -70),
                                                            Position = UDim2.new(1, -40, 0, 20),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = 0,
                                                            Image = "rbxassetid://139785960036434",
                                                            ScaleType = Enum.ScaleType.Tile,
                                                            TileSize = UDim2.new(0, 7, 0, 7)
                                                        }, {
                                                            CreateElement("Corner"),
                                                            CreateElement("ImageLabel", {
                                                                Name = "Select",
                                                                Size = UDim2.new(0, 18, 0, 18),
                                                                Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                                ScaleType = Enum.ScaleType.Fit,
                                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                                BackgroundTransparency = 1,
                                                                Image = "http://www.roblox.com/asset/?id=4805639000"
                                                            }),
                                                            CreateElement("UIGradient", {
                                                                Rotation = 270,
                                                                Color = ColorSequence.new{
                                                                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)), 
                                                                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(234, 255, 255)), 
                                                                }
                                                            })
                                                        }),
                                                        CreateElement("TextButton", {
                                                            Name = "ResetButtonFrame",
                                                            Size = UDim2.new(0, 20, 0, 20),
                                                            Position = UDim2.new(1, -40, 1, -40),
                                                            BackgroundTransparency = 0.9,
                                                            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                            Text = "",
                                                            AutoButtonColor = false,
                                                            BorderSizePixel = 0
                                                        }, {
                                                            CreateElement("ImageLabel", {
                                                                Name = "Image",
                                                                Size = UDim2.new(0, 20, 1, -0),
                                                                Position = UDim2.new(1, -20, 0, 0),
                                                                BackgroundTransparency = 1,
                                                                ImageTransparency = 0,
                                                                Image = "rbxassetid://10734933056"
                                                            })
                                                        })
                                                    })

                                                    local Opened, CanBeClosed = false, false

                                                    local Color, ColorSelection = ItemHolder.ColorSelect, ItemHolder.ColorSelect.Select
                                                    local Hue, HueSelection = ItemHolder.HueSelect, ItemHolder.HueSelect.Select
                                                    local Transparency, TransparencySelection = ItemHolder.TransparencySelect, ItemHolder.TransparencySelect.Select
                                                    local ResetButton = ItemHolder.ResetButtonFrame
                                                    local SizeXHolder = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X - 30

                                                    local function ToggleColorpicker(Open: boolean)
                                                        if not Open then
                                                            Opened = Open
                                                            PlayTween(ItemHolder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
                                                            task.wait(0.15)

                                                            ItemHolder.Visible = Open
                                                            CanBeClosed = false
                                                        else
                                                            Opened = Open
                                                            ItemHolder.Visible = Opened
                                                            PlayTween(ItemHolder, 0.2, { Size = UDim2.new(1, 0, 0, 200) })
                                                            task.wait(0.2)
                                                            CanBeClosed = true
                                                        end
                                                    end

                                                    local function UpdateColorPicker(NotCallbacking)
                                                        ColorH = ColorH >= 0 and ColorH or 0
                                                        ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                                                        ColorpickerBox.BackgroundTransparency = TransparencyColor
                                                        Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)

                                                        if NotCallbacking == nil or NotCallbacking == false then
                                                            ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3, ColorpickerBox.BackgroundTransparency)
                                                        else
                                                            Colorpicker.Value = ColorpickerBox.BackgroundColor3
                                                            Colorpicker.TransparencyValue = ColorpickerBox.BackgroundTransparency
                                                        end
                                                    end

                                                    function Colorpicker:Set(Value, Transp)
                                                        Colorpicker.Value = Value
                                                        Colorpicker.TransparencyValue = Transp
                                                        ColorpickerBox.BackgroundColor3 = Colorpicker.Value
                                                        ColorpickerBox.BackgroundTransparency = Colorpicker.TransparencyValue
                                                        
                                                        ColorpickerConfig.Callback(
                                                            Colorpicker.Value, 
                                                            Colorpicker.TransparencyValue
                                                        )
                                                    end

                                                    AddConnection(ResetButton.MouseButton1Up, function()
                                                        ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.DefaultColor)
                                                        TransparencyColor = ColorpickerConfig.DefaultTransparency

                                                        HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                                                        ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                                                        TransparencySelection.Position = UDim2.new(0.5, 0, 1 - TransparencyColor, 0)

                                                        UpdateColorPicker()
                                                    end)

                                                    AddConnection(ColorpickerBox.MouseButton1Up, function()
                                                        ColorpickerInput = true
                                                        Opened = not Opened
                                                        ToggleColorpicker(Opened)
                                                        task.delay(0.1, function() ColorpickerInput = false end)
                                                    end)

                                                    AddConnection(SectionsHolder.FakeDescendantClipperFrameRight:GetPropertyChangedSignal("AbsoluteSize"), function()
                                                        local SizeX = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X
                                                        SizeXHolder = SizeX
                                                        ItemHolder.Size = UDim2.new(0, SizeXHolder - 30, 0, 200)
                                                        ItemHolder.Position = UDim2.new(0, 0, 0, 30)
                                                    end)

                                                    local ColorInput = nil
                                                    AddConnection(Color.InputBegan, function(input)
                                                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                            if ColorInput then ColorInput:Disconnect() end
                                                            ColorInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                                CanBeClosed = false
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
                                                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                            if ColorInput then 
                                                                task.delay(0.1, function() CanBeClosed = true end)
                                                                ColorInput:Disconnect()
                                                                
                                                                local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                                                                local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
                                                                ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                                                                ColorS = ColorX
                                                                ColorV = 1 - ColorY
                                                                UpdateColorPicker()
                                                            end
                                                        end
                                                    end)

                                                    local HueInput = nil
                                                    AddConnection(Hue.InputBegan, function(input)
                                                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                            if HueInput then HueInput:Disconnect() end

                                                            HueInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                                CanBeClosed = false
                                                                local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                                                                HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                                                                ColorH = 1 - HueY

                                                                UpdateColorPicker()
                                                            end)
                                                        end
                                                    end)

                                                    AddConnection(Hue.InputEnded, function(input)
                                                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                            if HueInput then 
                                                                task.delay(0.1, function() CanBeClosed = true end)
                                                                HueInput:Disconnect()
                                                                
                                                                local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                                                                HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                                                                ColorH = 1 - HueY

                                                                UpdateColorPicker()
                                                            end
                                                        end
                                                    end)

                                                    local TransparencyInput = nil
                                                    AddConnection(Transparency.InputBegan, function(input)
                                                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                            if TransparencyInput then TransparencyInput:Disconnect() end

                                                            TransparencyInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                                CanBeClosed = false
                                                                local TransparencyY = (math.clamp(Mouse.Y - Transparency.AbsolutePosition.Y, 0, Transparency.AbsoluteSize.Y) / Transparency.AbsoluteSize.Y)

                                                                TransparencySelection.Position = UDim2.new(0.5, 0, TransparencyY, 0)
                                                                TransparencyColor = 1 - TransparencyY

                                                                UpdateColorPicker()
                                                            end)
                                                        end
                                                    end)

                                                    AddConnection(Transparency.InputEnded, function(input)
                                                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                            if TransparencyInput then 
                                                                task.delay(0.1, function() CanBeClosed = true end)
                                                                TransparencyInput:Disconnect()
                                                                
                                                                local TransparencyY = (math.clamp(Mouse.Y - Transparency.AbsolutePosition.Y, 0, Transparency.AbsoluteSize.Y) / Transparency.AbsoluteSize.Y)

                                                                TransparencySelection.Position = UDim2.new(0.5, 0, TransparencyY, 0)
                                                                TransparencyColor = 1 - TransparencyY

                                                                UpdateColorPicker()
                                                            end
                                                        end
                                                    end)

                                                    HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                                                    ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                                                    TransparencySelection.Position = UDim2.new(0.5, 0, 1 - TransparencyColor, 0)

                                                    Colorpicker:Set(ColorpickerConfig.DefaultColor, ColorpickerConfig.DefaultTransparency)

                                                    return Colorpicker
                                                end

                                                local OpenedToggle
                                                AddConnection(SettingsArrow.MouseButton1Up, function()
                                                    DropdownInput = true
                                                    OpenedToggle = not OpenedToggle

                                                    if OpenedToggle then
                                                        ToggleParentFrame.Visible = true
                                                    else
                                                        task.delay(0.1, function() ToggleParentFrame.Visible = false end)
                                                    end

                                                    PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, -20, 0, OpenedToggle and 30 or 0) })
                                                    PlayTween(ToggleParentFrame, 0.1, { Size = UDim2.new(1, 0, 0, OpenedToggle and 30 or 0) })
                                                end)

                                                AddConnection(ToggleFrame.Click.MouseButton1Up, function()
                                                    if ColorpickerInput then return end
                                                    if BindInput then BindInput = false; return end
                                                    if SliderInput then SliderInput = false; return end
                                                    if DropdownInput then DropdownInput = false; return end

                                                    Toggle.Value = not Toggle.Value
                                                    Toggle:Set(Toggle.Value)
                                                end)

                                                AddConnection(ToggleText:GetPropertyChangedSignal("TextBounds"), function()
                                                    ToggleText.Size = UDim2.new(0, ToggleText.TextBounds.X, 0, 20)
                                                end)

                                                AddConnection(ToggleFrame.MouseEnter, function() ToggleText.TextSize = 17 end)
                                                AddConnection(ToggleFrame.MouseLeave, function() ToggleText.TextSize = 16 end)

                                                Toggle:Set(ToggleConfig.Default)

                                                UI.Elements.Texts[#UI.Elements.Texts+1] = ToggleText
                                                UI.Elements.Elements[#UI.Elements.Elements+1] = ToggleFrame
                                                UI.Flags[ToggleConfig.Flag] = Toggle
                                                UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = ToggleFrame.ItemsHolder.ToggleBox.Circle
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = ToggleFrame.ItemsHolder.ToggleBox
                                                
                                                return Toggle
                                            end

                                            function Toggle:CreateLabel(LabelConfig: { Name: string }?)
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                LabelConfig = LabelConfig or {}
                                                LabelConfig.Name = LabelConfig.Name or "Label"

                                                local Label = {}

                                                if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                    ItemHolderSettings = CreateElement("FakeFrame", {
                                                        Name = "SettingsHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        Parent = ToggleFrame
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })

                                                    AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                        PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                        PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                    end)
                                                end

                                                if not ToggleFrame.ItemsHolder:FindFirstChild("SettingsArrow") then
                                                    local ArrowToggled = false
                                                    SettingsArrow = CreateElement("TextButton", {
                                                        Name = "SettingsArrow",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        ZIndex = 101
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = Theme.LittleTextTransparency,
                                                            Image = "rbxassetid://10709790948",
                                                            Rotation = 180,
                                                            LayoutOrder = -100
                                                        })
                                                    })
                                                    
                                                    AddConnection(SettingsArrow.MouseButton1Up, function()
                                                        ArrowToggled = not ArrowToggled
                                                        PlayTween(SettingsArrow.Image, 0.1, { Rotation = ArrowToggled and 0 or 180 })
                                                    end)
                                                end

                                                local LabelParentFrame = CreateElement("RoundFrame", {
                                                    Name = "LabelParentFrame",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    Parent = ItemHolderSettings,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    Visible = false
                                                })

                                                local LabelFrame = CreateElement("RoundFrame", {
                                                    Name = "LabelFrame",
                                                    Size = UDim2.new(1, -20, 0, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Parent = LabelParentFrame,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency
                                                }, {
                                                    CreateElement("TextLabel", {
                                                        Name = "NameText",
                                                        Size = UDim2.new(1, -20, 1, 0),
                                                        Position = UDim2.new(0, 10, 0, 0),
                                                        TextWrapped = true,
                                                        Text = LabelConfig.Name,
                                                        TextSize = 16,
                                                        TextColor3 = Theme.TextColor,
                                                        Font = Theme.Font,
                                                        TextTransparency = Theme.TextTransparency,
                                                        BorderSizePixel = 0,
                                                        TextXAlignment = Enum.TextXAlignment.Left,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        TextWrap = false
                                                    })
                                                })

                                                local LabelText = LabelFrame.NameText

                                                function Label:Set(Name: string)
                                                    LabelText.Text = Name
                                                    LabelConfig.Name = Name

                                                    local TextBounds = LabelText.TextBounds
                                                    PlayTween(LabelFrame, 0.1, { Size = UDim2.new(1, -20, 0, TextBounds.Y + 10) })
                                                    PlayTween(LabelParentFrame, 0.1, { Size = UDim2.new(1, 0, 0, TextBounds.Y + 10) })
                                                end

                                                local OpenedLabel
                                                AddConnection(SettingsArrow.MouseButton1Up, function()
                                                    OpenedLabel = not OpenedLabel

                                                    if OpenedLabel then
                                                        LabelParentFrame.Visible = true
                                                    else
                                                        task.delay(0.1, function() LabelParentFrame.Visible = false end)
                                                    end

                                                    local SizeY = LabelText.TextBounds.Y + 10
                                                    PlayTween(LabelFrame, 0.1, { Size = UDim2.new(1, -20, 0, OpenedLabel and SizeY or 0) })
                                                    PlayTween(LabelParentFrame, 0.1, { Size = UDim2.new(1, 0, 0, OpenedLabel and SizeY or 0) })
                                                end)

                                                Label:Set(LabelConfig.Name)

                                                UI.Elements.Texts[#UI.Elements.Texts+1] = LabelText
                                                UI.Elements.Elements[#UI.Elements.Elements+1] = LabelFrame

                                                return Label
                                            end

                                            function Toggle:CreateTextbox(TextboxConfig: {
                                                Name: string, Default: string,
                                                PlaceholderText: string, TextDisappear: boolean,
                                                Flag: string, Callback: () -> text
                                            })
                                                UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                                TextboxConfig = TextboxConfig or {}
                                                TextboxConfig.Name = TextboxConfig.Namew or "Textbox"
                                                TextboxConfig.Default = TextboxConfig.Deafult or ""
                                                TextboxConfig.PlaceholderText = TextboxConfig.PlaceholderText or "Input"
                                                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                                                TextboxConfig.Flag = TextboxConfig.Flag or string_format("Slider%s", UI.ElementCounter)
                                                TextboxConfig.Callback = TextboxConfig.Callback or function() end

                                                local Textbox = { 
                                                    Name = TextboxConfig.Name,
                                                    Value = TextboxConfig.Default,
                                                    Type = "Textbox"
                                                }

                                                if not ToggleFrame:FindFirstChild("SettingsHolder") then
                                                    ItemHolderSettings = CreateElement("FakeFrame", {
                                                        Name = "SettingsHolder",
                                                        Size = UDim2.new(1, 0, 0, 0),
                                                        Position = UDim2.new(0, 0, 0, 30),
                                                        Parent = ToggleFrame
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        })
                                                    })

                                                    AddConnection(ItemHolderSettings.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                        local AbsoluteContentSize = ItemHolderSettings.UIListLayout.AbsoluteContentSize
                                                        PlayTween(ItemHolderSettings, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y) })
                                                        PlayTween(ToggleFrame, 0.1, { Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 30) })
                                                    end)
                                                end

                                                if not ToggleFrame.ItemsHolder:FindFirstChild("SettingsArrow") then
                                                    local ArrowToggled = false
                                                    SettingsArrow = CreateElement("TextButton", {
                                                        Name = "SettingsArrow",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0,
                                                        Parent = ToggleFrame.ItemsHolder,
                                                        ZIndex = 101
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(1, 0, 1, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = Theme.LittleTextTransparency,
                                                            Image = "rbxassetid://10709790948",
                                                            Rotation = 180,
                                                            LayoutOrder = -100
                                                        })
                                                    })
                                                    
                                                    AddConnection(SettingsArrow.MouseButton1Up, function()
                                                        ArrowToggled = not ArrowToggled
                                                        PlayTween(SettingsArrow.Image, 0.1, { Rotation = ArrowToggled and 0 or 180 })
                                                    end)
                                                end

                                                local TextboxParentFrame = CreateElement("RoundFrame", {
                                                    Name = "TextboxParentFrame",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    Parent = ItemHolderSettings,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency,
                                                    Visible = false
                                                })

                                                local TextboxFrame = CreateElement("RoundFrame", {
                                                    Name = "TextboxFrame",
                                                    Size = UDim2.new(1, -20, 0, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    Parent = TextboxParentFrame,
                                                    BackgroundColor3 = Theme.ElementsColor,
                                                    BackgroundTransparency = Theme.ElementsTransparency
                                                }, {
                                                    CreateElement("TextLabel", {
                                                        Name = "NameText",
                                                        Size = UDim2.new(1, -30, 1, 0),
                                                        Position = UDim2.new(0, 10, 0, 0),
                                                        TextWrapped = true,
                                                        Text = TextboxConfig.Name,
                                                        TextSize = 16,
                                                        TextColor3 = Theme.TextColor,
                                                        Font = Theme.Font,
                                                        TextTransparency = Theme.TextTransparency,
                                                        BorderSizePixel = 0,
                                                        TextXAlignment = Enum.TextXAlignment.Left,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        TextWrap = false
                                                    }),
                                                    CreateElement("TextBox", {
                                                        Name = "Value",
                                                        Size = UDim2.new(0, 55, 0, 20),
                                                        Position = UDim2.new(1, -10, 0, 5),
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        TextWrapped = false,
                                                        Text = "Textbox",
                                                        TextSize = 14,
                                                        TextColor3 = Theme.LittleTextColor,
                                                        Font = Theme.LittleFont,
                                                        TextTransparency = Theme.LittleTextTransparency,
                                                        BackgroundTransparency = 0.9,
                                                        PlaceholderText = TextboxConfig.PlaceholderText,
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        ClipsDescendants = true,
                                                        ClearTextOnFocus = TextboxConfig.TextDisappear,
                                                        AnchorPoint = Vector2.new(1, 0)
                                                    }, { CreateElement("Corner") }),
                                                }); TextboxFrame.NameText.Size = UDim2.new(0, TextboxFrame.NameText.TextBounds.X, 1, 0)

                                                local TextboxText = TextboxFrame.NameText
                                                local Value = TextboxFrame.Value

                                                function Textbox:Set(Text)
                                                    Value.Text = Text
                                                    Textbox.Value = Text
                                                    TextboxConfig.Callback(Value.Text)
                                                end

                                                local function UpdateSize()
                                                    PlayTween(Value, 0.1, { 
                                                        Size = UDim2.new(
                                                            0, math.clamp(
                                                                Value.TextBounds.X + 10, 0,
                                                                math.max(
                                                                    TextboxText.TextBounds.X, 
                                                                    TextboxFrame.AbsoluteSize.X - TextboxText.TextBounds.X - 30
                                                                )
                                                            ),
                                                            0, 20
                                                        ) 
                                                    })
                                                end

                                                local OpenedTextbox
                                                AddConnection(SettingsArrow.MouseButton1Up, function()
                                                    DropdownInput = true
                                                    OpenedTextbox = not OpenedTextbox

                                                    if OpenedTextbox then
                                                        TextboxParentFrame.Visible = true
                                                    else
                                                        task.delay(0.1, function() TextboxParentFrame.Visible = false end)
                                                    end

                                                    PlayTween(TextboxFrame, 0.1, { Size = UDim2.new(1, -20, 0, OpenedTextbox and 30 or 0) })
                                                    PlayTween(TextboxParentFrame, 0.1, { Size = UDim2.new(1, 0, 0, OpenedTextbox and 30 or 0) })
                                                end)

                                                AddConnection(Value:GetPropertyChangedSignal("Text"), UpdateSize)

                                                AddConnection(Value.FocusLost, function()
                                                    Textbox:Set(Value.Text)
                                                    if TextboxConfig.TextDisappear then Value.Text = "" end
                                                end)

                                                AddConnection(TextboxFrame.MouseEnter, function() TextboxText.TextSize = 17 end)
                                                AddConnection(TextboxFrame.MouseLeave, function() TextboxText.TextSize = 16 end)

                                                Textbox:Set(TextboxConfig.Default)
                                                UpdateSize()

                                                UI.Elements.Texts[#UI.Elements.Texts+1] = TextboxText
                                                UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = Value
                                                UI.Elements.Elements[#UI.Elements.Elements+1] = TextboxFrame
                                                UI.Flags[TextboxConfig.Flag] = Textbox
                                                UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = Value

                                                return Textbox
                                            end

                                            AddConnection(ToggleFrame.Click.MouseButton1Up, function()
                                                if ColorpickerInput then return end
                                                if BindInput then BindInput = false; return end
                                                if SliderInput then SliderInput = false; return end
                                                if DropdownInput then DropdownInput = false; return end

                                                Toggle.Value = not Toggle.Value
                                                Toggle:Set(Toggle.Value)
                                            end)

                                            AddConnection(ToggleText:GetPropertyChangedSignal("TextBounds"), function()
                                                ToggleText.Size = UDim2.new(0, ToggleText.TextBounds.X, 0, 20)
                                            end)

                                            AddConnection(ToggleFrame.MouseEnter, function() ToggleText.TextSize = 17 end)
                                            AddConnection(ToggleFrame.MouseLeave, function() ToggleText.TextSize = 16 end)

                                            Toggle:Set(ToggleConfig.Default)

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = ToggleText
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = ToggleFrame
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Toggle", 
                                                Name = ToggleConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = ToggleFrame,
                                                Side = SectionConfig.Side
                                            }
                                            UI.Flags[ToggleConfig.Flag] = Toggle
                                            UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = ToggleFrame.ItemsHolder.ToggleBox.Circle
                                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = ToggleFrame.ItemsHolder.ToggleBox
                                            if SettingsArrow then UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = SettingsArrow end

                                            return Toggle
                                        end

                                        function Section:CreateBind(BindConfig: {
                                            Name: string, Default: Enum, 
                                            Flag: string, Hold: boolean, Callback: () -> boolean?
                                        }?)
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                            BindConfig = BindConfig or {}
                                            BindConfig.Name = BindConfig.Name or "Bind"
                                            BindConfig.Default = BindConfig.Default or "None"
                                            BindConfig.Flag = BindConfig.Flag or string_format("Bind%s", UI.ElementCounter)
                                            BindConfig.Hold = BindConfig.Hold or false
                                            BindConfig.Callback = BindConfig.Callback or function() end

                                            local MouseKeys = {
                                                Enum.UserInputType.MouseButton1,
                                                Enum.UserInputType.MouseButton2,
                                                Enum.UserInputType.MouseButton3,
                                                "MouseButton1", 
                                                "MouseButton2",
                                                "MouseButton3"
                                            }; local function GetBind(Key)
                                                if typeof(Key) == "string" then
                                                    if Key == "" or Key == "None" or Key == "nil" then return nil end
                                                    if table_find(MouseKeys, Key) then
                                                        return Enum.UserInputType[Key]
                                                    else
                                                        return Enum.KeyCode[Key]
                                                    end
                                                end
                                                return Key
                                            end
                                            
                                            local Bind = {
                                                Value = GetBind(BindConfig.Default) and GetBind(BindConfig.Default).Name or "",
                                                Type = "Bind"
                                            }

                                            local Holding = false
                                            local IsBinding = false

                                            local BindFrame = CreateElement("TextButton", {
                                                Name = "BindFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent(),
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency,
                                                Text = "",
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 1, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextWrapped = true,
                                                    Text = BindConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("RoundFrame", {
                                                    Name = "BindBoxFrame",
                                                    Size = UDim2.new(0, 40, 0, 20),
                                                    Position = UDim2.new(1, -50, 0.5, 0),
                                                    AnchorPoint = Vector2.new(0, 0.5),
                                                    BackgroundTransparency = 0.9,
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                                }, {
                                                    CreateElement("TextButton", {
                                                        Name = "BindBox",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        Position = UDim2.new(0, 0, 0.5, 0),
                                                        AnchorPoint = Vector2.new(0, 0.5),
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        TextWrapped = false,
                                                        Text = "None",
                                                        TextSize = 14,
                                                        TextColor3 = Theme.LittleTextColor,
                                                        Font = Theme.LittleFont,
                                                        BackgroundTransparency = 1,
                                                        TextTransparency = Theme.LittleTextTransparency,
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0
                                                    }, { CreateElement("Corner") })
                                                }),
                                                CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                            }); BindFrame.NameText.Size = UDim2.new(0, BindFrame.NameText.TextBounds.X, 1, 0)

                                            local BindText = BindFrame.NameText
                                            local BindBox = BindFrame.BindBoxFrame.BindBox

                                            AddConnection(BindBox:GetPropertyChangedSignal("Text"), function()
                                                local TextBounds = BindBox.TextBounds
                                                PlayTween(BindFrame.BindBoxFrame, 0.1, { 
                                                    Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                                    Position = UDim2.new(1, -TextBounds.X - 20, 0.5, 0)
                                                })
                                            end)

                                            function Bind:Set(Key)
                                                local BindValue = GetBind(Key)
                                                if not BindValue or BindValue == Enum.KeyCode.None or BindValue == Enum.UserInputType.None then
                                                    Bind.Value = ""
                                                    BindBox.Text = "None"
                                                    return
                                                end
                                                Bind.Value = BindValue.Name
                                                BindBox.Text = BindValue.Name
                                            end

                                            AddConnection(BindFrame.MouseButton1Up, function()
                                                IsBinding = true
                                                BindBox.Text = "Press any key"
                                            end)

                                            AddConnection(Serv.UserInputService.InputBegan, function(Input)
                                                if Serv.UserInputService:GetFocusedTextBox() then return end
                                                if IsBinding then
                                                    if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
                                                        Bind:Set(Input.UserInputType ~= Enum.UserInputType.Keyboard and Input.UserInputType or Input.KeyCode)
                                                        IsBinding = false
                                                    end
                                                else
                                                    if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
                                                    if BindConfig.Hold then
                                                        Holding = true
                                                        BindConfig.Callback(Holding)
                                                    else
                                                        BindConfig.Callback()
                                                    end
                                                end
                                            end)

                                            AddConnection(Serv.UserInputService.InputEnded, function(Input)
                                                if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
                                                if BindConfig.Hold and Holding then
                                                    Holding = false
                                                    BindConfig.Callback(Holding)
                                                end
                                            end)

                                            AddConnection(BindFrame.MouseEnter, function() BindText.TextSize = 17 end)
                                            AddConnection(BindFrame.MouseLeave, function() BindText.TextSize = 16 end)

                                            Bind:Set(BindConfig.Default)

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = BindText
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = BindFrame
                                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = BindBox
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Bind", 
                                                Name = BindConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = BindFrame,
                                                Side = SectionConfig.Side
                                            }
                                            UI.Flags[BindConfig.Flag] = Bind
                                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = BindFrame.BindBoxFrame

                                            return Bind
                                        end

                                        function Section:CreateSlider(SliderConfig: {
                                            Name: string, Default: number,
                                            Min: number, Max: number, Increment: number,
                                            ValueName: string, Flag: string,
                                            Callback: () -> number, InputEndedCallback: () -> number
                                        }?)
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end
                                            
                                            SliderConfig = SliderConfig or {}
                                            SliderConfig.Name = SliderConfig.Name or "Slider"
                                            SliderConfig.Default = SliderConfig.Default or 50
                                            SliderConfig.Min = SliderConfig.Min or 0
                                            SliderConfig.Max = SliderConfig.Max or 100
                                            SliderConfig.Increment = SliderConfig.Increment or 1
                                            SliderConfig.ValueName = SliderConfig.ValueName or ""
                                            SliderConfig.Flag = SliderConfig.Flag or string_format("Slider%s", UI.ElementCounter)
                                            SliderConfig.Callback = SliderConfig.Callback or function() end
                                            SliderConfig.InputEndedCallback = SliderConfig.InputEndedCallback or function() end

                                            local Slider = {
                                                Name = SliderConfig.Name,
                                                Value = SliderConfig.Default,
                                                Type = "Slider"
                                            }

                                            local SliderFrame = CreateElement("RoundFrame", {
                                                Name = "SliderFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent(),
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency,
                                                ClipsDescendants = true
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 0, 30),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextWrapped = true,
                                                    Text = SliderConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("TextBox", {
                                                    Name = "Value",
                                                    Size = UDim2.new(0, 50, 0, 20),
                                                    Position = UDim2.new(1, -60, 0, 5),
                                                    TextXAlignment = Enum.TextXAlignment.Center,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    TextWrapped = false,
                                                    Text = string_format("%s%s", Slider.Value, SliderConfig.ValueName),
                                                    TextSize = 14,
                                                    TextColor3 = Theme.LittleTextColor,
                                                    Font = Theme.LittleFont,
                                                    TextTransparency = Theme.LittleTextTransparency,
                                                    BackgroundTransparency = 0.9,
                                                    PlaceholderText = "Enter value",
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                }, { CreateElement("Corner") }),
                                                CreateElement("RoundFrame", {
                                                    Name = "SliderBar",
                                                    Size = UDim2.new(1, -20, 0, 10),
                                                    Position = UDim2.new(0, 10, 0, 40),
                                                    AnchorPoint = Vector2.new(0, 0.5),
                                                    BackgroundTransparency = 0.9,
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                                }, {
                                                    CreateElement("RoundFrame", {
                                                        Name = "Bar",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        BackgroundTransparency = Theme.LittleTextTransparency,
                                                        BackgroundColor3 = Theme.LittleTextColor,
                                                    })
                                                }),
                                                CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                            }); SliderFrame.NameText.Size = UDim2.new(0, SliderFrame.NameText.TextBounds.X, 0, 30)

                                            local SliderText = SliderFrame.NameText
                                            local SliderValue = SliderFrame.Value
                                            local SliderBar = SliderFrame.SliderBar
                                            local Bar = SliderBar.Bar
                                            local Dragging = false
                                            local Focused = false

                                            function Slider:Set(Value)
                                                Slider.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                                                
                                                PlayTween(Bar, {0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {
                                                    Size = UDim2.fromScale((Slider.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)
                                                }):Play()

                                                SliderValue.Text = string_format("%s%s", tostring(Slider.Value), SliderConfig.ValueName)
                                                SliderConfig.Callback(Slider.Value)
                                            end

                                            function Slider:SetMax(Value)
                                                SliderConfig.Max = Value
                                                Slider:Set(Slider.Value)
                                            end

                                            function Slider:SetMin(Value)
                                                SliderConfig.Min = Value
                                                Slider:Set(Slider.Value)
                                            end

                                            function Slider:Get()
                                                return Slider.Value
                                            end

                                            AddConnection(SliderBar.InputBegan, function(Input)
                                                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                                                Dragging = true
                                            end)

                                            AddConnection(SliderBar.InputEnded, function(Input)
                                                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                                                Dragging = false

                                                local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                                                SliderConfig.InputEndedCallback(Round(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale), SliderConfig.Increment))
                                            end)

                                            AddConnection(Serv.UserInputService.InputChanged, function(Input)
                                                if not Dragging then return end
                                                if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end

                                                local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                                                Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale)) 
                                            end)

                                            local function UpdateSize()
                                                SliderValue.Text = SliderValue.Text:gsub("[^%d%.%-]", "")
                                                local TextBounds = SliderValue.TextBounds
                                                PlayTween(SliderValue, 0.1, {
                                                    Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                                    Position = UDim2.new(1, -TextBounds.X - 20, 0, 5)
                                                })
                                            end

                                            AddConnection(SliderValue:GetPropertyChangedSignal("Text"), UpdateSize)

                                            AddConnection(SliderValue.Focused, function() Focused = true end)
                                            AddConnection(SliderValue.FocusLost, function()
                                                Focused = false
                                                if SliderValue.Text == "" then Slider:Set(Slider.Value); return end

                                                Slider.Value = SliderValue.Text
                                                Slider:Set(Slider.Value)
                                            end)

                                            AddConnection(SliderFrame.MouseEnter, function()
                                                SliderText.TextSize = 17 
                                                PlayTween(SliderFrame, 0.1, { Size = UDim2.new(1, 0, 0, 50) })
                                            end)

                                            AddConnection(SliderFrame.MouseLeave, function() 
                                                if Dragging or Focused then
                                                    while Dragging or Focused do task.wait() end
                                                    task.wait(0.2)
                                                end

                                                SliderText.TextSize = 16 
                                                PlayTween(SliderFrame, 0.1, { Size = UDim2.new(1, 0, 0, 30) })
                                            end)
                                            
                                            Slider:Set(SliderConfig.Default)
                                            UpdateSize()

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = SliderText
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = SliderFrame
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Slider", 
                                                Name = SliderConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = SliderFrame,
                                                Side = SectionConfig.Side
                                            }
                                            UI.Flags[SliderConfig.Flag] = Slider
                                            UI.Elements.SecondElements[#UI.Elements.SecondElements+1] = Bar
                                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = SliderValue
                                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = SliderBar
                                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = SliderValue

                                            return Slider
                                        end

                                        function Section:CreateTextbox(TextboxConfig: {
                                            Name: string, Default: string,
                                            PlaceholderText: string, TextDisappear: boolean,
                                            Flag: string, Callback: () -> text
                                        })
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                            TextboxConfig = TextboxConfig or {}
                                            TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                                            TextboxConfig.Default = TextboxConfig.Deafult or ""
                                            TextboxConfig.PlaceholderText = TextboxConfig.PlaceholderText or "Input"
                                            TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                                            TextboxConfig.Flag = TextboxConfig.Flag or string_format("Slider%s", UI.ElementCounter)
                                            TextboxConfig.Callback = TextboxConfig.Callback or function() end

                                            local Textbox = { 
                                                Name = TextboxConfig.Name,
                                                Value = TextboxConfig.Default,
                                                Type = "Textbox"
                                            }

                                            local TextboxFrame = CreateElement("RoundFrame", {
                                                Name = "TextboxFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent() ,
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 1, 0),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextWrapped = true,
                                                    Text = TextboxConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("TextBox", {
                                                    Name = "Value",
                                                    Size = UDim2.new(0, 55, 0, 20),
                                                    Position = UDim2.new(1, -10, 0, 5),
                                                    TextXAlignment = Enum.TextXAlignment.Center,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    TextWrapped = false,
                                                    Text = "Textbox",
                                                    TextSize = 14,
                                                    TextColor3 = Theme.LittleTextColor,
                                                    Font = Theme.LittleFont,
                                                    TextTransparency = Theme.LittleTextTransparency,
                                                    BackgroundTransparency = 0.9,
                                                    PlaceholderText = TextboxConfig.PlaceholderText,
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    ClipsDescendants = true,
                                                    ClearTextOnFocus = TextboxConfig.TextDisappear,
                                                    AnchorPoint = Vector2.new(1, 0)
                                                }, { CreateElement("Corner") }),
                                            }); TextboxFrame.NameText.Size = UDim2.new(0, TextboxFrame.NameText.TextBounds.X, 1, 0)

                                            local TextboxText = TextboxFrame.NameText
                                            local Value = TextboxFrame.Value

                                            function Textbox:Set(Text)
                                                Value.Text = Text
                                                Textbox.Value = Text
                                                TextboxConfig.Callback(Text)
                                            end

                                            local function UpdateSize()
                                                PlayTween(Value, 0.1, { 
                                                    Size = UDim2.new(
                                                        0, math.clamp(
                                                            Value.TextBounds.X + 10, 0,
                                                            math.max(
                                                                TextboxText.TextBounds.X, 
                                                                TextboxFrame.AbsoluteSize.X - TextboxText.TextBounds.X - 30
                                                            )
                                                        ),
                                                        0, 20
                                                    ) 
                                                })
                                            end

                                            AddConnection(Value:GetPropertyChangedSignal("Text"), UpdateSize)

                                            AddConnection(Value.FocusLost, function()
                                                Textbox:Set(Value.Text)
                                                if TextboxConfig.TextDisappear then Value.Text = "" end
                                            end)

                                            AddConnection(TextboxFrame.MouseEnter, function() TextboxText.TextSize = 17 end)
                                            AddConnection(TextboxFrame.MouseLeave, function() TextboxText.TextSize = 16 end)

                                            Textbox:Set(TextboxConfig.Default)
                                            UpdateSize()

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = TextboxText
                                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = Value
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = TextboxFrame
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Textbox", 
                                                Name = TextboxConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = TextboxFrame,
                                                Side = SectionConfig.Side
                                            }
                                            UI.Flags[TextboxConfig.Flag] = Textbox
                                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = Value

                                            return Textbox
                                        end

                                        function Section:CreateDropdown(DropdownConfig: {
                                            Name: string, Default: any,
                                            Options: table, Multi: boolean,
                                            Flag: string, Callback: () -> any,
                                        })
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                            DropdownConfig = DropdownConfig or {}
                                            DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                                            DropdownConfig.Default = DropdownConfig.Default or "None"
                                            DropdownConfig.Options = DropdownConfig.Options or {}
                                            DropdownConfig.Multi = DropdownConfig.Multi or false
                                            DropdownConfig.Flag = DropdownConfig.Flag or string_format("Dropdown%s", UI.ElementCounter)
                                            DropdownConfig.Callback = DropdownConfig.Callback or function() end

                                            local Dropdown = {
                                                Name = DropdownConfig.Name,
                                                Value = DropdownConfig.Default,
                                                Type = "Dropdown"
                                            }
                                            local SelectedOptions = {}

                                            local DropdownFrame = CreateElement("TextButton", {
                                                Name = "DropdownFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent(),
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency,
                                                ClipsDescendants = true,
                                                Text = "",
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 0, 30),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextWrapped = true,
                                                    Text = DropdownConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("RoundFrame", {
                                                    Name = "SelectedItemBox",
                                                    Size = UDim2.new(0, 40, 0, 20),
                                                    Position = UDim2.new(1, -50, 0, 5),
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    BackgroundTransparency = 0.9,
                                                }, {
                                                    CreateElement("TextLabel", {
                                                        Name = "NameText",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        Position = UDim2.new(0, 0, 0, 0),
                                                        TextWrapped = true,
                                                        Text = "None",
                                                        TextSize = 14,
                                                        TextColor3 = Theme.LittleTextColor,
                                                        Font = Theme.LittleFont,
                                                        TextTransparency = Theme.LittleTextTransparency,
                                                        BorderSizePixel = 0,
                                                        TextXAlignment = Enum.TextXAlignment.Center,
                                                        TextYAlignment = Enum.TextYAlignment.Center,
                                                        BackgroundTransparency = 1,
                                                        TextWrap = false
                                                    }),
                                                }),
                                                CreateElement("RoundFrame", {
                                                    Name = "ItemHolder",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    Position = UDim2.new(0, 0, 0, 30),
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    BackgroundTransparency = 1,
                                                    Visible = false,
                                                    Active = true,
                                                    ZIndex = 10,
                                                }, {
                                                    CreateElement("ScrollingFrame", {
                                                        Name = "Holder",
                                                        Size = UDim2.new(1, 0, 1, 0),
                                                        Position = UDim2.new(0, 0, 0, 0),
                                                        BackgroundTransparency = 1,
                                                        ScrollBarThickness = 0,
                                                        Active = true
                                                    }, {
                                                        CreateElement("UIListLayout", {
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            Padding = UDim.new(0, 5)
                                                        }),
                                                    })
                                                }),
                                                CreateElement("TextButton", {
                                                    Name = "Click",
                                                    Size = UDim2.new(1, 0, 0, 30),
                                                    BackgroundTransparency = 1,
                                                    Text = "",
                                                    AutoButtonColor = false,
                                                    BorderSizePixel = 0
                                                }),
                                                CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                            }); DropdownFrame.NameText.Size = UDim2.new(0, DropdownFrame.NameText.TextBounds.X, 0, 30)

                                            local DropdownText = DropdownFrame.NameText
                                            local SelectedItemBox = DropdownFrame.SelectedItemBox
                                            local ItemHolder = DropdownFrame.ItemHolder
                                            local Opened, CanBeClosed = false, false

                                            local function DropdownSet(Option: string, FromClick: boolean)
                                                local OptionButton = ItemHolder.Holder:FindFirstChild(string_format("ButtonFrame_%s", tostring(Option)))
                                                if not OptionButton then return end

                                                local DeSelected = false

                                                -- De Select
                                                    if FromClick and OptionButton.FakeTextName.BackgroundTransparency ~= 1 then
                                                        DeSelected = true

                                                        PlayTween(OptionButton.FakeTextName, 0.2, { 
                                                            BackgroundTransparency = 1
                                                        }); OptionButton.FakeTextName.TextName.TextSize = 16

                                                        if DropdownConfig.Multi then
                                                            for i, OptionSelect in SelectedOptions do
                                                                if Option ~= OptionSelect then continue end
                                                                table.remove(SelectedOptions, i)
                                                                DropdownConfig.Callback(SelectedOptions)
                                                            end
                                                        else
                                                            Option = ""
                                                        end
                                                    end

                                                -- Select
                                                    if not DropdownConfig.Multi then
                                                        for _, Button in ItemHolder.Holder:GetChildren() do
                                                            if Button.Name == "UIListLayout" then continue end
                                                            local ButtonText = Button.FakeTextName
                                                            PlayTween(ButtonText, 0.2, { BackgroundTransparency = 1 })
                                                            ButtonText.TextName.TextSize = 16
                                                        end

                                                        DropdownConfig.Callback(Option)
                                                        SelectedItemBox.NameText.Text = Option
                                                        Dropdown.Value = Option
                                                    else
                                                        if not DeSelected then
                                                            local AlreadySelected = false
                                                            for _, OptionSelect in SelectedOptions do
                                                                if Option == OptionSelect then
                                                                    AlreadySelected = true
                                                                    break
                                                                end
                                                            end
                                                            
                                                            if not AlreadySelected then
                                                                table.insert(SelectedOptions, Option)
                                                                DropdownConfig.Callback(SelectedOptions)
                                                            end
                                                        end
                                                        Dropdown.Value = SelectedOptions

                                                        local SelectedString = ""
                                                        for i, OptionSelect in SelectedOptions do
                                                            local FormOption = #OptionSelect > 5 and string_format("%s.", OptionSelect:sub(1, 5)) or OptionSelect
                                                            SelectedString = i == 1 and FormOption or string.format("%s, %s", SelectedString, FormOption)
                                                        end

                                                        SelectedItemBox.NameText.Text = string.len(SelectedString) > 25 and string_format("%s, ...", SelectedString:sub(0, 25)) or SelectedString
                                                    end

                                                -- Init Text
                                                    SelectedItemBox.NameText.Text = SelectedItemBox.NameText.Text:gsub("%(%(", ""):gsub("%)%)", "")
                                                    if SelectedItemBox.NameText.Text == "" then
                                                        SelectedItemBox.NameText.Text = "None"
                                                    end

                                                    if not DeSelected then 
                                                        PlayTween(OptionButton.FakeTextName, 0.2, { 
                                                            BackgroundTransparency = 0.8
                                                        }); OptionButton.FakeTextName.TextName.TextSize = 17
                                                    end

                                                    SelectedItemBox.Size = UDim2.new(0, SelectedItemBox.NameText.TextBounds.X + 10, 0, 20)
                                                    SelectedItemBox.Position = UDim2.new(1, -(SelectedItemBox.NameText.TextBounds.X + 20), 0, 5)
                                            end

                                            function Dropdown:Set(Options: string | table)
                                                SelectedOptions = {}

                                                for _, Button in ItemHolder.Holder:GetChildren() do
                                                    if Button.Name == "UIListLayout" then continue end
                                                    local ButtonText = Button.FakeTextName
                                                    PlayTween(ButtonText, 0.2, { BackgroundTransparency = 1 })
                                                    ButtonText.TextName.TextSize = 16
                                                end

                                                SelectedItemBox.NameText.Text = "None"
                                                SelectedItemBox.Size = UDim2.new(0, SelectedItemBox.NameText.TextBounds.X + 10, 0, 20)
                                                SelectedItemBox.Position = UDim2.new(1, -(SelectedItemBox.NameText.TextBounds.X + 20), 0, 5)

                                                if typeof(Options) == "string" then
                                                    DropdownSet(Options, false)
                                                    Dropdown.Value = Options
                                                else
                                                    for _, Option in Options do DropdownSet(Option, false) end
                                                    Dropdown.Value = SelectedOptions
                                                end
                                            end

                                            local AbsoluteContentSize = ItemHolder.Holder.UIListLayout.AbsoluteContentSize
                                            local SizeY = math.clamp(AbsoluteContentSize.Y, 1, 200)

                                            local function ToggleDropdown(Open: boolean)
                                                if not ItemHolder:FindFirstChild("Holder") then return end

                                                AbsoluteContentSize = ItemHolder.Holder.UIListLayout.AbsoluteContentSize
                                                SizeY = math.clamp(AbsoluteContentSize.Y, 1, 200)

                                                if not Open then
                                                    Opened = Open
                                                    PlayTween(ItemHolder, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
                                                    PlayTween(DropdownFrame, 0.2, { Size = UDim2.new(1, 0, 0, 30) })
                                                    task.wait(0.2)

                                                    ItemHolder.Visible = Open
                                                    CanBeClosed = false
                                                else
                                                    Opened = Open
                                                    ItemHolder.Visible = Opened
                                                    PlayTween(ItemHolder, 0.2, { Size = UDim2.new(1, 0, 0, SizeY) })
                                                    PlayTween(DropdownFrame, 0.2, { Size = UDim2.new(1, 0, 0, SizeY + 30) })
                                                    task.wait(0.2)
                                                    CanBeClosed = true
                                                end
                                            end
                                            
                                            local function AddOptions(OptionsAdd, NeedSet, ToSelect)
                                                AddConnection(ItemHolder.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                                                    local AbsoluteContentSize = ItemHolder.Holder.UIListLayout.AbsoluteContentSize
                                                    ItemHolder.Holder.CanvasSize = UDim2.new(0, 0, 0, AbsoluteContentSize.Y)
                                                    ItemHolder.Size = UDim2.new(1, 0, 0, math.clamp(AbsoluteContentSize.Y, 1, 250)) 
                                                end)

                                                for i, Option in OptionsAdd do
                                                    local Split = string_match(Option, "[((]") and Option:split("((")
                                                    local ToGsub = Split and Split[2] or nil
                                                    local Desctiption = ToGsub and ToGsub:gsub("[))]", "") or ""

                                                    local ButtonFrame = CreateElement("TextButton", {
                                                        Name = string_format("ButtonFrame_%s", Option),
                                                        Size = UDim2.new(1, 0, 0, 30),
                                                        Parent = ItemHolder.Holder,
                                                        Active = true,
                                                        ZIndex = 11,
                                                        BackgroundTransparency = 1,
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0
                                                    }, {
                                                        CreateElement("RoundFrame", {
                                                            Name = "FakeTextName",
                                                            Size = UDim2.new(1, -20, 1, -10),
                                                            Position = UDim2.new(0, 10, 0, 5),
                                                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                            BackgroundTransparency = 1
                                                        }, {
                                                            CreateElement("TextLabel", {
                                                                Name = "TextName",
                                                                Size = UDim2.new(1, -20, 1, 0),
                                                                Position = UDim2.new(0, 10, 0, 0),
                                                                TextWrapped = true,
                                                                Text = Split and Split[1] or Option,
                                                                TextSize = 16,
                                                                TextColor3 = Theme.TextColor,
                                                                Font = Theme.Font,
                                                                TextTransparency = Theme.TextTransparency,
                                                                BorderSizePixel = 0,
                                                                TextXAlignment = Enum.TextXAlignment.Left,
                                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                                BackgroundTransparency = 1,
                                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                                TextWrap = true,
                                                                ZIndex = 12
                                                            }),
                                                            CreateElement("TextLabel", {
                                                                Name = "TextDescription",
                                                                Size = UDim2.new(1, -10, 1, 0),
                                                                Position = UDim2.new(0, 0, 0, 0),
                                                                TextWrapped = true,
                                                                Text = Desctiption,
                                                                TextSize = 15,
                                                                TextColor3 = Theme.LittleTextColor,
                                                                Font = Theme.LittleFont,
                                                                TextTransparency = Theme.LittleTextTransparency,
                                                                BorderSizePixel = 0,
                                                                TextXAlignment = Enum.TextXAlignment.Left,
                                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                                BackgroundTransparency = 1,
                                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                                TextWrap = true,
                                                                ZIndex = 12
                                                            })
                                                        })
                                                    })

                                                    local TextName, TextDescription = ButtonFrame.FakeTextName.TextName, ButtonFrame.FakeTextName.TextDescription
                                                    local TextNameBounds = TextName.TextBounds

                                                    AddConnection(TextName:GetPropertyChangedSignal("TextBounds"), function()
                                                        TextDescription.Size = UDim2.new(1, -TextName.TextBounds.X - 25, 1, 0)
                                                        TextDescription.Position = UDim2.new(0, TextName.TextBounds.X + 15, 0, 0)
                                                    end)

                                                    TextDescription.Size = UDim2.new(1, -TextName.TextBounds.X - 25, 1, 0)
                                                    TextDescription.Position = UDim2.new(0, TextName.TextBounds.X + 15, 0, 0)

                                                    AddConnection(ButtonFrame.MouseButton1Up, function()
                                                        CanBeClosed = false
                                                        task.delay(0.2, function() CanBeClosed = true end)

                                                        if typeof(Option) == "string" then
                                                            DropdownSet(Option, true)
                                                        else
                                                            for _, Options in Option do DropdownSet(Options, true) end
                                                        end
                                                    end)
                                                end

                                                if NeedSet then
                                                    if typeof(ToSelect) == "string" then
                                                        DropdownSet(ToSelect, true)
                                                    else
                                                        for _, Options in ToSelect do DropdownSet(ToSelect, true) end
                                                    end
                                                end

                                                for i, Text in UI.Elements.Texts do
                                                    if not Text or Text and not Text.Parent then
                                                        table.remove(UI.Elements.Texts, i)
                                                    end
                                                end

                                                for _, Button in ItemHolder.Holder:GetChildren() do
                                                    if Button.Name == "UIListLayout" then continue end
                                                    UI.Elements.Texts[#UI.Elements.Texts+1] = Button.FakeTextName.TextName
                                                end
                                            end

                                            function Dropdown:Refresh(OptionsAdd)
                                                local OldDropdownValue = Dropdown.Value
                                                SelectedOptions = {}

                                                for _, Button in ItemHolder.Holder:GetChildren() do
                                                    if Button.Name == "UIListLayout" then continue end
                                                    local ButtonText = Button.FakeTextName
                                                    PlayTween(ButtonText, 0.2, { BackgroundTransparency = 1 })
                                                    ButtonText.TextName.TextSize = 16
                                                end

                                                SelectedItemBox.NameText.Text = "None"
                                                SelectedItemBox.Size = UDim2.new(0, SelectedItemBox.NameText.TextBounds.X + 10, 0, 20)
                                                SelectedItemBox.Position = UDim2.new(1, -(SelectedItemBox.NameText.TextBounds.X + 20), 0, 5)

                                                for _, Option in ItemHolder.Holder:GetChildren() do
                                                    if Option.Name == "UIListLayout" then continue end
                                                    Option:Destroy(OptionsAdd)
                                                end

                                                AddOptions(OptionsAdd, true, OldDropdownValue)
                                            end

                                            AddOptions(DropdownConfig.Options, false, nil)

                                            AddConnection(DropdownFrame.Click.MouseButton1Up, function()
                                                Opened = not Opened
                                                ToggleDropdown(Opened)
                                            end)

                                            AddConnection(DropdownFrame.MouseEnter, function() 
                                                DropdownText.TextSize = 17 
                                            end)

                                            AddConnection(DropdownFrame.MouseLeave, function() 
                                                DropdownText.TextSize = 16 
                                            end)

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = DropdownText
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = DropdownFrame
                                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = SelectedItemBox.NameText
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Dropdown", 
                                                Name = DropdownConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = DropdownFrame,
                                                Side = SectionConfig.Side
                                            }
                                            for _, Button in ItemHolder.Holder:GetChildren() do
                                                if Button.Name == "UIListLayout" then continue end
                                                UI.Elements.Texts[#UI.Elements.Texts+1] = Button.FakeTextName.TextName
                                            end
                                            UI.Elements.ThirdElements[#UI.Elements.ThirdElements+1] = SelectedItemBox

                                            Dropdown:Set(DropdownConfig.Default)

                                            UI.Flags[DropdownConfig.Flag] = Dropdown

                                            return Dropdown
                                        end

                                        function Section:CreateColorpicker(ColorpickerConfig: {
                                            Name: string, DefaultColor: Color3, DefaultTransparency: number,
                                            Flag: string, Callback: () -> (Color3, number)
                                        })
                                            UI.ElementCounter += 1; if UI.ElementCounter % 8 == 0 then task.wait() end

                                            ColorpickerConfig = ColorpickerConfig or {}
                                            ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                                            ColorpickerConfig.DefaultColor = ColorpickerConfig.DefaultColor or Color3.fromRGB(255, 255, 255)
                                            ColorpickerConfig.DefaultTransparency = ColorpickerConfig.DefaultTransparency or 0.5
                                            ColorpickerConfig.Flag = ColorpickerConfig.Flag or string_format("Colorpicker%s", UI.ElementCounter)
                                            ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                                            
                                            local Colorpicker = { 
                                                Name = ColorpickerConfig.Name,
                                                Value = ColorpickerConfig.DefaultColor,
                                                TransparencyValue = ColorpickerConfig.DefaultTransparency,
                                                Type = "Colorpicker"
                                            }

                                            local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.DefaultColor)
                                            local TransparencyColor = ColorpickerConfig.DefaultTransparency

                                            local ColorpickerFrame = CreateElement("TextButton", {
                                                Name = "ColorpickerFrame",
                                                Size = UDim2.new(1, 0, 0, 30),
                                                Parent = GetParent(),
                                                BackgroundColor3 = Theme.ElementsColor,
                                                BackgroundTransparency = Theme.ElementsTransparency,
                                                ClipsDescendants = false,
                                                Text = "",
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0
                                            }, {
                                                CreateElement("TextLabel", {
                                                    Name = "NameText",
                                                    Size = UDim2.new(1, -30, 0, 30),
                                                    Position = UDim2.new(0, 10, 0, 0),
                                                    TextWrapped = true,
                                                    Text = ColorpickerConfig.Name,
                                                    TextSize = 16,
                                                    TextColor3 = Theme.TextColor,
                                                    Font = Theme.Font,
                                                    TextTransparency = Theme.TextTransparency,
                                                    BorderSizePixel = 0,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    TextYAlignment = Enum.TextYAlignment.Center,
                                                    BackgroundTransparency = 1,
                                                    TextWrap = false
                                                }),
                                                CreateElement("RoundFrame", {
                                                    Name = "ColorBox",
                                                    Size = UDim2.new(0, 25, 0, 25),
                                                    Position = UDim2.new(1, -35, 0, 5),
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    BackgroundTransparency = 0.9,
                                                }, {
                                                    CreateElement("RoundFrame", {
                                                        Name = "Color",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        BackgroundColor3 = ColorpickerConfig.DefaultColor,
                                                        BackgroundTransparency = ColorpickerConfig.DefaultTransparency,
                                                    })
                                                }),
                                                CreateElement("RoundFrame", {
                                                    Name = "ItemHolder",
                                                    Size = UDim2.new(1, 0, 0, 0),
                                                    Position = UDim2.new(0, 0, 0, 30),
                                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                    BackgroundTransparency = 1,
                                                    Visible = false,
                                                    Active = true,
                                                    ClipsDescendants = true
                                                }, {
                                                    CreateElement("ImageLabel", {
                                                        Name = "ColorSelect",
                                                        Size = UDim2.new(1, -100, 1, -40),
                                                        Position = UDim2.new(0, 20, 0, 20),
                                                        BackgroundTransparency = 0,
                                                        ImageTransparency = 0,
                                                        Image = "rbxassetid://4155801252"
                                                    }, {
                                                        CreateElement("Corner"),
                                                        CreateElement("ImageLabel", {
                                                            Name = "Select",
                                                            Size = UDim2.new(0, 18, 0, 18),
                                                            Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                            ScaleType = Enum.ScaleType.Fit,
                                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                                            BackgroundTransparency = 1,
                                                            Image = "http://www.roblox.com/asset/?id=4805639000"
                                                        })
                                                    }),
                                                    CreateElement("Frame", {
                                                        Name = "HueSelect",
                                                        Size = UDim2.new(0, 20, 1, -40),
                                                        Position = UDim2.new(1, -70, 0, 20),
                                                        BackgroundTransparency = 0
                                                    }, {
                                                        CreateElement("Corner"),
                                                        CreateElement("ImageLabel", {
                                                            Name = "Select",
                                                            Size = UDim2.new(0, 18, 0, 18),
                                                            Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                            ScaleType = Enum.ScaleType.Fit,
                                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                                            BackgroundTransparency = 1,
                                                            Image = "http://www.roblox.com/asset/?id=4805639000"
                                                        }),
                                                        CreateElement("UIGradient", {
                                                            Rotation = 270,
                                                            Color = ColorSequence.new{
                                                                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), 
                                                                ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), 
                                                                ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), 
                                                                ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), 
                                                                ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), 
                                                                ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), 
                                                                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
                                                            }
                                                        })
                                                    }),
                                                    CreateElement("ImageLabel", {
                                                        Name = "TransparencySelect",
                                                        Size = UDim2.new(0, 20, 1, -70),
                                                        Position = UDim2.new(1, -40, 0, 20),
                                                        BackgroundTransparency = 1,
                                                        ImageTransparency = 0,
                                                        Image = "rbxassetid://139785960036434",
                                                        ScaleType = Enum.ScaleType.Tile,
                                                        TileSize = UDim2.new(0, 7, 0, 7)
                                                    }, {
                                                        CreateElement("Corner"),
                                                        CreateElement("ImageLabel", {
                                                            Name = "Select",
                                                            Size = UDim2.new(0, 18, 0, 18),
                                                            Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                                                            ScaleType = Enum.ScaleType.Fit,
                                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                                            BackgroundTransparency = 1,
                                                            Image = "http://www.roblox.com/asset/?id=4805639000"
                                                        }),
                                                        CreateElement("UIGradient", {
                                                            Rotation = 270,
                                                            Color = ColorSequence.new{
                                                                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)), 
                                                                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(234, 255, 255)), 
                                                            }
                                                        })
                                                    }),
                                                    CreateElement("TextButton", {
                                                        Name = "ResetButtonFrame",
                                                        Size = UDim2.new(0, 20, 0, 20),
                                                        Position = UDim2.new(1, -40, 1, -40),
                                                        BackgroundTransparency = 0.9,
                                                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                                        Text = "",
                                                        AutoButtonColor = false,
                                                        BorderSizePixel = 0
                                                    }, {
                                                        CreateElement("ImageLabel", {
                                                            Name = "Image",
                                                            Size = UDim2.new(0, 20, 1, -0),
                                                            Position = UDim2.new(1, -20, 0, 0),
                                                            BackgroundTransparency = 1,
                                                            ImageTransparency = 0,
                                                            Image = "rbxassetid://10734933056"
                                                        })
                                                    })
                                                }),
                                                CreateElement("TextButton", {
                                                    Name = "Click",
                                                    Size = UDim2.new(1, 0, 0, 30),
                                                    BackgroundTransparency = 1,
                                                    Text = "",
                                                    AutoButtonColor = false,
                                                    BorderSizePixel = 0
                                                }),
                                                CreateElement("Stroke", { Transparency = 1, Color = Color3.fromRGB(255, 255, 255) })
                                            }); ColorpickerFrame.NameText.Size = UDim2.new(0, ColorpickerFrame.NameText.TextBounds.X, 0, 30)

                                            local ColorpickerText = ColorpickerFrame.NameText
                                            local Color, ColorSelection = ColorpickerFrame.ItemHolder.ColorSelect, ColorpickerFrame.ItemHolder.ColorSelect.Select
                                            local Hue, HueSelection = ColorpickerFrame.ItemHolder.HueSelect, ColorpickerFrame.ItemHolder.HueSelect.Select
                                            local Transparency, TransparencySelection = ColorpickerFrame.ItemHolder.TransparencySelect, ColorpickerFrame.ItemHolder.TransparencySelect.Select
                                            local ItemHolder = ColorpickerFrame.ItemHolder
                                            local Opened, CanBeClosed = false, false
                                            local ResetButton = ItemHolder.ResetButtonFrame
                                            local ColorpickerBox = ColorpickerFrame.ColorBox.Color
                                            local SizeXHolder = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X - 30

                                            function Colorpicker:Set(Value, Transp)
                                                Colorpicker.Value = Value
                                                Colorpicker.TransparencyValue = Transp
                                                ColorpickerBox.BackgroundColor3 = Colorpicker.Value
                                                ColorpickerBox.BackgroundTransparency = Colorpicker.TransparencyValue
                                                
                                                ColorpickerConfig.Callback(
                                                    Colorpicker.Value, 
                                                    Colorpicker.TransparencyValue
                                                )
                                            end

                                            local function ToggleColorpicker(Open: boolean)
                                                local SizeX = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X

                                                if not Open then
                                                    Opened = Open
                                                    PlayTween(ItemHolder, 0.2, { Size = UDim2.new(0, SizeX - 30, 0, 0) })
                                                    PlayTween(ColorpickerFrame, 0.2, { Size = UDim2.new(1, 0, 0, 30) })
                                                    task.wait(0.15)

                                                    ItemHolder.Visible = Open
                                                    CanBeClosed = false
                                                else
                                                    Opened = Open
                                                    ItemHolder.Visible = Opened
                                                    PlayTween(ItemHolder, 0.2, { Size = UDim2.new(0, SizeX - 30, 0, 200) })
                                                    PlayTween(ColorpickerFrame, 0.2, { Size = UDim2.new(1, 0, 0, 230) })
                                                    task.wait(0.2)
                                                    CanBeClosed = true
                                                end
                                            end

                                            AddConnection(ColorpickerFrame.Click.MouseButton1Up, function()
                                                Opened = not Opened
                                                ToggleColorpicker(Opened)
                                            end)

                                            AddConnection(SectionsHolder.FakeDescendantClipperFrameRight:GetPropertyChangedSignal("AbsoluteSize"), function()
                                                local SizeX = SectionsHolder.FakeDescendantClipperFrameRight.AbsoluteSize.X
                                                ItemHolder.Size = UDim2.new(0, SizeX - 30, 0, 200)
                                                ItemHolder.Position = UDim2.new(1, -SizeX + 20, 0, 30)
                                            end)

                                            local function UpdateColorPicker(NotCallbacking)
                                                ColorH = ColorH >= 0 and ColorH or 0
                                                ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                                                ColorpickerBox.BackgroundTransparency = TransparencyColor
                                                Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)

                                                Colorpicker.Value = ColorpickerBox.BackgroundColor3
                                                Colorpicker.TransparencyValue = ColorpickerBox.BackgroundTransparency

                                                if NotCallbacking == nil or NotCallbacking == false then
                                                    ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3, ColorpickerBox.BackgroundTransparency)
                                                end
                                            end

                                            AddConnection(ResetButton.MouseButton1Up, function()
                                                ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.DefaultColor)
                                                TransparencyColor = ColorpickerConfig.DefaultTransparency

                                                HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                                                ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                                                TransparencySelection.Position = UDim2.new(0.5, 0, 1 - TransparencyColor, 0)

                                                UpdateColorPicker()
                                            end)

                                            HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
                                            ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
                                            TransparencySelection.Position = UDim2.new(0.5, 0, 1 - TransparencyColor, 0)

                                            local ColorInput = nil
                                            AddConnection(Color.InputBegan, function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    if ColorInput then ColorInput:Disconnect() end
                                                    ColorInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                        CanBeClosed = false
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
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    if ColorInput then 
                                                        task.delay(0.1, function() CanBeClosed = true end)
                                                        ColorInput:Disconnect()
                                                        
                                                        local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                                                        local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
                                                        ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                                                        ColorS = ColorX
                                                        ColorV = 1 - ColorY
                                                        UpdateColorPicker()
                                                    end
                                                end
                                            end)

                                            local HueInput = nil
                                            AddConnection(Hue.InputBegan, function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    if HueInput then HueInput:Disconnect() end

                                                    HueInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                        CanBeClosed = false
                                                        local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                                                        HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                                                        ColorH = 1 - HueY

                                                        UpdateColorPicker()
                                                    end)
                                                end
                                            end)

                                            AddConnection(Hue.InputEnded, function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    if HueInput then 
                                                        task.delay(0.1, function() CanBeClosed = true end)
                                                        HueInput:Disconnect()
                                                        
                                                        local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                                                        HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                                                        ColorH = 1 - HueY

                                                        UpdateColorPicker()
                                                    end
                                                end
                                            end)

                                            local TransparencyInput = nil
                                            AddConnection(Transparency.InputBegan, function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    if TransparencyInput then TransparencyInput:Disconnect() end

                                                    TransparencyInput = AddConnection(Serv.RunService.RenderStepped, function()
                                                        CanBeClosed = false
                                                        local TransparencyY = (math.clamp(Mouse.Y - Transparency.AbsolutePosition.Y, 0, Transparency.AbsoluteSize.Y) / Transparency.AbsoluteSize.Y)

                                                        TransparencySelection.Position = UDim2.new(0.5, 0, TransparencyY, 0)
                                                        TransparencyColor = 1 - TransparencyY

                                                        UpdateColorPicker()
                                                    end)
                                                end
                                            end)

                                            AddConnection(Transparency.InputEnded, function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    if TransparencyInput then 
                                                        task.delay(0.1, function() CanBeClosed = true end)
                                                        TransparencyInput:Disconnect()
                                                        
                                                        local TransparencyY = (math.clamp(Mouse.Y - Transparency.AbsolutePosition.Y, 0, Transparency.AbsoluteSize.Y) / Transparency.AbsoluteSize.Y)

                                                        TransparencySelection.Position = UDim2.new(0.5, 0, TransparencyY, 0)
                                                        TransparencyColor = 1 - TransparencyY

                                                        UpdateColorPicker()
                                                    end
                                                end
                                            end)

                                            Colorpicker:Set(ColorpickerConfig.DefaultColor, ColorpickerConfig.DefaultTransparency)

                                            UI.Elements.Texts[#UI.Elements.Texts+1] = ColorpickerText
                                            UI.Elements.Elements[#UI.Elements.Elements+1] = ColorpickerFrame
                                            UI.SearchElements[#UI.SearchElements+1] = { 
                                                Type = "Colorpicker", 
                                                Name = ColorpickerConfig.Name:lower(), 
                                                Window = WindowConfig.Name,
                                                Frame = ColorpickerFrame,
                                                Side = SectionConfig.Side
                                            }

                                            UI.Flags[ColorpickerConfig.Flag] = Colorpicker

                                            return Colorpicker
                                        end

                                        return Section
                                    end

                                return Tab
                            end

                        -- Connections
                            local MouseHere, StartHolding, IsHolding, OpenedMenu = false

                            AddConnection(TaskbarIcon.InputBegan, function(Input)
                                if Input.UserInputType == Enum.UserInputType.MouseButton2 then
                                    Window.ContextMenuOpen = not Window.ContextMenuOpen
                                    Window:ToggleContextMenu(Window.ContextMenuOpen)
                                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                                    Window.ContextMenuOpen = false
                                    Window:ToggleContextMenu(false)

                                    IsHolding = true
                                    StartHolding = tick()
                                    
                                    while IsHolding and ((tick() - StartHolding) <= 1) do task.wait() end
                                    if not IsHolding then return end

                                    IsHolding = false
                                    StartHolding = 0
                                    OpenedMenu = true

                                    Window.ContextMenuOpen = true
                                    Window:ToggleContextMenu(true)
                                end 
                            end)

                            AddConnection(TaskbarIcon.InputEnded, function(Input)
                                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                                    task.spawn(function()
                                        PlayTween(TaskbarIcon.Icon, 0.2, { 
                                            Size = UDim2.new(1, -20, 1, -20),
                                            Position = UDim2.new(0.5, -5, 0.5, -5)
                                        })
                                        task.wait(0.2)
                                        PlayTween(TaskbarIcon.Icon, 0.2, { 
                                            Size = UDim2.new(1, -10, 1, -10),
                                            Position = MouseHere and UDim2.new(0.5, -5, 0.5, -10) or UDim2.new(0.5, -5, 0.5, -5)
                                        })
                                    end)

                                    IsHolding = false
                                    StartHolding = 0

                                    if OpenedMenu then
                                        OpenedMenu = false
                                        return
                                    end

                                    Window.Opened = not Window.Opened
                                    Window:Toggle(Window.Opened)
                                end
                            end)

                            AddConnection(Serv.UserInputService.InputEnded, function(Input)
                                if Window.ContextMenuOpen and Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType == Enum.UserInputType.Touch then
                                    Window.ContextMenuOpen = false
                                    Window:ToggleContextMenu(false)
                                end
                            end)

                            AddConnection(ButtonsFrame.CloseButton.MouseButton1Up, function()
                                Window.Opened = not Window.Opened
                                Window:Toggle(Window.Opened)
                            end)

                            AddConnection(ButtonsFrame.MinimizeButton.MouseButton1Up, function()
                                Window.Minimized = not Window.Minimized
                                Window:MinimizeToggle(Window.Minimized)
                            end)

                            AddConnection(WindowFrame.ResizePointFake.MouseEnter, function()
                                PlayTween(WindowFrame.ResizePointFake.ResizePoint, 0.3, {
                                    Size = UDim2.new(0, 30, 0, 30)
                                })
                            end)

                            local IsInputting = false
                            AddConnection(WindowFrame.ResizePointFake.MouseLeave, function()
                                while IsInputting do task.wait() end
                                PlayTween(WindowFrame.ResizePointFake.ResizePoint, 0.3, {
                                    Size = UDim2.new(0, 20, 0, 20)
                                })
                            end)

                            AddConnection(TaskbarIcon.MouseEnter, function()
                                MouseHere = true
                                PlayTween(TaskbarIcon.Icon, 0.1, { Position = UDim2.new(0.5, -5, 0.5, -10) })
                            end)

                            AddConnection(TaskbarIcon.MouseLeave, function()
                                MouseHere = false
                                PlayTween(TaskbarIcon.Icon, 0.1, { Position = UDim2.new(0.5, -5, 0.5, -5) })
                            end)

                            AddConnection(ContextMenu.ButtonPin.MouseButton1Up, function()
                                Window.Pinned = not Window.Pinned
                                Window:SetPinned(Window.Pinned)
                                Window.ContextMenuOpen = false
                                Window:ToggleContextMenu(false)
                            end)

                            AddConnection(ContextMenu.ButtonReset.MouseButton1Up, function()
                                Window:ResetSizePos()
                                Window.ContextMenuOpen = false
                                Window:ToggleContextMenu(false)
                            end)

                            do -- Dragging
                                local Dragging, DragInput, MousePos, FramePos = false
                                AddConnection(WindowFrame.TopBar.InputBegan, function(Input)
                                    if Input.UserInputType == Enum.UserInputType.MouseButton1  or Input.UserInputType == Enum.UserInputType.Touch then
                                        Dragging = true
                                        MousePos = Input.Position
                                        FramePos = WindowFrame.Position

                                        local Conn; Conn = Input.Changed:Connect(function()
                                            if Input.UserInputState == Enum.UserInputState.End then 
                                                Dragging = false
                                                Conn:Disconnect() 
                                            end
                                        end)
                                    end
                                end)
                                
                                AddConnection(WindowFrame.TopBar.InputChanged, function(Input)
                                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then 
                                        DragInput = Input 
                                    end
                                end)

                                AddConnection(Serv.UserInputService.InputChanged, function(Input)
                                    if Input == DragInput and Dragging then
                                        local Delta = Input.Position - MousePos

                                        local Pos = UDim2.new(
                                            FramePos.X.Scale,
                                            FramePos.X.Offset + Delta.X, 
                                            FramePos.Y.Scale, 
                                            FramePos.Y.Offset + Delta.Y
                                        )

                                        Window.OldPosition = Pos
                                        PlayTween(WindowFrame, {0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}, {
                                            Position = Pos 
                                        }):Play()
                                    end
                                end)
                            end

                            do -- Resizing
                                local Dragging, DragInput, MousePos, FrameSize = false
                                AddConnection(WindowFrame.ResizePointFake.InputBegan, function(Input)
                                    if Input.UserInputType == Enum.UserInputType.MouseButton1  or Input.UserInputType == Enum.UserInputType.Touch then
                                        Dragging = true
                                        MousePos = Input.Position
                                        FrameSize = WindowFrame.Size
                                        IsInputting = true

                                        local Conn; Conn = Input.Changed:Connect(function()
                                            if Input.UserInputState == Enum.UserInputState.End then 
                                                Dragging = false
                                                IsInputting = false
                                                Conn:Disconnect() 
                                            end
                                        end)
                                    end
                                end)
                                
                                AddConnection(WindowFrame.ResizePointFake.InputChanged, function(Input)
                                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then 
                                        DragInput = Input 
                                    end
                                end)

                                AddConnection(Serv.UserInputService.InputChanged, function(Input)
                                    if Input == DragInput and Dragging then
                                        local Delta = Input.Position - MousePos

                                        local Size = UDim2.new(
                                            FrameSize.X.Scale, 
                                            math.clamp(
                                                FrameSize.X.Offset + Delta.X, 
                                                100,
                                                9999
                                            ),
                                            FrameSize.Y.Scale, 
                                            math.clamp(
                                                FrameSize.Y.Offset + Delta.Y, 
                                                100, 
                                                9999
                                            )
                                        )

                                        Window.OldSize = Size
                                        PlayTween(WindowFrame, {0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}, {
                                            Size = Size 
                                        }):Play()
                                    end
                                end)
                            end

                            do -- Bind
                                local BindBox = ButtonsFrame.BindBox
                                local TextBounds = BindBox.TextBounds
                                BindBox.Position = UDim2.new(0, -TextBounds.X - 10, 0.5, 0)
                                BindBox.Size = UDim2.new(0, TextBounds.X + 10, 0, 20)

                                local MouseKeys = {
                                    Enum.UserInputType.MouseButton1,
                                    Enum.UserInputType.MouseButton2,
                                    Enum.UserInputType.MouseButton3,
                                    "MouseButton1", 
                                    "MouseButton2",
                                    "MouseButton3"
                                }; local function GetBind(Key)
                                    if typeof(Key) == "string" then
                                        if Key == "" or Key == "None" or Key == "nil" then return nil end
                                        if table_find(MouseKeys, Key) then
                                            return Enum.UserInputType[Key]
                                        else
                                            return Enum.KeyCode[Key]
                                        end
                                    end
                                    return Key
                                end

                                local Bind = { 
                                    Name = WindowConfig.Name.."_WindowBind", 
                                    Value = "",
                                    Type = "Bind"
                                }
                                local IsBinding

                                function Bind:Set(Key)
                                    local BindValue = GetBind(Key)
                                    if not BindValue or BindValue == Enum.KeyCode.None or BindValue == Enum.UserInputType.None then
                                        Bind.Value = ""
                                        BindBox.Text = "None"
                                        return
                                    end
                                    Bind.Value = BindValue.Name
                                    BindBox.Text = BindValue.Name
                                end

                                AddConnection(BindBox:GetPropertyChangedSignal("Text"), function()
                                    local TextBounds = BindBox.TextBounds
                                    PlayTween(BindBox, 0.1, { 
                                        Size = UDim2.new(0, TextBounds.X + 10, 0, 20),
                                        Position = UDim2.new(0, -TextBounds.X - 10, 0.5, 0)
                                    })
                                end)

                                AddConnection(BindBox.MouseButton1Up, function()
                                    IsBinding = true
                                    BindBox.Text = "Press any key"
                                end)

                                AddConnection(Serv.UserInputService.InputBegan, function(Input)
                                    if Serv.UserInputService:GetFocusedTextBox() then return end
                                    if IsBinding then
                                        if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
                                            Bind:Set(Input.UserInputType ~= Enum.UserInputType.Keyboard and Input.UserInputType or Input.KeyCode)
                                            IsBinding = false
                                        end
                                    else
                                        if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
                                        Window.Opened = not Window.Opened
                                        Window:Toggle(Window.Opened)
                                    end
                                end)

                                UI.Flags[Bind.Name] = Bind
                            end

                        UI.Windows[WindowConfig.Name] = Window
                        UI.Windows[WindowConfig.Name].TaskbarIcon = TaskbarIcon

                        return Window
                    end

                -- AutoClose
                    function Taskbar:ToggleAutoClose(Enabled: boolean)
                        local MainFakeCenterFrame = MainFrame.MainFakeCenterFrame
                        if Enabled then
                            local CloneFrame = MainFakeCenterFrame:Clone()
                            CloneFrame.Name = "MainFakeCenterFrameClone"
                            CloneFrame.Parent = MainFrame
                            CloneFrame:ClearAllChildren()

                            PlayTween(MainFakeCenterFrame, UI.AutoCloseSettings.Speed, { Position = UDim2.new(0.5, 0, 1.5, 0) })

                            local Opened = false
                            local CloseFunc = nil

                            AddConnection(CloneFrame.MouseEnter, function()
                                Opened = true

                                if CloseFunc then
                                    task.cancel(CloseFunc)
                                    CloseFunc = nil
                                end

                                PlayTween(MainFakeCenterFrame, UI.AutoCloseSettings.Speed, { Position = UDim2.new(0.5, 0, 0.5, 0) })
                            end, "AutoCloseMouseEnterConn")

                            AddConnection(CloneFrame.MouseLeave, function()
                                Opened = false
                                CloseFunc = task.delay(UI.AutoCloseSettings.Delay, function()
                                    CloseFunc = nil
                                    if Opened then return end
                                    PlayTween(MainFakeCenterFrame, UI.AutoCloseSettings.Speed, { Position = UDim2.new(0.5, 0, 1.5, 0) })
                                end)
                            end, "AutoCloseMouseLeaveConn")
                        else
                            local CloneFrame = MainFrame:FindFirstChild("MainFakeCenterFrameClone")
                            if CloneFrame then 
                                CloneFrame:Destroy() 
                                RemoveConnection("AutoCloseMouseEnterConn")
                                RemoveConnection("AutoCloseMouseLeaveConn")
                                PlayTween(MainFakeCenterFrame, UI.AutoCloseSettings.Speed, { Position = UDim2.new(0.5, 0, 0.5, 0) })
                            end
                        end
                    end

                    function Taskbar:ConfigAutoClose(Config: { Speed: number, Delay: number })
                        Config.Speed = Config.Speed or nil
                        Config.Delay = Config.Delay or nil

                        if Config.Speed then UI.AutoCloseSettings.Speed = Config.Speed end
                        if Config.Delay then UI.AutoCloseSettings.Delay = Config.Delay end
                    end

                -- Notifications
                    function Taskbar:CreateNotification(NotitficationConfig: {
                        Name: string, Desctiption: string, Duration: number,
                        Sound: string, Volume: number, Group: string
                    }) task.spawn(function()
                        if not UI.NotificationSettings.Enabled then return end

                        NotitficationConfig = NotitficationConfig or {}
                        NotitficationConfig.Name = NotitficationConfig.Name or "Notification"
                        NotitficationConfig.Description = NotitficationConfig.Description or "Description"
                        NotitficationConfig.Duration = NotitficationConfig.Duration or 3
                        NotitficationConfig.Group = NotitficationConfig.Group or "DefaultNotification"

                        UI.NotificationSettings.NotificationsCounter += 1
                        NotificationsHubFrame.AllParentFakeFrame.StatusFrame.NameText.Text = "Notifications: "..tostring(UI.NotificationSettings.NotificationsCounter)
                        
                        local IsGroup, NotificationFrame = false, nil

                        for _, Notification in MainFrame.NotificationsFrame:GetChildren() do
                            local StringValue = Notification:FindFirstChild("Value")
                            if StringValue and StringValue.Value == NotitficationConfig.Group then
                                IsGroup = true
                                NotificationFrame = Notification
                                break
                            end
                        end

                        if not IsGroup then
                            UI.NotificationSettings.NotificationOrder += 1
                            NotificationFrame = CreateElement("RoundFrame", {
                                Name = "NotificationFrame",
                                Size = UDim2.new(1, 0, 0, 0),
                                Position = UDim2.new(0.5, 0, 0, -10),
                                AnchorPoint = Vector2.new(0.5, 1),
                                Parent = MainFrame.NotificationsFrame,
                                BackgroundColor3 = Theme.TaskbarColor,
                                BackgroundTransparency = Theme.TaskbarTransparency,
                                Visible = true,
                                ClipsDescendants = true,
                                LayoutOrder = UI.NotificationSettings.NotificationOrder
                            }, {
                                CreateElement("TextLabel", {
                                    Name = "NameText",
                                    Text = NotitficationConfig.Name,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    BackgroundTransparency = 1,
                                    AnchorPoint = Vector2.new(0, 0),
                                    Size = UDim2.new(1, -20, 0, 10),
                                    Position = UDim2.new(0, 10, 0, 5),
                                    TextColor3 = Theme.TextColor,
                                    Font = Theme.Font,
                                    TextSize = 18,
                                    BorderSizePixel = 0,
                                    TextWrapped = true
                                }),
                                CreateElement("TextLabel", {
                                    Name = "DescriptionText",
                                    Text = NotitficationConfig.Description,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    BackgroundTransparency = 1,
                                    AnchorPoint = Vector2.new(0, 0),
                                    Size = UDim2.new(1, -20, 0, 10),
                                    TextColor3 = Theme.LittleTextColor,
                                    TextTransparency = Theme.LittleTextTransparency,
                                    Position = UDim2.new(0, 10, 0, 10),
                                    Font = Theme.LittleFont,
                                    TextSize = 18,
                                    BorderSizePixel = 0,
                                    TextWrapped = true
                                }),
                                CreateElement("StringValue", { Value = NotitficationConfig.Group }),
                                CreateElement("Noise"),
                                CreateElement("Vingette"),
                                CreateElement("BackgroundImage"),
                            })

                            local NameText, DescriptionText = NotificationFrame.NameText, NotificationFrame.DescriptionText
                            local IsMoreThanFrame = NameText.TextBounds.X + 30 + DescriptionText.TextBounds.X >= NotificationFrame.AbsoluteSize.X
                            local SizeY, PosY

                            if IsMoreThanFrame then DescriptionText.Text = "..." end

                            local CounterOffset = 0
                            local function UpdateSizes()
                                NameText.Size = UDim2.new(1, -20, 0, NameText.TextBounds.Y + 20)
                                DescriptionText.Size = UDim2.new(1, -20, 0, DescriptionText.TextBounds.Y + 20)

                                if NotificationFrame:FindFirstChild("CounterFrame") then
                                    CounterOffset = NotificationFrame.CounterFrame.CounterText.TextBounds.X + 10
                                end

                                NameText.Position = UDim2.new(0, 10 + CounterOffset, 0, 5)

                                if NameText.TextBounds.X + 30 + DescriptionText.TextBounds.X <= NotificationFrame.AbsoluteSize.X - CounterOffset then
                                    SizeY = UDim2.new(1, 0, 0, 30)
                                    PosY = UDim2.new(0, NameText.TextBounds.X + 20 + CounterOffset, 0, 5)
                                else
                                    SizeY = UDim2.new(1, 0, 0, NameText.TextBounds.Y + 15 + DescriptionText.TextBounds.Y)
                                    PosY = UDim2.new(0, 10 + CounterOffset, 0, NameText.TextBounds.Y + 10)
                                end

                                DescriptionText.Position = PosY
                                PlayTween(NotificationFrame, 0.2, {Size = SizeY})
                            end

                            AddConnection(NameText:GetPropertyChangedSignal("TextBounds"), UpdateSizes)
                            AddConnection(DescriptionText:GetPropertyChangedSignal("TextBounds"), UpdateSizes)
                            AddConnection(NameText:GetPropertyChangedSignal("Text"), UpdateSizes)
                            AddConnection(DescriptionText:GetPropertyChangedSignal("Text"), UpdateSizes)

                            AddConnection(NotificationFrame.MouseEnter, function()
                                if IsMoreThanFrame then 
                                    DescriptionText.Position = UDim2.new(0, 10 + CounterOffset, 0, NameText.TextBounds.Y + 10)
                                    DescriptionText.Text = NotitficationConfig.Description 
                                end
                            end)

                            AddConnection(NotificationFrame.MouseLeave, function()
                                if IsMoreThanFrame then DescriptionText.Text = "..." end
                            end)

                            task.wait()
                            UpdateSizes()
                            PlaySound(UI.NotificationSettings.Sound, UI.NotificationSettings.Volume)
                            PlayTween(NotificationFrame, 0.2, { Size = SizeY })

                            UI.Elements.Texts[#UI.Elements.Texts+1] = NotificationFrame.NameText
                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = NotificationFrame.DescriptionText
                        else
                            local CounterFrame = NotificationFrame:FindFirstChild("CounterFrame")
                            local Counter = 1

                            if CounterFrame then
                                Counter = tonumber(CounterFrame.CounterText.Text:match("%d+")) + 1
                                CounterFrame.CounterText.Text = string_format("x%s", Counter)
                            else
                                CounterFrame = CreateElement("RoundFrame", {
                                    Name = "CounterFrame",
                                    Size = UDim2.new(0, 0, 0, 20),
                                    Position = UDim2.new(0, 5, 0.5, 0),
                                    AnchorPoint = Vector2.new(0, 0.5),
                                    BackgroundTransparency = 0.9,
                                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                    Parent = NotificationFrame
                                }, {
                                    CreateElement("TextLabel", {
                                        Name = "CounterText",
                                        Text = "x2",
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        BackgroundTransparency = 1,
                                        AnchorPoint = Vector2.new(0, 0),
                                        Size = UDim2.new(1, 0, 1, 0),
                                        TextColor3 = Theme.TextColor,
                                        Font = Theme.LittleFont,
                                        TextSize = 18,
                                        BorderSizePixel = 0,
                                        TextWrapped = false
                                    })
                                })

                                local CounterText = CounterFrame.CounterText
                                AddConnection(CounterText:GetPropertyChangedSignal("Text"), function()
                                    local TextBounds = CounterText.TextBounds
                                    PlayTween(CounterFrame, 0.1, { Size = UDim2.new(0, TextBounds.X + 10, 0, 20) })
                                end)
                            end

                            PlaySound(UI.NotificationSettings.Sound, UI.NotificationSettings.Volume)
                            local CounterText = CounterFrame.CounterText
                            PlayTween(CounterFrame, 0.1, { Size = UDim2.new(0, CounterText.TextBounds.X + 10, 0, 20) })

                            local NameText = NotificationFrame.NameText
                            NameText.Position = UDim2.new(0, 10 + CounterText.TextBounds.X + 10, 0, 5)

                            local DescriptionText = NotificationFrame.DescriptionText
                            if NameText.TextBounds.X + 30 + DescriptionText.TextBounds.X <= NotificationFrame.AbsoluteSize.X - CounterText.TextBounds.X - 10 then
                                DescriptionText.Position = UDim2.new(0, NameText.TextBounds.X + 20 + CounterText.TextBounds.X + 10, 0, 5)
                            else
                                DescriptionText.Position = UDim2.new(0, 10 + CounterText.TextBounds.X + 10, 0, NameText.TextBounds.Y + 10)
                            end
                        end

                        do -- Notifications Hub
                            local NotificationFrame2 = CreateElement("RoundFrame", {
                                Name = "NotificationFrame",
                                Size = UDim2.new(1, 0, 0, 0),
                                Position = UDim2.new(0.5, 0, 0, -10),
                                AnchorPoint = Vector2.new(0.5, 1),
                                Parent = NotificationsHubFrame.AllParentFakeFrame,
                                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                                BackgroundTransparency = 0.9,
                                Visible = true,
                                ClipsDescendants = true,
                                LayoutOrder = UI.NotificationSettings.NotificationOrder
                            }, {
                                CreateElement("TextLabel", {
                                    Name = "NameText",
                                    Text = NotitficationConfig.Name,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    BackgroundTransparency = 1,
                                    AnchorPoint = Vector2.new(0, 0),
                                    Size = UDim2.new(1, -20, 0, 10),
                                    Position = UDim2.new(0, 10, 0, 10),
                                    TextColor3 = Theme.TextColor,
                                    Font = Theme.Font,
                                    TextSize = 18,
                                    BorderSizePixel = 0,
                                    TextWrapped = true
                                }),
                                CreateElement("TextLabel", {
                                    Name = "DescriptionText",
                                    Text = NotitficationConfig.Description,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Top,
                                    BackgroundTransparency = 1,
                                    AnchorPoint = Vector2.new(0, 0),
                                    Size = UDim2.new(1, -20, 0, 10),
                                    TextColor3 = Theme.LittleTextColor,
                                    Position = UDim2.new(0, 10, 0, 10),
                                    Font = Theme.LittleFont,
                                    TextSize = 18,
                                    BorderSizePixel = 0,
                                    TextWrapped = true,
                                    TextTransparency = Theme.LittleTextTransparency
                                }),
                                CreateElement("StringValue", { Value = NotitficationConfig.Group }),
                            })

                            local NameText2, DescriptionText2 = NotificationFrame2.NameText, NotificationFrame2.DescriptionText

                            local function UpdateSizes()
                                NameText2.Size = UDim2.new(1, -20, 0, NameText2.TextBounds.Y + 20)
                                DescriptionText2.Size = UDim2.new(1, -20, 0, DescriptionText2.TextBounds.Y + 20)
                                DescriptionText2.Position = UDim2.new(0, 10, 0, NameText2.TextBounds.Y + 10)
                                NotificationFrame2.Size = UDim2.new(1, 0, 0, NameText2.AbsoluteSize.Y + DescriptionText2.AbsoluteSize.Y - 20)
                            end; UpdateSizes()

                            AddConnection(NameText2:GetPropertyChangedSignal("TextBounds"), UpdateSizes)
                            AddConnection(DescriptionText2:GetPropertyChangedSignal("TextBounds"), UpdateSizes)
                            AddConnection(NameText2:GetPropertyChangedSignal("Text"), UpdateSizes)
                            AddConnection(DescriptionText2:GetPropertyChangedSignal("Text"), UpdateSizes)

                            UI.Elements.Texts[#UI.Elements.Texts+1] = NotificationFrame2.NameText
                            UI.Elements.LittleTexts[#UI.Elements.LittleTexts+1] = NotificationFrame2.DescriptionText
                        end

                        task.delay(NotitficationConfig.Duration, function() 
                            if NotificationFrame:FindFirstChild("CounterFrame") then
                                local CounterText = NotificationFrame.CounterFrame.CounterText
                                local Counter = tonumber(CounterText.Text:match("%d+")) - 1
                                if Counter <= 1 then
                                    PlayTween(NotificationFrame, 0.2, { Size = UDim2.new(1, 0, 0, 0) }) 
                                    task.wait(0.2)
                                    NotificationFrame:Destroy()
                                else
                                    CounterText.Text = string_format("x%s", Counter)
                                end
                            else
                                PlayTween(NotificationFrame, 0.2, { Size = UDim2.new(1, 0, 0, 0) }) 
                                task.wait(0.2)
                                NotificationFrame:Destroy()
                            end
                        end)
                    end) end

                    function Taskbar:ConfigNotifications(Config: { Sound: string, Volume: number, Enabled: boolean })
                        Config.Sound = Config.Sound or nil
                        Config.Volume = Config.Volume or nil
                        Config.Enabled = Config.Enabled or nil

                        if Config.Sound then UI.NotificationSettings.Sound = Config.Sound end
                        if Config.Volume then UI.NotificationSettings.Volume = Config.Volume end
                        if Config.Enabled then UI.NotificationSettings.Enabled = Config.Enabled end
                    end

                -- Theme Functions
                    function Taskbar:SetWindowsColor(Color: Color3, Transparency: number, ColorIndex: string)
                        local ScreenGui = UI.ScreenGui
                        local MainFakeFrame = ScreenGui.MainFakeFrame

                        if ColorIndex == "Main" then
                            for _, Window in ScreenGui.WindowsFolder:GetChildren() do
                                Window.TopBar.BackgroundColor3 = Color
                                Window.Holder.BackgroundColor3 = Color
                                Window.ResizePointFake.ResizePoint.BackgroundColor3 = Color

                                Window.TopBar.BackgroundTransparency = Transparency
                                Window.Holder.BackgroundTransparency = Transparency
                                Window.ResizePointFake.ResizePoint.BackgroundTransparency = Transparency

                                if Window:FindFirstChild("TabButtonsHolder") then
                                    Window.TabButtonsHolder.BackgroundColor3 = Color
                                    Window.TabButtonsHolder.BackgroundTransparency = Transparency
                                end
                            end

                            for _, Frame in MainFakeFrame.MainFakeCenterFrame:GetChildren() do
                                if Frame.Name == "UIListLayout" then continue end

                                Frame.BackgroundColor3 = Color
                                Frame.BackgroundTransparency = Transparency
                            end

                            MainFakeFrame.StartMainFrame.BackgroundColor3 = Color
                            MainFakeFrame.StartMainFrame.BackgroundTransparency = Transparency
                            
                            MainFakeFrame.NotificationsHubFrame.BackgroundColor3 = Color
                            MainFakeFrame.NotificationsHubFrame.BackgroundTransparency = Transparency

                            Theme.TaskbarColor = Color
                            Theme.TaskbarTransparency = Transparency
                        elseif ColorIndex == "Second" then
                            local OtherAppsFake = MainFakeFrame.StartMainFrame.AllParentFakeFrame.OtherAppsFake

                            for _, Element in UI.Elements.SecondElements do
                                if Element.ClassName == "Frame" then
                                    Element.BackgroundColor3 = Color
                                    Element.BackgroundTransparency = Transparency
                                elseif Element.ClassName == "ImageLabel" then
                                    Element.ImageColor3 = Color
                                    Element.ImageTransparency = Transparency
                                end
                            end
                        elseif ColorIndex == "Third" then
                            for _, Element in UI.Elements.ThirdElements do
                                Element.BackgroundColor3 = Color
                                Element.BackgroundTransparency = Transparency
                            end
                        elseif ColorIndex == "Sections" then
                            local AllParentFakeFrame = MainFakeFrame.StartMainFrame.AllParentFakeFrame
                            local OtherAppsFake = AllParentFakeFrame.OtherAppsFake

                            for _, Section in UI.Elements.Sections do
                                Section.BackgroundColor3 = Color
                                Section.BackgroundTransparency = Transparency
                            end

                            for _, Notification in MainFakeFrame.NotificationsHubFrame.AllParentFakeFrame:GetChildren() do
                                if Notification.Name == "StatusFrame" or Notification.Name == "UIListLayout" then continue end

                                Notification.BackgroundColor3 = Color
                                Notification.BackgroundTransparency = Transparency
                            end

                            OtherAppsFake.BackgroundColor3 = Color
                            OtherAppsFake.BackgroundTransparency = Transparency
                            AllParentFakeFrame.SearchFrame.SearchBox.BackgroundColor3 = Color
                            AllParentFakeFrame.SearchFrame.SearchBox.BackgroundTransparency = Transparency
                        end
                    end

                    function Taskbar:SetFont(Config: {Color: Color3, Transparency: number, Font: Enum, Type: string})
                        Config.Transparency = Config.Transparency or nil
                        Config.Color = Config.Color or nil
                        Config.Font = Config.Font and Enum.Font[Config.Font] or nil
                        Config.Type = Config.Type or nil
                        if not Config.Type then return end

                        if Config.Type == "Main" then
                            for _, Text in UI.Elements.Texts do
                                if Text.ClassName == "TextLabel" or Text.ClassName == "TextBox" then
                                    if Config.Color then Text.TextColor3 = Config.Color end
                                    if Config.Transparency then Text.TextTransparency = Config.Transparency end
                                    if Config.Font then Text.Font = Config.Font end
                                elseif Text.ClassName == "ImageLabel" then
                                    if Config.Color then Text.ImageColor3 = Config.Color end
                                    if Config.Transparency then Text.ImageTransparency = Config.Transparency end
                                end
                            end

                            if Config.Color then Theme.TextColor = Config.Color end
                            if Config.Transparency then Theme.TextTransparency = Config.Transparency end
                        else
                            for _, Text in UI.Elements.LittleTexts do
                                if Config.Color then Text.TextColor3 = Config.Color end
                                if Config.Transparency then Text.TextTransparency = Config.Transparency end
                                if Config.Font then Text.Font = Config.Font end
                            end

                            if Config.Color then Theme.LittleTextColor = Config.Color end
                            if Config.Transparency then Theme.LittleTextTransparency = Config.Transparency end
                        end
                    end

                    function Taskbar:SetNoise(Config: {Transparency: number, Size: number})
                        Config.Transparency = Config.Transparency or nil
                        Config.Size = Config.Size or nil

                        for _, Noise in UI.Elements.Noise do
                            if Config.Transparency then Noise.ImageTransparency = Config.Transparency end
                            if Config.Size then Noise.TileSize = UDim2.new(0, 128 * Config.Size, 0, 128 * Config.Size) end
                        end
                    end

                    function Taskbar:SetBackground(Config: {Transparency: number, Image: string})
                        Config.Transparency = Config.Transparency or nil
                        Config.Image = Config.Image or nil

                        for _, Image in UI.Backgrounds do
                            if Config.Transparency then Image.ImageTransparency = Config.Transparency end
                            if Config.Image then Image.Image = Config.Image end
                        end

                        UI.BackgroundImage = Config.Image
                    end

                    function Taskbar:SetAutoUnlockMouse(Enabled: boolean)
                        UI.WindowsSettings.AutoUnlockMouse = Enabled or false
                    end

                    function Taskbar:SetVingette(Config: {Transparency: number, Size: number})
                        Config.Transparency = Config.Transparency or nil

                        for _, Vingette in UI.Elements.Vingette do
                            if Config.Transparency then Vingette.ImageTransparency = Config.Transparency end
                        end
                    end

                -- Init
                    function Taskbar:Init()
                        task.delay(0.1, function() PlaySound(TaskbarConfig.LoadedSound, 1) end)
                        task.delay(0.1, function()
                            PlayTween(MainFrame, {0.15, Enum.EasingStyle.Quint}, { Position = UDim2.new(0, 0, 1, -77) })
                            task.wait(0.16)
                            PlayTween(MainFrame, {0.15, Enum.EasingStyle.Quint}, { Position = UDim2.new(0, 0, 1, -70) })
                        end)
                        getgenv().TheWorstUIV2Loaded = true
                    end

            UI.Taskbar = Taskbar
            return Taskbar
        end

return UI
