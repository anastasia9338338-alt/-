local Style = {}
Style.Name = "astral"
Style.BrandIcon = "sparkle"
Style.YieldURL = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"

Style.Icons = {
    Home = "house", Player = "user-round", Combat = "hand", Invincibility = "shield",
    Target = "locate-fixed", Blobman = "refresh-cw", Toys = "circle-plus", Visual = "eye",
    AutoClicker = "mouse", Keybinds = "keyboard", Misc = "wrench", Lists = "file-text", Settings = "settings",
}

-- Obsidian is the GUI used by the supplied message.txt. Rendering is bundled
-- from its compatible upstream revision; no GUI source is fetched at launch.
function Style.Theme()
    return {BackgroundColor=Color3.fromRGB(15,15,15),MainColor=Color3.fromRGB(25,25,25),
        AccentColor=Color3.fromRGB(125,85,255),OutlineColor=Color3.fromRGB(40,40,40),FontColor=Color3.new(1,1,1),
        HeaderColor=Color3.fromRGB(15,15,15),BodyTopColor=Color3.fromRGB(15,15,15),BodyBottomColor=Color3.fromRGB(15,15,15),
        CheckColor=Color3.fromRGB(25,25,25),SliderFillColor=Color3.fromRGB(125,85,255),
        GlassTransparency=0,RowTransparency=0,HeaderTransparency=0,FontFace="Code",BackgroundImage=""}
end
function Style.Window()
    return {Title="astral",Subtitle="FTAP | v5.02",Footer="astral | v5.02",Icon=Style.BrandIcon,
        NotifySide="Right",BackgroundImage=108109283852139,ShowCustomCursor=true,
        SidebarCompacted=true,CornerRadius=100,Size=UDim2.fromOffset(650,500),
        ToggleKeybind=Enum.KeyCode.RightShift,Center=true,AutoShow=true,
        Font=Enum.Font.Code,ShowMobileButtons=false,
        ShowWatermark={Enabled=true,Title=true,User=true,FPS=true,Duration=false,Ping=true}}
end
function Style.ApplyBase(library)
    library.Presentation="ShadowObsidian"
    library.NotifySound="rbxassetid://8486683243"
    for key,value in pairs(Style.Theme())do if key~="FontFace"then library.Scheme[key]=value end end
    library:UpdateColorsUsingRegistry()
end
function Style.MigrateLayoutDefaults(library,presentation)
    if presentation=="ShadowObsidian"then return end
    local defaults={AstralGUIWindowAlpha={.35,0},AstralGUIRowAlpha={.95,0},AstralGUISliderHeight={26,15}}
    for id,pair in pairs(defaults)do local option=library.Options[id]
        if option and option.Value==pair[1]then option:SetValue(pair[2])end
    end
end
function Style.ApplyStartupTheme(manager,library)
    local choice=library.Options.ThemeManager_ThemeList
    if choice then choice:SetValue("Default")end
    return manager:ApplyTheme("Default")
end

function Style.CreateYieldLauncher(context)
    local state = context.Environment.AstralInfiniteYield
    if not state then
        state = {Loading = false, Loaded = false}
        context.Environment.AstralInfiniteYield = state
    end
    return function()
        if state.Loading or state.Loaded then
            context.Notify(state.Loading and "Infinite Yield is loading." or "Infinite Yield is already loaded.")
            return
        end
        state.Loading = true
        context.Spawn(function()
            local ok, message = pcall(function()
                local source = context.HttpGet(Style.YieldURL)
                assert(type(source) == "string" and source ~= "", "Empty Infinite Yield response")
                local run, err = context.Compile(source, "@astral/InfiniteYield")
                assert(type(run) == "function", err or "Infinite Yield compilation failed")
                if context.IsUnloaded() then return end
                run()
                state.Loaded = true
            end)
            state.Loading = false
            if not ok and not context.IsUnloaded() then context.Notify("Infinite Yield: " .. tostring(message)) end
        end)
    end
end

return Style
