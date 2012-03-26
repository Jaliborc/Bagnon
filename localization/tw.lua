--[[
	THIS FILE IS ENCODED IN UTF-8

	Bagnon Localization Information: Chinese Traditional
	        2007/11/17 by matini< yiting.jheng <at> gmail <dot> com
	        2008/12/01 by yleaf@cwdg(yaroot@gmail.com)
	        2009/04/23 by youngway@水晶之刺
			    2009/06/19 by 狂飆@cwdg(networm@qq.com)
          2011/07/06 by Seraveegd@鬼霧峰
          2012/01/24 by Seraveegd@鬼霧峰

	Last Update: 2012/01/24 by Seraveegd@鬼霧峰

--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bagnon', 'zhTW')
if not L then return end

--keybinding text
L.ToggleBags = '切換 背包'
L.ToggleBank = '切換 銀行'


--system messages
L.NewUser = '新使用者發現，已載入預設設定。'
L.Updated = '已更新到 Bagnon v%s'
L.UpdatedIncompatible = '由一個不相容版本升級，已載入預設設定。'


--slash commands
L.Commands = '命令：'
L.CmdShowInventory = '切換背包'
L.CmdShowBank = '切換銀行'
L.CmdShowVersion = '顯示目前版本'


--frame text
L.TitleBags = '%s的背包'
L.TitleBank = '%s的銀行'
L.Bank = '銀行'


--tooltips
L.TipBags = '背包'
L.TipBank = '銀行'
L.TipBankToggle = '<右鍵點擊> 切換銀行。'
L.TipChangePlayer = '點擊檢視其他角色的物品。'
L.TipGoldOnRealm = '%s上的總資產'
L.TipHideBag = '點擊隱藏背包。'
L.TipHideBags = '<左鍵點擊>隱藏背包顯示。'
L.TipHideSearch = '點擊隱藏搜尋介面。'
L.TipInventoryToggle = '<右鍵點擊>切換背包。'
L.TipPurchaseBag = '點擊購買銀行槽。'
L.TipShowBag = '點擊顯示背包。'
L.TipShowBags = '<左鍵點擊>顯示背包顯示。'
L.TipShowMenu = '<右鍵點擊>設定視窗。'
L.TipShowSearch = '點擊搜尋。'
L.TipShowFrameConfig = '打開設定視窗。'
L.TipDoubleClickSearch = '<Alt-拖動>移動。\n<右鍵點擊>設定。\n<兩次點擊>搜尋。'
L.Total = '總共'

--itemcount tooltips
L.TipCount1 = ', 已裝備: %d'
L.TipCount2 = ', 背包: %d'
L.TipCount3 = ', 銀行: %d'

--databroker plugin tooltips
L.TipShowBank = '<Shift-左鍵點擊>切換銀行。'
L.TipShowInventory = '<左鍵點擊>切換背包。'
L.TipShowOptions = '<右鍵點擊>打開設定選單。'