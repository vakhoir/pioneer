-- Copyright © 2008-2020 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Engine = import('Engine')
local ui = import 'pigui/pigui.lua'
local pigui = Engine.pigui

local fontSizes = {}
local fontStack = {}

local TextRescale = {}

function TextRescale.withFont(name, size, handler)
	if type(name) == "table" and type(size) == "function" then
		name, size, handler = table.unpack{name.name, name.size, size}
	end

	table.insert(fontStack, { name = name, size = size})

	ui.withFont(name, size, handler)

	table.remove(fontStack, #fontStack)
end

function TextRescale.fitToSpace(text, maxSpace, handler)
	local key = text .. tostring(maxSpace)
	local pushed

	if(fontSizes[key]) then
		ui.withFont(fontSizes[key], handler)
	else
		local font = fontStack[#fontStack]
		local currentFontSize = font.size

		pushed = pigui:PushFont(font.name, currentFontSize)
		local currentTextSize = ui.calcTextSize(text)

		while (currentTextSize.x > maxSpace.x) do
			if not pushed then return end

			currentFontSize = currentFontSize - 1

			if pushed then pigui:PopFont() end
			pushed = pigui:PushFont(font.name, currentFontSize)
			currentTextSize = ui.calcTextSize(text)
			print(currentFontSize, key, currentTextSize, pushed)
		end

		fontSizes[key] = {name=font.name, size=currentFontSize}
		handler()

		pigui:PopFont()
	end
end

return TextRescale
