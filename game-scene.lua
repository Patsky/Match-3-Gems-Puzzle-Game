-- Project: Match 3 Gems - Puzzle Game
-- SDK:		CoronaSDK
-- Version: 0.1 - training purposes
-- 
-- Copyright 2012 Patryk Kubiak.
-- email : patryk [at] yaystudios [dot] com
-- email2: patsky [at] indieZero2Hero [dot] com
-- website: www.indieZero2Hero.com
-- twitter: @PatskyPat 
-- All Rights Reserved.
-- 
--
--[[ MIT LICENSE  
Copyright (C) 2012 Patryk Kubiak
Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies 
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
OR OTHER DEALINGS IN THE SOFTWARE.
--]]
---------------------------------------------------------------------------------
-- game-scene.lua - GAME SCENE
---------------------------------------------------------------------------------

 
local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
 
----------------------------------------------------------------------------------
-- 
--      NOTE:
--      
--      Code outside of listener functions (below) will only be executed once,
--      unless storyboard.removeScene() is called.
-- 
---------------------------------------------------------------------------------
 
---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

local _W = display.contentWidth 
local _H = display.contentHeight
local mRandom = math.random

local score
local scoreText

local gameTimer
local gameTimerText
local gameTimerBar
local gameTimerBar_bg


local gemsTable = {}
local numberOfMarkedToDestroy = 0
local gemToBeDestroyed  			-- used as a placeholder
local isGemTouchEnabled = true 		-- blocker for double touching gems

local gameOverLayout
local gameOverText1
local gameOverText2

local timers = {}

-- pre-declaration of function
local onGemTouch



local function newGem (i,j)

	local newGem
	newGem = display.newCircle(i*40-20, -60, 20)
	newGem.i = i
	newGem.j = j
	newGem.isMarkedToDestroy = false

	newGem.destination_y = j*40+60

	local R = mRandom(1,4)
	
	if 		(R == 1 ) then 
	
		newGem:setFillColor( 200, 0,   0 )
		newGem.gemType = "red"
	
	elseif 	(R == 2 ) then 
	
		newGem:setFillColor( 0, 200, 0 )
		newGem.gemType = "green"
	
	elseif 	(R == 3 ) then 
	
		newGem:setFillColor( 0, 0, 200 )
		newGem.gemType = "blue"
	
	elseif 	(R == 4 ) then 
	
		newGem:setFillColor( 200, 200, 0 )
		newGem.gemType = "yellow"
	
	end

	--new gem falling animation
	transition.to( newGem, { time=100, y= newGem.destination_y} )

	groupGameLayer:insert( newGem )


	newGem.touch = onGemTouch
	newGem:addEventListener( "touch", newGem )

return newGem
end



local function shiftGems () -- not working yet <-- you stupid.. oh u <_< of coz it's working! :P

print ("Shifting Gems")

	-- first roww
	for i = 1, 8, 1 do
			if gemsTable[i][1].isMarkedToDestroy then

					-- current gem must go to a 'gemToBeDestroyed' variable holder to prevent memory leaks
					-- cannot destroy it now as gemsTable will be sorted and elements moved down
					gemToBeDestroyed = gemsTable[i][1]
					
					-- create a new one
					gemsTable[i][1] = newGem(i,1)
					
					-- destroy old gem
					gemToBeDestroyed:removeSelf()
					gemToBeDestroyed = nil
			end
	end

	-- rest of the rows
	for j = 2, 8, 1 do  -- j = row number - need to do like this it needs to be checked row by row
		for i = 1, 8, 1 do
			
			if gemsTable[i][j].isMarkedToDestroy then --if you find and empty hole then shift down all gems in column

					gemToBeDestroyed = gemsTable[i][j]
				
					-- shiftin whole column down, element by element in one column
					for k = j, 2, -1 do -- starting from bottom - finishing at the second row

						-- curent markedToDestroy Gem is replaced by the one above in the gemsTable
						gemsTable[i][k] = gemsTable[i][k-1]
						gemsTable[i][k].destination_y = gemsTable[i][k].destination_y +40
						transition.to( gemsTable[i][k], { time=100, y= gemsTable[i][k].destination_y} )
						
						-- we change its j value as it has been 'moved down' in the gemsTable
						gemsTable[i][k].j = gemsTable[i][k].j + 1
				
					end

					-- create a new gem at the first row as there is en ampty space due to gems
					-- that have been moved in the column
					gemsTable[i][1] = newGem(i,1)

					-- destroy the old gem (the one that was invisible and placed in gemToBeDestroyed holder)
					gemToBeDestroyed:removeSelf()
					gemToBeDestroyed = nil
			end 
		end
	end
end --shiftGems()



