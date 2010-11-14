--[[
	Bagnon Localization Information: Russian Localization by kutensky
	Updated by StingerSoft
		This file must be present to have partial translations
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bagnon', 'ruRU')
if not L then return end

--keybinding text
L.ToggleBags = 'Открыть/закрыть инвентарь'
L.ToggleBank = 'Открыть/закрыть банк'
L.ToggleKeys = 'Открыть/закрыть связку ключей'


--system messages
L.NewUser = 'Обнаружен новый пользователь, загружены стандартные настройки'
L.Updated = 'Обновлено до v%s'
L.UpdatedIncompatible = 'Обновление от несовместимой версии, загружены стандартные настройки'


--slash commands
L.Commands = 'Команды:'
L.CmdShowInventory = 'Открыть/закрыть инвентарь'
L.CmdShowBank = 'Открыть/закрыть банк'
L.CmdShowKeyring = 'Открыть/закрыть связку ключей'
L.CmdShowVersion = 'Сообщить текущую версию модификации'


--frame text
L.TitleBags = 'Инвентарь |3-1(%s)'
L.TitleBank = 'Банк |3-1(%s)'
L.TitleKeys = 'Связка ключей |3-1(%s)'


--tooltips
L.TipBank = 'Банк'
L.TipChangePlayer = '<Клик> - просмотр предметов другого персонажа.'
L.TipGoldOnRealm = 'Всего денег на %s'
L.TipHideBag = '<Клик> - скрыть сумку.'
L.TipHideBags = '<Клик> - скрыть область сумок.'
L.TipHideSearch = '<Клик> скрыть область поиска.'
L.TipPurchaseBag = '<Клик> - купить ячейку в банке.'
L.TipShowBag = '<Клик> - показать сумку.'
L.TipShowBags = '<Клик> - показать область сумки.'
L.TipShowMenu = '<Правый-клик> - настройки.'
L.TipShowSearch = '<Клик> - показать область поиска.'
L.TipShowSearch = '<Клик> - поиск.'
L.TipShowFrameConfig = '<Правый-клик> - настройки.'
L.TipDoubleClickSearch = '<Alt-тищить> - переместить.\n<Правый-клик> - настройка.\n<Двойной-клик> - поиск.'
L.Total = 'Всего'

--databroker plugin tooltips
L.TipShowBank = '<Shift-Левый клик> - открыть/закрыть банк.'
L.TipShowInventory = '<Левый клик> - открыть/закрыть инвентарь.'
L.TipShowKeyring = '<Alt-левый клик> - открыть/закрыть связку ключей.'
L.TipShowOptions = '<Правый-клик> - настройки.'