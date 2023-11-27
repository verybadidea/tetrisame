const as long BLOCK_INVALID = -1
const as long BLOCK_FREE = 0
'const as long BLOCK_FIXED = 1
const as long BLOCK_PIECE = 2
const as long BLOCK_MARKED = 3
'const as long BLOCK_RES = 32
const as short BLOCK_FAIL = 64
const as short BLOCK_CHECK = 128

const MAX_TETRO = 20 'used in tetro search

#define TILE_T long
#define TILE_C ulong

type tile_type
	dim as TILE_T tType ', colorIdx
	dim as TILE_C tColor
end type

operator =(byref a as tile_type, byref b as tile_type) as integer
	return ((a.tType = b.tType) and (a.tColor = b.tColor))
end operator

type board_type
	private:
	const as integer GRID_YSZ = 20
	const as integer GRID_XSZ = 10
	const as integer GRID_SIZE = SCREEN_H \ GRID_YSZ 'size of squares
	const as integer GRID_XOFFS = (SCREEN_W - GRID_XSZ * GRID_SIZE) \ 2 'offset on screen
	const as integer GRID_YOFFS = (SCREEN_H - GRID_YSZ * GRID_SIZE) \ 2 'offset on screen
	'variables:
	dim as tile_type tile(GRID_XSZ-1, -2 to GRID_YSZ-1) 'block type & color index
	public:
	declare sub init()
	declare sub drawBoard()
	declare sub drawTile(x as integer, y as integer, tile as tile_type)
	declare sub drawTilePos(pos_ as int2d, tile as tile_type)
	declare function onBoard(x as integer, y as integer) as integer
	declare function getWidth() as integer
	declare function getHeight() as integer
	declare function getSize() as int2d
	declare function getInfo(id as integer) as integer
	declare sub setTile(x as integer, y as integer, tile as tile_type)
	declare sub setTileType(x as integer, y as integer, tt as TILE_T)
	'~ declare sub setTileC(x as integer, y as integer, c as ulong)
	declare sub setTilePos(pos_ as int2d, tile as tile_type)
	declare function getTile(x as integer, y as integer) as tile_type
	declare function getTileType(x as integer, y as integer) as TILE_T
	'declare function checkHorzLine(yiCheck as integer) as integer
	'declare sub markHorzLine(yiMark as integer)
	'declare sub moveHorzLines(yiRemove as integer)
	'declare function checkLines() as integer
	'declare function removeLines() as integer
	declare sub replaceType(fromType as integer, toType as integer)
	declare function checkTetro() as integer
	declare sub removeTetro()
	declare function floodFill(x as integer, y as integer, c as ulong) as integer
end type

'Can be converted to constructor
sub board_type.init()
	for yi as integer = -2 to GRID_YSZ-1
		for xi as integer = 0 to GRID_XSZ-1
			tile(xi, yi) = type(BLOCK_FREE, -1) '&hffffffff
		next
	next
end sub

sub board_type.drawBoard()
	for xi as integer = 0 to GRID_XSZ-1
		for yi as integer = 0 to GRID_YSZ-1
			dim as tile_type tile = getTile(xi, yi)
			'dim as ulong c = &hF0F0F0
			'~ select case tile.tType
			'~ case BLOCK_PIECE, BLOCK_MARKED
				'~ c = pieceColor(tile.colorIdx)
			'~ end select
			'drawSquare(xi, yi, tile.tType, c)
			drawTile(xi, yi, tile)
		next
	next
end sub

'Position (x,y) = grid position
sub board_type.drawTile(x as integer, y as integer, tile as tile_type)
	if inRange(x, 0, GRID_XSZ-1) and inRange(y, 0, GRID_YSZ-1) then
		dim as integer xScrn = GRID_XOFFS + x * GRID_SIZE
		dim as integer yScrn = GRID_YOFFS + y * GRID_SIZE
		'get color
		dim as ulong c = &hF0F0F0
		select case tile.tType
		case BLOCK_PIECE, BLOCK_MARKED
			'c = colors(tile.colorIdx)
			c = tile.tColor
		end select
		'draw gray border always
		line(xScrn, yScrn)-step(GRID_SIZE-1, GRID_SIZE-1), C_DARK_GRAY, b
		select case tile.tType 
		case BLOCK_PIECE
			line(xScrn + 1, yScrn + 1)-step(GRID_SIZE-3, GRID_SIZE-3), c, bf
		case BLOCK_MARKED
			line(xScrn + 1, yScrn + 1)-step(GRID_SIZE-3, GRID_SIZE-3), c, b
			line(xScrn + 2, yScrn + 2)-step(GRID_SIZE-5, GRID_SIZE-5), c, b
			line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c, b
		'~ case BLOCK_RES
			'~ line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c, bf
		case else
			'not good, unknown block type
		end select
	else
		'not good, outside grid
		'panic("drawSquare"), don't panic, just skip, can be 2 lines above
	end if
end sub

