--Other import such as ankulua-utils or string-utils are defined in support.lua.
package.path = package.path .. ";" .. dir .. 'modules/?.lua'
local support = require("support")
local card = require("card")
local battle = require("battle")
local autoskill = require("autoskill")

--[[このスクリプトは人の動きを真似してるだけなので、サーバーには余計な負担を掛からないはず。
	私の国では仕事時間は異常に長いので、もう満足プレイする時間すらできない。休日を使ってシナリオを読むことがもう精一杯…
	お願いします。このプログラムを禁止しないでください。
--]]

--Main loop, pattern detection regions.
--Click pos are hard-coded into code, unlikely to change in the future.
local APP_WIDTH = getAppUsableScreenSize():getX()
local APP_HEIGHT =getAppUsableScreenSize():getY()

AcceptClick = Location(APP_WIDTH*.65,APP_HEIGHT*.75)

MenuRegion = Region(APP_WIDTH*.85,APP_HEIGHT*.85,APP_WIDTH*.15,APP_HEIGHT*.15)
ResultRegion = Region(APP_WIDTH*.04,APP_HEIGHT*.2,APP_WIDTH*.28,APP_HEIGHT*.14)
BondRegion = Region(APP_WIDTH*.7,APP_HEIGHT*.5,APP_WIDTH*.15,APP_HEIGHT*.15)
QuestrewardRegion = Region(APP_WIDTH*.64,APP_HEIGHT*.098,APP_WIDTH*.145,APP_HEIGHT*.174)
FriendrequestRegion = Region(APP_WIDTH*.25, APP_HEIGHT*.084, APP_WIDTH*.055, APP_HEIGHT*.12)
StaminaRegion = Region(APP_WIDTH*.23,APP_HEIGHT*.135,APP_WIDTH*.12,APP_HEIGHT*.2)
ItemDroppedRegion = Region(APP_WIDTH*.07,APP_HEIGHT*.08,APP_WIDTH*.22,APP_HEIGHT*.08)

StoneClick = (Location(APP_WIDTH*.5,APP_HEIGHT*.24))
AppleClick = (Location(APP_WIDTH*.5,APP_HEIGHT*.44))
SilverClick = (Location(APP_WIDTH*.5,APP_HEIGHT*.64))
BronzeClick = (Location(APP_WIDTH*.5,APP_HEIGHT*.8))

StartQuestClick = Location(APP_WIDTH*.9375,APP_HEIGHT*.9375)
StartQuestWithoutItemClick = Location(APP_WIDTH*.645,APP_HEIGHT*.9) -- see docs/start_quest_without_item_click.png
QuestResultNextClick = Location(APP_WIDTH*.86, APP_HEIGHT*.9375) -- see docs/quest_result_next_click.png

isFirstTurn = true

--[[For future use:
	NpbarRegion = Region(280,1330,1620,50)
	Ultcard1Region = Region(900,100,200,200)
	Ultcard2Region = Region(1350,100,200,200)
	Ultcard3Region = Region(1800,100,200,200)
--]]

--File paths
GeneralImagePath = "image_" .. GameRegion .. "/"

--TBD:Autoskill execution optimization, switch target during Autoskill, Do not let Targetchoose().ultcard() interfere with Autoskill, battle()execution order cleanup.
--TBD:Screenshot function refactoring: https://github.com/29988122/Fate-Grand-Order_Lua/issues/21#issuecomment-428015815

--[[recognize speed realated functions:
	1.setScanInterval(1)
	2.Settings:set("MinSimilarity", 0.5)
	3.Settings:set("AutoWaitTimeout", 1)
	4.usePreviousSnap(true)
	5.resolution 1280
	6.exists(var ,0)
--]]

function menu()
	battle.resetState()
	turnCounter = {0, 0, 0, 0, 0}

	--Click uppermost quest.
	click(Location(APP_WIDTH*.74,APP_HEIGHT*.28))
	wait(1.5)

	--Auto refill.
	if StaminaRegion:exists(GeneralImagePath .. "stamina.png", 0) then
		RefillStamina()
	end

	--Friend selection.
	local hasSelectedSupport = support.selectSupport(Support_SelectionMode)
	if hasSelectedSupport then
		wait(2.5)
		startQuest()
	end
end

