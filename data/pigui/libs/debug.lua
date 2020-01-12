-- Copyright © 2008-2019 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Lang = import 'Lang'
local Game = import 'Game'
local Format = import 'Format'
local ShipDef = import 'ShipDef'
local StationView = import 'pigui/views/station-view'
local Market = import 'pigui/libs/market.lua'
local PiImage = import 'ui/PiImage'
local ModelSpinner = import 'PiGui.Modules.ModelSpinner'

local ui = import 'pigui/pigui.lua'
local pionillium = ui.fonts.pionillium
local orbiteer = ui.fonts.orbiteer
local l = Lang.GetResource("ui-core")
local colors = ui.theme.colors

local vZero = Vector2(0,0)
local rescaleVector = ui.rescaleUI(Vector2(1, 1), Vector2(1600, 900), true)
local widgetSizes = ui.rescaleUI({
	buySellSize = Vector2(128, 48),
	buttonSizeBase = Vector2(64, 48),
	iconSize = Vector2(64, 64),
	smallButton = Vector2(92, 48),
	bigButton = Vector2(128, 48),
	confirmButtonSize = Vector2(384, 48),
	itemSpacing = Vector2(18, 4),
}, Vector2(1600, 900))

local shipMarket
local icons = {}
local tradeModeBuy = true;
local selectedItem
local tradeAmount = 0
local tradeText = ''
local textColorDefault = Color(255, 255, 255)
local textColorWarning = Color(255, 255, 0)
local textColorError = Color(255, 0, 0)
local tradeTextColor = textColorDefault

local popupId = "shipMarketPopup"
local popupMsg = "shipMarketPopup"

local currentIconSize = Vector2(0,0)

local modelSpinner = ModelSpinner()
local cachedShip = nil
local cachedPattern = nil

local shipClassString = {
	light_cargo_shuttle        = l.LIGHT_CARGO_SHUTTLE,
	light_courier              = l.LIGHT_COURIER,
	light_fighter              = l.LIGHT_FIGHTER,
	light_freighter            = l.LIGHT_FREIGHTER,
	light_passenger_shuttle    = l.LIGHT_PASSENGER_SHUTTLE,
	light_passenger_transport  = l.LIGHT_PASSENGER_TRANSPORT,
	medium_cargo_shuttle       = l.MEDIUM_CARGO_SHUTTLE,
	medium_courier             = l.MEDIUM_COURIER,
	medium_fighter             = l.MEDIUM_FIGHTER,
	medium_freighter           = l.MEDIUM_FREIGHTER,
	medium_passenger_shuttle   = l.MEDIUM_PASSENGER_SHUTTLE,
	medium_passenger_transport = l.MEDIUM_PASSENGER_TRANSPORT,
	heavy_cargo_shuttle        = l.HEAVY_CARGO_SHUTTLE,
	heavy_courier              = l.HEAVY_COURIER,
	heavy_fighter              = l.HEAVY_FIGHTER,
	heavy_freighter            = l.HEAVY_FREIGHTER,
	heavy_passenger_shuttle    = l.HEAVY_PASSENGER_SHUTTLE,
	heavy_passenger_transport  = l.HEAVY_PASSENGER_TRANSPORT,

	unknown                    = "",
}

--player clicked confirm purchase button
local doBuy = function ()

end

--player clicked the confirm sale button
local doSell = function ()

end

local tradeInValue = function(shipDef)
	return 0
end