sub board_type.drawTilePos(pos_ as int2d, tile as tile_type)
	drawTile(pos_.x, pos_.y, tile)
end sub

function board_type.onBoard(x as integer, y as integer) as integer
	if not inRange(x, 0, GRID_XSZ-1) then return false
	if not inRange(y, -2, GRID_YSZ-1) then return false
	return true
end function

function board_type.getWidth() as integer
	return GRID_XSZ
end function

function board_type.getHeight() as integer
	return GRID_YSZ
end function

function board_type.getSize() as int2d
	return type(GRID_XSZ, GRID_YSZ)
end function

function board_type.getInfo(id as integer) as integer
	select case id
	case 0: return GRID_SIZE
	case 1: return GRID_XOFFS 'left
	case 2: return GRID_YOFFS 'top
	case 3: return GRID_XOFFS + GRID_XSZ * GRID_SIZE 'right
	case 4: return GRID_YOFFS + GRID_YSZ * GRID_SIZE 'bottom
	case else 'panic("board_type.getBoardEdge")
	end select
end function

sub board_type.setTile(x as integer, y as integer, tile_ as tile_type)
	if onBoard(x, y) then tile(x, y) = tile_
end sub

sub board_type.setTileType(x as integer, y as integer, bt as long)
	if onBoard(x, y) then tile(x, y).tType = bt
end sub

'~ sub board_type.setTileColor(x as integer, y as integer, c as ulong)
	'~ if onBoard(x, y) then tile(x, y).tColor = c
'~ end sub

sub board_type.setTilePos(pos_ as int2d, tile as tile_type)
	setTile(pos_.x, pos_.y, tile)
end sub

function board_type.getTile(x as integer, y as integer) as tile_type
	if not onBoard(x, y) then
		'panic("getTileType")
		return type(BLOCK_INVALID, -1)
	else
		return tile(x, y)
	end if
end function

function board_type.getTileType(x as integer, y as integer) as TILE_T
	if not onBoard(x, y) then
		'panic("getTileType")
		return BLOCK_INVALID
	else
		return tile(x, y).tType
	end if
end function


'~ function board_type.checkHorzLine(yiCheck as integer) as integer
	'~ dim as integer xi
	'~ for xi = 0 to GRID_XSZ-1
		'~ if getTile(xi, yiCheck).tType = BLOCK_FREE then return false
	'~ next
	'~ return true 'complete line
'~ end function

'~ 'move all lines 1 down from yiRemove and above
'~ sub board_type.moveHorzLines(yiRemove as integer)
	'~ dim as integer xi, yi
	'~ for yi = yiRemove to 1 step -1
		'~ for xi = 0 to GRID_XSZ-1
			'~ if not onBoard(xi, yi) then panic("moveHorzLines")
			'~ setTile(xi, yi, getTile(xi, yi - 1))
		'~ next
	'~ next
'~ end sub

'~ sub board_type.markHorzLine(yiMark as integer)
	'~ dim as integer xi
	'~ for xi = 0 to GRID_XSZ-1
		'~ if not onBoard(xi, yiMark) then panic("markHorzLine")
		'~ 'setTile(xi, yiMark, type(BLOCK_MARKED, -1))
		'~ tile(xi, yiMark).tType = BLOCK_MARKED
	'~ next
'~ end sub

'~ 'find and mark complete lines
'~ function board_type.checkLines() as integer
	'~ dim as integer yi, xi
	'~ dim as integer numLines = 0
	'~ 'from bottom to top
	'~ for yi = GRID_YSZ-1 to -2 step -1
		'~ if checkHorzLine(yi) then
			'~ numLines += 1
			'~ markHorzLine(yi)
		'~ end if
	'~ next
	'~ return numLines
'~ end function

'~ 'check and move lines, return number of lines removed
'~ function board_type.removeLines() as integer
	'~ dim as integer xi, yi
	'~ dim as integer numLines = 0
	'~ 'loop bottom to top
	'~ for yi = GRID_YSZ-1 to -2 step -1
		'~ 'check complete horizontal line
		'~ if checkHorzLine(yi) then
			'~ moveHorzLines(yi)
			'~ numLines += 1
			'~ yi += 1 'recheck this line
		'~ end if
	'~ next
	'~ return numLines
'~ end function

sub board_type.replaceType(fromType as integer, toType as integer)
	for yi as integer = GRID_YSZ-1 to -2 step -1
		for xi as integer  = 0 to GRID_XSZ-1
			if tile(xi, yi).tType = fromType then
				tile(xi, yi).tType = toType
			end if
		next
	next
end sub