function RefillStamina()
	if Refill_or_Not == 1 and StoneUsed < Repetitions then
		if Use == "Stone" then
			click(StoneClick)
			--toast("Auto Refilling Stamina")
			wait(1.5)
			click(AcceptClick)
			StoneUsed = StoneUsed + 1
		elseif Use == "All Apples" then
			click(BronzeClick)
			click(SilverClick)
			click(AppleClick)
			--toast("Auto Refilling Stamina")
			wait(1.5)
			click(AcceptClick)
			StoneUsed = StoneUsed + 1
		elseif Use == "Gold" then
			click(AppleClick)
			--toast("Auto Refilling Stamina")
			wait(1.5)
			click(AcceptClick)
			StoneUsed = StoneUsed + 1
		elseif Use == "Silver" then
			click(SilverClick)
			--toast("Auto Refilling Stamina")
			wait(1.5)
			click(AcceptClick)
			StoneUsed = StoneUsed + 1
		elseif Use == "Bronze" then
			click(BronzeClick)
			--toast("Auto Refilling Stamina")
			wait(1.5)
			click(AcceptClick)
			StoneUsed = StoneUsed + 1
		end
		wait(3)
		if NotJPserverForStaminaRefillExtraClick == nil then
			--Temp solution, https://github.com/29988122/Fate-Grand-Order_Lua/issues/21#issuecomment-357257089
			click(Location(1900,400))
			wait(1.5)
		end
	else
		scriptExit("AP ran out!")
	end
end

function startQuest()
	click(StartQuestClick)

	if isEvent == 1 then
		wait(2)
		click(StartQuestWithoutItemClick)
	end
end

function result()
	
	continueClick(QuestResultNextClick,35)

	wait(3)

	--Friend request screen. Non-friend support was selected this battle.  Ofc it's defaulted not sending request.
	if FriendrequestRegion:exists(GeneralImagePath .. "friendrequest.png") ~= nil then
		click(Location(600,1200))
	end

	wait(15)

	--1st time quest reward screen.
	if QuestrewardRegion:exists(GeneralImagePath .. "questreward.png") ~= nil then
		click(Location(100,100))
	end
end

--User option PSA dialogue. Also choosble list of perdefined skill.
function PSADialogue()
	dialogInit()
	--Auto Refill dialogue content generation.
	if Refill_or_Not == 1 then
		if Use == "Stone" then
			RefillType = "stones"
		elseif Use == "All Apples"
			RefillType = "all apples"
		elseif Use == "Gold"
			RefillType = "gold apples"
		elseif Use == "Silver"
			RefillType = "silver apples"
		else Use == "Bronze"
			RefillType = "bronze apples"
		end
		addTextView("Auto Refill Enabled:")
		newRow()
		addTextView("You are going to use")
		newRow()
		addTextView(Repetitions .. " " .. RefillType .. ", ")
		newRow()
		addTextView("remember to check those values everytime you execute the script!")
		addSeparator()
	end

	--Autoskill dialogue content generation.
	if Enable_Autoskill == 1 then
		addTextView("AutoSkill Enabled:")
		newRow()
		addTextView("Start the script from memu or Battle 1/3 to make it work properly.")
		addSeparator()
	end

	--Autoskill list dialogue content generation.
	if Enable_Autoskill_List == 1 then
		addTextView("Please select your predefined Autoskill setting:")
		newRow()
		addRadioGroup("AutoskillListIndex", 1)
		addRadioButton(Autoskill_List[1][1] .. ": " .. Autoskill_List[1][2], 1)
		addRadioButton(Autoskill_List[2][1] .. ": " .. Autoskill_List[2][2], 2)
		addRadioButton(Autoskill_List[3][1] .. ": " .. Autoskill_List[3][2], 3)
		addRadioButton(Autoskill_List[4][1] .. ": " .. Autoskill_List[4][2], 4)
		addRadioButton(Autoskill_List[5][1] .. ": " .. Autoskill_List[5][2], 5)
		addRadioButton(Autoskill_List[6][1] .. ": " .. Autoskill_List[6][2], 6)
		addRadioButton(Autoskill_List[7][1] .. ": " .. Autoskill_List[7][2], 7)
		addRadioButton(Autoskill_List[8][1] .. ": " .. Autoskill_List[8][2], 8)
		addRadioButton(Autoskill_List[9][1] .. ": " .. Autoskill_List[9][2], 9)
		addRadioButton(Autoskill_List[10][1] .. ": " .. Autoskill_List[10][2], 10)
	end

	--Show the generated dialogue.
	dialogShow("CAUTION")

	--Put user selection into list for later exception handling.
	if Enable_Autoskill_List == 1 then
		Skill_Command = Autoskill_List[AutoskillListIndex][2]
	end
end

function init()
	--Set only ONCE for every separated script run.
	setImmersiveMode(true)
	Settings:setCompareDimension(true,1280)
	Settings:setScriptDimension(true,APP_WIDTH)

	StoneUsed = 0
	PSADialogue()

	autoskill.init(battle, card)
	battle.init(autoskill, card)
	card.init(autoskill, battle)
end

init()
while(1) do
	if MenuRegion:exists(GeneralImagePath .. "menu.png", 0) then
		--toast("Will only select servant/danger enemy as noble phantasm target, unless specified using Skill Command. Please check github for further detail.")
		menu()
	end
	if battle.isIdle() then
		battle.performBattle()
	end
	if ResultRegion:exists(GeneralImagePath .. "result.png", 0) then
		result()
	end
	if BondRegion:exists(GeneralImagePath .. "bond.png", 0) then
		result()
	end
end
