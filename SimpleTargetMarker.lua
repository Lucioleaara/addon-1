-- SimpleTargetMarker.lua

-- Variables globales
local frame = CreateFrame("Frame")
local icon, castIcon
local rotateAnim, zoomAnim
local menuFrame
local lineTop, lineBottom, lineLeft, lineRight -- Lignes pour le viseur

-- Sauvegarde des paramètres (définition par défaut si non existante)
SimpleTargetMarkerDB = SimpleTargetMarkerDB or {
    iconSize = 60,
    color = {1, 1, 1, 1}, -- Blanc par défaut
    offsetX = 0,
    offsetY = 0,
    rotationEnabled = true,
    
    castIconEnabled = true,
    staticModeEnabled = false,
    showOnFriendlies = false,
    linesEnabled = false, -- Option pour les lignes
}

-- Palette de couleurs
local COLORS = {
    {1,0,0,1},   -- Rouge
    {0,1,0,1},   -- Vert
    {0,0,1,1},   -- Bleu
    {1,1,0,1},   -- Jaune
    {1,0,1,1},   -- Magenta
    {0,1,1,1},   -- Cyan
    {1,0.5,0,1}, -- Orange
    {0.5,0,1,1}, -- Violet
    {0.6,0.3,0,1}, -- Marron
    {1,1,1,1},   -- Blanc
}

-- Met à jour la visibilité des lignes
local function UpdateLines()
    local show = SimpleTargetMarkerDB.linesEnabled and icon and icon:IsShown()
    if show then
        if lineTop then lineTop:Show() end
        if lineBottom then lineBottom:Show() end
        if lineLeft then lineLeft:Show() end
        if lineRight then lineRight:Show() end
    else
        if lineTop then lineTop:Hide() end
        if lineBottom then lineBottom:Hide() end
        if lineLeft then lineLeft:Hide() end
        if lineRight then lineRight:Hide() end
    end
end

-- Fonction pour changer la couleur de l'icône et des lignes
local function SetIconColor(r, g, b, a)
    if icon and icon.texture then
        icon.texture:SetVertexColor(r, g, b, a)
    end
    if castIcon and castIcon.texture then
        castIcon.texture:SetVertexColor(r, g, b, a)
    end
    if lineTop then lineTop:SetVertexColor(r, g, b, a) end
    if lineBottom then lineBottom:SetVertexColor(r, g, b, a) end
    if lineLeft then lineLeft:SetVertexColor(r, g, b, a) end
    if lineRight then lineRight:SetVertexColor(r, g, b, a) end
end

-- Vérifie si la cible est valide
local function IsTargetValid(unit)
    return UnitExists(unit) and not UnitIsDead(unit) and (SimpleTargetMarkerDB.showOnFriendlies or not UnitIsFriend("player", unit))
end

-- Vérifie si la cible est en combat
local function IsTargetInCombat(unit)
    return UnitAffectingCombat(unit)
end

-- Met à jour l'apparence de l'icône
local function UpdateIconAppearance(targetUnit)
    if SimpleTargetMarkerDB.staticModeEnabled then
        if icon then icon:Show() end
        if castIcon then castIcon:Hide() end
        UpdateLines()
        return
    end

    local spellName = UnitCastingInfo(targetUnit) or UnitChannelInfo(targetUnit)
    if spellName and SimpleTargetMarkerDB.castIconEnabled then
        if not castIcon then
            castIcon = icon:CreateTexture(nil, "OVERLAY")
            castIcon:SetTexture("Interface\\AddOns\\SimpleTargetMarker\\Textures\\4ArrowsKOS.tga")
        end
        castIcon:SetSize(SimpleTargetMarkerDB.iconSize * 1.5, SimpleTargetMarkerDB.iconSize * 1.5)
        castIcon:SetPoint("CENTER", icon, "CENTER")
        castIcon:Show()
    else
        if castIcon then castIcon:Hide() end
        icon.texture:SetTexture("Interface\\AddOns\\SimpleTargetMarker\\Textures\\core.tga")
        SetIconColor(unpack(SimpleTargetMarkerDB.color))
    end
    UpdateLines()
end

