'* Initial date = 2023-08-17
'* Fbc = 1.09.0, 32/64-bit, linux-x86
'* Indent = tab

'This variation of tetris is a programming excercise, if you like playing teris,
'consider buying as officially licenced teris game from the original creator:
'Алексе́й Леони́дович Па́житнов: https://en.wikipedia.org/wiki/Alexey_Pajitnov

'Note: I made this program as one file to make it easier to post on the forum.
'      The code can be easily converted to seperate .bas and .bi files, the
'      comments show where to split the files. Declarations and constants to
'      .bi files, the rest in the .bas files. 

'Controls: Up, Down, Left, Rigt, Space, Escape

'Score: ????

const as integer SCREEN_W = 800
const as integer SCREEN_H = SCREEN_W
const as integer FONT_W = 8, FONT_H = 16

type menu_options
	dim as boolean showNext = true
	dim as boolean showGhost = false
	dim as boolean showRotPoint = true
end type

dim shared as menu_options menuOpt

sub printSpecial2(x as long, y as long, text as string, c1 as ulong, c2 as ulong)
	for yi as integer = -1 to +1
		for xi as integer = -1 to +1
			if (abs(xi) + abs(yi)) > 2 then continue for
			if xi = 0 and yi = 0 then continue for
			draw string(x+xi,y+yi), text, c2
		next
	next
	draw string(x,y), text, c1
end sub

sub printSpecial3(x as long, y as long, text as string, c1 as ulong, c2 as ulong, c3 as ulong)
	for yi as integer = -2 to +2
		for xi as integer = -2 to +2
			if (abs(xi) + abs(yi)) > 3 then continue for
			if (abs(xi) < 1) and (abs(yi) < 2) then continue for
			if (abs(yi) < 1) and (abs(xi) < 2) then continue for
			draw string(x+xi,y+yi), text, c3
		next
	next
	for yi as integer = -1 to +1
		for xi as integer = -1 to +1
			if (abs(xi) + abs(yi)) > 1 then continue for
			if xi = 0 and yi = 0 then continue for
			draw string(x+xi,y+yi), text, c2
		next
	next
	draw string(x,y), text, c1
end sub

#include "inc/common.bi"
#include "inc/int2d_sgl2d.bi"
#include "inc/timers.bi"
#include "inc/pieces.bi"
#include "inc/piece.bi"
#include "inc/board.bi"
#include "inc/game.bi"

'******************************* main.bas **************************************

dim as game_type game

screenres SCREEN_W, SCREEN_H, 32
width SCREEN_W \ FONT_W, SCREEN_H \ FONT_H

randomize(timer())
'randomize (88)
game.init()
game.loop_()
game.gameOver()

'game.drawScene()

'game.showAllPieces() '<-- This is broken, pieces too large
'sleep 1000,1

'locate 4, 2: print "Game ended, press any key."
'draw string(10,50), "Game ended, press any key."
printSpecial3(10, 50, "Game ended, press any key.", &hffffffff, &hff404040, &hff000000)
waitKeyCode()