local function markToDestroy( self )

	self.isMarkedToDestroy = true
	numberOfMarkedToDestroy = numberOfMarkedToDestroy + 1
	
	-- check on the left
	if self.i>1 then
		if (gemsTable[self.i-1][self.j]).isMarkedToDestroy == false then

			if (gemsTable[self.i-1][self.j]).gemType == self.gemType then

			   markToDestroy( gemsTable[self.i-1][self.j] )
			end	 
		end
	end

	-- check on the right
	if self.i<8 then
		if (gemsTable[self.i+1][self.j]).isMarkedToDestroy == false then

			if (gemsTable[self.i+1][self.j]).gemType == self.gemType then

			    markToDestroy( gemsTable[self.i+1][self.j] )
			end	 
		end
	end

	-- check above
	if self.j>1 then
		if (gemsTable[self.i][self.j-1]).isMarkedToDestroy == false then

			if (gemsTable[self.i][self.j-1]).gemType == self.gemType then

			   markToDestroy( gemsTable[self.i][self.j-1] )
			end	 
		end
	end

	-- check below
	if self.j<8 then
		if (gemsTable[self.i][self.j+1]).isMarkedToDestroy== false then

			if (gemsTable[self.i][self.j+1]).gemType == self.gemType then

			   markToDestroy( gemsTable[self.i][self.j+1] )
			end	 
		end
	end
end



local function enableGemTouch()

	isGemTouchEnabled = true
end



local function destroyGems()
	print ("Destroying Gems. Marked to Destroy = "..numberOfMarkedToDestroy)


	for i = 1, 8, 1 do
		for j = 1, 8, 1 do
			
			if gemsTable[i][j].isMarkedToDestroy then

				isGemTouchEnabled = false
				transition.to( gemsTable[i][j], { time=300, alpha=0.2, xScale=2, yScale = 2, onComplete=enableGemTouch } )

				-- update score
				score = score + 10
				scoreText.text = string.format( "SCORE: %6.0f", score )
				scoreText:setReferencePoint(display.TopLeftReferencePoint)
				scoreText.x = 60
				
			end
		end
	end

	numberOfMarkedToDestroy = 0
	timer.performWithDelay( 320, shiftGems )

end



local function cleanUpGems()
	print("Cleaning Up Gems")
		
	numberOfMarkedToDestroy = 0
	
	for i = 1, 8, 1 do
		for j = 1, 8, 1 do
			
			-- show that there is not enough
			if gemsTable[i][j].isMarkedToDestroy then
				transition.to( gemsTable[i][j], { time=100, xScale=1.2, yScale = 1.2 } )
				transition.to( gemsTable[i][j], { time=100, delay=100, xScale=1.0, yScale = 1.0} )
			end

			gemsTable[i][j].isMarkedToDestroy = false
			

		end
	end
end



function onGemTouch( self, event )	-- was pre-declared

	if event.phase == "began" and isGemTouchEnabled then

		print("Gem touched i= "..self.i.." j= "..self.j)

		markToDestroy(self)
		
		if numberOfMarkedToDestroy >= 3 then

			destroyGems()
		else 
			cleanUpGems()
		end
	end

return true

end



function onTouchGameOverScreen ( self, event )

	if event.phase == "began" then
		
		storyboard.gotoScene( "menu-scene", "fade", 400  )
		
		return true
	end
end	


local function showGameOver ()

	gameOverLayout.alpha = 0.8
	gameOverText1.alpha = 1
	gameOverText2.alpha = 1


end

local function gameTimerUpdate ()

	gameTimer = gameTimer - 1
	
	if gameTimer >= 0 then gameTimerText.text = gameTimer

	else
		gameOverText2.text = string.format( "SCORE: %6.0f", score )
		showGameOver()

	end
end


