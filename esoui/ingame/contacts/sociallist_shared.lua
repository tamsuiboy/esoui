
function ZO_SocialList_GetRowColors(data, selected)
    local textColor = data.online and ZO_SECOND_CONTRAST_TEXT or ZO_DISABLED_TEXT
    local iconColor = data.online and ZO_DEFAULT_ENABLED_COLOR or ZO_DISABLED_TEXT
    if selected then
        textColor = ZO_SELECTED_TEXT
        iconColor = ZO_SELECTED_TEXT
    end

    return textColor, iconColor
end

function ZO_SocialList_ColorRow(control, data, displayNameTextColor, iconColor, otherTextColor)
    local displayName = control:GetNamedChild("DisplayName")
    displayName:SetColor(displayNameTextColor:UnpackRGBA())

    if data.hasCharacter then
        local character = control:GetNamedChild("CharacterName")
        if character then
            character:SetColor(otherTextColor:UnpackRGBA())
        end

        local zone = control:GetNamedChild("Zone")
        zone:SetColor(otherTextColor:UnpackRGBA())

        local champion = control:GetNamedChild("Champion")
        champion:SetColor(iconColor:UnpackRGBA())

        local level = control:GetNamedChild("Level")
        level:SetColor(otherTextColor:UnpackRGBA())

        local alliance = control:GetNamedChild("AllianceIcon")
        alliance:SetColor(iconColor:UnpackRGBA())

        local class = control:GetNamedChild("ClassIcon")
        class:SetColor(iconColor:UnpackRGBA())
    end
end

function ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
    data.online = online
    data.secsSinceLogoff = online and -1 or secsSinceLogoff
    data.normalizedLogoffSort = online and -1 or ZO_NormalizeSecondsPositive(secsSinceLogoff)
    data.timeStamp = online and 0 or GetFrameTimeSeconds()
end

local KEYBOARD_FUNCTIONS =
{
    playerStatusIcon = GetPlayerStatusIcon,
    championPointsIcon = GetChampionPointsIconSmall,
    allianceIcon = GetAllianceSymbolIcon,
    classIcon = GetClassIcon,
}

local GAMEPAD_FUNCTIONS =
{
    playerStatusIcon = GetGamepadPlayerStatusIcon,
    championPointsIcon = GetGamepadChampionPointsIcon,
    allianceIcon = GetLargeAllianceSymbolIcon,
    classIcon = GetGamepadClassIcon,
}

function ZO_SocialList_SharedSocialSetup(control, data, selected)
    local textureFunctions = IsInGamepadPreferredMode() and GAMEPAD_FUNCTIONS or KEYBOARD_FUNCTIONS

    local displayName = control:GetNamedChild("DisplayName")
    local characterName = control:GetNamedChild("CharacterName")
    local status = control:GetNamedChild("StatusIcon")
    local zone = control:GetNamedChild("Zone")
    local class = control:GetNamedChild("ClassIcon")
    local alliance = control:GetNamedChild("AllianceIcon")
    local heronUserInfoTexture = control:GetNamedChild("HeronUserInfoIcon")
    local level = control:GetNamedChild("Level")
    local champion = control:GetNamedChild("Champion")

    if displayName then
        displayName:SetText(ZO_FormatUserFacingDisplayName(data.displayName))
    end

    if heronUserInfoTexture then
        heronUserInfoTexture:SetHidden(not data.isHeronUser)
    end

    if status then
        status:SetTexture(textureFunctions.playerStatusIcon(data.status))
    end

    local hideCharacterFields = not data.hasCharacter or (zo_strlen(data.characterName) <= 0)
    if characterName then
        if not hideCharacterFields then
            characterName:SetText(ZO_FormatUserFacingCharacterName(data.characterName))
        else
            characterName:SetText("")
        end
    end
    zone:SetHidden(hideCharacterFields)
    class:SetHidden(hideCharacterFields)
    if alliance then
        alliance:SetHidden(hideCharacterFields)
    end
    level:SetHidden(hideCharacterFields)
    champion:SetHidden(hideCharacterFields)

    if data.hasCharacter then
        zone:SetText(data.formattedZone)

        level:SetText(GetLevelOrChampionPointsStringNoIcon(data.level, data.championPoints))

        if data.championPoints and data.championPoints > 0 then
            champion:SetTexture(textureFunctions.championPointsIcon())
        else
            champion:SetHidden(true)
        end

        if alliance then
            local allianceTexture = textureFunctions.allianceIcon(data.alliance)
            if allianceTexture then
                alliance:SetTexture(allianceTexture)
            else
                alliance:SetHidden(true)
            end
        end

        local classTexture = textureFunctions.classIcon(data.class)
        if classTexture  then
            class:SetTexture(classTexture)
        else
            class:SetHidden(true)
        end
    end
end

-- Social lists tend to respond to events caused by other players, which can happen even when you aren't viewing the list directly.
-- To make sure this doesn't impact the rest of the game these events should just dirty the list when it isn't visible, instead of refreshing and potentially causing slow sorts/string formats
-- This class should be used as part of an inheritance chain that includes SortFilterList
ZO_SocialListDirtyLogic_Shared = ZO_Object:Subclass()

function ZO_SocialListDirtyLogic_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SocialListDirtyLogic_Shared:InitializeDirtyLogic(listFragment)
    self.refreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY)
    self.refreshGroup:AddDirtyState("Data", function()
        self:RefreshData()
    end)
    self.refreshGroup:AddDirtyState("Filters", function()
        self:RefreshFilters()
    end)
    self.refreshGroup:AddDirtyState("Sort", function()
        self:RefreshSort()
    end)
    self.refreshGroup:SetActive(function()
        return listFragment:IsShowing()
    end)
    listFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.refreshGroup:TryClean()
        end
    end)
end

function ZO_SocialListDirtyLogic_Shared:DirtyData()
    self.refreshGroup:MarkDirty("Data")
end

function ZO_SocialListDirtyLogic_Shared:DirtyFilters()
    self.refreshGroup:MarkDirty("Filters")
end

function ZO_SocialListDirtyLogic_Shared:DirtySort()
    self.refreshGroup:MarkDirty("Sort")
end
