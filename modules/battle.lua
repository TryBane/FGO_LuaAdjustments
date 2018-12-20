-- modules
local _ankuluaUtils = require("ankulua-utils")
local _autoskill
local _card

-- consts
local APP_WIDTH = getAppUsableScreenSize():getX()
local APP_HEIGHT =getAppUsableScreenSize():getY()

local BATTLE_REGION = Region(APP_WIDTH*.86,APP_HEIGHT*.14,APP_WIDTH*.4,APP_HEIGHT*.42)
local ATTACK_CLICK = Location(APP_WIDTH*.9,APP_HEIGHT*.83)
local SKIP_DEATH_ANIMATION_CLICK = Location(APP_WIDTH*.66, APP_HEIGHT*.07) -- see docs/skip_death_animation_click.png

-- see docs/target_regions.png
local TARGET_REGION_ARRAY = {
	Region( APP_WIDTH*0,APP_HEIGHT*0,APP_WIDTH*.19,APP_HEIGHT*.15),
	Region( APP_WIDTH*.19,APP_HEIGHT*0,APP_WIDTH*.19,APP_HEIGHT*.15),
	Region( APP_WIDTH*.38,APP_HEIGHT*0,APP_WIDTH*.185,APP_HEIGHT*.15)
}

local TARGET_CLICK_ARRAY = {
	Location( APP_WIDTH*.035,APP_HEIGHT*.055),
	Location( APP_WIDTH*.22,APP_HEIGHT*.055),
	Location( APP_WIDTH*.41,APP_HEIGHT*.055)
}

-- state vars
local _currentStage
local _currentTurn
local _hasChosenTarget
local _hasTakenFirstStageSnapshot
local _hasClickedAttack

-- functions
local init
local resetState
local isIdle

local getCurrentStage
local getCurrentTurn

local performBattle
local onTurnStarted
local skipDeathAnimation

local checkCurrentStage
local didStageChange
local takeStageSnapshot
local onStageSnapshotTaken
local onStageChanged

local autoChooseTarget
local isPriorityTarget
local chooseTarget
local onTargetChosen
local hasChosenTarget

local clickAttack
local onAttackClicked
local hasClickedAttack

init = function(autoskill, card)
	_autoskill = autoskill
	_card = card

	resetState()
end

resetState = function()
	_autoskill.resetState()
	_currentStage = 0
	_currentTurn = 0
	_hasTakenFirstStageSnapshot = false
	_hasChosenTarget = false
	_hasClickedAttack = false
end

isIdle = function()
	return BATTLE_REGION:exists(GeneralImagePath .. "battle.png")
end

getCurrentStage = function()
	return _currentStage
end

getCurrentTurn = function()
	return _currentTurn
end

performBattle = function()
	_ankuluaUtils.useSameSnapIn(onTurnStarted)
	wait(2)
	
	if Enable_Autoskill == 1 then
		_autoskill.executeSkill()
	end

	-- maybe Autoskill already did this, so we need to check
	if not _hasClickedAttack then
		clickAttack()
	end
	
	if _card.canClickNpCards() then
		_card.clickNpCards()
	end
	
	_card.clickCommandCards()

	if UnstableFastSkipDeadAnimation == 1 then
		skipDeathAnimation()
	end

	wait(2)
end

onTurnStarted = function()
	checkCurrentStage()
	_currentTurn = _currentTurn + 1
	_hasClickedAttack = false

	if not _hasChosenTarget then
		autoChooseTarget()
	end
end

skipDeathAnimation = function()
	-- https://github.com/29988122/Fate-Grand-Order_Lua/issues/55 Experimental
	for i = 1, 3 do
		click(SKIP_DEATH_ANIMATION_CLICK)
		wait(1)
	end
end

checkCurrentStage = function()
	if not _hasTakenFirstStageSnapshot or didStageChange() then
		takeStageSnapshot()
		onStageChanged()
	end
end

didStageChange = function()
	-- Alternative fix for different font of stage count number among different regions, worked pretty damn well tho.
	-- This will compare last screenshot with current screen, effectively get to know if stage changed or not.

	local currentStagePattern = Pattern(GeneralImagePath .. "_GeneratedStageCounterSnapshot.png"):similar(0.8)
	return not StageCountRegion:exists(currentStagePattern)
end

takeStageSnapshot = function()
	StageCountRegion:save(GeneralImagePath .. "_GeneratedStageCounterSnapshot.png")
	onStageSnapshotTaken()
end

onStageSnapshotTaken = function()
	_hasTakenFirstStageSnapshot = true
end

onStageChanged = function()
	_currentStage = _currentStage + 1
	_hasChosenTarget = false
end

autoChooseTarget = function()
	for i, target in ipairs(TARGET_REGION_ARRAY) do
		if isPriorityTarget(target) then
			chooseTarget(i)			
			return
		end
	end
end

isPriorityTarget = function(target)
	local isDanger = target:exists(GeneralImagePath .. "target_danger.png")
	local isServant = target:exists(GeneralImagePath .. "target_servant.png")

	return isDanger or isServant
end

chooseTarget = function(targetIndex)
	click(TARGET_CLICK_ARRAY[targetIndex])
	onTargetChosen()
end

onTargetChosen = function()
	_hasChosenTarget = true
end

hasChosenTarget = function()
	return _hasChosenTarget
end

clickAttack = function()
	click(ATTACK_CLICK)
	wait(1.5) -- Although it seems slow, make it no shorter than 1 sec to protect user with less processing power devices.

	onAttackClicked()
end

onAttackClicked = function()
	_hasClickedAttack = true
end

hasClickedAttack = function()
	return _hasClickedAttack
end

-- "public" interface
return {
	init = init,
	resetState = resetState,
	isIdle = isIdle,
	getCurrentStage = getCurrentStage,
	getCurrentTurn = getCurrentTurn,
	performBattle = performBattle,
	chooseTarget = chooseTarget,
	hasChosenTarget = hasChosenTarget,
	clickAttack = clickAttack,
	hasClickedAttack = hasClickedAttack
}