local tradeMenu = function()
	if(selectedItem) then
		ui.withStyleVars({ WindowPadding = shipMarket.style.windowPadding, ItemSpacing = shipMarket.style.itemSpacing}, function()
			ui.child("TradeMenu", Vector2(ui.screenWidth / 2,0), {"AlwaysUseWindowPadding"}, function()
				local bottomHalf = ui.getCursorPos()
				bottomHalf.y = bottomHalf.y + ui.getContentRegion().y/1.65

				ui.withFont(orbiteer.xlarge.name, orbiteer.xlarge.size, function()
					ui.text(selectedItem.def.name)
				end)
				ui.withFont(orbiteer.medlarge.name, orbiteer.medlarge.size, function()
					ui.text(shipClassString[selectedItem.def.shipClass])
				end)

				ui.text(l.PRICE..": "..Format.Money(selectedItem.def.basePrice, false))
				ui.sameLine()
				ui.text(l.AFTER_TRADE_IN..": "..Format.Money(selectedItem.def.basePrice - tradeInValue(ShipDef[Game.player.shipId]), false))

				local spinnerWidth = ui.getContentRegion().x
				modelSpinner:setSize(Vector2(spinnerWidth, spinnerWidth / 2.5))
				if selectedItem.def.modelName ~= cachedShip then
					cachedShip = selectedItem.def.modelName
					cachedPattern = selectedItem.pattern
					modelSpinner:setModel(cachedShip, selectedItem.skin, cachedPattern)
				end

				modelSpinner:draw()
				ui.text(selectedItem.def.name)
			end)
		end)
	end
end

shipMarket = Market.New("ShipMarket", false, {
	itemTypes = { },
	columnCount = 4,
	initTable = function(self)
		local iconColumnWidth = widgetSizes.iconSize.x + widgetSizes.itemSpacing.x
		local columnWidth = (self.style.size.x - iconColumnWidth) / (self.columnCount-1)
		ui.setColumnWidth(0, widgetSizes.iconSize.x + widgetSizes.itemSpacing.x)
		ui.setColumnWidth(1, columnWidth)
		ui.setColumnWidth(2, columnWidth)
		ui.setColumnWidth(3, columnWidth)

		ui.withFont(orbiteer.xlarge.name, orbiteer.xlarge.size, function()
			ui.text('')
			ui.nextColumn()
			ui.text(l.SHIP)
			ui.nextColumn()
			ui.text(l.PRICE)
			ui.nextColumn()
			ui.text(l.CAPACITY)
			ui.nextColumn()
		end)
	end,
	renderRow = function(self, item)
		-- {shipClassIcon(def.shipClass), def.name, Format.Money(def.basePrice,false), def.capacity.."t"}
		if(icons[item.def.shipClass] == nil) then
			icons[item.def.shipClass] = PiImage.New("icons/shipclass/".. item.def.shipClass ..".png")
			currentIconSize = icons[item.def.shipClass].texture.size
		end
		if not selectedItem then selectedItem = item end
		icons[item.def.shipClass]:Draw(widgetSizes.iconSize)
		ui.nextColumn()
		ui.withStyleVars({ItemSpacing = vZero}, function()
			ui.dummy(widgetSizes.rowVerticalSpacing)
			ui.text(item.def.name)
			ui.nextColumn()
			ui.dummy(widgetSizes.rowVerticalSpacing)
			ui.text(Format.Money(item.def.basePrice,false))
			ui.nextColumn()
			ui.dummy(widgetSizes.rowVerticalSpacing)
			ui.text(item.def.capacity.."t")
			ui.nextColumn()
		end)
	end,
	displayItem = function (s, e) return true end,
	onMouseOverItem = function(s, e)
		--if ui.isMouseClicked(0) and s.funcs.onClickBuy(e) then
			--selectedItem = e
			--tradeModeBuy = true
			--changeTradeAmount(-tradeAmount)
			--s:refresh()
		--end
	end,
	sortingFunction = function(s1,s2) return s1.def.name < s2.def.name end
})

local function refresh()
	widgetSizes.rowVerticalSpacing = Vector2(0, (widgetSizes.iconSize.y + widgetSizes.itemSpacing.y - pionillium.large.size)/2)


	local station = Game.player:GetDockedWith()
	shipMarket.itemTypes = { station:GetShipsOnSale() }
	shipMarket:refresh()
	--currentShipOnSale = nil
	--updateStation(station, station:GetShipsOnSale())
end

local function drawCommoditytView()

	ui.withFont(pionillium.large.name, pionillium.large.size, function()
		ui.child("shipMarketContainer", Vector2(0, ui.getContentRegion().y - StationView.style.height), {}, function()
			shipMarket:render()
			ui.sameLine()
			tradeMenu()
		end)

		StationView:shipSummary()
	end)
end

local importTestView = {}

importTestView.showView = true

function importTestView:render()
	refresh()
	drawCommoditytView()
end

return importTestView
