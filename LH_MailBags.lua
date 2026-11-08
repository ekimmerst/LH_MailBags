local addonName = ...
local Addon = {}
LH_MailBags = Addon
local DEFAULT_CLOSE_ON_HIDE = true -- false: keep bags open after closing the mailbox
local BANKER_GOSSIP_ICON = 132050
local frame = CreateFrame("Frame")
local hooked, active, serial = false, false, 0
local bankSerial = 0
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
    if type(LH_MailBagsDB.skipBankGossip) ~= "boolean" then
        LH_MailBagsDB.skipBankGossip = false
    end
    return LH_MailBagsDB
end

function Addon:IsEnabled() return GetOptions().enabled end
function Addon:GetCloseOnHide() return GetOptions().closeOnHide end
function Addon:GetSkipBankGossip() return GetOptions().skipBankGossip end

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
        bankSerial = bankSerial + 1
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

function Addon:SetSkipBankGossip(skip)
    GetOptions().skipBankGossip = skip == true
    bankSerial = bankSerial + 1 -- Cancel a bank opening queued before this toggle.
    if self.RefreshSettings then self:RefreshSettings() end
end

local function SelectBankerGossip()
    if not Addon:IsEnabled() or not Addon:GetSkipBankGossip() then return end
    if not (C_GossipInfo and type(C_GossipInfo.GetOptions) == "function"
        and type(C_GossipInfo.SelectOption) == "function") then return end

    local options = C_GossipInfo.GetOptions()
    if not options then return end
    for _, option in ipairs(options) do
        if option.icon == BANKER_GOSSIP_ICON and option.gossipOptionID then
            C_GossipInfo.SelectOption(option.gossipOptionID)
            return
        end
    end
end

local function OpenBagsAtBank()
    bankSerial = bankSerial + 1
    local ticket = bankSerial
    if not Addon:IsEnabled() or not Addon:GetSkipBankGossip() or not Compatible() then return end
    C_Timer.After(0, function()
        if ticket == bankSerial and Addon:IsEnabled() and Addon:GetSkipBankGossip()
            and Compatible() then OpenBags() end
    end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("BANKFRAME_CLOSED")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "GOSSIP_SHOW" then SelectBankerGossip(); return end
    if event == "BANKFRAME_OPENED" then OpenBagsAtBank(); return end
    if event == "BANKFRAME_CLOSED" then bankSerial = bankSerial + 1; return end
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
    elseif command == "bank on" or command == "bank off" then
        Addon:SetSkipBankGossip(command == "bank on")
        Print("Skip banker dialogue and open bags at the bank: "
            .. (Addon:GetSkipBankGossip() and "ON" or "OFF"))
    elseif command == "" and Addon.category then
        Settings.OpenToCategory(Addon.category:GetID())
    else
        Print("/lh_mailbags on | off | close on | close off | bank on | bank off. Use /lh_mailbags to open settings.")
    end
end

Attach()
