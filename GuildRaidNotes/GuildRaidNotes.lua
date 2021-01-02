GRN = {}
local InCombatLockdown, IsLeftAltKeyDown = InCombatLockdown, IsLeftAltKeyDown
local mfloor, tinsert = math.floor, table.insert
local UnitClass, UnitName, UnitInRaid, GetTime, GetNumGuildMembers,
      GetGuildRosterInfo, GetNumRaidMembers = UnitClass, UnitName, UnitInRaid,
                                              GetTime, GetNumGuildMembers,
                                              GetGuildRosterInfo,
                                              GetNumRaidMembers
local timeout = 0
local lastScan = GetTime() - 5
local classColor = {
    ["DEATHKNIGHT"] = "C41F3B",
    ["DRUID"] = "FF7D0A",
    ["HUNTER"] = "A9D271",
    ["MAGE"] = "40C7EB",
    ["PALADIN"] = "F58CBA",
    ["PRIEST"] = "FFFFFF",
    ["ROGUE"] = "FFF569",
    ["SHAMAN"] = "0070DE",
    ["WARLOCK"] = "8787ED",
    ["WARRIOR"] = "C79C6E"
}

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return mfloor(num * mult + 0.5) / mult
end

function GRN:eventHandler(event, ...)
    GRN.MyGUILD = {}
    for i = 1, GetNumGuildMembers() do
        local name, rank, _, _, _, _, note, officernote = GetGuildRosterInfo(i)
        if name then
            GRN.MyGUILD[name] = {}
            GRN.MyGUILD[name].rank = rank or ""
            GRN.MyGUILD[name].note = note or ""
            GRN.MyGUILD[name].EPGP = officernote or ""
        end
    end
end
local f = CreateFrame("Frame")
f:SetScript("OnEvent", GRN.eventHandler)
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

function GRN:RaidZametki(elapsed)
    timeout = timeout + elapsed
    if timeout > 1 then
        timeout = 0
    else
        return
    end
    if InCombatLockdown() then return end
    if not Ttoo then
        Ttoo = true
        if not GRNFrame then
            local SHUMFIX_S_F = CreateFrame("Frame", "Intatheone_Second_Frame")
            SHUMFIX_S_F:SetFrameLevel(1)
            SHUMFIX_S_F:SetParent(RaidFrame)
            SHUMFIX_S_F:SetWidth(25)
            SHUMFIX_S_F:SetHeight(20)
            SHUMFIX_S_F:SetBackdrop({
                bgFile = "Interface/Tooltips//UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips//UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = {left = 0, right = 0, top = 0, bottom = 0}
            })

            SHUMFIX_S_F:SetPoint("TOP", 392, -252)
            SHUMFIX_S_F:SetScale(1)
            SHUMFIX_S_F:SetBackdropColor(0, 0, 0, 1)

        end
        local frame = CreateFrame("Frame", "SimpleBorder",
                                  Intatheone_Second_Frame)
        frame:SetSize(415, 500)
        frame:SetPoint("CENTER", 0, 0)

        local border = frame:CreateTexture(nil, "BACKGROUND")
        border:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        border:SetPoint("TOPLEFT", -1, 0)
        border:SetPoint("BOTTOMRIGHT", 1, 0)
        border:SetVertexColor(0, 0, 0, 1) -- half-alpha light grey

        local body = frame:CreateTexture(nil, "ARTWORK")
        body:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        body:SetAllPoints(frame)
        body:SetVertexColor(0.1, 0.1, 0.1, 0.85) -- solid dark grey

        -- Передвигать мышью
        SimpleBorder:EnableMouse(true)
        SimpleBorder:SetMovable(true)
        SimpleBorder:SetUserPlaced(enable)
        SimpleBorder:SetClampedToScreen(true)
        SimpleBorder:SetScript("OnMouseDown", function(self)
            if IsLeftAltKeyDown() then self:StartMoving() end
        end)
        SimpleBorder:SetScript("OnMouseUp", function(self)
            if IsLeftAltKeyDown() then self:StopMovingOrSizing() end
        end)
        SimpleBorder:SetScript("OnDragStop", function(self)
            if IsLeftAltKeyDown() then self:StopMovingOrSizing() end
        end)

        local f1 = CreateFrame("Frame", nil, SimpleBorder)
        f1:SetWidth(1)
        f1:SetHeight(1)
        f1:SetAlpha(1)
        f1:SetPoint("CENTER", 0, 0)

        f1.text = f1:CreateFontString("GRNFrame", "ARTWORK")
        f1.text:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
        f1.text:SetPoint("CENTER", 0, 0)
        f1.text:SetJustifyH("LEFT")
        f1:Show()
    end
    local myString = ""
    GRN.roster = {}
    if (GetTime() - lastScan > 10) and UnitInRaid("player") then
        GRNFrame:Show()
        for i = 1, GetNumRaidMembers() do
            local class = select(2, UnitClass("raid" .. i))
            if not GRN.roster[class] and class then GRN.roster[class] = {} end
            if class and GRN.roster[class] then tinsert(GRN.roster[class], "raid" .. i) end
        end
        for class, uIds in pairs(GRN.roster) do
            if class then
                for _, uId in ipairs(uIds) do
                    local selfname = UnitName(uId)
                    if selfname and uId and GRN.MyGUILD[selfname] then
                        local unitdata = "|cff" .. classColor[class] .. selfname .. "|r" .. " - |cff00FF96" .. GRN.MyGUILD[selfname].rank .. "|r " .. "[" .. GRN.MyGUILD[selfname].note .. "] "
                        if EPGP then
                            local ep, gp, main = EPGP:GetEPGP(selfname)
                            main = main or selfname
                            if ep and gp and main ~= selfname then
                                unitdata = unitdata .. "(" .. main .. "->".. ep .. ", " .. gp .. ", " .. round(ep/gp, 2)  .. ")"
                            elseif not ep or main == selfname then
                                unitdata = unitdata .. "(" .. GRN.MyGUILD[selfname].EPGP .. ")"
                            end
                        else
                            unitdata = unitdata .. "(" .. GRN.MyGUILD[selfname].EPGP .. ")"
                        end
                        if GRN.MyGUILD[selfname] then
                            myString = myString .. unitdata .. "\n"
                            GRNFrame:SetText(myString)
                        end
                    end
                end
            end
        end
        lastScan = GetTime()
    elseif (GetTime() - lastScan > 30) then
        GRNFrame:Hide()
        lastScan = GetTime()
    end

    if RaidFrame:IsShown() then
        GRNFrame:Show()
    else
        GRNFrame:Hide()
    end
end
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", GRN.RaidZametki)
