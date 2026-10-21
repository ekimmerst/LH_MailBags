local addonName = ...
local Addon = {}
LH_MailBags = Addon
local DEFAULT_CLOSE_ON_HIDE = true -- false: keep bags open after closing the mailbox
local frame = CreateFrame("Frame")
local hooked, active, serial = false, false, 0
local warned = false

local function Print(text)
    print("|cff66ccffLH_MailBags:|r " .. text)
end

local function GetOptions()
    if type(LH_MailBagsDB) ~= "table" then LH_MailBagsDB = {} end
    if type(LH_MailBagsDB.enabled) ~= "boolean" then LH_MailBagsDB.enabled = true end
    if type(LH_MailBagsDB.closeOnHide) ~= "boolean" then
        LH_MailBagsDB.closeOnHide = DEFAULT_CLOSE_ON_HIDE
    end
    return LH_MailBagsDB
end

function Addon:IsEnabled() return GetOptions().enabled end
function Addon:GetCloseOnHide() return GetOptions().closeOnHide end

local function BagCount()
    return NUM_TOTAL_BAG_FRAMES or (Constants and Constants.InventoryConstants
        and Constants.InventoryConstants.NumBagSlots)
end

local function BaganatorRegistry()
    local registry = Baganator and Baganator.CallbackRegistry
    if registry and type(registry.TriggerEvent) == "function" then return registry end
end

local function Compatible()
    if not (C_Timer and type(C_Timer.After) == "function") then return false end
    if Baganator then return BaganatorRegistry() ~= nil end
    return type(OpenBag) == "function" and type(CloseAllBags) == "function"
        and C_Timer and type(C_Timer.After) == "function" and type(BagCount()) == "number"
end

local function OpenBags()
    local registry = BaganatorRegistry()
    if registry then
        registry:TriggerEvent("BagShow")
        return
    end
    -- OpenAllBags may return early if any bag is already open.
    -- OpenBag is idempotent and respects Blizzard's combined-bag setting.
    for id = 0, BagCount() do OpenBag(id) end
end

local function CloseBags()
    local registry = BaganatorRegistry()
    if registry then registry:TriggerEvent("BagHide") else CloseAllBags() end
end

local function ApplyAfterBlizzard(showing)
    serial = serial + 1
    local ticket = serial
    if not Addon:IsEnabled() then return end
    if not Compatible() then
        if not warned then
            warned = true
            Print("Required bag API is missing (Blizzard/Baganator).")
        end
        return
    end
    C_Timer.After(0, function()
        if ticket ~= serial or not Addon:IsEnabled() then return end
        if not Compatible() then return end
        if showing then
            if MailFrame and MailFrame:IsShown() then OpenBags() end
        elseif not (MailFrame and MailFrame:IsShown()) then
            if GetOptions().closeOnHide then CloseBags() else OpenBags() end
        end
    end)
end

local function Attach()
    if hooked or not MailFrame then return end
    hooked = true
    MailFrame:HookScript("OnShow", function()
        if not Addon:IsEnabled() then active = false; return end
        active = true
        ApplyAfterBlizzard(true)
    end)
    MailFrame:HookScript("OnHide", function()
        if not active then return end
        active = false
        ApplyAfterBlizzard(false)
    end)
    if MailFrame:IsShown() and Addon:IsEnabled() then
        active = true
        ApplyAfterBlizzard(true)
    end
end

function Addon:SetEnabled(enabled)
    enabled = enabled == true
    local changed = GetOptions().enabled ~= enabled
    GetOptions().enabled = enabled
    if changed then
        serial = serial + 1 -- Cancel actions queued before this toggle.
        active = false
        if enabled and MailFrame and MailFrame:IsShown() then
            active = true
            ApplyAfterBlizzard(true)
        end
    end
    if self.RefreshSettings then self:RefreshSettings() end
end

function Addon:SetCloseOnHide(close)
    GetOptions().closeOnHide = close == true
    if self.RefreshSettings then self:RefreshSettings() end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == addonName then GetOptions() end
    Attach() -- Blizzard_MailFrame can be loaded on demand.
end)

SLASH_LH_MAILBAGS1 = "/lh_mailbags"
SlashCmdList.LH_MAILBAGS = function(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "on" or command == "off" then
        Addon:SetEnabled(command == "on")
        Print(Addon:IsEnabled() and "Enabled." or "Disabled.")
    elseif command == "close on" or command == "close off" then
        Addon:SetCloseOnHide(command == "close on")
        Print("Close bags the next time the mailbox closes: "
            .. (GetOptions().closeOnHide and "ON" or "OFF (bags will be kept open)"))
    elseif command == "" and Addon.category then
        Settings.OpenToCategory(Addon.category:GetID())
    else
        Print("/lh_mailbags on | off | close on | close off. Use /lh_mailbags to open settings.")
    end
end

Attach()
