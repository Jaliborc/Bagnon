-- === Config ===
local NUM_BOXES = 7         -- how many squares in the row
local BOX_SIZE = 44         -- square size (pixels)
local BOX_GAP  = 10         -- gap between squares (pixels)

-- Create the status frame
local combatFrame = CreateFrame("Frame", "CombatLockdownStatusFrame", UIParent)
combatFrame:SetSize(200, 20)                 -- width, height
combatFrame:SetPoint("TOP", UIParent, "TOP", 0, -20) -- top center, 20px down

-- Add a texture for background color
local tex = combatFrame:CreateTexture(nil, "BACKGROUND")
tex:SetAllPoints()
combatFrame.tex = tex

-- Update every frame
combatFrame:SetScript("OnUpdate", function(self, elapsed)
  if InCombatLockdown() then
    self.tex:SetColorTexture(1, 0, 0, 0.7) -- red, 70% alpha
  else
    self.tex:SetColorTexture(0, 1, 0, 0.7) -- green, 70% alpha
  end
end)

combatFrame:Show()


do
  -- === Build parent (ID 0) and the ContainerFrameItemButton (ID 0) ===
  local parent = CreateFrame("Frame", "MyParentFrame_StaticID", UIParent)
  parent:SetID(0)

  local itemBtn = CreateFrame("Button", "MyContainerItemBtn_StaticID", parent, "ContainerFrameItemButtonTemplate")
  itemBtn:SetSize(36, 36)
  itemBtn:SetID(1)
  itemBtn:Show()

  do
    local tex = itemBtn:CreateTexture(nil, "BACKGROUND")
    tex:SetTexture(134414)
    tex:SetAllPoints()
    itemBtn.bg = tex
  end

  -- === Helper to make a simple colored square ===
  local function MakeSquare(name, parent)
    local f = CreateFrame("Frame", name, parent)
    f:SetSize(BOX_SIZE, BOX_SIZE)

    local tex = f:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetColorTexture(0.15, 0.6, 1, 0.4)
    f.bg = tex

    f:EnableMouse(true)

    f:SetScript("OnEnter", function(self)
      itemBtn:ClearAllPoints()
      itemBtn:SetPoint("CENTER", f, "CENTER")
    end)

    return f
  end

  -- === Create a centered row of squares ===
  local boxes = {}
  local totalWidth = NUM_BOXES * BOX_SIZE + (NUM_BOXES - 1) * BOX_GAP
  local startX = -totalWidth / 2 + BOX_SIZE / 2

  for i = 1, NUM_BOXES do
    local box = MakeSquare("MyHoverBox_" .. i, UIParent)
    box:SetPoint("CENTER", UIParent, "CENTER", startX + (i - 1) * (BOX_SIZE + BOX_GAP), 0)
    boxes[i] = box
  end
end

do
  -- === Build parent (ID 0) and the ContainerFrameItemButton (ID 0) ===
  local parent0 = CreateFrame("Frame", "MyParentFrame_DynamicID0", UIParent)
  parent0:SetID(0)

  local parent1 = CreateFrame("Frame", "MyParentFrame_DynamicID1", UIParent)
  parent1:SetID(1)

  local itemBtn = CreateFrame("Button", "MyContainerItemBtn_DynamicID", parent0, "ContainerFrameItemButtonTemplate")
  itemBtn:SetSize(36, 36)
  itemBtn:SetID(1)
  itemBtn:Show()

  do
    local tex = itemBtn:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    itemBtn.bg = tex
  end

  -- === Helper to make a simple colored square ===
  local active
  local function MakeSquare(name, parent)
    local f = CreateFrame("Frame", name, parent)
    f:SetSize(BOX_SIZE, BOX_SIZE)

    local tex = f:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetColorTexture(0.15, 0.6, 1, 0.4)
    f.bg = tex

    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
      if active ~= f then
        active = f
        
        if itemBtn:GetID() == 1 then
          itemBtn:SetParent(parent1)
          itemBtn:SetID(2)
          itemBtn.bg:SetTexture(134939)
        else
          itemBtn:SetParent(parent0)
          itemBtn:SetID(1)
          itemBtn.bg:SetTexture(134414)
        end
      end

      itemBtn:ClearAllPoints()
      itemBtn:SetPoint("CENTER", f, "CENTER")
    end)

    return f
  end

  -- === Create a centered row of squares ===
  local boxes = {}
  local totalWidth = NUM_BOXES * BOX_SIZE + (NUM_BOXES - 1) * BOX_GAP
  local startX = -totalWidth / 2 + BOX_SIZE / 2

  for i = 1, NUM_BOXES do
    local box = MakeSquare("MyHoverBox_" .. i, UIParent)
    box:SetPoint("CENTER", UIParent, "CENTER", startX + (i - 1) * (BOX_SIZE + BOX_GAP), -54)
    boxes[i] = box
  end
end

-- bank button
local itemBtn = CreateFrame("Button", "MyContainerBtnAtBank", MyParentFrame_StaticID, "ContainerFrameItemButtonTemplate")
itemBtn:SetPoint("CENTER", UIParent, "CENTER", (BOX_SIZE + BOX_GAP) * NUM_BOXES, -27)
itemBtn:SetSize(36, 36)
itemBtn:SetID(1)
itemBtn:Show()
itemBtn:SetScript('PreClick', function(self)
  if IsShiftKeyDown() then
    C_Container.UseContainerItem(0, 1, nil, 2)
  end
end)

local label = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
label:SetPoint("BOTTOM", itemBtn, "TOP", 0, 4) -- position just above
label:SetText("I think I'm at the bank")

local tex = itemBtn:CreateTexture(nil, "BACKGROUND")
tex:SetTexture(134414)
tex:SetAllPoints()

-- toggles
local btn = CreateFrame("Button", "MyToggleBankButton", UIParent, "UIPanelButtonTemplate")
btn:SetPoint("CENTER", UIParent, "CENTER", -120,-100)
btn:SetText("Toggle Bank")
btn:SetSize(120, 30)
btn:SetScript("OnClick", function()
  if BankFrame:IsShown() then
    HideUIPanel(BankFrame)
  else
    ShowUIPanel(BankFrame)
  end
end)

local btn = CreateFrame("Button", "MyToggleMerchantButton", UIParent, "UIPanelButtonTemplate")
btn:SetPoint("CENTER", UIParent, "CENTER", 0,-100)
btn:SetText("Toggle Merchant")
btn:SetSize(120, 30)
btn:SetScript("OnClick", function()
  if MerchantFrame:IsShown() then
    MerchantFrame:Hide()
  else
    MerchantFrame:Show()
  end
end)

local btn = CreateFrame("Button", "MyTaintTabsButton", UIParent, "UIPanelButtonTemplate")
btn:SetPoint("CENTER", UIParent, "CENTER", 120,-100)
btn:SetText("Taint Frames")
btn:SetSize(120, 30)
btn:SetScript("OnClick", function()
  MerchantFrame.selectedTab = 5
  BankFrame.selectedTab = 5
  function BankFrame:GetActiveBankType() return 2 end
end)