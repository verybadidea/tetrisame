#include "bmp.bi"
#include "block_list.bi"

'message centered on screen
sub showMsg(msgStr as string, c1 as ulong, c2 as ulong)
	dim as integer widthPx =  len(msgStr) * 8
	dim as integer x = (SCREEN_W - widthPx) \ 2
	dim as integer y = (SCREEN_H - 16) \ 2
	line(x-8,y-8)-step(widthPx + 16 - 1, 16 + 8 - 1), c2, bf
	line(x-8,y-8)-step(widthPx + 16 - 1, 16 + 8 - 1), c1, b
	draw string (x,y), msgStr, c1
end sub

enum playStateEnum
	psNewPiece
	psActivePlay
	psWaitDrop 'fast drop
	psCheckBoard
	psWaitClearLine
	psFloatDrop
	psPaused
	psEnd 'not used
end enum

dim shared as string playStateStr(0 to psEnd)
playStateStr(0) = "psNewPiece"
playStateStr(1) = "psActivePlay"
playStateStr(2) = "psWaitDrop"
playStateStr(3) = "psCheckBoard"
playStateStr(4) = "psWaitClearLine"
playStateStr(5) = "psFloatDrop"
playStateStr(6) = "psPaused"
playStateStr(7) = "psEnd"

type game_type
	private:
	dim as all_pieces allPieces
	dim as piece_type piece
	dim as image_type bgImg
	dim as playStateEnum playState
	dim as piece_type activePiece, nextPiece, ghostPiece
	dim as bcl_type bcl 'block collection list
	'public: 'TEMPORARY until gameloop in here game.bi
	dim as board_type board
	dim as integer score
	public:
	declare sub init()
	declare function loop_() as integer
	declare sub drawScene()
	declare sub clearScreen()
	declare sub showAllPieces()
	declare sub gameOver()
	declare function piecePossible(piece as piece_type) as integer
	declare sub wallKick(piece as piece_type)
	declare sub copyToBoard(piece as piece_type)
	declare sub drawPieceGrid(piece as piece_type)
	declare sub drawGhostPiece(piece as piece_type)
	declare sub showPieceFree(piece as piece_type, xOffs as integer, yOffs as integer, tileSize as integer)
	declare function CheckFloat() as integer
	declare function checkNeighbours(x as integer, y as integer, bcNum as integer) as integer
	declare function calcGhostPiece(playPiece as piece_type) as piece_type
end type

sub game_type.init()
	'pieces.init()
	board.init()
	'bgImg.createFromBmp("res/Basil-cathedral-morning_800.bmp")
	bgImg.createFromBmp("res/radioactive_800.bmp")
	imageGrayInt(bgImg.pFbImg, type(000, 0, 199, (bgImg.size.y-1)), +20)
	imageGrayInt(bgImg.pFbImg, type((bgImg.size.x-1)-199, 0, (bgImg.size.x-1)-000, (bgImg.size.y-1)), +20)
	imageGrayInt(bgImg.pFbImg, type(200, 0, (bgImg.size.x-1)-200, (bgImg.size.y-1)), -50)
end sub

