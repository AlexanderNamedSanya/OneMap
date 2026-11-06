local A = OneMap

function A:CreateSettings()
    local panelName = "OneMapSettings"
    LibAddonMenu2:RegisterAddonPanel(panelName, {
        type = "panel", name = "OneMap", displayName = "OneMap", author = "oneDOK",
        version = self.version, registerForRefresh = true, registerForDefaults = true,
    })
    local options = {}
    local function Header(key) options[#options + 1] = { type = "header", name = self:Text(key) } end
    local function Description(key) options[#options + 1] = { type = "description", text = self:Text(key) } end
    local function Checkbox(key)
        options[#options + 1] = {
            type = "checkbox", name = self:Text(key), width = "full", default = self.defaults[key],
            getFunc = function() return self.saved[key] end,
            setFunc = function(value)
                self.saved[key] = value
                self:CancelPendingTravel()
                self.quote = nil
                self:ApplyMapSettings()
                self:RefreshHouseRows()
                WORLD_MAP_INFO.modeBar:UpdateButtons()
                if (key == "showDungeons" or key == "showTrials") and not value then
                    WORLD_MAP_INFO:SelectTab(SI_MAP_INFO_MODE_LOCATIONS)
                end
            end,
        }
    end
    Description("scope")
    Header("map")
    for _, key in ipairs({ "enlargeMap", "hideCompletion", "playerPulse", "compactHouses", "showDungeons", "showTrials", "questZone", "antiquityZone" }) do Checkbox(key) end
    Header("travel")
    Description("instructions")
    for _, key in ipairs({ "rightClickTravel", "freeTravel", "travelTooltips" }) do Checkbox(key) end
    Description("instance")
    Description("social")
    Header("sources")
    for _, key in ipairs({ "useGroup", "useFriends", "useGuilds" }) do Checkbox(key) end
    LibAddonMenu2:RegisterOptionControls(panelName, options)
end