-- Ajuste la taille et la position de l'icône
local function UpdateIconSizeAndPosition(targetUnit)
    if not icon then return end
    icon:SetSize(SimpleTargetMarkerDB.iconSize, SimpleTargetMarkerDB.iconSize)
    if castIcon then
        castIcon:SetSize(SimpleTargetMarkerDB.iconSize * 1.5, SimpleTargetMarkerDB.iconSize * 1.5)
    end

            local namePlate = C_NamePlate.GetNamePlateForUnit(targetUnit)
    if namePlate then
        local scale = namePlate:GetEffectiveScale()
        icon:SetParent(namePlate)
        icon:SetPoint("CENTER", namePlate, "CENTER", SimpleTargetMarkerDB.offsetX, 0.5 * scale + SimpleTargetMarkerDB.offsetY)
        icon:Show()
        if castIcon then
            castIcon:SetParent(namePlate)
            castIcon:SetPoint("CENTER", namePlate, "CENTER", SimpleTargetMarkerDB.offsetX, 0.5 * scale + SimpleTargetMarkerDB.offsetY)
        end
    else
        -- Si aucune barre de vie n'est trouvée pour la cible actuelle, masquer l'icône
        icon:Hide()
        if castIcon then castIcon:Hide() end
    end
end

-- Animation de rotation
local function StartRotation()
    if rotateAnim and SimpleTargetMarkerDB.rotationEnabled and not SimpleTargetMarkerDB.staticModeEnabled then
        rotateAnim:Play()
    elseif rotateAnim then
        rotateAnim:Stop()
    end
end

-- Zoom
local function StopZoomEffect()
    if zoomAnim then
        zoomAnim:Stop()
        if icon then icon:SetScale(1,1) end
    end
end

local function ApplyZoomEffect()
    if zoomAnim and SimpleTargetMarkerDB.zoomEnabled and not SimpleTargetMarkerDB.staticModeEnabled then
        zoomAnim:Play()
    else
        StopZoomEffect()
    end
end

