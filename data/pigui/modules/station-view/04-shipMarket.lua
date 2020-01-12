-- Copyright © 2008-2020 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local ui = import 'pigui/pigui.lua'
local StationView = import 'pigui/views/station-view'
local Lang = import 'Lang'

local l = Lang.GetResource("ui-core")
local shipMarket
local view
view = {
	id = "shipMarket",
	name = l.SHIP_MARKET,
	icon = ui.theme.icons.ship,
	showView = true,
	draw = function()
		if(shipMarket) then
			shipMarket:render()
		end
	end,
	refresh = function()
		print('refresh')
		shipMarket = import 'pigui/libs/debug'
		view.showView = shipMarket.showView
	end,
}

StationView:registerView(view)