-- Called when the scene's view does not exist:
function scene:createScene( event )
        local screenGroup = self.view

		print( "\n1: createScene event")
 
        -----------------------------------------------------------------------------
                
        --      CREATE display objects and add them to 'group' here.
        --      Example use-case: Restore 'group' from previously saved state.
        
        -----------------------------------------------------------------------------

    -- reseting values
    score		= 0
    gameTimer 	= 30


   	groupGameLayer = display.newGroup()
   	groupEndGameLayer = display.newGroup()

    --score text

    scoreText = display.newText( "SCORE:" , 40, 20, "Helvetica", 32 )
	scoreText.text = string.format( "SCORE: %6.0f", score )
	scoreText:setReferencePoint(display.TopLeftReferencePoint)
	scoreText.x = 60
	scoreText:setTextColor(0, 0, 255)
	
	
	gameTimerBar_bg = display.newRoundedRect( 20, 430, 280, 20, 4)
	gameTimerBar_bg:setFillColor( 60, 60, 60 )
 	gameTimerBar = display.newRoundedRect( 20, 430, 280, 20, 4)
 	gameTimerBar:setFillColor( 0, 150, 0 )
 	gameTimerBar:setReferencePoint(display.TopLeftReferencePoint)

 	
 	gameTimerText = display.newText( gameTimer , 0, 0, "Helvetica", 18 )
 	gameTimerText:setTextColor( 255, 255, 255 )
	gameTimerText:setReferencePoint(display.TopLeftReferencePoint)
    gameTimerText.x = _W * 0.5 - 12
    gameTimerText.y = 426
    
	groupGameLayer:insert ( scoreText )
	groupGameLayer:insert ( gameTimerBar_bg )
 	groupGameLayer:insert ( gameTimerBar )
 	groupGameLayer:insert ( gameTimerText )

    --gemsTable
    for i = 1, 8, 1 do

    	gemsTable[i] = {}

		for j = 1, 8, 1 do

			gemsTable[i][j] = newGem(i,j)
	
 		end
 	end
 		

 	gameOverLayout = display.newRect( 0, 0, 320, 480)
 	gameOverLayout:setFillColor( 0, 0, 0 )
 	gameOverLayout.alpha = 0
 	
 	gameOverText1 = display.newText( "GAME OVER", 0, 0, native.systemFontBold, 24 )
	gameOverText1:setTextColor( 255 )
	gameOverText1:setReferencePoint( display.CenterReferencePoint )
	gameOverText1.x, gameOverText1.y = _W * 0.5, _H * 0.5 -150
	gameOverText1.alpha = 0

	gameOverText2 = display.newText( "SCORE: ", 0, 0, native.systemFontBold, 24 )
	gameOverText2.text = string.format( "SCORE: %6.0f", score )
	gameOverText2:setTextColor( 255 )
	gameOverText2:setReferencePoint( display.CenterReferencePoint )
	gameOverText2.x, gameOverText2.y = _W * 0.5, _H * 0.5 - 50
	gameOverText2.alpha = 0

	
	gameOverLayout.touch = onTouchGameOverScreen
	gameOverLayout:addEventListener( "touch", gameOverLayout )


	groupEndGameLayer:insert ( gameOverLayout )
	groupEndGameLayer:insert ( gameOverText1 )
	groupEndGameLayer:insert ( gameOverText2 )


	-- insterting display groups to the screen group (storyboard group)
	screenGroup:insert ( groupGameLayer )
	screenGroup:insert ( groupEndGameLayer )
end
 
-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
        local screenGroup = self.view
        
        -----------------------------------------------------------------------------
                
        --      This event requires build 2012.782 or later.
        
        -----------------------------------------------------------------------------
        
end
 
-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
        local screenGroup = self.view
        
        -----------------------------------------------------------------------------
                
        --      INSERT code here (e.g. start timers, load audio, start listeners, etc.)
        
        -----------------------------------------------------------------------------
	
	-- remove previous scene's view
        
    storyboard.purgeScene( "menu-scene" )

	print( "1: enterScene event" )
	
	-- storyboard.purgeScene( "scene4" )

	-- reseting values
	score = 0
	

	transition.to( gameTimerBar, { time = gameTimer * 1000, width=0 } )
	timers.gameTimerUpdate = timer.performWithDelay(1000, gameTimerUpdate, 0)
				


end
 
 
-- Called when scene is about to move offscreen:
function scene:exitScene( event )
        local screenGroup = self.view
        
        -----------------------------------------------------------------------------
        
        --      INSERT code here (e.g. stop timers, remove listeners, unload sounds, etc.)
        
        -----------------------------------------------------------------------------
       
	if timers.gameTimerUpdate then 
		timer.cancel(timers.gameTimerUpdate)
		timers.gameTimerUpdate = nil
	 end

end
 
-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene( event )
        local screenGroup = self.view
        
        -----------------------------------------------------------------------------
                
        --      This event requires build 2012.782 or later.
        
        -----------------------------------------------------------------------------
        
end
 
 
-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
        local screenGroup = self.view
        
        -----------------------------------------------------------------------------
        
        --      INSERT code here (e.g. remove listeners, widgets, save state, etc.)
        
        -----------------------------------------------------------------------------
        
end
 
-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan( event )
        local screenGroup = self.view
        local overlay_scene = event.sceneName  -- overlay scene name
        
        -----------------------------------------------------------------------------
                
        --      This event requires build 2012.797 or later.
        
        -----------------------------------------------------------------------------
        
end
 
-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded( event )
        local screenGroup = self.view
        local overlay_scene = event.sceneName  -- overlay scene name
 
        -----------------------------------------------------------------------------
                
        --      This event requires build 2012.797 or later.
        
        -----------------------------------------------------------------------------
        
end
 
 
 
---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
 
-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )
 
-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener( "willEnterScene", scene )
 
-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )
 
-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )
 
-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener( "didExitScene", scene )
 
-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )
 
-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener( "overlayBegan", scene )
 
-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener( "overlayEnded", scene )
 
---------------------------------------------------------------------------------
 
return scene