--[[
	THIS FILE IS ENCODED IN UTF-8

	Bagnon Localization Information: Chinese Simplified
		Credits: Diablohu, yleaf@cwdg(yaroot@gmail.com), 狂飙@cwdg(networm@qq.com)

	Last Update: 2009/06/19 by 狂飙@cwdg(networm@qq.com)

--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bagnon', 'zhCN')
if not L then return end

--keybinding text
L.ToggleBags = '开关 背包'
L.ToggleBank = '开关 银行'
L.ToggleKeys = '开关 钥匙链'


--system messages
L.NewUser = '这是该角色第一次使用 Bagnon，已载入默认设置。'
L.Updated = '已更新到 Bagnon v%s'
L.UpdatedIncompatible = '由一个不相容版本升级，已载入默认设置。'


--slash commands
L.Commands = '命令：'
L.CmdShowInventory = '开关背包界面'
L.CmdShowBank = '开关银行界面'
L.CmdShowKeyring = '开关钥匙链界面'
L.CmdShowVersion = '显示当前版本'


--frame text
L.TitleBags = '%s的背包'
L.TitleBank = '%s的银行'
L.TitleKeys = '%s的钥匙链'


--tooltips
L.TipBank = '银行'
L.TipChangePlayer = '查看其他角色的物品'
L.TipGoldOnRealm = '%s上的总资产'
L.TipHideBag = '隐藏包裹'
L.TipHideBags = '隐藏背包'
L.TipHideSearch = '隐藏搜索界面'
L.TipPurchaseBag = '购买银行空位'
L.TipShowBag = '显示包裹'
L.TipShowBags = '显示背包'
L.TipShowMenu = '右击打开设置菜单'
L.TipShowSearch = '显示搜索界面'
L.TipShowSearch = '搜索'
L.TipShowFrameConfig = '打开设置菜单'
L.TipDoubleClickSearch = '双击打开搜索框'
L.Total = '总共'

--databroker plugin tooltips
L.TipShowBank = 'Shift-点击 开关银行'
L.TipShowInventory = '点击 开关背包'
L.TipShowKeyring = 'Alt-点击 开关钥匙链'
L.TipShowOptions = '右击 打开设置菜单'