function game_type.loop_() as integer
	dim as integer quit = 0
	dim as ushort keyCode
	dim as timer_type gravTmr, clearTmr
	dim as piece_type movedPiece 'temporary copy to test movement
	dim as all_pieces allPieces
	dim as integer tetroScore, floatCount

	playState = psNewPiece
	nextPiece.init(-1, allPieces)
	do
		keyCode = pollKeyCode()

		if playState = psNewPiece then
			activePiece = nextPiece
			ghostPiece = calcGhostPiece(activePiece)
			nextPiece.init(-1, allPieces)
			if not piecePossible(activePiece) then quit = 1
			gravTmr.start(0.500)
			playState = psActivePlay
		end if

		movedPiece = activePiece 'copy piece for location / orientation

		if playState = psPaused then
			select case keyCode
				case KEY_P
					gravTmr.unpause()
					playState = psActivePlay
					keyCode = 0 'hack, prevent repause in section below
				case KEY_ESC
					quit = 1
				case else
				'...
			end select
		end if

		if playState = psActivePlay then
			dim as integer possibleChange = 0
			select case keyCode
				case KEY_LE
					movedPiece.position.x -= 1
					possibleChange = 1
				case KEY_RI
					movedPiece.position.x += 1
					possibleChange = 1
				case KEY_UP
					movedPiece.rotRight()
					wallKick(movedPiece)
					possibleChange = 1
				case KEY_DN
					movedPiece.rotLeft()
					wallKick(movedPiece)
					possibleChange = 1
				case KEY_SPACE
					playState = psWaitDrop 'disable user piece control
					gravTmr.start(0.025) 'drop faster
				case KEY_P
					gravTmr.pause()
					playState = psPaused
				case KEY_ESC
					quit = 1
				case else
				'...
			end select
			'keys: left, right, up, down -> x-change or rotation
			if possibleChange = 1 then
				'check move possible
				if piecePossible(movedPiece) then
					activePiece = movedPiece 'update position
					ghostPiece = calcGhostPiece(activePiece)
				else
					movedPiece = activePiece 'reset moved piece, for next step
				end if
			end if
		end if

		if playState = psActivePlay or playState = psWaitDrop then
			'piece drop by timer
			if gravTmr.ended() then
				movedPiece.position.y += 1
				'check drop possible
				if piecePossible(movedPiece) then 'continue drop
					gravTmr.restart()
					activePiece = movedPiece
				else
					copyToBoard(activePiece)
					activePiece.disable() 
					playState = psCheckBoard
				end if
			end if
		end if
		
		if playState = psCheckBoard then
			'piece has been dropped onto something
			tetroScore = board.checkTetro() 'and mark for visualisation
			if tetroScore > 0 then
				clearTmr.start(0.500) 'remove section after this time
				playState = psWaitClearLine
			else
				playState = psNewPiece
			end if
		end if

		if playState = psWaitClearLine then
			if clearTmr.ended() then
				score += tetroScore
				board.removeTetro() 'marked -> free
				'
				floatCount = checkFloat() 'find + remove + reserve + build list
				if floatCount > 0 then
					clearTmr.start(0.250)
					playState = psFloatDrop
				else
					playState = psNewPiece
				end if
			end if
		end if

		if playState = psFloatDrop then
			if clearTmr.ended() then
				bcl.update(board) 'move down and/or copy bl to board
				floatCount = bcl.getUsed()
				if floatCount > 0 then
					clearTmr.start(0.250) 'stay in this play state
				else
					playState = psCheckBoard
				end if
			end if
		end if

		screenlock
		clearScreen()
		drawScene()
		'locate 6, 2: print "Time: "; time;
		'locate 8, 2: print "floatCount:"; floatCount;
		screenunlock
		sleep 1,1
	loop until quit = 1
	return quit
end function

sub game_type.drawScene()
	put (0, 0), bgImg.pFbImg, pset
	board.drawBoard()
	bcl.drawBlocks(board)
	if menuOpt.showNext then
		showPieceFree(nextPiece, board.getInfo(3) + 50, 50, 32) 'NEXT piece indicator
	end if
	printSpecial3(10, 10, "Score: " & str(score), &hffffffff, &hff404040, &hff000000)
	printSpecial3(10, 30, "State: " & str(playState), &hffffffff, &hff404040, &hff000000)
	'draw string(10,10), "Score: " & str(score)
	'draw string(10,30), "State: " & str(playState)
	if activePiece.alive then drawPieceGrid(activePiece)
	select case playState
		case psPaused
			showMsg("PAUSED", C_WHITE, C_DARK_RED)
		case psActivePlay ', psWaitDrop
			if menuOpt.showGhost then drawGhostPiece(ghostPiece)
	end select
end sub

sub game_type.clearScreen()
	line(0, 0) - (SCREEN_W-1, SCREEN_H-1), C_BLACK, bf
end sub