-- Initialisation icône et animations
local function InitializeIcon()
    if not icon then
        icon = CreateFrame("Frame", nil, UIParent)
        icon:SetSize(SimpleTargetMarkerDB.iconSize, SimpleTargetMarkerDB.iconSize)
        icon.texture = icon:CreateTexture(nil, "OVERLAY")
        icon.texture:SetAllPoints()
        icon.texture:SetTexture("Interface\\AddOns\\SimpleTargetMarker\\Textures\\core.tga")
        icon:SetFrameStrata("HIGH")
        icon:SetFrameLevel(10)
        icon:Hide()

        -- Création des 4 segments de ligne
        local lineThickness = 2
        local lineLength = 1000

        lineTop = icon:CreateTexture(nil, "BACKGROUND")
        lineTop:SetTexture(1, 1, 1)
        lineTop:SetSize(lineThickness, lineLength)
        lineTop:SetPoint("BOTTOM", icon, "TOP")

        lineBottom = icon:CreateTexture(nil, "BACKGROUND")
        lineBottom:SetTexture(1, 1, 1)
        lineBottom:SetSize(lineThickness, lineLength)
        lineBottom:SetPoint("TOP", icon, "BOTTOM")

        lineLeft = icon:CreateTexture(nil, "BACKGROUND")
        lineLeft:SetTexture(1, 1, 1)
        lineLeft:SetSize(lineLength, lineThickness)
        lineLeft:SetPoint("RIGHT", icon, "LEFT")

        lineRight = frame:CreateTexture(nil, "BACKGROUND")
        lineRight:SetTexture(1, 1, 1)
        lineRight:SetSize(lineLength, lineThickness)
        lineRight:SetPoint("LEFT", icon, "RIGHT")

        -- Animation rotation (appliquée à la texture de l'icône uniquement)
        rotateAnim = icon.texture:CreateAnimationGroup()
        local rotate = rotateAnim:CreateAnimation("Rotation")
        rotate:SetDegrees(360)
        rotate:SetDuration(10)
        rotate:SetSmoothing("NONE")
        rotateAnim:SetLooping("REPEAT")

        
    end
end

-- Gestionnaire d’événements

frame:SetScript("OnEvent", function(self,event,unit)
    local targetUnit = "target"
    if event=="PLAYER_TARGET_CHANGED" then
        if IsTargetValid(targetUnit) then
            UpdateIconAppearance(targetUnit)
            UpdateIconSizeAndPosition(targetUnit)
            StartRotation()
            
        else
            icon:Hide()
            if castIcon then castIcon:Hide() end
        end
        UpdateLines()
    elseif (event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_STOP" or event=="UNIT_SPELLCAST_CHANNEL_START" or event=="UNIT_SPELLCAST_CHANNEL_STOP") and unit==targetUnit then
        UpdateIconAppearance(targetUnit)
    elseif event=="PLAYER_REGEN_DISABLED" then
        StartRotation()
    elseif event=="PLAYER_REGEN_ENABLED" then
        StartRotation()
    end
end)

-- OnUpdate pour vérifier la validité de la cible régulièrement
local lastTargetCheckTime = 0
local targetCheckInterval = 0.2 -- Vérifier toutes les 0.2 secondes pour une bonne réactivité

frame:SetScript("OnUpdate", function(self, elapsed)
    lastTargetCheckTime = lastTargetCheckTime + elapsed
    if lastTargetCheckTime > targetCheckInterval then
        lastTargetCheckTime = 0
        local targetUnit = "target"
        if IsTargetValid(targetUnit) then
            if icon and not icon:IsShown() then
                icon:Show()
                UpdateIconAppearance(targetUnit)
                UpdateIconSizeAndPosition(targetUnit)
                StartRotation()
                
                UpdateLines()
            end
        else
            if icon and icon:IsShown() then
                icon:Hide()
                UpdateLines()
            end
        end
    end
end)

-- Slash pour menu
SLASH_SIMPLETARGETMARKER1 = "/stm"
SlashCmdList["SIMPLETARGETMARKER"] = function()
    if not menuFrame then
        menuFrame = CreateFrame("Frame","SimpleTargetMarkerMenu",UIParent,"BackdropTemplate")
        menuFrame:SetSize(360,550)
        menuFrame:SetPoint("CENTER")
        menuFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileSize=16, edgeSize=2,
            insets={left=2,right=2,top=2,bottom=2}
        })
        menuFrame:SetBackdropColor(0.1,0.1,0.1,0.85)
        menuFrame:SetBackdropBorderColor(0.7,0.7,0.7,1)
        menuFrame:SetMovable(true)
        menuFrame:EnableMouse(true)
        menuFrame:RegisterForDrag("LeftButton")
        menuFrame:SetScript("OnDragStart",function(self) self:StartMoving() end)
        menuFrame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)

        -- Titre
        local title = menuFrame:CreateFontString(nil,"ARTWORK","GameFontHighlightLarge")
        title:SetPoint("TOP",menuFrame,"TOP",0,-10)
        title:SetText("Simple Target Marker")
        title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        title:SetTextColor(1,1,1,1)

        -- Slider taille icône
        local sizeSlider = CreateFrame("Slider",nil,menuFrame,"OptionsSliderTemplate")
        sizeSlider:SetOrientation("HORIZONTAL")
        sizeSlider:SetSize(200,20)
        sizeSlider:SetPoint("TOP",title,"BOTTOM",0,-30)
        sizeSlider:SetMinMaxValues(30,120)
        sizeSlider:SetValue(SimpleTargetMarkerDB.iconSize)
        sizeSlider:SetValueStep(1)
        sizeSlider:SetScript("OnValueChanged",function(self,val)
            SimpleTargetMarkerDB.iconSize=val
            UpdateIconSizeAndPosition("target")
        end)
        sizeSlider.text=sizeSlider:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        sizeSlider.text:SetPoint("BOTTOM",sizeSlider,"TOP",0,5)
        sizeSlider.text:SetText("Taille Icône")
        sizeSlider.text:SetTextColor(1,1,1,1)

        -- Fonction pour créer sliders X/Y avec Reset et affichage valeur
        local function CreateOffsetSlider(label, parent, yStart, getValFunc, setValFunc)
            local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
            slider:SetOrientation("HORIZONTAL")
            slider:SetSize(200,20)
            slider:SetPoint("TOP", yStart, "BOTTOM", 0, -40)
            slider:SetMinMaxValues(-50,50)
            slider:SetValue(getValFunc())
            slider:SetValueStep(1)

            local valueText = slider:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            valueText:SetPoint("BOTTOM", slider,"TOP",0,5)
            valueText:SetText(label..math.floor(getValFunc()))
            valueText:SetTextColor(1,1,1,1)

            slider:SetScript("OnValueChanged", function(self,val)
                setValFunc(val)
                UpdateIconSizeAndPosition("target")
                valueText:SetText(label..math.floor(val))
            end)

            -- Bouton Reset
            local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            resetBtn:SetSize(60,20)
            resetBtn:SetPoint("LEFT", slider, "RIGHT", 10, 0)
            resetBtn:SetText("Reset")
            resetBtn:SetScript("OnClick", function()
                slider:SetValue(0)
            end)
            resetBtn:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            resetBtn:GetFontString():SetTextColor(1,1,1,1)
            resetBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

            return slider, valueText, resetBtn
        end

        local sliderX, valXText, resetX = CreateOffsetSlider("X: ", menuFrame, sizeSlider, function() return SimpleTargetMarkerDB.offsetX end, function(val) SimpleTargetMarkerDB.offsetX=val end)
        local sliderY, valYText, resetY = CreateOffsetSlider("Y: ", menuFrame, sliderX, function() return SimpleTargetMarkerDB.offsetY end, function(val) SimpleTargetMarkerDB.offsetY=val end)

        -- Palette de couleurs
        local startY=-250
        for i,color in ipairs(COLORS) do
            local btn = CreateFrame("Button",nil,menuFrame)
            btn:SetSize(25,25)
            btn:SetPoint("TOPLEFT",20+(i-1)*30,startY)
            btn:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
            local tex = btn:GetNormalTexture()
            tex:SetVertexColor(unpack(color))
            btn:SetScript("OnClick",function()
                SimpleTargetMarkerDB.color={unpack(color)}
                SetIconColor(unpack(color))
            end)
        end

        -- Checkbuttons
        local function CreateCheck(name,text,val,func,y)
            local chk=CreateFrame("CheckButton",name,menuFrame,"UICheckButtonTemplate")
            chk:SetPoint("TOPLEFT",20,y)
            chk:SetChecked(val)
            chk.text:SetText(text)
            chk:SetScript("OnClick",function(self) 
                func(self:GetChecked())
            end)
        end

        local y=-320
        CreateCheck("STM_Rot","Activer Rotation",SimpleTargetMarkerDB.rotationEnabled,function(val) SimpleTargetMarkerDB.rotationEnabled=val; StartRotation() end,y); y=y-30
        
        CreateCheck("STM_Cast","Icône Incantation",SimpleTargetMarkerDB.castIconEnabled,function(val) SimpleTargetMarkerDB.castIconEnabled=val; UpdateIconAppearance("target") end,y); y=y-30
        CreateCheck("STM_Static","Mode Statique",SimpleTargetMarkerDB.staticModeEnabled,function(val) SimpleTargetMarkerDB.staticModeEnabled=val
            if val then rotateAnim:Stop(); if castIcon then castIcon:Hide() end
            else UpdateIconAppearance("target"); StartRotation()
            end
        end,y); y=y-30
        CreateCheck("STM_Friendlies", "Afficher sur les alliés", SimpleTargetMarkerDB.showOnFriendlies, function(val) 
            SimpleTargetMarkerDB.showOnFriendlies = val
            frame:GetScript("OnEvent")(frame, "PLAYER_TARGET_CHANGED")
        end, y); y=y-30
        CreateCheck("STM_Lines", "Activer les lignes", SimpleTargetMarkerDB.linesEnabled, function(val) 
            SimpleTargetMarkerDB.linesEnabled = val
            UpdateLines()
        end, y); y=y-30

        -- Bouton Fermer
        local closeBtn = CreateFrame("Button",nil,menuFrame,"UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT",menuFrame,"TOPRIGHT",-5,-5)
    end
    menuFrame:Show()
end

-- Initialisation
InitializeIcon()
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
