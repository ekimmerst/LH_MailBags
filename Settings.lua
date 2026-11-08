local addonName = ...
local Addon = LH_MailBags
local variables = {"LH_MailBags_enabled", "LH_MailBags_closeOnHide", "LH_MailBags_skipBankGossip"}

function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
end

local function Build(category, layout)
    Addon.category = category
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Mailbox and bank bags"))
    local enabled = Settings.RegisterProxySetting(category, variables[1], "boolean", "Enable bag automation", true,
        function() return Addon:IsEnabled() end,
        function(value) Addon:SetEnabled(value) end)
    local enabledControl = Settings.CreateCheckbox(category, enabled,
        "Open carried bags when the Blizzard mailbox opens. When the bank option is enabled, also skip the banker dialogue and open bags at the bank. Use Baganator when available, otherwise Blizzard bags. Disabling cancels pending actions and leaves current bags alone. Saved account-wide.")
    local close = Settings.RegisterProxySetting(category, variables[2], "boolean", "Close bags with the mailbox", true,
        function() return Addon:GetCloseOnHide() end,
        function(value) Addon:SetCloseOnHide(value) end)
    local control = Settings.CreateCheckbox(category, close,
        "Enabled: close carried bags when the mailbox closes, including bags that were already open. Disabled: keep or reopen carried bags after the mailbox closes, even if you closed them during the visit. Applies while automation is enabled. Saved account-wide.")
    control:SetParentInitializer(enabledControl, function() return Addon:IsEnabled() end)
    local bank = Settings.RegisterProxySetting(category, variables[3], "boolean", "Skip banker dialogue and open bags", false,
        function() return Addon:GetSkipBankGossip() end,
        function(value) Addon:SetSkipBankGossip(value) end)
    local bankControl = Settings.CreateCheckbox(category, bank,
        "Select the banker option automatically, then open your carried bags alongside the bank. Uses Baganator when available, otherwise Blizzard bags. Saved account-wide.")
    bankControl:SetParentInitializer(enabledControl, function() return Addon:IsEnabled() end)
end

LH_Tweaks:RegisterModule(addonName, "LH MailBags", Build)