'draw all tretris pieces (for debugging only)
'~ sub game_type.showAllPieces()
	'~ dim as integer iPiece, iOrient
	'~ dim as piece_type piece
	'~ for iPiece = 0 to NUM_PIECES-1
		'~ for iOrient = 0 to NUM_ORIENT-1
			'~ piece.init(type<int2d>(5 + iPiece * 5, 5 + iOrient * 5), iPiece, iOrient)
			'~ piece.id = iPiece
			'~ piece.rot = iOrient
			'~ drawPiece(piece)
		'~ next
	'~ next
'~ end sub

'Game over animation, fill board to to bottom
sub game_type.gameOver()
	dim as int2d boardSize = board.getGridSize()
	dim as tile_type tile
	for yi as integer = boardSize.y-1 to 0 step -1
		for xi as integer  = 0 to boardSize.x-1
			tile = board.getTile(xi, yi)
			tile.tType = BLOCK_MARKED
			board.setTile(xi, yi, tile)
		next
		screenlock
		clearScreen()
		drawScene()
		screenunlock
		sleep 25, 1
	next
end sub

'check if piece is possible on board
function game_type.piecePossible(piece as piece_type) as integer
	for iTile as integer = 0 to 3
		dim as integer xi = piece.position.x + piece.tilePos(iTile).x
		dim as integer yi = piece.position.y + piece.tilePos(iTile).y
		if board.onBoard(xi, yi) = false then return false
		if board.getTileType(xi, yi) <> BLOCK_FREE then return false
	next
	return true
end function

'test and shift piece (max 1 block/tile), after turn
sub game_type.wallKick(piece as piece_type)
	dim as integer bw = board.getWidth()
	for iTest as integer = 0 to 1 'run twice for long piece
		'check left/right (can't be both)
		for iTile as integer = 0 to 3
			dim as integer xi = piece.position.x + piece.tilePos(iTile).x
			if xi < 0 then
				piece.position.x += 1 'move piece right
				exit for
			end if
			if xi >= bw then
				piece.position.x -= 1 'move piece left
				exit for
			end if
		next
	next
end sub

'copy piece to board
sub game_type.copyToBoard(piece as piece_type)
	for iTile as integer = 0 to N_TILES-1
		dim as int2d absTilePos = piece.getTilePos(iTile)
		dim as ulong c = piece.tileColor(iTile)
		board.setTilePos(absTilePos, type(BLOCK_PIECE, c))
	next
end sub

'draw teris 1 piece, multiple squares, on board
sub game_type.drawPieceGrid(piece as piece_type)
	for iTile as integer = 0 to N_TILES-1
		dim as int2d absTilePos = piece.getTilePos(iTile)
		dim as ulong c = piece.tileColor(iTile)
		board.drawTilePos(absTilePos, type(BLOCK_PIECE, c))
	next
	if menuOpt.showRotPoint then
		board.drawRotPos(piece.getRotPos(), &hffffffff)
	end if
end sub

'display anyway, at specified location and tile size
sub game_type.showPieceFree(piece as piece_type, xScrn as integer, yScrn as integer, tileSize as integer)
	for iTile as integer = 0 to N_TILES-1
		dim as int2d tilePos = piece.tilePos(iTile)
		dim as ulong c = piece.tileColor(iTile)
		dim as integer x = xScrn + (tilePos.x + piece.offsetPos.x) * tileSize
		dim as integer y = yScrn + (tilePos.y + piece.offsetPos.y) * tileSize
		line(x+1, y+1)-step(tileSize - 3, tileSize - 3), c, b
		line(x+2, y+2)-step(tileSize - 5, tileSize - 5), c, b
		c = c and &hffdfdfdf
		line(x+3, y+3)-step(tileSize - 7, tileSize - 7), c, bf
	next
end sub

'draw on grid:
sub game_type.drawGhostPiece(piece as piece_type)
	for iTile as integer = 0 to N_TILES-1
		dim as int2d absTilePos = piece.getTilePos(iTile)
		dim as ulong c = piece.tileColor(iTile)
		board.drawTilePos(absTilePos, type(BLOCK_GHOST, c))
	next
	'board.drawRotPos(piece.getRotPos(), &hffffffff)