'find and mark neighbouring blocks sections
function board_type.checkTetro() as integer
	dim as int2d tetroPos(0 to MAX_TETRO-1)
	dim as integer xi, yi, numTiles, numTetro = 0
	dim as ulong c
	'loop bottom to top, find and count tetrominoes+ (4-tile piece or larger)
	for yi = GRID_YSZ-1 to -2 step -1
		for xi = 0 to GRID_XSZ-1
			if tile(xi, yi).tType = BLOCK_PIECE then
				c = tile(xi, yi).tColor
				numTiles = floodFill(xi, yi, c)
				if numTiles >= 4 then
					tetroPos(numTetro) = type(xi, yi)
					numTetro += 1
				end if
			end if
		next
	next
	'clear all again, tetro positions were saved
	replaceType(BLOCK_MARKED, BLOCK_PIECE)
	'run the recursive thing again on listed positions
	for iTetro as integer = 0 to numTetro-1
		xi = tetroPos(iTetro).x
		yi = tetroPos(iTetro).y
		if tile(xi, yi).tType = BLOCK_PIECE then
			c = tile(xi, yi).tColor
			numTiles = floodFill(xi, yi, c)
		end if
	next
	'if no tetrominoes+ found, clear marks
	'if numTetro = 0 then clearMarked()
	return numTetro
end function

sub board_type.removeTetro()
	'replaceType(BLOCK_MARKED, BLOCK_FREE)
	for yi as integer = GRID_YSZ-1 to -2 step -1
		for xi as integer  = 0 to GRID_XSZ-1
			if tile(xi, yi).tType = BLOCK_MARKED then
				tile(xi, yi) = type(BLOCK_FREE, -1) '&hffffffff
			end if
		next
	next
end sub

function board_type.floodFill(x as integer, y as integer, c as ulong) as integer
	dim as integer count
	dim as tile_type matchTile = type(BLOCK_PIECE, c)
	'mark this tile, prevent resursive loop
	tile(x, y).tType = BLOCK_MARKED
	'check neighbour tiles
	if onBoard(x + 1, y) andalso tile(x + 1, y) = matchTile then count += floodFill(x + 1, y, c)
	if onBoard(x - 1, y) andalso tile(x - 1, y) = matchTile then count += floodFill(x - 1, y, c)
	if onBoard(x, y + 1) andalso tile(x, y + 1) = matchTile then count += floodFill(x, y + 1, c)
	if onBoard(x, y - 1) andalso tile(x, y - 1) = matchTile then count += floodFill(x, y - 1, c)
	return count + 1 'should return at least 1 if nothing else is found
end function

'~ 'Drop all pieces not touching? Only floating parts? most natural!
'~ 'Make block lists & mark --> use additional map or reset afterwards?
'~ 'wait for all block lists to finish dropping? Easier with current dynamic list
'~ 'then check for complete lines
'~ function game_type.stirBlocks() as integer
	'~ 'create lists of blocks, loop all blocks
	'~ dim as integer bcNum, canMove, tType, count = 0
	'~ dim as int2d blockPos
	'~ for yi as integer = 0 to board.Y_DIM-1
		'~ for xi as integer = 0 to board.X_DIM-1
			'~ if board.getType(type(xi, yi)) = BLOCK_PIECE then
				'~ bcNum = bl.alloc() 'start a block list
				'~ with bl.bc(bcNum)
					'~ .speed = type(0, V_STIR_BLOCK)
					'~ .relPosCurrent = type(0, 0)
					'~ .absPosSource = type(xi, yi)
					'~ .relPosTarget = type(0, 1)
					'~ .addBlock(type(0, 0), board.getBlock(type(xi, yi))) 'first one at rel. pos 0,0
				'~ end with
				'~ checkBlocks(xi, yi, bcNum) 'resurve block search
				'~ 'check if dropable (all piece of section nothing below?)
				'~ canMove = 1
				'~ for iBlock as integer = 0 to bl.bc(bcNum).getSize() - 1
					'~ blockPos = toCint2d(bl.bc(bcNum).getAbsPosBlocks(iBlock))
					'~ tType = board.getType(type(blockPos.x, blockPos.y + 1))
					'~ if not(tType = BLOCK_FREE or tType = BLOCK_CHECK) then
						'~ canMove = 0
						'~ exit for
					'~ end if
				'~ next
				'~ if canMove = 1 then
					'~ 'remove from board + reserve position
					'~ for iBlock as integer = 0 to bl.bc(bcNum).getSize() - 1
						'~ blockPos = toCint2d(bl.bc(bcNum).getAbsPosBlocks(iBlock))
						'~ board.setType(blockPos, BLOCK_FREE)
						'~ board.setType(type(blockPos.x, blockPos.y + 1), BLOCK_RES)
					'~ next
					'~ count += 1
				'~ else
					'~ bl.bc(bcNum).cleanUp() 'remove from list
				'~ end if
			'~ end if
		'~ next
	'~ next
	'marked --> piece
	'~ for yi as integer = 0 to board.Y_DIM-1
		'~ for xi as integer = 0 to board.X_DIM-1
			'~ if board.getType(type(xi, yi)) = BLOCK_CHECK then
				'~ board.setType(type(xi, yi), BLOCK_PIECE)
			'~ end if
		'~ next
	'~ next
	'~ 'note: count can also be obtained form list length
	'~ return count
'~ end function
