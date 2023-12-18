const as long BLOCK_INVALID = -1
const as long BLOCK_FREE = 0
'const as long BLOCK_FIXED = 1
const as long BLOCK_PIECE = 2
const as long BLOCK_MARKED = 3
'const as long BLOCK_RES = 32
'const as short BLOCK_FAIL = 64
const as short BLOCK_CHECK = 128
const as short BLOCK_GHOST = 256

const MAX_TETRO = 20 'used in tetro search

#define TILE_T long
#define TILE_C ulong

type tile_type
	dim as TILE_T tType ', colorIdx
	dim as TILE_C tColor
	dim as long score
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
	declare sub drawRotPos(pos_ as sgl2d, c as ulong)
	declare function onBoard(x as integer, y as integer) as integer
	declare function getWidth() as integer
	declare function getHeight() as integer
	declare function getGridSize() as int2d
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
	declare function floodFill2(x as integer, y as integer, c as ulong, score as long) as integer
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
		dim as ulong c = &hF0F0F0, c2 'default white
		'draw gray border always
		line(xScrn, yScrn)-step(GRID_SIZE-1, GRID_SIZE-1), C_DARK_GRAY, b
		select case tile.tType 
		case BLOCK_PIECE
			'~ c = tile.tColor
			'~ line(xScrn + 1, yScrn + 1)-step(GRID_SIZE-3, GRID_SIZE-3), c, bf
			c = tile.tColor
			c2 = c and &hffdfdfdf
			line(xScrn + 1, yScrn + 1)-step(GRID_SIZE-3, GRID_SIZE-3), c, b
			line(xScrn + 2, yScrn + 2)-step(GRID_SIZE-5, GRID_SIZE-5), c, b
			'line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c, b
			line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c2, bf
		case BLOCK_MARKED
			c = tile.tColor
			c2 = c and &hff3f3f3f
			line(xScrn + 1, yScrn + 1)-step(GRID_SIZE-3, GRID_SIZE-3), c, b
			line(xScrn + 2, yScrn + 2)-step(GRID_SIZE-5, GRID_SIZE-5), c, b
			'line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c, b
			line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c2, bf
			'dim as string scoreStr = iif(tile.score > 0, str(tile.score), "X")
			if tile.score > 0 then
				dim as string scoreStr = str(tile.score)
				dim as long xOffset = (GRID_SIZE - FONT_W * len(scoreStr)) \ 2 + 1
				dim as long yOffset = (GRID_SIZE - FONT_H) \ 2 + 2
				draw string(xScrn + xOffset, yScrn + yOffset), scoreStr, c
				'printSpecial3(xScrn + xOffset, yScrn + yOffset, scoreStr, c, &hff404040, &hff000000)
			end if
		case BLOCK_GHOST
			c = tile.tColor
			c2 = c and &hff3f3f3f
			line(xScrn + 1, yScrn + 1)-step(GRID_SIZE-3, GRID_SIZE-3), c, b
			line(xScrn + 2, yScrn + 2)-step(GRID_SIZE-5, GRID_SIZE-5), c, b
			'line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c, b
			line(xScrn + 3, yScrn + 3)-step(GRID_SIZE-7, GRID_SIZE-7), c2, bf
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

'show rotational point on board
sub board_type.drawRotPos(pos_ as sgl2d, c as ulong)
	if inRange(pos_.x, 0, GRID_XSZ-1) and inRange(pos_.y, 0, GRID_YSZ-1) then
		dim as integer xScrn = GRID_XOFFS + pos_.x * GRID_SIZE
		dim as integer yScrn = GRID_YOFFS + pos_.y * GRID_SIZE
		circle (xScrn, yScrn), 6,c
		circle (xScrn, yScrn), 5,c
		circle (xScrn, yScrn), 4,c
	end if
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

function board_type.getGridSize() as int2d
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
	dim as long tetroScore(0 to MAX_TETRO-1)
	dim as integer xi, yi, numTiles, numTetro = 0, totalScore = 0
	dim as ulong c
	'loop bottom to top, find and count tetrominoes+ (4-tile piece or larger)
	for yi = GRID_YSZ-1 to -2 step -1
		for xi = 0 to GRID_XSZ-1
			if tile(xi, yi).tType = BLOCK_PIECE then
				c = tile(xi, yi).tColor
				numTiles = floodFill(xi, yi, c)
				if numTiles >= 4 then
					dim as integer score = (numTiles - 3) '4 -> 1, 5 -> 2, etc.
					totalScore += score
					tetroScore(numTetro) = score
					tetroPos(numTetro) = type(xi, yi) 'save position (of first tile)
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
			'numTiles = floodFill(xi, yi, c)
			numTiles = floodFill2(xi, yi, c, tetroScore(iTetro))
		end if
	next
	'if no tetrominoes+ found, clear marks
	'if numTetro = 0 then clearMarked()
	return totalScore
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

function board_type.floodFill2(x as integer, y as integer, c as ulong, score as long) as integer
	dim as integer count
	dim as tile_type matchTile = type(BLOCK_PIECE, c)
	'mark this tile, prevent resursive loop
	tile(x, y).tType = BLOCK_MARKED
	tile(x, y).score = score
	'check neighbour tiles
	if onBoard(x + 1, y) andalso tile(x + 1, y) = matchTile then count += floodFill2(x + 1, y, c, score)
	if onBoard(x - 1, y) andalso tile(x - 1, y) = matchTile then count += floodFill2(x - 1, y, c, score)
	if onBoard(x, y + 1) andalso tile(x, y + 1) = matchTile then count += floodFill2(x, y + 1, c, score)
	if onBoard(x, y - 1) andalso tile(x, y - 1) = matchTile then count += floodFill2(x, y - 1, c, score)
	return count + 1 'should return at least 1 if nothing else is found
end function
