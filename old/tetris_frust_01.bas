'TODO: IMAGE MANIP FUCTIONS
'* Initial date = 2018-01-12
'* Fbc = 1.04.0, 32-bit, linux-x86
'* Indent = tab

'This variation of tetris is a programming excercise, if you like playing teris,
'consider buying as officially licenced teris game from the original creator:
'Алексе́й Леони́дович Па́житнов: https://en.wikipedia.org/wiki/Alexey_Pajitnov

'Note: I made this program as one file to make it easier to post on the forum.
'      The code can be easily converted to seperate .bas and .bi files, the
'      comments show where to split the files. Declarations and constants to
'      .bi files, the rest in the .bas files. 

'Controls: Up, Down, Left, Rigt, Space, Escape

'Score: Number of lines cleared ^ 2 (1, 4, 9, 16) 

'To do:
' check use of integer and boolean
' 1 function for check, mark, remove lines?
' Wallkick, hidden lines
' Bonus point + message for clear field
' Next piece indicator
' Nicer collors
' Pause button + Screen change (darker)

const as integer SCREEN_W = 800
const as integer SCREEN_H = SCREEN_W
const as integer GRID_YDIM = 20
const as integer GRID_XDIM = 10
const as integer GRID_SIZE = SCREEN_H \ GRID_YDIM 'size of squares
const as integer GRID_XOFFS = (SCREEN_W - GRID_XDIM * GRID_SIZE) \ 2 'offset on screen
const as integer GRID_YOFFS = (SCREEN_H - GRID_YDIM * GRID_SIZE) \ 2 'offset on screen

#include "inc/common.bi"
#include "inc/timers.bi"
#include "inc/pieces.bi"
#include "inc/piece.bi"
#include "inc/board.bi"
#include "inc/game.bi"

'******************************* main.bas **************************************

enum playStateEnum
	psNewPiece
	psActivePlay
	psWaitDrop
	psWaitClear
end enum

dim as game_type game
dim as timer_type gravTmr, clearTmr
dim as piece_type activePiece, movedPiece
dim as integer quit = 0
dim as ushort keyCode
'dim as integer dropActive
'dim as integer requestNewPiece = true
dim as integer score, lineCount
dim as playStateEnum playState = psNewPiece

screenres SCREEN_W, SCREEN_H, 32

randomize(timer())
game.init()
'game.showAllPieces() '<-- This is broken, pieces too large
'sleep 1000,1
game.drawBoard()

do
	keyCode = pollKeyCode()

	if playState = psNewPiece then
		'if requestNewPiece then
			'requestNewPiece = false
			activePiece.init(type<xy_int>(GRID_XDIM\2, 0), -1, 0)
			if not game.piecePossible(activePiece) then quit = 1
			gravTmr.start(0.50)
		'end if
		playState = psActivePlay
	end if

	movedPiece = activePiece 'copy piece for location / orientation

	if playState = psActivePlay then
		select case keyCode
			case KEY_LE
				movedPiece.p.x -= 1
			case KEY_RI
				movedPiece.p.x += 1
			case KEY_UP
				movedPiece.rot = (movedPiece.rot + 1) mod NUM_ORIENT
			case KEY_DN
				movedPiece.rot = (movedPiece.rot + 3) mod NUM_ORIENT
			case KEY_SPACE
				playState = psWaitDrop 'disable user piece control
				gravTmr.start(0.02) 'drop faster
			case KEY_ESC
				quit = 1
			case else
			'...
		end select
		'check move possible
		if game.piecePossible(movedPiece) then
			activePiece = movedPiece 'update position
		else
			movedPiece = activePiece 'reset moved piece, for next step
		end if
	end if

	if playState = psActivePlay or playState = psWaitDrop then
		'piece drop by timer
		if gravTmr.ended() then
			movedPiece.p.y += 1
			'check drop possible
			if game.piecePossible(movedPiece) then
				gravTmr.restart()
				activePiece = movedPiece
			else
				'piece has been dropped onto something
				game.moveToBoard(activePiece)
				activePiece.disable()
				lineCount = game.checkLines()
				if lineCount > 0 then
					clearTmr.start(0.500)
					playState = psWaitClear
				else
					playState = psNewPiece
				end if
				'requestNewPiece = true
				'dropActive = false
			end if
		end if
	end if

	if playState = psWaitClear then
		if clearTmr.ended() then
			score += game.removeLines() ^ 2
			playState = psNewPiece
		end if
	end if

	screenlock
	game.clearScreen()
	game.drawBoard()
	game.drawPiece(activePiece)
	locate 2, 2
	print "Score:"; score
	locate 4, 2
	print "State:"; playState
	screenunlock
	sleep 1,1
loop until quit = 1

locate 4, 2
print "Game ended, press any key."
waitKeyCode()