end sub


'Drop all pieces not touching? Only floating parts? most natural!
'Make block lists & mark --> use additional map or reset afterwards?
'wait for all block lists to finish dropping? Easier with current dynamic list
'then check for complete lines

'find + remove + reserve + build list
function game_type.checkFloat() as integer
	'create lists of blocks, loop all blocks
	dim as integer bcNum, floating, blockType, count = 0
	dim as int2d blockPos
	for yi as integer = 0 to board.getHeight() - 1
		for xi as integer = 0 to board.getWidth() - 1
			if board.getTileType(xi, yi) = BLOCK_PIECE then
				bcNum = bcl.alloc() 'start a block list
				with bcl.bc(bcNum)
					'.speed = type(0, V_STIR_BLOCK)
					.relPos = type(0, 0)
					.absPosSource = type(xi, yi)
					'.relPosTarget = type(0, 1)
					.addBlock(type(0, 0), board.getTile(xi, yi)) 'first one at rel. pos 0,0
				end with
				'start resurve block search, add more neighbour blocks to list
				checkNeighbours(xi, yi, bcNum)
				'check if dropable (all piece of section with nothing below)
				floating = 1
				for iBlock as integer = 0 to bcl.bc(bcNum).getSize() - 1
					blockPos = bcl.bc(bcNum).getAbsPosBlocks(iBlock)
					blockType = board.getTileType(blockPos.x, blockPos.y + 1)
					if not(blockType = BLOCK_FREE or blockType = BLOCK_CHECK) then
						floating = 0
						exit for
					end if
				next
				'if floation section then remove from board & reserve position
				if floating = 1 then
					for iBlock as integer = 0 to bcl.bc(bcNum).getSize() - 1
						blockPos = bcl.bc(bcNum).getAbsPosBlocks(iBlock)
						'board.setTileType(blockPos.x, blockPos.y, BLOCK_FREE)
						board.setTile(blockPos.x, blockPos.y, type(BLOCK_FREE, -1)) '&hffffffff = clear
						'board.setTileType(blockPos.x, blockPos.y + 1, BLOCK_RES) Waarom ???????????????
					next
					count += 1
				else
					bcl.bc(bcNum).cleanUp() 'remove from list (no floating)
				end if
			end if
		next
	next
	'restore all marked blocks to normal
	for yi as integer = 0 to board.getHeight() - 1
		for xi as integer = 0 to board.getWidth() - 1
			if board.getTileType(xi, yi) = BLOCK_CHECK then
				board.setTileType(xi, yi, BLOCK_PIECE)
			end if
		next
	next
	'note: count can also be obtained from list length
	return count
end function

'resurve block search + mark, no check
function game_type.checkNeighbours(x as integer, y as integer, bcNum as integer) as integer
	with bcl.bc(bcNum)
		if .getSize() > 0 then 'skip first block here
			.addBlock(type(x - .absPosSource.x, y - .absPosSource.y), board.getTile(x, y)) 'relative to source
		end if
	end with
	board.setTileType(x, y, BLOCK_CHECK)
	if board.getTileType(x - 1, y) = BLOCK_PIECE then checkNeighbours(x - 1, y, bcNum)
	if board.getTileType(x + 1, y) = BLOCK_PIECE then checkNeighbours(x + 1, y, bcNum)
	if board.getTileType(x, y - 1) = BLOCK_PIECE then checkNeighbours(x, y - 1, bcNum)
	if board.getTileType(x, y + 1) = BLOCK_PIECE then checkNeighbours(x, y + 1, bcNum)
	return 0
end function

function game_type.calcGhostPiece(playPiece as piece_type) as piece_type
	dim as piece_type tempPiece = playPiece
	do
		tempPiece.position.y += 1
	loop while piecePossible(tempPiece)
	tempPiece.position.y -= 1
	return tempPiece
end function
