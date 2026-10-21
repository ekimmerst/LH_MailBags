local addonName = ...
local Addon = LH_MailBags
local variables = {"LH_MailBags_enabled", "LH_MailBags_closeOnHide"}

function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
end

local function Build(category, layout)
    Addon.category = category
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Mailbox bags"))
    local enabled = Settings.RegisterProxySetting(category, variables[1], "boolean", "Enable mailbox bag automation", true,
        function() return Addon:IsEnabled() end,
        function(value) Addon:SetEnabled(value) end)
    local enabledControl = Settings.CreateCheckbox(category, enabled,
        "Open carried bags when the Blizzard mailbox opens. Use Baganator when available, otherwise Blizzard bags. Enabling with an open mailbox also opens the bags. Disabling cancels pending actions and leaves current bags alone. Saved account-wide.")
    local close = Settings.RegisterProxySetting(category, variables[2], "boolean", "Close bags with the mailbox", true,
        function() return Addon:GetCloseOnHide() end,
        function(value) Addon:SetCloseOnHide(value) end)
    local control = Settings.CreateCheckbox(category, close,
        "Enabled: close carried bags when the mailbox closes, including bags that were already open. Disabled: keep or reopen carried bags after the mailbox closes, even if you closed them during the visit. Applies while automation is enabled. Saved account-wide.")
    control:SetParentInitializer(enabledControl, function() return Addon:IsEnabled() end)
end

LH_Tweaks:RegisterModule(addonName, "LH MailBags", Build)
